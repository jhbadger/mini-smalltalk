"Mini Smalltalk-80 kernel, part 3: streams, blocks, methods, contexts, Transcript, exceptions"

Object subclass: #Stream instanceVariableNames: '' classVariableNames: '' category: 'Collections-Streams'!
Stream subclass: #PositionableStream instanceVariableNames: 'collection position readLimit' classVariableNames: '' category: 'Collections-Streams'!
PositionableStream subclass: #ReadStream instanceVariableNames: '' classVariableNames: '' category: 'Collections-Streams'!
PositionableStream subclass: #WriteStream instanceVariableNames: '' classVariableNames: '' category: 'Collections-Streams'!
WriteStream subclass: #ReadWriteStream instanceVariableNames: '' classVariableNames: '' category: 'Collections-Streams'!
Stream subclass: #TranscriptStream instanceVariableNames: '' classVariableNames: '' category: 'System-Support'!
Object subclass: #BlockClosure instanceVariableNames: 'outerContext method receiver numArgs' classVariableNames: '' category: 'Kernel-Methods'!
Object subclass: #CompiledMethod instanceVariableNames: 'header literals bytecodes selector methodClass sourceCode primitive category' classVariableNames: '' category: 'Kernel-Methods'!
Object variableSubclass: #Context instanceVariableNames: 'sender pc stackp method receiver home outer closure' classVariableNames: '' category: 'Kernel-Methods'!
Object subclass: #Exception instanceVariableNames: 'messageText' classVariableNames: '' category: 'Kernel-Exceptions'!
Exception subclass: #Error instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Exceptions'!
Object subclass: #Compiler instanceVariableNames: '' classVariableNames: '' category: 'System-Compiler'!
Object subclass: #Random instanceVariableNames: 'seed' classVariableNames: '' category: 'Kernel-Numbers'!

!Stream methodsFor: 'accessing'!
next
	^self subclassResponsibility!
nextPut: anObject
	^self subclassResponsibility!
nextPutAll: aCollection
	aCollection do: [:e | self nextPut: e].
	^aCollection!
print: anObject
	anObject printOn: self!
display: anObject
	self nextPutAll: anObject displayString!
<< anObject
	anObject isString ifTrue: [self nextPutAll: anObject] ifFalse: [self print: anObject]!
space
	self nextPut: Character space!
tab
	self nextPut: Character tab!
cr
	self nextPut: Character cr!
nl
	self nextPut: Character cr!
atEnd
	^self subclassResponsibility!
do: aBlock
	[self atEnd] whileFalse: [aBlock value: self next]!
contents
	^self subclassResponsibility! !

!PositionableStream class methodsFor: 'instance creation'!
on: aCollection
	^self basicNew on: aCollection! !

!PositionableStream methodsFor: 'accessing'!
on: aCollection
	collection := aCollection. position := 0. readLimit := aCollection size!
position
	^position!
position: anInteger
	position := anInteger!
reset
	position := 0!
setToEnd
	position := readLimit!
skip: n
	position := (position + n max: 0) min: readLimit!
atEnd
	^position >= readLimit!
isEmpty
	^readLimit = 0!
size
	^readLimit!
collection
	^collection!
contents
	^collection copyFrom: 1 to: readLimit! !

!ReadStream methodsFor: 'accessing'!
next
	position >= readLimit ifTrue: [^nil].
	position := position + 1.
	^collection at: position!
next: n
	| r |
	r := collection species new: n.
	1 to: n do: [:i | r at: i put: self next].
	^r!
peek
	position >= readLimit ifTrue: [^nil].
	^collection at: position + 1!
peekFor: anObject
	self peek = anObject ifTrue: [self next. ^true].
	^false!
upTo: anObject
	| s e |
	s := WriteStream on: (collection species new: 16).
	[self atEnd or: [(e := self next) = anObject]] whileFalse: [s nextPut: e].
	^s contents!
upToEnd
	| r |
	r := collection copyFrom: position + 1 to: readLimit.
	position := readLimit.
	^r!
skipSeparators
	[self atEnd not and: [self peek isSeparator]] whileTrue: [self next]!
nextLine
	^self upTo: Character cr! !

!WriteStream class methodsFor: 'instance creation'!
on: aCollection
	^self basicNew on: aCollection!
with: aCollection
	^(self basicNew on: aCollection) setToEnd; yourself! !

!WriteStream methodsFor: 'accessing'!
on: aCollection
	collection := aCollection. position := 0. readLimit := 0!
setToEnd
	position := collection size. readLimit := position!
nextPut: anObject
	position >= collection size ifTrue: [self grow].
	position := position + 1.
	collection at: position put: anObject.
	position > readLimit ifTrue: [readLimit := position].
	^anObject!
nextPutAll: aCollection
	| n |
	n := aCollection size.
	[position + n > collection size] whileTrue: [self grow].
	collection replaceFrom: position + 1 to: position + n with: aCollection startingAt: 1.
	position := position + n.
	position > readLimit ifTrue: [readLimit := position].
	^aCollection!
grow
	| c |
	c := collection species new: collection size * 2 + 16.
	c replaceFrom: 1 to: collection size with: collection startingAt: 1.
	collection := c!
contents
	^collection copyFrom: 1 to: readLimit!
reset
	position := 0. readLimit := 0! !

