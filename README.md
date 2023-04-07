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

## Supported languages

  - [x] `bash`
  - [x] `c`
  - [x] `c_sharp`
  - [x] `cpp`
  - [x] `dart`
  - [x] `elixir`
  - [x] `go`
  - [x] `java`
  - [x] `javascript`
  - [x] `json`
  - [x] `latex`
  - [x] `lua`
  - [x] `markdown`
  - [x] `php`
  - [x] `python`
  - [x] `r`
  - [x] `ruby`
  - [x] `rust`
  - [x] `scala`
  - [x] `teal`
  - [x] `toml`
  - [x] `tsx`
  - [x] `typescript`
  - [x] `verilog`
  - [x] `vim`
  - [x] `yaml`
  - [ ] `ada`
  - [ ] `agda`
  - [ ] `arduino`
  - [ ] `astro`
  - [ ] `beancount`
  - [ ] `bibtex`
  - [ ] `bicep`
  - [ ] `blueprint`
  - [ ] `capnp`
  - [ ] `chatito`
  - [ ] `clojure`
  - [ ] `cmake`
  - [ ] `commonlisp`
  - [ ] `cooklang`
  - [ ] `cpon`
  - [ ] `css`
  - [ ] `cuda`
  - [ ] `d`
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
  - [ ] `fish`
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
  - [ ] `graphql`
  - [ ] `hack`
  - [ ] `haskell`
  - [ ] `hcl`
  - [ ] `heex`
  - [ ] `hjson`
  - [ ] `hlsl`
  - [ ] `hocon`
  - [ ] `html`
  - [ ] `html_tags`
  - [ ] `htmldjango`
  - [ ] `http`
  - [ ] `ini`
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
  - [ ] `matlab`
  - [ ] `menhir`
  - [ ] `mermaid`
  - [ ] `meson`
  - [ ] `nickel`
  - [ ] `nix`
  - [x] `ocaml`
  - [x] `ocaml_interface`
  - [ ] `ocamllex`
  - [ ] `pascal`
  - [ ] `perl`
  - [ ] `phpdoc`
  - [ ] `pioasm`
  - [ ] `po`
  - [ ] `poe_filter`
  - [ ] `prisma`
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
  - [ ] `scss`
  - [ ] `slint`
  - [ ] `smali`
  - [ ] `smithy`
  - [ ] `solidity`
  - [ ] `sparql`
  - [ ] `sql`
  - [ ] `starlark`
  - [ ] `supercollider`
  - [ ] `surface`
  - [ ] `svelte`
  - [ ] `swift`
  - [ ] `sxhkdrc`
  - [ ] `t32`
  - [ ] `terraform`
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
  - [ ] `zig`

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

## Adding support for other languages

To add support for another language, simply add a `context.scm` file under
`queries/[LANG]`.

Queries specify the `@context` capture which specifies the first line of a node
will be used for the context.

Here is a basic example for C:

```query
(function_definition) @context
(for_statement) @context
(if_statement) @context
(while_statement) @context
(do_statement) @context
```

You can easily look at a node names of a tree using `InspectTree` in Nvim 0.9.

Additionally an optional `@context.end` capture can also be specified. When
provided, the text from the start of the `@context` capture to the start of
`@context.end` capture (exclusive) will be used for the context and joined into
a single line.

Here's what that looks like for C:

```query
(if_statement consequence: (_ (_) @context.end)) @context
```

This query specifies that everything from the `if` keyword up-to the first
statement (exclusive) should be used for the context. This is useful when an
if-statement spans multiple lines.
