---@diagnostic disable-next-line
local api = vim.api
local highlighter = vim.treesitter.highlighter

---@diagnostic disable-next-line
local parsers = require'nvim-treesitter.parsers'

local augroup = api.nvim_create_augroup
local command = api.nvim_create_user_command

--- @class Config
--- @field enable boolean
--- @field max_lines integer
--- @field min_window_height integer
--- @field line_numbers boolean
--- @field multiline_threshold integer
--- @field trim_scope 'outer'|'inner'
--- @field zindex integer
--- @field mode 'cursor'|'topline'
--- @field separator string?

--- @type Config
local defaultConfig = {
  enable = true,
  max_lines = 0, -- no limit
  min_window_height = 0,
  line_numbers = true,
  multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
  trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  zindex = 20,
  mode = 'cursor', -- Choices: 'cursor', 'topline'
  separator = nil,
}

--- @type Config
local config = {}

-- Constants

local INDENT_PATTERN = '^%s+'

-- Script variables

local did_setup = false
local enabled = false

-- Don't access directly, use get_bufs()
--- @type integer?
local gutter_winid

--- @type integer?
local context_winid

--- @type integer?
local gutter_bufnr

--- @type integer?
local context_bufnr

local ns = api.nvim_create_namespace('nvim-treesitter-context')

--- @type TSNode[]?
local previous_nodes

--- @return TSNode
local function get_root_node()
  ---@diagnostic disable-next-line
  local tree = parsers.get_parser():parse()[1]
  return tree:root()
end

--- @class TSNode
--- @field parent fun(TSNode): TSNode?
--- @field start fun(TSNode): integer, integer
--- @field range fun(TSNode): integer, integer, integer, integer
--- @field named_descendant_for_range fun(TSNode, integer, integer, integer, integer): TSNode

--- @param node TSNode
--- @param query Query
--- @return Range?
local function is_valid(node, query)
  local bufnr = api.nvim_get_current_buf()
  local range --[[@type Range]] = {node:range()}
  for _, match in query:iter_matches(node --[[@as userdata]], bufnr, 0, -1) do
    local r = false

    for id, node0 in pairs(match --[[@as table<integer,TSNode>]]) do
      local name = query.captures[id] -- name of the capture in the query
      if not r and name == 'context' then
        r = node == node0
      elseif name == 'context.final' then
        local _, _, erow, ecol = node0:range()
        range[3] = erow
        range[4] = ecol
      elseif name == 'context.end' then
        local srow, scol = node0:range()
        range[3] = srow
        range[4] = scol
      end
    end

    if r then
      return range
    end
  end
end

--- @alias Range {[1]: integer, [2]: integer, [3]: integer, [4]: integer}

