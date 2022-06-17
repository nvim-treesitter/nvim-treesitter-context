local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local f = util.field_name_query

return {
  ['impl_item'] = {
    category = CATEGORY.CLASS,
    last = { f'type' },
  },
  ['trait_item'] = {
    category = CATEGORY.INTERFACE,
    last = { f'bounds', f'name' },
  },
  ['struct_item'] = {
    category = CATEGORY.STRUCT,
    last = { f'name' },
  },
  ['enum_item'] = {
    category = CATEGORY.ENUM,
    last = { f'name' },
  },
  ['function_item'] = {
    category = CATEGORY.FUNCTION,
    last = { f'return_type', f'parameters' },
  },
  ['for_expression'] = {
    category = CATEGORY.FOR,
    last = { f'value' },
  },
  ['while_expression'] = {
    category = CATEGORY.WHILE,
    last = { f'condition' },
  },
  ['while_let_expression'] = {
    category = CATEGORY.WHILE,
    last = { f'value' },
  },
  ['loop_expression'] = {
    category = CATEGORY.WHILE,
  },
  ['if_expression' ] = {
    category = CATEGORY.IF,
    last = { f'condition' },
  },
  ['if_let_expression' ] = {
    category = CATEGORY.IF,
    last = { f'value' },
  },
  ['match_expression' ] = {
    category = CATEGORY.SWITCH,
    last = { f'value' },
  },
  ['match_arm' ] = {
    category = CATEGORY.CASE,
    last = { f'pattern' },
  },
}
