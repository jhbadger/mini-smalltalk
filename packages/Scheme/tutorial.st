"The Scheme tutorial: expressions, defining things, numbers, decisions, lists, recursion and tail calls, higher-order procedures,
scope, closures, strings and characters, vectors and hash tables, quasiquote and eval, macros, continuations, errors,
streams, records and ports, the bridge to Smalltalk, and some larger programs.  Start it with   SchemeTutorial go"

AbstractTutorial subclass: #SchemeTutorial instanceVariableNames: '' classVariableNames: '' category: 'Scheme'!

!SchemeTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Scheme'!
lessonSelectors
	^#(
		#welcome #expressions #defining #numbers #conditionals #lists #recursion #higher #scope
		#closures #text #vectors #quasi #macros #continuations #errors #lazy #records
		#smalltalk #program #whatNext)! !

!SchemeTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'This is a Scheme system inside Smalltalk: a small, clean language in which a
program is a list, a procedure is a value, and the whole syntax is parentheses.
It follows R5RS and much of R7RS, including proper tail calls, continuations
that can be re-entered, and syntax-rules macros.

Everything in this tutorial is live: select a line and press ctrl-P (print it).
The message eval: sent to Scheme runs some Scheme and answers the value of the
last expression, written the way a Scheme program would write it:

Scheme reset
Scheme eval: ''(+ 1 2)''
Scheme eval: ''(* 6 7)''
Scheme eval: ''(list 1 2 3)''

What a program displays goes to a buffer, and the message run: answers it:

Scheme run: ''(display "Hello, ") (display "world") (newline)''

The system keeps what you define between calls (it lives in Scheme default), so
each lesson can build on the last. Run Scheme reset to start again from nothing.
There is also a workspace (System menu, scheme workspace) in which you select
text and print it: it shows what was displayed and then ;Value: and the result.'!
expressions
	^TutorialLesson title: 'Expressions' text:
'A Scheme expression is either an atom, such as a number, or a list in
parentheses. In a list the first element is the operator and the rest are the
operands, so there are no precedence rules to learn and no commas:

Scheme eval: ''(+ 1 2 3 4)''
Scheme eval: ''(- 10 3)''
Scheme eval: ''(* (+ 1 2) (- 5 1))''
Scheme eval: ''(/ 10 4)''

Operators take any number of operands where that makes sense, and expressions
nest as deeply as you like. Note that 10 divided by 4 is the exact fraction 5/2,
not a rounded number. The special forms are the only exceptions to the rule that
every operand is evaluated first. The simplest is quote, which keeps its operand
as data instead of evaluating it:

Scheme eval: ''(quote (1 2 3))''
Scheme eval: ''(quote hello)''
Scheme eval: ''''''(1 2 3)''

The last line is the same as the first, using the '' shorthand. (Inside a string
in Smalltalk a quote is written twice, which is why it looks doubled here; in
the workspace you write it once.)

Comments run from a semicolon to the end of the line, and #| ... |# comments
nest. Because a program is data, a misspelled name is only found when it is
used:

[Scheme eval: ''(frobnicate 1)''] on: SchemeError do: [:e | e messageText]'!
defining
	^TutorialLesson title: 'Defining things' text:
'define gives a name to a value. Define a procedure with the shorthand that puts
the name and the parameters together in a list:

Scheme eval: ''(define pi 3.14159)''
Scheme eval: ''(define (area r) (* pi r r))''
Scheme eval: ''(area 2)''

A procedure is an ordinary value. lambda makes one without naming it, and the
shorthand above is just a lambda bound to a name:

Scheme eval: ''(define square (lambda (x) (* x x)))''
Scheme eval: ''(square 12)''
Scheme eval: ''((lambda (a b) (+ a b)) 3 4)''
Scheme eval: ''square''

Parameters can be optional in a sense: a dotted tail, or a lone symbol, collects
the extra arguments into a list:

Scheme eval: ''(define (f a . rest) (list a rest))''
Scheme eval: ''(f 1)''
Scheme eval: ''(f 1 2 3)''
Scheme eval: ''((lambda args args) 1 2 3)''

set!! changes an existing variable (it does not create one):

