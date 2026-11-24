"The expression trees. An expression is built only through the class-side constructors (sum:, product:,
power:to:, fn:of:), which put every result into a canonical form: sums are flattened with like terms collected and
the numbers folded, products are flattened with equal bases merged and the numbers folded, powers of numbers are
worked out (square roots come out as surds), and the usual identities are applied (x^0, x^1, sin(0), ln(exp(x)) ...).
Two expressions that are equal in this obvious sense have the same key, so = is a comparison of keys.  Nothing is
ever multiplied out or factored behind your back: that is what expand and factor are for."

!SymExpr class methodsFor: 'building'!
num: aNumber
	^SymNum new setValue: aNumber!
sym: aName
	^SymSym new setName: aName asString!
zero
	^self num: 0!
one
	^self num: 1!
minusOne
	^self num: -1!
half
	^self num: 1/2!
pi
	^self sym: 'pi'!
e
	^self fn: 'exp' of: self one!
i
	^self sym: 'i'!
infinity
	^self sym: 'oo'!
error: aString
	^SymError new signal: aString!
coerce: anObject
	"an expression from an expression, a number or a string to be read"
	(anObject isKindOf: SymExpr) ifTrue: [^anObject].
	anObject isNumber ifTrue: [^self num: anObject].
	anObject isString ifTrue: [^SymParser parse: anObject].
	^self error: 'cannot make an expression from ', anObject printString!
isExact: aNumber
	^aNumber isInteger or: [aNumber isFraction]! !

!SymExpr class methodsFor: 'sums'!
sum: aCollection
	| const pairs flat terms |
	const := 0.
	pairs := OrderedCollection new.
	flat := OrderedCollection new.
	aCollection do: [:each | | t |
		t := self coerce: each.
		t isAdd ifTrue: [flat addAll: t terms] ifFalse: [flat add: t]].
	flat do: [:t |
		t isNum
			ifTrue: [const := const + t value]
			ifFalse: [ | rest c p |
				rest := t nonNumericPart.
				c := t coefficient.
				p := pairs detect: [:each | (each at: 2) = rest] ifNone: [nil].
				p isNil
					ifTrue: [pairs add: (Array with: c with: rest)]
					ifFalse: [p at: 1 put: (p at: 1) + c]]].
	terms := OrderedCollection new.
	pairs do: [:p | (p at: 1) = 0 ifFalse: [terms add: (self scale: (p at: 2) by: (p at: 1))]].
	terms := self sortTerms: terms.
	const = 0 ifFalse: [terms := terms copyWith: (self num: const)].
	terms isEmpty ifTrue: [^self zero].
	terms size = 1 ifTrue: [^terms first].
	^SymAdd new setTerms: terms asArray!
scale: anExpression by: aNumber
	"aNumber times an expression that is not a number, without checking anything"
	aNumber = 1 ifTrue: [^anExpression].
	anExpression isMul
		ifTrue: [^SymMul new setFactors: (Array with: (self num: aNumber)), anExpression factors].
	^SymMul new setFactors: (Array with: (self num: aNumber) with: anExpression)!
sortTerms: aCollection
	| vars info |
	aCollection size < 2 ifTrue: [^aCollection asArray].
	vars := Set new.
	aCollection do: [:t | t collectMonomialVariablesInto: vars].
	vars := vars asArray sort: [:a :b | a <= b].
	info := (aCollection collect: [:t | Array with: (t monomialVector: vars) with: t with: t key]) asArray.
	info := info sort: [:a :b | self monomial: a before: b].
	^info collect: [:each | each at: 2]!
monomial: a before: b
	| va vb |
	va := a at: 1.
	vb := b at: 1.
	1 to: va size do: [:i | (va at: i) = (vb at: i) ifFalse: [^(va at: i) > (vb at: i)]].
	^(a at: 3) < (b at: 3)! !

