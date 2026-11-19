"Mini Smalltalk-80 kernel, part 7: everyday gaps - testing protocol, collections, sets, dictionaries, Point and Rectangle, blocks, symbols, classes, random numbers, streams"

"---- Object ----"

!Object methodsFor: 'testing'!
isBoolean
	^false!
isCollection
	^false!
isDictionary
	^false!
isSequenceable
	^false!
isSet
	^false!
isPoint
	^false!
isRectangle
	^false!
isInterval
	^false!
isText
	^false!
isFraction
	^false!
isRational
	^false!
isBehavior
	^false!
isMetaclass
	^false!
isAssociation
	^false! !

!Object methodsFor: 'converting'!
asString
	^self displayString!
in: aBlock
	"evaluate aBlock with the receiver as its argument"
	^aBlock value: self! !

!Object methodsFor: 'nil handling'!
ifNotNil: notNilBlock ifNil: nilBlock
	^notNilBlock numArgs = 0 ifTrue: [notNilBlock value] ifFalse: [notNilBlock value: self]! !

!UndefinedObject methodsFor: 'nil handling'!
ifNotNil: notNilBlock ifNil: nilBlock
	^nilBlock value!
isEmptyOrNil
	^true! !

!Object methodsFor: 'error handling'!
halt: aString
	^self error: 'halt: ', aString!
assert: aBlock description: aString
	aBlock value ifFalse: [self error: aString]! !

!Object methodsFor: 'printing'!
printStringLimitedTo: limit
	| s |
	s := self printString.
	^s size > limit ifTrue: [(s copyFrom: 1 to: limit), '...'] ifFalse: [s]!
displayStringLimitedTo: limit
	| s |
	s := self displayString.
	^s size > limit ifTrue: [(s copyFrom: 1 to: limit), '...'] ifFalse: [s]! !

!Boolean methodsFor: 'testing'!
isBoolean
	^true! !

"---- Collection ----"

!Collection class methodsFor: 'instance creation'!
newFrom: aCollection
	^self withAll: aCollection!
empty
	^self new! !

!Collection methodsFor: 'testing'!
isNotEmpty
	^self notEmpty!
ifEmpty: aBlock
	^self isEmpty ifTrue: [aBlock value] ifFalse: [self]!
ifNotEmpty: aBlock
	^self isEmpty ifTrue: [self] ifFalse: [aBlock numArgs = 0 ifTrue: [aBlock value] ifFalse: [aBlock value: self]]!
ifEmpty: emptyBlock ifNotEmpty: notEmptyBlock
	^self isEmpty ifTrue: [emptyBlock value] ifFalse: [notEmptyBlock numArgs = 0 ifTrue: [notEmptyBlock value] ifFalse: [notEmptyBlock value: self]]!
ifNotEmpty: notEmptyBlock ifEmpty: emptyBlock
	^self ifEmpty: emptyBlock ifNotEmpty: notEmptyBlock!
noneSatisfy: aBlock
	^(self anySatisfy: aBlock) not!
contains: aBlock
	^self anySatisfy: aBlock!
includesAllOf: aCollection
	aCollection do: [:e | (self includes: e) ifFalse: [^false]].
	^true!
includesAnyOf: aCollection
	aCollection do: [:e | (self includes: e) ifTrue: [^true]].
	^false!
identityIncludes: anObject
	self do: [:e | e == anObject ifTrue: [^true]].
	^false! !

!Collection methodsFor: 'enumerating'!
detect: aBlock ifFound: foundBlock
	^self detect: aBlock ifFound: foundBlock ifNone: [nil]!
detect: aBlock ifFound: foundBlock ifNone: noneBlock
	self do: [:e | (aBlock value: e) ifTrue: [^foundBlock value: e]].
	^noneBlock value!
collect: collectBlock thenSelect: selectBlock
	^(self collect: collectBlock) select: selectBlock!
select: selectBlock thenCollect: collectBlock
	^(self select: selectBlock) collect: collectBlock!
