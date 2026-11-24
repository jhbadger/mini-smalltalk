"The printer: display and write, answering Strings. write gives text that the reader reads back (strings quoted, characters
as #\x, odd symbols between bars); display gives the plain text."

!SchemePrinter class methodsFor: 'printing'!
write: anObject
	^self new setWrite: true; print: anObject; contents!
display: anObject
	^self new setWrite: false; print: anObject; contents!
reportString: anObject
	"how an error is reported: a condition's message and irritants, or what was raised"
	anObject class == SchemeCondition ifTrue: [^anObject reportString].
	^'uncaught raise: ', (self write: anObject)!
floatString: x
	x isNaN ifTrue: [^'+nan.0'].
	x isInfinite ifTrue: [^x > 0 ifTrue: ['+inf.0'] ifFalse: ['-inf.0']].
	^x printString!
numberString: x
	x isInteger ifTrue: [^x printString].
	x isFloat ifTrue: [^self floatString: x].
	^x numerator printString, '/', x denominator printString!
numberString: x radix: r
	"the number in another base (floats are always decimal)"
	x isFloat ifTrue: [^self floatString: x].
	x isInteger ifTrue: [^r = 10 ifTrue: [x printString] ifFalse: [(x printString: r) asLowercase]].
	^(self numberString: x numerator radix: r), '/', (self numberString: x denominator radix: r)!
charName: c
	"the name write uses after #\"
	| v |
	v := c value.
	v = 32 ifTrue: [^'space'].
	v = 10 ifTrue: [^'newline'].
	v = 9 ifTrue: [^'tab'].
	v = 13 ifTrue: [^'return'].
	v = 0 ifTrue: [^'null'].
	v = 127 ifTrue: [^'delete'].
	v = 27 ifTrue: [^'escape'].
	v = 8 ifTrue: [^'backspace'].
	v = 7 ifTrue: [^'alarm'].
	v < 32 ifTrue: [^'x', (v printString: 16) asLowercase].
	^String with: c! !

!SchemePrinter methodsFor: 'printing'!
setWrite: aBoolean
	write := aBoolean.
	out := WriteStream on: String new!
contents
	^out contents!
print: x
	| p |
	x == true ifTrue: [^out nextPutAll: '#t'].
	x == false ifTrue: [^out nextPutAll: '#f'].
	x isNumber ifTrue: [^out nextPutAll: (SchemePrinter numberString: x)].
	x isSymbol ifTrue: [^self printSymbol: x].
	x isString ifTrue: [^self printString: x].
	x isCharacter ifTrue: [^self printCharacter: x].
	x == SchemeNil ifTrue: [^out nextPutAll: '()'].
	x class == SchemePair ifTrue: [^self printPair: x].
	x class == Array ifTrue: [^self printVector: x].
	x == SchemeUnspec ifTrue: [^out nextPutAll: '#!!unspecific'].
	x == SchemeEofObject ifTrue: [^out nextPutAll: '#[eof]'].
	x == SchemeDefault ifTrue: [^out nextPutAll: '#!!default'].
	x class == SchemeClosure ifTrue: [^out nextPutAll: '#[compound-procedure '; nextPutAll: (x name ifNil: ['anonymous']); nextPut: $]].
	x class == SchemePrimitive ifTrue: [^out nextPutAll: '#[compiled-procedure '; nextPutAll: x name; nextPut: $]].
	x class == SchemeContinuation ifTrue: [^out nextPutAll: '#[continuation]'].
	x class == SchemeParameter ifTrue: [^out nextPutAll: '#[parameter]'].
	x class == SchemeCaseLambda ifTrue: [^out nextPutAll: '#[compound-procedure case-lambda]'].
	x class == SchemeRecord ifTrue: [^self printRecord: x].
	x class == SchemeValues ifTrue: [
		x items doWithIndex: [:each :i | i > 1 ifTrue: [out space]. self print: each].
		^self].
	x class == SchemeTable ifTrue: [^out nextPutAll: '#[hash-table '; print: x count; nextPut: $]].
	x class == SchemeCondition ifTrue: [^out nextPutAll: '#[condition '; nextPutAll: x kind asString; nextPut: $]].
	x class == SchemePromise ifTrue: [^out nextPutAll: '#[promise]'].
	x class == SchemeRecordType ifTrue: [^out nextPutAll: '#[record-type '; nextPutAll: x name; nextPut: $]].
	x class == SchemeEnvironment ifTrue: [^out nextPutAll: x printString].
	(x class == SchemeInPort or: [x class == SchemeOutPort]) ifTrue: [^out nextPutAll: x printString].
	^out nextPutAll: '#[st '; nextPutAll: x printString; nextPut: $]!
printSymbol: s
	| str |
	str := s asString.
	(write and: [self symbolNeedsBars: str]) ifFalse: [^out nextPutAll: str].
	out nextPut: $|.
	str do: [:c |
		(c = $| or: [c = $\]) ifTrue: [out nextPut: $\].
		out nextPut: c].
	out nextPut: $|!
symbolNeedsBars: str
	str isEmpty ifTrue: [^true].
	str do: [:c | (c isSeparator or: ['()";''`,|' includes: c]) ifTrue: [^true]].
	^(SchemeReader parseNumber: str radix: 10) notNil!
printString: s
	write ifFalse: [^out nextPutAll: s].
	out nextPut: $".
	s do: [:c |
		c = $" ifTrue: [out nextPutAll: '\"'] ifFalse: [
		c = $\ ifTrue: [out nextPutAll: '\\'] ifFalse: [
		c = Character nl ifTrue: [out nextPutAll: '\n'] ifFalse: [
		c = Character tab ifTrue: [out nextPutAll: '\t'] ifFalse: [
		c value = 13 ifTrue: [out nextPutAll: '\r'] ifFalse: [
		out nextPut: c]]]]]].
	out nextPut: $"!
printCharacter: c
	write ifFalse: [^out nextPut: c].
	out nextPutAll: '#\'; nextPutAll: (SchemePrinter charName: c)!
printVector: v
	out nextPutAll: '#('.
	1 to: v size do: [:i |
		i > 1 ifTrue: [out space].
		self print: (v at: i)].
	out nextPut: $)!
printRecord: r
	| t |
	t := r type.
	out nextPutAll: '#['; nextPutAll: t name.
	1 to: t fields size do: [:i |
		out space; nextPutAll: (t fields at: i) asString; nextPut: $=.
		self print: (r at: i)].
	out nextPut: $]!
abbreviationFor: p
	"the prefix that stands for (quote x) and friends, or nil"
	| h |
	h := p car.
	(h isSymbol and: [p cdr class == SchemePair and: [p cdr cdr == SchemeNil]]) ifFalse: [^nil].
	h == #quote ifTrue: [^''''].
	h == #quasiquote ifTrue: [^'`'].
	h == #unquote ifTrue: [^','].
	h == #'unquote-splicing' ifTrue: [^',@'].
	^nil!
printPair: p
	| q n pre |
	pre := self abbreviationFor: p.
	pre notNil ifTrue: [out nextPutAll: pre. ^self print: p cdr car].
	out nextPut: $(.
	q := p. n := 0.
	[q class == SchemePair] whileTrue: [
		n > 0 ifTrue: [out space].
		n := n + 1.
		n > 100000 ifTrue: [out nextPutAll: '...)'. ^self].
		self print: q car.
		q := q cdr].
	q == SchemeNil ifFalse: [out nextPutAll: ' . '. self print: q].
	out nextPut: $)! !
