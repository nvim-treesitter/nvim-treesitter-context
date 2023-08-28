local api, fn = vim.api, vim.fn
local highlighter = vim.treesitter.highlighter

local util = require('treesitter-context.util')
local config = require('treesitter-context.config')

local ns = api.nvim_create_namespace('nvim-treesitter-context')

-- Don't access directly, use get_bufs()
local gutter_bufnr --- @type integer?
local context_bufnr --- @type integer?

local gutter_winid --- @type integer?
local context_winid --- @type integer?

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
            hl_group = hl
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
  add_extmark(bufnr, row, 0, {
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
  highlight_bottom(bufnr, #lno_text - 1)
end

---@param winid? integer
local function win_close(winid)
  vim.schedule(function()
    if winid ~= nil and api.nvim_win_is_valid(winid) then
      api.nvim_win_close(winid, true)
    end
  end)
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

local M = {}

--- @param bufnr integer
--- @param winid integer
--- @param ctx_ranges Range4[]
--- @param ctx_lines string[]
function M.open(bufnr, winid, ctx_ranges, ctx_lines)
  local gutter_width = get_gutter_width(winid)
  local win_width = math.max(1, api.nvim_win_get_width(winid) - gutter_width)

  local win_height = #ctx_lines

  local gbufnr, ctx_bufnr = get_bufs()

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
    render_lno(winid, gbufnr, ctx_ranges, gutter_width)
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
  highlight_bottom(ctx_bufnr, win_height - 1)
  horizontal_scroll_contexts()
end

function M.close()
  -- Can't close other windows when the command-line window is open
  if fn.getcmdwintype() ~= '' then
    return
  end

  win_close(context_winid)
  context_winid = nil

  win_close(gutter_winid)
  gutter_winid = nil
end

return M
