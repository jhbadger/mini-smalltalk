"Mini Smalltalk-80 kernel, part 2: collections"

Object subclass: #Collection instanceVariableNames: '' classVariableNames: '' category: 'Collections-Abstract'!
Collection subclass: #SequenceableCollection instanceVariableNames: '' classVariableNames: '' category: 'Collections-Abstract'!
SequenceableCollection subclass: #ArrayedCollection instanceVariableNames: '' classVariableNames: '' category: 'Collections-Abstract'!
ArrayedCollection variableSubclass: #Array instanceVariableNames: '' classVariableNames: '' category: 'Collections-Arrayed'!
ArrayedCollection variableByteSubclass: #String instanceVariableNames: '' classVariableNames: '' category: 'Collections-Text'!
String variableByteSubclass: #Symbol instanceVariableNames: '' classVariableNames: '' category: 'Collections-Text'!
ArrayedCollection variableByteSubclass: #ByteArray instanceVariableNames: '' classVariableNames: '' category: 'Collections-Arrayed'!
SequenceableCollection subclass: #Interval instanceVariableNames: 'start stop step' classVariableNames: '' category: 'Collections-Sequenceable'!
SequenceableCollection subclass: #OrderedCollection instanceVariableNames: 'firstIndex lastIndex array' classVariableNames: '' category: 'Collections-Sequenceable'!
OrderedCollection subclass: #SortedCollection instanceVariableNames: 'sortBlock' classVariableNames: '' category: 'Collections-Sequenceable'!
Collection subclass: #Set instanceVariableNames: 'tally keys values' classVariableNames: '' category: 'Collections-Unordered'!
Set subclass: #IdentitySet instanceVariableNames: '' classVariableNames: '' category: 'Collections-Unordered'!
Set subclass: #Dictionary instanceVariableNames: '' classVariableNames: '' category: 'Collections-Unordered'!
Dictionary subclass: #IdentityDictionary instanceVariableNames: '' classVariableNames: '' category: 'Collections-Unordered'!
IdentityDictionary subclass: #SystemDictionary instanceVariableNames: '' classVariableNames: '' category: 'System-Support'!
Collection subclass: #Bag instanceVariableNames: 'contents' classVariableNames: '' category: 'Collections-Unordered'!

!Collection class methodsFor: 'instance creation'!
with: a
	^self new add: a; yourself!
with: a with: b
	^self new add: a; add: b; yourself!
with: a with: b with: c
	^self new add: a; add: b; add: c; yourself!
with: a with: b with: c with: d
	^self new add: a; add: b; add: c; add: d; yourself!
withAll: aCollection
	^self new addAll: aCollection; yourself! !

!Collection methodsFor: 'accessing'!
size
	| n |
	n := 0.
	self do: [:e | n := n + 1].
	^n!
anyOne
	self do: [:e | ^e].
	^self error: 'collection is empty'!
max
	^self inject: self anyOne into: [:a :b | a max: b]!
min
	^self inject: self anyOne into: [:a :b | a min: b]!
sum
	^self inject: 0 into: [:a :b | a + b]! !

!Collection methodsFor: 'adding/removing'!
add: anObject
	^self subclassResponsibility!
addAll: aCollection
	aCollection do: [:e | self add: e].
	^aCollection!
remove: anObject
	^self remove: anObject ifAbsent: [self error: 'object not found']!
remove: anObject ifAbsent: aBlock
	^self subclassResponsibility!
removeAll: aCollection
	aCollection do: [:e | self remove: e].
	^aCollection! !

!Collection methodsFor: 'testing'!
isCollection
	^true!
isEmpty
	^self size = 0!
notEmpty
	^self isEmpty not!
isEmptyOrNil
	^self isEmpty!
includes: anObject
	self do: [:e | e = anObject ifTrue: [^true]].
	^false!
occurrencesOf: anObject
	| n |
	n := 0.
	self do: [:e | e = anObject ifTrue: [n := n + 1]].
	^n!
