(for_statement
  body: (_) @context.end
) @context

(while_statement
  body: (_) @context.end
) @context

(do_statement
  body: (_) @context.end
) @context

(function_definition
  body: (_) @context.end
) @context

(table_constructor
  (_) @context.end
) @context

(function_declaration
  parameters: (_) @context.final
) @context

(if_statement
  consequence: (_) @context.end
) @context

(repeat_statement
  body: (_) @context.end
) @context
