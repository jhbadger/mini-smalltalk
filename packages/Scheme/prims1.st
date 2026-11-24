"The primitive procedures, part 1: helpers, control (apply, call/cc, values, dynamic-wind, errors, promises, eval), equivalence,
and numbers."

!SchemePrims class methodsFor: 'helpers'!
ordinal: i
	^#('first' 'second' 'third' 'fourth' 'fifth' 'sixth' 'seventh' 'eighth' 'ninth' 'tenth') at: i ifAbsent: [i printString, 'th']!
wrong: obj arg: i to: aName
	"the error for an argument of the wrong type"
	^SchemeError message: 'The object ', (SchemePrinter write: obj), ', passed as the ', (self ordinal: i), ' argument to ', aName, ', is not the correct type.'!
badRange: obj arg: i to: aName
	^SchemeError message: 'The object ', (SchemePrinter write: obj), ', passed as the ', (self ordinal: i), ' argument to ', aName, ', is not in the correct range.'!
isTrue: x
	^x ~~ false!
listArray: l arg: i to: aName
	"the elements of a proper list, as an Array"
	(l == SchemeNil or: [l class == SchemePair and: [l isList]]) ifFalse: [^self wrong: l arg: i to: aName].
	^l asArray!
eqv: a to: b
	a == b ifTrue: [^true].
	(a isNumber and: [b isNumber]) ifTrue: [^a isFloat = b isFloat and: [a = b]].
	(a isCharacter and: [b isCharacter]) ifTrue: [^a = b].
	^false!
equal: a to: b
	| x y |
	(self eqv: a to: b) ifTrue: [^true].
	a class == SchemePair ifTrue: [
		x := a. y := b.
		[x class == SchemePair and: [y class == SchemePair]] whileTrue: [
			(self equal: x car to: y car) ifFalse: [^false].
			x := x cdr. y := y cdr].
		^self equal: x to: y].
	a isSymbol ifTrue: [^false].
	a isString ifTrue: [^b isString and: [b isSymbol not and: [a size = b size and: [a = b]]]].
	a class == Array ifTrue: [
		(b class == Array and: [a size = b size]) ifFalse: [^false].
		1 to: a size do: [:i | (self equal: (a at: i) to: (b at: i)) ifFalse: [^false]].
		^true].
	^false!
isProcedure: x
	| c |
	c := x class.
	^c == SchemeClosure or: [c == SchemePrimitive or: [c == SchemeContinuation or: [c == SchemeParameter or: [c == SchemeCaseLambda]]]]!
isScheme: x list: l
	^l == SchemeNil or: [l class == SchemePair and: [l isList]]!
condition: x
	"the condition behind a raised object, or nil"
	^x class == SchemeCondition ifTrue: [x] ifFalse: [nil]! !

