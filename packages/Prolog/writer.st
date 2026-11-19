"Prolog writer: terms as text. write/1 style by default; quoted: true gives writeq/print style (atoms quoted where the reader would need it)."

Object subclass: #PrologWriter instanceVariableNames: 'quoted ignoreOps numberVars ops' classVariableNames: 'DefaultOps' category: 'Prolog-Writer'!

!PrologWriter class methodsFor: 'instance creation'!
new
	^self basicNew init!
defaultOps
	^DefaultOps ifNil: [DefaultOps := PrologOps new]!
atomText: aString quoted: aBoolean
	"aString as an atom, in quotes when quoted is true and the reader would need them"
	^aBoolean ifTrue: [self new quoteIfNeeded: aString] ifFalse: [aString]! !

!PrologWriter methodsFor: 'private'!
init
	quoted := false. ignoreOps := false. numberVars := true. ops := self class defaultOps!
isSymbolChar: c
	^'+-*/\^<>=~:.?@#&$' includes: c!
isAlnum: c
	^c isLetter or: [c isDigit or: [c = $_]]!
needsQuotes: s
	| c |
	s isEmpty ifTrue: [^true].
	(#('[]' '!!' ';' '{}') includes: s) ifTrue: [^false].
	c := s first.
	(c isLetter and: [c isLowercase]) ifTrue: [^(s allSatisfy: [:ch | self isAlnum: ch]) not].
	(self isSymbolChar: c) ifTrue: [^(s allSatisfy: [:ch | self isSymbolChar: ch]) not].
	^true!
quoteIfNeeded: s
	^(self needsQuotes: s) ifTrue: [self quote: s with: $'] ifFalse: [s]!
quote: s with: q
	| out |
	out := WriteStream on: (String new: s size + 2).
	out nextPut: q.
	s do: [:c |
		c = q ifTrue: [out nextPut: $\. out nextPut: q]
		ifFalse: [
			c = $\ ifTrue: [out nextPutAll: '\\']
			ifFalse: [
				c = Character lf ifTrue: [out nextPutAll: '\n']
				ifFalse: [c = Character tab ifTrue: [out nextPutAll: '\t'] ifFalse: [out nextPut: c]]]]].
	out nextPut: q.
	^out contents!
atomText: aSymbol
	^quoted ifTrue: [self quoteIfNeeded: aSymbol asString] ifFalse: [aSymbol asString]!
floatText: f
	f isNaN ifTrue: [^'nan'].
	f isInfinite ifTrue: [^f > 0 ifTrue: ['inf'] ifFalse: ['-inf']].
	^f printString!
isAlphaOperator: aString
	^aString first isLetter!
startsWithSymbolChar: s
	^s notEmpty and: [self isSymbolChar: s first]!
endsWithSymbolChar: s
	^s notEmpty and: [self isSymbolChar: s last]! !

!PrologWriter methodsFor: 'options'!
quoted: aBoolean
	quoted := aBoolean!
ignoreOps: aBoolean
	ignoreOps := aBoolean!
numberVars: aBoolean
	numberVars := aBoolean!
ops: aPrologOps
	ops := aPrologOps! !

!PrologWriter methodsFor: 'writing'!
stringFor: aTerm
	^self stringFor: aTerm prec: 1200!
stringFor: aTerm prec: p
	| x |
	x := aTerm plDeref.
	x isPrologVar ifTrue: [^'_G', x id printString].
	x isInteger ifTrue: [^x printString].
	x isFloat ifTrue: [^self floatText: x].
	x isSymbol ifTrue: [^self atomTermText: x prec: p].
	x isString ifTrue: [^quoted ifTrue: [self quote: x with: $"] ifFalse: [x]].
	x isPrologStruct ifTrue: [^self structText: x prec: p].
	^x printString!
atomTermText: aSymbol prec: p
	| t pri info |
	t := self atomText: aSymbol.
	pri := 0.
	info := ops infix: aSymbol asString.
	info notNil ifTrue: [pri := pri max: (info at: 1)].
	info := ops prefix: aSymbol asString.
	info notNil ifTrue: [pri := pri max: (info at: 1)].
	^pri > p ifTrue: ['(', t, ')'] ifFalse: [t]!
structText: s prec: p
	| f args n info text left right pri type la ra opText |
	f := s functor. args := s args. n := args size.
	(f == #'.' and: [n = 2]) ifTrue: [^self listText: s].
	(f == #'{}' and: [n = 1 and: [ignoreOps not]]) ifTrue: [^'{', (self stringFor: (args at: 1) prec: 1200), '}'].
	(numberVars and: [f == #'$VAR' and: [n = 1]]) ifTrue: [
		| v |
		v := (args at: 1) plDeref.
		v isInteger ifTrue: [^(String with: (Character value: 65 + (v \\ 26))), (v >= 26 ifTrue: [(v // 26) printString] ifFalse: [''])]].
	ignoreOps ifFalse: [
		n = 2 ifTrue: [
			info := ops infix: f asString.
			info notNil ifTrue: [
				pri := info at: 1. type := info at: 2.
				la := type == #yfx ifTrue: [pri] ifFalse: [pri - 1].
				ra := type == #xfy ifTrue: [pri] ifFalse: [pri - 1].
				left := self stringFor: (args at: 1) prec: la.
				right := self stringFor: (args at: 2) prec: ra.
				opText := self atomText: f.
				text := f == #',' ifTrue: [left, ',', right]
					ifFalse: [
						(self isAlphaOperator: f asString)
							ifTrue: [left, ' ', opText, ' ', right]
							ifFalse: [
								((self endsWithSymbolChar: left) ifTrue: [left, ' '] ifFalse: [left]),
								opText,
								((self startsWithSymbolChar: right) ifTrue: [' ', right] ifFalse: [right])]].
				^pri > p ifTrue: ['(', text, ')'] ifFalse: [text]]].
		n = 1 ifTrue: [
			info := ops prefix: f asString.
			(info notNil and: [(args at: 1) plDeref isNumber not or: [(f == #'-' or: [f == #'+']) not]]) ifTrue: [
				pri := info at: 1. type := info at: 2.
				ra := type == #fy ifTrue: [pri] ifFalse: [pri - 1].
				right := self stringFor: (args at: 1) prec: ra.
				opText := self atomText: f.
				text := (self isAlphaOperator: f asString)
					ifTrue: [opText, ' ', right]
					ifFalse: [opText, ((self startsWithSymbolChar: right) ifTrue: [' ', right] ifFalse: [right])].
				^pri > p ifTrue: ['(', text, ')'] ifFalse: [text]].
			(info notNil and: [(args at: 1) plDeref isNumber]) ifTrue: [
				text := (self atomText: f), ' ', (self stringFor: (args at: 1) prec: 200).
				^200 > p ifTrue: ['(', text, ')'] ifFalse: [text]]]].
	text := WriteStream on: (String new: 32).
	text nextPutAll: (self atomText: f); nextPut: $(.
	1 to: n do: [:i |
		i > 1 ifTrue: [text nextPut: $,].
		text nextPutAll: (self stringFor: (args at: i) prec: 999)].
	text nextPut: $).
	^text contents!
listText: aStruct
	| out t first |
	out := WriteStream on: (String new: 32).
	out nextPut: $[.
	t := aStruct.
	first := true.
	[t isPrologStruct and: [t isList]] whileTrue: [
		first ifFalse: [out nextPut: $,].
		first := false.
		out nextPutAll: (self stringFor: t first prec: 999).
		t := t second plDeref].
	t == #'[]' ifFalse: [out nextPut: $|. out nextPutAll: (self stringFor: t prec: 999)].
	out nextPut: $].
	^out contents! !
