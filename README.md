# nvim-treesitter-context

Lightweight alternative to [context.vim](https://github.com/wellle/context.vim)

Note: This plugin requires necessary language parsers in order to work. Non default
language parsers can be installed with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).

## Requirements

Neovim >= v0.9.0

Note: if you need support for Neovim 0.6.x please use the tag `compat/0.6`.

## Screenshot

![theme](./static/demo.gif)

## Supported Languages

Note: support for specific languages is strictly community maintained and can break from time to time as parsers are updated.

<details>
<summary>Supported (click to expand)</summary

  - [x] `ada`
  - [x] `apex`
  - [x] `bash`
  - [x] `c`
  - [x] `c_sharp`
  - [x] `capnp`
  - [x] `clojure`
  - [x] `cmake`
  - [x] `cpp`
  - [x] `css`
  - [x] `cuda`
  - [x] `cue`
  - [x] `d`
  - [x] `dart`
  - [x] `devicetree`
  - [x] `diff`
  - [x] `elixir`
  - [x] `elm`
  - [x] `enforce`
  - [x] `fennel`
  - [x] `fish`
  - [x] `fortran`
  - [x] `gdscript`
  - [x] `glimmer`
  - [x] `glsl`
  - [x] `go`
  - [x] `graphql`
  - [x] `groovy`
  - [x] `haskell`
  - [x] `html`
  - [x] `ini`
  - [x] `janet_simple`
  - [x] `java`
  - [x] `javascript`
  - [x] `json`
  - [x] `jsonnet`
  - [x] `julia`
  - [x] `kdl`
  - [x] `kotlin`
  - [x] `latex`
  - [x] `liquidsoap`
  - [x] `lua`
  - [x] `make`
  - [x] `markdown`
  - [x] `matlab`
  - [x] `nim`
  - [x] `nix`
  - [x] `nu`
  - [x] `objdump`
  - [x] `ocaml`
  - [x] `ocaml_interface`
  - [x] `odin`
  - [x] `php`
  - [x] `php_only`
  - [x] `prisma`
  - [x] `proto`
  - [x] `python`
  - [x] `r`
  - [x] `ruby`
  - [x] `rust`
  - [x] `scala`
  - [x] `scss`
  - [x] `smali`
  - [x] `solidity`
  - [x] `starlark`
  - [x] `svelte`
  - [x] `swift`
  - [x] `tact`
  - [x] `tcl`
  - [x] `teal`
  - [x] `templ`
  - [x] `terraform`
  - [x] `toml`
  - [x] `tsx`
  - [x] `typescript`
  - [x] `typoscript`
  - [x] `typst`
  - [x] `usd`
  - [x] `verilog`
  - [x] `vhdl`
  - [x] `vim`
  - [x] `vue`
  - [x] `xml`
  - [x] `yaml`
  - [x] `yang`
  - [x] `zig`

</details>

