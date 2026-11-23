"A workspace for trying Forth out: select some Forth and print it (or do it) to run it. What it prints comes
back, followed by ok and whatever is left on the stack. The system is the same every time, so what you
define stays defined until you ask for a fresh one."

Object subclass: #ForthTool instanceVariableNames: '' classVariableNames: 'System' category: 'Forth'!

!ForthTool class methodsFor: 'opening'!
open
	Smalltalk openTool: 'ForthTool' title: 'Forth' contents: self welcomeText!
welcomeText
	^'\ Select some Forth and print it (ctrl-P) or do it (ctrl-D).  What it prints
\ comes back, then ok, then the stack if anything is left on it.  Definitions
\ are kept from one run to the next, until you run   FORGET-ALL   or close
\ the window.

2 3 + .
: square ( n -- n*n )  dup * ;
7 square .
: stars ( n -- )  0 ?do [char] * emit loop ;
5 stars cr
1 2 3 .s

: fact ( n -- n!! )  dup 2 < if drop 1 else dup 1- recurse * then ;
20 fact .
30 fact .

\ strings, loops and memory
: greet  ." Hello from Forth" cr ;
greet
variable count   0 count !!
: tally  10 0 do  1 count +!!  loop ;
tally count ?
see square
' ! !

!ForthTool class methodsFor: 'evaluating'!
system
	"the Forth system the workspace runs in"
	System isNil ifTrue: [System := Forth new].
	^System!
reset
	"a fresh system: every definition forgotten"
	System := Forth new.
	^System!
evaluate: aString
	"the report for the selected text: what it printed, then ok (with the stack) or what went wrong"
	| f text err ws |
	aString trimBoth = 'FORGET-ALL' ifTrue: [self reset. ^'a fresh Forth system ok'].
	f := self system.
	err := nil.
	text := [f eval: aString] on: ForthError do: [:e | err := e. f output].
	ws := WriteStream on: String new.
	ws nextPutAll: text.
	(text isEmpty or: [text last isSeparator]) ifFalse: [ws space].
	err isNil
		ifTrue: [ws nextPutAll: f statusLine]
		ifFalse: [
			ws nextPutAll: 'error: '; nextPutAll: err messageText.
			f errorLine notNil ifTrue: [ws nextPutAll: '  (line '; print: f errorLine; nextPut: $)]].
	^ws contents! !
