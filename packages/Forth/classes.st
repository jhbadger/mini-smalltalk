"The classes of the Forth system: the errors, the kinds of word that can live in a dictionary or in a
compiled definition, and the machine itself (the methods of Forth are in machine.st, compiler.st, api.st)."

Error subclass: #ForthError instanceVariableNames: 'code' classVariableNames: '' category: 'Forth'!
ForthError subclass: #ForthThrow instanceVariableNames: '' classVariableNames: '' category: 'Forth'!
Exception subclass: #ForthStop instanceVariableNames: '' classVariableNames: '' category: 'Forth'!

Object subclass: #ForthWord instanceVariableNames: 'name immediate' classVariableNames: '' category: 'Forth'!
ForthWord subclass: #ForthPrimitive instanceVariableNames: 'block' classVariableNames: '' category: 'Forth'!
ForthWord subclass: #ForthColon instanceVariableNames: 'body' classVariableNames: '' category: 'Forth'!
ForthWord subclass: #ForthLiteral instanceVariableNames: 'value' classVariableNames: '' category: 'Forth'!
ForthLiteral subclass: #ForthFloatLiteral instanceVariableNames: '' classVariableNames: '' category: 'Forth'!
ForthWord subclass: #ForthText instanceVariableNames: 'text' classVariableNames: '' category: 'Forth'!
ForthWord subclass: #ForthJump instanceVariableNames: 'op target' classVariableNames: '' category: 'Forth'!
ForthWord subclass: #ForthCreated instanceVariableNames: 'address does' classVariableNames: '' category: 'Forth'!
ForthCreated subclass: #ForthValue instanceVariableNames: '' classVariableNames: '' category: 'Forth'!
ForthWord subclass: #ForthDefer instanceVariableNames: 'action' classVariableNames: '' category: 'Forth'!

Object subclass: #Forth
	instanceVariableNames: 'dict stack rstack fstack memory here source out code ip body current controls latest noname holdBuf errorLine errorWord lastToken tokenStart keyInput keyBuffer stringSlot'
	classVariableNames: 'Primitives Template Shared Prelude Generator'
	category: 'Forth'!

!ForthError methodsFor: 'accessing'!
code
	"the ANS throw code: -4 stack underflow, -10 division by zero, -13 undefined word, ..."
	^code ifNil: [-1]!
code: anInteger
	code := anInteger! !

!ForthError class methodsFor: 'signalling'!
code: anInteger message: aString
	^self new code: anInteger; signal: aString! !

!ForthWord class methodsFor: 'instance creation'!
named: aString
	^self new setName: aString! !

!ForthWord methodsFor: 'accessing'!
setName: aString
	name := aString.
	immediate := false!
name
	^name!
name: aString
	name := aString!
isImmediate
	^immediate == true!
immediate: aBoolean
	immediate := aBoolean!
executeIn: aForth
	^aForth fail: 'word cannot be executed'!
describe
	"how this word reads inside a decompiled definition"
	^name ifNil: ['(anonymous)']!
printOn: aStream
	aStream nextPutAll: 'Forth word '; nextPutAll: (name ifNil: ['(anonymous)'])! !

!ForthPrimitive methodsFor: 'accessing'!
block: aBlock
	block := aBlock!
executeIn: aForth
	^block value: aForth! !

!ForthColon methodsFor: 'accessing'!
body
	^body!
body: anArray
	body := anArray!
executeIn: aForth
	body isNil ifTrue: [^aForth fail: 'the definition is not finished yet'].
	^aForth run: body! !

!ForthLiteral class methodsFor: 'instance creation'!
value: anObject
	^(self named: nil) value: anObject! !

!ForthLiteral methodsFor: 'accessing'!
value
	^value!
value: anObject
	value := anObject!
executeIn: aForth
	^aForth push: value!
describe
	^value printString! !

!ForthFloatLiteral methodsFor: 'accessing'!
executeIn: aForth
	^aForth fpush: value! !

!ForthText class methodsFor: 'instance creation'!
text: aString
	^(self named: nil) text: aString! !

!ForthText methodsFor: 'accessing'!
text
	^text!
text: aString
	text := aString!
executeIn: aForth
	^aForth type: text!
describe
	^'." ', text, '"'! !

!ForthJump class methodsFor: 'instance creation'!
op: aSymbol
	^(self named: nil) op: aSymbol! !

!ForthJump methodsFor: 'accessing'!
op
	^op!
op: aSymbol
	op := aSymbol!
target
	^target!
target: anInteger
	target := anInteger!
describe
	^(op == #zbranch ifTrue: ['0BRANCH'] ifFalse: [op asString asUppercase]), ' ', (target ifNil: ['?']) printString!
executeIn: f
	"the control cells that the compiler lays down: every one is a jump of some kind, and the
	loop ones also keep the loop's limit and index on the return stack"
	| x |
	op == #zbranch ifTrue: [^f pop = 0 ifTrue: [f jumpTo: target]].
	op == #branch ifTrue: [^f jumpTo: target].
	op == #loop ifTrue: [^f loopBy: 1 target: target].
	op == #ploop ifTrue: [^f loopBy: f pop target: target].
	op == #do ifTrue: [^f startLoopSkipping: false target: target].
	op == #qdo ifTrue: [^f startLoopSkipping: true target: target].
	op == #leave ifTrue: [^f leaveLoopTo: target].
	op == #of ifTrue: [
		x := f pop.
		^f top = x ifTrue: [f pop] ifFalse: [f jumpTo: target]].
	^f fail: 'unknown control cell'! !

!ForthCreated methodsFor: 'accessing'!
address
	^address!
address: anInteger
	address := anInteger!
does
	^does!
does: anArray
	does := anArray!
executeIn: f
	f push: address.
	does notNil ifTrue: [f run: does]!
describe
	^name ifNil: ['(created)']! !

!ForthValue methodsFor: 'accessing'!
executeIn: f
	^f push: (f fetch: address)! !

!ForthDefer methodsFor: 'accessing'!
action
	^action!
action: aWord
	action := aWord!
executeIn: f
	action isNil ifTrue: [^f fail: 'uninitialised deferred word: ', (name ifNil: ['?'])].
	^action executeIn: f! !
