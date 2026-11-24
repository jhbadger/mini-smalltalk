"The reader: text to Scheme data. Lists are SchemePairs, vectors Arrays, symbols Symbols (case is kept), strings Strings,
numbers Smalltalk numbers (integers, fractions, floats). Comments are ; to the end of the line, #| ... |# (they nest) and
#; before a datum."

!SchemeReader class methodsFor: 'reading'!
on: aString
	^self basicNew setText: aString position: 1!
on: aString position: anInteger
	^self basicNew setText: aString position: anInteger!
readAll: aString
	"every datum in the text, as an Array"
	| r out d |
	r := self on: aString.
	out := OrderedCollection new.
	[d := r read. d == SchemeEofObject] whileFalse: [out add: d].
	^out asArray!
readOne: aString
	^(self on: aString) read! !

!SchemeReader class methodsFor: 'numbers'!
digitOf: c radix: r
	"the value of the digit c in that base, or nil"
	| v |
	v := c value.
	(v >= 48 and: [v <= 57]) ifTrue: [v := v - 48] ifFalse: [
		(v >= 97 and: [v <= 122]) ifTrue: [v := v - 87] ifFalse: [
		(v >= 65 and: [v <= 90]) ifTrue: [v := v - 55] ifFalse: [^nil]]].
	^v < r ifTrue: [v] ifFalse: [nil]!
