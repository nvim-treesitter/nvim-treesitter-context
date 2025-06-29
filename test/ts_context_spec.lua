local helpers = require('nvim-test.helpers')
local tc_helpers = require('test.helpers')
local Screen = require('nvim-test.screen')

local install_langs = require('test.helpers').install_langs

local clear = helpers.clear
local exec_lua = helpers.exec_lua
local cmd = helpers.api.nvim_command
local feed = helpers.feed

describe('ts_context', function()
  local screen --- @type test.screen

  before_each(function()
    clear()
    exec_lua(tc_helpers.setup)
    screen = Screen.new(30, 16)

    -- Need ext_messages as nvim-treesitter parser installation
    -- uses nvim_echo which can cause press enter prompts and thus blocks
    screen:attach({ ext_messages = true })

    local default_attrs = {
      [1] = {
        foreground = Screen.colors.Brown,
        background = Screen.colors.LightMagenta,
        bold = true,
      },
      [2] = { background = Screen.colors.LightMagenta },
      [3] = { foreground = Screen.colors.DarkCyan, background = Screen.colors.LightMagenta },
      [4] = { bold = true, foreground = Screen.colors.Brown },
      [5] = { foreground = Screen.colors.DarkCyan },
      [6] = { bold = true, foreground = Screen.colors.Blue },
      [7] = {
        foreground = Screen.colors.SeaGreen,
        background = Screen.colors.LightMagenta,
        bold = true,
      },
      [8] = { foreground = Screen.colors.Blue },
      [9] = { bold = true, foreground = Screen.colors.SeaGreen },
      [10] = { foreground = Screen.colors.Fuchsia, background = Screen.colors.LightMagenta },
      [11] = { foreground = Screen.colors.Fuchsia },
      [12] = { foreground = tonumber('0x6a0dad'), background = Screen.colors.LightMagenta },
      [13] = { foreground = Screen.colors.White, background = Screen.colors.Red },
      [14] = { background = Screen.colors.LightMagenta, foreground = Screen.colors.SlateBlue },
      [15] = { foreground = Screen.colors.SlateBlue },
      [16] = { foreground = tonumber('0x6a0dad') },
      [17] = { background = Screen.colors.Plum1, bold = true, foreground = Screen.colors.Magenta1 },
      [18] = { background = Screen.colors.LightMagenta, foreground = Screen.colors.Blue },
    }

    cmd('colorscheme vim')

    screen:set_default_attr_ids(default_attrs)

    cmd('syntax enable')
  end)

  it('load the plugin', function()
    exec_lua(tc_helpers.setup)
  end)

  it('edit a file', function()
    exec_lua(install_langs, 'lua')
    exec_lua(tc_helpers.setup)
    cmd('edit test/test_file.lua')
    exec_lua([[vim.treesitter.start()]])
    feed('<C-e>')
    feed('jj')
    -- screen:snapshot_util()
    screen:expect({
      grid = [[
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
      {6:~                             }|*2
    ]],
    })

    feed('2<C-e>')
    feed('jj')
    screen:expect({
      grid = [[
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
      {6:~                             }|*4
    ]],
    })
  end)

  it('#627', function()
    exec_lua(install_langs, { 'vimdoc' })
    exec_lua(tc_helpers.setup, { multiwindow = true })
    cmd('edit test/snapshots/snapshot.md')
    cmd('set splitkeep=screen')
    cmd('help')
    cmd('sleep 100m')
  end)

  describe('language:', function()
    before_each(function()
      exec_lua(tc_helpers.setup, {
        mode = 'topline',
      })
      cmd('set scrolloff=5')
      cmd('set nowrap')
    end)

    it('rust', function()
      exec_lua(install_langs, 'rust')
      cmd('edit test/snapshots/snapshot.rs')
      exec_lua([[vim.treesitter.start()]])
      feed('20<C-e>')

      screen:expect({
        grid = [[
        {1:impl}{2: }{7:Foo}{2: }{14:{}{2:                    }|
        {2:    }{1:fn}{2: }{3:bar}{14:(}{1:&}{14:self)}{2: }{14:{}{2:           }|
        {2:        }{1:if}{2: }{3:condition}{2: }{14:{}{2:        }|
        {2:            }{1:for}{2: }{3:i}{2: }{1:in}{2: }{10:0}{1:..}{10:100}{2: }{14:{}{2: }|
                                      |
        ^                {5:foo}{15:(}{4:async} {4:move}|
                                      |
                                      |
                                      |
                                      |
                                      |
                                      |
                            {8:// comment}|
                                      |
                                      |
                                      |
      ]],
      })

      feed('14<C-e>')
      screen:expect({
        grid = [[
        {1:impl}{2: }{7:Foo}{2: }{14:{}{2:                    }|
        {2:    }{1:fn}{2: }{3:bar}{14:(}{1:&}{14:self)}{2: }{14:{}{2:           }|
        {2:        }{1:if}{2: }{3:condition}{2: }{14:{}{2:        }|
        {2:            }{1:for}{2: }{3:i}{2: }{1:in}{2: }{10:0}{1:..}{10:100}{2: }{14:{}{2: }|
        {2:                }{3:foo}{14:(}{1:async}{2: }{1:move}|
        ^                {15:})}            |
                    {15:}}                 |
                {15:}}                     |
                                      |
                                      |
                                      |
                                      |
                                      |
                {4:try} {15:{}                 |
                                      |
                                      |
      ]],
      })
    end)

    it('c', function()
      exec_lua(install_langs, 'c')
      cmd('edit test/test.c')
      exec_lua([[vim.treesitter.start()]])
      feed('<C-e>')

      -- Check the struct context
      screen:expect({
        grid = [[
        {7:struct}{2: }{7:Bert}{2: }{14:{}{2:                 }|
            {8:// comment}                |
            {15:int} {4:*}{5:f2}{15:;}                  |
            {8:// comment}                |*2
        ^    {8:// comment}                |
            {8:// comment}                |*2
        {15:};}                            |
                                      |
        {9:typedef} {9:enum} {15:{}                |
          {11:E1}{15:,}                         |
          {11:E2}{15:,}                         |
          {11:E3}                          |
          {8:// comment}                  |*2
      ]],
      })

      feed('12<C-e>')

      -- Check the enum context
      screen:expect({
        grid = [[
        {7:typedef}{2: }{7:enum}{2: }{14:{}{2:                }|
          {11:E3}                          |
          {8:// comment}                  |*3
        ^  {8:// comment}                  |
          {8:// comment}                  |*2
        {15:}} {9:Myenum}{15:;}                     |
                                      |
        {15:int} {5:main}{15:(int} {5:arg1}{15:,}            |
                 {15:char} {4:**}{5:arg2}{15:,}         |
                 {15:char} {4:**}{5:arg3}          |
                 {15:)}                    |
        {15:{}                             |
                                      |
      ]],
      })

      -- func -> if -> for -> do while
      feed('40<C-e>')
      screen:expect({
        grid = [[
        {14:int}{2: }{3:main}{14:(int}{2: }{3:arg1}{14:,}{2:            }|
        {2:         }{14:char}{2: }{1:**}{3:arg2}{14:,}{2:         }|
        {2:  }{1:if}{2: }{14:(}{3:arg1}{2: }{1:==}{2: }{10:4}{2:               }|
        {2:      }{1:&&}{2: }{3:arg2}{2: }{1:==}{2: }{3:arg3}{14:)}{2: }{14:{}{2:      }|
        {2:    }{1:for}{2: }{14:(int}{2: }{3:i}{2: }{1:=}{2: }{10:0}{14:;}{2: }{3:i}{2: }{1:<}{2: }{3:arg1}{14:;}{2: }|
        ^                              |
              {4:do} {15:{}                    |
                {8:// comment}            |*5
                                      |
              {15:}} {4:while} {15:(}{11:1}{15:);}            |
              {8:// comment}              |*2
      ]],
      })

      -- func -> if / else if / else
      feed('41<C-e>')
      screen:expect({
        grid = [[
        {14:int}{2: }{3:main}{14:(int}{2: }{3:arg1}{14:,}{2:            }|
        {2:  }{1:if}{2: }{14:(}{3:arg1}{2: }{1:==}{2: }{10:4}{2:               }|
        {2:      }{1:&&}{2: }{3:arg2}{2: }{1:==}{2: }{3:arg3}{14:)}{2: }{14:{}{2:      }|
        {2:  }{14:}}{2: }{1:else}{2: }{1:if}{2: }{14:(}{3:arg1}{2: }{1:==}{2: }{10:4}{14:)}{2: }{14:{}{2:     }|
        {2:  }{14:}}{2: }{1:else}{2: }{14:{}{2:                    }|
        ^    {8:// comment}                |
            {8:// comment}                |*10
      ]],
      })
    end)

    it('cpp', function()
      exec_lua(install_langs, 'cpp')
      cmd('edit test/snapshots/snapshot.cpp')
      exec_lua([[vim.treesitter.start()]])
      feed('<C-e>')

      screen:expect({
        grid = [[
        {7:struct}{2: }{7:Struct}{2: }{14:{}{2:               }|
            {15:int} {4:*}{5:f2}{15:;}                  |
                                      |*3
        ^    {8:// cursor position 1}      |
        {15:};}                            |
                                      |*8
        {9:class} {9:Class} {15:{}                 |
      ]],
      })
      feed('16<C-e>')

      screen:expect({
        grid = [[
        {7:class}{2: }{7:Class}{2: }{14:{}{2:                 }|
            {15:int} {4:*}{5:f2}{15:;}                  |
                                      |*3
        ^    {8:// cursor position 2}      |
        {15:};}                            |
                                      |*8
        {9:typedef} {9:enum} {15:{}                |
      ]],
      })

      feed('16<C-e>')

      screen:expect({
        grid = [[
        {7:typedef}{2: }{7:enum}{2: }{14:{}{2:                }|
          {11:E2}{15:,}                         |
          {11:E3}                          |
                                      |*2
        ^  {8:// cursor position 3}        |
        {15:}} {9:myenum}{15:;}                     |
                                      |*9
      ]],
      })

      feed('26<C-e>')
      screen:expect({
        grid = [[
        {14:int}{2: }{3:main}{14:(int}{2: }{3:arg1}{14:,}{2:            }|
        {2:  }{1:if}{2: }{14:(}{3:arg1}{2: }{1:==}{2: }{10:4}{2:               }|
        {2:      }{1:&&}{2: }{3:arg2}{2: }{1:==}{2: }{3:arg3}{14:)}{2: }{14:{}{2:      }|
        {2:    }{1:for}{2: }{14:(int}{2: }{3:i}{2: }{1:=}{2: }{10:0}{14:;}{2: }{3:i}{2: }{1:<}{2: }{3:arg1}{14:;}{2: }|
        {2:      }{1:while}{2: }{14:(}{10:1}{14:)}{2: }{14:{}{2:             }|
        ^        {8:// cursor position 4}  |
              {15:}}                       |
            {15:}}                         |
          {15:}}                           |
                                      |*6
          {4:do} {15:{}                        |
      ]],
      })

      feed('18<C-e>')
      screen:expect({
        grid = [[
        {14:int}{2: }{3:main}{14:(int}{2: }{3:arg1}{14:,}{2:            }|
        {2:         }{14:char}{2: }{1:**}{3:arg2}{14:,}{2:         }|
        {2:         }{14:char}{2: }{1:**}{3:arg3}{2:          }|
        {2:  }{1:do}{2: }{14:{}{2:                        }|
        {2:    }{1:for}{2: }{14:(auto}{2: }{3:value}{2: }{14::}{2: }{3:array}{14:)}{2: }{14:{}|
        ^      {8:// cursor position 5}    |
            {15:}}                         |
          {15:}} {4:while} {15:(}{11:1}{15:);}                |
        {15:}}                             |
        {6:~                             }|*7
      ]],
      })
    end)

    it('php', function()
      exec_lua(install_langs, 'php')
      cmd('edit test/snapshots/snapshot.php')
      exec_lua([[vim.treesitter.start()]])

      feed('7<C-e>')
      screen:expect({
        grid = [[
        {1:function}{2: }{3:foo}{14:(}{3:$a}{14:,}{2: }{3:$b}{14:)}{2: }{14:{}{2:        }|
        {2:  }{1:while}{2: }{14:(}{3:$a}{2: }{1:<=}{2: }{3:$b}{14:)}{2: }{14:{}{2:          }|
            {5:$index} {4:=} {5:$low} {4:+} {5:floor}{15:((}{5:$hi}|
            {8:// comment}                |
            {5:$indexValue} {4:=} {5:$a}{15:;}         |
        ^    {4:if} {15:(}{5:$indexValue} {4:===} {5:$a}{15:)} {15:{} |
              {8:// comment}              |
                                      |
                                      |
              {5:$position} {4:=} {5:$index}{15:;}     |
              {4:return} {15:(int)} {5:$position}{15:;} |
            {15:}}                         |
            {4:if} {15:(}{5:$indexValue} {4:<} {5:$key}{15:)} {15:{} |
              {8:// comment}              |
                                      |
              {5:$low} {4:=} {5:$index} {4:+} {11:1}{15:;}      |
      ]],
      })

      feed('67<C-e>')
      screen:expect({
        grid = [[
        {7:class}{2: }{7:Fruit}{2: }{14:{}{2:                 }|
                                      |
                                      |
                                      |
                                      |
        ^    {15:#[}{16:ReturnTypeWillChange}{15:]}   |
            {4:public} {4:function} {5:rot}{15:():} {15:voi}|
            {15:{}                         |
                                      |
                                      |
                {4:return}{15:;}               |
            {15:}}                         |
                                      |
                                      |
                                      |
         {8:// comment}                   |

      ]],
      })

      feed('5<C-e>')
      screen:expect({
        grid = [[
        {7:class}{2: }{7:Fruit}{2: }{14:{}{2:                 }|
        {2:    }{1:public}{2: }{1:function}{2: }{3:rot}{14:():}{2: }{14:voi}|
        {2:    }{14:{}{2:                         }|
                                      |
                                      |
        ^        {4:return}{15:;}               |
            {15:}}                         |
                                      |
                                      |
                                      |
         {8:// comment}                   |
                                      |
                                      |
                                      |
                                      |
        {15:}}                             |
      ]],
      })
    end)

    it('typescript', function()
      exec_lua(install_langs, 'typescript')
      cmd('edit test/snapshots/snapshot.ts')
      exec_lua([[vim.treesitter.start()]])
      feed('<C-e>')

      screen:expect({
        grid = [[
        {7:interface}{2: }{7:User}{2: }{14:{}{2:              }|
                                      |*3
          {5:id}{15::} {15:number;}                 |
        ^                              |
                                      |*3
        {15:}}                             |
                                      |
        {9:class} {9:UserAccount} {15:{}           |
          {5:name}{15::} {15:string;}               |
          {5:id}{15::} {15:number;}                 |
                                      |*2
      ]],
      })

      feed('21<C-e>')
      screen:expect({
        grid = [[
        {7:class}{2: }{7:UserAccount}{2: }{14:{}{2:           }|
        {2:  }{14:constructor(}{3:name}{14::}{2: }{14:string,}{2: }{3:id}|
        {2:    }{1:for}{2: }{14:(}{1:let}{2: }{3:i}{2: }{1:=}{2: }{10:0}{14:;}{2: }{3:i}{2: }{1:<}{2: }{10:3}{14:;}{2: }{3:i}{1:++}|
                                      |*2
        ^                              |
            {15:}}                         |
                                      |*4
          {15:}}                           |
        {15:}}                             |
                                      |*2
        {4:function} {5:wrapInArray}{15:(}{5:obj}{15::} {15:stri}|
      ]],
      })

      feed('16<C-e>')
      screen:expect({
        grid = [[
        {1:function}{2: }{3:wrapInArray}{14:(}{3:obj}{14::}{2: }{14:stri}|
        {2:  }{1:if}{2: }{14:(}{1:typeof}{2: }{3:obj}{2: }{1:===}{2: }{10:"string"}{14:)}|
                                      |*3
        ^                              |
          {15:}}                           |
          {4:return} {5:obj}{15:;}                 |
        {15:}}                             |
        {6:~                             }|*7
      ]],
      })
    end)

    it('markdown', function()
      exec_lua(install_langs, { 'markdown', 'markdown_inline', 'html' })
      cmd('edit test/snapshots/snapshot.md')
      exec_lua([[vim.treesitter.start()]])

      feed('3<C-e>')
      screen:expect({
        grid = [[
        {18:```}{1:html}{2:                       }|
        {14:<html>}{2:                        }|
        {2:  }{14:<body>}{2:                      }|
                                      |*2
        ^                              |
        {8:    }{15:<script>}                  |
                                      |*9
      ]],
      })

      feed('5<C-e>')
      screen:expect({
        grid = [[
        {18:```}{1:html}{2:                       }|
        {14:<html>}{2:                        }|
        {2:  }{14:<body>}{2:                      }|
        {2:    }{14:<script>}{2:                  }|
                                      |
        ^                              |
                                      |*8
        {8:      }{4:function}{8: }{5:test}{15:()}{8: }{15:{}       |
        {8:        }{4:if}{8: }{5:test}{8: }{4:!=}{8: }{11:""}{8: }{15:{}       |
      ]],
      })

      feed('12<C-e>')
      screen:expect({
        grid = [[
          {18:```}{1:html}{2:                       }|
          {14:<html>}{2:                        }|
          {2:  }{14:<body>}{2:                      }|
          {2:    }{14:<script>}{2:                  }|
                                        |
          ^                              |
                                        |*10
      ]],
      })
    end)

    -- Separate Markdown testcase to test plugin behavior with
    -- unsupported injected languages (markdown_inline does not
    -- have queries specified)
    it('markdown_inline', function()
      exec_lua(install_langs, { 'markdown', 'markdown_inline' })
      cmd('edit test/snapshots/snapshot.md')
      exec_lua([[vim.treesitter.start()]])

      feed('47<C-e>')
      screen:expect({
        grid = [[
        {17:# Title}{2:                       }|
                                      |*4
        ^Test                          |
                                      |*10
      ]],
      })
    end)
  end)
end)
