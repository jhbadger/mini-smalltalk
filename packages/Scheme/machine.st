"The machine: the registers (env, val, k, winders, handlers), the loop that runs nodes and resumes frames, procedure
application, errors and handlers, call/cc and dynamic-wind. Nothing here recurses on the Smalltalk stack for a Scheme call, so
Scheme recursion is limited only by memory (a limit of MaxDepth frames is imposed so that runaway recursion ends with
the message maximum recursion depth exceeded, as in MIT Scheme)."

!Scheme methodsFor: 'registers'!
env
	^env!
env: anEnv
	env := anEnv!
val
	^val!
val: anObject
	val := anObject!
k
	^k!
k: aFrame
	k := aFrame!
winders
	^winders!
winders: aWinder
	winders := aWinder!
handlers
	^handlers!
handlers: aHandler
	handlers := aHandler!
globals
	^globals!
macros
	^macros!
output
	"the console output port's stream"
	^output!
push: aFrame
	| d |
	aFrame next: k.
	d := k isNil ifTrue: [1] ifFalse: [k depth + 1].
	d > 400000 ifTrue: [^SchemeAbort new signal: 'Aborting!!: maximum recursion depth exceeded'].
	aFrame depth: d.
	k := aFrame!
freshSymbolFor: aSymbol
	"a symbol that has not been used before, named after aSymbol"
	counter := counter + 1.
	^(aSymbol asString, '.', counter printString) asSymbol!
outPort
	^outParam value!
inPort
	^inParam value! !

!Scheme methodsFor: 'applying'!
apply: f args: args
	"apply a procedure to an Array of arguments: answer the node to run next, or nil when val is ready"
	| c |
	c := f class.
	c == SchemeClosure ifTrue: [^self applyClosure: f args: args].
	c == SchemePrimitive ifTrue: [^self applyPrimitive: f args: args].
	c == SchemeContinuation ifTrue: [^self throwTo: f args: args].
	c == SchemeParameter ifTrue: [
		args isEmpty ifFalse: [^self arityError: f count: args size].
		val := f value.
		^nil].
	c == SchemeCaseLambda ifTrue: [^self applyCaseLambda: f args: args].
	c == BlockClosure ifTrue: [
		f numArgs = args size ifFalse: [^SchemeError message: 'The Smalltalk block takes a different number of arguments:' with: args size].
		val := f valueWithArguments: args.
		val isNil ifTrue: [val := SchemeUnspec].
		^nil].
	^SchemeError message: 'The object ', (SchemePrinter write: f), ' is not applicable.'!
arityError: f count: n
	| need |
	f class == SchemePrimitive
		ifTrue: [
			need := f max isNil
				ifTrue: ['at least ', f min printString, (f min = 1 ifTrue: [' argument'] ifFalse: [' arguments'])]
				ifFalse: [
					f min = f max
						ifTrue: ['exactly ', f min printString, (f min = 1 ifTrue: [' argument'] ifFalse: [' arguments'])]
						ifFalse: ['between ', f min printString, ' and ', f max printString, ' arguments']]]
		ifFalse: [
			f class == SchemeClosure
				ifTrue: [need := f lambda arityText]
				ifFalse: [need := 'no arguments']].
	^SchemeError message: 'The procedure ', (SchemePrinter write: f), ' has been called with ', n printString,
		(n = 1 ifTrue: [' argument'] ifFalse: [' arguments']), '; it requires ', need, '.'!
applyClosure: f args: args
	| lam n fr nreq rest |
	lam := f lambda.
	n := args size.
	nreq := lam nreq.
	fr := Array new: lam frameSize.
	fr at: 1 put: f env.
	lam hasRest
		ifFalse: [
			n = nreq ifFalse: [^self arityError: f count: n].
			1 to: n do: [:i | fr at: i + 1 put: (args at: i)]]
		ifTrue: [
			n < nreq ifTrue: [^self arityError: f count: n].
			1 to: nreq do: [:i | fr at: i + 1 put: (args at: i)].
			rest := SchemeNil.
			n to: nreq + 1 by: -1 do: [:i | rest := SchemePair car: (args at: i) cdr: rest].
			fr at: nreq + 2 put: rest].
	env := fr.
	^lam body!
