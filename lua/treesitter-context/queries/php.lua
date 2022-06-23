local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY
local q = util.build_query
local f = util.field_name_query
local t = util.node_type_query

return {
  ['class_declaration'] = {
    category = CATEGORY.CLASS,
    skip = { q { f('attributes') } },
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['interface_declaration'] = {
    category = CATEGORY.INTERFACE,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['enum_declaration'] = {
    category = CATEGORY.ENUM,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['function_definition'] = {
    category = CATEGORY.METHOD,
    skip = { q { f('attributes') } },
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['method_declaration'] = {
    category = CATEGORY.METHOD,
    skip = { q { f('attributes') } },
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { q { t(')') } },
    next = { q { t('compound_statement'), offsetcol = 1 } },
  },
  ['foreach_statement'] = {
    category = CATEGORY.FOR,
    last = { q { t(')') } },
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { q { f('condition') } },
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['if_statement'] = {
    category = CATEGORY.IF,
    last = { q { f('condition') } },
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['switch_statement'] = {
    category = CATEGORY.SWITCH,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['case_statement'] = {
    category = CATEGORY.CASE,
    last = { q { t(':') } },
    next = { q { t('compound_statement'), offsetcol = 1 } },
  },
  ['default_statement'] = {
    category = CATEGORY.CASE,
    last = { q { t(':') } },
    next = { q { t('compound_statement'), offsetcol = 1 } },
  },
  ['match_expression'] = {
    category = CATEGORY.SWITCH,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['match_conditional_expression'] = {
    category = CATEGORY.CASE,
    last = { q { t('=>') } },
  },
  ['match_default_expression'] = {
    category = CATEGORY.CASE,
    last = { q { t('=>') } },
  },
}