sum: aBlock
	"the sum of aBlock evaluated for each element"
	| s |
	s := 0.
	self do: [:e | s := s + (aBlock value: e)].
	^s!
average
	^self sum / self size!
fold: aBlock
	"combine the elements pairwise with aBlock; an error if there are none"
	| result first |
	first := true.
	self do: [:e | first ifTrue: [result := e. first := false] ifFalse: [result := aBlock value: result value: e]].
	first ifTrue: [^self error: 'cannot fold an empty collection'].
	^result!
gather: aBlock
	"the concatenation of the collections aBlock answers for each element"
	| r |
	r := OrderedCollection new.
	self do: [:e | r addAll: (aBlock value: e)].
	^r asArray!
flatCollect: aBlock
	^self gather: aBlock!
groupBy: aBlock
	"a Dictionary from the values of aBlock to the OrderedCollection of elements that gave them"
	| d |
	d := Dictionary new.
	self do: [:e | (d at: (aBlock value: e) ifAbsentPut: [OrderedCollection new]) add: e].
	^d!
groupedBy: aBlock
	^self groupBy: aBlock! !

!Collection methodsFor: 'sorting'!
sorted
	^self asSortedCollection asArray!
sorted: aBlock
	^(self asSortedCollection: aBlock) asArray! !

!Collection methodsFor: 'copying'!
copyEmpty
	^self species new!
copyWith: anObject
	^self copy add: anObject; yourself!
copyWithout: anObject
	^self reject: [:e | e = anObject]! !

!Collection methodsFor: 'removing'!
removeAll
	self copy do: [:e | self remove: e]!
removeAllSuchThat: aBlock
	(self select: aBlock) do: [:e | self remove: e]! !

!Collection methodsFor: 'converting'!
asIdentitySet
	^IdentitySet withAll: self!
asDictionary
	"from a collection of Associations"
	| d |
	d := Dictionary new.
	self do: [:a | d add: a].
	^d!
readStream
	^ReadStream on: self asArray! !

"---- SequenceableCollection ----"

!SequenceableCollection methodsFor: 'testing'!
isSequenceable
	^true!
isSorted
	^self isSortedBy: [:a :b | a <= b]!
isSortedBy: aBlock
	2 to: self size do: [:i | (aBlock value: (self at: i - 1) value: (self at: i)) ifFalse: [^false]].
	^true! !

!SequenceableCollection methodsFor: 'accessing'!
at: index ifAbsent: aBlock
	^(index isInteger and: [index between: 1 and: self size]) ifTrue: [self at: index] ifFalse: [aBlock value]!
atAll: indices
	| r idx |
	idx := indices asArray.
	r := self species new: idx size.
	1 to: idx size do: [:j | r at: j put: (self at: (idx at: j))].
	^r!
atWrap: index
	^self at: index - 1 \\ self size + 1!
fourth
	^self at: 4!
middle
	^self at: self size + 1 // 2! !

!SequenceableCollection methodsFor: 'searching'!
lastIndexOf: anObject
	^self lastIndexOf: anObject ifAbsent: [0]!
lastIndexOf: anObject ifAbsent: aBlock
	self size to: 1 by: -1 do: [:i | (self at: i) = anObject ifTrue: [^i]].
	^aBlock value!
identityIndexOf: anObject
	1 to: self size do: [:i | (self at: i) == anObject ifTrue: [^i]].
	^0!
matchesSubCollection: sub at: start
	1 to: sub size do: [:k | (self at: start + k - 1) = (sub at: k) ifFalse: [^false]].
	^true!
indexOfSubCollection: sub startingAt: start
	"the index where sub first occurs at or after start, or 0"
	| last |
	last := self size - sub size + 1.
	start to: last do: [:i | (self matchesSubCollection: sub at: i) ifTrue: [^i]].
	^0! !

!SequenceableCollection methodsFor: 'copying'!
copyFrom: start
	^self copyFrom: start to: self size!