anySatisfy: aBlock
	self do: [:e | (aBlock value: e) ifTrue: [^true]].
	^false!
allSatisfy: aBlock
	self do: [:e | (aBlock value: e) ifFalse: [^false]].
	^true!
emptyCheck
	self isEmpty ifTrue: [self error: 'collection is empty']! !

!Collection methodsFor: 'enumerating'!
do: aBlock
	^self subclassResponsibility!
do: aBlock separatedBy: sepBlock
	| first |
	first := true.
	self do: [:e | first ifTrue: [first := false] ifFalse: [sepBlock value]. aBlock value: e]!
collect: aBlock
	| r |
	r := OrderedCollection new.
	self do: [:e | r add: (aBlock value: e)].
	^r!
select: aBlock
	| r |
	r := self species new.
	self do: [:e | (aBlock value: e) ifTrue: [r add: e]].
	^r!
reject: aBlock
	^self select: [:e | (aBlock value: e) not]!
detect: aBlock
	^self detect: aBlock ifNone: [self error: 'object not found']!
detect: aBlock ifNone: exceptionBlock
	self do: [:e | (aBlock value: e) ifTrue: [^e]].
	^exceptionBlock value!
inject: thisValue into: binaryBlock
	| acc |
	acc := thisValue.
	self do: [:e | acc := binaryBlock value: acc value: e].
	^acc!
count: aBlock
	| n |
	n := 0.
	self do: [:e | (aBlock value: e) ifTrue: [n := n + 1]].
	^n! !

!Collection methodsFor: 'converting'!
asArray
	| a i |
	a := Array new: self size. i := 0.
	self do: [:e | a at: (i := i + 1) put: e].
	^a!
asOrderedCollection
	^OrderedCollection withAll: self!
asSet
	^Set withAll: self!
asBag
	^Bag withAll: self!
asSortedCollection
	^self asSortedCollection: [:a :b | a <= b]!
asSortedCollection: aBlock
	^(SortedCollection sortBlock: aBlock) addAll: self; yourself!
asString
	^self printString! !

!Collection methodsFor: 'printing'!
printOn: aStream
	| n |
	aStream nextPutAll: self class name; nextPutAll: ' ('.
	n := 0.
	self do: [:e | n := n + 1. n <= 100 ifTrue: [aStream print: e] ifFalse: [n = 101 ifTrue: [aStream nextPutAll: '...']]] separatedBy: [n < 101 ifTrue: [aStream space]].
	aStream nextPut: $)! !

!SequenceableCollection methodsFor: 'accessing'!
first
	^self at: 1!
last
	^self at: self size!
first: n
	^self copyFrom: 1 to: n!
last: n
	^self copyFrom: self size - n + 1 to: self size!
allButFirst
	^self copyFrom: 2 to: self size!
allButLast
	^self copyFrom: 1 to: self size - 1!
indexOf: anObject
	^self indexOf: anObject ifAbsent: [0]!
indexOf: anObject ifAbsent: aBlock
	1 to: self size do: [:i | (self at: i) = anObject ifTrue: [^i]].
	^aBlock value!
indexOfSubCollection: sub
	| n |
	n := sub size.
	1 to: self size - n + 1 do: [:i | (self copyFrom: i to: i + n - 1) = sub ifTrue: [^i]].
	^0!
atAll: indices put: anObject
	indices do: [:i | self at: i put: anObject]!
atAllPut: anObject
	1 to: self size do: [:i | self at: i put: anObject]!
swap: i with: j
	| t |
	t := self at: i. self at: i put: (self at: j). self at: j put: t!
readStream
	^ReadStream on: self!
writeStream
	^WriteStream on: self! !

!SequenceableCollection methodsFor: 'comparing'!
= aCollection
	self class == aCollection class ifFalse: [^false].
	self size = aCollection size ifFalse: [^false].
	1 to: self size do: [:i | (self at: i) = (aCollection at: i) ifFalse: [^false]].
	^true!
