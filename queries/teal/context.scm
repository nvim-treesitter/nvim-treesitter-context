
(while_statement) @context

(generic_for_statement
  body: (_ (_) @context.end)
) @context

(function_statement
  body: (_) @context.end
) @context

(anon_function
  body: (_) @context.end
) @context

(if_statement
  condition: (_)
  (_) @context.end
) @context

(elseif_block
  condition: (_)
  (_) @context.end
) @context

(record_declaration
  record_body: (_) @context.end
) @context
