(class
  (body_statement) @context.end
) @context

(module
  (body_statement) @context.end
) @context

(method
  (body_statement) @context.end
) @context

(singleton_method
  (body_statement) @context.end
) @context

(if
  (then) @context.end
) @context

(if
  (else (_) @context.end)
) @context

(unless
  (then) @context.end
) @context

(unless
  (else (_) @context.end)
) @context

(_
  (do_block (body_statement) @context.end)
) @context
