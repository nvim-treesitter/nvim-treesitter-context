
local api = vim.api
local ts = vim.treesitter
local Highlighter = ts.highlighter
local ts_utils = require'nvim-treesitter.ts_utils'
local ts_query = require('nvim-treesitter.query')
local ts_highlight = require('nvim-treesitter.highlight')
local parsers = require'nvim-treesitter.parsers'

-- Script variables

local winid = nil
local bufnr = api.nvim_create_buf(false, true)
local ns = api.nvim_create_namespace('nvim-treesitter-context')
local current_node = nil
local previous_node = nil


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

local get_lines_for_node = function(node)
  local start_row = node:start()
  local end_row   = node:end_()
  return api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
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

function tbl_reverse(tbl)
  for i=1, math.floor(#tbl / 2) do
    tbl[i], tbl[#tbl - i + 1] = tbl[#tbl - i + 1], tbl[i]
  end
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

  tbl_reverse(parent_matches)

  return parent_matches
end

function M.update_context()
  if api.nvim_get_option('buftype') ~= '' or
      vim.fn.getwinvar(0, '&previewwindow') ~= 0 then
    M.close()
    return
  end

  local context = M.get_parent_matches()

  current_node = nil

  if context then
    local first_visible_line = api.nvim_call_function('line', { 'w0' })

    for i = #context, 1, -1 do
      local node = context[i]
      local row = node:start()

      if row < (first_visible_line - 1) then
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

do
  local running = false
  local timer

  function M.throttled_update_context()
    if running == false then
      running = true

      vim.defer_fn(function()
        M.update_context()

        running = false
        if timer then timer:close() end
      end, 500)
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
  if current_node == nil then
    return
  end

  if current_node == previous_node then
    return
  end

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

  local start_row, start_col = current_node:start()
  local end_row = start_row + 1
  local end_col = 0

  local lines =
    start_col == 0
      and vim.split(get_text_for_node(current_node), '\n')
      or  get_lines_for_node(current_node)
  local target_node = current_node

  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  local ft = vim.bo.filetype
  ts_highlight.attach(bufnr, ft)
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
