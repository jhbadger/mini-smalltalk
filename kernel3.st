"Mini Smalltalk-80 kernel, part 3: streams, blocks, methods, contexts, Transcript, exceptions"

Object subclass: #Stream instanceVariableNames: '' classVariableNames: '' category: 'Collections-Streams'!
Stream subclass: #PositionableStream instanceVariableNames: 'collection position readLimit' classVariableNames: '' category: 'Collections-Streams'!
PositionableStream subclass: #ReadStream instanceVariableNames: '' classVariableNames: '' category: 'Collections-Streams'!
PositionableStream subclass: #WriteStream instanceVariableNames: '' classVariableNames: '' category: 'Collections-Streams'!
WriteStream subclass: #ReadWriteStream instanceVariableNames: '' classVariableNames: '' category: 'Collections-Streams'!
Stream subclass: #TranscriptStream instanceVariableNames: '' classVariableNames: '' category: 'System-Support'!
Object subclass: #BlockClosure instanceVariableNames: 'outerContext method receiver numArgs' classVariableNames: '' category: 'Kernel-Methods'!
Object subclass: #CompiledMethod instanceVariableNames: 'header literals bytecodes selector methodClass sourceCode primitive category tempNames sourceMap' classVariableNames: '' category: 'Kernel-Methods'!
Object variableSubclass: #ContextPart instanceVariableNames: 'sender pc stackp method receiver home outer closure' classVariableNames: '' category: 'Kernel-Methods'!
ContextPart variableSubclass: #MethodContext instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Methods'!
ContextPart variableSubclass: #BlockContext instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Methods'!
Object subclass: #Exception instanceVariableNames: 'messageText signalContext handlerContext resumeBlock disabled' classVariableNames: '' category: 'Kernel-Exceptions'!
Exception subclass: #Error instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Exceptions'!
Exception subclass: #Notification instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Exceptions'!
Notification subclass: #Warning instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Exceptions'!
Error subclass: #ArithmeticError instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Exceptions'!
ArithmeticError subclass: #ZeroDivide instanceVariableNames: 'dividend' classVariableNames: '' category: 'Kernel-Exceptions'!
Error subclass: #MessageNotUnderstood instanceVariableNames: 'message receiver' classVariableNames: '' category: 'Kernel-Exceptions'!
Error subclass: #SubscriptOutOfBounds instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Exceptions'!
Error subclass: #KeyNotFound instanceVariableNames: 'key' classVariableNames: '' category: 'Kernel-Exceptions'!
Object subclass: #ExceptionSet instanceVariableNames: 'classes' classVariableNames: '' category: 'Kernel-Exceptions'!
Object subclass: #ExceptionRetry instanceVariableNames: 'block' classVariableNames: '' category: 'Kernel-Exceptions'!
Object subclass: #Compiler instanceVariableNames: '' classVariableNames: '' category: 'System-Compiler'!
Stream subclass: #Random instanceVariableNames: 'seed' classVariableNames: '' category: 'Kernel-Numbers'!

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
store: anObject
	anObject storeOn: self!
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
	^collection at: position + 1!
reset
	position := 0! !

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
	"Evaluate the receiver, then aBlock -- also when the receiver is left by a ^, an exception return or an error.
	The VM finds this frame by its selector and runs aBlock (temp 1) unless the flag (temp 2) says it already has."
	| complete result |
	complete := false.
	result := self value.
	complete := true.
	aBlock value.
	^result!
ifCurtailed: aBlock
	"Evaluate the receiver; aBlock runs only if the receiver is left without completing."
	| complete result |
	complete := false.
	result := self value.
	complete := true.
	^result!
on: exceptionSelector do: handlerBlock
	"Evaluate the receiver; an exception matching exceptionSelector (an Exception class or an ExceptionSet) signalled
	while it runs is given to handlerBlock. Falling off the end of the handler returns its value from here."
	| block result |
	block := self.
	[result := block primOn: exceptionSelector do: handlerBlock.
	 result class == ExceptionRetry] whileTrue: [result block notNil ifTrue: [block := result block]].
	^result!
