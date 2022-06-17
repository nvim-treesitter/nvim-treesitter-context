local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local f = util.field_name_query

return {
  ['function_declaration' ] = {
    category = CATEGORY.FUNCTION,
    last = { f'parameters' },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { f'clause' },
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
