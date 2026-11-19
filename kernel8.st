"Mini Smalltalk-80 kernel, part 8: numbers - Float constants and tests, bit operations on negative large integers, radix printing, more Integer and Number protocol"

!Float class methodsFor: 'constants'!
nan
	^self infinity - self infinity!
negativeInfinity
	^self infinity negated!
epsilon
	"the difference between 1.0 and the next larger Float"
	^2.220446049250313e-16!
fmax
	^1.7976931348623157e308!
fmin
	"the smallest positive normalized Float"
	^2.2250738585072014e-308!
halfPi
	^self pi / 2!
twoPi
	^self pi * 2!
ln2
	^0.6931471805599453!
ln10
	^2.302585092994046!
emax
	^1023!
emin
	^-1022!
precision
	^53!
radix
	^2! !

!Float methodsFor: 'testing'!
isNaN
	^self ~= self!
isInfinite
	^self = Float infinity or: [self = Float negativeInfinity]!
isFinite
	^self isNaN not and: [self isInfinite not]! !

!Float methodsFor: 'mathematical functions'!
sinh
	^(self exp - self negated exp) / 2!
cosh
	^(self exp + self negated exp) / 2!
tanh
	| a b |
	self > 20 ifTrue: [^1.0].
	self < -20 ifTrue: [^-1.0].
	a := self exp. b := self negated exp.
	^(a - b) / (a + b)!
log
	"logarithm to the base 10"
	<primitive: 59>
	^self error: 'log failed'! !

!Number methodsFor: 'mathematical functions'!
sqrt
	<primitive: 51>
	^self isFloat ifTrue: [self error: 'sqrt failed'] ifFalse: [self asFloat sqrt]!
ln
	<primitive: 52>
	^self isFloat ifTrue: [self error: 'ln failed'] ifFalse: [self asFloat ln]!
exp
	<primitive: 53>
	^self isFloat ifTrue: [self error: 'exp failed'] ifFalse: [self asFloat exp]!
sin
	<primitive: 54>
	^self isFloat ifTrue: [self error: 'sin failed'] ifFalse: [self asFloat sin]!
cos
	<primitive: 55>
	^self isFloat ifTrue: [self error: 'cos failed'] ifFalse: [self asFloat cos]!
arcTan
	<primitive: 56>
	^self isFloat ifTrue: [self error: 'arcTan failed'] ifFalse: [self asFloat arcTan]!
sinh
	^self asFloat sinh!
cosh
	^self asFloat cosh!
tanh
	^self asFloat tanh!
log
	^self asFloat log!
cubed
	^self * self * self!
arcTan: aNumber
	"the angle of the point (aNumber, self), in radians, in the right quadrant"
	aNumber > 0 ifTrue: [^(self / aNumber) arcTan].
	aNumber < 0 ifTrue: [^self >= 0 ifTrue: [(self / aNumber) arcTan + Float pi] ifFalse: [(self / aNumber) arcTan - Float pi]].
	self > 0 ifTrue: [^Float halfPi].
	self < 0 ifTrue: [^Float halfPi negated].
	^0.0!
withSign: aNumber
	"the receiver's magnitude with the sign of aNumber"
	^aNumber negative ifTrue: [self abs negated] ifFalse: [self abs]! !

!Number methodsFor: 'truncation and round off'!
integerPart
	^self truncated!
fractionPart
	^self - self truncated! !

!Number methodsFor: 'testing'!
closeTo: aNumber
	"equal within a small relative error"
	self = aNumber ifTrue: [^true].
	^(self - aNumber) abs / (self abs max: aNumber abs) < 0.0001!
isRational
	^false!
isSmallInteger
	^false! !

!Number methodsFor: 'converting'!
asNumber
	^self! !

!Number methodsFor: 'enumerating'!
to: stop collect: aBlock
	^(self to: stop) collect: aBlock!
to: stop by: step collect: aBlock
	^(self to: stop by: step) collect: aBlock! !

!Integer methodsFor: 'testing'!
isRational
	^true!
isPerfectSquare
	^self >= 0 and: [self sqrtFloor squared = self]! !

!SmallInteger methodsFor: 'testing'!
isSmallInteger
	^true! !

!SmallInteger class methodsFor: 'constants'!
maxVal
	^2305843009213693951!
minVal
	^-2305843009213693952! !

!Fraction methodsFor: 'testing'!
isRational
	^true! !

!Fraction methodsFor: 'truncation and round off'!
integerPart
	^self truncated!
fractionPart
	^self - self truncated! !

"---- bit operations with two's complement semantics for negative operands ----
The primitives handle non-negative operands of any size. A negative operand x is handled through
x bitInvert (= -1 - x, which is non-negative), using the identities
   a & b = a - (a & ~b) = ~(~a | ~b)      a | b = ~(~a & ~b)      a ^ b = ~a ^ ~b for two negatives."

!Integer methodsFor: 'private bit operations'!
checkBitArgument: anInteger
	anInteger isInteger ifFalse: [^self error: 'bit operations need an Integer argument']!
