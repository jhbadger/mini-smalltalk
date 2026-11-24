"The evaluator. A sentence is first read left to right into items (numbers, strings and names looked up, a parenthesised
part evaluated, adjacent nouns made into one strand), then reduced from the right the way J does it: an adverb takes the
verb or noun to its left, a conjunction the two beside it, a verb followed by a noun is applied (monadically unless a
noun stands to its left, when it is dyadic), three verbs make a fork and two a hook. A sentence with an assignment sets
the name to the value of everything after it. A definition (3 : text) is read into statements with the control
structures if. while. for. select. try. and run with x and y bound in a frame of local names."

!APL class methodsFor: 'instance creation'!
new
	^self basicNew initialize!
default
	"the session that  APL eval:  and friends use, so that what you define stays defined"
	Default isNil ifTrue: [Default := self new].
	^Default!
reset
	"start the default session again from scratch"
	Default := self new.
	^Default!
current
	"the session now running a sentence (for the primitives that need to call back)"
	^Current isNil ifTrue: [self default] ifFalse: [Current]!
debug: aBoolean
	"when true, an error from Smalltalk inside a primitive shows its own message"
	Debug := aBoolean! !

!APL methodsFor: 'initializing'!
initialize
	names := Dictionary new.
	frames := OrderedCollection new.
	selfStack := OrderedCollection new.
	precision := 6.
	assigned := false.
	APLPrims installNamesIn: names!
precision
	^precision!
precision: n
	precision := n!
names
	^names! !

!APL methodsFor: 'names'!
valueOfName: nm
	frames isEmpty ifFalse: [(frames last includesKey: nm) ifTrue: [^frames last at: nm]].
	^names at: nm ifAbsent: [APLError value: nm]!
setName: nm to: aValue local: isLocal
	(isLocal and: [frames notEmpty])
		ifTrue: [frames last at: nm put: aValue]
		ifFalse: [names at: nm put: aValue].
	^aValue! !