parseNumber: aString radix: aRadix
	"a number from its text, or nil when the text is not a number"
	| s r exact i sign body q |
	s := aString. r := aRadix. exact := nil.
	[s size >= 2 and: [s first = $#]] whileTrue: [
		| c |
		c := (s at: 2) asLowercase.
		c = $x ifTrue: [r := 16] ifFalse: [
		c = $b ifTrue: [r := 2] ifFalse: [
		c = $o ifTrue: [r := 8] ifFalse: [
		c = $d ifTrue: [r := 10] ifFalse: [
		c = $e ifTrue: [exact := true] ifFalse: [
		c = $i ifTrue: [exact := false] ifFalse: [^nil]]]]]].
		s := s copyFrom: 3 to: s size].
	s isEmpty ifTrue: [^nil].
	q := self parseReal: s radix: r.
	q isNil ifTrue: [^nil].
	exact == true ifTrue: [^q isFloat ifTrue: [q isNaN | q isInfinite ifTrue: [nil] ifFalse: [q asExactFraction]] ifFalse: [q]].
	exact == false ifTrue: [^q asFloat].
	^q!
parseReal: s radix: r
	| sign body slash num den |
	(s = '+inf.0') ifTrue: [^Float infinity].
	(s = '-inf.0') ifTrue: [^Float infinity negated].
	(s = '+nan.0' or: [s = '-nan.0']) ifTrue: [^Float nan].
	sign := 1. body := s.
	(s first = $+ or: [s first = $-]) ifTrue: [
		s first = $- ifTrue: [sign := -1].
		body := s copyFrom: 2 to: s size].
	body isEmpty ifTrue: [^nil].
	slash := body indexOf: $/.
	slash > 0 ifTrue: [
		num := self parseDigits: (body copyFrom: 1 to: slash - 1) radix: r.
		den := self parseDigits: (body copyFrom: slash + 1 to: body size) radix: r.
		(num isNil or: [den isNil or: [den = 0]]) ifTrue: [^nil].
		^(num / den) * sign].
	num := self parseDigits: body radix: r.
	num notNil ifTrue: [^num * sign].
	r = 10 ifFalse: [^nil].
	num := self parseDecimal: body.
	num isNil ifTrue: [^nil].
	^sign < 0 ifTrue: [num negated] ifFalse: [num]!
parseDigits: s radix: r
	| acc d |
	s isEmpty ifTrue: [^nil].
	acc := 0.
	s do: [:c |
		d := self digitOf: c radix: r.
		d isNil ifTrue: [^nil].
		acc := acc * r + d].
	^acc!
parseDecimal: s
	"digits, an optional point and fraction, an optional exponent: a Float"
	| i n mant digits frac exp esign any c scale value |
	i := 1. n := s size. mant := 0. frac := 0. any := false.
	[i <= n and: [(c := s at: i) isDigit]] whileTrue: [mant := mant * 10 + (c value - 48). any := true. i := i + 1].
	(i <= n and: [(s at: i) = $.]) ifTrue: [
		i := i + 1.
		[i <= n and: [(c := s at: i) isDigit]] whileTrue: [mant := mant * 10 + (c value - 48). frac := frac + 1. any := true. i := i + 1]].
	any ifFalse: [^nil].
	exp := 0.
	(i <= n and: [(s at: i) = $e or: [(s at: i) = $E]]) ifTrue: [
		i := i + 1. esign := 1.
		(i <= n and: [(s at: i) = $+ or: [(s at: i) = $-]]) ifTrue: [
			(s at: i) = $- ifTrue: [esign := -1].
			i := i + 1].
		i > n ifTrue: [^nil].
		[i <= n and: [(c := s at: i) isDigit]] whileTrue: [exp := exp * 10 + (c value - 48). i := i + 1].
		exp := exp * esign].
	i <= n ifTrue: [^nil].
	scale := exp - frac.
	mant = 0 ifTrue: [^0.0].
	scale > 400 ifTrue: [^Float infinity].
	scale < -800 ifTrue: [^0.0].
	value := scale >= 0 ifTrue: [mant * (10 raisedTo: scale)] ifFalse: [mant / (10 raisedTo: scale negated)].
	^value asFloat! !

!SchemeReader methodsFor: 'private'!
setText: aString position: anInteger
	text := aString. pos := anInteger!
position
	^pos!
fail: aString
	^SchemeError message: aString!
peekChar
	^pos <= text size ifTrue: [text at: pos] ifFalse: [nil]!
nextChar
	| c |
	c := self peekChar.
	c notNil ifTrue: [pos := pos + 1].
	^c!
isDelimiter: c
	^c isNil or: [c isSeparator or: ['()[]";''`,' includes: c]]!
skipAtmosphere
	"white space and comments"
	| c next |
	[c := self peekChar. c notNil] whileTrue: [
		next := pos < text size ifTrue: [text at: pos + 1] ifFalse: [nil].
		c isSeparator
			ifTrue: [pos := pos + 1]
			ifFalse: [
				c = $;
					ifTrue: [self skipLineComment]
					ifFalse: [
						(c = $# and: [next = $|])
							ifTrue: [self skipBlockComment]
							ifFalse: [
								(c = $# and: [next = $;])
									ifTrue: [pos := pos + 2. self readDatum]
									ifFalse: [^self]]]]]!
skipLineComment
	[self peekChar notNil and: [self peekChar ~= Character nl]] whileTrue: [pos := pos + 1]!
skipBlockComment
	| depth c |
	pos := pos + 2. depth := 1.
	[depth > 0] whileTrue: [
		c := self nextChar.
		c isNil ifTrue: [^self fail: 'unterminated block comment'].
		(c = $| and: [self peekChar = $#])
			ifTrue: [pos := pos + 1. depth := depth - 1]
			ifFalse: [
				(c = $# and: [self peekChar = $|])
					ifTrue: [pos := pos + 1. depth := depth + 1]]]!
token
	"the characters up to the next delimiter"
	| start |
	start := pos.
	[self isDelimiter: self peekChar] whileFalse: [pos := pos + 1].
	^text copyFrom: start to: pos - 1! !

!SchemeReader methodsFor: 'reading'!
read
	"the next datum, or the eof object when only atmosphere is left"
	self skipAtmosphere.
	self peekChar isNil ifTrue: [^SchemeEofObject].
	^self readDatum!
readDatum
	"a datum that must be there"
	| c |
	self skipAtmosphere.
	c := self nextChar.
	c isNil ifTrue: [^self fail: 'premature end of input'].
	(c = $( or: [c = $[]) ifTrue: [^self readListAfter: c].
	(c = $) or: [c = $]]) ifTrue: [^self fail: 'unbalanced close parenthesis'].
	c = $' ifTrue: [^SchemePair with: #quote with: self readDatum].
	c = $` ifTrue: [^SchemePair with: #quasiquote with: self readDatum].
	c = $, ifTrue: [
		self peekChar = $@ ifTrue: [pos := pos + 1. ^SchemePair with: #'unquote-splicing' with: self readDatum].
		^SchemePair with: #unquote with: self readDatum].
	c = $" ifTrue: [^self readString].
	c = $# ifTrue: [^self readHash].
	c = $| ifTrue: [pos := pos - 1. ^self readBarSymbol].
	pos := pos - 1.
	^self readAtom!
readListAfter: open
	| items tail c close |
	close := open = $( ifTrue: [$)] ifFalse: [$]].
	items := OrderedCollection new. tail := SchemeNil.
	[self skipAtmosphere.
	c := self peekChar.
	c isNil ifTrue: [^self fail: 'premature end of input: missing close parenthesis'].
	c = close or: [c = $) or: [c = $]]]] whileFalse: [
		(c = $. and: [pos < text size and: [self isDelimiter: (text at: pos + 1)]]) ifTrue: [
			pos := pos + 1.
			items isEmpty ifTrue: [^self fail: 'bad dot syntax'].
			tail := self readDatum.
			self skipAtmosphere.
			(self peekChar = close or: [self peekChar = $) or: [self peekChar = $]]]) ifFalse: [^self fail: 'bad dot syntax'].
			pos := pos + 1.
			^self finishList: items tail: tail] ifFalse: [
			items add: self readDatum]].
	pos := pos + 1.
	^self finishList: items tail: tail!
finishList: items tail: tail
	| l |
	l := tail.
	items size to: 1 by: -1 do: [:i | l := SchemePair car: (items at: i) cdr: l].
	^l!
readString
	| ws c |
	ws := WriteStream on: String new.
	[c := self nextChar.
	c isNil ifTrue: [^self fail: 'unterminated string'].
	c = $"] whileFalse: [
		c = $\ ifTrue: [self readEscapeInto: ws] ifFalse: [ws nextPut: c]].
	^ws contents!
readEscapeInto: ws
	| c hex d |
	c := self nextChar.
	c isNil ifTrue: [^self fail: 'unterminated string'].
	c = $n ifTrue: [^ws nextPut: Character nl].
	c = $t ifTrue: [^ws nextPut: Character tab].
	c = $r ifTrue: [^ws nextPut: (Character value: 13)].
	c = $a ifTrue: [^ws nextPut: (Character value: 7)].
	c = $0 ifTrue: [^ws nextPut: (Character value: 0)].
	c = $x ifTrue: [
		hex := 0.
		[c := self nextChar. c notNil and: [c ~= $;]] whileTrue: [
			d := SchemeReader digitOf: c radix: 16.
			d isNil ifTrue: [^self fail: 'bad \x escape in string'].
			hex := hex * 16 + d].
		^ws nextPut: (Character value: hex)].
	(c = Character nl or: [c isSeparator]) ifTrue: [
		"a backslash at the end of a line: skip the line break and the next line's indentation"
		[c ~= Character nl and: [self peekChar notNil and: [self peekChar isSeparator]]] whileTrue: [c := self nextChar].
		[self peekChar notNil and: [self peekChar isSeparator and: [self peekChar ~= Character nl]]] whileTrue: [pos := pos + 1].
		^self].
	^ws nextPut: c!
readHash
	"after a #"
	| c name tok n |
	c := self peekChar.
	c isNil ifTrue: [^self fail: 'bad # syntax'].
	c = $( ifTrue: [pos := pos + 1. ^(self readListAfter: $() asArray].
	c = $\ ifTrue: [pos := pos + 1. ^self readCharacter].
	c = (Character value: 33) ifTrue: [
		pos := pos + 1.
		tok := self token.
		tok = 'default' ifTrue: [^SchemeDefault].
		tok = 'eof' ifTrue: [^SchemeEofObject].
		tok = 'unspecific' ifTrue: [^SchemeUnspec].
		^(String with: $# with: (Character value: 33)), tok].
	tok := self token.
	(tok = 't' or: [tok = 'true']) ifTrue: [^true].
	(tok = 'f' or: [tok = 'false']) ifTrue: [^false].
	n := SchemeReader parseNumber: '#', tok radix: 10.
	n notNil ifTrue: [^n].
	^self fail: 'bad # syntax: #', tok!
readCharacter
	"after #\"
	| start tok c v |
	c := self nextChar.
	c isNil ifTrue: [^self fail: 'bad character syntax'].
	(self isDelimiter: self peekChar) ifTrue: [^c].
	pos := pos - 1.
	tok := self token.
	tok size = 1 ifTrue: [^tok first].
	tok := tok asLowercase.
	tok = 'space' ifTrue: [^Character space].
	(tok = 'newline' or: [tok = 'linefeed' or: [tok = 'nl']]) ifTrue: [^Character nl].
	tok = 'tab' ifTrue: [^Character tab].
	(tok = 'return' or: [tok = 'cr']) ifTrue: [^Character value: 13].
	(tok = 'null' or: [tok = 'nul']) ifTrue: [^Character value: 0].
	tok = 'alarm' ifTrue: [^Character value: 7].
	tok = 'backspace' ifTrue: [^Character value: 8].
	tok = 'delete' ifTrue: [^Character value: 127].
	(tok = 'escape' or: [tok = 'altmode']) ifTrue: [^Character value: 27].
	(tok first = $x and: [tok size > 1]) ifTrue: [
		v := SchemeReader parseDigits: (tok copyFrom: 2 to: tok size) radix: 16.
		v notNil ifTrue: [^Character value: v]].
	"a character outside ASCII followed by more text, as in #\λx: take just the first"
	^self fail: 'unknown character name: ', tok!
readBarSymbol
	| ws c |
	pos := pos + 1.
	ws := WriteStream on: String new.
	[c := self nextChar.
	c isNil ifTrue: [^self fail: 'unterminated |symbol|'].
	c = $|] whileFalse: [
		c = $\ ifTrue: [c := self nextChar].
		ws nextPut: c].
	^ws contents asSymbol!
readAtom
	| tok n |
	tok := self token.
	tok isEmpty ifTrue: [pos := pos + 1. ^self fail: 'unexpected character'].
	n := SchemeReader parseNumber: tok radix: 10.
	n notNil ifTrue: [^n].
	^tok asSymbol! !
