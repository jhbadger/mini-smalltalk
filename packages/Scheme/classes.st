"The classes of the Scheme system: its errors, the data that Smalltalk's own classes do not already supply (pairs, the
empty list, procedures, promises, records, hash tables, ports), and the interpreter itself (the methods of Scheme are in
compiler.st, machine.st, api.st and the primitives files).

Numbers, booleans, characters and symbols are Smalltalk's own; a Scheme string is a Smalltalk String (and so mutable),
a vector is an Array, and a hash table wraps a Dictionary. Anything else a Scheme program meets -- an OrderedCollection
from st-new, say -- is simply passed along as it is."

Error subclass: #SchemeError instanceVariableNames: 'payload' classVariableNames: '' category: 'Scheme'!
Exception subclass: #SchemeExit instanceVariableNames: 'value' classVariableNames: '' category: 'Scheme'!

Object subclass: #SchemeEmpty instanceVariableNames: '' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeUnspecified instanceVariableNames: '' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeEof instanceVariableNames: '' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeDefaultObject instanceVariableNames: '' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeEnvironment instanceVariableNames: 'name' classVariableNames: '' category: 'Scheme'!

Object subclass: #SchemePair instanceVariableNames: 'car cdr' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeCell instanceVariableNames: 'name value' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeValues instanceVariableNames: 'items' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemePromise instanceVariableNames: 'done value node env chain' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeRecordType instanceVariableNames: 'name fields' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeRecord instanceVariableNames: 'type values' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeTable instanceVariableNames: 'dict' classVariableNames: 'StringMark FloatMark PairMark VectorMark' category: 'Scheme'!
Object subclass: #SchemeCondition instanceVariableNames: 'message irritants kind' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeOutPort instanceVariableNames: 'stream path atLineStart' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeInPort instanceVariableNames: 'text pos' classVariableNames: '' category: 'Scheme'!

Object subclass: #SchemeProcedure instanceVariableNames: 'name' classVariableNames: '' category: 'Scheme'!
SchemeProcedure subclass: #SchemeClosure instanceVariableNames: 'lambda env' classVariableNames: '' category: 'Scheme'!
SchemeProcedure subclass: #SchemePrimitive instanceVariableNames: 'min max kind block' classVariableNames: '' category: 'Scheme'!
SchemeProcedure subclass: #SchemeContinuation instanceVariableNames: 'k winders handlers' classVariableNames: '' category: 'Scheme'!
SchemeProcedure subclass: #SchemeParameter instanceVariableNames: 'value converter' classVariableNames: '' category: 'Scheme'!
SchemeProcedure subclass: #SchemeCaseLambda instanceVariableNames: 'closures' classVariableNames: '' category: 'Scheme'!

Object subclass: #SchemeScope instanceVariableNames: 'vars parent macros frameless' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeMacro instanceVariableNames: 'literals rules ellipsis scope' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeWinder instanceVariableNames: 'before after next depth' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeHandler instanceVariableNames: 'proc next' classVariableNames: '' category: 'Scheme'!
SchemeHandler subclass: #SchemeGuardHandler instanceVariableNames: 'k winders env node' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemePrims instanceVariableNames: '' classVariableNames: 'Generator' category: 'Scheme'!
Exception subclass: #SchemeAbort instanceVariableNames: '' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemeReader instanceVariableNames: 'text pos' classVariableNames: '' category: 'Scheme'!
Object subclass: #SchemePrinter instanceVariableNames: 'out write' classVariableNames: '' category: 'Scheme'!

Object subclass: #Scheme
	instanceVariableNames: 'globals macros env val k winders handlers output outParam inParam counter depth'
	classVariableNames: 'Primitives Template Shared Prelude SpecialForms Gensym'
	category: 'Scheme'!

Smalltalk at: #SchemeNil put: SchemeEmpty basicNew!
Smalltalk at: #SchemeUnspec put: SchemeUnspecified basicNew!
Smalltalk at: #SchemeEofObject put: SchemeEof basicNew!
Smalltalk at: #SchemeDefault put: SchemeDefaultObject basicNew!

!SchemeError methodsFor: 'accessing'!
payload
	"the object that was raised: a SchemeCondition for an error, anything at all for raise"
	^payload!
payload: anObject
	payload := anObject!
messageText
	^payload isNil ifTrue: [super messageText] ifFalse: [SchemePrinter reportString: payload]! !

!SchemeError class methodsFor: 'signalling'!
message: aString
	^self new payload: (SchemeCondition message: aString irritants: SchemeNil); signal!
message: aString with: anIrritant
	^self new payload: (SchemeCondition message: aString irritants: (SchemePair car: anIrritant cdr: SchemeNil)); signal!
