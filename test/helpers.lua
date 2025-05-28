local M = {}

function M.install_langs(langs)
  if type(langs) == 'string' then
    langs = { langs }
  end
  require('nvim-treesitter').install(langs):wait()
  -- Dirty hack to clear ext_messages
  vim.cmd.normal(':<esc>')
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

  ---@type table<string, table>
  local parsers = require('deps/nvim-treesitter/lua/nvim-treesitter/parsers')

  for k in vim.spairs(parsers) do
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

--- @param opts? TSContext.UserConfig
function M.setup(opts)
  -- Do not pull in parsers from /usr/local/share/ as they may
  -- be the wrong ABI
  vim.opt.runtimepath = {
    vim.env.VIMRUNTIME,
    '.',
    './deps/nvim-treesitter',
  }
  require('nvim-treesitter').setup({
    install_dir = vim.fs.joinpath('deps', 'nvim-treesitter-data'),
  })

  require('treesitter-context').setup(opts)
  -- Need to source plugin to define highlights for screen tests
  vim.cmd.source(vim.api.nvim_get_runtime_file('plugin/treesitter-context.lua', false)[1])

  vim.env.XDG_CACHE_HOME = 'scratch/cache'
  vim.opt.packpath = ''
end

if arg[0] == 'test/helpers.lua' and arg[1] == 'install' then
  M.setup()
  M.install_langs(M.get_langs())
end

return M
