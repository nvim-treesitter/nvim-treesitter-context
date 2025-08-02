local api, fn = vim.api, vim.fn
local highlighter = vim.treesitter.highlighter

local util = require('treesitter-context.util')
local config = require('treesitter-context.config')

local ns = api.nvim_create_namespace('nvim-treesitter-context')

--- List of free buffers that can be reused.
--- @type integer[]
local buffer_pool = {}

local MAX_BUFFER_POOL_SIZE = 20

--- @class WindowContext
--- @field context_winid integer? The context window ID.
--- @field gutter_winid integer? The gutter window ID.

--- A table mapping window IDs to WindowContext objects.
--- This table contains mappings for windows where the context is displayed.
--- @type table<integer, WindowContext>
local window_contexts = {}

--- @return integer buf
local function create_or_get_buf()
  for index = #buffer_pool, 1, -1 do
    local buf = table.remove(buffer_pool, index)
    if api.nvim_buf_is_valid(buf) then
      return buf
    end
  end

  local buf = api.nvim_create_buf(false, true)

  vim.bo[buf].undolevels = -1

  return buf
end

--- @param winid integer
--- @param context_winid integer?
--- @param width integer
--- @param height integer
--- @param col integer
--- @param ty string
--- @param hl string
--- @return integer Window ID of context window
local function display_window(winid, context_winid, width, height, col, ty, hl)
  if not context_winid then
    local sep = config.separator and { config.separator, 'TreesitterContextSeparator' } or nil
    context_winid = api.nvim_open_win(create_or_get_buf(), false, {
      win = winid,
      relative = 'win',
      width = width,
      height = height,
      row = 0,
      col = col,
      focusable = false,
      style = 'minimal',
      noautocmd = true,
      zindex = config.zindex,
      border = sep and { '', '', '', '', sep, sep, sep, '' } or 'none',
    })
    vim.w[context_winid][ty] = true
    vim.wo[context_winid].wrap = false
    vim.wo[context_winid].foldenable = false
    vim.wo[context_winid].winhl = 'NormalFloat:' .. hl
    vim.wo[context_winid].conceallevel = vim.wo[winid].conceallevel
  elseif api.nvim_win_is_valid(context_winid) then
    api.nvim_win_set_config(context_winid, {
      win = winid,
      relative = 'win',
      width = width,
      height = height,
      row = 0,
      col = col,
    })
  end
  return context_winid
end

--- @param winid integer
--- @return integer
local function get_gutter_width(winid)
  return fn.getwininfo(winid)[1].textoff
end

--- @param name string
--- @param from_buf integer
--- @param to_buf integer
local function copy_option(name, from_buf, to_buf)
  --- @cast name any
  local current = vim.bo[from_buf][name]
  -- Only set when necessary to avoid OptionSet events
  if current ~= vim.bo[to_buf][name] then
    vim.bo[to_buf][name] = current
  end
end

--- @param bufnr integer
--- @param row integer
--- @param col integer
--- @param opts vim.api.keyset.set_extmark
--- @param ns0? integer
local function add_extmark(bufnr, row, col, opts, ns0)
  local ok, err = pcall(api.nvim_buf_set_extmark, bufnr, ns0 or ns, row, col, opts)
  if not ok then
    local range = vim.inspect({ row, col, opts.end_row, opts.end_col }) --- @type string
    error(string.format('Could not apply exmtark to %s: %s', range, err), 2)
  end
end

--- @param buf_query vim.treesitter.highlighter.Query
--- @param capture integer
--- @return integer?
local function get_hl(buf_query, capture)
  --- @diagnostic disable-next-line: invisible naughty
  if buf_query.get_hl_from_capture then
    --- @diagnostic disable-next-line: invisible naughty
    return buf_query:get_hl_from_capture(capture)
  end
  --- @diagnostic disable-next-line: invisible naughty
  return buf_query.hl_cache[capture]
end

--- Is a position a after another position b?
--- @param arow integer
--- @param acol integer
--- @param brow integer
--- @param bcol integer
--- @return boolean
local function is_after(arow, acol, brow, bcol)
  return arow > brow or (arow == brow and acol > bcol)
end

