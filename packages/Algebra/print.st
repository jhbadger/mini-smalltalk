"Printing: the text that reads back with the parser, LaTeX, and a two-dimensional rendering with fraction bars and raised
exponents. The text puts the highest powers first and the constant last, writes quotients as a/b, and keeps its
parentheses to the ones that are needed."

!SymExpr methodsFor: 'printing'!
text
	textCache isNil ifTrue: [textCache := self computeText].
	^textCache!
precedence
	"1 a sum, 2 a product or a fraction or a negative number, 3 a power, 4 anything that needs no brackets"
	^4!
textPrec: aLevel
	^self precedence < aLevel ifTrue: ['(', self text, ')'] ifFalse: [self text]!
latex
	^self computeLatex!
latexPrec: aLevel
	^self precedence < aLevel ifTrue: ['\left(', self computeLatex, '\right)'] ifFalse: [self computeLatex]!
pretty
	"the lines of the two-dimensional picture, as one string"
	| box ws |
	box := self box.
	ws := WriteStream on: String new.
	(box at: 1) do: [:line | ws nextPutAll: line] separatedBy: [ws nl].
	^ws contents!
isNegativeExponentPower
	^self isPow and: [self exponent isNum and: [self exponent value < 0]]! !

!SymNum methodsFor: 'printing'!
precedence
	^(value < 0 or: [value isFraction]) ifTrue: [2] ifFalse: [4]!
computeText
	value isFraction ifTrue: [^value numerator printString, '/', value denominator printString].
	^value printString!
computeLatex
	value isFraction ifTrue: [
		^(value < 0 ifTrue: ['-'] ifFalse: ['']), '\frac{', value numerator abs printString, '}{', value denominator printString, '}'].
	^value printString!
box
	^SymPretty text: self text! !

!SymSym methodsFor: 'printing'!
computeText
	^name!
computeLatex
	name = 'pi' ifTrue: [^'\pi'].
	name = 'oo' ifTrue: [^'\infty'].
	^name size > 1 ifTrue: ['\mathrm{', name, '}'] ifFalse: [name]!
box
	^SymPretty text: name! !

!SymFn methodsFor: 'printing'!
computeText
	(name = 'exp' and: [arg isOne]) ifTrue: [^'e'].
	^name, '(', arg text, ')'!
computeLatex
	(name = 'exp' and: [arg isOne]) ifTrue: [^'e'].
	name = 'exp' ifTrue: [^'e^{', arg computeLatex, '}'].
	name = 'abs' ifTrue: [^'\left|', arg computeLatex, '\right|'].
	name = 'asin' ifTrue: [^'\arcsin\left(', arg computeLatex, '\right)'].
	name = 'acos' ifTrue: [^'\arccos\left(', arg computeLatex, '\right)'].
	name = 'atan' ifTrue: [^'\arctan\left(', arg computeLatex, '\right)'].
	^'\', name, '\left(', arg computeLatex, '\right)'!
box
	(name = 'exp' and: [arg isOne]) ifTrue: [^SymPretty text: 'e'].
	^SymPretty hcat: (Array with: (SymPretty text: name) with: (SymPretty paren: arg box))! !

!SymAdd methodsFor: 'printing'!
precedence
	^1!
computeText
	| ws first |
	ws := WriteStream on: String new.
	first := true.
	terms do: [:t |
		first
			ifTrue: [ws nextPutAll: t text]
			ifFalse: [
				t isNegativeTerm
					ifTrue: [ws nextPutAll: ' - '; nextPutAll: (t negated textPrec: 2)]
					ifFalse: [ws nextPutAll: ' + '; nextPutAll: t text]].
		first := false].
	^ws contents!
computeLatex
	| ws first |
	ws := WriteStream on: String new.
	first := true.
	terms do: [:t |
		first
			ifTrue: [ws nextPutAll: t computeLatex]
			ifFalse: [
				t isNegativeTerm
					ifTrue: [ws nextPutAll: ' - '; nextPutAll: (t negated latexPrec: 2)]
					ifFalse: [ws nextPutAll: ' + '; nextPutAll: t computeLatex]].
		first := false].
	^ws contents!
box
	| parts first |
	parts := OrderedCollection new.
	first := true.
	terms do: [:t |
		first
			ifTrue: [parts add: t box]
			ifFalse: [
				t isNegativeTerm
					ifTrue: [parts add: (SymPretty text: ' - '); add: (t negated boxPrec: 2)]
					ifFalse: [parts add: (SymPretty text: ' + '); add: t box]].
		first := false].
	^SymPretty hcat: parts! !

!SymExpr methodsFor: 'pretty'!
boxPrec: aLevel
	^self precedence < aLevel ifTrue: [SymPretty paren: self box] ifFalse: [self box]! !

!SymMul methodsFor: 'printing'!
precedence
	^2!
