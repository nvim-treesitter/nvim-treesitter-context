[:name "clojure"

 ;; a comment
 :extras []

 :conflicts []

 :inline [:_kwd_leading_slash
          :_kwd_just_slash
          :_kwd_qualified
          :_kwd_unqualified
          :_kwd_marker
          :_sym_qualified
          :_sym_unqualified]

 :_tokens
 {:WHITESPACE_CHAR
  [:regex "["
          "\\f\\n\\r\\t, "
          "\\u000B\\u001C\\u001D\\u001E\\u001F"
          "\\u2028\\u2029\\u1680"
          "\\u2000\\u2001\\u2002\\u2003\\u2004\\u2005\\u2006\\u2008\\u2009"
          "\\u200a\\u205f\\u3000"
          "]"]

  :WHITESPACE [:token [:repeat1 :WHITESPACE_CHAR]]

  :COMMENT [:token [:regex "(;|#!)"
                           ".*"
                           "\\n?"]]

  :DIGIT [:regex "[0-9]"]

  :ALPHANUMERIC [:regex "[0-9a-zA-Z]"]

  :HEX_DIGIT [:regex "[0-9a-fA-F]"]

  :OCTAL_DIGIT [:regex "[0-7]"]

  :HEX_NUMBER [:seq "0"
                    [:regex "[xX]"]
                    [:repeat1 :HEX_DIGIT]
                    [:optional "N"]]

  :OCTAL_NUMBER [:seq "0"
                      [:repeat1 :OCTAL_DIGIT]
                      [:optional "N"]]

  :RADIX_NUMBER [:seq [:repeat1 :DIGIT]
                      [:regex "[rR]"]
                      [:repeat1 :ALPHANUMERIC]]

  :RATIO [:seq [:repeat1 :DIGIT]
               "/"
               [:repeat1 :DIGIT]]

  :DOUBLE [:seq [:repeat1 :DIGIT]
                [:optional [:seq "."
                                 [:repeat :DIGIT]]]
                [:optional [:seq [:regex "[eE]"]
                                 [:optional [:regex "[+-]"]]
                                 [:repeat1 :DIGIT]]]
                [:optional "M"]]

  :INTEGER [:seq [:repeat1 :DIGIT]
                 [:optional [:regex "[MN]"]]]

  :NUMBER [:token [:prec 10
                         [:seq [:optional [:regex "[+-]"]]
                               [:choice :HEX_NUMBER
                                        :OCTAL_NUMBER
                                        :RADIX_NUMBER
                                        :RATIO
                                        :DOUBLE
                                        :INTEGER]]]]

  :NIL [:token "nil"]

  :BOOLEAN [:token [:choice "false"
                            "true"]]

  :KEYWORD_HEAD
  [:regex "[^"
          "\\f\\n\\r\\t "
          "/"
          "()"
          "\\[\\]"
          "{}"
          "\""
          "@~^;`"
          "\\\\"
          ",:"
          "\\u000B\\u001C\\u001D\\u001E\\u001F"
          "\\u2028\\u2029\\u1680"
          "\\u2000\\u2001\\u2002\\u2003\\u2004\\u2005\\u2006\\u2008\\u2009"
          "\\u200a\\u205f\\u3000"
          "]"]

  :KEYWORD_BODY [:choice [:regex "[:']"]
                         :KEYWORD_HEAD]

  :KEYWORD_NAMESPACED_BODY
  [:token [:repeat1 [:choice [:regex "[:'/]"]
                             :KEYWORD_HEAD]]]

  :KEYWORD_NO_SIGIL
  [:token [:seq :KEYWORD_HEAD
                [:repeat :KEYWORD_BODY]]]

  :KEYWORD_MARK [:token ":"]

  :AUTO_RESOLVE_MARK [:token "::"]

  :STRING
  [:token [:seq "\""
                [:repeat [:regex "[^"
                                 "\""
                                 "\\\\"
                                 "]"]]
                [:repeat [:seq "\\"
                               [:regex "."]
                               [:repeat [:regex "[^"
                                                "\""
                                                "\\\\"
                                                "]"]]]]
                "\""]]

  :OCTAL_CHAR [:seq "o"
                    [:choice [:seq :DIGIT :DIGIT :DIGIT]
                             [:seq :DIGIT :DIGIT]
                             [:seq :DIGIT]]]

  :NAMED_CHAR [:choice "backspace"
                       "formfeed"
                       "newline"
                       "return"
                       "space"
                       "tab"]

  :UNICODE [:seq "u"
                 :HEX_DIGIT
                 :HEX_DIGIT
                 :HEX_DIGIT
                 :HEX_DIGIT]

  :ANY_CHAR [:regex ".|\\n"]

  :CHARACTER [:token [:seq "\\"
                           [:choice :OCTAL_CHAR
                                    :NAMED_CHAR
                                    :UNICODE
                                    :ANY_CHAR]]]

  :SYMBOL_HEAD [:regex "[^"
                       "\\f\\n\\r\\t "
                       "/"
                       "()"
                       "\\[\\]"
                       "{}"
                       "\""
                       "@~^;`"
                       "\\\\"
                       ",:"
                       "#'"
                       "0-9"
                       "\\u000B\\u001C\\u001D\\u001E\\u001F"
                       "\\u2028\\u2029\\u1680"
                       "\\u2000\\u2001\\u2002\\u2003\\u2004\\u2005\\u2006\\u2008"
                       "\\u2009\\u200a\\u205f\\u3000"
                       "]"]

  :NS_DELIMITER [:token "/"]

  :SYMBOL_BODY [:choice :SYMBOL_HEAD
                        [:regex "[:#'0-9]"]]

  :SYMBOL_NAMESPACED_NAME
  [:token [:repeat1 [:choice :SYMBOL_HEAD
                             [:regex "[/:#'0-9]"]]]]

  :SYMBOL
  [:token [:seq :SYMBOL_HEAD
                [:repeat :SYMBOL_BODY]]]
  }

 :rules
 {:source [:repeat [:choice :_form
                            :_gap]]

  :_gap [:choice :_ws
                 :comment
                 :dis_expr]

  :_ws :WHITESPACE

  :comment :COMMENT

  :dis_expr [:seq [:field "marker" "#_"]
                  [:repeat :_gap]
                  [:field "value" :_form]]

  :_form [:choice :num_lit ;; atom-ish
                  :kwd_lit
                  :str_lit
                  :char_lit
                  :nil_lit
                  :bool_lit
                  :sym_lit
                  ;; basic collection-ish
                  :list_lit
                  :map_lit
                  :vec_lit
                  ;; dispatch reader macros
                  :set_lit
                  :anon_fn_lit
                  :regex_lit
                  :read_cond_lit
                  :splicing_read_cond_lit
                  :ns_map_lit
                  :var_quoting_lit
                  :sym_val_lit
                  :evaling_lit
                  :tagged_or_ctor_lit
                  ;; some other reader macros
                  :derefing_lit
                  :quoting_lit
                  :syn_quoting_lit
                  :unquote_splicing_lit
                  :unquoting_lit]

  :num_lit :NUMBER

  :kwd_lit [:choice :_kwd_leading_slash
                    :_kwd_just_slash
                    :_kwd_qualified
                    :_kwd_unqualified]

  :_kwd_leading_slash [:seq [:field "marker" :_kwd_marker]
                            [:field "delimiter" :NS_DELIMITER]
                            [:field "name"
                                    [:alias :KEYWORD_NAMESPACED_BODY
                                            :kwd_name]]]

  :_kwd_just_slash [:seq [:field "marker" :_kwd_marker]
                         [:field "name" [:alias :NS_DELIMITER :kwd_name]]]

  :_kwd_qualified
  [:prec 2
         [:seq [:field "marker" :_kwd_marker]
               [:field "namespace"
                       [:alias :KEYWORD_NO_SIGIL :kwd_ns]]
               [:field "delimiter" :NS_DELIMITER]
               [:field "name"
                       [:alias :KEYWORD_NAMESPACED_BODY :kwd_name]]]]

  :_kwd_unqualified
  [:prec 1
         [:seq [:field "marker" :_kwd_marker]
               [:field "name" [:alias :KEYWORD_NO_SIGIL :kwd_name]]]]

  :_kwd_marker [:choice :KEYWORD_MARK
                        :AUTO_RESOLVE_MARK]

  :str_lit :STRING

  :char_lit :CHARACTER

  :nil_lit :NIL

  :bool_lit :BOOLEAN

  :sym_lit [:seq [:repeat :_metadata_lit]
                 [:choice :_sym_qualified :_sym_unqualified]]

  :_sym_qualified
  [:prec 1 [:seq [:field "namespace" [:alias :SYMBOL :sym_ns]]
                 [:field "delimiter" :NS_DELIMITER]
                 [:field "name" [:alias :SYMBOL_NAMESPACED_NAME :sym_name]]]]

  :_sym_unqualified
  [:field "name"
          [:alias [:choice :NS_DELIMITER
                           :SYMBOL]
                  :sym_name]]

  :_metadata_lit
  [:seq [:choice [:field "meta" :meta_lit]
                 [:field "old_meta" :old_meta_lit]]
        [:optional [:repeat :_gap]]]

  :meta_lit
  [:seq [:field "marker" "^"]
        [:repeat :_gap]
        [:field "value" [:choice :read_cond_lit
                                 :map_lit
                                 :str_lit
                                 :kwd_lit
                                 :sym_lit]]]

  :old_meta_lit
  [:seq [:field "marker" "#^"]
        [:repeat :_gap]
        [:field "value" [:choice :read_cond_lit
                                 :map_lit
                                 :str_lit
                                 :kwd_lit
                                 :sym_lit]]]

  :list_lit [:seq [:repeat :_metadata_lit]
                  :_bare_list_lit]

  :_bare_list_lit [:seq [:field "open" "("]
                        [:repeat [:choice [:field "value" :_form]
                                          :_gap]]
                        [:field "close" ")"]]

  :map_lit [:seq [:repeat :_metadata_lit]
                 :_bare_map_lit]

  :_bare_map_lit [:seq [:field "open" "{"]
                       [:repeat [:choice
                                 [:field "value" :_form]
                                 :_gap]]
                       [:field "close" "}"]]

  :vec_lit [:seq [:repeat :_metadata_lit]
                 :_bare_vec_lit]

  :_bare_vec_lit [:seq [:field "open" "["]
                       [:repeat [:choice [:field "value" :_form]
                                         :_gap]]
                       [:field "close" "]"]]

  :set_lit [:seq [:repeat :_metadata_lit]
                 :_bare_set_lit]

  :_bare_set_lit [:seq [:field "marker" "#"]
                       [:field "open" "{"]
                       [:repeat [:choice [:field "value" :_form]
                                         :_gap]]
                       [:field "close" "}"]]

  :anon_fn_lit [:seq [:repeat :_metadata_lit]
                     [:field "marker" "#"]
                     :_bare_list_lit]

  :regex_lit [:seq [:field "marker" "#"]
                   :STRING]

  :read_cond_lit [:seq [:repeat :_metadata_lit]
                       [:field "marker" "#?"]
                       [:repeat :_ws]
                       :_bare_list_lit]

  :splicing_read_cond_lit [:seq [:repeat :_metadata_lit]
                                [:field "marker" "#?@"]
                                [:repeat :_ws]
                                :_bare_list_lit]

  :auto_res_mark :AUTO_RESOLVE_MARK

  :ns_map_lit [:seq [:repeat :_metadata_lit]
                    [:field "marker" "#"]
                    [:field "prefix" [:choice :auto_res_mark
                                              :kwd_lit]]
                    [:repeat :_gap]
                    :_bare_map_lit]

  :var_quoting_lit [:seq [:repeat :_metadata_lit]
                         [:field "marker" "#'"]
                         [:repeat :_gap]
                         [:field "value" :_form]]

  :sym_val_lit [:seq [:field "marker" "##"]
                     [:repeat :_gap]
                     [:field "value" :sym_lit]]

  :evaling_lit [:seq [:repeat :_metadata_lit]
                     [:field "marker" "#="]
                     [:repeat :_gap]
                     [:field "value" [:choice :list_lit
                                              :read_cond_lit
                                              :sym_lit]]]

  :tagged_or_ctor_lit [:seq [:repeat :_metadata_lit]
                            [:field "marker" "#"]
                            [:repeat :_gap]
                            [:field "tag" :sym_lit]
                            [:repeat :_gap]
                            [:field "value" :_form]]

  :derefing_lit [:seq [:repeat :_metadata_lit]
                      [:field "marker" "@"]
                      [:repeat :_gap]
                      [:field "value" :_form]]

  :quoting_lit [:seq [:repeat :_metadata_lit]
                     [:field "marker" "'"]
                     [:repeat :_gap]
                     [:field "value" :_form]]

  :syn_quoting_lit [:seq [:repeat :_metadata_lit]
                         [:field "marker" "`"]
                         [:repeat :_gap]
                         [:field "value" :_form]]

  :unquote_splicing_lit [:seq [:repeat :_metadata_lit]
                              [:field "marker" "~@"]
                              [:repeat :_gap]
                              [:field "value" :_form]]

  :unquoting_lit [:seq [:repeat :_metadata_lit]
                       [:field "marker" "~"]
                       [:repeat :_gap]
                       [:field "value" :_form]]

  }]

