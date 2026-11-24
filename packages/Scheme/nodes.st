"The compiled form of a program, and the continuation frames the machine pushes while it runs.

Scheme source is compiled once into a tree of nodes. A node is run by the machine with exec:, which either leaves a value in
the machine's val register and answers nil, or answers the next node to run (a tail call, the branch of an if, the last
form of a body). A node that cannot be waiting for anything -- a constant, a variable, a lambda -- is simple, and answers
its value at once to value:, which saves a frame. Anything that has to wait for a sub-expression pushes a frame on the
machine's continuation, a linked list on the heap, so recursion is limited by memory and not by the Smalltalk stack, and a
captured continuation is just a pointer to a frame."

Object subclass: #SchemeNode instanceVariableNames: '' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeConst instanceVariableNames: 'value' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeLocalRef instanceVariableNames: 'depth index name' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeGlobalRef instanceVariableNames: 'cell' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeSetLocal instanceVariableNames: 'depth index value isDefine name' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeSetGlobal instanceVariableNames: 'cell value isDefine' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeIfNode instanceVariableNames: 'test then else' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeLambdaNode instanceVariableNames: 'nreq hasRest frameSize body name' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeSeqNode instanceVariableNames: 'forms' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeAppNode instanceVariableNames: 'parts' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeAndNode instanceVariableNames: 'forms' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeOrNode instanceVariableNames: 'forms' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeDelayNode instanceVariableNames: 'body chain' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeCaseLambdaNode instanceVariableNames: 'lambdas' classVariableNames: '' category: 'Scheme'!
SchemeNode subclass: #SchemeGuardNode instanceVariableNames: 'body handler frameSize' classVariableNames: '' category: 'Scheme'!

Object subclass: #SchemeFrame instanceVariableNames: 'next depth' classVariableNames: '' category: 'Scheme'!
SchemeFrame subclass: #SchemeIfFrame instanceVariableNames: 'node env' classVariableNames: '' category: 'Scheme'!
SchemeFrame subclass: #SchemeSeqFrame instanceVariableNames: 'node index env' classVariableNames: '' category: 'Scheme'!
SchemeFrame subclass: #SchemeAppFrame instanceVariableNames: 'node index fn buf env' classVariableNames: '' category: 'Scheme'!
SchemeFrame subclass: #SchemeSetFrame instanceVariableNames: 'node env' classVariableNames: '' category: 'Scheme'!
SchemeFrame subclass: #SchemeAndFrame instanceVariableNames: 'node index env' classVariableNames: '' category: 'Scheme'!
SchemeFrame subclass: #SchemeOrFrame instanceVariableNames: 'node index env' classVariableNames: '' category: 'Scheme'!
SchemeFrame subclass: #SchemeBlockFrame instanceVariableNames: 'block' classVariableNames: '' category: 'Scheme'!

"---- the frames ----"

!SchemeFrame methodsFor: 'accessing'!
next
	^next!
next: aFrame
	next := aFrame!
depth
	^depth!
depth: anInteger
	depth := anInteger!
resume: m
	"the value is in m val: answer the next node to run, or nil when the value of this frame is ready"
	^nil! !

!SchemeIfFrame class methodsFor: 'instance creation'!
node: aNode env: anEnv
	^self basicNew setNode: aNode env: anEnv! !

!SchemeIfFrame methodsFor: 'running'!
setNode: aNode env: anEnv
	node := aNode. env := anEnv!
resume: m
	m env: env.
	^m val == false ifTrue: [node else] ifFalse: [node then]! !

!SchemeSeqFrame class methodsFor: 'instance creation'!
node: aNode index: i env: anEnv
	^self basicNew setNode: aNode index: i env: anEnv! !

!SchemeSeqFrame methodsFor: 'running'!
setNode: aNode index: i env: anEnv
	node := aNode. index := i. env := anEnv!
resume: m
	^node run: index env: env m: m! !

