"The table of primitives, and the arithmetic ones: the atomic verbs (+ - * % ^ | < > = and the rest), which work on single
items and so on arrays of any shape by the scalar extension, and the numeric helpers they share. Whole numbers are
exact and unbounded; % of two integers is an integer when it divides, else a float; rationals (3r4) stay exact."

!APLPrims class methodsFor: 'the table'!
table
	Table isNil ifTrue: [self build].
	^Table!
isSpelling: s
	^self table includesKey: s!
lookup: s
	^self table at: s ifAbsent: [APLError message: 'spelling error: ', s]!
cap
	^self table at: '[:'!
installNamesIn: names
	"the names that every session starts with"
	self table keysAndValuesDo: [:k :v | (k startsWith: 'name:') ifTrue: [names at: (k copyFrom: 6 to: k size) put: v]]!
build
	Table := Dictionary new.
	self defineAtomic.
	self defineStructural.
	self defineSearching.
	self defineAdverbs.
	self defineConjunctions.
	self defineOthers.
	self linkInverses!
infinity
	^APLVerb infinity!
av: spelling m: mBlock d: dBlock
	| v |
	v := APLVerb atomicName: spelling monad: mBlock dyad: dBlock.
	Table at: spelling put: v.
	^v!
sv: spelling m: msel d: dsel ranks: ranks
	| v |
	v := APLVerb name: spelling monad: msel dyad: dsel ranks: ranks.
	Table at: spelling put: v.
	^v!
mixed: spelling m: msel mr: mrank d: dBlock
	"a monadic verb on whole arrays whose dyad is atomic"
	| v |
	v := APLVerb name: spelling monad: msel dyad: nil ranks: (Array with: mrank with: 0 with: 0).
	v atomicMonad: nil dyad: dBlock.
	Table at: spelling put: v.
	^v!
linkInverse: a with: b
	| va vb |
	va := Table at: a. vb := Table at: b.
	va inverse: vb.
	vb inverse: va!
linkInverses
	self linkInverse: '+' with: '+'.
	self linkInverse: '-' with: '-'.
	self linkInverse: '%' with: '%'.
	self linkInverse: '^' with: '^.'.
	self linkInverse: '*:' with: '%:'.
	self linkInverse: '>:' with: '<:'.
	self linkInverse: '|.' with: '|.'.
	self linkInverse: '|:' with: '|:'.
	self linkInverse: '<' with: '>'.
	self linkInverse: '-.' with: '-.'.
	self linkInverse: '-:' with: '+:'.
	self linkInverse: ']' with: ']'.
	self linkInverse: '[' with: '['.
	self linkInverse: '#.' with: '#:'!
setIdentity: spelling to: anItem
	(Table at: spelling) identity: (APLArray scalar: anItem)! !

!APLPrims class methodsFor: 'numbers'!
flag: aBoolean
	^aBoolean ifTrue: [1] ifFalse: [0]!
isInfinite: a
	^a isFloat and: [a = Float infinity or: [a = Float infinity negated]]!
