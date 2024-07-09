[
  (quote_reader_macro)
  (quasi_quote_reader_macro)
  (quote_form)
  (fn_form)
  (lambda_form)
  (macro_form)
  (case_form)
  (match_form)
  (case_try_form)
  (match_try_form)
] @context

(list
  call: (symbol) @_sym
  (#eq? @_sym "when")) @context

(hashfn_reader_macro
  expression: (list
    call: (symbol) @_sym
    (#eq? @_sym "do"))) @context
