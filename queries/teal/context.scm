(while_statement
  (while_body (_) @context.end)
) @context.loop

(generic_for_statement
  body: (_ (_) @context.end)
) @context.loop

(repeat_statement) @context.loop

(function_statement
  body: (_) @context.end
) @context.function

(anon_function
  body: (_) @context.end
) @context.function

(if_statement
  condition: (_)
  (_) @context.end
) @context.conditional

(elseif_block
  condition: (_)
  (_) @context.end
) @context.conditional

(record_declaration
  record_body: (_) @context.end
) @context.type
