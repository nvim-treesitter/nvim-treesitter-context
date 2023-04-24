; inherits: css

(if_statement) @context

(else_if_clause
  (block (_) @context.end)
) @context

(else_clause
  (block (_) @context.end)
) @context

(while_statement
  (block (_) @context.end)
) @context

(for_statement
  (block (_) @context.end)
) @context

(each_statement
  (block (_) @context.end)
) @context

(mixin_statement
  (block (_) @context.end)
) @context

(function_statement
  (block (_) @context.end)
) @context
