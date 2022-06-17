local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local f = util.field_name_query
local t = util.node_type_query

return {
  ['class_declaration'] = {
    category = CATEGORY.CLASS,
    last = { f'interfaces', f'superclasses', f'name' },
  },
  ['enum_declaration'] = {
    category = CATEGORY.ENUM,
    last = { f'name' },
  },
  ['interface_declaration'] = {
    category = CATEGORY.INTERFACE,
    last = { f'extends_interfaces', f'name' },
  },
  ['constructor_declaration'] = {
    category = CATEGORY.METHOD,
    last = { f'parameters' },
  },
  ['method_declaration'] = {
    category = CATEGORY.METHOD,
    last = { f'parameters' },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { f'update', f'condition', f'init' },
  },
  ['enhanced_for_statement'] = {
    category = CATEGORY.FOR,
    last = { f'value' },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { f'condition' },
  },
  ['if_statement' ] = {
    category = CATEGORY.IF,
    last = { f'condition' },
  },
  ['switch_expression' ] = {
    category = CATEGORY.SWITCH,
    last = { f'condition' },
  },
  ['switch_block_statement_group' ] = {
    category = CATEGORY.CASE,
    last = { t'switch_label' },
  },
  ['switch_rule' ] = {
    category = CATEGORY.CASE,
    last = { t'switch_label' },
  },
}