!SymExpr class methodsFor: 'products'!
product: aCollection
	| coeff pairs flat expArgs results final refold |
	coeff := 1.
	pairs := OrderedCollection new.
	flat := OrderedCollection new.
	expArgs := OrderedCollection new.
	aCollection do: [:each | | t |
		t := self coerce: each.
		t isMul ifTrue: [flat addAll: t factors] ifFalse: [flat add: t]].
	flat do: [:f |
		f isNum
			ifTrue: [coeff := coeff * f value]
			ifFalse: [
				(f isFnNamed: 'exp')
					ifTrue: [expArgs add: f arg]
					ifFalse: [ | b e p |
						f isPow ifTrue: [b := f base. e := f exponent] ifFalse: [b := f. e := self one].
						p := pairs detect: [:x | (x at: 1) = b] ifNone: [nil].
						p isNil
							ifTrue: [pairs add: (Array with: b with: (OrderedCollection with: e))]
							ifFalse: [(p at: 2) add: e]]]].
	coeff = 0 ifTrue: [^self zero].
	pairs := self mergeRadicals: pairs.
	results := OrderedCollection new.
	expArgs isEmpty ifFalse: [results add: (self fn: 'exp' of: (self sum: expArgs))].
	pairs do: [:p | results add: (self power: (p at: 1) to: (self sum: (p at: 2)))].
	final := OrderedCollection new.
	refold := false.
	results do: [:r |
		r isNum
			ifTrue: [coeff := coeff * r value]
			ifFalse: [r isMul ifTrue: [refold := true]. final add: r]].
	refold ifTrue: [^self product: (final copyWith: (self num: coeff))].
	coeff = 0 ifTrue: [^self zero].
	final := self sortFactors: final.
	coeff = 1 ifFalse: [final := (Array with: (self num: coeff)), final].
	final isEmpty ifTrue: [^self one].
	final size = 1 ifTrue: [^final first].
	^SymMul new setFactors: final asArray!
mergeRadicals: pairs
	"powers of positive numbers with the same fractional exponent become one power: sqrt(2) sqrt(3) = sqrt(6)"
	| groups out |
	groups := Dictionary new.
	out := OrderedCollection new.
	pairs do: [:p | | b e |
		b := p at: 1.
		e := self sum: (p at: 2).
		(b isNum and: [(self isExact: b value) and: [b value > 0 and: [e isNum and: [e value isFraction]]]])
			ifTrue: [ | g |
				g := groups at: e value ifAbsentPut: [OrderedCollection new].
				g add: b value]
			ifFalse: [out add: p]].
	groups keysAndValuesDo: [:e :bases | | prod |
		prod := bases inject: 1 into: [:a :x | a * x].
		out add: (Array with: (self num: prod) with: (OrderedCollection with: (self num: e)))].
	^out!
sortFactors: aCollection
	^aCollection asArray sort: [:a :b | self factor: a before: b]!
factor: a before: b
	| ra rb ka kb |
	ra := a factorRank.
	rb := b factorRank.
	ra = rb ifFalse: [^ra < rb].
	ka := a sortBase key.
	kb := b sortBase key.
	ka = kb ifFalse: [^ka < kb].
	^a key < b key! !

!SymExpr class methodsFor: 'powers'!
power: aBase to: anExponent
	| b e |
	b := self coerce: aBase.
	e := self coerce: anExponent.
	e isZero ifTrue: [^self one].
	e isOne ifTrue: [^b].
	b isOne ifTrue: [^b].
	b isZero ifTrue: [
		e isNum ifTrue: [
			e value > 0 ifTrue: [^b].
			^self error: 'division by zero'].
		^SymPow new setBase: b exponent: e].
	b isNum ifTrue: [e isNum ifTrue: [^self numberPower: b value to: e value]].
	(b isPow and: [e isNum and: [e value isInteger]])
		ifTrue: [^self power: b base to: (self product: (Array with: b exponent with: e))].
	(b isMul and: [e isNum]) ifTrue: [
		e value isInteger
			ifTrue: [^self product: (b factors collect: [:f | self power: f to: e])].
		(self isExact: e value) ifTrue: [ | c |
			c := b coefficient.
			(c ~= 1 and: [(self isExact: c) and: [c > 0]])
				ifTrue: [^self product: (Array with: (self power: (self num: c) to: e)
					with: (self power: b nonNumericPart to: e))]]].
	(b isFnNamed: 'exp') ifTrue: [^self fn: 'exp' of: (self product: (Array with: b arg with: e))].
	(b isSym and: [b name = 'i' and: [e isNum and: [e value isInteger]]])
		ifTrue: [^self imaginaryPower: e value].
	^SymPow new setBase: b exponent: e!
