([
  (var_declaration)
  (type_declaration)
  (import_declaration)
  (const_declaration)
  (select_statement)
] @context)

(function_declaration
  body: (block (_) @context.end)
) @context

(method_declaration
  body: (block (_) @context.end)
) @context

(if_statement
  consequence: (block (_) @context.end)
) @context

(for_statement
  body: (block (_) @context.end)
) @context

(communication_case
  communication: (_)
  (_) @context.end
) @context
