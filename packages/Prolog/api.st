"The Smalltalk face of Prolog.

	Prolog consult: 'parent(tom, bob). parent(bob, ann).'
	Prolog solve: 'parent(tom, X)'              an OrderedCollection of Dictionaries: 'X' -> #bob
	Prolog solveFirst: 'parent(X, ann)'         a Dictionary, or nil
	Prolog succeeds: 'parent(tom, bob)'         true
	Prolog answer: 'member(X, [1,2])'           'X = 1 ;\nX = 2.'   (what the toplevel prints)
	Prolog valueOf: 'X' in: 'X is 6 * 7'        42
	Prolog define: #double arity: 2 as: [:engine :args | engine unify: (args at: 2) with: (engine eval: (args at: 1)) * 2]

Prolog values map to Smalltalk ones: integers, floats, strings as they are, atoms are Symbols, lists are Arrays, true/false/nil
are the Smalltalk objects, and compound terms are PrologStructs. Smalltalk objects can appear in Prolog as opaque constants,
and Prolog can call Smalltalk: smalltalk('3 + 4', X), smalltalk_send(Receiver, Selector, Args, Result)."

Object subclass: #Prolog instanceVariableNames: '' classVariableNames: 'Engine' category: 'Prolog'!
Object subclass: #PrologTool instanceVariableNames: '' classVariableNames: '' category: 'Prolog'!

!Prolog class methodsFor: 'engine'!
engine
	"the default engine, created on first use with the library loaded"
	^Engine ifNil: [self reset. Engine]!
reset
	"discard all programs and start a fresh default engine"
	Engine := self newEngine.
	^Engine!
newEngine
	"a new engine with the standard library; it shares nothing with the default one"
	| e |
	e := PrologEngine new.
	e loadingLibrary: true.
	e consultFile: (Smalltalk packagePath: 'Prolog'), '/lib.pl'.
	e loadingLibrary: false.
	^e! !

!Prolog class methodsFor: 'programs'!
consult: aString
	"load clauses (and run directives) from Prolog text"
	^self engine consultString: aString!
consultFile: aPath
	^self engine consultFile: aPath!
assert: aString
	"add the clause written in aString"
	| e r |
	e := self engine.
	r := PrologReader on: aString, ' .' ops: e ops flags: e flags.
	e addClause: r readTerm atEnd: true.
	^true!
define: aName arity: n as: aBlock
	"define a predicate in Smalltalk: aBlock value: engine value: (Array of the arguments) answers true or false;
	it can bind arguments with  engine unify: x with: y"
	| pred row e |
	e := self engine.
	e defineBuiltin: aName asSymbol arity: n block: aBlock! !

