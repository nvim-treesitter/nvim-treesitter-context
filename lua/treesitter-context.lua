local api = vim.api
local ts_utils = require'nvim-treesitter.ts_utils'
local Highlighter = vim.treesitter.highlighter
-- local ts_query = require('nvim-treesitter.query')
local parsers = require'nvim-treesitter.parsers'
local utils = require'treesitter-context.utils'
local len = utils.len
local slice = utils.slice
local slice_right = utils.slice_right
local word_pattern = utils.word_pattern

local defaultConfig = {
  enable = true,
  throttle = false,
}

local config = {}

local ffi = require("ffi")
ffi.cdef'int curwin_col_off(void);'

-- Constants

-- Tells us at which node type to stop when highlighting a multi-line
-- node. If not specified, the highlighting stops after the first line.
local last_types = {
  ['function'] = {
    c = 'function_declarator',
    cpp = 'function_declarator',
    lua = 'parameters',
    javascript = 'formal_parameters',
    typescript = 'formal_parameters',
  },
}

local TYPE_PATTERNS = vim.tbl_map(word_pattern, {
  -- These catch most generic groups, eg "function_declaration" or "function_block"
  'class',
  'function',
  'method',
  'for',
  'while',
  'if',
  'switch',
  'case',
  -- There are more specific
  'impl_item', -- Rust
})
local INDENT_PATTERN = '^%s+'

-- Script variables

local enabled = nil
local winid = nil
local bufnr = api.nvim_create_buf(false, true)
local ns = api.nvim_create_namespace('nvim-treesitter-context')
local context_nodes = {}
local context_types = {}
local previous_nodes = nil
local current_height = 0


-- Helper functions
local log_message = function(value)
  api.nvim_command('echom ' .. vim.fn.json_encode(value))
end

local function get_first_visible_line()
  return api.nvim_call_function('line', { 'w0' }) + current_height
end

local get_target_node = function()
  local tree = parsers.get_parser():parse()[1]
  return tree:root()
end

local is_valid = function(node, type_patterns)
  local node_type = node:type()
  for _, rgx in ipairs(type_patterns) do
    if node_type:find(rgx) then
      return true, rgx
    end
  end
  return false
end

local get_type_pattern = function(node, type_patterns)
  local node_type = node:type()
  for _, rgx in ipairs(type_patterns) do
    if node_type:find(rgx) then
      return rgx
    end
  end
  return nil
end

