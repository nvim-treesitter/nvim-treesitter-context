{1 "main"
 "main" (^ (V "input") 1)
 "input" (+ (V "gap") (V "form"))
 "gap" (+ (V "ws") (V "comment"))
 "ws" (^ (S " \f\n\r\t,") 1)
 "comment" (* ";"
              (^ (- (P 1) (S "\r\n"))
                 0))
 "form" (+ (V "boolean") (V "nil")
           (V "number") (V "keyword") (V "symbol") (V "string")
           (V "list") (V "vector") (V "hash-map")
           (V "deref") (V "quasiquote") (V "quote")
           (V "splice-unquote")
           (V "unquote")
           (V "with-meta"))
 "name-char" (- (P 1)
                (S " \f\n\r\t,[]{}()'`~^@\";"))
 "nil" (Cmt (C (* (P "nil")
                  (- (V "name-char"))))
            (fn [s i a]
              (values i t.mal-nil)))
 "boolean" (Cmt (C (* (+ (P "false") (P "true"))
                      (- (V "name-char"))))
                (fn [s i a]
                  (values i (if (= a "true")
                              t.mal-true
                              t.mal-false))))
 "number" (Cmt (C (^ (- (P 1)
                        (S " \f\n\r\t,[]{}()'`~^@\";"))
                     1))
               (fn [s i a]
                 (let [result (tonumber a)]
                   (if result
                     (values i (t.make-number result))
                     nil))))
 "keyword" (Cmt (C (* ":"
                      (^ (V "name-char") 0)))
                (fn [s i a]
                  (values i (t.make-keyword a))))
 "symbol" (Cmt (^ (V "name-char") 1)
               (fn [s i a]
                 (values i (t.make-symbol a))))
 "string" (* (P "\"")
             (Cmt (C (* (^ (- (P 1)
                              (S "\"\\"))
                           0)
                        (^ (* (P "\\")
                              (P 1)
                              (^ (- (P 1)
                                    (S "\"\\"))
                                 0))
                           0)))
                  (fn [s i a]
                    (values i (t.make-string (unescape a)))))
             (+ (P "\"")
                (P (fn [s i]
                     (error "unbalanced \"")))))
 "list" (* (P "(")
           (Cmt (C (^ (V "input") 0))
                (fn [s i a ...]
                  (values i (t.make-list [...]))))
           (+ (P ")")
              (P (fn [s i]
                   (error "unbalanced )")))))
 "vector" (* (P "[")
             (Cmt (C (^ (V "input") 0))
                  (fn [s i a ...]
                    (values i (t.make-vector [...]))))
             (+ (P "]")
                (P (fn [s i]
                     (error "unbalanced ]")))))
 "hash-map" (* (P "{")
               (Cmt (C (^ (V "input") 0))
                    (fn [s i a ...]
                      (values i (t.make-hash-map [...]))))
               (+ (P "}")
                  (P (fn [s i]
                       (error "unbalanced }")))))
 "deref" (Cmt (C (* (P "@")
                    (V "form")))
              (fn [s i ...]
                (let [content [(t.make-symbol "deref")]]
                  (table.insert content (. [...] 2))
                  (values i (t.make-list content)))))
 "quasiquote" (Cmt (C (* (P "`")
                         (V "form")))
                   (fn [s i ...]
                     (let [content [(t.make-symbol "quasiquote")]]
                       (table.insert content (. [...] 2))
                       (values i (t.make-list content)))))
 "quote" (Cmt (C (* (P "'")
                    (V "form")))
              (fn [s i ...]
                (let [content [(t.make-symbol "quote")]]
                  (table.insert content (. [...] 2))
                  (values i (t.make-list content)))))
 "splice-unquote" (Cmt (C (* (P "~@")
                             (V "form")))
                       (fn [s i ...]
                         (let [content [(t.make-symbol "splice-unquote")]]
                           (table.insert content (. [...] 2))
                           (values i (t.make-list content)))))
 "unquote" (Cmt (C (* (P "~")
                      (V "form")))
                (fn [s i ...]
                  (let [content [(t.make-symbol "unquote")]]
                    (table.insert content (. [...] 2))
                    (values i (t.make-list content)))))
 "with-meta" (Cmt (C (* (P "^")
                        (V "form")
                        (^ (V "gap") 1)
                        (V "form")))
                  (fn [s i ...]
                    (let [content [(t.make-symbol "with-meta")]]
                      (table.insert content (. [...] 3))
                      (table.insert content (. [...] 2))
                      (values i (t.make-list content)))))
 }

