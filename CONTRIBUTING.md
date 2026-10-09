## Adding support for other languages

### Composing `context.scm` queries

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

You can look at a node names of a tree using `:InspectTree`.

Optional captures in the same query pattern as `@context` can change the context
range:

- `@context.start` sets the start of the range to the start of the captured node.
  By default, the range starts at the start of the `@context` node.
- `@context.end` sets the end of the range to the start of the captured node
  (exclusive).
- `@context.final` sets the end of the range to the end of the captured node,
  so the range includes that node.

Use either `@context.end` or `@context.final` to set the end of the range. Without
either capture, the range ends after the first line of the `@context` node. If
`@context.start` moves the start to a later line, also set an end capture.

The context window shows whole lines from this range and preserves line breaks.
Text on the same line before or after a captured node can therefore be shown.
Trailing blank lines are removed, and `multiline_threshold` and `max_lines` limit
the number of lines shown.

Here's what that looks like for C:

```query
(if_statement consequence: (_ (_) @context.end)) @context
```

This query specifies that everything from the `if` keyword up-to the first
statement (exclusive) should be used for the context. This is useful when an
if-statement spans multiple lines.

To start at a C function's declarator and include all its parameter lines:

```query
(function_definition
  declarator: (_) @context.start @context.final) @context
```

This omits the return type when it is on an earlier line.

### Committing your changes

Your commit messages should follow the [Conventional Commits specification](https://conventionalcommits.org).

Good:

```
feat(lua): added lua support
```

Bad:

```
added lua support
```

> You can do `git commit --amend` followed by `git push --force` if you made a mistake.

### Raising a pull request

A pull request for supporting a new language requires:

1. Adding `queries/[LANG]/context.scm` as explained in the previous section.

2. Adding `test/lang/test.[LANG]` or `test/lang/test.[LANG].[EXT]` with code examples the `context.scm` is designed to support.
  - These test files use custom comment directives to annotate what lines should be a context. It has the format.

    ```c
    // {{TEST}} -- mark start of test

    int main() { // {{CONTEXT}} -- mark line as a context


    // {{CURSOR}}  -- where cursor needs to be for contexts to be shown.

    }
    ```

    See `test/lang/test.c` for examples.

3. Run `make test`. This should automatically update README.md to mark `[LANG]` as supported.
