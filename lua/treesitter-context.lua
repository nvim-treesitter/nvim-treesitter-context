local fn, api = vim.fn, vim.api
local highlighter = vim.treesitter.highlighter

local cache = require('treesitter-context.cache')

local get_lang = vim.treesitter.language.get_lang or require('nvim-treesitter.parsers').ft_to_lang

--- @diagnostic disable-next-line:deprecated
local get_query = vim.treesitter.query.get or vim.treesitter.query.get_query

local augroup = api.nvim_create_augroup
local command = api.nvim_create_user_command

--- @class TSContext.Config
--- @field enable boolean
--- @field max_lines integer
--- @field min_window_height integer
--- @field line_numbers boolean
--- @field multiline_threshold integer
--- @field trim_scope 'outer'|'inner'
--- @field zindex integer
--- @field mode 'cursor'|'topline'
--- @field separator? string
--- @field on_attach? fun(buf: integer): boolean

--- @type TSContext.Config
local defaultConfig = {
  enable = true,
  max_lines = 0, -- no limit
  min_window_height = 0,
  line_numbers = true,
  multiline_threshold = 20, -- Maximum number of lines to show for a single context
  trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  zindex = 20,
  mode = 'cursor',
}

--- @type TSContext.Config
local config = vim.deepcopy(defaultConfig)

local enabled = false

-- Don't access directly, use get_bufs()
local gutter_bufnr --- @type integer?
local context_bufnr --- @type integer?

local gutter_winid --- @type integer?
local context_winid --- @type integer?

local ns = api.nvim_create_namespace('nvim-treesitter-context')

--- @type TSNode[]?
local previous_context

--- @type table<integer, Range4[]>
local all_contexts = {}

---@param node TSNode
---@return string
local function hash_node(node)
  return table.concat({
    node:id(),
    node:symbol(),
    node:child_count(),
    node:type(),
    node:range(),
  }, ',')
end

