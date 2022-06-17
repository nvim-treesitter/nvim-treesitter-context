local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local f = util.field_name_query

return {
  ['record_declaration' ] = {
    category = CATEGORY.CLASS,
    last = { f'name' },
  },
  ['enum_declaration' ] = {
    category = CATEGORY.ENUM,
    last = { f'name' },
  },
  ['function_statement' ] = {
    category = CATEGORY.FUNCTION,
    last = { f'signature' },
  },
  ['numeric_for_statement'] = {
    category = CATEGORY.FOR,
    last = { f'step', f'target' },
  },
  ['generic_for_statement'] = {
    category = CATEGORY.FOR,
    last = { f'iterator' },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { f'condition' },
  },
  ['if_statement'] = {
    category = CATEGORY.IF,
    last = { f'condition' },
  },
}
