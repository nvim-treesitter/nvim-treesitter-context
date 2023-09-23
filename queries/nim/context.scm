
; declarations
(const_section (variable_declaration) @context.end) @context
(var_section (variable_declaration) @context.end) @context
(let_section (variable_declaration) @context.end) @context
(using_section (variable_declaration) @context.end) @context

; types
(type_section (type_declaration) @context.end) @context
(object_declaration (field_declaration_list) @context.end) @context
(tuple_type . (field_declaration) @context.end) @context
(enum_declaration . (enum_field_declaration) @context.end) @context

; routines
(proc_declaration body: (statement_list) @context.end) @context
(func_declaration body: (statement_list) @context.end) @context
(method_declaration body: (statement_list) @context.end) @context
(iterator_declaration body: (statement_list) @context.end) @context
(converter_declaration body: (statement_list) @context.end) @context
(template_declaration body: (statement_list) @context.end) @context
(macro_declaration body: (statement_list) @context.end) @context

; routine expressions
(proc_expression body: (statement_list) @context.end) @context
(func_expression body: (statement_list) @context.end) @context
(iterator_expression body: (statement_list) @context.end) @context

; calls
(do_block body: (statement_list) @context.end) @context
(call (argument_list ":" (statement_list) @context.end)) @context

; single line statements
(for body: (statement_list) @context.end) @context
(while body: (statement_list) @context.end) @context
(block body: (statement_list) @context.end) @context
(static_statement body: (statement_list) @context.end) @context

; multi line statements
(try body: (statement_list) @context.end) @context
(except_branch (statement_list) @context.end) @context
(finally_branch (statement_list) @context.end) @context

(if consequence: (statement_list) @context.end) @context
(when consequence: (statement_list) @context.end) @context
(elif_branch (statement_list) @context.end) @context
(else_branch (statement_list) @context.end) @context
(case value: (_) . (_) @context.end) @context
(of_branch (statement_list) @context.end) @context
