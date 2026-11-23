"The outer interpreter: taking the source a word at a time, deciding whether each is a word to run, a word to
compile, or a number, and reading numbers (integers in any base, doubles, floats). Also the helpers the
defining and control words use to build a definition."

!Forth methodsFor: 'interpreting'!
interpret
	"work through the source until it runs out"
	| token |
	[token := self parseName. token notNil] whileTrue: [self interpretToken: token]!
interpretToken: token
	| w |
	w := self lookup: token.
	w isNil ifTrue: [^self handleNumber: token].
	(self compiling and: [w isImmediate not])
		ifTrue: [body addLast: w]
		ifFalse: [w executeIn: self]!
lookup: aName
	^dict at: aName asUppercase ifAbsent: [nil]!
handleNumber: token
	| n parts |
	n := self parseNumber: token.
	n isNil ifTrue: [^self fail: 'undefined word: ', token code: -13].
	(n at: 1) == #float ifTrue: [
		^self compiling
			ifTrue: [body addLast: (ForthFloatLiteral value: (n at: 2))]
			ifFalse: [self fpush: (n at: 2)]].
	(n at: 1) == #double ifTrue: [
		parts := self splitDouble: (n at: 2).
		^self compiling
			ifTrue: [self compileLiteral: (parts at: 1); compileLiteral: (parts at: 2)]
			ifFalse: [self push: (parts at: 1); push: (parts at: 2)]].
	^self compiling
		ifTrue: [self compileLiteral: (n at: 2)]
		ifFalse: [self push: (n at: 2)]!
evaluate: aString
	"interpret Forth source; an error is passed on to the caller as it stands (eval: tidies up after one)"
	| oldSource oldPos |
	oldSource := source.
	oldPos := self pos.
	source := aString.
	self pos: 0.
	^[self interpret] ensure: [source := oldSource. self pos: oldPos]! !

!Forth methodsFor: 'compiling'!
compiling
	^(memory at: 2) ~= 0!
compile: aWord
	body addLast: aWord!
compileLiteral: x
	body addLast: (ForthLiteral value: x)!
needCompiling
	self compiling ifFalse: [^self fail: 'compile-only word used while interpreting' code: -14]!
nextCell
	"the index that the next compiled cell will have: where a jump forward lands"
	^body size + 1!
openControl: aSymbol with: anObject
	controls addLast: (Array with: aSymbol with: anObject)!
closeControl: validTags
	"take the innermost control structure off, checking that it is one of those that can be closed here"
	| entry |
	controls isEmpty ifTrue: [^self fail: 'control structure mismatch' code: -22].
	entry := controls last.
	(validTags includes: (entry at: 1)) ifFalse: [^self fail: 'control structure mismatch' code: -22].
	controls removeLast.
	^entry!
beginDefinition: aWord
	self compiling ifTrue: [^self fail: 'a definition is already open' code: -14].
	current := aWord.
	body := OrderedCollection new.
	controls := OrderedCollection new.
	memory at: 2 put: -1!
endDefinition
	"the ; word: close the definition and enter it in the dictionary"
	| w |
	self needCompiling.
	controls isEmpty ifFalse: [^self fail: 'unfinished control structure' code: -22].
	w := current.
	w body: body asArray.
	body := nil.
	current := nil.
	memory at: 2 put: 0.
	noname
		ifTrue: [noname := false. self push: w]
		ifFalse: [self enter: w]!
enter: aWord
	"make the word findable, and the latest one"
	aWord name notNil ifTrue: [dict at: aWord name asUppercase put: aWord].
	latest := aWord!
latest
	^latest!
beginNoname
	self beginDefinition: (ForthColon named: nil).
	noname := true! !

!Forth methodsFor: 'numbers'!
base
	| b |
	b := memory at: 3.
	(b isInteger and: [b >= 2 and: [b <= 36]]) ifFalse: [^self fail: 'BASE has to be between 2 and 36' code: -24].
	^b!
digitValue: aCharacter in: aBase
	"the value of that digit in the base, or -1 when it is not one"
	| v |
	v := aCharacter asInteger.
	(v >= 48 and: [v <= 57]) ifTrue: [v := v - 48]
		ifFalse: [(v >= 65 and: [v <= 90]) ifTrue: [v := v - 55]
			ifFalse: [(v >= 97 and: [v <= 122]) ifTrue: [v := v - 87] ifFalse: [v := -1]]].
	^v < aBase ifTrue: [v] ifFalse: [-1]!
integerFrom: aString base: aBase
	"the integer a string spells (an optional minus sign, then digits), or nil"
	| i n v neg d |
	n := aString size.
	n = 0 ifTrue: [^nil].
	i := 1.
	neg := false.
	(aString at: 1) = $- ifTrue: [neg := true. i := 2].
	i > n ifTrue: [^nil].
	v := 0.
	[i <= n] whileTrue: [
		d := self digitValue: (aString at: i) in: aBase.
		d < 0 ifTrue: [^nil].
		v := v * aBase + d.
		i := i + 1].
	^neg ifTrue: [v negated] ifFalse: [v]!
