"Mini Smalltalk-80 kernel, part 5: more collections and streams - LinkedList, RunArray, MappedCollection, Text, FileStream; storing, copying, dependents"

Object subclass: #Link instanceVariableNames: 'nextLink' classVariableNames: '' category: 'Collections-Support'!
SequenceableCollection subclass: #LinkedList instanceVariableNames: 'firstLink lastLink' classVariableNames: '' category: 'Collections-Sequenceable'!
SequenceableCollection subclass: #RunArray instanceVariableNames: 'runs values' classVariableNames: '' category: 'Collections-Sequenceable'!
Collection subclass: #MappedCollection instanceVariableNames: 'domain map' classVariableNames: '' category: 'Collections-Sequenceable'!
ArrayedCollection subclass: #Text instanceVariableNames: 'string runs' classVariableNames: '' category: 'Collections-Text'!
ReadWriteStream subclass: #FileStream instanceVariableNames: 'name dirty' classVariableNames: '' category: 'Collections-Streams'!

!Object methodsFor: 'copying'!
deepCopy
	"a copy whose instance variables are themselves deep copies"
	| c |
	c := self shallowCopy.
	c == self ifTrue: [^self].
	1 to: self class instSize do: [:i | c instVarAt: i put: (self instVarAt: i) deepCopy].
	(self class isVariable and: [self class isBytes not]) ifTrue: [1 to: self basicSize do: [:i | c basicAt: i put: (self basicAt: i) deepCopy]].
	^c! !

!Object methodsFor: 'storing'!
storeString
	| s |
	s := WriteStream on: (String new: 32).
	self storeOn: s.
	^s contents!
storeOn: aStream
	"Smalltalk code that reconstructs the receiver"
	| n |
	aStream nextPutAll: '(('; nextPutAll: self class name; nextPutAll: (self class isVariable ifTrue: [' basicNew: ', self basicSize printString] ifFalse: [' basicNew']); nextPut: $).
	n := self class instSize.
	1 to: n do: [:i | aStream nextPutAll: ' instVarAt: '; print: i; nextPutAll: ' put: '; store: (self instVarAt: i); nextPut: $;].
	self class isVariable ifTrue: [1 to: self basicSize do: [:i | aStream nextPutAll: ' basicAt: '; print: i; nextPutAll: ' put: '; store: (self basicAt: i); nextPut: $;]].
	aStream nextPutAll: ' yourself)'! !

!Object methodsFor: 'error handling'!
primitiveFailed
	^self error: 'a primitive has failed'!
notYetImplemented
	^self error: 'not yet implemented'!
caseError
	^self error: 'case not found'! !

!Object methodsFor: 'accessing'!
instVarNamed: aString
	| i |
	i := self class allInstVarNames indexOf: aString.
	i = 0 ifTrue: [^self error: 'no instance variable named ', aString].
	^self instVarAt: i!
instVarNamed: aString put: anObject
	| i |
	i := self class allInstVarNames indexOf: aString.
	i = 0 ifTrue: [^self error: 'no instance variable named ', aString].
	^self instVarAt: i put: anObject! !

