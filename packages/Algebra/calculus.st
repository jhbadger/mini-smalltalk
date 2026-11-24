"Calculus: derivatives, antiderivatives (a table of standard forms, linear and u substitution, integration by parts,
rational functions through partial fractions, reduction formulas for powers of sin and cos), definite integrals,
limits (substitution, cancelling, l'Hopital's rule, the exp-log rewriting of powers, a numeric look at the two sides to
decide on infinity), Taylor series, and finite sums."

!SymExpr methodsFor: 'derivatives'!
diffIn: aName
	"the derivative with respect to the symbol"
	^SymExpr zero!
diffIn: aName times: n
	| r |
	r := self.
	n timesRepeat: [r := r diffIn: aName].
	^r! !

!SymSym methodsFor: 'derivatives'!
diffIn: aName
	^name = aName ifTrue: [SymExpr one] ifFalse: [SymExpr zero]! !

!SymAdd methodsFor: 'derivatives'!
diffIn: aName
	^SymExpr sum: (terms collect: [:t | t diffIn: aName])! !

!SymMul methodsFor: 'derivatives'!
diffIn: aName
	^SymExpr sum: ((1 to: factors size) collect: [:i | | parts |
		parts := factors copy.
		parts at: i put: ((factors at: i) diffIn: aName).
		SymExpr product: parts])! !

!SymPow methodsFor: 'derivatives'!
diffIn: aName
	| db de |
	(exponent freeOf: aName) ifTrue: [
		db := base diffIn: aName.
		db isZero ifTrue: [^SymExpr zero].
		^SymExpr product: (Array with: exponent with: (SymExpr power: base to: exponent - 1) with: db)].
	de := exponent diffIn: aName.
	(base freeOf: aName) ifTrue: [
		^SymExpr product: (Array with: self with: (SymExpr fn: 'ln' of: base) with: de)].
	db := base diffIn: aName.
	^self * ((de * (SymExpr fn: 'ln' of: base)) + (exponent * db / base))! !

!SymFn methodsFor: 'derivatives'!
diffIn: aName
	| da |
	da := arg diffIn: aName.
	da isZero ifTrue: [^SymExpr zero].
	^da * self slope!
slope
	"the derivative of the function at its argument"
	| a one |
	a := arg.
	one := SymExpr one.
	name = 'sin' ifTrue: [^SymExpr fn: 'cos' of: a].
	name = 'cos' ifTrue: [^(SymExpr fn: 'sin' of: a) negated].
	name = 'tan' ifTrue: [^SymExpr power: (SymExpr fn: 'cos' of: a) to: -2].
	name = 'asin' ifTrue: [^SymExpr power: one - a squared to: (SymExpr num: -1/2)].
	name = 'acos' ifTrue: [^(SymExpr power: one - a squared to: (SymExpr num: -1/2)) negated].
	name = 'atan' ifTrue: [^SymExpr power: one + a squared to: -1].
	name = 'sinh' ifTrue: [^SymExpr fn: 'cosh' of: a].
	name = 'cosh' ifTrue: [^SymExpr fn: 'sinh' of: a].
	name = 'tanh' ifTrue: [^SymExpr power: (SymExpr fn: 'cosh' of: a) to: -2].
	name = 'exp' ifTrue: [^self].
	name = 'ln' ifTrue: [^SymExpr power: a to: -1].
	name = 'abs' ifTrue: [^a / self].
	^SymError new signal: 'cannot differentiate ', name! !

