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

```lua
local ts_context = require'treesitter-context'
local CATEGORY = ts_context.CATEGORY
local f = ts_context.field_name_query
local t = ts_context.node_type_query

ts_context.setup{
    enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'.
    mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
    separator = nil, -- Bottom border of the context popup.
    categories = {
        -- Categories that should be shown.
        default = {
            CATEGORY.CLASS,
            CATEGORY.INTERFACE,
            CATEGORY.STRUCT,
            CATEGORY.ENUM,
            CATEGORY.FUNCTION,
            CATEGORY.METHOD,
            -- CATEGORY.FOR, -- These won't appear in the context.
            -- CATEGORY.WHILE,
            -- CATEGORY.IF,
            -- CATEGORY.SWITCH,
            -- CATEGORY.CASE,
            CATEGORY.SECTION,
        },
        rust = {
            -- Override for specific filetypes.
            -- Note that when setting language specific categories, the default
            -- categories are ignored
        },
    },
    queries = {
        -- Filetype specific queries for treesitter nodes
        -- If queries for a language are missing, *open a PR* so everyone can benefit.
        cpp = {
            ['class_specifier'] = { -- The entry key should be the exact node type
                -- The category that this context belongs to (see https://github.com/nvim-treesitter/nvim-treesitter-context/blob/master/lua/treesitter-context.lua#L24).
                category = CATEGORY.CLASS,
                -- The last child node that should show up in the context popup,
                -- in reverse order. So the `base_class_clause` node should appear
                -- after the `name` node.
                -- There are node type queries here `t'base_class_clause'`, and
                -- field name queries like `f'name'`
                last = { t'base_class_clause', f'name' },
                -- Child nodes that should be skipped when displaying the context.
                skip = { t'<some unwanted child node>' },
            },
        },
        ...
    }
    fallback_patterns = {
        -- Fallback patterns for filetypes that have no exact queries.
        -- Match patterns for TS nodes. These get wrapped to match at word
        -- boundaries.
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
        rust = {
            -- Additional patterns for specific filetypes
            'impl_item',
        },
    },
    exclude_patterns = {
        -- Exclude node types that match these patterns
        default = {
            -- Patterns that are always excluded
        },
        go = {
            -- Additional patterns for specific filetypes
        },
    },

    -- [!] The options below are exposed but shouldn't require your attention,
    --     you can safely ignore them.

    zindex = 20, -- The Z-index of the context window
}
```

## Commands

`TSContextEnable`, `TSContextDisable` and `TSContextToggle`.

## Appearance

Use the highlight group `TreesitterContext` to change the colors of the
context. Per default it links to `NormalFloat`.

Use the highlight group `TreesitterContextLineNumber` to change the colors of the
context line numbers if `line_numbers` is set. Per default it links to `LineNr`.
