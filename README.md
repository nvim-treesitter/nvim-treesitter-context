# nvim-treesitter-context

Lightweight alternative to [context.vim](https://github.com/wellle/context.vim)
implemented with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).

## Requirements

Neovim >= v0.8.2

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

## Supported Languages
<details>
<summary>click to expand</summary

  - [x] `bash`
  - [x] `c`
  - [x] `c_sharp`
  - [x] `capnp`
  - [x] `cpp`
  - [x] `css`
  - [x] `cuda`
  - [x] `d`
  - [x] `dart`
  - [x] `elixir`
  - [x] `fish`
  - [x] `fortran`
  - [x] `go`
  - [x] `graphql`
  - [x] `html_tags`
  - [x] `ini`
  - [x] `java`
  - [x] `javascript`
  - [x] `json`
  - [x] `latex`
  - [x] `lua`
  - [x] `markdown`
  - [x] `matlab`
  - [x] `nix`
  - [x] `norg`
  - [x] `ocaml_interface`
  - [x] `ocaml`
  - [x] `php`
  - [x] `prisma`
  - [x] `python`
  - [x] `r`
  - [x] `ruby`
  - [x] `rust`
  - [x] `scala`
  - [x] `scss`
  - [x] `smali`
  - [x] `swift`
  - [x] `teal`
  - [x] `terraform`
  - [x] `toml`
  - [x] `tsx`
  - [x] `typescript`
  - [x] `usd`
  - [x] `verilog`
  - [x] `vim`
  - [x] `yaml`
  - [x] `zig`
  - [ ] `ada`
  - [ ] `agda`
  - [ ] `arduino`
  - [ ] `astro`
  - [ ] `beancount`
  - [ ] `bibtex`
  - [ ] `bicep`
  - [ ] `blueprint`
  - [ ] `chatito`
  - [ ] `clojure`
  - [ ] `cmake`
  - [ ] `commonlisp`
  - [ ] `cooklang`
  - [ ] `cpon`
  - [ ] `devicetree`
  - [ ] `dhall`
  - [ ] `dockerfile`
  - [ ] `dot`
  - [ ] `ebnf`
  - [ ] `ecma`
  - [ ] `eex`
  - [ ] `elm`
  - [ ] `elsa`
  - [ ] `elvish`
  - [ ] `embedded_template`
  - [ ] `erlang`
  - [ ] `fennel`
  - [ ] `foam`
  - [ ] `fsh`
  - [ ] `func`
  - [ ] `fusion`
  - [ ] `gdscript`
  - [ ] `git_rebase`
  - [ ] `gleam`
  - [ ] `glimmer`
  - [ ] `glsl`
  - [ ] `godot_resource`
  - [ ] `gomod`
  - [ ] `gosum`
  - [ ] `gowork`
  - [ ] `hack`
  - [ ] `haskell`
  - [ ] `hcl`
  - [ ] `heex`
  - [ ] `hjson`
  - [ ] `hlsl`
  - [ ] `hocon`
  - [ ] `html`
  - [ ] `htmldjango`
  - [ ] `http`
  - [ ] `jq`
  - [ ] `jsdoc`
  - [ ] `json5`
  - [ ] `jsonc`
  - [ ] `jsonnet`
  - [ ] `jsx`
  - [ ] `julia`
  - [ ] `kdl`
  - [ ] `kotlin`
  - [ ] `lalrpop`
  - [ ] `ledger`
  - [ ] `llvm`
  - [ ] `m68k`
  - [ ] `menhir`
  - [ ] `mermaid`
  - [ ] `meson`
  - [ ] `nickel`
  - [ ] `ocamllex`
  - [ ] `pascal`
  - [ ] `perl`
  - [ ] `phpdoc`
  - [ ] `pioasm`
  - [ ] `po`
  - [ ] `poe_filter`
  - [ ] `proto`
  - [ ] `prql`
  - [ ] `pug`
  - [ ] `ql`
  - [ ] `qmldir`
  - [ ] `qmljs`
  - [ ] `query`
  - [ ] `racket`
  - [ ] `rasi`
  - [ ] `rego`
  - [ ] `rnoweb`
  - [ ] `ron`
  - [ ] `rst`
  - [ ] `scheme`
  - [ ] `slint`
  - [ ] `smithy`
  - [ ] `solidity`
  - [ ] `sparql`
  - [ ] `sql`
  - [ ] `starlark`
  - [ ] `supercollider`
  - [ ] `surface`
  - [ ] `svelte`
  - [ ] `sxhkdrc`
  - [ ] `t32`
  - [ ] `thrift`
  - [ ] `tiger`
  - [ ] `tlaplus`
  - [ ] `todotxt`
  - [ ] `turtle`
  - [ ] `twig`
  - [ ] `ungrammar`
  - [ ] `v`
  - [ ] `vala`
  - [ ] `vhs`
  - [ ] `vue`
  - [ ] `wgsl`
  - [ ] `wgsl_bevy`
  - [ ] `yang`
  - [ ] `yuck`

</details>

## Configuration

(Default values are shown below)

```lua
require'treesitter-context'.setup{
  enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
  max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
  min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
  line_numbers = true,
  multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
  trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
  -- Separator between context and content. Should be a single character string, like '-'.
  -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
  separator = nil,
  zindex = 20, -- The Z-index of the context window
  on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
}
```

## Commands

`TSContextEnable`, `TSContextDisable` and `TSContextToggle`.

## Appearance

Use the highlight group `TreesitterContext` to change the colors of the
context. Per default it links to `NormalFloat`.

Use the highlight group `TreesitterContextLineNumber` to change the colors of the
context line numbers if `line_numbers` is set. Per default it links to `LineNr`.

Use the highlight group `TreesitterContextBottom` to change the highlight of the
last line of the context window. By default it links to `NONE`.
However, you can use this to create a border by applying an underline highlight, e.g:

```vim
hi TreesitterContextBottom gui=underline guisp=Grey
```

## Jumping to context (upwards)

```lua
vim.keymap.set("n", "[c", function()
  require("treesitter-context").go_to_context()
end, { silent = true })
```

## Adding support for other languages

See [CONTRIBUTING.md](CONTRIBUTING.md)

