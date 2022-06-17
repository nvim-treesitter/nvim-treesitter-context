local M = {}

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

function M.field_name_query(text)
  return {
    text = text,
    kind = M.QUERY.FIELD_NAME,
  }
end

function M.node_type_query(text)
  return {
    text = text,
    kind = M.QUERY.NODE_TYPE,
  }
end

return M