copyAfter: anObject
	| i |
	i := self indexOf: anObject.
	^i = 0 ifTrue: [self copyFrom: 1 to: 0] ifFalse: [self copyFrom: i + 1 to: self size]!
copyAfterLast: anObject
	| i |
	i := self lastIndexOf: anObject.
	^i = 0 ifTrue: [self copyFrom: 1 to: 0] ifFalse: [self copyFrom: i + 1 to: self size]!
copyUpTo: anObject
	| i |
	i := self indexOf: anObject.
	^i = 0 ifTrue: [self copy] ifFalse: [self copyFrom: 1 to: i - 1]!
copyUpToLast: anObject
	| i |
	i := self lastIndexOf: anObject.
	^i = 0 ifTrue: [self copy] ifFalse: [self copyFrom: 1 to: i - 1]!
copyWithFirst: anObject
	^((self species new: 1) at: 1 put: anObject; yourself), self! !

!SequenceableCollection methodsFor: 'enumerating'!
from: start to: stop do: aBlock
	start to: stop do: [:i | aBlock value: (self at: i)]!
from: start to: stop keysAndValuesDo: aBlock
	start to: stop do: [:i | aBlock value: i value: (self at: i)]!
withIndexDo: aBlock
	1 to: self size do: [:i | aBlock value: (self at: i) value: i]!
collectWithIndex: aBlock
	"an Array of aBlock evaluated with each element and its index"
	| r |
	r := Array new: self size.
	1 to: self size do: [:i | r at: i put: (aBlock value: (self at: i) value: i)].
	^r!
withIndexCollect: aBlock
	^self collectWithIndex: aBlock!
pairsDo: aBlock
	1 to: self size - 1 by: 2 do: [:i | aBlock value: (self at: i) value: (self at: i + 1)]!
reverseWith: aCollection do: aBlock
	self size = aCollection size ifFalse: [^self error: 'collections must be the same size'].
	self size to: 1 by: -1 do: [:i | aBlock value: (self at: i) value: (aCollection at: i)]! !

!SequenceableCollection methodsFor: 'replacing'!
replaceAll: oldObject with: newObject
	1 to: self size do: [:i | (self at: i) = oldObject ifTrue: [self at: i put: newObject]]! !

!SequenceableCollection methodsFor: 'sorting'!
sorted
	| c |
	c := (self isKindOf: ArrayedCollection) ifTrue: [self copy] ifFalse: [self asArray copy].
	c sort.
	^c!
sorted: aBlock
	| c |
	c := (self isKindOf: ArrayedCollection) ifTrue: [self copy] ifFalse: [self asArray copy].
	c sort: aBlock.
	^c!
shuffle
	"mix the elements into a random order, in place"
	| r j |
	r := Random default.
	self size to: 2 by: -1 do: [:i | j := r nextInt: i. self swap: i with: j]!
shuffled
	| c |
	c := (self isKindOf: ArrayedCollection) ifTrue: [self copy] ifFalse: [self asArray copy].
	c shuffle.
	^c! !

!SequenceableCollection methodsFor: 'combining'!
join: aCollectionOfCollections
	"the receiver is the separator: ', ' join: #('a' 'b') is 'a, b'"
	| out first |
	out := WriteStream on: (self species new: 0).
	first := true.
	aCollectionOfCollections do: [:e |
		first ifFalse: [out nextPutAll: self].
		first := false.
		out nextPutAll: e].
	^out contents!
permutationsDo: aBlock
	"evaluate aBlock with each ordering of the elements (as an Array)"
	| a |
	a := self asArray copy.
	self permute: a from: 1 do: aBlock!
permute: anArray from: k do: aBlock
	k > anArray size ifTrue: [^aBlock value: anArray copy].
	k to: anArray size do: [:i |
		anArray swap: k with: i.
		self permute: anArray from: k + 1 do: aBlock.
		anArray swap: k with: i]! !

