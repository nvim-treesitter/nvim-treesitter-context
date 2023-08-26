local helpers = require('test.functional.helpers')()
local Screen = require('test.functional.ui.screen')

local clear    = helpers.clear
local exec_lua = helpers.exec_lua
local cmd      = helpers.command
local feed     = helpers.feed

describe('ts_context', function()
  local screen

  before_each(function()
    clear()
    screen = Screen.new(30, 16)
    screen:attach()
    screen:set_default_attr_ids({
      [1] = {foreground = Screen.colors.Brown, background = Screen.colors.LightMagenta, bold = true};
      [2] = {background = Screen.colors.LightMagenta};
      [3] = {foreground = Screen.colors.DarkCyan, background = Screen.colors.LightMagenta};
      [4] = {bold = true, foreground = Screen.colors.Brown};
      [5] = {foreground = Screen.colors.DarkCyan};
      [6] = {bold = true, foreground = Screen.colors.Blue};
      [7] = {foreground = Screen.colors.SeaGreen, background = Screen.colors.LightMagenta, bold = true};
      [8] = {foreground = Screen.colors.Blue};
      [9] = {bold = true, foreground = Screen.colors.SeaGreen};
      [10] = {foreground = Screen.colors.Fuchsia, background = Screen.colors.LightMagenta};
      [11] = {foreground = Screen.colors.Fuchsia};
      [12] = {foreground = tonumber('0x6a0dad'), background = Screen.colors.LightMagenta};
      [13] = {foreground = Screen.colors.White, background = Screen.colors.Red};
    })
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

  describe('language:', function()
    before_each(function()
      exec_lua[[require'treesitter-context'.setup{
        mode = 'topline',
      }]]
      cmd'set scrolloff=5'
      cmd'set nowrap'
    end)

    it('rust', function()
      cmd('edit test/test.rs')
      feed'20<C-e>'

      screen:expect{grid=[[
        {1:impl}{2: Foo {                    }|
        {2:    }{1:fn}{2: }{3:bar}{2:(}{7:&}{10:self}{2:) {           }|
        {2:        }{1:if}{2: condition {        }|
        {2:            }{1:for}{2: i }{1:in}{2: }{10:0}{2:..}{10:100}{2: { }|
                                      |
        ^            }                 |
                }                     |
            }                         |
        }                             |
                                      |
        {4:struct} {5:Foo} {                  |
                                      |
            active: {9:bool},             |
                                      |
            username: {9:String},         |
                                      |
      ]]}

      feed'14<C-e>'
      screen:expect{grid=[[
        {1:struct}{2: }{3:Foo}{2: {                  }|
                                      |
            email: {9:String},            |
                                      |
            sign_in_count: {9:u64},       |
        ^                              |
        }                             |
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
                                      |
      ]]}

    end)

    it('c', function()
      cmd('edit test/test.c')
      feed'<C-e>'

      -- Check the struct context
      screen:expect{grid=[[
        {7:struct}{2: Bert {                 }|
            {8:// comment}                |
            {9:int} *f2;                  |
            {8:// comment}                |
            {8:// comment}                |
        ^    {8:// comment}                |
            {8:// comment}                |
            {8:// comment}                |
        };                            |
                                      |
        {9:typedef} {9:enum} {                |
          E1,                         |
          E2,                         |
          E3                          |
          {8:// comment}                  |
                                      |
      ]]}

      feed'12<C-e>'

      -- Check the enum context
      screen:expect{grid=[[
        {7:typedef}{2: }{7:enum}{2: {                }|
          E3                          |
          {8:// comment}                  |
          {8:// comment}                  |
          {8:// comment}                  |
        ^  {8:// comment}                  |
          {8:// comment}                  |
          {8:// comment}                  |
        } Myenum;                     |
                                      |
        {9:int} main({9:int} arg1,            |
                 {9:char} **arg2,         |
                 {9:char} **arg3          |
                 )                    |
        {                             |
                                      |
      ]]}

      feed'40<C-e>'
      screen:expect{grid=[[
        {7:int}{2: main(}{7:int}{2: arg1,            }|
        {2:         }{7:char}{2: **arg2,         }|
        {2:  }{1:if}{2: (arg1 == }{10:4}{2:               }|
        {2:      && arg2 == arg3) }{13:{}{2:      }|
        {2:    }{1:for}{2: (}{7:int}{2: i = }{10:0}{2:; i < arg1; }|
        ^                              |
              {4:do} {                    |
                {8:// comment}            |
                {8:// comment}            |
                {8:// comment}            |
                {8:// comment}            |
                {8:// comment}            |
                                      |
              } {4:while} ({11:1});            |
              {8:// comment}              |
                                      |
      ]]}
    end)

    it('cpp', function()
      cmd('edit test/test.cpp')
      feed'<C-e>'

      screen:expect{grid=[[
        {7:struct}{2: Struct {               }|
            {9:int} *f2;                  |
                                      |
                                      |
                                      |
        ^    {8:// cursor position 1}      |
        };                            |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
      ]]}

      feed'16<C-e>'

      screen:expect{grid=[[
        {7:class}{2: Class {                 }|
            {9:int} *f2;                  |
                                      |
                                      |
                                      |
        ^    {8:// cursor position 2}      |
        };                            |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
      ]]}

      feed'16<C-e>'

      screen:expect{grid=[[
        {7:typedef}{2: }{7:enum}{2: {                }|
          E2,                         |
          E3                          |
                                      |
                                      |
        ^  {8:// cursor position 3}        |
        } myenum;                     |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
      ]]}

      feed'26<C-e>'
      screen:expect{grid=[[
        {7:int}{2: main(}{7:int}{2: arg1,            }|
        {2:  }{1:if}{2: (arg1 == }{10:4}{2:               }|
        {2:      && arg2 == arg3) {      }|
        {2:    }{1:for}{2: (}{7:int}{2: i = }{10:0}{2:; i < arg1; }|
        {2:      }{1:while}{2: (}{10:1}{2:) {             }|
        ^        {8:// cursor position 4}  |
              }                       |
            }                         |
          }                           |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
      ]]}

      feed'18<C-e>'
      screen:expect{grid=[[
        {7:int}{2: main(}{7:int}{2: arg1,            }|
        {2:         }{7:char}{2: **arg2,         }|
        {2:         }{7:char}{2: **arg3          }|
        {2:  }{1:do}{2: {                        }|
        {2:    }{1:for}{2: (}{7:auto}{2: value : array) {}|
        ^      {8:// cursor position 5}    |
            }                         |
          } {4:while} ({11:1});                |
        }                             |
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
                                      |
      ]]}
    end)

    it('typescript', function()
      cmd('edit test/test.ts')
      feed'<C-e>'

      screen:expect{grid=[[
        {1:interface}{2: }{3:User}{2: }{3:{}{2:              }|
                                      |
                                      |
                                      |
          {5:id}: {9:number}{4:;}                 |
        ^                              |
                                      |
                                      |
                                      |
        {5:}}                             |
                                      |
        {4:class} UserAccount {5:{}           |
          {5:name}: {9:string};               |
          {5:id}: {9:number};                 |
                                      |
                                      |
      ]]}

      feed'21<C-e>'
      screen:expect{grid=[[
        {1:class}{2: UserAccount }{3:{}{2:           }|
        {2:  }{3:constructor}{2:(}{12:name}{2::}{12: }{7:string}{1:,}{12: id}|
        {2:    }{1:for}{2: (}{3:let}{2: i = }{10:0}{1:;}{2: i < }{10:3}{1:;}{2: i++}|
                                      |
                                      |
        ^                              |
            {5:}}                         |
                                      |
                                      |
                                      |
                                      |
          {5:}}                           |
        {5:}}                             |
                                      |
                                      |
                                      |
      ]]}

      feed'16<C-e>'
      screen:expect{grid=[[
        {1:function}{2: }{3:wrapInArray}{2:(}{12:obj}{2::}{12: }{7:stri}|
        {2:  }{1:if}{2: (}{3:typeof}{2: obj === }{10:"string"}{2:)}|
                                      |
                                      |
                                      |
        ^                              |
          {5:}}                           |
          {4:return} obj;                 |
        {5:}}                             |
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
        {6:~                             }|
                                      |
      ]]}
    end)

  end)

end)