{"Ada"
 {:file-extensions [".adb" ".ads"]
  :people ["Jean Ichbiah"]
  :year 1983}

 "Bash"
 {:file-extensions [".sh"]
  :people ["Brian Fox"
           "Chet Ramey"]
  :year 1989}

 "C"
 {:file-extensions [".c" ".h"]
  :people ["Dennis Ritchie"]
  :year 1972}

 "Dart"
 {:file-extensions [".dart"]
  :people ["Lars Bak"
           "Kasper Lund"]
  :year 2011}

 "Emacs Lisp"
 {:file-extensions [".el" ".elc" ".eln"]
  :people ["Richard Stallman"
           "Guy L. Steele, Jr."]
  :year 1985}

 "Forth"
 {:file-extensions [".fs" ".fth" ".4th" ".f" ".forth"]
  :people ["Charles H. Moore"]
  :year 1970}

 "Go"
 {:file-extensions [".go"]
  :people ["Robert Griesemer"
           "Rob Pike"
           "Ken Thompson"]
  :year 2009}

 "Haskell"
 {:file-extensions [".hs" ".lhs"]
  :people ["Lennart Augustsson"
           "Dave Barton"
           "Brian Boutel"
           "Warren Burton"
           "Joseph Fasel"
           "Kevin Hammond"
           "Ralf Hinze"
           "Paul Hudak"
           "John Hughes"
           "Thomas Johnsson"
           "Mark Jones"
           "Simon Peyton Jones"
           "John Launchbury"
           "Erik Meijer"
           "John Peterson"
           "Alastair Reid"
           "Colin Runciman"
           "Philip Wadler"]
  :year 1990}

 "Idris"
 {:file-extensions [".idr" ".lidr"]
  :people ["Edwin Brady"]
  :year 2007}

 "Janet"
 {:file-extensions [".cgen" ".janet" ".jdn"]
  :people ["Calvin Rose"]
  :year 2017}
}