--- @param range Range
--- @return string[]?, Range?
local function get_text_for_range(range)
  local lines = api.nvim_buf_get_text(0, range[1], 0, range[3], range[4], {})
  if lines == nil then
    return nil, nil
  end

  local start_row = range[1]
  local end_row = range[3]
  local end_col = range[4]

  lines = vim.list_slice(lines, 1, end_row - start_row+1)
  lines[#lines] = lines[#lines]:sub(1, end_col)

  if #lines > config.multiline_threshold then
    lines = vim.list_slice(lines, 1, 1)
    end_row = start_row
    end_col = #lines[1]
  end

  range = {start_row, 0, end_row, end_col}

  return lines, range
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
  local indents = vim.tbl_map(function(line)
    local indent = line:match(INDENT_PATTERN)
    return indent and #indent or 0
  end, lines)
  -- Dont skip first line indentation
  indents[1] = 0
  return indents
end

--- @return integer
local function get_gutter_width()
  return vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff
end

local cursor_moved_vertical --[[@type fun(): boolean]]
do
  local line --[[@type integer]]
  cursor_moved_vertical = function()
    local newline = vim.api.nvim_win_get_cursor(0)[1]
    if newline ~= line then
      line = newline
      return true
    end
    return false
  end
end

--- @return integer, integer
local function get_bufs()
  if not context_bufnr or not api.nvim_buf_is_valid(context_bufnr) then
    context_bufnr = api.nvim_create_buf(false, true)
  end

  if not gutter_bufnr or not api.nvim_buf_is_valid(gutter_bufnr) then
    gutter_bufnr = api.nvim_create_buf(false, true)
  end

  return gutter_bufnr, context_bufnr
end

local function delete_bufs()
  if context_bufnr and api.nvim_buf_is_valid(context_bufnr) then
    api.nvim_buf_delete(context_bufnr, { force = true })
  end
  context_bufnr = nil

  if gutter_bufnr and api.nvim_buf_is_valid(gutter_bufnr) then
    api.nvim_buf_delete(gutter_bufnr, { force = true })
  end
  gutter_bufnr = nil
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
    local sep = config.separator
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
      border = sep and {'', '', '', '', sep, sep, sep, ''} or nil,
    })
    api.nvim_win_set_var(winid, ty, true)
    api.nvim_win_set_option(winid, 'wrap', false)
    api.nvim_win_set_option(winid, 'foldenable', false)
    api.nvim_win_set_option(winid, 'winhl', 'NormalFloat:' .. hl)
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
    parents[#parents+1] = node
    node = node:parent()
  end
  return parents
end

--- @param max_lines integer
--- @return Range[]?
local function get_parent_matches(max_lines)
  if max_lines == 0 then
    return
  end

  if not parsers.has_parser() then
    return
  end

  local root_node = get_root_node()

  --- @type integer, integer
  local lnum, col
  if config.mode == 'topline' then
    lnum, col = vim.fn.line('w0') --[[@as integer]], 0
  else -- default to 'cursor'
    lnum, col = unpack(api.nvim_win_get_cursor(0)) --[[@as integer]]
  end

  --- @type string
  local lang = parsers.ft_to_lang(vim.bo.filetype)

  local query = vim.treesitter.query.get_query(lang, 'context')

  if not query then
    return
  end

  --- @type Range[]
  local last_matches

  --- @type Range[]
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
    local topline = vim.fn.line('w0')

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
          parent_matches[#parent_matches+1] = range
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
    return vim.list_slice(
      parent_matches,
      1,
      math.min(#parent_matches, max_lines)
    )
  else -- default to 'outer'
    return vim.list_slice(
      parent_matches,
      math.max(1, #parent_matches - max_lines + 1),
      #parent_matches
    )
  end
end

--- @generic F: function
--- @param fn F
--- @return F
local function throttle_fn(fn)
  local recalc_after_cooldown = false
  local cooling_down = false
  local function wrapped()
    if cooling_down then
      recalc_after_cooldown = true
    else
      local start = vim.loop.hrtime()
      fn()
      local elapsed_ms = math.floor((vim.loop.hrtime() - start) / 1e6)
      -- If this took < 2ms, we don't need a cooldown period. This prevents the context floats from flickering
      if elapsed_ms > 2 then
        cooling_down = true
        vim.defer_fn(function()
          cooling_down = false
          if recalc_after_cooldown then
            recalc_after_cooldown = false
            wrapped()
          end
        end, 20)
      end
    end
  end
  return wrapped
end

local function close()
  previous_nodes = nil
  -- Can't close other windows when the command-line window is open
  if vim.fn.getcmdwintype() ~= '' then
    return
  end

  if context_winid ~= nil and api.nvim_win_is_valid(context_winid) then
    api.nvim_win_close(context_winid, true)
  end
  context_winid = nil

  if gutter_winid and api.nvim_win_is_valid(gutter_winid) then
    api.nvim_win_close(gutter_winid, true)
  end
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
    api.nvim_buf_set_option(bufnr, 'modified', false)
  end

  return redraw
end

--- @param bufnr integer
--- @param ctx_bufnr integer
--- @param contexts Context[]
local function highlight_contexts(bufnr, ctx_bufnr, contexts)
  api.nvim_buf_clear_namespace(ctx_bufnr, ns, 0, -1)

  local buf_highlighter = highlighter.active[bufnr] --[[@as TSHighlighter]]

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

  local buf_query = buf_highlighter:get_query(parsers.ft_to_lang(vim.bo.filetype))

  local query = buf_query:query()
  local root = get_root_node()

  for i, context in ipairs(contexts) do
    local start_row, _, end_row, end_col = unpack(context.range)
    local indents = context.indents
    local lines = context.lines

    local start_row_abs = context.range[1]

    for capture, node in query:iter_captures(root, bufnr, start_row, context.range[3]) do
      local node_start_row, node_start_col, node_end_row, node_end_col = (node --[[@as TSNode]]):range()

      if node_end_row > end_row or
        (node_end_row == end_row and node_end_col > end_col) then
        break
      end

      if node_start_row >= start_row_abs then
        local intended_start_row = node_start_row - start_row_abs

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
          hl_group = buf_query.hl_cache[capture]
        })
      end
    end
  end
end

--- @param lnum integer
--- @param width integer
--- @return string
local function build_lno_str(lnum, width)
  return string.format('%'..width..'d', lnum)
end

--- @param ctx_node_line_num integer
--- @return integer
local function get_relative_line_num(ctx_node_line_num)
  local cursor_line_num = vim.fn.line('.')
  local num_folded_lines = 0
  -- Find all folds between the context node and the cursor
  local current_line = ctx_node_line_num
  while current_line < cursor_line_num do
    local fold_end = vim.fn.foldclosedend(current_line)
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
  local active_win_view = vim.fn.winsaveview()
  local context_win_view = api.nvim_win_call(context_winid, vim.fn.winsaveview)
  if active_win_view.leftcol ~= context_win_view.leftcol then
    context_win_view.leftcol = active_win_view.leftcol
    api.nvim_win_call(context_winid, function()
      return vim.fn.winrestview({leftcol = context_win_view.leftcol})
    end)
  end
end

--- @class Context
--- @field indents integer[]
--- @field lines string[]
--- @field range Range

--- @param ctx_ranges Range[]
local function open(ctx_ranges)
  local bufnr = api.nvim_get_current_buf()

  local gutter_width = get_gutter_width()
  local win_width  = math.max(1, api.nvim_win_get_width(0) - gutter_width)
  local win_height = math.max(1, #ctx_ranges)

  local gbufnr, ctx_bufnr = get_bufs()

  if config.line_numbers and (vim.wo.number or vim.wo.relativenumber) then
    gutter_winid = display_window(
      gbufnr, gutter_winid, gutter_width, win_height, 0,
      'treesitter_context_line_number', 'TreesitterContextLineNumber')
  end

  context_winid = display_window(
    ctx_bufnr, context_winid, win_width, win_height, gutter_width,
    'treesitter_context', 'TreesitterContext')

  -- Set text

  local context_text --[[@type string[] ]] = {}
  local lno_text --[[@type string[] ]] = {}
  local contexts --[[@type Context[] ]] = {}

  for _, range0 in ipairs(ctx_ranges) do
    local lines, range = get_text_for_range(range0)
    if lines == nil or range == nil or range[1] == nil then
      return
    end
    local text = merge_lines(lines)

    contexts[#contexts+1] = {
      lines = lines,
      range = range,
      indents = get_indents(lines),
    }

    table.insert(context_text, text)

    local line_num  --[[@type integer]]
    local ctx_line_num = range[1] + 1
    if vim.o.relativenumber then
      line_num = get_relative_line_num(ctx_line_num)
    else
      line_num = ctx_line_num
    end
    table.insert(lno_text, build_lno_str(line_num, gutter_width-1))
  end

  set_lines(gbufnr, lno_text)
  if not set_lines(ctx_bufnr, context_text) then
    -- Context didn't change, can return here
    return
  end

  highlight_contexts(bufnr, ctx_bufnr, contexts)

  api.nvim_buf_set_extmark(ctx_bufnr, ns, #lno_text-1, 0, {end_line=#lno_text, hl_group='TreesitterContextBottom', hl_eol=true})
  api.nvim_buf_set_extmark(gbufnr, ns, #context_text-1, 0, {end_line=#context_text, hl_group='TreesitterContextBottom', hl_eol=true})
end

--- @param config_max integer
--- @return integer
local function calc_max_lines(config_max)
  local max_lines = config_max
  max_lines = max_lines == 0 and -1 or max_lines

  local wintop = vim.fn.line('w0')
  local cursor = vim.fn.line('.')
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

local update = throttle_fn(function()
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

  autocmd({ 'WinScrolled', 'BufEnter', 'WinEnter', 'VimResized' }, update)

  autocmd('CursorMoved', function()
    if cursor_moved_vertical() then
      update()
    end
  end)

  autocmd('WinLeave', close)

  autocmd('User', {close , pattern = 'SessionSavePre'  })
  autocmd('User', {update, pattern = 'SessionSavePost' })

  update()
  enabled = true
end

function M.disable()
  augroup('treesitter_context_update', {})
  close()
  delete_bufs()
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

command('TSContextEnable' , M.enable , {})
command('TSContextDisable', M.disable, {})
command('TSContextToggle' , M.toggle , {})

api.nvim_set_hl(0, 'TreesitterContext',           {link = 'NormalFloat', default = true})
api.nvim_set_hl(0, 'TreesitterContextLineNumber', {link = 'LineNr',      default = true})
api.nvim_set_hl(0, 'TreesitterContextBottom',     {link = 'NONE',        default = true})

-- Setup with default options if user didn't call setup()
autocmd_for_group('treesitter_context')('VimEnter', function()
  M.setup()
end)

return M