applyPrimitive: p args: args
	| n kind b |
	n := args size.
	(n >= p min and: [p max isNil or: [n <= p max]]) ifFalse: [^self arityError: p count: n].
	kind := p kind.
	b := p block.
	kind == #fixed ifTrue: [
		n = 1 ifTrue: [val := b value: (args at: 1). ^nil].
		n = 2 ifTrue: [val := b value: (args at: 1) value: (args at: 2). ^nil].
		n = 0 ifTrue: [val := b value. ^nil].
		n = 3 ifTrue: [val := b value: (args at: 1) value: (args at: 2) value: (args at: 3). ^nil].
		val := b valueWithArguments: args.
		^nil].
	kind == #rest ifTrue: [val := b value: args. ^nil].
	kind == #machine ifTrue: [^b value: self value: args].
	"#value: the machine and the arguments, answering a value"
	val := b value: self value: args.
	^nil!
applyCaseLambda: f args: args
	| n |
	n := args size.
	f closures do: [:c |
		| lam |
		lam := c lambda.
		(lam hasRest ifTrue: [n >= lam nreq] ifFalse: [n = lam nreq]) ifTrue: [^self applyClosure: c args: args]].
	^SchemeError message: 'case-lambda: no clause accepts' with: (SchemePair fromArray: args)!
throwTo: cont args: args
	| v |
	v := args size = 1 ifTrue: [args at: 1] ifFalse: [SchemeValues items: args].
	^self rewindTo: cont winders then: [k := cont k. handlers := cont handlers. val := v. nil]! !

!Scheme methodsFor: 'running'!
drive: startNode
	"run nodes and resume frames until the continuation is empty, then answer val"
	| node f |
	node := startNode.
	[true] whileTrue: [
		[node notNil] whileTrue: [node := node exec: self].
		k isNil ifTrue: [^val].
		f := k.
		k := f next.
		node := f resume: self]!
