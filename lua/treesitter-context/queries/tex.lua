local util = require'treesitter-context.util'
local CATEGORY = util.CATEGORY
local f = util.field_name_query

return {
  ['part'] = {
    category = CATEGORY.SECTION,
    last = { f'text' },
  },
  ['chapter'] = {
    category = CATEGORY.SECTION,
    last = { f'text' },
  },
  ['section'] = {
    category = CATEGORY.SECTION,
    last = { f'text' },
  },
  ['subsection'] = {
    category = CATEGORY.SECTION,
    last = { f'text' },
  },
  ['subsubsection'] = {
    category = CATEGORY.SECTION,
    last = { f'text' },
  },
}
