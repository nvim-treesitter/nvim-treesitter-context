(class
  name: (constant)
  (_) @context.end) @context

(singleton_class
  value: (self) @context.end) @context

(module
  name: (constant) @context.end) @context

(method
  name: (identifier)
  parameters: (method_parameters) @context.end) @context

(method
  name: (identifier) @context.end) @context

(singleton_method
  object: (self)
  name: (identifier)
  parameters: (method_parameters) @context.end) @context

(singleton_method
  object: (self)
  name: (identifier) @context.end) @context

(if
  (then) @context.end) @context

(if
  condition: (_) @context.end) @context

(else
  (_) @context.end) @context

(unless
  (then) @context.end) @context

(unless
  condition: (_) @context.end) @context

(do_block
  parameters: (block_parameters) @context.end) @context

(call
  method: (identifier) @_identifier
  block: (do_block
    body: (body_statement) @context.end)
  (#any-of? @_identifier
    "it" "it_behaves_like" "include_examples" "include_context" "context" "describe"
    "shared_context" "shared_examples")) @context

(case
  (when
    (_) @context.end)*
  (else
    (_) @context.end)?) @context

(for
  (_) @context.end) @context

(while
  (_) @context.end) @context

(until
  (_) @context.end) @context

(begin
  (_) @context.end) @context

(rescue
  (_) @context.end) @context

(ensure
  (_) @context.end) @context

(lambda
  (_) @context.end) @context
