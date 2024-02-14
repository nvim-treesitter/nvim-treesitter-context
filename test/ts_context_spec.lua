local helpers = require('nvim-test.helpers')
local Screen = require('nvim-test.screen')

local clear    = helpers.clear
local exec_lua = helpers.exec_lua
local cmd      = helpers.api.nvim_command
local feed     = helpers.feed

describe('ts_context', function()
  local screen --- @type test.screen

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
      [14] = {background = Screen.colors.LightMagenta, foreground = Screen.colors.SlateBlue};
      [15] = {foreground = Screen.colors.SlateBlue};
    })

    cmd [[set runtimepath+=.,./nvim-treesitter]]

    exec_lua[[
    require'nvim-treesitter.configs'.setup {
      ensure_installed = {
        "c",
        "lua",
        "rust",
        "cpp",
        "typescript"
      },
      sync_install = true,
    }
    ]]
    cmd [[let $XDG_CACHE_HOME='scratch/cache']]
    cmd [[set packpath=]]
    cmd('syntax enable')
  end)

  it('load the plugin', function()
    exec_lua[[require'treesitter-context'.setup{}]]
  end)

  it('edit a file', function()
    exec_lua[[require'treesitter-context'.setup{}]]
    cmd('edit test/test_file.lua')
    exec_lua [[vim.treesitter.start()]]
    feed'<C-e>'
    feed'jj'
    -- screen:snapshot_util()
    screen:expect{grid=[[
      {1:local}{2: }{1:function}{2: }{3:foo}{14:()}{2:          }|
        {4:local} {4:function} {5:bar}{15:()}        |
      ^                              |
                                    |*2
        {4:end}                         |
                                    |
        {4:local} {4:function} {5:baz}{15:()}        |
                                    |*3
        {4:end}                         |
                                    |
      {4:end}                           |
      {6:~                             }|
                                    |
    ]]}

    feed'2<C-e>'
    feed'jj'
    screen:expect{grid=[[
      {1:local}{2: }{1:function}{2: }{3:foo}{14:()}{2:          }|
      {2:  }{1:local}{2: }{1:function}{2: }{3:bar}{14:()}{2:        }|
      ^                              |
        {4:end}                         |
                                    |
        {4:local} {4:function} {5:baz}{15:()}        |
                                    |*3
        {4:end}                         |
                                    |
      {4:end}                           |
      {6:~                             }|*3
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
      exec_lua [[vim.treesitter.start()]]
      feed'20<C-e>'

      screen:expect{grid=[[
        {1:impl}{2: }{7:Foo}{2: }{14:{}{2:                    }|
        {2:    }{1:fn}{2: }{3:bar}{14:(}{1:&}{3:self}{14:)}{2: }{14:{}{2:           }|
        {2:        }{1:if}{2: }{3:condition}{2: }{14:{}{2:        }|
        {2:            }{1:for}{2: }{3:i}{2: }{1:in}{2: }{10:0}{1:..}{10:100}{2: }{14:{}{2: }|
                                      |
        ^            {15:}}                 |
                {15:}}                     |
            {15:}}                         |
        {15:}}                             |
                                      |
        {4:struct} {9:Foo} {15:{}                  |
                                      |
            {5:active}{15::} {9:bool}{15:,}             |
                                      |
            {5:username}{15::} {9:String}{15:,}         |
                                      |
      ]]}

      feed'14<C-e>'
      screen:expect{grid=[[
        {1:struct}{2: }{7:Foo}{2: }{14:{}{2:                  }|
                                      |
            {5:email}{15::} {9:String}{15:,}            |
                                      |
            {5:sign_in_count}{15::} {9:u64}{15:,}       |
        ^                              |
        {15:}}                             |
        {6:~                             }|*8
                                      |
      ]]}

    end)

    it('c', function()
      cmd('edit test/test.c')
      exec_lua [[vim.treesitter.start()]]
      feed'<C-e>'

      -- Check the struct context
      screen:expect{grid=[[
        {1:struct}{2: }{7:Bert}{2: }{14:{}{2:                 }|
            {8:// comment}                |
            {9:int} {4:*}f2{15:;}                  |
            {8:// comment}                |*2
        ^    {8:// comment}                |
            {8:// comment}                |*2
        {15:};}                            |
                                      |
        {4:typedef} {4:enum} {15:{}                |
          {11:E1}{15:,}                         |
          {11:E2}{15:,}                         |
          {11:E3}                          |
          {8:// comment}                  |
                                      |
      ]]}

      feed'12<C-e>'

      -- Check the enum context
      screen:expect{grid=[[
        {1:typedef}{2: }{1:enum}{2: }{14:{}{2:                }|
          {11:E3}                          |
          {8:// comment}                  |*3
        ^  {8:// comment}                  |
          {8:// comment}                  |*2
        {15:}} {9:Myenum}{15:;}                     |
                                      |
        {9:int} {5:main}{15:(}{9:int} {5:arg1}{15:,}            |
                 {9:char} {4:**}{5:arg2}{15:,}         |
                 {9:char} {4:**}{5:arg3}          |
                 {15:)}                    |
        {15:{}                             |
                                      |
      ]]}

      -- func -> if -> for -> do while
      feed'40<C-e>'
      screen:expect{grid=[[
        {7:int}{2: }{3:main}{14:(}{7:int}{2: }{3:arg1}{14:,}{2:            }|
        {2:         }{7:char}{2: }{1:**}{3:arg2}{14:,}{2:         }|
        {2:  }{1:if}{2: }{14:(}{3:arg1}{2: }{1:==}{2: }{10:4}{2:               }|
        {2:      }{1:&&}{2: }{3:arg2}{2: }{1:==}{2: }{3:arg3}{14:)}{2: }{14:{}{2:      }|
        {2:    }{1:for}{2: }{14:(}{7:int}{2: }{3:i}{2: }{1:=}{2: }{10:0}{14:;}{2: }{3:i}{2: }{1:<}{2: }{3:arg1}{14:;}{2: }|
        ^                              |
              {4:do} {15:{}                    |
                {8:// comment}            |*5
                                      |
              {15:}} {4:while} {15:(}{11:1}{15:);}            |
              {8:// comment}              |
                                      |
      ]]}

      -- func -> if / else if / else
      feed'41<C-e>'
      screen:expect{grid=[[
        {7:int}{2: }{3:main}{14:(}{7:int}{2: }{3:arg1}{14:,}{2:            }|
        {2:  }{1:if}{2: }{14:(}{3:arg1}{2: }{1:==}{2: }{10:4}{2:               }|
        {2:      }{1:&&}{2: }{3:arg2}{2: }{1:==}{2: }{3:arg3}{14:)}{2: }{14:{}{2:      }|
        {2:  }{14:}}{2: }{1:else}{2: }{1:if}{2: }{14:(}{3:arg1}{2: }{1:==}{2: }{10:4}{14:)}{2: }{14:{}{2:     }|
        {2:  }{14:}}{2: }{1:else}{2: }{14:{}{2:                    }|
        ^    {8:// comment}                |
            {8:// comment}                |*9
                                      |
      ]]}
    end)

    it('cpp', function()
      cmd('edit test/test.cpp')
      exec_lua [[vim.treesitter.start()]]
      feed'<C-e>'

      screen:expect{grid=[[
        {1:struct}{2: }{7:Struct}{2: }{14:{}{2:               }|
            {9:int} {4:*}f2{15:;}                  |
                                      |*3
        ^    {8:// cursor position 1}      |
        {15:};}                            |
                                      |*9
      ]]}
      feed'16<C-e>'

      screen:expect{grid=[[
        {1:class}{2: }{7:Class}{2: }{14:{}{2:                 }|
            {9:int} {4:*}f2{15:;}                  |
                                      |*3
        ^    {8:// cursor position 2}      |
        {15:};}                            |
                                      |*9
      ]]}

      feed'16<C-e>'

      screen:expect{grid=[[
        {1:typedef}{2: }{1:enum}{2: }{14:{}{2:                }|
          {11:E2}{15:,}                         |
          {11:E3}                          |
                                      |*2
        ^  {8:// cursor position 3}        |
        {15:}} {9:myenum}{15:;}                     |
                                      |*9
      ]]}

      feed'26<C-e>'
      screen:expect{grid=[[
        {7:int}{2: }{3:main}{14:(}{7:int}{2: }{3:arg1}{14:,}{2:            }|
        {2:  }{1:if}{2: }{14:(}{3:arg1}{2: }{1:==}{2: }{10:4}{2:               }|
        {2:      }{1:&&}{2: }{3:arg2}{2: }{1:==}{2: }{3:arg3}{14:)}{2: }{14:{}{2:      }|
        {2:    }{1:for}{2: }{14:(}{7:int}{2: }{3:i}{2: }{1:=}{2: }{10:0}{14:;}{2: }{3:i}{2: }{1:<}{2: }{3:arg1}{14:;}{2: }|
        {2:      }{1:while}{2: }{14:(}{10:1}{14:)}{2: }{14:{}{2:             }|
        ^        {8:// cursor position 4}  |
              {15:}}                       |
            {15:}}                         |
          {15:}}                           |
                                      |*7
      ]]}

      feed'18<C-e>'
      screen:expect{grid=[[
        {7:int}{2: }{3:main}{14:(}{7:int}{2: }{3:arg1}{14:,}{2:            }|
        {2:         }{7:char}{2: }{1:**}{3:arg2}{14:,}{2:         }|
        {2:         }{7:char}{2: }{1:**}{3:arg3}{2:          }|
        {2:  }{1:do}{2: }{14:{}{2:                        }|
        {2:    }{1:for}{2: }{14:(}{7:auto}{2: }{3:value}{2: }{14::}{2: }{3:array}{14:)}{2: }{14:{}|
        ^      {8:// cursor position 5}    |
            {15:}}                         |
          {15:}} {4:while} {15:(}{11:1}{15:);}                |
        {15:}}                             |
        {6:~                             }|*6
                                      |
      ]]}
    end)

    it('typescript', function()
      cmd('edit test/test.ts')
      exec_lua [[vim.treesitter.start()]]
      feed'<C-e>'

      screen:expect{grid=[[
        {1:interface}{2: }{7:User}{2: }{14:{}{2:              }|
                                      |*3
          {5:id}{15::} {9:number}{15:;}                 |
        ^                              |
                                      |*3
        {15:}}                             |
                                      |
        {4:class} {9:UserAccount} {15:{}           |
          {5:name}{15::} {9:string}{15:;}               |
          {5:id}{15::} {9:number}{15:;}                 |
                                      |*2
      ]]}

      feed'21<C-e>'
      screen:expect{grid=[[
        {1:class}{2: }{7:UserAccount}{2: }{14:{}{2:           }|
        {2:  }{14:constructor(}{3:name}{14::}{2: }{7:string}{14:,}{2: }{3:id}|
        {2:    }{1:for}{2: }{14:(}{1:let}{2: }{3:i}{2: }{1:=}{2: }{10:0}{14:;}{2: }{3:i}{2: }{1:<}{2: }{10:3}{14:;}{2: }{3:i}{1:++}|
                                      |*2
        ^                              |
            {15:}}                         |
                                      |*4
          {15:}}                           |
        {15:}}                             |
                                      |*3
      ]]}

      feed'16<C-e>'
      screen:expect{grid=[[
        {1:function}{2: }{3:wrapInArray}{14:(}{3:obj}{14::}{2: }{7:stri}|
        {2:  }{1:if}{2: }{14:(}{1:typeof}{2: }{3:obj}{2: }{1:===}{2: }{10:"string"}{14:)}|
                                      |*3
        ^                              |
          {15:}}                           |
          {4:return} {5:obj}{15:;}                 |
        {15:}}                             |
        {6:~                             }|*6
                                      |
      ]]}
    end)

  end)

end)