!SymExpr class methodsFor: 'integrals'!
integralOfFunction: aName at: u
	"an antiderivative with respect to u of the function, or nil"
	| one |
	one := SymExpr one.
	aName = 'sin' ifTrue: [^(SymExpr fn: 'cos' of: u) negated].
	aName = 'cos' ifTrue: [^SymExpr fn: 'sin' of: u].
	aName = 'tan' ifTrue: [^(SymExpr fn: 'ln' of: (SymExpr fn: 'cos' of: u)) negated].
	aName = 'exp' ifTrue: [^SymExpr fn: 'exp' of: u].
	aName = 'sinh' ifTrue: [^SymExpr fn: 'cosh' of: u].
	aName = 'cosh' ifTrue: [^SymExpr fn: 'sinh' of: u].
	aName = 'tanh' ifTrue: [^SymExpr fn: 'ln' of: (SymExpr fn: 'cosh' of: u)].
	aName = 'ln' ifTrue: [^(u * (SymExpr fn: 'ln' of: u)) - u].
	aName = 'atan' ifTrue: [^(u * (SymExpr fn: 'atan' of: u)) - ((SymExpr fn: 'ln' of: one + u squared) / 2)].
	aName = 'asin' ifTrue: [^(u * (SymExpr fn: 'asin' of: u)) + (one - u squared) sqrt].
	aName = 'acos' ifTrue: [^(u * (SymExpr fn: 'acos' of: u)) - (one - u squared) sqrt].
	^nil! !

!SymExpr methodsFor: 'integrals'!
linearForm: v
	"Array (slope intercept) when this is a x + c with a and c free of the symbol (and a not zero), else nil"
	| cs |
	(self dependsOn: v) ifFalse: [^nil].
	cs := self polyCoefficientsIn: v.
	(cs isNil or: [cs size ~= 2]) ifTrue: [^nil].
	(cs at: 2) isZero ifTrue: [^nil].
	^Array with: (cs at: 2) with: (cs at: 1)!
antiderivativeIn: v
	"an antiderivative with respect to the symbol, or nil when none is found (a constant of integration is never added)"
	^self antiderivativeIn: v depth: 0!
antiderivativeIn: v depth: depth
	| r consts rest e |
	depth > 9 ifTrue: [^nil].
	(self dependsOn: v) ifFalse: [^self * (SymExpr sym: v)].
	self isAdd ifTrue: [
		r := OrderedCollection new.
		self terms do: [:t | | a |
			a := t antiderivativeIn: v depth: depth + 1.
			a isNil ifTrue: [
				e := self expanded.
				(e = self or: [e isAdd not]) ifTrue: [^nil].
				^e antiderivativeIn: v depth: depth + 1].
			r add: a].
		^SymExpr sum: r].
	self isMul ifTrue: [
		consts := self factors select: [:f | f freeOf: v].
		consts isEmpty ifFalse: [
			rest := SymExpr product: (self factors reject: [:f | f freeOf: v]).
			r := rest antiderivativeIn: v depth: depth + 1.
			^r isNil ifTrue: [nil] ifFalse: [SymExpr product: (consts copyWith: r)]]].
	r := self tableIntegralIn: v.
	r isNil ifFalse: [^r].
	r := self trigIntegralIn: v depth: depth.
	r isNil ifFalse: [^r].
	r := self rationalIntegralIn: v depth: depth.
	r isNil ifFalse: [^r].
	r := self substitutionIntegralIn: v depth: depth.
	r isNil ifFalse: [^r].
	r := self partsIntegralIn: v depth: depth.
	r isNil ifFalse: [^r].
	e := self expanded.
	(e = self) ifFalse: [^e antiderivativeIn: v depth: depth + 1].
	^nil!