imaginaryPower: anInteger
	| r |
	r := anInteger \\ 4.
	r = 0 ifTrue: [^self one].
	r = 1 ifTrue: [^self i].
	r = 2 ifTrue: [^self minusOne].
	^SymMul new setFactors: (Array with: self minusOne with: self i)!
numberPower: bv to: ev
	"a number to a number: exact when both are exact (surds stay as roots), otherwise a Float"
	(bv isFloat or: [ev isFloat]) ifTrue: [
		(bv < 0 and: [ev isInteger not and: [ev ~= ev truncated]])
			ifTrue: [^self error: 'the result is not a real number'].
		^self num: (ev = ev truncated
			ifTrue: [bv asFloat raisedTo: ev truncated]
			ifFalse: [bv asFloat raisedTo: ev asFloat])].
	ev isInteger ifTrue: [
		ev abs > 100000 ifTrue: [^self error: 'the exponent is too large'].
		^self num: (bv raisedTo: ev)].
	^self surdPower: bv to: ev!
surdPower: bv to: ev
	| p q k r c root coef resid |
	p := ev numerator.
	q := ev denominator.
	bv < 0 ifTrue: [
		q odd ifTrue: [
			^self product: (Array with: (self num: (-1 raisedTo: p abs))
				with: (self power: (self num: bv negated) to: (self num: ev)))].
		q = 2 ifTrue: [
			^self product: (Array with: (self imaginaryPower: p)
				with: (self power: (self num: bv negated) to: (self num: ev)))].
		^SymPow new setBase: (self num: bv) exponent: (self num: ev)].
	p < 0 ifTrue: [^self power: (self num: bv reciprocal) to: (self num: ev negated)].
	k := p // q.
	r := p \\ q.
	c := bv raisedTo: k.
	root := self rationalRoot: (bv raisedTo: r) index: q.
	coef := c * (root at: 1).
	resid := root at: 2.
	resid = 1 ifTrue: [^self num: coef].
	^self scale: (SymPow new setBase: (self num: resid) exponent: (self num: 1 / q)) by: coef!
rationalRoot: t index: q
	"t to the 1/q as a coefficient times the q-th root of an integer that has no q-th power in it"
	| n d bigN a |
	n := t numerator.
	d := t denominator.
	bigN := n * (d raisedTo: q - 1).
	a := self extractRoot: bigN index: q.
	^Array with: (a at: 1) / d with: (a at: 2)!
