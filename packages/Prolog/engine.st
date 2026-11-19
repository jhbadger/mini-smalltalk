"Prolog engine: an iterative machine. The continuation is a linked list of goal frames; alternatives are a stack of choicepoints
(clauses still to try, a goal to run instead, a catch/3 marker, a findall barrier, or an iterator of solutions); a trail records
bindings so they can be undone. Cut is just truncating the choicepoint stack, catch/throw unwind it, and deep recursion costs heap
rather than Smalltalk stack. Clauses are stored compiled (PrologArg slots for variables); head unification builds nothing until it
has to."

Object subclass: #PrologFrame instanceVariableNames: 'goal next cutBarrier' classVariableNames: '' category: 'Prolog-Engine'!
Object subclass: #PrologChoice instanceVariableNames: 'kind trailMark frame goal clauses index height data active' classVariableNames: '' category: 'Prolog-Engine'!
Object subclass: #PrologClause instanceVariableNames: 'head body nvars keyKind key keyArity goals' classVariableNames: '' category: 'Prolog-Engine'!
Object subclass: #PrologPredicate instanceVariableNames: 'name arity clauses kind selector dynamic library block' classVariableNames: '' category: 'Prolog-Engine'!
Object subclass: #PrologAlts instanceVariableNames: 'items index tryBlock' classVariableNames: '' category: 'Prolog-Engine'!
Object subclass: #PrologBetween instanceVariableNames: 'low high current var' classVariableNames: '' category: 'Prolog-Engine'!
Object subclass: #PrologEngine instanceVariableNames: 'preds ops flags frame choices trail output input globals loadingLibrary started lastError operatorsChanged' classVariableNames: 'Builtins ControlTable' category: 'Prolog-Engine'!

!PrologFrame class methodsFor: 'instance creation'!
goal: aTerm next: aFrame cutBarrier: anInteger
	^self basicNew setGoal: aTerm next: aFrame cutBarrier: anInteger! !

!PrologFrame methodsFor: 'accessing'!
setGoal: aTerm next: aFrame cutBarrier: anInteger
	goal := aTerm. next := aFrame. cutBarrier := anInteger!
goal
	^goal!
next
	^next!
cutBarrier
	^cutBarrier! !

!PrologChoice methodsFor: 'accessing'!
kind
	^kind!
kind: aSymbol
	kind := aSymbol!
trailMark
	^trailMark!
trailMark: n
	trailMark := n!
frame
	^frame!
frame: aFrame
	frame := aFrame!
goal
	^goal!
goal: aTerm
	goal := aTerm!
clauses
	^clauses!
clauses: anArray
	clauses := anArray!
index
	^index!
index: n
	index := n!
height
	^height!
height: n
	height := n!
data
	^data!
data: anObject
	data := anObject!
active
	^active!
active: aBoolean
	active := aBoolean! !

"---- clauses ----"

!PrologClause class methodsFor: 'instance creation'!
head: aHead body: aBody
	"compile a clause from run-time terms (their variables become argument slots)"
	^self basicNew compileHead: aHead body: aBody! !