tableIntegralIn: v
	"the standard forms, also of a linear function of the symbol"
	| x lin b e e1 |
	x := SymExpr sym: v.
	self = x ifTrue: [^x squared / 2].
	self isFn ifTrue: [ | r |
		lin := self arg linearForm: v.
		lin isNil ifTrue: [^nil].
		r := SymExpr integralOfFunction: self name at: self arg.
		^r isNil ifTrue: [nil] ifFalse: [r / lin first]].
	self isPow ifTrue: [
		b := self base.
		e := self exponent.
		(e freeOf: v) ifTrue: [
			lin := b linearForm: v.
			lin notNil ifTrue: [
				e1 := e + 1.
				e1 isZero ifTrue: [^(SymExpr fn: 'ln' of: b) / lin first].
				^(SymExpr power: b to: e1) / (e1 * lin first)].
			(b = (SymExpr one - x squared)) ifTrue: [
				(e isNum and: [e value = (-1/2)]) ifTrue: [^SymExpr fn: 'asin' of: x].
				(e isNum and: [e value = (1/2)]) ifTrue: [
					^((x * (SymExpr one - x squared) sqrt) + (SymExpr fn: 'asin' of: x)) / 2]].
			^nil].
		(b freeOf: v) ifTrue: [
			lin := e linearForm: v.
			lin notNil ifTrue: [^self / (lin first * (SymExpr fn: 'ln' of: b))]]].
	^nil!
trigIntegralIn: v depth: depth
	"powers of sin and cos by the reduction formula, products of two of them as sums, exp times sin or cos"
	| fs n u lin a r kind m |
	self isPow ifTrue: [
		(self exponent isNum and: [self exponent value isInteger and: [self exponent value >= 2]]) ifFalse: [^nil].
		kind := self base.
		((kind isFnNamed: 'sin') or: [kind isFnNamed: 'cos']) ifFalse: [^nil].
		lin := kind arg linearForm: v.
		lin isNil ifTrue: [^nil].
		n := self exponent value.
		u := kind arg.
		a := lin first.
		m := SymExpr power: kind to: n - 2.
		r := m antiderivativeIn: v depth: depth + 1.
		r isNil ifTrue: [^nil].
		(kind isFnNamed: 'sin') ifTrue: [
			^((SymExpr power: kind to: n - 1) * (SymExpr fn: 'cos' of: u) negated / (a * n)) + (r * (n - 1) / n)].
		^((SymExpr power: kind to: n - 1) * (SymExpr fn: 'sin' of: u) / (a * n)) + (r * (n - 1) / n)].
	self isMul ifFalse: [^nil].
	fs := self factors.
	fs size = 2 ifFalse: [^nil].
	((fs first isFn and: [fs last isFn])) ifFalse: [^nil].
	"exp(u1) times sin(u2) or cos(u2)"
	(fs detect: [:f | f isFnNamed: 'exp'] ifNone: [nil]) notNil ifTrue: [ | ex tr l1 l2 |
		ex := fs detect: [:f | f isFnNamed: 'exp'].
		tr := fs detect: [:f | (f isFnNamed: 'sin') or: [f isFnNamed: 'cos']] ifNone: [^nil].
		l1 := ex arg linearForm: v.
		l2 := tr arg linearForm: v.
		(l1 isNil or: [l2 isNil]) ifTrue: [^nil].
		^(tr isFnNamed: 'sin')
			ifTrue: [(ex * (((l1 first * tr) - (l2 first * (SymExpr fn: 'cos' of: tr arg))))) / (l1 first squared + l2 first squared)]
			ifFalse: [(ex * (((l1 first * tr) + (l2 first * (SymExpr fn: 'sin' of: tr arg))))) / (l1 first squared + l2 first squared)]].
	"products of sin and cos of linear arguments: sums of sines and cosines"
	(fs allSatisfy: [:f | (f isFnNamed: 'sin') or: [f isFnNamed: 'cos']]) ifFalse: [^nil].
	((fs first arg linearForm: v) isNil or: [(fs last arg linearForm: v) isNil]) ifTrue: [^nil].
	^(SymExpr sum: (self productToSum: fs first with: fs last)) antiderivativeIn: v depth: depth + 1!
