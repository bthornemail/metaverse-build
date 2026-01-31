Invariant: Authority-Projection
Semantic-Core: CanvasL
Adapter: true
Capability: CanvasL
Authority: automaton
Justification: ../ADAPTER-JUSTIFICATION.md
Inputs: (see adapter justification)
Outputs: (see adapter justification)
Trace: no
Halt-On-Violation: yes
;; =============================================================================
;; R5RS Canvas Engine - Unified Modular Codebase for JSONL Reference
;; =============================================================================
;; This file unifies all R5RS code from grok_files into a modular structure
;; organized as pure functions that can be referenced and invoked from JSONL.
;;
;; Structure:
;;   MODULE 1: Foundation & Primitives
;;   MODULE 2: JSONL Parser & Canvas Loader
;;   MODULE 3: RDF Layer
;;   MODULE 4: OWL Reasoning
;;   MODULE 5: SHACL Validation
;;   MODULE 6: Logic Programming
;;   MODULE 7: SPARQL Engine
;;   MODULE 8: NLP & M/S-Expressions
;;   MODULE 9: Quantum & AI
;;   MODULE 10: REPL & Interactive
;;   MODULE 11: Public API & Function Registry
;;
;; All functions are pure (no side effects) unless marked with ! suffix
;; =============================================================================

;; =============================================================================
;; MODULE 1: FOUNDATION & PRIMITIVES
;; =============================================================================
;; Church encoding, Y-combinator, basic data structures, utility functions
;; Source: 02-Grok.md

