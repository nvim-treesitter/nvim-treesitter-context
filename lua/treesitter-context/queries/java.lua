local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY

return {
  ['class_declaration'] = {
    category = CATEGORY.CLASS,
    skip = { { type = 'modifiers' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['enum_declaration'] = {
    category = CATEGORY.ENUM,
    skip = { { type = 'modifiers' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['interface_declaration'] = {
    category = CATEGORY.INTERFACE,
    skip = { { type = 'modifiers' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['constructor_declaration'] = {
    category = CATEGORY.METHOD,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['method_declaration'] = {
    category = CATEGORY.METHOD,
    skip = { { type = 'modifiers' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { { type = ')' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['enhanced_for_statement'] = {
    category = CATEGORY.FOR,
    last = { { type = ')' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { { field = 'condition' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['if_statement'] = {
    category = CATEGORY.IF,
    last = { field = 'condition' },
    next = { { field = 'consequence', type = 'block', offsetcol = 1 } },
  },
  ['switch_expression'] = {
    category = CATEGORY.SWITCH,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['switch_block_statement_group'] = {
    category = CATEGORY.CASE,
    last = { { type = ':' } },
    next = { { type = 'block', offsetcol = 1 } },
  },
  ['switch_rule'] = {
    category = CATEGORY.CASE,
    last = { { type = '->' } },
    next = { { type = 'block', offsetcol = 1 } },
  },
}
