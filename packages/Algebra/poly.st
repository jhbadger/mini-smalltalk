"Polynomials in one variable over the rationals, and exact linear algebra on rows of numbers or expressions. A SymPoly keeps
its coefficients lowest power first, as Integers and Fractions, with no trailing zeros. It supplies the arithmetic the
expression-level operations are built on: division with remainder, gcd, square-free decomposition, factoring over the
rationals (rational roots, then Kronecker's method for the factors of higher degree), and numeric roots."

!SymPoly class methodsFor: 'building'!
coefficients: anArray
	| n |
	n := anArray size.
	[n > 0 and: [(anArray at: n) = 0]] whileTrue: [n := n - 1].
	^self new setCoeffs: (anArray copyFrom: 1 to: n)!
zero
	^self coefficients: #()!
one
	^self coefficients: #(1)!
x
	^self coefficients: #(0 1)!
constant: aNumber
	^self coefficients: (Array with: aNumber)!
linearFrom: a to: b
	"the polynomial a x + b"
	^self coefficients: (Array with: b with: a)!
interpolate: xs values: ys
	"the polynomial of least degree through the points"
	| total |
	total := self zero.
	1 to: xs size do: [:i | | term |
		term := self constant: (ys at: i).
		1 to: xs size do: [:j |
			j = i ifFalse: [
				term := (term * (self linearFrom: 1 to: (xs at: j) negated)) scaledBy: 1 / ((xs at: i) - (xs at: j))]].
		total := total + term].
	^total!
divisorsOf: n
	"the positive divisors of an integer, or nil when it is too large to search"
	| out k m |
	n = 0 ifTrue: [^nil].
	m := n abs.
	m > 100000000000 ifTrue: [^nil].
	out := OrderedCollection new.
	k := 1.
	[k * k <= m] whileTrue: [
		m \\ k = 0 ifTrue: [out add: k. k * k = m ifFalse: [out add: m // k]].
		k := k + 1].
	^out asArray sort: [:a :b | a < b]! !

!SymPoly methodsFor: 'accessing'!
setCoeffs: anArray
	coeffs := anArray!
coeffs
	^coeffs!
degree
	^coeffs size - 1!
isZero
	^coeffs isEmpty!
isConstant
	^coeffs size <= 1!
leading
	^coeffs isEmpty ifTrue: [0] ifFalse: [coeffs last]!
coeffAt: aDegree
	^aDegree + 1 <= coeffs size ifTrue: [coeffs at: aDegree + 1] ifFalse: [0]!
= other
	^(other isKindOf: SymPoly) and: [coeffs = other coeffs]!
hash
	^coeffs hash!
printOn: aStream
	aStream nextPutAll: 'SymPoly('; print: coeffs; nextPut: $)!
asExprIn: aName
	| x |
	x := SymExpr sym: aName.
	^SymExpr sum: ((0 to: self degree) collect: [:k |
		SymExpr product: (Array with: (SymExpr num: (coeffs at: k + 1)) with: (SymExpr power: x to: k))])!
valueAt: x
	| r |
	r := 0.
	coeffs reverseDo: [:c | r := r * x + c].
	^r! !

!SymPoly methodsFor: 'arithmetic'!
+ other
	| n out |
	n := self degree max: other degree.
	out := (0 to: n) collect: [:k | (self coeffAt: k) + (other coeffAt: k)].
	^SymPoly coefficients: out!
- other
	^self + other negated!
negated
	^SymPoly coefficients: (coeffs collect: [:c | c negated])!
* other
	| out |
	(self isZero or: [other isZero]) ifTrue: [^SymPoly zero].
	out := Array new: self degree + other degree + 1 withAll: 0.
	0 to: self degree do: [:i |
		0 to: other degree do: [:j |
			out at: i + j + 1 put: (out at: i + j + 1) + ((coeffs at: i + 1) * (other coeffAt: j))]].
	^SymPoly coefficients: out!
scaledBy: aNumber
	^SymPoly coefficients: (coeffs collect: [:c | c * aNumber])!
raisedTo: n
	| r |
	r := SymPoly one.
	n timesRepeat: [r := r * self].
	^r!
divMod: other
	"an Array: the quotient and the remainder"
	| r q d lc |
	other isZero ifTrue: [^SymError new signal: 'division by the zero polynomial'].
	self degree < other degree ifTrue: [^Array with: SymPoly zero with: self].
	d := other degree.
	lc := other leading.
	r := coeffs copy.
	q := Array new: self degree - d + 1 withAll: 0.
	self degree to: d by: -1 do: [:i | | t |
		t := (r at: i + 1) / lc.
		q at: i - d + 1 put: t.
		t = 0 ifFalse: [0 to: d do: [:j | r at: i - d + j + 1 put: (r at: i - d + j + 1) - (t * (other coeffAt: j))]]].
	^Array with: (SymPoly coefficients: q) with: (SymPoly coefficients: (r copyFrom: 1 to: d))!
quotient: other
	^(self divMod: other) at: 1!
remainder: other
	^(self divMod: other) at: 2!
derivative
	self degree < 1 ifTrue: [^SymPoly zero].
	^SymPoly coefficients: ((1 to: self degree) collect: [:k | (coeffs at: k + 1) * k])!
monic
	self isZero ifTrue: [^self].
	^self scaledBy: 1 / self leading!
gcd: other
	| a b r |
	a := self.
	b := other.
	[b isZero] whileFalse: [r := a remainder: b. a := b. b := r].
	^a monic!
content
	"the rational number c with this = c times a primitive polynomial with integer coefficients (c has the sign of the leading coefficient)"
	| g l |
	self isZero ifTrue: [^0].
	g := 0.
	l := 1.
	coeffs do: [:c | g := g gcd: c numerator. l := l lcm: c denominator].
	^self leading < 0 ifTrue: [(g / l) negated] ifFalse: [g / l]!
primitive
	^self scaledBy: 1 / self content! !

!SymPoly methodsFor: 'factoring'!
squareFree
	"Yun's algorithm: an Array of Arrays (factor multiplicity), the factors monic and square-free, whose product is this up to a constant"
	| out a0 b c d i a |
	self degree < 1 ifTrue: [^#()].
	out := OrderedCollection new.
	a0 := self gcd: self derivative.
	b := self quotient: a0.
	c := self derivative quotient: a0.
	d := c - b derivative.
	i := 1.
	[b degree > 0] whileTrue: [
		a := b gcd: d.
		a degree > 0 ifTrue: [out add: (Array with: a monic with: i)].
		b := b quotient: a.
		c := d quotient: a.
		d := c - b derivative.
		i := i + 1].
	^out asArray!
factor
	"an Array: the constant, then Arrays (irreducible factor multiplicity) with integer coefficients and positive leading coefficient"
	| const out |
	self isZero ifTrue: [^Array with: 0 with: #()].
	const := self content.
	out := OrderedCollection new.
	self primitive squareFree do: [:sf |
		(sf at: 1) primitive factorSquareFree do: [:f | out add: (Array with: f with: (sf at: 2))]].
	out := out asArray sort: [:a :b | (a at: 1) orderedBefore: (b at: 1)].
	^Array with: const with: out!
orderedBefore: other
	"a fixed order for listing factors: lower degree first, then by coefficients from the top"
	self degree = other degree ifFalse: [^self degree < other degree].
	self degree to: 0 by: -1 do: [:k | (self coeffAt: k) = (other coeffAt: k) ifFalse: [^(self coeffAt: k) < (other coeffAt: k)]].
	^true!
rationalRoot
	"a root a/b of a polynomial with integer coefficients, or nil"
	| lead trail ps qs |
	self degree < 1 ifTrue: [^nil].
	(self coeffAt: 0) = 0 ifTrue: [^0].
	trail := SymPoly divisorsOf: (self coeffAt: 0).
	lead := SymPoly divisorsOf: self leading.
	(trail isNil or: [lead isNil]) ifTrue: [^nil].
	ps := trail.
	qs := lead.
	qs do: [:q |
		ps do: [:p |
			(self valueAt: p / q) = 0 ifTrue: [^p / q].
			(self valueAt: p negated / q) = 0 ifTrue: [^p negated / q]]].
	^nil!
factorSquareFree
	"the irreducible factors (primitive, integer coefficients) of a square-free primitive polynomial"
	| out work r lin k g |
	out := OrderedCollection new.
	work := self.
	[work degree >= 1 and: [(r := work rationalRoot) notNil]] whileTrue: [
		lin := (SymPoly linearFrom: r denominator to: r numerator negated).
		out add: lin.
		work := (work quotient: lin) primitive].
	work degree >= 2 ifTrue: [
		g := work degree <= 3 ifTrue: [nil] ifFalse: [work kronecker].
		g isNil
			ifTrue: [out add: work]
			ifFalse: [
				out addAll: g factorSquareFree.
				out addAll: (work quotient: g) primitive factorSquareFree]].
	work degree = 1 ifTrue: [out add: work].
	^out!
kronecker
	"a proper factor of degree 2 up to half the degree, found by interpolating divisors of the values at integer points, or nil"
	| n |
	n := self degree.
	2 to: n // 2 do: [:d | | f |
		f := self kroneckerDegree: d.
		f isNil ifFalse: [^f]].
	^nil!
kroneckerDegree: d
	| points vals divs combos index total g x |
	points := OrderedCollection new.
	x := 0.
	[points size < (d + 1)] whileTrue: [
		points add: x.
		x := x > 0 ifTrue: [x negated] ifFalse: [x negated + 1]].
	vals := points collect: [:p | self valueAt: p].
	divs := vals collect: [:v | | ds |
		ds := SymPoly divisorsOf: v.
		ds isNil ifTrue: [^nil].
		ds, (ds collect: [:q | q negated])].
	total := 1.
	divs do: [:ds | total := total * ds size].
	total > 200000 ifTrue: [^nil].
	index := Array new: d + 1 withAll: 1.
	total timesRepeat: [
		| ys |
		ys := (1 to: d + 1) collect: [:i | (divs at: i) at: (index at: i)].
		g := SymPoly interpolate: points asArray values: ys.
		(g degree = d and: [g leading > 0 and: [g coeffs allSatisfy: [:c | c isInteger]]]) ifTrue: [
			(self remainder: g) isZero ifTrue: [^g primitive]].
		"advance the odometer"
		[ | i |
		i := 1.
		[i <= (d + 1) and: [(index at: i) = (divs at: i) size]] whileTrue: [index at: i put: 1. i := i + 1].
		i <= (d + 1) ifTrue: [index at: i put: (index at: i) + 1]] value].
	^nil! !

!SymPoly methodsFor: 'roots'!
numericRoots
	"all the roots as Arrays (re im), by the Durand-Kerner iteration"
	| n c zs iter delta |
	n := self degree.
	n < 1 ifTrue: [^#()].
	c := coeffs collect: [:a | a asFloat / self leading asFloat].
	zs := (0 to: n - 1) collect: [:k | | re im p |
		re := 1.0. im := 0.0.
		k timesRepeat: [p := re * 0.4 - (im * 0.9). im := re * 0.9 + (im * 0.4). re := p].
		Array with: re with: im].
	iter := 0.
	delta := 1.0.
	[iter < 500 and: [delta > 1.0e-14]] whileTrue: [
		delta := 0.0.
		1 to: n do: [:k | | z pr pi dr di q qr qi t |
			z := zs at: k.
			pr := 1.0. pi := 0.0.
			(n - 1) to: 0 by: -1 do: [:j |
				t := pr * (z at: 1) - (pi * (z at: 2)) + (c at: j + 1).
				pi := pr * (z at: 2) + (pi * (z at: 1)).
				pr := t].
			qr := 1.0. qi := 0.0.
			1 to: n do: [:j |
				j = k ifFalse: [ | zj |
					zj := zs at: j.
					t := qr * ((z at: 1) - (zj at: 1)) - (qi * ((z at: 2) - (zj at: 2))).
					qi := qr * ((z at: 2) - (zj at: 2)) + (qi * ((z at: 1) - (zj at: 1))).
					qr := t]].
			q := qr * qr + (qi * qi).
			q = 0.0 ifFalse: [
				dr := (pr * qr + (pi * qi)) / q.
				di := (pi * qr - (pr * qi)) / q.
				z at: 1 put: (z at: 1) - dr.
				z at: 2 put: (z at: 2) - di.
				delta := delta max: dr abs + di abs]].
		iter := iter + 1].
	^zs!
realRoots
	"the real roots as Floats, in increasing order, each polished with a few Newton steps"
	| out d |
	out := OrderedCollection new.
	d := self derivative.
	self numericRoots do: [:z | | r |
		(((z at: 2) abs) < (1.0e-7 * (1.0 + (z at: 1) abs))) ifTrue: [
			r := z at: 1.
			3 timesRepeat: [ | dv |
				dv := d valueAt: r.
				dv = 0.0 ifFalse: [r := r - ((self valueAt: r) / dv)]].
			(out anySatisfy: [:o | (o - r) abs < 1.0e-9]) ifFalse: [out add: r]]].
	^out asArray sort: [:a :b | a < b]! !

!SymLinear class methodsFor: 'solving'!
solve: matrix zero: isZeroBlock normalize: normBlock
	"Gauss-Jordan elimination on rows whose last entry is the right-hand side; the solution, or nil if the
	equations contradict each other; a SymError if they leave an unknown free"
	| rows m n r pivots |
	rows := matrix collect: [:row | row collect: [:e | normBlock value: e]].
	m := rows size.
	n := rows isEmpty ifTrue: [0] ifFalse: [rows first size - 1].
	r := 1.
	pivots := Array new: n withAll: 0.
	1 to: n do: [:col | | p row piv |
		p := nil.
		r to: m do: [:i | (p isNil and: [(isZeroBlock value: ((rows at: i) at: col)) not]) ifTrue: [p := i]].
		p isNil ifFalse: [
			row := rows at: p.
			rows at: p put: (rows at: r).
			rows at: r put: row.
			piv := row at: col.
			row := row collect: [:e | normBlock value: e / piv].
			rows at: r put: row.
			1 to: m do: [:i |
				i = r ifFalse: [ | f other |
					other := rows at: i.
					f := other at: col.
					(isZeroBlock value: f) ifFalse: [
						rows at: i put: ((1 to: n + 1) collect: [:k | normBlock value: (other at: k) - (f * (row at: k))])]]].
			pivots at: col put: r.
			r := r + 1]].
	r to: m do: [:i | (isZeroBlock value: (rows at: i) last) ifFalse: [^nil]].
	pivots do: [:p | p = 0 ifTrue: [^SymError new signal: 'the equations do not determine every unknown']].
	^(1 to: n) collect: [:col | (rows at: (pivots at: col)) last]! !