extractRoot: n index: q
	| a m p r pq |
	a := 1.
	m := n.
	p := 2.
	[p <= 1000 and: [(p raisedTo: q) <= m]] whileTrue: [
		pq := p raisedTo: q.
		[m \\ pq = 0] whileTrue: [m := m // pq. a := a * p].
		p := p + 1].
	m > 1 ifTrue: [
		r := self integerRoot: m index: q.
		(r raisedTo: q) = m ifTrue: [a := a * r. m := 1]].
	^Array with: a with: m!
integerRoot: n index: q
	"the largest integer whose q-th power is not more than n"
	| lo hi mid |
	n < 2 ifTrue: [^n].
	lo := 1.
	hi := 1 bitShift: (n highBit // q) + 1.
	[lo < hi] whileTrue: [
		mid := (lo + hi + 1) // 2.
		((mid raisedTo: q) <= n) ifTrue: [lo := mid] ifFalse: [hi := mid - 1]].
	^lo! !

!SymExpr class methodsFor: 'functions'!
fn: aName of: anArgument
	| a r |
	a := self coerce: anArgument.
	aName = 'sqrt' ifTrue: [^self power: a to: self half].
	(a isNum and: [a value isFloat]) ifTrue: [^self num: (self floatFn: aName of: a value)].
	r := self exactFn: aName of: a.
	r isNil ifFalse: [^r].
	^SymFn new setName: aName arg: a!
floatFn: aName of: x
	aName = 'sin' ifTrue: [^x sin].
	aName = 'cos' ifTrue: [^x cos].
	aName = 'tan' ifTrue: [^x tan].
	aName = 'asin' ifTrue: [x abs > 1 ifTrue: [^self error: 'asin is not real here']. ^x arcSin].
	aName = 'acos' ifTrue: [x abs > 1 ifTrue: [^self error: 'acos is not real here']. ^x arcCos].
	aName = 'atan' ifTrue: [^x arcTan].
	aName = 'sinh' ifTrue: [^x sinh].
	aName = 'cosh' ifTrue: [^x cosh].
	aName = 'tanh' ifTrue: [^x tanh].
	aName = 'exp' ifTrue: [^x exp].
	aName = 'ln' ifTrue: [x <= 0 ifTrue: [^self error: 'ln needs a positive number']. ^x ln].
	aName = 'abs' ifTrue: [^x abs].
	^self error: 'unknown function ', aName!
exactFn: aName of: a
	"the value of a function at an argument where it is known exactly, or nil"
	| r neg |
	aName = 'exp' ifTrue: [
		a isZero ifTrue: [^self one].
		(a isFnNamed: 'ln') ifTrue: [^a arg].
		^nil].
	aName = 'ln' ifTrue: [
		a isOne ifTrue: [^self zero].
		a isZero ifTrue: [^self error: 'ln(0) is not defined'].
		(a isFnNamed: 'exp') ifTrue: [^a arg].
		(a isNum and: [a value < 0]) ifTrue: [^self error: 'ln of a negative number is not real'].
		(a isNum and: [a value isInteger and: [a value > 3]]) ifTrue: [ | pp |
			pp := self perfectPowerOf: a value.
			pp isNil ifFalse: [^self product: (Array with: (self num: (pp at: 2)) with: (self fn: 'ln' of: (self num: (pp at: 1))))]].
		(a isNum and: [a value isFraction and: [a value numerator = 1]])
			ifTrue: [^(self fn: 'ln' of: (self num: a value denominator)) negated].
		^nil].
	aName = 'abs' ifTrue: [
		a isNum ifTrue: [^self num: a value abs].
		(a isSym and: [#('pi' 'oo') includes: a name]) ifTrue: [^a].
		(a isFnNamed: 'abs') ifTrue: [^a].
		(a isFnNamed: 'exp') ifTrue: [^a].
		(a isPow and: [a exponent isNum and: [a exponent value isInteger and: [a exponent value even]]]) ifTrue: [^a].
		(a isMul and: [a coefficient ~= 1]) ifTrue: [
			^self product: (Array with: (self num: a coefficient abs) with: (self fn: 'abs' of: a nonNumericPart))].
		^nil].
	a isZero ifTrue: [
		(#('sin' 'tan' 'asin' 'atan' 'sinh' 'tanh') includes: aName) ifTrue: [^self zero].
		(#('cos' 'cosh') includes: aName) ifTrue: [^self one].
		aName = 'acos' ifTrue: [^self product: (Array with: self half with: self pi)]].
	neg := (a isMul and: [a coefficient < 0]) or: [a isNum and: [a value < 0]].
	(neg and: [#('sin' 'tan' 'asin' 'atan' 'sinh' 'tanh') includes: aName])
		ifTrue: [^(self fn: aName of: a negated) negated].
	(neg and: [#('cos' 'cosh') includes: aName]) ifTrue: [^self fn: aName of: a negated].
	(#('sin' 'cos' 'tan') includes: aName) ifTrue: [
		r := self piMultiple: a.
		r isNil ifFalse: [
			aName = 'sin' ifTrue: [r := self sinPi: r].
			aName = 'cos' ifTrue: [r := self sinPi: r + (1/2)].
			aName = 'tan' ifTrue: [r := self tanPi: r].
			r isNil ifFalse: [^r]]].
	aName = 'sin' ifTrue: [
		(a isFnNamed: 'asin') ifTrue: [^a arg].
		(a isFnNamed: 'acos') ifTrue: [^self sqrtOneMinusSquare: a arg].
		(a isFnNamed: 'atan') ifTrue: [^self product: (Array with: a arg with: (self power: (self sum: (Array with: self one with: (self power: a arg to: 2))) to: (self num: -1/2)))]].
	aName = 'cos' ifTrue: [
		(a isFnNamed: 'acos') ifTrue: [^a arg].
		(a isFnNamed: 'asin') ifTrue: [^self sqrtOneMinusSquare: a arg].
		(a isFnNamed: 'atan') ifTrue: [^self power: (self sum: (Array with: self one with: (self power: a arg to: 2))) to: (self num: -1/2)]].
	(aName = 'tan' and: [a isFnNamed: 'atan']) ifTrue: [^a arg].
	(aName = 'asin' and: [a isNum]) ifTrue: [
		a value = 1 ifTrue: [^self product: (Array with: self half with: self pi)].
		a value = (1/2) ifTrue: [^self product: (Array with: (self num: 1/6) with: self pi)]].
	(aName = 'acos' and: [a isNum]) ifTrue: [
		a value = 1 ifTrue: [^self zero].
		a value = -1 ifTrue: [^self pi].
		a value = (1/2) ifTrue: [^self product: (Array with: (self num: 1/3) with: self pi)]].
	(aName = 'atan' and: [a isNum and: [a value = 1]]) ifTrue: [^self product: (Array with: (self num: 1/4) with: self pi)].
	(aName = 'sinh' and: [a isFnNamed: 'asinh']) ifTrue: [^a arg].
	^nil!
perfectPowerOf: n
	"Array (base exponent) with n = base^exponent and the exponent as large as possible, or nil"
	n highBit to: 2 by: -1 do: [:e | | r |
		r := self integerRoot: n index: e.
		((r raisedTo: e) = n and: [r > 1]) ifTrue: [^Array with: r with: e]].
	^nil!
sqrtOneMinusSquare: x
	^self power: (self sum: (Array with: self one with: (self power: x to: 2) negated)) to: self half!
piMultiple: a
	"the number r when a is r times pi, else nil"
	(a isSym and: [a name = 'pi']) ifTrue: [^1].
	(a isMul and: [a factors size = 2 and: [a factors first isNum and: [a factors last isSym]]]) ifTrue: [
		(a factors last name = 'pi' and: [self isExact: a factors first value]) ifTrue: [^a factors first value]].
	^nil!
sinPi: r
	"sin(r pi) for a rational r when r is a multiple of 1/12 that has a closed form with square roots, else nil"
	| n s |
	n := r * 12.
	n isInteger ifFalse: [^nil].
	n := n \\ 24.
	s := 1.
	n > 12 ifTrue: [s := -1. n := n - 12].
	n > 6 ifTrue: [n := 12 - n].
	n = 0 ifTrue: [^self zero].
	n = 2 ifTrue: [^self num: s / 2].
	n = 3 ifTrue: [^self scale: (self power: (self num: 2) to: self half) by: s / 2].
	n = 4 ifTrue: [^self scale: (self power: (self num: 3) to: self half) by: s / 2].
	n = 6 ifTrue: [^self num: s].
	^nil!
tanPi: r
	| s c |
	s := self sinPi: r.
	c := self sinPi: r + (1/2).
	(s isNil or: [c isNil]) ifTrue: [^nil].
	c isZero ifTrue: [^self error: 'tan is not defined there'].
	^self product: (Array with: s with: (self power: c to: -1))! !

!SymExpr methodsFor: 'testing'!
isNum
	^false!
isSym
	^false!
isAdd
	^false!
isMul
	^false!
isPow
	^false!
isFn
	^false!
isZero
	^false!
isOne
	^false!
isFnNamed: aName
	^false!
isConstantSymbol
	^false!
isInteger
	^false!
isRational
	^false!
isNegativeTerm
	^false!
isAtom
	^false! !

!SymExpr methodsFor: 'accessing'!
key
	keyCache isNil ifTrue: [keyCache := self computeKey].
	^keyCache!
= other
	^(other isKindOf: SymExpr) and: [self key = other key]!
hash
	^self key hash!
operands
	^#()!
coefficient
	^1!
nonNumericPart
	^self!
sortBase
	^self!
factorRank
	^2!
nodeCount
	sizeCache isNil ifTrue: [
		sizeCache := 1.
		self operands do: [:o | sizeCache := sizeCache + o nodeCount]].
	^sizeCache!
dependsOn: aName
	^self operands anySatisfy: [:o | o dependsOn: aName]!
freeOf: aName
	^(self dependsOn: aName) not!
collectSymbolsInto: aSet
	self operands do: [:o | o collectSymbolsInto: aSet]!
variables
	"the names of the symbols in it, in order (pi, e, i and oo are constants, not variables)"
	| s |
	s := Set new.
	self collectSymbolsInto: s.
	^s asArray sort: [:a :b | a <= b]!
isConstant
	^self variables isEmpty!
collectMonomialVariablesInto: aSet
	self operands do: [:o | o collectMonomialVariablesInto: aSet]!
monomialVector: vars
	"total degree followed by the exponent of each variable, for ordering the terms of a sum"
	| vec total idx |
	vec := Array new: vars size withAll: 0.
	total := 0.
	(self isMul ifTrue: [self factors] ifFalse: [Array with: self]) do: [:f |
		f isNum ifFalse: [
			(f isSym and: [(idx := vars indexOf: f name) > 0])
				ifTrue: [vec at: idx put: (vec at: idx) + 1. total := total + 1]
				ifFalse: [
					(f isPow and: [f base isSym and: [f exponent isNum and: [(idx := vars indexOf: f base name) > 0]]])
						ifTrue: [vec at: idx put: (vec at: idx) + f exponent value. total := total + f exponent value]
						ifFalse: [total := total + (1/2)]]]].
	^(Array with: total), vec!
mapChildren: aBlock
	^self!
substitute: aMap
	"replace what the map (a Dictionary from key to expression) mentions, everywhere at once"
	| r |
	r := aMap at: self key ifAbsent: [nil].
	r isNil ifFalse: [^r].
	^self mapChildren: [:c | c substitute: aMap]! !

!SymExpr methodsFor: 'arithmetic'!
+ other
	^SymExpr sum: (Array with: self with: other)!
- other
	^SymExpr sum: (Array with: self with: (SymExpr coerce: other) negated)!
* other
	^SymExpr product: (Array with: self with: other)!
/ other
	^SymExpr product: (Array with: self with: (SymExpr power: other to: -1))!
negated
	^SymExpr product: (Array with: SymExpr minusOne with: self)!
reciprocal
	^SymExpr power: self to: -1!
raisedTo: anExponent
	^SymExpr power: self to: anExponent!
squared
	^SymExpr power: self to: 2!
sqrt
	^SymExpr power: self to: SymExpr half!
printOn: aStream
	aStream nextPutAll: self text!
asString
	^self text!
displayString
	^self text!
displayNl
	Transcript showCr: self text! !

!SymNum class methodsFor: 'x'!
value: aNumber
	^SymExpr num: aNumber! !

!SymNum methodsFor: 'accessing'!
setValue: aNumber
	value := aNumber!
value
	^value!
isNum
	^true!
isZero
	^value = 0!
isOne
	^value = 1!
isInteger
	^value isInteger!
isRational
	^value isInteger or: [value isFraction]!
isAtom
	^value >= 0 and: [value isFraction not]!
isNegativeTerm
	^value < 0!
coefficient
	^value!
nonNumericPart
	^SymExpr one!
factorRank
	^0!
computeKey
	^'n', value printString!
dependsOn: aName
	^false!
collectSymbolsInto: aSet
	^self! !

!SymSym methodsFor: 'accessing'!
setName: aString
	name := aString!
name
	^name!
isSym
	^true!
isAtom
	^true!
isConstantSymbol
	^#('pi' 'i' 'oo') includes: name!
factorRank
	^1!
computeKey
	^'s', name!
dependsOn: aName
	^name = aName!
collectSymbolsInto: aSet
	self isConstantSymbol ifFalse: [aSet add: name]!
collectMonomialVariablesInto: aSet
	self isConstantSymbol ifFalse: [aSet add: name]! !

!SymAdd methodsFor: 'accessing'!
setTerms: anArray
	terms := anArray!
terms
	^terms!
isAdd
	^true!
operands
	^terms!
factorRank
	^3!
constantTerm
	^terms last isNum ifTrue: [terms last value] ifFalse: [0]!
computeKey
	| ws |
	ws := WriteStream on: String new.
	ws nextPutAll: '(+'.
	terms do: [:t | ws space; nextPutAll: t key].
	ws nextPut: $).
	^ws contents!
mapChildren: aBlock
	^SymExpr sum: (terms collect: aBlock)!
collectMonomialVariablesInto: aSet
	terms do: [:t | t collectMonomialVariablesInto: aSet]! !

!SymMul methodsFor: 'accessing'!
setFactors: anArray
	factors := anArray!
factors
	^factors!
isMul
	^true!
operands
	^factors!
coefficient
	^factors first isNum ifTrue: [factors first value] ifFalse: [1]!
nonNumericPart
	| rest |
	factors first isNum ifFalse: [^self].
	rest := factors copyFrom: 2 to: factors size.
	^rest size = 1 ifTrue: [rest first] ifFalse: [SymMul new setFactors: rest]!
isNegativeTerm
	^self coefficient < 0!
computeKey
	| ws |
	ws := WriteStream on: String new.
	ws nextPutAll: '(*'.
	factors do: [:t | ws space; nextPutAll: t key].
	ws nextPut: $).
	^ws contents!
mapChildren: aBlock
	^SymExpr product: (factors collect: aBlock)!
collectMonomialVariablesInto: aSet
	factors do: [:t | t collectMonomialVariablesInto: aSet]! !

!SymPow methodsFor: 'accessing'!
setBase: b exponent: e
	base := b.
	exponent := e!
base
	^base!
exponent
	^exponent!
isPow
	^true!
operands
	^Array with: base with: exponent!
sortBase
	^base!
factorRank
	^base factorRank!
computeKey
	^'(^ ', base key, ' ', exponent key, ')'!
mapChildren: aBlock
	^SymExpr power: (aBlock value: base) to: (aBlock value: exponent)!
collectMonomialVariablesInto: aSet
	base isSym ifTrue: [base collectMonomialVariablesInto: aSet]! !

!SymFn methodsFor: 'accessing'!
setName: aString arg: anExpression
	name := aString.
	arg := anExpression!
name
	^name!
arg
	^arg!
isFn
	^true!
isFnNamed: aName
	^name = aName!
operands
	^Array with: arg!
computeKey
	^'(f ', name, ' ', arg key, ')'!
mapChildren: aBlock
	^SymExpr fn: name of: (aBlock value: arg)!
collectMonomialVariablesInto: aSet
	^self! !
