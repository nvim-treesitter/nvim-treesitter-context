local M = {}

local default = {
  enable = true,
}

function M.setup(options)
  M.config = vim.tbl_deep_extend("force", {}, default, options or {})
end

M.setup()

return M