message: aString irritants: aList
	^self new payload: (SchemeCondition message: aString irritants: aList); signal!
raise: anObject
	^self new payload: anObject; signal! !

!SchemeExit methodsFor: 'accessing'!
value
	^value!
value: anObject
	value := anObject! !

!SchemeEmpty methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: '()'!
asArray
	^#()!
isList
	^true!
length
	^0! !

!SchemeUnspecified methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'unspecified'! !

!SchemeEof methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: '#[eof]'! !

!SchemeDefaultObject methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: '#!!default'! !

!SchemeEnvironment class methodsFor: 'instance creation'!
named: aString
	^self new setName: aString! !

!SchemeEnvironment methodsFor: 'accessing'!
setName: aString
	name := aString!
printOn: aStream
	aStream nextPutAll: '#[environment '; nextPutAll: name; nextPut: $]! !

"---- pairs and lists ----"

!SchemePair class methodsFor: 'instance creation'!
car: a cdr: d
	^self basicNew setCar: a cdr: d!
fromArray: anArray
	"a proper list of the elements"
	| l |
	l := SchemeNil.
	anArray size to: 1 by: -1 do: [:i | l := self car: (anArray at: i) cdr: l].
	^l!
fromArray: anArray tail: aTail
	| l |
	l := aTail.
	anArray size to: 1 by: -1 do: [:i | l := self car: (anArray at: i) cdr: l].
	^l!
fromCollection: aCollection
	^self fromArray: aCollection asArray!
with: a
	^self car: a cdr: SchemeNil!
with: a with: b
	^self car: a cdr: (self car: b cdr: SchemeNil)!
with: a with: b with: c
	^self car: a cdr: (self car: b cdr: (self car: c cdr: SchemeNil))! !

!SchemePair methodsFor: 'accessing'!
setCar: a cdr: d
	car := a. cdr := d!
car
	^car!
cdr
	^cdr!
car: anObject
	car := anObject!
cdr: anObject
	cdr := anObject!
cadr
	^cdr car!
cddr
	^cdr cdr!
caddr
	^cdr cdr car!
cdddr
	^cdr cdr cdr!
isList
	"a proper list: false for a dotted tail or a cycle"
	| slow fast |
	slow := self. fast := self.
	[fast == SchemeNil] whileFalse: [
		fast class == SchemePair ifFalse: [^false].
		fast := fast cdr.
		fast == SchemeNil ifTrue: [^true].
		fast class == SchemePair ifFalse: [^false].
		fast := fast cdr.
		slow := slow cdr.
		fast == slow ifTrue: [^false]].
	^true!
length
	| n p |
	n := 0. p := self.
	[p class == SchemePair] whileTrue: [n := n + 1. p := p cdr].
	^n!
asArray
	"the elements of a proper list as an Array (the tail of an improper list is dropped)"
	| out p |
	out := OrderedCollection new. p := self.
	[p class == SchemePair] whileTrue: [out add: p car. p := p cdr].
	^out asArray!
printOn: aStream
	aStream nextPutAll: (SchemePrinter write: self)! !

"---- cells, values, promises ----"

!SchemeCell class methodsFor: 'instance creation'!
named: aSymbol
	^self basicNew setName: aSymbol! !

!SchemeCell methodsFor: 'accessing'!
setName: aSymbol
	name := aSymbol!
name
	^name!
value
	^value!
value: anObject
	value := anObject!
copyCell
	^(SchemeCell named: name) value: value; yourself! !

!SchemeValues class methodsFor: 'instance creation'!
items: anArray
	^self basicNew setItems: anArray! !

!SchemeValues methodsFor: 'accessing'!
setItems: anArray
	items := anArray!
items
	^items!
printOn: aStream
	aStream nextPutAll: '#[values'.
	items do: [:each | aStream space; nextPutAll: (SchemePrinter write: each)].
	aStream nextPut: $]! !

!SchemePromise class methodsFor: 'instance creation'!
node: aNode env: anEnv
	^self basicNew setNode: aNode env: anEnv!
value: anObject
	^self basicNew setValue: anObject! !

!SchemePromise methodsFor: 'accessing'!
setNode: aNode env: anEnv
	done := false. node := aNode. env := anEnv!
setValue: anObject
	done := true. value := anObject!
isDone
	^done!
value
	^value!
node
	^node!
env
	^env!
chain
	"true for a delay-force promise: its body answers another promise, and the value is that promise's"
	^chain == true!
chain: aBoolean
	chain := aBoolean!
finish: anObject
	done := true. value := anObject. node := nil. env := nil!
printOn: aStream
	aStream nextPutAll: '#[promise]'! !

