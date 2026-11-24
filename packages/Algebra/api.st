"The front door. Algebra has nothing but class-side methods: each takes expressions as text (like 'x^2 - 1'), as numbers, or
as expressions already built, and answers an expression (which prints as text) or, where it should, an Array or a Float.
A problem in the mathematics or in the text signals a SymError whose messageText says what went wrong.

Where a symbol is not named, the one symbol in the expression is used (or x when there are several)."

!Algebra class methodsFor: 'the package'!
version
	^'1.0'!
examples
	"a few things to try"
	^#(#('Algebra expand: ''(x+1)^3''' 'x^3 + 3*x^2 + 3*x + 1')
		#('Algebra factor: ''x^4 - 1''' '(x - 1)*(x + 1)*(x^2 + 1)')
		#('Algebra diff: ''x*sin(x)''' 'sin(x) + x*cos(x)')
		#('Algebra integrate: ''x*exp(x)''' 'x*exp(x) - exp(x)')
		#('Algebra solve: ''x^2 - 2 = 0''' '#(-sqrt(2) sqrt(2))')
		#('Algebra limit: ''sin(x)/x'' at: 0' '1')
		#('Algebra apart: ''1/(x^2-1)''' '1/(2*(x - 1)) - 1/(2*(x + 1))'))! !

!Algebra class methodsFor: 'reading'!
parse: anExpression
	"an expression from text, a number or an expression"
	^SymExpr coerce: anExpression!
expr: anExpression
	^SymExpr coerce: anExpression!
equation: aString
	"the left side minus the right side of  lhs = rhs  (or the text itself when there is no =)"
	| sides |
	aString isString ifFalse: [^SymExpr coerce: aString].
	sides := SymParser splitEquation: aString.
	sides size = 1 ifTrue: [^SymExpr coerce: aString].
	^(SymExpr coerce: (sides at: 1)) - (SymExpr coerce: (sides at: 2))!
variableOf: anExpression
	"the symbol to work with when none is named"
	| vars |
	vars := anExpression variables.
	vars isEmpty ifTrue: [^'x'].
	vars size = 1 ifTrue: [^vars first].
	(vars includes: 'x') ifTrue: [^'x'].
	^SymError new signal: 'which symbol? the expression has ', vars size printString, ' of them: name one'!
nameOf: aSymbolSpec
	^aSymbolSpec isString ifTrue: [aSymbolSpec trimBoth] ifFalse: [aSymbolSpec name]!
bindings: aSpec
	"a Dictionary from the key of a symbol to its replacement; the spec is text like 'x=2, y=a+1', an Association, an Array of Associations, or a Dictionary"
	| map |
	map := Dictionary new.
	aSpec isString ifTrue: [
		(self splitTopLevel: aSpec on: $,) do: [:piece | | sides |
			sides := SymParser splitEquation: piece.
			sides size = 2 ifFalse: [^SymError new signal: 'a binding looks like x=2, not ', piece printString].
			map at: (SymExpr sym: (sides at: 1) trimBoth) key put: (SymExpr coerce: (sides at: 2))].
		^map].
	(aSpec isKindOf: Association) ifTrue: [
		map at: (SymExpr sym: (self nameOf: aSpec key)) key put: (SymExpr coerce: aSpec value).
		^map].
	(aSpec isKindOf: Dictionary) ifTrue: [
		aSpec keysAndValuesDo: [:k :v | map at: (SymExpr sym: (self nameOf: k)) key put: (SymExpr coerce: v)].
		^map].
	aSpec do: [:a | map at: (SymExpr sym: (self nameOf: a key)) key put: (SymExpr coerce: a value)].
	^map!
splitTopLevel: aString on: aChar
	"the pieces of the text between the commas (or whatever) that are not inside brackets"
	| out depth start |
	out := OrderedCollection new.
	depth := 0.
	start := 1.
	1 to: aString size do: [:i | | c |
		c := aString at: i.
		c = $( ifTrue: [depth := depth + 1].
		c = $) ifTrue: [depth := depth - 1].
		(c = aChar and: [depth = 0]) ifTrue: [
			out add: (aString copyFrom: start to: i - 1).
			start := i + 1]].
	out add: (aString copyFrom: start to: aString size).
	^out asArray! !

