--- Test the query for each language is valid and update the README.
local helpers = require('nvim-test.helpers')
local exec_lua = helpers.exec_lua

local tc_helpers = require('test.helpers')

describe('query:', function()
  local readme_lines = {} --- @type string[]

  setup(function()
    helpers.clear()
    exec_lua(tc_helpers.setup)

    local f = assert(io.open('README.md', 'r'))
    for l in f:lines() do
      readme_lines[#readme_lines + 1] = l
    end
    f:close()
  end)

  for _, lang in ipairs(tc_helpers.get_langs()) do
    it(lang, function()
      local lang_index --- @type integer
      local last_supported_lang_index --- @type integer
      local last_lang_index --- @type integer

      -- Find the line in the README for this lang
      for i, l in ipairs(readme_lines) do
        --- @type string?
        local tick, lang1 = l:match('%- %[(.)%] `([^`]+)`')
        if lang1 then
          if tick == 'x' then
            last_supported_lang_index = i
          else
            last_lang_index = i
          end

          if lang1 == lang then
            lang_index = i
          end
        end
      end

      if lang_index then
        table.remove(readme_lines, lang_index)
      end

      if not vim.uv.fs_stat('queries/' .. lang .. '/context.scm') then
        table.insert(readme_lines, last_lang_index, ('  - [ ] `%s`'):format(lang))
        pending('no queries/' .. lang .. '/context.scm')
        return
      end
      exec_lua(tc_helpers.install_langs, lang)
      local ok = exec_lua(function(...)
        return (pcall(vim.treesitter.query.get, ...))
      end, lang, 'context')
      table.insert(
        readme_lines,
        last_supported_lang_index,
        ('  - [x] `%s`%s'):format(lang, ok and '' or ' (broken)')
      )
      assert(ok)
    end)
  end

  teardown(function()
    -- Update the README.
    local f = assert(io.open('README.md', 'w'))
    for _, l in ipairs(readme_lines) do
      f:write(l)
      f:write('\n')
    end
    f:close()
  end)
end)
