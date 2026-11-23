"The public face of Forth: making a system, evaluating text, and the helpers that the primitive words lean on."

!Forth class methodsFor: 'instance creation'!
new
	^self basicNew initializeFrom: self template!
template
	"a system with the prelude already read in; every new system starts as a copy of it"
	Template isNil ifTrue: [self buildTemplate].
	^Template!
buildTemplate
	| f |
	f := self basicNew initializeEmpty.
	Prelude isNil ifFalse: [f evaluate: Prelude].
	Template := f!
prelude: aString
	"the Forth source every system starts with (the package reads prelude.fs and passes it here)"
	Prelude := aString.
	Template := nil.
	Shared := nil!
default
	"the system that  Forth eval:  and friends use, so that what you define stays defined"
	Shared isNil ifTrue: [Shared := self new].
	^Shared!
reset
	"start the default system again from scratch"
	Shared := self new.
	^Shared! !

!Forth class methodsFor: 'evaluating'!
eval: aString
	"run Forth source in the default system and answer what it printed"
	^self default eval: aString!
valueOf: aString
	"run Forth source in the default system and answer what is left on top of the stack"
	^self default valueOf: aString!
evalFile: aPath
	"run a Forth source file in the default system and answer what it printed"
	^self default eval: (FileStream contentsOf: aPath)!
stackAfter: aString
	"run Forth source in a new system and answer its data stack, bottom first"
	| f |
	f := self new.
	f eval: aString.
	^f stack!
define: aName do: aBlock
	"add a word written in Smalltalk to every system, present and future; the block is given the Forth system"
	| w |
	w := (ForthPrimitive named: aName) block: aBlock; yourself.
	self default dictionary at: aName asUppercase put: w.
	self template dictionary at: aName asUppercase put: w.
	^w! !

!Forth class methodsFor: 'support'!
random: n
	n <= 0 ifTrue: [^0].
	Generator isNil ifTrue: [Generator := Random new].
	^(Generator next * n) truncated!
