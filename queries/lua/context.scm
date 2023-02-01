([
  (function_definition)
  (while_statement)
  (table_constructor)
  (for_statement)
] @context)

(function_declaration
  parameters: (_) @context.final
) @context

(if_statement
  consequence: (_) @context.end
) @context