floatFrom: s
	"a floating-point number as Forth writes it: digits, a point, an E and an exponent. The E is what
	makes it a float; here digits with a point and more digits (1.5) do too. nil when the text is not one."
	| i n m scale seen neg eneg e d v |
	n := s size.
	i := 1.
	neg := false.
	(i <= n and: [(s at: i) = $- or: [(s at: i) = $+]]) ifTrue: [neg := (s at: i) = $-. i := i + 1].
	m := 0.
	scale := 0.
	seen := false.
	[i <= n and: [(s at: i) isDigit]] whileTrue: [
		m := m * 10 + ((s at: i) asInteger - 48).
		seen := true.
		i := i + 1].
	(i <= n and: [(s at: i) = $.]) ifTrue: [
		i := i + 1.
		[i <= n and: [(s at: i) isDigit]] whileTrue: [
			m := m * 10 + ((s at: i) asInteger - 48).
			scale := scale + 1.
			seen := true.
			i := i + 1]].
	seen ifFalse: [^nil].
	i > n ifTrue: [
		scale = 0 ifTrue: [^nil].
		v := (m / (10 raisedTo: scale)) asFloat.
		^neg ifTrue: [v negated] ifFalse: [v]].
	(s at: i) asLowercase = $e ifFalse: [^nil].
	i := i + 1.
	eneg := false.
	(i <= n and: [(s at: i) = $- or: [(s at: i) = $+]]) ifTrue: [eneg := (s at: i) = $-. i := i + 1].
	e := 0.
	[i <= n and: [(s at: i) isDigit]] whileTrue: [
		e := e * 10 + ((s at: i) asInteger - 48).
		i := i + 1].
	i <= n ifTrue: [^nil].
	e := (eneg ifTrue: [e negated] ifFalse: [e]) - scale.
	v := e >= 0
		ifTrue: [(m * (10 raisedTo: e)) asFloat]
		ifFalse: [(m / (10 raisedTo: e negated)) asFloat].
	^neg ifTrue: [v negated] ifFalse: [v]!
parseNumber: token
	"Array(#single n), Array(#double n), Array(#float x), or nil when the word is not a number.
	Prefixes $ (hex), # (decimal) and % (binary) override BASE, 'c' is a character, a trailing point
	makes a double, and a number with an E in it, or a point with digits after it, is a float (in base ten)."
	| s base v prefixed |
	s := token.
	(s size = 3 and: [(s at: 1) = $' and: [(s at: 3) = $']])
		ifTrue: [^Array with: #single with: (s at: 2) asInteger].
	base := self base.
	prefixed := false.
	(s size > 1 and: [(s at: 1) = $$]) ifTrue: [base := 16. prefixed := true].
	(s size > 1 and: [(s at: 1) = $#]) ifTrue: [base := 10. prefixed := true].
	(s size > 1 and: [(s at: 1) = $%]) ifTrue: [base := 2. prefixed := true].
	prefixed ifTrue: [s := s copyFrom: 2 to: s size].
	v := self integerFrom: s base: base.
	v notNil ifTrue: [^Array with: #single with: v].
	(s size > 1 and: [s last = $.]) ifTrue: [
		v := self integerFrom: (s copyFrom: 1 to: s size - 1) base: base.
		v notNil ifTrue: [^Array with: #double with: v]].
	(base = 10 and: [prefixed not]) ifTrue: [
		v := self floatFrom: s.
		v notNil ifTrue: [^Array with: #float with: v]].
	^nil!
numberString: x
	"how . shows a number: in the current base, and anything else as Smalltalk prints it"
	| b |
	x isInteger ifFalse: [^x printString].
	b := self base.
	^b = 10 ifTrue: [x printString] ifFalse: [x printString: b]!
unsignedString: x
	| u b |
	u := x \\ Forth two64.
	b := self base.
	^b = 10 ifTrue: [u printString] ifFalse: [u printString: b]! !

!Forth methodsFor: 'output'!
type: aString
	aString isWideString ifTrue: [self widenOutput].
	out nextPutAll: aString!
emit: code
	code > 255 ifTrue: [self widenOutput].
	out nextPut: (Character value: code)!
widenOutput
	"output that has to hold characters beyond Latin-1 moves to a WideString"
	| wide |
	out contents isWideString ifTrue: [^self].
	wide := WriteStream on: WideString new.
	wide nextPutAll: out contents.
	out := wide!
output
	"what has been printed since the last eval:"
	^out contents!
spaces: n
	n > 0 ifTrue: [out nextPutAll: (String new: n withAll: (Character value: 32))]!
column
	"how far along the current output line"
	| s i |
	s := out contents.
	i := s size.
	[i > 0 and: [(s at: i) ~= Character lf]] whileTrue: [i := i - 1].
	^s size - i! !
