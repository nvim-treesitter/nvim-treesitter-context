(if_statement
  consequence: (_) @context.end
) @context.if

(method_declaration
  body: (_) @context.end
) @context.function

(for_statement
  body: (_) @context.end
) @context.loop

(enhanced_for_statement
  body: (_) @context.end
) @context.loop

(class_declaration
  body: (_) @context.end
) @context.class

(expression_statement) @context
