(subroutine_declaration_statement
  body: (_) @context.end
) @context

(loop_statement
  block: (_) @context.end
) @context

(for_statement
  block: (_) @context.end
) @context

(conditional_statement
  block: (_) @context.end
) @context

(do_expression) @context

(elsif
  block: (_) @context.end
) @context

(else
  block: (_) @context.end
) @context

(eval_expression
  (block) @context.end
) @context

(try_statement
  try_block: (_) @context.end
) @context

(class_statement
  (block) @context.end
) @context

(method_declaration_statement
  body: (_) @context.end
) @context
