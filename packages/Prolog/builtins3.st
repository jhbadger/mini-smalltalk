"Prolog built-in predicates, part 3: output and input, format, listing, statistics, and the bridge to Smalltalk."

!PrologEngine methodsFor: 'output'!
biWrite: a
	self out: (self textOf: (a at: 1) quoted: false).
	^true!
biWriteln: a
	self out: (self textOf: (a at: 1) quoted: false), (String with: Character lf).
	^true!
biPrint: a
	self out: (self textOf: (a at: 1) quoted: true).
	^true!
biWriteq: a
	self out: (self textOf: (a at: 1) quoted: true).
	^true!
biWriteCanonical: a
	self out: ((self writer quoted: true; ignoreOps: true; numberVars: false; yourself) stringFor: (a at: 1)).
	^true!
biWriteTerm: a
	| w opts |
	w := self writer.
	w numberVars: false.
	(self listToArray: (a at: 2)) do: [:o |
		| opt v |
		opt := o plDeref.
		(opt isPrologStruct and: [opt arity = 1]) ifTrue: [
			v := opt first plDeref == #true.
			opt functor == #quoted ifTrue: [w quoted: v].
			opt functor == #ignore_ops ifTrue: [w ignoreOps: v].
			opt functor == #numbervars ifTrue: [w numberVars: v]]].
	self out: (w stringFor: (a at: 1)).
	^true!
biWrite2: a
	^self biWrite: (Array with: (a at: 2))!
biWriteln2: a
	^self biWriteln: (Array with: (a at: 2))!
biWrite2q: a
	^self biWriteq: (Array with: (a at: 2))!
biNl0: a
	self out: (String with: Character lf).
	^true!
biNl1: a
	^self biNl0: a!
biTab: a
	| n |
	n := self eval: (a at: 1).
	n isInteger ifFalse: [^self typeError: #integer culprit: n].
	self out: (String new: (n max: 0) withAll: $ ).
	^true!
biTab2: a
	^self biTab: (Array with: (a at: 2))!
biPutChar: a
	self out: (self textFor: (a at: 1)).
	^true!
biPutChar2: a
	^self biPutChar: (Array with: (a at: 2))!
biPortrayClause: a
	self out: (self portrayClause: (a at: 1)).
	^true!
biWithOutputTo: a
	| sink old ok text spec |
	sink := (a at: 1) plDeref.
	(sink isPrologStruct and: [sink arity = 1]) ifFalse: [^self domainError: #output_sink culprit: sink].
	old := output.
	output := WriteStream on: String new.
	[ok := self solveOnce: (a at: 2)] ensure: [text := output contents. output := old].
	ok ifFalse: [^false].
	spec := sink functor.
	spec == #atom ifTrue: [^self unify: sink first with: text asSymbol].
	spec == #string ifTrue: [^self unify: sink first with: text].
	spec == #codes ifTrue: [^self unify: sink first with: (self codesOf: text)].
	spec == #chars ifTrue: [^self unify: sink first with: (self charsOf: text)].
	^self domainError: #output_sink culprit: sink! !

!PrologEngine methodsFor: 'listing'!
bindVariablesOf: t
	"bind the variables of t to '$VAR'(N), numbering from 0"
	| acc n |
	acc := OrderedCollection new.
	self variablesOf: t into: acc.
	n := 0.
	acc do: [:v | self bind: v to: (PrologStruct functor: #'$VAR' with: n). n := n + 1]!
conjunctsOf: t into: acc
	| x |
	x := t plDeref.
	(x isPrologStruct and: [x functor == #',' and: [x arity = 2]])
		ifTrue: [self conjunctsOf: x first into: acc. self conjunctsOf: x second into: acc]
		ifFalse: [acc add: x]!
portrayClause: t
	"the clause as source text, ending in a full stop and a newline; variables are named A, B, ..."
	| mark head body w out goals lf |
	mark := trail size.
	lf := String with: Character lf.
	self bindVariablesOf: t.
	w := self writer quoted: true; numberVars: true; yourself.
	out := WriteStream on: String new.
	head := self splitClause: t.
	body := (head at: 2) plDeref.
	head := (head at: 1).
	out nextPutAll: (w stringFor: head prec: 999).
	body == #true
		ifFalse: [
			goals := OrderedCollection new.
			self conjunctsOf: body into: goals.
			out nextPutAll: ' :-'.
			goals doWithIndex: [:g :i |
				out nextPutAll: lf; nextPutAll: '    '; nextPutAll: (w stringFor: g prec: 999).
				i < goals size ifTrue: [out nextPut: $,]]].
	out nextPut: $.; nextPutAll: lf.
	self undoTo: mark.
	^out contents!
listPredicate: p on: out
	p isDynamic ifTrue: [out nextPutAll: ':- dynamic '; nextPutAll: (self textOf: p name quoted: true); nextPut: $/; print: p arity; nextPut: $.; nextPut: Character lf; nextPut: Character lf].
	p clauses do: [:c |
		| t |
		t := self clauseTermsOf: c.
		out nextPutAll: (self portrayClause: (PrologStruct functor: #':-' with: (t at: 1) with: (t at: 2)))].
	out nextPut: Character lf!
biListing: a
	| spec name arity out |
	spec := (a at: 1) plDeref.
	spec isPrologVar ifTrue: [^self instantiationError].
	(spec isPrologStruct and: [spec functor == #'/' and: [spec arity = 2]])
		ifTrue: [name := spec first plDeref. arity := spec second plDeref]
		ifFalse: [name := spec. arity := nil].
	out := WriteStream on: String new.
	self predicatesDo: [:p |
		(p name == name and: [(arity isNil or: [arity isInteger not]) or: [p arity = arity]]) ifTrue: [self listPredicate: p on: out]].
	self out: out contents.
	^true!
biListing0: a
	| out |
	out := WriteStream on: String new.
	self predicatesDo: [:p | p isLibrary ifFalse: [self listPredicate: p on: out]].
	self out: out contents.
	^true! !

!PrologEngine methodsFor: 'format'!
formatError: aMessage
	^self throwFormal: (PrologStruct functor: #format with: aMessage)!
formatFloat: x digits: n
	"~Nf: x with n digits after the point"
	| scaled s neg point |
	neg := x < 0.
	scaled := (x isInteger ifTrue: [x abs * (10 raisedTo: n)] ifFalse: [(x abs * (10 raisedTo: n)) rounded]).
	s := scaled printString.
	n > 0 ifTrue: [
		[s size <= n] whileTrue: [s := '0', s].
		s := (s copyFrom: 1 to: s size - n), '.', (s copyFrom: s size - n + 1 to: s size)].
	^(neg and: [scaled > 0]) ifTrue: ['-', s] ifFalse: [s]!
formatExp: x digits: n
	"~Ne: scientific notation"
	| f e m s |
	f := x asFloat.
	f = 0 ifTrue: [^(self formatFloat: 0 digits: n), 'e+00'].
	e := f abs log floor.
	m := f abs / (10 raisedTo: e).
	(m roundTo: 1 / (10 raisedTo: n)) >= 10 ifTrue: [e := e + 1. m := f abs / (10 raisedTo: e)].
	s := self formatFloat: m digits: n.
	^(f < 0 ifTrue: ['-'] ifFalse: ['']), s, 'e', (e < 0 ifTrue: ['-'] ifFalse: ['+']), (e abs printPaddedWith: $0 to: 2)!
groupDigits: s
	"1234567 -> 1,234,567"
	| out n |
	out := WriteStream on: String new.
	n := s size.
	s doWithIndex: [:c :i |
		(i > 1 and: [(n - i + 1) \\ 3 = 0]) ifTrue: [out nextPut: $,].
		out nextPut: c].
	^out contents!
formatString: fmt args: argsTerm
	^(PrologFormatter engine: self args: argsTerm) run: fmt!
biFormat1: a
	self out: (self formatString: (self textFor: (a at: 1)) args: #'[]').
	^true!
biFormat2: a
	self out: (self formatString: (self textFor: (a at: 1)) args: (a at: 2)).
	^true!
biFormat3: a
	| sink text spec |
	sink := (a at: 1) plDeref.
	text := self formatString: (self textFor: (a at: 2)) args: (a at: 3).
	(sink isPrologStruct and: [sink arity = 1]) ifTrue: [
		spec := sink functor.
		spec == #atom ifTrue: [^self unify: sink first with: text asSymbol].
		spec == #string ifTrue: [^self unify: sink first with: text].
		spec == #codes ifTrue: [^self unify: sink first with: (self codesOf: text)].
		spec == #chars ifTrue: [^self unify: sink first with: (self charsOf: text)]].
	self out: text.
	^true! !

!PrologEngine methodsFor: 'input'!
readTermFrom: aReader
	| t |
	aReader isNil ifTrue: [^#end_of_file].
	t := aReader readTerm.
	^t isNil ifTrue: [#end_of_file] ifFalse: [t]!
biRead: a
	^self unify: (a at: 1) with: (self readTermFrom: input)!
biReadTerm: a
	^self unify: (a at: 1) with: (self readTermFrom: input)!
biRead2: a
	^self unify: (a at: 2) with: (self readTermFrom: input)!
biReadTerm3: a
	^self unify: (a at: 2) with: (self readTermFrom: input)! !

!PrologEngine methodsFor: 'system'!
biStatistics: a
	| k ms |
	k := (a at: 1) plDeref.
	ms := Time millisecondClock.
	(k == #runtime or: [k == #cputime or: [k == #process_cputime or: [k == #walltime or: [k == #real_time]]]]) ifFalse: [
		k isSymbol ifFalse: [^self typeError: #atom culprit: k].
		^self unify: (a at: 2) with: (PrologStruct list: (Array with: 0 with: 0))].
	k == #cputime ifTrue: [^self unify: (a at: 2) with: ms / 1000.0].
	^self unify: (a at: 2) with: (PrologStruct list: (Array with: ms with: 0))!
biGetTime: a
	^self unify: (a at: 1) with: Smalltalk microsecondClock / 1000000.0!
biSleep: a
	(Delay forMilliseconds: ((self eval: (a at: 1)) * 1000) rounded) wait.
	^true!
biRandom: a
	^self unify: (a at: 1) with: Random default next!
biRandomBetween: a
	| l h |
	l := self eval: (a at: 1). h := self eval: (a at: 2).
	h < l ifTrue: [^false].
	^self unify: (a at: 3) with: l + (Random default nextInt: h - l + 1) - 1! !

"---- the bridge to Smalltalk ----"

!PrologEngine methodsFor: 'smalltalk bridge'!
toSmalltalk: aTerm
	"a Prolog term as a Smalltalk object: lists become Arrays, true/false/nil become the Smalltalk objects"
	| x |
	x := aTerm plDeref.
	x isPrologVar ifTrue: [^x].
	x == #true ifTrue: [^true].
	x == #false ifTrue: [^false].
	x == #nil ifTrue: [^nil].
	x == #'[]' ifTrue: [^Array new].
	(x isPrologStruct and: [x isList]) ifTrue: [^(self listToArray: x) collect: [:e | self toSmalltalk: e]].
	^x!
fromSmalltalk: anObject
	"a Smalltalk object as a Prolog term: collections become lists; other objects stay as opaque constants"
	anObject isNil ifTrue: [^#nil].
	anObject == true ifTrue: [^#true].
	anObject == false ifTrue: [^#false].
	anObject isInteger ifTrue: [^anObject].
	anObject isFloat ifTrue: [^anObject].
	anObject isSymbol ifTrue: [^anObject].
	anObject isString ifTrue: [^anObject].
	anObject isCharacter ifTrue: [^anObject asString asSymbol].
	anObject isFraction ifTrue: [^anObject asFloat].
	(anObject isPrologVar or: [anObject isPrologStruct]) ifTrue: [^anObject].
	anObject isAssociation ifTrue: [^PrologStruct functor: #'-' with: (self fromSmalltalk: anObject key) with: (self fromSmalltalk: anObject value)].
	(anObject isCollection and: [anObject isDictionary not]) ifTrue: [^PrologStruct list: (anObject asArray collect: [:e | self fromSmalltalk: e])].
	^anObject!
refFromSmalltalk: anObject
	"like fromSmalltalk:, but objects other than numbers, strings, symbols, characters, booleans and nil stay as they are
	(a collection stays a Smalltalk collection instead of becoming a Prolog list)"
	(anObject isNil or: [anObject == true or: [anObject == false or: [anObject isNumber or: [anObject isString or: [anObject isCharacter]]]]])
		ifTrue: [^self fromSmalltalk: anObject].
	^anObject!
smalltalkFailure: e
	^self throwFormal: (PrologStruct functor: #smalltalk_error with: e messageText asString)!
evaluateSmalltalk: aString
	"the value of a Smalltalk expression (statements, ending with the value to answer); errors become Prolog exceptions"
	| value |
	value := [Compiler evaluate: aString onError: [:m | ^self throwFormal: (PrologStruct functor: #syntax_error with: m asString asSymbol)]]
		on: Error do: [:e |
			((e isKindOf: PrologThrow) or: [e isKindOf: PrologHalt]) ifTrue: [e pass].
			^self smalltalkFailure: e].
	^value!
biSmalltalk: a
	^self unify: (a at: 2) with: (self fromSmalltalk: (self evaluateSmalltalk: (self textFor: (a at: 1))))!
biSmalltalk1: a
	^(self evaluateSmalltalk: (self textFor: (a at: 1))) ~~ false!
biSmalltalkSend: a
	| receiver sel args result |
	receiver := self toSmalltalk: (a at: 1).
	sel := self textFor: (a at: 2).
	args := (self listToArray: (a at: 3)) collect: [:e | self toSmalltalk: e].
	sel asSymbol numArgs = args size ifFalse: [^self domainError: #selector_arity culprit: (a at: 2)].
	result := [receiver perform: sel asSymbol withArguments: args]
		on: Error do: [:e |
			((e isKindOf: PrologThrow) or: [e isKindOf: PrologHalt]) ifTrue: [e pass].
			^self smalltalkFailure: e].
	^self unify: (a at: 4) with: (self fromSmalltalk: result)!
biSmalltalkRef: a
	^self unify: (a at: 2) with: (self refFromSmalltalk: (self evaluateSmalltalk: (self textFor: (a at: 1))))!
biSmalltalkSendRef: a
	| receiver sel args result |
	receiver := self toSmalltalk: (a at: 1).
	sel := self textFor: (a at: 2).
	args := (self listToArray: (a at: 3)) collect: [:e | self toSmalltalk: e].
	sel asSymbol numArgs = args size ifFalse: [^self domainError: #selector_arity culprit: (a at: 2)].
	result := [receiver perform: sel asSymbol withArguments: args]
		on: Error do: [:e |
			((e isKindOf: PrologThrow) or: [e isKindOf: PrologHalt]) ifTrue: [e pass].
			^self smalltalkFailure: e].
	^self unify: (a at: 4) with: (self refFromSmalltalk: result)!
biSmalltalkGlobal: a
	| name v |
	name := self textFor: (a at: 1).
	v := Smalltalk at: name asSymbol ifAbsent: [^self existenceError: #smalltalk_global what: name asSymbol].
	^self unify: (a at: 2) with: v!
biSmalltalkPrint: a
	^self unify: (a at: 2) with: (self toSmalltalk: (a at: 1)) printString! !
