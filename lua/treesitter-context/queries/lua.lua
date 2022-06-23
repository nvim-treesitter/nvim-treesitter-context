local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY
local q = util.build_query
local f = util.field_name_query
local t = util.node_type_query

return {
  ['function_declaration'] = {
    category = CATEGORY.FUNCTION,
    last = { q { f('parameters') } },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { q { t('do') } },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { q { t('do') } },
  },
  ['if_statement'] = {
    category = CATEGORY.IF,
    last = { q { t('then') } },
  },
}
