"A workspace for algebra: select a line (or several) and print it. Each line is a command - expand, factor, simplify, together,
cancel, apart, diff, integrate, limit, series, solve, system, sum, subs, eval, roots, horner, latex, pretty - or just an
expression. let gives names to expressions (let p = x^2 - 1) and defines functions (let f(x) = x^2 + 1, then f(3)). What you
define stays defined until you close the window or say  forget all."

Object subclass: #AlgebraTool instanceVariableNames: '' classVariableNames: 'Defs Funs' category: 'Algebra'!

!AlgebraTool class methodsFor: 'opening'!
open
	Smalltalk openTool: 'AlgebraTool' title: 'Algebra' contents: self welcomeText!
welcomeText
	^'"Select some lines and print them (ctrl-P).  Commands:  expand  factor  simplify  together  cancel  apart
"diff e, x  integrate e, x  integrate e, x, a, b  limit e, x, a  series e, x, a, n  solve eq, x
"system eq1 ; eq2 for x y  sum e, k, a, b  subs e, x=2  eval e  roots p  horner p, x  latex e  pretty e
"let p = x^2 - 1   let f(x) = x^2 + 1   forget all

expand (x+1)^3
factor x^4 - 1
simplify (x^2 - 1)/(x - 1)
apart 1/(x^2 - 1)
diff x*sin(x), x
integrate x*exp(x), x
integrate 1/(1+x^2), x, 0, 1
limit sin(x)/x, x, 0
series exp(x), x, 0, 5
solve x^2 - 2 = 0
system x + y = 3 ; x - y = 1 for x y
sum k^2, k, 1, n
let f(x) = x^2 + 1
f(3)
diff f(x), x
eval sqrt(2) + pi
pretty (x+1)/(x^2+2) + sqrt(x)'! !

!AlgebraTool class methodsFor: 'state'!
defs
	^Defs ifNil: [Defs := Dictionary new]!
funs
	^Funs ifNil: [Funs := Dictionary new]!
reset
	Defs := Dictionary new.
	Funs := Dictionary new! !

