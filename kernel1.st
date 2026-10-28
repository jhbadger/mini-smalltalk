"Mini Smalltalk-80 kernel, part 1: classes, Object, Boolean, UndefinedObject, Magnitude, Number, Character"

!Class methodsFor: 'class creation'!
subclass: n instanceVariableNames: i classVariableNames: c category: cat
	^self subclass: n instanceVariableNames: i classVariableNames: c category: cat kind: 0!
variableSubclass: n instanceVariableNames: i classVariableNames: c category: cat
	^self subclass: n instanceVariableNames: i classVariableNames: c category: cat kind: 1!
variableByteSubclass: n instanceVariableNames: i classVariableNames: c category: cat
	^self subclass: n instanceVariableNames: i classVariableNames: c category: cat kind: 2!
subclass: n instanceVariableNames: i classVariableNames: c category: cat kind: k
	<primitive: 100>
	^self error: 'cannot define class'! !

!UndefinedObject methodsFor: 'class creation'!
subclass: n instanceVariableNames: i classVariableNames: c category: cat
	^self subclass: n instanceVariableNames: i classVariableNames: c category: cat kind: 0!
subclass: n instanceVariableNames: i classVariableNames: c category: cat kind: k
	<primitive: 100>
	^self error: 'cannot define class'! !

Object subclass: #Behavior instanceVariableNames: 'superclass methodDict format' classVariableNames: '' category: 'Kernel-Classes'!
Behavior subclass: #ClassDescription instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Classes'!
ClassDescription subclass: #Class instanceVariableNames: 'name instanceVariables classPool category comment' classVariableNames: '' category: 'Kernel-Classes'!
ClassDescription subclass: #Metaclass instanceVariableNames: 'thisClass' classVariableNames: '' category: 'Kernel-Classes'!
Object subclass: #UndefinedObject instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Objects'!
Object subclass: #Boolean instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Objects'!
Boolean subclass: #True instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Objects'!
Boolean subclass: #False instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Objects'!
Object subclass: #Message instanceVariableNames: 'selector arguments' classVariableNames: '' category: 'Kernel-Methods'!
Object subclass: #Magnitude instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Magnitudes'!
Magnitude subclass: #Number instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Numbers'!
Number subclass: #Integer instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Numbers'!
Integer subclass: #SmallInteger instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Numbers'!
Number variableByteSubclass: #Float instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Numbers'!
Magnitude subclass: #Character instanceVariableNames: 'value' classVariableNames: '' category: 'Kernel-Magnitudes'!
Magnitude subclass: #LookupKey instanceVariableNames: 'key' classVariableNames: '' category: 'Kernel-Objects'!
LookupKey subclass: #Association instanceVariableNames: 'value' classVariableNames: '' category: 'Kernel-Objects'!
Object subclass: #Point instanceVariableNames: 'x y' classVariableNames: '' category: 'Graphics-Primitives'!
Object subclass: #Time instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Magnitudes'!

!Object methodsFor: 'accessing'!
class
	<primitive: 2>
	^self error: 'cannot determine class'!
yourself
	^self!
size
	^self basicSize!
basicSize
	<primitive: 3>
	^0!
at: index
	^self basicAt: index!
at: index put: value
	^self basicAt: index put: value!
basicAt: index
	<primitive: 4>
	index isInteger ifFalse: [^self error: 'index must be an integer'].
	^self errorSubscriptBounds: index!
basicAt: index put: value
	<primitive: 5>
	index isInteger ifFalse: [^self error: 'index must be an integer'].
	(index between: 1 and: self basicSize) ifFalse: [^self errorSubscriptBounds: index].
	^self error: 'improper store into indexable object'!
instVarAt: index
	<primitive: 9>
	^self errorSubscriptBounds: index!
instVarAt: index put: value
	<primitive: 10>
	^self errorSubscriptBounds: index!
species
	^self class! !

!Object methodsFor: 'comparing'!
== anObject
	<primitive: 1>
	^false!