on: selector1 do: handler1 on: selector2 do: handler2
	^[self on: selector1 do: handler1] on: selector2 do: handler2!
primOn: exceptionSelector do: handlerBlock
	"The marker frame that Exception>>signal looks for. Its temps are read through ContextPart>>handlerSelector etc."
	| active unwindBlock |
	active := true.
	unwindBlock := [:value | ^value].
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
	^(header bitShift: -8) bitAnd: 255!
tempNames
	"the names of the arguments and temporaries, in the order they are stored in a context"
	^tempNames ifNil: [Array new]!
sourceMap
	"pc, source offset, pc, source offset ... one pair for each statement, in increasing pc order"
	^sourceMap ifNil: [Array new]!
sourceOffsetForPC: aPC
	"where in sourceCode the statement being run at aPC begins, or nil"
	| map best |
	map := self sourceMap.
	best := nil.
	1 to: map size by: 2 do: [:i | (map at: i) < aPC ifTrue: [best := map at: i + 1]].
	^best ifNil: [map isEmpty ifTrue: [nil] ifFalse: [map at: 2]]!
lineForPC: aPC
	"the 1-based line of sourceCode being run at aPC, or nil"
	| off line |
	off := self sourceOffsetForPC: aPC.
	(off isNil or: [sourceCode isNil]) ifTrue: [^nil].
	line := 1.
	1 to: (off min: sourceCode size) do: [:i | (sourceCode at: i) = Character lf ifTrue: [line := line + 1]].
	^line! !

!CompiledMethod methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: methodClass name; nextPutAll: '>>'; nextPutAll: (selector isNil ifTrue: ['[]'] ifFalse: [selector])! !

!ContextPart methodsFor: 'accessing'!
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
stackPointer
	^stackp!
isBlockContext
	^home notNil!
selector
	^home isNil ifTrue: [method selector] ifFalse: [home method selector]!
methodClass
	^method methodClass!
tempAt: index
	^self basicAt: index!
tempAt: index put: value
	^self basicAt: index put: value!
numTemps
	^method numTemps!
parentContext
	^sender!
outerContext
	^outer!
isDead
	"true once the context has returned or been unwound"
	^pc < 0!
stackDepth
	| n c |
	n := 0. c := self.
	[c notNil] whileTrue: [n := n + 1. c := c sender].
	^n!
stack
	"the receiver and all the contexts below it, innermost first"
	| r c |
	r := OrderedCollection new. c := self.
	[c notNil] whileTrue: [r add: c. c := c sender].
	^r!
findContextSuchThat: aBlock
	| c |
	c := self.
	[c notNil] whileTrue: [(aBlock value: c) ifTrue: [^c]. c := c sender].
	^nil! !

!ContextPart methodsFor: 'controlling'!
primResume: value
	"Abandon the running contexts and continue the receiver with value as the answer of the send it is suspended in.
	Fails unless the receiver is a live context lower down in the active process's stack."
	<primitive: 149>
	^self error: 'cannot resume this context'!
runUnwindBlocksDownTo: aContext
	"run, innermost first, the ensure: and ifCurtailed: blocks of the frames between the active context and aContext"
	| c |
	c := thisContext sender.
	[c notNil and: [c ~~ aContext]] whileTrue: [
		(c isUnwindContext and: [(c tempAt: 2) ~~ true]) ifTrue: [c tempAt: 2 put: true. (c tempAt: 1) value].
		c := c sender]!
resume: value
	"Unwind back to the receiver (running ensure: blocks on the way) and continue it with value."
	self isDead ifTrue: [^self error: 'cannot resume a dead context'].
	self runUnwindBlocksDownTo: self.
	^self primResume: value!
return: value
	"Return value from the receiver to its sender, as if the receiver had executed ^value."
	sender isNil ifTrue: [^self error: 'cannot return from the bottom context'].
	^sender resume: value! !