productToSum: f with: g
	"the terms of sin/cos(A) times sin/cos(B) as sines and cosines of A+B and A-B"
	| a b half |
	a := f arg.
	b := g arg.
	half := SymExpr half.
	(f isFnNamed: 'sin') ifTrue: [
		(g isFnNamed: 'cos') ifTrue: [^Array with: half * (SymExpr fn: 'sin' of: a + b) with: half * (SymExpr fn: 'sin' of: a - b)].
		^Array with: half * (SymExpr fn: 'cos' of: a - b) with: half negated * (SymExpr fn: 'cos' of: a + b)].
	(g isFnNamed: 'cos') ifTrue: [^Array with: half * (SymExpr fn: 'cos' of: a + b) with: half * (SymExpr fn: 'cos' of: a - b)].
	^Array with: half * (SymExpr fn: 'sin' of: a + b) with: half negated * (SymExpr fn: 'sin' of: a - b)!
rationalIntegralIn: v depth: depth
	| nd pn pd parts r |
	nd := self numerDenom.
	pn := nd first expanded asPolyIn: v.
	pd := nd last expanded asPolyIn: v.
	(pn isNil or: [pd isNil or: [pd degree < 1]]) ifTrue: [^nil].
	r := self quadraticTermIn: v.
	r isNil ifFalse: [^r].
	parts := [self apartIn: v] on: SymError do: [:e | ^nil].
	parts = self ifTrue: [^nil].
	^parts antiderivativeIn: v depth: depth + 1!
quadraticTermIn: v
	"(M x + K) / (c p^j) for an irreducible quadratic p: logarithm, arctangent and the reduction formula"
	| nd pn pd fac f j c x p a b cc m k part1 part2 coef |
	nd := self numerDenom.
	pn := nd first expanded asPolyIn: v.
	pd := nd last expanded asPolyIn: v.
	(pn isNil or: [pd isNil]) ifTrue: [^nil].
	pn degree > 1 ifTrue: [^nil].
	fac := pd factor.
	(fac at: 2) size = 1 ifFalse: [^nil].
	f := (fac at: 2) first at: 1.
	j := (fac at: 2) first at: 2.
	f degree = 2 ifFalse: [^nil].
	c := fac at: 1.
	a := f coeffAt: 2.
	b := f coeffAt: 1.
	cc := f coeffAt: 0.
	m := (pn coeffAt: 1) / c.
	k := (pn coeffAt: 0) / c.
	x := SymExpr sym: v.
	p := f asExprIn: v.
	part1 := SymExpr zero.
	m = 0 ifFalse: [
		j = 1
			ifTrue: [part1 := (SymExpr num: m / (2 * a)) * (SymExpr fn: 'ln' of: p)]
			ifFalse: [part1 := (SymExpr num: m / (2 * a)) * (SymExpr power: p to: 1 - j) / (1 - j)]].
	coef := k - (m * b / (2 * a)).
	part2 := SymExpr zero.
	coef = 0 ifFalse: [part2 := (SymExpr num: coef) * (self inverseQuadraticPower: j a: a b: b c: cc in: x p: p)].
	^part1 + part2!
inverseQuadraticPower: j a: a b: b c: c in: x p: p
	"the integral of 1/(a x^2 + b x + c)^j"
	| d first s lin r |
	d := 4 * a * c - (b * b).
	lin := (SymExpr num: 2 * a) * x + b.
	d > 0
		ifTrue: [
			s := SymExpr power: (SymExpr num: d) to: SymExpr half.
			first := ((SymExpr num: 2) / s) * (SymExpr fn: 'atan' of: (lin / s) factored)]
		ifFalse: [
			s := SymExpr power: (SymExpr num: d negated) to: SymExpr half.
			first := (SymExpr fn: 'ln' of: (lin - s) / (lin + s)) / s].
	r := first.
	1 to: j - 1 do: [:n |
		r := (lin / ((SymExpr num: n * d) * (SymExpr power: p to: n))) + (r * (SymExpr num: 2 * (2 * n - 1) * a / (n * d)))].
	^r!
