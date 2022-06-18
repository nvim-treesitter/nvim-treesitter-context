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

  it('edit a file in topline mode', function()
    exec_lua[[require'treesitter-context'.setup{
      mode = 'topline',
      max_lines = 2,
    }]]
    cmd('edit test/nested_file.rs')
    feed'L'
    feed'<C-e>'
    -- screen:snapshot_util()
    screen:expect{grid=[[
      {1:impl}{2: Foo {                    }|
          {4:fn} {5:bar}({7:&}{8:self}) {           |
              {4:if} condition {        |
                                    |
                                    |
                  {4:for} i {4:in} {8:0}..{8:100} { |
                                    |
                                    |
                  }                 |
              }                     |
          }                         |
      }                             |
                                    |
      {4:^struct} {5:Foo} {                  |
                                    |
                                    |
    ]], attr_ids={
      [1] = {foreground = Screen.colors.Brown, background = Screen.colors.Plum1, bold = true};
      [2] = {background = Screen.colors.Plum1};
      [3] = {foreground = Screen.colors.Cyan4, background = Screen.colors.Plum1};
      [4] = {bold = true, foreground = Screen.colors.Brown};
      [5] = {foreground = Screen.colors.Cyan4};
      [6] = {bold = true, foreground = Screen.colors.Blue1};
      [7] = {bold = true, foreground = Screen.colors.SeaGreen4};
      [8] = {foreground = Screen.colors.Fuchsia};
    }}

    feed'<C-e>'
    screen:expect{grid=[[
      {2:    }{1:fn}{2: }{3:bar}{2:(}{7:&}{8:self}{2:)             }|
      {2:        }{1:if}{2: condition {        }|
                                    |
                                    |
                  {4:for} i {4:in} {9:0}..{9:100} { |
                                    |
                                    |
                  }                 |
              }                     |
          }                         |
      }                             |
                                    |
      {4:^struct} {5:Foo} {                  |
                                    |
      }                             |
                                    |
    ]], attr_ids={
      [1] = {foreground = Screen.colors.Brown, bold = true, background = Screen.colors.LightMagenta};
      [2] = {background = Screen.colors.LightMagenta};
      [3] = {background = Screen.colors.LightMagenta, foreground = Screen.colors.Cyan4};
      [4] = {foreground = Screen.colors.Brown, bold = true};
      [5] = {foreground = Screen.colors.Cyan4};
      [6] = {foreground = Screen.colors.Blue1, bold = true};
      [7] = {foreground = Screen.colors.SeaGreen4, bold = true, background = Screen.colors.LightMagenta};
      [8] = {background = Screen.colors.LightMagenta, foreground = Screen.colors.Magenta1};
      [9] = {foreground = Screen.colors.Magenta1};
    }}

    feed'3<C-e>'
    screen:expect{grid=[[
      {2:        }{1:if}{2: condition {        }|
      {2:            }{1:for}{2: i }{1:in}{2: }{7:0}{2:..}{7:100}{2: { }|
                                    |
                                    |
                  }                 |
              }                     |
          }                         |
      }                             |
                                    |
      {4:^struct} {5:Foo} {                  |
                                    |
      }                             |
      {6:~                             }|
      {6:~                             }|
      {6:~                             }|
                                    |
    ]], attr_ids={
      [1] = {background = Screen.colors.Plum1, bold = true, foreground = Screen.colors.Brown};
      [2] = {background = Screen.colors.Plum1};
      [3] = {background = Screen.colors.Plum1, foreground = Screen.colors.Cyan4};
      [4] = {foreground = Screen.colors.Brown, bold = true};
      [5] = {foreground = Screen.colors.Cyan4};
      [6] = {foreground = Screen.colors.Blue1, bold = true};
      [7] = {background = Screen.colors.Plum1, foreground = Screen.colors.Magenta};
    }}
  end)
end)
