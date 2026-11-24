"The reader: infix text such as  3x^2 + 2*x - 5,  sin(x)^2,  (x+1)(x-1),  x/(x+1),  2^-x,  sqrt(x),  pi,  e.
Juxtaposition is multiplication (2x, 2(x+1), (a+b)(a-b), x y), ^ binds tighter than * and / and is
right-associative, and -x^2 is -(x^2).  A name is a run of letters and digits, so xy is one symbol: write x*y or x y.
Decimals such as 0.25 are read as exact fractions.  e is the base of natural logarithms and i the square root of -1."

!SymParser class methodsFor: 'reading'!
parse: aString
	^self new parse: aString definitions: nil functions: nil!
parse: aString definitions: defs functions: funs
	^self new parse: aString definitions: defs functions: funs!
functionNames
	^#('sin' 'cos' 'tan' 'cot' 'sec' 'csc' 'asin' 'acos' 'atan' 'arcsin' 'arccos' 'arctan' 'sinh' 'cosh' 'tanh' 'exp' 'ln' 'log' 'sqrt' 'abs')!
splitEquation: aString
	"the text on each side of the = , or just the text if there is none"
	| depth |
	depth := 0.
	1 to: aString size do: [:i | | c |
		c := aString at: i.
		(c = $( ) ifTrue: [depth := depth + 1].
		(c = $) ) ifTrue: [depth := depth - 1].
		(c = $= and: [depth = 0]) ifTrue: [
			^Array with: (aString copyFrom: 1 to: i - 1) with: (aString copyFrom: i + 1 to: aString size)]].
	^Array with: aString! !

!SymParser methodsFor: 'reading'!
parse: aString definitions: d functions: f
	| r |
	source := aString.
	defs := d.
	funs := f.
	tokens := self tokenize: aString.
	pos := 1.
	r := self parseSum.
	self peekKind == #end ifFalse: [^self fail: 'unexpected ', self peekText].
	^r!
fail: aMessage
	^SymError new signal: 'cannot read ', source printString, ': ', aMessage!