!SchemeAppFrame class methodsFor: 'instance creation'!
node: aNode index: i fn: f buf: b env: anEnv
	^self basicNew setNode: aNode index: i fn: f buf: b env: anEnv! !

!SchemeAppFrame methodsFor: 'running'!
setNode: aNode index: i fn: f buf: b env: anEnv
	node := aNode. index := i. fn := f. buf := b. env := anEnv!
resume: m
	"the buffer is copied so that a continuation captured while an argument was being worked out can be entered twice"
	| b |
	b := buf copy.
	index = 1 ifTrue: [^node step: 2 fn: m val buf: b env: env m: m].
	b at: index - 1 put: m val.
	^node step: index + 1 fn: fn buf: b env: env m: m! !

!SchemeSetFrame class methodsFor: 'instance creation'!
node: aNode env: anEnv
	^self basicNew setNode: aNode env: anEnv! !

!SchemeSetFrame methodsFor: 'running'!
setNode: aNode env: anEnv
	node := aNode. env := anEnv!
resume: m
	^node assign: m val env: env m: m! !

!SchemeAndFrame class methodsFor: 'instance creation'!
node: aNode index: i env: anEnv
	^self basicNew setNode: aNode index: i env: anEnv! !

!SchemeAndFrame methodsFor: 'running'!
setNode: aNode index: i env: anEnv
	node := aNode. index := i. env := anEnv!
resume: m
	m val == false ifTrue: [^nil].
	^node run: index env: env m: m! !

!SchemeOrFrame class methodsFor: 'instance creation'!
node: aNode index: i env: anEnv
	^self basicNew setNode: aNode index: i env: anEnv! !

!SchemeOrFrame methodsFor: 'running'!
setNode: aNode index: i env: anEnv
	node := aNode. index := i. env := anEnv!
resume: m
	m val == false ifFalse: [^nil].
	^node run: index env: env m: m! !

!SchemeBlockFrame class methodsFor: 'instance creation'!
block: aBlock
	^self basicNew setBlock: aBlock! !

!SchemeBlockFrame methodsFor: 'running'!
setBlock: aBlock
	block := aBlock!
resume: m
	^block value: m! !

"---- the nodes ----"

!SchemeNode methodsFor: 'running'!
isSimple
	^false!
isLambda
	^false!
exec: m
	^self subclassResponsibility!
value: env
	^self subclassResponsibility! !

!SchemeConst class methodsFor: 'instance creation'!
value: anObject
	^self basicNew setValue: anObject! !

!SchemeConst methodsFor: 'running'!
setValue: anObject
	value := anObject!
constant
	^value!
isSimple
	^true!
value: env
	^value!
exec: m
	m val: value.
	^nil! !

!SchemeLocalRef class methodsFor: 'instance creation'!
depth: d index: i name: aSymbol
	^self basicNew setDepth: d index: i name: aSymbol! !

!SchemeLocalRef methodsFor: 'running'!
setDepth: d index: i name: aSymbol
	depth := d. index := i. name := aSymbol!
isSimple
	^true!
value: env
	| e v |
	e := env.
	depth = 0 ifFalse: [
		depth = 1 ifTrue: [e := e at: 1] ifFalse: [depth timesRepeat: [e := e at: 1]]].
	v := e at: index.
	v isNil ifTrue: [^SchemeError message: 'Unassigned variable:' with: name].
	^v!
exec: m
	m val: (self value: m env).
	^nil! !

!SchemeGlobalRef class methodsFor: 'instance creation'!
cell: aCell
	^self basicNew setCell: aCell! !

!SchemeGlobalRef methodsFor: 'running'!
setCell: aCell
	cell := aCell!
isSimple
	^true!
value: env
	| v |
	v := cell value.
	v isNil ifTrue: [^SchemeError message: 'Unbound variable:' with: cell name].
	^v!
exec: m
	m val: (self value: m env).
	^nil! !

!SchemeSetLocal class methodsFor: 'instance creation'!
depth: d index: i value: aNode define: aBoolean name: aSymbol
	^self basicNew setDepth: d index: i value: aNode define: aBoolean name: aSymbol! !