hash
	| h |
	h := self size.
	self do: [:e | h := (h * 31 + e hash) bitAnd: 1073741823].
	^h!
startsWith: aCollection
	aCollection size > self size ifTrue: [^false].
	^(self copyFrom: 1 to: aCollection size) = aCollection!
endsWith: aCollection
	aCollection size > self size ifTrue: [^false].
	^(self copyFrom: self size - aCollection size + 1 to: self size) = aCollection! !

!SequenceableCollection methodsFor: 'enumerating'!
do: aBlock
	1 to: self size do: [:i | aBlock value: (self at: i)]!
doWithIndex: aBlock
	1 to: self size do: [:i | aBlock value: (self at: i) value: i]!
keysAndValuesDo: aBlock
	1 to: self size do: [:i | aBlock value: i value: (self at: i)]!
reverseDo: aBlock
	self size to: 1 by: -1 do: [:i | aBlock value: (self at: i)]!
with: aCollection do: aBlock
	1 to: self size do: [:i | aBlock value: (self at: i) value: (aCollection at: i)]!
with: aCollection collect: aBlock
	| r |
	r := self species new: self size.
	1 to: self size do: [:i | r at: i put: (aBlock value: (self at: i) value: (aCollection at: i))].
	^r!
collect: aBlock
	| r |
	r := self species new: self size.
	1 to: self size do: [:i | r at: i put: (aBlock value: (self at: i))].
	^r!
select: aBlock
	| r |
	r := OrderedCollection new.
	self do: [:e | (aBlock value: e) ifTrue: [r add: e]].
	^self species withAll: r!
findFirst: aBlock
	1 to: self size do: [:i | (aBlock value: (self at: i)) ifTrue: [^i]].
	^0! !

!SequenceableCollection methodsFor: 'copying'!
copyFrom: start to: stop
	| r n |
	n := stop - start + 1.
	n < 0 ifTrue: [n := 0].
	r := self species new: n.
	r replaceFrom: 1 to: n with: self startingAt: start.
	^r!
copyWith: anObject
	| r |
	r := self species new: self size + 1.
	r replaceFrom: 1 to: self size with: self startingAt: 1.
	r at: self size + 1 put: anObject.
	^r!
copyWithout: anObject
	^self reject: [:e | e = anObject]!
, aCollection
	| r |
	r := self species new: self size + aCollection size.
	r replaceFrom: 1 to: self size with: self startingAt: 1.
	r replaceFrom: self size + 1 to: self size + aCollection size with: aCollection startingAt: 1.
	^r!
reversed
	| r n |
	n := self size.
	r := self species new: n.
	1 to: n do: [:i | r at: i put: (self at: n + 1 - i)].
	^r!
reverse
	^self reversed!
replaceFrom: start to: stop with: aCollection startingAt: repStart
	<primitive: 67>
	| j |
	j := repStart.
	start to: stop do: [:i | self at: i put: (aCollection at: j). j := j + 1]!
replaceFrom: start to: stop with: aCollection
	^self replaceFrom: start to: stop with: aCollection startingAt: 1!
copyReplaceAll: old with: new
	| s i |
	s := WriteStream on: (self species new: self size).
	i := 1.
	[i <= self size] whileTrue: [
		(i + old size - 1 <= self size and: [(self copyFrom: i to: i + old size - 1) = old])
			ifTrue: [s nextPutAll: new. i := i + old size]
			ifFalse: [s nextPut: (self at: i). i := i + 1]].
	^s contents! !

!SequenceableCollection methodsFor: 'sorting'!
sort
	^self sort: [:a :b | a <= b]!
sort: aBlock
	self sortFrom: 1 to: self size with: aBlock!
