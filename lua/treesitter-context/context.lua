local fn, api = vim.fn, vim.api

local config = require('treesitter-context.config')
local util = require('treesitter-context.util')
local cache = require('treesitter-context.cache')

local get_query = vim.treesitter.query.get or vim.treesitter.query.get_query

--- @param langtree vim.treesitter.LanguageTree
--- @param range Range4
--- @return TSNode[]?
local function get_parent_nodes(langtree, range)
  local tree = langtree:tree_for_range(range, { ignore_injections = true })
  if not tree then
    return
  end

  local root = tree:root()
  local n = root:named_descendant_for_range(unpack(range))

  if not n then
    return
  end

  -- More efficient method for iterating parents

  local ret = {} --- @type TSNode[]

  --- @diagnostic disable-next-line:undefined-field added in 0.11
  if root.child_with_descendant ~= nil then
    local p = root --- @type TSNode?
    while p do
      ret[#ret + 1] = p
      --- @diagnostic disable-next-line:undefined-field added in 0.11
      p = p:child_with_descendant(n) --- @type TSNode?
    end
    ret[#ret + 1] = n
  else
    while n do
      table.insert(ret, 1, n)
      n = n:parent() --- @type TSNode?
    end
  end

  return ret
end

--- @param winid integer
--- @param percent string
--- @return integer
local function max_lines_from_string(winid, percent)
  local win_height = api.nvim_win_get_height(winid)
  local percent_s = percent:match('^(%d+)%%$')
  local percent1 = percent_s and tonumber(percent_s, 10) or 0
  return math.ceil((percent1 / 100) * win_height)
end

--- @param winid integer
--- @return integer
local function calc_max_lines(winid)
  local max_lines = config.max_lines

  if type(max_lines) == 'string' then
    max_lines = max_lines_from_string(winid, max_lines)
  end

  -- ensure we never have zero as max lines
  max_lines = max_lines == 0 and -1 or max_lines

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

--- @param node TSNode
--- @param bufnr integer
--- @return string
local function hash_args(node, bufnr)
  return table.concat({
    node:id(),
    node:symbol(),
    node:child_count(),
    node:type(),
    node:range(),
    bufnr,
  }, ',')
end

--- Run the context query on a node and return the range if it is a valid
--- context node.
--- @param node TSNode
--- @param bufnr integer
--- @param query vim.treesitter.Query
--- @return Range4?
local context_range = cache.memoize(function(node, bufnr, query)
  --- @diagnostic disable-next-line:missing-fields
  local range = { node:range() } --- @type Range4
  range[3] = range[1] + 1
  range[4] = 0

  -- max_start_depth depth is only supported in nvim 0.10. It is ignored on
  -- versions 0.9 or less. It is only needed to improve performance
  for _, match in query:iter_matches(node, bufnr, 0, -1, { max_start_depth = 0 }) do
    local r = false

    for id, nodes in pairs(match) do
      --- In Nvim 0.9 node is a TSNode, in Nvim 0.10+ it is a list of TSNode
      --- @type TSNode
      local node0 = type(nodes) == 'table' and nodes[#nodes] or nodes

      local srow, scol, erow, ecol = node0:range()

      local name = query.captures[id] -- name of the capture in the query
      if name == 'context' then
        r = r or (node == node0)
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
end, hash_args)

--- @param lang string
--- @return vim.treesitter.Query?
local function get_context_query(lang)
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

--- @param context_ranges Range4[]
--- @param context_lines string[][]
--- @param trim integer
--- @param top boolean
local function trim_contexts(context_ranges, context_lines, trim, top)
  while trim > 0 do
    local idx = top and 1 or #context_ranges
    local context_to_trim = context_ranges[idx]
    if not context_to_trim then
      return
    end

    local height = util.get_range_height(context_to_trim)

    if height <= trim then
      table.remove(context_ranges, idx)
      table.remove(context_lines, idx)
    else
      context_to_trim[3] = context_to_trim[3] - trim + (context_to_trim[4] == 0 and 0 or 1)
      context_to_trim[4] = 0
      local context_lines_to_trim = context_lines[idx]
      for _ = 1, trim do
        context_lines_to_trim[#context_lines_to_trim] = nil
      end
    end
    trim = math.max(0, trim - height)
  end
end

--- @param range Range4
--- @param bufnr integer
--- @return Range4, string[]
local function get_text_for_range(range, bufnr)
  local start_row, end_row, end_col = range[1], range[3], range[4]

  if end_col == 0 then
    end_row = end_row - 1
    end_col = -1
  end

  local lines = api.nvim_buf_get_text(bufnr, start_row, 0, end_row, -1, {})

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

  -- Adjust the end row to include the whole line. If we decide to clip
  -- at the end column, then we also need to adjust lines.
  -- if end_col == -1 then
  if end_col ~= 0 then
    end_col = 0
    end_row = end_row + 1
  end

  return { start_row, 0, end_row, end_col }, lines
end

local M = {}

--- @param bufnr integer
--- @param range Range4
--- @return vim.treesitter.LanguageTree[]
local function get_parent_langtrees(bufnr, range)
  local root_tree = vim.treesitter.get_parser(bufnr)
  if not root_tree then
    return {}
  end

  --- @diagnostic disable-next-line:redundant-parameter added in 0.11
  root_tree:parse(range, function(...) end)
  local ret = { root_tree }

  while true do
    local child_langtree = nil

    for _, langtree in pairs(ret[#ret]:children()) do
      if langtree:contains(range) then
        child_langtree = langtree
        break
      end
    end

    if not child_langtree then
      break
    end
    ret[#ret + 1] = child_langtree
  end

  return ret
end

--- Iterate Parent nodes of a range of LanguageTree's with a context query
--- @param bufnr integer
--- @param line_range Range4
--- @return fun(): TSNode[]?, vim.treesitter.Query?
local function iter_context_parents(bufnr, line_range)
  local i = 0
  local trees = get_parent_langtrees(bufnr, line_range)
  return function()
    --- @type TSNode[]?, vim.treesitter.Query?
    local parents, query
    repeat
      i = i + 1
      local tree = trees[i]
      if not tree then
        return
      end
      parents = get_parent_nodes(tree, line_range)
      query = get_context_query(tree:lang())
    until parents and query
    return parents, query
  end
end

--- Creates a copy of a list-like table such that any nested tables are
--- "unrolled" and appended to the result.
---
--- @see From https://github.com/premake/premake-core/blob/master/src/base/table.lua
---
--- @param t table List-like table
--- @return table Flattened copy of the given list-like table
local function tbl_flatten(t)
  local result = {}
  --- @param _t table<any,any>
  local function _tbl_flatten(_t)
    for i = 1, #_t do
      local v = _t[i]
      if type(v) == 'table' then
        _tbl_flatten(v)
      elseif v then
        table.insert(result, v)
      end
    end
  end
  _tbl_flatten(t)
  return result
end

--- @param range Range4
local function range_is_valid(range)
  -- Zero width
  if range[1] == range[3] and range[2] == range[4] then
    return false
  end

  return true
end

--- @param winid? integer
--- @return Range4[]?, string[]?
function M.get(winid)
  winid = winid or api.nvim_get_current_win()
  local bufnr = api.nvim_win_get_buf(winid)

  -- vim.treesitter.get_parser() calls bufload(), but we don't actually want to load the buffer:
  -- this method is called during plugin init, before other plugins or the user's config
  -- have a chance to initialize.
  -- They may want to register autocmds, and this would prevent them from firing.
  if not api.nvim_buf_is_loaded(bufnr) then
    return
  end

  if not pcall(vim.treesitter.get_parser, bufnr) then
    return
  end

  local max_lines = calc_max_lines(winid)

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
    local col0 = offset == 0 and col or 0
    local line_range = { node_row, col0, node_row, col0 + 1 }

    context_ranges = {}
    context_lines = {}
    contexts_height = 0

    for parents, query in iter_context_parents(bufnr, line_range) do
      for _, parent in ipairs(parents) do
        local parent_start_row = parent:range()

        local num_context_lines = math.min(max_lines, contexts_height)

        -- NOTE: this avoids covering up context by separator line
        --  but only when there is a context to display
        local separator_offset = (num_context_lines > 0 and config.separator) and 1 or 0

        local contexts_end_row = top_row + separator_offset + num_context_lines

        -- Only process the parent if it is not in view.
        if parent_start_row < contexts_end_row then
          local range0 = context_range(parent, bufnr, query)
          if range0 and range_is_valid(range0) then
            local range, lines = get_text_for_range(range0, bufnr)
            if range_is_valid(range) then
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

  return context_ranges, tbl_flatten(context_lines)
end

return M
