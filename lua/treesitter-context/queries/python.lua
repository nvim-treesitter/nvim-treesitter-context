local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local f = util.field_name_query

return {
  ['class_definition'] = {
    category = CATEGORY.CLASS,
    last = { f'superclasses', f'name' },
  },
  ['function_definition' ] = {
    category = CATEGORY.FUNCTION,
    last = { f'return_type', f'parameters' },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { f'right' },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { f'condition' },
  },
  ['if_statement'] = {
    category = CATEGORY.IF,
    last = { f'condition' },
  },
  ['with_statement'] = {
    category = CATEGORY.IF,
    last = { f'with_clause' },
  },
  ['match_statement'] = {
    category = CATEGORY.SWITCH,
    last = { f'subject' },
  },
  ['case_clause'] = {
    category = CATEGORY.CASE,
    last = { f'pattern' },
  },
}
