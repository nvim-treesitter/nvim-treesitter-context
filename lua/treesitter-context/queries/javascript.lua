local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY

return {
  ['class_declaration'] = {
    category = CATEGORY.CLASS,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['function_declaration'] = {
    category = CATEGORY.FUNCTION,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['method_declaration'] = {
    category = CATEGORY.METHOD,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { { type = ')' } },
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['for_in_statement'] = {
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
    next = { { field = 'consequence', type = 'statement_block', offsetcol = 1 } },
  },
  ['switch_statement'] = {
    category = CATEGORY.SWITCH,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['switch_case'] = {
    category = CATEGORY.CASE,
    last = { { type = ':' } },
    next = { { field = 'body', type = 'statement_block', offsetcol = 1 } },
  },
  ['switch_default'] = {
    category = CATEGORY.CASE,
    last = { { type = ':' } },
    next = { { field = 'body', type = 'statement_block', offsetcol = 1 } },
  },
}
