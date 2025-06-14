(class_declaration
  (class_body (_)) @context.end
) @context

(function_declaration
  (function_body (_) @context.end )
) @context

(if_expression
  condition: (_)
  consequence: (_) @context.end
) @context

(if_expression
  alternative: (_) @context.end
) @context

(when_expression) @context

(when_entry) @context

(while_statement
  (control_structure_body (_)) @context.end
) @context

(for_statement
 (control_structure_body (_)) @context.end
  ) @context

(try_expression
  (statements (_))
) @context
