([
  (for_statement)
  (while_statement)
  (if_expression)
  (if_type_expression)
  (test_declaration)
  (comptime_declaration)
  (using_namespace_declaration)
] @context)

(function_declaration
  (block (_) @context.end)
) @context

(variable_declaration
  type: (_)? @context.end
) @context

(if_statement
  (block (_) @context.end)
) @context

(switch_expression
  "{" @context.end
) @context