!SchemeSetLocal methodsFor: 'running'!
setDepth: d index: i value: aNode define: aBoolean name: aSymbol
	depth := d. index := i. value := aNode. isDefine := aBoolean. name := aSymbol!
exec: m
	value isSimple ifTrue: [^self assign: (value value: m env) env: m env m: m].
	m push: (SchemeSetFrame node: self env: m env).
	^value!
assign: v env: env m: m
	| e |
	e := env.
	depth timesRepeat: [e := e at: 1].
	e at: index put: v.
	m val: (isDefine ifTrue: [name] ifFalse: [SchemeUnspec]).
	^nil! !

!SchemeSetGlobal class methodsFor: 'instance creation'!
cell: aCell value: aNode define: aBoolean
	^self basicNew setCell: aCell value: aNode define: aBoolean! !

!SchemeSetGlobal methodsFor: 'running'!
setCell: aCell value: aNode define: aBoolean
	cell := aCell. value := aNode. isDefine := aBoolean!
exec: m
	value isSimple ifTrue: [^self assign: (value value: m env) env: m env m: m].
	m push: (SchemeSetFrame node: self env: m env).
	^value!
assign: v env: env m: m
	(isDefine not and: [cell value isNil]) ifTrue: [^SchemeError message: 'Unbound variable:' with: cell name].
	cell value: v.
	(isDefine and: [v class == SchemeClosure and: [v name isNil]]) ifTrue: [v name: cell name asString].
	m val: (isDefine ifTrue: [cell name] ifFalse: [SchemeUnspec]).
	^nil! !

!SchemeIfNode class methodsFor: 'instance creation'!
test: t then: a else: b
	^self basicNew setTest: t then: a else: b! !

!SchemeIfNode methodsFor: 'running'!
setTest: t then: a else: b
	test := t. then := a. else := b!
then
	^then!
else
	^else!
exec: m
	test isSimple ifTrue: [
		^(test value: m env) == false ifTrue: [else] ifFalse: [then]].
	m push: (SchemeIfFrame node: self env: m env).
	^test! !

!SchemeLambdaNode class methodsFor: 'instance creation'!
required: n rest: aBoolean frameSize: size body: aNode name: aString
	^self basicNew setRequired: n rest: aBoolean frameSize: size body: aNode name: aString! !

!SchemeLambdaNode methodsFor: 'running'!
setRequired: n rest: aBoolean frameSize: size body: aNode name: aString
	nreq := n. hasRest := aBoolean. frameSize := size. body := aNode. name := aString!
nreq
	^nreq!
hasRest
	^hasRest!
frameSize
	^frameSize!
body
	^body!
name
	^name!
name: aString
	name := aString!
isLambda
	^true!
isSimple
	^true!
value: env
	^SchemeClosure lambda: self env: env!
exec: m
	m val: (SchemeClosure lambda: self env: m env).
	^nil!
arityText
	"how many arguments a closure of this lambda takes, for error messages"
	hasRest ifTrue: [^'at least ', nreq printString, (nreq = 1 ifTrue: [' argument'] ifFalse: [' arguments'])].
	^'exactly ', nreq printString, (nreq = 1 ifTrue: [' argument'] ifFalse: [' arguments'])! !

!SchemeSeqNode class methodsFor: 'instance creation'!
forms: anArray
	^self basicNew setForms: anArray! !

!SchemeSeqNode methodsFor: 'running'!
setForms: anArray
	forms := anArray!
exec: m
	^self run: 1 env: m env m: m!
run: i env: env m: m
	| n j f |
	n := forms size. j := i.
	[j < n] whileTrue: [
		f := forms at: j.
		f isSimple
			ifTrue: [f value: env]
			ifFalse: [
				m push: (SchemeSeqFrame node: self index: j + 1 env: env).
				m env: env.
				^f].
		j := j + 1].
	m env: env.
	^forms at: n! !

