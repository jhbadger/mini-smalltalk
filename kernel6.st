"Mini Smalltalk-80 kernel, part 6: processes, semaphores, delays, shared queues; class organization and reflection"

Object subclass: #ProcessorScheduler instanceVariableNames: 'quiescentProcessLists activeProcess' classVariableNames: '' category: 'Kernel-Processes'!
Link subclass: #Process instanceVariableNames: 'suspendedContext priority myList name' classVariableNames: '' category: 'Kernel-Processes'!
LinkedList subclass: #Semaphore instanceVariableNames: 'excessSignals' classVariableNames: '' category: 'Kernel-Processes'!
Object subclass: #Delay instanceVariableNames: 'delayDuration resumptionTime' classVariableNames: '' category: 'Kernel-Processes'!
Object subclass: #SharedQueue instanceVariableNames: 'contents accessProtect readSynch' classVariableNames: '' category: 'Kernel-Processes'!
Object subclass: #ClassOrganizer instanceVariableNames: 'subject' classVariableNames: '' category: 'Kernel-Classes'!

!ProcessorScheduler methodsFor: 'accessing'!
activeProcess
	^activeProcess!
activePriority
	^activeProcess priority!
quiescentProcessLists
	^quiescentProcessLists!
highestPriority
	^quiescentProcessLists size! !

!ProcessorScheduler methodsFor: 'priority names'!
systemBackgroundPriority
	^1!
userBackgroundPriority
	^3!
userSchedulingPriority
	^4!
userInterruptPriority
	^5!
lowIOPriority
	^6!
highIOPriority
	^7!
timingPriority
	^8! !

!ProcessorScheduler methodsFor: 'process state change'!
yield
	"give other processes at my priority a chance to run"
	<primitive: 144>
	^self!
terminateActive
	^activeProcess terminate!
sleep
	^self yield! !

!ProcessorScheduler methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'Processor'! !

!Process methodsFor: 'accessing'!
priority
	^priority!
priority: anInteger
	(anInteger between: 1 and: Processor highestPriority) ifFalse: [^self error: 'priority out of range'].
	priority := anInteger!
suspendedContext
	^suspendedContext!
name
	^name!
name: aString
	name := aString!
myList
	^myList! !

!Process methodsFor: 'changing process state'!
resume
	"make the receiver runnable"
	<primitive: 141>
	^self error: 'cannot resume this process'!
suspend
	<primitive: 142>
	^self error: 'cannot suspend this process'!
terminate
	<primitive: 143>
	^self error: 'cannot terminate this process'! !

!Process methodsFor: 'testing'!
isTerminated
	^suspendedContext isNil and: [self ~~ Processor activeProcess]!
isSuspended
	^suspendedContext notNil and: [myList isNil and: [self ~~ Processor activeProcess]]!
isWaiting
	^myList notNil and: [myList isKindOf: Semaphore]!
isActive
	^self == Processor activeProcess! !

!Process methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a Process'.
	name notNil ifTrue: [aStream nextPutAll: ' named '; print: name].
	aStream nextPutAll: ' at priority '; print: priority.
	self isTerminated ifTrue: [aStream nextPutAll: ' (terminated)'].
	self isActive ifTrue: [aStream nextPutAll: ' (active)'].
	(suspendedContext notNil and: [self isActive not]) ifTrue: [aStream nextPutAll: ' in '; print: suspendedContext]! !

!BlockClosure methodsFor: 'scheduling'!
newProcess
	"a suspended Process that will evaluate the receiver"
	<primitive: 140>
	^self error: 'only zero-argument blocks can become processes'!
newProcessWith: anArray
	^[self valueWithArguments: anArray] newProcess!
fork
	^self newProcess resume!
forkAt: priority
	| p |
	p := self newProcess.
	p priority: priority.
	^p resume!
forkNamed: aString
	| p |
	p := self newProcess.
	p name: aString.
	^p resume!
valueUnpreemptively
	^self value! !

!Semaphore class methodsFor: 'instance creation'!
new
	^self basicNew initSignals!
forMutualExclusion
	^self new signal; yourself! !

