
(if_expression
  consequence: (_ (_) @context.end)
) @context.if

(else_clause
  (block (_)) @context.end
) @context.if

(match_expression
  body: (_ (_) @context.end)
) @context.switch

(match_arm
  (block (_) @context.end)
) @context.switch

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
) @context.lambda

(function_item
  body: (_ (_) @context.end)
) @context.function

(impl_item
  body: (_ (_) @context.end)
) @context.class

(trait_item
  body: (_ (_) @context.end)
) @context.interface

(struct_item
  body: (_ (_) @context.end)
) @context.struct

(enum_item
  body: (_ (_) @context.end)
) @context.enum

(mod_item
  body: (_ (_) @context.end)
) @context.module
