local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY

return {
  ['impl_item'] = {
    category = CATEGORY.CLASS,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['trait_item'] = {
    category = CATEGORY.INTERFACE,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['struct_item'] = {
    category = CATEGORY.STRUCT,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['enum_item'] = {
    category = CATEGORY.ENUM,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['function_item'] = {
    category = CATEGORY.FUNCTION,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['for_expression'] = {
    category = CATEGORY.FOR,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['while_expression'] = {
    category = CATEGORY.WHILE,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['while_let_expression'] = {
    category = CATEGORY.WHILE,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['loop_expression'] = {
    category = CATEGORY.WHILE,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['if_expression'] = {
    category = CATEGORY.IF,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['if_let_expression'] = {
    category = CATEGORY.IF,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['match_expression'] = {
    category = CATEGORY.SWITCH,
    next = { { field = 'body', offsetcol = 1 } },
  },
  ['match_arm'] = {
    category = CATEGORY.CASE,
    last = { { type = '=>' } },
    next = { { type = 'block', offsetcol = 1 } },
  },
}
