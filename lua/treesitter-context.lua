local api = vim.api

local config = require('treesitter-context.config')

local augroup = api.nvim_create_augroup
local command = api.nvim_create_user_command

local enabled = false

--- @type table<integer, Range4[]>
local all_contexts = {}

--- @type table<integer, boolean>
local win_update_scheduled = {}

local attached = {} --- @type table<integer,true>

local function close()
  require('treesitter-context.render').close()
end

---@param bufnr integer
---@param winid integer
local function can_open(bufnr, winid)
  if not attached[bufnr] then
    return false
  end

  if vim.bo[bufnr].filetype == '' then
    return false
  end

  if vim.bo[bufnr].buftype ~= '' then
    return false
  end

  if vim.wo[winid].previewwindow then
    return false
  end

  if vim.fn.getcmdtype() ~= '' then
    return false
  end

  if api.nvim_win_get_height(winid) < config.min_window_height then
    return false
  end

  return true
end

---@param winid integer
local function update_single_context(winid)
  -- Since the update is performed asynchronously, the window may be closed at this moment.
  -- Therefore, we need to check if it is still valid.
  if not api.nvim_win_is_valid(winid) then
    return
  end

  local bufnr = api.nvim_win_get_buf(winid)

  if not can_open(bufnr, winid) then
    close()
    return
  end

  local context_ranges, context_lines = require('treesitter-context.context').get(bufnr, winid)
  all_contexts[bufnr] = context_ranges

  if not context_ranges or #context_ranges == 0 then
    close()
    return
  end

  assert(context_lines)

  require('treesitter-context.render').open(bufnr, winid, context_ranges, context_lines)
end

---@param winid integer
local function schedule_context_update(winid)
  if not win_update_scheduled[winid] then
    win_update_scheduled[winid] = true
    vim.schedule(function()
      win_update_scheduled[winid] = nil
      update_single_context(winid)
    end)
  end
end

local function update()
  schedule_context_update(api.nvim_get_current_win())
end

local M = {
  config = config,
}

local group = augroup('treesitter_context_update', {})

---@param event string|string[]
---@param callback fun(args: table)
---@param opts? vim.api.keyset.create_autocmd
local function autocmd(event, callback, opts)
  opts = opts or {}
  opts.callback = callback
  opts.group = group
  api.nvim_create_autocmd(event, opts)
end

function M.enable()
  local cbuf = api.nvim_get_current_buf()

  attached[cbuf] = true

  autocmd({ 'WinScrolled', 'BufEnter', 'WinEnter', 'VimResized' }, update)

  autocmd('BufReadPost', function(args)
    attached[args.buf] = nil
    if not config.on_attach or config.on_attach(args.buf) ~= false then
      attached[args.buf] = true
    end
  end)

  autocmd('BufDelete', function(args)
    attached[args.buf] = nil
  end)

  autocmd('CursorMoved', update)

  autocmd('OptionSet', function(args)
    if args.match == 'number' or args.match == 'relativenumber' then
      update()
    end
  end)

  autocmd({ 'BufLeave', 'WinLeave' }, close)

  autocmd('User', close, { pattern = 'SessionSavePre' })
  autocmd('User', update, { pattern = 'SessionSavePost' })

  update_single_context(api.nvim_get_current_win())
  enabled = true
end

function M.disable()
  augroup('treesitter_context_update', {})
  attached = {}
  close()
  enabled = false
end

function M.toggle()
  if enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.enabled()
  return enabled
end

local function init()
  command('TSContextEnable', M.enable, {})
  command('TSContextDisable', M.disable, {})
  command('TSContextToggle', M.toggle, {})

  api.nvim_set_hl(0, 'TreesitterContext', { link = 'NormalFloat', default = true })
  api.nvim_set_hl(0, 'TreesitterContextLineNumber', { link = 'LineNr', default = true })
  api.nvim_set_hl(0, 'TreesitterContextBottom', { link = 'NONE', default = true })
  api.nvim_set_hl(0, 'TreesitterContextLineNumberBottom', { link = 'TreesitterContextBottom', default = true })
  api.nvim_set_hl(0, 'TreesitterContextSeparator', { link = 'FloatBorder', default = true })
end

local did_init = false

---@param options? TSContext.UserConfig
function M.setup(options)
  if options then
    config.update(options)
  end

  if config.enable then
    M.enable()
  else
    M.disable()
  end

  if not did_init then
    init()
    did_init = true
  end
end

---@param depth integer? default 1
function M.go_to_context(depth)
  depth = depth or 1
  local line = api.nvim_win_get_cursor(0)[1]
  local context = nil
  local bufnr = api.nvim_get_current_buf()
  local contexts = all_contexts[bufnr] or {}

  for idx = #contexts, 1, -1 do
    local c = contexts[idx]
    if depth == 0 then
      break
    end
    if c[1] + 1 < line then
      context = c
      depth = depth - 1
    end
  end

  if context == nil then
    return
  end

  vim.cmd([[ normal! m' ]]) -- add current cursor position to the jump list
  api.nvim_win_set_cursor(0, { context[1] + 1, context[2] })
end

return M