!Semaphore methodsFor: 'private'!
initSignals
	excessSignals := 0! !

!Semaphore methodsFor: 'communication'!
signal
	"wake one waiting process, or remember the signal"
	<primitive: 146>
	^self error: 'signal failed'!
wait
	"block until signalled"
	<primitive: 145>
	^self error: 'wait failed'!
critical: aBlock
	| r |
	self wait.
	r := aBlock value.
	self signal.
	^r!
excessSignals
	^excessSignals!
isEmpty
	^firstLink isNil!
terminateProcess
	self isEmpty ifFalse: [self removeFirst terminate]! !

!Semaphore methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a Semaphore with '; print: excessSignals; nextPutAll: ' excess signals and '; print: self size; nextPutAll: ' waiting'! !

!Delay class methodsFor: 'instance creation'!
forMilliseconds: anInteger
	^self basicNew setDelay: anInteger!
forSeconds: aNumber
	^self basicNew setDelay: (aNumber * 1000) rounded!
untilMilliseconds: millisecondClockValue
	^self basicNew setDelay: (millisecondClockValue - Time millisecondClock max: 0)! !

!Delay methodsFor: 'private'!
setDelay: ms
	delayDuration := ms!
primWait: ms
	<primitive: 148>
	^self error: 'wait failed'! !

!Delay methodsFor: 'accessing'!
delayDuration
	^delayDuration!
resumptionTime
	^resumptionTime! !

!Delay methodsFor: 'delaying'!
wait
	"suspend the active process for the delay's duration"
	resumptionTime := Time millisecondClock + delayDuration.
	^self primWait: delayDuration! !

!Delay methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a Delay of '; print: delayDuration; nextPutAll: ' ms'! !

!SharedQueue class methodsFor: 'instance creation'!
new
	^self basicNew init!
new: n
	^self new! !

!SharedQueue methodsFor: 'private'!
init
	contents := OrderedCollection new.
	accessProtect := Semaphore forMutualExclusion.
	readSynch := Semaphore new! !

!SharedQueue methodsFor: 'accessing'!
next
	"the next object in the queue, blocking until one is available"
	| v |
	readSynch wait.
	accessProtect critical: [v := contents removeFirst].
	^v!
nextPut: anObject
	accessProtect critical: [contents addLast: anObject].
	readSynch signal.
	^anObject!
peek
	^accessProtect critical: [contents isEmpty ifTrue: [nil] ifFalse: [contents first]]!
isEmpty
	^contents isEmpty!
size
	^contents size! !

!SharedQueue methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a SharedQueue with '; print: contents size; nextPutAll: ' items'! !

!ClassOrganizer class methodsFor: 'instance creation'!
on: aClass
	^self new setSubject: aClass! !

!ClassOrganizer methodsFor: 'private'!
setSubject: aClass
	subject := aClass! !

!ClassOrganizer methodsFor: 'accessing'!
subject
	^subject!
categories
	| cats |
	cats := Set new.
	subject selectors do: [:s | cats add: (subject compiledMethodAt: s) category].
	^cats asSortedCollection asArray!
listAtCategoryNamed: aString
	^(subject selectors select: [:s | (subject compiledMethodAt: s) category = aString]) asSortedCollection asArray!
categoryOfElement: aSelector
	^(subject compiledMethodAt: aSelector) category!
classify: aSelector under: aString
	(subject compiledMethodAt: aSelector) category: aString!
allElements
	^subject selectors asSortedCollection asArray!
removeElement: aSelector
	^self!
printOn: aStream
	aStream nextPutAll: 'a ClassOrganizer for '; print: subject! !

!Behavior methodsFor: 'accessing instances'!
allInstances
	"an Array of all current instances"
	<primitive: 160>
	^#()!
instanceCount
	^self allInstances size!
someInstance
	^self allInstances isEmpty ifTrue: [nil] ifFalse: [self allInstances first]!
allInstancesDo: aBlock
	self allInstances do: aBlock! !

!Behavior methodsFor: 'accessing method dictionary'!
allSelectors
	| all |
	all := Set new.
	self withAllSuperclasses do: [:c | all addAll: c selectors].
	^all!
