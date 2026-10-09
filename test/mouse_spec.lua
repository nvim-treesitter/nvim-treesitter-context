local helpers = require('nvim-test.helpers')
local tc_helpers = require('test.helpers')
local Screen = require('nvim-test.screen')

local api, exec_lua, eq = helpers.api, helpers.exec_lua, helpers.eq
local feed = helpers.feed

describe('mouse navigation', function()
  local screen --- @type test.screen
  local source_win --- @type integer

  local function expect_context()
    screen:sleep(200)
    eq(
      { 'local function outer()', '  local function inner(', '    arg', '  )' },
      exec_lua(function(winid)
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.w[win].treesitter_context and vim.api.nvim_win_get_config(win).win == winid then
            return vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
          end
        end
      end, source_win)
    )
  end

  --- @param opts? TSContext.UserConfig
  local function setup(opts)
    helpers.clear()
    exec_lua(tc_helpers.setup, opts)
    screen = Screen.new(50, 14)
    screen:attach({ ext_messages = true })
    exec_lua(tc_helpers.install_langs, 'lua')
    exec_lua(function()
      vim.o.mouse = 'a'
      vim.o.mousetime = 0
      vim.o.scrolloff = 0
      vim.wo.number = true
      local lines = { 'local function outer()' }
      for _ = 2, 9 do
        lines[#lines + 1] = '  -- outer body'
      end
      vim.list_extend(lines, { '  local function inner(', '    arg', '  )' })
      for _ = 13, 39 do
        lines[#lines + 1] = '    -- inner body'
      end
      vim.list_extend(lines, { '  end', 'end' })
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      vim.bo.filetype = 'lua'
      vim.treesitter.start()

      _G.entered_context = false
      vim.api.nvim_create_autocmd('WinEnter', {
        callback = function()
          if vim.w.treesitter_context or vim.w.treesitter_context_line_number then
            _G.entered_context = true
          end
        end,
      })
    end)
    source_win = api.nvim_get_current_win()
    feed('20Gzt5j')
    expect_context()
  end

  --- @param row integer
  --- @param col integer
  local function click(row, col)
    local pos = api.nvim_win_get_position(source_win)
    api.nvim_input_mouse('left', 'press', '', 0, pos[1] + row, pos[2] + col)
    screen:sleep(100)
    api.nvim_input_mouse('left', 'release', '', 0, pos[1] + row, pos[2] + col)
  end

  --- @param line integer
  local function expect_line(line)
    screen:sleep(200)
    eq(source_win, api.nvim_get_current_win())
    eq(line, api.nvim_win_get_cursor(source_win)[1])
    eq(false, exec_lua('return _G.entered_context'))
  end

  it('jumps to the clicked line of a multiline header and back', function()
    setup()
    eq('', helpers.fn.maparg('<LeftMouse>', 'n'))
    feed('<C-w>w')
    expect_line(25)
    click(2, 12)
    expect_line(11)
    feed('<C-o>')
    expect_line(25)
  end)

  it('jumps from the context line number gutter', function()
    setup()
    click(0, 1)
    expect_line(1)
  end)

  it('preserves clicks and dragging outside the context', function()
    setup()
    click(6, 10)
    expect_line(26)
    -- Process each event so Neovim does not coalesce the drag with the release.
    api.nvim_input_mouse('left', 'press', '', 0, 6, 10)
    screen:sleep(100)
    api.nvim_input_mouse('left', 'drag', '', 0, 7, 12)
    screen:sleep(100)
    api.nvim_input_mouse('left', 'release', '', 0, 7, 12)
    screen:sleep(200)
    eq('v', api.nvim_get_mode().mode)
    eq(27, api.nvim_win_get_cursor(source_win)[1])
  end)

  it('accounts for a winbar above the context', function()
    setup()
    exec_lua(function()
      vim.wo.winbar = 'source file'
    end)
    expect_context()
    click(3, 12)
    expect_line(11)
  end)

  it('preserves clicks on the separator', function()
    setup({ separator = '-' })
    click(4, 10)
    expect_line(24)
  end)

  it('jumps in an inactive source window and skips contexts during window navigation', function()
    setup({ multiwindow = true })
    api.nvim_command('vnew')
    local other_win = api.nvim_get_current_win()
    exec_lua(function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'other buffer' })
    end)
    expect_context()
    click(1, 10)
    expect_line(10)
    feed('<C-o>')
    expect_line(25)
    feed('<C-w>w')
    screen:sleep(200)
    eq(other_win, api.nvim_get_current_win())
    eq({ 'other buffer' }, api.nvim_buf_get_lines(0, 0, -1, false))
    eq(false, exec_lua('return _G.entered_context'))
  end)

  it('updates the target when the source lines move', function()
    setup()
    api.nvim_buf_set_lines(0, 0, 0, false, { '-- added line', '-- added line' })
    feed('20Gzt5j')
    expect_context()
    click(2, 12)
    expect_line(13)
  end)

  for _, change in ipairs({ 'switching buffers', 'editing the buffer' }) do
    it('keeps mouse navigation after ' .. change .. ' before a context refresh', function()
      setup({ multiwindow = true })
      local original_buf = api.nvim_get_current_buf()
      local original_lines = api.nvim_buf_get_lines(original_buf, 0, -1, false)
      exec_lua(function(switch_buffer)
        local api = vim.api
        -- Start a render so the source change happens inside the throttle interval.
        vim.cmd.normal('j')
        vim.wait(10)
        if switch_buffer then
          api.nvim_win_set_buf(0, api.nvim_create_buf(true, false))
        else
          api.nvim_buf_set_lines(0, 0, -1, false, { '-- replacement' })
        end
        api.nvim_input_mouse('left', 'press', '', 0, 2, 12)
      end, change == 'switching buffers')
      screen:sleep(100)
      api.nvim_input_mouse('left', 'release', '', 0, 2, 12)
      expect_line(1)

      api.nvim_win_set_buf(source_win, original_buf)
      api.nvim_buf_set_lines(original_buf, 0, -1, false, original_lines)
      feed('20Gzt5j')
      expect_context()
      click(2, 12)
      expect_line(11)
    end)
  end

  it('preserves normal clicks when the plugin is disabled', function()
    setup()
    exec_lua("require('treesitter-context').disable()")
    click(0, 10)
    expect_line(20)
  end)

  it('handles clicks once after repeated setup and re-enabling', function()
    setup()
    exec_lua(function()
      local context = require('treesitter-context')
      context.disable()
      context.enable()
      context.setup()
      context.setup()
    end)
    expect_context()
    click(2, 12)
    expect_line(11)
    feed('<C-o>')
    expect_line(25)
  end)

  it('preserves user mouse mappings across setup', function()
    setup()
    exec_lua(function()
      vim.keymap.set('n', '<LeftMouse>', function()
        _G.mouse_mapping = 'global'
      end)
      vim.keymap.set('n', '<LeftMouse>', function()
        _G.mouse_mapping = 'buffer'
      end, { buffer = 0 })
      require('treesitter-context').setup()
    end)
    expect_context()
    click(2, 12)
    expect_line(25)
    eq('buffer', exec_lua('return _G.mouse_mapping'))
    exec_lua(function()
      vim.keymap.del('n', '<LeftMouse>', { buffer = 0 })
    end)
    click(2, 12)
    expect_line(25)
    eq('global', exec_lua('return _G.mouse_mapping'))
  end)

  it('preserves Insert-mode clicks', function()
    setup()
    feed('i')
    click(2, 12)
    expect_line(22)
    eq('i', api.nvim_get_mode().mode)
  end)

  it('respects mouse support being disabled in Normal mode', function()
    setup()
    exec_lua(function()
      vim.o.mouse = 'i'
    end)
    click(2, 12)
    -- Injected events still reach Neovim, but must not jump to the context.
    expect_line(22)
  end)

  it('keeps the jump when a context click is followed by a drag', function()
    setup()
    click(6, 10)
    expect_line(26)
    api.nvim_input_mouse('left', 'press', '', 0, 2, 12)
    screen:sleep(100)
    api.nvim_input_mouse('left', 'drag', '', 0, 7, 12)
    screen:sleep(100)
    api.nvim_input_mouse('left', 'release', '', 0, 7, 12)
    expect_line(11)
    eq('n', api.nvim_get_mode().mode)
  end)
end)
