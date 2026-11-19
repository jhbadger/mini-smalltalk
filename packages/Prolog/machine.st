"Prolog engine, part 2: unification, the run loop, control constructs, the clause database, consult and DCG translation."

!PrologEngine class methodsFor: 'instance creation'!
new
	^self basicNew init!
atomic: a equals: b
	"equality of two terms that are neither variables nor compounds (an Integer is not a Float, an atom is not a string)"
	a isInteger ifTrue: [^b isInteger and: [a = b]].
	a isFloat ifTrue: [^b isFloat and: [a = b]].
	a isSymbol ifTrue: [^a == b].
	a isString ifTrue: [^b isString and: [b isSymbol not and: [a = b]]].
	^a = b!
ensureBuiltins
	"build the table of control constructs and built-in predicates (shared by all engines)"
	| add |
	Builtins notNil ifTrue: [^self].
	Builtins := Dictionary new.
	add := [:spec :kind |
		1 to: spec size by: 3 do: [:i |
			| name arity row |
			name := (spec at: i) asSymbol. arity := spec at: i + 1.
			row := Builtins at: name ifAbsent: [Builtins at: name put: (Array new: 13)].
			row at: arity + 1 put: (PrologPredicate name: name arity: arity kind: kind selector: (spec at: i + 2))]].
	add value: self controlSpec value: #control.
	add value: self builtinSpec value: #builtin!
isBuiltin: aSymbol arity: n
	| row |
	self ensureBuiltins.
	row := Builtins at: aSymbol ifAbsent: [nil].
	^row notNil and: [n <= 12 and: [(row at: n + 1) notNil]]!
controlSpec
	^#(',' 2 #cAnd:cut: ';' 2 #cOr:cut: '|' 2 #cOr:cut: '->' 2 #cIfThen:cut: '*->' 2 #cSoftIfThen:cut:
	   '\+' 1 #cNot:cut: 'not' 1 #cNot:cut: 'call' 1 #cCall:cut: 'call' 2 #cCall:cut: 'call' 3 #cCall:cut: 'call' 4 #cCall:cut:
	   'call' 5 #cCall:cut: 'call' 6 #cCall:cut: 'call' 7 #cCall:cut: 'call' 8 #cCall:cut:
	   '!!' 0 #cCut:cut: 'true' 0 #cTrue:cut: 'otherwise' 0 #cTrue:cut: 'fail' 0 #cFail:cut: 'false' 0 #cFail:cut:
	   '$cut' 1 #cCutTo:cut: '$softcut' 1 #cSoftCut:cut: '$collect' 2 #cCollect:cut: '$exit_catch' 1 #cExitCatch:cut:
	   'findall' 3 #cFindall:cut: 'findall' 4 #cFindall:cut: 'catch' 3 #cCatch:cut: 'forall' 2 #cForall:cut:
	   'once' 1 #cOnce:cut: 'ignore' 1 #cIgnore:cut: 'phrase' 2 #cPhrase:cut: 'phrase' 3 #cPhrase:cut:)! !

!PrologEngine methodsFor: 'initialization'!
init
	self class ensureBuiltins.
	preds := Dictionary new. ops := PrologOps new. flags := Dictionary new.
	flags at: #double_quotes put: #string; at: #unknown put: #error; at: #occurs_check put: #false.
	choices := OrderedCollection new. trail := OrderedCollection new. globals := Dictionary new.
	loadingLibrary := false. started := false!
ops
	^ops!
flags
	^flags!
globals
	^globals!
output
	^output!
output: aStream
	"where write/1 and friends send their text: a WriteStream, or nil for the Transcript"
	output := aStream!
input
	^input!
input: aStringOrStream
	"text that read/1 reads terms from"
	input := aStringOrStream isString ifTrue: [PrologReader on: aStringOrStream ops: ops flags: flags] ifFalse: [aStringOrStream]!
loadingLibrary: aBoolean
	loadingLibrary := aBoolean!
out: aString
	output isNil ifTrue: [Transcript show: aString] ifFalse: [output nextPutAll: aString]!
writer
	^PrologWriter new ops: ops; yourself!
