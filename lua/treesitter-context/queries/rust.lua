local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY
local q = util.build_query
local f = util.field_name_query
local t = util.node_type_query

return {
  ['impl_item'] = {
    category = CATEGORY.CLASS,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['trait_item'] = {
    category = CATEGORY.INTERFACE,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['struct_item'] = {
    category = CATEGORY.STRUCT,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['enum_item'] = {
    category = CATEGORY.ENUM,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['function_item'] = {
    category = CATEGORY.FUNCTION,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['for_expression'] = {
    category = CATEGORY.FOR,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['while_expression'] = {
    category = CATEGORY.WHILE,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['while_let_expression'] = {
    category = CATEGORY.WHILE,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['loop_expression'] = {
    category = CATEGORY.WHILE,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['if_expression'] = {
    category = CATEGORY.IF,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['if_let_expression'] = {
    category = CATEGORY.IF,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['match_expression'] = {
    category = CATEGORY.SWITCH,
    next = { q { f('body'), offsetcol = 1 } },
  },
  ['match_arm'] = {
    category = CATEGORY.CASE,
    last = { q { t('=>') } },
    next = { q { t('block'), offsetcol = 1 } },
  },
}
