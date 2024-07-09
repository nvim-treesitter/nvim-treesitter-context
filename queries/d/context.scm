(class_declaration
  (aggregate_body (_) @context.end)
) @context

(interface_declaration
  (aggregate_body (_) @context.end)
) @context

(function_declaration
  (function_body (block_statement (_) @context.end))
) @context

(template_declaration
  (identifier)
  (template_parameters)
  (_) @context.end
) @context

(union_declaration
  (aggregate_body (_) @context.end)
) @context

(enum_declaration
  (enum_member) @context.end
) @context

(struct_declaration
  (aggregate_body (_) @context.end)
) @context

(unittest_declaration
  (block_statement (_) @context.end)
) @context

(try_statement
  body: (scope_statement (_) @context.end)
) @context

(catch_statement
  body: (scope_statement (_) @context.end)
) @context

(asm_statement
  (asm_inline (_) @context.end)
) @context

(with_statement
  (scope_statement (_) @context.end)
) @context

(while_statement
  (scope_statement (_) @context.end)
) @context

(for_statement
  (block_statement (_) @context.end)
) @context

(foreach_statement
  (scope_statement (_) @context.end)
) @context

(if_statement
  consequence: (scope_statement
    (block_statement (_) @context.end)
  )
) @context

(if_statement
  (else) @context
  .
  (_) @context.end
  ; (scope_statement
  ;   (block_statement (_) @context.end)
  ; )
)

(switch_statement
  (scope_statement (_) @context.end)
) @context

(case_statement
  (case)
  .
  (expression_list) @context.end
) @context

