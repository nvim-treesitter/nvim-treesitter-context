local fn, api = vim.fn, vim.api

local config = require('treesitter-context.config')
local util = require('treesitter-context.util')
local cache = require('treesitter-context.cache')

local get_lang = vim.treesitter.language.get_lang or require('nvim-treesitter.parsers').ft_to_lang

--- @diagnostic disable-next-line:deprecated
local get_query = vim.treesitter.query.get or vim.treesitter.query.get_query

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

--- @param winid integer
--- @return integer
local function calc_max_lines(winid)
  local max_lines = config.max_lines == 0 and -1 or config.max_lines

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

---@param context_ranges Range4[]
---@param context_lines string[][]
---@param trim integer
---@param top boolean
local function trim_contexts(context_ranges, context_lines, trim, top)
  while trim > 0 do
    local idx = top and 1 or #context_ranges
    local context_to_trim = context_ranges[idx]

    local height = util.get_range_height(context_to_trim)

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

local M = {}

--- @param bufnr integer
--- @param winid integer
--- @return Range4[]?, string[]?
function M.get(bufnr, winid)
  local max_lines = calc_max_lines(winid)

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
            contexts_height = contexts_height - util.get_range_height(last_context)
            context_ranges[#context_ranges] = nil
            context_lines[#context_lines] = nil
          end

          contexts_height = contexts_height + util.get_range_height(range)
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

return M