primBitAnd: anInteger
	<primitive: 150>
	| na nb |
	self checkBitArgument: anInteger.
	self < 0
		ifTrue: [
			anInteger < 0 ifTrue: [^(self bitInvert bitOr: anInteger bitInvert) bitInvert].
			^anInteger - (anInteger bitAnd: self bitInvert)]
		ifFalse: [^self - (self bitAnd: anInteger bitInvert)]!
primBitOr: anInteger
	<primitive: 151>
	self checkBitArgument: anInteger.
	self < 0
		ifTrue: [
			anInteger < 0 ifTrue: [^(self bitInvert bitAnd: anInteger bitInvert) bitInvert].
			^(self bitInvert - (self bitInvert bitAnd: anInteger)) bitInvert]
		ifFalse: [^(anInteger bitInvert - (anInteger bitInvert bitAnd: self)) bitInvert]!
primBitXor: anInteger
	<primitive: 152>
	self checkBitArgument: anInteger.
	self < 0
		ifTrue: [
			anInteger < 0 ifTrue: [^self bitInvert bitXor: anInteger bitInvert].
			^(self bitInvert bitXor: anInteger) bitInvert]
		ifFalse: [^(self bitXor: anInteger bitInvert) bitInvert]!
primBitShift: anInteger
	<primitive: 153>
	anInteger isInteger ifFalse: [^self error: 'bad shift'].
	^anInteger >= 0
		ifTrue: [self * (2 raisedTo: anInteger)]
		ifFalse: [self // (2 raisedTo: anInteger negated)]! !

!Integer methodsFor: 'bit manipulation'!
bitClear: aMask
	^self bitAnd: aMask bitInvert!
bitCount
	"the number of 1 bits in the magnitude"
	| c n |
	c := 0. n := self abs.
	[n > 0] whileTrue: [c := c + (n bitAnd: 1). n := n bitShift: -1].
	^c!
lowBit
	"the index (from 1) of the least significant 1 bit; 0 for 0"
	| n i |
	self = 0 ifTrue: [^0].
	n := self abs. i := 1.
	[n odd] whileFalse: [n := n bitShift: -1. i := i + 1].
	^i!
anyMask: aMask
	^(self bitAnd: aMask) ~= 0!
allMask: aMask
	^(self bitAnd: aMask) = aMask!
noMask: aMask
	^(self bitAnd: aMask) = 0! !

!Integer methodsFor: 'number theory'!
raisedTo: exponent modulo: modulus
	"self ** exponent \\ modulus, without building the huge intermediate power"
	| result base e |
	exponent < 0 ifTrue: [^self error: 'negative exponent'].
	result := 1 \\ modulus. base := self \\ modulus. e := exponent.
	[e > 0] whileTrue: [
		e odd ifTrue: [result := result * base \\ modulus].
		e := e bitShift: -1.
		base := base * base \\ modulus].
	^result!
isProbablyPrime
	"Miller-Rabin with the first twelve primes as witnesses: exact below 3.3 * 10^24"
	| d r |
	self < 2 ifTrue: [^false].
	#(2 3 5 7 11 13 17 19 23 29 31 37) do: [:p |
		self = p ifTrue: [^true].
		self \\ p = 0 ifTrue: [^false]].
	d := self - 1. r := 0.
	[d even] whileTrue: [d := d bitShift: -1. r := r + 1].
	#(2 3 5 7 11 13 17 19 23 29 31 37) do: [:a | | x composite |
		x := a raisedTo: d modulo: self.
		(x = 1 or: [x = (self - 1)]) ifFalse: [
			composite := true.
			r - 1 timesRepeat: [
				composite ifTrue: [
					x := x * x \\ self.
					x = (self - 1) ifTrue: [composite := false]]].
			composite ifTrue: [^false]]].
	^true!
primeFactors
	"the prime factors in increasing order, with repetition"
	| n f r |
	self < 2 ifTrue: [^Array new].
	n := self. r := OrderedCollection new. f := 2.
	[f * f <= n] whileTrue: [
		[n \\ f = 0] whileTrue: [r add: f. n := n // f].
		f := f = 2 ifTrue: [3] ifFalse: [f + 2]].
	n > 1 ifTrue: [r add: n].
	^r asArray!
binomial: k
	"the number of ways to choose k of the receiver's elements"
	| r |
	(k < 0 or: [k > self]) ifTrue: [^0].
	r := 1.
	1 to: (k min: self - k) do: [:i | r := r * (self - (k min: self - k) + i) // i].
	^r! !

!Integer methodsFor: 'printing'!
numberOfDigits
	^self abs printString size!
hex
	^self printString: 16!
printStringHex
	^self printString: 16!
printStringRadix: base
	"16rFF"
	^self < 0
		ifTrue: ['-', base printString, 'r', (self negated printString: base)]
		ifFalse: [base printString, 'r', (self printString: base)]!
storeString: base
	^self printStringRadix: base!
storeStringRadix: base
	^self printStringRadix: base! !


!LargePositiveInteger methodsFor: 'mathematical functions'!
ln
	"natural logarithm, valid beyond the range of a Float"
	| shift |
	shift := self highBit - 60.
	^shift <= 0 ifTrue: [self asFloat ln] ifFalse: [(self bitShift: shift negated) asFloat ln + (shift * Float ln2)]!
log
	^self ln / Float ln10! !