;; Basic list operations
(define (null? x) (eq? x '()))
(define (pair? x) (and (not (null? x)) (list? x)))
(define (list . x) x)
(define (car p) (if (pair? p) (if (null? (cdr p)) (cdr p) p) (error "car")))
(define (cdr p) (if (pair? p) (if (null? (cdr p)) '() (cdr p)) (error "cdr")))
(define (cons a b) (lambda (m) (m a b)))
(define (list? x) (or (null? x) (and (pair? x) (list? (cdr x)))))

;; Church booleans
(define true  (lambda (t f) t))
(define false (lambda (t f) f))
(define if-boolean    (lambda (c t e) (c t e)))
(define not-boolean   (lambda (b) (b false true)))
(define and-boolean   (lambda (a b) (a b a)))
(define or-boolean    (lambda (a b) (a a b)))

;; Church numerals (pure functions)
(define church-zero  (lambda (f) (lambda (x) x)))
(define church-one   (lambda (f) (lambda (x) (f x))))
(define church-succ  (lambda (n) (lambda (f) (lambda (x) (f ((n f) x))))))
(define church-add   (lambda (m n) (lambda (f) (lambda (x) ((m f) ((n f) x))))))
(define church-mult  (lambda (m n) (lambda (f) (m (n f)))))
(define church-exp   (lambda (m n) (n m)))

;; Y-combinator (fixed-point for self-reference)
(define Y (lambda (f) ((lambda (x) (f (lambda (y) ((x x) y))))
                      (lambda (x) (f (lambda (y) ((x x) y)))))))

;; Utility functions
(define (string-prefix? prefix str)
  (let ((pre-len (string-length prefix))
        (str-len (string-length str)))
    (and (>= str-len pre-len)
         (string=? prefix (substring str 0 pre-len)))))

(define (string-contains? str substr)
  (let ((sub-len (string-length substr))
        (str-len (string-length str)))
    (let loop ((i 0))
      (cond
        ((> (+ i sub-len) str-len) #f)
        ((string=? substr (substring str i (+ i sub-len))) #t)
        (else (loop (+ i 1)))))))

;; =============================================================================
;; MODULE 2: JSONL PARSER & CANVAS LOADER
;; =============================================================================
;; JSONL parsing, canvas fact extraction, node/edge extraction
;; Source: 03-Grok.md, 05-Grok.md
;; Converted to pure functions: parse-jsonl-canvas returns data structure

;; Pure JSONL parser - returns list of parsed objects
(define (parse-jsonl-canvas filename)
  (call-with-input-file filename
    (lambda (port)
      (let loop ((line (read-line port)) (result '()))
        (if (eof-object? line)
            (reverse result)
            (begin
              (when (and (> (string-length line) 0)
                        (char=? (string-ref line 0) #\{))
                (let ((obj (json->alist line)))
                  (when obj
                    (set! result (cons obj result)))))
              (loop (read-line port) result)))))))

;; JSON string → association list (pure)
(define (json->alist str)
  (with-input-from-string (string-append "(" str ")")
    (lambda ()
      (let ((port (current-input-port)))
        (let loop ((obj '()) (key #f) (in-str #f) (str-chars '()))
          (let ((c (read-char port)))
            (cond
              ((eof-object? c)
               (if key (reverse (cons (cons (string->symbol key) (list->string (reverse str-chars))) obj))
                   (reverse obj)))
              ((char=? c #\") 
               (if in-str
                   (if key
                       (loop (cons (cons (string->symbol key) (list->string (reverse str-chars))) obj) #f #f '())
                       (loop obj (list->string (reverse str-chars)) #f '()))
                   (loop obj key #t '())))
              ((char=? c #\:) (loop obj key in-str str-chars))
              ((char=? c #\,) (loop obj #f in-str '()))
              ((char=? c #\{) (loop obj #f #f '()))
              ((char=? c #\}) (reverse obj))
              (in-str (loop obj key #t (cons c str-chars)))
              (else (loop obj key in-str str-chars))))))))))

;; Extract facts from parsed JSONL (pure transformation)
(define (extract-facts parsed-objects)
  (let loop ((objs parsed-objects) (facts '()))
    (if (null? objs)
        (reverse facts)
        (let ((obj (car objs))
              (id (cdr (assoc 'id obj)))
              (type (cdr (assoc 'type obj))))
          (cond
            ((string-prefix? "v:" id)
             (loop (cdr objs) (cons (list 'vertical id 
                                          (cdr (assoc 'fromNode obj))
                                          (cdr (assoc 'toNode obj))) facts)))
            ((string-prefix? "h:" id)
             (loop (cdr objs) (cons (list 'horizontal id 
                                          (cdr (assoc 'fromNode obj))
                                          (cdr (assoc 'toNode obj))) facts)))
            ((equal? type "text")
             (loop (cdr objs) (cons (list 'node id 'text
                                         (cdr (assoc 'x obj))
                                         (cdr (assoc 'y obj))
                                         (cdr (assoc 'text obj))) facts)))
            ((equal? type "file")
             (loop (cdr objs) (cons (list 'node id 'file (cdr (assoc 'file obj))) facts)))
            (else (loop (cdr objs) (cons (list 'raw id obj) facts))))))))

;; Query facts (pure)
(define (query-facts facts pattern)
  (filter (lambda (fact)
            (match-pattern pattern fact))
          facts))

;; Pattern matching (pure)
(define (match-pattern pat fact)
  (let ((pat-pred (car pat))
        (fact-pred (car fact))
        (pat-args (cdr pat))
        (fact-args (cdr fact)))
    (and (equal? pat-pred fact-pred)
         (= (length pat-args) (length fact-args))
         (match-args pat-args fact-args '()))))

(define (match-args pat fact bindings)
  (cond
    ((null? pat) (null? fact))
    ((null? fact) #f)
    ((variable? (car pat))
     (let ((binding (assoc (car pat) bindings)))
       (if binding
           (and (equal? (cdr binding) (car fact))
                (match-args (cdr pat) (cdr fact) bindings))
           (match-args (cdr pat) (cdr fact)
                       (cons (cons (car pat) (car fact)) bindings)))))
    ((equal? (car pat) (car fact))
     (match-args (cdr pat) (cdr fact) bindings))
    (else #f)))

(define (variable? x)
  (and (symbol? x) (char=? (string-ref (symbol->string x) 0) #\?)))

;; =============================================================================
;; MODULE 3: RDF LAYER
;; =============================================================================
;; Triple store, RDFS entailment, graph operations
;; Source: 05-Grok.md
;; Converted to pure: jsonl-to-rdf returns triples, rdfs-entail takes triples

;; Convert JSONL facts to RDF triples (pure)
(define (jsonl-to-rdf facts)
  (let ((triples '())
        (nodes (query-facts facts '(node ?id ?type . ?rest)))
        (vedges (query-facts facts '(vertical ?id ?from ?to)))
        (hedges (query-facts facts '(horizontal ?id ?from ?to))))
    ;; Nodes → rdf:type
    (for-each (lambda (n)
                (let ((id (cadr n)))
                  (set! triples (cons (list id "rdf:type" "canvas:Node") triples))))
              nodes)
    ;; Vertical → rdfs:subClassOf
    (for-each (lambda (v)
                (let ((from (caddr v))
                      (to (cadddr v)))
                  (set! triples (cons (list (string-append "canvas:" to) 
                                           "rdfs:subClassOf" 
                                           (string-append "canvas:" from)) triples))))
              vedges)
    ;; Horizontal → canvas:implements
    (for-each (lambda (h)
                (let ((from (caddr h))
                      (to (cadddr h)))
                  (set! triples (cons (list (string-append "canvas:" from)
                                           "canvas:implements"
                                           (string-append "canvas:" to)) triples))))
              hedges)
    (reverse triples)))

;; RDF query (pure - takes triples as parameter)
(define (rdf-query triples s p o)
  (filter (lambda (t)
            (and (or (equal? s '?) (equal? s (car t)))
                 (or (equal? p '?) (equal? p (cadr t)))
                 (or (equal? o '?) (equal? o (caddr t)))))
          triples))

;; RDFS entailment (pure - input/output triples)
(define (rdfs-entail triples)
  (let loop ((current triples) (new '()))
    (let ((derived (append
                    ;; subClassOf transitivity
                    (transitive-closure current "rdfs:subClassOf")
                    ;; domain/range inference (stub)
                    '())))
      (if (null? derived)
          current
          (let ((updated (append current derived)))
            (loop updated '()))))))

(define (transitive-closure triples pred)
  (let ((pairs (map (lambda (t) (list (car t) (caddr t)))
                    (rdf-query triples '? pred '?))))
    (let collect ((new '()) (seen '()))
      (if (null? pairs)
          new
          (let* ((a (caar pairs))
                 (b (cadar pairs))
                 (chain (rdf-query triples b pred '?)))
            (let rec ((c chain) (acc new))
              (cond
                ((null? c) (collect acc (cons (list a b) seen)))
                ((member (list a (caddr (car c))) seen) (rec (cdr c) acc))
                (else
                 (rec (cdr c)
                      (cons (list a pred (caddr (car c))) acc))))))))))

;; =============================================================================
;; MODULE 4: OWL REASONING
;; =============================================================================
;; OWL entailment rules, sameAs, inverseOf, transitive closure
;; Source: 06-Grok.md
;; Converted to pure: owl-entail takes triples, returns new triples

;; OWL entailment (pure - input/output triples)
(define (owl-entail triples)
  (let loop ((current triples) (new '()))
    (let ((derived (append
                    (owl-sameAs-closure current)
                    (owl-inverse-closure current)
                    (owl-transitive-closure current)
                    (owl-symmetric-closure current)
                    (owl-functional-closure current)
                    (owl-inv-functional-closure current))))
      (if (null? derived)
          current
          (let ((updated (append current derived)))
            (loop updated '()))))))

(define (owl-sameAs-closure triples)
  (let ((pairs (rdf-query triples '? "owl:sameAs" '?)))
    (let collect ((new '()))
      (if (null? pairs)
          new
          (let* ((a (car (car pairs)))
                 (b (caddr (car pairs)))
                 (a-props (rdf-query triples a '? '?))
                 (b-props (rdf-query triples b '? '?)))
            (let rec ((props (append a-props b-props)) (acc new))
              (cond
                ((null? props) (collect acc))
                (else
                 (let* ((s (if (equal? a (car (car props))) b a))
                        (p (cadr (car props)))
                        (o (caddr (car props)))
                        (t (list s p o)))
                   (rec (cdr props)
                        (if (member t triples) acc (cons t acc))))))))))))

(define (owl-inverse-closure triples)
  (let ((inverses (rdf-query triples '? "owl:inverseOf" '?)))
    (let collect ((new '()))
      (if (null? inverses)
          new
          (let* ((p (car (car inverses)))
                 (q (caddr (car inverses)))
                 (fwd (rdf-query triples '? p '?))
                 (rev (rdf-query triples '? q '?)))
            (let rec ((t (append fwd rev)) (acc new))
              (cond
                ((null? t) (collect acc))
                (else
                 (let* ((s (car (car t)))
                        (o (caddr (car t)))
                        (inv-p (if (equal? p (cadr (car t))) q p))
                        (t-new (list o inv-p s)))
                   (rec (cdr t)
                        (if (member t-new triples) acc (cons t-new acc))))))))))))

(define (owl-transitive-closure triples)
  (let ((trans (rdf-query triples '? "rdf:type" "owl:TransitiveProperty")))
    (if (null? trans)
        '()
        (let ((p (car (car trans))))
          (transitive-chain triples p)))))

(define (transitive-chain triples p)
  (let ((edges (map (lambda (t) (list (car t) (caddr t)))
                    (rdf-query triples '? p '?))))
    (let collect ((new '()) (seen '()))
      (if (null? edges)
          new
          (let* ((a (caar edges))
                 (b (cadar edges))
                 (next (rdf-query triples b p '?)))
            (let rec ((n next) (acc new))
              (cond
                ((null? n) (collect acc (cons (list a b) seen)))
                ((member (list a (caddr (car n))) seen) (rec (cdr n) acc))
                (else
                 (rec (cdr n)
                      (cons (list a p (caddr (car n))) acc))))))))))

(define (owl-symmetric-closure triples)
  (let ((sym (rdf-query triples '? "rdf:type" "owl:SymmetricProperty")))
    (let collect ((new '()))
      (if (null? sym)
          new
          (let* ((p (car (car sym)))
                 (t (rdf-query triples '? p '?)))
            (let rec ((ts t) (acc new))
              (cond
                ((null? ts) (collect acc))
                (else
                 (let ((rev (list (caddr (car ts)) p (car (car ts)))))
                   (rec (cdr ts)
                        (if (member rev triples) acc (cons rev acc))))))))))))

(define (owl-functional-closure triples)
  (let ((func (rdf-query triples '? "rdf:type" "owl:FunctionalProperty")))
    (let collect ((new '()))
      (if (null? func)
          new
          (let* ((p (car (car func)))
                 (groups (group-by-subject (rdf-query triples '? p '?))))
            (let rec ((g groups) (acc new))
              (cond
                ((null? g) (collect acc))
                ((> (length (cdar g)) 1)
                 (let* ((vals (map caddr (cdar g)))
                        (common (car vals)))
                   (let valrec ((vs (cdr vals)) (a acc))
                     (if (null? vs)
                         (rec (cdr g) a)
                         (valrec (cdr vs)
                                 (cons (list (caar g) p common) a))))))
                (else (rec (cdr g) acc)))))))))

(define (owl-inv-functional-closure triples)
  (let ((invfunc (rdf-query triples '? "rdf:type" "owl:InverseFunctionalProperty")))
    (let collect ((new '()))
      (if (null? invfunc)
          new
          (let* ((p (car (car invfunc)))
                 (groups (group-by-object (rdf-query triples '? p '?))))
            (let rec ((g groups) (acc new))
              (cond
                ((null? g) (collect acc))
                ((> (length (cdar g)) 1)
                 (let* ((subs (map car (cdar g)))
                        (common (car subs)))
                   (let subrec ((ss (cdr subs)) (a acc))
                     (if (null? ss)
                         (rec (cdr g) a)
                         (subrec (cdr ss)
                                 (cons (list common p (caddr (car (cdar g)))) a)))))
                (else (rec (cdr g) acc)))))))))

(define (group-by-subject triples)
  (let collect ((result '()) (t triples))
    (if (null? t)
        result
        (let* ((s (caar t))
               (existing (assoc s result)))
          (collect
           (if existing
               (cons (cons s (cons (car t) (cdr existing)))
                     (remq existing result))
               (cons (list s (car t)) result))
           (cdr t))))))

(define (group-by-object triples)
  (let collect ((result '()) (t triples))
    (if (null? t)
        result
        (let* ((o (caddar t))
               (existing (assoc o result)))
          (collect
           (if existing
               (cons (cons o (cons (car t) (cdr existing)))
                     (remq existing result))
               (cons (list o (car t)) result))
           (cdr t))))))

(define (remq item lst)
  (filter (lambda (x) (not (eq? x item))) lst))

;; =============================================================================
;; MODULE 5: SHACL VALIDATION
;; =============================================================================
;; Shape loading, constraint validation, validation reporting
;; Source: 07-Grok.md
;; Already pure: shacl-validate takes shapes and triples

;; Load SHACL shapes from canvas facts (pure)
(define (load-shacl-shapes facts)
  (let ((shapes '())
        (nodes (query-facts facts '(node ?id text ?x ?y ?text))))
    ;; Node shapes from vertical inheritance depth
    (for-each (lambda (node)
                (let ((id (cadr node))
                      (depth (inheritance-depth facts id)))
                  (set! shapes (cons (cons id `((sh:nodeKind sh:IRI)
                                                (sh:minCount 1)
                                                (sh:maxCount 1)
                                                (sh:datatype xsd:integer (depth . ,depth)))) shapes))))
              nodes)
    ;; Property shapes from horizontal edges
    (let ((hedges (query-facts facts '(horizontal ?id ?from ?to))))
      (for-each (lambda (h)
                  (let* ((from (caddr h))
                         (to (cadddr h))
                         (id (cadr h)))
                    (set! shapes (cons (cons (string-append "canvas:" from)
                                           `((sh:property
                                              (sh:path canvas:implements)
                                              (sh:minCount 1)
                                              (sh:maxCount 1)
                                              (sh:nodeKind sh:IRI)
                                              (sh:hasValue ,(string-append "canvas:" to))))) shapes))))
                hedges))
    (reverse shapes)))

(define (inheritance-depth facts node)
  (let count ((n node) (d 0))
    (let ((parents (map caddr (query-facts facts `(vertical ?id ?p ,n)))))
      (if (null? parents)
          d
          (apply max (map (lambda (p) (+ 1 (count p d))) parents))))))

;; SHACL validation (pure - takes shapes and triples)
(define (shacl-validate shapes triples)
  (let ((report '()))
    (for-each (lambda (shape)
                (let ((target (car shape))
                      (constraints (cdr shape)))
                  (set! report (append report (validate-target target constraints triples)))))
              shapes)
    (if (null? report)
        '(sh:conforms true)
        `(sh:conforms false (sh:result ,@report)))))

(define (validate-target target constraints triples)
  (let ((focus (resolve-target target triples)))
    (if (null? focus)
        `((sh:result
           (sh:resultSeverity sh:Violation)
           (sh:sourceConstraintComponent sh:Target)
           (sh:focusNode ,target)
           (sh:resultMessage "No focus node found")))
        (let collect ((results '()) (c constraints) (f focus))
          (if (null? c)
              results
              (collect (append results (validate-constraint (car c) f triples))
                       (cdr c) f))))))

(define (resolve-target target triples)
  (cond
    ((string-prefix? "canvas:" target)
     (list target))
    ((not (null? (rdf-query triples target "rdf:type" '?)))
     (map car (rdf-query triples target "rdf:type" '?)))
    (else '())))

(define (validate-constraint constraint focus triples)
  (let ((type (car constraint)))
    (cond
      ((eq? type 'sh:nodeKind)
       (if (not (valid-node-kind? focus (cadr constraint)))
           (violation focus "Invalid node kind" constraint)
           '()))
      ((eq? type 'sh:minCount)
       (let ((path (cadar (cdr constraint)))
             (count (length (rdf-query triples focus path '?))))
         (if (< count (cadr constraint))
             (violation focus (string-append "Min count violation: " (number->string count)) constraint)
             '())))
      ((eq? type 'sh:maxCount)
       (let ((path (cadar (cdr constraint)))
             (count (length (rdf-query triples focus path '?))))
         (if (> count (cadr constraint))
             (violation focus (string-append "Max count violation: " (number->string count)) constraint)
             '())))
      ((eq? type 'sh:hasValue)
       (let ((path (cadar (cdr constraint)))
             (value (cadr constraint)))
         (if (null? (rdf-query triples focus path value))
             (violation focus "Missing required value" constraint)
             '())))
      (else '()))))

(define (valid-node-kind? node kind)
  (case kind
    ((sh:IRI) (string-prefix? "canvas:" node))
    ((sh:Literal) (not (string-prefix? "canvas:" node)))
    (else #t)))

(define (violation focus message constraint)
  `((sh:result
     (sh:resultSeverity sh:Violation)
     (sh:sourceConstraintComponent ,(car constraint))
     (sh:focusNode ,focus)
     (sh:resultMessage ,message))))

;; =============================================================================
;; MODULE 6: LOGIC PROGRAMMING
;; =============================================================================
;; Prolog engine, Datalog engine, unification & resolution
;; Source: 08-Grok.md, 10-Grok.md
;; Converted to pure: prolog-query and datalog-query take DB and goal

;; Unification (pure)
(define (unify x y bindings)
  (cond
    ((eq? x y) bindings)
    ((variable? x) (bind x y bindings))
    ((variable? y) (bind y x bindings))
    ((and (pair? x) (pair? y))
     (let ((b1 (unify (car x) (car y) bindings)))
       (and b1 (unify (cdr x) (cdr y) b1))))
    ((equal? x y) bindings)
    (else #f)))

(define (bind var val bindings)
  (let ((existing (assoc var bindings)))
    (if existing
        (unify (cdr existing) val bindings)
        (cons (cons var val) bindings))))

(define (subst bindings term)
  (cond
    ((variable? term)
     (let ((b (assoc term bindings)))
       (if b (subst bindings (cdr b)) term)))
    ((pair? term)
     (cons (subst bindings (car term))
           (subst bindings (cdr term))))
    (else term)))

;; Prolog query (pure - takes database and goal)
(define (prolog-query db goal)
  (let search ((clauses db) (bindings '()) (proof '()))
    (if (null? clauses)
        (if (null? bindings) '() (list (cons bindings proof)))
        (let* ((clause (car clauses))
               (head (car clause))
               (body (cdr clause))
               (unified (unify goal head '())))
          (if unified
              (let ((new-goal (map (lambda (g) (subst unified g)) body)))
                (if (null? new-goal)
                    (search (cdr clauses) unified (cons clause proof))
                    (append
                     (search db unified (cons clause proof))
                     (search (cdr clauses) bindings proof))))
              (search (cdr clauses) bindings proof))))))

;; Datalog query (pure - takes program and goal)
(define (datalog-query program goal)
  (let ((evaluated (evaluate-program program)))
    (immediate-query evaluated goal '())))

(define (evaluate-program program)
  (let ((strata (stratify-program program)))
    (let loop ((current '()) (s strata))
      (if (null? s)
          current
          (let ((new (evaluate-stratum (car s) program current)))
            (loop (append current new) (cdr s)))))))

(define (stratify-program program)
  (let ((graph '()))
    (for-each (lambda (clause)
                (let ((head-pred (caar clause)))
                  (for-each (lambda (lit)
                              (let ((p (if (eq? (car lit) 'not)
                                           (caadr lit)
                                           (car lit))))
                                (when (and (not (builtin? p))
                                           (or (eq? (car lit) 'not)
                                               (not (eq? p head-pred))))
                                  (set! graph (cons (list head-pred p (eq? (car lit) 'not)) graph)))))
                            (cdr clause))))
              program)
    (topological-sort graph)))

(define (builtin? p)
  (memq p '(> < >= <= = != + length bagof count not)))

(define (topological-sort graph)
  (let ((visited '())
        (order '()))
    (let visit ((node (if (null? graph) '() (caar graph))))
      (unless (or (null? node) (member node visited))
        (set! visited (cons node visited))
        (for-each (lambda (edge)
                    (when (not (caddr edge)) ; only positive dependencies
                      (visit (cadr edge))))
                  (filter (lambda (e) (eq? (car e) node)) graph))
        (set! order (cons node order))))
    (reverse order)))

(define (evaluate-stratum stratum program known)
  (let ((rules (filter (lambda (c) (eq? (caar c) stratum)) program))
        (new-facts '()))
    (let loop ()
      (let ((delta (compute-delta stratum rules known new-facts)))
        (if (null? delta)
            new-facts
            (begin
              (set! new-facts (append new-facts delta))
              (loop)))))))

(define (compute-delta pred rules known new)
  (let ((result '()))
    (for-each (lambda (rule)
                (let ((head (car rule))
                      (body (cdr rule)))
                  (let ((bindings (join-body body known new '())))
                    (for-each (lambda (b)
                                (let ((inst (subst b head)))
                                  (unless (or (member inst known)
                                              (member inst new)
                                              (member inst result))
                                    (set! result (cons inst result)))))
                              bindings))))
              rules)
    result))

(define (join-body body known new bindings)
  (if (null? body)
      (list bindings)
      (let* ((lit (car body))
             (positive (not (eq? (car lit) 'not)))
             (goal (if positive lit (cadr lit)))
             (candidates (if positive
                             (append known new)
                             (negation-as-failure goal known new))))
        (let collect ((results '()) (c candidates))
          (if (null? c)
              results
              (let ((unified (unify goal (car c) bindings)))
                (if unified
                    (append (join-body (cdr body) known new unified)
                            results)
                    (collect results (cdr c)))))))))

(define (negation-as-failure goal known new)
  (if (null? (join-body (list goal) known new '()))
      (list goal)
      '()))

(define (immediate-query facts goal bindings)
  (filter (lambda (fact)
            (let ((unified (unify goal fact bindings)))
              (and unified (not (null? unified)))))
          facts))

;; =============================================================================
;; MODULE 7: SPARQL ENGINE
;; =============================================================================
;; SPARQL parser, query execution, HTTP endpoint
;; Source: 14-Grok.md
;; Converted to pure: sparql-query takes query string and triples

;; SPARQL query (pure - takes query string and triples)
(define (sparql-query query-str triples)
  (let ((parsed (parse-sparql query-str)))
    (cond
      ((eq? parsed 'error) `(error "Invalid SPARQL syntax"))
      (else (execute-query parsed triples)))))

(define (parse-sparql str)
  (with-input-from-string str
    (lambda ()
      (let ((tokens (tokenize (read-all-chars))))
        (parse-select tokens)))))

(define (execute-query parsed triples)
  (let ((proj (cadr (assoc 'project parsed)))
        (where (cadr (assoc 'where parsed)))
        (filters (cadr (assoc 'filter parsed)))
        (optionals (cadr (assoc 'optional parsed))))
    (let* ((bgp-results (execute-bgp where triples))
           (filtered (apply-filters bgp-results filters))
           (with-opt (apply-optionals filtered optionals triples)))
      `(results ,proj ,with-opt))))

(define (tokenize chars)
  (let loop ((cs chars) (tokens '()) (buf '()) (in-str #f))
    (if (null? cs)
        (reverse (if (null? buf) tokens (cons (list->string (reverse buf)) tokens)))
        (let ((c (car cs)))
          (cond
            (in-str
             (if (char=? c #\")
                 (loop (cdr cs) (cons (list->string (reverse (cons c buf))) tokens) '() #f)
                 (loop (cdr cs) tokens (cons c buf) #t)))
            ((char=? c #\")
             (loop (cdr cs) tokens (cons c buf) #t))
            ((char-whitespace? c)
             (loop (cdr cs)
                   (if (null? buf) tokens (cons (list->string (reverse buf)) tokens))
                   '() #f))
            ((memq c '(#\{ #\} #\( #\) #\. #\, #\;))
             (loop (cdr cs)
                   (cons (string c)
                         (if (null? buf) tokens (cons (list->string (reverse buf)) tokens)))
                   '() #f))
            (else
             (loop (cdr cs) tokens (cons c buf) #f)))))))

(define (parse-select tokens)
  (cond
    ((null? tokens) 'error)
    ((string=? (car tokens) "SELECT")
     (let* ((proj (parse-projection (cdr tokens)))
            (rest (cadr proj))
            (where (parse-where rest)))
       `(select (project ,(car proj))
                (where ,(cadr where))
                (filter ,(caddr where))
                (optional ,(cadddr where)))))
    (else 'error)))

(define (parse-projection tokens)
  (let loop ((t tokens) (vars '()))
    (cond
      ((null? t) (list (reverse vars) t))
      ((string=? (car t) "WHERE") (list (reverse vars) t))
      ((string-prefix? "?" (car t)) (loop (cdr t) (cons (car t) vars)))
      (else (loop (cdr t) vars)))))

(define (parse-where tokens)
  (if (and (pair? tokens) (string=? (car tokens) "WHERE"))
      (parse-graph-pattern (cddr tokens) '() '() '())
      'error))

(define (parse-graph-pattern tokens bgp filters optionals)
  (cond
    ((null? tokens) (list bgp filters optionals tokens))
    ((string=? (car tokens) "FILTER") 
     (let ((f (parse-filter (cdr tokens))))
       (parse-graph-pattern (caddr f) bgp (cons (car f) filters) optionals)))
    ((string=? (car tokens) "OPTIONAL")
     (let ((o (parse-optional (cdr tokens))))
       (parse-graph-pattern (cadddr o) bgp filters (cons (car o) optionals))))
    ((string=? (car tokens) "}") (list bgp filters optionals (cdr tokens)))
    (else
     (let ((tp (parse-triple-pattern tokens)))
       (parse-graph-pattern (caddr tp)
                            (cons (car tp) bgp)
                            filters
                            optionals)))))

(define (parse-triple-pattern tokens)
  (let ((s (parse-term (car tokens)))
        (p (parse-term (cadr tokens)))
        (o (parse-term (caddr tokens))))
    (list `(,s ,p ,o) (cddddr tokens))))

(define (parse-term token)
  (cond
    ((string-prefix? "?" token) (string->symbol token))
    ((string-prefix? "canvas:" token) token)
    ((char=? (string-ref token 0) #\") token)
    (else token)))

(define (parse-filter tokens)
  (let ((expr (parse-expression tokens)))
    (list (car expr) '() (cddr expr))))

(define (parse-optional tokens)
  (let ((pat (parse-graph-pattern (cdr tokens) '() '() '())))
    (list (car pat) (cadddr pat))))

(define (parse-expression tokens)
  (if (null? tokens)
      (list '() tokens)
      (let ((op (car tokens))
            (arg1 (cadr tokens))
            (arg2 (caddr tokens)))
        (list `(,op ,arg1 ,arg2) (cddddr tokens)))))

(define (execute-bgp patterns triples)
  (let loop ((p patterns) (results (list '())))
    (if (null? p)
        results
        (let ((tp (car p)))
          (loop (cdr p)
                (join-triple-pattern tp results triples))))))

(define (join-triple-pattern tp current triples)
  (let ((s (car tp)) (p (cadr tp)) (o (caddr tp)))
    (let collect ((matches '()) (t triples))
      (if (null? t)
          (apply append
                 (map (lambda (binding)
                        (let ((s-val (var-lookup s binding))
                              (p-val (var-lookup p binding))
                              (o-val (var-lookup o binding)))
                          (if (and (or (variable? s) (equal? s (car (car t))))
                                   (or (variable? p) (equal? p (cadr (car t))))
                                   (or (variable? o) (equal? o (caddr (car t)))))
                              (list (bind-pattern s (car (car t))
                                        (bind-pattern p (cadr (car t))
                                          (bind-pattern o (caddr (car t)) binding))))
                              '())))
                      current))
          (collect (cons (car t) matches) (cdr t))))))

(define (var-lookup var binding)
  (cond
    ((not (variable? var)) var)
    ((assoc var binding) => cdr)
    (else var)))

(define (bind-pattern var val binding)
  (if (variable? var)
      (cons (cons var val) (remq (assoc var binding) binding))
      binding))

(define (apply-filters results filters)
  (filter (lambda (binding)
            (andmap (lambda (f) (eval-filter f binding)) filters))
          results))

(define (eval-filter filter binding)
  (let ((op (car filter))
        (args (cdr filter)))
    (case op
      ((=) (equal? (eval-expr (car args) binding)
                   (eval-expr (cadr args) binding)))
      ((>) (> (eval-expr (car args) binding)
              (eval-expr (cadr args) binding)))
      (else #t))))

(define (eval-expr expr binding)
  (if (variable? expr)
      (var-lookup expr binding)
      expr))

(define (apply-optionals results optionals triples)
  (if (null? optionals)
      results
      (let ((opt-bgp (car optionals)))
        (map (lambda (res)
               (let ((opt-matches (execute-bgp opt-bgp triples)))
                 (if (null? opt-matches)
                     res
                     (left-join res opt-matches))))
             results))))

(define (left-join base opt)
  (if (null? opt)
      base
      (append base opt)))

;; =============================================================================
;; MODULE 8: NLP & M/S-EXPRESSIONS
;; =============================================================================
;; M/S mapping, pattern matching, NLP parsing
;; Source: 04-Grok.md
;; Already pure: m->s, s->m, nlp-eval

;; M-expression to S-expression (pure)
(define (m->s expr mappings)
  (rewrite expr mappings))

;; S-expression to M-expression (pure)
(define (s->m expr mappings)
  (rewrite expr mappings))

(define (rewrite expr rules)
  (cond
    ((null? rules) expr)
    ((match (caar rules) expr '())
     => (lambda (bindings)
          (instantiate (cdar rules) bindings)))
    (else (rewrite expr (cdr rules)))))

(define (match pat expr bindings)
  (cond
    ((variable? pat)
     (let ((b (assoc pat bindings)))
       (if b
           (and (equal? (cdr b) expr) bindings)
           (cons (cons pat expr) bindings))))
    ((and (pair? pat) (pair? expr))
     (and (match (car pat) (car expr) bindings)
          (match (cdr pat) (cdr expr) bindings)))
    ((equal? pat expr) bindings)
    (else #f)))

(define (instantiate template bindings)
  (cond
    ((variable? template)
     (let ((b (assoc template bindings)))
       (if b (cdr b) template)))
    ((pair? template)
     (cons (instantiate (car template) bindings)
           (instantiate (cdr template) bindings)))
    (else template)))

;; NLP parsing (pure)
(define (nlp-parse query-str)
  (let ((tokens (string-split query-str #\space)))
    (cond
      ((member "point" tokens) `(topology ,(cadr tokens)))
      ((member "time" tokens) `(time ,(cadr tokens)))
      ((member "pair" tokens) `(pair ,(cadr tokens) ,(caddr tokens)))
      ((member "pattern" tokens) `(pattern ,(cadr tokens)))
      (else `(unknown ,query-str)))))

(define (nlp-eval query-str mappings)
  (let* ((m (nlp-parse query-str))
         (s (m->s m mappings)))
    `(m ,m s ,s)))

;; =============================================================================
;; MODULE 9: QUANTUM & AI
;; =============================================================================
;; Attention mechanism, quantum circuits, qubit operations
;; Source: 22-Grok.md, 24-Grok.md
;; Already pure: attention, qubit, apply-gate

;; Attention mechanism (pure function)
(define (attention Q K V)
  (let* ((scores (mat-mul Q (transpose K)))
         (weights (softmax scores))
         (output (mat-mul weights V)))
    output))

(define (mat-mul A B)
  (map (lambda (row)
         (map (lambda (col)
                (sum (map * row col)))
              (transpose B)))
       A))

(define (transpose M)
  (apply map list M))

(define (softmax scores)
  (let* ((exp-scores (map exp scores))
         (sum-exp (sum exp-scores)))
    (map (lambda (e) (/ e sum-exp)) exp-scores)))

(define (sum lst)
  (fold + 0 lst))

;; Quantum operations (pure)
(define (qubit alpha beta)
  (cons alpha beta))

(define (apply-gate state gate)
  (mat-vec-mul gate state))

(define (mat-vec-mul M v)
  (map (lambda (row)
         (complex-sum (map complex-mul row v)))
       M))

(define (complex-mul a b)
  (let ((ar (real-part a)) (ai (imag-part a))
        (br (real-part b)) (bi (imag-part b)))
    (make-rectangular (- (* ar br) (* ai bi))
                      (+ (* ar bi) (* ai br)))))

(define (complex-sum lst)
  (fold (lambda (a b) (make-rectangular (+ (real-part a) (real-part b))
                                        (+ (imag-part a) (imag-part b))))
        0.0+0.0i lst))

;; =============================================================================
;; MODULE 10: REPL & INTERACTIVE
;; =============================================================================
;; REPL interface, command dispatch, demo functions
;; Source: 13-Grok.md
;; Keep REPL as stateful wrapper, extract pure command handlers

;; Pure command handlers
(define (handle-query-command query-str facts triples)
  (let ((parsed (read-from-string query-str)))
    (cond
      ((eq? parsed 'triples) (list triples))
      ((eq? parsed 'inherits) (query-inherits facts))
      ((eq? parsed 'implements) (query-implements facts))
      (else '()))))

(define (query-inherits facts)
  (query-facts facts '(inherits ?x ?y)))

(define (query-implements facts)
  (query-facts facts '(implements ?x ?y)))

;; =============================================================================
;; MODULE 11: PUBLIC API & FUNCTION REGISTRY
;; =============================================================================
;; Function registry for JSONL reference, export all pure functions
;; JSONL invocation interface

;; Function registry
(define *function-registry*
  `((r5rs:church-zero . ,church-zero)
    (r5rs:church-one . ,church-one)
    (r5rs:church-succ . ,church-succ)
    (r5rs:church-add . ,church-add)
    (r5rs:church-mult . ,church-mult)
    (r5rs:church-exp . ,church-exp)
    (r5rs:parse-jsonl-canvas . ,parse-jsonl-canvas)
    (r5rs:extract-facts . ,extract-facts)
    (r5rs:query-facts . ,query-facts)
    (r5rs:jsonl-to-rdf . ,jsonl-to-rdf)
    (r5rs:rdf-query . ,rdf-query)
    (r5rs:rdfs-entail . ,rdfs-entail)
    (r5rs:owl-entail . ,owl-entail)
    (r5rs:load-shacl-shapes . ,load-shacl-shapes)
    (r5rs:shacl-validate . ,shacl-validate)
    (r5rs:prolog-query . ,prolog-query)
    (r5rs:datalog-query . ,datalog-query)
    (r5rs:sparql-query . ,sparql-query)
    (r5rs:m->s . ,m->s)
    (r5rs:s->m . ,s->m)
    (r5rs:nlp-eval . ,nlp-eval)
    (r5rs:attention . ,attention)
    (r5rs:qubit . ,qubit)
    (r5rs:apply-gate . ,apply-gate)))

;; JSONL invocation interface
(define (invoke-from-jsonl func-name args context)
  ;; context = {facts, triples, prolog-db, datalog-db, ...}
  (let ((func (assoc func-name *function-registry*)))
    (if func
        (apply (cdr func) (append args (list context)))
        (error "Function not found" func-name))))

;; Helper function to get context value
(define (get-context context key)
  (let ((pair (assoc key context)))
    (if pair (cdr pair) '())))

;; =============================================================================
;; UTILITY FUNCTIONS (for R5RS compatibility)
;; =============================================================================

(define (read-line)
  (let loop ((chars '()))
    (let ((c (read-char)))
      (cond
        ((eof-object? c) (eof-object))
        ((char=? c #\newline) (list->string (reverse chars)))
        (else (loop (cons c chars)))))))

(define (read-all-chars)
  (let loop ((chars '()))
    (let ((c (read-char)))
      (if (eof-object? c)
          (reverse chars)
          (loop (cons c chars))))))

(define (string-split str char)
  (let loop ((chars (string->list str)) (current '()) (result '()))
    (cond
      ((null? chars) (reverse (cons (list->string (reverse current)) result)))
      ((char=? (car chars) char)
       (loop (cdr chars) '() (cons (list->string (reverse current)) result)))
      (else (loop (cdr chars) (cons (car chars) current) result)))))

(define (read-from-string str)
  (with-input-from-string str read))

(define (with-input-from-string str proc)
  (let ((port (open-input-string str)))
    (let ((result (proc)))
      (close-input-port port)
      result)))

(define (open-input-string str)
  (cons str 0))

(define (close-input-port port) #t)

(define (char-whitespace? c)
  (memq c '(#\space #\tab #\newline #\return)))

;; =============================================================================
;; END OF UNIFIED R5RS CANVAS ENGINE
;; =============================================================================
