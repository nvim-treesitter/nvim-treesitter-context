; inherits: go,html

([
  (component_declaration)
  (script_declaration)
  (css_declaration)
  (component_switch_statement)
  (component_switch_expression_case)
  (component_switch_default_case)
] @context)

(component_if_statement
  consequence: (component_block (_) @context.end)
) @context

(component_for_statement
  body: (component_block (_) @context.end)
) @context

(component_import
  body: (component_block (_) @context.end)
) @context
