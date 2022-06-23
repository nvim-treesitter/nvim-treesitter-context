local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY

return {
  ['class_declaration'] = {
    category = CATEGORY.CLASS,
    skip = { { field = 'attributes' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['interface_declaration'] = {
    category = CATEGORY.INTERFACE,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['enum_declaration'] = {
    category = CATEGORY.ENUM,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['function_definition'] = {
    category = CATEGORY.METHOD,
    skip = { { field = 'attributes' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['method_declaration'] = {
    category = CATEGORY.METHOD,
    skip = { { field = 'attributes' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { { type = ')' } },
    next = { { type = 'compound_statement', offsetcol = 1 } },
  },
  ['foreach_statement'] = {
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
    last = { { field = 'condition' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['switch_statement'] = {
    category = CATEGORY.SWITCH,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['case_statement'] = {
    category = CATEGORY.CASE,
    last = { { type = ':' } },
    next = { { type = 'compound_statement', offsetcol = 1 } },
  },
  ['default_statement'] = {
    category = CATEGORY.CASE,
    last = { { type = ':' } },
    next = { { type = 'compound_statement', offsetcol = 1 } },
  },
  ['match_expression'] = {
    category = CATEGORY.SWITCH,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['match_conditional_expression'] = {
    category = CATEGORY.CASE,
    last = { { type = '=>' } },
  },
  ['match_default_expression'] = {
    category = CATEGORY.CASE,
    last = { { type = '=>' } },
  },
}