<details>
<summary>Unsupported (click to expand)</summary

  - [ ] `agda`
  - [ ] `angular`
  - [ ] `arduino`
  - [ ] `asm`
  - [ ] `astro`
  - [ ] `authzed`
  - [ ] `awk`
  - [ ] `bass`
  - [ ] `beancount`
  - [ ] `bibtex`
  - [ ] `bicep`
  - [ ] `bitbake`
  - [ ] `blade`
  - [ ] `blueprint`
  - [ ] `bp`
  - [ ] `brightscript`
  - [ ] `caddy`
  - [ ] `cairo`
  - [ ] `chatito`
  - [ ] `circom`
  - [ ] `comment`
  - [ ] `commonlisp`
  - [ ] `cooklang`
  - [ ] `corn`
  - [ ] `cpon`
  - [ ] `csv`
  - [ ] `cylc`
  - [ ] `desktop`
  - [ ] `dhall`
  - [ ] `disassembly`
  - [ ] `djot`
  - [ ] `dockerfile`
  - [ ] `dot`
  - [ ] `doxygen`
  - [ ] `dtd`
  - [ ] `earthfile`
  - [ ] `ebnf`
  - [ ] `ecma`
  - [ ] `editorconfig`
  - [ ] `eds`
  - [ ] `eex`
  - [ ] `elsa`
  - [ ] `elvish`
  - [ ] `embedded_template`
  - [ ] `erlang`
  - [ ] `facility`
  - [ ] `faust`
  - [ ] `fidl`
  - [ ] `firrtl`
  - [ ] `foam`
  - [ ] `forth`
  - [ ] `fsh`
  - [ ] `fsharp`
  - [ ] `func`
  - [ ] `fusion`
  - [ ] `gap`
  - [ ] `gaptst`
  - [ ] `gdshader`
  - [ ] `git_config`
  - [ ] `git_rebase`
  - [ ] `gitattributes`
  - [ ] `gitcommit`
  - [ ] `gitignore`
  - [ ] `gleam`
  - [ ] `glimmer_javascript`
  - [ ] `glimmer_typescript`
  - [ ] `gn`
  - [ ] `gnuplot`
  - [ ] `goctl`
  - [ ] `godot_resource`
  - [ ] `gomod`
  - [ ] `gosum`
  - [ ] `gotmpl`
  - [ ] `gowork`
  - [ ] `gpg`
  - [ ] `gren`
  - [ ] `gstlaunch`
  - [ ] `hack`
  - [ ] `hare`
  - [ ] `haskell_persistent`
  - [ ] `hcl`
  - [ ] `heex`
  - [ ] `helm`
  - [ ] `hjson`
  - [ ] `hlsl`
  - [ ] `hlsplaylist`
  - [ ] `hocon`
  - [ ] `hoon`
  - [ ] `html_tags`
  - [ ] `htmldjango`
  - [ ] `http`
  - [ ] `hurl`
  - [ ] `hyprlang`
  - [ ] `idl`
  - [ ] `idris`
  - [ ] `inko`
  - [ ] `ipkg`
  - [ ] `ispc`
  - [ ] `javadoc`
  - [ ] `jinja`
  - [ ] `jinja_inline`
  - [ ] `jq`
  - [ ] `jsdoc`
  - [ ] `json5`
  - [ ] `jsonc`
  - [ ] `jsx`
  - [ ] `just`
  - [ ] `kcl`
  - [ ] `kconfig`
  - [ ] `koto`
  - [ ] `kusto`
  - [ ] `lalrpop`
  - [ ] `ledger`
  - [ ] `leo`
  - [ ] `linkerscript`
  - [ ] `liquid`
  - [ ] `llvm`
  - [ ] `luadoc`
  - [ ] `luap`
  - [ ] `luau`
  - [ ] `m68k`
  - [ ] `markdown_inline`
  - [ ] `menhir`
  - [ ] `mermaid`
  - [ ] `meson`
  - [ ] `mlir`
  - [ ] `muttrc`
  - [ ] `nasm`
  - [ ] `nginx`
  - [ ] `nickel`
  - [ ] `nim_format_string`
  - [ ] `ninja`
  - [ ] `nqc`
  - [ ] `objc`
  - [ ] `ocamllex`
  - [ ] `pascal`
  - [ ] `passwd`
  - [ ] `pem`
  - [ ] `perl`
  - [ ] `phpdoc`
  - [ ] `pioasm`
  - [ ] `po`
  - [ ] `pod`
  - [ ] `poe_filter`
  - [ ] `pony`
  - [ ] `powershell`
  - [ ] `printf`
  - [ ] `problog`
  - [ ] `prolog`
  - [ ] `promql`
  - [ ] `properties`
  - [ ] `prql`
  - [ ] `psv`
  - [ ] `pug`
  - [ ] `puppet`
  - [ ] `purescript`
  - [ ] `pymanifest`
  - [ ] `ql`
  - [ ] `qmldir`
  - [ ] `qmljs`
  - [ ] `query`
  - [ ] `racket`
  - [ ] `ralph`
  - [ ] `rasi`
  - [ ] `razor`
  - [ ] `rbs`
  - [ ] `re2c`
  - [ ] `readline`
  - [ ] `regex`
  - [ ] `rego`
  - [ ] `requirements`
  - [ ] `rescript`
  - [ ] `rnoweb`
  - [ ] `robot`
  - [ ] `robots`
  - [ ] `roc`
  - [ ] `ron`
  - [ ] `rst`
  - [ ] `runescript`
  - [ ] `scfg`
  - [ ] `scheme`
  - [ ] `sflog`
  - [ ] `slang`
  - [ ] `slim`
  - [ ] `slint`
  - [ ] `smithy`
  - [ ] `snakemake`
  - [ ] `soql`
  - [ ] `sosl`
  - [ ] `sourcepawn`
  - [ ] `sparql`
  - [ ] `sql`
  - [ ] `squirrel`
  - [ ] `ssh_config`
  - [ ] `strace`
  - [ ] `styled`
  - [ ] `supercollider`
  - [ ] `superhtml`
  - [ ] `surface`
  - [ ] `sway`
  - [ ] `sxhkdrc`
  - [ ] `systemtap`
  - [ ] `t32`
  - [ ] `tablegen`
  - [ ] `tera`
  - [ ] `textproto`
  - [ ] `thrift`
  - [ ] `tiger`
  - [ ] `tlaplus`
  - [ ] `tmux`
  - [ ] `todotxt`
  - [ ] `tsv`
  - [ ] `turtle`
  - [ ] `twig`
  - [ ] `typespec`
  - [ ] `udev`
  - [ ] `ungrammar`
  - [ ] `unison`
  - [ ] `uxntal`
  - [ ] `v`
  - [ ] `vala`
  - [ ] `vento`
  - [ ] `vhs`
  - [ ] `vimdoc`
  - [ ] `vrl`
  - [ ] `wgsl`
  - [ ] `wgsl_bevy`
  - [ ] `wing`
  - [ ] `wit`
  - [ ] `xcompose`
  - [ ] `xresources`
  - [ ] `yuck`
  - [ ] `zathurarc`
  - [ ] `ziggy`
  - [ ] `ziggy_schema`