substitutionIntegralIn: v depth: depth
	"try u = g(x) for the arguments and bases that occur: divide by g' and see whether only g is left"
	| cands u x tried |
	x := SymExpr sym: v.
	cands := OrderedCollection new.
	self collectSubstitutionCandidatesInto: cands for: v.
	u := SymExpr sym: '_u', depth printString.
	tried := 0.
	cands do: [:g | | gp q map q2 r |
		tried < 6 ifTrue: [
			tried := tried + 1.
			gp := g diffIn: v.
			gp isZero ifFalse: [
				q := [(self / gp) cancelled] on: SymError do: [:e | nil].
				q notNil ifTrue: [
					map := Dictionary new.
					map at: g key put: u.
					q2 := q substitute: map.
					(q2 dependsOn: v) ifFalse: [
						r := q2 antiderivativeIn: u name depth: depth + 1.
						r isNil ifFalse: [
							map := Dictionary new.
							map at: u key put: g.
							^r substitute: map]]]]]].
	^nil!
collectSubstitutionCandidatesInto: aCollection for: v
	self operands do: [:o | o collectSubstitutionCandidatesInto: aCollection for: v].
	self isFn ifTrue: [self noteCandidate: self arg in: aCollection for: v].
	self isPow ifTrue: [
		self base isSym ifFalse: [self noteCandidate: self base in: aCollection for: v].
		(self exponent dependsOn: v) ifTrue: [self noteCandidate: self exponent in: aCollection for: v]]!
noteCandidate: g in: aCollection for: v
	((g dependsOn: v) and: [g isSym not and: [(aCollection includes: g) not]]) ifTrue: [aCollection add: g]!
