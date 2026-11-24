# Scheme

A Scheme system: R5RS and much of R7RS-small, with proper tail calls, full re-entrant `call/cc`, `dynamic-wind`, `syntax-rules` macros, records, hash tables, string ports, streams, and a bridge to Smalltalk objects. It is an optional package:

```smalltalk
Smalltalk loadPackage: 'Scheme'          "or: st -l Scheme, or System menu → load package..."
```

## From Smalltalk

```smalltalk
Scheme eval: '(+ 1 2)'                                  "'3'  -- the value of the last form, as write shows it"
Scheme eval: '(define (sq x) (* x x)) (sq 12)'          "'144' -- definitions stay defined"
Scheme run: '(display "hi") (newline)'                  "what the program displayed"
Scheme evalValue: '(list 1 "two" (vector 3))'           "#(1 'two' #(3)) -- lists and vectors become Arrays"
Scheme reset                                            "forget everything the default interpreter knows"
Scheme load: 'program.scm'

s := Scheme new.                                        "an interpreter of your own"
s eval: '(define x 10)'. s at: 'x'                      "10; s at: 'y' put: 5 sets a global"
s define: 'triple' do: [:n | n * 3]                     "a procedure written in Smalltalk (arity = block arity)"
Scheme define: 'triple' do: [...]                       "...in every interpreter, present and future"
s call: 'sq' with: #(7)                                 "call a Scheme procedure: 49"
s takeOutput. s outputText                              "the displayed text, taking it or not"
```

`eval:` answers the written value (an unspecified value is `''`). An error that nothing in the program handles is signalled as a `SchemeError`: `messageText` is the report (`The object 5, passed as the first argument to car, is not the correct type.`), `payload` is what was raised (a condition, or any object given to `raise`). `(exit n)` ends the program and `eval:` answers `n`. `Scheme new` copies the prelude's definitions, so interpreters are independent.

## The language

Special forms: `quote quasiquote lambda named-lambda define set! if begin and or let letrec letrec* delay delay-force cons-stream define-syntax let-syntax letrec-syntax guard define-record-type case-lambda the-environment`, and by `syntax-rules` in the prelude `cond case when unless let* do let-values let*-values receive define-values parameterize fluid-let`. Internal definitions, named let, curried `define`, `=>` clauses are all there.

* **Numbers**: Smalltalk's tower. Exact integers of any size, exact rationals, floats; `exact inexact floor round` (to even) `expt sqrt exact-integer-sqrt number->string string->number` with radix, `quotient remainder modulo floor/ truncate/`, bit operations, `random`. No complex numbers (`(sqrt -4)` is an error).
* **Data**: pairs and lists with `c[ad]{2,4}r`, SRFI-1 style `fold reduce filter remove partition delete-duplicates any every count take drop span break iota list-tabulate append-map filter-map last-pair`, association lists, vectors, strings (mutable Smalltalk Strings), characters, symbols, `sort` (stable merge sort on lists and vectors), hash tables (`make-equal-hash-table make-strong-eqv-hash-table make-string-hash-table`, `hash-table-set! hash-table-ref hash-table-ref/default hash-table-update! hash-table-update!/default hash-table-walk hash-table-keys hash-table->alist ...`; every table compares keys with `equal?`), records, promises and streams (`stream-head stream-tail stream-map stream-filter ...`), parameters.
* **Control**: `call/cc` (re-entrant: generators and coroutines work), `dynamic-wind`, `values call-with-values`, `apply`, `eval`, `with-exception-handler raise raise-continuable error guard assert exit`, `error-object? error-object-message error-object-irritants condition/report-string`.
* **Ports**: `display write write-string write-char write-line newline fresh-line`, `open-input-string open-output-string get-output-string with-output-to-string call-with-output-string with-input-from-string read read-char peek-char read-line read-string`, files (`open-input-file open-output-file call-with-output-file with-output-to-file load`; an output file is written when its port is closed).
* **Bridge**: `(st-eval "3 + 4")`, `(st-class "Date")`, `(st-new "OrderedCollection")`, `(st-send obj 'add: 5)`, `(st->list collection)`, `st-class-of st-print st-nil? st-object?`. Numbers, strings, symbols, characters and booleans are the same objects on both sides, a Smalltalk Array is a vector, other Smalltalk objects are passed along (and printed `#[st ...]`), and a Smalltalk block can be called like a procedure.

`Scheme availablePrimitives` lists the procedures written in Smalltalk; the rest are in `prelude.scm`.

## How it works

Source is read (`reader.st`), compiled once into a tree of nodes with lexical addressing (`compiler.st`, `nodes.st`), and run by a register machine (`machine.st`) whose continuation is a linked list of heap frames. Nothing recurses on the Smalltalk stack for a Scheme call, so tail calls are free, `call/cc` is a pointer copy, and recursion is limited by memory: runaway recursion stops at 400000 frames with `Aborting!: maximum recursion depth exceeded`. Errors raised in Smalltalk primitives become Scheme conditions at the machine's top, so `guard` and handlers see them. Primitives are Smalltalk blocks (`prims1-3.st`), the prelude is Scheme (`prelude.scm`), and `Scheme new` starts from a copy of a template that has both.

## The workspace

*System menu → scheme workspace*, or `SchemeTool open`. Select some Scheme and **print it** or **do it**: what it displayed comes back, then `;Value: ...` (or `;Unspecified return value`, or the error). Definitions stay until you run `(forget-all)`.

## Tutorial

`SchemeTutorial go` (also in the System menu's tutorials): 21 lessons from expressions to macros, continuations, streams, records and the bridge, ending with eight queens and a small evaluator.

## Limits

* Macros are not fully hygienic: variables that a template binds with `let`, `let*`, `letrec`, `lambda`, `do`, named `let` or a `define` parameter list are renamed afresh at every use, but a free identifier in a template means what it means where the macro is used (a local variable named `list` shadows the macro's `list`). Only `syntax-rules` is supported.
* Arguments are evaluated left to right. `eval` ignores its environment argument (there is one global environment per interpreter). `guard` re-raises a condition that no clause handles to the outer handlers in the guard's own context, not the raise point.
* A handler that returns from a non-continuable `raise` passes the object to the next handler outward (and an uncaught one ends the program with its original message).
* No bytevectors, no complex numbers. `st-eval` runs Smalltalk through `evaluate:`: a syntax error is a `SchemeError`, but a runtime error inside the evaluated Smalltalk code is reported by the Smalltalk system, not caught by `guard`. `call/cc` across `load` or `st-eval` is not supported (each runs its own machine loop).
* Speed: about 4 microseconds per procedure call; `(fib 25)` takes about a second.

## Tests

`tests/tests.txt` has `expression ==> expected printString` lines for `make check`, run normally and under GC stress.