!ReadWriteStream methodsFor: 'accessing'!
next
	position >= readLimit ifTrue: [^nil].
	position := position + 1.
	^collection at: position!
peek
	position >= readLimit ifTrue: [^nil].
	^collection at: position + 1! !

!TranscriptStream methodsFor: 'accessing'!
show: anObject
	^self primShow: anObject displayString!
primShow: aString
	<primitive: 110>
	^self!
cr
	<primitive: 111>
	^self!
nl
	^self cr!
showCr: anObject
	self show: anObject; cr!
display: anObject
	self show: anObject displayString!
print: anObject
	self show: anObject printString!
nextPut: aCharacter
	self primShow: (String with: aCharacter)!
nextPutAll: aString
	self primShow: aString asString!
space
	self primShow: ' '!
tab
	self primShow: (String with: Character tab)!
flush
	^self!
endEntry
	^self!
clear
	^self!
atEnd
	^true!
contents
	^''!
next
	^nil! !

!BlockClosure methodsFor: 'evaluating'!
value
	<primitive: 80>
	^self numArgsError: 0!
value: a
	<primitive: 80>
	^self numArgsError: 1!
value: a value: b
	<primitive: 80>
	^self numArgsError: 2!
value: a value: b value: c
	<primitive: 80>
	^self numArgsError: 3!
value: a value: b value: c value: d
	<primitive: 80>
	^self numArgsError: 4!
valueWithArguments: anArray
	<primitive: 81>
	^self numArgsError: anArray size!
numArgsError: n
	^self error: 'block expects ', numArgs printString, ' arguments but was given ', n printString!
numArgs
	^numArgs!
receiver
	^receiver!
method
	^method!
outerContext
	^outerContext! !

!BlockClosure methodsFor: 'controlling'!
whileTrue: aBlock
	[self value] whileTrue: [aBlock value]!
whileFalse: aBlock
	[self value] whileFalse: [aBlock value]!
whileTrue
	[self value] whileTrue!
whileFalse
	[self value] whileFalse!
repeat
	[true] whileTrue: [self value]!
ensure: aBlock
	| r |
	r := self value.
	aBlock value.
	^r!
ifCurtailed: aBlock
	^self value!
on: anExceptionClass do: aBlock
	^self value!
valueWithExit
	^self value: [^nil]! !

!BlockClosure methodsFor: 'testing'!
isBlock
	^true! !

!BlockClosure methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a BlockClosure'! !

!CompiledMethod methodsFor: 'accessing'!
selector
	^selector!
methodClass
	^methodClass!
sourceCode
	^sourceCode!
sourceString
	^sourceCode!
literals
	^literals!
bytecodes
	^bytecodes!
category
	^category!
category: aString
	category := aString!
primitive
	^primitive!
numArgs
	^header bitAnd: 255!
numTemps
	^(header bitShift: -8) bitAnd: 255! !

!CompiledMethod methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: methodClass name; nextPutAll: '>>'; nextPutAll: (selector isNil ifTrue: ['[]'] ifFalse: [selector])! !

!Context methodsFor: 'accessing'!
sender
	^sender!
receiver
	^receiver!
method
	^method!
home
	^home!
pc
	^pc!
isBlockContext
	^home notNil!
selector
	^home isNil ifTrue: [method selector] ifFalse: [home method selector]!
methodClass
	^method methodClass! !

!Context methodsFor: 'printing'!
printOn: aStream
	home notNil ifTrue: [aStream nextPutAll: '[] in '].
	aStream nextPutAll: receiver class name.
	receiver class == method methodClass ifFalse: [aStream nextPut: $(; nextPutAll: method methodClass name; nextPut: $)].
	aStream nextPutAll: '>>'; nextPutAll: (self selector ifNil: ['?'])!
backtrace
	| s c |
	s := WriteStream on: String new. c := self.
	[c notNil] whileTrue: [s print: c; cr. c := c sender].
	^s contents! !

!Exception class methodsFor: 'signalling'!
signal
	^self new signal!
signal: aString
	^self new signal: aString!
new
	^self basicNew messageText: 'An exception has occurred'! !

!Exception methodsFor: 'signalling'!
signal
	^self error: messageText!
signal: aString
	messageText := aString.
	^self error: aString!
messageText
	^messageText!
messageText: aString
	messageText := aString!
description
	^messageText! !

!Compiler class methodsFor: 'evaluating'!
evaluate: aString
	^nil evaluate: aString!
fileIn: aString
	^Smalltalk fileInString: aString! !

!Random class methodsFor: 'instance creation'!
new
	^self basicNew setSeed: Time millisecondClock!
seed: anInteger
	^self basicNew setSeed: anInteger! !

!Random methodsFor: 'accessing'!
setSeed: anInteger
	seed := anInteger \\ 2147483647.
	seed = 0 ifTrue: [seed := 42]!
next
	"Park-Miller minimal standard generator; answers a Float in [0, 1)"
	seed := seed * 16807 \\ 2147483647.
	^seed asFloat / 2147483647.0!
between: low and: high
	^low + (self next * (high - low + 1)) truncated!
nextInt: n
	^self between: 1 and: n! !

!Object methodsFor: 'evaluating'!
evaluate: aString
	^self evaluateString: aString!
evaluateString: aString
	<primitive: 120>
	^self error: 'evaluation failed'! !

Transcript := TranscriptStream new!
