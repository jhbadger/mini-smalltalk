"The Forth machine: its stacks and memory, reading the source text, the inner interpreter that runs a
compiled definition, and the errors."

!Forth class methodsFor: 'memory layout'!
tibStart
	"where SOURCE copies the text being interpreted"
	^16!
tibSize
	^8192!
padAddress
	^8208!
stringBuffer
	"two buffers of 1024 cells that S-quote and its friends use when they are not compiling"
	^8464!
holdAddress
	^10512!
dataStart
	"the first address ALLOT, CREATE and the comma hand out"
	^11000!
two64
	^18446744073709551616! !

!Forth methodsFor: 'initialising'!
initializeEmpty
	dict := Forth primitives copy.
	memory := Array new: 16384 withAll: 0.
	here := Forth dataStart.
	latest := nil.
	source := ''.
	out := WriteStream on: String new.
	keyInput := nil.
	keyBuffer := ''.
	stringSlot := 0.
	self clearState.
	memory at: 3 put: 10!
initializeFrom: aForth
	dict := aForth dictionary copy.
	memory := aForth memoryCopy.
	here := aForth here.
	latest := nil.
	source := ''.
	out := WriteStream on: String new.
	keyInput := nil.
	keyBuffer := ''.
	stringSlot := 0.
	self clearState.
	memory at: 3 put: 10!
clearState
	"what an error or ABORT does: forget the stacks and any half-made definition (the dictionary
	and the memory are kept)"
	stack := OrderedCollection new.
	rstack := OrderedCollection new.
	fstack := OrderedCollection new.
	controls := OrderedCollection new.
	body := nil.
	current := nil.
	noname := false.
	holdBuf := nil.
	code := nil.
	ip := 1.
	memory at: 1 put: 0.
	memory at: 2 put: 0!
dictionary
	^dict!
memoryCopy
	^memory copy!
here
	^here! !

!Forth methodsFor: 'the data stack'!
push: x
	stack addLast: x.
	^x!
pop
	stack isEmpty ifTrue: [^self underflow].
	^stack removeLast!
top
	stack isEmpty ifTrue: [^self underflow].
	^stack last!
popInteger
	| x |
	x := self pop.
	x isInteger ifFalse: [^self fail: 'an integer was expected, not ', x printString code: -24].
	^x!
depth
	^stack size!
stack
	"the data stack from the bottom up"
	^stack asArray!
stackList
	"the data stack as a mutable OrderedCollection, bottom first (what the primitives work on)"
	^stack!
flag: aBoolean
	^aBoolean ifTrue: [-1] ifFalse: [0]!
pickAt: n
	(n < 0 or: [n >= stack size]) ifTrue: [^self underflow].
	^stack at: stack size - n!
roll: n
	| x |
	(n < 0 or: [n >= stack size]) ifTrue: [^self underflow].
	x := stack at: stack size - n.
	stack removeIndex: stack size - n.
	stack addLast: x!
underflow
	^self fail: 'stack underflow' code: -4!
