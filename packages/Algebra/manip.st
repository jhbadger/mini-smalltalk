"Manipulating expressions: expanding, putting over a common denominator, cancelling, partial fractions, factoring,
collecting, trigonometric rules, simplifying, and evaluating. Everything here takes and answers canonical expressions."

!SymExpr class methodsFor: 'expanding'!
multiplyExpanded: a by: b
	"the product of two expressions that are already expanded, multiplied out"
	| ta tb out |
	ta := a isAdd ifTrue: [a terms] ifFalse: [Array with: a].
	tb := b isAdd ifTrue: [b terms] ifFalse: [Array with: b].
	out := OrderedCollection new.
	ta do: [:x | tb do: [:y | out add: (self product: (Array with: x with: y))]].
	^self sum: out!
power: anExpanded expandedTo: n
	| h |
	n = 0 ifTrue: [^self one].
	n = 1 ifTrue: [^anExpanded].
	n even ifTrue: [
		h := self power: anExpanded expandedTo: n // 2.
		^self multiplyExpanded: h by: h].
	^self multiplyExpanded: anExpanded by: (self power: anExpanded expandedTo: n - 1)! !

!SymExpr methodsFor: 'expanding'!
expanded
	"multiplied out, with like terms collected"
	^self!
termsOf
	^self isAdd ifTrue: [self terms] ifFalse: [Array with: self]!
collected: aName
	"grouped by the powers of a symbol: coefficient times power, with equal powers' coefficients added"
	| cs |
	cs := self polyCoefficientsIn: aName.
	cs isNil ifTrue: [^SymError new signal: 'this is not a polynomial in ', aName].
	^SymExpr sum: ((0 to: cs size - 1) collect: [:k |
		SymExpr product: (Array with: (cs at: k + 1) with: (SymExpr power: (SymExpr sym: aName) to: k))])! !

!SymAdd methodsFor: 'expanding'!
expanded
	^SymExpr sum: (terms collect: [:t | t expanded])! !

!SymMul methodsFor: 'expanding'!
expanded
	| acc |
	acc := SymExpr one.
	factors do: [:f | acc := SymExpr multiplyExpanded: acc by: f expanded].
	^acc! !

!SymPow methodsFor: 'expanding'!
expanded
	| b e |
	b := base expanded.
	e := exponent expanded.
	(b isAdd and: [e isNum and: [e value isInteger and: [e value > 1 and: [e value <= 2000]]]])
		ifTrue: [^SymExpr power: b expandedTo: e value].
	(b isNum and: [e isAdd]) ifTrue: [
		b value > 0 ifTrue: [^SymExpr product: (e terms collect: [:t | SymExpr power: b to: t])]].
	^SymExpr power: b to: e! !

!SymFn methodsFor: 'expanding'!
expanded
	^SymExpr fn: name of: arg expanded! !

!SymExpr methodsFor: 'polynomials'!
splitPowerOf: aName
	"Array (degree coefficient) when this term is coefficient * name^k with k a positive integer or 0, else nil"
	| deg rest |
	(self dependsOn: aName) ifFalse: [^Array with: 0 with: self].
	self isSym ifTrue: [^Array with: 1 with: SymExpr one].
	(self isPow and: [self base isSym and: [self base name = aName and: [self exponent isNum and: [self exponent value isInteger and: [self exponent value > 0]]]]])
		ifTrue: [^Array with: self exponent value with: SymExpr one].
	self isMul ifTrue: [
		deg := 0.
		rest := OrderedCollection new.
		self factors do: [:f |
			(f dependsOn: aName)
				ifTrue: [ | p |
					p := f splitPowerOf: aName.
					p isNil ifTrue: [^nil].
					deg := deg + (p at: 1)]
				ifFalse: [rest add: f]].
		^Array with: deg with: (SymExpr product: rest)].
	^nil!