tokenize: s
	| out i n c start |
	out := OrderedCollection new.
	i := 1.
	n := s size.
	[i <= n] whileTrue: [
		c := s at: i.
		c isSeparator
			ifTrue: [i := i + 1]
			ifFalse: [
				(c isDigit or: [c = $. and: [i < n and: [(s at: i + 1) isDigit]]])
					ifTrue: [ | r |
						r := self readNumber: s from: i.
						out add: (Array with: #n with: (r at: 1)).
						i := r at: 2]
					ifFalse: [
						c isLetter
							ifTrue: [
								start := i.
								[i <= n and: [(s at: i) isLetter or: [(s at: i) isDigit or: [(s at: i) = $_]]]] whileTrue: [i := i + 1].
								out add: (Array with: #id with: (s copyFrom: start to: i - 1))]
							ifFalse: [
								('+-*/^(),' includes: c)
									ifTrue: [out add: (Array with: #op with: (String with: c)). i := i + 1]
									ifFalse: [^self fail: 'unexpected character ', (String with: c)]]]]].
	out add: (Array with: #end with: '').
	^out!
readNumber: s from: start
	"answers the exact value and the index after it"
	| i n v frac scale |
	i := start.
	n := s size.
	v := 0.
	[i <= n and: [(s at: i) isDigit]] whileTrue: [v := v * 10 + (s at: i) digitValue. i := i + 1].
	(i < n and: [(s at: i) = $. and: [(s at: i + 1) isDigit]]) ifTrue: [
		i := i + 1.
		scale := 1.
		frac := 0.
		[i <= n and: [(s at: i) isDigit]] whileTrue: [
			frac := frac * 10 + (s at: i) digitValue.
			scale := scale * 10.
			i := i + 1].
		v := v + (frac / scale)].
	(i <= n and: [(s at: i) = $e or: [(s at: i) = $E]]) ifTrue: [ | j sign ex |
		j := i + 1.
		sign := 1.
		(j <= n and: [(s at: j) = $- or: [(s at: j) = $+]]) ifTrue: [(s at: j) = $- ifTrue: [sign := -1]. j := j + 1].
		(j <= n and: [(s at: j) isDigit]) ifTrue: [
			ex := 0.
			[j <= n and: [(s at: j) isDigit]] whileTrue: [ex := ex * 10 + (s at: j) digitValue. j := j + 1].
			v := v * (10 raisedTo: sign * ex).
			i := j]].
	^Array with: v with: i! !

!SymParser methodsFor: 'grammar'!
peekKind
	^(tokens at: pos) at: 1!
peekText
	| t |
	t := tokens at: pos.
	^(t at: 1) == #end ifTrue: ['the end of the text'] ifFalse: [(t at: 2) printString]!
peekIsOp: aString
	| t |
	t := tokens at: pos.
	^(t at: 1) == #op and: [(t at: 2) = aString]!
next
	| t |
	t := tokens at: pos.
	pos := pos + 1.
	^t!
expect: aString
	(self peekIsOp: aString) ifFalse: [^self fail: 'expected ', aString, ' but found ', self peekText].
	self next!
parseSum
	| acc |
	acc := self parseProduct.
	[(self peekIsOp: '+') or: [self peekIsOp: '-']] whileTrue: [
		(self next at: 2) = '+'
			ifTrue: [acc := acc + self parseProduct]
			ifFalse: [acc := acc - self parseProduct]].
	^acc!
parseProduct
	| acc |
	acc := self parseUnary.
	[true] whileTrue: [
		(self peekIsOp: '*')
			ifTrue: [self next. acc := acc * self parseUnary]
			ifFalse: [
				(self peekIsOp: '/')
					ifTrue: [self next. acc := acc / self parseUnary]
					ifFalse: [
						(self peekKind == #n or: [self peekKind == #id or: [self peekIsOp: '(']])
							ifTrue: [acc := acc * self parsePower]
							ifFalse: [^acc]]]]!
parseUnary
	(self peekIsOp: '-') ifTrue: [self next. ^self parseUnary negated].
	(self peekIsOp: '+') ifTrue: [self next. ^self parseUnary].
	^self parsePower!
parsePower
	| base |
	base := self parseAtom.
	(self peekIsOp: '^') ifTrue: [self next. ^base raisedTo: self parseUnary].
	^base!
parseAtom
	| t k v |
	t := self next.
	k := t at: 1.
	v := t at: 2.
	k == #n ifTrue: [^SymExpr num: v].
	k == #id ifTrue: [^self parseName: v].
	(k == #op and: [v = '(']) ifTrue: [ | r |
		r := self parseSum.
		self expect: ')'.
		^r].
	pos := pos - 1.
	self peekKind == #end ifTrue: [^self fail: 'the text ends too soon'].
	^self fail: 'unexpected ', self peekText!
parseName: aName
	| f args |
	(self peekIsOp: '(') ifTrue: [
		(funs notNil and: [funs includesKey: aName]) ifTrue: [^self callUser: aName].
		(SymParser functionNames includes: aName) ifTrue: [
			self next.
			args := self parseArguments.
			^self applyBuiltin: aName to: args]].
	aName = 'pi' ifTrue: [^SymExpr pi].
	aName = 'e' ifTrue: [^SymExpr e].
	aName = 'i' ifTrue: [^SymExpr i].
	aName = 'oo' ifTrue: [^SymExpr infinity].
	(SymParser functionNames includes: aName) ifTrue: [^self fail: aName, ' needs its argument in brackets, as in ', aName, '(x)'].
	(defs notNil and: [defs includesKey: aName]) ifTrue: [^defs at: aName].
	^SymExpr sym: aName!
parseArguments
	"after the opening bracket: the comma-separated expressions, and the closing bracket"
	| args |
	args := OrderedCollection new.
	[args add: self parseSum.
	self peekIsOp: ','] whileTrue: [self next].
	self expect: ')'.
	^args!
callUser: aName
	| spec params body args map |
	self next.
	spec := funs at: aName.
	params := spec at: 1.
	body := spec at: 2.
	args := self parseArguments.
	args size = params size ifFalse: [^self fail: aName, ' takes ', params size printString, ' argument(s)'].
	map := Dictionary new.
	params with: args do: [:p :a | map at: (SymExpr sym: p) key put: a].
	^body substitute: map!
applyBuiltin: aName to: args
	| n a |
	n := aName.
	n = 'arcsin' ifTrue: [n := 'asin'].
	n = 'arccos' ifTrue: [n := 'acos'].
	n = 'arctan' ifTrue: [n := 'atan'].
	(n = 'log' and: [args size = 2]) ifTrue: [
		^(SymExpr fn: 'ln' of: (args at: 2)) / (SymExpr fn: 'ln' of: (args at: 1))].
	args size = 1 ifFalse: [^self fail: aName, ' takes one argument'].
	a := args first.
	n = 'log' ifTrue: [n := 'ln'].
	n = 'cot' ifTrue: [^(SymExpr fn: 'tan' of: a) reciprocal].
	n = 'sec' ifTrue: [^(SymExpr fn: 'cos' of: a) reciprocal].
	n = 'csc' ifTrue: [^(SymExpr fn: 'sin' of: a) reciprocal].
	^SymExpr fn: n of: a! !
