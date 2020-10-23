
local vim = vim
local api = vim.api
local ts = vim.treesitter
local Highlighter = ts.highlighter
local ts_utils = require'nvim-treesitter.ts_utils'
local parsers = require'nvim-treesitter.parsers'

-- Script variables

local winid = nil
local bufnr = api.nvim_create_buf(false, true)
local ns = api.nvim_create_namespace('nvim-treesitter-context')
local current_node = nil


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

-- Trim spaces and opening brackets from end
local transform_line = function(line)
  return line:gsub('%s*[%[%(%{]*%s*$', ''):gsub('\n', '')
end

local get_gutter_width = function()
  local width = api.nvim_win_get_width(0)
  local number_width = math.max(
    api.nvim_win_get_option(0, 'numberwidth'),
    #tostring(api.nvim_call_function('line', { '$' })) + 1
  )
  local number = api.nvim_win_get_option(0, 'number')
  local relative_number = api.nvim_win_get_option(0, 'relativenumber')
  number_width = (number or relative_number) and number_width or 0
  local fold_width = api.nvim_win_get_option(0, 'foldcolumn')

  local sign_width = 0

  local sign_column = api.nvim_win_get_option(0, 'signcolumn')

  if sign_column == 'yes' then
    sign_width = 2
  elseif sign_column == 'auto' then
    local signs = api.nvim_call_function('execute', {
      'sign place buffer=' .. api.nvim_get_current_buf(),
    })
    local signs = vim.split(signs, '\n', true)
    sign_width = #signs > 2 and 2 or 0
  else
    sign_width = 0
  end

  return number_width + fold_width + sign_width
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
  local transform_fn = options.transform_fn or transform_line
  local separator = options.separator or ' -> '

  local current_node = ts_utils.get_node_at_cursor()
  if not current_node then return nil end

  local matches = {}
  local expr = current_node

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

function M.update_context()
  if api.nvim_get_option('buftype') ~= '' or
      vim.fn.getwinvar(0, '&previewwindow') ~= 0 then
    M.close()
    return
  end

  local context = M.get_context()

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

  return { winid, get_gutter_width(), context }
end

function M.close()
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

  local saved_bufnr = api.nvim_get_current_buf()
  local start_row = current_node:start()
  local end_row   = current_node:end_()

  local gutter_width = get_gutter_width()
  local win_width = api.nvim_win_get_width(0) - gutter_width

  if win_width <= 0 then
    return
  end

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
  local lines =
    start_col == 0
      and vim.split(get_text_for_node(current_node), '\n')
      or  get_lines_for_node(current_node)
  local target_node =
    start_col == 0
      and current_node
      or  current_node:parent()

  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  local start_row_absolute = current_node:start()

  for _, highlighter in pairs(Highlighter.active[saved_bufnr] or {}) do
    local iter = highlighter.query:iter_captures(target_node, saved_bufnr, start_row, end_row)
    for capture, node in iter do

      local start_row, start_col, end_row, end_col = node:range()
      local hl = highlighter.hl_cache[capture]

      if start_row >= start_row_absolute then

        start_row = start_row - start_row_absolute
        end_row   = end_row   - start_row_absolute

        -- Sometimes there is an error :/
        -- but we ignore it :)
        -- Yay?
        local ok, err = pcall(function()
          api.nvim_buf_set_extmark(bufnr, ns, start_row, start_col,
                                { end_line = end_row, end_col = end_col,
                                  hl_group = hl,
                                  -- ephemeral = true
                                  })
        end)
      end
    end
  end
end

function M.enable()
  nvim_augroup('treesitter_context', {
    {'Scroll',      '*',               'silent lua require("treesitter-context").update_context()'},
    {'CursorMoved', '*',               'silent lua require("treesitter-context").update_context()'},
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


return M