splitFactors
	"an Array of the numerator factors and the denominator factors (as positive powers)"
	| num den |
	num := OrderedCollection new.
	den := OrderedCollection new.
	factors do: [:f |
		f isNum ifFalse: [
			f isNegativeExponentPower
				ifTrue: [den add: (SymExpr power: f base to: (SymExpr num: f exponent value negated))]
				ifFalse: [num add: f]]].
	^Array with: num with: den!
coefficientParts
	"the sign, the numerator and the denominator of the numeric coefficient"
	| c a |
	c := self coefficient.
	a := c abs.
	a isFraction ifTrue: [^Array with: (c < 0) with: a numerator with: a denominator].
	^Array with: (c < 0) with: a with: 1!
computeText
	| sp cp numParts denParts ws |
	sp := self splitFactors.
	cp := self coefficientParts.
	numParts := OrderedCollection new.
	((cp at: 2) ~= 1 or: [(sp at: 1) isEmpty]) ifTrue: [numParts add: (cp at: 2) printString].
	(sp at: 1) do: [:f | numParts add: (f textPrec: 3)].
	denParts := OrderedCollection new.
	(cp at: 3) ~= 1 ifTrue: [denParts add: (cp at: 3) printString].
	(sp at: 2) do: [:f | denParts add: (f textPrec: 3)].
	ws := WriteStream on: String new.
	(cp at: 1) ifTrue: [ws nextPut: $-].
	numParts do: [:p | ws nextPutAll: p] separatedBy: [ws nextPut: $*].
	denParts isEmpty ifFalse: [
		ws nextPut: $/.
		denParts size > 1 ifTrue: [ws nextPut: $(].
		denParts do: [:p | ws nextPutAll: p] separatedBy: [ws nextPut: $*].
		denParts size > 1 ifTrue: [ws nextPut: $)]].
	^ws contents!
computeLatex
	| sp cp numParts denParts ws np dp |
	sp := self splitFactors.
	cp := self coefficientParts.
	denParts := OrderedCollection new.
	(cp at: 3) ~= 1 ifTrue: [denParts add: (cp at: 3) printString].
	(sp at: 2) do: [:f | denParts add: f].
	np := ((cp at: 2) ~= 1 or: [(sp at: 1) isEmpty]) ifTrue: [(sp at: 1) size + 1] ifFalse: [(sp at: 1) size].
	numParts := OrderedCollection new.
	((cp at: 2) ~= 1 or: [(sp at: 1) isEmpty]) ifTrue: [numParts add: (cp at: 2) printString].
	(sp at: 1) do: [:f | numParts add: (f latexPrec: ((denParts notEmpty and: [np = 1]) ifTrue: [0] ifFalse: [3]))].
	ws := WriteStream on: String new.
	(cp at: 1) ifTrue: [ws nextPut: $-].
	denParts isEmpty
		ifTrue: [numParts do: [:p | ws nextPutAll: p] separatedBy: [ws nextPutAll: ' ']]
		ifFalse: [
			dp := denParts size = 1 ifTrue: [0] ifFalse: [3].
			ws nextPutAll: '\frac{'.
			numParts do: [:p | ws nextPutAll: p] separatedBy: [ws nextPutAll: ' '].
			ws nextPutAll: '}{'.
			denParts do: [:p | ws nextPutAll: (p isString ifTrue: [p] ifFalse: [p latexPrec: dp])] separatedBy: [ws nextPutAll: ' '].
			ws nextPut: $}].
	^ws contents!
box
	| sp cp numBoxes denBoxes num den np |
	sp := self splitFactors.
	cp := self coefficientParts.
	denBoxes := OrderedCollection new.
	(cp at: 3) ~= 1 ifTrue: [denBoxes add: (SymPretty text: (cp at: 3) printString)].
	(sp at: 2) do: [:f | denBoxes add: (f boxPrec: (denBoxes isEmpty ifTrue: [0] ifFalse: [3]))].
	denBoxes size > 1 ifTrue: [
		denBoxes := OrderedCollection new.
		(cp at: 3) ~= 1 ifTrue: [denBoxes add: (SymPretty text: (cp at: 3) printString)].
		(sp at: 2) do: [:f | denBoxes add: (f boxPrec: 3)]].
	np := ((cp at: 2) ~= 1 or: [(sp at: 1) isEmpty]) ifTrue: [(sp at: 1) size + 1] ifFalse: [(sp at: 1) size].
	numBoxes := OrderedCollection new.
	((cp at: 2) ~= 1 or: [(sp at: 1) isEmpty]) ifTrue: [numBoxes add: (SymPretty text: (cp at: 2) printString)].
	(sp at: 1) do: [:f | numBoxes add: (f boxPrec: ((denBoxes notEmpty and: [np = 1]) ifTrue: [0] ifFalse: [3]))].
	num := SymPretty hcat: (SymPretty join: numBoxes with: '*').
	denBoxes isEmpty ifTrue: [
		^(cp at: 1) ifTrue: [SymPretty hcat: (Array with: (SymPretty text: '-') with: num)] ifFalse: [num]].
	den := SymPretty hcat: (SymPretty join: denBoxes with: '*').
	num := SymPretty fraction: num over: den.
	^(cp at: 1) ifTrue: [SymPretty hcat: (Array with: (SymPretty text: '-') with: num)] ifFalse: [num]! !