textOf: aTerm quoted: aBoolean
	^(self writer quoted: aBoolean; yourself) stringFor: aTerm! !

!PrologEngine methodsFor: 'unification'!
bind: aVar to: aTerm
	aVar value: aTerm.
	trail addLast: aVar!
undoTo: mark
	[trail size > mark] whileTrue: [trail removeLast value: nil]!
trailMark
	^trail size!
unify: a with: b
	| x y n |
	x := a plDeref. y := b plDeref.
	[x == y ifTrue: [^true].
	 x class == PrologVar ifTrue: [self bind: x to: y. ^true].
	 y class == PrologVar ifTrue: [self bind: y to: x. ^true].
	 x class == PrologStruct ifFalse: [^y class ~~ PrologStruct and: [PrologEngine atomic: x equals: y]].
	 y class == PrologStruct ifFalse: [^false].
	 x functor == y functor ifFalse: [^false].
	 n := x args size.
	 n = y args size ifFalse: [^false].
	 1 to: n - 1 do: [:i | (self unify: (x args basicAt: i) with: (y args basicAt: i)) ifFalse: [^false]].
	 x := (x args basicAt: n) plDeref. y := (y args basicAt: n) plDeref.
	 true] whileTrue.
	^false!
instantiate: t vars: vars
	"a copy of a stored clause term with its argument slots filled by (new) variables"
	| c |
	c := t class.
	c == PrologArg ifTrue: [^(vars basicAt: t index) ifNil: [vars basicAt: t index put: PrologVar new]].
	c == PrologStruct ifTrue: [
		t isGround ifTrue: [^t].
		^(PrologStruct functor: t functor args: (t args collect: [:a | self instantiate: a vars: vars])) source: t; yourself].
	^t!
unifyHead: pat with: t vars: vars
	"unify a stored head argument with a call argument, binding the clause's slots in vars"
	| x cur n |
	pat class == PrologArg ifTrue: [
		cur := vars basicAt: pat index.
		cur isNil ifTrue: [vars basicAt: pat index put: t. ^true].
		^self unify: cur with: t].
	x := t plDeref.
	pat class == PrologStruct ifTrue: [
		x class == PrologVar ifTrue: [self bind: x to: (self instantiate: pat vars: vars). ^true].
		x class == PrologStruct ifFalse: [^false].
		x functor == pat functor ifFalse: [^false].
		n := pat args size.
		n = x args size ifFalse: [^false].
		1 to: n do: [:i | (self unifyHead: (pat args basicAt: i) with: (x args basicAt: i) vars: vars) ifFalse: [^false]].
		^true].
	x class == PrologVar ifTrue: [self bind: x to: pat. ^true].
	^x class ~~ PrologStruct and: [PrologEngine atomic: pat equals: x]!
copy: t map: map
	"a copy of a term with fresh variables (sharing preserved through map)"
	| x |
	x := t plDeref.
	x isPrologVar ifTrue: [^map at: x ifAbsent: [map at: x put: PrologVar new]].
	x isPrologStruct ifFalse: [^x].
	^PrologStruct functor: x functor args: (x args collect: [:a | self copy: a map: map])!
copyTerm: t
	^self copy: t map: IdentityDictionary new! !

