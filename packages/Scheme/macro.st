"syntax-rules macros: patterns with literals, ellipsis (also followed by tail patterns and nested), underscore, vector patterns,
(... ...) escapes, and a custom ellipsis identifier.

The expander is not fully hygienic. What it does protect: a variable that a template binds with let, let*, letrec, lambda, do,
a named let or a define's parameter list is renamed afresh at every expansion, so the usual swap and my-or accidents cannot
happen. What it does not protect: a free identifier in a template (say, a call to list) means whatever it means where the
macro is used, so a program that shadows list locally and then uses a macro whose template calls list will see its own list."

!SchemeMacro class methodsFor: 'instance creation'!
fromSyntaxRules: spec
	"spec is (syntax-rules (literal ...) (pattern template) ...) or (syntax-rules ellipsis (literal ...) ...)"
	| a ellipsis literals ruleStart m |
	a := spec asArray.
	a size >= 2 ifFalse: [^SchemeError message: 'Ill-formed special form:' with: spec].
	ellipsis := #'...'.
	(a at: 2) isSymbol
		ifTrue: [
			ellipsis := a at: 2.
			literals := (a at: 3) asArray.
			ruleStart := 4]
		ifFalse: [
			literals := (a at: 2) asArray.
			ruleStart := 3].
	m := self basicNew setLiterals: literals ellipsis: ellipsis.
	(a copyFrom: ruleStart to: a size) do: [:r |
		(r class == SchemePair and: [r cdr class == SchemePair and: [r car class == SchemePair]])
			ifFalse: [^SchemeError message: 'Ill-formed special form:' with: spec].
		m addRule: r car template: r cadr].
	^m! !

!SchemeMacro methodsFor: 'building'!
setLiterals: anArray ellipsis: aSymbol
	literals := anArray. ellipsis := aSymbol. rules := OrderedCollection new!
addRule: pattern template: template
	"the pattern without its keyword, the template, and the variables the template binds"
	| vars binders |
	vars := Set new.
	self patternVars: pattern cdr into: vars.
	binders := Set new.
	self collectBinders: template into: binders.
	vars do: [:v | binders remove: v ifAbsent: [nil]].
	binders remove: ellipsis ifAbsent: [nil].
	rules add: (Array with: pattern cdr with: template with: binders asArray)!
