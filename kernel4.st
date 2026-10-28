"Mini Smalltalk-80 kernel, part 4: exact arithmetic (Fraction, LargeIntegers), generality coercion, Date, Time, Rectangle"

Number subclass: #Fraction instanceVariableNames: 'numerator denominator' classVariableNames: '' category: 'Kernel-Numbers'!
Integer variableByteSubclass: #LargePositiveInteger instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Numbers'!
LargePositiveInteger variableByteSubclass: #LargeNegativeInteger instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Numbers'!
Magnitude subclass: #Date instanceVariableNames: 'day year' classVariableNames: 'DaysInMonth FirstDayOfMonth MonthNames WeekDayNames' category: 'Kernel-Magnitudes'!
Magnitude subclass: #Time instanceVariableNames: 'seconds' classVariableNames: '' category: 'Kernel-Magnitudes'!
Object subclass: #Rectangle instanceVariableNames: 'origin corner' classVariableNames: '' category: 'Graphics-Primitives'!

!Number methodsFor: 'coercing'!
generality
	^self subclassResponsibility!
coerce: aNumber
	^self subclassResponsibility!
retry: aSymbol coercing: aNumber
	"Arithmetic between numbers of different classes: convert the less general one"
	aNumber isNumber ifFalse: [
		aSymbol == #= ifTrue: [^false].
		aSymbol == #~= ifTrue: [^true].
		^self error: 'argument to ', aSymbol, ' must be a number'].
	self generality > aNumber generality ifTrue: [^self perform: aSymbol with: (self coerce: aNumber)].
	self generality < aNumber generality ifTrue: [^(aNumber coerce: self) perform: aSymbol with: aNumber].
	^self error: 'coercion of ', self class name, ' and ', aNumber class name, ' failed'! !

!Number methodsFor: 'testing'!
isFraction
	^false!
isNaN
	^false!
isInfinite
	^false! !

!Number methodsFor: 'mathematical functions'!
tan
	^self sin / self cos!
arcSin
	^(self / (1 - self squared) sqrt) arcTan!
arcCos
	^Float pi / 2 - self arcSin!
floorLog: radix
	^(self log: radix) floor!
degreesToRadians
	^self asFloat / 180.0 * Float pi!
radiansToDegrees
	^self asFloat / Float pi * 180.0!
asFraction
	^self asExactFraction!
asExactFraction
	^self subclassResponsibility! !

!Number methodsFor: 'printing'!
storeOn: aStream
	self printOn: aStream!
printString: base
	^self printString!
printOn: aStream base: base
	aStream nextPutAll: (self printString: base)! !

!Number class methodsFor: 'instance creation'!
readFrom: aStream
	"Answer a number from the digits on aStream (an Integer, a Fraction-free decimal, or a Float); nil if none"
	| neg value digit scale radix |
	aStream skipSeparators.
	neg := aStream peekFor: $-.
	(aStream atEnd or: [aStream peek isDigit not]) ifTrue: [^nil].
	value := 0.
	[aStream atEnd not and: [aStream peek isDigit]] whileTrue: [value := value * 10 + aStream next digitValue].
	(aStream peekFor: $r) ifTrue: [
		radix := value. value := 0.
		[aStream atEnd not and: [aStream peek digitValue between: 0 and: radix - 1]] whileTrue: [value := value * radix + aStream next digitValue]].
	(aStream atEnd not and: [aStream peek = $. and: [(aStream skip: 1; atEnd) not and: [aStream peek isDigit]]])
		ifTrue: [
			scale := 1.0. value := value asFloat.
			[aStream atEnd not and: [aStream peek isDigit]] whileTrue: [scale := scale / 10. value := value + (aStream next digitValue * scale)]]
		ifFalse: [aStream atEnd ifFalse: [aStream peek = $. ifTrue: [aStream skip: -1]]].
	(aStream peekFor: $e) ifTrue: [
		| eneg exp |
		eneg := aStream peekFor: $-. exp := 0.
		[aStream atEnd not and: [aStream peek isDigit]] whileTrue: [exp := exp * 10 + aStream next digitValue].
		value := value * (10 raisedTo: (eneg ifTrue: [exp negated] ifFalse: [exp]))].
	^neg ifTrue: [value negated] ifFalse: [value]!
readFromString: aString
	^self readFrom: (ReadStream on: aString)! !

