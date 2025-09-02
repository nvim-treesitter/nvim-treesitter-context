; standard if
(if_expression
  consequence: (_ (_) @context.end)
) @context

; standard else
(else_clause
  (block (_)) @context.end
) @context

; let if  (its else is caught above)
(let_declaration
   (if_expression
     (block (_))) @context.end
) @context

; let else
(let_declaration
  alternative: (block (_) @context.end)
) @context

; let (tuple) = (values)
(let_declaration
  (tuple_pattern (_))
  (tuple_expression _) @context.end
) @context

; helps with long array definitions
(let_declaration
   (array_expression _) @context.end
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

(struct_expression
  (type_identifier) @context.end
) @context

(union_item
  body: (_ (_) @context.end)
) @context

(enum_item
  body: (_ (_) @context.end)
) @context

(mod_item
  body: (_ (_) @context.end)
) @context

; extern
(foreign_mod_item
  body: (_ (_) @context.end)
) @context

(async_block
  (block (_) @context.end)
) @context

(try_block
  (block (_) @context.end)
) @context

(unsafe_block
  (block (_) @context.end)
) @context

; function call site; helps with long parameter lists
(call_expression
  (arguments (_) @context.end)
) @context

(macro_invocation
  (token_tree (_) @context.end)
) @context

(macro_definition
  name: (_) @context.end
) @context

; let = {}
(let_declaration
  value: (block (_) @context.end)
) @context
