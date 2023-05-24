(class_declaration
  (aggregate_body (_) @context.end)
) @context

(interface_declaration
  (aggregate_body (_) @context.end)
) @context

(func_declaration
  (specified_function_body (block_statement (_) @context.end))
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
  (enum_body (_) @context.end)
) @context

(struct_declaration
  (aggregate_body (_) @context.end)
) @context

(unit_test
  (block_statement (_) @context.end)
) @context

(try_statement
  (block_statement (_) @context.end)
) @context

(catch
  (block_statement (_) @context.end)
) @context

(asm_statement
  (asm_instruction_list (_) @context.end)
) @context

(with_statement
  (block_statement (_) @context.end)
) @context

(while_statement
  (block_statement (_) @context.end)
) @context

(for_statement
  (block_statement (_) @context.end)
) @context

(foreach_statement
  (block_statement (_) @context.end)
) @context

(if_statement
  (then_statement (
    (block_statement (_) @context.end)
  ))
) @context

(else_statement
  (block_statement (_) @context.end)
) @context

(switch_statement
  (block_statement (_) @context.end)
) @context

