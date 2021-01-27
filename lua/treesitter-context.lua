local api = vim.api
local ts_utils = require'nvim-treesitter.ts_utils'
local Highlighter = vim.treesitter.highlighter
local ts_query = require('nvim-treesitter.query')
local ts_highlight = require('nvim-treesitter.highlight')
local parsers = require'nvim-treesitter.parsers'

-- Script variables

local winid = nil
local bufnr = api.nvim_create_buf(false, true)
local ns = api.nvim_create_namespace('nvim-treesitter-context')
local context_nodes = {}
local previous_node = nil

local Pos = {}
Pos.__index = Pos

function Pos.from_node(node)
  local self = setmetatable({}, Pos)

  local start_row, start_col = node:start()
  self.start_row = start_row
  self.start_col = start_col
  self.end_row = start_row + 1
  self.end_col = 0

  return self
end

-- Helper functions

local is_valid = function(node, type_patterns)
  local node_type = node:type()
  for _, rgx in ipairs(type_patterns) do
    if node_type:find(rgx) then
      return true
    end
  end
  return false
end

local get_text_for_node = function(node)
  return ts_utils.get_node_text(node)[1]
end

local function get_text_for_multiple_nodes(nodes)
  return vim.tbl_map(get_text_for_node, nodes)
end

local get_lines_for_node = function(node)
  local start_row = node:start()
  local end_row   = node:end_()
  return api.nvim_buf_get_lines(0, start_row, end_row + 1, false)[1]
end

local function get_lines_for_multiple_nodes(nodes)
  return vim.tbl_map(get_lines_for_node, nodes)
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

local line_changed
do
  local line
  line_changed = function()
    local newline =  vim.api.nvim_win_get_cursor(0)[1]
    if newline ~= line then
      line = newline
      return true
    end
    return false
  end
end

local function highlight_node_from_buf(buf, buf_query, target_node, start_row, start_col, end_row, end_col)
  if buf_query == nil then
    return
  end

  local iter = buf_query:query():iter_captures(target_node, buf, start_row, end_row)

  for capture, node in iter do

    local hl = buf_query.hl_cache[capture]

    local atom_start_row, atom_start_col, atom_end_row, atom_end_col = node:range()

    if atom_end_row >= end_row and atom_end_col >= end_col then
      break
    end

    if atom_start_row >= start_row then

      local hl_start_row = atom_start_row - start_row
      local hl_end_row   = atom_end_row   - start_row
      local hl_start_col = atom_start_col
      local hl_end_col   = atom_end_col

      api.nvim_buf_set_extmark(bufnr, ns, hl_start_row, hl_start_col, {
        end_line = hl_end_row,
        end_col = hl_end_col,
        hl_group = hl
      })
    end
  end
end

function remove_dup(tbl)
  local hash = {}
  local res = {}

  for _,v in ipairs(tbl) do
    if (not hash[v]) then
      res[#res+1] = v
      hash[v] = true
    end
  end

  return res
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
    if is_valid(expr, type_patterns) then
      table.insert(matches, 1, expr)
    end
    expr = expr:parent()
  end

  if #matches == 0 then
    return nil
  end

  return matches
end

function M.get_parent_matches()
  local contains = vim.tbl_contains

  local matches = ts_query.get_capture_matches(0, '@scope.node', 'locals')

  local curr_node = ts_utils.get_node_at_cursor()
  if not curr_node then return end

  local parent_matches = {}
  while true do
    if contains(matches, curr_node) then
      table.insert(parent_matches, curr_node)
    end
    curr_node = curr_node:parent()
    if curr_node == nil then
      break
    end
  end

  return parent_matches
end

function M.update_context()
  if not line_changed() then
    return
  end

  if api.nvim_get_option('buftype') ~= '' or
      vim.fn.getwinvar(0, '&previewwindow') ~= 0 then
    M.close()
    return
  end

  local context = M.get_parent_matches()

  context_nodes = {}

  if context then
    local first_visible_line = api.nvim_call_function('line', { 'w0' })

    for i = #context, 1, -1 do
      local node = context[i]
      local row = node:start()

      if row < (first_visible_line - 1) then
        table.insert(context_nodes, node)
        -- context_nodes = node
        -- break
      end
    end
  end

  if #context_nodes ~= 0 then
    M.open()
  else
    M.close()
  end
end

local async_wrap = function(f)
  local wrapped = function(...)
    local handle
    handle = vim.loop.new_async(vim.schedule_wrap(function(...)
      f(...)
      handle:close()
    end))
    handle:send(...)
  end

  return wrapped
end

do
  local running = false
  local timer

  function M.throttled_update_context()
    if running == false then
      running = true

      vim.defer_fn(async_wrap(function()
        local status, err = pcall(M.update_context)

        if err then
          print('Failed to get context: ' .. err)
        end

        running = false
        if timer then timer:close() end
      end), 500)
    end
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
  if #context_nodes == 0 then
    return
  end

  if context_nodes == previous_node then
    return
  end

  previous_node = context_nodes

  local saved_bufnr = api.nvim_get_current_buf()

  local gutter_width = get_gutter_width()
  local win_width = api.nvim_win_get_width(0) - gutter_width

  local start_row, start_col = context_nodes[1]:start()
  local end_row = start_row + 1
  local end_col = 0

  local lines = get_lines_for_multiple_nodes(context_nodes)
  lines = remove_dup(lines)
  -- local lines =
  --   start_col == 0
  --   and get_text_for_multiple_nodes(context_nodes)
  --   or get_lines_for_multiple_nodes(context_nodes)

  if #lines <= 0 then
    return
  end

  if winid == nil or not api.nvim_win_is_valid(winid) then
    winid = api.nvim_open_win(bufnr, false, {
      relative = 'win',
      width = win_width,
      height = #lines,
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
      height = #lines,
      row = 0,
      col = gutter_width,
    })
  end

  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  local highlight_better = true

  if highlight_better then
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

    local buf_query = buf_queries[vim.bo.filetype]

    for _, target_node in ipairs(context_nodes) do
      highlight_node_from_buf(saved_bufnr, buf_query, target_node, start_row, start_col, end_row, end_col)
    end
  else
    local ft = vim.bo.filetype
    ts_highlight.attach(bufnr, ft)
  end
end

function M.enable()
  nvim_augroup('treesitter_context', {
    {'WinScrolled', '*',               'silent lua require("treesitter-context").throttled_update_context()'},
    {'CursorMoved', '*',               'silent lua require("treesitter-context").throttled_update_context()'},
    {'BufEnter',    '*',               'silent lua require("treesitter-context").throttled_update_context()'},
    {'WinEnter',    '*',               'silent lua require("treesitter-context").throttled_update_context()'},
    {'WinLeave',    '*',               'silent lua require("treesitter-context").close()'},
    {'VimResized',  '*',               'silent lua require("treesitter-context").open()'},
    {'User',        'SessionSavePre',  'silent lua require("treesitter-context").close()'},
    {'User',        'SessionSavePost', 'silent lua require("treesitter-context").open()'},
  })

  M.throttled_update_context()
end

function M.disable()
  nvim_augroup('treesitter_context', {})

  M.close()
end

-- Setup

M.enable()

api.nvim_command('command! TSContextEnable  lua require("treesitter-context").enable()')
api.nvim_command('command! TSContextDisable lua require("treesitter-context").disable()')


return M