--- @param range Range4
--- @return Range4, string[]
local function get_text_for_range(range)
  local start_row, end_row, end_col = range[1], range[3], range[4]

  if end_col == 0 then
    end_row = end_row - 1
    end_col = -1
  end

  local lines = api.nvim_buf_get_text(0, start_row, 0, end_row, -1, {})

  -- Strip any empty lines from the node
  while #lines > 0 do
    local last_line_of_node = lines[#lines]:sub(1, end_col)
    if last_line_of_node:match('%S') and #lines <= config.multiline_threshold then
      break
    end
    lines[#lines] = nil
    end_col = -1
    end_row = end_row - 1
  end

  return { start_row, 0, end_row, -1 }, lines
end

--- Run the context query on a node and return the range if it is a valid
--- context node.
--- @param node TSNode
--- @param query Query
--- @return Range4?
local context_range = cache.memoize(function(node, query)
  local bufnr = api.nvim_get_current_buf()
  local range = { node:range() } --- @type Range4
  range[3] = range[1]
  range[4] = -1

  -- max_start_depth depth is only supported in nvim 0.10. It is ignored on
  -- versions 0.9 or less. It is only needed to improve performance
  for _, match in query:iter_matches(node, bufnr, 0, -1, { max_start_depth = 0 }) do
    local r = false

    for id, node0 in pairs(match) do
      local srow, scol, erow, ecol = node0:range()

      local name = query.captures[id] -- name of the capture in the query
      if not r and name == 'context' then
        r = node == node0
      elseif name == 'context.start' then
        range[1] = srow
        range[2] = scol
      elseif name == 'context.final' then
        range[3] = erow
        range[4] = ecol
      elseif name == 'context.end' then
        range[3] = srow
        range[4] = scol
      end
    end

    if r then
      return range
    end
  end
end, hash_node)

--- @param winid integer
--- @return integer
local function get_gutter_width(winid)
  return fn.getwininfo(winid)[1].textoff
end

local cursor_moved_vertical --- @type fun(): boolean
do
  local line --- @type integer?
  cursor_moved_vertical = function()
    local newline = api.nvim_win_get_cursor(0)[1]
    if newline ~= line then
      line = newline
      return true
    end
    return false
  end
end

--- @param buf integer?
--- @return integer buf
local function create_buf(buf)
  if buf and api.nvim_buf_is_valid(buf) then
    return buf
  end

  buf = api.nvim_create_buf(false, true)

  vim.bo[buf].undolevels = -1
  vim.bo[buf].bufhidden = 'wipe'

  return buf
end

--- @return integer gutter_bufnr
--- @return integer context_bufnr
local function get_bufs()
  context_bufnr = create_buf(context_bufnr)
  gutter_bufnr = create_buf(gutter_bufnr)

  return gutter_bufnr, context_bufnr
end

--- @param bufnr integer
--- @param winid integer?
--- @param width integer
--- @param height integer
--- @param col integer
--- @param ty string
--- @param hl string
--- @return integer
local function display_window(bufnr, winid, width, height, col, ty, hl)
  if not winid or not api.nvim_win_is_valid(winid) then
    local sep = config.separator and { config.separator, 'TreesitterContextSeparator' } or nil
    winid = api.nvim_open_win(bufnr, false, {
      relative = 'win',
      width = width,
      height = height,
      row = 0,
      col = col,
      focusable = false,
      style = 'minimal',
      noautocmd = true,
      zindex = config.zindex,
      border = sep and { '', '', '', '', sep, sep, sep, '' } or nil,
    })
    vim.w[winid][ty] = true
    vim.wo[winid].wrap = false
    vim.wo[winid].foldenable = false
    vim.wo[winid].winhl = 'NormalFloat:' .. hl
  else
    api.nvim_win_set_config(winid, {
      win = api.nvim_get_current_win(),
      relative = 'win',
      width = width,
      height = height,
      row = 0,
      col = col,
    })
  end
  return winid
end

--- @param node TSNode
--- @return TSNode[]
local function get_parent_nodes(node)
  local n = node --- @type TSNode?
  local ret = {} --- @type TSNode[]
  while n do
    ret[#ret + 1] = n
    n = n:parent()
  end
  return ret
end

---@param r Range4
local function get_range_height(r)
  return r[3] - r[1] + (r[4] == 0 and 0 or 1)
end

---@param bufnr integer
---@return Query?
local function get_context_query(bufnr)
  --- @type string
  local lang = assert(get_lang(vim.bo[bufnr].filetype))

  local ok, query = pcall(get_query, lang, 'context')

  if not ok then
    vim.notify_once(
      string.format('Unable to load context query for %s:\n%s', lang, query),
      vim.log.levels.ERROR,
      { title = 'nvim-treesitter-context' }
    )
    return
  end

  return query
end

---@param bufnr integer
---@param row integer
---@param col integer
---@return TSNode?
local function get_node(bufnr, row, col)
  local root_tree = vim.treesitter.get_parser(bufnr)
  if not root_tree then
    return
  end

  return root_tree:named_node_for_range({ row, col, row, col + 1 })
end

---@param context_ranges Range4[]
---@param context_lines string[][]
---@param trim integer
---@param top boolean
local function trim_contexts(context_ranges, context_lines, trim, top)
  while trim > 0 do
    local idx = top and 1 or #context_ranges
    local context_to_trim = context_ranges[idx]

    local height = get_range_height(context_to_trim)

    if height <= trim then
      table.remove(context_ranges, idx)
      table.remove(context_lines, idx)
    else
      context_to_trim[3] = context_to_trim[3] - trim
      context_to_trim[4] = -1
      local context_lines_to_trim = context_lines[idx]
      for _ = 1, trim do
        context_lines_to_trim[#context_lines_to_trim] = nil
      end
    end
    trim = math.max(0, trim - height)
  end
end

--- @param winid integer
--- @param config_max integer
--- @return integer
local function calc_max_lines(winid, config_max)
  local max_lines = config_max == 0 and -1 or config_max

  local wintop = fn.line('w0', winid)
  local cursor = fn.line('.', winid)
  local max_from_cursor = cursor - wintop

  if config.separator and max_from_cursor > 0 then
    max_from_cursor = max_from_cursor - 1 -- separator takes 1 line
  end

  if max_lines ~= -1 then
    max_lines = math.min(max_lines, max_from_cursor)
  else
    max_lines = max_from_cursor
  end

  return max_lines
end

--- @param bufnr integer
--- @param winid integer
--- @return Range4[]?, string[]?
local function get_context_ranges(bufnr, winid)
  local max_lines = calc_max_lines(winid, config.max_lines)

  if max_lines == 0 then
    return
  end

  if not pcall(vim.treesitter.get_parser, bufnr) then
    return
  end

  local query = get_context_query(bufnr)

  if not query then
    return
  end

  local top_row = fn.line('w0', winid) - 1

  --- @type integer, integer
  local row, col

  if config.mode == 'topline' then
    row, col = top_row, 0
  else
    local c = api.nvim_win_get_cursor(winid)
    row, col = c[1] - 1, c[2]
  end

  local context_ranges = {} --- @type Range4[]
  local context_lines = {} --- @type string[][]
  local contexts_height = 0

  for offset = 0, max_lines do
    local node_row = row + offset

    local node = get_node(bufnr, node_row, offset == 0 and col or 0)
    if not node then
      return
    end

    local parents = get_parent_nodes(node)

    context_ranges = {}
    context_lines = {}
    contexts_height = 0

    for i = #parents, 1, -1 do
      local parent = parents[i]
      local parent_start_row = parent:range()

      local contexts_end_row = top_row + math.min(max_lines, contexts_height)
      -- Only process the parent if it is not in view.
      if parent_start_row < contexts_end_row then
        local range0 = context_range(parent, query)
        if range0 then
          local range, lines = get_text_for_range(range0)

          local last_context = context_ranges[#context_ranges]
          if last_context and parent_start_row == last_context[1] then
            -- If there are multiple contexts on the same row, then prefer the inner
            contexts_height = contexts_height - get_range_height(last_context)
            context_ranges[#context_ranges] = nil
            context_lines[#context_lines] = nil
          end

          contexts_height = contexts_height + get_range_height(range)
          context_ranges[#context_ranges + 1] = range
          context_lines[#context_lines + 1] = lines
        end
      end
    end

    local contexts_end_row = top_row + math.min(max_lines, contexts_height)

    if node_row >= contexts_end_row then
      break
    end
  end

  local trim = contexts_height - max_lines
  if trim > 0 then
    trim_contexts(context_ranges, context_lines, trim, config.trim_scope == 'outer')
  end

  return context_ranges, vim.tbl_flatten(context_lines)
end

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

local function win_close(winid)
  vim.schedule(function()
    if winid ~= nil and api.nvim_win_is_valid(winid) then
      api.nvim_win_close(winid, true)
    end
  end)
end

local function close()
  previous_context = nil
  -- Can't close other windows when the command-line window is open
  if fn.getcmdwintype() ~= '' then
    return
  end

  win_close(context_winid)
  context_winid = nil

  win_close(gutter_winid)
  gutter_winid = nil
end

--- @param bufnr integer
--- @param lines string[]
--- @return boolean
local function set_lines(bufnr, lines)
  local clines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local redraw = false
  if #clines ~= #lines then
    redraw = true
  else
    for i, l in ipairs(clines) do
      if l ~= lines[i] then
        redraw = true
        break
      end
    end
  end

  if redraw then
    api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modified = false
  end

  return redraw
end

---@param name string
---@param from_buf integer
---@param to_buf integer
local function copy_option(name, from_buf, to_buf)
  --- @cast name any
  local current = vim.bo[from_buf][name]
  -- Only set when necessary to avoid OptionSet events
  if current ~= vim.bo[to_buf][name] then
    vim.bo[to_buf][name] = current
  end
end

--- @param bufnr integer
--- @param ctx_bufnr integer
--- @param contexts Range4[]
local function highlight_contexts(bufnr, ctx_bufnr, contexts)
  api.nvim_buf_clear_namespace(ctx_bufnr, ns, 0, -1)

  local buf_highlighter = highlighter.active[bufnr]

  copy_option('tabstop', bufnr, ctx_bufnr)

  if not buf_highlighter then
    -- Use standard highlighting when TS highlighting is not available
    copy_option('filetype', bufnr, ctx_bufnr)
    return
  end

  local parser = buf_highlighter.tree

  parser:for_each_tree(function(tstree, ltree)
    local buf_query = buf_highlighter:get_query(ltree:lang())
    local query = buf_query:query()
    if not query then
      return
    end

    local p = 0
    local offset = 0
    for _, context in ipairs(contexts) do
      local start_row, end_row, end_col = context[1], context[3], context[4]

      for capture, node, metadata in
        query:iter_captures(tstree:root(), bufnr, start_row, end_row + 1)
      do
        local range = vim.treesitter.get_range(node, bufnr, metadata[capture])
        local nsrow, nscol, nerow, necol = range[1], range[2], range[4], range[5]

        if nerow > end_row or (nerow == end_row and necol > end_col and end_col ~= -1) then
          break
        end

        if nsrow >= start_row then
          local msrow = offset + (nsrow - start_row)
          local merow = offset + (nerow - start_row)

          local hl = buf_query.hl_cache[capture]
          local priority = tonumber(metadata.priority) or vim.highlight.priorities.treesitter
          local ok, err = pcall(api.nvim_buf_set_extmark, ctx_bufnr, ns, msrow, nscol, {
            end_line = merow,
            end_col = necol,
            hl_group = hl,
            priority = priority + p,
          })
          if not ok then
            error(
              string.format(
                'Could not apply exmtark to %s: %s',
                vim.inspect({ msrow, nscol, merow, necol }),
                err
              )
            )
          end

          -- TODO(lewis6991): Extmarks of equal priority appear to apply
          -- highlights differently between ephemeral and non-ephemeral:
          -- - ephemeral:  give priority to the last mark applied
          -- - non-ephemeral: give priority to the first mark applied
          --
          -- In order the match the behaviour of main highlighter which uses
          -- ephemeral marks, make sure increase the priority as we apply marks.
          p = p + 1
        end
      end
      offset = offset + get_range_height(context)
    end
  end)
end

--- @class StatusLineHighlight
--- @field group string
--- @field start integer

--- @param ctx_node_line_num integer
--- @return integer
local function get_relative_line_num(ctx_node_line_num)
  local cursor_line_num = fn.line('.')
  local num_folded_lines = 0
  -- Find all folds between the context node and the cursor
  local current_line = ctx_node_line_num
  while current_line < cursor_line_num do
    local fold_end = fn.foldclosedend(current_line)
    if fold_end == -1 then
      current_line = current_line + 1
    else
      num_folded_lines = num_folded_lines + fold_end - current_line
      current_line = fold_end + 1
    end
  end
  return cursor_line_num - ctx_node_line_num - num_folded_lines
end

--- @param win integer
--- @param lnum integer
--- @param width integer
--- @return string, StatusLineHighlight[]?
local function build_lno_str(win, lnum, width)
  local has_col, statuscol =
    pcall(api.nvim_get_option_value, 'statuscolumn', { win = win, scope = 'local' })
  if has_col and statuscol and statuscol ~= '' then
    local ok, data = pcall(api.nvim_eval_statusline, statuscol, {
      winid = win,
      use_statuscol_lnum = lnum,
      highlights = true,
    })
    if ok then
      return data.str, data.highlights
    end
  end
  local relnum --- @type integer?
  if vim.wo[win].relativenumber then
    relnum = get_relative_line_num(lnum)
  end
  return string.format('%' .. width .. 'd', relnum or lnum)
end

---@param bufnr integer
---@param row integer
local function highlight_bottom(bufnr, row)
  api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
    end_line = row + 1,
    hl_group = 'TreesitterContextBottom',
    hl_eol = true,
  })
end

--- @param buf integer
--- @param text string[]
--- @param highlights StatusLineHighlight[][]
local function highlight_lno_str(buf, text, highlights)
  for line, linehl in ipairs(highlights) do
    for hlidx, hl in ipairs(linehl) do
      local col = hl.start
      local endcol = hlidx < #linehl and linehl[hlidx + 1].start or #text[line]
      if col ~= endcol then
        api.nvim_buf_set_extmark(buf, ns, line - 1, col, {
          end_col = endcol,
          hl_group = hl.group:find('LineNr') and 'TreesitterContextLineNumber' or hl.group,
        })
      end
    end
  end
  highlight_bottom(buf, #text - 1)
end

---@param win integer
---@param bufnr integer
---@param contexts Range4[]
---@param gutter_width integer
---@return integer
local function render_lno(win, bufnr, contexts, gutter_width)
  local lno_text = {} --- @type string[]
  local lno_highlights = {} --- @type StatusLineHighlight[][]

  for _, range in ipairs(contexts) do
    for i = 1, get_range_height(range) do
      local txt, hl = build_lno_str(win, range[1] + i, gutter_width - 1)
      table.insert(lno_text, txt)
      table.insert(lno_highlights, hl)
    end
  end

  set_lines(bufnr, lno_text)
  highlight_lno_str(bufnr, lno_text, lno_highlights)

  return #lno_text
end

local function horizontal_scroll_contexts()
  if context_winid == nil then
    return
  end
  local active_win_view = fn.winsaveview()
  local context_win_view = api.nvim_win_call(context_winid, fn.winsaveview)
  if active_win_view.leftcol ~= context_win_view.leftcol then
    context_win_view.leftcol = active_win_view.leftcol
    api.nvim_win_call(context_winid, function()
      return fn.winrestview({ leftcol = context_win_view.leftcol })
    end)
  end
end

--- @param bufnr integer
--- @param winid integer
--- @param ctx_ranges Range4[]
--- @param ctx_lines string[]
local function open(bufnr, winid, ctx_ranges, ctx_lines)
  local gutter_width = get_gutter_width(winid)
  local win_width = math.max(1, api.nvim_win_get_width(winid) - gutter_width)

  all_contexts[bufnr] = ctx_ranges

  local win_height = #ctx_lines

  local gbufnr, ctx_bufnr = get_bufs()

  local lno_width = 0

  if config.line_numbers and (vim.wo[winid].number or vim.wo[winid].relativenumber) then
    gutter_winid = display_window(
      gbufnr,
      gutter_winid,
      gutter_width,
      win_height,
      0,
      'treesitter_context_line_number',
      'TreesitterContextLineNumber'
    )
    lno_width = render_lno(winid, gbufnr, ctx_ranges, gutter_width)
  else
    win_close(gutter_winid)
  end

  context_winid = display_window(
    ctx_bufnr,
    context_winid,
    win_width,
    win_height,
    gutter_width,
    'treesitter_context',
    'TreesitterContext'
  )

  if not set_lines(ctx_bufnr, ctx_lines) then
    -- Context didn't change, can return here
    return
  end

  highlight_contexts(bufnr, ctx_bufnr, ctx_ranges)
  highlight_bottom(ctx_bufnr, lno_width - 1)
end

local attached = {} --- @type table<integer,true>

local update = throttle(function()
  local bufnr = api.nvim_get_current_buf()
  local winid = api.nvim_get_current_win()

  if not attached[bufnr] then
    close()
    return
  end

  if vim.bo[bufnr].buftype ~= '' or vim.wo[winid].previewwindow then
    close()
    return
  end

  local context, context_lines = get_context_ranges(bufnr, winid)

  if context and #context ~= 0 then
    assert(context_lines)

    if context == previous_context then
      return
    end

    previous_context = context

    if api.nvim_win_get_height(winid) < config.min_window_height then
      close()
      return
    end

    open(bufnr, winid, context, context_lines)
    horizontal_scroll_contexts()
  else
    close()
  end
end)

--- @param group string
--- @return function
local function autocmd_for_group(group)
  local gid = augroup(group, {})
  return function(event, opts)
    ---@diagnostic disable:no-unknown
    if opts then
      if type(opts) == 'function' then
        opts = { callback = opts }
      elseif opts[1] then
        opts.callback = opts[1]
        opts[1] = nil
      end
    else
      opts = {}
    end
    opts.group = gid
    api.nvim_create_autocmd(event, opts)
  end
end

local M = {
  config = config,
}

function M.enable()
  local autocmd = autocmd_for_group('treesitter_context_update')

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

  autocmd('CursorMoved', function()
    if cursor_moved_vertical() then
      update()
    end
  end)

  autocmd('OptionSet', function(args)
    if args.match == 'number'
      or args.match == 'relativenumber' then
      update()
    end
  end)

  autocmd({ 'BufLeave', 'WinLeave' }, close)

  autocmd('User', { close, pattern = 'SessionSavePre' })
  autocmd('User', { update, pattern = 'SessionSavePost' })

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

local did_setup = false

function M.setup(options)
  if did_setup then
    return
  end
  did_setup = true

  local user_options = options or {}

  config = vim.tbl_deep_extend('force', config, user_options)

  if config.enable then
    M.enable()
  else
    M.disable()
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

  api.nvim_win_set_cursor(0, { context[1] + 1, context[2] })
end

command('TSContextEnable', M.enable, {})
command('TSContextDisable', M.disable, {})
command('TSContextToggle', M.toggle, {})

api.nvim_set_hl(0, 'TreesitterContext', { link = 'NormalFloat', default = true })
api.nvim_set_hl(0, 'TreesitterContextLineNumber', { link = 'LineNr', default = true })
api.nvim_set_hl(0, 'TreesitterContextBottom', { link = 'NONE', default = true })
api.nvim_set_hl(0, 'TreesitterContextSeparator', { link = 'FloatBorder', default = true })

-- Setup with default options if user didn't call setup()
autocmd_for_group('treesitter_context')('VimEnter', function()
  M.setup()
end)

return M