!SchemeAppNode class methodsFor: 'instance creation'!
parts: anArray
	^self basicNew setParts: anArray! !

!SchemeAppNode methodsFor: 'running'!
setParts: anArray
	parts := anArray!
parts
	^parts!
exec: m
	^self step: 1 fn: nil buf: (Array new: parts size - 1) env: m env m: m!
step: start fn: fn0 buf: buf env: env m: m
	| j fn p v n |
	n := parts size. j := start. fn := fn0.
	[j <= n] whileTrue: [
		p := parts at: j.
		p isSimple
			ifTrue: [v := p value: env]
			ifFalse: [
				m push: (SchemeAppFrame node: self index: j fn: fn buf: buf env: env).
				m env: env.
				^p].
		j = 1 ifTrue: [fn := v] ifFalse: [buf at: j - 1 put: v].
		j := j + 1].
	^m apply: fn args: buf! !

!SchemeAndNode class methodsFor: 'instance creation'!
forms: anArray
	^self basicNew setForms: anArray! !

!SchemeAndNode methodsFor: 'running'!
setForms: anArray
	forms := anArray!
exec: m
	^self run: 1 env: m env m: m!
run: i env: env m: m
	| n j f |
	n := forms size. j := i.
	[j < n] whileTrue: [
		f := forms at: j.
		f isSimple
			ifTrue: [(f value: env) == false ifTrue: [m val: false. ^nil]]
			ifFalse: [
				m push: (SchemeAndFrame node: self index: j + 1 env: env).
				m env: env.
				^f].
		j := j + 1].
	m env: env.
	^forms at: n! !

!SchemeOrNode class methodsFor: 'instance creation'!
forms: anArray
	^self basicNew setForms: anArray! !

!SchemeOrNode methodsFor: 'running'!
setForms: anArray
	forms := anArray!
exec: m
	^self run: 1 env: m env m: m!
run: i env: env m: m
	| n j f v |
	n := forms size. j := i.
	[j < n] whileTrue: [
		f := forms at: j.
		f isSimple
			ifTrue: [
				v := f value: env.
				v == false ifFalse: [m val: v. ^nil]]
			ifFalse: [
				m push: (SchemeOrFrame node: self index: j + 1 env: env).
				m env: env.
				^f].
		j := j + 1].
	m env: env.
	^forms at: n! !

!SchemeDelayNode class methodsFor: 'instance creation'!
body: aNode chain: aBoolean
	^self basicNew setBody: aNode chain: aBoolean! !

!SchemeDelayNode methodsFor: 'running'!
setBody: aNode chain: aBoolean
	body := aNode. chain := aBoolean!
isSimple
	^true!
value: env
	^(SchemePromise node: body env: env) chain: chain; yourself!
exec: m
	m val: (self value: m env).
	^nil! !

!SchemeCaseLambdaNode class methodsFor: 'instance creation'!
lambdas: anArray
	^self basicNew setLambdas: anArray! !

!SchemeCaseLambdaNode methodsFor: 'running'!
setLambdas: anArray
	lambdas := anArray!
isSimple
	^true!
value: env
	^SchemeCaseLambda closures: (lambdas collect: [:each | SchemeClosure lambda: each env: env])!
exec: m
	m val: (self value: m env).
	^nil! !

!SchemeGuardNode class methodsFor: 'instance creation'!
body: aLambdaNode handler: aNode frameSize: n
	^self basicNew setBody: aLambdaNode handler: aNode frameSize: n! !

!SchemeGuardNode methodsFor: 'running'!
setBody: aLambdaNode handler: aNode frameSize: n
	body := aLambdaNode. handler := aNode. frameSize := n!
handler
	^handler!
frameSize
	^frameSize!
exec: m
	| env h saved |
	env := m env.
	saved := m handlers.
	h := SchemeGuardHandler k: m k winders: m winders env: env node: self next: saved.
	m push: (SchemeBlockFrame block: [:mm | mm handlers: saved. nil]).
	m handlers: h.
	^m apply: (body value: env) args: #()! !