!Algebra class methodsFor: 'showing'!
text: anExpression
	^(self parse: anExpression) text!
latex: anExpression
	"LaTeX source for the expression"
	^(self parse: anExpression) latex!
pretty: anExpression
	"a two-dimensional picture: fraction bars and raised exponents; show it with displayNl"
	^(self parse: anExpression) pretty!
size: anExpression
	"how many nodes the expression tree has"
	^(self parse: anExpression) nodeCount!
variables: anExpression
	^(self parse: anExpression) variables! !

!Algebra class methodsFor: 'rewriting'!
simplify: anExpression
	^(self parse: anExpression) simplified!
expand: anExpression
	^(self parse: anExpression) expanded!
factor: anExpression
	^(self parse: anExpression) factored!
together: anExpression
	"over a single denominator, the numerator multiplied out"
	^(self parse: anExpression) together!
cancel: anExpression
	"together, with common factors of numerator and denominator removed"
	^(self parse: anExpression) cancelled!
apart: anExpression
	^self apart: anExpression in: (self variableOf: (self parse: anExpression))!
apart: anExpression in: aSymbol
	"partial fractions over the rationals"
	^(self parse: anExpression) apartIn: (self nameOf: aSymbol)!
collect: anExpression in: aSymbol
	"grouped by powers of the symbol"
	^(self parse: anExpression) collected: (self nameOf: aSymbol)!
trigSimplify: anExpression
	"sin^2 + cos^2 = 1 and its relatives"
	^(self parse: anExpression) trigSimplified!
trigExpand: anExpression
	"sin and cos of sums and multiples written with sin and cos of the parts, multiplied out"
	^(self parse: anExpression) trigExpanded expanded!
expandLog: anExpression
	"ln of a product or a power as a sum of ln's, assuming the factors are positive"
	^self log: (self parse: anExpression)!
log: e
	| inner |
	e operands isEmpty ifTrue: [^e].
	inner := e mapChildren: [:c | self log: c].
	inner isFn ifFalse: [^inner].
	(inner isFnNamed: 'ln') ifFalse: [^inner].
	inner arg isMul ifTrue: [
		^SymExpr sum: (inner arg factors collect: [:f | self log: (SymExpr fn: 'ln' of: f)])].
	(inner arg isPow and: [inner arg exponent isNum not or: [inner arg exponent value ~= (1/2) or: [true]]]) ifTrue: [
		^SymExpr product: (Array with: inner arg exponent with: (self log: (SymExpr fn: 'ln' of: inner arg base)))].
	^inner!
isEqual: a to: b
	"true when the difference simplifies to zero"
	| d |
	d := (self parse: a) - (self parse: b).
	d isZero ifTrue: [^true].
	^d simplified isZero!
seemsEqual: a to: b
	"true when the two agree numerically at several points where both have a value (a good sign, not a proof)"
	| ea eb names points compared |
	ea := self parse: a.
	eb := self parse: b.
	names := (ea variables , eb variables) asSet asArray.
	points := #(0.37 1.3 2.9 -0.8 0.11 0.63).
	compared := 0.
	^(points allSatisfy: [:p | | map x y |
		map := Dictionary new.
		names doWithIndex: [:n :i | map at: (SymExpr sym: n) key put: (SymExpr num: p + (i * 0.173))].
		x := [(ea substitute: map) numericOrNil] on: SymError do: [:e | nil].
		y := [(eb substitute: map) numericOrNil] on: SymError do: [:e | nil].
		(x isNil or: [y isNil])
			ifTrue: [x isNil and: [y isNil] ]
			ifFalse: [compared := compared + 1. (x - y) abs <= (1.0e-9 * (1.0 + x abs))]]) and: [compared >= 2]! !

!Algebra class methodsFor: 'evaluating'!
substitute: anExpression with: someBindings
	"replace symbols (all at once): Algebra substitute: 'x^2 + y' with: 'x=3, y=a'"
	^(self parse: anExpression) substitute: (self bindings: someBindings)!
