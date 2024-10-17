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

local function close()
  require('treesitter-context.render').close(api.nvim_get_current_win())
end

---@param bufnr integer
---@param winid integer
local function cannot_open(bufnr, winid)
  return not attached[bufnr]
    or vim.bo[bufnr].filetype == ''
    or vim.bo[bufnr].buftype ~= ''
    or vim.wo[winid].previewwindow
    or vim.fn.getcmdtype() ~= ''
    or api.nvim_win_get_height(winid) < config.min_window_height
end

---@param winid integer
local update_single_context = throttle_by_id(function(winid)
  -- Since the update is performed asynchronously, the window may be closed at this moment.
  -- Therefore, we need to check if it is still valid.
  if not api.nvim_win_is_valid(winid) then
    return
  end

  local bufnr = api.nvim_win_get_buf(winid)

  if cannot_open(bufnr, winid) or winid ~= api.nvim_get_current_win() then
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

local function update()
  update_single_context(api.nvim_get_current_win())
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

  autocmd({ 'WinScrolled', 'BufEnter', 'WinEnter', 'VimResized', 'DiagnosticChanged' }, update)

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

  update()
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