!Prolog class methodsFor: 'queries'!
parseQuery: aString on: anEngine
	"Array(goal term, the reader's variable bindings)"
	| text r t |
	text := aString trimBoth.
	(text startsWith: '?-') ifTrue: [text := (text copyFrom: 3 to: text size) trimBoth].
	[text notEmpty and: [text last = $.]] whileTrue: [text := (text copyFrom: 1 to: text size - 1) trimBoth].
	r := PrologReader on: text, ' .' ops: anEngine ops flags: anEngine flags.
	t := r readTerm.
	t isNil ifTrue: [^anEngine throwFormal: (PrologStruct functor: #syntax_error with: #end_of_file)].
	^Array with: t with: r variableBindings!
solutionOf: bindings on: anEngine
	"a Dictionary from variable names to (Smalltalk) values for the current solution"
	| d |
	d := Dictionary new.
	bindings do: [:b | d at: b key put: (anEngine toSmalltalk: (anEngine copyTerm: b value))].
	^d!
solve: aString do: aBlock
	"evaluate aBlock with a Dictionary of bindings for each solution of the goal"
	| e q |
	e := self engine.
	q := self parseQuery: aString on: e.
	e solveAll: (q at: 1) do: [aBlock value: (self solutionOf: (q at: 2) on: e). nil]!
solve: aString
	"all the solutions, as an OrderedCollection of Dictionaries"
	| all |
	all := OrderedCollection new.
	self solve: aString do: [:d | all add: d].
	^all!
solveFirst: aString
	"the first solution as a Dictionary, or nil"
	| e q result |
	e := self engine.
	q := self parseQuery: aString on: e.
	e solveAll: (q at: 1) do: [result := self solutionOf: (q at: 2) on: e. #stop].
	^result!
succeeds: aString
	| e q found |
	e := self engine.
	q := self parseQuery: aString on: e.
	found := false.
	e solveAll: (q at: 1) do: [found := true. #stop].
	^found!
valueOf: aVariableName in: aString
	"the value of one variable in the first solution (nil if there is none)"
	| d |
	d := self solveFirst: aString.
	^d isNil ifTrue: [nil] ifFalse: [d at: aVariableName ifAbsent: [nil]]!
answer: aString
	"what a toplevel would print for the query: the solutions, one per line, ending in a full stop; 'false.' if there are none"
	^self answer: aString limit: 100!
answer: aString limit: limit
	| e q out lines count text saved |
	e := self engine.
	out := WriteStream on: String new.
	lines := OrderedCollection new.
	count := 0.
	saved := e output.
	e output: out.
	[[q := self parseQuery: aString on: e.
	  e solveAll: (q at: 1) do: [
		count := count + 1.
		lines add: (self describeSolution: (q at: 2) on: e).
		count >= limit ifTrue: [#stop] ifFalse: [nil]]]
		on: PrologThrow do: [:ex | lines add: 'ERROR: ', (e describeBall: ex ball). count := count + 1]]
		ensure: [e output: saved].
	text := out contents.
	lines isEmpty ifTrue: [^text, 'false.'].
	^self renumberVariables: text, (self joinSolutions: lines)!
answerLine: aString
	"answer:, all on one line"
	^(self answer: aString) copyReplacing: Character lf with: $ !
renumberVariables: aString
	"rename the run-time variable names _G123 in an answer to _1, _2, ... in order of appearance"
	| out i n names j digits |
	out := WriteStream on: String new.
	names := Dictionary new.
	i := 1. n := aString size.
	[i <= n] whileTrue: [
		((aString at: i) = $_ and: [i + 2 <= n and: [(aString at: i + 1) = $G and: [(aString at: i + 2) isDigit]]])
			ifTrue: [
				j := i + 2.
				[j <= n and: [(aString at: j) isDigit]] whileTrue: [j := j + 1].
				digits := aString copyFrom: i to: j - 1.
				out nextPutAll: '_', (names at: digits ifAbsent: [names at: digits put: names size + 1]) printString.
				i := j]
			ifFalse: [out nextPut: (aString at: i). i := i + 1]].
	^out contents!
joinSolutions: lines
	| s |
	s := WriteStream on: String new.
	lines doWithIndex: [:l :i |
		s nextPutAll: l.
		i < lines size ifTrue: [s nextPutAll: ' ;'; nextPut: Character lf] ifFalse: [(l startsWith: 'ERROR') ifFalse: [s nextPut: $.]]].
	^s contents!
describeSolution: bindings on: e
	"X = 1, Y = foo  (anonymous variables are left out; 'true' if there is nothing to show)"
	| parts w |
	w := e writer quoted: true; yourself.
	parts := OrderedCollection new.
	bindings do: [:b |
		(b key first = $_) ifFalse: [
			| v |
			v := b value plDeref.
			(v isPrologVar and: [(bindings anySatisfy: [:o | o ~~ b and: [o value plDeref == v and: [o key first ~= $_]]]) not])
				ifFalse: [v isPrologVar ifFalse: [parts add: b key, ' = ', (w stringFor: v prec: 699)]]]].
	^parts isEmpty ifTrue: ['true'] ifFalse: [', ' join: parts]! !

!PrologEngine methodsFor: 'smalltalk api'!
solveAll: goal do: aBlock
	"run goal, evaluating aBlock for every solution (until it answers #stop); the bindings are undone afterwards"
	| saved mark more |
	saved := Array with: frame with: choices with: started.
	mark := trail size.
	frame := PrologFrame goal: goal next: nil cutBarrier: 0.
	choices := OrderedCollection new.
	started := false.
	[more := self nextSolution.
	 [more] whileTrue: [
		aBlock value == #stop ifTrue: [more := false] ifFalse: [more := self nextSolution]]]
		ensure: [self undoTo: mark. frame := saved at: 1. choices := saved at: 2. started := saved at: 3]!
defineBuiltin: aName arity: n block: aBlock
	"a predicate implemented by a Smalltalk block (value: engine value: args answers true or false)"
	| pred |
	n > 12 ifTrue: [^self error: 'arity too large'].
	pred := self userPredicate: aName arity: n create: true.
	pred kind: #block; block: aBlock.
	^pred! !

!PrologTool class methodsFor: 'user interface'!
welcomeText
	^'% Prolog workspace.  Select some text (or leave the cursor on a line) and press ctrl-P (print it):
%   text starting with ?-  runs the query and shows the answers below it;
%   anything else is added to the program.   ctrl-D does the same without printing.
%   Prolog can call Smalltalk:  ?- smalltalk(''Date today printString'', D).

parent(tom, bob).
parent(bob, ann).
parent(bob, pat).
grandparent(X, Z) :- parent(X, Y), parent(Y, Z).

?- grandparent(tom, Who).
?- parent(bob, Child).
?- findall(X-Y, parent(X, Y), Pairs).
?- format("~a has ~d children~n", [bob, 2]).
'!
openWorkspace
	Smalltalk openTool: 'PrologTool' title: 'Prolog' contents: self welcomeText!
evaluate: aString
	"the text of the answer for the selected text (a query, or program text to add)"
	| text n |
	text := aString trimBoth.
	text isEmpty ifTrue: [^''].
	(text startsWith: '?-') ifTrue: [^Prolog answer: text].
	n := 0.
	[Prolog consult: text] on: PrologThrow do: [:e | ^'ERROR: ', (Prolog engine describeBall: e ball)].
	^'ok.'! !

!Prolog class methodsFor: 'testing'!
isPrologLoaded
	^true! !