!Integer class methodsFor: 'instance creation'!
readFrom: aStream
	| n |
	n := Number readFrom: aStream.
	^n isNil ifTrue: [nil] ifFalse: [n truncated]! !

!Integer methodsFor: 'arithmetic'!
+ aNumber
	<primitive: 20>
	^aNumber isInteger ifTrue: [self primAdd: aNumber] ifFalse: [self retry: #+ coercing: aNumber]!
- aNumber
	<primitive: 21>
	^aNumber isInteger ifTrue: [self primSubtract: aNumber] ifFalse: [self retry: #- coercing: aNumber]!
* aNumber
	<primitive: 22>
	^aNumber isInteger ifTrue: [self primMultiply: aNumber] ifFalse: [self retry: #* coercing: aNumber]!
/ aNumber
	<primitive: 25>
	aNumber isInteger ifFalse: [^self retry: #/ coercing: aNumber].
	aNumber = 0 ifTrue: [^self zeroDivide].
	^(Fraction numerator: self denominator: aNumber) reduced!
// aNumber
	<primitive: 23>
	aNumber isInteger ifFalse: [^self retry: #// coercing: aNumber].
	aNumber = 0 ifTrue: [^self zeroDivide].
	^self primDiv: aNumber!
\\ aNumber
	<primitive: 24>
	aNumber isInteger ifFalse: [^self retry: #\\ coercing: aNumber].
	aNumber = 0 ifTrue: [^self zeroDivide].
	^self primMod: aNumber!
quo: aNumber
	<primitive: 38>
	aNumber isInteger ifFalse: [^self retry: #quo: coercing: aNumber].
	aNumber = 0 ifTrue: [^self zeroDivide].
	^self primQuo: aNumber!
rem: aNumber
	<primitive: 39>
	aNumber isInteger ifFalse: [^self retry: #rem: coercing: aNumber].
	aNumber = 0 ifTrue: [^self zeroDivide].
	^self primRem: aNumber!
negated
	^0 - self!
abs
	^self < 0 ifTrue: [self negated] ifFalse: [self]!
zeroDivide
	^self error: 'division by zero'!
gcd: anInteger
	| a b t |
	a := self abs. b := anInteger abs.
	[b = 0] whileFalse: [t := a \\ b. a := b. b := t].
	^a!
lcm: anInteger
	(self = 0 or: [anInteger = 0]) ifTrue: [^0].
	^(self * anInteger) abs // (self gcd: anInteger)!
factorial
	| r |
	self < 0 ifTrue: [^self error: 'factorial of a negative number'].
	r := 1.
	2 to: self do: [:i | r := r * i].
	^r!
raisedTo: aNumber
	| r b e |
	aNumber isInteger ifFalse: [^self asFloat raisedTo: aNumber].
	aNumber < 0 ifTrue: [^(self raisedTo: aNumber negated) reciprocal].
	r := 1. b := self. e := aNumber.
	[e > 0] whileTrue: [e odd ifTrue: [r := r * b]. e := e bitShift: -1. e > 0 ifTrue: [b := b * b]].
	^r!
isPrime
	| i |
	self < 2 ifTrue: [^false].
	i := 2.
	[i * i <= self] whileTrue: [self \\ i = 0 ifTrue: [^false]. i := i + 1].
	^true!
sqrtFloor
	"the largest integer whose square does not exceed the receiver"
	| guess |
	self < 0 ifTrue: [^self error: 'square root of a negative number'].
	self < 2 ifTrue: [^self].
	guess := self asFloat sqrt truncated.
	[guess * guess > self] whileTrue: [guess := guess - 1].
	[(guess + 1) * (guess + 1) <= self] whileTrue: [guess := guess + 1].
	^guess! !

!Integer methodsFor: 'private arithmetic'!
primAdd: anInteger
	<primitive: 130>
	^self primitiveFailed!
primSubtract: anInteger
	<primitive: 131>
	^self primitiveFailed!
primMultiply: anInteger
	<primitive: 132>
	^self primitiveFailed!
primDiv: anInteger
	<primitive: 133>
	^self primitiveFailed!
primMod: anInteger
	<primitive: 134>
	^self primitiveFailed!
primQuo: anInteger
	<primitive: 135>
	^self primitiveFailed!
primRem: anInteger
	<primitive: 136>
	^self primitiveFailed!
primCompare: anInteger
	"answer -1, 0 or 1"
	<primitive: 137>
	^self primitiveFailed!
primPrintString: base
	<primitive: 138>
	^self primitiveFailed!
primAsFloat
	<primitive: 139>
	^self primitiveFailed! !

!Integer methodsFor: 'comparing'!
< aNumber
	<primitive: 26>
	^aNumber isInteger ifTrue: [(self primCompare: aNumber) < 0] ifFalse: [self retry: #< coercing: aNumber]!
> aNumber
	<primitive: 27>
	^aNumber isInteger ifTrue: [(self primCompare: aNumber) > 0] ifFalse: [self retry: #> coercing: aNumber]!
<= aNumber
	<primitive: 28>
	^aNumber isInteger ifTrue: [(self primCompare: aNumber) <= 0] ifFalse: [self retry: #<= coercing: aNumber]!
>= aNumber
	<primitive: 29>
	^aNumber isInteger ifTrue: [(self primCompare: aNumber) >= 0] ifFalse: [self retry: #>= coercing: aNumber]!
= aNumber
	<primitive: 30>
	aNumber isNumber ifFalse: [^false].
	^aNumber isInteger ifTrue: [(self primCompare: aNumber) = 0] ifFalse: [self retry: #= coercing: aNumber]!
~= aNumber
	<primitive: 31>
	^(self = aNumber) not!
hash
	<primitive: 64>
	^0! !

!Integer methodsFor: 'bit manipulation'!
bitAnd: anInteger
	<primitive: 32>
	^self primBitAnd: anInteger!
bitOr: anInteger
	<primitive: 33>
	^self primBitOr: anInteger!
bitXor: anInteger
	<primitive: 34>
	^self primBitXor: anInteger!
bitShift: anInteger
	<primitive: 35>
	^self primBitShift: anInteger!
primBitAnd: anInteger
	<primitive: 150>
	^self error: 'bit operations on negative large integers are not supported'!
primBitOr: anInteger
	<primitive: 151>
	^self error: 'bit operations on negative large integers are not supported'!
primBitXor: anInteger
	<primitive: 152>
	^self error: 'bit operations on negative large integers are not supported'!
primBitShift: anInteger
	<primitive: 153>
	^self error: 'bad shift'!
<< anInteger
	^self bitShift: anInteger!
>> anInteger
	^self bitShift: anInteger negated!
bitAt: index
	^(self bitShift: 1 - index) bitAnd: 1!
bitInvert
	^-1 - self!
highBit
	| n v |
	self < 0 ifTrue: [^self error: 'highBit of a negative number'].
	n := 0. v := self.
	[v > 0] whileTrue: [n := n + 1. v := v bitShift: -1].
	^n!
isPowerOfTwo
	^self > 0 and: [(self bitAnd: self - 1) = 0]! !

!Integer methodsFor: 'converting'!
asFloat
	<primitive: 36>
	^self primAsFloat!
asInteger
	^self!
asExactFraction
	^self!
truncated
	^self!
rounded
	^self!
floor
	^self!
ceiling
	^self!
asCharacter
	^Character value: self!
generality
	^40!
coerce: aNumber
	^aNumber truncated!
numerator
	^self!
denominator
	^1!
isLargeInteger
	^false! !

!Integer methodsFor: 'printing'!
printString: base
	<primitive: 37>
	^self primPrintString: base!
printOn: aStream
	aStream nextPutAll: (self printString: 10)!
printOn: aStream base: base
	aStream nextPutAll: (self printString: base)!
radix: base
	^self printString: base!
printStringRadix: base
	^base printString, 'r', (self printString: base)!
storeOn: aStream
	aStream nextPutAll: self printString!
printPaddedWith: aCharacter to: width
	| s |
	s := self printString.
	[s size < width] whileTrue: [s := (String with: aCharacter), s].
	^s!
asStringWithCommas
	| s r |
	s := self abs printString. r := ''.
	[s size > 3] whileTrue: [r := ',', (s last: 3), r. s := s allButLast: 3].
	r := s, r.
	^self < 0 ifTrue: ['-', r] ifFalse: [r]! !

!LargePositiveInteger methodsFor: 'testing'!
isLargeInteger
	^true!
negative
	^false!
positive
	^true!
sign
	^1! !

!LargePositiveInteger methodsFor: 'accessing'!
digitAt: index
	^self basicAt: index!
digitLength
	^self basicSize! !

!LargeNegativeInteger methodsFor: 'testing'!
negative
	^true!
positive
	^false!
sign
	^-1! !

!Fraction class methodsFor: 'instance creation'!
numerator: n denominator: d
	^self basicNew setNumerator: n denominator: d! !

!Fraction methodsFor: 'private'!
setNumerator: n denominator: d
	d = 0 ifTrue: [^self error: 'division by zero'].
	d < 0 ifTrue: [numerator := n negated. denominator := d negated] ifFalse: [numerator := n. denominator := d]!
reduced
	| g |
	numerator = 0 ifTrue: [^0].
	g := numerator gcd: denominator.
	g = denominator ifTrue: [^numerator // g].
	g > 1 ifTrue: [^Fraction numerator: numerator // g denominator: denominator // g].
	^self! !

!Fraction methodsFor: 'accessing'!
numerator
	^numerator!
denominator
	^denominator! !

!Fraction methodsFor: 'arithmetic'!
+ aNumber
	aNumber isFraction ifTrue: [^(Fraction numerator: numerator * aNumber denominator + (aNumber numerator * denominator) denominator: denominator * aNumber denominator) reduced].
	^self retry: #+ coercing: aNumber!
- aNumber
	aNumber isFraction ifTrue: [^(Fraction numerator: numerator * aNumber denominator - (aNumber numerator * denominator) denominator: denominator * aNumber denominator) reduced].
	^self retry: #- coercing: aNumber!
* aNumber
	aNumber isFraction ifTrue: [^(Fraction numerator: numerator * aNumber numerator denominator: denominator * aNumber denominator) reduced].
	^self retry: #* coercing: aNumber!
/ aNumber
	aNumber isFraction ifTrue: [
		aNumber numerator = 0 ifTrue: [^self error: 'division by zero'].
		^(Fraction numerator: numerator * aNumber denominator denominator: denominator * aNumber numerator) reduced].
	^self retry: #/ coercing: aNumber!
// aNumber
	^(self / aNumber) floor!
\\ aNumber
	^self - (self // aNumber * aNumber)!
negated
	^Fraction numerator: numerator negated denominator: denominator!
abs
	^Fraction numerator: numerator abs denominator: denominator!
reciprocal
	numerator = 0 ifTrue: [^self error: 'division by zero'].
	^(Fraction numerator: denominator denominator: numerator) reduced!
squared
	^Fraction numerator: numerator squared denominator: denominator squared!
raisedTo: aNumber
	aNumber isInteger ifFalse: [^self asFloat raisedTo: aNumber].
	aNumber < 0 ifTrue: [^(self raisedTo: aNumber negated) reciprocal].
	^(Fraction numerator: (numerator raisedTo: aNumber) denominator: (denominator raisedTo: aNumber)) reduced!
sqrt
	^self asFloat sqrt!
ln
	^self asFloat ln! !

!Fraction methodsFor: 'comparing'!
< aNumber
	aNumber isFraction ifTrue: [^numerator * aNumber denominator < (aNumber numerator * denominator)].
	^self retry: #< coercing: aNumber!
> aNumber
	aNumber isFraction ifTrue: [^numerator * aNumber denominator > (aNumber numerator * denominator)].
	^self retry: #> coercing: aNumber!
<= aNumber
	aNumber isFraction ifTrue: [^numerator * aNumber denominator <= (aNumber numerator * denominator)].
	^self retry: #<= coercing: aNumber!
>= aNumber
	aNumber isFraction ifTrue: [^numerator * aNumber denominator >= (aNumber numerator * denominator)].
	^self retry: #>= coercing: aNumber!
= aNumber
	aNumber isNumber ifFalse: [^false].
	aNumber isFraction ifTrue: [^numerator = aNumber numerator and: [denominator = aNumber denominator]].
	^self retry: #= coercing: aNumber!
hash
	^numerator hash bitXor: denominator hash! !

!Fraction methodsFor: 'testing'!
isFraction
	^true!
isZero
	^numerator = 0!
negative
	^numerator < 0!
sign
	^numerator sign! !

!Fraction methodsFor: 'converting'!
asFloat
	^numerator asFloat / denominator asFloat!
asExactFraction
	^self!
truncated
	^numerator quo: denominator!
floor
	^numerator // denominator!
ceiling
	^(numerator // denominator) + 1!
rounded
	^(self + (self sign / 2)) truncated!
generality
	^60!
coerce: aNumber
	^Fraction numerator: aNumber truncated denominator: 1! !

!Fraction methodsFor: 'printing'!
printOn: aStream
	aStream nextPut: $(; print: numerator; nextPut: $/; print: denominator; nextPut: $)!
storeOn: aStream
	self printOn: aStream! !

!Float methodsFor: 'arithmetic'!
+ aNumber
	<primitive: 40>
	^self retry: #+ coercing: aNumber!
- aNumber
	<primitive: 41>
	^self retry: #- coercing: aNumber!
* aNumber
	<primitive: 42>
	^self retry: #* coercing: aNumber!
/ aNumber
	<primitive: 43>
	aNumber isNumber ifTrue: [aNumber = 0 ifTrue: [^self error: 'division by zero']].
	^self retry: #/ coercing: aNumber!
// aNumber
	^(self / aNumber) floor!
\\ aNumber
	^self - (self // aNumber * aNumber)!
negated
	^0.0 - self!
abs
	^self < 0.0 ifTrue: [self negated] ifFalse: [self]!
fractionPart
	<primitive: 58>
	^self error: 'failed'!
integerPart
	^self - self fractionPart!
raisedTo: aNumber
	<primitive: 57>
	^self retry: #raisedTo: coercing: aNumber!
timesTwoPower: anInteger
	^self * (2 raisedTo: anInteger)!
exponent
	self = 0.0 ifTrue: [^0].
	^(self abs log: 2) floor!
ln
	<primitive: 52>
	^self error: 'ln failed'! !

!Float methodsFor: 'comparing'!
< aNumber
	<primitive: 44>
	^self retry: #< coercing: aNumber!
> aNumber
	<primitive: 45>
	^self retry: #> coercing: aNumber!
<= aNumber
	<primitive: 46>
	^self retry: #<= coercing: aNumber!
>= aNumber
	<primitive: 47>
	^self retry: #>= coercing: aNumber!
= aNumber
	<primitive: 48>
	aNumber isNumber ifFalse: [^false].
	^self retry: #= coercing: aNumber!
hash
	<primitive: 64>
	^0! !

!Float methodsFor: 'converting'!
asFloat
	^self!
isFloat
	^true!
truncated
	<primitive: 49>
	^self primTruncatedToLargeInteger!
primTruncatedToLargeInteger
	<primitive: 155>
	^self error: 'cannot truncate ', self printString!
asExactFraction
	| n d |
	self fractionPart = 0.0 ifTrue: [^self truncated].
	d := 1. n := self.
	[n fractionPart ~= 0.0 and: [d < 1000000000000]] whileTrue: [n := n * 2. d := d * 2].
	^(Fraction numerator: n truncated denominator: d) reduced!
generality
	^80!
coerce: aNumber
	^aNumber asFloat!
isNaN
	^self ~= self!
isInfinite
	^self = Float infinity or: [self = Float infinity negated]! !

!Float methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: self printString!
printString
	<primitive: 50>
	^'aFloat'!
printString: base
	^self printString!
storeOn: aStream
	self printOn: aStream! !

!Date class methodsFor: 'class initialization'!
initialize
	MonthNames := #(#January #February #March #April #May #June #July #August #September #October #November #December).
	WeekDayNames := #(#Monday #Tuesday #Wednesday #Thursday #Friday #Saturday #Sunday).
	DaysInMonth := #(31 28 31 30 31 30 31 31 30 31 30 31).
	FirstDayOfMonth := #(1 32 60 91 121 152 182 213 244 274 305 335)! !

!Date class methodsFor: 'instance creation'!
today
	^self fromDays: Time primSecondsClock // 86400!
fromDays: dayCount
	"days since 1 January 1901"
	| days year |
	days := dayCount. year := 1901.
	days < 0 ifTrue: [[days < 0] whileTrue: [year := year - 1. days := days + (self daysInYear: year)]]
		ifFalse: [[days >= (self daysInYear: year)] whileTrue: [days := days - (self daysInYear: year). year := year + 1]].
	^self basicNew setDay: days + 1 year: year!
newDay: dayCount year: yearInteger
	^self basicNew setDay: dayCount year: yearInteger!
newDay: day month: month year: year
	| m |
	m := month isInteger ifTrue: [month] ifFalse: [self indexOfMonth: month].
	^self basicNew setDay: (self firstDayOfMonth: m forYear: year) + day - 1 year: year!
year: y month: m day: d
	^self newDay: d month: m year: y!
readFrom: aStream
	"day monthName year, e.g. 28 October 2026"
	| d m y name |
	aStream skipSeparators. d := Integer readFrom: aStream. aStream skipSeparators.
	name := WriteStream on: String new.
	[aStream atEnd not and: [aStream peek isLetter]] whileTrue: [name nextPut: aStream next].
	aStream skipSeparators. y := Integer readFrom: aStream.
	m := self indexOfMonth: name contents.
	^self newDay: d month: m year: y! !

!Date class methodsFor: 'general inquiries'!
nameOfDay: dayIndex
	^WeekDayNames at: dayIndex!
nameOfMonth: monthIndex
	^MonthNames at: monthIndex!
indexOfMonth: aName
	| lower |
	lower := aName asLowercase.
	1 to: 12 do: [:i | ((MonthNames at: i) asLowercase startsWith: (lower copyFrom: 1 to: (3 min: lower size))) ifTrue: [^i]].
	^self error: 'unknown month ', aName!
dayOfWeek: dayName
	| lower |
	lower := dayName asLowercase.
	1 to: 7 do: [:i | ((WeekDayNames at: i) asLowercase startsWith: (lower copyFrom: 1 to: (3 min: lower size))) ifTrue: [^i]].
	^self error: 'unknown day ', dayName!
daysInMonth: monthName forYear: year
	| m |
	m := monthName isInteger ifTrue: [monthName] ifFalse: [self indexOfMonth: monthName].
	^(m = 2 and: [self leapYear: year]) ifTrue: [29] ifFalse: [DaysInMonth at: m]!
daysInYear: year
	^(self leapYear: year) ifTrue: [366] ifFalse: [365]!
leapYear: year
	^(year \\ 4 = 0 and: [year \\ 100 ~= 0]) or: [year \\ 400 = 0]!
firstDayOfMonth: monthIndex forYear: year
	| d |
	d := FirstDayOfMonth at: monthIndex.
	^(monthIndex > 2 and: [self leapYear: year]) ifTrue: [d + 1] ifFalse: [d]!
dateAndTimeNow
	^Array with: self today with: Time now! !

!Date methodsFor: 'private'!
setDay: dayOfYear year: yearInteger
	day := dayOfYear. year := yearInteger! !

!Date methodsFor: 'accessing'!
day
	^day!
dayOfYear
	^day!
year
	^year!
monthIndex
	12 to: 1 by: -1 do: [:m | (Date firstDayOfMonth: m forYear: year) <= day ifTrue: [^m]].
	^1!
monthName
	^Date nameOfMonth: self monthIndex!
month
	^self monthIndex!
dayOfMonth
	^day - (Date firstDayOfMonth: self monthIndex forYear: year) + 1!
dayOfWeek
	"1 = Monday ... 7 = Sunday; 1 January 1901 was a Tuesday"
	^(self asDays + 1) \\ 7 + 1!
dayName
	^Date nameOfDay: self dayOfWeek!
weekday
	^self dayName!
daysInMonth
	^Date daysInMonth: self monthIndex forYear: year!
daysInYear
	^Date daysInYear: year!
daysLeftInYear
	^self daysInYear - day!
firstDayOfMonth
	^Date firstDayOfMonth: self monthIndex forYear: year!
leap
	^Date leapYear: year! !

!Date methodsFor: 'arithmetic'!
asDays
	| days |
	days := day - 1.
	year > 1901 ifTrue: [1901 to: year - 1 do: [:y | days := days + (Date daysInYear: y)]].
	year < 1901 ifTrue: [year to: 1900 do: [:y | days := days - (Date daysInYear: y)]].
	^days!
asSeconds
	^self asDays * 86400!
addDays: dayCount
	^Date fromDays: self asDays + dayCount!
subtractDays: dayCount
	^Date fromDays: self asDays - dayCount!
subtractDate: aDate
	^self asDays - aDate asDays!
previous: dayName
	| k |
	k := self dayOfWeek - (Date dayOfWeek: dayName) \\ 7.
	^self subtractDays: (k = 0 ifTrue: [7] ifFalse: [k])! !

!Date methodsFor: 'comparing'!
< aDate
	^year = aDate year ifTrue: [day < aDate day] ifFalse: [year < aDate year]!
= aDate
	^(aDate isKindOf: Date) and: [year = aDate year and: [day = aDate day]]!
hash
	^(year * 367) + day! !

!Date methodsFor: 'printing'!
printOn: aStream
	aStream print: self dayOfMonth; space; nextPutAll: self monthName; space; print: year!
storeOn: aStream
	aStream nextPut: $(; nextPutAll: 'Date readFrom: '; store: self printString; nextPut: $)!
mmddyyyy
	^self monthIndex printString, '/', self dayOfMonth printString, '/', year printString!
yyyymmdd
	^year printString, '-', (self monthIndex printPaddedWith: $0 to: 2), '-', (self dayOfMonth printPaddedWith: $0 to: 2)! !

!Time class methodsFor: 'instance creation'!
now
	^self fromSeconds: Time primSecondsClock \\ 86400!
fromSeconds: secondCount
	^self basicNew setSeconds: secondCount!
hour: h minute: m second: s
	^self fromSeconds: h * 3600 + (m * 60) + s!
readFrom: aStream
	"hh:mm:ss [am|pm]"
	| h m s |
	h := Integer readFrom: aStream. m := 0. s := 0.
	(aStream peekFor: $:) ifTrue: [m := Integer readFrom: aStream. (aStream peekFor: $:) ifTrue: [s := Integer readFrom: aStream]].
	aStream skipSeparators.
	(aStream peekFor: $p) ifTrue: [h < 12 ifTrue: [h := h + 12]].
	(aStream peekFor: $a) ifTrue: [h = 12 ifTrue: [h := 0]].
	^self hour: h minute: m second: s! !

!Time class methodsFor: 'general inquiries'!
primSecondsClock
	"local seconds since 1 January 1901"
	<primitive: 118>
	^0!
totalSeconds
	^self primSecondsClock!
dateAndTimeNow
	^Array with: Date today with: self now!
millisecondClock
	<primitive: 116>
	^0!
millisecondClockValue
	^self millisecondClock!
millisecondsToRun: aBlock
	| t |
	t := self millisecondClock.
	aBlock value.
	^self millisecondClock - t! !

!Time methodsFor: 'private'!
setSeconds: secondCount
	seconds := secondCount \\ 86400! !

!Time methodsFor: 'accessing'!
hours
	^seconds // 3600!
minutes
	^seconds \\ 3600 // 60!
seconds
	^seconds \\ 60!
asSeconds
	^seconds! !

!Time methodsFor: 'arithmetic'!
addTime: aTime
	^Time fromSeconds: seconds + aTime asSeconds!
subtractTime: aTime
	^Time fromSeconds: seconds - aTime asSeconds!
addSeconds: n
	^Time fromSeconds: seconds + n! !

!Time methodsFor: 'comparing'!
< aTime
	^seconds < aTime asSeconds!
= aTime
	^(aTime isKindOf: Time) and: [seconds = aTime asSeconds]!
hash
	^seconds! !

!Time methodsFor: 'printing'!
printOn: aStream
	| h |
	h := self hours \\ 12. h = 0 ifTrue: [h := 12].
	aStream print: h; nextPut: $:; nextPutAll: (self minutes printPaddedWith: $0 to: 2); nextPut: $:; nextPutAll: (self seconds printPaddedWith: $0 to: 2);
		nextPutAll: (self hours < 12 ifTrue: [' am'] ifFalse: [' pm'])!
print24
	^(self hours printPaddedWith: $0 to: 2), ':', (self minutes printPaddedWith: $0 to: 2), ':', (self seconds printPaddedWith: $0 to: 2)!
storeOn: aStream
	aStream nextPut: $(; nextPutAll: 'Time readFrom: '; store: self printString; nextPut: $)! !

!Point methodsFor: 'converting'!
corner: aPoint
	^Rectangle origin: self corner: aPoint!
extent: aPoint
	^Rectangle origin: self extent: aPoint!
truncated
	^x truncated @ y truncated!
rounded
	^x rounded @ y rounded!
asPoint
	^self! !

!Point methodsFor: 'point functions'!
// aNumber
	^(x // aNumber) @ (y // aNumber)!
max: aPoint
	^(x max: aPoint x) @ (y max: aPoint y)!
min: aPoint
	^(x min: aPoint x) @ (y min: aPoint y)!
<= aPoint
	^x <= aPoint x and: [y <= aPoint y]!
> aPoint
	^x > aPoint x and: [y > aPoint y]!
>= aPoint
	^x >= aPoint x and: [y >= aPoint y]!
dotProduct: aPoint
	^(x * aPoint x) + (y * aPoint y)!
grid: aPoint
	^((x / aPoint x) rounded * aPoint x) @ ((y / aPoint y) rounded * aPoint y)!
r
	^(x squared + y squared) sqrt!
negated
	^x negated @ y negated!
storeOn: aStream
	aStream nextPut: $(; store: x; nextPutAll: ' @ '; store: y; nextPut: $)! !

!Number methodsFor: 'converting'!
asPoint
	^self @ self! !

!Rectangle class methodsFor: 'instance creation'!
origin: originPoint corner: cornerPoint
	^self basicNew setOrigin: originPoint corner: cornerPoint!
origin: originPoint extent: extentPoint
	^self basicNew setOrigin: originPoint corner: originPoint + extentPoint!
left: l right: r top: t bottom: b
	^self basicNew setOrigin: l @ t corner: r @ b! !

!Rectangle methodsFor: 'private'!
setOrigin: originPoint corner: cornerPoint
	origin := originPoint. corner := cornerPoint! !

!Rectangle methodsFor: 'accessing'!
origin
	^origin!
corner
	^corner!
origin: aPoint
	origin := aPoint!
corner: aPoint
	corner := aPoint!
origin: o corner: c
	origin := o. corner := c!
extent
	^corner - origin!
width
	^corner x - origin x!
height
	^corner y - origin y!
left
	^origin x!
right
	^corner x!
top
	^origin y!
bottom
	^corner y!
topLeft
	^origin!
topRight
	^corner x @ origin y!
bottomLeft
	^origin x @ corner y!
bottomRight
	^corner!
center
	^(origin + corner) // 2!
area
	^self width * self height! !

!Rectangle methodsFor: 'testing'!
containsPoint: aPoint
	^origin <= aPoint and: [aPoint < corner]!
contains: aRectangle
	^(self containsPoint: aRectangle origin) and: [aRectangle corner <= corner]!
intersects: aRectangle
	^(origin max: aRectangle origin) < (corner min: aRectangle corner)! !

!Rectangle methodsFor: 'rectangle functions'!
intersect: aRectangle
	^Rectangle origin: (origin max: aRectangle origin) corner: (corner min: aRectangle corner)!
merge: aRectangle
	^Rectangle origin: (origin min: aRectangle origin) corner: (corner max: aRectangle corner)!
translateBy: delta
	^Rectangle origin: origin + delta corner: corner + delta!
moveTo: aPoint
	^Rectangle origin: aPoint extent: self extent!
scaleBy: scale
	^Rectangle origin: origin * scale corner: corner * scale!
expandBy: delta
	^Rectangle origin: origin - delta corner: corner + delta!
insetBy: delta
	^Rectangle origin: origin + delta corner: corner - delta!
areasOutside: aRectangle
	| areas |
	(self intersects: aRectangle) ifFalse: [^Array with: self].
	areas := OrderedCollection new.
	aRectangle top > self top ifTrue: [areas add: (Rectangle left: self left right: self right top: self top bottom: aRectangle top)].
	aRectangle bottom < self bottom ifTrue: [areas add: (Rectangle left: self left right: self right top: aRectangle bottom bottom: self bottom)].
	aRectangle left > self left ifTrue: [areas add: (Rectangle left: self left right: aRectangle left top: (self top max: aRectangle top) bottom: (self bottom min: aRectangle bottom))].
	aRectangle right < self right ifTrue: [areas add: (Rectangle left: aRectangle right right: self right top: (self top max: aRectangle top) bottom: (self bottom min: aRectangle bottom))].
	^areas! !

!Rectangle methodsFor: 'comparing'!
= aRectangle
	^(aRectangle isKindOf: Rectangle) and: [origin = aRectangle origin and: [corner = aRectangle corner]]!
hash
	^origin hash bitXor: corner hash! !

!Rectangle methodsFor: 'printing'!
printOn: aStream
	aStream print: origin; nextPutAll: ' corner: '; print: corner!
storeOn: aStream
	aStream nextPut: $(; store: origin; nextPutAll: ' corner: '; store: corner; nextPut: $)! !

Date initialize!
