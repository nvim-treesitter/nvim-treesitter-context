
(if_expression
  consequence: (_ (_) @context.end)
) @context.conditional

(else_clause
  (block (_)) @context.end
) @context.conditional

(match_expression
  body: (_ (_) @context.end)
) @context.conditional

(match_arm
  (block (_) @context.end)
) @context.conditional

(for_expression
  body: (_ (_) @context.end)
) @context.loop

(while_expression
  body: (_ (_) @context.end)
) @context.loop

(loop_expression
  body: (_ (_) @context.end)
) @context.loop
  
(closure_expression
  body: (_ (_) @context.end)
) @context.closure

(function_item
  body: (_ (_) @context.end)
) @context.function

(impl_item
  body: (_ (_) @context.end)
) @context.type

(trait_item
  body: (_ (_) @context.end)
) @context.type

(struct_item
  body: (_ (_) @context.end)
) @context.type

(enum_item
  body: (_ (_) @context.end)
) @context.type

(mod_item
  body: (_ (_) @context.end)
) @context.namespace
