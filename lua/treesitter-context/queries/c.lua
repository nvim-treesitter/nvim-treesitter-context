local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY

return {
  ['struct_specifier'] = {
    category = CATEGORY.STRUCT,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['enum_specifier'] = {
    category = CATEGORY.ENUM,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['function_definition'] = {
    category = CATEGORY.FUNCTION,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { { type = ')' } },
    next = { { type = 'compound_statement', offsetcol = 1 } },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { { field = 'condition' } },
    next = { { type = 'compound_statement', offsetcol = 1 } },
  },
  ['if_statement'] = {
    category = CATEGORY.IF,
    last = { { field = 'condition' } },
    next = { { field = 'consequence', type = 'compound_statement', offsetcol = 1 } },
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
}
