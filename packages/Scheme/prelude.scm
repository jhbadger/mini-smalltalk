;;; The Scheme prelude: the derived forms (as syntax-rules macros) and the library procedures that take procedures.
;;; It is read once, when the first interpreter is made, and every new interpreter starts with its definitions.

;;; ---- derived forms ----

(define-syntax cond
  (syntax-rules (else =>)
    ((_ (else e1 e2 ...)) (begin e1 e2 ...))
    ((_ (test => f) clause ...) (let ((t test)) (if t (f t) (cond clause ...))))
    ((_ (test) clause ...) (let ((t test)) (if t t (cond clause ...))))
    ((_ (test e1 e2 ...) clause ...) (if test (begin e1 e2 ...) (cond clause ...)))
    ((_) (if #f #f))))

(define-syntax case
  (syntax-rules (else =>)
    ((_ (key ...) clauses ...) (let ((atom-key (key ...))) (case atom-key clauses ...)))
    ((_ key (else => result)) (result key))
    ((_ key (else result1 result2 ...)) (begin result1 result2 ...))
    ((_ key ((atoms ...) result1 result2 ...)) (if (memv key '(atoms ...)) (begin result1 result2 ...)))
    ((_ key ((atoms ...) => result)) (if (memv key '(atoms ...)) (result key)))
    ((_ key ((atoms ...) => result) clause clauses ...)
     (if (memv key '(atoms ...)) (result key) (case key clause clauses ...)))
    ((_ key ((atoms ...) result1 result2 ...) clause clauses ...)
     (if (memv key '(atoms ...)) (begin result1 result2 ...) (case key clause clauses ...)))))

(define-syntax when
  (syntax-rules () ((_ test e1 e2 ...) (if test (begin e1 e2 ...)))))

(define-syntax unless
  (syntax-rules () ((_ test e1 e2 ...) (if test (if #f #f) (begin e1 e2 ...)))))

(define-syntax let*
  (syntax-rules ()
    ((_ () body1 body2 ...) (let () body1 body2 ...))
    ((_ ((name val) rest ...) body1 body2 ...) (let ((name val)) (let* (rest ...) body1 body2 ...)))))

(define-syntax do
  (syntax-rules ()
    ((_ ((var init step ...) ...) (test expr ...) command ...)
     (let loop ((var init) ...)
       (if test
           (begin (if #f #f) expr ...)
           (begin command ... (loop (%do-step var step ...) ...)))))))

(define-syntax %do-step
  (syntax-rules () ((_ x) x) ((_ x y) y)))

(define-syntax let-values
  (syntax-rules ()
    ((_ () body1 body2 ...) (let () body1 body2 ...))
    ((_ ((formals expr) rest ...) body1 body2 ...)
     (call-with-values (lambda () expr) (lambda formals (let-values (rest ...) body1 body2 ...))))))

(define-syntax let*-values
  (syntax-rules ()
    ((_ bindings body1 body2 ...) (let-values bindings body1 body2 ...))))

(define-syntax receive
  (syntax-rules ()
    ((_ formals expr body1 body2 ...) (call-with-values (lambda () expr) (lambda formals body1 body2 ...)))))

(define-syntax define-values
  (syntax-rules ()
    ((_ (var ...) expr)
     (begin (define var #f) ...
            (%set-values! (lambda () expr) (list (lambda (v) (set! var v)) ...))))))

(define (%set-values! thunk setters)
  (call-with-values thunk
    (lambda vals (for-each (lambda (setter v) (setter v)) setters vals))))

(define-syntax parameterize
  (syntax-rules ()
    ((_ ((p v) ...) body1 body2 ...)
     (%parameterize (list (cons p v) ...) (lambda () body1 body2 ...)))))

(define-syntax fluid-let
  (syntax-rules ()
    ((_ ((var val) ...) body1 body2 ...)
     (%fluid-let (list (cons (lambda () var) (lambda (x) (set! var x))) ...)
                 (list val ...)
                 (lambda () body1 body2 ...)))))

(define-syntax assert-equal
  (syntax-rules ()
    ((_ expected expr)
     (let ((v expr))
       (if (not (equal? v expected))
           (error "Assertion failed: wrong value" 'expr v expected))))))

;;; ---- parameters and fluid-let ----

(define (make-parameter value . conv)
  (let ((converter (if (pair? conv) (car conv) (lambda (x) x))))
    (%make-parameter (converter value) converter)))

(define make-settable-parameter make-parameter)
(define make-unsettable-parameter make-parameter)

(define (%parameterize bindings thunk)
  (let ((params (map car bindings))
        (vals (map (lambda (b) ((%parameter-converter (car b)) (cdr b))) bindings))
        (olds '()))
    (dynamic-wind
      (lambda () (set! olds (map %parameter-value params)) (for-each %parameter-set! params vals))
      thunk
      (lambda () (for-each %parameter-set! params olds)))))

(define (%fluid-let accessors new-values thunk)
  (let ((olds '()))
    (dynamic-wind
      (lambda ()
        (set! olds (map (lambda (a) ((car a))) accessors))
        (for-each (lambda (a v) ((cdr a) v)) accessors new-values))
      thunk
      (lambda ()
        (set! new-values (map (lambda (a) ((car a))) accessors))
        (for-each (lambda (a v) ((cdr a) v)) accessors olds)))))

;;; ---- lists ----

(define (%all-pairs? ls)
  (cond ((null? ls) #t)
        ((pair? (car ls)) (%all-pairs? (cdr ls)))
        (else #f)))

(define (%cars ls) (if (null? ls) '() (cons (car (car ls)) (%cars (cdr ls)))))
(define (%cdrs ls) (if (null? ls) '() (cons (cdr (car ls)) (%cdrs (cdr ls)))))

(define (map f l . ls)
  (if (null? ls)
      (let loop ((l l) (acc '()))
        (if (pair? l)
            (loop (cdr l) (cons (f (car l)) acc))
            (reverse acc)))
      (let loop ((ls (cons l ls)) (acc '()))
        (if (%all-pairs? ls)
            (loop (%cdrs ls) (cons (apply f (%cars ls)) acc))
            (reverse acc)))))

(define (for-each f l . ls)
  (if (null? ls)
      (let loop ((l l))
        (if (pair? l)
            (begin (f (car l)) (loop (cdr l)))))
      (let loop ((ls (cons l ls)))
        (if (%all-pairs? ls)
            (begin (apply f (%cars ls)) (loop (%cdrs ls)))))))

(define (append-map f l . ls) (apply append (apply map f l ls)))

(define (filter-map f l . ls)
  (let loop ((r (apply map f l ls)) (acc '()))
    (cond ((null? r) (reverse acc))
          ((car r) (loop (cdr r) (cons (car r) acc)))
          (else (loop (cdr r) acc)))))

(define (vector-map f v . vs) (list->vector (apply map f (vector->list v) (map vector->list vs))))
(define (vector-for-each f v . vs) (apply for-each f (vector->list v) (map vector->list vs)))
(define (string-for-each f s . ss) (apply for-each f (string->list s) (map string->list ss)))
(define (string-map f s . ss) (list->string (apply map f (string->list s) (map string->list ss))))

(define (vector-fill-range! v start end x)
  (do ((i start (+ i 1))) ((>= i end)) (vector-set! v i x)))

(define (make-initialized-vector n f)
  (let ((v (make-vector n)))
    (do ((i 0 (+ i 1))) ((= i n) v) (vector-set! v i (f i)))))
(define vector-tabulate (lambda (f n) (make-initialized-vector n f)))

(define (make-initialized-list n f)
  (let loop ((i (- n 1)) (acc '()))
    (if (< i 0) acc (loop (- i 1) (cons (f i) acc)))))
(define (list-tabulate n f) (make-initialized-list n f))

(define (vector-count pred v)
  (let loop ((i 0) (n 0))
    (if (= i (vector-length v)) n (loop (+ i 1) (if (pred (vector-ref v i)) (+ n 1) n)))))

(define (vector-binary-search v key key-compare)
  (let loop ((lo 0) (hi (- (vector-length v) 1)))
    (if (> lo hi)
        #f
        (let* ((mid (quotient (+ lo hi) 2))
               (c (key-compare key (vector-ref v mid))))
          (cond ((= c 0) (vector-ref v mid))
                ((< c 0) (loop lo (- mid 1)))
                (else (loop (+ mid 1) hi)))))))

(define (filter pred l)
  (let loop ((l l) (acc '()))
    (cond ((null? l) (reverse acc))
          ((pred (car l)) (loop (cdr l) (cons (car l) acc)))
          (else (loop (cdr l) acc)))))

(define (remove pred l) (filter (lambda (x) (not (pred x))) l))

(define (partition pred l)
  (let loop ((l l) (in '()) (out '()))
    (cond ((null? l) (values (reverse in) (reverse out)))
          ((pred (car l)) (loop (cdr l) (cons (car l) in) out))
          (else (loop (cdr l) in (cons (car l) out))))))

(define (reduce f initial l)
  (if (null? l)
      initial
      (let loop ((acc (car l)) (l (cdr l)))
        (if (null? l) acc (loop (f (car l) acc) (cdr l))))))

(define (reduce-left f initial l)
  (if (null? l)
      initial
      (let loop ((acc (car l)) (l (cdr l)))
        (if (null? l) acc (loop (f acc (car l)) (cdr l))))))

(define (reduce-right f initial l)
  (cond ((null? l) initial)
        ((null? (cdr l)) (car l))
        (else (f (car l) (reduce-right f initial (cdr l))))))

(define (fold-left f init l . ls)
  (if (null? ls)
      (let loop ((acc init) (l l))
        (if (null? l) acc (loop (f acc (car l)) (cdr l))))
      (let loop ((acc init) (ls (cons l ls)))
        (if (%all-pairs? ls)
            (loop (apply f acc (%cars ls)) (%cdrs ls))
            acc))))

(define (fold-right f init l . ls)
  (if (null? ls)
      (let loop ((l (reverse l)) (acc init))
        (if (null? l) acc (loop (cdr l) (f (car l) acc))))
      (let loop ((ls (map reverse (cons l ls))) (acc init))
        (if (%all-pairs? ls)
            (loop (%cdrs ls) (apply f (append (%cars ls) (list acc))))
            acc))))

(define (fold f init l . ls)
  (if (null? ls)
      (let loop ((acc init) (l l))
        (if (null? l) acc (loop (f (car l) acc) (cdr l))))
      (let loop ((acc init) (ls (cons l ls)))
        (if (%all-pairs? ls)
            (loop (apply f (append (%cars ls) (list acc))) (%cdrs ls))
            acc))))

(define (delete-duplicates l . eq)
  (let ((same? (if (pair? eq) (car eq) equal?)))
    (let loop ((l l) (acc '()))
      (cond ((null? l) (reverse acc))
            ((let seen ((a acc)) (cond ((null? a) #f) ((same? (car a) (car l)) #t) (else (seen (cdr a)))))
             (loop (cdr l) acc))
            (else (loop (cdr l) (cons (car l) acc)))))))

(define (member x l . eq)
  (if (null? eq)
      (%member x l)
      (let loop ((l l))
        (cond ((null? l) #f)
              (((car eq) x (car l)) l)
              (else (loop (cdr l)))))))

(define (assoc x l . eq)
  (if (null? eq)
      (%assoc x l)
      (let loop ((l l))
        (cond ((null? l) #f)
              (((car eq) x (car (car l))) (car l))
              (else (loop (cdr l)))))))

(define (find pred l)
  (let loop ((l l))
    (cond ((null? l) #f) ((pred (car l)) (car l)) (else (loop (cdr l))))))

(define (find-tail pred l)
  (let loop ((l l))
    (cond ((null? l) #f) ((pred (car l)) l) (else (loop (cdr l))))))

(define (list-index pred l)
  (let loop ((l l) (i 0))
    (cond ((null? l) #f) ((pred (car l)) i) (else (loop (cdr l) (+ i 1))))))

(define (any pred l . ls)
  (if (null? ls)
      (let loop ((l l))
        (cond ((null? l) #f)
              ((null? (cdr l)) (pred (car l)))
              ((pred (car l)) => (lambda (x) x))
              (else (loop (cdr l)))))
      (let loop ((ls (cons l ls)))
        (if (%all-pairs? ls)
            (or (apply pred (%cars ls)) (loop (%cdrs ls)))
            #f))))

(define (every pred l . ls)
  (if (null? ls)
      (let loop ((l l))
        (cond ((null? l) #t)
              ((null? (cdr l)) (pred (car l)))
              ((pred (car l)) (loop (cdr l)))
              (else #f)))
      (let loop ((ls (cons l ls)) (last #t))
        (if (%all-pairs? ls)
            (let ((r (apply pred (%cars ls))))
              (if r (loop (%cdrs ls) r) #f))
            last))))

(define (count pred l)
  (let loop ((l l) (n 0))
    (cond ((null? l) n) ((pred (car l)) (loop (cdr l) (+ n 1))) (else (loop (cdr l) n)))))

(define (take l n) (list-head l n))
(define (drop l n) (list-tail l n))
(define (take-while pred l)
  (let loop ((l l) (acc '()))
    (if (and (pair? l) (pred (car l))) (loop (cdr l) (cons (car l) acc)) (reverse acc))))
(define (drop-while pred l)
  (let loop ((l l))
    (if (and (pair? l) (pred (car l))) (loop (cdr l)) l)))
(define (span pred l) (values (take-while pred l) (drop-while pred l)))
(define (break pred l) (span (lambda (x) (not (pred x))) l))
(define (take-right l n) (list-tail l (- (length l) n)))
(define (drop-right l n) (list-head l (- (length l) n)))
(define (concatenate ls) (apply append ls))
(define (flatten x)
  (cond ((null? x) '())
        ((pair? x) (append (flatten (car x)) (flatten (cdr x))))
        (else (list x))))

(define (del-assq key alist) (remove (lambda (p) (eq? (car p) key)) alist))
(define (del-assv key alist) (remove (lambda (p) (eqv? (car p) key)) alist))
(define (del-assoc key alist) (remove (lambda (p) (equal? (car p) key)) alist))
(define (alist-copy alist) (map (lambda (p) (if (pair? p) (cons (car p) (cdr p)) p)) alist))

(define (%sort-list l less?)
  (define (merge a b acc)
    (cond ((null? a) (append-reverse acc b))
          ((null? b) (append-reverse acc a))
          ((less? (car b) (car a)) (merge a (cdr b) (cons (car b) acc)))
          (else (merge (cdr a) b (cons (car a) acc)))))
  (define (msort l n)
    (cond ((= n 0) '())
          ((= n 1) (list (car l)))
          (else (let ((h (quotient n 2)))
                  (merge (msort l h) (msort (list-tail l h) (- n h)) '())))))
  (msort l (length l)))

(define (sort seq less?)
  (cond ((vector? seq) (list->vector (%sort-list (vector->list seq) less?)))
        ((list? seq) (%sort-list seq less?))
        (else (error "The object, passed as the first argument to sort, is not the correct type." seq))))
(define (sort! seq less?)
  (if (vector? seq)
      (let ((sorted (sort seq less?))) (vector-copy! seq 0 sorted) seq)
      (sort seq less?)))
(define merge-sort sort)
(define (list-sort less? seq) (sort seq less?))

;;; ---- symbols, characters, strings ----

(define (symbol=? a b . rest)
  (and (eq? a b) (or (null? rest) (apply symbol=? b rest))))
(define char-foldcase char-downcase)
(define string-foldcase string-downcase)

(define string-index
  (let ((prim string-index))
    (lambda (s p)
      (if (char? p)
          (prim s p)
          (let loop ((i 0))
            (cond ((= i (string-length s)) #f)
                  ((p (string-ref s i)) i)
                  (else (loop (+ i 1)))))))))

(define (string-count s p)
  (let loop ((i 0) (n 0))
    (if (= i (string-length s))
        n
        (loop (+ i 1) (if (if (char? p) (char=? p (string-ref s i)) (p (string-ref s i))) (+ n 1) n)))))

;;; ---- hash tables ----

(define (hash-table-ref table key . rest)
  (let ((e (%hash-table-entry table key)))
    (if e
        (if (and (pair? rest) (pair? (cdr rest))) ((cadr rest) (cdr e)) (cdr e))
        (if (and (pair? rest) (car rest))
            ((car rest))
            (error "key not found:" key)))))

(define (hash-table-update! table key proc . rest)
  (hash-table-set! table key (proc (apply hash-table-ref table key rest))))

(define (hash-table-update!/default table key proc default)
  (hash-table-set! table key (proc (hash-table-ref/default table key default))))

(define (hash-table-walk table proc)
  (for-each (lambda (p) (proc (car p) (cdr p))) (hash-table->alist table)))

(define (hash-table-fold table kons knil)
  (fold (lambda (p acc) (kons (car p) (cdr p) acc)) knil (hash-table->alist table)))

;;; ---- ports ----

(define (call-with-output-string proc)
  (let ((port (open-output-string)))
    (proc port)
    (get-output-string port)))

(define (with-output-to-string . thunk)
  (let ((port (open-output-string)) (old #f))
    (if (pair? thunk)
        (dynamic-wind
          (lambda () (set! old (%swap-output-port! port)))
          (car thunk)
          (lambda () (%swap-output-port! old))))
    (get-output-string port)))

(define (call-with-input-string string proc) (proc (open-input-string string)))

(define (with-input-from-string string thunk)
  (let ((port (open-input-string string)) (old #f))
    (dynamic-wind
      (lambda () (set! old (%swap-input-port! port)))
      thunk
      (lambda () (%swap-input-port! old)))))

(define (call-with-port port proc)
  (call-with-values (lambda () (proc port)) (lambda results (close-port port) (apply values results))))
(define (call-with-output-file path proc) (call-with-port (open-output-file path) proc))
(define (call-with-input-file path proc) (call-with-port (open-input-file path) proc))
(define (with-output-to-file path thunk)
  (let ((port (open-output-file path)) (old #f))
    (dynamic-wind
      (lambda () (set! old (%swap-output-port! port)))
      thunk
      (lambda () (%swap-output-port! old) (close-port port)))))
(define (with-input-from-file path thunk)
  (let ((port (open-input-file path)) (old #f))
    (dynamic-wind
      (lambda () (set! old (%swap-input-port! port)))
      thunk
      (lambda () (%swap-input-port! old)))))

(define (read-all . port)
  (let loop ((acc '()))
    (let ((x (apply read port)))
      (if (eof-object? x) (reverse acc) (loop (cons x acc))))))

;;; ---- streams ----

(define the-empty-stream '())
(define stream-nil '())
(define (stream-pair? s) (and (pair? s) (promise? (cdr s))))
(define (stream-null? s) (null? s))
(define empty-stream? stream-null?)
(define (stream-car s)
  (if (stream-pair? s) (car s) (error "The object, passed as the first argument to stream-car, is not the correct type." s)))
(define (stream-cdr s)
  (if (stream-pair? s) (force (cdr s)) (error "The object, passed as the first argument to stream-cdr, is not the correct type." s)))
(define stream-first stream-car)
(define stream-rest stream-cdr)
(define (stream-head s n) (if (= n 0) '() (cons (stream-car s) (stream-head (stream-cdr s) (- n 1)))))
(define (stream-tail s n) (if (= n 0) s (stream-tail (stream-cdr s) (- n 1))))
(define (stream-ref s n) (stream-car (stream-tail s n)))
(define (stream->list s . n)
  (let loop ((s s) (n (if (pair? n) (car n) -1)) (acc '()))
    (if (or (null? s) (= n 0)) (reverse acc) (loop (stream-cdr s) (- n 1) (cons (stream-car s) acc)))))
(define (list->stream l) (if (null? l) '() (cons-stream (car l) (list->stream (cdr l)))))
(define (stream . items) (list->stream items))
(define (stream-map f s . rest)
  (if (null? rest)
      (let loop ((s s))
        (if (null? s) '() (cons-stream (f (stream-car s)) (loop (stream-cdr s)))))
      (let loop ((ss (cons s rest)))
        (if (any null? ss) '() (cons-stream (apply f (map stream-car ss)) (loop (map stream-cdr ss)))))))
(define (stream-filter pred s)
  (cond ((null? s) '())
        ((pred (stream-car s)) (cons-stream (stream-car s) (stream-filter pred (stream-cdr s))))
        (else (stream-filter pred (stream-cdr s)))))
(define (stream-for-each f s)
  (if (not (null? s)) (begin (f (stream-car s)) (stream-for-each f (stream-cdr s)))))
(define (stream-append . ss)
  (cond ((null? ss) '())
        ((null? (car ss)) (apply stream-append (cdr ss)))
        (else (cons-stream (stream-car (car ss)) (apply stream-append (stream-cdr (car ss)) (cdr ss))))))

;;; ---- misc ----

(define (identity x) x)
(define (compose . fs)
  (if (null? fs) identity (lambda args (call-with-values (lambda () (apply (apply compose (cdr fs)) args)) (car fs)))))
(define (exact-floor x) (exact (floor x)))
(define (exact-round x) (exact (round x)))
(define (exact-ceiling x) (exact (ceiling x)))
(define (exact-truncate x) (exact (truncate x)))
(define (boolean=? a b . rest) (and (eq? a b) (or (null? rest) (apply boolean=? b rest))))
(define (forget-all) (error "forget-all is only available in the workspace"))

(define system-global-environment (interaction-environment))
(define user-initial-environment system-global-environment)
