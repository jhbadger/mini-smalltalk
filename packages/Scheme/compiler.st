"The compiler: Scheme data to nodes. Special forms are methods here, found through the SpecialForms table; the derived forms
(cond, case, do, let*, when, unless, parameterize ...) are syntax-rules macros in prelude.scm. A body is scanned first so that
the names it defines are known before any of it is compiled, which is what lets internal definitions refer to each other."

!Scheme class methodsFor: 'special forms'!
specialForms
	SpecialForms isNil ifTrue: [self initSpecialForms].
	^SpecialForms!
initSpecialForms
	SpecialForms := Dictionary new.
	#(#('quote' #compileQuote:scope:) #('quasiquote' #compileQuasiquote:scope:) #('lambda' #compileLambdaForm:scope:)
	  #('named-lambda' #compileNamedLambda:scope:) #('define' #compileDefine:scope:) #('define-integrable' #compileDefine:scope:)
	  #('set!!' #compileSet:scope:) #('if' #compileIf:scope:) #('begin' #compileBegin:scope:) #('and' #compileAnd:scope:)
	  #('or' #compileOr:scope:) #('let' #compileLet:scope:) #('letrec' #compileLetrec:scope:) #('letrec*' #compileLetrec:scope:)
	  #('delay' #compileDelay:scope:) #('make-promise-lazy' #compileDelay:scope:) #('delay-force' #compileDelayForce:scope:)
	  #('cons-stream' #compileConsStream:scope:) #('define-syntax' #compileDefineSyntax:scope:)
	  #('let-syntax' #compileLetSyntax:scope:) #('letrec-syntax' #compileLetSyntax:scope:) #('guard' #compileGuard:scope:)
	  #('define-record-type' #compileRecordType:scope:) #('case-lambda' #compileCaseLambda:scope:)
	  #('the-environment' #compileTheEnvironment:scope:))
		do: [:pair | SpecialForms at: (pair at: 1) asSymbol put: (pair at: 2)]! !

!Scheme methodsFor: 'compiling'!
fail: aString
	^SchemeError message: aString!
illFormed: aForm
	^SchemeError message: 'Ill-formed special form:' with: aForm!
formArray: aForm
	"the elements of a form, which must be a proper list"
	(aForm class == SchemePair and: [aForm isList]) ifFalse: [^self illFormed: aForm].
	^aForm asArray!
compile: x scope: scope
	x isSymbol ifTrue: [^self compileRef: x scope: scope].
	x class == SchemePair ifTrue: [^self compilePair: x scope: scope].
	x == SchemeNil ifTrue: [^self fail: 'Combination must be a proper list'].
	^SchemeConst value: x!
compileTop: x
	^self compile: x scope: nil!
lookup: aSymbol scope: scope
	"(depth, slot) of a lexical variable, or nil"
	| s depth i |
	depth := 0. s := scope.
	[s notNil] whileTrue: [
		s isFrameless ifFalse: [
			i := s vars indexOf: aSymbol.
			i > 0 ifTrue: [^Array with: depth with: i + 1].
			depth := depth + 1].
		s := s parent].
	^nil!
cellFor: aSymbol
	^globals at: aSymbol ifAbsent: [globals at: aSymbol put: (SchemeCell named: aSymbol)]!
macroFor: aSymbol scope: scope
	| s m |
	s := scope.
	[s notNil] whileTrue: [
		m := s macroAt: aSymbol.
		m notNil ifTrue: [^m].
		s := s parent].
	^macros at: aSymbol ifAbsent: [nil]!
isBoundVariable: aSymbol
	"true when a global of that name has been given a value (it then hides a special form of the same name)"
	| c |
	c := globals at: aSymbol ifAbsent: [nil].
	^c notNil and: [c value notNil]!
compileRef: aSymbol scope: scope
	| loc |
	loc := self lookup: aSymbol scope: scope.
	loc notNil ifTrue: [^SchemeLocalRef depth: (loc at: 1) index: (loc at: 2) name: aSymbol].
	(self macroFor: aSymbol scope: scope) notNil ifTrue: [^self fail: 'Syntactic keyword may not be used as an expression: ', aSymbol].
	^SchemeGlobalRef cell: (self cellFor: aSymbol)!
specialSelectorFor: aSymbol scope: scope
	"the selector that compiles the special form of that name, when it is one (and not hidden by a variable)"
	(self lookup: aSymbol scope: scope) notNil ifTrue: [^nil].
	(self macroFor: aSymbol scope: scope) notNil ifTrue: [^nil].
	(self isBoundVariable: aSymbol) ifTrue: [^nil].
	^Scheme specialForms at: aSymbol ifAbsent: [nil]!