divide: a by: b
	b = 0 ifTrue: [
		a = 0 ifTrue: [^0].
		^a > 0 ifTrue: [Float infinity] ifFalse: [Float infinity negated]].
	(a isFloat or: [b isFloat]) ifTrue: [^a asFloat / b asFloat].
	(a isInteger and: [b isInteger]) ifTrue: [^(a \\ b) = 0 ifTrue: [a // b] ifFalse: [(a / b) asFloat]].
	^a / b!
power: a to: b
	| r |
	b isInteger ifTrue: [
		b >= 0 ifTrue: [^a isFloat ifTrue: [a asFloat raisedTo: b] ifFalse: [a raisedTo: b]].
		a = 0 ifTrue: [^Float infinity].
		r := 1 / (a raisedTo: b negated).
		^(a isInteger or: [a isFloat]) ifTrue: [r asFloat] ifFalse: [r]].
	a = 0 ifTrue: [^b > 0 ifTrue: [0] ifFalse: [Float infinity]].
	a < 0 ifTrue: [^APLError domain].
	^a asFloat raisedTo: b asFloat!
exp: a
	a = 0 ifTrue: [^1].
	^a asFloat exp!
ln: a
	a = 0 ifTrue: [^Float infinity negated].
	a < 0 ifTrue: [^APLError domain].
	^a asFloat ln!
residue: a of: b
	a = 0 ifTrue: [^b].
	(a isInteger and: [b isInteger]) ifTrue: [^b \\ a].
	^b - (a * (b / a) floor)!
floor: a
	(a isInteger or: [self isInfinite: a]) ifTrue: [^a].
	^a floor!
ceiling: a
	(a isInteger or: [self isInfinite: a]) ifTrue: [^a].
	^a ceiling!
lcm: a with: b
	(a = 0 or: [b = 0]) ifTrue: [^0].
	^(a * b) abs // (a gcd: b)!
sqrt: a
	| r |
	a < 0 ifTrue: [^APLError domain].
	a isInteger ifTrue: [
		r := a sqrtFloor.
		r * r = a ifTrue: [^r]].
	^a asFloat sqrt!
root: x of: y
	x = 0 ifTrue: [^APLError domain].
	x = 2 ifTrue: [^self sqrt: y].
	^self power: y to: (self divide: 1 by: x)!
factorial: a
	| n |
	(a isFloat and: [a = a truncated]) ifTrue: [n := a truncated] ifFalse: [n := a].
	(n isInteger and: [n >= 0]) ifFalse: [^APLError domain].
	^n factorial!
outOf: x with: y
	"out of: how many ways to choose x of y"
	| r |
	(x isInteger and: [y isInteger]) ifFalse: [^APLError domain].
	(x < 0 or: [y < 0]) ifTrue: [^APLError domain].
	x > y ifTrue: [^0].
	r := 1.
	1 to: x do: [:k | r := r * (y - x + k) // k].
	^r!
circle: x with: y
	| f |
	f := y asFloat.
	x = 0 ifTrue: [^(1 - (f * f)) sqrt].
	x = 1 ifTrue: [^f sin].
	x = 2 ifTrue: [^f cos].
	x = 3 ifTrue: [^f tan].
	x = 5 ifTrue: [^(f exp - f negated exp) / 2].
	x = 6 ifTrue: [^(f exp + f negated exp) / 2].
	x = 7 ifTrue: [^(f exp - f negated exp) / (f exp + f negated exp)].
	x = -1 ifTrue: [^f arcSin].
	x = -2 ifTrue: [^f arcCos].
	x = -3 ifTrue: [^f arcTan].
	^APLError domain!
random
	Generator isNil ifTrue: [Generator := Random new].
	^Generator!
roll: a
	a = 0 ifTrue: [^self random next].
	a isInteger ifFalse: [^APLError domain].
	^(self random next * a) truncated!
exactOf: a
	"the exact rational nearest a float (as continued fractions find it), unchanged for an exact number"
	| x n0 d0 n1 d1 b f n d k |
	a isFloat ifFalse: [^a].
	(a isNaN or: [self isInfinite: a]) ifTrue: [^APLError domain].
	a = a truncated ifTrue: [^a truncated].
	x := a abs.
	n0 := 0. d0 := 1. n1 := 1. d1 := 0.
	f := x.
	k := 0.
	[k < 40] whileTrue: [
		b := f floor.
		n := b * n1 + n0. d := b * d1 + d0.
		n0 := n1. d0 := d1. n1 := n. d1 := d.
		((n / d) asFloat - x) abs <= (x * 1.0e-15) ifTrue: [k := 100] ifFalse: [
			f := f - b.
			f = 0 ifTrue: [k := 100] ifFalse: [f := 1.0 / f. k := k + 1]]].
	^a < 0 ifTrue: [(n1 / d1) negated] ifFalse: [n1 / d1]! !

!APLPrims class methodsFor: 'atomic verbs'!
defineAtomic
	self av: '+' m: [:a | a] d: [:a :b | a + b].
	self av: '-' m: [:a | a negated] d: [:a :b | a - b].
	self av: '*' m: [:a | a sign] d: [:a :b | a * b].
	self av: '%' m: [:a | self divide: 1 by: a] d: [:a :b | self divide: a by: b].
	self av: '^' m: [:a | self exp: a] d: [:a :b | self power: a to: b].
	self av: '^.' m: [:a | self ln: a] d: [:a :b | self divide: (self ln: b) by: (self ln: a)].
	self av: '|' m: [:a | a abs] d: [:a :b | self residue: a of: b].
	self av: '<.' m: [:a | self floor: a] d: [:a :b | a min: b].
	self av: '>.' m: [:a | self ceiling: a] d: [:a :b | a max: b].
	self av: '<:' m: [:a | a - 1] d: [:a :b | self flag: a <= b].
	self av: '>:' m: [:a | a + 1] d: [:a :b | self flag: a >= b].
	self av: '=' m: nil d: [:a :b | self flag: a = b].
	self av: '*.' m: nil d: [:a :b | self lcm: a with: b].
	self av: '+.' m: nil d: [:a :b | a gcd: b].
	self av: '*:' m: [:a | a * a] d: [:a :b | self flag: (a ~= 0 and: [b ~= 0]) not].
	self av: '+:' m: [:a | a * 2] d: [:a :b | self flag: (a ~= 0 or: [b ~= 0]) not].
	self av: '%:' m: [:a | self sqrt: a] d: [:a :b | self root: a of: b].
	self av: '!!' m: [:a | self factorial: a] d: [:a :b | self outOf: a with: b].
	self av: 'o.' m: [:a | a * 1.0 * Float pi] d: [:a :b | self circle: a with: b].
	self av: 'x:' m: [:a | self exactOf: a] d: nil.
	self mixed: '<' m: #box: mr: self infinity d: [:a :b | self flag: a < b].
	self mixed: '>' m: #open: mr: 0 d: [:a :b | self flag: a > b].
	self mixed: '~:' m: #nubSieve: mr: self infinity d: [:a :b | self flag: a ~= b].
	(self sv: '-.' m: nil d: #less:with: ranks: (Array with: 0 with: self infinity with: self infinity))
		atomicMonad: [:a | 1 - a] dyad: nil.
	self setIdentity: '+' to: 0.
	self setIdentity: '-' to: 0.
	self setIdentity: '*' to: 1.
	self setIdentity: '%' to: 1.
	self setIdentity: '^' to: 1.
	self setIdentity: '<.' to: Float infinity.
	self setIdentity: '>.' to: Float infinity negated.
	self setIdentity: '*.' to: 1.
	self setIdentity: '+.' to: 0.
	self setIdentity: '=' to: 1.
	self setIdentity: '~:' to: 0.
	self setIdentity: '<:' to: 1.
	self setIdentity: '>:' to: 0! !
