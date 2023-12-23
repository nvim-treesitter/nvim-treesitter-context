([
  (import_declaration)
  (let_clause)
] @context)

(field
  (value (_) @context.end)
) @context

(call_expression
  (arguments (_) @context.end)
) @context

(_
  ([
    (for_clause)
    (guard_clause)
  ] (_)+ @context.end)
) @context