Scheme eval: ''(define counter 0)''
Scheme eval: ''(set!! counter (+ counter 1))''
Scheme eval: ''counter'''!
numbers
	^TutorialLesson title: 'Numbers' text:
'Numbers in Scheme form a tower. Integers are exact and as large as memory allows;
division of integers gives an exact fraction; a decimal point makes a number
inexact (a float), and inexactness spreads:

Scheme eval: ''(expt 2 100)''
Scheme eval: ''(/ 1 3)''
Scheme eval: ''(+ 1/3 1/6)''
Scheme eval: ''(* 1.0 1/3)''
Scheme eval: ''(exact->inexact 1/3)''
Scheme eval: ''(inexact->exact 0.5)''

The integer operations come in the three flavours that people confuse.
quotient rounds toward zero, modulo takes the sign of the divisor, remainder the
sign of the dividend:

Scheme eval: ''(list (quotient -7 2) (modulo -7 2) (remainder -7 2))''
Scheme eval: ''(list (floor 2.5) (ceiling 2.5) (round 2.5) (round 3.5) (truncate -2.5))''

round goes to the even neighbour at a tie, which is why 2.5 gives 2. The
answers to floor and friends stay inexact when the argument is. The
predicates ask about exactness and kind:

Scheme eval: ''(list (exact? 1/2) (inexact? 0.5) (integer? 4.0) (rational? 1/2) (even? 10))''
Scheme eval: ''(sqrt 16)''
Scheme eval: ''(sqrt 2)''
Scheme eval: ''(number->string 255 16)''
Scheme eval: ''(string->number "1e3")''
Scheme eval: ''(exact (floor (sqrt 1000)))'''!
conditionals
	^TutorialLesson title: 'Deciding' text:
'if takes a test and two branches; only the branch that is chosen is evaluated.
In Scheme only #f is false: 0, the empty list and the empty string all count as
true.

Scheme eval: ''(if (> 3 2) "yes" "no")''
Scheme eval: ''(if 0 "zero is true" "zero is false")''
Scheme eval: ''(if (quote ()) "empty list is true" "empty list is false")''

cond is a chain of tests, with else for the rest, and => passing the test''s value
to a procedure. case compares against lists of constants:

Scheme eval: ''(define (sign n) (cond ((< n 0) (quote negative)) ((= n 0) (quote zero)) (else (quote positive))))''
Scheme eval: ''(map sign (list -5 0 5))''
Scheme eval: ''(cond ((assv 2 (quote ((1 . one) (2 . two)))) => cdr) (else (quote none)))''
Scheme eval: ''(case (* 2 3) ((2 3 5 7) (quote prime)) ((1 4 6 8 9) (quote composite)))''

and and or stop as soon as the answer is known, and return the value that
decided it, not just #t or #f. when and unless are one-armed ifs:

