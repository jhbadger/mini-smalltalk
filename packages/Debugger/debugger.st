"The debugger: a window on the stack of an error. The frames are listed innermost first; the right pane shows
the source of the selected frame with the statement being run marked, or its variables, and you can evaluate
expressions with self bound to that frame's receiver.

An unhandled error opens it by itself once the package is loaded. It can also be opened on any context:

	Debugger openOn: thisContext message: 'a look around'
	Debugger debug: [1/0]              run a block and open on whatever goes wrong

The stack cannot be resumed: by the time an error reaches the debugger the run has already been abandoned, so
the debugger is for looking, not for continuing. Close the window when you are done."

Object subclass: #Debugger instanceVariableNames: '' classVariableNames: 'Frames Message Mode Selected' category: 'Debugger'!
Object subclass: #DebuggerFrame instanceVariableNames: 'context pc label' classVariableNames: '' category: 'Debugger'!

"---- one frame of the stack ----
The pc is copied when the frame is captured: a handler that unwinds the stack (anything using return: or retry)
marks the frames it leaves as dead, and the debugger is usually looked at after that has happened."

!DebuggerFrame class methodsFor: 'instance creation'!
on: aContext
	^self basicNew setContext: aContext! !

!DebuggerFrame methodsFor: 'accessing'!
setContext: aContext
	context := aContext.
	pc := [aContext pc] on: Error do: [:e | nil].
	label := [aContext printString] on: Error do: [:e | '(a frame that cannot be printed)']!
context
	^context!
pc
	"the program counter as it was when the frame was captured"
	^pc!
label
	^label!
receiver
	^context receiver!
method
	^context method!
home
	^context home!
sender
	^context sender!
isDead
	^context isDead!
inspect
	^context inspect!
printOn: aStream
	aStream nextPutAll: label! !

