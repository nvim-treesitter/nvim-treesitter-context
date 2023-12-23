
local M = {}

--- @param r Range4
--- @return integer
function M.get_range_height(r)
  return r[3] - r[1] + (r[4] == 0 and 0 or 1)
end

return M