evaluate: anExpression with: someBindings
	"substitute and work out what can be worked out exactly"
	^(self substitute: anExpression with: someBindings) simplified!
numeric: anExpression with: someBindings
	"the value as a Float"
	^(self substitute: anExpression with: someBindings) numericValue!
numeric: anExpression
	^(self parse: anExpression) numericValue!
digits: anExpression
	"the value as a Float, from an expression with no unknowns"
	^self numeric: anExpression! !

!Algebra class methodsFor: 'calculus'!
diff: anExpression
	^self diff: anExpression by: (self variableOf: (self parse: anExpression))!
diff: anExpression by: aSymbol
	^(self parse: anExpression) diffIn: (self nameOf: aSymbol)!
diff: anExpression by: aSymbol times: n
	^(self parse: anExpression) diffIn: (self nameOf: aSymbol) times: n!
integrate: anExpression
	^self integrate: anExpression by: (self variableOf: (self parse: anExpression))!
integrate: anExpression by: aSymbol
	"an antiderivative (no constant); ln of a negative argument stands for ln of its absolute value"
	| e r |
	e := self parse: anExpression.
	r := e antiderivativeIn: (self nameOf: aSymbol).
	r isNil ifTrue: [^SymError new signal: 'no antiderivative found for ', e text].
	^r!
integrate: anExpression by: aSymbol from: a to: b
	"the definite integral, from the antiderivative (take care over singularities between the limits)"
	| f v lo hi |
	f := self integrate: anExpression by: aSymbol.
	v := self nameOf: aSymbol.
	lo := self parse: a.
	hi := self parse: b.
	^((self valueOf: f at: v is: hi) - (self valueOf: f at: v is: lo)) simplified!
valueOf: f at: v is: a
	a isInfinityValue ifTrue: [^f limitIn: v at: a].
	^f valueAt: v is: a ifNone: [SymError new signal: 'the antiderivative is not defined at ', a text]!
limit: anExpression at: aValue
	^self limit: anExpression of: (self variableOf: (self parse: anExpression)) at: aValue!
limit: anExpression of: aSymbol at: aValue
	"the limit as the symbol approaches the value (a number, oo or -oo)"
	^(self parse: anExpression) limitIn: (self nameOf: aSymbol) at: (self parse: aValue)!
series: anExpression in: aSymbol at: a order: n
	"the Taylor polynomial through (x - a)^n"
	^(self parse: anExpression) taylorIn: (self nameOf: aSymbol) at: (self parse: a) order: n!
taylor: anExpression order: n
	"the Maclaurin polynomial"
	^self series: anExpression in: (self variableOf: (self parse: anExpression)) at: 0 order: n!
sum: anExpression in: aSymbol from: lo to: hi
	"the sum: terms added for numeric bounds, closed forms (polynomial summands, geometric series) otherwise"
	^(self parse: anExpression) sumIn: (self nameOf: aSymbol) from: (self parse: lo) to: (self parse: hi)!
product: anExpression in: aSymbol from: lo to: hi
	"the product, for whole-number bounds"
	| e a b |
	e := self parse: anExpression.
	a := (self parse: lo) value.
	b := (self parse: hi) value.
	^SymExpr product: ((a to: b) collect: [:i | | m |
		m := Dictionary new.
		m at: (SymExpr sym: (self nameOf: aSymbol)) key put: (SymExpr num: i).
		e substitute: m])! !

!SymExpr methodsFor: 'evaluating'!
valueAt: aName is: a ifNone: aBlock
	| r |
	r := self valueAt: aName is: a.
	^r isNil ifTrue: [aBlock value] ifFalse: [r]! !

!Algebra class methodsFor: 'solving'!
solve: anEquation
	^self solve: anEquation for: (self variableOf: (self equation: anEquation))!
solve: anEquation for: aSymbol
	"an Array of the solutions of  lhs = rhs  (principal values for the inverse trigonometric functions)"
	^(self equation: anEquation) solveFor: (self nameOf: aSymbol)!