!Debugger class methodsFor: 'opening'!
openOn: aContext message: aString
	"called by the system when an error is not handled, and usable by hand"
	Message := aString.
	Frames := self framesOf: aContext.
	Mode isNil ifTrue: [Mode := #source].
	Selected := 1.
	Smalltalk openListTool: 'Debugger' title: 'Debugger: ', (aString truncateTo: 60).
	^true!
openOn: aContext
	^self openOn: aContext message: 'inspecting the stack'!
debug: aBlock
	"run the block; if it raises an error, open the debugger on the context that signalled it"
	^[aBlock value]
		on: Error
		do: [:e |
			self openOn: e signalerContext message: (e messageText ifNil: [e class name asString]).
			e return: nil]! !

!Debugger class methodsFor: 'the stack'!
framesOf: aContext
	"the contexts from aContext outwards, leaving out the frames of the exception machinery itself"
	| out c |
	out := OrderedCollection new.
	c := aContext.
	[c notNil and: [out size < 200]] whileTrue: [
		(self isMachineryFrame: c) ifFalse: [out add: (DebuggerFrame on: c)].
		c := c sender].
	out isEmpty ifTrue: [out add: (DebuggerFrame on: aContext)].
	^out asArray!
isMachineryFrame: aContext
	"a frame of Exception or the Debugger: it says nothing about where the error came from"
	| cls |
	aContext method isNil ifTrue: [^false].
	cls := aContext method methodClass.
	cls isNil ifTrue: [^false].
	cls isMeta ifTrue: [cls := cls theNonMetaClass].
	(cls == Object and: [aContext selector == #doesNotUnderstand: or: [aContext selector == #error:]])
		ifTrue: [^true].        "the universal way of raising an error: the message text already says it"
	^(cls == Exception or: [cls inheritsFrom: Exception]) or: [cls == Debugger]!
frames
	^Frames ifNil: [Array new]!
message
	^Message ifNil: ['']!
mode
	^Mode ifNil: [Mode := #source]!
frameAt: anIndex
	^(anIndex between: 1 and: self frames size) ifTrue: [self frames at: anIndex] ifFalse: [nil]!
selectedFrame
	^self frameAt: (Selected ifNil: [1])! !

!Debugger class methodsFor: 'describing a frame'!
sourceOf: aFrame
	"the source of the method the frame is running; for a block, its home method, since that is the text
	its source map refers to"
	| home method |
	home := aFrame home ifNil: [aFrame context].
	method := home method.
	method isNil ifTrue: [^'(no method)'].
	^method sourceCode ifNil: ['(the source of this method was not kept)']!
linesOf: aString
	"the lines of the text, keeping empty ones, so that line numbers agree with the source offsets
	the compiler recorded (String>>lines drops a leading empty line)"
	| out start |
	out := OrderedCollection new.
	start := 1.
	1 to: aString size do: [:i |
		(aString at: i) = Character lf ifTrue: [out add: (aString copyFrom: start to: i - 1). start := i + 1]].
	out add: (aString copyFrom: start to: aString size).
	^out asArray!
markedSourceOf: aFrame
	"the source with a > against the line being run"
	| source line out |
	source := self sourceOf: aFrame.
	line := self lineOf: aFrame.
	line isNil ifTrue: [^source].
	out := WriteStream on: String new.
	(self linesOf: source) doWithIndex: [:l :n |
		out nextPutAll: (n = line ifTrue: ['>  '] ifFalse: ['   ']); nextPutAll: l; nl].
	^out contents!
lineOf: aFrame
	"the line of the displayed source the frame is stopped in; a block reports the line in its home method"
	| method pc offset source line |
	method := aFrame method.
	method isNil ifTrue: [^nil].
	pc := aFrame pc.
	(pc isNil or: [pc isInteger not]) ifTrue: [^nil].
	offset := method sourceOffsetForPC: pc.
	offset isNil ifTrue: [^nil].
	source := self sourceOf: aFrame.
	source isNil ifTrue: [^nil].
	line := 1.
	1 to: (offset min: source size) do: [:i | (source at: i) = Character lf ifTrue: [line := line + 1]].
	^line!
labelOf: aFrame
	^aFrame label!
describeVariablesOf: aFrame
	| out method names count args |
	out := WriteStream on: String new.
	out nextPutAll: aFrame label; nl; nl.
	out nextPutAll: 'self = '; nextPutAll: (self describe: aFrame receiver); nl.
	method := aFrame method.
	method isNil ifTrue: [^out contents].
	names := method tempNames.
	count := method numTemps.
	args := method numArgs.
	count = 0 ifTrue: [out nl; nextPutAll: '(no arguments or temporaries)'; nl. ^out contents].
	out nl.
	1 to: count do: [:i |
		| name value |
		name := i <= names size ifTrue: [(names at: i) asString] ifFalse: ['temp', i printString].
		value := [aFrame context tempAt: i] on: Error do: [:e | nil].
		out nextPutAll: (i <= args ifTrue: ['arg  '] ifFalse: ['temp ']);
			nextPutAll: name; nextPutAll: ' = '; nextPutAll: (self describe: value); nl].
	^out contents!
describe: anObject
	^[anObject printStringLimitedTo: 200] on: Error do: [:e | '<an object that cannot be printed>']! !

!Debugger class methodsFor: 'the list tool'!
listItems
	| out |
	self frames isEmpty ifTrue: [^Array with: '(no stack)'].
	out := OrderedCollection new.
	self frames do: [:f | out add: f label].
	^out asArray!
detailAt: anIndex
	| c |
	Selected := anIndex.
	c := self frameAt: anIndex.
	c isNil ifTrue: [^self header].
	^[self header, (self detailOf: c)] on: Error do: [:e | self header, 'could not describe this frame: ', e messageText]!
header
	| out |
	out := WriteStream on: String new.
	out nextPutAll: self message; nl.
	out nextPutAll: (String new: (self message size min: 78) withAll: $-); nl; nl.
	^out contents!
detailOf: aFrame
	| mode |
	mode := self mode.
	mode == #source ifTrue: [^self markedSourceOf: aFrame].
	mode == #variables ifTrue: [^self describeVariablesOf: aFrame].
	mode == #receiver ifTrue: [^self describeReceiverOf: aFrame].
	mode == #stack ifTrue: [^self fullStack].
	^self markedSourceOf: aFrame!
describeReceiverOf: aFrame
	| out r names |
	out := WriteStream on: String new.
	r := aFrame receiver.
	out nextPutAll: 'self = '; nextPutAll: (self describe: r); nl;
		nextPutAll: 'a '; nextPutAll: r class name asString; nl; nl.
	names := r class allInstVarNames.
	names isEmpty ifTrue: [out nextPutAll: '(no instance variables)'; nl. ^out contents].
	names doWithIndex: [:n :i |
		out nextPutAll: n asString; nextPutAll: ' = ';
			nextPutAll: (self describe: ([r instVarAt: i] on: Error do: [:e | nil])); nl].
	^out contents!
fullStack
	| out |
	out := WriteStream on: String new.
	self frames doWithIndex: [:f :i |
		out print: i; nextPutAll: '. '; nextPutAll: f label.
		(self lineOf: f) notNil ifTrue: [out nextPutAll: '   (line '; print: (self lineOf: f); nextPut: $)].
		out nl].
	^out contents! !

!Debugger class methodsFor: 'the menu'!
commandLabels
	^#('source' 'variables' 'receiver' 'whole stack' '-' 'inspect receiver' 'inspect frame' 'evaluate...' '-' 'copy stack to Transcript')!
command: aCommand at: anIndex
	| label c |
	label := self commandLabels at: aCommand.
	Selected := anIndex.
	c := self frameAt: anIndex.
	label = 'source' ifTrue: [Mode := #source. ^nil].
	label = 'variables' ifTrue: [Mode := #variables. ^nil].
	label = 'receiver' ifTrue: [Mode := #receiver. ^nil].
	label = 'whole stack' ifTrue: [Mode := #stack. ^nil].
	label = 'inspect receiver' ifTrue: [c isNil ifTrue: [^'select a frame first']. c receiver inspect. ^nil].
	label = 'inspect frame' ifTrue: [c isNil ifTrue: [^'select a frame first']. c context inspect. ^nil].
	label = 'evaluate...' ifTrue: [^self evaluateIn: c].
	label = 'copy stack to Transcript' ifTrue: [Transcript showCr: self message; showCr: self fullStack. ^'copied to the Transcript'].
	^nil!
evaluateIn: aFrame
	"evaluate an expression with self bound to the frame's receiver, so instance variables are in scope"
	| source answer |
	aFrame isNil ifTrue: [^'select a frame first'].
	source := Smalltalk promptFor: 'Evaluate with self = ', (self describe: aFrame receiver) default: 'self'.
	(source isNil or: [source trimBoth isEmpty]) ifTrue: [^nil].
	answer := [aFrame receiver evaluateSafely: source]
		on: Error
		do: [:e | ^source, (String with: Character lf), '  ==> error: ', (e messageText ifNil: [e class name asString])].
	(answer at: 1) ifFalse: [^source, (String with: Character lf), '  ==> syntax error: ', (answer at: 2)].
	^source, (String with: Character lf), '  ==> ', (self describe: (answer at: 2))! !

!Debugger class methodsFor: 'temporaries'!
tempNamed: aName
	"the value of a temporary of the selected frame, for use in evaluate..."
	^self tempNamed: aName in: self selectedFrame!
tempNamed: aName in: aContext
	| method names |
	aContext isNil ifTrue: [^nil].
	method := aContext method.
	method isNil ifTrue: [^nil].
	names := method tempNames.
	1 to: names size do: [:i | (names at: i) asString = aName asString ifTrue: [^aContext context tempAt: i]].
	^nil!
receiver
	"the receiver of the selected frame, for use in evaluate..."
	^self selectedFrame ifNotNil: [:c | c receiver]! !