!PrologClause methodsFor: 'private'!
compileHead: aHead body: aBody
	| map a1 |
	map := IdentityDictionary new.
	head := self compile: aHead map: map.
	body := (aBody plDeref == #true) ifTrue: [nil] ifFalse: [self compile: (self wrapVariableGoals: aBody) map: map].
	nvars := map size.
	goals := body isNil ifTrue: [Array new] ifFalse: [self flatten: body].
	keyKind := 0.
	(head isPrologStruct and: [head arity > 0]) ifTrue: [
		a1 := head first.
		a1 class == PrologArg
			ifFalse: [
				a1 isPrologStruct
					ifTrue: [keyKind := 2. key := a1 functor. keyArity := a1 arity]
					ifFalse: [keyKind := 1. key := a1]]]!
flatten: aBody
	"the top-level conjunction of a compiled body as an Array of goals"
	| acc |
	acc := OrderedCollection new.
	self flatten: aBody into: acc.
	^acc asArray!
flatten: t into: acc
	(t class == PrologStruct and: [t functor == #',' and: [t args size = 2]])
		ifTrue: [self flatten: (t args at: 1) into: acc. self flatten: (t args at: 2) into: acc]
		ifFalse: [acc add: t]!
compile: t map: map
	| x args s |
	x := t plDeref.
	x isPrologVar ifTrue: [^map at: x ifAbsent: [map at: x put: (PrologArg index: map size + 1)]].
	x isPrologStruct ifFalse: [^x].
	args := x args collect: [:a | self compile: a map: map].
	s := PrologStruct functor: x functor args: args.
	(args allSatisfy: [:a | a class ~~ PrologArg and: [a isPrologStruct not or: [a isGround]]]) ifTrue: [s beGround].
	^s!
wrapVariableGoals: g
	"a variable used as a goal in a body means call(Variable)"
	| x f |
	x := g plDeref.
	x isPrologVar ifTrue: [^PrologStruct functor: #call with: x].
	x isPrologStruct ifFalse: [^x].
	f := x functor.
	((f == #',' or: [f == #';' or: [f == #'->' or: [f == #'*->']]]) and: [x arity = 2]) ifTrue: [
		^PrologStruct functor: f with: (self wrapVariableGoals: x first) with: (self wrapVariableGoals: x second)].
	(f == #'\+' and: [x arity = 1]) ifTrue: [^PrologStruct functor: f with: (self wrapVariableGoals: x first)].
	^x! !

!PrologClause methodsFor: 'accessing'!
head
	^head!
body
	^body!
goals
	"the body's top-level conjunction, one stored term per goal"
	^goals!
nvars
	^nvars!
headArgs
	^head isPrologStruct ifTrue: [head args] ifFalse: [#()]!
couldMatch: t
	"a quick test on the first argument: false if this clause cannot match a call whose first argument is t (already dereferenced)"
	keyKind = 0 ifTrue: [^true].
	t isPrologVar ifTrue: [^true].
	keyKind = 2 ifTrue: [^t isPrologStruct and: [t functor == key and: [t args size = keyArity]]].
	^t isPrologStruct not and: [PrologEngine atomic: key equals: t]! !

"---- predicates ----"

!PrologPredicate class methodsFor: 'instance creation'!
name: aSymbol arity: n
	^self basicNew setName: aSymbol arity: n!
name: aSymbol arity: n kind: aKind selector: aSelector
	^(self name: aSymbol arity: n) kind: aKind; selector: aSelector; yourself! !

!PrologPredicate methodsFor: 'accessing'!
setName: aSymbol arity: n
	name := aSymbol. arity := n. clauses := Array new. kind := #user. dynamic := false. library := false!
name
	^name!
arity
	^arity!
clauses
	^clauses!
kind
	^kind!
kind: aSymbol
	kind := aSymbol!
selector
	^selector!
selector: aSymbol
	selector := aSymbol!
block
	^block!
block: aBlock
	block := aBlock!
isDynamic
	^dynamic!
beDynamic
	dynamic := true!
isLibrary
	^library!
library: aBoolean
	library := aBoolean!
isUser
	^kind == #user!
isDefined
	"has it ever had clauses, or been declared dynamic?"
	^dynamic or: [clauses notEmpty]!
addLast: aClause
	clauses := clauses copyWith: aClause!
addFirst: aClause
	clauses := (Array with: aClause), clauses!
remove: aClause
	clauses := clauses reject: [:c | c == aClause]!
removeAll
	clauses := Array new! !

"---- iterators for nondeterministic built-ins ----"

!PrologAlts class methodsFor: 'instance creation'!
over: anArray do: aBlock
	"aBlock value: item  tries one alternative (unifying) and answers whether it succeeded"
	^self basicNew setItems: anArray tryBlock: aBlock! !

!PrologAlts methodsFor: 'iterating'!
setItems: anArray tryBlock: aBlock
	items := anArray. tryBlock := aBlock. index := 1!
hasNext
	^index <= items size!
isLast
	^index >= items size!
unifyNext: anEngine
	| item |
	item := items at: index.
	index := index + 1.
	^tryBlock value: item! !

!PrologBetween class methodsFor: 'instance creation'!
from: low to: high var: aVar
	^self basicNew setLow: low high: high var: aVar! !

!PrologBetween methodsFor: 'iterating'!
setLow: l high: h var: v
	low := l. high := h. current := l. var := v!
hasNext
	^high isNil or: [current <= high]!
isLast
	^high notNil and: [current >= high]!
unifyNext: anEngine
	| n |
	n := current.
	current := current + 1.
	^anEngine unify: var with: n! !
