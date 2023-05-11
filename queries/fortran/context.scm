(program
  (program_statement (_))
  (_) @context.end
) @context

(derived_type_definition
  (derived_type_statement (_))
  (_) @context.end
) @context

(do_loop_statement
  (loop_control_expression (_))
  (_) @context.end
) @context

(subroutine
  (subroutine_statement (_))
  (_) @context.end
) @context

(if_statement
  (parenthesized_expression (_))
  (_) @context.end
) @context

(elseif_clause
  (parenthesized_expression (_))
  (_) @context.end
) @context

(else_clause
  (_) @context.end
) @context