Scheme eval: ''(and 1 2 3)''
Scheme eval: ''(and 1 #f 3)''
Scheme eval: ''(or #f #f "found")''
Scheme eval: ''(when (> 3 2) "a" "b")''
Scheme eval: ''(unless (> 3 2) "never")'''!
lists
	^TutorialLesson title: 'Lists and pairs' text:
'Everything in a list is built from pairs. cons makes a pair, car and cdr take it
apart, and a list is a chain of pairs ending in the empty list:

Scheme eval: ''(cons 1 2)''
Scheme eval: ''(cons 1 (cons 2 (cons 3 (quote ()))))''
Scheme eval: ''(car (list 10 20 30))''
Scheme eval: ''(cdr (list 10 20 30))''
Scheme eval: ''(cadr (list 10 20 30))''

A chain that does not end in the empty list is written with a dot. The usual list
operations are all there:

Scheme eval: ''(cons 1 (cons 2 3))''
Scheme eval: ''(append (list 1 2) (list 3) (list 4 5))''
Scheme eval: ''(reverse (list 1 2 3))''
Scheme eval: ''(length (list 1 2 3 4))''
Scheme eval: ''(list-ref (list "a" "b" "c") 1)''
Scheme eval: ''(list-tail (list 1 2 3 4) 2)''
Scheme eval: ''(memq (quote c) (list (quote a) (quote b) (quote c) (quote d)))''
Scheme eval: ''(iota 6 1)''

An association list is a list of pairs used as a table; assq, assv and assoc
look a key up with eq?, eqv? and equal?:

Scheme eval: ''(define ages (list (cons "ann" 31) (cons "bob" 27)))''
Scheme eval: ''(assoc "bob" ages)''
Scheme eval: ''(cdr (assoc "ann" ages))''
Scheme eval: ''(assoc "carl" ages)''

Pairs are mutable (set-car!! and set-cdr!!), and lists can share structure, so
equal? asks whether two things look alike and eq? whether they are the same one:

Scheme eval: ''(equal? (list 1 2 (list 3)) (list 1 2 (list 3)))''
Scheme eval: ''(eq? (list 1) (list 1))'''!
recursion
	^TutorialLesson title: 'Recursion and tail calls' text:
'There are no loops in the core of Scheme: a loop is a procedure that calls
itself. A call in tail position (the last thing a procedure does) does not use
any space, so a loop written that way can run forever:

Scheme eval: ''(define (fact n) (if (< n 2) 1 (* n (fact (- n 1)))))''
Scheme eval: ''(fact 20)''
Scheme eval: ''(fact 50)''
Scheme eval: ''(define (count-up n acc) (if (= n 0) acc (count-up (- n 1) (+ acc 1))))''
Scheme eval: ''(count-up 100000 0)''

The second procedure has the recursive call in tail position, so a hundred
thousand iterations take no more room than one. Even ordinary recursion is not
limited by the Smalltalk stack; it is limited by memory, and runaway recursion
stops with a message:

Scheme eval: ''(define (depth n) (if (= n 0) 0 (+ 1 (depth (- n 1)))))''
Scheme eval: ''(depth 100000)''
[Scheme eval: ''(define (forever n) (+ 1 (forever n))) (forever 0)''] on: SchemeError do: [:e | e messageText]

The named let is the idiom for a local loop: it names a procedure and calls it
at once. And do is a loop in the style of other languages, built from it:

Scheme eval: ''(let loop ((i 0) (acc (quote ()))) (if (= i 5) (reverse acc) (loop (+ i 1) (cons (* i i) acc))))''
Scheme eval: ''(do ((i 0 (+ i 1)) (sum 0 (+ sum i))) ((= i 5) sum))''

Mutual recursion works the same way, and a tail call through cond, and, or, when
and unless is still a tail call:

Scheme eval: ''(define (even2? n) (if (= n 0) #t (odd2? (- n 1))))''
Scheme eval: ''(define (odd2? n) (if (= n 0) #f (even2? (- n 1))))''
Scheme eval: ''(even2? 100001)'''!
higher
	^TutorialLesson title: 'Higher-order procedures' text:
'Because procedures are values, they can be passed to other procedures. map applies
a procedure to every element of a list, filter keeps the elements that pass a test,
and the folds combine a list into one value:

Scheme eval: ''(map square (list 1 2 3 4))''
Scheme eval: ''(map + (list 1 2 3) (list 10 20 30))''
Scheme eval: ''(filter odd? (iota 10))''
Scheme eval: ''(reduce + 0 (iota 11))''
Scheme eval: ''(fold-left list 0 (list 1 2 3))''
Scheme eval: ''(fold-right list 0 (list 1 2 3))''
Scheme eval: ''(apply max (list 3 9 2))''
Scheme eval: ''(apply + 1 2 (list 3 4))''

for-each is map for effect, and sort takes any comparison:

Scheme run: ''(for-each (lambda (x) (display (* x x)) (display " ")) (iota 5))''
Scheme eval: ''(sort (list 3 1 4 1 5 9 2 6) <)''
Scheme eval: ''(sort (list "pear" "fig" "apple") string<?)''
Scheme eval: ''(list-index even? (list 1 3 4 5))''
Scheme eval: ''(any even? (list 1 3 5))''
Scheme eval: ''(every odd? (list 1 3 5))''

Procedures can make procedures, too. compose and the adder below each return a
new procedure:

Scheme eval: ''(define (make-adder n) (lambda (x) (+ x n)))''
Scheme eval: ''((make-adder 10) 5)''
Scheme eval: ''(map (make-adder 100) (list 1 2 3))''
Scheme eval: ''((compose square (make-adder 1)) 4)'''!
scope
	^TutorialLesson title: 'Let and scope' text:
'let binds names for the length of its body. All the initial values are worked out
first, in the outside scope; let* binds one after another, and letrec lets
procedures refer to each other:

Scheme eval: ''(let ((x 2) (y 3)) (* x y))''
Scheme eval: ''(let* ((x 2) (y (* x 10))) (list x y))''
Scheme eval: ''(define x 100)''
Scheme eval: ''(let ((x 1) (y x)) (list x y))''
Scheme eval: ''(let* ((x 1) (y x)) (list x y))''
Scheme eval: ''(letrec ((even? (lambda (n) (if (= n 0) #t (odd? (- n 1))))) (odd? (lambda (n) (if (= n 0) #f (even? (- n 1)))))) (even? 10))''

A procedure body may begin with definitions, which are local to it. Scoping is
lexical: a name means what it meant where the procedure was written, not where
it is called:

Scheme eval: ''(define (hyp a b) (define (sq x) (* x x)) (sqrt (+ (sq a) (sq b))))''
Scheme eval: ''(hyp 3 4)''
Scheme eval: ''(define y 10)''
Scheme eval: ''(define (show-y) y)''
Scheme eval: ''(let ((y 20)) (show-y))''

Multiple values come back with values, and let-values, receive or
call-with-values take them apart:

Scheme eval: ''(call-with-values (lambda () (values 1 2 3)) list)''
Scheme eval: ''(let-values (((q r) (floor/ 17 5))) (list q r))'''!
closures
	^TutorialLesson title: 'Closures' text:
'A procedure remembers the variables that were in scope where it was made. That
makes an object: private state, and procedures that share it. make-counter
returns a procedure; each counter has its own n:

Scheme eval: ''(define (make-counter) (let ((n 0)) (lambda () (set!! n (+ n 1)) n)))''
Scheme eval: ''(define c1 (make-counter))''
Scheme eval: ''(define c2 (make-counter))''
Scheme eval: ''(list (c1) (c1) (c1) (c2))''

A bank account is the standard example: several procedures closing over the same
variable, chosen by a message symbol:

Scheme eval: ''(define (make-account balance) (define (deposit n) (set!! balance (+ balance n)) balance) (define (withdraw n) (if (> n balance) "insufficient funds" (begin (set!! balance (- balance n)) balance))) (lambda (msg . args) (cond ((eq? msg (quote deposit)) (apply deposit args)) ((eq? msg (quote withdraw)) (apply withdraw args)) ((eq? msg (quote balance)) balance))))''
Scheme eval: ''(define acct (make-account 100))''
Scheme eval: ''(acct (quote deposit) 50)''
Scheme eval: ''(acct (quote withdraw) 500)''
Scheme eval: ''(acct (quote withdraw) 30)''
Scheme eval: ''(acct (quote balance))'''!
text
	^TutorialLesson title: 'Strings, characters, symbols' text:
'Strings are written in double quotes, characters as #\a (with names like
space and newline written #\space and #\newline), and symbols are bare names
compared by identity. Strings are mutable here; use string-copy first if you
must change a literal:

Scheme eval: ''(string-append "foo" "bar" "baz")''
Scheme eval: ''(string-length "hello")''
Scheme eval: ''(substring "hello world" 6 11)''
Scheme eval: ''(string-upcase "shout")''
Scheme eval: ''(string->list "abc")''
Scheme eval: ''(list->string (reverse (string->list "stressed")))''
Scheme eval: ''(string<? "apple" "banana")''
Scheme eval: ''(string-index "hello" #\l)''
Scheme eval: ''(string-search-forward "lo" "hello" 0)''
Scheme eval: ''(string-pad-left (number->string 7) 3 #\0)''

Characters have their own predicates, and can be turned into numbers and back.
Symbols and strings convert freely:

Scheme eval: ''(map char-upcase (string->list "abc"))''
Scheme eval: ''(char->integer #\A)''
Scheme eval: ''(integer->char 955)''
Scheme eval: ''(char-numeric? #\7)''
Scheme eval: ''(symbol->string (quote lambda))''
Scheme eval: ''(string->symbol "hello world")''
Scheme eval: ''(eq? (quote abc) (string->symbol "abc"))''

display shows a value for people and write shows it for the reader: strings
are quoted and characters spelled out, so that what write prints can be read back:

Scheme run: ''(display "a string") (newline) (write "a string") (newline) (write #\a) (display #\a)''
Scheme eval: ''(string-join (list "a" "b" "c") "-")''
Scheme eval: ''(string-split "one,two,three" #\,)'''!
vectors
	^TutorialLesson title: 'Vectors and hash tables' text:
'A vector is a fixed-size array with constant-time access, written #(1 2 3).
Hash tables map any keys (compared with equal?) to values:

Scheme eval: ''(define v (make-vector 4 0))''
Scheme eval: ''(vector-set!! v 2 "two")''
Scheme eval: ''v''
Scheme eval: ''(vector-ref v 2)''
Scheme eval: ''(vector-length #(a b c))''
Scheme eval: ''(vector->list (vector-map square #(1 2 3)))''
Scheme eval: ''(vector-fill!! v 7)''
Scheme eval: ''v''
Scheme eval: ''(vector-binary-search #(1 3 5 7 9) 7 -)''

Scheme eval: ''(define ht (make-equal-hash-table))''
Scheme eval: ''(hash-table-set!! ht "apple" 3)''
Scheme eval: ''(hash-table-set!! ht (list 1 2) "a list as a key")''
Scheme eval: ''(hash-table-ref/default ht "apple" 0)''
Scheme eval: ''(hash-table-ref/default ht (list 1 2) 0)''
Scheme eval: ''(hash-table-ref/default ht "pear" 0)''
Scheme eval: ''(hash-table-update!!/default ht "apple" (lambda (n) (+ n 1)) 0)''
Scheme eval: ''(hash-table-count ht)''
Scheme eval: ''(hash-table-ref/default ht "apple" 0)''

Asking for a missing key without a default is an error; hash-table-ref takes a
procedure to call instead:

Scheme eval: ''(hash-table-ref ht "pear" (lambda () "not there"))''
[Scheme eval: ''(hash-table-ref ht "pear")''] on: SchemeError do: [:e | e messageText]'!
quasi
	^TutorialLesson title: 'Quasiquote and programs as data' text:
'A backquote works like quote, except that a comma inside it evaluates, and ,@
splices in a list. It is the easy way to build lists with a few computed parts:

Scheme eval: ''(define n 5)''
Scheme eval: ''`(n is ,n and twice that is ,(* 2 n))''
Scheme eval: ''`(1 ,@(list 2 3) 4)''
Scheme eval: ''`#(a ,(+ 1 2))''

Since a program is a list, a program can build another and run it. eval takes
an expression and an environment:

Scheme eval: ''(define expr (list (quote +) 1 2 3))''
Scheme eval: ''expr''
Scheme eval: ''(eval expr (interaction-environment))''
Scheme eval: ''(eval (quote (* 6 7)) system-global-environment)''

read turns text into data, which is how a program can be read from a string:

Scheme eval: ''(read (open-input-string "(a (b c) 42)"))''
Scheme eval: ''(eval (read (open-input-string "(+ 20 22)")) (interaction-environment))'''!
macros
	^TutorialLesson title: 'Macros' text:
'A macro is a function from code to code, run before the program does. Scheme''s
syntax-rules describes the rewrite with patterns and templates; ... means
"zero or more". Here is a swap that works on any two variables, and a while loop:

Scheme eval: ''(define-syntax swap!! (syntax-rules () ((_ a b) (let ((tmp a)) (set!! a b) (set!! b tmp)))))''
Scheme eval: ''(define p 1)''
Scheme eval: ''(define q 2)''
Scheme eval: ''(swap!! p q)''
Scheme eval: ''(list p q)''
Scheme eval: ''(define-syntax while (syntax-rules () ((_ test body ...) (let loop () (when test body ... (loop))))))''
Scheme eval: ''(define i 0)''
Scheme eval: ''(while (< i 5) (set!! i (+ i 1)))''
Scheme eval: ''i''

The variable tmp that swap!! introduces cannot capture a user variable that is
also called tmp: the system renames the variables a template binds, afresh at
every use. (This is a partial hygiene: a free name in a template means what it
means where the macro is used, so shadowing list or + locally and then calling
a macro that uses it would see your version.)

Scheme eval: ''(let ((tmp 1) (other 2)) (swap!! tmp other) (list tmp other))''

Patterns can contain literal keywords and nested ellipses. my-or below is the
classic: it must not evaluate its arguments more than once.

Scheme eval: ''(define-syntax my-or (syntax-rules () ((_) #f) ((_ e) e) ((_ e rest ...) (let ((t e)) (if t t (my-or rest ...))))))''
Scheme eval: ''(let ((t 5)) (my-or #f t))''
Scheme eval: ''(define-syntax for (syntax-rules (in) ((_ x in lst body ...) (for-each (lambda (x) body ...) lst))))''
Scheme run: ''(for y in (list 1 2 3) (display (* y y)) (display " "))''

Most of the language''s own derived forms (cond, case, do, let*, when, parameterize)
are defined this way in the system''s prelude.'!
continuations
	^TutorialLesson title: 'Continuations' text:
'call-with-current-continuation (call/cc) hands a procedure a snapshot of "what
happens next", as a procedure. Calling it abandons the current computation and
goes there instead. The simplest use is an early exit:

Scheme eval: ''(call/cc (lambda (k) (+ 1 (k 42))))''
Scheme eval: ''(define (find-first pred lst) (call/cc (lambda (return) (for-each (lambda (x) (if (pred x) (return x))) lst) #f)))''
Scheme eval: ''(find-first even? (list 1 3 4 5 6))''

A continuation can be kept and called again after its extent has ended. This is
a generator: each call to it resumes the loop where it left off:

Scheme eval: ''(define (make-generator lst) (define return #f) (define (loop) (for-each (lambda (x) (call/cc (lambda (resume) (set!! loop (lambda () (resume #f))) (return x)))) lst) (return (quote done))) (lambda () (call/cc (lambda (r) (set!! return r) (loop)))))''
Scheme eval: ''(define g (make-generator (list 10 20 30)))''
Scheme eval: ''(list (g) (g) (g) (g))''

dynamic-wind runs a "before" thunk on the way in and an "after" thunk on the way
out, however that happens: by returning, by an error, or by a continuation, and
again if a continuation takes you back inside:

Scheme run: ''(call/cc (lambda (k) (dynamic-wind (lambda () (display "[in]")) (lambda () (display "[body]") (k 1) (display "[never]")) (lambda () (display "[out]")))))'''!
errors
	^TutorialLesson title: 'Errors and conditions' text:
'error signals a condition with a message and any number of irritants. An error
nobody handles reaches Smalltalk as a SchemeError:

[Scheme eval: ''(error "Something went wrong:" 42 (quote foo))''] on: SchemeError do: [:e | e messageText]
[Scheme eval: ''(car 5)''] on: SchemeError do: [:e | e messageText]
[Scheme eval: ''(vector-ref (vector 1 2) 9)''] on: SchemeError do: [:e | e messageText]

Inside Scheme, guard catches. Each clause is like a cond clause, tried in order;
if none matches, the error goes on to the next guard out. raise throws any
object, not only error conditions:

Scheme eval: ''(guard (e (#t (condition/report-string e))) (undefined-name))''
Scheme eval: ''(guard (e ((symbol? e) (list (quote caught) e)) ((string? e) e)) (raise (quote oops)))''
Scheme eval: ''(guard (e ((error? e) (list (error-object-message e) (error-object-irritants e)))) (error "bad thing:" 1 2))''
Scheme eval: ''(guard (e ((string? e) (quote outer))) (guard (e2 ((number? e2) (quote inner))) (raise "s")))''

with-exception-handler calls a handler where the error happened, which is what
lets raise-continuable put a value back. The handler of an ordinary raise must
not return: escape with a continuation, as guard does for you:

Scheme eval: ''(with-exception-handler (lambda (e) 10) (lambda () (+ 1 (raise-continuable (quote ask)))))''
Scheme eval: ''(call/cc (lambda (k) (with-exception-handler (lambda (e) (k (list (quote escaped) e))) (lambda () (raise (quote boom))))))''
Scheme eval: ''(guard (e (#t (quote cleaned-up))) (dynamic-wind (lambda () #f) (lambda () (error "x")) (lambda () #f)))'''!
lazy
	^TutorialLesson title: 'Delayed evaluation and streams' text:
'delay wraps an expression in a promise that is evaluated at most once, when it is
forced. cons-stream makes a pair whose second half is such a promise, which
gives lists as long as you like (a stream), computed only as far as they are used:

Scheme eval: ''(define p (delay (begin (display "[computing]") 42)))''
Scheme run: ''(force p)''
Scheme run: ''(force p)''
Scheme eval: ''(force p)''
Scheme eval: ''(define (integers-from n) (cons-stream n (integers-from (+ n 1))))''
Scheme eval: ''(define naturals (integers-from 0))''
Scheme eval: ''(stream-head naturals 8)''
Scheme eval: ''(stream-head (stream-map square naturals) 8)''
Scheme eval: ''(stream-ref (stream-filter odd? naturals) 100)''

The sieve of Eratosthenes needs nothing more than a stream and a filter:

Scheme eval: ''(define (sieve s) (cons-stream (stream-car s) (sieve (stream-filter (lambda (x) (not (= 0 (remainder x (stream-car s))))) (stream-cdr s)))))''
Scheme eval: ''(stream-head (sieve (integers-from 2)) 15)''
Scheme eval: ''(define fibs (cons-stream 0 (cons-stream 1 (stream-map + fibs (stream-cdr fibs)))))''
Scheme eval: ''(stream-head fibs 15)'''!
records
	^TutorialLesson title: 'Records and ports' text:
'define-record-type makes a new kind of object: a constructor, a predicate, and
an accessor (and optionally a modifier) for each field:

Scheme eval: ''(define-record-type point (make-point x y) point? (x point-x set-point-x!!) (y point-y))''
Scheme eval: ''(define pt (make-point 3 4))''
Scheme eval: ''(list (point-x pt) (point-y pt) (point? pt) (point? 5))''
Scheme eval: ''(set-point-x!! pt 10)''
Scheme eval: ''pt''
Scheme eval: ''(sqrt (+ (square (point-x pt)) (square (point-y pt))))''

Ports are where characters come from and go to. A string port lets a program
build or read text in memory; with-output-to-string captures whatever the body
displays:

Scheme eval: ''(with-output-to-string (lambda () (display "x = ") (write (list 1 "two" #\3))))''
Scheme eval: ''(call-with-output-string (lambda (port) (write (quote hello) port) (write-char #\!! port)))''
Scheme eval: ''(let ((in (open-input-string "first line"))) (list (read-char in) (read-char in) (read in) (read in) (eof-object? (read in))))''

Parameters are dynamically scoped variables; parameterize rebinds one for the
duration of its body:

Scheme eval: ''(define radix (make-parameter 10))''
Scheme eval: ''(define (show n) (number->string n (radix)))''
Scheme eval: ''(list (show 255) (parameterize ((radix 16)) (show 255)) (show 255))'''!
smalltalk
	^TutorialLesson title: 'The bridge to Smalltalk' text:
'From Scheme, st-eval runs a piece of Smalltalk, st-class finds a class, and
st-send sends a message. Numbers, strings, symbols and characters are the same
objects on both sides; a Smalltalk Array is a Scheme vector:

Scheme eval: ''(st-eval "3 + 4")''
Scheme eval: ''(st-send 10 (quote factorial))''
Scheme eval: ''(st-send "hello" (quote asUppercase))''
Scheme eval: ''(st-send (st-eval "3") (quote +) 4)''
Scheme eval: ''(define oc (st-new "OrderedCollection"))''
Scheme eval: ''(st-send oc (quote add:) 10)''
Scheme eval: ''(st-send oc (quote add:) 20)''
Scheme eval: ''(st->list oc)''
Scheme eval: ''(st-send (st-class "Date") (quote name))''

Keyword selectors take their arguments after the selector. Any other Smalltalk
object is simply carried along and can be handed back to Smalltalk. Smalltalk
blocks can be called like procedures:

Scheme eval: ''(st-send oc (quote inject:into:) 0 (st-eval "[:a :b | a + b]"))''
Scheme eval: ''((st-eval "[:x | x * x]") 12)''

From Smalltalk, eval: answers the value written, evalValue: answers it as an ordinary
object (lists become Arrays), and run: answers what was displayed:

Scheme evalValue: ''(list 1 2 (list 3 4) "five")''
Scheme eval: ''(+ 1 2)''
Scheme run: ''(display "shown") 42''

A procedure written in Smalltalk can be added to the interpreter with define:do:
and then used from Scheme like any other; call:with: calls a Scheme procedure
back from Smalltalk:

Scheme default define: ''st-twice'' do: [:x | x * 2]
Scheme eval: ''(map st-twice (list 1 2 3))''
Scheme eval: ''(define (cube x) (* x x x))''
Scheme default call: ''cube'' with: #(5)'!
program
	^TutorialLesson title: 'A larger program' text:
'Eight queens: place queens on a chess board so that no two attack each other. The
program builds every safe placement row by row, keeping each placement as a list
of columns. It is a good use of lists, recursion and higher-order procedures:

Scheme eval: ''(define (queens board-size) (define (safe? positions) (let ((new (car positions))) (let loop ((rest (cdr positions)) (d 1)) (or (null? rest) (and (not (= (car rest) new)) (not (= (abs (- (car rest) new)) d)) (loop (cdr rest) (+ d 1))))))) (define (place k) (if (= k 0) (list (quote ())) (filter safe? (append-map (lambda (rest) (map (lambda (col) (cons col rest)) (iota board-size 1))) (place (- k 1)))))) (place board-size))''
Scheme eval: ''(length (queens 6))''
Scheme eval: ''(length (queens 8))''
Scheme eval: ''(car (queens 8))''

A Scheme interpreter in Scheme is the classic exercise, and it is short, because
a program is already data. This evaluator handles numbers, variables, if, lambda
and application, with environments as association lists:

Scheme eval: ''(define (my-eval x env) (cond ((number? x) x) ((symbol? x) (cdr (assq x env))) ((eq? (car x) (quote if)) (if (my-eval (cadr x) env) (my-eval (caddr x) env) (my-eval (cadddr x) env))) ((eq? (car x) (quote lambda)) (lambda args (my-eval (caddr x) (append (map cons (cadr x) args) env)))) (else (apply (my-eval (car x) env) (map (lambda (a) (my-eval a env)) (cdr x))))))''
Scheme eval: ''(my-eval (quote ((lambda (n) (if (< n 2) n (* n 100))) 5)) (list (cons (quote <) <) (cons (quote *) *)))''
Scheme eval: ''(my-eval (quote (+ 1 (* 2 3))) (list (cons (quote +) +) (cons (quote *) *)))'''!
whatNext
	^TutorialLesson title: 'Where to go next' text:
'That is the language. Worth carrying away:

A program is data, so macros, eval and read are ordinary parts of the language,
not extensions. Use them when the problem is about code, and not otherwise.

Prefer recursion over lists with higher-order procedures to explicit mutation;
reach for set!! when state really is the point, as in the counters and accounts
of the closures lesson.

Tail calls are guaranteed, so a loop is a procedure that ends with a call. Use
a named let and stop thinking about the stack.

Continuations are the general tool behind exceptions, generators, backtracking
and coroutines. guard and dynamic-wind cover most of what you need in daily use.

The class Scheme is a Smalltalk class like any other: browse it in the System
Browser, see how the compiler and the machine are organized, add primitives with
define:do:, and read prelude.scm in the package folder to see how much of the
language is written in itself. The workspace keeps its own interpreter, and the
package README lists every procedure that is available.

The end.'! !
