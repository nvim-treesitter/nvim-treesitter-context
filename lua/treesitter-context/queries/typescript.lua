local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local q = util.build_query
local f = util.field_name_query
local t = util.node_type_query

return {
  ['class_declaration'] = {
    category = CATEGORY.CLASS,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['interface_declaration'] = {
    category = CATEGORY.INTERFACE,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['enum_declaration'] = {
    category = CATEGORY.INTERFACE,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['function_declaration'] = {
    category = CATEGORY.FUNCTION,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['method_declaration'] = {
    category = CATEGORY.METHOD,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { q{ t')' } },
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['for_in_statement'] = {
    category = CATEGORY.FOR,
    last = { q{ t')' } },
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { q{ f'condition' } },
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['if_statement' ] = {
    category = CATEGORY.IF,
    last = { q{ f'condition' } },
    next = { q{ f'consequence', t'statement_block', offsetcol = 1 } },
  },
  ['switch_statement' ] = {
    category = CATEGORY.SWITCH,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['switch_case' ] = {
    category = CATEGORY.CASE,
    last = { q{ t':' } },
    next = { q{ f'body', t'statement_block', offsetcol = 1 } },
  },
  ['switch_default' ] = {
    category = CATEGORY.CASE,
    last = { q{ t':' } },
    next = { q{ f'body', t'statement_block', offsetcol = 1 } },
  },
}