= anObject
	^self == anObject!
~= anObject
	^(self = anObject) not!
~~ anObject
	^(self == anObject) not!
hash
	<primitive: 8>
	^0!
identityHash
	<primitive: 8>
	^0! !

!Object methodsFor: 'testing'!
isNil
	^false!
notNil
	^true!
ifNil: aBlock
	^self!
ifNotNil: aBlock
	^aBlock value: self!
ifNil: nilBlock ifNotNil: aBlock
	^aBlock value: self!
isString
	^false!
isSymbol
	^false!
isNumber
	^false!
isInteger
	^false!
isFloat
	^false!
isCharacter
	^false!
isClass
	^false!
isBlock
	^false!
isArray
	^false!
isKindOf: aClass
	^self class == aClass or: [self class inheritsFrom: aClass]!
isMemberOf: aClass
	^self class == aClass!
respondsTo: aSymbol
	<primitive: 15>
	^false! !

!Object methodsFor: 'copying'!
copy
	^self shallowCopy postCopy!
shallowCopy
	<primitive: 12>
	^self!
postCopy
	^self!
deepCopy
	^self copy! !

!Object methodsFor: 'printing'!
printString
	| s |
	s := WriteStream on: (String new: 32).
	self printOn: s.
	^s contents!
printOn: aStream
	| n |
	n := self class name.
	aStream nextPutAll: (n first isVowel ifTrue: ['an '] ifFalse: ['a ']); nextPutAll: n!
displayString
	^self printString!
displayNl
	Transcript show: self displayString; cr!
printNl
	Transcript show: self printString; cr!
storeString
	^self printString! !

!Object methodsFor: 'message handling'!
perform: aSymbol
	<primitive: 82>
	^self error: 'bad selector'!
perform: aSymbol with: a
	<primitive: 82>
	^self error: 'bad selector'!
perform: aSymbol with: a with: b
	<primitive: 82>
	^self error: 'bad selector'!
perform: aSymbol with: a with: b with: c
	<primitive: 82>
	^self error: 'bad selector'!
perform: aSymbol withArguments: anArray
	<primitive: 83>
	^self error: 'bad selector or arguments'!
-> anObject
	^Association key: self value: anObject! !

!Object methodsFor: 'error handling'!
error: aString
	<primitive: 11>
	^nil!
doesNotUnderstand: aMessage
	^self error: 'does not understand #', aMessage selector!
halt
	^self error: 'halt'!
subclassResponsibility
	^self error: 'This method is a subclass responsibility'!
shouldNotImplement
	^self error: 'This message is not appropriate for this object'!
errorSubscriptBounds: index
	^self error: 'subscript out of bounds: ', index printString!
assert: aBlock
	aBlock value ifFalse: [self error: 'assertion failed']!
inspect
	<primitive: 119>
	^self! !

!Boolean methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: (self ifTrue: ['true'] ifFalse: ['false'])! !

!Boolean methodsFor: 'copying'!
shallowCopy
	^self! !

!True methodsFor: 'logic'!
& aBoolean
	^aBoolean!
| aBoolean
	^true!
and: aBlock
	^aBlock value!
or: aBlock
	^true!
not
	^false!
xor: aBoolean
	^aBoolean not!
eqv: aBoolean
	^aBoolean! !

!True methodsFor: 'controlling'!
ifTrue: aBlock
	^aBlock value!
ifFalse: aBlock
	^nil!
ifTrue: trueBlock ifFalse: falseBlock
	^trueBlock value!
ifFalse: falseBlock ifTrue: trueBlock
	^trueBlock value! !

!False methodsFor: 'logic'!
& aBoolean
	^false!
| aBoolean
	^aBoolean!
and: aBlock
	^false!
or: aBlock
	^aBlock value!
not
	^true!
xor: aBoolean
	^aBoolean!
eqv: aBoolean
	^aBoolean not! !