--- @param bufnr integer
--- @param ctx_bufnr integer
--- @param contexts Range4[]
local function highlight_contexts(bufnr, ctx_bufnr, contexts)
  local buf_highlighter = highlighter.active[bufnr]

  copy_option('tabstop', bufnr, ctx_bufnr)

  if not buf_highlighter then
    -- Use standard highlighting when TS highlighting is not available
    copy_option('filetype', bufnr, ctx_bufnr)
    return
  end

  local parser = buf_highlighter.tree

  parser:for_each_tree(function(tstree, ltree)
    --- @diagnostic disable-next-line:invisible
    local buf_query = buf_highlighter:get_query(ltree:lang())
    --- @diagnostic disable-next-line:invisible
    local query = buf_query:query()
    if not query then
      return
    end

    local offset = 0
    for _, context in ipairs(contexts) do
      local pri_offset = 0
      local start_row, end_row, end_col = context[1], context[3], context[4]

      for capture, node, metadata in
        query:iter_captures(tstree:root(), bufnr, start_row, end_row + 1)
      do
        local range = vim.treesitter.get_range(node, bufnr, metadata[capture])
        local nsrow, nscol, nerow, necol = range[1], range[2], range[4], range[5]

        if nsrow >= start_row then
          if is_after(nsrow, nscol, end_row, end_col) then
            -- Node range begins after the context range, skip it
            break
          elseif is_after(nerow, necol, end_row, end_col) then
            -- Node range extends beyond the context range, clip it
            nerow, necol = end_row, end_col
          end

          local msrow = offset + (nsrow - start_row)
          local merow = offset + (nerow - start_row)

          local priority = tonumber(metadata.priority)
            or (vim.hl and vim.hl.priorities.treesitter)
            or vim.highlight.priorities.treesitter

          -- The "conceal" attribute can be set at the pattern level or on a particular capture
          local conceal = metadata.conceal or metadata[capture] and metadata[capture].conceal

          add_extmark(ctx_bufnr, msrow, nscol, {
            end_row = merow,
            end_col = necol,
            priority = priority + pri_offset,
            hl_group = get_hl(buf_query, capture),
            conceal = conceal,
          })

          -- TODO(lewis6991): Extmarks of equal priority appear to apply
          -- highlights differently between ephemeral and non-ephemeral:
          -- - ephemeral:  give priority to the last mark applied
          -- - non-ephemeral: give priority to the first mark applied
          --
          -- In order the match the behaviour of main highlighter which uses
          -- ephemeral marks, make sure increase the priority as we apply marks.
          pri_offset = pri_offset + 1
        end
      end
      offset = offset + util.get_range_height(context)
    end
  end)
end

--- @class StatusLineHighlight
--- @field group string
--- @field groups? string[]
--- @field start integer

--- @param ctx_node_line_num integer
--- @param win integer
--- @return integer
local function get_relative_line_num(ctx_node_line_num, win)
  local cursor_line_num = fn.line('.', win)
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
      fillchar = ' ', -- Fixed in Neovim 0.10 (#396)
    })
    if ok then
      return data.str, data.highlights
    end
  end
  local relnum --- @type integer?
  if vim.wo[win].relativenumber then
    relnum = get_relative_line_num(lnum, win)
  end
  return string.format('%' .. width .. 'd', relnum or lnum)
end

