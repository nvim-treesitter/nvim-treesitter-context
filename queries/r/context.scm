([
(call)
(binary_operator)
]) @context

(for_statement
  body: (_) @context.end
) @context

(while_statement
  body: (_) @context.end
) @context

(if_statement
  consequence: (_) @context.end
) @context

(if_statement
  consequence: (_) @context.end
) @context

(function_definition
  (braced_expression) @context.end) @context
