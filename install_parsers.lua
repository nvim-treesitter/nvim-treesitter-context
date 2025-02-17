
local function get_langs()
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
  local txt = f:read('*a')
  local j = vim.json.decode(txt)

  local langs = {} --- @type string[]
  for k in pairs(j) do
    if readme_langs[k] then
      langs[#langs+1] = k
      readme_langs[k] = nil
    end
  end
  print('Invalid languages:', table.concat(vim.tbl_keys(readme_langs), ', '))
  return langs
end

vim.cmd [[set runtimepath+=.,./deps/nvim-treesitter]]
require'nvim-treesitter.install'.prefer_git = false
require("nvim-treesitter").setup()
require'nvim-treesitter.install'.ensure_installed_sync(get_langs())
vim.cmd.quit()
