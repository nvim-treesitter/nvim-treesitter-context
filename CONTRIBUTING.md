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


### Raising a pull request

A pull request for supporting a new language requires:

1. Adding `queries/[LANG]/context.scm` as explained in the previous section.
2. Adding `test/test.[LANG EXT]` with code examples the `context.scm` is designed to support.
3. Updating `README.md` to mark `[LANG]` as supported.
