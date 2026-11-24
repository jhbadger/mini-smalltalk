"A workspace for trying Scheme out: select some Scheme and print it (or do it) to run it. What it displays comes back, then
;Value: and the value of the last form (or the error). The interpreter is the same every time, so what you define stays
defined until you run   (forget-all)."

Object subclass: #SchemeTool instanceVariableNames: '' classVariableNames: 'System' category: 'Scheme'!

!SchemeTool class methodsFor: 'opening'!
open
	Smalltalk openTool: 'SchemeTool' title: 'Scheme' contents: self welcomeText!
welcomeText
	^';;; Select some Scheme and print it (ctrl-P) or do it (ctrl-D).  What it displays
;;; comes back, then ;Value: and the value of the last form.  Definitions are
;;; kept from one run to the next, until you run   (forget-all)   or close the
;;; window.

(+ 1 2)
(define (square x) (* x x))
(map square (iota 10))

(define (fact n) (if (< n 2) 1 (* n (fact (- n 1)))))
(fact 30)

;; strings, lists and display
(display "Hello from Scheme") (newline)
(let loop ((i 0))
  (when (< i 3) (display i) (display " ") (loop (+ i 1))))

;; call/cc, tail calls, macros
(call/cc (lambda (k) (+ 1 (k 42))))
(define-syntax swap!!
  (syntax-rules () ((_ a b) (let ((tmp a)) (set!! a b) (set!! b tmp)))))
(define x 1) (define y 2) (swap!! x y) (list x y)
(vector-map square #(1 2 3))
(st-eval "3 + 4")' ! !

!SchemeTool class methodsFor: 'evaluating'!
system
	"the interpreter the workspace runs in"
	System isNil ifTrue: [System := Scheme new].
	^System!
reset
	"a fresh interpreter: every definition forgotten"
	System := Scheme new.
	^System!
echo: v
	"the line that reports a value"
	v == SchemeUnspec ifTrue: [^';Unspecified return value'].
	v class == SchemeValues ifTrue: [v items isEmpty ifTrue: [^';No values']].
	^';Value: ', (SchemePrinter write: v)!
evaluate: aString
	"the report for the selected text: what it displayed, then the value of the last form, or what went wrong"
	| s v text ws failure |
	aString trimBoth = '(forget-all)' ifTrue: [self reset. ^';a fresh Scheme system'].
	s := self system.
	s takeOutput.
	failure := nil.
	v := [[s evalString: aString]
		on: SchemeError do: [:e | failure := ';', e messageText. nil]]
		on: SchemeExit do: [:e | failure := ';Exit'. nil].
	text := s takeOutput.
	ws := WriteStream on: String new.
	ws nextPutAll: text.
	(text notEmpty and: [text last ~= Character nl]) ifTrue: [ws nextPut: Character nl].
	failure isNil ifTrue: [ws nextPutAll: (self echo: v)] ifFalse: [ws nextPutAll: failure].
	^ws contents! !
