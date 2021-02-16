# nvim-treesitter-context

Very basic alternative to [context.vim](https://github.com/wellle/context.vim)
implemented with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).

## Install

```vim
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'romgrk/nvim-treesitter-context'
```

## Screenshot

![theme](./static/demo.gif)

### Notes

Currently only updates the context on `CursorMoved` because there is no good scroll
event, and trying to remap basic movement mappings like context.vim does ends up being
brittle.

## Commands

`TSContextEnable` and `TSContextDisable`.

## Appearance

Use the highlight group `TreesitterContext` to change the colors of the
context. Per default it links to `NormalFloat`.