sortFrom: lo to: hi with: aBlock
	| i j pivot |
	hi - lo < 1 ifTrue: [^self].
	i := lo. j := hi. pivot := self at: (lo + hi) // 2.
	[i <= j] whileTrue: [
		[(aBlock value: (self at: i) value: pivot) and: [(aBlock value: pivot value: (self at: i)) not]] whileTrue: [i := i + 1].
		[(aBlock value: pivot value: (self at: j)) and: [(aBlock value: (self at: j) value: pivot) not]] whileTrue: [j := j - 1].
		i <= j ifTrue: [self swap: i with: j. i := i + 1. j := j - 1]].
	self sortFrom: lo to: j with: aBlock.
	self sortFrom: i to: hi with: aBlock!
asSortedArray
	^self asArray sort; yourself! !

!ArrayedCollection class methodsFor: 'instance creation'!
new
	^self new: 0!
with: a
	^(self new: 1) at: 1 put: a; yourself!
with: a with: b
	^(self new: 2) at: 1 put: a; at: 2 put: b; yourself!
with: a with: b with: c
	^(self new: 3) at: 1 put: a; at: 2 put: b; at: 3 put: c; yourself!
with: a with: b with: c with: d
	^(self new: 4) at: 1 put: a; at: 2 put: b; at: 3 put: c; at: 4 put: d; yourself!
withAll: aCollection
	| r i |
	r := self new: aCollection size. i := 0.
	aCollection do: [:e | r at: (i := i + 1) put: e].
	^r!
new: n withAll: anObject
	^(self new: n) atAllPut: anObject; yourself! !

!ArrayedCollection methodsFor: 'accessing'!
size
	<primitive: 3>
	^0!
add: anObject
	^self shouldNotImplement! !

!Array methodsFor: 'testing'!
isArray
	^true! !

!Array methodsFor: 'converting'!
asArray
	^self! !

!Array methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: '#('.
	self do: [:e | aStream print: e] separatedBy: [aStream space].
	aStream nextPut: $)! !

!ByteArray methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: '#['.
	self do: [:e | aStream print: e] separatedBy: [aStream space].
	aStream nextPut: $]! !

!String class methodsFor: 'instance creation'!
new: n
	<primitive: 7>
	^self error: 'cannot create'!
cr
	^self with: Character cr!
tab
	^self with: Character tab! !

!String methodsFor: 'comparing'!
= aString
	<primitive: 63>
	^false!
hash
	<primitive: 64>
	^0!
compare: aString
	<primitive: 68>
	^self error: 'argument must be a string'!
< aString
	^(self compare: aString) < 0!
> aString
	^(self compare: aString) > 0!
<= aString
	^(self compare: aString) <= 0!
>= aString
	^(self compare: aString) >= 0!
max: aString
	^self > aString ifTrue: [self] ifFalse: [aString]!
min: aString
	^self < aString ifTrue: [self] ifFalse: [aString]!
sameAs: aString
	^self asLowercase = aString asLowercase! !

!String methodsFor: 'testing'!
isString
	^true!
includesSubstring: aString
	^(self indexOfSubCollection: aString) > 0!
isEmpty
	^self size = 0! !

!String methodsFor: 'converting'!
asString
	^self!
asSymbol
	<primitive: 65>
	^self error: 'cannot intern'!
asNumber
	<primitive: 69>
	^nil!
asInteger
	| n |
	n := self asNumber.
	^n isNil ifTrue: [nil] ifFalse: [n truncated]!
asUppercase
	^self collect: [:c | c asUppercase]!
asLowercase
	^self collect: [:c | c asLowercase]!
asArray
	^Array withAll: self!
withBlanksTrimmed
	| a b |
	a := 1. b := self size.
	[a <= b and: [(self at: a) isSeparator]] whileTrue: [a := a + 1].
	[b >= a and: [(self at: b) isSeparator]] whileTrue: [b := b - 1].
	^self copyFrom: a to: b!
trimmed
	^self withBlanksTrimmed!
substrings
	^self subStrings: (String with: Character space with: Character tab with: Character cr)!