!False methodsFor: 'controlling'!
ifTrue: aBlock
	^nil!
ifFalse: aBlock
	^aBlock value!
ifTrue: trueBlock ifFalse: falseBlock
	^falseBlock value!
ifFalse: falseBlock ifTrue: trueBlock
	^falseBlock value! !

!UndefinedObject methodsFor: 'testing'!
isNil
	^true!
notNil
	^false!
ifNil: aBlock
	^aBlock value!
ifNotNil: aBlock
	^nil!
ifNil: nilBlock ifNotNil: aBlock
	^nilBlock value! !

!UndefinedObject methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'nil'! !

!UndefinedObject methodsFor: 'copying'!
shallowCopy
	^self! !

!Message methodsFor: 'accessing'!
selector
	^selector!
arguments
	^arguments!
selector: aSymbol arguments: anArray
	selector := aSymbol. arguments := anArray! !

!Message methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a Message '; print: selector! !

!Message class methodsFor: 'instance creation'!
selector: aSymbol arguments: anArray
	^self new selector: aSymbol arguments: anArray! !

!Behavior methodsFor: 'instance creation'!
new
	<primitive: 6>
	^self basicNew: 0!
basicNew
	<primitive: 6>
	^self basicNew: 0!
new: anInteger
	<primitive: 7>
	^self error: 'cannot create indexable instance'!
basicNew: anInteger
	<primitive: 7>
	^self error: 'cannot create indexable instance'! !

!Behavior methodsFor: 'accessing'!
superclass
	^superclass!
methodDictionary
	^methodDict!
name
	^'a Behavior'!
selectors
	<primitive: 103>
	^#()!
compiledMethodAt: aSymbol
	<primitive: 104>
	^self error: 'selector not found: ', aSymbol!
>> aSymbol
	^self compiledMethodAt: aSymbol!
sourceCodeAt: aSymbol
	^(self compiledMethodAt: aSymbol) sourceCode!
allInstVarNames
	<primitive: 105>
	^#()!
instSize
	^self allInstVarNames size!
isVariable
	^self formatKind > 0!
isBytes
	^self formatKind = 2!
formatKind
	<primitive: 106>
	^0!
category
	^'Unclassified'!
comment
	^''!
theNonMetaClass
	^self!
isMeta
	^false! !

!Behavior methodsFor: 'testing'!
isClass
	^true!
inheritsFrom: aClass
	| c |
	c := superclass.
	[c isNil] whileFalse: [c == aClass ifTrue: [^true]. c := c superclass].
	^false!
includesSelector: aSymbol
	<primitive: 16>
	^false!
canUnderstand: aSymbol
	^(self lookupSelector: aSymbol) notNil!
lookupSelector: aSymbol
	| c |
	c := self.
	[c isNil] whileFalse: [(c includesSelector: aSymbol) ifTrue: [^c compiledMethodAt: aSymbol]. c := c superclass].
	^nil!
whichClassIncludesSelector: aSymbol
	| c |
	c := self.
	[c isNil] whileFalse: [(c includesSelector: aSymbol) ifTrue: [^c]. c := c superclass].
	^nil! !

!Behavior methodsFor: 'compiling'!
compile: aString
	^self compile: aString classified: 'as yet unclassified'!
compile: aString classified: aCategory
	<primitive: 101>
	^self error: 'compilation failed'!
removeSelector: aSymbol
	<primitive: 102>
	^self error: 'selector not found'! !

!Behavior methodsFor: 'enumerating'!
subclasses
	^Smalltalk allClasses select: [:c | c superclass == self]!
allSubclasses
	| all |
	all := OrderedCollection new.
	self subclasses do: [:c | all add: c. all addAll: c allSubclasses].
	^all!
allSuperclasses
	| all c |
	all := OrderedCollection new. c := superclass.
	[c isNil] whileFalse: [all add: c. c := c superclass].
	^all!
withAllSuperclasses
	^(OrderedCollection with: self) addAll: self allSuperclasses; yourself!
