
@(:ant :bee






  :cat :dog




  :elephant :fox










  :giraffe :heron











  :iguana :janet)

@["Archimedes" "Bohm"








  "Cantor" "Deming"










  "Erdos" "Feynman"








  "Gauss" "Houdini"





  "Ishikawa" "Janet"]

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

~@{:main
   (some :input)
   #
   :input
   (choice :non-form
           :form)
   #
   :non-form
   (choice :whitespace
           :comment)
   #
   :whitespace
   (choice (some (set " \0\f\t\v"))
           (choice "\r\n"
                   "\r"
                   "\n"))
   #
   :comment
   (sequence "#"
             (any (if-not (set "\r\n") 1)))
   #
   :form
   (choice :reader-macro
           :collection
           :literal)
   #
   :reader-macro
   (choice :fn
           :quasiquote
           :quote
           :splice
           :unquote)
   #
   :fn
   (sequence "|"
             (any :non-form)
             :form)
   #
   :quasiquote
   (sequence "~"
             (any :non-form)
             :form)
   #
   :quote
   (sequence "'"
             (any :non-form)
             :form)
   #
   :splice
   (sequence ";"
             (any :non-form)
             :form)
   #
   :unquote
   (sequence ","
             (any :non-form)
             :form)
   #
   :literal
   (choice :number
           :constant
           :buffer
           :string
           :long-buffer
           :long-string
           :keyword
           :symbol)
   #
   :collection
   (choice :array
           :bracket-array
           :tuple
           :bracket-tuple
           :table
           :struct)
   #
   :number
   (drop (cmt
           (capture (some :name-char))
           ,scan-number))
   #
   :name-char
   (choice (range "09" "AZ" "az" "\x80\xFF")
           (set "!$%&*+-./:<?=>@^_"))
   #
   :constant
   (sequence (choice "false" "nil" "true")
             (not :name-char))
   #
   :buffer
   (sequence "@\""
             (any (choice :escape
                          (if-not "\"" 1)))
             "\"")
   #
   :escape
   (sequence "\\"
             (choice (set `"'0?\abefnrtvz`)
                     (sequence "x" [2 :h])
                     (sequence "u" [4 :h])
                     (sequence "U" [6 :h])
                     (error (constant "bad escape"))))
   #
   :string
   (sequence "\""
             (any (choice :escape
                          (if-not "\"" 1)))
             "\"")
   #
   :long-string :long-bytes
   #
   :long-bytes
   {:main (drop (sequence :open
                          (any (if-not :close 1))
                          :close))
    :open (capture :delim :n)
    :delim (some "`")
    :close (cmt (sequence (not (look -1 "`"))
                          (backref :n)
                          (capture (backmatch :n)))
                ,=)}
   #
   :long-buffer
   (sequence "@"
             :long-bytes)
   #
   :keyword
   (sequence ":"
             (any :name-char))
   #
   :symbol (some :name-char)
   #
   :array
   (sequence "@("
             (any :input)
             (choice ")"
                     (error (constant "missing )"))))
   #
   :tuple
   (sequence "("
             (any :input)
             (choice ")"
                     (error (constant "missing )"))))
   #
   :bracket-array
   (sequence "@["
             (any :input)
             (choice "]"
                     (error (constant "missing ]"))))
   #
   :bracket-tuple
   (sequence "["
             (any :input)
             (choice "]"
                     (error (constant "missing ]"))))
   :table
   (sequence "@{"
             (any :input)
             (choice "}"
                     (error (constant "missing }"))))
   #
   :struct
   (sequence "{"
             (any :input)
             (choice "}"
                     (error (constant "missing }"))))
   }

