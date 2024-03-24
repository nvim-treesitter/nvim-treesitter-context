
; (package_statement (block)) @fold
;
; [(subroutine_declaration_statement)
;  (conditional_statement)
;  (loop_statement)
;  (for_statement)
;  (cstyle_for_statement)
;  (block_statement)
;  (phaser_statement)] @fold
;
; (anonymous_subroutine_expression) @fold
;
; ; perhaps folks want to fold these too?
; [(anonymous_array_expression)
;  (anonymous_hash_expression)] @fold

(subroutine_declaration_statement
  body: (block (_) @context.end)
) @context
(conditional_statement
  block: (block (_) @context.end)
) @context
(elsif
  block: (block (_) @context.end)
) @context
(else
  block: (block (_) @context.end)
) @context
(loop_statement
  block: (block (_) @context.end)
) @context
(for_statement
  block: (block (_) @context.end)
) @context
(cstyle_for_statement
  (block (_) @context.end)
) @context
(block_statement) @context
(phaser_statement) @context

(assignment_expression
  left: (_)
  right: (list_expression (_)) @context.end
) @context

(anonymous_subroutine_expression
  body: (block (_) @context.end)
) @context

(anonymous_array_expression
  (list_expression (_) @context.end)
) @context
(anonymous_hash_expression
  (list_expression (_) @context.end)
) @context
