
(function_definition
  name: (_) @context.start
  body: (_ (_) @context.end)
) @context

(method_declaration
  name: (_) @context.start
  body: (_ (_) @context.end)
) @context

(while_statement
  body: (_ (_) @context.end)
) @context

(if_statement
  body: (_ (_) @context.end)
) @context

(else_clause
  body: (_ (_) @context.end)
) @context

(else_if_clause
  body: (_ (_) @context.end)
) @context

(do_statement
  body: (_ (_) @context.end)
) @context

(foreach_statement
  body: (_ (_) @context.end)
) @context

(class_declaration
  name: (_) @context.start
  body: (_ (_) @context.end)
) @context

(for_statement
  (compound_statement (_) @context.end)
) @context

(switch_statement) @context

(case_statement) @context
