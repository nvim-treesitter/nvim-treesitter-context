
local api = vim.api
local ts = vim.treesitter
local Highlighter = ts.highlighter
local ts_utils = require'nvim-treesitter.ts_utils'
local parsers = require'nvim-treesitter.parsers'
local utils = require'treesitter-context.utils'
local slice = utils.slice

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

local INDENT_PATTERN = '^%s+'

-- Script variables

local winid = nil
local bufnr = api.nvim_create_buf(false, true)
local ns = api.nvim_create_namespace('nvim-treesitter-context')

local current_type = nil
local current_node = nil
local previous_node = nil



-- Helper functions
local get_target_node = function(node)
  local tree = parsers.get_parser():parse()[1]
  local root = tree:root()
  return root
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

local get_text_for_node = function(node)
  local start_row, start_col = node:start()
  local end_row, end_col     = node:end_()

  local lines = ts_utils.get_node_text(node)

  if start_col ~= 0 then
    lines[1] = api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1]
  end
  start_col = 0

  local filetype = api.nvim_buf_get_option(0, 'filetype')
  local last_type = (last_types[current_type] or {})[filetype]
  local last_position = nil

  if last_type ~= nil then
    for child, field_name in node:iter_children() do
      local type = child:type()

      if type == last_type then
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

  -- api.nvim_command('echom ' .. vim.fn.json_encode({
  --   last_position = last_position,
  --   range = range,
  -- }))

  return lines, range
end

local get_lines_for_node = function(node)
  local start_row = node:start()
  local end_row   = node:end_()
  return api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
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
  -- Note when moving the cursor, we must ensure that the 'curswant' state is
  -- restored (see #11). Functions like 'cursor()' and 'nvim_buf_set_cursor()'
  -- clear this state.
  local saved_cursor = api.nvim_call_function('getcurpos', {})

  api.nvim_call_function('cursor', { 0, 1 })
  local gutter_width = api.nvim_call_function('wincol', {}) - 1

  api.nvim_call_function('setpos', { '.', saved_cursor })
  return gutter_width
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


-- Exports

local M = {}

function M.get_context(opts)
  if not parsers.has_parser() then return nil end
  local options = opts or {}
  local type_patterns = options.type_patterns or {'class', 'function', 'method'}

  local cursor_node = ts_utils.get_node_at_cursor()
  if not cursor_node then return nil end

  local matches = {}
  local expr = cursor_node

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

function M.update_context()
  if api.nvim_get_option('buftype') ~= '' or
      vim.fn.getwinvar(0, '&previewwindow') ~= 0 then
    M.close()
    return
  end

  local context = M.get_context()

  current_type = nil
  current_node = nil

  if context then
    local first_visible_line = api.nvim_call_function('line', { 'w0' })

    for i = #context, 1, -1 do
      local node = context[i][1]
      local type = context[i][2]
      local row = node:start()

      if row < (first_visible_line - 1) then
        current_type = type
        current_node = node
        break
      end
    end
  end

  if current_node then
    M.open()
  else
    M.close()
  end
end

function M.close()
  previous_node = nil

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
  if current_node == nil then return end
  if current_node == previous_node then return end

  previous_node = current_node

  local saved_bufnr = api.nvim_get_current_buf()

  local gutter_width = get_gutter_width()
  local win_width = api.nvim_win_get_width(0) - gutter_width

  if winid == nil or not api.nvim_win_is_valid(winid) then
    winid = api.nvim_open_win(bufnr, false, {
      relative = 'win',
      width = win_width,
      height = 1,
      row = 0,
      col = gutter_width,
      focusable = false,
      style = 'minimal',
    })
  else
    api.nvim_win_set_config(winid, {
      win = api.nvim_get_current_win(),
      relative = 'win',
      width = win_width,
      height = 1,
      row = 0,
      col = gutter_width,
    })
  end

  api.nvim_win_set_option(winid, 'winhl', 'NormalFloat:TreesitterContext')

  -- Set text

  local lines, range = get_text_for_node(current_node)
  local indents = get_indents(lines)

  local start_row = range[1]
  local start_col = range[2]
  local end_row   = range[3]
  local end_col   = range[4]

  local text = merge_lines(lines)
  local target_node = get_target_node(current_node)

  -- api.nvim_command('echom ' .. vim.fn.json_encode({
  --   type = target_node:type(),
  --   text = ts_utils.get_node_text(target_node),
  -- }))

  -- Highlight

  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, {text})

  local start_row_absolute = current_node:start()

  local buf_highlighter = Highlighter.active[saved_bufnr] or nil
  local buf_queries = {}
  if buf_highlighter then
    buf_queries = buf_highlighter._queries
  else
    local current_ft = api.nvim_buf_get_option(0, 'filetype')
    local buffer_ft  = api.nvim_buf_get_option(bufnr, 'filetype')
    if current_ft ~= buffer_ft then
      api.nvim_buf_set_option(bufnr, 'filetype', current_ft)
    end
  end

  for _, buf_query in pairs(buf_queries) do
    if buf_query == nil then break end

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
          for i = 1, intended_start_row do
            offset = offset + #lines[i] - indents[i]
          end
          -- Remove the indentation negative offset for current line
          offset = offset - (indents[intended_start_row + 1])
        end

        local hl_start_row = 0
        local hl_end_row   = 0
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
  nvim_augroup('treesitter_context', {
    {'WinScrolled', '*',               'silent lua require("treesitter-context").update_context()'},
    {'CursorMoved', '*',               'silent lua require("treesitter-context").update_context()'},
    {'BufEnter',    '*',               'silent lua require("treesitter-context").update_context()'},
    {'WinEnter',    '*',               'silent lua require("treesitter-context").update_context()'},
    {'WinLeave',    '*',               'silent lua require("treesitter-context").close()'},
    {'VimResized',  '*',               'silent lua require("treesitter-context").open()'},
    {'User',        'SessionSavePre',  'silent lua require("treesitter-context").close()'},
    {'User',        'SessionSavePost', 'silent lua require("treesitter-context").open()'},
  })

  M.update_context()
end

function M.disable()
  nvim_augroup('treesitter_context', {})

  M.close()
end

-- Setup

M.enable()

api.nvim_command('command! TSContextEnable  lua require("treesitter-context").enable()')
api.nvim_command('command! TSContextDisable lua require("treesitter-context").disable()')
api.nvim_command('highlight default link TreesitterContext NormalFloat')


return M
