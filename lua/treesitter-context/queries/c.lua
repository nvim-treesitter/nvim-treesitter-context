local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local f = util.field_name_query

return {
  ['struct_specifier'] = {
    category = CATEGORY.STRUCT,
    last = { f'name' },
  },
  ['enum_specifier'] = {
    category = CATEGORY.ENUM,
    last = { f'name' },
  },
  ['function_definition'] = {
    category = CATEGORY.FUNCTION,
    last = { f'declarator' },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { f'update', f'condition', f'initializer' },
  },
  ['while_statement' ] = {
    category = CATEGORY.WHILE,
    last = { f'condition' },
  },
  ['if_statement' ] = {
    category = CATEGORY.IF,
    last = { f'condition' },
  },
  ['switch_statement' ] = {
    category = CATEGORY.SWITCH,
    last = { f'condition' },
  },
  ['case_statement' ] = {
    category = CATEGORY.CASE,
    last = { f'value' },
  },
}
