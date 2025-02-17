local helpers = require('nvim-test.helpers')
local exec_lua = helpers.exec_lua

local M = {}

function M.install_langs(langs)
  if type(langs) == 'string' then
    langs = { langs }
  end
  exec_lua(
    [[
  local langs = ...
  require'nvim-treesitter.configs'.setup {
    ensure_installed = langs,
    sync_install = true,
  }

  -- Clear the message "<lang> has been installed".
  print(' ')
  ]],
    langs
  )
end

local langs --- @type string[]?

function M.get_langs()
  if langs then
    return langs
  end

  langs = {}
  local f = assert(io.open('README.md', 'r'))
  local readme_langs = {} --- @type table<string,true>
  for l in f:lines() do
    --- @type string?
    local lang = l:match('%- %[x%] `([^`]+)`')
    if lang then
      readme_langs[lang] = true
    end
  end
  f:close()

  f = assert(io.open('deps/nvim-treesitter/lockfile.json', 'r'))

  for k in vim.spairs(vim.json.decode(f:read('*a'))) do
    langs[#langs + 1] = k
    if readme_langs[k] then
      readme_langs[k] = nil
    end
  end
  if next(readme_langs) then
    print('Invalid languages in README:', table.concat(vim.tbl_keys(readme_langs), ', '))
  end
  return langs
end

return M