partsIntegralIn: v depth: depth
	"integration by parts, u chosen as a logarithm or inverse trigonometric function, else a power of the symbol"
	| fs choices |
	self isPow ifTrue: [ | x n r |
		(self base isFnNamed: 'ln') ifFalse: [^nil].
		(self exponent isNum and: [self exponent value isInteger and: [self exponent value >= 2]]) ifFalse: [^nil].
		n := self exponent value.
		x := SymExpr sym: v.
		r := (SymExpr power: self base to: n - 1) antiderivativeIn: v depth: depth + 1.
		r isNil ifTrue: [^nil].
		^(x * self) - (r * n)].
	self isMul ifFalse: [^nil].
	fs := self factors.
	choices := OrderedCollection new.
	fs do: [:f | ((f isFn and: [#('ln' 'atan' 'asin' 'acos') includes: f name]) or: [f isPow and: [(f base isFnNamed: 'ln') and: [f exponent isNum and: [f exponent value isInteger and: [f exponent value >= 2]]]]]) ifTrue: [choices add: f]].
	fs do: [:f | (f isSym or: [f isPow and: [f base isSym and: [f exponent isNum and: [f exponent value isInteger and: [f exponent value > 0]]]]]) ifTrue: [choices add: f]].
	choices do: [:u | | dv vv du w big |
		dv := SymExpr product: (fs copyWithout: u).
		vv := dv antiderivativeIn: v depth: depth + 1.
		vv isNil ifFalse: [
			du := u diffIn: v.
			w := [(vv * du) cancelled] on: SymError do: [:e | nil].
			w notNil ifTrue: [
				big := w antiderivativeIn: v depth: depth + 1.
				big isNil ifFalse: [^(u * vv) - big]]]].
	^nil! !

!SymExpr methodsFor: 'limits'!
isInfinityValue
	^self key = 'soo' or: [self negated key = 'soo']!
valueAt: aName is: a
	"substitute and answer the value, or nil when that is undefined"
	| map |
	map := Dictionary new.
	map at: (SymExpr sym: aName) key put: a.
	^[self substitute: map] on: SymError do: [:e | nil]!
limitIn: v at: a
	^self limitIn: v at: a side: 0 depth: 0!
limitIn: v at: a side: side depth: depth
	"the limit as the symbol approaches a (a number, oo or -oo) from the left (-1), the right (1) or both sides (0)"
	| r s nd sd |
	depth > 7 ifTrue: [^SymError new signal: 'the limit could not be found'].
	sd := side.
	a isInfinityValue ifFalse: [
		r := self valueAt: v is: a.
		r isNil ifFalse: [^r].
		s := [self cancelled] on: SymError do: [:e | self].
		s = self ifFalse: [
			r := s valueAt: v is: a.
			r isNil ifFalse: [^r]].
		sd = 0 ifTrue: [ | right left |
			right := self sampleOf: self in: v at: a side: 1.
			left := self sampleOf: self in: v at: a side: -1.
			(left isNil and: [right notNil]) ifTrue: [^self limitIn: v at: a side: 1 depth: depth].
			(right isNil and: [left notNil]) ifTrue: [^self limitIn: v at: a side: -1 depth: depth]]].
	r := [self structuralLimitIn: v at: a side: sd depth: depth] on: SymError do: [:e | nil].
	r isNil ifFalse: [^r].
	nd := [self numerDenom] on: SymError do: [:e | Array with: self with: SymExpr one].
	nd last isOne ifFalse: [^self lhopital: nd first over: nd last in: v at: a side: sd depth: depth].
	^self limitOfProductIn: v at: a side: sd depth: depth!
structuralLimitIn: v at: a side: side depth: depth
	"from the limits of the parts; nil when they are indeterminate"
	^nil!
lhopital: n over: d in: v at: a side: side depth: depth
	| ln ld |
	ln := n limitIn: v at: a side: side depth: depth.
	ld := d limitIn: v at: a side: side depth: depth.
	((ln isInfinityValue not) and: [ld isInfinityValue not]) ifTrue: [
		ld isZero ifFalse: [^ln / ld].
		ln isZero ifFalse: [^self infinityByLookingAt: (n / d) in: v at: a side: side]].
	(ln isInfinityValue and: [ld isInfinityValue not and: [ld isZero not]]) ifTrue: [
		^ln * (SymExpr num: (ld numericValue > 0 ifTrue: [1] ifFalse: [-1]))].
	(ln isInfinityValue not and: [ld isInfinityValue]) ifTrue: [^SymExpr zero].
	^((n diffIn: v) / (d diffIn: v)) limitIn: v at: a side: side depth: depth + 1!
limitOfProductIn: v at: a side: side depth: depth
	| dep f rest r |
	self isPow ifTrue: [
		((self exponent dependsOn: v) or: [self base dependsOn: v]) ifTrue: [
			r := (self exponent * (SymExpr fn: 'ln' of: self base)) limitIn: v at: a side: side depth: depth.
			r key = 'soo' ifTrue: [^r].
			r negated key = 'soo' ifTrue: [^SymExpr zero].
			^SymExpr fn: 'exp' of: r]].
	self isMul ifTrue: [
		dep := self factors select: [:g | g dependsOn: v].
		dep size >= 2 ifTrue: [
			f := dep first.
			rest := SymExpr product: (self factors copyWithout: f).
			r := [self lhopital: f over: rest reciprocal in: v at: a side: side depth: depth] on: SymError do: [:e | nil].
			r isNil ifFalse: [^r].
			^self lhopital: rest over: f reciprocal in: v at: a side: side depth: depth]].
	^self infinityByLookingAt: self in: v at: a side: side!
infinityByLookingAt: e in: v at: a side: side
	"oo or -oo from the signs and sizes of the values just either side of the point, else an error"
	| right left |
	a isInfinityValue ifTrue: [
		right := self sampleOf: e in: v at: a side: 1.
		right isNil ifTrue: [^SymError new signal: 'the limit could not be found'].
		right abs > 1.0e4 ifFalse: [^SymError new signal: 'the limit could not be found'].
		^right > 0 ifTrue: [SymExpr infinity] ifFalse: [SymExpr infinity negated]].
	right := side >= 0 ifTrue: [self sampleOf: e in: v at: a side: 1] ifFalse: [nil].
	left := side <= 0 ifTrue: [self sampleOf: e in: v at: a side: -1] ifFalse: [nil].
	side > 0 ifTrue: [left := right].
	side < 0 ifTrue: [right := left].
	(right isNil or: [left isNil]) ifTrue: [^SymError new signal: 'the limit could not be found'].
	(right abs > 1.0e4 and: [left abs > 1.0e4]) ifFalse: [^SymError new signal: 'the limit could not be found'].
	right sign = left sign ifFalse: [^SymError new signal: 'the limit does not exist: the two sides differ'].
	^right > 0 ifTrue: [SymExpr infinity] ifFalse: [SymExpr infinity negated]!
sampleOf: e in: v at: a side: s
	| h map |
	h := 1.0e-7.
	map := Dictionary new.
	map at: (SymExpr sym: v) key put: (SymExpr num: (a isInfinityValue
		ifTrue: [a key = 'soo' ifTrue: [1.0e6] ifFalse: [-1.0e6]]
		ifFalse: [a numericValue + (s * h)])).
	^[(e substitute: map) numericValue] on: SymError do: [:x | nil]!
signOfLimit
	"1 or -1 for oo or -oo, else the sign of a number, or nil"
	self isInfinityValue ifTrue: [^self key = 'soo' ifTrue: [1] ifFalse: [-1]].
	^self numericOrNil ifNotNil: [:x | x sign]! !

!SymNum methodsFor: 'limits'!
structuralLimitIn: v at: a side: side depth: depth
	^self! !

!SymSym methodsFor: 'limits'!
structuralLimitIn: v at: a side: side depth: depth
	^name = v ifTrue: [a] ifFalse: [self]! !

!SymAdd methodsFor: 'limits'!
structuralLimitIn: v at: a side: side depth: depth
	| lims infs |
	lims := terms collect: [:t | t limitIn: v at: a side: side depth: depth].
	infs := lims select: [:l | l isInfinityValue].
	infs isEmpty ifTrue: [^SymExpr sum: lims].
	^(infs allSatisfy: [:l | l = infs first]) ifTrue: [infs first] ifFalse: [nil]! !

!SymMul methodsFor: 'limits'!
structuralLimitIn: v at: a side: side depth: depth
	| lims sign |
	lims := factors collect: [:f | f limitIn: v at: a side: side depth: depth].
	(lims anySatisfy: [:l | l isInfinityValue]) ifFalse: [^SymExpr product: lims].
	(lims anySatisfy: [:l | l isZero]) ifTrue: [^nil].
	sign := 1.
	lims do: [:l | | sg |
		sg := l signOfLimit.
		sg isNil ifTrue: [^nil].
		sign := sign * sg].
	^sign > 0 ifTrue: [SymExpr infinity] ifFalse: [SymExpr infinity negated]! !

!SymPow methodsFor: 'limits'!
structuralLimitIn: v at: a side: side depth: depth
	| lb sg |
	(exponent dependsOn: v) ifTrue: [^nil].
	lb := base limitIn: v at: a side: side depth: depth.
	(exponent isNum not) ifTrue: [^lb isInfinityValue ifTrue: [nil] ifFalse: [SymExpr power: lb to: exponent]].
	lb isInfinityValue ifFalse: [
		lb isZero ifTrue: [
			exponent value > 0 ifTrue: [^SymExpr zero].
			^self infinityByLookingAt: self in: v at: a side: side].
		^SymExpr power: lb to: exponent].
	exponent value < 0 ifTrue: [^SymExpr zero].
	sg := lb key = 'soo' ifTrue: [1] ifFalse: [-1].
	exponent value isInteger ifTrue: [^(sg = 1 or: [exponent value even]) ifTrue: [SymExpr infinity] ifFalse: [SymExpr infinity negated]].
	^sg = 1 ifTrue: [SymExpr infinity] ifFalse: [nil]! !

!SymFn methodsFor: 'limits'!
structuralLimitIn: v at: a side: side depth: depth
	| l pos |
	l := arg limitIn: v at: a side: side depth: depth.
	l isInfinityValue ifFalse: [
		(name = 'ln' and: [l isZero]) ifTrue: [^SymExpr infinity negated].
		^SymExpr fn: name of: l].
	pos := l key = 'soo'.
	name = 'exp' ifTrue: [^pos ifTrue: [l] ifFalse: [SymExpr zero]].
	name = 'ln' ifTrue: [^pos ifTrue: [l] ifFalse: [nil]].
	name = 'atan' ifTrue: [^pos ifTrue: [SymExpr pi / 2] ifFalse: [SymExpr pi negated / 2]].
	name = 'tanh' ifTrue: [^SymExpr num: (pos ifTrue: [1] ifFalse: [-1])].
	name = 'sinh' ifTrue: [^l].
	name = 'cosh' ifTrue: [^SymExpr infinity].
	name = 'abs' ifTrue: [^SymExpr infinity].
	^nil! !

!SymExpr methodsFor: 'series'!
taylorIn: v at: a order: n
	"the terms through (x - a)^n"
	| x terms d f |
	x := SymExpr sym: v.
	terms := OrderedCollection new.
	d := self.
	0 to: n do: [:k | | map c |
		map := Dictionary new.
		map at: x key put: a.
		c := (d substitute: map).
		c := c / (SymExpr num: k factorial).
		terms add: (c * (SymExpr power: x - a to: k)).
		d := d diffIn: v.
		d := d simplified].
	^SymExpr sum: terms! !

!SymExpr methodsFor: 'sums'!
sumIn: k from: lo to: hi
	"the sum of this for the symbol k from lo to hi: terms added when the bounds are numbers, otherwise Faulhaber's formulas for a
	polynomial in k, or a geometric series"
	| cs total ratio map |
	(lo isNum and: [hi isNum and: [lo isInteger and: [hi isInteger]]]) ifTrue: [
		hi value - lo value > 100000 ifTrue: [^SymError new signal: 'too many terms to add one at a time'].
		^SymExpr sum: ((lo value to: hi value) collect: [:i | | m |
			m := Dictionary new.
			m at: (SymExpr sym: k) key put: (SymExpr num: i).
			self substitute: m])].
	cs := self polyCoefficientsIn: k.
	cs isNil ifFalse: [
		total := SymExpr zero.
		0 to: cs size - 1 do: [:m | | p |
			p := SymExpr faulhaber: m.
			total := total + ((cs at: m + 1) * ((p substituteN: hi) - (p substituteN: lo - 1)))].
		^total expanded].
	"c * r^k with r free of k"
	(self isPow and: [self exponent = (SymExpr sym: k) and: [self base freeOf: k]]) ifTrue: [
		ratio := self base.
		^((SymExpr power: ratio to: hi + 1) - (SymExpr power: ratio to: lo)) / (ratio - 1)].
	(self isMul and: [self factors size >= 1]) ifTrue: [ | c rest |
		c := SymExpr product: (self factors select: [:f | f freeOf: k]).
		rest := SymExpr product: (self factors reject: [:f | f freeOf: k]).
		(c isOne not and: [rest isOne not]) ifTrue: [^c * (rest sumIn: k from: lo to: hi)]].
	^SymError new signal: 'cannot find a closed form for this sum'!
substituteN: anExpression
	"in an expression of the symbol n: the value at anExpression"
	| map |
	map := Dictionary new.
	map at: (SymExpr sym: 'n') key put: anExpression.
	^self substitute: map! !

!SymExpr class methodsFor: 'sums'!
faulhaber: m
	"the sum of k^m for k from 1 to n, as an expression in n"
	| xs ys acc |
	xs := (0 to: m + 1) asArray.
	acc := 0.
	ys := xs collect: [:n | | s |
		s := 0.
		1 to: n do: [:k | s := s + (k raisedTo: m)].
		s].
	^(SymPoly interpolate: xs values: ys) asExprIn: 'n'! !
