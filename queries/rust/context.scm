
(for_expression
  body: (_ (_) @context.end)
) @context

(if_expression
  consequence: (_ (_) @context.end)
) @context

(function_item
  body: (_ (_) @context.end)
) @context

(impl_item
  type: (_) @context.final
) @context

(struct_item
  body: (_ (_) @context.end)
) @context

([
  (mod_item)
  (enum_item)
  (closure_expression)
  (expression_statement)
  (loop_expression)
  (match_expression)
] @context)