!AlgebraTool class methodsFor: 'evaluating'!
evaluate: aString
	"the report for the selected text: one line of answer for each line of text"
	| lines out |
	lines := (aString lines collect: [:l | l trimBoth]) select: [:l | l notEmpty and: [(l first = $") not]].
	out := WriteStream on: String new.
	lines do: [:l |
		out nextPutAll: (self run: l)]
		separatedBy: [out nl].
	^out contents!
run: aLine
	"one command, answered as text"
	^[self report: (self execute: aLine)] on: SymError do: [:e | 'error: ', e messageText]!
parse: aString
	^SymParser parse: aString definitions: self defs functions: self funs!
equation: aString
	| sides |
	sides := SymParser splitEquation: aString.
	sides size = 1 ifTrue: [^self parse: aString].
	^(self parse: (sides at: 1)) - (self parse: (sides at: 2))!
args: aString
	^(Algebra splitTopLevel: aString on: $,) collect: [:a | a trimBoth]!
report: anAnswer
	"text for whatever a command answered"
	anAnswer isString ifTrue: [^anAnswer].
	(anAnswer isKindOf: SymExpr) ifTrue: [^anAnswer text].
	anAnswer isFloat ifTrue: [^anAnswer printString].
	(anAnswer isKindOf: Association) ifTrue: [^anAnswer key, ' = ', (self report: anAnswer value)].
	anAnswer isArray ifTrue: [
		anAnswer isEmpty ifTrue: [^'no solutions'].
		^(anAnswer collect: [:each | self reportOne: each]) inject: '' into: [:acc :each | acc isEmpty ifTrue: [each] ifFalse: [acc, (String with: Character nl), each]]].
	^anAnswer printString!
reportOne: anAnswer
	(anAnswer isArray and: [anAnswer notEmpty and: [anAnswer first isKindOf: Association]]) ifTrue: [
		^(anAnswer collect: [:a | self report: a]) inject: '' into: [:acc :each | acc isEmpty ifTrue: [each] ifFalse: [acc, ', ', each]]].
	^self report: anAnswer!
execute: aLine
	| word rest a v |
	word := aLine readStream upTo: Character space.
	rest := (aLine copyFrom: word size + 1 to: aLine size) trimBoth.
	word = 'let' ifTrue: [^self define: rest].
	word = 'forget' ifTrue: [
		rest = 'all' ifTrue: [self reset. ^'everything forgotten'].
		self defs removeKey: rest ifAbsent: [nil].
		self funs removeKey: rest ifAbsent: [nil].
		^rest, ' forgotten'].
	word = 'expand' ifTrue: [^(self parse: rest) expanded].
	word = 'factor' ifTrue: [^(self parse: rest) factored].
	word = 'simplify' ifTrue: [^(self parse: rest) simplified].
	word = 'together' ifTrue: [^(self parse: rest) together].
	word = 'cancel' ifTrue: [^(self parse: rest) cancelled].
	word = 'latex' ifTrue: [^(self parse: rest) latex].
	word = 'pretty' ifTrue: [^'
', (self parse: rest) pretty].
	word = 'eval' ifTrue: [^(self parse: rest) numericValue].
	word = 'roots' ifTrue: [^(Algebra roots: (self parse: rest))].
	word = 'apart' ifTrue: [
		a := self args: rest.
		^(self parse: a first) apartIn: (a size > 1 ifTrue: [a at: 2] ifFalse: [Algebra variableOf: (self parse: a first)])].
	word = 'horner' ifTrue: [
		a := self args: rest.
		^Algebra horner: (self parse: a first) in: (a size > 1 ifTrue: [a at: 2] ifFalse: [Algebra variableOf: (self parse: a first)])].
	word = 'diff' ifTrue: [
		a := self args: rest.
		v := a size > 1 ifTrue: [a at: 2] ifFalse: [Algebra variableOf: (self parse: a first)].
		^(self parse: a first) diffIn: v times: (a size > 2 ifTrue: [(a at: 3) asNumber] ifFalse: [1])].
	word = 'integrate' ifTrue: [
		a := self args: rest.
		v := a size > 1 ifTrue: [a at: 2] ifFalse: [Algebra variableOf: (self parse: a first)].
		a size >= 4 ifTrue: [^Algebra integrate: (self parse: a first) by: v from: (self parse: (a at: 3)) to: (self parse: (a at: 4))].
		^Algebra integrate: (self parse: a first) by: v].
	word = 'limit' ifTrue: [
		a := self args: rest.
		a size = 3 ifFalse: [^SymError new signal: 'limit takes an expression, a symbol and a value: limit sin(x)/x, x, 0'].
		^(self parse: a first) limitIn: (a at: 2) at: (self parse: (a at: 3))].
	word = 'series' ifTrue: [
		a := self args: rest.
		a size = 4 ifFalse: [^SymError new signal: 'series takes an expression, a symbol, a point and an order'].
		^(self parse: a first) taylorIn: (a at: 2) at: (self parse: (a at: 3)) order: (a at: 4) asNumber].
	word = 'sum' ifTrue: [
		a := self args: rest.
		a size = 4 ifFalse: [^SymError new signal: 'sum takes an expression, a symbol and two bounds: sum k^2, k, 1, n'].
		^(self parse: a first) sumIn: (a at: 2) from: (self parse: (a at: 3)) to: (self parse: (a at: 4))].
	word = 'subs' ifTrue: [
		a := self args: rest.
		^((self parse: a first) substitute: (Algebra bindings: ((a copyFrom: 2 to: a size) inject: '' into: [:acc :each | acc isEmpty ifTrue: [each] ifFalse: [acc, ',', each]]))) simplified].
	word = 'solve' ifTrue: [
		a := self args: rest.
		v := a size > 1 ifTrue: [a at: 2] ifFalse: [Algebra variableOf: (self equation: a first)].
		^(self equation: a first) solveFor: v].
	word = 'system' ifTrue: [ | parts eqs vars |
		parts := rest subStrings: ' '.
		(parts includes: 'for') ifFalse: [^SymError new signal: 'say which unknowns: system x + y = 3 ; x - y = 1 for x y'].
		eqs := (Algebra splitTopLevel: (rest copyFrom: 1 to: (rest indexOfSubCollection: ' for ') - 1) on: $;) collect: [:e | self equation: e].
		vars := (rest copyFrom: (rest indexOfSubCollection: ' for ') + 5 to: rest size) subStrings: ' ,'.
		^SymExpr solveSystem: eqs for: vars asArray].
	^self parse: aLine!
define: aString
	"let name = expression   or   let f(x, y) = expression"
	| sides lhs body name params |
	sides := SymParser splitEquation: aString.
	sides size = 2 ifFalse: [^SymError new signal: 'let looks like  let p = x^2 - 1  or  let f(x) = x^2'].
	lhs := (sides at: 1) trimBoth.
	body := self parse: (sides at: 2).
	(lhs includes: $()
		ifTrue: [
			name := lhs copyFrom: 1 to: (lhs indexOf: $() - 1.
			params := ((lhs copyFrom: (lhs indexOf: $() + 1 to: lhs size - 1) subStrings: ', ') asArray.
			self funs at: name put: (Array with: params with: body).
			^name, '(', ((params inject: '' into: [:a :p | a isEmpty ifTrue: [p] ifFalse: [a, ', ', p]])), ') = ', body text]
		ifFalse: [
			self defs at: lhs put: body.
			^lhs, ' = ', body text]! !
