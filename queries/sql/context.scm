[
  (case)
  (create_materialized_view)
  (create_table)
  (create_view)
  (cte)
  (insert)
  (subquery)
  (update)
] @context

(create_function
  (function_arguments) @context.final) @context

(create_procedure
  (function_arguments)? @context.final) @context
