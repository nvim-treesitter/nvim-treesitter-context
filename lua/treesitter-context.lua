local api = vim.api
local ts_utils = require'nvim-treesitter.ts_utils'
local highlighter = vim.treesitter.highlighter
local parsers = require'nvim-treesitter.parsers'

local augroup = api.nvim_create_augroup
local command = api.nvim_create_user_command

local function word_pattern(p)
  return '%f[%w]' .. p .. '%f[^%w]'
end

local defaultConfig = {
  enable = true,
  throttle = false,
  max_lines = 0, -- no limit
}

local config = {}

-- Constants

-- Tells us at which node type to stop when highlighting a multi-line
-- node. If not specified, the highlighting stops after the first line.
local last_types = {
  [word_pattern('function')] = {
    c = 'function_declarator',
    cpp = 'function_declarator',
    lua = 'parameters',
    python = 'parameters',
    rust = 'parameters',
    javascript = 'formal_parameters',
    typescript = 'formal_parameters',
  },
}

-- Tells us which leading child node type to skip when highlighting a
-- multi-line node.
local skip_leading_types = {
  [word_pattern('class')] = {
    php = 'attribute_list',
  },
  [word_pattern('method')] = {
    php = 'attribute_list',
  },
}

-- There are language-specific
local DEFAULT_TYPE_PATTERNS = {
  -- These catch most generic groups, eg "function_declaration" or "function_block"
  default = {
    'class',
    'function',
    'method',
    'for',
    'while',
    'if',
    'switch',
    'case',
  },
  tex = {
    'chapter',
    'section',
    'subsection',
    'subsubsection',
  },
  rust = {
    'impl_item',
  },
  vhdl = {
    'process_statement',
    'architecture_body',
    'entity_declaration',
  },
  exact_patterns = {},
}

local DEFAULT_TYPE_EXCLUDE_PATTERNS = {
  default = {},
  teal = {
    'function_body',
  },
}

local INDENT_PATTERN = '^%s+'

-- Script variables

local did_setup = false
local enabled = false
local gutter_winid, context_winid
local gutter_bufnr, context_bufnr -- Don't access directly, use get_bufs()
local ns = api.nvim_create_namespace('nvim-treesitter-context')
local previous_nodes

local function get_root_node()
  local tree = parsers.get_parser():parse()[1]
  return tree:root()
end

local function is_excluded(node, filetype)
  local node_type = node:type()
  for _, rgx in ipairs(config.exclude_patterns.default) do
    if node_type:find(rgx) then
      return true
    end
  end
  local filetype_patterns = config.exclude_patterns[filetype]
  for _, rgx in ipairs(filetype_patterns or {}) do
    if node_type:find(rgx) then
      return true
    end
  end
  return false
end

local function is_valid(node, filetype)
  if is_excluded(node, filetype) then
    return false
  end

  local node_type = node:type()
  for _, rgx in ipairs(config.patterns.default) do
    if node_type:find(rgx) then
      return true
    end
  end
  local filetype_patterns = config.patterns[filetype]
  for _, rgx in ipairs(filetype_patterns or {}) do
    if node_type:find(rgx) then
      return true
    end
  end
  return false
end

local function get_type_pattern(node, type_patterns)
  local node_type = node:type()
  for _, rgx in ipairs(type_patterns) do
    if node_type:find(rgx) then
      return rgx
    end
  end
end

local function find_node(node, type)
  local children = ts_utils.get_named_children(node)
  for _, child in ipairs(children) do
    if child:type() == type then
      return child
    end
  end
  for _, child in ipairs(children) do
    local deep_child = find_node(child, type)
    if deep_child ~= nil then
      return deep_child
    end
  end
end

