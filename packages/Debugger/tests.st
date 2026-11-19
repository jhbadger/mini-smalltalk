"Tests for the debugger. They need SUnit; the package loads it."

TestCase subclass: #DebuggerTest instanceVariableNames: '' classVariableNames: '' category: 'Debugger-Tests'!
Object subclass: #DebuggerExample instanceVariableNames: 'count name' classVariableNames: '' category: 'Debugger-Tests'!

!DebuggerExample methodsFor: 'examples'!
setUpValues
	count := 42. name := 'example'!
divide: a by: b
	| result |
	result := a / b.
	^result!
outer: n
	| doubled |
	doubled := n * 2.
	^self divide: doubled by: 0!
inABlock
	| items |
	items := #(1 2 3).
	items do: [:each | each / 0].
	^items! !

!DebuggerTest methodsFor: 'opening'!
framesOfError: aBlock
	"the frames of whatever goes wrong in the block, captured while the stack is still live -- which is what
	both the system hook and Debugger debug: do"
	^[aBlock value. Array new] on: Error do: [:e | e return: (Debugger framesOf: e signalerContext)]!
contextOfError: aBlock
	"the context that signalled; by the time the handler has returned, its frames are dead"
	^[aBlock value. nil] on: Error do: [:e | e return: e signalerContext]!
testDebugOnAnError
	| c |
	c := self contextOfError: [1/0].
	self deny: c isNil!
testDebugBlockOpensOnTheError
	Debugger debug: [DebuggerExample new divide: 1 by: 0].
	self assert: (Debugger listItems anySatisfy: [:i | i includesSubstring: 'divide:by:'])!
testFramesSkipTheExceptionMachinery
	| frames |
	frames := self framesOfError: [DebuggerExample new divide: 1 by: 0].
	self deny: (frames anySatisfy: [:f | f method methodClass == Exception]).
	self deny: (frames anySatisfy: [:f | f label includesSubstring: 'Exception>>signal'])!
testDoesNotUnderstandPlumbingIsLeftOut
	| frames |
	frames := self framesOfError: [DebuggerExample new noSuchMessage].
	self deny: (frames anySatisfy: [:f | f label includesSubstring: 'doesNotUnderstand:']).
	self assert: (frames first label includesSubstring: 'DebuggerTest')!
testErrorPlumbingIsLeftOut
	| frames |
	frames := self framesOfError: [Object new error: 'boom'].
	self deny: (frames anySatisfy: [:f | f label includesSubstring: 'Object>>error:'])!
testTheInnermostFrameIsWhereTheErrorWasRaised
	| frames |
	frames := self framesOfError: [DebuggerExample new divide: 1 by: 0].
	self assert: (frames first label includesSubstring: 'zeroDivide')!
testFramesNameTheFailingMethod
	| frames |
	frames := self framesOfError: [DebuggerExample new divide: 1 by: 0].
	self assert: (frames anySatisfy: [:f | f label includesSubstring: 'divide:by:'])!
testFramesAreInnermostFirst
	| frames outer inner |
	frames := self framesOfError: [DebuggerExample new outer: 3].
	inner := frames findFirst: [:f | f label includesSubstring: 'divide:by:'].
	outer := frames findFirst: [:f | f label includesSubstring: 'outer:'].
	self assert: inner > 0.
	self assert: outer > 0.
	self assert: inner < outer! !

!DebuggerTest methodsFor: 'source and variables'!
testSourceOfAFrame
	| frames source |
	frames := self framesOfError: [DebuggerExample new divide: 1 by: 0].
	source := Debugger sourceOf: (frames detect: [:each | each label includesSubstring: 'divide:by:']).
	self assert: (source includesSubstring: 'result := a / b')!
testMarkedSourceMarksTheFailingLine
	| marked marker |
	marked := Debugger markedSourceOf: ((self framesOfError: [DebuggerExample new divide: 1 by: 0])
		detect: [:each | each label includesSubstring: 'divide:by:']).
	marker := (Debugger linesOf: marked) detect: [:l | l startsWith: '>'] ifNone: [''].
	self assert: (marker includesSubstring: 'result := a / b').
	self assert: ((Debugger linesOf: marked) count: [:l | l startsWith: '>']) equals: 1!
testLineOfAFrameIsTheStatementThatFailed
	| f line source |
	f := (self framesOfError: [DebuggerExample new divide: 1 by: 0])
		detect: [:each | each label includesSubstring: 'divide:by:'].
	line := Debugger lineOf: f.
	source := Debugger sourceOf: f.
	self assert: (((Debugger linesOf: source) at: line) includesSubstring: 'result := a / b')!
testVariablesShowArgumentsByName
	| frames text |
	frames := self framesOfError: [DebuggerExample new divide: 7 by: 0].
	text := Debugger describeVariablesOf: (frames detect: [:each | each label includesSubstring: 'divide:by:']).
	self assert: (text includesSubstring: 'arg  a = 7').
	self assert: (text includesSubstring: 'arg  b = 0')!