!SchemePrims class methodsFor: 'control'!
installControl
	Scheme def: 'apply' min: 2 max: nil machine: [:m :args |
		| list rest |
		list := OrderedCollection new.
		2 to: args size - 1 do: [:i | list add: (args at: i)].
		rest := SchemePrims listArray: args last arg: args size to: 'apply'.
		list addAll: rest.
		m apply: (args at: 1) args: list asArray].
	Scheme def: 'call-with-current-continuation' min: 1 max: 1 machine: [:m :args | m callCC: (args at: 1)].
	Scheme alias: 'call/cc' for: 'call-with-current-continuation'.
	Scheme alias: 'call-with-escape-continuation' for: 'call-with-current-continuation'.
	Scheme def: 'values' min: 0 max: nil value: [:m :args | args size = 1 ifTrue: [args at: 1] ifFalse: [SchemeValues items: args]].
	Scheme def: 'call-with-values' min: 2 max: 2 machine: [:m :args | m callWithValues: (args at: 1) consumer: (args at: 2)].
	Scheme def: 'dynamic-wind' min: 3 max: 3 machine: [:m :args | m dynamicWind: (args at: 1) thunk: (args at: 2) after: (args at: 3)].
	Scheme def: 'with-exception-handler' min: 2 max: 2 machine: [:m :args | m withHandler: (args at: 1) thunk: (args at: 2)].
	Scheme def: 'raise' min: 1 max: 1 machine: [:m :args | m doRaise: (args at: 1) continuable: false].
	Scheme def: 'raise-continuable' min: 1 max: 1 machine: [:m :args | m doRaise: (args at: 1) continuable: true].
	Scheme def: '%reraise' min: 1 max: 1 machine: [:m :args | m doRaise: (args at: 1) continuable: true].
	Scheme def: 'error' min: 0 max: nil machine: [:m :args |
		m doRaise: (SchemeCondition
			message: (args isEmpty ifTrue: [''] ifFalse: [args at: 1])
			irritants: (SchemePair fromArray: (args copyFrom: 2 to: args size)))
			continuable: false].
	Scheme def: 'warn' min: 1 max: nil value: [:m :args | SchemeUnspec].
	Scheme def: 'assert' min: 1 max: nil value: [:m :args |
		(args at: 1) == false ifTrue: [SchemeError message: 'Assertion failed'].
		SchemeUnspec].
	Scheme def: 'exit' min: 0 max: 1 value: [:m :args |
		SchemeExit new value: (args isEmpty ifTrue: [SchemeUnspec] ifFalse: [args at: 1]); signal].
	Scheme alias: 'emergency-exit' for: 'exit'.
	Scheme alias: '%exit' for: 'exit'.
	Scheme def: 'force' min: 1 max: 1 machine: [:m :args | m force: (args at: 1)].
	Scheme def: 'make-promise' min: 1 max: 1 value: [:m :args |
		(args at: 1) class == SchemePromise ifTrue: [args at: 1] ifFalse: [SchemePromise value: (args at: 1)]].
	Scheme def: 'promise?' do: [:x | x class == SchemePromise].
	Scheme def: 'eval' min: 1 max: 2 machine: [:m :args |
		m env: nil.
		m compileTop: (args at: 1)].
	Scheme def: 'system-global-environment-object' do: [SchemeEnvironment named: 'system-global-environment'].
	Scheme def: 'interaction-environment' min: 0 max: 0 value: [:m :args | SchemeEnvironment named: 'system-global-environment'].
	Scheme def: 'scheme-report-environment' min: 0 max: 1 value: [:m :args | SchemeEnvironment named: 'system-global-environment'].
	Scheme def: 'null-environment' min: 0 max: 1 value: [:m :args | SchemeEnvironment named: 'system-global-environment'].
	Scheme def: 'procedure?' do: [:x | SchemePrims isProcedure: x].
	Scheme def: 'procedure-name' do: [:p | p class == SchemeClosure | (p class == SchemePrimitive) ifTrue: [p name ifNil: ['']] ifFalse: ['']].
	Scheme def: 'default-object?' do: [:x | x == SchemeDefault].
	Scheme def: 'void' min: 0 max: nil value: [:m :args | SchemeUnspec].
	Scheme def: 'runtime' min: 0 max: 0 value: [:m :args | Time millisecondClockValue / 1000.0].
	Scheme def: 'real-time' min: 0 max: 0 value: [:m :args | Time millisecondClockValue asFloat].
	Scheme def: 'current-time' min: 0 max: 0 value: [:m :args | Time millisecondClockValue // 1000].
	Scheme def: 'gensym' min: 0 max: 1 value: [:m :args | m freshSymbolFor: 'g'].
	Scheme alias: 'generate-uninterned-symbol' for: 'gensym'.
	"conditions"
	Scheme def: 'error-object?' do: [:x | x class == SchemeCondition].
	Scheme alias: 'error?' for: 'error-object?'.
	Scheme alias: 'condition?' for: 'error-object?'.
	Scheme def: 'error-message' do: [:c | c class == SchemeCondition ifTrue: [c message] ifFalse: ['']].
	Scheme def: 'error-object-message' do: [:c |
		c class == SchemeCondition ifFalse: [SchemePrims wrong: c arg: 1 to: 'error-object-message'].
		c message isString ifTrue: [c message] ifFalse: [SchemePrinter write: c message]].
	Scheme def: 'error-object-irritants' do: [:c |
		c class == SchemeCondition ifFalse: [SchemePrims wrong: c arg: 1 to: 'error-object-irritants'].
		c irritants].
	Scheme alias: 'error-irritants' for: 'error-object-irritants'.
	Scheme alias: 'error-message-string' for: 'error-object-message'.
	Scheme def: 'condition/report-string' do: [:c |
		c class == SchemeCondition ifFalse: [SchemePrims wrong: c arg: 1 to: 'condition/report-string'].
		c reportString].
	Scheme def: 'file-error?' do: [:x | x class == SchemeCondition and: [x kind == #file]].
	Scheme def: 'read-error?' do: [:x | x class == SchemeCondition and: [x kind == #read]].
	"parameters"
	Scheme def: '%make-parameter' do: [:v :conv | SchemeParameter value: v converter: conv].
	Scheme def: '%parameter-value' do: [:p | p value].
	Scheme def: '%parameter-set!!' do: [:p :v | p value: v. SchemeUnspec].
	Scheme def: '%parameter-converter' do: [:p | p converter ifNil: [SchemePrimitive name: 'identity' min: 1 max: 1 kind: #fixed block: [:x | x]]].
	Scheme def: 'parameter?' do: [:x | x class == SchemeParameter]! !

!SchemePrims class methodsFor: 'equivalence'!
installEquivalence
	Scheme def: 'eq?' do: [:a :b | SchemePrims eqv: a to: b].
	Scheme def: 'eqv?' do: [:a :b | SchemePrims eqv: a to: b].
	Scheme def: 'equal?' do: [:a :b | SchemePrims equal: a to: b].
	Scheme def: 'not' do: [:x | x == false].
	Scheme def: 'boolean?' do: [:x | x == true or: [x == false]].
	Scheme def: 'boolean=?' min: 2 max: nil rest: [:args |
		args do: [:a | (a == true or: [a == false]) ifFalse: [SchemePrims wrong: a arg: 1 to: 'boolean=?']].
		args allSatisfy: [:a | a == (args at: 1)]]! !

!SchemePrims class methodsFor: 'numbers helpers'!
num: x arg: i to: aName
	x isNumber ifFalse: [^self wrong: x arg: i to: aName].
	^x!
int: x arg: i to: aName
	"an integer, or an integral float, as an exact integer"
	x isInteger ifTrue: [^x].
	(x isFloat and: [x isNaN not and: [x isInfinite not and: [x fractionPart = 0]]]) ifTrue: [^x asExactFraction].
	^self wrong: x arg: i to: aName!
integral: x
	^x isInteger or: [x isFloat and: [x isNaN not and: [x isInfinite not and: [x fractionPart = 0]]]]!
divide: a by: b
	b isZero ifTrue: [
		b isFloat ifFalse: [^SchemeError message: 'Division by zero signalled by /.'].
		(a isZero or: [a isNaN]) ifTrue: [^Float nan].
		^a > 0 ifTrue: [Float infinity] ifFalse: [Float infinity negated]].
	^a / b!
isqrt: n
	"the integer square root, rounded down"
	| x y |
	n < 2 ifTrue: [^n].
	x := 1 bitShift: (n highBit + 1) // 2.
	[y := (x + (n // x)) // 2. y >= x] whileFalse: [x := y].
	^x!
roundEven: x
	"round half to even; an inexact number stays inexact"
	| f d half |
	x isInteger ifTrue: [^x].
	x isFloat ifTrue: [
		(x isNaN or: [x isInfinite]) ifTrue: [^x].
		f := x floor. d := x - f.
		d < 0.5 ifTrue: [^f asFloat].
		d > 0.5 ifTrue: [^(f + 1) asFloat].
		^(f even ifTrue: [f] ifFalse: [f + 1]) asFloat].
	f := x floor. d := x - f. half := 1 / 2.
	d < half ifTrue: [^f].
	d > half ifTrue: [^f + 1].
	^f even ifTrue: [f] ifFalse: [f + 1]!
rounding: x with: aSelector name: aName
	"floor, ceiling or truncated; an inexact number stays inexact"
	self num: x arg: 1 to: aName.
	x isInteger ifTrue: [^x].
	x isFloat ifTrue: [
		(x isNaN or: [x isInfinite]) ifTrue: [^x].
		^(x perform: aSelector) asFloat].
	^x perform: aSelector!
toExact: x
	x isFloat ifFalse: [^x].
	(x isNaN or: [x isInfinite]) ifTrue: [^SchemeError message: 'Integer too large to be converted to exact:' with: x].
	^x asExactFraction!
sqrtOf: x
	| r n d rn rd |
	self num: x arg: 1 to: 'sqrt'.
	x isFloat ifTrue: [
		x < 0 ifTrue: [^SchemeError message: 'sqrt: complex results are not supported:' with: x].
		^x sqrt].
	x < 0 ifTrue: [^SchemeError message: 'sqrt: complex results are not supported:' with: x].
	x isInteger ifTrue: [
		r := self isqrt: x.
		^r * r = x ifTrue: [r] ifFalse: [x asFloat sqrt]].
	n := x numerator. d := x denominator.
	rn := self isqrt: n. rd := self isqrt: d.
	(rn * rn = n and: [rd * rd = d]) ifTrue: [^rn / rd].
	^x asFloat sqrt!
expt: b to: e
	| r |
	self num: b arg: 1 to: 'expt'. self num: e arg: 2 to: 'expt'.
	e isInteger ifTrue: [
		e = 0 ifTrue: [^1].
		(b isInteger or: [b isFraction]) ifTrue: [
			(b isZero and: [e < 0]) ifTrue: [^SchemeError message: 'Division by zero signalled by expt.'].
			^b raisedTo: e].
		^b raisedTo: e].
	(b isFloat not and: [e isFraction and: [b > 0]]) ifTrue: [
		r := (b asFloat raisedTo: e asFloat) rounded.
		(r raisedTo: e denominator) = (b raisedTo: e numerator) ifTrue: [^r]].
	b < 0 ifTrue: [^SchemeError message: 'expt: complex results are not supported:' with: b].
	b isZero ifTrue: [^e > 0 ifTrue: [b isFloat ifTrue: [0.0] ifFalse: [0]] ifFalse: [SchemeError message: 'Division by zero signalled by expt.']].
	^b asFloat raisedTo: e asFloat!
flo: x name: aName exact: exactCase do: aBlock
	"apply a float function; the exact argument 0 (or 1 for log) has an exact answer"
	| v |
	self num: x arg: 1 to: aName.
	(exactCase notNil and: [x isInteger and: [x = (exactCase at: 1)]]) ifTrue: [^exactCase at: 2].
	^aBlock value: x asFloat!
asin: x
	| f |
	f := x asFloat.
	(f > 1.0 or: [f < -1.0]) ifTrue: [^Float nan].
	f = 1.0 ifTrue: [^Float pi / 2].
	f = -1.0 ifTrue: [^Float pi / -2].
	^f arcSin!
acos: x
	| f |
	f := x asFloat.
	(f > 1.0 or: [f < -1.0]) ifTrue: [^Float nan].
	f = 1.0 ifTrue: [^0.0].
	f = -1.0 ifTrue: [^Float pi].
	^f arcCos!
compare: args name: aName with: aBlock
	"a chain of comparisons, true when each neighbouring pair satisfies aBlock"
	| ok |
	1 to: args size do: [:i | self num: (args at: i) arg: i to: aName].
	ok := true.
	1 to: args size - 1 do: [:i | (aBlock value: (args at: i) value: (args at: i + 1)) ifFalse: [ok := false]].
	^ok!
generator
	^Generator ifNil: [Generator := Random new]!
numberToString: x radix: r
	(r between: 2 and: 36) ifFalse: [^SchemePrims badRange: r arg: 2 to: 'number->string'].
	^SchemePrinter numberString: x radix: r! !

!SchemePrims class methodsFor: 'numbers'!
installNumbers
	Scheme def: 'number?' do: [:x | x isNumber].
	Scheme alias: 'complex?' for: 'number?'.
	Scheme alias: 'real?' for: 'number?'.
	Scheme def: 'rational?' do: [:x | x isInteger or: [x isFraction or: [x isFloat and: [x isNaN not and: [x isInfinite not]]]]].
	Scheme def: 'integer?' do: [:x | x isNumber and: [SchemePrims integral: x]].
	Scheme def: 'exact?' do: [:x | (SchemePrims num: x arg: 1 to: 'exact?') isFloat not].
	Scheme def: 'inexact?' do: [:x | (SchemePrims num: x arg: 1 to: 'inexact?') isFloat].
	Scheme def: 'exact-integer?' do: [:x | x isInteger].
	Scheme def: 'exact-rational?' do: [:x | x isInteger or: [x isFraction]].
	Scheme def: 'exact-nonnegative-integer?' do: [:x | x isInteger and: [x >= 0]].
	Scheme def: 'nan?' do: [:x | (SchemePrims num: x arg: 1 to: 'nan?') isFloat and: [x isNaN]].
	Scheme def: 'finite?' do: [:x | (SchemePrims num: x arg: 1 to: 'finite?') isFloat not or: [x isNaN not and: [x isInfinite not]]].
	Scheme def: 'infinite?' do: [:x | (SchemePrims num: x arg: 1 to: 'infinite?') isFloat and: [x isInfinite]].
	Scheme def: 'zero?' do: [:x | (SchemePrims num: x arg: 1 to: 'zero?') = 0].
	Scheme def: 'positive?' do: [:x | (SchemePrims num: x arg: 1 to: 'positive?') > 0].
	Scheme def: 'negative?' do: [:x | (SchemePrims num: x arg: 1 to: 'negative?') < 0].
	Scheme def: 'odd?' do: [:x | (SchemePrims int: x arg: 1 to: 'odd?') odd].
	Scheme def: 'even?' do: [:x | (SchemePrims int: x arg: 1 to: 'even?') even].
	Scheme def: '+' min: 0 max: nil rest: [:args |
		| sum |
		sum := 0.
		1 to: args size do: [:i | sum := sum + (SchemePrims num: (args at: i) arg: i to: 'integer-add')].
		sum].
	Scheme def: '*' min: 0 max: nil rest: [:args |
		| prod |
		prod := 1.
		1 to: args size do: [:i | prod := prod * (SchemePrims num: (args at: i) arg: i to: 'integer-multiply')].
		prod].
	Scheme def: '-' min: 1 max: nil rest: [:args |
		| r |
		r := SchemePrims num: (args at: 1) arg: 1 to: 'integer-subtract'.
		args size = 1 ifTrue: [r negated] ifFalse: [
			2 to: args size do: [:i | r := r - (SchemePrims num: (args at: i) arg: i to: 'integer-subtract')].
			r]].
	Scheme def: '/' min: 1 max: nil rest: [:args |
		| r |
		r := SchemePrims num: (args at: 1) arg: 1 to: '/'.
		args size = 1 ifTrue: [SchemePrims divide: 1 by: r] ifFalse: [
			2 to: args size do: [:i | r := SchemePrims divide: r by: (SchemePrims num: (args at: i) arg: i to: '/')].
			r]].
	Scheme def: '=' min: 1 max: nil rest: [:args | SchemePrims compare: args name: 'integer-equal?' with: [:a :b | a = b]].
	Scheme def: '<' min: 1 max: nil rest: [:args | SchemePrims compare: args name: 'integer-less?' with: [:a :b | a < b]].
	Scheme def: '>' min: 1 max: nil rest: [:args | SchemePrims compare: args name: 'integer-less?' with: [:a :b | a > b]].
	Scheme def: '<=' min: 1 max: nil rest: [:args | SchemePrims compare: args name: 'integer-less-or-equal?' with: [:a :b | a <= b]].
	Scheme def: '>=' min: 1 max: nil rest: [:args | SchemePrims compare: args name: 'integer-less-or-equal?' with: [:a :b | a >= b]].
	Scheme def: 'max' min: 1 max: nil rest: [:args |
		| r inexact |
		r := SchemePrims num: (args at: 1) arg: 1 to: 'max'. inexact := r isFloat.
		2 to: args size do: [:i |
			| x |
			x := SchemePrims num: (args at: i) arg: i to: 'max'.
			x isFloat ifTrue: [inexact := true].
			x > r ifTrue: [r := x]].
		inexact ifTrue: [r asFloat] ifFalse: [r]].
	Scheme def: 'min' min: 1 max: nil rest: [:args |
		| r inexact |
		r := SchemePrims num: (args at: 1) arg: 1 to: 'min'. inexact := r isFloat.
		2 to: args size do: [:i |
			| x |
			x := SchemePrims num: (args at: i) arg: i to: 'min'.
			x isFloat ifTrue: [inexact := true].
			x < r ifTrue: [r := x]].
		inexact ifTrue: [r asFloat] ifFalse: [r]].
	Scheme def: 'abs' do: [:x | (SchemePrims num: x arg: 1 to: 'integer-abs') abs].
	Scheme alias: 'magnitude' for: 'abs'.
	Scheme def: '1+' do: [:x | (SchemePrims num: x arg: 1 to: 'integer-add') + 1].
	Scheme def: '-1+' do: [:x | (SchemePrims num: x arg: 1 to: 'integer-subtract') - 1].
	Scheme alias: '1-' for: '-1+'.
	Scheme def: 'square' do: [:x | (SchemePrims num: x arg: 1 to: 'integer-multiply') * x].
	Scheme def: 'cube' do: [:x | (SchemePrims num: x arg: 1 to: 'integer-multiply') * x * x].
	Scheme def: 'quotient' do: [:a :b |
		| x y q |
		x := SchemePrims int: a arg: 1 to: 'integer-quotient'. y := SchemePrims int: b arg: 2 to: 'integer-quotient'.
		y = 0 ifTrue: [SchemeError message: 'Division by zero signalled by integer-quotient.'].
		q := x quo: y.
		(a isFloat or: [b isFloat]) ifTrue: [q asFloat] ifFalse: [q]].
	Scheme alias: 'truncate-quotient' for: 'quotient'.
	Scheme def: 'remainder' do: [:a :b |
		| x y q |
		x := SchemePrims int: a arg: 1 to: 'integer-remainder'. y := SchemePrims int: b arg: 2 to: 'integer-remainder'.
		y = 0 ifTrue: [SchemeError message: 'Division by zero signalled by integer-remainder.'].
		q := x rem: y.
		(a isFloat or: [b isFloat]) ifTrue: [q asFloat] ifFalse: [q]].
	Scheme alias: 'truncate-remainder' for: 'remainder'.
	Scheme def: 'modulo' do: [:a :b |
		| x y q |
		x := SchemePrims int: a arg: 1 to: 'integer-modulo'. y := SchemePrims int: b arg: 2 to: 'integer-modulo'.
		y = 0 ifTrue: [SchemeError message: 'Division by zero signalled by modulo.'].
		q := x \\ y.
		(a isFloat or: [b isFloat]) ifTrue: [q asFloat] ifFalse: [q]].
	Scheme alias: 'floor-remainder' for: 'modulo'.
	Scheme def: 'floor-quotient' do: [:a :b |
		| x y q |
		x := SchemePrims int: a arg: 1 to: 'floor-quotient'. y := SchemePrims int: b arg: 2 to: 'floor-quotient'.
		y = 0 ifTrue: [SchemeError message: 'Division by zero signalled by floor-quotient.'].
		q := x // y.
		(a isFloat or: [b isFloat]) ifTrue: [q asFloat] ifFalse: [q]].
	Scheme def: 'floor/' min: 2 max: 2 value: [:m :args |
		| x y |
		x := SchemePrims int: (args at: 1) arg: 1 to: 'floor/'. y := SchemePrims int: (args at: 2) arg: 2 to: 'floor/'.
		y = 0 ifTrue: [SchemeError message: 'Division by zero signalled by floor/.'].
		SchemeValues items: (Array with: x // y with: x \\ y)].
	Scheme def: 'truncate/' min: 2 max: 2 value: [:m :args |
		| x y |
		x := SchemePrims int: (args at: 1) arg: 1 to: 'truncate/'. y := SchemePrims int: (args at: 2) arg: 2 to: 'truncate/'.
		y = 0 ifTrue: [SchemeError message: 'Division by zero signalled by truncate/.'].
		SchemeValues items: (Array with: (x quo: y) with: (x rem: y))].
	Scheme def: 'gcd' min: 0 max: nil rest: [:args |
		| g |
		g := 0.
		1 to: args size do: [:i | g := g gcd: (SchemePrims int: (args at: i) arg: i to: 'gcd')].
		g].
	Scheme def: 'lcm' min: 0 max: nil rest: [:args |
		| l |
		l := 1.
		1 to: args size do: [:i |
			| x |
			x := SchemePrims int: (args at: i) arg: i to: 'lcm'.
			l := x = 0 ifTrue: [0] ifFalse: [l = 0 ifTrue: [0] ifFalse: [l lcm: x]]].
		l abs].
	Scheme def: 'floor' do: [:x | SchemePrims rounding: x with: #floor name: 'floor'].
	Scheme def: 'ceiling' do: [:x | SchemePrims rounding: x with: #ceiling name: 'ceiling'].
	Scheme def: 'truncate' do: [:x | SchemePrims rounding: x with: #truncated name: 'truncate'].
	Scheme def: 'round' do: [:x | SchemePrims roundEven: (SchemePrims num: x arg: 1 to: 'round')].
	Scheme def: 'floor->exact' do: [:x | SchemePrims toExact: (SchemePrims rounding: x with: #floor name: 'floor->exact')].
	Scheme def: 'ceiling->exact' do: [:x | SchemePrims toExact: (SchemePrims rounding: x with: #ceiling name: 'ceiling->exact')].
	Scheme def: 'truncate->exact' do: [:x | SchemePrims toExact: (SchemePrims rounding: x with: #truncated name: 'truncate->exact')].
	Scheme def: 'round->exact' do: [:x | SchemePrims toExact: (SchemePrims roundEven: (SchemePrims num: x arg: 1 to: 'round->exact'))].
	Scheme def: 'numerator' do: [:x |
		SchemePrims num: x arg: 1 to: 'numerator'.
		x isFloat ifTrue: [x asExactFraction numerator asFloat] ifFalse: [x numerator]].
	Scheme def: 'denominator' do: [:x |
		SchemePrims num: x arg: 1 to: 'denominator'.
		x isFloat ifTrue: [x asExactFraction denominator asFloat] ifFalse: [x denominator]].
	Scheme def: 'exact' do: [:x | SchemePrims toExact: (SchemePrims num: x arg: 1 to: 'inexact->exact')].
	Scheme alias: 'inexact->exact' for: 'exact'.
	Scheme def: 'inexact' do: [:x | (SchemePrims num: x arg: 1 to: 'exact->inexact') asFloat].
	Scheme alias: 'exact->inexact' for: 'inexact'.
	Scheme def: 'sqrt' do: [:x | SchemePrims sqrtOf: x].
	Scheme def: 'exact-integer-sqrt' min: 1 max: 1 value: [:m :args |
		| n s |
		n := args at: 1.
		(n isInteger and: [n >= 0]) ifFalse: [SchemePrims wrong: n arg: 1 to: 'exact-integer-sqrt'].
		s := SchemePrims isqrt: n.
		SchemeValues items: (Array with: s with: n - (s * s))].
	Scheme def: 'cbrt' do: [:x | (SchemePrims num: x arg: 1 to: 'cbrt') asFloat raisedTo: 1 / 3].
	Scheme def: 'expt' do: [:b :e | SchemePrims expt: b to: e].
	Scheme def: 'exp' do: [:x | SchemePrims flo: x name: 'exp' exact: (Array with: 0 with: 1) do: [:f | f exp]].
	Scheme def: 'log' min: 1 max: 2 rest: [:args |
		| x |
		x := SchemePrims num: (args at: 1) arg: 1 to: 'log'.
		args size = 2
			ifTrue: [
				x isZero ifTrue: [SchemeError message: 'Division by zero signalled by log.'].
				x asFloat ln / (SchemePrims num: (args at: 2) arg: 2 to: 'log') asFloat ln]
			ifFalse: [
				(x isInteger and: [x = 1]) ifTrue: [0] ifFalse: [
					x < 0 ifTrue: [SchemeError message: 'log: complex results are not supported:' with: x].
					x isZero ifTrue: [Float infinity negated] ifFalse: [x asFloat ln]]]].
	Scheme def: 'sin' do: [:x | SchemePrims flo: x name: 'sin' exact: (Array with: 0 with: 0) do: [:f | f sin]].
	Scheme def: 'cos' do: [:x | SchemePrims flo: x name: 'cos' exact: (Array with: 0 with: 1) do: [:f | f cos]].
	Scheme def: 'tan' do: [:x | SchemePrims flo: x name: 'tan' exact: (Array with: 0 with: 0) do: [:f | f tan]].
	Scheme def: 'asin' do: [:x | SchemePrims flo: x name: 'asin' exact: (Array with: 0 with: 0) do: [:f | SchemePrims asin: f]].
	Scheme def: 'acos' do: [:x | SchemePrims flo: x name: 'acos' exact: (Array with: 1 with: 0) do: [:f | SchemePrims acos: f]].
	Scheme def: 'atan' min: 1 max: 2 rest: [:args |
		| y x |
		y := SchemePrims num: (args at: 1) arg: 1 to: 'atan'.
		args size = 2
			ifTrue: [
				x := SchemePrims num: (args at: 2) arg: 2 to: 'atan'.
				(y isInteger and: [y = 0 and: [x isInteger and: [x > 0]]])
					ifTrue: [0]
					ifFalse: [y asFloat arcTan: x asFloat]]
			ifFalse: [(y isInteger and: [y = 0]) ifTrue: [0] ifFalse: [y asFloat arcTan]]].
	Scheme def: 'number->string' min: 1 max: 2 rest: [:args |
		SchemePrims numberToString: (SchemePrims num: (args at: 1) arg: 1 to: 'number->string')
			radix: (args size = 2 ifTrue: [args at: 2] ifFalse: [10])].
	Scheme def: 'string->number' min: 1 max: 2 rest: [:args |
		| s n |
		s := args at: 1.
		(s isString and: [s isSymbol not]) ifFalse: [SchemePrims wrong: s arg: 1 to: 'string->number'].
		n := SchemeReader parseNumber: s radix: (args size = 2 ifTrue: [args at: 2] ifFalse: [10]).
		n isNil ifTrue: [false] ifFalse: [n]].
	Scheme def: 'random' min: 1 max: 2 rest: [:args |
		| n |
		n := args at: 1.
		(n isNumber and: [n > 0]) ifFalse: [SchemePrims badRange: n arg: 1 to: 'random'].
		n isFloat
			ifTrue: [SchemePrims generator next * n]
			ifFalse: [
				n isInteger ifFalse: [SchemePrims wrong: n arg: 1 to: 'random'].
				n < 1000000000
					ifTrue: [(SchemePrims generator next * n) truncated]
					ifFalse: [
						| r |
						r := 0.
						(n highBit // 24 + 2) timesRepeat: [r := r * 16777216 + (SchemePrims generator next * 16777216) truncated].
						r \\ n]]].
	Scheme def: 'bitwise-and' min: 0 max: nil rest: [:args | args inject: -1 into: [:a :b | a bitAnd: (SchemePrims int: b arg: 1 to: 'bitwise-and')]].
	Scheme def: 'bitwise-or' min: 0 max: nil rest: [:args | args inject: 0 into: [:a :b | a bitOr: (SchemePrims int: b arg: 1 to: 'bitwise-or')]].
	Scheme def: 'bitwise-xor' min: 0 max: nil rest: [:args | args inject: 0 into: [:a :b | a bitXor: (SchemePrims int: b arg: 1 to: 'bitwise-xor')]].
	Scheme def: 'bitwise-not' do: [:x | (SchemePrims int: x arg: 1 to: 'bitwise-not') bitInvert].
	Scheme def: 'arithmetic-shift' do: [:x :n | (SchemePrims int: x arg: 1 to: 'arithmetic-shift') bitShift: (SchemePrims int: n arg: 2 to: 'arithmetic-shift')].
	Scheme def: 'shift-left' do: [:x :n | (SchemePrims int: x arg: 1 to: 'shift-left') bitShift: n].
	Scheme def: 'shift-right' do: [:x :n | (SchemePrims int: x arg: 1 to: 'shift-right') bitShift: n negated].
	Scheme def: 'bit-count' do: [:x |
		| n c |
		n := SchemePrims int: x arg: 1 to: 'bit-count'. c := 0.
		[n > 0] whileTrue: [n odd ifTrue: [c := c + 1]. n := n bitShift: -1].
		c]! !
