local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local f = util.field_name_query
local t = util.node_type_query

return {
  ['class_declaration'] = {
    category = CATEGORY.CLASS,
    last = { t'class_heritage', f'name' },
  },
  ['interface_declaration'] = {
    category = CATEGORY.INTERFACE,
    last = { t'extends_type_clause', f'name' },
  },
  ['function_declaration'] = {
    category = CATEGORY.FUNCTION,
    last = { f'return_type', f'parameters' },
  },
  ['method_declaration'] = {
    category = CATEGORY.METHOD,
    last = { f'return_type', f'parameters' },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { f'increment' },
  },
  ['for_in_statement'] = {
    category = CATEGORY.FOR,
    last = { f'right' },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { f'condition' },
  },
  ['if_statement' ] = {
    category = CATEGORY.IF,
    last = { f'condition' },
  },
  ['switch_statement' ] = {
    category = CATEGORY.SWITCH,
    last = { f'value' },
  },
  ['switch_case' ] = {
    category = CATEGORY.CASE,
    last = { f'pattern' },
  },
  ['switch_default' ] = {
    category = CATEGORY.CASE,
  },
}
