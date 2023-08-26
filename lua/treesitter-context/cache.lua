local M = {}

---Memoize a function using hash_fn to hash the arguments.
---@generic F: function
---@param fn F
---@param hash_fn fun(...): any
---@return F
function M.memoize(fn, hash_fn)
  local cache = setmetatable({}, { __mode = 'kv' }) ---@type table<any,any>

  return function(...)
    local key = hash_fn(...)
    if cache[key] == nil then
      local v = fn(...) ---@type any
      cache[key] = v ~= nil and v or vim.NIL
    end

    local v = cache[key]
    return v ~= vim.NIL and vim.deepcopy(v) or nil
  end
end

return M
