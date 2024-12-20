local helpers = require('nvim-test.helpers')
local clear = helpers.clear
local exec_lua = helpers.exec_lua
local cmd = helpers.api.nvim_command
local feed = helpers.feed
local api = helpers.api
local fn = helpers.fn

local tc_helpers = require('test.helpers')
local install_langs = tc_helpers.install_langs
local get_langs = tc_helpers.get_langs

--- @param line string
--- @return string?
local function parse_directive(line)
  --- @type string?
  local directive = line:match('{{([A-Z]+)}}')
  return directive
end

--- @param filename string
--- @return table<integer, integer[]>? contexts
local function parse_directives(filename)
  local f = io.open(filename, 'r')
  if not f then
    return
  end

  local context = {} --- @type table<integer,integer[]>
  local contexts = {} --- @type table<integer,integer[]>

  local i = 0
  for l in f:lines() do
    local directive = parse_directive(l)
    if directive then
      if directive == 'TEST' then
        context = {}
      elseif directive == 'CURSOR' then
        contexts[i] = vim.deepcopy(context)
      elseif directive == 'CONTEXT' then
        table.insert(context, i)
      elseif directive == 'POPCONTEXT' then
        table.remove(context, #context)
      end
    end
    i = i + 1
  end
  f:close()

  for _, c in pairs(contexts) do
    table.sort(c)
  end

  return contexts
end

local langs = get_langs()
local langs_with_queries = {}
for _, lang in ipairs(langs) do
  if vim.uv.fs_stat('queries/' .. lang .. '/context.scm') then
    table.insert(langs_with_queries, lang)
  end
end

for _, lang in ipairs(langs_with_queries) do
  describe('contexts (' .. lang .. '):', function()
    local test_file = 'test/lang/test.' .. lang
    if not vim.uv.fs_stat(test_file) then
      pending('No test file')
      return
    end

    local contexts = parse_directives(test_file)

    if not contexts or not next(contexts) then
      pending('No tests')
      return
    end

    setup(function()
      clear()
      cmd([[set runtimepath+=.,./nvim-treesitter]])

      -- Required to load custom predicates
      exec_lua([[require'nvim-treesitter'.setup()]])

      cmd([[let $XDG_CACHE_HOME='scratch/cache']])

      install_langs(lang)
    end)

    for cursor_row, context_rows in pairs(contexts) do
      it(('line %s in %s'):format(cursor_row, test_file), function()
        cmd('edit ' .. test_file)
        local bufnr = api.nvim_get_current_buf()
        local winid = api.nvim_get_current_win()
        api.nvim_win_set_cursor(winid, { cursor_row + 1, 0 })
        assert(fn.getline('.'):match('{{CURSOR}}'))
        feed(string.format('zt%d<C-y>', #context_rows + 2))

        --- @type [integer,integer,integer,integer][]
        local ranges = exec_lua(
          [[
          return require('treesitter-context.context').get(...)
        ]],
          bufnr,
          winid
        )

        local act_context_rows = {} --- @type integer[]
        for _, r in ipairs(ranges) do
          table.insert(act_context_rows, r[1])
        end

        helpers.eq(
          context_rows,
          act_context_rows,
          string.format('test for cursor %d failed', cursor_row)
        )
      end)
    end
  end)
end