compilePair: x scope: scope
	| head m sel |
	head := x car.
	head isSymbol ifTrue: [
		(self lookup: head scope: scope) isNil ifTrue: [
			m := self macroFor: head scope: scope.
			m notNil ifTrue: [^self compile: (m expand: x with: self) scope: scope].
			(self isBoundVariable: head) ifFalse: [
				sel := Scheme specialForms at: head ifAbsent: [nil].
				sel notNil ifTrue: [^self perform: sel with: x with: scope]]]].
	^self compileApp: x scope: scope!
compileApp: x scope: scope
	| items parts |
	(x isList) ifFalse: [^self fail: 'Combination must be a proper list'].
	items := x asArray.
	parts := Array new: items size.
	1 to: items size do: [:i | parts at: i put: (self compile: (items at: i) scope: scope)].
	^SchemeAppNode parts: parts!
compileSeq: forms scope: scope
	"forms is an Array of data; the nodes run in order and the last is the value"
	| nodes |
	forms isEmpty ifTrue: [^SchemeConst value: SchemeUnspec].
	nodes := forms collect: [:f | self compile: f scope: scope].
	nodes size = 1 ifTrue: [^nodes at: 1].
	^SchemeSeqNode forms: nodes!

!Scheme methodsFor: 'special forms'!
compileQuote: x scope: scope
	| a |
	a := self formArray: x.
	a size = 2 ifFalse: [^self illFormed: x].
	^SchemeConst value: (a at: 2)!
compileIf: x scope: scope
	| a |
	a := self formArray: x.
	(a size = 3 or: [a size = 4]) ifFalse: [^self illFormed: x].
	^SchemeIfNode
		test: (self compile: (a at: 2) scope: scope)
		then: (self compile: (a at: 3) scope: scope)
		else: (a size = 4 ifTrue: [self compile: (a at: 4) scope: scope] ifFalse: [SchemeConst value: SchemeUnspec])!
compileBegin: x scope: scope
	| a |
	a := self formArray: x.
	^self compileSeq: (a copyFrom: 2 to: a size) scope: scope!
compileAnd: x scope: scope
	| a nodes |
	a := self formArray: x.
	a size = 1 ifTrue: [^SchemeConst value: true].
	nodes := (a copyFrom: 2 to: a size) collect: [:f | self compile: f scope: scope].
	nodes size = 1 ifTrue: [^nodes at: 1].
	^SchemeAndNode forms: nodes!
compileOr: x scope: scope
	| a nodes |
	a := self formArray: x.
	a size = 1 ifTrue: [^SchemeConst value: false].
	nodes := (a copyFrom: 2 to: a size) collect: [:f | self compile: f scope: scope].
	nodes size = 1 ifTrue: [^nodes at: 1].
	^SchemeOrNode forms: nodes!
compileLambdaForm: x scope: scope
	| a |
	a := self formArray: x.
	a size >= 3 ifFalse: [^self illFormed: x].
	^self compileLambda: (a at: 2) body: (a copyFrom: 3 to: a size) name: nil scope: scope!
compileNamedLambda: x scope: scope
	| a spec |
	a := self formArray: x.
	(a size >= 3 and: [(a at: 2) class == SchemePair]) ifFalse: [^self illFormed: x].
	spec := a at: 2.
	^self compileLambda: spec cdr body: (a copyFrom: 3 to: a size) name: spec car asString scope: scope!
compileLambda: params body: forms name: aName scope: scope
	"the lambda node for a parameter list and a body (an Array of forms)"
	| vars rest p newScope bodyNode nreq |
	vars := OrderedCollection new. rest := false. p := params.
	[p class == SchemePair] whileTrue: [
		p car isSymbol ifFalse: [^self fail: 'Ill-formed special form: bad lambda list'].
		vars add: p car.
		p := p cdr].
	nreq := vars size.
	p == SchemeNil ifFalse: [
		p isSymbol ifFalse: [^self fail: 'Ill-formed special form: bad lambda list'].
		vars add: p. rest := true].
	newScope := SchemeScope vars: vars asArray parent: scope.
	bodyNode := self compileBody: forms scope: newScope.
	^SchemeLambdaNode required: nreq rest: rest frameSize: newScope size + 1 body: bodyNode name: aName!
