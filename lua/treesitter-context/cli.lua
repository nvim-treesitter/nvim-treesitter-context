local subcmds = { 'enable', 'disable', 'toggle' }

local M = {}

--- @param command string
local function do_subcmd(command)
  local TSContext = require('treesitter-context')
  if TSContext[command] then
    TSContext[command]()
  else
    vim.notify('TSContext: Unknown command ' .. command, vim.log.levels.ERROR)
  end
end

--- @param args string[]
function M.run(args)
  if #args == 0 then
    vim.ui.select(subcmds, {
      prompt = 'Treesitter Context: ',
      format_item = function(item)
        return item:sub(1, 1):upper() .. item:sub(2)
      end,
    }, function(choice)
      if choice then
        do_subcmd(choice)
      end
    end)
    return
  end

  do_subcmd(args[1])
end

function M.complete()
  return subcmds
end

return M
