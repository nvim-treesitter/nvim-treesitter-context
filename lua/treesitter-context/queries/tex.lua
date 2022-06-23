local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY
local q = util.build_query
local f = util.field_name_query

return {
  ['part'] = {
    category = CATEGORY.SECTION,
    last = { q { f('text') } },
  },
  ['chapter'] = {
    category = CATEGORY.SECTION,
    last = { q { f('text') } },
  },
  ['section'] = {
    category = CATEGORY.SECTION,
    last = { q { f('text') } },
  },
  ['subsection'] = {
    category = CATEGORY.SECTION,
    last = { q { f('text') } },
  },
  ['subsubsection'] = {
    category = CATEGORY.SECTION,
    last = { q { f('text') } },
  },
}
