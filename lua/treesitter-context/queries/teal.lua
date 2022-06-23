local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY

return {
  ['record_declaration'] = {
    category = CATEGORY.CLASS,
    last = { { field = 'name' } },
  },
  ['enum_declaration'] = {
    category = CATEGORY.ENUM,
    last = { { field = 'name' } },
  },
  ['function_statement'] = {
    category = CATEGORY.FUNCTION,
    last = { { field = 'return_type' }, { field = 'signature' } },
  },
  ['numeric_for_statement'] = {
    category = CATEGORY.FOR,
    last = { { type = 'do' } },
  },
  ['generic_for_statement'] = {
    category = CATEGORY.FOR,
    last = { { type = 'do' } },
  },
  ['while_statement'] = {
    category = CATEGORY.WHILE,
    last = { { type = 'do' } },
  },
  ['if_statement'] = {
    category = CATEGORY.IF,
    last = { { type = 'then' } },
  },
}
