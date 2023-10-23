(class_definition
  body: (_) @context.end
) @context.type

(function_definition
  body: (_) @context.end
) @context.function

(try_statement
  body: (_) @context.end
) @context.block

(except_clause
  (block) @context.end
) @context.block

(with_statement
  body: (_) @context.end
) @context.block

(if_statement
  consequence: (_) @context.end
) @context.conditional

(elif_clause
  consequence: (_) @context.end
) @context.conditional

(match_statement
  body: (_) @context.end
) @context.conditional

(case_clause
  consequence: (_) @context.end
) @context.conditional

(while_statement
  body: (_) @context.end
) @context.loop

([
  (for_statement)
  (finally_clause)
  (else_clause)
  (pair)
] @context)
