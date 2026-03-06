--- Test the query for each language is valid and update the README.
local helpers = require('nvim-test.helpers')
local exec_lua = helpers.exec_lua

local tc_helpers = require('test.helpers')

--- @param line string
--- @return string? tick
--- @return string? lang
local function parse_readme_lang_line(line)
  return line:match('^%s*%- %[(.)%] `([^`]+)`')
end

--- @param lines string[]
--- @param lang string
--- @return integer?
local function find_readme_lang_index(lines, lang)
  for i, line in ipairs(lines) do
    local _, line_lang = parse_readme_lang_line(line)
    if line_lang == lang then
      return i
    end
  end
end

--- Find insertion point for `lang` inside a specific README language block (`x` or space).
--- @param lines string[]
--- @param tick string
--- @param lang string
--- @return integer
local function find_readme_insert_index(lines, tick, lang)
  local last_tick_index --- @type integer?

  for i, line in ipairs(lines) do
    local line_tick, line_lang = parse_readme_lang_line(line)
    if line_tick == tick and line_lang then
      last_tick_index = i
      if line_lang > lang then
        return i
      end
    end
  end

  return last_tick_index and (last_tick_index + 1) or (#lines + 1)
end

--- Remove any existing README entry for `lang` and insert the updated one in order.
--- @param lines string[]
--- @param lang string
--- @param tick string
--- @param broken boolean?
local function upsert_readme_lang_line(lines, lang, tick, broken)
  local existing_index = find_readme_lang_index(lines, lang)
  if existing_index then
    table.remove(lines, existing_index)
  end

  local insert_index = find_readme_insert_index(lines, tick, lang)
  local line
  if tick == 'x' then
    line = ('  - [x] `%s`%s'):format(lang, broken and ' (broken)' or '')
  else
    line = ('  - [ ] `%s`'):format(lang)
  end
  table.insert(lines, insert_index, line)
end

describe('query:', function()
  local readme_lines = {} --- @type string[]

  setup(function()
    helpers.clear()
    exec_lua(tc_helpers.setup)

    local f = assert(io.open('README.md', 'r'))
    for line in f:lines() do
      table.insert(readme_lines, line)
    end
    f:close()
  end)

  for _, lang in ipairs(tc_helpers.get_langs()) do
    it(lang, function()
      if not vim.uv.fs_stat('queries/' .. lang .. '/context.scm') then
        upsert_readme_lang_line(readme_lines, lang, ' ')
        pending('no queries/' .. lang .. '/context.scm')
        return
      end

      exec_lua(tc_helpers.install_langs, lang, { force = true })
      local ok = exec_lua(function(...)
        return (pcall(vim.treesitter.query.get, ...))
      end, lang, 'context')

      upsert_readme_lang_line(readme_lines, lang, 'x', not ok)
      assert(ok)
    end)
  end

  teardown(function()
    local f = assert(io.open('README.md', 'w'))
    for _, line in ipairs(readme_lines) do
      f:write(line)
      f:write('\n')
    end
    f:close()
  end)
end)