compileBody: forms scope: scope
	"a body: its definitions are collected first (macros are expanded to find them), then everything is compiled"
	| items |
	items := OrderedCollection new.
	forms do: [:f | self scanForm: f scope: scope into: items].
	items isEmpty ifTrue: [^self fail: 'Ill-formed special form: empty body'].
	^self compileSeq: items asArray scope: scope!
headOf: f scope: scope
	"the symbol heading a form when it names a special form that is not hidden, else nil"
	| h |
	f class == SchemePair ifFalse: [^nil].
	h := f car.
	h isSymbol ifFalse: [^nil].
	(self lookup: h scope: scope) notNil ifTrue: [^nil].
	(self macroFor: h scope: scope) notNil ifTrue: [^nil].
	(self isBoundVariable: h) ifTrue: [^nil].
	^(Scheme specialForms includesKey: h) ifTrue: [h] ifFalse: [nil]!
scanForm: form scope: scope into: items
	| f m head name target |
	f := form.
	"expand macros at the head until the form is not a macro use"
	[f class == SchemePair and: [f car isSymbol and: [(self lookup: f car scope: scope) isNil and: [(m := self macroFor: f car scope: scope) notNil]]]]
		whileTrue: [f := m expand: f with: self].
	head := self headOf: f scope: scope.
	head == #begin ifTrue: [
		f isList ifFalse: [^self illFormed: f].
		f cdr asArray do: [:g | self scanForm: g scope: scope into: items].
		^self].
	head == #'define-syntax' ifTrue: [
		self compileDefineSyntax: f scope: scope.
		^self].
	head == #'define-record-type' ifTrue: [
		^self scanForm: (self expandRecordType: f) scope: scope into: items].
	(head == #define or: [head == #'define-integrable']) ifTrue: [
		target := f cdr class == SchemePair ifTrue: [f cadr] ifFalse: [^self illFormed: f].
		[target class == SchemePair] whileTrue: [target := target car].
		target isSymbol ifFalse: [^self illFormed: f].
		scope nearestFramed notNil ifTrue: [scope nearestFramed addVar: target]].
	items add: f!
