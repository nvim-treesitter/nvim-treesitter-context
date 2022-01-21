local vim_fn = vim.fn
local vim_api = vim.api
local ts_utils = require'nvim-treesitter.ts_utils'
local Highlighter = vim.treesitter.highlighter
-- local ts_query = require('nvim-treesitter.query')
local parsers = require'nvim-treesitter.parsers'
local utils = require'treesitter-context.utils'
local slice = utils.slice
local word_pattern = utils.word_pattern

local defaultConfig = {
  enable = true,
  throttle = false,
  max_lines = 0, -- no limit
}

local config = {}

local has_textoff = vim_fn.has('nvim-0.6')

local ffi = nil
if not has_textoff then
  ffi = require("ffi")
  ffi.cdef'int curwin_col_off(void);'
end

-- Constants

-- Tells us at which node type to stop when highlighting a multi-line
-- node. If not specified, the highlighting stops after the first line.
local last_types = {
  [word_pattern('function')] = {
    c = 'function_declarator',
    cpp = 'function_declarator',
    lua = 'parameters',
    python = 'parameters',
    rust = 'parameters',
    javascript = 'formal_parameters',
    typescript = 'formal_parameters',
  },
}

-- Tells us which leading child node type to skip when highlighting a
-- multi-line node.
local skip_leading_types = {
  [word_pattern('class')] = {
    php = 'attribute_list',
  },
  [word_pattern('method')] = {
    php = 'attribute_list',
  },
}

-- There are language-specific
local DEFAULT_TYPE_PATTERNS = {
  -- These catch most generic groups, eg "function_declaration" or "function_block"
  default = {
    'class',
    'function',
    'method',
    'for',
    'while',
    'if',
    'switch',
    'case',
  },
  rust = {
    'impl_item',
  },
  vhdl = {
    'process_statement',
    'architecture_body',
    'entity_declaration',
  },
  exact_patterns = {},
}
local INDENT_PATTERN = '^%s+'

-- Script variables

local didSetup = false
local enabled = nil
local context_win_id = nil
local _context_buf_nr = nil -- Don't access directly, use get_context_buf_nr()
local ns = vim_api.nvim_create_namespace('nvim-treesitter-context')
local context_nodes = {}
local context_types = {}
local previous_nodes = nil


-- Helper functions
local log_message = function(value)
  vim_api.nvim_command('echom ' .. vim_fn.json_encode(value))
end

local get_target_node = function()
  local tree = parsers.get_parser():parse()[1]
  return tree:root()
end

local is_valid = function(node, filetype)
  local node_type = node:type()
  for _, rgx in ipairs(config.patterns.default) do
    if node_type:find(rgx) then
      return true, rgx
    end
  end
  local filetype_patterns = config.patterns[filetype]
  if filetype_patterns ~= nil then
    for _, rgx in ipairs(filetype_patterns) do
      if node_type:find(rgx) then
        return true, rgx
      end
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

local function find_node(node, type)
  local children = ts_utils.get_named_children(node)
  for _, child in ipairs(children) do
    if child:type() == type then
      return child
    end
  end
  for _, child in ipairs(children) do
    local deep_child = find_node(child, type)
    if deep_child ~= nil then
      return deep_child
    end
  end
  return nil
end