withAllSubclasses
	^(OrderedCollection with: self) addAll: self allSubclasses; yourself! !

!Behavior methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: self name! !

!Class methodsFor: 'accessing'!
name
	^name!
category
	^category!
category: aString
	category := aString!
comment
	^comment!
comment: aString
	comment := aString!
instanceVariableNames
	^instanceVariables!
classPool
	^classPool!
classVarNames
	^classPool keys!
addClassVarName: aString
	classPool at: aString asSymbol put: nil!
classVariableAt: aSymbol
	^classPool at: aSymbol!
classVariableAt: aSymbol put: anObject
	^classPool at: aSymbol put: anObject! !

!Class methodsFor: 'fileIn/Out'!
definition
	| s |
	s := WriteStream on: String new.
	s nextPutAll: (superclass isNil ifTrue: ['nil'] ifFalse: [superclass name]).
	s nextPutAll: (self isBytes & (superclass notNil and: [superclass isBytes not])
		ifTrue: [' variableByteSubclass: #']
		ifFalse: [(self isVariable & (superclass notNil and: [superclass isVariable not])) ifTrue: [' variableSubclass: #'] ifFalse: [' subclass: #']]).
	s nextPutAll: name; nextPutAll: '
	instanceVariableNames: '''.
	instanceVariables do: [:v | s nextPutAll: v] separatedBy: [s space].
	s nextPutAll: '''
	classVariableNames: '''.
	classPool keys asSortedCollection do: [:v | s nextPutAll: v] separatedBy: [s space].
	s nextPutAll: '''
	category: '''; nextPutAll: category; nextPutAll: ''''.
	^s contents!
fileOutString
	^self fileOutStringOf: self!
fileOutStringOf: aClass
	<primitive: 115>
	^''!
removeFromSystem
	Smalltalk removeKey: name! !

!Metaclass methodsFor: 'accessing'!
name
	^thisClass name, ' class'!
soleInstance
	^thisClass!
thisClass
	^thisClass!
theNonMetaClass
	^thisClass!
isMeta
	^true!
category
	^thisClass category! !

!Magnitude methodsFor: 'comparing'!
< aMagnitude
	^self subclassResponsibility!
> aMagnitude
	^aMagnitude < self!
<= aMagnitude
	^(aMagnitude < self) not!
>= aMagnitude
	^(self < aMagnitude) not!
between: min and: max
	^self >= min and: [self <= max]!
min: aMagnitude
	^self < aMagnitude ifTrue: [self] ifFalse: [aMagnitude]!
max: aMagnitude
	^self > aMagnitude ifTrue: [self] ifFalse: [aMagnitude]! !

!Number methodsFor: 'arithmetic'!
+ aNumber
	^self subclassResponsibility!
- aNumber
	^self subclassResponsibility!
* aNumber
	^self subclassResponsibility!
/ aNumber
	^self subclassResponsibility!
// aNumber
	^(self / aNumber) floor!