integerSqrt: n
	| x y |
	n < 0 ifTrue: [^ForthError code: -24 message: 'square root of a negative number'].
	n < 2 ifTrue: [^n].
	x := n.
	y := (x + 1) // 2.
	[y < x] whileTrue: [x := y. y := (x + (n // x)) // 2].
	^x!
compare: a with: b
	"-1, 0 or 1: how string a sorts against string b, character code by character code"
	| n x y |
	n := a size min: b size.
	1 to: n do: [:i |
		x := (a at: i) asInteger.
		y := (b at: i) asInteger.
		x < y ifTrue: [^-1].
		x > y ifTrue: [^1]].
	a size = b size ifTrue: [^0].
	^a size < b size ifTrue: [-1] ifFalse: [1]!
indexOf: sub in: s
	"where sub first occurs in s, or 0"
	sub isEmpty ifTrue: [^1].
	1 to: s size - sub size + 1 do: [:i |
		(s copyFrom: i to: i + sub size - 1) = sub ifTrue: [^i]].
	^0!
digitCode: d
	^d < 10 ifTrue: [48 + d] ifFalse: [55 + d]! !

!Forth methodsFor: 'evaluating'!
eval: aString
	"interpret the Forth source and answer what it printed. An error clears the stacks, stops the
	evaluation and is signalled as a ForthError, with what was printed so far still in #output."
	| err |
	out := WriteStream on: String new.
	err := [[self evaluate: aString. nil] on: ForthStop do: [:e | nil]]
		on: Error do: [:e | self noteError: e. e].
	err notNil ifTrue: [
		self clearState.
		^(self errorFor: err) signal].
	^out contents!
valueOf: aString
	"the top of the stack after running the source, which is taken off"
	self eval: aString.
	^self pop!
input: aString
	"text for KEY and ACCEPT to read, as if typed; without it they ask the user"
	keyInput := ReadStream on: aString!
define: aName do: aBlock
	"add a word written in Smalltalk to this system only; the block is given the Forth system"
	| w |
	w := (ForthPrimitive named: aName) block: aBlock; yourself.
	dict at: aName asUppercase put: w.
	^w!
hasWord: aName
	^(self lookup: aName) notNil!
words
	"the names of all the words, sorted"
	^(dict keys asSortedCollection: [:a :b | a <= b]) asArray!
statusLine
	"what a terminal would show after a line has run: ok, and the stack if it is not empty"
	^stack isEmpty
		ifTrue: ['ok']
		ifFalse: ['ok  ', self stackText trimBoth]!
printOn: aStream
	aStream nextPutAll: 'a Forth (', dict size printString, ' words, ', stack size printString, ' on the stack)'! !

!Forth methodsFor: 'helpers for the words'!
divisor: b
	b = 0 ifTrue: [^self fail: 'division by zero' code: -10].
	^b!
wordNamed: aName
	| w |
	w := self lookup: aName.
	w isNil ifTrue: [^self fail: 'undefined word: ', aName code: -13].
	^w!
createWord: aName
	"a new word that leaves the address of its data area, which begins at HERE"
	| w |
	w := ForthCreated named: aName.
	w address: here.
	self enter: w.
	^w!
compileFloat: x
	body addLast: (ForthFloatLiteral value: x)!
currentDefinition
	^current!
openLoop: op
	| cell |
	self needCompiling.
	cell := ForthJump op: op.
	self compile: cell.
	self openControl: #do with: (Array with: self nextCell with: OrderedCollection new with: cell)!
closeLoop: op
	| e p exit |
	self needCompiling.
	e := self closeControl: #(#do).
	p := e at: 2.
	self compile: ((ForthJump op: op) target: (p at: 1); yourself).
	exit := self nextCell.
	(p at: 2) do: [:leave | leave target: exit].
	(p at: 3) op == #qdo ifTrue: [(p at: 3) target: exit]!
innermost: aTag
	"the innermost open control structure of that kind (a LEAVE may be inside IFs within its loop)"
	controls size to: 1 by: -1 do: [:i |
		((controls at: i) at: 1) == aTag ifTrue: [^controls at: i]].
	^self fail: 'control structure mismatch' code: -22!
skipConditional: stopAtElse
	"skip source words up to the matching [ELSE] (when that ends the skip) or [THEN]"
	| depth token u |
	depth := 0.
	[token := self parseName. token notNil] whileTrue: [
		u := token asUppercase.
		u = '[IF]' ifTrue: [depth := depth + 1].
		u = '[THEN]' ifTrue: [depth = 0 ifTrue: [^self] ifFalse: [depth := depth - 1]].
		(u = '[ELSE]' and: [depth = 0 and: [stopAtElse]]) ifTrue: [^self]].
	^self fail: 'unterminated [IF]' code: -22!
setDoesFor: def from: k
	"what DOES> does when the defining word runs: give the new word the rest of the definition as its
	behaviour, and end the defining word's own run here"
	(latest isKindOf: ForthCreated) ifFalse: [^self fail: 'DOES> needs a word made by CREATE' code: -32].
	latest does: (def body copyFrom: k to: def body size).
	self exitDefinition!
restoreDictionary: saved here: h
	dict := saved.
	here := h!
catch: xt
	"CATCH: run xt; push 0 if it finished, or the throw code (with the stacks put back as they were)"
	| depth rdepth fdepth err savedSource savedPos savedCode savedIp |
	depth := stack size.
	rdepth := rstack size.
	fdepth := fstack size.
	savedSource := source.
	savedPos := self pos.
	savedCode := code.
	savedIp := ip.
	err := [self execute: xt. nil] on: Error do: [:e | e].
	err isNil ifTrue: [^self push: 0].
	[stack size > depth] whileTrue: [stack removeLast].
	[stack size < depth] whileTrue: [stack addLast: 0].
	[rstack size > rdepth] whileTrue: [rstack removeLast].
	[fstack size > fdepth] whileTrue: [fstack removeLast].
	source := savedSource.
	self pos: savedPos.
	code := savedCode.
	ip := savedIp.
	self push: (self codeFor: err)!
moveCells: n from: src to: dst
	n <= 0 ifTrue: [^self].
	dst > src
		ifTrue: [n - 1 to: 0 by: -1 do: [:i | self store: (self fetch: src + i) at: dst + i]]
		ifFalse: [0 to: n - 1 do: [:i | self store: (self fetch: src + i) at: dst + i]]!
stackText
	"the data stack the way .S shows it"
	| ws |
	ws := WriteStream on: String new.
	ws nextPut: $<; print: stack size; nextPutAll: '> '.
	stack do: [:x | ws nextPutAll: (self numberString: x); space].
	^ws contents!
floatStackText
	| ws |
	ws := WriteStream on: String new.
	ws nextPut: $<; print: fstack size; nextPutAll: '> '.
	fstack do: [:x | ws nextPutAll: x printString; space].
	^ws contents!
nextInputLine
	"a line for ACCEPT and KEY: from the text given to #input:, or else asked of the user; nil when there is none"
	keyInput notNil ifTrue: [^keyInput atEnd ifTrue: [nil] ifFalse: [keyInput upTo: Character lf]].
	^Smalltalk promptFor: 'Forth input'!
nextKey
	| line c |
	keyBuffer isEmpty ifTrue: [
		line := self nextInputLine.
		line isNil ifTrue: [^-1].
		keyBuffer := line, (String with: Character lf)].
	c := keyBuffer first asInteger.
	keyBuffer := keyBuffer copyFrom: 2 to: keyBuffer size.
	^c!
startHold
	holdBuf := OrderedCollection new!
hold: aCode
	holdBuf isNil ifTrue: [^self fail: 'pictured numeric output outside <# and #>' code: -17].
	holdBuf addFirst: aCode!
holdText
	| ws |
	holdBuf isNil ifTrue: [^self fail: '#> without <#' code: -17].
	ws := WriteStream on: String new.
	holdBuf do: [:c | ws nextPut: (Character value: c)].
	holdBuf := nil.
	^ws contents!
countedString: aString
	"a counted string (the length in the first cell) in one of the two transient buffers"
	| a n |
	stringSlot := (stringSlot + 1) \\ 2.
	a := Forth stringBuffer + (stringSlot * 1024).
	n := aString size min: 255.
	self store: n at: a.
	self storeString: (aString copyFrom: 1 to: n) at: a + 1.
	^a!
includeFile: aPath
	| text |
	(FileStream exists: aPath) ifFalse: [^self fail: 'no such file: ', aPath code: -38].
	text := [FileStream contentsOf: aPath] on: Error do: [:e | ^self fail: 'cannot read ', aPath code: -37].
	^self evaluate: text!
evaluateSmalltalk: aString
	| r |
	r := nil evaluateSafely: aString.
	(r at: 1) ifFalse: [^self fail: 'Smalltalk could not read that: ', (r at: 2) code: -21].
	^r at: 2!
sendMessage
	"SEND ( receiver arg1 ... argN N c-addr u -- result )"
	| sel n args rcvr |
	sel := self popString asSymbol.
	n := self popInteger.
	sel numArgs = n ifFalse: [
		^self fail: 'the selector ', sel printString, ' takes ', sel numArgs printString,
			' argument(s), not ', n printString code: -21].
	args := Array new: n.
	n to: 1 by: -1 do: [:i | args at: i put: self pop].
	rcvr := self pop.
	^self push: ([rcvr perform: sel withArguments: args]
		on: MessageNotUnderstood
		do: [:e | e receiver == rcvr
			ifTrue: [self fail: rcvr printString, ' does not understand #', sel code: -21]
			ifFalse: [e pass]])! !

!Forth methodsFor: 'looking at words'!
wordList
	"all the words, sorted, wrapped to lines (what WORDS prints)"
	| ws col |
	ws := WriteStream on: String new.
	col := 0.
	self words do: [:k |
		col + k size + 1 > 72 ifTrue: [ws nl. col := 0].
		ws nextPutAll: k; space.
		col := col + k size + 1].
	ws nl.
	^ws contents!
decompile: aWord
	"what SEE shows of a word"
	| ws jumps |
	ws := WriteStream on: String new.
	(aWord isKindOf: ForthColon) ifFalse: [
		(aWord isKindOf: ForthValue) ifTrue: [
			ws nextPutAll: aWord describe; nextPutAll: ' is a VALUE, now '; print: (self fetch: aWord address); nl.
			^ws contents].
		(aWord isKindOf: ForthCreated) ifTrue: [
			ws nextPutAll: aWord describe; nextPutAll: ' is a CREATEd word; its data begins at address '; print: aWord address.
			aWord does notNil ifTrue: [ws nextPutAll: ' and it has a DOES> part of '; print: aWord does size; nextPutAll: ' cells'].
			ws nl.
			^ws contents].
		(aWord isKindOf: ForthLiteral) ifTrue: [
			ws nextPutAll: aWord describe; nextPutAll: ' is a constant: '; print: aWord value; nl.
			^ws contents].
		(aWord isKindOf: ForthDefer) ifTrue: [
			ws nextPutAll: aWord describe; nextPutAll: ' is a deferred word'.
			aWord action notNil ifTrue: [ws nextPutAll: ' that does '; nextPutAll: aWord action describe].
			ws nl.
			^ws contents].
		ws nextPutAll: aWord describe; nextPutAll: ' is a primitive word, written in Smalltalk'; nl.
		^ws contents].
	jumps := aWord body anySatisfy: [:c | c isKindOf: ForthJump].
	ws nextPutAll: ': '; nextPutAll: aWord describe.
	jumps
		ifTrue: [
			ws nl.
			aWord body doWithIndex: [:c :i |
				ws nextPutAll: '  '; nextPutAll: (i printString: 10); nextPutAll: '  '; nextPutAll: c describe; nl].
			ws nextPutAll: ';']
		ifFalse: [
			aWord body do: [:c | ws space; nextPutAll: c describe].
			ws nextPutAll: ' ;'].
	aWord isImmediate ifTrue: [ws nextPutAll: ' immediate'].
	ws nl.
	^ws contents! !