(set EVAL
  (fn [ast-param env-param]
    (var ast ast-param)
    (var env env-param)
    (var result nil)
    (while (not result)
      (if (not (t.list?* ast))
          (set result (eval_ast ast env))
          (do
           (set ast (macroexpand ast env))
           (if (not (t.list?* ast))
               (set result (eval_ast ast env))
               (if (t.empty?* ast)
                   (set result ast)
                   (let [ast-elts (t.get-value ast)
                         head-name (t.get-value (. ast-elts 1))]
                     ;; XXX: want to check for symbol, but...
                     (if (= "def!" head-name)
                         (let [def-name (. ast-elts 2)
                               def-val (EVAL (. ast-elts 3) env)]
                           (e.env-set env
                                      def-name def-val)
                           (set result def-val))
                         ;;
                         (= "defmacro!" head-name)
                         (let [def-name (. ast-elts 2)
                               def-val (EVAL (. ast-elts 3) env)
                               macro-ast (t.macrofy def-val)]
                           (e.env-set env
                                      def-name macro-ast)
                           (set result macro-ast))
                         ;;
                         (= "macroexpand" head-name)
                         (set result (macroexpand (. ast-elts 2) env))
                         ;;
                         (= "let*" head-name)
                         (let [new-env (e.make-env env)
                               bindings (t.get-value (. ast-elts 2))
                               stop (/ (length bindings) 2)]
                           (for [idx 1 stop]
                                (let [b-name
                                      (. bindings (- (* 2 idx) 1))
                                      b-val
                                      (EVAL (. bindings (* 2 idx)) new-env)]
                                  (e.env-set new-env
                                             b-name b-val)))
                           ;; tco
                           (set ast (. ast-elts 3))
                           (set env new-env))
                         ;;
                         (= "quote" head-name)
                         ;; tco
                         (set result (. ast-elts 2))
                         ;;
                         (= "quasiquoteexpand" head-name)
                         ;; tco
                         (set result (quasiquote* (. ast-elts 2)))
                         ;;
                         (= "quasiquote" head-name)
                         ;; tco
                         (set ast (quasiquote* (. ast-elts 2)))
                         ;;
                         (= "try*" head-name)
                         (set result
                              (let [(ok? res)
                                    (pcall EVAL (. ast-elts 2) env)]
                                (if (not ok?)
                                    (let [maybe-catch-ast (. ast-elts 3)]
                                      (if (not maybe-catch-ast)
                                          (u.throw* res)
                                          (if (not (starts-with maybe-catch-ast
                                                                "catch*"))
                                              (u.throw*
                                               (t.make-string
                                                "Expected catch* form"))
                                              (let [catch-asts
                                                    (t.get-value
                                                     maybe-catch-ast)]
                                                (if (< (length catch-asts) 2)
                                                    (u.throw*
                                                     (t.make-string
                                                      (.. "catch* requires at "
                                                          "least 2 "
                                                          "arguments")))
                                                    (let [catch-sym-ast
                                                          (. catch-asts 2)
                                                          catch-body-ast
                                                          (. catch-asts 3)]
                                                      (EVAL catch-body-ast
                                                            (e.make-env
                                                             env
                                                             [catch-sym-ast]
                                                             [res]))))))))
                                    res)))
                         ;;
                         (= "do" head-name)
                         (let [most-forms (u.slice ast-elts 2 -2) ;; XXX
                               last-body-form (u.last ast-elts)
                               res-ast (eval_ast
                                        (t.make-list most-forms) env)]
                           ;; tco
                           (set ast last-body-form))
                         ;;
                         (= "if" head-name)
                         (let [cond-res (EVAL (. ast-elts 2) env)]
                           (if (or (t.nil?* cond-res)
                                   (t.false?* cond-res))
                               (let [else-ast (. ast-elts 4)]
                                 (if (not else-ast)
                                     ;; tco
                                     (set result t.mal-nil)
                                     (set ast else-ast)))
                               ;; tco
                               (set ast (. ast-elts 3))))
                         ;;
                         (= "fn*" head-name)
                         (let [params (t.get-value (. ast-elts 2))
                               body (. ast-elts 3)]
                           ;; tco
                           (set result
                                (t.make-fn
                                 (fn [args]
                                   (EVAL body
                                         (e.make-env env params args)))
                                 body params env false nil)))
                         ;;
                         (let [eval-list (t.get-value (eval_ast ast env))
                               f (. eval-list 1)
                               args (u.slice eval-list 2 -1)]
                           (let [body (t.get-ast f)] ;; tco
                             (if body
                                 (do
                                  (set ast body)
                                  (set env
                                       (e.make-env (t.get-env f)
                                                   (t.get-params f)
                                                   args)))
                                 (set result
                                      ((t.get-value f) args))))))))))))
    result))

["Archimedes" "Bohm"








 "Cantor" "Deming"










 "Erdos" "Fennel"









 "Gauss" "Houdini"





 "Ishikawa" "Johnson"]
