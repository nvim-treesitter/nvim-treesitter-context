local helpers = require('test.functional.helpers')()
local Screen = require('test.functional.ui.screen')

local clear    = helpers.clear
local exec_lua = helpers.exec_lua
local eq       = helpers.eq
local cmd      = helpers.command
local feed     = helpers.feed

describe('ts_context', function()
  local screen

  setup(function()
    screen = Screen.new(30, 16)
    screen:set_default_attr_ids({
      [1] = {foreground = Screen.colors.Brown, background = Screen.colors.LightMagenta, bold = true};
      [2] = {background = Screen.colors.LightMagenta};
      [3] = {foreground = Screen.colors.DarkCyan, background = Screen.colors.LightMagenta};
      [4] = {bold = true, foreground = Screen.colors.Brown};
      [5] = {foreground = Screen.colors.DarkCyan};
      [6] = {bold = true, foreground = Screen.colors.Blue};
    })
  end)

  before_each(function()
    clear()
    screen:attach()
    cmd [[set runtimepath+=.,./nvim-treesitter]]
    cmd [[let $XDG_CACHE_HOME='scratch/cache']]
    cmd [[set packpath=]]
    cmd('syntax enable')

    exec_lua[[
      require'nvim-treesitter.configs'.setup {
        highlight = { enable = true }
      }
    ]]
  end)

  it('load the plugin', function()
    exec_lua[[require'treesitter-context'.setup{}]]
  end)

  it('edit a file', function()
    exec_lua[[require'treesitter-context'.setup{}]]
    cmd('edit test/test_file.lua')
    feed'<C-e>'
    feed'jj'
    -- screen:snapshot_util()
    screen:expect{grid=[[
      {1:local}{2: }{3:function}{2: foo()          }|
        {4:local} {5:function} bar()        |
      ^                              |
                                    |
                                    |
        {5:end}                         |
                                    |
        {4:local} {5:function} baz()        |
                                    |
                                    |
                                    |
        {5:end}                         |
                                    |
      {5:end}                           |
      {6:~                             }|
                                    |
    ]]}

    feed'2<C-e>'
    feed'jj'
    screen:expect{grid=[[
      {1:local}{2: }{3:function}{2: foo()          }|
      {2:  }{1:local}{2: }{3:function}{2: bar()        }|
      ^                              |
        {5:end}                         |
                                    |
        {4:local} {5:function} baz()        |
                                    |
                                    |
                                    |
        {5:end}                         |
                                    |
      {5:end}                           |
      {6:~                             }|
      {6:~                             }|
      {6:~                             }|
                                    |
    ]]}
  end)

end)
