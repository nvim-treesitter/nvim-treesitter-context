(for_statement
  body: (_) @context.end
) @context.loop

(while_statement
  body: (_) @context.end
) @context.loop

(repeat_statement
  body: (_) @context.end
) @context.loop

(do_statement
  body: (_) @context.end
) @context.block

(function_definition
  body: (_) @context.end
) @context.function

(table_constructor
  (_) @context.end
) @context

(function_declaration
  parameters: (_) @context.final
) @context.function

(if_statement
  consequence: (_) @context.end
) @context.conditional

(elseif_statement
  consequence: (_) @context.end
) @context.conditional