--- @param bufnr integer
--- @param row integer
--- @param hl_group 'TreesitterContextBottom' | 'TreesitterContextLineNumberBottom'
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
        local hl_groups = hl.groups or { hl.group }
        for i, shl in ipairs(hl_groups) do
          hl_groups[i] = shl:find('LineNr') and 'TreesitterContextLineNumber' or shl
        end
        add_extmark(buf, line - 1, col, {
          end_col = endcol,
          --- @diagnostic disable-next-line:assign-type-mismatch added in 0.11
          hl_group = hl.groups and hl_groups or hl_groups[1],
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
    vim.bo[bufnr].modifiable = true
    api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modifiable = false
    vim.bo[bufnr].modified = false
  end

  return redraw
end

--- @param win integer
--- @param bufnr integer
--- @param contexts Range4[]
--- @param gutter_width integer
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

--- @param context_winid? integer
local function close(context_winid)
  vim.schedule(function()
    if not context_winid or not api.nvim_win_is_valid(context_winid) then
      return
    end

    local bufnr = api.nvim_win_get_buf(context_winid)
    api.nvim_win_close(context_winid, true)

    -- Add the buffer back to the pool for reuse.
    if bufnr and api.nvim_buf_is_valid(bufnr) then
      buffer_pool[#buffer_pool + 1] = bufnr
    end

    -- Delete excess buffers in the pool.
    -- Can't delete buffers when the command-line window is open.
    if fn.getcmdwintype() == '' then
      while #buffer_pool > MAX_BUFFER_POOL_SIZE do
        local buf = table.remove(buffer_pool, #buffer_pool)
        if api.nvim_buf_is_valid(buf) then
          api.nvim_buf_delete(buf, { force = true })
        end
      end
    end
  end)
end

--- @param winid integer
--- @param context_winid integer
local function horizontal_scroll_contexts(winid, context_winid)
  local active_win_view = api.nvim_win_call(winid, fn.winsaveview)
  --- @type vim.fn.winsaveview.ret
  local context_win_view = api.nvim_win_call(context_winid, fn.winsaveview)
  if active_win_view.leftcol ~= context_win_view.leftcol then
    context_win_view.leftcol = active_win_view.leftcol
    api.nvim_win_call(context_winid, function()
      return fn.winrestview({ leftcol = context_win_view.leftcol })
    end)
  end
end

--- @param bufnr integer
--- @param ctx_bufnr integer
--- @param contexts Range4[]
local function copy_extmarks(bufnr, ctx_bufnr, contexts)
  local offset = 0
  for _, context in ipairs(contexts) do
    local ctx_srow, ctx_scol, ctx_erow, ctx_ecol = context[1], context[2], context[3], context[4]
    local extmarks = api.nvim_buf_get_extmarks(
      bufnr,
      -1,
      { ctx_srow, ctx_scol },
      { ctx_erow, ctx_ecol },
      { details = true }
    )

    local namespaces = {} --- @type table<integer, true>
    for nm, id in pairs(api.nvim_get_namespaces()) do
      -- Only copy extmarks from core as they are the only ones we can update
      -- reliably.
      if vim.startswith(nm, 'nvim.') then
        namespaces[id] = true
      end
    end

    --- @param e vim.api.keyset.get_extmark_item
    extmarks = vim.tbl_filter(function(e)
      local opts = e[4] --[[@as vim.api.keyset.extmark_details]]
      return namespaces[opts.ns_id]
    end, extmarks)

    for _, m in ipairs(extmarks) do
      local id, row, col = m[1], m[2], m[3]
      local opts = m[4] --[[@as vim.api.keyset.extmark_details]]
      local start_row = offset + (row - ctx_srow)

      local end_row --- @type integer?
      local end_col = opts.end_col
      local mend_row = opts.end_row
      if mend_row then
        if is_after(mend_row, assert(end_col), ctx_erow, ctx_ecol) then
          mend_row = ctx_erow
          end_col = ctx_ecol
        end

        end_row = offset + (mend_row - ctx_srow)
      end

      local virt_text_pos = opts.virt_text_pos
      if virt_text_pos == 'win_col' then
        virt_text_pos = nil
      end

      -- Use pcall incase fields from opts are inconsistent with opts in
      -- nvim_buf_set_extmark
      pcall(add_extmark, ctx_bufnr, start_row, col, {
        id = id,
        end_row = end_row,
        end_col = end_col,
        priority = opts.priority,
        hl_group = opts.hl_group,
        --- @diagnostic disable-next-line:assign-type-mismatch bug in core
        end_right_gravity = opts.end_right_gravity,
        right_gravity = opts.right_gravity,
        hl_eol = opts.hl_eol,
        virt_text = opts.virt_text,
        virt_text_hide = opts.virt_text_hide,
        virt_text_pos = virt_text_pos,
        virt_text_repeat_linebreak = opts.virt_text_repeat_linebreak,
        virt_text_win_col = opts.virt_text_win_col,
        hl_mode = opts.hl_mode,
        line_hl_group = opts.line_hl_group,
        spell = opts.spell,
        --- @diagnostic disable-next-line:assign-type-mismatch fixed in 0.11
        url = opts.url,
      }, opts.ns_id)
    end
    offset = offset + util.get_range_height(context)
  end
end

local M = {}

--- @param winid integer
--- @param ctx_ranges Range4[]
--- @param ctx_lines string[]
--- @param force_hl_update? boolean
function M.open(winid, ctx_ranges, ctx_lines, force_hl_update)
  local bufnr = api.nvim_win_get_buf(winid)
  local gutter_width = get_gutter_width(winid)
  local win_width = math.max(1, api.nvim_win_get_width(winid) - gutter_width)

  local win_height = math.max(1, #ctx_lines)

  window_contexts[winid] = window_contexts[winid] or {}
  local window_context = window_contexts[winid]

  if gutter_width > 0 then
    window_context.gutter_winid = display_window(
      winid,
      window_context.gutter_winid,
      gutter_width,
      win_height,
      0,
      'treesitter_context_line_number',
      'TreesitterContextLineNumber'
    )
    if
      api.nvim_win_is_valid(window_context.gutter_winid)
      and (vim.wo[winid].number or vim.wo[winid].relativenumber)
    then
      render_lno(winid, api.nvim_win_get_buf(window_context.gutter_winid), ctx_ranges, gutter_width)
    end
  else
    close(window_context.gutter_winid)
    window_context.gutter_winid = nil
  end

  window_context.context_winid = display_window(
    winid,
    window_context.context_winid,
    win_width,
    win_height,
    gutter_width,
    'treesitter_context',
    'TreesitterContext'
  )

  if not api.nvim_win_is_valid(window_context.context_winid) then
    return
  end

  local ctx_bufnr = api.nvim_win_get_buf(window_context.context_winid)

  local changed = set_lines(ctx_bufnr, ctx_lines)

  if changed or force_hl_update then
    -- Update highlights
    api.nvim_buf_clear_namespace(ctx_bufnr, -1, 0, -1)
    highlight_contexts(bufnr, ctx_bufnr, ctx_ranges)
    copy_extmarks(bufnr, ctx_bufnr, ctx_ranges)
    highlight_bottom(ctx_bufnr, win_height - 1, 'TreesitterContextBottom')
    horizontal_scroll_contexts(winid, window_context.context_winid)
  end
end

--- @param exclude_winids integer[] The only window for which the context should be displayed.
function M.close_contexts(exclude_winids)
  for winid in pairs(window_contexts) do
    if not vim.tbl_contains(exclude_winids, winid) then
      M.close(winid)
    end
  end
end

--- @param winid integer
function M.close(winid)
  local window_context = window_contexts[winid]
  if window_context then
    close(window_context.context_winid)
    close(window_context.gutter_winid)
    window_contexts[winid] = nil
  end
end

return M
