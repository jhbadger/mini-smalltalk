"Prolog reader: an operator table, a tokenizer and an operator-precedence parser for standard (Edinburgh/ISO) syntax -
atoms, quoted atoms, variables, integers (also 0'c 0x 0o 0b), floats, strings, lists, {}, comments, and user-defined operators."

Object subclass: #PrologOps instanceVariableNames: 'prefix infix postfix' classVariableNames: '' category: 'Prolog-Reader'!
Object subclass: #PrologToken instanceVariableNames: 'kind value layout functional' classVariableNames: '' category: 'Prolog-Reader'!
Object subclass: #PrologReader instanceVariableNames: 'text pos ops flags peeked varMap varList primary primaryPrec lastKind stopComma' classVariableNames: '' category: 'Prolog-Reader'!

!PrologOps class methodsFor: 'instance creation'!
new
	^self basicNew init; installDefaults; yourself! !

!PrologOps methodsFor: 'private'!
init
	prefix := Dictionary new. infix := Dictionary new. postfix := Dictionary new!
installDefaults
	#(#':-' #'-->') do: [:n | self add: 1200 type: #xfx name: n].
	#(#':-' #'?-') do: [:n | self add: 1200 type: #fx name: n].
	self add: 1100 type: #xfy name: #';'.
	self add: 1100 type: #xfy name: #'|'.
	self add: 1105 type: #xfy name: #'|'.
	#(#'->' #'*->') do: [:n | self add: 1050 type: #xfy name: n].
	self add: 1000 type: #xfy name: #','.
	self add: 990 type: #xfx name: #':='.
	self add: 900 type: #fy name: #'\+'.
	#(#'=' #'\=' #'==' #'\==' #'@<' #'@>' #'@=<' #'@>=' #'=..' #'is' #'=:=' #'=\=' #'<' #'>' #'=<' #'>=' #'>:<' #':<' #'as') do: [:n | self add: 700 type: #xfx name: n].
	self add: 600 type: #xfy name: #':'.
	#(#'+' #'-' #'/\' #'\/' #'xor') do: [:n | self add: 500 type: #yfx name: n].
	#(#'*' #'/' #'//' #'mod' #'rem' #'<<' #'>>' #'div' #'rdiv' #'divmod') do: [:n | self add: 400 type: #yfx name: n].
	self add: 200 type: #xfx name: #'**'.
	self add: 200 type: #xfy name: #'^'.
	#(#'-' #'+' #'\') do: [:n | self add: 200 type: #fy name: n].
	#(#'dynamic' #'discontiguous' #'initialization' #'module_transparent' #'multifile' #'public' #'thread_local' #'table') do: [:n | self add: 1150 type: #fx name: n]! !

!PrologOps methodsFor: 'operators'!
add: priority type: aType name: aName
	"priority 0 removes the operator"
	| table n |
	n := aName asSymbol.
	table := (aType == #fx or: [aType == #fy]) ifTrue: [prefix] ifFalse: [(aType == #xf or: [aType == #yf]) ifTrue: [postfix] ifFalse: [infix]].
	priority = 0
		ifTrue: [table removeKey: n ifAbsent: []]
		ifFalse: [table at: n put: (Array with: priority with: aType)]!
prefix: aName
	^prefix at: aName asSymbol ifAbsent: [nil]!
infix: aName
	^infix at: aName asSymbol ifAbsent: [nil]!
postfix: aName
	^postfix at: aName asSymbol ifAbsent: [nil]!
isOperator: aName
	| n |
	n := aName asSymbol.
	^(prefix includesKey: n) or: [(infix includesKey: n) or: [postfix includesKey: n]]!
allDo: aBlock
	"aBlock value: priority value: type value: name"
	#(#prefix #infix #postfix) do: [:which |
		| t |
		t := which == #prefix ifTrue: [prefix] ifFalse: [which == #infix ifTrue: [infix] ifFalse: [postfix]].
		t keysAndValuesDo: [:k :v | aBlock value: (v at: 1) value: (v at: 2) value: k]]! !

!PrologToken class methodsFor: 'instance creation'!
kind: aKind value: aValue
	^self basicNew setKind: aKind value: aValue! !

!PrologToken methodsFor: 'accessing'!
setKind: aKind value: aValue
	kind := aKind. value := aValue. layout := false. functional := false!
kind
	^kind!
value
	^value!
layout
	^layout!
layout: aBoolean
	layout := aBoolean!
functional
	^functional!
functional: aBoolean
	functional := aBoolean!
isPunct: aString
	^kind == #punct and: [value = aString]!
isTerminator
	"a token that cannot start a term"
	^kind == #end or: [kind == #eof or: [kind == #punct and: [#(')' ']' '}' ',' '|') includes: value]]]! !

!PrologReader class methodsFor: 'instance creation'!
on: aString ops: anOps flags: aDictionary
	^self basicNew setText: aString ops: anOps flags: aDictionary! !

!PrologReader methodsFor: 'private'!
setText: aString ops: anOps flags: aDictionary
	text := aString. pos := 1. ops := anOps. flags := aDictionary.
	varMap := Dictionary new. varList := OrderedCollection new. stopComma := false!
syntaxError: aMessage
	| near |
	near := text copyFrom: (pos - 10 max: 1) to: (pos + 10 min: text size).
	^PrologThrow ball: (PrologStruct functor: #error
		with: (PrologStruct functor: #syntax_error with: aMessage asSymbol)
		with: (PrologStruct functor: #context with: aMessage asString with: near))!
atEnd
	^pos > text size!
cur
	^pos <= text size ifTrue: [text at: pos] ifFalse: [nil]!
charAt: i
	^i <= text size ifTrue: [text at: i] ifFalse: [nil]!
isSymbolChar: c
	^c notNil and: ['+-*/\^<>=~:.?@#&$' includes: c]!
isAlnum: c
	^c notNil and: [c isLetter or: [c isDigit or: [c = $_]]]! !

!PrologReader methodsFor: 'tokenizing'!
skipLayout
	"skip white space and comments; true if anything was skipped"
	| start c |
	start := pos.
	[c := self cur.
	 c notNil and: [c isSeparator or: [c = $% or: [c = $/ and: [(self charAt: pos + 1) = $*]]]]] whileTrue: [
		c = $%
			ifTrue: [[self cur notNil and: [self cur ~= Character lf]] whileTrue: [pos := pos + 1]]
			ifFalse: [
				c = $/
					ifTrue: [
						pos := pos + 2.
						[self atEnd not and: [(self cur = $* and: [(self charAt: pos + 1) = $/]) not]] whileTrue: [pos := pos + 1].
						pos := pos + 2]
					ifFalse: [pos := pos + 1]]].
	^pos > start!
readToken
	"the next token (the source position moves past it)"
	| layout c tok start |
	layout := self skipLayout.
	c := self cur.
	c isNil ifTrue: [^(PrologToken kind: #eof value: nil) layout: layout; yourself].
	start := pos.
	tok := self scanToken: c.
	tok layout: layout.
	(tok kind == #atom or: [tok kind == #qatom]) ifTrue: [tok functional: self cur = $(].
	^tok!
scanToken: c
	| s |
	c isDigit ifTrue: [^self scanNumber].
	c = $_ ifTrue: [^self scanVariable].
	c isLetter ifTrue: [
		c isUppercase ifTrue: [^self scanVariable].
		s := self scanWord.
		^PrologToken kind: #atom value: s].
	c = $' ifTrue: [^PrologToken kind: #qatom value: (self scanQuoted: $')].
	c = $" ifTrue: [^PrologToken kind: #string value: (self scanQuoted: $")].
	c = $` ifTrue: [^PrologToken kind: #codes value: (self scanQuoted: $`)].
	('()[]{},|' includes: c) ifTrue: [
		pos := pos + 1.
		^PrologToken kind: #punct value: (String with: c)].
	c = $!! ifTrue: [pos := pos + 1. ^PrologToken kind: #atom value: '!!'].
	c = $; ifTrue: [pos := pos + 1. ^PrologToken kind: #atom value: ';'].
	(self isSymbolChar: c) ifTrue: [
		| start |
		start := pos.
		[self isSymbolChar: self cur] whileTrue: [pos := pos + 1].
		s := text copyFrom: start to: pos - 1.
		(s = '.' and: [self cur isNil or: [self cur isSeparator or: [self cur = $%]]]) ifTrue: [^PrologToken kind: #end value: '.'].
		^PrologToken kind: #atom value: s].
	pos := pos + 1.
	^self syntaxError: 'illegal character'!
scanWord
	| start |
	start := pos.
	[self isAlnum: self cur] whileTrue: [pos := pos + 1].
	^text copyFrom: start to: pos - 1!
scanVariable
	^PrologToken kind: #var value: self scanWord!
scanQuoted: quote
	"the contents of a quoted item; pos is on the opening quote"
	| out c |
	out := WriteStream on: (String new: 16).
	pos := pos + 1.
	[c := self cur.
	 c isNil ifTrue: [^self syntaxError: 'unterminated quoted'].
	 c = quote
		ifTrue: [
			(self charAt: pos + 1) = quote
				ifTrue: [out nextPut: quote. pos := pos + 2. true]
				ifFalse: [pos := pos + 1. false]]
		ifFalse: [
			c = $\ ifTrue: [self scanEscapeInto: out] ifFalse: [out nextPut: c. pos := pos + 1].
			true]] whileTrue.
	^out contents!
scanEscapeInto: out
	"pos is on a backslash"
	| c code |
	pos := pos + 1.
	c := self cur.
	c isNil ifTrue: [^self syntaxError: 'bad escape'].
	pos := pos + 1.
	c = $n ifTrue: [^out nextPut: Character lf].
	c = $t ifTrue: [^out nextPut: Character tab].
	c = $r ifTrue: [^out nextPut: (Character value: 13)].
	c = $a ifTrue: [^out nextPut: (Character value: 7)].
	c = $b ifTrue: [^out nextPut: (Character value: 8)].
	c = $f ifTrue: [^out nextPut: (Character value: 12)].
	c = $v ifTrue: [^out nextPut: (Character value: 11)].
	c = $0 ifTrue: [pos := pos - 1. ^self scanNumericEscapeInto: out base: 8].
	c = $e ifTrue: [^out nextPut: (Character value: 27)].
	c = $s ifTrue: [^out nextPut: $ ].
	c = $x ifTrue: [^self scanNumericEscapeInto: out base: 16].
	c isDigit ifTrue: [pos := pos - 1. ^self scanNumericEscapeInto: out base: 8].
	c = Character lf ifTrue: [^self].
	^out nextPut: c!
scanNumericEscapeInto: out base: base
	| code d |
	code := 0.
	[d := self cur. d notNil and: [(d digitValue between: 0 and: base - 1)]] whileTrue: [code := code * base + d digitValue. pos := pos + 1].
	self cur = $\ ifTrue: [pos := pos + 1].
	out nextPutAll: (Character value: code) utf8Encoded!
scanNumber
	"integers, floats, and the forms 0'c 0x1F 0o7 0b101"
	| start c n base d |
	start := pos.
	(self cur = $0 and: [(self charAt: pos + 1) = $']) ifTrue: [
		pos := pos + 2.
		c := self cur.
		c = $\
			ifTrue: [
				| tmp |
				tmp := WriteStream on: String new.
				self scanEscapeInto: tmp.
				^PrologToken kind: #int value: (tmp contents asWideString first value)]
			ifFalse: [
				(c = $' and: [(self charAt: pos + 1) = $']) ifTrue: [pos := pos + 2. ^PrologToken kind: #int value: 39].
				"a possibly multi-byte (UTF-8) character"
				d := self utf8CharAt: pos.
				^PrologToken kind: #int value: d]].
	(self cur = $0 and: [#($x $o $b) includes: (self charAt: pos + 1)]) ifTrue: [
		base := (self charAt: pos + 1) = $x ifTrue: [16] ifFalse: [(self charAt: pos + 1) = $o ifTrue: [8] ifFalse: [2]].
		((self charAt: pos + 2) notNil and: [(self charAt: pos + 2) digitValue between: 0 and: base - 1]) ifTrue: [
			pos := pos + 2. n := 0.
			[d := self cur. d notNil and: [d digitValue between: 0 and: base - 1]] whileTrue: [n := n * base + d digitValue. pos := pos + 1].
			^PrologToken kind: #int value: n]].
	n := 0.
	[self cur notNil and: [self cur isDigit]] whileTrue: [n := n * 10 + self cur digitValue. pos := pos + 1].
	"digit groups: 1 000 000 is not supported, but 1_000 is"
	[self cur = $_ and: [(self charAt: pos + 1) notNil and: [(self charAt: pos + 1) isDigit]]] whileTrue: [
		pos := pos + 1.
		[self cur notNil and: [self cur isDigit]] whileTrue: [n := n * 10 + self cur digitValue. pos := pos + 1]].
	(self cur = $. and: [(self charAt: pos + 1) notNil and: [(self charAt: pos + 1) isDigit]]) ifTrue: [
		pos := pos + 1.
		[self cur notNil and: [self cur isDigit]] whileTrue: [pos := pos + 1].
		self scanExponent.
		^PrologToken kind: #float value: (text copyFrom: start to: pos - 1) asNumber asFloat].
	(self cur = $e or: [self cur = $E]) ifTrue: [
		| save |
		save := pos.
		self scanExponent.
		pos > save ifTrue: [^PrologToken kind: #float value: (text copyFrom: start to: pos - 1) asNumber asFloat]].
	^PrologToken kind: #int value: n!
scanExponent
	"an optional e[+-]digits; leaves pos unchanged if there is none"
	| save |
	(self cur = $e or: [self cur = $E]) ifFalse: [^self].
	save := pos.
	pos := pos + 1.
	(self cur = $+ or: [self cur = $-]) ifTrue: [pos := pos + 1].
	(self cur notNil and: [self cur isDigit])
		ifTrue: [[self cur notNil and: [self cur isDigit]] whileTrue: [pos := pos + 1]]
		ifFalse: [pos := save]!
utf8CharAt: i
	"the code point of the (UTF-8) character at index i; pos moves past it"
	| b extra cp |
	b := (text at: i) value.
	extra := b >= 240 ifTrue: [3] ifFalse: [b >= 224 ifTrue: [2] ifFalse: [b >= 192 ifTrue: [1] ifFalse: [0]]].
	extra = 0 ifTrue: [pos := i + 1. ^b].
	cp := extra = 3 ifTrue: [b bitAnd: 7] ifFalse: [extra = 2 ifTrue: [b bitAnd: 15] ifFalse: [b bitAnd: 31]].
	1 to: extra do: [:k | cp := cp * 64 + (((self charAt: i + k) ifNil: [^b]) value bitAnd: 63)].
	pos := i + extra + 1.
	^cp! !

!PrologReader methodsFor: 'parsing'!
peek
	peeked isNil ifTrue: [peeked := self readToken].
	^peeked!
advance
	| t |
	t := self peek.
	peeked := nil.
	lastKind := t kind.
	^t!
expect: aString
	| t |
	t := self advance.
	(t isPunct: aString) ifFalse: [^self syntaxError: 'expected ', aString].
	^t!
variableNamed: aName
	| v |
	aName = '_' ifTrue: [^PrologVar new].
	^varMap at: aName ifAbsent: [
		v := PrologVar new.
		varMap at: aName put: v.
		varList add: aName -> v.
		v]!
variableBindings
	"Associations from names to variables, in order of appearance (anonymous variables excluded)"
	^varList!
readTerm
	"the next clause or term (ended by a full stop) or nil at the end of the text; raises a syntax_error exception, after skipping to the end of the offending clause"
	| t term |
	varMap := Dictionary new. varList := OrderedCollection new. lastKind := nil. stopComma := false.
	[t := self peek.
	 t kind == #eof ifTrue: [^nil].
	 term := self parse: 1200.
	 t := self advance.
	 t kind == #end ifFalse: [^self syntaxError: 'operator expected'].
	 ^term] on: PrologThrow do: [:e | self skipToEnd. e pass]!
skipToEnd
	"error recovery: skip to just after the next full stop (unless the error came right after one)"
	| t |
	peeked isNil ifTrue: [lastKind == #end ifTrue: [^self]].
	peeked notNil ifTrue: [
		t := peeked. peeked := nil.
		(t kind == #end or: [t kind == #eof]) ifTrue: [^self]].
	[[t := self readToken. t kind == #end or: [t kind == #eof]] whileFalse] on: PrologThrow do: [:e | pos := pos + 1. e retry]!
parse: maxPrec
	| left leftPrec tok name info pri type la ra right |
	self parsePrimary: maxPrec.
	left := primary. leftPrec := primaryPrec.
	[tok := self peek.
	 name := self infixNameFor: tok.
	 name notNil and: [((stopComma and: [tok kind == #punct]) not) and: [(info := ops infix: name) notNil]]] whileTrue: [
		pri := info at: 1. type := info at: 2.
		la := type == #yfx ifTrue: [pri] ifFalse: [pri - 1].
		ra := type == #xfy ifTrue: [pri] ifFalse: [pri - 1].
		(pri <= maxPrec and: [leftPrec <= la])
			ifFalse: [primary := left. primaryPrec := leftPrec. ^left].
		self advance.
		right := self parse: ra.
		name = '|' ifTrue: [name := ';'].
		left := PrologStruct functor: name asSymbol with: left with: right.
		leftPrec := pri].
	primary := left. primaryPrec := leftPrec.
	^left!
infixNameFor: tok
	"the name under which tok can act as an infix operator, or nil"
	(tok kind == #atom or: [tok kind == #qatom]) ifTrue: [^tok value].
	tok kind == #punct ifTrue: [(tok value = ',' or: [tok value = '|']) ifTrue: [^tok value]].
	^nil!
parseArgument
	"an argument of a compound term or list: any priority, but ',' and '|' end it (so f(a:-b) and f(a;b) are accepted)"
	| saved r |
	saved := stopComma.
	stopComma := true.
	r := self parse: 1200.
	stopComma := saved.
	^r!
parseNested: prec
	"a parenthesised or braced term: commas are operators again"
	| saved r |
	saved := stopComma.
	stopComma := false.
	r := self parse: prec.
	stopComma := saved.
	^r!
parsePrimary: maxPrec
	| tok name info next pri argMax operand |
	tok := self advance.
	tok kind == #int ifTrue: [primary := tok value. primaryPrec := 0. ^primary].
	tok kind == #float ifTrue: [primary := tok value. primaryPrec := 0. ^primary].
	tok kind == #string ifTrue: [primary := self stringTerm: tok value. primaryPrec := 0. ^primary].
	tok kind == #codes ifTrue: [primary := PrologStruct list: (tok value asWideString asArray collect: [:ch | ch value]). primaryPrec := 0. ^primary].
	tok kind == #var ifTrue: [primary := self variableNamed: tok value. primaryPrec := 0. ^primary].
	tok kind == #punct ifTrue: [^self parsePunct: tok].
	(tok kind == #atom or: [tok kind == #qatom]) ifFalse: [^self syntaxError: 'unexpected end of clause'].
	name := tok value.
	tok functional ifTrue: [^self parseCompound: name].
	"a negative number"
	(name = '-' and: [tok kind == #atom]) ifTrue: [
		next := self peek.
		((next kind == #int or: [next kind == #float]) and: [next layout not]) ifTrue: [
			self advance.
			primary := next value negated. primaryPrec := 0. ^primary]].
	(tok kind == #atom and: [(info := ops prefix: name) notNil]) ifTrue: [
		next := self peek.
		(self startsOperand: next) ifTrue: [
			pri := info at: 1.
			pri > maxPrec ifTrue: [pri := maxPrec].
			argMax := (info at: 2) == #fy ifTrue: [pri] ifFalse: [pri - 1].
			operand := self parse: argMax.
			primary := PrologStruct functor: name asSymbol with: operand. primaryPrec := pri. ^primary]].
	primary := name asSymbol. primaryPrec := 0.
	^primary!
startsOperand: next
	"can next begin the operand of a prefix operator?"
	| n |
	next isTerminator ifTrue: [^false].
	(next kind == #atom and: [next functional not]) ifTrue: [
		n := next value.
		((ops infix: n) notNil and: [(ops prefix: n) isNil]) ifTrue: [^false]].
	^true!
parseCompound: name
	| args t |
	self expect: '('.
	args := OrderedCollection new.
	[args add: self parseArgument.
	 t := self advance.
	 (t isPunct: ',')] whileTrue.
	(t isPunct: ')') ifFalse: [^self syntaxError: 'expected , or ) in arguments'].
	primary := PrologStruct functor: name asSymbol args: args asArray. primaryPrec := 0.
	^primary!
parsePunct: tok
	| v items t tail |
	v := tok value.
	v = '(' ifTrue: [
		primary := self parseNested: 1200.
		self expect: ')'.
		primaryPrec := 0. ^primary].
	v = '[' ifTrue: [
		(self peek isPunct: ']') ifTrue: [self advance. primary := #'[]'. primaryPrec := 0. ^primary].
		items := OrderedCollection new.
		[items add: self parseArgument.
		 (self peek isPunct: ',')] whileTrue: [self advance].
		tail := #'[]'.
		(self peek isPunct: '|') ifTrue: [self advance. tail := self parseArgument].
		self expect: ']'.
		primary := PrologStruct list: items tail: tail. primaryPrec := 0. ^primary].
	v = '{' ifTrue: [
		(self peek isPunct: '}') ifTrue: [self advance. primary := #'{}'. primaryPrec := 0. ^primary].
		t := self parseNested: 1200.
		self expect: '}'.
		primary := PrologStruct functor: #'{}' with: t. primaryPrec := 0. ^primary].
	^self syntaxError: 'unexpected ', v!
stringTerm: aString
	"a double-quoted item: a String, or codes/chars/atom according to the double_quotes flag"
	| mode |
	mode := flags at: #double_quotes ifAbsent: [#string].
	mode == #codes ifTrue: [^PrologStruct list: (aString asWideString asArray collect: [:c | c value])].
	mode == #chars ifTrue: [^PrologStruct list: (aString asWideString asArray collect: [:c | c asString asSymbol])].
	mode == #atom ifTrue: [^aString asSymbol].
	^aString! !