local function get_text_for_node(node)
  local type = get_type_pattern(node, config.patterns.default) or node:type()
  local filetype = vim.bo.filetype

  local skip_leading_type = (skip_leading_types[type] or {})[filetype]
  if skip_leading_type then
    local children = ts_utils.get_named_children(node)
    for _, child in ipairs(children) do
      if child:type() ~= skip_leading_type then
        node = child
        break
      end
    end
  end

  local start_row, start_col = node:start()
  local end_row, end_col     = node:end_()

  local lines = vim.split(vim.treesitter.query.get_node_text(node, 0), '\n')

  if start_col ~= 0 then
    lines[1] = api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1]
  end
  start_col = 0

  local last_type = (last_types[type] or {})[filetype]

  local last_position

  if last_type then
    local child = find_node(node, last_type)

    if child then
      last_position = {child:end_()}

      end_row = last_position[1]
      end_col = last_position[2]
      local last_index = end_row - start_row
      lines = vim.list_slice(lines, 1, last_index + 1)
      lines[#lines] = lines[#lines]:sub(1, end_col)
    end
  end

  if not last_position then
    lines = vim.list_slice(lines, 1, 1)
    end_row = start_row
    end_col = #lines[1]
  end

  local range = {start_row, start_col, end_row, end_col}

  return lines, range
end

-- Merge lines, removing the indentation after 1st line
local function merge_lines(lines)
  local text = { lines[1] }
  for i = 2, #lines do
    text[i] = lines[i]:gsub(INDENT_PATTERN, '')
  end
  return table.concat(text, ' ')
end

-- Get indentation for lines except first
local function get_indents(lines)
  local indents = vim.tbl_map(function(line)
    local indent = line:match(INDENT_PATTERN)
    return indent and #indent or 0
  end, lines)
  -- Dont skip first line indentation
  indents[1] = 0
  return indents
end

local function get_gutter_width()
  return vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff
end

local cursor_moved_vertical
do
  local line
  cursor_moved_vertical = function()
    local newline = vim.api.nvim_win_get_cursor(0)[1]
    if newline ~= line then
      line = newline
      return true
    end
    return false
  end
end

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

local function display_window(bufnr, winid, width, height, col, ty, hl)
  if not winid or not api.nvim_win_is_valid(winid) then
    winid = api.nvim_open_win(bufnr, false, {
      relative = 'win',
      width = width,
      height = height,
      row = 0,
      col = col,
      focusable = false,
      style = 'minimal',
      noautocmd = true,
    })
    api.nvim_win_set_var(winid, ty, true)
    vim.wo[winid].winhl = 'NormalFloat:'..hl
    vim.wo[winid].foldenable = false
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

local function reverse_table(t)
  local r = {}

  if t then
    for i = #t, 1, -1 do
      r[#r+1] = t[i]
    end
  end

  return r
end

local function get_parent_matches(max_lines)
  if max_lines == 0 then
    return
  end

  if not parsers.has_parser() then
    return
  end

  local lnum, col = unpack(api.nvim_win_get_cursor(0))

  local node = get_root_node():named_descendant_for_range(lnum-1, col, lnum-1, col)
  if not node then
    return
  end

  local parent_matches = {}
  local lines = 0
  local last_row = -1
  local topline = vim.fn.line('w0')

  -- save nodes in a table to iterate from top to bottom
  local parents = {}
  while node ~= nil do
    parents[#parents+1] = node
    node = node:parent()
  end

  for i = #parents, 1, -1 do
    local parent = parents[i]
    local row = parent:start()

    if is_valid(parent, vim.bo.filetype)
        and row > 0
        and row < (topline + #parent_matches - 1)
        and row ~= last_row then
      table.insert(parent_matches, 1, parent)

      if row ~= last_row then
        lines = lines + 1
        last_row = row
      end

      if lines >= max_lines then
        break
      end
    end
  end

  return reverse_table(parent_matches)
end

local function throttle_fn(fn)
  local running = false
  return function()
    if not running then
      running = true
      vim.defer_fn(function()
        fn()
        running = false
      end, 100)
    end
  end
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
  end

  return redraw
end

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

  local buf_query = buf_highlighter:get_query(parsers.ft_to_lang(vim.bo.filetype))

  local query = buf_query:query()
  local root = get_root_node()

  for i, context in ipairs(contexts) do
    local start_row, _, end_row, end_col = unpack(context.range)
    local indents = context.indents
    local lines = context.lines

    local start_row_abs = context.node:start()

    for capture, node in query:iter_captures(root, bufnr, start_row, context.node:end_()) do
      local node_start_row, node_start_col, node_end_row, node_end_col = node:range()

      if node_end_row > end_row or
        (node_end_row == end_row and node_end_col > end_col) then
        break
      end

      if node_start_row >= start_row_abs then
        local intended_start_row = node_start_row - start_row_abs

        -- Add 1 for each space added between lines when
        -- we replace "\n" with " "
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

local function build_lno_str(lnum, width)
  return string.format('%'..width..'d', lnum)
end

local function open(ctx_nodes)
  local bufnr = api.nvim_get_current_buf()

  local gutter_width = get_gutter_width()
  local win_width  = math.max(1, api.nvim_win_get_width(0) - gutter_width)
  local win_height = math.max(1, #ctx_nodes)

  local gbufnr, ctx_bufnr = get_bufs()

  if vim.wo.number or vim.wo.relativenumber then
    gutter_winid = display_window(
      gbufnr, gutter_winid, gutter_width, win_height, 0,
      'treesitter_context_line_number', 'TreesitterContextLineNumber')
  end

  context_winid = display_window(
    ctx_bufnr, context_winid, win_width, win_height, gutter_width,
    'treesitter_context', 'TreesitterContext')

  -- Set text

  local context_text = {}
  local lno_text = {}
  local contexts = {}

  for _, node in ipairs(ctx_nodes) do
    local lines, range = get_text_for_node(node)
    local text = merge_lines(lines)

    contexts[#contexts+1] = {
      node = node,
      lines = lines,
      range = range,
      indents = get_indents(lines),
    }

    table.insert(context_text, text)
    table.insert(lno_text, build_lno_str(range[1]+1, gutter_width-1))
  end

  if not set_lines(ctx_bufnr, context_text) then
    -- Context didn't change, can return here
    return
  end

  set_lines(gbufnr, lno_text)

  highlight_contexts(bufnr, ctx_bufnr, contexts)
end

local function calc_max_lines(config_max)
  local max_lines = config_max
  max_lines = max_lines == 0 and -1 or max_lines

  local wintop = vim.fn.line('w0')
  local cursor = vim.fn.line('.')
  local max_from_cursor = cursor - wintop
  if max_lines ~= -1 then
    max_lines = math.min(max_lines, max_from_cursor)
  else
    max_lines = max_from_cursor
  end

  return max_lines
end

local function update_context()
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

    open(context)
  else
    close()
  end
end

local throttled_update_context = throttle_fn(update_context)

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

local function update()
  if config.throttle then
    throttled_update_context()
  else
    update_context()
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

  config                  = vim.tbl_deep_extend("force", {}, defaultConfig, userOptions)
  config.patterns         = vim.tbl_deep_extend("force", {}, DEFAULT_TYPE_PATTERNS, userOptions.patterns or {})
  config.exclude_patterns = vim.tbl_deep_extend("force", {}, DEFAULT_TYPE_EXCLUDE_PATTERNS, userOptions.exclude_patterns or {})
  config.exact_patterns   = vim.tbl_deep_extend("force", {}, userOptions.exact_patterns or {})

  for filetype, patterns in pairs(config.patterns) do
    -- Map with word_pattern only if users don't need exact pattern matching
    if not config.exact_patterns[filetype] then
      config.patterns[filetype] = vim.tbl_map(word_pattern, patterns)
    end
  end

  if config.enable then
    M.enable()
  else
    M.disable()
  end
end

command('TSContextEnable' , M.enable , {})
command('TSContextDisable', M.disable, {})
command('TSContextToggle' , M.toggle , {})

api.nvim_set_hl(0, 'TreesitterContext'          , {link = 'NormalFloat', default = true})
api.nvim_set_hl(0, 'TreesitterContextLineNumber', {link = 'LineNr'     , default = true})

-- Setup with default options if user didn't call setup()
autocmd_for_group('treesitter_context')('VimEnter', function()
  M.setup()
end)

return M