runNode: aNode
	"run a compiled top-level form to its value; registers are saved and restored, so this may be used re-entrantly"
	| savedK savedW savedH savedE node done result |
	savedK := k. savedW := winders. savedH := handlers. savedE := env.
	k := nil. winders := nil. handlers := nil. env := nil.
	[[
		node := aNode. done := false.
		[done] whileFalse: [
			[result := self drive: node. done := true]
				on: Error
				do: [:e | node := self nodeForError: e. e return: nil]]]
		on: SchemeAbort
		do: [:e |
			k := nil. winders := nil. handlers := nil.
			^SchemeError new payload: (SchemeCondition message: e messageText irritants: SchemeNil kind: #abort); signal]]
		ensure: [k := savedK. winders := savedW. handlers := savedH. env := savedE].
	^result!
nodeForError: e
	"an error from Smalltalk code (a failed primitive, say) becomes a Scheme raise, and the node for the handler to run"
	| payload |
	payload := (e isKindOf: SchemeError)
		ifTrue: [e payload]
		ifFalse: [SchemeCondition message: e messageText irritants: SchemeNil].
	^self doRaise: payload continuable: false! !

!Scheme methodsFor: 'errors'!
doRaise: obj continuable: cont
	"call the innermost handler with obj; with none, the error leaves the machine as a SchemeError"
	| h saved |
	h := handlers.
	h isNil ifTrue: [^SchemeError raise: obj].
	h isGuard ifTrue: [^self unwindToGuard: h with: obj].
	saved := handlers.
	self push: (SchemeBlockFrame block: [:m |
		m handlers: saved.
		cont
			ifTrue: [nil]
			ifFalse: [
				"the handler returned from a non-continuable raise: pass it on to the next handler out"
				m handlers: h next.
				m doRaise: obj continuable: false]]).
	handlers := h next.
	^self apply: h proc args: (Array with: obj)!
unwindToGuard: h with: obj
	^self rewindTo: h winders then: [
		| gnode frame |
		k := h k.
		handlers := h next.
		gnode := h node.
		frame := Array new: gnode frameSize.
		frame at: 1 put: h env.
		frame at: 2 put: obj.
		env := frame.
		gnode handler]! !

!Scheme methodsFor: 'winding'!
depthOfWinder: w
	^w isNil ifTrue: [0] ifFalse: [w depth]!
windSteps: from to: to
	"the thunks to run to get from one dynamic extent to another: the afters on the way out, then the befores on the way in.
	Each step is (thunk, winders while it runs, winders after it)."
	| steps a b downs |
	steps := OrderedCollection new. downs := OrderedCollection new.
	a := from. b := to.
	[(self depthOfWinder: a) > (self depthOfWinder: b)] whileTrue: [
		steps add: (Array with: a after with: a next with: a next).
		a := a next].
	[(self depthOfWinder: b) > (self depthOfWinder: a)] whileTrue: [
		downs addFirst: b.
		b := b next].
	[a ~~ b] whileTrue: [
		steps add: (Array with: a after with: a next with: a next).
		a := a next.
		downs addFirst: b.
		b := b next].
	downs do: [:w | steps add: (Array with: w before with: w next with: w)].
	^steps!
rewindTo: target then: aBlock
	"run the after and before thunks between the current dynamic extent and target, then the block (which answers a node)"
	winders == target ifTrue: [^aBlock value].
	^self runSteps: (self windSteps: winders to: target) index: 1 target: target then: aBlock!
runSteps: steps index: i target: target then: aBlock
	| s |
	i > steps size ifTrue: [winders := target. ^aBlock value].
	s := steps at: i.
	winders := s at: 2.
	self push: (SchemeBlockFrame block: [:m |
		m winders: (s at: 3).
		m runSteps: steps index: i + 1 target: target then: aBlock]).
	^self apply: (s at: 1) args: #()!
dynamicWind: before thunk: thunk after: after
	self push: (SchemeBlockFrame block: [:m | m enterWinder: before thunk: thunk after: after]).
	^self apply: before args: #()!
enterWinder: before thunk: thunk after: after
	winders := SchemeWinder before: before after: after next: winders.
	self push: (SchemeBlockFrame block: [:m |
		| saved |
		saved := m val.
		m winders: m winders next.
		m push: (SchemeBlockFrame block: [:mm | mm val: saved. nil]).
		m apply: after args: #()]).
	^self apply: thunk args: #()! !

!Scheme methodsFor: 'control'!
callCC: f
	^self apply: f args: (Array with: (SchemeContinuation k: k winders: winders handlers: handlers))!
callWithValues: producer consumer: consumer
	self push: (SchemeBlockFrame block: [:m |
		| v |
		v := m val.
		m apply: consumer args: (v class == SchemeValues ifTrue: [v items] ifFalse: [Array with: v])]).
	^self apply: producer args: #()!
withHandler: handler thunk: thunk
	| saved |
	saved := handlers.
	self push: (SchemeBlockFrame block: [:m | m handlers: saved. nil]).
	handlers := SchemeHandler proc: handler next: saved.
	^self apply: thunk args: #()!
force: p
	p class == SchemePromise ifFalse: [val := p. ^nil].
	p isDone ifTrue: [val := p value. ^nil].
	self push: (SchemeBlockFrame block: [:m | m forceResume: p]).
	env := p env.
	^p node!
forceResume: p
	"val is what the body of the promise answered"
	| q |
	p isDone ifTrue: [val := p value. ^nil].
	(p chain and: [val class == SchemePromise]) ifTrue: [
		q := val.
		self push: (SchemeBlockFrame block: [:m |
			p isDone ifFalse: [p finish: m val].
			m val: p value.
			nil]).
		^self force: q].
	p finish: val.
	^nil! !

!Scheme methodsFor: 'evaluating'!
compileForms: aString
	"the data in the text"
	^SchemeReader readAll: aString!
evalString: aString
	"every form in the text is compiled and run in turn: the value of the last (SchemeUnspec for no forms)"
	| result |
	result := SchemeUnspec.
	[(SchemeReader readAll: aString) do: [:form |
		result := self runNode: (self compileTop: form)]]
			on: SchemeExit do: [:e | ^e value].
	^result!
evalDatum: aDatum
	^self runNode: (self compileTop: aDatum)!
applyProcedure: f to: args
	"call a Scheme procedure from Smalltalk with an Array of arguments"
	^self runNode: (SchemeAppNode parts: (Array with: (SchemeConst value: f)) , (args collect: [:a | SchemeConst value: a]))! !
