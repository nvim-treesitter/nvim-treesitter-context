
(if_expression
  consequence: (_ (_) @context.end)
) @context

(else_clause
  (block (_)) @context.end
) @context

(match_expression
  body: (_ (_) @context.end)
) @context

(match_arm
  (block (_) @context.end)
) @context

(for_expression
  body: (_ (_) @context.end)
) @context

(while_expression
  body: (_ (_) @context.end)
) @context

(loop_expression
  body: (_ (_) @context.end)
) @context
  
(closure_expression
  body: (_ (_) @context.end)
) @context

(function_item
  body: (_ (_) @context.end)
) @context

(impl_item
  body: (_ (_) @context.end)
) @context

(trait_item
  body: (_ (_) @context.end)
) @context

(struct_item
  body: (_ (_) @context.end)
) @context

(enum_item
  body: (_ (_) @context.end)
) @context

(mod_item
  body: (_ (_) @context.end)
) @context