subStrings: separators
	| r s |
	r := OrderedCollection new. s := WriteStream on: (String new: 16).
	self do: [:c |
		(separators includes: c)
			ifTrue: [s contents isEmpty ifFalse: [r add: s contents. s := WriteStream on: (String new: 16)]]
			ifFalse: [s nextPut: c]].
	s contents isEmpty ifFalse: [r add: s contents].
	^r!
lines
	^self subStrings: (String with: Character cr)!
size
	<primitive: 3>
	^0! !

!String methodsFor: 'printing'!
printOn: aStream
	aStream nextPut: $'.
	self do: [:c | c = $' ifTrue: [aStream nextPut: c]. aStream nextPut: c].
	aStream nextPut: $'!
displayString
	^self!
displayNl
	Transcript show: self; cr! !

!Symbol class methodsFor: 'instance creation'!
new: n
	^self shouldNotImplement!
intern: aString
	^aString asSymbol! !

!Symbol methodsFor: 'comparing'!
= aSymbol
	^self == aSymbol!
hash
	<primitive: 8>
	^0! !

!Symbol methodsFor: 'accessing'!
numArgs
	| n |
	self isEmpty ifTrue: [^0].
	self first isLetter ifFalse: [^1].
	n := 0.
	self do: [:c | c = $: ifTrue: [n := n + 1]].
	^n!
species
	^String! !

!Symbol methodsFor: 'converting'!
asSymbol
	^self!
asString
	<primitive: 66>
	^self error: 'cannot convert'!
isSymbol
	^true! !

!Symbol methodsFor: 'printing'!
printOn: aStream
	aStream nextPut: $#; nextPutAll: self!
displayString
	^self asString! !

!Interval class methodsFor: 'instance creation'!
from: start to: stop
	^self new setFrom: start to: stop by: 1!
from: start to: stop by: step
	^self new setFrom: start to: stop by: step! !

!Interval methodsFor: 'accessing'!
setFrom: a to: b by: c
	start := a. stop := b. step := c!
size
	step > 0
		ifTrue: [stop >= start ifTrue: [^(stop - start) // step + 1] ifFalse: [^0]]
		ifFalse: [start >= stop ifTrue: [^(start - stop) // step negated + 1] ifFalse: [^0]]!
at: i
	(i between: 1 and: self size) ifFalse: [^self errorSubscriptBounds: i].
	^start + (step * (i - 1))!
at: i put: v
	^self shouldNotImplement!
first
	^start!
last
	^stop - ((stop - start) \\ step)!
increment
	^step!
species
	^Array! !

!Interval methodsFor: 'enumerating'!
do: aBlock
	start to: stop by: step do: aBlock!
collect: aBlock
	| r i |
	r := Array new: self size. i := 0.
	self do: [:e | r at: (i := i + 1) put: (aBlock value: e)].
	^r! !

!Interval methodsFor: 'printing'!
printOn: aStream
	aStream nextPut: $(; print: start; nextPutAll: ' to: '; print: stop.
	step ~= 1 ifTrue: [aStream nextPutAll: ' by: '; print: step].
	aStream nextPut: $)! !

!OrderedCollection class methodsFor: 'instance creation'!
new
	^self new: 8!
new: n
	^self basicNew setCapacity: (n max: 4)! !

!OrderedCollection methodsFor: 'private'!
setCapacity: n
	array := Array new: n. firstIndex := 1. lastIndex := 0!
grow
	| a |
	a := Array new: array size * 2 + 2.
	a replaceFrom: 1 to: self size with: array startingAt: firstIndex.
	lastIndex := self size. firstIndex := 1. array := a!
makeRoomAtFirst
	| a n |
	n := self size.
	a := Array new: array size * 2 + 2.
	a replaceFrom: array size + 1 to: array size + n with: array startingAt: firstIndex.
	firstIndex := array size + 1. lastIndex := firstIndex + n - 1. array := a! !

!OrderedCollection methodsFor: 'accessing'!
size
	^lastIndex - firstIndex + 1!
at: i
	(i between: 1 and: self size) ifFalse: [^self errorSubscriptBounds: i].
	^array at: firstIndex + i - 1!
at: i put: v
	(i between: 1 and: self size) ifFalse: [^self errorSubscriptBounds: i].
	^array at: firstIndex + i - 1 put: v!
first
	self emptyCheck. ^array at: firstIndex!
last
	self emptyCheck. ^array at: lastIndex!
species
	^OrderedCollection! !

!OrderedCollection methodsFor: 'adding'!
add: anObject
	^self addLast: anObject!
addLast: anObject
	lastIndex = array size ifTrue: [self grow].
	lastIndex := lastIndex + 1.
	^array at: lastIndex put: anObject!
addFirst: anObject
	firstIndex = 1 ifTrue: [self makeRoomAtFirst].
	firstIndex := firstIndex - 1.
	^array at: firstIndex put: anObject!
add: anObject beforeIndex: i
	| n |
	n := self size.
	self addLast: anObject.
	n to: i by: -1 do: [:k | array at: firstIndex + k put: (array at: firstIndex + k - 1)].
	^array at: firstIndex + i - 1 put: anObject!
addAllFirst: aCollection
	aCollection reverseDo: [:e | self addFirst: e].
	^aCollection! !

!OrderedCollection methodsFor: 'removing'!
removeFirst
	| e |
	self emptyCheck.
	e := array at: firstIndex. array at: firstIndex put: nil. firstIndex := firstIndex + 1.
	^e!
removeLast
	| e |
	self emptyCheck.
	e := array at: lastIndex. array at: lastIndex put: nil. lastIndex := lastIndex - 1.
	^e!
removeIndex: i
	| e |
	e := self at: i.
	i to: self size - 1 do: [:k | self at: k put: (self at: k + 1)].
	array at: lastIndex put: nil. lastIndex := lastIndex - 1.
	^e!
remove: anObject ifAbsent: aBlock
	| i |
	i := self indexOf: anObject.
	i = 0 ifTrue: [^aBlock value].
	^self removeIndex: i!
removeAll
	self setCapacity: 8! !

!OrderedCollection methodsFor: 'enumerating'!
do: aBlock
	| i |
	i := firstIndex.
	[i <= lastIndex] whileTrue: [aBlock value: (array at: i). i := i + 1]! !

!OrderedCollection methodsFor: 'copying'!
postCopy
	array := array copy!
asOrderedCollection
	^self copy! !

!SortedCollection class methodsFor: 'instance creation'!
sortBlock: aBlock
	^self new setSortBlock: aBlock!
new: n
	^(super new: n) setSortBlock: [:a :b | a <= b]! !

!SortedCollection methodsFor: 'accessing'!
setSortBlock: aBlock
	sortBlock := aBlock!
sortBlock
	^sortBlock!
species
	^OrderedCollection!
add: anObject
	| i |
	i := self size.
	[i >= 1 and: [(sortBlock value: (self at: i) value: anObject) not]] whileTrue: [i := i - 1].
	^self add: anObject beforeIndex: i + 1!
addAll: aCollection
	aCollection size > (self size // 3)
		ifTrue: [aCollection do: [:e | super addLast: e]. self reSort]
		ifFalse: [aCollection do: [:e | self add: e]].
	^aCollection!
reSort
	| a |
	a := self asArray. a sort: sortBlock.
	self removeAll. a do: [:e | super addLast: e]!
addFirst: anObject
	^self shouldNotImplement!
at: i put: v
	^self shouldNotImplement!
median
	^self at: self size + 1 // 2! !

!Set class methodsFor: 'instance creation'!
new
	^self basicNew init!
new: n
	^self new! !

!Set methodsFor: 'private'!
init
	tally := 0. keys := Array new: 16. values := Array new: 16!
primAt: key ifAbsent: aBlock
	<primitive: 90>
	^aBlock value!
primAt: key put: anObject
	<primitive: 91>
	^self error: 'cannot store'!
primRemoveKey: key ifAbsent: aBlock
	<primitive: 92>
	^aBlock value!
primKeys
	<primitive: 93>
	^#()!
primIncludesKey: key
	<primitive: 94>
	^false! !

!Set methodsFor: 'accessing'!
size
	^tally!
anyOne
	self do: [:e | ^e].
	^self error: 'collection is empty'! !

!Set methodsFor: 'adding/removing'!
add: anObject
	anObject isNil ifTrue: [^anObject].
	self primAt: anObject put: anObject.
	^anObject!
remove: anObject ifAbsent: aBlock
	^self primRemoveKey: anObject ifAbsent: aBlock!
removeAll
	self init! !

!Set methodsFor: 'testing'!
includes: anObject
	^self primIncludesKey: anObject!
occurrencesOf: anObject
	^(self includes: anObject) ifTrue: [1] ifFalse: [0]! !

!Set methodsFor: 'enumerating'!
do: aBlock
	self primKeys do: aBlock!
collect: aBlock
	| r |
	r := Set new.
	self do: [:e | r add: (aBlock value: e)].
	^r! !

!Set methodsFor: 'copying'!
postCopy
	keys := keys copy.
	values := values collect: [:a | a isNil ifTrue: [nil] ifFalse: [a copy]]! !

!Set methodsFor: 'comparing'!
= aSet
	self class == aSet class ifFalse: [^false].
	self size = aSet size ifFalse: [^false].
	self do: [:e | (aSet includes: e) ifFalse: [^false]].
	^true!
hash
	| h |
	h := self size.
	self do: [:e | h := h bitXor: e hash].
	^h! !

!Dictionary methodsFor: 'accessing'!
at: key
	<primitive: 90>
	^self error: 'key not found: ', key printString!
at: key ifAbsent: aBlock
	<primitive: 90>
	^aBlock value!
at: key ifAbsentPut: aBlock
	^self at: key ifAbsent: [self at: key put: aBlock value]!
at: key ifPresent: aBlock
	^(self includesKey: key) ifTrue: [aBlock value: (self at: key)] ifFalse: [nil]!
at: key put: value
	<primitive: 91>
	^self error: 'cannot store'!
associationAt: key
	<primitive: 95>
	^self error: 'key not found'!
keys
	"Answer a Set of the keys"
	^Set withAll: self primKeys!
values
	^self primKeys collect: [:k | self at: k]!
associations
	^self primKeys collect: [:k | self associationAt: k]!
size
	^tally!
keyAtValue: value
	^self keyAtValue: value ifAbsent: [nil]!
keyAtValue: value ifAbsent: aBlock
	self keysAndValuesDo: [:k :v | v = value ifTrue: [^k]].
	^aBlock value!
anyOne
	^self values anyOne! !

!Dictionary methodsFor: 'adding/removing'!
add: anAssociation
	self at: anAssociation key put: anAssociation value.
	^anAssociation!
removeKey: key
	<primitive: 92>
	^self error: 'key not found: ', key printString!
removeKey: key ifAbsent: aBlock
	<primitive: 92>
	^aBlock value!
remove: anObject ifAbsent: aBlock
	^self shouldNotImplement! !

!Dictionary methodsFor: 'testing'!
includesKey: key
	<primitive: 94>
	^false!
includes: anObject
	self do: [:v | v = anObject ifTrue: [^true]].
	^false! !

!Dictionary methodsFor: 'enumerating'!
do: aBlock
	self primKeys do: [:k | aBlock value: (self at: k)]!
keysDo: aBlock
	self primKeys do: aBlock!
valuesDo: aBlock
	self do: aBlock!
keysAndValuesDo: aBlock
	self primKeys do: [:k | aBlock value: k value: (self at: k)]!
associationsDo: aBlock
	self primKeys do: [:k | aBlock value: (self associationAt: k)]!
collect: aBlock
	| r |
	r := Bag new.
	self do: [:v | r add: (aBlock value: v)].
	^r!
select: aBlock
	| r |
	r := self species new.
	self keysAndValuesDo: [:k :v | (aBlock value: v) ifTrue: [r at: k put: v]].
	^r!
keysSortedSafely
	^self primKeys asSortedCollection: [:a :b | a printString <= b printString]! !

!Dictionary methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: self class name; nextPutAll: ' ('.
	self primKeys doWithIndex: [:k :i | i <= 50 ifTrue: [aStream print: k; nextPutAll: '->'; print: (self at: k); space]].
	tally > 50 ifTrue: [aStream nextPutAll: '...'].
	aStream nextPut: $)! !

!Dictionary methodsFor: 'comparing'!
= aDictionary
	self class == aDictionary class ifFalse: [^false].
	self size = aDictionary size ifFalse: [^false].
	self keysAndValuesDo: [:k :v | (aDictionary at: k ifAbsent: [^false]) = v ifFalse: [^false]].
	^true! !

!SystemDictionary methodsFor: 'classes'!
allClasses
	| r |
	r := OrderedCollection new.
	self do: [:v | v isClass ifTrue: [r add: v]].
	^r asSortedCollection: [:a :b | a name <= b name]!
allClassesDo: aBlock
	self allClasses do: aBlock!
allClassNames
	^self allClasses collect: [:c | c name]!
classNamed: aString
	^self at: aString asSymbol ifAbsent: [nil]!
classCategories
	^(self allClasses collect: [:c | c category]) asSet asSortedCollection!
classesInCategory: aString
	^self allClasses select: [:c | c category = aString]!
printOn: aStream
	aStream nextPutAll: 'Smalltalk'! !

!SystemDictionary methodsFor: 'system'!
quit
	<primitive: 112>
	^self!
fileIn: aFileName
	<primitive: 114>
	^self error: 'file in failed'!
fileInString: aString
	<primitive: 121>
	^self error: 'file in failed'!
garbageCollect
	<primitive: 117>
	^self!
flushCache
	<primitive: 113>
	^self!
version
	^'Mini Smalltalk-80 TUI 1.0'! !

!Bag class methodsFor: 'instance creation'!
new
	^self basicNew init! !

!Bag methodsFor: 'private'!
init
	contents := Dictionary new! !

!Bag methodsFor: 'accessing'!
size
	| n |
	n := 0.
	contents do: [:c | n := n + c].
	^n!
occurrencesOf: anObject
	^contents at: anObject ifAbsent: [0]!
asSet
	^contents keys!
sortedCounts
	^(contents associations collect: [:a | a value -> a key]) asSortedCollection: [:x :y | x key >= y key]! !

!Bag methodsFor: 'adding/removing'!
add: anObject
	^self add: anObject withOccurrences: 1!
add: anObject withOccurrences: anInteger
	anObject isNil ifTrue: [^anObject].
	contents at: anObject put: (contents at: anObject ifAbsent: [0]) + anInteger.
	^anObject!
remove: anObject ifAbsent: aBlock
	| n |
	n := contents at: anObject ifAbsent: [^aBlock value].
	n = 1 ifTrue: [contents removeKey: anObject] ifFalse: [contents at: anObject put: n - 1].
	^anObject! !

!Bag methodsFor: 'testing'!
includes: anObject
	^contents includesKey: anObject! !

!Bag methodsFor: 'enumerating'!
do: aBlock
	contents keysAndValuesDo: [:k :n | n timesRepeat: [aBlock value: k]]! !

!Bag methodsFor: 'copying'!
postCopy
	contents := contents copy! !

!Bag methodsFor: 'comparing'!
= aBag
	^(aBag isKindOf: Bag) and: [self size = aBag size and: [contents keys allSatisfy: [:k | (self occurrencesOf: k) = (aBag occurrencesOf: k)]]]! !