!SymPow methodsFor: 'printing'!
precedence
	(exponent isNum and: [exponent value = (1/2)]) ifTrue: [^4].
	(exponent isNum and: [exponent value < 0]) ifTrue: [^2].
	^3!
computeText
	(exponent isNum and: [exponent value = (1/2)]) ifTrue: [^'sqrt(', base text, ')'].
	(exponent isNum and: [exponent value < 0])
		ifTrue: [^'1/', ((SymExpr power: base to: (SymExpr num: exponent value negated)) textPrec: 3)].
	^(base textPrec: 4), '^', (exponent textPrec: 4)!
computeLatex
	(exponent isNum and: [exponent value = (1/2)]) ifTrue: [^'\sqrt{', base computeLatex, '}'].
	(exponent isNum and: [exponent value < 0])
		ifTrue: [^'\frac{1}{', (SymExpr power: base to: (SymExpr num: exponent value negated)) computeLatex, '}'].
	^(base latexPrec: 4), '^{', exponent computeLatex, '}'!
box
	| b e |
	(exponent isNum and: [exponent value = (1/2)]) ifTrue: [
		^SymPretty hcat: (Array with: (SymPretty text: 'sqrt') with: (SymPretty paren: base box))].
	(exponent isNum and: [exponent value < 0]) ifTrue: [
		^SymPretty fraction: (SymPretty text: '1')
			over: ((SymExpr power: base to: (SymExpr num: exponent value negated)) boxPrec: 3)].
	b := base boxPrec: 4.
	e := exponent boxPrec: 4.
	^SymPretty raise: e onto: b! !

!SymPretty class methodsFor: 'boxes'!
text: aString
	^Array with: (Array with: aString) with: 0!
width: aBox
	^(aBox at: 1) inject: 0 into: [:m :l | m max: l size]!
blank: n
	^String new: n withAll: $ !
padded: aString to: w
	^aString, (self blank: w - aString size)!
hcat: boxes
	| above below h w lines |
	boxes isEmpty ifTrue: [^self text: ''].
	above := 0.
	below := 0.
	boxes do: [:b |
		above := above max: (b at: 2).
		below := below max: (b at: 1) size - (b at: 2) - 1].
	h := above + below + 1.
	lines := (1 to: h) collect: [:i | ''].
	boxes do: [:b | | top bl |
		w := self width: b.
		bl := b at: 2.
		top := above - bl.
		1 to: h do: [:i | | k |
			k := i - top.
			lines at: i put: (lines at: i), (self padded: ((k >= 1 and: [k <= (b at: 1) size]) ifTrue: [(b at: 1) at: k] ifFalse: ['']) to: w)]].
	^Array with: lines with: above!
join: boxes with: aString
	| out |
	out := OrderedCollection new.
	boxes do: [:b | out add: b] separatedBy: [out add: (self text: aString)].
	^out!
paren: aBox
	| h left right lines |
	h := (aBox at: 1) size.
	h = 1 ifTrue: [^self hcat: (Array with: (self text: '(') with: aBox with: (self text: ')'))].
	left := (1 to: h) collect: [:i | i = 1 ifTrue: ['/'] ifFalse: [i = h ifTrue: ['\'] ifFalse: ['|']]].
	right := (1 to: h) collect: [:i | i = 1 ifTrue: ['\'] ifFalse: [i = h ifTrue: ['/'] ifFalse: ['|']]].
	^self hcat: (Array with: (Array with: left with: (aBox at: 2)) with: aBox with: (Array with: right with: (aBox at: 2)))!
centered: aString in: w
	| left |
	left := (w - aString size) // 2.
	^self padded: (self blank: left), aString to: w!
fraction: num over: den
	| w lines |
	w := (self width: num) max: (self width: den).
	lines := OrderedCollection new.
	(num at: 1) do: [:l | lines add: (self centered: l in: w)].
	lines add: (String new: w withAll: $-).
	(den at: 1) do: [:l | lines add: (self centered: l in: w)].
	^Array with: lines asArray with: (num at: 1) size!
raise: expBox onto: baseBox
	| eh bw ew lines |
	eh := (expBox at: 1) size.
	bw := self width: baseBox.
	ew := self width: expBox.
	lines := OrderedCollection new.
	(expBox at: 1) do: [:l | lines add: (self blank: bw), (self padded: l to: ew)].
	(baseBox at: 1) do: [:l | lines add: (self padded: l to: bw), (self blank: ew)].
	^Array with: lines asArray with: (baseBox at: 2) + eh! !