(ns parse-samples
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [clojure.string :as cs]
            [conf :as cnf]))

(defn -main
  [& _args]
  (when (fs/exists? (cnf/repos :root))
    (let [start-time (System/currentTimeMillis)
          files (atom [])]
      ;; find all relevant clojure-related files
      (println "Looking in samples collection:" (cnf/repos :name))
      (print "Focusing on" (sort (cnf/repos :extensions)) "files ... ")
      (flush)
      (fs/walk-file-tree (cnf/repos :root)
                         {:visit-file
                          (fn [path _]
                            (when ((cnf/repos :extensions)
                                   (fs/extension path))
                              (swap! files conj path))
                            :continue)})
      (println "found"
               (count @files) "files"
               "in" (- (System/currentTimeMillis) start-time) "ms")
      (let [to-be-parsed (fs/create-temp-file)
            _ (fs/delete-on-exit to-be-parsed)]
        ;; save file paths to be parsed to a file
        (fs/write-lines to-be-parsed (map str @files))
        ;; parse with tree-sitter via the paths file
        (print "Invoking tree-sitter to parse files ... ")
        (flush)
        (try
          (let [start-time (System/currentTimeMillis)
                out-file-path (fs/create-temp-file)
                _ (fs/delete-on-exit out-file-path)
                p (proc/process {:dir (cnf/grammar :dir)
                                 :extra-env
                                 {"TREE_SITTER_DIR" cnf/ts-conf-dir
                                  "TREE_SITTER_LIBDIR" cnf/ts-lib-dir}
                                 :out :write
                                 :out-file (fs/file out-file-path)}
                                (str cnf/ts-bin-path
                                     " parse --quiet --paths "
                                     to-be-parsed))
                exit-code (:exit @p)
                duration (- (System/currentTimeMillis) start-time)]
            (when (= 1 exit-code)
              (println))
            (let [errors (atom 0)]
              ;; save and print error file info
              (fs/write-lines (cnf/repos :error-file-paths)
                              (keep (fn [line]
                                      (if-let [[path-ish time message]
                                               (cs/split line #"\t")]
                                        (let [path (cs/trim path-ish)]
                                          (when cnf/verbose
                                            (println message path))
                                          (swap! errors inc)
                                          path)
                                        (println "Did not parse:" line)))
                                    (fs/read-all-lines
                                      (fs/file out-file-path))))
              (if (zero? @errors)
                (println "No parse errors.")
                (do
                  (println "Counted" @errors "paths with parse issues.")
                  (println "See" (cnf/repos :error-file-paths)
                           "for details or rerun verbosely."))))
            (when-not (#{0 1} exit-code)
              (println "tree-sitter parse exited with unexpected exit-code:"
                       exit-code)
              (System/exit 1))
            (println "Took" duration "ms"))
          (catch Exception e
            (println "Exception:" (.getMessage e))
            (System/exit 1)))))))
