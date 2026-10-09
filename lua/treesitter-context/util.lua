local M = {}

--- @param r Range4
--- @return integer
function M.get_range_height(r)
  return r[3] - r[1] + (r[4] == 0 and 0 or 1)
end

--- @param events string|string[] Events to ignore.
--- @param callback fun(...)
--- @param ... any
function M.with_eventignore(events, callback, ...)
  events = type(events) == 'table' and table.concat(events, ',') or events
  local eventignore = vim.o.eventignore
  vim.o.eventignore = (eventignore == '' or events == 'all') and events
    or eventignore .. ',' .. events
  --- @type boolean, any
  local ok, err = xpcall(callback, debug.traceback, ...)
  -- Restoring eventignore can itself trigger OptionSet, after the callback finishes.
  vim.o.eventignore = eventignore
  if not ok then
    error(err, 0)
  end
end

return M