!PrologEngine methodsFor: 'errors'!
throwFormal: aTerm
	^PrologThrow ball: (PrologStruct functor: #error with: aTerm with: PrologVar new)!
instantiationError
	^self throwFormal: #instantiation_error!
typeError: aType culprit: aTerm
	^self throwFormal: (PrologStruct functor: #type_error with: aType asSymbol with: aTerm)!
domainError: aDomain culprit: aTerm
	^self throwFormal: (PrologStruct functor: #domain_error with: aDomain asSymbol with: aTerm)!
existenceError: aKind what: aTerm
	^self throwFormal: (PrologStruct functor: #existence_error with: aKind asSymbol with: aTerm)!
permissionError: anAction type: aType culprit: aTerm
	^self throwFormal: (PrologStruct functor: #permission_error with: anAction asSymbol with: aType asSymbol with: aTerm)!
evaluationError: aWhat
	^self throwFormal: (PrologStruct functor: #evaluation_error with: aWhat asSymbol)!
indicator: aSymbol arity: n
	^PrologStruct functor: #'/' with: aSymbol with: n!
unknownProcedure: f arity: n
	(flags at: #unknown ifAbsent: [#error]) == #fail ifTrue: [^false].
	^self existenceError: #procedure what: (self indicator: f arity: n)!
warning: aBall
	"report an uncaught exception from a directive or while loading"
	self out: 'Warning: ', (self describeBall: aBall), (String with: Character lf)!
describeBall: aBall
	"readable text for an exception: error(Formal, _) in the usual words, any other ball as 'Unhandled exception'"
	| b f g q |
	b := aBall plDeref.
	q := [:t | '`', (self textOf: t quoted: true), (String with: $')].
	(b isPrologStruct and: [b functor == #error and: [b arity = 2]]) ifFalse: [^'Unhandled exception: ', (self textOf: b quoted: true)].
	f := b first plDeref.
	f == #instantiation_error ifTrue: [^'Arguments are not sufficiently instantiated'].
	f isPrologStruct ifFalse: [^self textOf: f quoted: true].
	g := f functor.
	(g == #existence_error and: [f arity = 2]) ifTrue: [
		f first plDeref == #procedure ifTrue: [^'Unknown procedure: ', (self textOf: f second quoted: true)].
		^'Unknown ', (self textOf: f first quoted: false), ': ', (self textOf: f second quoted: true)].
	(g == #type_error and: [f arity = 2]) ifTrue: [
		f first plDeref == #evaluable ifTrue: [^'Arithmetic: evaluable ', (q value: f second), ' does not exist'].
		^'Type error: ', (q value: f first), ' expected, found ', (q value: f second)].
	(g == #domain_error and: [f arity = 2]) ifTrue: [^'Domain error: ', (q value: f first), ' expected, found ', (q value: f second)].
	(g == #evaluation_error and: [f arity = 1]) ifTrue: [^'Arithmetic: evaluation error: ', (self textOf: f first quoted: false)].
	(g == #permission_error and: [f arity = 3]) ifTrue: [^'No permission to ', (self textOf: f first quoted: false), ' ', (self textOf: f second quoted: false), ' ', (q value: (f args at: 3))].
	(g == #syntax_error and: [f arity = 1]) ifTrue: [^'Syntax error: ', (self textOf: f first quoted: false)].
	(g == #smalltalk_error and: [f arity = 1]) ifTrue: [^'Smalltalk error: ', (self textOf: f first quoted: false)].
	(g == #format and: [f arity = 1]) ifTrue: [^'Format error: ', (self textOf: f first quoted: false)].
	^self textOf: f quoted: true! !

!PrologEngine methodsFor: 'running'!
solveOnce: goal
	"true if goal has a solution (the bindings are kept); safe to use while another query is running"
	| saved result |
	saved := Array with: frame with: choices with: started.
	frame := PrologFrame goal: goal next: nil cutBarrier: 0.
	choices := OrderedCollection new.
	[result := self run] ensure: [frame := saved at: 1. choices := saved at: 2. started := saved at: 3].
	^result!
solve: goal
	"prepare to enumerate the solutions of goal with #nextSolution (one query at a time per engine)"
	frame := PrologFrame goal: goal next: nil cutBarrier: 0.
	choices := OrderedCollection new.
	started := false!
nextSolution
	"true if there is another solution (the goal's variables are bound), false when there are no more"
	started ifFalse: [started := true. ^self run].
	self backtrack ifFalse: [^false].
	^self run!
run
	"run until the continuation is empty (a solution: true) or there is nothing left to try (false)"
	| result |
	[result := self runLoop] on: PrologThrow do: [:e |
		(self handleBall: e ball) ifTrue: [e retry] ifFalse: [e pass]].
	^result!
runLoop
	| f goal |
	[true] whileTrue: [
		frame isNil ifTrue: [^true].
		f := frame.
		frame := f next.
		goal := f goal plDeref.
		(self step: goal cut: f cutBarrier) ifFalse: [self backtrack ifFalse: [^false]]].
	^false!
step: goal cut: cutB
	| f args pred holder |
	goal class == PrologStruct
		ifTrue: [f := goal functor. args := goal args]
		ifFalse: [
			goal class == PrologVar ifTrue: [^self instantiationError].
			goal isSymbol ifFalse: [^self typeError: #callable culprit: goal].
			f := goal. args := #().
			pred := self lookup: f arity: 0.
			pred isNil ifTrue: [^self unknownProcedure: f arity: 0].
			^self dispatch: pred args: args cut: cutB].
	holder := goal source ifNil: [goal].
	pred := holder cachedPredicate.
	pred isNil ifTrue: [
		pred := self lookup: f arity: args size.
		pred isNil ifTrue: [^self unknownProcedure: f arity: args size].
		holder cachedPredicate: pred].
	^self dispatch: pred args: args cut: cutB!
dispatch: pred args: args cut: cutB
	pred kind == #user ifTrue: [^self callUser: pred args: args].
	pred kind == #control ifTrue: [^self perform: pred selector with: args with: cutB].
	pred kind == #block ifTrue: [^(pred block value: self value: args) == true].
	^self perform: pred selector with: args!
lookup: f arity: n
	| row |
	n > 12 ifTrue: [^nil].
	row := Builtins at: f ifAbsent: [nil].
	row notNil ifTrue: [(row at: n + 1) notNil ifTrue: [^row at: n + 1]].
	row := preds at: f ifAbsent: [nil].
	^row isNil ifTrue: [nil] ifFalse: [row at: n + 1]!
callUser: pred args: args
	| clauses first i |
	clauses := pred clauses.
	clauses isEmpty ifTrue: [^false].
	first := args isEmpty ifTrue: [nil] ifFalse: [(args at: 1) plDeref].
	i := self nextClause: 1 in: clauses for: first.
	i = 0 ifTrue: [^false].
	^self tryClauses: clauses from: i args: args cont: frame height: choices size!
nextClause: start in: clauses for: first
	start to: clauses size do: [:k | ((clauses basicAt: k) couldMatch: first) ifTrue: [^k]].
	^0!
tryClauses: clauses from: i args: args cont: cont height: h
	| idx next clause vars mark first pushed pats gs |
	first := args isEmpty ifTrue: [nil] ifFalse: [(args basicAt: 1) plDeref].
	idx := i.
	mark := trail size.
	[idx > 0] whileTrue: [
		clause := clauses basicAt: idx.
		next := self nextClause: idx + 1 in: clauses for: first.
		pushed := next > 0.
		pushed ifTrue: [self pushClauseChoice: clauses index: next args: args cont: cont height: h].
		vars := Array new: clause nvars.
		pats := clause headArgs.
		(self unifyHeadArgs: pats with: args vars: vars) ifTrue: [
			frame := cont.
			gs := clause goals.
			gs size to: 1 by: -1 do: [:g | frame := PrologFrame goal: (self instantiate: (gs basicAt: g) vars: vars) next: frame cutBarrier: h].
			^true].
		self undoTo: mark.
		pushed ifTrue: [choices removeLast].
		idx := next].
	^false!
unifyHeadArgs: pats with: args vars: vars
	1 to: pats size do: [:k | (self unifyHead: (pats basicAt: k) with: (args basicAt: k) vars: vars) ifFalse: [^false]].
	^true!
pushClauseChoice: clauses index: next args: args cont: cont height: h
	| c |
	c := PrologChoice new.
	c kind: #clauses; trailMark: trail size; frame: cont; clauses: clauses; index: next; data: args; height: h.
	choices addLast: c!
pushGoalChoice: aGoal cutBarrier: cb
	"on backtracking, run aGoal in place of what follows (the current continuation)"
	| c |
	c := PrologChoice new.
	c kind: #goal; trailMark: trail size; frame: frame; goal: aGoal; height: cb.
	choices addLast: c.
	^c!
tryAlts: it cont: cont
	"try the alternatives of an iterator in turn; true as soon as one succeeds"
	| last mark c |
	[it hasNext] whileTrue: [
		last := it isLast.
		mark := trail size.
		last ifFalse: [
			c := PrologChoice new.
			c kind: #alts; trailMark: mark; frame: cont; data: it.
			choices addLast: c].
		(it unifyNext: self) ifTrue: [frame := cont. ^true].
		self undoTo: mark.
		last ifFalse: [choices removeLast]].
	^false!
pushAlternatives: anIterator
	"for a built-in with several solutions: its first (and later) alternatives are tried now and on backtracking"
	^self tryAlts: anIterator cont: frame!
cutTo: height
	[choices size > height] whileTrue: [choices removeLast]!
backtrack
	"resume the most recent alternative; false when there are none"
	| c k |
	[choices isEmpty] whileFalse: [
		c := choices removeLast.
		self undoTo: c trailMark.
		k := c kind.
		k == #clauses ifTrue: [(self tryClauses: c clauses from: c index args: c data cont: c frame height: c height) ifTrue: [^true]].
		k == #goal ifTrue: [frame := PrologFrame goal: c goal next: c frame cutBarrier: c height. ^true].
		k == #alts ifTrue: [(self tryAlts: c data cont: c frame) ifTrue: [^true]].
		k == #findall ifTrue: [(self finishFindall: c) ifTrue: [^true]].
		k == #reactivate ifTrue: [c data active: true]].
	^false!
finishFindall: c
	| list |
	list := PrologStruct list: (c data at: 1) tail: (c data at: 3).
	(self unify: (c data at: 2) with: list) ifTrue: [frame := c frame. ^true].
	^false!
handleBall: ball
	"an exception was thrown: unwind to the innermost active catch/3 whose catcher unifies with the ball; true if there is one"
	| c mark |
	[choices isEmpty] whileFalse: [
		c := choices removeLast.
		(c kind == #catch and: [c active]) ifTrue: [
			self undoTo: c trailMark.
			mark := trail size.
			(self unify: (c data at: 1) with: ball) ifTrue: [
				frame := PrologFrame goal: (c data at: 2) next: c frame cutBarrier: choices size.
				^true].
			self undoTo: mark]].
	^false! !

!PrologEngine methodsFor: 'control'!
cAnd: args cut: cutB
	frame := PrologFrame goal: (args at: 1) next: (PrologFrame goal: (args at: 2) next: frame cutBarrier: cutB) cutBarrier: cutB.
	^true!
cOr: args cut: cutB
	| left h cond |
	left := (args at: 1) plDeref.
	(left isPrologStruct and: [left arity = 2 and: [left functor == #'->']]) ifTrue: [
		h := choices size.
		self pushGoalChoice: (args at: 2) cutBarrier: cutB.
		frame := PrologFrame goal: left first
			next: (PrologFrame goal: (PrologStruct functor: #'$cut' with: h)
				next: (PrologFrame goal: left second next: frame cutBarrier: cutB) cutBarrier: cutB)
			cutBarrier: h + 1.
		^true].
	(left isPrologStruct and: [left arity = 2 and: [left functor == #'*->']]) ifTrue: [
		cond := self pushGoalChoice: (args at: 2) cutBarrier: cutB.
		frame := PrologFrame goal: left first
			next: (PrologFrame goal: (PrologStruct functor: #'$softcut' with: cond)
				next: (PrologFrame goal: left second next: frame cutBarrier: cutB) cutBarrier: cutB)
			cutBarrier: choices size.
		^true].
	self pushGoalChoice: (args at: 2) cutBarrier: cutB.
	frame := PrologFrame goal: left next: frame cutBarrier: cutB.
	^true!
cIfThen: args cut: cutB
	| h |
	h := choices size.
	frame := PrologFrame goal: (args at: 1)
		next: (PrologFrame goal: (PrologStruct functor: #'$cut' with: h)
			next: (PrologFrame goal: (args at: 2) next: frame cutBarrier: cutB) cutBarrier: cutB)
		cutBarrier: h.
	^true!
cSoftIfThen: args cut: cutB
	frame := PrologFrame goal: (args at: 1) next: (PrologFrame goal: (args at: 2) next: frame cutBarrier: cutB) cutBarrier: choices size.
	^true!
cNot: args cut: cutB
	| h |
	h := choices size.
	self pushGoalChoice: #true cutBarrier: cutB.
	frame := PrologFrame goal: (args at: 1)
		next: (PrologFrame goal: (PrologStruct functor: #'$cut' with: h)
			next: (PrologFrame goal: #fail next: nil cutBarrier: 0) cutBarrier: 0)
		cutBarrier: h + 1.
	^true!
cCall: args cut: cutB
	| g |
	g := self addArguments: (args copyFrom: 2 to: args size) to: (args at: 1).
	frame := PrologFrame goal: g next: frame cutBarrier: choices size.
	^true!
addArguments: extra to: aGoal
	"call/N: the goal with extra arguments appended"
	| g |
	g := aGoal plDeref.
	extra isEmpty ifTrue: [^g].
	g isPrologVar ifTrue: [^self instantiationError].
	g isSymbol ifTrue: [^PrologStruct functor: g args: extra].
	g isPrologStruct ifTrue: [^PrologStruct functor: g functor args: g args, extra].
	^self typeError: #callable culprit: g!
cCut: args cut: cutB
	self cutTo: cutB.
	^true!
cTrue: args cut: cutB
	^true!
cFail: args cut: cutB
	^false!
cCutTo: args cut: cutB
	self cutTo: (args at: 1).
	^true!
cSoftCut: args cut: cutB
	(args at: 1) kind: #dead.
	^true!
cCollect: args cut: cutB
	"inside findall: record a copy of the template and fail to get the next solution"
	((args at: 2) add: (self copyTerm: (args at: 1))).
	^false!
cFindall: args cut: cutB
	| c acc |
	acc := OrderedCollection new.
	c := PrologChoice new.
	c kind: #findall; trailMark: trail size; frame: frame; data: (Array with: acc with: (args at: 3) with: (args size = 4 ifTrue: [args at: 4] ifFalse: [#'[]'])).
	choices addLast: c.
	frame := PrologFrame goal: (args at: 2)
		next: (PrologFrame goal: (PrologStruct functor: #'$collect' with: (args at: 1) with: acc) next: nil cutBarrier: 0)
		cutBarrier: choices size.
	^true!
cCatch: args cut: cutB
	| c |
	c := PrologChoice new.
	c kind: #catch; trailMark: trail size; frame: frame; data: (Array with: (args at: 2) with: (args at: 3)); height: cutB; active: true.
	choices addLast: c.
	frame := PrologFrame goal: (args at: 1)
		next: (PrologFrame goal: (PrologStruct functor: #'$exit_catch' with: c) next: frame cutBarrier: cutB)
		cutBarrier: choices size.
	^true!
cExitCatch: args cut: cutB
	"the goal of a catch/3 has exited: the catch is no longer active (until we backtrack into the goal)"
	| c r |
	c := args at: 1.
	choices notEmpty ifTrue: [
		choices last == c ifTrue: [choices removeLast. ^true]].
	c active: false.
	r := PrologChoice new.
	r kind: #reactivate; trailMark: trail size; data: c.
	choices addLast: r.
	^true!
cForall: args cut: cutB
	| inner |
	inner := PrologStruct functor: #'\+' with: (PrologStruct functor: #',' with: (args at: 1) with: (PrologStruct functor: #'\+' with: (args at: 2))).
	frame := PrologFrame goal: inner next: frame cutBarrier: cutB.
	^true!
cOnce: args cut: cutB
	frame := PrologFrame goal: (PrologStruct functor: #'->' with: (args at: 1) with: #true) next: frame cutBarrier: cutB.
	^true!
cIgnore: args cut: cutB
	frame := PrologFrame goal: (PrologStruct functor: #';' with: (PrologStruct functor: #'->' with: (args at: 1) with: #true) with: #true) next: frame cutBarrier: cutB.
	^true!
cPhrase: args cut: cutB
	"phrase(Body, List) and phrase(Body, List, Rest): run a DCG body"
	| s0 s goal |
	s0 := (args at: 2) plDeref.
	(s0 isString and: [s0 isSymbol not]) ifTrue: [s0 := self codesOf: s0].
	s := args size = 3 ifTrue: [args at: 3] ifFalse: [#'[]'].
	goal := self dcgBody: (args at: 1) from: s0 to: s.
	frame := PrologFrame goal: goal next: frame cutBarrier: choices size.
	^true! !

!PrologEngine methodsFor: 'database'!
userPredicate: f arity: n create: aBoolean
	| row |
	row := preds at: f ifAbsent: [aBoolean ifTrue: [preds at: f put: (Array new: 13)] ifFalse: [^nil]].
	^(row at: n + 1) ifNil: [aBoolean ifTrue: [row at: n + 1 put: (PrologPredicate name: f arity: n)] ifFalse: [nil]]!
predicatesDo: aBlock
	preds do: [:row | row do: [:p | p notNil ifTrue: [aBlock value: p]]]!
addClause: aTerm atEnd: atEnd
	| t head body f n pred c |
	t := aTerm plDeref.
	t isPrologVar ifTrue: [^self instantiationError].
	(t isPrologStruct and: [t arity = 2 and: [t functor == #':-']])
		ifTrue: [head := t first plDeref. body := t second plDeref]
		ifFalse: [head := t. body := #true].
	head isPrologVar ifTrue: [^self instantiationError].
	head isPrologStruct ifTrue: [f := head functor. n := head arity]
		ifFalse: [head isSymbol ifFalse: [^self typeError: #callable culprit: head]. f := head. n := 0].
	body isPrologVar ifFalse: [(body isSymbol or: [body isPrologStruct]) ifFalse: [^self typeError: #callable culprit: body]].
	n > 12 ifTrue: [^self throwFormal: (PrologStruct functor: #representation_error with: #max_arity)].
	(PrologEngine isBuiltin: f arity: n) ifTrue: [^self permissionError: #modify type: #static_procedure culprit: (self indicator: f arity: n)].
	pred := self userPredicate: f arity: n create: true.
	(pred isLibrary and: [loadingLibrary not]) ifTrue: [pred removeAll. pred library: false].
	loadingLibrary ifTrue: [pred library: true].
	c := PrologClause head: head body: body.
	atEnd ifTrue: [pred addLast: c] ifFalse: [pred addFirst: c].
	^c!
clauseTermsOf: aClause
	"a fresh copy of a stored clause as Array(head, body)"
	| vars |
	vars := Array new: aClause nvars.
	^Array with: (self instantiate: aClause head vars: vars)
		with: (aClause body isNil ifTrue: [#true] ifFalse: [self instantiate: aClause body vars: vars])! !

!PrologEngine methodsFor: 'consulting'!
consultString: text
	"load clauses and run directives from Prolog source text"
	| reader term initGoals more |
	reader := PrologReader on: text ops: ops flags: flags.
	initGoals := OrderedCollection new.
	more := true.
	[more] whileTrue: [
		[term := reader readTerm.
		 term isNil ifTrue: [more := false] ifFalse: [self handleClauseTerm: term initGoals: initGoals]]
			on: PrologThrow do: [:e | self warning: e ball]].
	initGoals do: [:g | self runDirective: g].
	^true!
consultFile: aPath
	| text |
	text := (FileStream exists: aPath) ifTrue: [FileStream contentsOf: aPath] ifFalse: [nil].
	text isNil ifTrue: [^self existenceError: #source_sink what: aPath asSymbol].
	^self consultString: text!
handleClauseTerm: term initGoals: initGoals
	| t g |
	t := term plDeref.
	(t isPrologStruct and: [t arity = 1 and: [t functor == #':-' or: [t functor == #'?-']]]) ifTrue: [
		g := t first plDeref.
		(g isPrologStruct and: [g functor == #initialization and: [g arity = 1]])
			ifTrue: [initGoals add: g first]
			ifFalse: [self runDirective: g].
		^self].
	(t isPrologStruct and: [t arity = 2 and: [t functor == #'-->']]) ifTrue: [t := self dcgTransform: t].
	self addClause: t atEnd: true!
runDirective: goal
	"run a directive, reporting failure or an exception as a warning"
	[(self solveOnce: goal) ifFalse: [self out: 'Warning: Goal (directive) failed: ', (self textOf: goal quoted: true), (String with: Character lf)]]
		on: PrologThrow do: [:e | self warning: e ball]! !

!PrologEngine methodsFor: 'DCG'!
dcgTransform: rule
	| head body s0 s pushback mid nh nb |
	head := rule first plDeref. body := rule second plDeref.
	s0 := PrologVar new. s := PrologVar new.
	pushback := nil.
	(head isPrologStruct and: [head functor == #',' and: [head arity = 2]]) ifTrue: [
		pushback := head second plDeref. head := head first plDeref].
	nh := self extend: head with: s0 and: s.
	pushback isNil
		ifTrue: [nb := self dcgBody: body from: s0 to: s]
		ifFalse: [
			mid := PrologVar new.
			nb := PrologStruct functor: #',' with: (self dcgBody: body from: s0 to: mid) with: (self dcgTerminals: pushback from: s to: mid)].
	^PrologStruct functor: #':-' with: nh with: nb!
extend: aTerm with: a and: b
	| t |
	t := aTerm plDeref.
	t isPrologVar ifTrue: [^self instantiationError].
	t isSymbol ifTrue: [^PrologStruct functor: t with: a with: b].
	t isPrologStruct ifTrue: [^PrologStruct functor: t functor args: t args, (Array with: a with: b)].
	^self typeError: #callable culprit: t!
dcgTerminals: aList from: s0 to: s
	"S0 = [a,b,c|S]"
	| items t |
	items := OrderedCollection new.
	t := aList plDeref.
	[t isPrologStruct and: [t isList]] whileTrue: [items add: t first. t := t second plDeref].
	t == #'[]' ifFalse: [^self typeError: #list culprit: aList].
	^PrologStruct functor: #'=' with: s0 with: (PrologStruct list: items tail: s)!
dcgBody: b from: s0 to: s
	| x f mid items |
	x := b plDeref.
	x isPrologVar ifTrue: [^PrologStruct functor: #phrase with: x with: s0 with: s].
	x == #'[]' ifTrue: [^PrologStruct functor: #'=' with: s0 with: s].
	x == #'!!' ifTrue: [^PrologStruct functor: #',' with: #'!!' with: (PrologStruct functor: #'=' with: s0 with: s)].
	(x isString and: [x isSymbol not]) ifTrue: [
		^self dcgTerminals: (PrologStruct list: (x asWideString asArray collect: [:ch | ch value])) from: s0 to: s].
	x isSymbol ifTrue: [^self extend: x with: s0 and: s].
	x isPrologStruct ifFalse: [^self typeError: #callable culprit: x].
	f := x functor.
	x isList ifTrue: [^self dcgTerminals: x from: s0 to: s].
	(f == #',' and: [x arity = 2]) ifTrue: [
		mid := PrologVar new.
		^PrologStruct functor: #',' with: (self dcgBody: x first from: s0 to: mid) with: (self dcgBody: x second from: mid to: s)].
	((f == #';' or: [f == #'|']) and: [x arity = 2]) ifTrue: [
		^PrologStruct functor: #';' with: (self dcgBody: x first from: s0 to: s) with: (self dcgBody: x second from: s0 to: s)].
	(f == #'->' and: [x arity = 2]) ifTrue: [
		mid := PrologVar new.
		^PrologStruct functor: #'->' with: (self dcgBody: x first from: s0 to: mid) with: (self dcgBody: x second from: mid to: s)].
	(f == #'\+' and: [x arity = 1]) ifTrue: [
		^PrologStruct functor: #',' with: (PrologStruct functor: #'\+' with: (self dcgBody: x first from: s0 to: PrologVar new))
			with: (PrologStruct functor: #'=' with: s0 with: s)].
	(f == #'{}' and: [x arity = 1]) ifTrue: [
		^PrologStruct functor: #',' with: x first with: (PrologStruct functor: #'=' with: s0 with: s)].
	(f == #call) ifTrue: [^PrologStruct functor: #call args: x args, (Array with: s0 with: s)].
	^self extend: x with: s0 and: s! !
