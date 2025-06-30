(if_statement
  consequence: (_) @context.end
) @context

(method_declaration
  type: (_) @context.start
  body: (_) @context.end
) @context

(constructor_declaration
  name: (_) @context.start
  body: (_) @context.end
) @context

(for_statement
  body: (_) @context.end
) @context

(enhanced_for_statement
  body: (_) @context.end
) @context

(class_declaration
  name: (_) @context.start
  body: (_) @context.end
) @context

(switch_expression) @context

(switch_block_statement_group) @context

(expression_statement) @context
