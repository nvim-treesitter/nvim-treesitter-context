local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY
local q = util.build_query
local t = util.node_type_query

return {
  ['class_definition'] = {
    category = CATEGORY.CLASS,
    last = { q { t(':') } },
  },
  ['function_definition'] = {
    category = CATEGORY.FUNCTION,
    last = { q { t(':') } },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { q { t(':') } },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { q { t(':') } },
  },
  ['if_statement'] = {
    category = CATEGORY.IF,
    last = { q { t(':') } },
  },
  ['with_statement'] = {
    category = CATEGORY.IF,
    last = { q { t(':') } },
  },
  ['match_statement'] = {
    category = CATEGORY.SWITCH,
    last = { q { t(':') } },
  },
  ['case_clause'] = {
    category = CATEGORY.CASE,
    last = { q { t(':') } },
  },
}