patternVars: p into: set
	p isSymbol ifTrue: [
		((literals includes: p) or: [p == ellipsis or: [p == #_]]) ifFalse: [set add: p].
		^self].
	p class == SchemePair ifTrue: [
		self patternVars: p car into: set.
		^self patternVars: p cdr into: set].
	p class == Array ifTrue: [p do: [:e | self patternVars: e into: set]]!
collectBinders: t into: set
	"the symbols that let, lambda, do and define bind inside the template"
	| h rest first bindings |
	t class == SchemePair ifFalse: [^self].
	h := t car.
	(h isSymbol and: [t cdr class == SchemePair]) ifTrue: [
		rest := t cdr.
		((h == #let or: [h == #'let*' or: [h == #letrec or: [h == #'letrec*']]])) ifTrue: [
			first := rest car.
			first isSymbol
				ifTrue: [set add: first. bindings := rest cdr class == SchemePair ifTrue: [rest cdr car] ifFalse: [nil]]
				ifFalse: [bindings := first].
			self bindersOf: bindings into: set].
		h == #do ifTrue: [self bindersOf: rest car into: set].
		h == #lambda ifTrue: [self parametersOf: rest car into: set].
		((h == #define or: [h == #'define-values']) and: [rest car class == SchemePair]) ifTrue: [
			self parametersOf: rest car cdr into: set]].
	"look at every element, and the tail"
	t car class == SchemePair ifTrue: [self collectBinders: t car into: set].
	self collectBinders: t cdr into: set!
bindersOf: bindings into: set
	| p |
	p := bindings.
	[p class == SchemePair] whileTrue: [
		(p car class == SchemePair and: [p car car isSymbol]) ifTrue: [set add: p car car].
		p := p cdr]!
parametersOf: params into: set
	| p |
	p := params.
	[p class == SchemePair] whileTrue: [
		p car isSymbol ifTrue: [set add: p car].
		p := p cdr].
	p isSymbol ifTrue: [set add: p]! !

!SchemeMacro methodsFor: 'expanding'!
expand: form with: interp
	"the form that a use of the macro stands for"
	| b renames |
	rules do: [:rule |
		b := Dictionary new.
		(self match: (rule at: 1) against: form cdr into: b) ifTrue: [
			renames := Dictionary new.
			(rule at: 3) do: [:s | renames at: s put: (interp freshSymbolFor: s)].
			^self instantiate: (rule at: 2) bindings: b renames: renames]].
	^SchemeError message: 'Ill-formed special form:' with: form!
match: p against: f into: b
	| items g avail vars sets rest tail sub minTail bi |
	p isSymbol ifTrue: [
		(literals includes: p) ifTrue: [^f isSymbol and: [f == p]].
		p == #_ ifTrue: [^true].
		b at: p put: f.
		^true].
	p class == SchemePair ifTrue: [
		(p cdr class == SchemePair and: [p cdr car == ellipsis]) ifTrue: [
			sub := p car. tail := p cdr cdr.
			minTail := 0. g := tail.
			[g class == SchemePair] whileTrue: [minTail := minTail + 1. g := g cdr].
			items := OrderedCollection new. g := f.
			[g class == SchemePair] whileTrue: [items add: g car. g := g cdr].
			avail := items size - minTail.
			avail < 0 ifTrue: [^false].
			vars := Set new.
			self patternVars: sub into: vars.
			sets := OrderedCollection new.
			1 to: avail do: [:i |
				bi := Dictionary new.
				(self match: sub against: (items at: i) into: bi) ifFalse: [^false].
				sets add: bi].
			vars do: [:v | b at: v put: (OrderedCollection withAll: (sets collect: [:s | s at: v]))].
			rest := SchemePair fromArray: (items copyFrom: avail + 1 to: items size) tail: g.
			^self match: tail against: rest into: b].
		f class == SchemePair ifFalse: [^false].
		(self match: p car against: f car into: b) ifFalse: [^false].
		^self match: p cdr against: f cdr into: b].
	p == SchemeNil ifTrue: [^f == SchemeNil].
	p class == Array ifTrue: [
		^f class == Array and: [self match: (SchemePair fromArray: p) against: (SchemePair fromArray: f) into: b]].
	^SchemePrims equal: p to: f!
instantiate: t bindings: b renames: r
	| sub rest depth results tail saved |
	t isSymbol ifTrue: [
		(b includesKey: t) ifTrue: [^b at: t].
		^r at: t ifAbsent: [t]].
	t class == SchemePair ifTrue: [
		(t car == ellipsis and: [t cdr class == SchemePair]) ifTrue: [
			"(... template): the template with ellipses taken literally"
			saved := ellipsis. ellipsis := Object new.
			results := [self instantiate: t cadr bindings: b renames: r] ensure: [ellipsis := saved].
			^results].
		sub := t car. rest := t cdr. depth := 0.
		[rest class == SchemePair and: [rest car == ellipsis]] whileTrue: [depth := depth + 1. rest := rest cdr].
		depth = 0 ifTrue: [
			^SchemePair car: (self instantiate: sub bindings: b renames: r)
				cdr: (self instantiate: rest bindings: b renames: r)].
		results := self expandEllipsis: sub depth: depth bindings: b renames: r.
		tail := self instantiate: rest bindings: b renames: r.
		^SchemePair fromArray: results asArray tail: tail].
	t class == Array ifTrue: [
		^(self instantiate: (SchemePair fromArray: t) bindings: b renames: r) asArray].
	^t!
templateVars: t into: set
	t isSymbol ifTrue: [set add: t. ^self].
	t class == SchemePair ifTrue: [
		self templateVars: t car into: set.
		^self templateVars: t cdr into: set].
	t class == Array ifTrue: [t do: [:e | self templateVars: e into: set]]!
expandEllipsis: sub depth: d bindings: b renames: r
	| all vars n results b2 |
	all := Set new.
	self templateVars: sub into: all.
	vars := all select: [:v | (b at: v ifAbsent: [nil]) class == OrderedCollection].
	vars isEmpty ifTrue: [^SchemeError message: 'Ill-formed special form: no ellipsis variable in the template'].
	n := nil.
	vars do: [:v |
		n isNil ifTrue: [n := (b at: v) size] ifFalse: [
			n = (b at: v) size ifFalse: [^SchemeError message: 'Ill-formed special form: ellipsis variables of different lengths']]].
	results := OrderedCollection new.
	1 to: n do: [:i |
		b2 := b copy.
		vars do: [:v | b2 at: v put: ((b at: v) at: i)].
		d > 1
			ifTrue: [results addAll: (self expandEllipsis: sub depth: d - 1 bindings: b2 renames: r)]
			ifFalse: [results add: (self instantiate: sub bindings: b2 renames: r)]].
	^results! !