"---- records ----"

!SchemeRecordType class methodsFor: 'instance creation'!
name: aString fields: anArray
	^self basicNew setName: aString fields: anArray! !

!SchemeRecordType methodsFor: 'accessing'!
setName: aString fields: anArray
	name := aString. fields := anArray!
name
	^name!
fields
	^fields!
indexOf: aField
	| i |
	i := fields indexOf: aField.
	i = 0 ifTrue: [^SchemeError message: 'no such record field' with: aField].
	^i!
printOn: aStream
	aStream nextPutAll: '#[record-type '; nextPutAll: name; nextPut: $]! !

!SchemeRecord class methodsFor: 'instance creation'!
type: aType values: anArray
	^self basicNew setType: aType values: anArray! !

!SchemeRecord methodsFor: 'accessing'!
setType: aType values: anArray
	type := aType. values := anArray!
type
	^type!
values
	^values!
at: i
	^values at: i!
at: i put: anObject
	^values at: i put: anObject!
printOn: aStream
	aStream nextPutAll: (SchemePrinter write: self)! !

"---- conditions ----"

!SchemeCondition class methodsFor: 'instance creation'!
message: aString irritants: aList
	^self basicNew setMessage: aString irritants: aList kind: #error!
message: aString irritants: aList kind: aSymbol
	^self basicNew setMessage: aString irritants: aList kind: aSymbol! !

!SchemeCondition methodsFor: 'accessing'!
setMessage: aString irritants: aList kind: aSymbol
	message := aString. irritants := aList. kind := aSymbol!
message
	^message!
irritants
	^irritants!
kind
	^kind!
reportString
	"the message followed by the irritants, as write would show them"
	| ws p |
	ws := WriteStream on: String new.
	message isString ifTrue: [ws nextPutAll: message asString] ifFalse: [ws nextPutAll: (SchemePrinter write: message)].
	p := irritants.
	[p class == SchemePair] whileTrue: [
		ws space; nextPutAll: (SchemePrinter write: p car).
		p := p cdr].
	^ws contents!
printOn: aStream
	aStream nextPutAll: '#[condition '; nextPutAll: kind; nextPut: $]! !

"---- procedures ----"

!SchemeProcedure methodsFor: 'accessing'!
name
	^name!
name: aString
	name := aString!
yourself2
	^self! !

!SchemeClosure class methodsFor: 'instance creation'!
lambda: aLambdaNode env: anEnv
	^self basicNew setLambda: aLambdaNode env: anEnv! !

!SchemeClosure methodsFor: 'accessing'!
setLambda: aLambdaNode env: anEnv
	lambda := aLambdaNode. env := anEnv. name := aLambdaNode name!
lambda
	^lambda!
env
	^env! !

!SchemePrimitive class methodsFor: 'instance creation'!
name: aString min: lo max: hi kind: aSymbol block: aBlock
	^self basicNew setName: aString min: lo max: hi kind: aSymbol block: aBlock! !

!SchemePrimitive methodsFor: 'accessing'!
setName: aString min: lo max: hi kind: aSymbol block: aBlock
	name := aString. min := lo. max := hi. kind := aSymbol. block := aBlock!
min
	^min!
max
	^max!
kind
	^kind!
block
	^block!
acceptsCount: n
	^n >= min and: [max isNil or: [n <= max]]! !

!SchemeContinuation class methodsFor: 'instance creation'!
k: aFrame winders: w handlers: h
	^self basicNew setK: aFrame winders: w handlers: h! !

!SchemeContinuation methodsFor: 'accessing'!
setK: aFrame winders: w handlers: h
	k := aFrame. winders := w. handlers := h!
k
	^k!
winders
	^winders!
handlers
	^handlers! !

!SchemeParameter class methodsFor: 'instance creation'!
value: anObject converter: aProcedure
	^self basicNew setValue: anObject converter: aProcedure! !

!SchemeParameter methodsFor: 'accessing'!
setValue: anObject converter: aProcedure
	value := anObject. converter := aProcedure!
value
	^value!
value: anObject
	value := anObject!
converter
	^converter! !

!SchemeCaseLambda class methodsFor: 'instance creation'!
closures: anArray
	^self basicNew setClosures: anArray! !

!SchemeCaseLambda methodsFor: 'accessing'!
setClosures: anArray
	closures := anArray!
closures
	^closures! !

"---- ports ----"

!SchemeOutPort class methodsFor: 'instance creation'!
on: aStream
	^self basicNew setStream: aStream path: nil!
toFile: aPath
	^self basicNew setStream: (WriteStream on: String new) path: aPath! !