polyCoefficientsIn: aName
	"the coefficients, lowest power first, as expressions, when this is a polynomial in the symbol (checked after expanding), else nil"
	| e out max |
	e := self expanded.
	out := Dictionary new.
	max := 0.
	e termsOf do: [:t | | p k |
		p := t splitPowerOf: aName.
		p isNil ifTrue: [^nil].
		k := p at: 1.
		out at: k put: (out at: k ifAbsent: [#()]) , (Array with: (p at: 2)).
		max := max max: k].
	^(0 to: max) collect: [:k | SymExpr sum: (out at: k ifAbsent: [#()])]!
asPolyIn: aName
	"a SymPoly when this is a polynomial in the symbol with rational coefficients, else nil"
	| cs |
	cs := self polyCoefficientsIn: aName.
	cs isNil ifTrue: [^nil].
	(cs allSatisfy: [:c | c isNum and: [SymExpr isExact: c value]]) ifFalse: [^nil].
	^SymPoly coefficients: (cs collect: [:c | c value])! !

!SymExpr methodsFor: 'fractions'!
numerDenom
	"an Array: numerator and denominator, the denominator a product of powers that is not multiplied out"
	^Array with: self with: SymExpr one!
together
	"over a single denominator"
	| nd |
	nd := self numerDenom.
	^SymExpr product: (Array with: nd first with: nd last reciprocal)! !

!SymNum methodsFor: 'fractions'!
numerDenom
	value isFraction ifTrue: [^Array with: (SymExpr num: value numerator) with: (SymExpr num: value denominator)].
	^Array with: self with: SymExpr one! !

!SymMul methodsFor: 'fractions'!
numerDenom
	| n d |
	n := OrderedCollection new.
	d := OrderedCollection new.
	factors do: [:f | | p |
		p := f numerDenom.
		n add: p first.
		d add: p last].
	^Array with: (SymExpr product: n) with: (SymExpr product: d)! !

!SymPow methodsFor: 'fractions'!
numerDenom
	| p e |
	(exponent isNum and: [exponent value isInteger]) ifFalse: [
		^(exponent isNum and: [exponent value < 0])
			ifTrue: [Array with: SymExpr one with: (SymExpr power: base to: exponent negated)]
			ifFalse: [Array with: self with: SymExpr one]].
	e := exponent value.
	p := base numerDenom.
	e > 0 ifTrue: [^Array with: (SymExpr power: p first to: e) with: (SymExpr power: p last to: e)].
	^Array with: (SymExpr power: p last to: e negated) with: (SymExpr power: p first to: e negated)! !

!SymAdd methodsFor: 'fractions'!
numerDenom
	| pairs lcdNum map lcd num one |
	one := SymExpr one.
	pairs := terms collect: [:t | t numerDenom].
	(pairs allSatisfy: [:p | p last isOne]) ifTrue: [^Array with: self with: one].
	lcdNum := 1.
	map := OrderedCollection new.
	pairs do: [:p | | d |
		d := p last.
		d isNum
			ifTrue: [lcdNum := lcdNum lcm: d value]
			ifFalse: [
				(d isMul ifTrue: [d factors] ifFalse: [Array with: d]) do: [:f |
					f isNum
						ifTrue: [lcdNum := lcdNum lcm: f value]
						ifFalse: [ | b k m |
							(f isPow and: [f exponent isNum]) ifTrue: [b := f base. k := f exponent value] ifFalse: [b := f. k := 1].
							m := map detect: [:x | (x at: 1) = b] ifNone: [nil].
							m isNil
								ifTrue: [map add: (Array with: b with: k)]
								ifFalse: [m at: 2 put: ((m at: 2) max: k)]]]]].
	lcd := SymExpr product: (map collect: [:m | SymExpr power: (m at: 1) to: (m at: 2)]) asArray , (Array with: (SymExpr num: lcdNum)).
	num := SymExpr sum: (pairs collect: [:p | SymExpr product: (Array with: p first with: lcd with: p last reciprocal)]).
	^Array with: num expanded with: lcd! !

!SymExpr methodsFor: 'fractions'!
cancelled
	"together, with the factors the numerator and the denominator have in common removed"
	| nd n d vars v pn pd g f r |
	nd := self numerDenom.
	n := nd first expanded.
	d := nd last expanded.
	n isZero ifTrue: [^n].
	d isOne ifTrue: [^n].
	d isNum ifTrue: [^(SymExpr product: (Array with: n with: d reciprocal)) expanded].
	vars := (n variables , d variables) asSet asArray.
	vars size = 1 ifTrue: [
		v := vars first.
		pn := n asPolyIn: v.
		pd := d asPolyIn: v.
		(pn notNil and: [pd notNil]) ifTrue: [
			g := pn gcd: pd.
			g degree > 0 ifTrue: [pn := pn quotient: g. pd := pd quotient: g].
			f := pd content.
			pd := pd scaledBy: 1 / f.
			pn := pn scaledBy: 1 / f.
			^SymExpr product: (Array with: (pn asExprIn: v) with: (pd asExprIn: v) reciprocal)]].
	^SymExpr product: (Array with: n factored with: d factored reciprocal)!
apartIn: aName
	"partial fractions in a symbol, over the rationals"
	| nd n d pn pd qr fac const x unknowns cols rhs rows sol result idx dd |
	nd := self numerDenom.
	n := nd first expanded.
	d := nd last expanded.
	pn := n asPolyIn: aName.
	pd := d asPolyIn: aName.
	(pn isNil or: [pd isNil]) ifTrue: [^SymError new signal: 'apart needs a rational function of ', aName, ' with rational coefficients'].
	pd degree < 1 ifTrue: [^self expanded].
	qr := pn divMod: pd.
	(qr at: 2) isZero ifTrue: [^((qr at: 1) asExprIn: aName)].
	fac := pd factor.
	const := fac at: 1.
	dd := SymPoly one.
	(fac at: 2) do: [:f | dd := dd * ((f at: 1) raisedTo: (f at: 2))].
	unknowns := OrderedCollection new.
	(fac at: 2) do: [:f |
		1 to: (f at: 2) do: [:j |
			0 to: (f at: 1) degree - 1 do: [:s |
				unknowns add: (Array with: f with: j with: s)]]].
	rows := (0 to: dd degree - 1) collect: [:k | OrderedCollection new].
	unknowns do: [:u | | basis |
		basis := (dd quotient: ((u first at: 1) raisedTo: (u at: 2))) * (SymPoly x raisedTo: (u at: 3)).
		0 to: dd degree - 1 do: [:k | (rows at: k + 1) add: (basis coeffAt: k)]].
	0 to: dd degree - 1 do: [:k | (rows at: k + 1) add: ((qr at: 2) coeffAt: k) / const].
	sol := SymLinear solve: (rows collect: [:r | r asArray]) zero: [:v | v = 0] normalize: [:v | v].
	sol isNil ifTrue: [^SymError new signal: 'the partial fractions could not be found'].
	result := OrderedCollection new.
	result add: ((qr at: 1) asExprIn: aName).
	idx := 0.
	(fac at: 2) do: [:f |
		1 to: (f at: 2) do: [:j | | numer |
			numer := SymPoly coefficients: ((0 to: (f at: 1) degree - 1) collect: [:s | idx := idx + 1. sol at: idx]).
			numer isZero ifFalse: [
				result add: (SymExpr product: (Array with: (SymExpr num: numer content)
					with: (numer primitive asExprIn: aName)
					with: (SymExpr power: ((f at: 1) asExprIn: aName) to: j negated)))]]].
	^SymExpr sum: result! !

!SymExpr methodsFor: 'factoring'!
factored
	"factored over the rationals (irreducible factors: found by rational roots, then Kronecker's method up to a modest size)"
	^self!
abstractAtoms: aDictionary
	"replace what is not a polynomial atom (a function, a root, ...) by fresh symbols, remembering them in the dictionary"
	^self!
factoredSymbolic
	"an expanded sum that is a polynomial in symbols: monomial and numeric content out, then the factors of what is left"
	| terms exps names coeffs mingcd content mono q first |
	terms := self terms.
	names := Set new.
	exps := terms collect: [:t | | d |
		d := Dictionary new.
		(t isMul ifTrue: [t factors] ifFalse: [Array with: t]) do: [:f |
			f isNum ifFalse: [
				f isSym
					ifTrue: [d at: f name put: 1. names add: f name]
					ifFalse: [
						(f isPow and: [f base isSym and: [f exponent isNum and: [f exponent value isInteger and: [f exponent value > 0]]]])
							ifTrue: [d at: f base name put: f exponent value. names add: f base name]
							ifFalse: [^self]]]].
		d].
	coeffs := terms collect: [:t | t coefficient].
	(coeffs allSatisfy: [:c | SymExpr isExact: c]) ifFalse: [^self].
	mingcd := Dictionary new.
	names do: [:nm | mingcd at: nm put: (exps inject: 1000000 into: [:m :d | m min: (d at: nm ifAbsent: [0])])].
	content := SymPoly contentOf: coeffs.
	first := terms first coefficient.
	first < 0 ifTrue: [content := content negated].
	mono := SymExpr product: (names asArray collect: [:nm | SymExpr power: (SymExpr sym: nm) to: (mingcd at: nm)]).
	q := (SymExpr product: (Array with: self with: (SymExpr product: (Array with: (SymExpr num: content) with: mono)) reciprocal)) expanded.
	^SymExpr product: (Array with: (SymExpr num: content) with: mono with: q factoredCore)!
factoredCore
	"an expanded sum without a common factor, integer coefficients: its irreducible factors where we can find them"
	| vars v p fac parts |
	self isAdd ifFalse: [^self].
	vars := self variables.
	vars size = 1 ifTrue: [
		v := vars first.
		p := self asPolyIn: v.
		p isNil ifTrue: [^self].
		fac := p factor.
		parts := OrderedCollection new.
		parts add: (SymExpr num: (fac at: 1)).
		(fac at: 2) do: [:f | parts add: (SymExpr power: ((f at: 1) asExprIn: v) to: (f at: 2))].
		^SymExpr product: parts].
	vars size = 2 ifTrue: [
		p := self factoredHomogeneous: vars.
		p isNil ifFalse: [^p]].
	^self factoredPatterns!
factoredHomogeneous: vars
	"for a polynomial in two symbols whose terms all have the same total degree: factor it with the second symbol set to 1, then put it back"
	| a b deg map poly fac parts |
	a := vars first.
	b := vars last.
	deg := nil.
	self terms do: [:t | | dg |
		dg := 0.
		(t isMul ifTrue: [t factors] ifFalse: [Array with: t]) do: [:f |
			f isSym ifTrue: [dg := dg + 1].
			f isPow ifTrue: [dg := dg + f exponent value]].
		deg isNil ifTrue: [deg := dg] ifFalse: [deg = dg ifFalse: [^nil]]].
	map := Dictionary new.
	map at: (SymExpr sym: b) key put: SymExpr one.
	poly := (self substitute: map) asPolyIn: a.
	(poly isNil or: [poly degree ~= deg]) ifTrue: [^nil].
	fac := poly factor.
	parts := OrderedCollection new.
	parts add: (SymExpr num: (fac at: 1)).
	(fac at: 2) do: [:f | | p d homog |
		p := f at: 1.
		d := p degree.
		homog := SymExpr sum: ((0 to: d) collect: [:k |
			SymExpr product: (Array with: (SymExpr num: (p coeffAt: k))
				with: (SymExpr power: (SymExpr sym: a) to: k)
				with: (SymExpr power: (SymExpr sym: b) to: d - k))]).
		parts add: (SymExpr power: homog to: (f at: 2))].
	^SymExpr product: parts!
monomialRoot: n
	"an expression whose n-th power is this term (a monomial with an exact coefficient), or nil"
	| c cr rest |
	self isNum ifTrue: [
		cr := SymExpr power: self to: (SymExpr num: 1 / n).
		^(cr isNum and: [SymExpr isExact: cr value]) ifTrue: [cr] ifFalse: [nil]].
	c := self coefficient.
	((SymExpr isExact: c) and: [c > 0]) ifFalse: [^nil].
	cr := SymExpr power: (SymExpr num: c) to: (SymExpr num: 1 / n).
	(cr isNum and: [SymExpr isExact: cr value]) ifFalse: [^nil].
	rest := OrderedCollection new.
	rest add: cr.
	self nonNumericPart factorsOrSelf do: [:f | | e b |
		(f isSym or: [f isPow and: [f base isSym]]) ifFalse: [^nil].
		e := f isPow ifTrue: [f exponent] ifFalse: [SymExpr one].
		b := f isPow ifTrue: [f base] ifFalse: [f].
		(e isNum and: [e value isInteger and: [e value \\ n = 0]]) ifFalse: [^nil].
		rest add: (SymExpr power: b to: (SymExpr num: e value / n))].
	^SymExpr product: rest!
factorsOrSelf
	^self isMul ifTrue: [self factors] ifFalse: [Array with: self]!
factoredPatterns
	"two or three terms: difference of squares, sum or difference of cubes, perfect squares"
	| t a b c |
	t := self terms.
	t size = 2 ifTrue: [
		a := t first.
		b := t last.
		(a coefficient > 0 and: [b coefficient < 0]) ifTrue: [
			a := a monomialRoot: 2.
			b := b negated monomialRoot: 2.
			(a notNil and: [b notNil]) ifTrue: [
				^SymExpr product: (Array with: (a - b) with: (a + b))]].
		a := t first monomialRoot: 3.
		b := (t last coefficient < 0 ifTrue: [t last negated] ifFalse: [t last]) monomialRoot: 3.
		(a notNil and: [b notNil and: [t first coefficient > 0]]) ifTrue: [
			t last coefficient < 0
				ifTrue: [^SymExpr product: (Array with: (a - b) with: (a squared + (a * b) + b squared))]
				ifFalse: [^SymExpr product: (Array with: (a + b) with: (a squared - (a * b) + b squared))]]].
	t size = 3 ifTrue: [
		a := t first monomialRoot: 2.
		c := t last monomialRoot: 2.
		(a notNil and: [c notNil]) ifTrue: [
			((a * c * 2) expanded = (t at: 2)) ifTrue: [^(a + c) squared].
			((a * c * -2) expanded = (t at: 2)) ifTrue: [^(a - c) squared]]].
	^self! !

!SymAdd methodsFor: 'factoring'!
abstractAtoms: aDictionary
	^SymExpr sum: (terms collect: [:t | t abstractAtoms: aDictionary])!
factored
	| nd e map abstracted back r counter |
	nd := self numerDenom.
	nd last isOne ifFalse: [^nd first factored * nd last factored reciprocal].
	e := self expanded.
	e isAdd ifFalse: [^e factored].
	map := Dictionary new.
	abstracted := e abstractAtoms: map.
	abstracted isAdd ifFalse: [^e].
	r := abstracted factoredSymbolic.
	map isEmpty ifTrue: [^r].
	back := Dictionary new.
	map keysAndValuesDo: [:k :v | back at: k put: v].
	^r substitute: back! !

!SymMul methodsFor: 'factoring'!
abstractAtoms: aDictionary
	^SymExpr product: (factors collect: [:t | t abstractAtoms: aDictionary])!
factored
	^SymExpr product: (factors collect: [:f | f factored])! !

!SymPow methodsFor: 'factoring'!
abstractAtoms: aDictionary
	| sym |
	(exponent isNum and: [exponent value isInteger and: [exponent value > 0]])
		ifTrue: [^SymExpr power: (base abstractAtoms: aDictionary) to: exponent].
	sym := SymExpr sym: '_t', (aDictionary size + 1) printString.
	aDictionary keysAndValuesDo: [:k :v | v = self ifTrue: [^SymExpr sym: (k copyFrom: 2)]].
	aDictionary at: sym key put: self.
	^sym!
factored
	^SymExpr power: base factored to: exponent! !

!SymFn methodsFor: 'factoring'!
abstractAtoms: aDictionary
	| sym |
	aDictionary keysAndValuesDo: [:k :v | v = self ifTrue: [^SymExpr sym: (k copyFrom: 2)]].
	sym := SymExpr sym: '_t', (aDictionary size + 1) printString.
	aDictionary at: sym key put: self.
	^sym!
factored
	^SymExpr fn: name of: arg factored! !

!SymPoly class methodsFor: 'content'!
contentOf: someNumbers
	"the rational gcd of numbers: the largest rational that divides each of them to give an integer"
	| g l |
	g := 0.
	l := 1.
	someNumbers do: [:c | g := g gcd: c numerator. l := l lcm: c denominator].
	g = 0 ifTrue: [^1].
	^g / l! !

!SymExpr methodsFor: 'trigonometry'!
trigSimplified
	"sin^2 + cos^2 = 1 and its relatives, applied to every sum inside"
	^self operands isEmpty ifTrue: [self] ifFalse: [self mapChildren: [:c | c trigSimplified]]!
trigExpanded
	"sin and cos of sums and of whole multiples, written with sin and cos of the parts (multiply out afterwards)"
	^self operands isEmpty ifTrue: [self] ifFalse: [self mapChildren: [:c | c trigExpanded]]! !

!SymAdd methodsFor: 'trigonometry'!
trigSimplified
	"pair up c R sin(u)^2 with c R cos(u)^2, and k with -k sin(u)^2 or -k cos(u)^2"
	| list found i j r fresh |
	list := OrderedCollection new.
	(SymExpr sum: (terms collect: [:t | t trigSimplified])) termsOf do: [:t | list add: t].
	found := true.
	[found] whileTrue: [
		found := false.
		i := 1.
		[i <= list size and: [found not]] whileTrue: [
			j := 1.
			[j <= list size and: [found not]] whileTrue: [
				i ~= j ifTrue: [
					r := (list at: i) pythagoreanWith: (list at: j).
					r isNil ifFalse: [
						fresh := OrderedCollection new.
						1 to: list size do: [:k | (k ~= i and: [k ~= j]) ifTrue: [fresh add: (list at: k)]].
						fresh add: r.
						list := fresh.
						found := true]].
				j := j + 1].
			i := i + 1]].
	^SymExpr sum: list! !

!SymExpr methodsFor: 'trigonometry'!
squareOfTrig
	"Array (kind angle rest coefficient) when this term is c * R * sin(u)^2 or c * R * cos(u)^2, else nil"
	| fs hit rest |
	fs := self factorsOrSelf.
	hit := fs detect: [:f | f isPow and: [f exponent isNum and: [f exponent value = 2 and: [(f base isFnNamed: 'sin') or: [f base isFnNamed: 'cos']]]]] ifNone: [nil].
	hit isNil ifTrue: [^nil].
	rest := SymExpr product: ((fs copyWithout: hit) reject: [:f | f isNum]).
	^Array with: hit base name with: hit base arg with: rest with: self coefficient!
pythagoreanWith: other
	"what two terms of a sum come to by sin^2 + cos^2 = 1, or nil when the rule does not apply"
	| a b |
	a := self squareOfTrig.
	b := other squareOfTrig.
	(a notNil and: [b notNil]) ifTrue: [
		((a at: 1) ~= (b at: 1) and: [(a at: 2) = (b at: 2) and: [(a at: 3) = (b at: 3) and: [(a at: 4) = (b at: 4)]]])
			ifTrue: [^SymExpr product: (Array with: (SymExpr num: (a at: 4)) with: (a at: 3))]].
	"a constant against a square: k - k sin^2 = k cos^2 and k - k cos^2 = k sin^2"
	(self isNum and: [b notNil and: [(b at: 3) isOne and: [(b at: 4) = self value negated]]]) ifTrue: [
		^SymExpr product: (Array with: self with: (SymExpr power: (SymExpr fn: ((b at: 1) = 'sin' ifTrue: ['cos'] ifFalse: ['sin']) of: (b at: 2)) to: 2))].
	^nil! !

!SymFn methodsFor: 'trigonometry'!
trigExpanded
	| a parts p q sp cp sq cq |
	a := arg trigExpanded.
	(name = 'sin' or: [name = 'cos']) ifFalse: [^SymExpr fn: name of: a].
	a isAdd
		ifTrue: [
			p := a terms first.
			q := SymExpr sum: (a terms copyFrom: 2 to: a terms size)]
		ifFalse: [
			(a isMul and: [a coefficient isInteger and: [a coefficient abs >= 2]]) ifFalse: [^SymExpr fn: name of: a].
			p := a nonNumericPart.
			q := a - p].
	sp := (SymExpr fn: 'sin' of: p) trigExpanded.
	cp := (SymExpr fn: 'cos' of: p) trigExpanded.
	sq := (SymExpr fn: 'sin' of: q) trigExpanded.
	cq := (SymExpr fn: 'cos' of: q) trigExpanded.
	name = 'sin' ifTrue: [^(sp * cq) + (cp * sq)].
	^(cp * cq) - (sp * sq)! !

!SymExpr methodsFor: 'simplifying'!
simplified
	"the smallest of: this, multiplied out, cancelled, with the trigonometric identities applied to each"
	| s cands best |
	self operands isEmpty ifTrue: [^self].
	s := self mapChildren: [:c | c simplified].
	s operands isEmpty ifTrue: [^s].
	cands := OrderedCollection new.
	cands add: s; add: s trigSimplified; add: s expanded; add: s expanded trigSimplified.
	s variables isEmpty ifFalse: [
		cands add: s cancelled.
		cands add: s cancelled trigSimplified].
	best := cands first.
	cands do: [:c | c nodeCount < best nodeCount ifTrue: [best := c]].
	^best! !

!SymExpr methodsFor: 'evaluating'!
numericValue
	"the value as a Float; every symbol except pi must have been replaced"
	^SymError new signal: 'cannot compute a number from ', self text!
numericOrNil
	^[self numericValue] on: SymError do: [:e | nil]! !

!SymNum methodsFor: 'evaluating'!
numericValue
	^value asFloat! !

!SymSym methodsFor: 'evaluating'!
numericValue
	name = 'pi' ifTrue: [^Float pi].
	name = 'oo' ifTrue: [^Float infinity].
	name = 'i' ifTrue: [^SymError new signal: 'i is not a real number'].
	^SymError new signal: name, ' has no value'! !

!SymAdd methodsFor: 'evaluating'!
numericValue
	^terms inject: 0.0 into: [:s :t | s + t numericValue]! !

!SymMul methodsFor: 'evaluating'!
numericValue
	^factors inject: 1.0 into: [:s :t | s * t numericValue]! !

!SymPow methodsFor: 'evaluating'!
numericValue
	| b e |
	b := base numericValue.
	e := exponent numericValue.
	e = e truncated ifTrue: [
		(b = 0.0 and: [e < 0]) ifTrue: [^SymError new signal: 'division by zero'].
		^b raisedTo: e truncated].
	b < 0 ifTrue: [^SymError new signal: 'the result is not a real number'].
	^b raisedTo: e! !

!SymFn methodsFor: 'evaluating'!
numericValue
	^SymExpr floatFn: name of: arg numericValue! !