!ContextPart methodsFor: 'exception support'!
isUnwindContext
	^home isNil and: [(method selector == #ensure: or: [method selector == #ifCurtailed:]) and: [receiver class == BlockClosure]]!
isHandlerContext
	^home isNil and: [method selector == #primOn:do: and: [receiver class == BlockClosure]]!
handlerSelector
	^self tempAt: 1!
handlerBlock
	^self tempAt: 2!
handlerActive
	^(self tempAt: 3) == true!
handlerActive: aBoolean
	self tempAt: 3 put: aBoolean!
handlerUnwindBlock
	^self tempAt: 4! !

!ContextPart methodsFor: 'printing'!
printOn: aStream
	home notNil ifTrue: [aStream nextPutAll: '[] in '].
	aStream nextPutAll: receiver class name.
	receiver class == method methodClass ifFalse: [aStream nextPut: $(; nextPutAll: method methodClass name; nextPut: $)].
	aStream nextPutAll: '>>'; nextPutAll: (self selector ifNil: ['?'])!
backtrace
	| s c |
	s := WriteStream on: String new. c := self.
	[c notNil] whileTrue: [s print: c; cr. c := c sender].
	^s contents!
shortStack
	^self backtrace! !

!MethodContext methodsFor: 'testing'!
isBlockContext
	^false! !

!BlockContext methodsFor: 'testing'!
isBlockContext
	^true! !

!Exception class methodsFor: 'signalling'!
new
	^self basicNew!
signal
	^self new signal!
signal: aString
	^self new signal: aString! !

!Exception class methodsFor: 'exception selector'!
, anExceptionSelector
	"Exception, Exception ... builds an ExceptionSet for on:do:"
	^ExceptionSet new add: self; add: anExceptionSelector; yourself!
handles: anException
	^anException isKindOf: self! !

!Exception methodsFor: 'signalling'!
signal
	"Look down the stack for an enabled #on:do: frame whose exception selector handles the receiver and run its
	handler block on top of the current stack, so that #resume: can come back here. Without a handler, #defaultAction."
	resumeBlock := [:value | ^value].
	signalContext := thisContext.
	disabled := OrderedCollection new.
	^self activateHandlerFrom: thisContext sender!
signal: aString
	messageText := aString.
	^self signal!
activateHandlerFrom: startContext
	| c |
	c := startContext.
	[c notNil] whileTrue: [
		(c isHandlerContext and: [c handlerActive and: [(c handlerSelector respondsTo: #handles:) and: [c handlerSelector handles: self]]])
			ifTrue: [^self runHandler: c].
		c := c sender].
	^self defaultAction!
runHandler: aHandlerContext
	"A handler is disabled while it runs, together with the handlers nested inside it: an exception signalled by the
	handler block is looked for further out."
	| c block result |
	handlerContext := aHandlerContext.
	c := signalContext.
	[c ~~ aHandlerContext] whileTrue: [
		(c isHandlerContext and: [c handlerActive]) ifTrue: [disabled add: c. c handlerActive: false].
		c := c sender].
	disabled add: aHandlerContext.
	aHandlerContext handlerActive: false.
	block := aHandlerContext handlerBlock.
	result := block numArgs = 0 ifTrue: [block value] ifFalse: [block value: self].
	"falling off the end of the handler returns its value from #on:do: -- through the local, because the handler may
	have signalled the receiver again, which replaces handlerContext"
	^aHandlerContext handlerUnwindBlock value: result! !

!Exception methodsFor: 'handling'!
return: value
	"leave #on:do: with value as its answer"
	handlerContext isNil ifTrue: [^self error: 'return: sent outside a handler block'].
	^handlerContext handlerUnwindBlock value: value!
return
	^self return: nil!
retry
	"leave the handler and evaluate the protected block again"
	handlerContext isNil ifTrue: [^self error: 'retry sent outside a handler block'].
	^handlerContext handlerUnwindBlock value: ExceptionRetry new!
retryUsing: aBlock
	"leave the handler and evaluate aBlock, under the same handler, in place of the protected block"
	handlerContext isNil ifTrue: [^self error: 'retryUsing: sent outside a handler block'].
	^handlerContext handlerUnwindBlock value: (ExceptionRetry new block: aBlock)!
resume: value
	"continue from the #signal that raised the exception, answering value"
	self isResumable ifFalse: [^self error: 'IllegalResumeAttempt: this exception is not resumable'].
	disabled do: [:each | each handlerActive: true].
	^resumeBlock value: value!
resume
	^self resume: nil!
outer
	"signal the exception again, to the handlers further out. If one of them resumes, answer the resumption value."
	| savedHandler savedResume savedDisabled answer |
	savedHandler := handlerContext.
	savedHandler isNil ifTrue: [^self signal].
	savedResume := resumeBlock.
	savedDisabled := disabled.
	disabled := OrderedCollection new.
	resumeBlock := [:value | handlerContext := savedHandler. resumeBlock := savedResume. disabled := savedDisabled. ^value].
	answer := self activateHandlerFrom: savedHandler sender.
	handlerContext := savedHandler. resumeBlock := savedResume. disabled := savedDisabled.
	^answer!
pass
	"hand the exception to the handlers further out, as if this handler did not exist"
	| answer |
	answer := self outer.
	^self isResumable ifTrue: [self resume: answer] ifFalse: [self return: answer]!
signalerContext
	^signalContext!
defaultAction
	"nothing handled the exception: report it, abandoning the evaluation (pending ensure: blocks still run)"
	^nil primError: self messageText! !

!Exception methodsFor: 'accessing'!
isResumable
	^true!
messageText
	^messageText ifNil: [self description]!
messageText: aString
	messageText := aString!
description
	^'An exception has occurred'! !

!Error methodsFor: 'handling'!
isResumable
	^false! !

!Notification methodsFor: 'handling'!
defaultAction
	"an unhandled notification just answers nil"
	^nil! !

!Warning methodsFor: 'handling'!
defaultAction
	"an unhandled warning is noted in the Transcript and execution continues"
	Transcript show: 'Warning: ', self messageText; cr.
	^nil! !

!ArithmeticError methodsFor: 'handling'!
isResumable
	^true! !

!ZeroDivide methodsFor: 'accessing'!
dividend
	^dividend!
dividend: aNumber
	dividend := aNumber!
description
	^'The program attempted to divide a number by zero'! !

!MessageNotUnderstood methodsFor: 'accessing'!
message
	^message!
message: aMessage
	message := aMessage!
receiver
	^receiver!
receiver: anObject
	receiver := anObject!
isResumable
	^true! !

!KeyNotFound methodsFor: 'accessing'!
key
	^key!
key: anObject
	key := anObject! !

!ExceptionSet class methodsFor: 'instance creation'!
new
	^self basicNew setUp! !

!ExceptionSet methodsFor: 'exceptions'!
setUp
	classes := OrderedCollection new!
add: anExceptionSelector
	classes add: anExceptionSelector!
, anExceptionSelector
	^ExceptionSet new add: self; add: anExceptionSelector; yourself!
handles: anException
	classes do: [:each | (each handles: anException) ifTrue: [^true]].
	^false! !

!ExceptionRetry methodsFor: 'accessing'!
block
	^block!
block: aBlock
	block := aBlock! !

!Number methodsFor: 'arithmetic'!
zeroDivide
	^ZeroDivide new dividend: self; signal: 'division by zero'! !

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
	^self between: 1 and: n!
atEnd
	^false!
nextPut: anObject
	^self shouldNotImplement!
contents
	^self shouldNotImplement! !

!Object methodsFor: 'evaluating'!
evaluate: aString
	^self evaluateString: aString!
evaluateString: aString
	<primitive: 120>
	^self error: 'evaluation failed'! !

Transcript := TranscriptStream new!