!SchemeOutPort methodsFor: 'writing'!
setStream: aStream path: aPath
	stream := aStream. path := aPath. atLineStart := true!
stream
	^stream!
path
	^path!
write: aString
	aString isEmpty ifTrue: [^self].
	stream nextPutAll: aString.
	atLineStart := aString last = Character nl!
writeChar: aCharacter
	stream nextPut: aCharacter.
	atLineStart := aCharacter = Character nl!
atLineStart
	^atLineStart!
contents
	^stream contents!
close
	"a file port writes its file when it is closed"
	path isNil ifFalse: [FileStream newFileNamed: path do: [:f | f nextPutAll: stream contents]]!
printOn: aStream
	aStream nextPutAll: '#[output-port]'! !

!SchemeInPort class methodsFor: 'instance creation'!
on: aString
	^self basicNew setText: aString! !

!SchemeInPort methodsFor: 'reading'!
setText: aString
	text := aString. pos := 1!
atEnd
	^pos > text size!
next
	| c |
	pos > text size ifTrue: [^nil].
	c := text at: pos. pos := pos + 1.
	^c!
peek
	pos > text size ifTrue: [^nil].
	^text at: pos!
readLine
	| start |
	pos > text size ifTrue: [^nil].
	start := pos.
	[pos <= text size and: [(text at: pos) ~= Character nl]] whileTrue: [pos := pos + 1].
	pos := pos + 1.
	^text copyFrom: start to: (pos - 2 min: text size)!
readString: n
	| start |
	pos > text size ifTrue: [^nil].
	start := pos.
	pos := (pos + n) min: text size + 1.
	^text copyFrom: start to: pos - 1!
rest
	^text copyFrom: pos to: text size!
position
	^pos!
position: n
	pos := n!
text
	^text!
printOn: aStream
	aStream nextPutAll: '#[input-port]'! !

"---- scopes, winders, handlers ----"

!SchemeScope class methodsFor: 'instance creation'!
vars: anArray parent: aScope
	^self basicNew setVars: anArray parent: aScope!
macroScopeParent: aScope
	"a scope that only holds macros: it adds no frame at run time"
	^(self basicNew setVars: #() parent: aScope) beFrameless; yourself! !

!SchemeScope methodsFor: 'accessing'!
setVars: anArray parent: aScope
	vars := OrderedCollection new.
	anArray do: [:v | vars add: v].
	parent := aScope.
	frameless := false!
beFrameless
	frameless := true!
isFrameless
	^frameless!
parent
	^parent!
vars
	^vars!
size
	^vars size!
addVar: aSymbol
	"the slot of aSymbol in this frame, adding it if it is new"
	| i |
	i := vars indexOf: aSymbol.
	i = 0 ifTrue: [vars add: aSymbol. i := vars size].
	^i + 1!
hasVar: aSymbol
	^(vars indexOf: aSymbol) > 0!
macroAt: aSymbol
	^macros isNil ifTrue: [nil] ifFalse: [macros at: aSymbol ifAbsent: [nil]]!
macroAt: aSymbol put: aMacro
	macros isNil ifTrue: [macros := Dictionary new].
	macros at: aSymbol put: aMacro!
nearestFramed
	| s |
	s := self.
	[s notNil and: [s isFrameless]] whileTrue: [s := s parent].
	^s! !

!SchemeWinder class methodsFor: 'instance creation'!
before: b after: a next: aWinder
	^self basicNew setBefore: b after: a next: aWinder! !

!SchemeWinder methodsFor: 'accessing'!
setBefore: b after: a next: aWinder
	before := b. after := a. next := aWinder.
	depth := aWinder isNil ifTrue: [1] ifFalse: [aWinder depth + 1]!
before
	^before!
after
	^after!
next
	^next!
depth
	^depth! !

!SchemeHandler class methodsFor: 'instance creation'!
proc: aProcedure next: aHandler
	^self basicNew setProc: aProcedure next: aHandler! !

!SchemeHandler methodsFor: 'accessing'!
setProc: aProcedure next: aHandler
	proc := aProcedure. next := aHandler!
proc
	^proc!
next
	^next!
isGuard
	^false! !

!SchemeGuardHandler class methodsFor: 'instance creation'!
k: aFrame winders: w env: anEnv node: aNode next: aHandler
	^(self basicNew setProc: nil next: aHandler) setK: aFrame winders: w env: anEnv node: aNode! !

!SchemeGuardHandler methodsFor: 'accessing'!
setK: aFrame winders: w env: anEnv node: aNode
	k := aFrame. winders := w. env := anEnv. node := aNode!
k
	^k!
winders
	^winders!
env
	^env!
node
	^node!
isGuard
	^true! !
