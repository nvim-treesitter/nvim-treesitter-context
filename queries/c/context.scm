
(preproc_if
  (_) (_) @context.end
) @context

(preproc_ifdef
  name: (identifier) (_) @context.end
) @context

(function_definition
  body: (_ (_) @context.end)
) @context

(for_statement
  (compound_statement) @context.end
) @context

(if_statement
  consequence: (_ (_) @context.end)
) @context

(else_clause
  (_ (_) @context.end)
) @context

(while_statement
  body: (_ (_) @context.end)
) @context

(do_statement
  body: (_ (_) @context.end)
) @context

(struct_specifier
  body: (_ (_) @context.end)
) @context

(enum_specifier
  body: (_ (_) @context.end)
) @context

(switch_statement
  body: (_) @context.end
) @context

(case_statement
  value: (_) (_) @context.end
) @context

(declaration
  declarator: (_ (_) @content.end)
) @context
