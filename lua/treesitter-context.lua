local api = vim.api

local config = require('treesitter-context.config')

local augroup = api.nvim_create_augroup
local command = api.nvim_create_user_command

local enabled = false

local function defer_require(mod)
  local t --- @type table
  t = setmetatable({}, {
    __index = function(_, key)
      --- @diagnostic disable-next-line: no-unknown
      t = require(mod)
      -- print(debug.traceback('deferred require ' .. mod))
      return t[key]
    end,
  })
  return t
end

--- @module 'treesitter-context.render'
local Render = defer_require('treesitter-context.render')

--- @type table<integer, Range4[]>
local all_contexts = {}

--- Schedule a function to run on the next event loop iteration.
--- If the function is called again within 150ms, it will be scheduled
--- again to run on the next event loop iteration. This means that
--- the function will run at most twice every 150ms.
--- @generic F: function
--- @param f F
--- @return F
local function throttle_by_id(f)
  local timers = {} --- @type table<any,uv.uv_timer_t>
  local scheduled = {} --- @type table<any,true?>
  local waiting = {} --- @type table<any,boolean>

  local function r(id)
    if not scheduled[id] then
      scheduled[id] = true
      vim.schedule(function()
        -- Start a timer to check if the function needs to run again
        -- after the throttling period.
        timers[id] = timers[id] or assert(vim.loop.new_timer())
        timers[id]:start(150, 0, function()
          scheduled[id] = nil
          if waiting[id] then
            -- r was called again within throttling period; reschedule it.
            waiting[id] = nil
            r(id)
          else
            -- Done - clean up
            timers[id] = nil
          end
        end)

        f(id)
      end)
    elseif timers[id] and timers[id]:get_due_in() > 0 then
      -- Only set waiting if the throttle timer is running as that means the
      -- function is about to start.
      -- Consequently, there is no need to run it again after throttling is completed.
      waiting[id] = true
    end
  end

  return r
end

local attached = {} --- @type table<integer,true>

--- @param args table
local function au_close(args)
  if args.event == 'WinClosed' then
    -- Closing current window instead of intended window may lead to context window flickering.
    Render.close(tonumber(args.match))
  else
    Render.close(api.nvim_get_current_win())
  end
end

--- @param bufnr integer
--- @param winid integer
local function cannot_open(bufnr, winid)
  return not attached[bufnr]
    or vim.bo[bufnr].filetype == ''
    or vim.bo[bufnr].buftype ~= ''
    or vim.wo[winid].previewwindow
    or api.nvim_win_get_height(winid) < config.min_window_height
end

--- @param winid integer
local update_single_context = throttle_by_id(function(winid)
  -- Remove leaked contexts firstly.
  local current_win = api.nvim_get_current_win()
  if config.multiwindow then
    Render.close_leaked_contexts()
  else
    Render.close_other_contexts(current_win)
  end

  -- Since the update is performed asynchronously, the window may be closed at this moment.
  -- Therefore, we need to check if it is still valid.
  if not api.nvim_win_is_valid(winid) or vim.fn.getcmdtype() ~= '' then
    return
  end

  local bufnr = api.nvim_win_get_buf(winid)

  if cannot_open(bufnr, winid) or not config.multiwindow and winid ~= current_win then
    Render.close(winid)
    return
  end

  local context_ranges, context_lines = require('treesitter-context.context').get(bufnr, winid)
  all_contexts[bufnr] = context_ranges

  if not context_ranges or #context_ranges == 0 then
    Render.close(winid)
    return
  end

  Render.open(bufnr, winid, context_ranges, assert(context_lines))
end)

local multiwindow_events = {
  WinResized = true,
  User = true,
}

--- @param event? string
local function update(event)
  if config.multiwindow and multiwindow_events[event] then
    -- Resizing a single window may cause many resizes in different windows,
    -- so it is necessary to iterate over all windows when a WinResized event is received.
    for _, winid in pairs(api.nvim_list_wins()) do
      update_single_context(winid)
    end
  else
    update_single_context(api.nvim_get_current_win())
  end
end

--- @param args table
local function au_update(args)
  if args.event == 'OptionSet' and args.match ~= 'number' and args.match ~= 'relativenumber' then
    return
  end

  update(args.event)
end

local M = {
  config = config,
}

local group = augroup('treesitter_context_update', {})

-- TODO(lewis6991): When nvim 0.11 is released use:
---- @param callback fun(args: vim.api.keyset.create_autocmd.callback_args):boolean?

--- @param event string|string[]
--- @param callback fun(args: table):boolean?
--- @param opts? vim.api.keyset.create_autocmd
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

--- @param req { type:string, method: string }
--- @return boolean
local function is_semantic_tokens_request(req)
  local ms = require('vim.lsp.protocol').Methods
  return req.type == 'complete'
    and (
      req.method == ms.textDocument_semanticTokens_full
      or req.method == ms.textDocument_semanticTokens_full_delta
      or req.method == ms.textDocument_semanticTokens_range
    )
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

  autocmd({
    'WinScrolled',
    'BufEnter',
    'WinEnter',
    'VimResized',
    'CursorMoved',
    'OptionSet',
    'WinResized',
  }, au_update)

  autocmd('DiagnosticChanged', vim.schedule_wrap(au_update))

  autocmd('BufReadPost', function(args)
    attached[args.buf] = should_attach(args.buf)
  end)

  autocmd('BufDelete', function(args)
    attached[args.buf] = nil
  end)

  if config.multiwindow then
    autocmd({ 'WinClosed' }, au_close)
  else
    autocmd({ 'BufLeave', 'WinLeave', 'WinClosed' }, au_close)
  end

  autocmd('User', au_close, { pattern = 'SessionSavePre' })
  autocmd('User', au_update, { pattern = 'SessionSavePost' })

  if vim.fn.has('nvim-0.10') == 1 then
    autocmd('LspRequest', function(args)
      if is_semantic_tokens_request(args.data.request) then
        vim.schedule(function()
          au_update(args)
        end)
      end
    end)
  end

  update()

  enabled = true
end

function M.disable()
  augroup('treesitter_context_update', {})
  -- We can't close only certain windows based on the config because it might have changed.
  for _, winid in pairs(api.nvim_list_wins()) do
    Render.close(winid)
  end
  attached = {}
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
  api.nvim_set_hl(
    0,
    'TreesitterContextLineNumberBottom',
    { link = 'TreesitterContextBottom', default = true }
  )
  api.nvim_set_hl(0, 'TreesitterContextSeparator', { link = 'FloatBorder', default = true })
end

local did_init = false

--- @param options? TSContext.UserConfig
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

--- @param depth integer? default 1
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
