local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local f = util.field_name_query
local t = util.node_type_query

return {
  ['class_declaration'] = {
    category = CATEGORY.CLASS,
    skip = { f'attributes' },
    last = { t'class_interface_clause', t'base_clause', f'name' },
  },
  ['interface_declaration'] = {
    category = CATEGORY.INTERFACE,
    last = { t'base_clause', f'name' },
  },
  ['enum_declaration'] = {
    category = CATEGORY.ENUM,
    last = { f'name' },
  },
  ['method_declaration'] = {
    category = CATEGORY.METHOD,
    skip = { f'attributes' },
    last = { f'return_type', f'parameters' },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
  },
  ['foreach_statement'] = {
    category = CATEGORY.FOR,
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { f'condition' },
  },
  ['if_statement'] = {
    category = CATEGORY.IF,
    last = { f'condition' },
  },
  ['switch_statement'] = {
    category = CATEGORY.SWITCH,
    last = { f'condition' },
  },
  ['case_statement'] = {
    category = CATEGORY.CASE,
    last = { f'value' },
  },
  ['default_statement'] = {
    category = CATEGORY.CASE,
  },
}