\\ aNumber
	^self - (self // aNumber * aNumber)!
rem: aNumber
	^self - ((self quo: aNumber) * aNumber)!
quo: aNumber
	^(self / aNumber) truncated!
abs
	^self < 0 ifTrue: [self negated] ifFalse: [self]!
negated
	^0 - self!
reciprocal
	^1 / self!
squared
	^self * self!
sign
	self > 0 ifTrue: [^1]. self < 0 ifTrue: [^-1]. ^0!
raisedTo: aNumber
	<primitive: 57>
	^self error: 'bad exponent'!
** aNumber
	^self raisedTo: aNumber!
sqrt
	<primitive: 51>
	^self error: 'sqrt failed'!
ln
	<primitive: 52>
	^self error: 'ln failed'!
exp
	<primitive: 53>
	^self error: 'exp failed'!
sin
	<primitive: 54>
	^self error: 'sin failed'!
cos
	<primitive: 55>
	^self error: 'cos failed'!
arcTan
	<primitive: 56>
	^self error: 'arcTan failed'!
log: base
	^self ln / base ln!
roundTo: aNumber
	^(self / aNumber) rounded * aNumber!
truncateTo: aNumber
	^(self quo: aNumber) * aNumber! !

!Number methodsFor: 'testing'!
isNumber
	^true!
isZero
	^self = 0!
negative
	^self < 0!
positive
	^self >= 0!
strictlyPositive
	^self > 0!
even
	^self \\ 2 = 0!
odd
	^self even not! !

!Number methodsFor: 'converting'!
truncated
	<primitive: 49>
	^self error: 'cannot truncate'!
asInteger
	^self truncated!
rounded
	^(self + (self sign / 2)) truncated!
floor
	| t |
	t := self truncated.
	^self < t ifTrue: [t - 1] ifFalse: [t]!
ceiling
	| t |
	t := self truncated.
	^self > t ifTrue: [t + 1] ifFalse: [t]!
asFloat
	^self subclassResponsibility!
asString
	^self printString!
@ aNumber
	^Point x: self y: aNumber!
to: stop
	^Interval from: self to: stop by: 1!
to: stop by: step
	^Interval from: self to: stop by: step! !

!Number methodsFor: 'enumerating'!
to: stop do: aBlock
	| i |
	i := self.
	[i <= stop] whileTrue: [aBlock value: i. i := i + 1]!
to: stop by: step do: aBlock
	| i |
	i := self.
	step > 0
		ifTrue: [[i <= stop] whileTrue: [aBlock value: i. i := i + step]]
		ifFalse: [[i >= stop] whileTrue: [aBlock value: i. i := i + step]]! !

!Number methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: (self printString: 10)!
printString: base
	^self subclassResponsibility! !

!Integer methodsFor: 'arithmetic'!
+ aNumber
	<primitive: 20>
	^self asFloat + aNumber asFloat!
- aNumber
	<primitive: 21>
	^self asFloat - aNumber asFloat!
* aNumber
	<primitive: 22>
	^self asFloat * aNumber asFloat!
/ aNumber
	<primitive: 25>
	aNumber = 0 ifTrue: [^self error: 'division by zero'].
	^self asFloat / aNumber asFloat!
// aNumber
	<primitive: 23>
	aNumber = 0 ifTrue: [^self error: 'division by zero'].
	^(self asFloat / aNumber asFloat) floor!
\\ aNumber
	<primitive: 24>
	aNumber = 0 ifTrue: [^self error: 'division by zero'].
	^self asFloat \\ aNumber asFloat!
quo: aNumber
	<primitive: 38>
	aNumber = 0 ifTrue: [^self error: 'division by zero'].
	^(self asFloat / aNumber asFloat) truncated!
rem: aNumber
	<primitive: 39>
	aNumber = 0 ifTrue: [^self error: 'division by zero'].
	^self asFloat rem: aNumber asFloat!
gcd: anInteger
	| a b t |
	a := self abs. b := anInteger abs.
	[b = 0] whileFalse: [t := a \\ b. a := b. b := t].
	^a!
lcm: anInteger
	^(self * anInteger) abs // (self gcd: anInteger)!
factorial
	self < 0 ifTrue: [^self error: 'factorial of negative number'].
	^self <= 1 ifTrue: [1] ifFalse: [self * (self - 1) factorial]!
raisedTo: aNumber
	| r |
	(aNumber isInteger and: [aNumber >= 0]) ifFalse: [^self asFloat raisedTo: aNumber].
	r := 1.
	aNumber timesRepeat: [r := r * self].
	^r!
isPrime
	| i |
	self < 2 ifTrue: [^false].
	i := 2.
	[i * i <= self] whileTrue: [self \\ i = 0 ifTrue: [^false]. i := i + 1].
	^true! !

!Integer methodsFor: 'comparing'!
< aNumber
	<primitive: 26>
	^self asFloat < aNumber!
> aNumber
	<primitive: 27>
	^self asFloat > aNumber!
<= aNumber
	<primitive: 28>
	^self asFloat <= aNumber!
>= aNumber
	<primitive: 29>
	^self asFloat >= aNumber!
= aNumber
	<primitive: 30>
	^aNumber isNumber and: [self asFloat = aNumber]!
~= aNumber
	<primitive: 31>
	^(self = aNumber) not!
hash
	^self! !

!Integer methodsFor: 'bit manipulation'!
bitAnd: anInteger
	<primitive: 32>
	^self error: 'bad argument'!
bitOr: anInteger
	<primitive: 33>
	^self error: 'bad argument'!
bitXor: anInteger
	<primitive: 34>
	^self error: 'bad argument'!
bitShift: anInteger
	<primitive: 35>
	^self error: 'shift overflow'!
<< anInteger
	^self bitShift: anInteger!
>> anInteger
	^self bitShift: anInteger negated!
bitAt: index
	^(self bitShift: 1 - index) bitAnd: 1!
bitInvert
	^-1 - self! !

!Integer methodsFor: 'converting'!
asFloat
	<primitive: 36>
	^self error: 'cannot convert'!
asInteger
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
	^Character value: self! !

!Integer methodsFor: 'testing'!
isInteger
	^true! !

!Integer methodsFor: 'enumerating'!
timesRepeat: aBlock
	| i |
	i := 1.
	[i <= self] whileTrue: [aBlock value. i := i + 1]! !

!Integer methodsFor: 'printing'!
printString: base
	<primitive: 37>
	^self error: 'bad radix'!
printOn: aStream base: base
	aStream nextPutAll: (self printString: base)!
radix: base
	^self printString: base!
printPaddedWith: aCharacter to: width
	| s |
	s := self printString.
	[s size < width] whileTrue: [s := (String with: aCharacter), s].
	^s! !

!Float methodsFor: 'arithmetic'!
+ aNumber
	<primitive: 40>
	^self error: 'argument must be a number'!
- aNumber
	<primitive: 41>
	^self error: 'argument must be a number'!
* aNumber
	<primitive: 42>
	^self error: 'argument must be a number'!
/ aNumber
	<primitive: 43>
	aNumber = 0 ifTrue: [^self error: 'division by zero'].
	^self error: 'argument must be a number'!
fractionPart
	<primitive: 58>
	^self error: 'failed'!
integerPart
	^self - self fractionPart! !

!Float methodsFor: 'comparing'!
< aNumber
	<primitive: 44>
	^self error: 'argument must be a number'!
> aNumber
	<primitive: 45>
	^self error: 'argument must be a number'!
<= aNumber
	<primitive: 46>
	^self error: 'argument must be a number'!
>= aNumber
	<primitive: 47>
	^self error: 'argument must be a number'!
= aNumber
	<primitive: 48>
	^false!
hash
	<primitive: 64>
	^0! !

!Float methodsFor: 'converting'!
asFloat
	^self!
isFloat
	^true! !

!Float methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: self printString!
printString
	<primitive: 50>
	^'aFloat'!
printString: base
	^self printString! !

!Float class methodsFor: 'constants'!
pi
	^3.141592653589793!
e
	^2.718281828459045!
infinity
	^1.0e308 * 10! !

!Character class methodsFor: 'instance creation'!
value: anInteger
	<primitive: 70>
	^self error: 'character value out of range'!
cr
	^self value: 10!
lf
	^self value: 10!
tab
	^self value: 9!
space
	^self value: 32!
esc
	^self value: 27!
nl
	^self value: 10! !

!Character methodsFor: 'accessing'!
value
	^value!
asInteger
	^value!
asciiValue
	^value!
digitValue
	(value between: 48 and: 57) ifTrue: [^value - 48].
	(value between: 65 and: 90) ifTrue: [^value - 55].
	(value between: 97 and: 122) ifTrue: [^value - 87].
	^-1! !

!Character methodsFor: 'comparing'!
< aCharacter
	^value < aCharacter asInteger!
= aCharacter
	^self == aCharacter!
hash
	^value! !

!Character methodsFor: 'testing'!
isCharacter
	^true!
isVowel
	^'aeiouAEIOU' includes: self!
isLetter
	^(value between: 65 and: 90) or: [value between: 97 and: 122]!
isDigit
	^value between: 48 and: 57!
isUppercase
	^value between: 65 and: 90!
isLowercase
	^value between: 97 and: 122!
isSeparator
	^value = 32 or: [value = 9 or: [value = 10 or: [value = 13]]]!
isAlphaNumeric
	^self isLetter or: [self isDigit]! !

!Character methodsFor: 'converting'!
asUppercase
	^self isLowercase ifTrue: [Character value: value - 32] ifFalse: [self]!
asLowercase
	^self isUppercase ifTrue: [Character value: value + 32] ifFalse: [self]!
asCharacter
	^self!
asString
	^String with: self!
asSymbol
	^self asString asSymbol!
to: aCharacter
	^(value to: aCharacter asInteger) collect: [:i | Character value: i]! !

!Character methodsFor: 'printing'!
printOn: aStream
	aStream nextPut: $$; nextPut: self!
displayString
	^self asString! !

!Character methodsFor: 'copying'!
shallowCopy
	^self! !

!LookupKey class methodsFor: 'instance creation'!
key: aKey
	^self new key: aKey! !

!LookupKey methodsFor: 'accessing'!
key
	^key!
key: aKey
	key := aKey! !

!LookupKey methodsFor: 'comparing'!
< aLookupKey
	^key < aLookupKey key!
= aLookupKey
	^(aLookupKey isKindOf: LookupKey) and: [key = aLookupKey key]!
hash
	^key hash! !

!LookupKey methodsFor: 'printing'!
printOn: aStream
	aStream print: key! !

!Association class methodsFor: 'instance creation'!
key: aKey value: aValue
	^self new key: aKey value: aValue! !

!Association methodsFor: 'accessing'!
value
	^value!
value: aValue
	value := aValue!
key: aKey value: aValue
	key := aKey. value := aValue! !

!Association methodsFor: 'comparing'!
= anAssociation
	^(anAssociation isKindOf: Association) and: [key = anAssociation key and: [value = anAssociation value]]! !

!Association methodsFor: 'printing'!
printOn: aStream
	aStream print: key; nextPutAll: '->'; print: value!
storeOn: aStream
	aStream nextPut: $(; store: key; nextPutAll: '->'; store: value; nextPut: $)! !

!Point class methodsFor: 'instance creation'!
x: xNumber y: yNumber
	^self new setX: xNumber y: yNumber! !

!Point methodsFor: 'accessing'!
x
	^x!
y
	^y!
x: aNumber
	x := aNumber!
y: aNumber
	y := aNumber!
setX: xNumber y: yNumber
	x := xNumber. y := yNumber! !

!Point methodsFor: 'arithmetic'!
+ aPoint
	^(x + aPoint x) @ (y + aPoint y)!
- aPoint
	^(x - aPoint x) @ (y - aPoint y)!
* aNumber
	^(x * aNumber) @ (y * aNumber)!
/ aNumber
	^(x / aNumber) @ (y / aNumber)!
abs
	^x abs @ y abs!
dist: aPoint
	^((x - aPoint x) squared + (y - aPoint y) squared) sqrt!
transpose
	^y @ x! !

!Point methodsFor: 'comparing'!
= aPoint
	^(aPoint isKindOf: Point) and: [x = aPoint x and: [y = aPoint y]]!
< aPoint
	^x < aPoint x and: [y < aPoint y]!
hash
	^(x hash bitShift: 2) bitXor: y hash! !

!Point methodsFor: 'printing'!
printOn: aStream
	aStream print: x; nextPut: $@; print: y! !

!Time class methodsFor: 'general inquiries'!
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
