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
  multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
  trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  zindex = 20,
  mode = 'cursor',
}

--- @type TSContext.Config
local config = {}

-- Constants

local INDENT_PATTERN = '^%s+'

-- Script variables

local did_setup = false
local enabled = false

-- Don't access directly, use get_bufs()
local gutter_bufnr --- @type integer?
local context_bufnr --- @type integer?

local gutter_winid --- @type integer?
local context_winid --- @type integer?

local ns = api.nvim_create_namespace('nvim-treesitter-context')

--- @type TSNode[]?
local previous_nodes

--- @type table<integer, Context[]>
local all_contexts = {}

--- @return TSNode
local function get_root_node()
  local tree = vim.treesitter.get_parser():parse()[1]
  return tree:root()
end

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

--- @param node TSNode
--- @param query Query
--- @return Range4?
local is_valid = cache.memoize(function(node, query)
  local bufnr = api.nvim_get_current_buf()
  local range = { node:range() } --- @type Range4
  range[3] = range[1]
  range[4] = -1

  -- max_start_depth depth is only supported in nvim 0.10. It is ignored on
  -- versions 0.9 or less. It is only needed to improve performance
  for _, match in query:iter_matches(node, bufnr, 0, -1, { max_start_depth = 1 }) do
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

--- @param range Range4
--- @return string[]?, Range4?
local function get_text_for_range(range)
  if range[4] == 0 then
    range[3] = range[3] - 1
    range[4] = -1
  end
  local lines = api.nvim_buf_get_text(0, range[1], 0, range[3], range[4], {})
  if not lines then
    return
  end

  local start_row = range[1]
  local end_row = range[3]
  local end_col = range[4]

  lines = vim.list_slice(lines, 1, end_row - start_row + 1)
  lines[#lines] = lines[#lines]:sub(1, end_col)

  if #lines > config.multiline_threshold then
    lines = vim.list_slice(lines, 1, 1)
    end_row = start_row
    end_col = #lines[1]
  end

  return lines, { start_row, 0, end_row, end_col }
end

-- Merge lines, removing the indentation after 1st line
--- @param lines string[]
--- @return string
local function merge_lines(lines)
  local text = { lines[1] }
  for i = 2, #lines do
    text[i] = lines[i]:gsub(INDENT_PATTERN, '')
  end
  return table.concat(text, ' ')
end

-- Get indentation for lines except first
--- @param lines string[]
--- @return integer[]
local function get_indents(lines)
  --- @type integer[]
  local indents = vim.tbl_map(
    --- @param line string
    --- @return integer
    function(line)
      --- @type string?
      local indent = line:match(INDENT_PATTERN)
      return indent and #indent or 0
    end,
    lines
  )
  -- Dont skip first line indentation
  indents[1] = 0
  return indents
end

--- @return integer
local function get_gutter_width()
  return fn.getwininfo(api.nvim_get_current_win())[1].textoff
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

-- Exports

local M = {
  config = config,
}

--- @param node TSNode?
--- @return TSNode[]
local function get_node_parents(node)
  -- save nodes in a table to iterate from top to bottom
  --- @type TSNode[]
  local parents = {}
  while node ~= nil do
    parents[#parents + 1] = node
    node = node:parent()
  end
  return parents
end

--- @return integer, integer
local function get_pos()
  --- @type integer, integer
  local lnum, col
  if config.mode == 'topline' then
    lnum, col =
      fn.line('w0'), --[[@as integer]]
      0
  else -- default to 'cursor'
    lnum, col = unpack(api.nvim_win_get_cursor(0)) --[[@as integer]]
  end

  return lnum, col
end

--- @param max_lines integer
--- @return Range4[]?
local function get_parent_matches(max_lines)
  if max_lines == 0 then
    return
  end

  if not pcall(vim.treesitter.get_parser) then
    return
  end

  --- @type string
  local lang = assert(get_lang(vim.bo.filetype))

  local ok, query = pcall(get_query, lang, 'context')

  if not ok then
    vim.notify_once(
      string.format('Unable to load context query for %s:\n%s', lang, query),
      vim.log.levels.ERROR,
      { title = 'nvim-treesitter-context' }
    )
    return
  end

  if not query then
    return
  end

  local root_node = get_root_node()
  local lnum, col = get_pos()

  --- @type Range4[]
  local last_matches

  --- @type Range4[]
  local parent_matches = {}
  local line_offset = 0

  repeat
    local offset_lnum = lnum + line_offset - 1
    local node = root_node:named_descendant_for_range(offset_lnum, col, offset_lnum, col)
    if not node then
      return
    end

    last_matches = parent_matches
    parent_matches = {}
    local last_row = -1
    local topline = fn.line('w0')

    -- save nodes in a table to iterate from top to bottom
    local parents = get_node_parents(node)

    for i = #parents, 1, -1 do
      local parent = parents[i]
      local row = parent:start()

      local height = math.min(max_lines, #parent_matches)
      local range = is_valid(parent, query)
      if range and row >= 0 and row < (topline + height - 1) then
        if row == last_row then
          parent_matches[#parent_matches] = range
        else
          parent_matches[#parent_matches + 1] = range
          last_row = row

          local new_height = math.min(max_lines, #parent_matches)
          if config.mode == 'topline' and line_offset < new_height then
            line_offset = line_offset + 1
            break
          end
        end
      end
    end
  until config.mode ~= 'topline' or #last_matches >= #parent_matches

  if config.trim_scope == 'inner' then
    return vim.list_slice(parent_matches, 1, math.min(#parent_matches, max_lines))
  else -- default to 'outer'
    return vim.list_slice(
      parent_matches,
      math.max(1, #parent_matches - max_lines + 1),
      #parent_matches
    )
  end
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
  previous_nodes = nil
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

--- @param bufnr integer
--- @param ctx_bufnr integer
--- @param contexts Context[]
local function highlight_contexts(bufnr, ctx_bufnr, contexts)
  api.nvim_buf_clear_namespace(ctx_bufnr, ns, 0, -1)

  local buf_highlighter = highlighter.active[bufnr]

  if not buf_highlighter then
    -- Use standard highlighting when TS highlighting is not available
    local current_ft = vim.bo.filetype
    if current_ft ~= vim.bo[ctx_bufnr].filetype then
      vim.bo[ctx_bufnr].filetype = current_ft
    end
    return
  end

  -- Only set when necessary to avoid OptionSet events
  local current_tabstop = vim.bo.tabstop
  if current_tabstop ~= vim.bo[ctx_bufnr].tabstop then
    vim.bo[ctx_bufnr].tabstop = current_tabstop
  end

  local lang = assert(get_lang(vim.bo.filetype))
  local buf_query = buf_highlighter:get_query(lang)

  local query = buf_query:query()

  if not query then
    -- no highlight query
    return
  end

  local root = get_root_node()

  for i, context in ipairs(contexts) do
    local start_row = context.range[1]
    local end_row = context.range[3]
    local end_col = context.range[4]
    local indents = context.indents
    local lines = context.lines

    for capture, node in query:iter_captures(root, bufnr, start_row, end_row + 1) do
      local node_start_row, node_start_col, node_end_row, node_end_col = node:range()

      if
        node_end_row > end_row
        or (node_end_row == end_row and node_end_col > end_col and end_col ~= -1)
      then
        break
      end

      if node_start_row >= start_row then
        local intended_start_row = node_start_row - start_row

        -- Add 1 for each space added between lines when
        -- we replace '\n' with ' '
        local offset = intended_start_row
        -- Add the length of each preceding lines
        for j = 1, intended_start_row do
          offset = offset + #lines[j] - indents[j]
        end
        -- Remove the indentation negative offset for current line
        offset = offset - indents[intended_start_row + 1]

        local row = i - 1
        api.nvim_buf_set_extmark(ctx_bufnr, ns, row, node_start_col + offset, {
          end_line = row,
          end_col = node_end_col + offset,
          hl_group = buf_query.hl_cache[capture],
        })
      end
    end
  end
end

--- @class StatusLineHighlight
--- @field group string
--- @field start integer

--- @param win integer
--- @param lnum integer
--- @param relnum integer?
--- @param width integer
--- @return string, StatusLineHighlight[]?
local function build_lno_str(win, lnum, relnum, width)
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
  if relnum then
    lnum = relnum
  end
  return string.format('%' .. width .. 'd', lnum)
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
  api.nvim_buf_set_extmark(
    buf,
    ns,
    #text - 1,
    0,
    { end_line = #text, hl_group = 'TreesitterContextBottom', hl_eol = true }
  )
end

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

--- @class Context
--- @field indents integer[]
--- @field lines string[]
--- @field range Range4

--- @param ctx_ranges Range4[]
local function open(ctx_ranges)
  local bufnr = api.nvim_get_current_buf()
  local win = api.nvim_get_current_win()

  local gutter_width = get_gutter_width()
  local win_width = math.max(1, api.nvim_win_get_width(0) - gutter_width)
  local win_height = math.max(1, #ctx_ranges)

  local gbufnr, ctx_bufnr = get_bufs()

  if config.line_numbers and (vim.wo.number or vim.wo.relativenumber) then
    gutter_winid = display_window(
      gbufnr,
      gutter_winid,
      gutter_width,
      win_height,
      0,
      'treesitter_context_line_number',
      'TreesitterContextLineNumber'
    )
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

  -- Set text

  local context_text = {} --- @type string[]
  local lno_text = {} --- @type string[]
  local lno_highlights = {} --- @type StatusLineHighlight[][]
  local contexts = {} --- @type Context[]

  for _, range0 in ipairs(ctx_ranges) do
    local lines, range = get_text_for_range(range0)
    if lines == nil or range == nil or range[1] == nil then
      return
    end
    local text = merge_lines(lines)

    contexts[#contexts + 1] = {
      lines = lines,
      range = range,
      indents = get_indents(lines),
    }

    table.insert(context_text, text)

    local ctx_line_num = range[1] + 1
    local relnum --- @type integer?
    if vim.wo[win].relativenumber then
      relnum = get_relative_line_num(ctx_line_num)
    end
    local txt, hl = build_lno_str(win, ctx_line_num, relnum, gutter_width - 1)
    table.insert(lno_text, txt)
    table.insert(lno_highlights, hl)
  end

  all_contexts[bufnr] = contexts

  set_lines(gbufnr, lno_text)
  highlight_lno_str(gbufnr, lno_text, lno_highlights)

  if not set_lines(ctx_bufnr, context_text) then
    -- Context didn't change, can return here
    return
  end

  highlight_contexts(bufnr, ctx_bufnr, contexts)

  api.nvim_buf_set_extmark(
    ctx_bufnr,
    ns,
    #lno_text - 1,
    0,
    { end_line = #lno_text, hl_group = 'TreesitterContextBottom', hl_eol = true }
  )
end

--- @param config_max integer
--- @return integer
local function calc_max_lines(config_max)
  local max_lines = config_max
  max_lines = max_lines == 0 and -1 or max_lines

  local wintop = fn.line('w0')
  local cursor = fn.line('.')
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

local attached = {} --- @type table<integer,true>

local update = throttle(function()
  local buf = api.nvim_get_current_buf()

  if not attached[buf] then
    close()
    return
  end

  if vim.bo.buftype ~= '' or vim.wo.previewwindow then
    close()
    return
  end

  local context = get_parent_matches(calc_max_lines(config.max_lines))

  if context and #context ~= 0 then
    if context == previous_nodes then
      return
    end

    previous_nodes = context

    if api.nvim_win_get_height(0) < config.min_window_height then
      close()
      return
    end

    open(context)
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

function M.enable()
  local autocmd = autocmd_for_group('treesitter_context_update')

  local cbuf = api.nvim_get_current_buf()

  attached[cbuf] = true

  autocmd({ 'WinScrolled', 'BufEnter', 'WinEnter', 'VimResized' }, update)

  autocmd('BufReadPost', function(args)
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

function M.setup(options)
  if did_setup then
    return
  end
  did_setup = true

  local userOptions = options or {}

  config = vim.tbl_deep_extend('force', {}, defaultConfig, userOptions)

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
    if v.range[1] + 1 < line then
      context = v
    end
  end

  if context == nil then
    return
  end

  api.nvim_win_set_cursor(0, { context.range[1] + 1, context.range[2] })
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
