([
  (switch_statement)
  (protocol_declaration)
  (repeat_while_statement)
  (do_statement)
] @context)

(switch_entry
  (statements) @context.end
) @context

(catch_block
  (statements) @context.end
) @context

(class_declaration
  body: (_ (_) @context.end)
) @context

(if_statement
  (statements) @context.end
) @context

(function_declaration
  body: (_ (_) @context.end)
) @context

(property_declaration
  computed_value: (_ (_) @context.end)
) @context

(for_statement
  (statements) @context.end
) @context

(while_statement
  (statements) @context.end
) @context

(guard_statement
  (statements) @context.end
) @context
