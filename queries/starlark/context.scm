; comment captures are not inside the body block
(function_definition
  (comment) @context.end
) @context

(function_definition
  body: (_) @context.end
) @context

; comment captures are not inside the consequence block
(if_statement
  (comment) @context.end
) @context

(if_statement
  consequence: (_) @context.end
) @context

(call
  (argument_list) @context.end
) @context

([
  (dictionary)
  (list)
] @context)