solveSystem: someEquations for: someSymbols
	"an Array of solutions, each an Array of name -> value:  Algebra solveSystem: #('x+y=3' 'x-y=1') for: #('x' 'y')"
	^SymExpr solveSystem: (someEquations collect: [:e | self equation: e]) for: (someSymbols collect: [:s | self nameOf: s])! !

!Algebra class methodsFor: 'polynomials'!
degree: anExpression in: aSymbol
	| cs |
	cs := (self parse: anExpression) polyCoefficientsIn: (self nameOf: aSymbol).
	cs isNil ifTrue: [^SymError new signal: 'not a polynomial in ', (self nameOf: aSymbol)].
	^cs size - 1!
coefficients: anExpression in: aSymbol
	"the coefficients, constant term first, as expressions"
	| cs |
	cs := (self parse: anExpression) polyCoefficientsIn: (self nameOf: aSymbol).
	cs isNil ifTrue: [^SymError new signal: 'not a polynomial in ', (self nameOf: aSymbol)].
	^cs!
polynomial: anExpression in: aSymbol
	| p |
	p := (self parse: anExpression) asPolyIn: (self nameOf: aSymbol).
	p isNil ifTrue: [^SymError new signal: 'not a polynomial in ', (self nameOf: aSymbol), ' with rational coefficients'].
	^p!
quotient: a by: b in: aSymbol
	^((self polynomial: a in: aSymbol) quotient: (self polynomial: b in: aSymbol)) asExprIn: (self nameOf: aSymbol)!
remainder: a by: b in: aSymbol
	^((self polynomial: a in: aSymbol) remainder: (self polynomial: b in: aSymbol)) asExprIn: (self nameOf: aSymbol)!
gcd: a with: b
	"the monic greatest common divisor of two polynomials in the one symbol they share"
	| v |
	v := self variableOf: (self parse: a) + (self parse: b).
	^((self polynomial: a in: v) gcd: (self polynomial: b in: v)) asExprIn: v!
roots: anExpression
	"the real roots of a polynomial in one symbol, as Floats in increasing order"
	| v |
	v := self variableOf: (self parse: anExpression).
	^(self polynomial: anExpression in: v) realRoots!
complexRoots: anExpression
	"all the roots as Arrays (real imaginary)"
	| v |
	v := self variableOf: (self parse: anExpression).
	^(self polynomial: anExpression in: v) numericRoots!
horner: anExpression in: aSymbol
	"the polynomial in nested form: ((a x + b) x + c) x + d"
	| p x r |
	p := self polynomial: anExpression in: aSymbol.
	x := SymExpr sym: (self nameOf: aSymbol).
	r := SymExpr zero.
	p degree to: 0 by: -1 do: [:k | r := (r * x) + (SymExpr num: (p coeffAt: k))].
	^r!
lagrange: points in: aSymbol
	"the polynomial of least degree through the points, an Array of Arrays (x y)"
	^(SymPoly interpolate: (points collect: [:p | p at: 1]) values: (points collect: [:p | p at: 2])) asExprIn: (self nameOf: aSymbol)!
newton: anExpression from: x0 steps: n
	"Newton's method on  f = 0 : the starting value and the next n iterates, exactly (use numeric: for decimals)"
	| f v x out |
	f := self parse: anExpression.
	v := self variableOf: f.
	x := self parse: x0.
	out := OrderedCollection with: x.
	n timesRepeat: [ | map fx dfx |
		map := Dictionary new.
		map at: (SymExpr sym: v) key put: x.
		fx := f substitute: map.
		dfx := (f diffIn: v) substitute: map.
		x := x - (fx / dfx).
		out add: x].
	^out asArray!
binomial: a with: b power: n
	"(a + b)^n multiplied out"
	^((self parse: a) + (self parse: b) raisedTo: n) expanded!
pascalRow: n
	"the coefficients of (a + b)^n"
	^(0 to: n) collect: [:k | n factorial / (k factorial * (n - k) factorial)]!
fibonacci: n
	"the first n Fibonacci numbers"
	| out a b |
	out := OrderedCollection new.
	a := 0.
	b := 1.
	n timesRepeat: [out add: a. b := a + b. a := b - a].
	^out asArray! !
