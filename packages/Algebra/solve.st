"Solving: one equation in one unknown (polynomials exactly - linear, quadratic with surds and complex roots, and higher degrees
by factoring over the rationals, with numeric real roots for the factors that do not split - and equations in which the
unknown occurs once, by undoing the operations), and systems of equations."

!SymExpr methodsFor: 'solving'!
solveFor: v
	"the solutions of  self = 0  for the symbol, as an Array of expressions"
	| nd sols den |
	(self dependsOn: v) ifFalse: [
		self isZero ifTrue: [^SymError new signal: 'every value is a solution'].
		^#()].
	nd := self numerDenom.
	den := nd last.
	sols := self solutionsOfNumerator: nd first expanded for: v.
	^self unique: (sols select: [:s | (self roots: s of: nd first in: v) and: [self doesNotZero: den at: s in: v]])!
unique: aCollection
	| out |
	out := OrderedCollection new.
	aCollection do: [:s | (out includes: s) ifFalse: [out add: s]].
	^self sortedSolutions: out asArray!
sortedSolutions: anArray
	"real numeric ones in increasing order; the rest stay as they are, after them"
	| keyed rest |
	keyed := OrderedCollection new.
	rest := OrderedCollection new.
	anArray do: [:s | | n |
		n := s numericOrNil.
		n isNil ifTrue: [rest add: s] ifFalse: [keyed add: (Array with: n with: s)]].
	keyed := (keyed asArray sort: [:a :b | (a at: 1) < (b at: 1)]) collect: [:p | p at: 2].
	^keyed, rest asArray!
doesNotZero: den at: s in: v
	| map r |
	den isOne ifTrue: [^true].
	map := Dictionary new.
	map at: (SymExpr sym: v) key put: s.
	r := [den substitute: map] on: SymError do: [:e | ^false].
	^r isZero not!
roots: s of: f in: v
	"a check of a candidate: it makes the expression zero (numerically, when it can be told)"
	| map r n |
	map := Dictionary new.
	map at: (SymExpr sym: v) key put: s.
	r := [f substitute: map] on: SymError do: [:e | ^false].
	r isZero ifTrue: [^true].
	n := r numericOrNil.
	n isNil ifTrue: [^true].
	^n abs < 1.0e-6!
solutionsOfNumerator: n for: v
	| cs dep |
	n isMul ifTrue: [ | out |
		out := OrderedCollection new.
		n factors do: [:f | (f dependsOn: v) ifTrue: [out addAll: (self solutionsOfNumerator: f for: v)]].
		^out asArray].
	(n isPow and: [n exponent isNum and: [n exponent value > 0 and: [n exponent value isInteger]]])
		ifTrue: [^self solutionsOfNumerator: n base for: v].
	cs := n polyCoefficientsIn: v.
	cs notNil ifTrue: [^self solvePolynomial: cs in: v].
	dep := n isolateIn: v equals: SymExpr zero.
	^dep!
solvePolynomial: cs in: v
	| deg p fac out |
	deg := cs size - 1.
	deg < 1 ifTrue: [^#()].
	deg = 1 ifTrue: [^Array with: ((cs at: 1) negated / (cs at: 2)) cancelled].
	deg = 2 ifTrue: [^self solveQuadratic: (cs at: 3) b: (cs at: 2) c: (cs at: 1)].
	(cs allSatisfy: [:c | c isNum and: [SymExpr isExact: c value]]) ifFalse: [
		((cs copyFrom: 2 to: deg) allSatisfy: [:c | c isZero]) ifTrue: [^self solveBinomial: cs in: v].
		^SymError new signal: 'cannot solve a polynomial of degree ', deg printString, ' with symbolic coefficients'].
	p := SymPoly coefficients: (cs collect: [:c | c value]).
	fac := p factor.
	out := OrderedCollection new.
	(fac at: 2) do: [:f | | q fc |
		q := f at: 1.
		q degree = 1 ifTrue: [out add: (SymExpr num: (q coeffAt: 0) negated / (q coeffAt: 1))].
		q degree = 2 ifTrue: [out addAll: (self solveQuadratic: (SymExpr num: (q coeffAt: 2)) b: (SymExpr num: (q coeffAt: 1)) c: (SymExpr num: (q coeffAt: 0)))].
		q degree > 2 ifTrue: [
			fc := (1 to: q degree - 1) allSatisfy: [:k | (q coeffAt: k) = 0].
			fc
				ifTrue: [out addAll: (self solveBinomial: (q coeffs collect: [:c | SymExpr num: c]) in: v)]
				ifFalse: [q realRoots do: [:r | out add: (SymExpr num: r)]]]].
	^out asArray!
solveBinomial: cs in: v
	"a x^n + c = 0: the real n-th roots"
	| n r |
	n := cs size - 1.
	r := (cs first negated / cs last).
	n odd ifTrue: [^Array with: (SymExpr power: r to: (SymExpr num: 1 / n))].
	(r isNum and: [r value < 0]) ifTrue: [^#()].
	r := SymExpr power: r to: (SymExpr num: 1 / n).
	^Array with: r negated with: r!
solveQuadratic: a b: b c: c
	| d s |
	d := ((b * b) - (a * c * 4)) expanded.
	d isZero ifTrue: [^Array with: (b negated / (a * 2)) cancelled].
	s := self sqrtOfExpanded: d.
	a isNum
		ifTrue: [^Array with: (((b negated - s) / (a * 2)) expanded) with: (((b negated + s) / (a * 2)) expanded)].
	^Array with: ((b negated - s) / (a * 2)) with: ((b negated + s) / (a * 2))!
sqrtOfExpanded: d
	"the square root, with the numeric content of a sum taken out: sqrt(4 - 4 x^2) = 2 sqrt(1 - x^2)"
	| coeffs g |
	d isAdd ifFalse: [^d sqrt].
	coeffs := d terms collect: [:t | t coefficient].
	(coeffs allSatisfy: [:c | SymExpr isExact: c]) ifFalse: [^d sqrt].
	g := SymPoly contentOf: coeffs.
	g = 1 ifTrue: [^d sqrt].
	^(SymExpr num: g) sqrt * (d / g) expanded sqrt!
isolateIn: v equals: rhs
	^SymError new signal: 'cannot solve this equation'! !

!SymNum methodsFor: 'solving'!
isolateIn: v equals: rhs
	^#()! !

!SymAdd methodsFor: 'solving'!
isolateIn: v equals: rhs
	"self = rhs where the symbol occurs once in self: undo the operations from the outside in"
	| dep rest |
	dep := terms select: [:t | t dependsOn: v].
	dep size = 1 ifFalse: [^SymError new signal: 'cannot solve this equation'].
	rest := SymExpr sum: (terms reject: [:t | t dependsOn: v]).
	^dep first isolateIn: v equals: rhs - rest! !

!SymMul methodsFor: 'solving'!
isolateIn: v equals: rhs
	| dep rest |
	dep := factors select: [:t | t dependsOn: v].
	dep size = 1 ifFalse: [^SymError new signal: 'cannot solve this equation'].
	rest := SymExpr product: (factors reject: [:t | t dependsOn: v]).
	^dep first isolateIn: v equals: rhs / rest! !

!SymPow methodsFor: 'solving'!
isolateIn: v equals: rhs
	| vals out |
	(exponent freeOf: v) ifTrue: [
		vals := OrderedCollection new.
		vals add: (SymExpr power: rhs to: exponent reciprocal).
		(exponent isNum and: [exponent value isInteger and: [exponent value even]])
			ifTrue: [vals add: vals first negated].
		out := OrderedCollection new.
		vals do: [:b | out addAll: (base isolateIn: v equals: b)].
		^out asArray].
	(base freeOf: v) ifTrue: [
		^exponent isolateIn: v equals: (SymExpr fn: 'ln' of: rhs) / (SymExpr fn: 'ln' of: base)].
	^SymError new signal: 'cannot solve this equation'! !

!SymFn methodsFor: 'solving'!
isolateIn: v equals: rhs
	| vals out one |
	one := SymExpr one.
	vals := OrderedCollection new.
	name = 'exp' ifTrue: [vals add: (SymExpr fn: 'ln' of: rhs)].
	name = 'ln' ifTrue: [vals add: (SymExpr fn: 'exp' of: rhs)].
	name = 'sin' ifTrue: [vals add: (SymExpr fn: 'asin' of: rhs); add: SymExpr pi - (SymExpr fn: 'asin' of: rhs)].
	name = 'cos' ifTrue: [vals add: (SymExpr fn: 'acos' of: rhs); add: (SymExpr fn: 'acos' of: rhs) negated].
	name = 'tan' ifTrue: [vals add: (SymExpr fn: 'atan' of: rhs)].
	name = 'asin' ifTrue: [vals add: (SymExpr fn: 'sin' of: rhs)].
	name = 'acos' ifTrue: [vals add: (SymExpr fn: 'cos' of: rhs)].
	name = 'atan' ifTrue: [vals add: (SymExpr fn: 'tan' of: rhs)].
	name = 'sinh' ifTrue: [vals add: (SymExpr fn: 'ln' of: rhs + (rhs squared + one) sqrt)].
	name = 'cosh' ifTrue: [ | t | t := SymExpr fn: 'ln' of: rhs + (rhs squared - one) sqrt. vals add: t; add: t negated].
	name = 'abs' ifTrue: [vals add: rhs; add: rhs negated].
	vals isEmpty ifTrue: [^SymError new signal: 'cannot solve an equation with ', name].
	out := OrderedCollection new.
	vals do: [:b | out addAll: (arg isolateIn: v equals: b)].
	^out asArray! !

!SymSym methodsFor: 'solving'!
isolateIn: v equals: rhs
	^name = v ifTrue: [Array with: rhs] ifFalse: [#()]! !

!SymExpr class methodsFor: 'systems'!
solveSystem: eqs for: vars
	"eqs are expressions that are to be zero, vars the names of the unknowns; an Array of solutions, each an Array of name -> value"
	| rows linear sol zero map |
	linear := true.
	rows := eqs collect: [:eq | | row |
		row := OrderedCollection new.
		vars do: [:v | | c |
			c := (eq diffIn: v) simplified.
			vars do: [:w | (c dependsOn: w) ifTrue: [linear := false]].
			row add: c].
		zero := Dictionary new.
		vars do: [:v | zero at: (SymExpr sym: v) key put: SymExpr zero].
		row add: (eq substitute: zero) negated.
		row asArray].
	linear ifTrue: [
		sol := SymLinear solve: rows zero: [:e | e isZero] normalize: [:e | e simplified].
		sol isNil ifTrue: [^#()].
		^Array with: ((1 to: vars size) collect: [:i | | val |
			val := sol at: i.
			val numerDenom last isNum ifTrue: [val := val expanded].
			(vars at: i) -> val])].
	^self solveNonlinear: eqs asOrderedCollection vars: vars asOrderedCollection!
solveNonlinear: eqs vars: vars
	| out |
	vars isEmpty ifTrue: [^(eqs allSatisfy: [:e | e isZero]) ifTrue: [Array with: #()] ifFalse: [#()]].
	eqs isEmpty ifTrue: [^SymError new signal: 'the equations do not determine every unknown'].
	out := OrderedCollection new.
	eqs do: [:eq |
		out isEmpty ifTrue: [
			vars do: [:v |
				out isEmpty ifTrue: [ | sols |
					(eq dependsOn: v) ifTrue: [
						sols := [eq solveFor: v] on: SymError do: [:e | nil].
						(sols notNil and: [sols notEmpty]) ifTrue: [
							sols do: [:s | | map rest rem later |
								map := Dictionary new.
								map at: (SymExpr sym: v) key put: s.
								rest := (eqs copyWithout: eq) collect: [:q | (q substitute: map) simplified].
								rem := vars copyWithout: v.
								later := self solveNonlinear: rest vars: rem.
								later do: [:sol | | m2 |
									m2 := Dictionary new.
									sol do: [:a | m2 at: (SymExpr sym: a key) key put: a value].
									out add: (((1 to: vars size) collect: [:i | | nm |
										nm := vars at: i.
										nm = v
											ifTrue: [nm -> (s substitute: m2) simplified]
											ifFalse: [nm -> (m2 at: (SymExpr sym: nm) key)]]) asArray)]]]]]]]].
	^out asArray! !