!APL methodsFor: 'sentences'!
kindOf: x
	x class == APLArray ifTrue: [^#noun].
	x class == APLVerb ifTrue: [^#verb].
	x class == APLAdverb ifTrue: [^#adverb].
	x class == APLConj ifTrue: [^#conj].
	x class == Array ifTrue: [^x first].
	^#edge!
execSentence: toks
	"the value of a sentence (an Array of tokens without newlines), or nil if it is empty"
	| items result |
	assigned := false.
	toks isEmpty ifTrue: [^nil].
	items := self prepass: toks.
	result := self reduce: items.
	^result!
prepass: toks
	"the values of the tokens, names looked up and parentheses evaluated, with adjacent nouns strung together"
	| items i n tk kind j depth v |
	items := OrderedCollection new.
	i := 1.
	n := toks size.
	[i <= n] whileTrue: [
		tk := toks at: i.
		kind := tk at: 1.
		kind == #lparen
			ifTrue: [
				depth := 1.
				j := i + 1.
				[depth > 0] whileTrue: [
					j > n ifTrue: [^APLError syntax].
					(toks at: j) first == #lparen ifTrue: [depth := depth + 1].
					(toks at: j) first == #rparen ifTrue: [depth := depth - 1].
					j := j + 1].
				v := self execSentence: (toks copyFrom: i + 1 to: j - 2).
				v isNil ifTrue: [^APLError syntax].
				items add: v.
				i := j]
			ifFalse: [
				(kind == #num or: [kind == #str]) ifTrue: [items add: (tk at: 3)].
				kind == #name ifTrue: [
					(i < n and: [(toks at: i + 1) first == #asgn])
						ifTrue: [items add: (Array with: #name with: (tk at: 2))]
						ifFalse: [items add: (self valueOfName: (tk at: 2))]].
				kind == #asgn ifTrue: [items add: (Array with: #asgn with: (tk at: 2))].
				kind == #prim ifTrue: [items add: (APLPrims lookup: (tk at: 2))].
				(kind == #rparen or: [kind == #ctrl]) ifTrue: [^APLError syntax].
				i := i + 1]].
	^self strand: items!
strand: items
	"adjacent nouns become one; a noun beside a conjunction or just left of an adverb is an operand and stays alone"
	| out run prev nxt e |
	out := OrderedCollection new.
	run := OrderedCollection new.
	prev := nil.
	1 to: items size do: [:i |
		e := items at: i.
		nxt := i < items size ifTrue: [items at: i + 1] ifFalse: [nil].
		(e class == APLArray and: [prev class ~~ APLConj and: [nxt class ~~ APLAdverb and: [nxt class ~~ APLConj]]])
			ifTrue: [run add: e]
			ifFalse: [self flushRun: run into: out. out add: e].
		prev := e].
	self flushRun: run into: out.
	^out!
flushRun: run into: out
	run size = 1 ifTrue: [out add: run first].
	run size > 1 ifTrue: [out add: (self makeStrand: run asArray)].
	[run isEmpty] whileFalse: [run removeFirst]!
makeStrand: arrays
	"nouns written side by side: a list of single items if they are all alike, else a list of boxes"
	| k |
	k := arrays first kind.
	((arrays allSatisfy: [:e | e isAtom and: [e kind == k]]) and: [k ~~ #box])
		ifTrue: [^APLArray vector: (arrays collect: [:e | e first])].
	^APLArray vector: (arrays collect: [:e | APLBox on: e])!
reduce: items
	| st |
	st := OrderedCollection new.
	items size to: 1 by: -1 do: [:i |
		st addLast: (items at: i).
		[self applyRule: st] whileTrue].
	st addLast: #edge.
	[self applyRule: st] whileTrue.
	st size = 1 ifTrue: [^nil].
	(st size = 2 and: [st last == #edge]) ifTrue: [^st first].
	^APLError syntax!
isContext: k
	"what may stand to the left of a pattern: the start of the sentence, a noun, verb or adverb (not a conjunction)"
	^k == #edge or: [k == #asgn or: [k == #verb or: [k == #noun or: [k == #adverb]]]]!
applyRule: st
	"the rules of J's parse table, tried in order on the leftmost four items of the stack (the top);
	the first item is the context to the left of the pattern, so a pattern is not used until what stands beside it is known.
	Answer true if one rule applied."
	| n w0 w1 w2 w3 k0 k1 k2 k3 |
	n := st size.
	n < 3 ifTrue: [^false].
	w0 := st at: n. w1 := st at: n - 1. w2 := st at: n - 2.
	w3 := n >= 4 ifTrue: [st at: n - 3] ifFalse: [nil].
	k0 := self kindOf: w0. k1 := self kindOf: w1. k2 := self kindOf: w2.
	k3 := w3 isNil ifTrue: [#none] ifFalse: [self kindOf: w3].
	"assignment: name =: value"
	(k0 == #name and: [k1 == #asgn and: [k2 ~~ #name and: [k2 ~~ #asgn and: [k2 ~~ #edge]]]]) ifTrue: [
		self setName: (w0 at: 2) to: w2 local: (w1 at: 2) = '=.'.
		st removeLast; removeLast; removeLast.
		st addLast: w2.
		assigned := true.
		^true].
	k0 == #name ifTrue: [^false].
	assigned := false.
	"monad: V N at the start of the sentence"
	((k0 == #edge or: [k0 == #asgn]) and: [k1 == #verb and: [k2 == #noun]]) ifTrue: [
		st removeLast; removeLast; removeLast.
		st addLast: (w1 monad: w2).
		st addLast: w0.
		^true].
	(self isContext: k0) ifFalse: [^false].
	"monad: V V N applies the second verb"
	(k1 == #verb and: [k2 == #verb and: [k3 == #noun]]) ifTrue: [
		st removeLast; removeLast; removeLast; removeLast.
		st addLast: (w2 monad: w3).
		st addLast: w1.
		st addLast: w0.
		^true].
	"dyad: N V N"
	(k1 == #noun and: [k2 == #verb and: [k3 == #noun]]) ifTrue: [
		st removeLast; removeLast; removeLast; removeLast.
		st addLast: (w2 dyad: w1 y: w3).
		st addLast: w0.
		^true].
	"adverb"
	((k1 == #verb or: [k1 == #noun]) and: [k2 == #adverb]) ifTrue: [
		st removeLast; removeLast; removeLast.
		st addLast: (w2 applyTo: w1).
		st addLast: w0.
		^true].
	"conjunction"
	((k1 == #verb or: [k1 == #noun]) and: [k2 == #conj and: [k3 == #verb or: [k3 == #noun]]]) ifTrue: [
		st removeLast; removeLast; removeLast; removeLast.
		st addLast: (w2 applyTo: w1 and: w3).
		st addLast: w0.
		^true].
	"fork"
	((k1 == #verb or: [k1 == #noun]) and: [k2 == #verb and: [k3 == #verb]]) ifTrue: [
		st removeLast; removeLast; removeLast; removeLast.
		st addLast: (self fork: w1 g: w2 h: w3).
		st addLast: w0.
		^true].
	"hook, adverb pair, and a conjunction with its right operand fixed (only at the start of the sentence)"
	(k0 == #edge or: [k0 == #asgn]) ifTrue: [
		(k1 == #verb and: [k2 == #verb]) ifTrue: [
			st removeLast; removeLast; removeLast.
			st addLast: (self hook: w1 with: w2).
			st addLast: w0.
			^true].
		(k1 == #adverb and: [k2 == #adverb]) ifTrue: [
			st removeLast; removeLast; removeLast.
			st addLast: (self adverbPair: w1 with: w2).
			st addLast: w0.
			^true].
		(k1 == #conj and: [k2 == #verb or: [k2 == #noun]]) ifTrue: [
			st removeLast; removeLast; removeLast.
			st addLast: (self bondConj: w1 with: w2).
			st addLast: w0.
			^true]].
	^false! !

!APL methodsFor: 'trains'!
trainDisplay: parts
	| ws |
	ws := WriteStream on: String new.
	ws nextPut: $(.
	parts doWithIndex: [:p :i |
		i > 1 ifTrue: [ws nextPut: $ ].
		ws nextPutAll: (p class == APLArray ifTrue: [APLFormat text: p precision: precision] ifFalse: [p display])].
	ws nextPut: $).
	^ws contents!
fork: f g: g h: h
	"(f g h) y is (f y) g (h y); a noun f is a constant, and [: as f makes g @: h"
	| cap |
	cap := f == (APLPrims lookup: '[:').
	^APLVerb derived: (self trainDisplay: (Array with: f with: g with: h))
		monad: [:y |
			cap
				ifTrue: [g monad: (h monad: y)]
				ifFalse: [g dyad: (f class == APLArray ifTrue: [f] ifFalse: [f monad: y]) y: (h monad: y)]]
		dyad: [:x :y |
			cap
				ifTrue: [g monad: (h dyad: x y: y)]
				ifFalse: [g dyad: (f class == APLArray ifTrue: [f] ifFalse: [f dyad: x y: y]) y: (h dyad: x y: y)]]!
hook: f with: g
	"(f g) y is y f (g y); x (f g) y is x f (g y)"
	^APLVerb derived: (self trainDisplay: (Array with: f with: g))
		monad: [:y | f dyad: y y: (g monad: y)]
		dyad: [:x :y | f dyad: x y: (g monad: y)]!
adverbPair: a with: b
	^APLAdverb name: a name, ' ', b name block: [:u | b applyTo: (a applyTo: u)]!
bondConj: c with: v
	"a conjunction with its right operand fixed is an adverb, as in  &.>"
	^APLAdverb name: c name, ' ', v display block: [:u | c applyTo: u and: v]! !

!APL methodsFor: 'statements'!
compileBody: text
	"the statements of a definition's text"
	| toks s |
	toks := (APLLexer tokens: text) asArray.
	s := ReadStream on: toks.
	^self parseBlock: s terms: #()!
flush: cur into: stmts
	| toks |
	cur isEmpty ifTrue: [^self].
	toks := cur asArray.
	(((toks first at: 1) == #ctrl) and: [(toks first at: 2) = 'assert.'])
		ifTrue: [stmts add: (Array with: #assert with: (toks copyFrom: 2 to: toks size))]
		ifFalse: [stmts add: (Array with: #sent with: toks)].
	[cur isEmpty] whileFalse: [cur removeFirst]!
parseBlock: s terms: terms
	"the statements up to a control word in terms (consumed, and left in term) or the end of the text"
	| stmts cur tk kind text |
	stmts := OrderedCollection new.
	cur := OrderedCollection new.
	[s atEnd] whileFalse: [
		tk := s next.
		kind := tk at: 1.
		text := tk at: 2.
		kind == #nl
			ifTrue: [self flush: cur into: stmts]
			ifFalse: [
				kind == #ctrl
					ifTrue: [
						(terms includes: text) ifTrue: [
							self flush: cur into: stmts.
							term := text.
							^stmts asArray].
						text = 'assert.'
							ifTrue: [self flush: cur into: stmts. cur add: tk]
							ifFalse: [
								self flush: cur into: stmts.
								stmts add: (self parseControl: tk from: s)]]
					ifFalse: [cur add: tk]]].
	self flush: cur into: stmts.
	term := nil.
	^stmts asArray!
parseControl: tk from: s
	| text conds bodies elseBody cond body cases var expr fall |
	text := tk at: 2.
	text = 'return.' ifTrue: [^Array with: #return].
	text = 'break.' ifTrue: [^Array with: #break].
	text = 'continue.' ifTrue: [^Array with: #continue].
	text = 'throw.' ifTrue: [^Array with: #throw].
	text = 'if.' ifTrue: [
		conds := OrderedCollection new. bodies := OrderedCollection new. elseBody := nil.
		cond := self parseBlock: s terms: #('do.').
		term = 'do.' ifFalse: [^APLError syntax].
		[body := self parseBlock: s terms: #('else.' 'elseif.' 'end.').
		conds add: cond. bodies add: body.
		term = 'elseif.']
			whileTrue: [
				cond := self parseBlock: s terms: #('do.').
				term = 'do.' ifFalse: [^APLError syntax]].
		term = 'else.' ifTrue: [
			elseBody := self parseBlock: s terms: #('end.').
			term = 'end.' ifFalse: [^APLError syntax]].
		term = 'end.' ifFalse: [^APLError syntax].
		^Array with: #if with: conds asArray with: bodies asArray with: elseBody].
	(text = 'while.' or: [text = 'whilst.']) ifTrue: [
		cond := self parseBlock: s terms: #('do.').
		term = 'do.' ifFalse: [^APLError syntax].
		body := self parseBlock: s terms: #('end.').
		term = 'end.' ifFalse: [^APLError syntax].
		^Array with: (text = 'while.' ifTrue: [#while] ifFalse: [#whilst]) with: cond with: body].
	(text = 'for.' or: [text startsWith: 'for_']) ifTrue: [
		var := text = 'for.' ifTrue: [nil] ifFalse: [text copyFrom: 5 to: text size - 1].
		expr := self parseBlock: s terms: #('do.').
		term = 'do.' ifFalse: [^APLError syntax].
		body := self parseBlock: s terms: #('end.').
		term = 'end.' ifFalse: [^APLError syntax].
		^Array with: #for with: var with: expr with: body].
	text = 'select.' ifTrue: [
		expr := self parseBlock: s terms: #('case.' 'fcase.' 'else.' 'end.').
		cases := OrderedCollection new. elseBody := nil.
		[term = 'case.' or: [term = 'fcase.']] whileTrue: [
			fall := term = 'fcase.'.
			cond := self parseBlock: s terms: #('do.').
			term = 'do.' ifFalse: [^APLError syntax].
			body := self parseBlock: s terms: #('case.' 'fcase.' 'else.' 'end.').
			cases add: (Array with: cond with: body with: fall)].
		term = 'else.' ifTrue: [
			elseBody := self parseBlock: s terms: #('end.')].
		term = 'end.' ifFalse: [^APLError syntax].
		^Array with: #select with: expr with: cases asArray with: elseBody].
	text = 'try.' ifTrue: [
		body := self parseBlock: s terms: #('catch.' 'catchd.' 'catcht.' 'end.').
		elseBody := nil.
		term = 'end.' ifFalse: [
			elseBody := self parseBlock: s terms: #('end.').
			term = 'end.' ifFalse: [^APLError syntax]].
		^Array with: #try with: body with: elseBody].
	^APLError syntax!
isTrue: v
	"the truth of a condition: its first item is not zero"
	v isNil ifTrue: [^false].
	v class == APLArray ifFalse: [^false].
	v size = 0 ifTrue: [^false].
	^v first ~= 0!
runStatements: stmts
	1 to: stmts size do: [:i | flow isNil ifTrue: [self runStatement: (stmts at: i)]]!
runStatement: s
	| kind v items loopOn |
	kind := s at: 1.
	kind == #sent ifTrue: [
		v := self execSentence: (s at: 2).
		v isNil ifFalse: [lastValue := v].
		^self].
	kind == #assert ifTrue: [
		v := self execSentence: (s at: 2).
		(v class == APLArray and: [v data allSatisfy: [:e | e = 1]]) ifFalse: [^APLError message: 'assertion failure'].
		^self].
	kind == #if ifTrue: [
		1 to: (s at: 2) size do: [:i |
			flow isNil ifTrue: [
				lastValue := nil.
				self runStatements: ((s at: 2) at: i).
				(flow isNil and: [self isTrue: lastValue]) ifTrue: [
					self runStatements: ((s at: 3) at: i).
					^self]]].
		flow isNil ifTrue: [(s at: 4) isNil ifFalse: [self runStatements: (s at: 4)]].
		^self].
	(kind == #while or: [kind == #whilst]) ifTrue: [
		loopOn := true.
		kind == #whilst ifTrue: [
			self runStatements: (s at: 3).
			self loopFlow ifFalse: [loopOn := false]].
		[loopOn] whileTrue: [
			lastValue := nil.
			self runStatements: (s at: 2).
			(flow isNil and: [self isTrue: lastValue]) ifFalse: [loopOn := false] ifTrue: [
				self runStatements: (s at: 3).
				self loopFlow ifFalse: [loopOn := false]]].
		^self].
	kind == #for ifTrue: [
		lastValue := nil.
		self runStatements: (s at: 3).
		v := lastValue.
		v isNil ifTrue: [^APLError syntax].
		items := v isAtom ifTrue: [Array with: v] ifFalse: [v items].
		1 to: items size do: [:i |
			flow isNil ifTrue: [
				(s at: 2) isNil ifFalse: [
					self setName: (s at: 2) to: (items at: i) local: true.
					self setName: (s at: 2), '_index' to: (APLArray scalar: i - 1) local: true].
				self runStatements: (s at: 4).
				self loopFlow ifFalse: [^self]]].
		^self].
	kind == #select ifTrue: [^self runSelect: s].
	kind == #try ifTrue: [
		v := self guard: [self runStatements: (s at: 2). nil] failing: [:e | e].
		(v isKindOf: Error) ifTrue: [
			(s at: 3) isNil ifFalse: [self runStatements: (s at: 3)]].
		^self].
	kind == #return ifTrue: [flow := #return. ^self].
	kind == #break ifTrue: [flow := #break. ^self].
	kind == #continue ifTrue: [flow := #continue. ^self].
	kind == #throw ifTrue: [^APLError message: 'uncaught throw'].
	^APLError syntax!
loopFlow
	"after a loop body: true to go on looping, false to stop; handles break. and continue."
	flow == #break ifTrue: [flow := nil. ^false].
	flow == #continue ifTrue: [flow := nil. ^true].
	flow == #return ifTrue: [^false].
	^true!
runSelect: s
	| sel matched fall cs |
	lastValue := nil.
	self runStatements: (s at: 2).
	sel := lastValue.
	fall := false.
	matched := false.
	cs := s at: 3.
	1 to: cs size do: [:i | | c |
		c := cs at: i.
		flow isNil ifTrue: [
			(fall or: [matched not and: [(lastValue := nil) isNil and: [self caseMatches: sel in: (c at: 1)]]]) ifTrue: [
				matched := true.
				self runStatements: (c at: 2).
				fall := (c at: 3)]]].
	(matched not and: [flow isNil and: [(s at: 4) notNil]]) ifTrue: [self runStatements: (s at: 4)]!
caseMatches: sel in: condStmts
	| cv |
	lastValue := nil.
	self runStatements: condStmts.
	cv := lastValue.
	cv isNil ifTrue: [^false].
	(cv match: sel) ifTrue: [^true].
	cv isAtom ifTrue: [^false].
	^(cv items) anySatisfy: [:e | e match: sel]! !

!APL methodsFor: 'definitions'!
quote: aString
	| ws |
	ws := WriteStream on: String new.
	ws nextPut: $'.
	aString do: [:c | c = $' ifTrue: [ws nextPut: $']. ws nextPut: c].
	ws nextPut: $'.
	^ws contents!
runDefinition: stmts bindings: dict self: aVerb
	"run the statements of a definition in a new frame whose names are the dictionary's"
	| frame savedFlow savedLast result |
	frame := Dictionary new.
	dict keysAndValuesDo: [:k :v | v isNil ifFalse: [frame at: k put: v]].
	frames addLast: frame.
	selfStack addLast: aVerb.
	savedFlow := flow. savedLast := lastValue.
	flow := nil. lastValue := nil.
	[self runStatements: stmts. result := lastValue] ensure: [
		frames removeLast.
		selfStack removeLast.
		flow := savedFlow.
		lastValue := savedLast].
	^result isNil ifTrue: [APLArray empty] ifFalse: [result]!
operandBindings: ops
	"u and v for verb operands, m and n for noun operands (first and second)"
	| d |
	d := Dictionary new.
	ops doWithIndex: [:o :i |
		o class == APLArray
			ifTrue: [d at: (i = 1 ifTrue: ['m'] ifFalse: ['n']) put: o]
			ifFalse: [d at: (i = 1 ifTrue: ['u'] ifFalse: ['v']) put: o]].
	^d!
defineVerb: monadText dyad: dyadText display: aText bindings: extra
	"a verb whose monadic case runs one text and dyadic case another (either may be nil)"
	| me v ms ds |
	me := self.
	ms := monadText isNil ifTrue: [nil] ifFalse: [self compileBody: monadText].
	ds := dyadText isNil ifTrue: [nil] ifFalse: [self compileBody: dyadText].
	v := APLVerb derived: aText monad: nil dyad: nil.
	v setMonad: (ms isNil ifTrue: [nil] ifFalse: [[:y | | d |
			d := extra copy. d at: 'y' put: y.
			me runDefinition: ms bindings: d self: v]])
		dyad: (ds isNil ifTrue: [nil] ifFalse: [[:x :y | | d |
			d := extra copy. d at: 'x' put: x. d at: 'y' put: y.
			me runDefinition: ds bindings: d self: v]]).
	^v!
defineKind: k text: aString
	"3 : text is a verb, 4 : text a verb for the dyadic case only, 1 : an adverb, 2 : a conjunction, 0 : a noun"
	| me |
	me := self.
	k = 0 ifTrue: [^APLArray text: aString].
	k = 3 ifTrue: [^self defineVerb: aString dyad: aString display: '3 : ', (self quote: aString) bindings: Dictionary new].
	k = 4 ifTrue: [^self defineVerb: nil dyad: aString display: '4 : ', (self quote: aString) bindings: Dictionary new].
	k = 1 ifTrue: [
		^APLAdverb name: '1 : ', (self quote: aString) block: [:u |
			me defineVerb: aString dyad: aString display: u display, ' (1 : ', (self quote: aString), ')' bindings: (me operandBindings: (Array with: u))]].
	k = 2 ifTrue: [
		^APLConj name: '2 : ', (self quote: aString) block: [:u :v |
			me defineVerb: aString dyad: aString display: '(2 : ', (self quote: aString), ')' bindings: (me operandBindings: (Array with: u with: v))]].
	^APLError domain!
selfVerb
	"the verb now running, for  $:"
	selfStack isEmpty ifTrue: [^APLError message: 'no verb running'].
	^selfStack last! !

!APL methodsFor: 'running'!
guard: aBlock
	^self guard: aBlock failing: nil!
guard: aBlock failing: handler
	"run aBlock; an error that is not an APLError becomes an APLError (domain error, or index error), which handler (if any) may answer instead"
	| r |
	r := aBlock on: Error do: [:e | e].
	(r isKindOf: Error) ifFalse: [^r].
	handler isNil ifFalse: [^handler value: r].
	r class == APLError ifTrue: [^APLError message: r messageText].
	Debug == true ifTrue: [^APLError message: 'domain error (', r class name, ': ', r messageText, ')'].
	(r isKindOf: SubscriptOutOfBounds) ifTrue: [^APLError index].
	^APLError domain!
sentencesIn: tokens
	"the tokens split at newlines into sentences (an Array of Arrays)"
	| out cur |
	out := OrderedCollection new.
	cur := OrderedCollection new.
	tokens do: [:t |
		(t at: 1) == #nl
			ifTrue: [out add: cur asArray. cur := OrderedCollection new]
			ifFalse: [cur add: t]].
	out add: cur asArray.
	^out!
display: v
	"what a value looks like when printed"
	v class == APLArray ifTrue: [^APLFormat text: v precision: precision].
	^v display!
run: text display: out
	"run every sentence of the text, writing what each would print to the stream"
	| prev sents first lastShown |
	prev := Current.
	Current := self.
	first := true.
	[sents := self sentencesIn: (APLLexer tokens: text).
	sents do: [:sent | | v |
		v := self guard: [self execSentence: sent].
		(v notNil and: [assigned not]) ifTrue: [
			first ifFalse: [out nextPut: Character lf].
			first := false.
			out nextPutAll: (self display: v)]]]
		ensure: [Current := prev]!
valueOf: text
	"run the text and answer the value of its last sentence"
	| prev sents v |
	prev := Current.
	Current := self.
	[sents := self sentencesIn: (APLLexer tokens: text).
	v := nil.
	sents do: [:sent | | r |
		r := self guard: [self execSentence: sent].
		r isNil ifFalse: [v := r]]]
		ensure: [Current := prev].
	^v! !
