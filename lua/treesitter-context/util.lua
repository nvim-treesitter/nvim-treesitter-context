local M = {}

---@class ContextQuery
---@field category number
---@field skip NodeQuery[]|nil
---@field last NodeQuery[]|nil
---@field next NodeQuery[]|nil

---@class NodeQuery:NodeQueryPart[]
---@field offsetrow number|nil
---@field offsetcol number|nil

---@class NodeQueryPart
---@field kind number
---@field text string

M.CATEGORY = {
  CLASS = 1,
  INTERFACE = 2,
  STRUCT = 3,
  ENUM = 4,
  FUNCTION = 5,
  METHOD = 6,
  FOR = 7,
  WHILE = 8,
  IF = 9,
  SWITCH = 10,
  CASE = 11,
  SECTION = 12,
}

M.QUERY = {
  FIELD_NAME = 1,
  NODE_TYPE = 2,
}

local NodeQuery = {}

function NodeQuery:matches(node, field)
  for _, q in ipairs(self) do
    if q.kind == M.QUERY.FIELD_NAME then
      if q.text ~= field then
        return false
      end
    elseif q.kind == M.QUERY.NODE_TYPE then
      if q.text ~= node:type() then
        return false
      end
    end
  end

  return true
end

---@param query table
---@return NodeQuery
function M.build_query(query)
  return setmetatable(query, { __index = NodeQuery })
end

---@param val string
---@return NodeQueryPart
function M.field_name_query(val)
  return {
    kind = M.QUERY.FIELD_NAME,
    text = val,
  }
end

---@param val string
---@return NodeQueryPart
function M.node_type_query(val)
  return {
    kind = M.QUERY.NODE_TYPE,
    text = val,
  }
end

return M