local get_text_for_node = function(node, type)
  local start_row, start_col = node:start()
  local end_row, end_col     = node:end_()

  local lines = ts_utils.get_node_text(node)

  if start_col ~= 0 then
    lines[1] = api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1]
  end
  start_col = 0

  local filetype = api.nvim_buf_get_option(0, 'filetype')
  local last_type = (last_types[type] or {})[filetype]
  local last_position = nil

  if last_type ~= nil then
    for child, _ in node:iter_children() do
      local ctype = child:type()

      if ctype == last_type then
        last_position = {child:end_()}

        end_row = last_position[1]
        end_col = last_position[2]
        local last_index = end_row - start_row
        lines = slice(lines, 1, last_index + 1)
        lines[#lines] = slice(lines[#lines], 1, end_col)
        break
      end
    end
  end

  if last_position == nil then
    lines = slice(lines, 1, 1)
    end_row = start_row
    end_col = #lines[1]
  end

  local range = {start_row, start_col, end_row, end_col}

  return lines, range
end

local function get_node_at_position(line, column)
  local position_range = { line - 1, column }
  local root = ts_utils.get_root_for_position(unpack(position_range))

  if not root then
    return
  end

  return root:named_descendant_for_range(position_range[1], position_range[2], position_range[1], position_range[2])
end

local function get_first_context_node()
  local line = get_first_visible_line()
  local text = api.nvim_buf_get_lines(0, line, line + 1, false)[1]
  local column = 1

  return get_node_at_position(line, column)
end


-- Merge lines, removing the indentation after 1st line
local merge_lines = function(lines)
  local text = ''
  for i, line in ipairs(lines) do
    if i == 1 then
      text = text .. line
    else
      text = text .. line:gsub(INDENT_PATTERN, '')
    end
    text = text .. ' '
  end
  return text
end

-- Get indentation for lines except first
local get_indents = function(lines)
  local indents = vim.tbl_map(function(line)
    local indent = line:match(INDENT_PATTERN)
    return indent and #indent or 0
  end, lines)
  -- Dont skip first line indentation
  indents[1] = 0
  return indents
end

local get_gutter_width = function()
  return ffi.C.curwin_col_off();
end

local nvim_augroup = function(group_name, definitions)
  api.nvim_command('augroup ' .. group_name)
  api.nvim_command('autocmd!')
  for _, def in ipairs(definitions) do
    local command = table.concat({'autocmd', unpack(def)}, ' ')
    if api.nvim_call_function('exists', {'##' .. def[1]}) ~= 0 then
      api.nvim_command(command)
    end
  end
  api.nvim_command('augroup END')
end

local cursor_moved_vertical
do
  local line
  cursor_moved_vertical = function()
    local newline =  vim.api.nvim_win_get_cursor(0)[1]
    if newline ~= line then
      line = newline
      return true
    end
    return false
  end
end

local function display_window(width, height, row, col)
  if winid == nil or not api.nvim_win_is_valid(winid) then
    winid = api.nvim_open_win(bufnr, false, {
      relative = 'win',
      width = width,
      height = height,
      row = row,
      col = col,
      focusable = false,
      style = 'minimal',
    })
    api.nvim_win_set_var(winid, 'treesitter_context', true)
  else
    api.nvim_win_set_config(winid, {
      win = api.nvim_get_current_win(),
      relative = 'win',
      width = width,
      height = height,
      row = row,
      col = col,
    })
  end
  api.nvim_win_set_option(winid, 'winhl', 'NormalFloat:TreesitterContext')
end

-- Exports

local M = {}

function M.do_au_cursor_moved_vertical()
  if cursor_moved_vertical() then
    vim.cmd [[doautocmd <nomodeline> User CursorMovedVertical]]
  end
end

function M.get_context(opts)
  if not parsers.has_parser() then return nil end
  local options = opts or {}
  local type_patterns = options.type_patterns or TYPE_PATTERNS

  local current_node = get_first_context_node()
  if not current_node then return nil end

  local matches = {}
  local expr = current_node

  while expr do
    local is_match, type = is_valid(expr, type_patterns)
    if is_match then
      table.insert(matches, 1, {expr, type})
    end
    expr = expr:parent()
  end

  if #matches == 0 then
    return nil
  end

  return matches
end

function M.get_parent_matches(type_patterns)
  if not parsers.has_parser() then return nil end

  -- FIXME: use TS queries when possible
  -- local matches = ts_query.get_capture_matches(0, '@scope.node', 'locals')

  local current = get_first_context_node()
  if not current then return end

  local parent_matches = {}
  while current ~= nil do
    local position = {current:start()}
    if is_valid(current, type_patterns) and position[1] > 0 then
      table.insert(parent_matches, current)
    end
    current = current:parent()
  end

  return parent_matches
end

function M.update_context()
  if api.nvim_get_option('buftype') ~= '' or
      vim.fn.getwinvar(0, '&previewwindow') ~= 0 then
    M.close()
    return
  end

  local context = M.get_parent_matches(TYPE_PATTERNS)

  context_nodes = {}
  context_types = {}

  if context then
    local first_visible_line = get_first_visible_line()
    local last_row = -1

    for i = #context, 1, -1 do
      local node = context[i]
      local type = get_type_pattern(node, TYPE_PATTERNS) or node:type()
      local row = node:start()

      if row < (first_visible_line - 1) and row ~= last_row then
        table.insert(context_nodes, node)
        table.insert(context_types, type)
        last_row = row
      end
    end
  end

  if #context_nodes ~= 0 then
    M.open()
  else
    M.close()
  end
end

do
  local running = false

  function M.throttled_update_context()
    if running then return end
    running = true
    vim.defer_fn(function()
      local status, err = pcall(M.update_context)

      if not status then
        print('Failed to get context: ' .. err)
      end

      running = false
    end, 100)
  end
end

function M.close()
  previous_nodes = nil
  current_height = 0

  if winid ~= nil and api.nvim_win_is_valid(winid) then
    -- Can't close other windows when the command-line window is open
    if api.nvim_call_function('getcmdwintype', {}) ~= '' then
      return
    end

    api.nvim_win_close(winid, true)
  end
  winid = nil
end

function M.open()
  if #context_nodes == 0 then return end

  local displayed_nodes = context_nodes

  local first_node_end = { get_first_context_node():end_() }
  local available_lines =
    math.min(
      first_node_end[1] - api.nvim_call_function('line', { 'w0' }),
      vim.fn.winline() - 1
    )

  if #displayed_nodes > available_lines then
    local length = available_lines == 0 and 1 or available_lines
    displayed_nodes = slice_right(displayed_nodes, length)
  end

  if displayed_nodes == previous_nodes then return end
  previous_nodes = displayed_nodes
  current_height = #displayed_nodes

  local saved_bufnr = api.nvim_get_current_buf()

  local gutter_width = get_gutter_width()
  local win_width  = math.max(1, api.nvim_win_get_width(0) - gutter_width)
  local win_height = math.max(1, #displayed_nodes)

  display_window(win_width, win_height, 0, gutter_width)

  -- Set text

  local context_ranges = {}
  local context_lines = {}
  local context_text = {}
  local context_indents = {}

  for i in ipairs(displayed_nodes) do
    local lines, range = get_text_for_node(displayed_nodes[i])
    local text = merge_lines(lines)
    local indents = get_indents(lines)
    table.insert(context_lines, lines)
    table.insert(context_ranges, range)
    table.insert(context_text, text)
    table.insert(context_indents, indents)
  end

  api.nvim_buf_set_lines(bufnr, 0, -1, false, context_text)

  -- api.nvim_command('echom ' .. vim.fn.json_encode({
  --   type = target_node:type(),
  --   text = ts_utils.get_node_text(target_node),
  -- }))

  -- Highlight

  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local buf_highlighter = Highlighter.active[saved_bufnr] or nil
  local buf_queries = nil
  local buf_query = nil

  if buf_highlighter then
    buf_queries = buf_highlighter._queries
    buf_query = buf_queries[vim.bo.filetype]
    if buf_query == nil then
      return
    end
  else
    local current_ft = api.nvim_buf_get_option(0, 'filetype')
    local buffer_ft  = api.nvim_buf_get_option(bufnr, 'filetype')
    if current_ft ~= buffer_ft then
      api.nvim_buf_set_option(bufnr, 'filetype', current_ft)
    end
    return
  end

  for i in ipairs(displayed_nodes) do
    local current_node = displayed_nodes[i]
    local range = context_ranges[i]
    local indents = context_indents[i]
    local lines = context_lines[i]

    local start_row = range[1]
    local start_col = range[2]
    local end_row   = range[3]
    local end_col   = range[4]

    local target_node = get_target_node()

    local start_row_absolute = current_node:start()

    local captures =
      buf_query:query()
        :iter_captures(target_node, saved_bufnr, start_row, current_node:end_())

    local last_line = nil
    local last_offset = nil

    for capture, node in captures do
      local hl = buf_query.hl_cache[capture]
      local atom_start_row, atom_start_col,
            atom_end_row,   atom_end_col = node:range()

      if atom_end_row > end_row or
        (atom_end_row == end_row and atom_end_col > end_col) then
        break
      end

      if atom_start_row >= start_row_absolute then

        local intended_start_row = atom_start_row - start_row_absolute
        local intended_end_row   = atom_end_row   - start_row_absolute
        local intended_start_col = atom_start_col
        local intended_end_col   = atom_end_col

        local offset
        if intended_start_row == last_line then
          offset = last_offset
        else
          -- Add 1 for each space added between lines when
          -- we replace "\n" with " "
          offset = intended_start_row
          -- Add the length of each precending lines
          for j = 1, intended_start_row do
            offset = offset + #lines[j] - indents[j]
          end
          -- Remove the indentation negative offset for current line
          offset = offset - (indents[intended_start_row + 1])
        end

        local hl_start_row = i - 1
        local hl_end_row   = i - 1
        local hl_start_col = atom_start_col + offset
        local hl_end_col   = atom_end_col + offset

        api.nvim_buf_set_extmark(bufnr, ns,
          hl_start_row, hl_start_col,
          { end_line = hl_end_row, end_col = hl_end_col,
            hl_group = hl })
      end
    end
  end
end

function M.enable()
  local throttle = config.throttle and 'throttled_' or ''
  nvim_augroup('treesitter_context', {
    {'WinScrolled', '*',                   'silent lua require("treesitter-context").' .. throttle .. 'update_context()'},
    {'BufEnter',    '*',                   'silent lua require("treesitter-context").' .. throttle .. 'update_context()'},
    {'WinEnter',    '*',                   'silent lua require("treesitter-context").' .. throttle .. 'update_context()'},
    {'User',        'CursorMovedVertical', 'silent lua require("treesitter-context").' .. throttle .. 'update_context()'},
    {'CursorMoved', '*',                   'silent lua require("treesitter-context").do_au_cursor_moved_vertical()'},
    {'WinLeave',    '*',                   'silent lua require("treesitter-context").close()'},
    {'VimResized',  '*',                   'silent lua require("treesitter-context").open()'},
    {'User',        'SessionSavePre',      'silent lua require("treesitter-context").close()'},
    {'User',        'SessionSavePost',     'silent lua require("treesitter-context").open()'},
  })

  M.throttled_update_context()
  enabled = true
end

function M.disable()
  nvim_augroup('treesitter_context', {})

  M.close()
  enabled = false
end

function M.toggleEnabled()
    if enabled then
        M.disable()
    else
        M.enable()
    end
end

-- Setup

function M.setup(options)
  config = vim.tbl_deep_extend("force", {}, defaultConfig, options or {})

  if config.enable then
    M.enable()
  else
    M.disable()
  end
end

M.setup()

api.nvim_command('command! TSContextEnable  lua require("treesitter-context").enable()')
api.nvim_command('command! TSContextDisable lua require("treesitter-context").disable()')
api.nvim_command('command! TSContextToggle  lua require("treesitter-context").toggleEnabled()')
api.nvim_command('highlight default link TreesitterContext NormalFloat')

return M