!ArrayedCollection class methodsFor: 'instance creation'!
with: a with: b with: c with: d with: e
	^(self new: 5) at: 1 put: a; at: 2 put: b; at: 3 put: c; at: 4 put: d; at: 5 put: e; yourself!
with: a with: b with: c with: d with: e with: f
	^(self new: 6) at: 1 put: a; at: 2 put: b; at: 3 put: c; at: 4 put: d; at: 5 put: e; at: 6 put: f; yourself!
streamContents: aBlock
	"the contents of a WriteStream that aBlock fills"
	| s |
	s := WriteStream on: (self new: 16).
	aBlock value: s.
	^s contents!
newFrom: aCollection
	^self withAll: aCollection!
empty
	^self new: 0! !

"---- OrderedCollection, Set, Bag, Dictionary, Interval, Association ----"

!OrderedCollection methodsFor: 'adding'!
add: anObject afterIndex: i
	^self add: anObject beforeIndex: i + 1!
add: anObject withOccurrences: n
	n timesRepeat: [self add: anObject].
	^anObject! !

!OrderedCollection methodsFor: 'removing'!
removeAtIndex: i
	^self removeIndex: i!
removeAllFoundIn: aCollection
	aCollection do: [:e | self remove: e ifAbsent: []]!
identityRemove: anObject
	| i |
	i := self identityIndexOf: anObject.
	i = 0 ifTrue: [^self error: 'object not found'].
	^self removeIndex: i! !

!Set methodsFor: 'testing'!
isSet
	^true!
isSubsetOf: aCollection
	^self allSatisfy: [:e | aCollection includes: e]! !

!Set methodsFor: 'set operations'!
union: aCollection
	^self copy addAll: aCollection; yourself!
intersection: aCollection
	^self select: [:e | aCollection includes: e]!
difference: aCollection
	^self reject: [:e | aCollection includes: e]! !

!Bag methodsFor: 'sorting'!
sortedByCount
	^self sortedCounts! !

!Dictionary class methodsFor: 'instance creation'!
newFrom: aCollection
	"from a Dictionary or a collection of Associations"
	| d |
	d := self new.
	aCollection isDictionary
		ifTrue: [aCollection keysAndValuesDo: [:k :v | d at: k put: v]]
		ifFalse: [aCollection do: [:a | d add: a]].
	^d!
keys: keyCollection values: valueCollection
	| d |
	d := self new.
	keyCollection with: valueCollection do: [:k :v | d at: k put: v].
	^d! !

!Dictionary methodsFor: 'testing'!
isDictionary
	^true!
includesAssociation: anAssociation
	^(self includesKey: anAssociation key) and: [(self at: anAssociation key) = anAssociation value]! !

!Dictionary methodsFor: 'accessing'!
asDictionary
	^self!
associationAt: key ifAbsent: aBlock
	^(self includesKey: key) ifTrue: [self associationAt: key] ifFalse: [aBlock value]!
addAll: aDictionaryOrCollection
	"add the associations of a Dictionary, or each Association of a collection"
	aDictionaryOrCollection isDictionary
		ifTrue: [aDictionaryOrCollection keysAndValuesDo: [:k :v | self at: k put: v]]
		ifFalse: [aDictionaryOrCollection do: [:a | self add: a]].
	^aDictionaryOrCollection! !

!Interval methodsFor: 'testing'!
isInterval
	^true! !

!Association methodsFor: 'testing'!
isAssociation
	^true! !

"---- Point and Rectangle: numbers are accepted wherever a Point is ----"

!Point class methodsFor: 'instance creation'!
r: radius degrees: angle
	| t |
	t := angle degreesToRadians.
	^(radius * t cos) @ (radius * t sin)!
zero
	^0 @ 0! !

!Point methodsFor: 'arithmetic'!
+ arg
	| p |
	p := arg asPoint.
	^(x + p x) @ (y + p y)!