local get_text_for_node = function(node)
  local type = get_type_pattern(node, config.patterns.default) or node:type()
  local filetype = vim_api.nvim_buf_get_option(0, 'filetype')

  local skip_leading_type = (skip_leading_types[type] or {})[filetype]
  if skip_leading_type then
    local children = ts_utils.get_named_children(node)
    for _, child in ipairs(children) do
      if child:type() ~= skip_leading_type then
        node = child
        break
      end
    end
  end

  local start_row, start_col = node:start()
  local end_row, end_col     = node:end_()

  local lines = ts_utils.get_node_text(node)

  if start_col ~= 0 then
    lines[1] = vim_api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1]
  end
  start_col = 0

  local last_type = (last_types[type] or {})[filetype]
  local last_position = nil

  if last_type ~= nil then
    local child = find_node(node, last_type)

    if child ~= nil then
      last_position = {child:end_()}

      end_row = last_position[1]
      end_col = last_position[2]
      local last_index = end_row - start_row
      lines = slice(lines, 1, last_index + 1)
      lines[#lines] = slice(lines[#lines], 1, end_col)
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
  if not has_textoff then
    return ffi.C.curwin_col_off();
  else
    return vim_fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff
  end
end

local nvim_augroup = function(group_name, definitions)
  vim_api.nvim_command('augroup ' .. group_name)
  vim_api.nvim_command('autocmd!')
  for _, def in ipairs(definitions) do
    local command = table.concat({'autocmd', unpack(def)}, ' ')
    if vim_api.nvim_call_function('exists', {'##' .. def[1]}) ~= 0 then
      vim_api.nvim_command(command)
    end
  end
  vim_api.nvim_command('augroup END')
end

local cursor_moved_vertical
do
  local line
  cursor_moved_vertical = function()
    local newline =  vim_api.nvim_win_get_cursor(0)[1]
    if newline ~= line then
      line = newline
      return true
    end
    return false
  end
end

local function get_context_buf_nr()
  if _context_buf_nr == nil or not vim_api.nvim_buf_is_valid(_context_buf_nr) then
    _context_buf_nr = vim_api.nvim_create_buf(false, true)
  end
  return _context_buf_nr
end

local function delete_buf()
  if _context_buf_nr ~= nil and vim_api.nvim_buf_is_valid(_context_buf_nr) then
    vim_api.nvim_buf_delete(_context_buf_nr, { force = true })
  end
  _context_buf_nr = nil
end

local function display_window(width, height, row, col)
  if context_win_id == nil or not vim_api.nvim_win_is_valid(context_win_id) then
    local context_buf_nr = get_context_buf_nr()
    context_win_id = vim_api.nvim_open_win(context_buf_nr, false, {
      relative = 'win',
      width = width,
      height = height,
      row = row,
      col = col,
      focusable = false,
      style = 'minimal',
      noautocmd = true,
    })
    vim_api.nvim_win_set_var(context_win_id, 'treesitter_context', true)
  else
    vim_api.nvim_win_set_config(context_win_id, {
      win = vim_api.nvim_get_current_win(),
      relative = 'win',
      width = width,
      height = height,
      row = row,
      col = col,
    })
  end
  vim_api.nvim_win_set_option(context_win_id, 'winhl', 'NormalFloat:TreesitterContext')
end

-- Exports

local M = {
  config = config,
}

function M.do_au_cursor_moved_vertical()
  if cursor_moved_vertical() then
    vim.cmd [[doautocmd <nomodeline> User CursorMovedVertical]]
  end
end

function M.get_context(opts)
  if not parsers.has_parser() then return nil end
  local options = opts or {}

  local cursor_node = ts_utils.get_node_at_cursor()
  if not cursor_node then return nil end

  local matches = {}
  local expr = cursor_node

  local filetype = vim_api.nvim_buf_get_option(0, 'filetype')
  while expr do
    local is_match, type = is_valid(expr, filetype)
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

local function range_contains_range(
  outer_start_line, outer_start_col, outer_end_line, outer_end_col,
  inner_start_line, inner_start_col, inner_end_line, inner_end_col
)
  local start_fits = outer_start_line < inner_start_line or
      (outer_start_line == inner_start_line and outer_start_col <= inner_start_col)
  local end_fits = inner_end_line < outer_end_line or
      (inner_end_line == outer_end_line and inner_end_col <= outer_end_col)

  return start_fits and end_fits
end

local function node_range_contains_range(node, start_line, start_col, end_line, end_col)
  local node_start_line, node_start_col, node_end_line, node_end_col = node:range()
  return range_contains_range(node_start_line, node_start_col, node_end_line, node_end_col,
      start_line, start_col, end_line, end_col)
end

local function range_contains_node_range(start_line, start_col, end_line, end_col, node)
  return range_contains_range(start_line, start_col, end_line, end_col, node:range())
end

local function get_lang_tree_for_range(start_line, start_col, end_line, end_col, root_lang_tree)
  if end_line == nil then end_line = start_line end
  if end_col == nil then end_col = start_col end
  if root_lang_tree == nil then
    if not parsers.has_parser() then return end
    root_lang_tree = parsers.get_parser()
  end
  return root_lang_tree:language_for_range({start_line, start_col, end_line, end_col})
end

local function get_root_for_range(start_line, start_col, end_line, end_col, root_lang_tree)
  local lang_tree =
    get_lang_tree_for_range(start_line, start_col, end_line, end_col, root_lang_tree)
  for _, tree in ipairs(lang_tree:trees()) do
    local root = tree:root()
    if root and node_range_contains_range(root, start_line, start_col, end_line, end_col) then
      return root, tree, lang_tree
    end
  end
  -- This isn't a likely scenario, since the range must belong to a tree somewhere.
  return nil, nil, lang_tree, start_line, start_col, end_line, end_col
end

local function get_node_for_range(start_line, start_col, end_line, end_col, root_lang_tree)
  if end_line == nil then end_line = start_line end
  if end_col == nil then end_col = start_col end
  local root, tree, lang_tree =
    get_root_for_range(start_line, start_col, end_line, end_col, root_lang_tree)
  if not root then return end
  return root:named_descendant_for_range(start_line, start_col, end_line, end_col)
end

local function get_pos_for_pos_expr(pos_expr)
  local curpos = vim_fn.getpos(pos_expr)
  -- buf_num, l_num, col, off
  return curpos[1], curpos[2], curpos[3], curpos[4]
end
M.get_pos_for_pos_expr = get_pos_for_pos_expr

local function get_position_for_pos_expr(pos_expr)
  if expr == nil then expr = '.' end
  local buf_num, l_num, col, off = get_pos_for_pos_expr(pos_expr)
  return l_num - 1, col - 1 + off, buf_num
end
M.get_position_for_pos_expr = get_position_for_pos_expr

local function get_range_for_pos_exprs(start_pos_expr, end_pos_expr, is_selection)
  if is_selection == nil then
    is_selection = start_pos_expr == nil and end_pos_expr == nil
  end
  if start_pos_expr == nil then
    start_pos_expr = is_selection and 'v' or '.'
  end
  local start_line, start_col, start_buf_num = get_position_for_pos_expr(start_pos_expr)
  local end_line, end_col, end_buf_num
  if end_pos_expr == nil and not is_selection then
    end_line, end_col, end_buf_num = start_line, start_col, start_buf_num
  else
    if end_pos_expr == nil then end_pos_expr = '.' end
    end_line, end_col, end_buf_num = get_position_for_pos_expr(end_pos_expr)
    if is_selection and end_pos_expr == '.' then
      local mode = vim_fn.mode()
      if mode == 'V' then
        if start_pos_expr == 'v' then
          start_col = 0
        end
        end_col = 2^31 - 2
      end
    end
  end
  return start_line, start_col, end_line, end_col, start_buf_num, end_buf_num
end
M.get_range_for_pos_exprs = get_range_for_pos_exprs

local function get_node_for_pos_exprs(start_pos_expr, end_pos_expr, is_selection, root_lang_tree)
  local start_line, start_col, end_line, end_col, start_buf_num, end_buf_num =
    get_range_for_pos_exprs(start_pos_expr, end_pos_expr, is_selection)
  if start_buf_num ~= end_buf_num then return end
  return get_node_for_range(start_line, start_col, end_line, end_col, root_lang_tree), start_buf_num
end
M.get_node_for_pos_exprs = get_node_for_pos_exprs

local function get_cursor_position(win_id)
  if win_id == nil then win_id = 0 end
  local cursor = vim_api.nvim_win_get_cursor(win_id)
  return cursor[1] - 1, cursor[2]
end
local function get_line_for_line_expr(line_expr, win_id)
  if win_id == nil then
    return vim_fn.line(line_expr) - 1
  end
  return vim_fn.line(line_expr, win_id) - 1
end
M.get_line_for_line_expr = get_line_for_line_expr
local function get_length_for_line(line, buf_id)
  if buf_id == nil or buf_id == 0 then
    return vim_fn.col({line + 1, '$'}) - 1
  end
  return #vim_api.nvim_buf_get_lines(buf_id, line, line + 1, false)[1]
end
M.get_length_for_line = get_length_for_line

function M.get_parent_matches()
  if not parsers.has_parser() then return nil end

  -- FIXME: use TS queries when possible
  -- local matches = ts_query.get_capture_matches(0, '@scope.node', 'locals')

  local first_context_win_line = get_line_for_line_expr('w0')
  local last_context_win_line = first_context_win_line - 1
  local cursor_line = get_cursor_position()
  local max_last_context_win_line = cursor_line - 1
  if config.max_lines > 0 and last_context_win_line + config.max_lines < max_last_context_win_line then
    max_last_context_win_line = last_context_win_line + config.max_lines
  end
  local filetype = vim_api.nvim_buf_get_option(0, 'filetype')

  -- print(string.format('context: first_context_win_line %d, max_last_context_win_line %d',
  --     first_context_win_line, max_last_context_win_line))
  local parent_matches = {}
  local start_line, start_col = first_context_win_line, 0
  while start_line <= max_last_context_win_line + 1 do
    local retry_lines = false

    last_context_win_line = first_context_win_line - 1
    local end_line, end_col = start_line, get_length_for_line(start_line)
    -- print(string.format('context:   start_line %d, end_line %d', start_line, end_line))
    local current = get_node_for_range(start_line, start_col, end_line, end_col)
    if not current then break end

    parent_matches = {}
    local previous_start_line = start_line
    while current ~= nil do
      local current_start_line = current:start()
      -- local current_end_line = current:end_()

      local is_current_valid = is_valid(current, filetype)
      -- print(string.format('context:     testing previous_start_line %d, current_start_line %d, current_end_line %d, last_context_win_line %d, %s%s',
      --   previous_start_line, current_start_line, current_end_line, last_context_win_line, current:type(), is_current_valid and ' (valid)' or ''))
      if is_current_valid and current_start_line < previous_start_line then
        last_context_win_line = last_context_win_line + 1
        if last_context_win_line >= start_line then
          -- print(string.format('context:       retry_lines from last_context_win_line >= start_line'))
          retry_lines = true
          start_line = last_context_win_line + 1
          break
        end
        table.insert(parent_matches, current)
        previous_start_line = current_start_line
        -- print(string.format('context:       new previous_start_line %d', previous_start_line))
      end

      if not retry_lines then
        if last_context_win_line >= max_last_context_win_line then
          -- print(string.format('context:     skipping remaining from last_context_win_line >= max_last_context_win_line'))
          break
        end
        current = current:parent()
      end
    end
    if not retry_lines then break end
  end
  -- print(string.format('context:  last_context_win_line %d, max_last_context_win_line %d',
  --   last_context_win_line, max_last_context_win_line))
  do
    local last_parent_match_ix, first_parent_match_ix = 1, #parent_matches
    while last_parent_match_ix <= first_parent_match_ix do
      local last_parent_match_start_line = parent_matches[last_parent_match_ix]:start()
      -- print(string.format('context:  testing last_parent_match_start_line %d, last_context_win_line %d',
      --   last_parent_match_start_line, last_context_win_line))
      if last_parent_match_start_line == last_context_win_line then
        last_context_win_line = last_context_win_line - 1
        -- print(string.format('context:    trimming parent_match_start_line == last_context_win_line'))
      else
        break
      end
      last_parent_match_ix = last_parent_match_ix + 1
    end
    local parent_matches_reversed = {}
    local i = 1
    for j = first_parent_match_ix, last_parent_match_ix, -1 do
      parent_matches_reversed[i] = parent_matches[j]
      i = i + 1
    end
    parent_matches = parent_matches_reversed
  end
  return parent_matches
end

function M.update_context()
  if vim_api.nvim_get_option('buftype') ~= '' or
      vim_fn.getwinvar(0, '&previewwindow') ~= 0 then
    M.close()
    return
  end

  local context = M.get_parent_matches()

  context_nodes = {}
  context_types = {}

  if context then

    for _, node in ipairs(context) do
      local type = get_type_pattern(node, config.patterns.default) or node:type()

      table.insert(context_nodes, node)
      table.insert(context_types, type)
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

  if context_win_id ~= nil and vim_api.nvim_win_is_valid(context_win_id) then
    -- Can't close other windows when the command-line window is open
    if vim_api.nvim_call_function('getcmdwintype', {}) ~= '' then
      return
    end

    vim_api.nvim_win_close(context_win_id, true)
  end
  context_win_id = nil
end

function M.open()
  if #context_nodes == 0 then return end
  if context_nodes == previous_nodes then return end

  previous_nodes = context_nodes

  local saved_buf_nr = vim_api.nvim_get_current_buf()

  local gutter_width = get_gutter_width()
  local win_width  = math.max(1, vim_api.nvim_win_get_width(0) - gutter_width)
  local win_height = math.max(1, #context_nodes)

  display_window(win_width, win_height, 0, gutter_width)

  -- Set text

  local context_ranges = {}
  local context_lines = {}
  local context_text = {}
  local context_indents = {}

  for i in ipairs(context_nodes) do
    local lines, range = get_text_for_node(context_nodes[i])
    local text = merge_lines(lines)
    local indents = get_indents(lines)
    table.insert(context_lines, lines)
    table.insert(context_ranges, range)
    table.insert(context_text, text)
    table.insert(context_indents, indents)
  end

  local context_buf_nr = get_context_buf_nr()
  vim_api.nvim_buf_set_lines(context_buf_nr, 0, -1, false, context_text)

  -- vim_api.nvim_command('echom ' .. vim_fn.json_encode({
  --   type = target_node:type(),
  --   text = ts_utils.get_node_text(target_node),
  -- }))

  -- Highlight

  vim_api.nvim_buf_clear_namespace(context_buf_nr, ns, 0, -1)

  local buf_highlighter = Highlighter.active[saved_buf_nr] or nil
  local buf_queries = nil
  local buf_query = nil

  if buf_highlighter then
    buf_queries = buf_highlighter._queries
    buf_query = buf_queries[vim.bo.filetype]
    if buf_query == nil then
      return
    end
  else
    local current_ft = vim_api.nvim_buf_get_option(0, 'filetype')
    local buffer_ft  = vim_api.nvim_buf_get_option(context_buf_nr, 'filetype')
    if current_ft ~= buffer_ft then
      vim_api.nvim_buf_set_option(context_buf_nr, 'filetype', current_ft)
    end
    return
  end

  for i in ipairs(context_nodes) do
    local current_node = context_nodes[i]
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
        :iter_captures(target_node, saved_buf_nr, start_row, current_node:end_())

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

        vim_api.nvim_buf_set_extmark(context_buf_nr, ns,
          hl_start_row, hl_start_col,
          { end_line = hl_end_row, end_col = hl_end_col,
            hl_group = hl })
      end
    end
  end
end

function M.enable()
  local throttle = config.throttle and 'throttled_' or ''
  nvim_augroup('treesitter_context_update', {
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
  nvim_augroup('treesitter_context_update', {})
  M.close()
  delete_buf()
  enabled = false
end

function M.toggleEnabled()
    if enabled then
        M.disable()
    else
        M.enable()
    end
end

function M.onVimEnter()
  if didSetup then return end
  -- Setup with default options if user didn't call setup()
  M.setup()
end

-- Setup

function M.setup(options)
  didSetup = true

  local userOptions = options or {}

  config = vim.tbl_deep_extend("force", {}, defaultConfig, userOptions)
  config.patterns =
    vim.tbl_deep_extend("force", {}, DEFAULT_TYPE_PATTERNS, userOptions.patterns or {})
  config.exact_patterns =
    vim.tbl_deep_extend("force", {}, userOptions.exact_patterns or {})

  for filetype, patterns in pairs(config.patterns) do
    -- Map with word_pattern only if users don't need exact pattern matching
    if not config.exact_patterns[filetype] then
        config.patterns[filetype] = vim.tbl_map(word_pattern, patterns)
    end
  end

  if config.enable then
    M.enable()
  else
    M.disable()
  end
end

vim_api.nvim_command('command! -bar TSContextEnable  lua require("treesitter-context").enable()')
vim_api.nvim_command('command! -bar TSContextDisable lua require("treesitter-context").disable()')
vim_api.nvim_command('command! -bar TSContextToggle  lua require("treesitter-context").toggleEnabled()')

vim_api.nvim_command('highlight default link TreesitterContext NormalFloat')

nvim_augroup('treesitter_context', {
  {'VimEnter', '*', 'lua require("treesitter-context").onVimEnter()'},
})
if vim.v.vim_did_enter then
  M.onVimEnter()
end

return M
