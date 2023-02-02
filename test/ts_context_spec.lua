local helpers = require('test.functional.helpers')()
local Screen = require('test.functional.ui.screen')

local clear    = helpers.clear
local exec_lua = helpers.exec_lua
local eq       = helpers.eq
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
    end)

    it('rust', function()
      cmd('edit test/test.rs')
      feed'L'
      feed'20<C-e>5j'

      screen:expect{grid=[[
        {1:impl}{2: Foo                      }|
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

      feed'14<C-e>3j'
      screen:expect{grid=[[
        {1:struct}{2: }{3:Foo}{2: {                  }|
                                      |
            email: {9:String},            |
        ^                              |
            sign_in_count: {9:u64},       |
                                      |
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
      feed'L'
      feed'<C-e>'

      -- Check the struct context
      screen:expect{grid=[[
        {7:struct}{2: Bert {                 }|
            {8:// comment}                |
            {9:int} *f2;                  |
            {8:// comment}                |
            {8:// comment}                |
            {8:// comment}                |
            {8:// comment}                |
            {8:// comment}                |
        };                            |
                                      |
        {9:typedef} {9:enum} {                |
          E1,                         |
          E2,                         |
          ^E3                          |
          {8:// comment}                  |
                                      |
      ]]}

      feed'12<C-e>'

      -- Check the enum context
      screen:expect{grid=[[
        {7:typedef}{2: }{7:enum}{2: {                }|
          ^E3                          |
          {8:// comment}                  |
          {8:// comment}                  |
          {8:// comment}                  |
          {8:// comment}                  |
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

      cmd'set scrolloff=4'
      feed'40<C-e>'
      screen:expect{grid=[[
        {7:int}{2: main(}{7:int}{2: arg1, }{7:char}{2: **arg2}|
        {2:  }{1:if}{2: (arg1 == }{10:4}{2: && arg2 == arg}|
        {2:    }{1:for}{2: (}{7:int}{2: i = }{10:0}{2:; i < arg1; }|
        {2:      }{1:while}{2: (}{10:1}{2:) {             }|
          ^      {8:// comment}            |
                {8:// comment}            |
                {8:// comment}            |
              }                       |
                                      |
              {4:do} {                    |
                {8:// comment}            |
                {8:// comment}            |
                {8:// comment}            |
                {8:// comment}            |
                {8:// comment}            |
                                      |
      ]]}
    end)
  end)

end)