splitDouble: d
	"the two cells of a double-cell number: the low 64 bits (signed, as a cell is) and the rest"
	| lo |
	lo := d \\ Forth two64.
	lo >= (Forth two64 // 2) ifTrue: [lo := lo - Forth two64].
	^Array with: lo with: d // Forth two64!
dpush: d
	| parts |
	parts := self splitDouble: d.
	stack addLast: (parts at: 1); addLast: (parts at: 2)!
dpop
	| hi lo |
	hi := self popInteger.
	lo := self popInteger.
	^hi * Forth two64 + (lo \\ Forth two64)!
clear
	stack := OrderedCollection new! !

!Forth methodsFor: 'the return and floating-point stacks'!
rpush: x
	rstack addLast: x.
	^x!
rpop
	rstack isEmpty ifTrue: [^self fail: 'return stack underflow' code: -6].
	^rstack removeLast!
rtop
	rstack isEmpty ifTrue: [^self fail: 'return stack underflow' code: -6].
	^rstack last!
rstack
	^rstack!
loopIndex: n
	"I is 0, J is 1, K is 2: the index of the n-th enclosing loop"
	| at |
	at := rstack size - (2 * n).
	at < 1 ifTrue: [^self fail: 'no loop to take an index from' code: -6].
	^rstack at: at!
fpush: x
	fstack addLast: x.
	^x!
fpop
	fstack isEmpty ifTrue: [^self fail: 'floating-point stack underflow' code: -45].
	^fstack removeLast!
ftop
	fstack isEmpty ifTrue: [^self fail: 'floating-point stack underflow' code: -45].
	^fstack last!
fstackList
	^fstack!
floatStack
	^fstack asArray! !

!Forth methodsFor: 'memory'!
fetch: addr
	(addr isInteger and: [addr > 0 and: [addr <= memory size]])
		ifFalse: [^self fail: 'invalid memory address: ', addr printString code: -9].
	^memory at: addr!
store: x at: addr
	(addr isInteger and: [addr > 0 and: [addr <= memory size]])
		ifFalse: [^self fail: 'invalid memory address: ', addr printString code: -9].
	memory at: addr put: x.
	^x!
allot: n
	"reserve n cells at HERE"
	n isInteger ifFalse: [^self fail: 'an integer was expected' code: -24].
	here + n < Forth dataStart ifTrue: [^self fail: 'cannot give back more than has been allotted' code: -9].
	here := here + n.
	self ensureMemory!
ensureMemory
	| bigger |
	here + 64 > memory size ifFalse: [^self].
	bigger := Array new: (memory size * 2 max: here + 4096) withAll: 0.
	bigger replaceFrom: 1 to: memory size with: memory startingAt: 1.
	memory := bigger!
comma: x
	"store x at HERE and move on one cell"
	self ensureMemory.
	memory at: here put: x.
	here := here + 1!
stringAt: addr length: n
	"the n characters at addr as a String (a WideString when any of them is beyond Latin-1)"
	| codes wide result |
	n isInteger ifFalse: [^self fail: 'an integer was expected' code: -24].
	n < 0 ifTrue: [^self fail: 'negative string length' code: -24].
	codes := Array new: n.
	wide := false.
	1 to: n do: [:i |
		codes at: i put: (self fetch: addr + i - 1).
		(codes at: i) > 255 ifTrue: [wide := true]].
	result := wide ifTrue: [WideString new: n] ifFalse: [String new: n].
	1 to: n do: [:i | result at: i put: (Character value: (codes at: i))].
	^result!
storeString: aString at: addr
	1 to: aString size do: [:i | self store: (aString at: i) asInteger at: addr + i - 1]!
pushString: aString
	"leave a Smalltalk string on the stack as a Forth string, address and length. It goes into one of two
	buffers that take turns, so it is good until the next two such strings; use the comma word, or S-quote inside a
	definition, for one that has to last."
	| a |
	aString size > 1000
		ifTrue: [a := here. self allot: aString size]
		ifFalse: [
			stringSlot := (stringSlot + 1) \\ 2.
			a := Forth stringBuffer + (stringSlot * 1024)].
	self storeString: aString at: a.
	stack addLast: a; addLast: aString size!
popString
	| n a |
	n := self popInteger.
	a := self popInteger.
	^self stringAt: a length: n!
keepString: aString
	"copy a string into the dictionary for good and answer its address"
	| a |
	a := here.
	self allot: aString size.
	self storeString: aString at: a.
	^a! !

!Forth methodsFor: 'reading the source'!
pos
	"the value of >IN: how many characters of the source have been used"
	^memory at: 1!
pos: n
	memory at: 1 put: n!
source
	^source!
parseName
	"the next blank-delimited word of the source, or nil at the end of it"
	| start end n |
	n := source size.
	start := self pos.
	[start < n and: [(source at: start + 1) asInteger <= 32]] whileTrue: [start := start + 1].
	start >= n ifTrue: [self pos: n. ^nil].
	end := start.
	[end < n and: [(source at: end + 1) asInteger > 32]] whileTrue: [end := end + 1].
	self pos: (end + 1 min: n).
	tokenStart := start.
	lastToken := source copyFrom: start + 1 to: end.
	^lastToken!
parse: delimiter
	"the text up to the next delimiter (a character code), which is used up too"
	| start i n |
	n := source size.
	start := self pos.
	i := start.
	[i < n and: [(source at: i + 1) asInteger ~= delimiter]] whileTrue: [i := i + 1].
	self pos: (i + 1 min: n).
	^source copyFrom: start + 1 to: i!
parseWord: delimiter
	"WORD: skip leading delimiters, then parse"
	[self pos < source size and: [(source at: self pos + 1) asInteger = delimiter]]
		whileTrue: [self pos: self pos + 1].
	^self parse: delimiter!
needName
	"the next word, which has to be there"
	| n |
	n := self parseName.
	n isNil ifTrue: [^self fail: 'a name was expected' code: -16].
	^n!
currentLine
	"the line of the source that the last word came from"
	| n |
	n := 1.
	1 to: ((tokenStart ifNil: [0]) min: source size) do: [:i | (source at: i) = Character lf ifTrue: [n := n + 1]].
	^n!
errorLine
	^errorLine!
errorWord
	^errorWord! !

!Forth methodsFor: 'running'!
run: aBody
	"the inner interpreter: execute the cells of a compiled definition in turn"
	| savedCode savedIp n cell |
	savedCode := code.
	savedIp := ip.
	n := aBody size.
	code := aBody.
	ip := 1.
	[ip <= n] whileTrue: [
		cell := code at: ip.
		ip := ip + 1.
		cell executeIn: self].
	code := savedCode.
	ip := savedIp!
jumpTo: anIndex
	ip := anIndex!
exitDefinition
	ip := code size + 1!
startLoopSkipping: skip target: t
	| index limit |
	index := self pop.
	limit := self pop.
	(skip and: [index = limit]) ifTrue: [^ip := t].
	rstack addLast: limit; addLast: index!
loopBy: n target: t
	"the end of a DO loop: step the index and go round again unless it has crossed the limit"
	| old limit new |
	rstack size < 2 ifTrue: [^self fail: 'LOOP without DO' code: -6].
	old := rstack last.
	limit := rstack at: rstack size - 1.
	new := old + n.
	((old - limit) < 0) ~= ((new - limit) < 0)
		ifTrue: [rstack removeLast; removeLast]
		ifFalse: [rstack at: rstack size put: new. ip := t]!
leaveLoopTo: t
	rstack size < 2 ifTrue: [^self fail: 'LEAVE outside a loop' code: -6].
	rstack removeLast; removeLast.
	ip := t!
unloop
	rstack size < 2 ifTrue: [^self fail: 'UNLOOP outside a loop' code: -6].
	rstack removeLast; removeLast!
execute: aWord
	aWord isNil ifTrue: [^self fail: 'nothing to execute' code: -21].
	aWord executeIn: self! !

!Forth methodsFor: 'errors'!
fail: aString
	^ForthError new code: -1; signal: aString!
fail: aString code: anInteger
	^ForthError new code: anInteger; signal: aString!
messageForCode: n
	n = -1 ifTrue: [^'aborted'].
	n = -2 ifTrue: [^'aborted'].
	n = -3 ifTrue: [^'stack overflow'].
	n = -4 ifTrue: [^'stack underflow'].
	n = -5 ifTrue: [^'return stack overflow'].
	n = -6 ifTrue: [^'return stack underflow'].
	n = -9 ifTrue: [^'invalid memory address'].
	n = -10 ifTrue: [^'division by zero'].
	n = -13 ifTrue: [^'undefined word'].
	n = -14 ifTrue: [^'interpreting a compile-only word'].
	n = -16 ifTrue: [^'attempt to use a zero-length string as a name'].
	n = -21 ifTrue: [^'unsupported operation'].
	n = -22 ifTrue: [^'control structure mismatch'].
	n = -24 ifTrue: [^'invalid numeric argument'].
	n = -37 ifTrue: [^'file I/O exception'].
	n = -38 ifTrue: [^'non-existent file'].
	^'throw code ', n printString!
codeFor: anError
	"the throw code that stands for an error, whether the system's own or Smalltalk's"
	(anError isKindOf: ForthError) ifTrue: [^anError code].
	(anError isKindOf: ZeroDivide) ifTrue: [^-10].
	(anError isKindOf: SubscriptOutOfBounds) ifTrue: [^-9].
	^-1!
errorFor: anError
	"the ForthError that says what the error was"
	| text |
	text := anError messageText ifNil: ['error'].
	(anError isKindOf: MessageNotUnderstood)
		ifTrue: [text := 'a stack item is not the kind of thing that word works on (', text, ')'].
	^ForthError new code: (self codeFor: anError); messageText: text; yourself!
noteError: anError
	errorLine := self currentLine.
	errorWord := lastToken! !