(defn- peg-match
  [the-peg the-text &opt the-start & the-args]
  #
  (defn peg-match**
    [opeg otext]
    #
    (def peg-table
      (case (type opeg)
        :string
        @{:main opeg}
        #
        :number
        (do (assert (int? opeg)
                    (string "number must be an integer: " opeg))
          @{:main opeg})
        #
        :keyword
        (do (assert (in default-peg-grammar opeg)
                    (string "default-peg-grammar does not have :" opeg))
          @{:main opeg})
        #
        :tuple
        @{:main opeg}
        #
        :struct
        (do (assert (get opeg :main)
                    (string "missing :main in grammar: %p" opeg))
          (table ;(kvs opeg)))
        #
        :table
        (do (assert (get opeg :main)
                    (string "missing :main in grammar: %p" opeg))
          opeg)))
    (assert (peg-table :main)
            "peg needs a :main key")
    (table/setproto peg-table default-peg-grammar)
    #
    (def tot-len (length otext))
    #
    (var indent 0)
    (def nws 1)
    #
    (var captures @[])
    (var scratch @"")
    (var tags @[])
    (var tagged_captures @[])
    (var mode :peg_mode_normal)
    (def linemap @[])
    (var linemaplen -1)
    # allow overriding via :meg-debug
    (def has_backref
      (if-let [md (dyn :meg-debug)]
        (if-let [setting (get md :disable_tagged_captures)]
          (not setting)
          true)
        true))
    #
    (defn log-entry
      [op peg text grammar]
      (++ indent)
      (when-let [md (dyn :meg-debug)]
        (let [ind (string/repeat " " (* nws indent))]
          (print ind op " >")
          (when (struct? md)
            (when (in md :captures)
              (printf "%s captures: %j" ind captures))
            (when (in md :scratch)
              (printf "%s scratch: %j" ind scratch))
            (when (in md :tags)
              (printf "%s tags: %j" ind tags))
            (when (in md :tagged_captures)
              (printf "%s tagged_captures: %j" ind tagged_captures))
            (when (in md :mode)
              (printf "%s mode: %j" ind mode))
            (when (in md :has_backref)
              (printf "%s has_backref: %j" ind has_backref))
            (when (in md :peg)
              (printf "%s peg: %p" ind peg))
            (when (in md :text)
              (printf "%s text: %j" ind text))))))
    #
    (defn log-exit
      [op ret &opt dict]
      (default dict {})
      (when-let [md (dyn :meg-debug)]
        (let [ind (string/repeat " " (* nws indent))]
          (print ind op " <")
          (when (struct? md)
            (when (in md :captures)
              (printf "%s captures: %j" ind captures))
            (when (in md :scratch)
              (printf "%s scratch: %j" ind scratch))
            (when (in md :tags)
              (printf "%s tags: %j" ind tags))
            (when (in md :tagged_captures)
              (printf "%s tagged_captures: %j" ind tagged_captures))
            (when (in md :mode)
              (printf "%s mode: %j" ind mode))
            (when (in md :has_backref)
              (printf "%s has_backref: %j" ind has_backref))
            (when (in md :peg)
              (when-let [peg (in dict :peg)]
                (printf "%s peg: %p" ind peg)))
            (when (in md :text)
              (when-let [text (in dict :text)]
                (printf "%s text: %j" ind text))))
          (printf "%s ret: %j" ind ret)))
      (-- indent))
    #
    (defn cap_save
      []
      {:scratch (length scratch)
       :captures (length captures)
       :tagged_captures (length tagged_captures)})
    #
    (defn cap_load
      [cs]
      (set scratch
           (buffer/slice scratch 0 (cs :scratch)))
      (set captures
           (array/slice captures 0 (cs :captures)))
      (set tags
           (array/slice tags 0 (cs :tagged_captures)))
      (set tagged_captures
           (array/slice tagged_captures 0 (cs :tagged_captures))))
    #
    (defn cap_load_keept
      [cs]
      (set scratch
           (buffer/slice scratch 0 (cs :scratch)))
      (set captures
           (array/slice captures 0 (cs :captures))))
    #
    (defn pushcap
      [capture tag]
      (case mode
        :peg_mode_accumulate
        (buffer/push scratch (string capture))
        #
        :peg_mode_normal
        (array/push captures capture)
        #
        (error (string "unrecognized mode: " mode)))
      #
      (when has_backref
        (array/push tagged_captures capture)
        (array/push tags tag)))
    #
    (defn get_linecol_from_position
      [position]
      (when (neg? linemaplen)
        (var nl-count 0)
        (def nl-char (chr "\n"))
        (forv i 0 (length otext)
          (let [ch (in otext i)]
            (when (= ch nl-char)
              (array/push linemap i)
              (++ nl-count))))
        (set linemaplen nl-count))
      #
      (var hi linemaplen)
      (var lo 0)
      (while (< (inc lo) hi)
        (def mid
          (math/floor (+ lo (/ (- hi lo) 2))))
        (if (>= (get linemap mid) position)
          (set hi mid)
          (set lo mid)))
      (if (or (= linemaplen 0)
              (and (= lo 0)
                   (>= (get linemap 0) position)))
        [1 (inc position)]
        [(+ lo 2) (- position (get linemap lo))]))
    #
    (defn peg-match*
      [peg text grammar]
      #
      (cond
        # keyword leads to a lookup in the grammar
        (keyword? peg)
        (do
          (log-entry "KEYWORD" peg text grammar)
          (def ret
            (peg-match* (grammar peg) text grammar))
          (log-exit "KEYWORD" ret {:peg peg :text text})
          ret)
        # string is RULE_LITERAL
        (string? peg)
        (do
          (log-entry "RULE_LITERAL" peg text grammar)
          (def ret
            (when (string/has-prefix? peg text)
              (length peg)))
          (log-exit "RULE_LITERAL" ret {:peg peg :text text})
          ret)
        # non-negative integer is RULE_NCHAR
        (nat? peg)
        (do
          (log-entry "RULE_NCHAR" peg text grammar)
          (def ret
            (when (<= peg (length text))
              peg))
          (log-exit "RULE_NCHAR" ret {:peg peg :text text})
          ret)
        # negative integer is RULE_NOTNCHAR
        (and (int? peg)
             (neg? peg))
        (do
          (log-entry "RULE_NOTNCHAR" peg text grammar)
          (def text-len (length text))
          (def ret
            (when (not (<= (math/abs peg) text-len))
              text-len))
          (log-exit "RULE_NOTNCHAR" ret {:peg peg :text text})
          ret)
        # struct looks up the peg associated with :main
        (struct? peg)
        (do
          (log-entry "STRUCT" peg text grammar)
          (assert (peg :main)
                  "peg does not have :main")
          (def ret
            (peg-match* (peg :main) text peg))
          (log-exit "STRUCT" ret {:peg peg :text text})
          ret)
        #
        (tuple? peg)
        (do
          (assert (pos? (length peg))
                  "peg must have non-zero length")
          (def op (get peg 0))
          (def tail (drop 1 peg))
          #
          (cond
            # RULE_RANGE
            (= 'range op)
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def ret
                (when (> (length text) 0)
                  (let [target-bytes
                        (reduce (fn [acc elt]
                                  (assert (= 2 (length elt))
                                          "`range` argument must be length 2")
                                  (let [left (get elt 0)
                                        right (get elt 1)]
                                    (assert (<= left right) "empty range")
                                    (array/concat acc
                                                  (range left (inc right)))))
                                @[]
                                tail)
                        target-set (string/from-bytes ;target-bytes)]
                    (when (string/check-set target-set
                                            (string/slice text 0 1))
                      1))))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_SET
            (= 'set op)
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def patt (first tail))
              (def ret
                (when (and (> (length text) 0)
                           (string/check-set patt
                                             (string/slice text 0 1)))
                  1))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_LOOK
            (or (= 'look op)
                (= '> op))
            (do
              (log-entry op peg text grammar)
              (assert (>= (length tail) 2)
                      (string/format "`%s` requires at least 2 arguments"
                                     (string op)))
              (def offset (first tail))
              (assert (int? offset)
                      "offset argument should be an integer")
              (def ret
                (label result
                  (let [text-len (length text)
                        cur-idx (- tot-len text-len)
                        new-start (+ cur-idx offset)]
                    (when (or (< new-start 0)
                              (> new-start text-len))
                      (return result nil))
                    (def patt (in tail 1))
                    (when-let [res-idx
                               (peg-match* patt
                                           (string/slice otext new-start)
                                           grammar)]
                      0))))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_CHOICE
            (or (= 'choice op)
                (= '+ op))
            (do
              (log-entry op peg text grammar)
              (def len (length tail))
              (def ret
                (label result
                  (when (= len 0)
                    (return result nil))
                  (def cs (cap_save))
                  (forv i 0 (dec len)
                    (def sub-peg (get tail i))
                    (def res-idx (peg-match* sub-peg text grammar))
                    # XXX: should be ok?
                    (when res-idx
                      (return result res-idx))
                    (cap_load cs))
                  (peg-match* (get tail (dec len))
                              text grammar)))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_SEQUENCE
            (or (= '* op)
                (= 'sequence op))
            (do
              (log-entry op peg text grammar)
              (def len (length tail))
              (def ret
                (label result
                  (when (= len 0)
                    (return result 0))
                  (var cur-text text)
                  (var res-idx nil)
                  (var acc-idx 0)
                  (var i 0)
                  (while (and cur-text
                              (< i (dec len)))
                    (def sub-peg (get tail i))
                    (set res-idx (peg-match* sub-peg cur-text grammar))
                    # looks weird but makes it more similar to peg.c
                    (if res-idx
                      (do
                        (set cur-text (string/slice cur-text res-idx))
                        (+= acc-idx res-idx))
                      (set cur-text nil))
                    (++ i))
                  (when (nil? cur-text)
                    (return result nil))
                  (when-let [last-idx
                             (peg-match* (get tail (dec len))
                                         cur-text grammar)]
                    (+ acc-idx last-idx))))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_IF
            (= 'if op)
            (do
              (log-entry op peg text grammar)
              (assert (>= (length tail) 2)
                      (string/format "`%s` requires at least 2 arguments"
                                     (string op)))
              (def patt-a (first tail))
              (def patt-b (in tail 1))
              (def res-idx (peg-match* patt-a text grammar))
              (def ret
                (if res-idx
                  (peg-match* patt-b text grammar)
                  nil))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_IFNOT
            (= 'if-not op)
            (do
              (log-entry op peg text grammar)
              (assert (>= (length tail) 2)
                      (string/format "`%s` requires at least 2 arguments"
                                     (string op)))
              (def patt-a (first tail))
              (def patt-b (in tail 1))
              (def cs (cap_save))
              (def res-idx (peg-match* patt-a text grammar))
              (def ret
                (if res-idx
                  nil
                  (do
                    (cap_load cs)
                    (peg-match* patt-b text grammar))))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_NOT
            (or (= 'not op)
                (= '! op))
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def patt (first tail))
              (def cs (cap_save))
              (def res-idx (peg-match* patt text grammar))
              (def ret
                (if res-idx
                  nil
                  (do
                    (cap_load cs)
                    0)))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_THRU
            (= 'thru op)
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def patt (first tail))
              (def cs (cap_save))
              (def ret
                (label result
                  (var cur-text text)
                  (def text-len (length text))
                  (var next-idx nil)
                  (var cur-idx 0)
                  (while (<= cur-idx text-len)
                    (def cs2 (cap_save))
                    (set next-idx (peg-match* patt cur-text grammar))
                    (when next-idx
                      (break))
                    (when (pos? (length cur-text))
                      (set cur-text (string/slice cur-text 1)))
                    (cap_load cs2)
                    (++ cur-idx))
                  (when (> cur-idx text-len)
                    (cap_load cs)
                    (return result nil))
                  (when next-idx
                    (+= cur-idx next-idx))))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_TO
            (= 'to op)
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def patt (first tail))
              (def cs (cap_save))
              (def ret
                (label result
                  (var cur-text text)
                  (def text-len (length text))
                  (var next-idx nil)
                  (var cur-idx 0)
                  (while (<= cur-idx text-len)
                    (def cs2 (cap_save))
                    (set next-idx (peg-match* patt cur-text grammar))
                    (when next-idx
                      (cap_load cs2)
                      (break))
                    (when (pos? (length cur-text))
                      (set cur-text (string/slice cur-text 1)))
                    (cap_load cs2)
                    (++ cur-idx))
                  (when (> cur-idx text-len)
                    (cap_load cs)
                    (return result nil))
                  (when next-idx
                    cur-idx)))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_BETWEEN
            (or (= 'between op)
                # XXX: might remove if analysis / rewrite path is taken
                (= 'opt op)
                (= '? op)
                (= 'any op)
                (= 'some op)
                (= 'at-least op)
                (= 'at-most op)
                (= 'repeat op)
                (int? op))
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (var lo 0)
              (var hi 1)
              (var patt nil)
              (cond
                (= 'between op)
                (do
                  (assert (<= 3 (length tail))
                          "`between` requires at least 3 arguments")
                  (set lo (in tail 0))
                  (assert (nat? lo)
                          (string "expected non-neg int, got: " lo))
                  (set hi (in tail 1))
                  (assert (nat? hi)
                          (string "expected non-neg int, got: " hi))
                  (set patt (in tail 2)))
                #
                (or (= 'opt op)
                    (= '? op))
                (set patt (first tail))
                #
                (= 'any op)
                (do
                  (set patt (first tail))
                  # XXX: 2 ^ 32 - 1 not an integer...
                  (set hi (math/pow 2 30)))
                #
                (= 'some op)
                (do
                  (set patt (first tail))
                  (set lo 1)
                  # XXX: 2 ^ 32 - 1 not an integer...
                  (set hi (math/pow 2 30)))
                #
                (= 'at-least op)
                (do
                  (assert (<= 2 (length tail))
                          "`at-least` requires at least 2 arguments")
                  (set patt (in tail 1))
                  (set lo (first tail))
                  (assert (nat? lo)
                          (string "expected non-neg int, got: " lo))
                  # XXX: 2 ^ 32 - 1 not an integer...
                  (set hi (math/pow 2 30)))
                #
                (= 'at-most op)
                (do
                  (assert (<= 2 (length tail))
                          "`at-most` requires at least 2 arguments")
                  (set patt (in tail 1))
                  (set hi (first tail))
                  (assert (nat? hi)
                          (string "expected non-neg int, got: " hi)))
                #
                (= 'repeat op)
                (do
                  (assert (<= 2 (length tail))
                          "`repeat` requires at least 2 arguments")
                  (set patt (in tail 1))
                  (def arg (first tail))
                  (assert (nat? arg)
                          (string "expected non-neg int, got: " arg))
                  (set lo arg)
                  (set hi arg))
                #
                (int? op)
                (do
                  (assert (not (empty? tail))
                          "`n` requires at least 1 argument")
                  (set patt (first tail))
                  (assert (nat? op)
                          (string "expected non-neg int, got: " op))
                  (set lo op)
                  (set hi op)))
              #
              (def cs (cap_save))
              (def ret
                (label result
                  (var captured 0)
                  (var cur-text text)
                  (var next-idx nil)
                  (var acc-idx 0)
                  (while (< captured hi)
                    (def cs2 (cap_save))
                    (set next-idx (peg-match* patt cur-text grammar))
                    # match fail or no change in position
                    (when (or (nil? next-idx)
                              (= next-idx 0))
                      (cap_load cs2)
                      (break))
                    (++ captured)
                    (set cur-text (string/slice cur-text next-idx))
                    (+= acc-idx next-idx))
                  (when (< captured lo)
                    (cap_load cs)
                    (return result nil))
                  acc-idx))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_GETTAG
            (or (= 'backref op)
                (= '-> op))
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def tag (first tail))
              (def ret
                (label result
                  (loop [i :down-to [(dec (length tags)) 0]]
                    (let [cur-tag (get tags i)]
                      (when (= cur-tag tag)
                        (pushcap (get tagged_captures i) tag)
                        (return result 0))))
                  nil))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_POSITION
            (or (= 'position op)
                (= '$ op))
            (do
              (log-entry op peg text grammar)
              (def tag (when (not (empty? tail))
                         (first tail)))
              (pushcap (- tot-len (length text)) tag)
              (def ret 0)
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_LINE
            (= 'line op)
            (do
              (log-entry op peg text grammar)
              (def tag (when (not (empty? tail))
                         (first tail)))
              (def [line _]
                (get_linecol_from_position (- tot-len
                                              (length text))))
              (pushcap line tag)
              (def ret 0)
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_COLUMN
            (= 'column op)
            (do
              (log-entry op peg text grammar)
              (def tag (when (not (empty? tail))
                         (first tail)))
              (def [_ col]
                (get_linecol_from_position (- tot-len
                                              (length text))))
              (pushcap col tag)
              (def ret 0)
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_ARGUMENT
            (= 'argument op)
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def patt (first tail))
              (assert (nat? patt)
                      (string "expected non-negative integer, got: " patt))
              (assert (< patt (length the-args))
                      (string "expected smaller integer, got: " patt))
              (def tag (when (< 1 (length tail))
                         (in tail 1)))
              (def arg-n (in the-args patt))
              (pushcap arg-n tag)
              (def ret 0)
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_CONSTANT
            (= 'constant op)
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def patt (first tail))
              (def tag (when (< 1 (length tail))
                         (in tail 1)))
              (pushcap patt tag)
              (def ret 0)
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_CAPTURE
            (or (= 'capture op)
                (= 'quote op)
                (= '<- op))
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def patt (first tail))
              (def tag (when (< 1 (length tail))
                         (in tail 1)))
              (def res-idx (peg-match* patt text grammar))
              (def ret
                (when res-idx
                  (let [cap (string/slice text 0 res-idx)]
                    (if (and (not has_backref)
                             (= mode :peg_mode_accumulate))
                      (buffer/push scratch cap)
                      (pushcap cap tag)))
                  res-idx))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_CAPTURE_NUM
            (= 'number op)
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def patt (first tail))
              (def base (when (< 1 (length tail))
                          (in tail 1)))
              (def tag (when (< 2 (length tail))
                         (in tail 2)))
              (def res-idx (peg-match* patt text grammar))
              (def ret
                (when res-idx
                  (let [cap (string/slice text 0 res-idx)]
                    (when-let [num (scan-number-base cap base)]
                      (if (and (not has_backref)
                               (= mode :peg_mode_accumulate))
                        (buffer/push scratch cap)
                        (pushcap num tag))))
                  res-idx))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_ACCUMULATE
            (or (= 'accumulate op)
                (= '% op))
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def patt (first tail))
              (def tag (when (< 1 (length tail))
                         (in tail 1)))
              (def old-mode mode)
              (when (and (not tag)
                         (= old-mode :peg_mode_accumulate))
                (peg-match* patt text grammar))
              (def cs (cap_save))
              (set mode :peg_mode_accumulate)
              (def res-idx (peg-match* patt text grammar))
              (set mode old-mode)
              (def ret
                (when res-idx
                  (def cap (string scratch))
                  (cap_load_keept cs)
                  (pushcap cap tag)
                  res-idx))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_DROP
            (= 'drop op)
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def patt (first tail))
              (def cs (cap_save))
              (def res-idx (peg-match* patt text grammar))
              (def ret
                (when res-idx
                  (cap_load cs)
                  res-idx))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_GROUP
            (= 'group op)
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def patt (first tail))
              (def tag (when (< 1 (length tail))
                         (in tail 1)))
              (def old-mode mode)
              (def cs (cap_save))
              (set mode :peg_mode_normal)
              (def res-idx (peg-match* patt text grammar))
              (set mode old-mode)
              (def ret
                (when res-idx
                  (def cap
                    # use only the new captures
                    (array/slice captures
                                 (cs :captures)))
                  (cap_load_keept cs)
                  (pushcap cap tag)
                  res-idx))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_REPLACE
            (or (= 'replace op)
                (= '/ op))
            (do
              (log-entry op peg text grammar)
              (assert (not (< (length tail) 2))
                      (string/format "`%s` requires at least 2 arguments"
                                     (string op)))
              (def patt (first tail))
              (def subst (in tail 1))
              (def tag (when (> (length tail) 2)
                         (in tail 2)))
              (def old-mode mode)
              (def cs (cap_save))
              (set mode :peg_mode_normal)
              (def res-idx (peg-match* patt text grammar))
              (set mode old-mode)
              (def ret
                (when res-idx
                  (def cap
                    (cond
                      (dictionary? subst)
                      (get subst (last captures))
                      #
                      (or (function? subst)
                          (cfunction? subst))
                      # use only the new captures
                      (subst ;(array/slice captures
                                           (cs :captures)))
                      #
                      subst))
                  (cap_load_keept cs)
                  (pushcap cap tag)
                  res-idx))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_MATCHTIME
            (= 'cmt op)
            (do
              (log-entry op peg text grammar)
              (assert (not (< (length tail) 2))
                      (string/format "`%s` requires at least 2 arguments"
                                     (string op)))
              (def patt (first tail))
              (def subst (in tail 1))
              (assert (or (function? subst)
                          (cfunction? subst))
                      (string "expected a function, got: " (type subst)))
              (def tag (when (> (length tail) 2)
                         (in tail 2)))
              (def old-mode mode)
              (def cs (cap_save))
              (set mode :peg_mode_normal)
              (def res-idx (peg-match* patt text grammar))
              (set mode old-mode)
              (def ret
                (label result
                  (when res-idx
                    (def cap
                      # use only the new captures
                      (subst ;(array/slice captures
                                           (cs :captures))))
                    (cap_load_keept cs)
                    (when (not (truthy? cap))
                      (return result nil))
                    (pushcap cap tag)
                    res-idx)))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_ERROR
            (= 'error op)
            (do
              (log-entry op peg text grammar)
              (def patt (if (empty? tail)
                          0 # determined via gdb
                          (first tail)))
              (def old-mode mode)
              (set mode :peg_mode_normal)
              (def old-cap (length captures))
              (def res-idx (peg-match* patt text grammar))
              (set mode old-mode)
              (def ret
                (when res-idx
                  (if (> (length captures) old-cap)
                    (error (string (last captures)))
                    (let [[line col]
                          (get_linecol_from_position (- tot-len
                                                        (length text)))]
                      (errorf "match error at line %d, column %d" line col)))
                  # XXX: should not get here
                  nil))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_BACKMATCH
            (= 'backmatch op)
            (do
              (log-entry op peg text grammar)
              (def tag (when (not (empty? tail))
                         (first tail)))
              (def ret
                (label result
                  (loop [i :down-to [(dec (length tags)) 0]]
                    (let [cur-tag (get tags i)]
                      (when (= cur-tag tag)
                        (def cap
                          (get tagged_captures i))
                        (when (not (string? cap))
                          (return result nil))
                        #
                        (let [caplen (length cap)]
                          (when (> (+ (length text) caplen)
                                   tot-len)
                            (return result nil))
                          (return result
                                  (when (string/has-prefix? cap text)
                                    caplen))))))
                  nil))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_LENPREFIX
            (= 'lenprefix op)
            (do
              (log-entry op peg text grammar)
              (assert (not (< (length tail) 2))
                      (string/format "`%s` requires at least 2 arguments"
                                     (string op)))
              (def n-patt (first tail))
              (def patt (in tail 1))
              (def old-mode mode)
              (set mode :peg_mode_normal)
              (def cs (cap_save))
              (def ret
                (label result
                  (def idx (peg-match* n-patt text grammar))
                  (when (nil? idx)
                    (return result nil))
                  #
                  (set mode old-mode)
                  (def num-sub-caps
                    (- (length captures) (cs :captures)))
                  (var lencap nil)
                  (when (<= num-sub-caps 0)
                    (cap_load cs)
                    (return result nil))
                  #
                  (set lencap (get captures (cs :captures)))
                  (when (not (int? lencap))
                    (cap_load cs)
                    (return result nil))
                  #
                  (def nrep lencap)
                  (cap_load cs)
                  (var next-idx nil)
                  (var next-text (string/slice text idx))
                  (var acc-idx idx)
                  (forv i 0 nrep
                    (set next-idx
                         (peg-match* patt next-text grammar))
                    (when (nil? next-idx)
                      (cap_load cs)
                      (return result nil))
                    (+= acc-idx next-idx)
                    (set next-text
                         (string/slice next-text next-idx)))
                  acc-idx))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_READINT
            (or (= 'int op)
                (= 'int-be op)
                (= 'uint op)
                (= 'uint-be op))
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def width (first tail))
              (def tag (when (> (length tail) 1)
                         (in tail 1)))
              (def ret
                (label result
                  (when (> width (length text))
                    (return result nil))
                  (var accum nil)
                  (cond
                    (= 'int op)
                    (do
                      (set accum (if (> width 6)
                                   (int/s64 0)
                                   0))
                      (loop [i :down-to [(dec width) 0]]
                        (set accum
                             (bor (blshift accum 8)
                                  (get text i)))))
                    #
                    (= 'int-be op)
                    (do
                      (set accum (if (> width 6)
                                   (int/s64 0)
                                   0))
                      (forv i 0 width
                        (set accum
                             (bor (blshift accum 8)
                                  (get text i)))))
                    #
                    (= 'uint op)
                    (do
                      (set accum (if (> width 6)
                                   (int/u64 0)
                                   0))
                      (loop [i :down-to [(dec width) 0]]
                        (set accum
                             (bor (blshift accum 8)
                                  (get text i)))))
                    #
                    (= 'uint-be op)
                    (do
                      (set accum (if (> width 6)
                                   (int/u64 0)
                                   0))
                      (forv i 0 width
                        (set accum
                             (bor (blshift accum 8)
                                  (get text i))))))
                  #
                  (when (or (= 'int op)
                            (= 'int-be op))
                    (def shift (* 8 (- 8 width)))
                    (set accum
                         (brshift (blshift accum shift) shift)))
                  (var capture-value accum)
                  (pushcap capture-value tag)
                  width))
              (log-exit op ret {:peg peg :text text})
              ret)
            # RULE_UNREF
            (= 'unref op)
            (do
              (log-entry op peg text grammar)
              (assert (not (empty? tail))
                      (string/format "`%s` requires at least 1 argument"
                                     (string op)))
              (def rule (first tail))
              (def tag (when (> (length tail) 1)
                         (in tail 1)))
              (def tcap (length tags))
              (def res-idx (peg-match* rule text grammar))
              (def ret
                (label result
                  (when (nil? res-idx)
                    (return result nil))
                  (def final-tcap (length tags))
                  (var w tcap)
                  (when tag
                    (forv i tcap final-tcap
                      (when (= tag (get tags i))
                        (put tags
                             w (get tags i))
                        (put tagged_captures
                             w (get tagged_captures i))
                        (++ w))))
                  (set tags
                       (array/slice tags 0 w))
                  (set tagged_captures
                       (array/slice tagged_captures 0 w))
                  res-idx))
              (log-exit op ret {:peg peg :text text})
              ret)
            #
            (error (string "unknown tuple op: " op))))
        #
        (error (string "unknown peg: " peg))))
    # XXX: for aesthetic purposes
    (when (dyn :meg-debug)
      (print))
    #
    (def index
      (peg-match* (peg-table :main) otext peg-table))
    [captures index tags])
  #
  (when the-start
    (let [text-len (length the-text)]
      (assert (and (<= the-start text-len)
                   (<= (* -1 (inc text-len)) the-start))
              "start argument out of range")))
  (default the-start 0)
  (def [captures index tags]
    (peg-match** (if (= :function (type the-peg))
                   (the-peg)
                   the-peg)
                 (if (not= 0 the-start)
                   (string/slice the-text the-start)
                   the-text)))
  (when (dyn :meg-debug)
    (print "--------")
    (prin "tags: ")
    (pp tags)
    (prin "captures: ")
    (pp captures))
  (when index
    (when (dyn :meg-debug)
      (print "index: " index)
      (print "--------"))
    captures))

[:name "janet_simple"

 # see is_whitespace in janet's parser.c
 :extras []

 :externals [:long_buf_lit :long_str_lit]

 :_tokens
 [:WHITESPACE_CHAR
  [:regex "\\x00|\\x09|\\x0a|\\x0b|\\x0c|\\x0d|\\x20"]

  :WHITESPACE [:token [:repeat1 :WHITESPACE_CHAR]]

  :COMMENT [:token [:regex "#.*\\n?"]]

  :SIGN [:choice "-" "+"]

  :DIGIT [:regex "[0-9]"]

  :DEC_CHUNK [:seq [:repeat1 :DIGIT]
                   [:repeat [:seq [:repeat "_"]
                                  [:repeat1 :DIGIT]
                                  [:repeat "_"]]]]

  :HEX_DIGIT [:regex "[0-9A-Fa-f]"]

  :HEX_CHUNK [:seq [:repeat1 :HEX_DIGIT]
                   [:repeat [:seq [:repeat "_"]
                                  [:repeat1 :HEX_DIGIT]
                                  [:repeat "_"]]]]

  :RADIX [:choice
          "2" "3" "4" "5" "6" "7" "8" "9" "10"
          "11" "12" "13" "14" "15" "16" "17" "18" "19" "20"
          "21" "22" "23" "24" "25" "26" "27" "28" "29" "30"
          "31" "32" "33" "34" "35" "36"]

  :ALPHA_NUM [:regex "[a-zA-Z0-9]"]

  :SYM_CHAR_NO_DIGIT_NO_COLON
  [:regex "["
          "a-zA-Z"
          "!$%&*+./<?=>@^_"
          "Ā-􏿿" # 0100 - 10ffff
          "-" # order matters here
          "]"]

  # see is_symbol_char_gen in janet's tools/symcharsgen.c
  :SYM_CHAR
  [:regex "["
          "0-9:"
          "a-zA-Z"
          "!$%&*+./<?=>@^_"
          "Ā-􏿿" # 0100 - 10ffff
          "-" # order matters here
          "]"]

  :STRING_DOUBLE_QUOTE_CONTENT
  [:repeat [:choice [:regex "[^"
                            "\\\\"
                            "\""
                            "]"]
                    [:regex "\\\\"
                            "(.|\\n)"]]]]



:rules
 [:source [:repeat [:choice :_lit
                            :_gap]]

  :_gap [:choice :_ws
                 :comment
                 :dis_expr]

  :_ws :WHITESPACE

  :comment :COMMENT

  :dis_expr [:seq "\\#"
             [:repeat :_gap]
             :_lit]

  :_lit [:choice :bool_lit
                 :buf_lit
                 :kwd_lit
                 :long_buf_lit
                 :long_str_lit
                 :nil_lit
                 :num_lit
                 :str_lit
                 :sym_lit
                 #
                 :par_arr_lit
                 :sqr_arr_lit
                 :struct_lit
                 :tbl_lit
                 :par_tup_lit
                 :sqr_tup_lit
                 #
                 :qq_lit
                 :quote_lit
                 :short_fn_lit
                 :splice_lit
                 :unquote_lit]

  # XXX: without the token here, false and true are exposed as
  #      anonymous nodes it seems...
  #      yet, the same does not happen for nil...strange
  :bool_lit [:token [:choice "false" "true"]]

  :kwd_lit [:prec 2
                  [:token [:seq ":"
                                [:repeat :SYM_CHAR]]]]

  :nil_lit "nil"

  :num_lit [:prec 5
                  [:choice :_dec
                           :_hex
                           :_radix]]

  :_dec
  [:token [:seq [:optional :SIGN]
                [:choice :DEC_CHUNK
                         [:seq "."
                               [:repeat [:optional "_"]]
                               :DEC_CHUNK]
                         [:seq :DEC_CHUNK
                               "."
                               [:repeat [:optional "_"]]]
                         [:seq :DEC_CHUNK
                               "."
                               [:repeat [:optional "_"]]
                               :DEC_CHUNK]]
                [:optional [:seq [:choice "e" "E"]
                                 [:optional :SIGN]
                                 [:repeat1 :DIGIT]]]]]

  :_hex
  [:token [:seq [:optional :SIGN]
                "0x"
                [:choice :HEX_CHUNK
                         [:seq "." :HEX_CHUNK]
                         [:seq :HEX_CHUNK "."]
                         [:seq :HEX_CHUNK "." :HEX_CHUNK]]]]

  :_radix
  [:token [:seq [:optional :SIGN]
                [:seq :RADIX
                      "r"
                      :ALPHA_NUM
                      [:repeat [:choice [:repeat :ALPHA_NUM]
                                        [:repeat "_"]]]
                      [:optional [:seq "&"
                                       [:optional :SIGN]
                                       [:repeat1 :DIGIT]]]]]]

  :str_lit [:token [:seq "\""
                         :STRING_DOUBLE_QUOTE_CONTENT
                         "\""]]

  :buf_lit [:token [:seq "@\""
                         :STRING_DOUBLE_QUOTE_CONTENT
                         "\""]]

  :sym_lit [:token [:seq :SYM_CHAR_NO_DIGIT_NO_COLON
                         [:repeat :SYM_CHAR]]]

  :par_arr_lit [:seq "@(" [:repeat [:choice :_lit :_gap]] ")"]

  :sqr_arr_lit [:seq "@[" [:repeat [:choice :_lit :_gap]] "]"]

  :struct_lit [:seq "{" [:repeat [:choice :_lit :_gap]] "}"]

  :tbl_lit [:seq "@{" [:repeat [:choice :_lit :_gap]] "}"]

  :par_tup_lit [:seq "(" [:repeat [:choice :_lit :_gap]] ")"]

  :sqr_tup_lit [:seq "[" [:repeat [:choice :_lit :_gap]] "]"]

  :qq_lit [:seq "~" [:repeat :_gap] :_lit]

  :quote_lit [:seq "'" [:repeat :_gap] :_lit]

  :short_fn_lit [:seq "|" [:repeat :_gap] :_lit]

  :splice_lit [:seq ";" [:repeat :_gap] :_lit]

  :unquote_lit [:seq "," [:repeat :_gap] :_lit]]




