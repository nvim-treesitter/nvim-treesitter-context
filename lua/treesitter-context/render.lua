local api, fn = vim.api, vim.fn
local highlighter = vim.treesitter.highlighter

local util = require('treesitter-context.util')
local config = require('treesitter-context.config')

local ns = api.nvim_create_namespace('nvim-treesitter-context')

--- @class WindowContext
--- @field bufnr integer The buffer number
--- @field gutter_bufnr integer The gutter buffer number
--- @field context_bufnr integer The context buffer number
--- @field gutter_winid integer? The window ID of the gutter
--- @field context_winid integer? The window ID of the context
local WindowContext = {}
WindowContext.__index = WindowContext

local windowContexts = {} --- @type table<integer, WindowContext>

--- @param winid integer?
local function win_close(winid)
  vim.schedule(function()
    if winid ~= nil and api.nvim_win_is_valid(winid) then
      api.nvim_win_close(winid, true)
    end
  end)
end

--- @param bufnr integer
--- @param winid integer
--- @return WindowContext
local function store_context(bufnr, winid)
  local window_ctx = windowContexts[winid]
  if window_ctx then
    if window_ctx.bufnr == bufnr then
      return window_ctx
    else
      -- Unserline buffer have changed, close it
      win_close(window_ctx.context_winid)
      win_close(window_ctx.gutter_winid)
    end
  end

  local self = setmetatable({
    bufnr = bufnr,
    gutter_bufnr = api.nvim_create_buf(false, true),
    context_bufnr = api.nvim_create_buf(false, true),
    gutter_winid = nil,
    context_winid = nil,
  }, WindowContext)

  vim.bo[self.context_bufnr].undolevels = -1
  vim.bo[self.context_bufnr].bufhidden = 'wipe'
  vim.bo[self.gutter_bufnr].undolevels = -1
  vim.bo[self.gutter_bufnr].bufhidden = 'wipe'
  windowContexts[winid] = self
  return self
end

--- @param bufnr integer
--- @param winid integer?
--- @param float_winid integer
--- @param width integer
--- @param height integer
--- @param col integer
--- @param ty string
--- @param hl string
--- @return integer
local function display_window(bufnr, winid, float_winid, width, height, col, ty, hl)
  if not float_winid or not api.nvim_win_is_valid(float_winid) then
    local sep = config.separator and { config.separator, 'TreesitterContextSeparator' } or nil
    float_winid = api.nvim_open_win(bufnr, false, {
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
    vim.w[float_winid][ty] = true
    vim.wo[float_winid].wrap = false
    vim.wo[float_winid].foldenable = false
    vim.wo[float_winid].winhl = 'NormalFloat:' .. hl
  else
    api.nvim_win_set_config(float_winid, {
      win = winid,
      relative = 'win',
      width = width,
      height = height,
      row = 0,
      col = col,
    })
  end
  return float_winid
end

--- @param winid integer
--- @return integer
local function get_gutter_width(winid)
  return fn.getwininfo(winid)[1].textoff
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

---@param bufnr integer
---@param row integer
---@param col integer
---@param opts vim.api.keyset.set_extmark
local function add_extmark(bufnr, row, col, opts)
  local ok, err = pcall(api.nvim_buf_set_extmark, bufnr, ns, row, col, opts)
  if not ok then
    local range = vim.inspect({ row, col, opts.end_row, opts.end_col }) --- @type string
    error(string.format('Could not apply exmtark to %s: %s', range, err))
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
          add_extmark(ctx_bufnr, msrow, nscol, {
            end_row = merow,
            end_col = necol,
            priority = priority + p,
            hl_group = hl,
            conceal = metadata.conceal,
          })

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
      offset = offset + util.get_range_height(context)
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
      fillchar = ' ',  -- Fixed in Neovim 0.10 (#396)
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
---@param hl_group 'TreesitterContextBottom' | 'TreesitterContextLineNumberBottom'
local function highlight_bottom(bufnr, row, hl_group)
  add_extmark(bufnr, row, 0, {
    end_line = row + 1,
    hl_group = hl_group,
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
        add_extmark(buf, line - 1, col, {
          end_col = endcol,
          hl_group = hl.group:find('LineNr') and 'TreesitterContextLineNumber' or hl.group,
        })
      end
    end
  end
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

---@param win integer
---@param bufnr integer
---@param contexts Range4[]
---@param gutter_width integer
local function render_lno(win, bufnr, contexts, gutter_width)
  local lno_text = {} --- @type string[]
  local lno_highlights = {} --- @type StatusLineHighlight[][]

  for _, range in ipairs(contexts) do
    for i = 1, util.get_range_height(range) do
      local txt, hl = build_lno_str(win, range[1] + i, gutter_width - 1)
      table.insert(lno_text, txt)
      table.insert(lno_highlights, hl)
    end
  end

  set_lines(bufnr, lno_text)
  highlight_lno_str(bufnr, lno_text, lno_highlights)
  highlight_bottom(bufnr, #lno_text - 1, 'TreesitterContextLineNumberBottom')
end

--- @param context_winid integer
local function horizontal_scroll_contexts(context_winid)
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

local M = {}

function M.get_window_contexts()
  return windowContexts
end

--- @param bufnr integer
--- @param winid integer
--- @param ctx_ranges Range4[]
--- @param ctx_lines string[]
function M.open(bufnr, winid, ctx_ranges, ctx_lines)
  local gutter_width = get_gutter_width(winid)
  local win_width = math.max(1, api.nvim_win_get_width(winid) - gutter_width)
  local win_height = #ctx_lines

  local window_context = store_context(bufnr, winid)
  local gbufnr, ctx_bufnr = window_context.gutter_bufnr, window_context.context_bufnr

  if config.line_numbers and (vim.wo[winid].number or vim.wo[winid].relativenumber) then
    window_context.gutter_winid = display_window(
      gbufnr,
      winid,
      window_context.gutter_winid,
      gutter_width,
      win_height,
      0,
      'treesitter_context_line_number',
      'TreesitterContextLineNumber'
    )
    render_lno(winid, gbufnr, ctx_ranges, gutter_width)
  else
    win_close(window_context.gutter_winid)
  end

  window_context.context_winid = display_window(
    ctx_bufnr,
    winid,
    window_context.context_winid,
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
  highlight_bottom(ctx_bufnr, win_height - 1, 'TreesitterContextBottom')
  horizontal_scroll_contexts(window_context.context_winid)
end

--- @param winid integer
function M.close(winid)
  -- Can't close other windows when the command-line window is open
  if fn.getcmdwintype() ~= '' then
    return
  end

  local window_context = windowContexts[winid]
  if window_context == nil then
    return
  end
  local context_winid, gutter_winid = window_context.context_winid, window_context.gutter_winid

  win_close(context_winid)

  win_close(gutter_winid)

  windowContexts[winid] = nil
end

return M
