local helpers = require('nvim-test.helpers')
local exec_lua = helpers.exec_lua
local cmd = helpers.api.nvim_command
local feed = helpers.feed
local api = helpers.api
local fn = helpers.fn

local tc_helpers = require('test.helpers')

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

--- Install the root treesitter language for the given file and injected languages.
--- @param filename string
--- @param root_lang string
local function install_langs_for_file(filename, root_lang)
  cmd('edit ' .. filename)
  local bufnr = api.nvim_get_current_buf()
  local line_count = api.nvim_buf_line_count(bufnr)
  --- @type table<string,boolean>
  local seen_langs = {}
  --- @type string[]
  local langs_to_check = { root_lang }
  while #langs_to_check > 0 do
    local current_lang = table.remove(langs_to_check, 1)
    -- We might encounter recursion, so check if we've traversed this language before.
    if seen_langs[current_lang] then
      goto continue
    end
    exec_lua(tc_helpers.install_langs, current_lang)

    -- Query for injections in the current language, and queue them for installation.
    --- @diagnostic disable-next-line: redefined-local Not actually redefining locals
    langs_to_check = exec_lua(function(bufnr, current_lang, line_count, langs_to_check)
      local current_parser = vim.treesitter.get_parser(bufnr, current_lang)
      if not current_parser then
        return langs_to_check
      end
      -- Parsing the whole file is a simple way to get all injections for the file.
      local tree_map = current_parser:parse({ 0, line_count })
      if not tree_map then
        return langs_to_check
      end
      local injection_query = vim.treesitter.query.get(current_lang, 'injections')
      if not injection_query then
        return langs_to_check
      end
      for _, tree in pairs(tree_map) do
        local root = tree:root()
        for id, node, metadata in injection_query:iter_captures(root, bufnr, 0, line_count) do
          -- The name of the injection language is either available through metadata or the text
          -- content of the `injection.language` capture.
          if metadata['injection.language'] then
            table.insert(langs_to_check, metadata['injection.language'])
          end
          local capture_name = injection_query.captures[id]
          if capture_name == 'injection.language' then
            local node_text = vim.treesitter.get_node_text(node, bufnr)
            table.insert(langs_to_check, node_text)
          end
        end
      end
      return langs_to_check
    end, bufnr, current_lang, line_count, langs_to_check)
    seen_langs[current_lang] = true
    ::continue::
  end
end

local langs = tc_helpers.get_langs()
local langs_with_queries = {} --- @type string[]
for _, lang in ipairs(langs) do
  if vim.uv.fs_stat('queries/' .. lang .. '/context.scm') then
    table.insert(langs_with_queries, lang)
  end
end

local lang_to_test_files = {} --- @type table<string,string[]>
setup(function()
  helpers.clear()
  exec_lua(tc_helpers.setup)
  exec_lua(tc_helpers.install_langs, 'lua')

  local test_files = fn.globpath('test/lang', '*', true, true) --- @type string[]
  for _, test_file in ipairs(test_files) do
    cmd('edit ' .. test_file)
    local bufnr = api.nvim_get_current_buf()
    --- @type string
    local treesitter_lang = exec_lua(function(...)
      local ok, parser = pcall(vim.treesitter.get_parser, ...)
      if not ok then
        return nil
      end
      return parser:lang()
    end, bufnr)
    if treesitter_lang ~= nil and treesitter_lang ~= '' then
      if not lang_to_test_files[treesitter_lang] then
        lang_to_test_files[treesitter_lang] = {}
      end
      if not vim.tbl_contains(lang_to_test_files[treesitter_lang], test_file) then
        table.insert(lang_to_test_files[treesitter_lang], test_file)
      end
    end
  end
end)

for _, lang in ipairs(langs_with_queries) do
  describe('contexts (' .. lang .. '):', function()
    local test_files_for_filetype = lang_to_test_files[lang]
    if not test_files_for_filetype then
      pending('No test file')
      return
    end
    for _, test_file in ipairs(test_files_for_filetype) do
      local contexts = parse_directives(test_file)

      if not contexts or not next(contexts) then
        pending('No test markers in ' .. test_file)
        return
      end

      lazy_setup(function()
        cmd([[let $XDG_CACHE_HOME='scratch/cache']])
        install_langs_for_file(test_file, lang)
      end)

      for cursor_row, context_rows in pairs(contexts) do
        it(('line %s in %s'):format(cursor_row, test_file), function()
          cmd('edit ' .. test_file)
          local winid = api.nvim_get_current_win()
          api.nvim_win_set_cursor(winid, { cursor_row + 1, 0 })
          assert(fn.getline('.'):match('{{CURSOR}}'))
          feed(string.format('zt%d<C-y>', #context_rows + 2))

          --- @type [integer,integer,integer,integer][]
          local ranges = exec_lua(function(...)
            return assert(require('treesitter-context.context').get(...))
          end, winid)

          local act_context_rows = {} --- @type integer[]
          for _, r in ipairs(ranges) do
            local start_row = r[1]
            local end_row = r[3]
            for i = start_row, end_row - 1 do
              table.insert(act_context_rows, i)
            end
          end

          helpers.eq(
            context_rows,
            act_context_rows,
            string.format('test for cursor %d failed', cursor_row)
          )
        end)
      end
    end
  end)
end