testVariablesShowTemporariesByName
	| frames text |
	frames := self framesOfError: [DebuggerExample new outer: 5].
	text := Debugger describeVariablesOf: (frames detect: [:each | each label includesSubstring: 'outer:']).
	self assert: (text includesSubstring: 'arg  n = 5').
	self assert: (text includesSubstring: 'temp doubled = 10')!
testVariablesShowSelf
	| frames text |
	frames := self framesOfError: [DebuggerExample new divide: 1 by: 0].
	text := Debugger describeVariablesOf: frames first.
	self assert: (text includesSubstring: 'self = ')!
testReceiverViewShowsInstanceVariables
	| e frames text |
	e := DebuggerExample new.
	e setUpValues.
	frames := self framesOfError: [e divide: 1 by: 0].
	text := Debugger describeReceiverOf: (frames detect: [:each | each receiver == e]).
	self assert: (text includesSubstring: 'count = 42').
	self assert: (text includesSubstring: 'name = ''example''')!
testTempNamedFindsATemporary
	| frames c |
	frames := self framesOfError: [DebuggerExample new outer: 5].
	c := frames detect: [:each | each label includesSubstring: 'outer:'].
	self assert: (Debugger tempNamed: 'doubled' in: c) equals: 10.
	self assert: (Debugger tempNamed: 'n' in: c) equals: 5.
	self assert: (Debugger tempNamed: 'nosuch' in: c) equals: nil!
testBlockFrameReportsItsHomeSource
	| f line source |
	f := (self framesOfError: [DebuggerExample new inABlock])
		detect: [:each | each label includesSubstring: '[] in DebuggerExample'] ifNone: [nil].
	self deny: f isNil.
	source := Debugger sourceOf: f.
	self assert: (source includesSubstring: 'inABlock').
	line := Debugger lineOf: f.
	self assert: (((Debugger linesOf: source) at: line) includesSubstring: 'each / 0')!
testFramesKeepThePCAfterTheStackIsUnwound
	| f |
	f := (self framesOfError: [DebuggerExample new divide: 1 by: 0])
		detect: [:each | each label includesSubstring: 'divide:by:'].
	self assert: f isDead description: 'the handler unwound the frame'.
	self deny: f pc isNil description: 'but the debugger kept the pc it had'! !

!DebuggerTest methodsFor: 'the window'!
openOnAnError
	"open the way the system does: while the stack that failed is still live"
	[DebuggerExample new divide: 1 by: 0]
		on: Error
		do: [:e | Debugger openOn: e signalerContext message: 'division by zero'. e return: nil]!
testOpeningFillsTheList
	self openOnAnError.
	self assert: Debugger listItems notEmpty.
	self assert: (Debugger listItems anySatisfy: [:i | i includesSubstring: 'divide:by:'])!
frameIndexOfDivide
	^(1 to: Debugger frames size) detect: [:i | ((Debugger frames at: i) label includesSubstring: 'divide:by:')]!
testDetailShowsTheMessage
	self openOnAnError.
	self assert: ((Debugger detailAt: 1) includesSubstring: 'division by zero')!
testModesChangeTheDetail
	| i |
	self openOnAnError.
	i := self frameIndexOfDivide.
	Debugger command: 1 at: i.
	self assert: ((Debugger detailAt: i) includesSubstring: 'result := a / b').
	Debugger command: 2 at: i.
	self assert: ((Debugger detailAt: i) includesSubstring: 'arg  a = 1').
	Debugger command: 3 at: i.
	self assert: ((Debugger detailAt: i) includesSubstring: 'self = ').
	Debugger command: 4 at: i.
	self assert: ((Debugger detailAt: i) includesSubstring: '1. ')!
testWholeStackNumbersTheFrames
	self openOnAnError.
	self assert: (Debugger fullStack includesSubstring: '1. ').
	self assert: (Debugger fullStack includesSubstring: 'line ')!
testCommandLabels
	self assert: Debugger commandLabels size equals: 10!
testDetailOutsideTheListIsSafe
	self openOnAnError.
	self assert: ((Debugger detailAt: 999) includesSubstring: 'division by zero')!
testEvaluateNeedsAFrame
	self assert: (Debugger evaluateIn: nil) equals: 'select a frame first'! !

!DebuggerTest methodsFor: 'the compiler support'!
testMethodsKnowTheirTemporaryNames
	| m |
	m := DebuggerExample compiledMethodAt: #divide:by:.
	self assert: m tempNames equals: #('a' 'b' 'result')!
testMethodsKnowTheirSourceMap
	| m |
	m := DebuggerExample compiledMethodAt: #divide:by:.
	self assert: m sourceMap notEmpty.
	self assert: m sourceMap size even!
testLineForPC
	| m |
	Object compile: 'debuggerLineExample | a | a := 1. a := a + 1. ^a'.
	m := Object compiledMethodAt: #debuggerLineExample.
	self assert: (m lineForPC: 1) equals: 1.
	Object removeSelector: #debuggerLineExample!
testSourceOffsetForPC
	| m |
	m := DebuggerExample compiledMethodAt: #divide:by:.
	self assert: (m sourceOffsetForPC: 1) isNil not!
testAMethodWithNoTemporaries
	| m |
	m := DebuggerExample compiledMethodAt: #setUpValues.
	self assert: m tempNames equals: #()! !
