(class_definition
  body: (_) @context.end
) @context

(function_definition
  body: (_) @context.end
) @context

(try_statement
  body: (_) @context.end
) @context

(with_statement
  body: (_) @context.end
) @context

(if_statement
  consequence: (_) @context.end
) @context

(elif_clause
  consequence: (_) @context.end
) @context

(case_clause
  consequence: (_) @context.end
) @context

(while_statement
  body: (_) @context.end
) @context

(except_clause
  (block) @context.end
) @context

(match_statement
  body: (_) @context.end
) @context

([
  (for_statement)
  (finally_clause)
  (else_clause)
  (pair)
] @context)