compileDefine: x scope: scope
	| a target valueForm name framed valueNode loc |
	a := self formArray: x.
	a size >= 2 ifFalse: [^self illFormed: x].
	target := a at: 2.
	[target class == SchemePair and: [target car class == SchemePair]] whileTrue: [
		"curried define: (define ((f a) b) ...) is (define (f a) (lambda (b) ...))"
		a := Array with: (a at: 1) with: target car
			with: (SchemePair car: #lambda cdr: (SchemePair car: target cdr cdr: (SchemePair fromArray: (a copyFrom: 3 to: a size)))).
		target := a at: 2].
	target class == SchemePair
		ifTrue: [
			name := target car.
			name isSymbol ifFalse: [^self illFormed: x].
			framed := scope isNil ifTrue: [nil] ifFalse: [scope nearestFramed].
			framed notNil ifTrue: [framed addVar: name].
			valueNode := self compileLambda: target cdr body: (a copyFrom: 3 to: a size) name: name asString scope: scope]
		ifFalse: [
			name := target.
			name isSymbol ifFalse: [^self illFormed: x].
			a size > 3 ifTrue: [^self illFormed: x].
			framed := scope isNil ifTrue: [nil] ifFalse: [scope nearestFramed].
			framed notNil ifTrue: [framed addVar: name].
			valueNode := a size = 3
				ifTrue: [self compile: (a at: 3) scope: scope]
				ifFalse: [SchemeConst value: SchemeUnspec].
			(valueNode isLambda and: [valueNode name isNil]) ifTrue: [valueNode name: name asString]].
	framed isNil ifTrue: [
		macros removeKey: name ifAbsent: [nil].
		^SchemeSetGlobal cell: (self cellFor: name) value: valueNode define: true].
	loc := self lookup: name scope: scope.
	^SchemeSetLocal depth: (loc at: 1) index: (loc at: 2) value: valueNode define: true name: name!
compileSet: x scope: scope
	| a name loc valueNode |
	a := self formArray: x.
	(a size = 3 and: [(a at: 2) isSymbol]) ifFalse: [^self illFormed: x].
	name := a at: 2.
	valueNode := self compile: (a at: 3) scope: scope.
	loc := self lookup: name scope: scope.
	loc notNil ifTrue: [^SchemeSetLocal depth: (loc at: 1) index: (loc at: 2) value: valueNode define: false name: name].
	^SchemeSetGlobal cell: (self cellFor: name) value: valueNode define: false!
compileLet: x scope: scope
	| a bindings vars inits parts name lam loop opForm |
	a := self formArray: x.
	a size >= 3 ifFalse: [^self illFormed: x].
	(a at: 2) isSymbol ifTrue: [^self compileNamedLet: a form: x scope: scope].
	bindings := (a at: 2) == SchemeNil ifTrue: [#()] ifFalse: [
		((a at: 2) class == SchemePair and: [(a at: 2) isList]) ifFalse: [^self illFormed: x].
		(a at: 2) asArray].
	vars := Array new: bindings size. inits := Array new: bindings size.
	1 to: bindings size do: [:i | | b |
		b := bindings at: i.
		b isSymbol
			ifTrue: [vars at: i put: b. inits at: i put: SchemeUnspec]
			ifFalse: [
				(b class == SchemePair and: [b car isSymbol]) ifFalse: [^self illFormed: x].
				vars at: i put: b car.
				inits at: i put: (b cdr == SchemeNil ifTrue: [SchemeUnspec] ifFalse: [b cadr])]].
	parts := Array new: bindings size + 1.
	parts at: 1 put: (self compileLambda: (SchemePair fromArray: vars) body: (a copyFrom: 3 to: a size) name: nil scope: scope).
	1 to: inits size do: [:i | parts at: i + 1 put: (self compile: (inits at: i) scope: scope)].
	^SchemeAppNode parts: parts!
compileNamedLet: a form: x scope: scope
	"(let name ((v i) ...) body...) is ((letrec ((name (lambda (v ...) body ...))) name) i ...)"
	| name bindings vars inits lam op |
	a size >= 4 ifFalse: [^self illFormed: x].
	name := a at: 2.
	bindings := (a at: 3) == SchemeNil ifTrue: [#()] ifFalse: [
		((a at: 3) class == SchemePair and: [(a at: 3) isList]) ifFalse: [^self illFormed: x].
		(a at: 3) asArray].
	vars := bindings collect: [:b | b class == SchemePair ifTrue: [b car] ifFalse: [b]].
	inits := bindings collect: [:b | (b class == SchemePair and: [b cdr class == SchemePair]) ifTrue: [b cadr] ifFalse: [SchemeUnspec]].
	lam := SchemePair car: #lambda cdr: (SchemePair car: (SchemePair fromArray: vars) cdr: (SchemePair fromArray: (a copyFrom: 4 to: a size))).
	op := SchemePair with: (SchemePair car: #lambda cdr: (SchemePair car: SchemeNil
		cdr: (SchemePair with: (SchemePair with: #define with: name with: lam) with: name))).
	^self compile: (SchemePair car: op cdr: (SchemePair fromArray: inits)) scope: scope!
compileLetrec: x scope: scope
	"(letrec ((v i) ...) body...) is ((lambda () (define v i) ... body ...))"
	| a bindings forms |
	a := self formArray: x.
	a size >= 3 ifFalse: [^self illFormed: x].
	bindings := (a at: 2) == SchemeNil ifTrue: [#()] ifFalse: [
		((a at: 2) class == SchemePair and: [(a at: 2) isList]) ifFalse: [^self illFormed: x].
		(a at: 2) asArray].
	forms := OrderedCollection new.
	bindings do: [:b |
		(b class == SchemePair and: [b car isSymbol]) ifFalse: [^self illFormed: x].
		forms add: (SchemePair car: #define cdr: b)].
	forms addAll: (a copyFrom: 3 to: a size).
	^self compile: (SchemePair with: (SchemePair car: #lambda cdr: (SchemePair car: SchemeNil cdr: (SchemePair fromArray: forms asArray)))) scope: scope!
compileDelay: x scope: scope
	| a |
	a := self formArray: x.
	a size = 2 ifFalse: [^self illFormed: x].
	^SchemeDelayNode body: (self compile: (a at: 2) scope: scope) chain: false!
compileDelayForce: x scope: scope
	| a |
	a := self formArray: x.
	a size = 2 ifFalse: [^self illFormed: x].
	^SchemeDelayNode body: (self compile: (a at: 2) scope: scope) chain: true!
compileConsStream: x scope: scope
	| a |
	a := self formArray: x.
	a size = 3 ifFalse: [^self illFormed: x].
	^SchemeAppNode parts: (Array
		with: (SchemeConst value: (Scheme primitiveNamed: 'cons'))
		with: (self compile: (a at: 2) scope: scope)
		with: (SchemeDelayNode body: (self compile: (a at: 3) scope: scope) chain: false))!
compileTheEnvironment: x scope: scope
	^SchemeConst value: (SchemeEnvironment named: 'system-global-environment')!
compileCaseLambda: x scope: scope
	| a lambdas |
	a := self formArray: x.
	lambdas := (a copyFrom: 2 to: a size) collect: [:clause |
		(clause class == SchemePair and: [clause cdr class == SchemePair]) ifFalse: [^self illFormed: x].
		self compileLambda: clause car body: clause cdr asArray name: nil scope: scope].
	^SchemeCaseLambdaNode lambdas: lambdas!

!Scheme methodsFor: 'quasiquote'!
compileQuasiquote: x scope: scope
	| a |
	a := self formArray: x.
	a size = 2 ifFalse: [^self illFormed: x].
	^self quasi: (a at: 2) depth: 1 scope: scope!
quasiCons: a with: b
	"a node for (cons a b), folded into a constant when both are constant"
	(a class == SchemeConst and: [b class == SchemeConst])
		ifTrue: [^SchemeConst value: (SchemePair car: a constant cdr: b constant)].
	^SchemeAppNode parts: (Array with: (SchemeConst value: (Scheme primitiveNamed: 'cons')) with: a with: b)!
quasiList: sym with: node
	"the node for the list (sym <node>)"
	^self quasiCons: (SchemeConst value: sym) with: (self quasiCons: node with: (SchemeConst value: SchemeNil))!
quasi: x depth: depth scope: scope
	| h |
	x class == SchemePair ifTrue: [
		h := x car.
		(h == #unquote and: [x cdr class == SchemePair]) ifTrue: [
			depth = 1 ifTrue: [^self compile: x cadr scope: scope].
			^self quasiList: #unquote with: (self quasi: x cadr depth: depth - 1 scope: scope)].
		(h == #quasiquote and: [x cdr class == SchemePair]) ifTrue: [
			^self quasiList: #quasiquote with: (self quasi: x cadr depth: depth + 1 scope: scope)].
		(h class == SchemePair and: [h car == #'unquote-splicing' and: [h cdr class == SchemePair]]) ifTrue: [
			depth = 1 ifTrue: [
				^SchemeAppNode parts: (Array
					with: (SchemeConst value: (Scheme primitiveNamed: 'append'))
					with: (self compile: h cadr scope: scope)
					with: (self quasi: x cdr depth: depth scope: scope))].
			^self quasiCons: (self quasiList: #'unquote-splicing' with: (self quasi: h cadr depth: depth - 1 scope: scope))
				with: (self quasi: x cdr depth: depth scope: scope)].
		^self quasiCons: (self quasi: h depth: depth scope: scope) with: (self quasi: x cdr depth: depth scope: scope)].
	x class == Array ifTrue: [
		| n |
		n := self quasi: (SchemePair fromArray: x) depth: depth scope: scope.
		n class == SchemeConst ifTrue: [^SchemeConst value: x].
		^SchemeAppNode parts: (Array with: (SchemeConst value: (Scheme primitiveNamed: 'list->vector')) with: n)].
	^SchemeConst value: x! !

!Scheme methodsFor: 'syntax'!
compileDefineSyntax: x scope: scope
	| a name rules m framed |
	a := self formArray: x.
	(a size = 3 and: [(a at: 2) isSymbol]) ifFalse: [^self illFormed: x].
	name := a at: 2.
	m := self macroFrom: (a at: 3) scope: scope.
	framed := scope isNil ifTrue: [nil] ifFalse: [scope].
	framed isNil
		ifTrue: [macros at: name put: m]
		ifFalse: [framed macroAt: name put: m].
	^SchemeConst value: name!
macroFrom: spec scope: scope
	"a SchemeMacro from a (syntax-rules ...) form"
	(spec class == SchemePair and: [spec car == #'syntax-rules' or: [spec car == #'er-macro-transformer']]) ifFalse: [
		^self fail: 'Unsupported macro transformer: only syntax-rules is available'].
	spec car == #'syntax-rules' ifFalse: [^self fail: 'Unsupported macro transformer: only syntax-rules is available'].
	^SchemeMacro fromSyntaxRules: spec!
compileLetSyntax: x scope: scope
	| a bindings newScope |
	a := self formArray: x.
	a size >= 3 ifFalse: [^self illFormed: x].
	newScope := SchemeScope macroScopeParent: scope.
	(a at: 2) asArray do: [:b |
		(b class == SchemePair and: [b car isSymbol and: [b cdr class == SchemePair]]) ifFalse: [^self illFormed: x].
		newScope macroAt: b car put: (self macroFrom: b cadr scope: newScope)].
	^self compileSeq: (a copyFrom: 3 to: a size) scope: newScope! !

!Scheme methodsFor: 'records'!
expandRecordType: x
	"(define-record-type name (ctor field ...) pred (field accessor [modifier]) ...) as a begin of defines"
	| a typeName typeSym ctor pred fields forms fieldNames ctorFields |
	a := self formArray: x.
	a size >= 4 ifFalse: [^self illFormed: x].
	typeSym := (a at: 2) class == SchemePair ifTrue: [(a at: 2) car] ifFalse: [a at: 2].
	typeSym isSymbol ifFalse: [^self illFormed: x].
	ctor := a at: 3. pred := a at: 4.
	fields := (a copyFrom: 5 to: a size) collect: [:f | f isSymbol ifTrue: [Array with: f] ifFalse: [self formArray: f]].
	fieldNames := fields collect: [:f | f at: 1].
	forms := OrderedCollection new.
	forms add: (SchemePair with: #define with: typeSym with:
		(SchemePair with: (Scheme primitiveNamed: '%make-record-type') with: (SchemePair with: #quote with: typeSym)
			with: (SchemePair with: #quote with: (SchemePair fromArray: fieldNames)))).
	ctor class == SchemePair
		ifTrue: [
			ctorFields := ctor cdr.
			forms add: (SchemePair with: #define with: ctor car with:
				(SchemePair with: (Scheme primitiveNamed: '%record-constructor') with: typeSym
					with: (SchemePair with: #quote with: ctorFields)))]
		ifFalse: [
			ctor isSymbol ifTrue: [
				forms add: (SchemePair with: #define with: ctor with:
					(SchemePair with: (Scheme primitiveNamed: '%record-constructor') with: typeSym
						with: (SchemePair with: #quote with: (SchemePair fromArray: fieldNames))))]].
	pred isSymbol ifTrue: [
		forms add: (SchemePair with: #define with: pred with:
			(SchemePair with: (Scheme primitiveNamed: '%record-predicate') with: typeSym))].
	fields do: [:f |
		f size >= 2 ifTrue: [
			forms add: (SchemePair with: #define with: (f at: 2) with:
				(SchemePair with: (Scheme primitiveNamed: '%record-accessor') with: typeSym
					with: (SchemePair with: #quote with: (f at: 1))))].
		f size >= 3 ifTrue: [
			forms add: (SchemePair with: #define with: (f at: 3) with:
				(SchemePair with: (Scheme primitiveNamed: '%record-modifier') with: typeSym
					with: (SchemePair with: #quote with: (f at: 1))))]].
	^SchemePair car: #begin cdr: (SchemePair fromArray: forms asArray)!
compileRecordType: x scope: scope
	^self compile: (self expandRecordType: x) scope: scope! !

!Scheme methodsFor: 'guard'!
compileGuard: x scope: scope
	"(guard (var clause ...) body ...): the body runs as a thunk under a guard handler; when something is raised the
	clauses are tried in a new frame holding var, and with no else clause the condition is raised again"
	| a spec var clauses handlerScope condForm body lastClause hasElse |
	a := self formArray: x.
	(a size >= 3 and: [(a at: 2) class == SchemePair and: [(a at: 2) car isSymbol]]) ifFalse: [^self illFormed: x].
	spec := a at: 2.
	var := spec car.
	clauses := spec cdr asArray.
	hasElse := clauses notEmpty and: [
		lastClause := clauses last.
		lastClause class == SchemePair and: [lastClause car == #else]].
	hasElse ifFalse: [
		clauses := clauses copyWith: (SchemePair with: #else with: (SchemePair with: (Scheme primitiveNamed: '%reraise') with: var))].
	body := self compileLambda: SchemeNil body: (a copyFrom: 3 to: a size) name: nil scope: scope.
	handlerScope := SchemeScope vars: (Array with: var) parent: scope.
	condForm := SchemePair car: #cond cdr: (SchemePair fromArray: clauses).
	^SchemeGuardNode body: body handler: (self compile: condForm scope: handlerScope) frameSize: handlerScope size + 1! !
