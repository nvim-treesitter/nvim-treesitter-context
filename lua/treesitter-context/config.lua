
--- @class (exact) TSContext.Config
--- @field enable boolean
--- @field max_lines integer
--- @field min_window_height integer
--- @field line_numbers boolean
--- @field multiline_threshold integer
--- @field trim_scope 'outer'|'inner'
--- @field zindex integer
--- @field mode 'cursor'|'topline'
--- @field separator? string
--- @field on_attach? fun(buf: integer): boolean

--- @class (exact) TSContext.UserConfig : TSContext.Config
---
--- Enable this plugin (Can be enabled/disabled later via commands)
--- @field enable? boolean
---
--- How many lines the window should span. Values <= 0 mean no limit.
--- @field max_lines? integer
---
--- Minimum editor window height to enable context. Values <= 0 mean no limit.
--- @field min_window_height? integer
---
--- @field line_numbers? boolean
---
--- Maximum number of lines to show for a single context
--- @field multiline_threshold? integer
---
--- Which context lines to discard if `max_lines` is exceeded.
--- @field trim_scope? 'outer'|'inner'
---
--- @field zindex? integer
---
--- Line used to calculate context.
--- @field mode? 'cursor'|'topline'
---
--- Separator between context and content. Should be a single character string, like '-'.
--- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
--- @field separator? string
---
--- Callback when attaching. Return false to disable attaching
--- @field on_attach? fun(buf: integer): boolean

--- @type TSContext.Config
local default_config = {
  enable = true,
  max_lines = 0, -- no limit
  min_window_height = 0,
  line_numbers = true,
  multiline_threshold = 20,
  trim_scope = 'outer',
  zindex = 20,
  mode = 'cursor',
}

local config = vim.deepcopy(default_config)

local M = {}

--- @param cfg TSContext.UserConfig
function M.update(cfg)
  config = vim.tbl_deep_extend('force', config, cfg)
end

--- @type TSContext.Config
setmetatable(M, {
  __index = function(_, k)
    return config[k]
  end
})

return M
