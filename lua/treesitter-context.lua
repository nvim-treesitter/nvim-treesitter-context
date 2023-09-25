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
local function throttle(f, ms)
  ms = ms or 200
  local timer = assert(vim.loop.new_timer())
  local waiting = 0
  return function()
    if timer:is_active() then
      waiting = waiting + 1
      return
    end
    waiting = 0
    f() -- first call, execute immediately
    timer:start(ms, 0, function()
      if waiting > 1 then
        vim.schedule(f) -- only execute if there are calls waiting
      end
    end)
  end
end

local had_open = false

local function close()
  if had_open then
    require('treesitter-context.render').close()
  end
end

--- @param bufnr integer
--- @param winid integer
--- @param ctx_ranges Range4[]
--- @param ctx_lines string[]
local function open(bufnr, winid, ctx_ranges, ctx_lines)
  had_open = true
  require('treesitter-context.render').open(bufnr, winid, ctx_ranges, ctx_lines)
end

---@param bufnr integer
---@param winid integer
---@return Range4[]?, string[]?
local function get_context(bufnr, winid)
  return require('treesitter-context.context').get(bufnr, winid)
end

local attached = {} --- @type table<integer,true>

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

local update = throttle(function()
  local bufnr = api.nvim_get_current_buf()
  local winid = api.nvim_get_current_win()

  if not can_open(bufnr, winid) then
    close()
    return
  end

  local context, context_lines = get_context(bufnr, winid)
  all_contexts[bufnr] = context

  if not context or #context == 0 then
    close()
    return
  end

  assert(context_lines)

  open(bufnr, winid, context, context_lines)
end)

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

local function init()
  command('TSContextEnable', M.enable, {})
  command('TSContextDisable', M.disable, {})
  command('TSContextToggle', M.toggle, {})

  api.nvim_set_hl(0, 'TreesitterContext', { link = 'NormalFloat', default = true })
  api.nvim_set_hl(0, 'TreesitterContextLineNumber', { link = 'LineNr', default = true })
  api.nvim_set_hl(0, 'TreesitterContextBottom', { link = 'NONE', default = true })
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

function M.go_to_context()
  local line = api.nvim_win_get_cursor(0)[1]
  local context = nil
  local bufnr = api.nvim_get_current_buf()
  local contexts = all_contexts[bufnr] or {}

  for _, v in ipairs(contexts) do
    if v[1] + 1 < line then
      context = v
    end
  end

  if context == nil then
    return
  end

  vim.cmd([[ normal! m' ]]) -- add current cursor position to the jump list
  api.nvim_win_set_cursor(0, { context[1] + 1, context[2] })
end

return M
