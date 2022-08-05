# nvim-treesitter-context

Lightweight alternative to [context.vim](https://github.com/wellle/context.vim)
implemented with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).

## Requirements

Neovim >= v0.7.x

Note: if you need support for Neovim 0.6.x please use the tag `compat/0.6`.

## Install

via vim-plug

```vim
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nvim-treesitter/nvim-treesitter-context'
```

via packer

```lua
use 'nvim-treesitter/nvim-treesitter'
use 'nvim-treesitter/nvim-treesitter-context'
```


## Screenshot

![theme](./static/demo.gif)

### Notes

This plugins uses the new neovim `WinScrolled` event when available to update its
context window. Make sure to have a recent neovim build to get this behavior. The fallback
behavior is to update its content on `CursorMoved`.

## Configuration

(Default values are shown below)

```lua
require'treesitter-context'.setup{
    enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
        -- For all filetypes
        -- Note that setting an entry here replaces all other patterns for this entry.
        -- By setting the 'default' entry below, you can control which nodes you want to
        -- appear in the context window.
        default = {
            'class',
            'function',
            'method',
            -- 'for', -- These won't appear in the context
            -- 'while',
            -- 'if',
            -- 'switch',
            -- 'case',
        },
        -- Example for a specific filetype.
        -- If a pattern is missing, *open a PR* so everyone can benefit.
        --   rust = {
        --       'impl_item',
        --   },
    },
    exact_patterns = {
        -- Example for a specific filetype with Lua patterns
        -- Treat patterns.rust as a Lua pattern (i.e "^impl_item$" will
        -- exactly match "impl_item" only)
        -- rust = true,
    },

    -- [!] The options below are exposed but shouldn't require your attention,
    --     you can safely ignore them.

    zindex = 20, -- The Z-index of the context window
    mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
    separator = nil, -- Separator between context and content. Should be a single character string, like '-'.
}
```

## Commands

`TSContextEnable`, `TSContextDisable` and `TSContextToggle`.

## Appearance

Use the highlight group `TreesitterContext` to change the colors of the
context. Per default it links to `NormalFloat`.

Use the highlight group `TreesitterContextLineNumber` to change the colors of the
context line numbers if `line_numbers` is set. Per default it links to `LineNr`.
