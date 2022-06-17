local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local q = util.build_query
local f = util.field_name_query
local t = util.node_type_query

return {
  ['record_declaration' ] = {
    category = CATEGORY.CLASS,
    last = { q{ f'name' } },
  },
  ['enum_declaration' ] = {
    category = CATEGORY.ENUM,
    last = { q{ f'name' } },
  },
  ['function_statement' ] = {
    category = CATEGORY.FUNCTION,
    last = { q{ f'return_type' },  q{ f'signature' } },
  },
  ['numeric_for_statement'] = {
    category = CATEGORY.FOR,
    last = { q{ t'do' } },
  },
  ['generic_for_statement'] = {
    category = CATEGORY.FOR,
    last = { q{ t'do' } },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { q{ t'do' } },
  },
  ['if_statement'] = {
    category = CATEGORY.IF,
    last = { q{ t'then' } },
  },
}
