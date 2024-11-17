local api = vim.api

local config = require('treesitter-context.config')

local augroup = api.nvim_create_augroup
local command = api.nvim_create_user_command

local enabled = false

--- @type table<integer, Range4[]>
local all_contexts = {}

--- @generic F: function
--- @param f F
--- @param ms? number
--- @return F
local function throttle_by_id(f, ms)
  ms = ms or 200
  local timers = {} --- @type table<any,uv.uv_timer_t>
  local waiting = {} --- @type table<any,boolean>
  return function(id)
    if timers[id] == nil then
      timers[id] = assert(vim.loop.new_timer())
    else
      waiting[id] = true
      return
    end

    f(id) -- first call, execute immediately
    timers[id]:start(ms, 0, function()
      if waiting[id] then
        vim.schedule(function() f(id) end) -- only execute if there are calls waiting
      end
      waiting[id] = nil
      timers[id] = nil
    end)
  end
end

local attached = {} --- @type table<integer,true>

local function close(args)
  local render = require('treesitter-context.render')
  if args.event == "WinClosed" then
    -- Closing current window instead of intended window may lead to context window flickering.
    render.close(tonumber(args.match))
  else
    render.close(api.nvim_get_current_win())
  end
end

local function close_all()
  -- We can't close only certain windows based on the config because it might have changed.
  local render = require('treesitter-context.render')
  for _, winid in pairs(api.nvim_list_wins()) do
    render.close(winid)
  end
end

---@param bufnr integer
---@param winid integer
local function cannot_open(bufnr, winid)
  return not attached[bufnr]
    or vim.bo[bufnr].filetype == ''
    or vim.bo[bufnr].buftype ~= ''
    or vim.wo[winid].previewwindow
    or api.nvim_win_get_height(winid) < config.min_window_height
end

---@param winid integer
local update_single_context = throttle_by_id(function(winid)
  -- Remove leaked contexts firstly.
  local current_win = api.nvim_get_current_win()
  if config.multiwindow then
    require('treesitter-context.render').close_leaked_contexts()
  else
    require('treesitter-context.render').close_other_contexts(current_win)
  end

  -- Since the update is performed asynchronously, the window may be closed at this moment.
  -- Therefore, we need to check if it is still valid.
  if not api.nvim_win_is_valid(winid) or vim.fn.getcmdtype() ~= '' then
    return
  end

  local bufnr = api.nvim_win_get_buf(winid)

  if cannot_open(bufnr, winid) or not config.multiwindow and winid ~= current_win then
    require('treesitter-context.render').close(winid)
    return
  end

  local context_ranges, context_lines = require('treesitter-context.context').get(bufnr, winid)
  all_contexts[bufnr] = context_ranges

  if not context_ranges or #context_ranges == 0 then
    require('treesitter-context.render').close(winid)
    return
  end

  assert(context_lines)

  require('treesitter-context.render').open(bufnr, winid, context_ranges, context_lines)
end)

---@param args table
local function update(args)
  if args.event == "OptionSet" and args.match ~= 'number' and args.match ~= 'relativenumber' then
    return
  end

  local multiwindow_events = { "WinResized", "User" }

  if config.multiwindow and vim.tbl_contains(multiwindow_events, args.event) then
    -- Resizing a single window may cause many resizes in different windows,
    -- so it is necessary to iterate over all windows when a WinResized event is received.
    for _, winid in pairs(api.nvim_list_wins()) do
      update_single_context(winid)
    end
  else
    update_single_context(api.nvim_get_current_win())
  end
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

--- @param bufnr integer
--- @return boolean?
local function should_attach(bufnr)
  if not config.on_attach or config.on_attach(bufnr) ~= false then
    return true
  end
  return nil
end

function M.enable()
  if enabled then
    -- Some options may have changed.
    -- We need to reload all contexts and clear autocommands first.
    M.disable()
  end

  -- Restore attached table after reloading.
  for _, bufnr in pairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(bufnr) then
      attached[bufnr] = should_attach(bufnr)
    end
  end

  local update_events = {
    'WinScrolled',
    'BufEnter',
    'WinEnter',
    'VimResized',
    'DiagnosticChanged',
    'CursorMoved',
    'OptionSet',
  }

  if config.multiwindow then
    table.insert(update_events, 'WinResized')
    table.insert(update_events, 'WinLeave')
  end

  autocmd(update_events, update)

  autocmd('BufReadPost', function(args)
    attached[args.buf] = should_attach(args.buf)
  end)

  autocmd('BufDelete', function(args)
    attached[args.buf] = nil
  end)

  if config.multiwindow then
    autocmd({ 'WinClosed' }, close)
  else
    autocmd({ 'BufLeave', 'WinLeave', 'WinClosed' }, close)
  end

  autocmd('User', close, { pattern = 'SessionSavePre' })
  autocmd('User', update, { pattern = 'SessionSavePost' })

  if config.multiwindow then
    for _, winid in pairs(api.nvim_list_wins()) do
      update_single_context(winid)
    end
  else
    update_single_context(api.nvim_get_current_win())
  end

  enabled = true
end

function M.disable()
  augroup('treesitter_context_update', {})
  attached = {}
  close_all()
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
  -- NB: setup  may be called several times.
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
