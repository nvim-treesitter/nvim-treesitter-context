local util = require('treesitter-context.util')
local CATEGORY = util.CATEGORY

return {
  ['part'] = {
    category = CATEGORY.SECTION,
    last = { { field = 'text' } },
  },
  ['chapter'] = {
    category = CATEGORY.SECTION,
    last = { { field = 'text' } },
  },
  ['section'] = {
    category = CATEGORY.SECTION,
    last = { { field = 'text' } },
  },
  ['subsection'] = {
    category = CATEGORY.SECTION,
    last = { { field = 'text' } },
  },
  ['subsubsection'] = {
    category = CATEGORY.SECTION,
    last = { { field = 'text' } },
  },
}