</details>

## Configuration

(Default values are shown below)

Note: calling `setup()` is optional.

```lua
require'treesitter-context'.setup{
  enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
  multiwindow = false, -- Enable multiwindow support.
  max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
  min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
  line_numbers = true,
  multiline_threshold = 20, -- Maximum number of lines to show for a single context
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

`TSContext` with subcommands `enable`, `disable` and `toggle`.

## Appearance

Use the highlight group `TreesitterContext` to change the colors of the
context. Per default it links to `NormalFloat`.

Use the highlight group `TreesitterContextLineNumber` to change the colors of the
context line numbers if `line_numbers` is set. Per default it links to `LineNr`.

Use the highlight group `TreesitterContextSeparator` to change the colors of the
separator if `separator` is set. By default it links to `FloatBorder`.

Use the highlight groups `TreesitterContextBottom` and/or
`TreesitterContextLineNumberBottom` to change the highlight of the last line of
the context window. By default it links to `NONE`.
However, you can use this to create a border by applying an underline highlight, e.g,
for an underline across the screen:

```vim
hi TreesitterContextBottom gui=underline guisp=Grey
hi TreesitterContextLineNumberBottom gui=underline guisp=Grey
```

Or an underline below the line numbers only:

```vim
hi TreesitterContextLineNumberBottom gui=underline guisp=Grey
```

## Jumping to context (upwards)

```lua
vim.keymap.set("n", "[c", function()
  require("treesitter-context").go_to_context(vim.v.count1)
end, { silent = true })
```

## Adding support for other languages

See [CONTRIBUTING.md](CONTRIBUTING.md)

## Overriding the builtin for a given language

Read [CONTRIBUTING.md](CONTRIBUTING.md) first.

You can provide you own language files by adding them to the
`runtimepath` (`:help runtimepath`).

For example, creating `~/.config/nvim/queries/java/context.scm` will take
precedence over the `queries/java/context.scm` included in `nvim-treesitter-context`
as long as `~/.config/nvim` appears earlier in  `runtimepath`.

You can check the value of `runtimepath` with `:set rtp`.