- arg
	| p |
	p := arg asPoint.
	^(x - p x) @ (y - p y)!
* arg
	| p |
	p := arg asPoint.
	^(x * p x) @ (y * p y)!
/ arg
	| p |
	p := arg asPoint.
	^(x / p x) @ (y / p y)!
// arg
	| p |
	p := arg asPoint.
	^(x // p x) @ (y // p y)!
\\ arg
	| p |
	p := arg asPoint.
	^(x \\ p x) @ (y \\ p y)!
scaleBy: factor
	^self * factor!
translateBy: delta
	^self + delta!
squared
	^x squared @ y squared!
sqrt
	^x sqrt @ y sqrt!
reciprocal
	^x reciprocal @ y reciprocal!
sign
	^x sign @ y sign! !

!Point methodsFor: 'comparing'!
< arg
	| p |
	p := arg asPoint.
	^x < p x and: [y < p y]!
<= arg
	| p |
	p := arg asPoint.
	^x <= p x and: [y <= p y]!
> arg
	| p |
	p := arg asPoint.
	^x > p x and: [y > p y]!
>= arg
	| p |
	p := arg asPoint.
	^x >= p x and: [y >= p y]!
max: arg
	| p |
	p := arg asPoint.
	^(x max: p x) @ (y max: p y)!
min: arg
	| p |
	p := arg asPoint.
	^(x min: p x) @ (y min: p y)!
between: min and: max
	^self >= min and: [self <= max]! !

!Point methodsFor: 'testing'!
isPoint
	^true!
isZero
	^x = 0 and: [y = 0]! !

!Point methodsFor: 'accessing'!
x: xNumber y: yNumber
	x := xNumber. y := yNumber! !

!Point methodsFor: 'converting'!
asArray
	^Array with: x with: y!
asFloat
	^x asFloat @ y asFloat!
ceiling
	^x ceiling @ y ceiling!
floor
	^x floor @ y floor!
fractionPart
	^x fractionPart @ y fractionPart!
roundTo: n
	^(x roundTo: n) @ (y roundTo: n)!
truncateTo: n
	^(x truncateTo: n) @ (y truncateTo: n)! !

!Point methodsFor: 'point functions'!
area
	^x * y!
theta
	"the angle of the vector, in radians"
	^y arcTan: x!
angle
	^self theta!
degrees
	^self theta radiansToDegrees!
unitVector
	| r |
	r := self r.
	^r = 0 ifTrue: [self] ifFalse: [(x / r) @ (y / r)]!
normal
	"the unit vector perpendicular to the receiver"
	| r |
	r := self r.
	^r = 0 ifTrue: [self] ifFalse: [(y negated / r) @ (x / r)]!
crossProduct: aPoint
	^(x * aPoint y) - (y * aPoint x)!
rotateBy: radians about: center
	| p |
	p := self - center.
	^(center x + ((p x * radians cos) - (p y * radians sin))) @ (center y + ((p x * radians sin) + (p y * radians cos)))! !

!Rectangle class methodsFor: 'instance creation'!
center: centerPoint extent: extentPoint
	^self origin: centerPoint - (extentPoint // 2) extent: extentPoint!
point: p1 point: p2
	"the Rectangle with the two points as opposite corners"
	^self origin: (p1 min: p2) corner: (p1 max: p2)!
left: l top: t right: r bottom: b
	^self left: l right: r top: t bottom: b!
merging: aCollectionOfRectangles
	^aCollectionOfRectangles fold: [:a :b | a merge: b]! !

!Rectangle methodsFor: 'testing'!
isRectangle
	^true!
isEmpty
	^origin x >= corner x or: [origin y >= corner y]! !

!Rectangle methodsFor: 'accessing'!
width: w
	corner := (origin x + w) @ corner y!
height: h
	corner := corner x @ (origin y + h)!
extent: aPoint
	corner := origin + aPoint!
left: x
	origin := x @ origin y!
right: x
	corner := x @ corner y!
top: y
	origin := origin x @ y!
bottom: y
	corner := corner x @ y!
topCenter
	^self center x @ self top!
bottomCenter
	^self center x @ self bottom!
leftCenter
	^self left @ self center y!
rightCenter
	^self right @ self center y! !

!Rectangle methodsFor: 'converting'!
asRectangle
	^self!
rounded
	^Rectangle origin: origin rounded corner: corner rounded!
truncated
	^Rectangle origin: origin truncated corner: corner truncated! !

!Rectangle methodsFor: 'rectangle functions'!
translateBy: delta
	^Rectangle origin: origin + delta corner: corner + delta!
moveBy: delta
	^self translateBy: delta!
expandBy: delta
	^Rectangle origin: origin - delta asPoint corner: corner + delta asPoint!
insetBy: delta
	^Rectangle origin: origin + delta asPoint corner: corner - delta asPoint!
outsetBy: delta
	^self expandBy: delta!
insetOriginBy: originDelta cornerBy: cornerDelta
	^Rectangle origin: origin + originDelta asPoint corner: corner - cornerDelta asPoint! !

"---- BlockClosure ----"

!BlockClosure methodsFor: 'evaluating'!
cull: a
	^numArgs = 0 ifTrue: [self value] ifFalse: [self value: a]!
cull: a cull: b
	^numArgs = 0 ifTrue: [self value] ifFalse: [numArgs = 1 ifTrue: [self value: a] ifFalse: [self value: a value: b]]!
cull: a cull: b cull: c
	^numArgs < 3 ifTrue: [self cull: a cull: b] ifFalse: [self value: a value: b value: c]!
valueWithEnoughArguments: anArray
	"evaluate with as many of the elements as the block takes"
	^self valueWithArguments: (anArray copyFrom: 1 to: numArgs)!
timeToRun
	"milliseconds taken to evaluate the receiver"
	^Time millisecondsToRun: self!
ifError: errorBlock
	"evaluate; if an Error is signalled, answer the value of errorBlock (given the message text)"
	^self on: Error do: [:e | errorBlock numArgs = 0 ifTrue: [errorBlock value] ifFalse: [errorBlock value: e messageText]]! !

"---- Symbol ----"

!Symbol methodsFor: 'evaluating'!
value: anObject
	^anObject perform: self!
value: anObject value: argument
	^anObject perform: self with: argument! !

!Symbol methodsFor: 'testing'!
isInfix
	"a binary selector"
	^self size > 0 and: [self first isLetter not and: [self first ~= $_]]!
isKeyword
	^self size > 0 and: [self last = $:]!
precedence
	"1 unary, 2 binary, 3 keyword"
	^self isKeyword ifTrue: [3] ifFalse: [self isInfix ifTrue: [2] ifFalse: [1]]! !

!Symbol methodsFor: 'system'!
implementors
	"the classes and metaclasses that define the selector"
	| r |
	r := OrderedCollection new.
	Smalltalk allClassesDo: [:c |
		(c includesSelector: self) ifTrue: [r add: c].
		(c class includesSelector: self) ifTrue: [r add: c class]].
	^r asArray!
sendersIn: aBehavior into: aCollection
	aBehavior selectors do: [:s | | m |
		m := aBehavior compiledMethodAt: s.
		(m literals includes: self) ifTrue: [aCollection add: m]]!
senders
	"the compiled methods that mention the selector among their literals"
	| r |
	r := OrderedCollection new.
	Smalltalk allClassesDo: [:c |
		self sendersIn: c into: r.
		self sendersIn: c class into: r].
	^r asArray! !

"---- classes ----"

!Behavior methodsFor: 'testing'!
isBehavior
	^true!
includesBehavior: aClass
	^self == aClass or: [self inheritsFrom: aClass]!
hasMethods
	^self selectors notEmpty! !

!Behavior methodsFor: 'enumerating'!
subclassesDo: aBlock
	self subclasses do: aBlock!
allSubclassesDo: aBlock
	self allSubclasses do: aBlock!
allSuperclassesDo: aBlock
	self allSuperclasses do: aBlock!
withAllSuperclassesDo: aBlock
	aBlock value: self.
	self allSuperclassesDo: aBlock!
selectorsAndMethodsDo: aBlock
	self selectors do: [:s | aBlock value: s value: (self compiledMethodAt: s)]! !

!Behavior methodsFor: 'accessing'!
instVarNames
	"the instance variables this class adds to its superclass's"
	^self instanceVariableNames!
instanceSide
	^self theNonMetaClass!
instanceClass
	^self theNonMetaClass!
thisClass
	^self theNonMetaClass!
classSide
	^self isMeta ifTrue: [self] ifFalse: [self class]! !

!Metaclass methodsFor: 'testing'!
isMetaclass
	^true! !

"---- Random, Semaphore ----"

!Random class methodsFor: 'shared instance'!
default
	"a Random shared by the whole system"
	^Smalltalk at: #DefaultRandom ifAbsent: [Smalltalk at: #DefaultRandom put: Random new]!
next
	^self default next!
between: low and: high
	^self default between: low and: high!
nextInt: n
	^self default nextInt: n! !

!Random methodsFor: 'accessing'!
seed
	^seed!
seed: anInteger
	self setSeed: anInteger!
nextBoolean
	^self next < 0.5!
nextGaussian
	"normally distributed (mean 0, standard deviation 1), by the Box-Muller transform"
	| u v |
	u := self next. v := self next.
	u = 0 ifTrue: [u := 1.0e-12].
	^(-2.0 * u ln) sqrt * (2.0 * Float pi * v) cos!
pick: aCollection
	"a randomly chosen element of a non-empty sequenceable collection"
	^aCollection at: (self nextInt: aCollection size)! !

!Semaphore methodsFor: 'testing'!
signals
	^excessSignals!
isSignaled
	^excessSignals > 0!
consumeAllSignals
	excessSignals := 0!
waitingProcesses
	^self asArray! !

"---- streams ----"

!Stream methodsFor: 'enumerating'!
inject: aValue into: aBlock
	| r |
	r := aValue.
	self do: [:e | r := aBlock value: r value: e].
	^r!
detect: aBlock ifNone: noneBlock
	self do: [:e | (aBlock value: e) ifTrue: [^e]].
	^noneBlock value!
detect: aBlock
	^self detect: aBlock ifNone: [self error: 'no element found']! !

!PositionableStream methodsFor: 'positioning'!
atStart
	^position = 0!
back
	"step back one element and answer it"
	position = 0 ifTrue: [^nil].
	position := position - 1.
	^collection at: position + 1!
backUp: n
	self skip: n negated!
notEmpty
	^self isEmpty not!
upToAll: aCollection
	"the elements up to the next occurrence of aCollection, which is skipped"
	| start i |
	start := position + 1.
	i := collection indexOfSubCollection: aCollection startingAt: start.
	i = 0 ifTrue: [^self upToEnd].
	position := i - 1 + aCollection size.
	^collection copyFrom: start to: i - 1!
skipToAll: aCollection
	"skip past the next occurrence of aCollection; false if there is none"
	| i |
	i := collection indexOfSubCollection: aCollection startingAt: position + 1.
	i = 0 ifTrue: [position := readLimit. ^false].
	position := i - 1 + aCollection size.
	^true!
lines
	"the remaining lines"
	| r |
	r := OrderedCollection new.
	[self atEnd] whileFalse: [r add: self nextLine].
	^r! !

!WriteStream methodsFor: 'character writing'!
lf
	self nextPut: Character lf!
next: n put: anObject
	n timesRepeat: [self nextPut: anObject].
	^anObject!
flush
	^self!
close
	^self!
readStream
	^ReadStream on: self contents!
reverseContents
	^self contents reverse! !
