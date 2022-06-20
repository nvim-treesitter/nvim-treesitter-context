local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local q = util.build_query
local f = util.field_name_query
local t = util.node_type_query

return {
  ['class_declaration'] = {
    category = CATEGORY.CLASS,
    skip = { q{ t'modifiers' } },
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['enum_declaration'] = {
    category = CATEGORY.ENUM,
    skip = { q{ t'modifiers' } },
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['interface_declaration'] = {
    category = CATEGORY.INTERFACE,
    skip = { q{ t'modifiers' } },
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['constructor_declaration'] = {
    category = CATEGORY.METHOD,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['method_declaration'] = {
    category = CATEGORY.METHOD,
    skip = { q{ t'modifiers' } },
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { q{ t')', } },
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['enhanced_for_statement'] = {
    category = CATEGORY.FOR,
    last = { q{ t')', } },
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { q{ f'condition' } },
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['if_statement' ] = {
    category = CATEGORY.IF,
    last = { f'condition' },
    next = { q{ f'consequence', t'block', offsetcol = 1 } },
  },
  ['switch_expression' ] = {
    category = CATEGORY.SWITCH,
    next = { q{ f'body', offsetcol = 1 } },
  },
  ['switch_block_statement_group' ] = {
    category = CATEGORY.CASE,
    last = { q{ t':' } },
    next = { q{ t'block', offsetcol = 1 } },
  },
  ['switch_rule' ] = {
    category = CATEGORY.CASE,
    last = { q{ t'->' } },
    next = { q{ t'block', offsetcol = 1 } },
  },
}
