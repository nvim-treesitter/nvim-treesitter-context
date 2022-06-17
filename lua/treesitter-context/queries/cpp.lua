local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local q = util.build_query
local f = util.field_name_query
local t = util.node_type_query

return {
  ['class_specifier'] = {
    category = CATEGORY.CLASS,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['struct_specifier'] = {
    category = CATEGORY.STRUCT,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['enum_specifier'] = {
    category = CATEGORY.ENUM,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['function_definition'] = {
    category = CATEGORY.FUNCTION,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { q{ t')' } },
    next = { q{ t'compound_statement', offsetcol = 1 } },
  },
  ['while_statement' ] = {
    category = CATEGORY.WHILE,
    last = { q{ f'condition' } },
    next = { q{ t'compound_statement', offsetcol = 1 } },
  },
  ['if_statement' ] = {
    category = CATEGORY.IF,
    last = { q{ f'condition' } },
    next = { q{ f'consequence', t'compound_statement', offsetcol = 1 } },
  },
  ['switch_statement' ] = {
    category = CATEGORY.SWITCH,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['case_statement' ] = {
    category = CATEGORY.CASE,
    last = { q{ t':' } },
    next = { q{ t'compound_statement', offsetcol = 1 } },
  },
}