!Object methodsFor: 'dependents access'!
dependents
	^Dependents at: self ifAbsent: [#()]!
addDependent: anObject
	| d |
	d := Dependents at: self ifAbsent: [Dependents at: self put: OrderedCollection new].
	(d includes: anObject) ifFalse: [d add: anObject].
	^anObject!
removeDependent: anObject
	| d |
	d := Dependents at: self ifAbsent: [^anObject].
	d remove: anObject ifAbsent: [].
	d isEmpty ifTrue: [Dependents removeKey: self].
	^anObject!
release
	Dependents removeKey: self ifAbsent: []! !

!Object methodsFor: 'updating'!
changed
	self changed: self!
changed: aParameter
	self dependents do: [:d | d update: aParameter]!
update: aParameter
	^self!
broadcast: aSymbol
	self dependents do: [:d | d perform: aSymbol]!
broadcast: aSymbol with: anObject
	self dependents do: [:d | d perform: aSymbol with: anObject]! !

!Boolean methodsFor: 'storing'!
storeOn: aStream
	self printOn: aStream! !

!UndefinedObject methodsFor: 'storing'!
storeOn: aStream
	aStream nextPutAll: 'nil'! !

!Character methodsFor: 'storing'!
storeOn: aStream
	self printOn: aStream! !

!Character class methodsFor: 'instance creation'!
digitValue: anInteger
	^self value: (anInteger < 10 ifTrue: [48 + anInteger] ifFalse: [55 + anInteger])!
backspace
	^self value: 8!
newPage
	^self value: 12!
delete
	^self value: 127! !

!Character methodsFor: 'testing'!
isPunctuation
	^'.,:;!!?' includes: self!
isCharacter
	^true! !

!Symbol methodsFor: 'storing'!
storeOn: aStream
	self printOn: aStream! !

!Symbol methodsFor: 'testing'!
isKeyword
	^self last = $:!
isBinary
	^self first isLetter not and: [self first ~= $_]!
isUnary
	^self isKeyword not and: [self isBinary not]!
keywords
	| r s |
	self isKeyword ifFalse: [^Array with: self].
	r := OrderedCollection new. s := WriteStream on: String new.
	self do: [:c | s nextPut: c. c = $: ifTrue: [r add: s contents asSymbol. s := WriteStream on: String new]].
	^r asArray! !

!String methodsFor: 'storing'!
storeOn: aStream
	self printOn: aStream! !

!String methodsFor: 'comparing'!
match: aString
	"Smalltalk-80 wildcard match: * matches any sequence, # any single character; case insensitive"
	^self matchPattern: self asLowercase from: 1 against: aString asLowercase from: 1!
matchPattern: pat from: pi against: str from: si
	| p |
	pi > pat size ifTrue: [^si > str size].
	p := pat at: pi.
	p = $* ifTrue: [
		si to: str size + 1 do: [:k | (self matchPattern: pat from: pi + 1 against: str from: k) ifTrue: [^true]].
		^false].
	si > str size ifTrue: [^false].
	(p = $# or: [p = (str at: si)]) ifFalse: [^false].
	^self matchPattern: pat from: pi + 1 against: str from: si + 1! !

!String methodsFor: 'copying'!
copyUpTo: aCharacter
	| i |
	i := self indexOf: aCharacter.
	^i = 0 ifTrue: [self copy] ifFalse: [self copyFrom: 1 to: i - 1]!
copyAfter: aCharacter
	| i |
	i := self indexOf: aCharacter.
	^i = 0 ifTrue: [''] ifFalse: [self copyFrom: i + 1 to: self size]!
copyAfterLast: aCharacter
	self size to: 1 by: -1 do: [:i | (self at: i) = aCharacter ifTrue: [^self copyFrom: i + 1 to: self size]].
	^''!
copyUpToLast: aCharacter
	self size to: 1 by: -1 do: [:i | (self at: i) = aCharacter ifTrue: [^self copyFrom: 1 to: i - 1]].
	^self copy!
contractTo: n
	self size <= n ifTrue: [^self].
	^(self copyFrom: 1 to: n // 2 - 1), '...', (self copyFrom: self size - (n - (n // 2) - 3) to: self size)!
replaceAll: oldChar with: newChar
	1 to: self size do: [:i | (self at: i) = oldChar ifTrue: [self at: i put: newChar]]! !

!String methodsFor: 'converting'!
asText
	^Text fromString: self!
asByteArray
	| b |
	b := ByteArray new: self size.
	1 to: self size do: [:i | b at: i put: (self at: i) value].
	^b!
asDate
	^Date readFrom: (ReadStream on: self)!
asTime
	^Time readFrom: (ReadStream on: self)!
asLowercase
	^self collect: [:c | c asLowercase]!
trimSeparators
	^self withBlanksTrimmed!
withCRs
	^self collect: [:c | c = $\ ifTrue: [Character cr] ifFalse: [c]]!
occurrencesOfString: aString
	| n i |
	n := 0. i := 1.
	[i + aString size - 1 <= self size] whileTrue: [
		(self copyFrom: i to: i + aString size - 1) = aString ifTrue: [n := n + 1. i := i + aString size] ifFalse: [i := i + 1]].
	^n! !

!String class methodsFor: 'instance creation'!
new: n withAll: aCharacter
	^(self new: n) atAllPut: aCharacter; yourself!
with: aCharacter
	^(self new: 1) at: 1 put: aCharacter; yourself!
with: c1 with: c2
	^(self new: 2) at: 1 put: c1; at: 2 put: c2; yourself!
with: c1 with: c2 with: c3
	^(self new: 3) at: 1 put: c1; at: 2 put: c2; at: 3 put: c3; yourself!
fromString: aString
	^aString asString copy!
crlf
	^self with: (Character value: 13) with: Character cr! !

!Array methodsFor: 'storing'!
storeOn: aStream
	aStream nextPutAll: '((Array new: '; print: self size; nextPut: $).
	self doWithIndex: [:e :i | aStream nextPutAll: ' at: '; print: i; nextPutAll: ' put: '; store: e; nextPut: $;].
	aStream nextPutAll: ' yourself)'! !

!Array methodsFor: 'testing'!
isLiteral
	^self allSatisfy: [:e | e isNil or: [e isNumber or: [e isString or: [e isSymbol or: [e isCharacter or: [e isArray and: [e isLiteral]]]]]]]! !

!Collection methodsFor: 'storing'!
storeOn: aStream
	aStream nextPutAll: '(('; nextPutAll: self class name; nextPutAll: ' new)'.
	self do: [:e | aStream nextPutAll: ' add: '; store: e; nextPut: $;].
	aStream nextPutAll: ' yourself)'! !

!Collection methodsFor: 'enumerating'!
detectMax: aBlock
	| best bestValue |
	self do: [:e | | v | v := aBlock value: e. (best isNil or: [v > bestValue]) ifTrue: [best := e. bestValue := v]].
	^best!
detectMin: aBlock
	| best bestValue |
	self do: [:e | | v | v := aBlock value: e. (best isNil or: [v < bestValue]) ifTrue: [best := e. bestValue := v]].
	^best!
detectSum: aBlock
	^self inject: 0 into: [:a :e | a + (aBlock value: e)]!
collect: collectBlock into: aCollection
	self do: [:e | aCollection add: (collectBlock value: e)].
	^aCollection! !

!Collection methodsFor: 'testing'!
isSequenceable
	^false!
includesAll: aCollection
	^aCollection allSatisfy: [:e | self includes: e]!
includesAny: aCollection
	^aCollection anySatisfy: [:e | self includes: e]! !

!SequenceableCollection methodsFor: 'testing'!
isSequenceable
	^true! !

!SequenceableCollection methodsFor: 'copying'!
copyEmpty: n
	"a new collection of my species able to hold n elements via at:put: or add:"
	^self species new: n!
collect: aBlock
	| r |
	r := self species new: self size.
	r size = self size
		ifTrue: [1 to: self size do: [:i | r at: i put: (aBlock value: (self at: i))]]
		ifFalse: [self do: [:e | r add: (aBlock value: e)]].
	^r!
with: aCollection collect: aBlock
	| r |
	r := self species new: self size.
	r size = self size
		ifTrue: [1 to: self size do: [:i | r at: i put: (aBlock value: (self at: i) value: (aCollection at: i))]]
		ifFalse: [1 to: self size do: [:i | r add: (aBlock value: (self at: i) value: (aCollection at: i))]].
	^r!
copyFrom: start to: stop
	| r n |
	n := stop - start + 1.
	n < 0 ifTrue: [n := 0].
	r := self species new: n.
	r size = n
		ifTrue: [r replaceFrom: 1 to: n with: self startingAt: start]
		ifFalse: [start to: stop do: [:i | r add: (self at: i)]].
	^r!
copyWith: anObject
	| r |
	r := self species new: self size + 1.
	r size = (self size + 1)
		ifTrue: [r replaceFrom: 1 to: self size with: self startingAt: 1. r at: self size + 1 put: anObject]
		ifFalse: [self do: [:e | r add: e]. r add: anObject].
	^r!
, aCollection
	| r |
	r := self species new: self size + aCollection size.
	r size = (self size + aCollection size)
		ifTrue: [r replaceFrom: 1 to: self size with: self startingAt: 1.
			r replaceFrom: self size + 1 to: self size + aCollection size with: aCollection startingAt: 1]
		ifFalse: [self do: [:e | r add: e]. aCollection do: [:e | r add: e]].
	^r!
reversed
	| r n |
	n := self size.
	r := self species new: n.
	r size = n
		ifTrue: [1 to: n do: [:i | r at: i put: (self at: n + 1 - i)]]
		ifFalse: [self reverseDo: [:e | r add: e]].
	^r!
copyReplaceFrom: start to: stop with: aCollection
	^(self copyFrom: 1 to: start - 1), aCollection, (self copyFrom: stop + 1 to: self size)!
copyReplacing: oldObject with: newObject
	^self collect: [:e | e = oldObject ifTrue: [newObject] ifFalse: [e]]!
allButFirst: n
	^self copyFrom: n + 1 to: self size!
allButLast: n
	^self copyFrom: 1 to: self size - n! !

!SequenceableCollection methodsFor: 'accessing'!
indexOf: anObject startingAt: start
	start to: self size do: [:i | (self at: i) = anObject ifTrue: [^i]].
	^0!
findLast: aBlock
	self size to: 1 by: -1 do: [:i | (aBlock value: (self at: i)) ifTrue: [^i]].
	^0!
atRandom
	^self at: (Random new between: 1 and: self size)!
second
	^self at: 2!
third
	^self at: 3! !

!OrderedCollection methodsFor: 'adding'!
add: newObject before: oldObject
	| i |
	i := self indexOf: oldObject.
	i = 0 ifTrue: [^self error: 'object not found'].
	^self add: newObject beforeIndex: i!
add: newObject after: oldObject
	| i |
	i := self indexOf: oldObject.
	i = 0 ifTrue: [^self error: 'object not found'].
	^self add: newObject beforeIndex: i + 1!
addAllLast: aCollection
	^self addAll: aCollection! !

!OrderedCollection methodsFor: 'removing'!
removeFirst: n
	| r |
	r := OrderedCollection new.
	n timesRepeat: [r addLast: self removeFirst].
	^r!
removeLast: n
	| r |
	r := OrderedCollection new.
	n timesRepeat: [r addFirst: self removeLast].
	^r!
removeAllSuchThat: aBlock
	| r |
	r := self select: aBlock.
	r do: [:e | self remove: e].
	^r! !

!Link class methodsFor: 'instance creation'!
nextLink: aLink
	^self new nextLink: aLink! !

!Link methodsFor: 'accessing'!
nextLink
	^nextLink!
nextLink: aLink
	nextLink := aLink! !

!LinkedList methodsFor: 'accessing'!
first
	self emptyCheck. ^firstLink!
last
	self emptyCheck. ^lastLink!
at: index
	| l |
	l := firstLink.
	index - 1 timesRepeat: [l isNil ifTrue: [^self errorSubscriptBounds: index]. l := l nextLink].
	l isNil ifTrue: [^self errorSubscriptBounds: index].
	^l!
at: index put: aLink
	^self shouldNotImplement!
size
	| n l |
	n := 0. l := firstLink.
	[l isNil] whileFalse: [n := n + 1. l := l nextLink].
	^n!
species
	^OrderedCollection! !

!LinkedList methodsFor: 'testing'!
isEmpty
	^firstLink isNil! !

!LinkedList methodsFor: 'adding'!
add: aLink
	^self addLast: aLink!
addFirst: aLink
	self isEmpty ifTrue: [lastLink := aLink].
	aLink nextLink: firstLink.
	firstLink := aLink.
	^aLink!
addLast: aLink
	self isEmpty ifTrue: [firstLink := aLink] ifFalse: [lastLink nextLink: aLink].
	aLink nextLink: nil.
	lastLink := aLink.
	^aLink! !

!LinkedList methodsFor: 'removing'!
removeFirst
	| l |
	self emptyCheck.
	l := firstLink.
	l == lastLink ifTrue: [firstLink := nil. lastLink := nil] ifFalse: [firstLink := l nextLink].
	l nextLink: nil.
	^l!
removeLast
	| l prev |
	self emptyCheck.
	l := lastLink.
	l == firstLink ifTrue: [firstLink := nil. lastLink := nil] ifFalse: [
		prev := firstLink.
		[prev nextLink == l] whileFalse: [prev := prev nextLink].
		prev nextLink: nil. lastLink := prev].
	l nextLink: nil.
	^l!
remove: aLink ifAbsent: aBlock
	| prev |
	aLink == firstLink ifTrue: [^self removeFirst].
	prev := firstLink.
	[prev notNil and: [prev nextLink ~~ aLink]] whileTrue: [prev := prev nextLink].
	prev isNil ifTrue: [^aBlock value].
	prev nextLink: aLink nextLink.
	aLink == lastLink ifTrue: [lastLink := prev].
	aLink nextLink: nil.
	^aLink!
removeAll
	firstLink := nil. lastLink := nil! !

!LinkedList methodsFor: 'enumerating'!
do: aBlock
	| l next |
	l := firstLink.
	[l isNil] whileFalse: [next := l nextLink. aBlock value: l. l := next]! !

!RunArray class methodsFor: 'instance creation'!
new
	^self basicNew setRuns: (Array new: 0) values: (Array new: 0)!
new: n withAll: anObject
	^self basicNew setRuns: (Array with: n) values: (Array with: anObject)!
runs: runArray values: valueArray
	^self basicNew setRuns: runArray values: valueArray! !

!RunArray methodsFor: 'private'!
setRuns: runArray values: valueArray
	runs := runArray. values := valueArray!
runs
	^runs!
values
	^values! !

!RunArray methodsFor: 'accessing'!
size
	^runs inject: 0 into: [:a :b | a + b]!
at: index
	| pos |
	pos := 0.
	runs doWithIndex: [:n :i | pos := pos + n. index <= pos ifTrue: [^values at: i]].
	^self errorSubscriptBounds: index!
at: index put: anObject
	"rebuild runs so that position index holds anObject"
	| all |
	all := self asArray.
	all at: index put: anObject.
	self setRuns: (Array new: 0) values: (Array new: 0).
	all do: [:e | self addLast: e].
	^anObject!
runLengthAt: index
	| pos |
	pos := 0.
	runs doWithIndex: [:n :i | pos := pos + n. index <= pos ifTrue: [^pos - index + 1]].
	^self errorSubscriptBounds: index!
species
	^Array! !

!RunArray methodsFor: 'adding'!
addLast: anObject
	(values size > 0 and: [values last = anObject])
		ifTrue: [runs at: runs size put: runs last + 1]
		ifFalse: [runs := runs copyWith: 1. values := values copyWith: anObject].
	^anObject!
add: anObject
	^self addLast: anObject! !

!RunArray methodsFor: 'enumerating'!
do: aBlock
	runs doWithIndex: [:n :i | n timesRepeat: [aBlock value: (values at: i)]]!
runsAndValuesDo: aBlock
	runs with: values do: aBlock! !

!RunArray methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'RunArray runs: '; print: runs; nextPutAll: ' values: '; print: values!
storeOn: aStream
	aStream nextPutAll: '(RunArray runs: '; store: runs; nextPutAll: ' values: '; store: values; nextPut: $)! !

!MappedCollection class methodsFor: 'instance creation'!
collection: aCollection map: aMap
	^self basicNew setCollection: aCollection map: aMap! !

!MappedCollection methodsFor: 'private'!
setCollection: aCollection map: aMap
	domain := aCollection. map := aMap! !

!MappedCollection methodsFor: 'accessing'!
at: anIndex
	^domain at: (map at: anIndex)!
at: anIndex put: anObject
	^domain at: (map at: anIndex) put: anObject!
size
	^map size!
contents
	^map collect: [:i | domain at: i]!
add: anObject
	^self shouldNotImplement! !

!MappedCollection methodsFor: 'enumerating'!
do: aBlock
	map do: [:i | aBlock value: (domain at: i)]!
collect: aBlock
	^self contents collect: aBlock!
select: aBlock
	^self contents select: aBlock! !

!Text class methodsFor: 'instance creation'!
fromString: aString
	^self basicNew setString: aString runs: (RunArray new: aString size withAll: 0)!
string: aString runs: aRunArray
	^self basicNew setString: aString runs: aRunArray!
new: n
	^self fromString: (String new: n)! !

!Text methodsFor: 'private'!
setString: aString runs: aRunArray
	string := aString. runs := aRunArray! !

!Text methodsFor: 'accessing'!
string
	^string!
runs
	^runs!
size
	^string size!
at: index
	^string at: index!
at: index put: aCharacter
	^string at: index put: aCharacter!
emphasisAt: index
	^runs at: index!
emphasizeFrom: start to: stop with: emphasis
	start to: stop do: [:i | runs at: i put: emphasis]!
allBold
	self emphasizeFrom: 1 to: self size with: 1! !

!Text methodsFor: 'converting'!
asString
	^string!
asText
	^self!
asSymbol
	^string asSymbol!
asNumber
	^string asNumber!
species
	^String! !

!Text methodsFor: 'copying'!
, aText
	^Text fromString: string, aText asString!
copyFrom: start to: stop
	^Text string: (string copyFrom: start to: stop) runs: (RunArray new: (stop - start + 1 max: 0) withAll: 0)! !

!Text methodsFor: 'comparing'!
= aText
	^(aText isKindOf: Text) and: [string = aText string]!
hash
	^string hash! !

!Text methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a Text for '; print: string!
displayString
	^string! !

!Stream methodsFor: 'accessing'!
next: anInteger
	| r |
	r := OrderedCollection new.
	anInteger timesRepeat: [r add: self next].
	^r asArray!
nextMatchFor: anObject
	^self next = anObject!
skip: anInteger
	anInteger timesRepeat: [self next]!
skipTo: anObject
	[self atEnd] whileFalse: [self next = anObject ifTrue: [^true]].
	^false!
collect: aBlock
	| r |
	r := OrderedCollection new.
	[self atEnd] whileFalse: [r add: (aBlock value: self next)].
	^r!
select: aBlock
	| r |
	r := OrderedCollection new.
	[self atEnd] whileFalse: [| e | e := self next. (aBlock value: e) ifTrue: [r add: e]].
	^r!
space: n
	n timesRepeat: [self space]!
tab: n
	n timesRepeat: [self tab]!
crtab
	self cr; tab!
crtab: n
	self cr; tab: n!
isStream
	^true! !

!Object methodsFor: 'testing'!
isStream
	^false! !

!PositionableStream methodsFor: 'positioning'!
skipTo: anObject
	[self atEnd] whileFalse: [self next = anObject ifTrue: [^true]].
	^false!
peekBack
	^position = 0 ifTrue: [nil] ifFalse: [collection at: position]!
last
	^collection at: position!
copyFrom: start to: stop
	^collection copyFrom: start to: stop!
nextAvailable: n
	| r |
	r := WriteStream on: (collection species new: n).
	n timesRepeat: [self atEnd ifFalse: [r nextPut: self next]].
	^r contents! !

!ReadStream methodsFor: 'accessing'!
next: n
	| r |
	r := collection species new: n.
	1 to: n do: [:i | r at: i put: self next].
	^r! !

!ReadWriteStream class methodsFor: 'instance creation'!
on: aCollection
	^(self basicNew on: aCollection) readLimit: aCollection size; yourself!
with: aCollection
	^(self basicNew on: aCollection) setToEnd; yourself! !

!ReadWriteStream methodsFor: 'accessing'!
readLimit: n
	readLimit := n!
contents
	^collection copyFrom: 1 to: readLimit!
readStream
	^ReadStream on: self contents! !

!FileStream class methodsFor: 'instance creation'!
fileNamed: aString
	"open for reading and writing; created if it does not exist"
	| c |
	c := self primRead: aString.
	^(self basicNew on: (c isNil ifTrue: [String new] ifFalse: [c])) setName: aString; yourself!
oldFileNamed: aString
	| c |
	c := self primRead: aString.
	c isNil ifTrue: [^self error: 'file not found: ', aString].
	^(self basicNew on: c) setName: aString; yourself!
newFileNamed: aString
	^(self basicNew on: String new) setName: aString; markDirty; yourself!
readOnlyFileNamed: aString
	^self oldFileNamed: aString!
isAFileNamed: aString
	^self primExists: aString!
remove: aString
	^self primDelete: aString! !

!FileStream class methodsFor: 'primitives'!
primRead: aString
	<primitive: 170>
	^nil!
primWrite: contents to: aString append: aBoolean
	<primitive: 171>
	^false!
primDelete: aString
	<primitive: 172>
	^false!
primExists: aString
	<primitive: 173>
	^false! !

!FileStream methodsFor: 'private'!
on: aCollection
	super on: aCollection.
	readLimit := aCollection size!
setName: aString
	name := aString. dirty := false!
markDirty
	dirty := true! !

!FileStream methodsFor: 'accessing'!
name
	^name!
nextPut: anObject
	dirty := true.
	^super nextPut: anObject!
nextPutAll: aCollection
	dirty := true.
	^super nextPutAll: aCollection!
contentsOfEntireFile
	^collection copyFrom: 1 to: readLimit!
size
	^readLimit!
fileIn
	^Smalltalk fileInString: self contentsOfEntireFile! !

!FileStream methodsFor: 'file status'!
flush
	dirty ifTrue: [
		(FileStream primWrite: self contentsOfEntireFile to: name append: false) ifFalse: [^self error: 'cannot write ', name].
		dirty := false].
	^self!
close
	^self flush!
isDirty
	^dirty! !

!FileStream methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a FileStream on '; print: name! !

Smalltalk at: #Dependents put: IdentityDictionary new!