selectorsDo: aBlock
	self selectors do: aBlock!
whichSelectorsReferTo: anObject
	^(self selectors select: [:s | (self compiledMethodAt: s) referencesLiteral: anObject]) asSortedCollection asArray!
whichSelectorsAccess: instVarName
	"approximation: methods whose source mentions the variable"
	^(self selectors select: [:s | (self compiledMethodAt: s) sourceCode includesSubstring: instVarName]) asSortedCollection asArray!
scopeHas: varName ifTrue: aBlock
	(self allInstVarNames includes: varName) ifTrue: [^aBlock value].
	^nil! !

!Behavior methodsFor: 'testing class hierarchy'!
isPointers
	^self isBytes not!
isBits
	^self isBytes!
isFixed
	^self isVariable not!
kindOfSubclass
	self isBytes ifTrue: [^'variableByteSubclass:'].
	self isVariable ifTrue: [^'variableSubclass:'].
	^'subclass:'!
inheritsFrom: aClass
	| c |
	c := superclass.
	[c isNil] whileFalse: [c == aClass ifTrue: [^true]. c := c superclass].
	^false! !

!Behavior methodsFor: 'printing'!
printHierarchy
	"a String showing the receiver and all its subclasses, indented"
	| s |
	s := WriteStream on: String new.
	self printSubclassesOn: s level: 0.
	^s contents!
printSubclassesOn: aStream level: level
	level timesRepeat: [aStream tab].
	aStream nextPutAll: self name.
	self instanceVariableNames isEmpty ifFalse: [aStream nextPutAll: ' ('. self instanceVariableNames do: [:v | aStream nextPutAll: v] separatedBy: [aStream space]. aStream nextPut: $)].
	aStream cr.
	(self subclasses asSortedCollection: [:a :b | a name <= b name]) do: [:c | c printSubclassesOn: aStream level: level + 1]!
instanceVariableNames
	^#()!
storeOn: aStream
	aStream nextPutAll: self name! !

!ClassDescription methodsFor: 'organization'!
organization
	^ClassOrganizer on: self!
whichCategoryIncludesSelector: aSelector
	^(self compiledMethodAt: aSelector) category!
category: aSymbol
	^self!
removeCategory: aString
	(self organization listAtCategoryNamed: aString) do: [:s | self removeSelector: s]! !

!Class methodsFor: 'class name'!
rename: aString
	| old |
	old := name.
	Smalltalk removeKey: old.
	name := aString asSymbol.
	Smalltalk at: name put: self!
classVariableNames
	^self classVarNames!
removeClassVarName: aString
	classPool removeKey: aString asSymbol ifAbsent: [self error: 'no such class variable']!
instanceVariableNames: aString
	"redefine the receiver with new instance variables"
	superclass subclass: name instanceVariableNames: aString classVariableNames: '' category: category.
	^self!
sharedPools
	^#()! !

!CompiledMethod methodsFor: 'literals'!
referencesLiteral: anObject
	literals do: [:l |
		l == anObject ifTrue: [^true].
		l = anObject ifTrue: [^true].
		((l isKindOf: Association) and: [l key == anObject or: [l value == anObject]]) ifTrue: [^true].
		((l isKindOf: CompiledMethod) and: [l referencesLiteral: anObject]) ifTrue: [^true]].
	^false!
sendsSelector: aSymbol
	^self referencesLiteral: aSymbol!
messages
	"the selectors sent by this method"
	| s |
	s := Set new.
	self literalsDo: [:l | (l isSymbol and: [l ~~ selector]) ifTrue: [s add: l]].
	^s!
literalsDo: aBlock
	literals do: [:l | aBlock value: l. (l isKindOf: CompiledMethod) ifTrue: [l literalsDo: aBlock]]!
allLiterals
	| r |
	r := OrderedCollection new.
	self literalsDo: [:l | r add: l].
	^r!
isQuick
	^primitive ~= 0! !

!CompiledMethod methodsFor: 'printing'!
storeOn: aStream
	aStream nextPut: $(; nextPutAll: methodClass name; nextPutAll: ' compiledMethodAt: '; store: selector; nextPut: $)!
displayString
	^self printString! !
