local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY

return {
  ['class_definition'] = {
    category = CATEGORY.CLASS,
    last = { { type = ':' } },
  },
  ['function_definition'] = {
    category = CATEGORY.FUNCTION,
    last = { { type = ':' } },
  },
  ['for_statement'] = {
    category = CATEGORY.FOR,
    last = { { type = ':' } },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { { type = ':' } },
  },
  ['if_statement'] = {
    category = CATEGORY.IF,
    last = { { type = ':' } },
  },
  ['with_statement'] = {
    category = CATEGORY.IF,
    last = { { type = ':' } },
  },
  ['match_statement'] = {
    category = CATEGORY.SWITCH,
    last = { { type = ':' } },
  },
  ['case_clause'] = {
    category = CATEGORY.CASE,
    last = { { type = ':' } },
  },
}
