
--- @class TSContext.Config
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

--- @type TSContext.Config
local default_config = {
  enable = true,
  max_lines = 0, -- no limit
  min_window_height = 0,
  line_numbers = true,
  multiline_threshold = 20, -- Maximum number of lines to show for a single context
  trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  zindex = 20,
  mode = 'cursor',
}

--- @type TSContext.Config
local config = vim.deepcopy(default_config)

local M = {}

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
