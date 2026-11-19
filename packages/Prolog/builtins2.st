"Prolog built-in predicates, part 2: atoms and strings, sorting, the clause database, flags and operators."

"---- text ----"

!PrologEngine methodsFor: 'text'!
textFor: t
	"the text of an atom, string, number, or list of codes or characters"
	| x |
	x := t plDeref.
	x isPrologVar ifTrue: [^self instantiationError].
	x == #'[]' ifTrue: [^''].
	x isSymbol ifTrue: [^x asString].
	x isString ifTrue: [^x].
	x isInteger ifTrue: [^x printString].
	x isFloat ifTrue: [^self writer stringFor: x].
	(x isPrologStruct and: [x isList]) ifTrue: [^self textFromList: x].
	^self typeError: #atomic culprit: x!
textFromList: l
	| out t e |
	out := WriteStream on: (String new: 16).
	t := l plDeref.
	[t isPrologStruct and: [t isList]] whileTrue: [
		e := t first plDeref.
		e isInteger
			ifTrue: [out nextPutAll: (Character value: e) utf8Encoded]
			ifFalse: [
				e isSymbol ifTrue: [out nextPutAll: e asString]
				ifFalse: [e isPrologVar ifTrue: [^self instantiationError]. ^self typeError: #character culprit: e]].
		t := t second plDeref].
	t isPrologVar ifTrue: [^self instantiationError].
	t == #'[]' ifFalse: [^self typeError: #list culprit: l].
	^out contents!
codesOf: aString
	^PrologStruct list: (aString asWideString asArray collect: [:c | c value])!
charsOf: aString
	^PrologStruct list: (aString asWideString asArray collect: [:c | c asString asSymbol])!
numberFrom: aString
	"the number written in aString (optional sign and surrounding white space), or nil"
	| s neg r tok |
	s := aString trimBoth.
	s isEmpty ifTrue: [^nil].
	neg := false.
	(s first = $- or: [s first = $+]) ifTrue: [neg := s first = $-. s := s copyFrom: 2 to: s size].
	(s isEmpty or: [s first isDigit not]) ifTrue: [^nil].
	r := PrologReader on: s ops: ops flags: flags.
	tok := [r readToken] on: PrologThrow do: [:e | ^nil].
	(tok kind == #int or: [tok kind == #float]) ifFalse: [^nil].
	r readToken kind == #eof ifFalse: [^nil].
	^neg ifTrue: [tok value negated] ifFalse: [tok value]!
isTextTerm: t
	| x |
	x := t plDeref.
	^x isPrologVar not! !

!PrologEngine methodsFor: 'atoms and strings'!
biAtomCodes: a
	| x |
	x := (a at: 1) plDeref.
	x isPrologVar ifFalse: [^self unify: (a at: 2) with: (self codesOf: (self textFor: x))].
	^self unify: x with: (self textFor: (a at: 2)) asSymbol!
biAtomChars: a
	| x |
	x := (a at: 1) plDeref.
	x isPrologVar ifFalse: [^self unify: (a at: 2) with: (self charsOf: (self textFor: x))].
	^self unify: x with: (self textFor: (a at: 2)) asSymbol!
biCharCode: a
	| c n |
	c := (a at: 1) plDeref.
	c isPrologVar ifFalse: [^self unify: (a at: 2) with: c asString asWideString first value].
	n := (a at: 2) plDeref.
	n isPrologVar ifTrue: [^self instantiationError].
	n isInteger ifFalse: [^self typeError: #integer culprit: n].
	^self unify: c with: (Character value: n) asString asSymbol!
biAtomLength: a
	| x |
	x := (a at: 1) plDeref.
	x isPrologVar ifTrue: [^self instantiationError].
	^self unify: (a at: 2) with: (self textFor: x) asWideString size!
biAtomNumber: a
	| x n |
	x := (a at: 1) plDeref.
	x isPrologVar ifFalse: [
		n := self numberFrom: (self textFor: x).
		^n notNil and: [self unify: (a at: 2) with: n]].
	n := (a at: 2) plDeref.
	n isPrologVar ifTrue: [^self instantiationError].
	^self unify: x with: (self textFor: n) asSymbol!
biNumberCodes: a
	| x n |
	x := (a at: 1) plDeref.
	x isPrologVar ifFalse: [^self unify: (a at: 2) with: (self codesOf: (self textFor: x))].
	n := self numberFrom: (self textFor: (a at: 2)).
	n isNil ifTrue: [^self throwFormal: (PrologStruct functor: #syntax_error with: #illegal_number)].
	^self unify: x with: n!
biNumberChars: a
	| x n |
	x := (a at: 1) plDeref.
	x isPrologVar ifFalse: [^self unify: (a at: 2) with: (self charsOf: (self textFor: x))].
	n := self numberFrom: (self textFor: (a at: 2)).
	n isNil ifTrue: [^self throwFormal: (PrologStruct functor: #syntax_error with: #illegal_number)].
	^self unify: x with: n!
biAtomString: a
	| x |
	x := (a at: 1) plDeref.
	x isPrologVar ifFalse: [^self unify: (a at: 2) with: (self textFor: x) copy].
	^self unify: x with: (self textFor: (a at: 2)) asSymbol!
biNumberString: a
	| x n |
	x := (a at: 1) plDeref.
	x isPrologVar ifFalse: [^self unify: (a at: 2) with: (self textFor: x) copy].
	n := self numberFrom: (self textFor: (a at: 2)).
	^n notNil and: [self unify: x with: n]!
biTermToAtom: a
	| t |
	t := (a at: 1) plDeref.
	t isPrologVar ifFalse: [^self unify: (a at: 2) with: (self textOf: t quoted: true) asSymbol].
	^self unify: t with: (self parseTerm: (self textFor: (a at: 2)))!
biTermString: a
	| t |
	t := (a at: 1) plDeref.
	t isPrologVar ifFalse: [^self unify: (a at: 2) with: (self textOf: t quoted: true)].
	^self unify: t with: (self parseTerm: (self textFor: (a at: 2)))!
biAtomToTerm: a
	| r t bs |
	r := PrologReader on: (self textFor: (a at: 1)), ' .' ops: ops flags: flags.
	t := r readTerm.
	t isNil ifTrue: [^self throwFormal: (PrologStruct functor: #syntax_error with: #end_of_file)].
	bs := r variableBindings collect: [:b | PrologStruct functor: #'=' with: b key asSymbol with: b value].
	^(self unify: (a at: 2) with: t) and: [self unify: (a at: 3) with: (PrologStruct list: bs)]!
parseTerm: aString
	| r t |
	r := PrologReader on: aString, ' .' ops: ops flags: flags.
	t := r readTerm.
	t isNil ifTrue: [^self throwFormal: (PrologStruct functor: #syntax_error with: #end_of_file)].
	^t!
biUpcaseAtom: a
	^self unify: (a at: 2) with: (self textFor: (a at: 1)) asWideString asUppercase utf8Encoded asSymbol!
biDowncaseAtom: a
	^self unify: (a at: 2) with: (self textFor: (a at: 1)) asWideString asLowercase utf8Encoded asSymbol!
biStringUpper: a
	^self unify: (a at: 2) with: (self textFor: (a at: 1)) asWideString asUppercase utf8Encoded!
biStringLower: a
	^self unify: (a at: 2) with: (self textFor: (a at: 1)) asWideString asLowercase utf8Encoded!
concat: a as: aBlock
	"atom_concat/3 and string_concat/3: aBlock converts text to the result type"
	| x y z s splits n |
	x := (a at: 1) plDeref. y := (a at: 2) plDeref.
	(x isPrologVar not and: [y isPrologVar not]) ifTrue: [
		^self unify: (a at: 3) with: (aBlock value: (self textFor: x), (self textFor: y))].
	z := (a at: 3) plDeref.
	z isPrologVar ifTrue: [^self instantiationError].
	s := (self textFor: z) asWideString.
	n := s size.
	splits := (0 to: n) asArray.
	^self pushAlternatives: (PrologAlts over: splits do: [:i |
		(self unify: x with: (aBlock value: (s copyFrom: 1 to: i) utf8Encoded))
			and: [self unify: y with: (aBlock value: (s copyFrom: i + 1 to: n) utf8Encoded)]])!
biAtomConcat: a
	^self concat: a as: [:t | t asSymbol]!
biStringConcat: a
	^self concat: a as: [:t | t]!
subText: a as: aBlock
	"sub_atom/5 and sub_string/5"
	| text sub n sols b l af |
	text := (self textFor: (a at: 1)) asWideString. n := text size.
	sub := (a at: 5) plDeref.
	b := (a at: 2) plDeref. l := (a at: 3) plDeref. af := (a at: 4) plDeref.
	sols := OrderedCollection new.
	sub isPrologVar not
		ifTrue: [
			| s pos |
			s := (self textFor: sub) asWideString.
			pos := text indexOfSubCollection: s startingAt: 1.
			[pos > 0] whileTrue: [
				sols add: (Array with: pos - 1 with: s size with: n - (pos - 1) - s size).
				pos := text indexOfSubCollection: s startingAt: pos + 1]]
		ifFalse: [
			(b isInteger ifTrue: [Array with: b] ifFalse: [(0 to: n) asArray]) do: [:bb |
				(l isInteger ifTrue: [Array with: l] ifFalse: [
					af isInteger ifTrue: [Array with: n - bb - af] ifFalse: [(0 to: n - bb) asArray]]) do: [:ll |
					(ll >= 0 and: [bb + ll <= n]) ifTrue: [
						(af isInteger not or: [af = (n - bb - ll)]) ifTrue: [sols add: (Array with: bb with: ll with: n - bb - ll)]]]]].
	^self pushAlternatives: (PrologAlts over: sols asArray do: [:s |
		(self unify: b with: (s at: 1)) and: [(self unify: l with: (s at: 2)) and: [(self unify: af with: (s at: 3)) and: [
			self unify: sub with: (aBlock value: (text copyFrom: (s at: 1) + 1 to: (s at: 1) + (s at: 2)) utf8Encoded)]]]])!
biSubAtom: a
	^self subText: a as: [:t | t asSymbol]!
biSubString: a
	^self subText: a as: [:t | t]!
biAtomicListConcat2: a
	| out |
	out := WriteStream on: String new.
	(self listToArray: (a at: 1)) do: [:e | out nextPutAll: (self textFor: e)].
	^self unify: (a at: 2) with: out contents asSymbol!
biAtomicListConcat3: a
	| sep items out l parts atom pos start |
	sep := self textFor: (a at: 2).
	items := nil.
	items := [self listToArray: (a at: 1)] on: PrologThrow do: [:e | nil].
	(items notNil and: [items allSatisfy: [:e | e plDeref isPrologVar not]]) ifTrue: [
		out := WriteStream on: String new.
		items doWithIndex: [:e :i | i > 1 ifTrue: [out nextPutAll: sep]. out nextPutAll: (self textFor: e)].
		^self unify: (a at: 3) with: out contents asSymbol].
	"split mode"
	atom := (a at: 3) plDeref.
	atom isPrologVar ifTrue: [^self instantiationError].
	sep isEmpty ifTrue: [^self domainError: #non_empty_atom culprit: (a at: 2)].
	parts := OrderedCollection new.
	l := self textFor: atom.
	start := 1.
	[pos := l indexOfSubCollection: sep startingAt: start.
	 pos > 0] whileTrue: [
		parts add: (l copyFrom: start to: pos - 1) asSymbol.
		start := pos + sep size].
	parts add: (l copyFrom: start to: l size) asSymbol.
	^self unify: (a at: 1) with: (PrologStruct list: parts)!
biSplitString: a
	| text seps pad parts cur result |
	text := self textFor: (a at: 1). seps := self textFor: (a at: 2). pad := self textFor: (a at: 3).
	parts := OrderedCollection new.
	cur := WriteStream on: String new.
	text do: [:c |
		(seps includes: c)
			ifTrue: [parts add: cur contents. cur := WriteStream on: String new]
			ifFalse: [cur nextPut: c]].
	parts add: cur contents.
	result := parts collect: [:p | self strip: p of: pad].
	^self unify: (a at: 4) with: (PrologStruct list: result)!
strip: s of: pad
	| i j |
	i := 1. j := s size.
	[i <= j and: [pad includes: (s at: i)]] whileTrue: [i := i + 1].
	[j >= i and: [pad includes: (s at: j)]] whileTrue: [j := j - 1].
	^s copyFrom: i to: j!
biStringChars: a
	| x |
	x := (a at: 1) plDeref.
	x isPrologVar ifFalse: [^self unify: (a at: 2) with: (self charsOf: (self textFor: x))].
	^self unify: x with: (self textFor: (a at: 2)) copy!
biStringCodes: a
	| x |
	x := (a at: 1) plDeref.
	x isPrologVar ifFalse: [^self unify: (a at: 2) with: (self codesOf: (self textFor: x))].
	^self unify: x with: (self textFor: (a at: 2)) copy!
biStringToAtom: a
	| x |
	x := (a at: 1) plDeref.
	x isPrologVar ifFalse: [^self unify: (a at: 2) with: (self textFor: x) asSymbol].
	^self unify: x with: (self textFor: (a at: 2)) copy!
biTextToString: a
	^self unify: (a at: 2) with: (self textFor: (a at: 1)) copy!
biStringCode: a
	| i s |
	i := (a at: 1) plDeref. s := (self textFor: (a at: 2)) asWideString.
	i isInteger ifFalse: [^self typeError: #integer culprit: i].
	^(i between: 1 and: s size) and: [self unify: (a at: 3) with: (s at: i) value]!
biSformat: a
	^self unify: (a at: 1) with: (self formatString: (self textFor: (a at: 2)) args: (a at: 3))!
charTypeOf: ch type: ty
	"ch: a Character; ty: the dereferenced type term; true if ch has the type (binding the argument when it has one)"
	| name v |
	ty isPrologVar ifTrue: [^self instantiationError].
	ty isSymbol
		ifTrue: [
			name := ty.
			name == #alpha ifTrue: [^ch isLetter or: [ch isDigit or: [ch = $_]]].
			name == #alnum ifTrue: [^ch isLetter or: [ch isDigit]].
			name == #digit ifTrue: [^ch isDigit].
			name == #space ifTrue: [^ch isSeparator].
			name == #white ifTrue: [^ch = $  or: [ch = Character tab]].
			name == #upper ifTrue: [^ch isUppercase].
			name == #lower ifTrue: [^ch isLowercase].
			name == #punct ifTrue: [^ch value > 32 and: [ch value ~= 127 and: [ch isLetter not and: [ch isDigit not]]]].
			name == #csym ifTrue: [^ch isLetter or: [ch isDigit or: [ch = $_]]].
			name == #csymf ifTrue: [^ch isLetter or: [ch = $_]].
			name == #graph ifTrue: [^ch value > 32 and: [ch value ~= 127]].
			name == #ascii ifTrue: [^ch value < 128].
			name == #end_of_line ifTrue: [^ch value = 10 or: [ch value = 13]].
			^false].
	(ty isPrologStruct and: [ty arity = 1]) ifFalse: [^false].
	name := ty functor. v := ty first.
	name == #digit ifTrue: [^ch isDigit and: [self unify: v with: ch digitValue]].
	name == #to_lower ifTrue: [^self unify: v with: ch asLowercase asString asSymbol].
	name == #to_upper ifTrue: [^self unify: v with: ch asUppercase asString asSymbol].
	name == #upper ifTrue: [^ch isUppercase and: [self unify: v with: ch asLowercase asString asSymbol]].
	name == #lower ifTrue: [^ch isLowercase and: [self unify: v with: ch asUppercase asString asSymbol]].
	^false!
biCharType: a
	| c |
	c := (a at: 1) plDeref.
	c isPrologVar ifTrue: [^self instantiationError].
	^self charTypeOf: (self textFor: c) asWideString first type: (a at: 2) plDeref!
biCodeType: a
	| c |
	c := (a at: 1) plDeref.
	c isPrologVar ifTrue: [^self instantiationError].
	^self charTypeOf: (c isInteger ifTrue: [Character value: c] ifFalse: [(self textFor: c) asWideString first]) type: (a at: 2) plDeref! !

"---- sorting ----"

!PrologEngine methodsFor: 'sorting'!
sorted: anArray by: aBlock
	"a stable merge sort; aBlock value: a value: b is true when a may come before b"
	| n left right out i j |
	n := anArray size.
	n <= 1 ifTrue: [^anArray].
	left := self sorted: (anArray copyFrom: 1 to: n // 2) by: aBlock.
	right := self sorted: (anArray copyFrom: n // 2 + 1 to: n) by: aBlock.
	out := OrderedCollection new: n.
	i := 1. j := 1.
	[i <= left size and: [j <= right size]] whileTrue: [
		(aBlock value: (left at: i) value: (right at: j))
			ifTrue: [out add: (left at: i). i := i + 1]
			ifFalse: [out add: (right at: j). j := j + 1]].
	[i <= left size] whileTrue: [out add: (left at: i). i := i + 1].
	[j <= right size] whileTrue: [out add: (right at: j). j := j + 1].
	^out asArray!
dedupe: anArray
	"remove adjacent duplicates (standard order equality)"
	| out |
	out := OrderedCollection new.
	anArray do: [:e | (out isEmpty or: [(self compare: out last with: e) ~= 0]) ifTrue: [out add: e]].
	^out asArray!
biMsort: a
	^self unify: (a at: 2) with: (PrologStruct list: (self sorted: (self listToArray: (a at: 1)) by: [:x :y | (self compare: x with: y) <= 0]))!
biSort2: a
	^self unify: (a at: 2) with: (PrologStruct list: (self dedupe: (self sorted: (self listToArray: (a at: 1)) by: [:x :y | (self compare: x with: y) <= 0])))!
keyOf: t
	| x |
	x := t plDeref.
	(x isPrologStruct and: [x functor == #'-' and: [x arity = 2]]) ifFalse: [
		x isPrologVar ifTrue: [^self instantiationError].
		^self typeError: #pair culprit: x].
	^x first!
biKeysort: a
	| items |
	items := self listToArray: (a at: 1).
	items do: [:e | self keyOf: e].
	^self unify: (a at: 2) with: (PrologStruct list: (self sorted: items by: [:x :y | (self compare: (self keyOf: x) with: (self keyOf: y)) <= 0]))!
biSort4: a
	| key order items sel sorted out |
	key := (a at: 1) plDeref. order := (a at: 2) plDeref.
	key isInteger ifFalse: [^self typeError: #integer culprit: key].
	items := self listToArray: (a at: 3).
	sel := [:t | key = 0 ifTrue: [t] ifFalse: [
		| x |
		x := t plDeref.
		x isPrologStruct ifFalse: [^self typeError: #compound culprit: x].
		(key between: 1 and: x arity) ifFalse: [^self typeError: #compound culprit: x].
		x args at: key]].
	(order == #'@<' or: [order == #'@=<'])
		ifTrue: [sorted := self sorted: items by: [:x :y | (self compare: (sel value: x) with: (sel value: y)) <= 0]]
		ifFalse: [
			(order == #'@>' or: [order == #'@>=']) ifFalse: [^self domainError: #order culprit: order].
			sorted := self sorted: items by: [:x :y | (self compare: (sel value: x) with: (sel value: y)) >= 0]].
	(order == #'@<' or: [order == #'@>']) ifTrue: [
		out := OrderedCollection new.
		sorted do: [:e | (out isEmpty or: [(self compare: (sel value: out last) with: (sel value: e)) ~= 0]) ifTrue: [out add: e]].
		sorted := out asArray].
	^self unify: (a at: 4) with: (PrologStruct list: sorted)!
biBagofPrepare: a
	"'$bagof_prepare'(Template, Goal, InnerGoal, Witness): strip Var^Goal and find the free variables"
	| goal bound free x w |
	goal := (a at: 2) plDeref.
	bound := OrderedCollection new.
	self variablesOf: (a at: 1) into: bound.
	[goal isPrologStruct and: [goal functor == #'^' and: [goal arity = 2]]] whileTrue: [
		self variablesOf: goal first into: bound.
		goal := goal second plDeref].
	free := OrderedCollection new.
	self variablesOf: goal into: free.
	free := free reject: [:v | bound anySatisfy: [:b | b == v]].
	w := free isEmpty ifTrue: [#none] ifFalse: [PrologStruct functor: #v args: free asArray].
	^(self unify: (a at: 3) with: goal) and: [self unify: (a at: 4) with: w]!
biBagofGroup: a
	"'$bagof_group'(SortedWitnessTemplatePairs, Groups): Groups is a list of Witness-Items"
	| pairs groups curKey cur |
	pairs := self listToArray: (a at: 1).
	groups := OrderedCollection new.
	curKey := nil. cur := nil.
	pairs do: [:p |
		| pr |
		pr := p plDeref.
		(curKey notNil and: [self variant: curKey with: pr first map: IdentityDictionary new])
			ifTrue: [cur add: pr second]
			ifFalse: [
				curKey := pr first. cur := OrderedCollection new. cur add: pr second.
				groups add: (Array with: curKey with: cur)]].
	^self unify: (a at: 2) with: (PrologStruct list: (groups collect: [:g | PrologStruct functor: #'-' with: (g at: 1) with: (PrologStruct list: (g at: 2))]))! !

"---- the clause database ----"

!PrologEngine methodsFor: 'database built-ins'!
biAssertz: a
	self addClause: (self copyTerm: (a at: 1)) atEnd: true.
	^true!
biAsserta: a
	self addClause: (self copyTerm: (a at: 1)) atEnd: false.
	^true!
splitClause: t
	"Array(head, body) of a clause term"
	| x |
	x := t plDeref.
	(x isPrologStruct and: [x functor == #':-' and: [x arity = 2]]) ifTrue: [^Array with: x first plDeref with: x second].
	^Array with: x with: #true!
predicateOf: head create: aBoolean
	| h |
	h := head plDeref.
	h isPrologVar ifTrue: [^self instantiationError].
	h isSymbol ifTrue: [^self userPredicate: h arity: 0 create: aBoolean].
	h isPrologStruct ifFalse: [^self typeError: #callable culprit: h].
	^self userPredicate: h functor arity: h arity create: aBoolean!
biRetract: a
	| parts head body pred snapshot |
	parts := self splitClause: (a at: 1).
	head := parts at: 1. body := parts at: 2.
	(head isPrologStruct or: [head isSymbol]) ifFalse: [^head isPrologVar ifTrue: [self instantiationError] ifFalse: [self typeError: #callable culprit: head]].
	(PrologEngine isBuiltin: (head isSymbol ifTrue: [head] ifFalse: [head functor]) arity: (head isSymbol ifTrue: [0] ifFalse: [head arity]))
		ifTrue: [^self permissionError: #modify type: #static_procedure culprit: head].
	pred := self predicateOf: head create: false.
	pred isNil ifTrue: [^false].
	snapshot := pred clauses.
	^self pushAlternatives: (PrologAlts over: snapshot do: [:c |
		| t mark |
		mark := trail size.
		t := self clauseTermsOf: c.
		((self unify: head with: (t at: 1)) and: [self unify: body with: (t at: 2)])
			ifTrue: [pred remove: c. true]
			ifFalse: [self undoTo: mark. false]])!
biRetractAll: a
	| head pred snapshot |
	head := (a at: 1) plDeref.
	(PrologEngine isBuiltin: (head isSymbol ifTrue: [head] ifFalse: [head isPrologStruct ifTrue: [head functor] ifFalse: [nil]]) arity: (head isPrologStruct ifTrue: [head arity] ifFalse: [0]))
		ifTrue: [^self permissionError: #modify type: #static_procedure culprit: head].
	pred := self predicateOf: head create: true.
	pred beDynamic.
	snapshot := pred clauses.
	snapshot do: [:c |
		| t mark |
		mark := trail size.
		t := self clauseTermsOf: c.
		(self unify: head with: (t at: 1)) ifTrue: [pred remove: c].
		self undoTo: mark].
	^true!
biAbolish: a
	| spec pred |
	spec := (a at: 1) plDeref.
	(spec isPrologStruct and: [spec functor == #'/' and: [spec arity = 2]]) ifFalse: [^self typeError: #predicate_indicator culprit: spec].
	pred := self userPredicate: spec first plDeref arity: spec second plDeref create: false.
	pred notNil ifTrue: [pred removeAll].
	^true!
biClause: a
	| head pred snapshot |
	head := (a at: 1) plDeref.
	head isPrologVar ifTrue: [^self instantiationError].
	(head isSymbol or: [head isPrologStruct]) ifFalse: [^self typeError: #callable culprit: head].
	(PrologEngine isBuiltin: (head isSymbol ifTrue: [head] ifFalse: [head functor]) arity: (head isSymbol ifTrue: [0] ifFalse: [head arity]))
		ifTrue: [^self permissionError: #access type: #private_procedure culprit: head].
	pred := self predicateOf: head create: false.
	pred isNil ifTrue: [^false].
	snapshot := pred clauses.
	^self pushAlternatives: (PrologAlts over: snapshot do: [:c |
		| t |
		t := self clauseTermsOf: c.
		(self unify: head with: (t at: 1)) and: [self unify: (a at: 2) with: (t at: 2)]])!
declareDynamic: spec
	| s pred |
	s := spec plDeref.
	s isPrologVar ifTrue: [^self instantiationError].
	(s isPrologStruct and: [(s functor == #',' or: [s isList]) and: [s arity = 2]]) ifTrue: [
		self declareDynamic: s first. ^self declareDynamic: s second].
	s == #'[]' ifTrue: [^self].
	(s isPrologStruct and: [s functor == #'/' and: [s arity = 2]]) ifFalse: [^self typeError: #predicate_indicator culprit: s].
	(PrologEngine isBuiltin: s first plDeref arity: s second plDeref) ifTrue: [^self permissionError: #modify type: #static_procedure culprit: s].
	pred := self userPredicate: s first plDeref arity: s second plDeref create: true.
	pred beDynamic!
biDynamic: a
	self declareDynamic: (a at: 1).
	^true!
biCurrentPredicate: a
	| spec found |
	spec := (a at: 1) plDeref.
	(spec isPrologStruct and: [spec functor == #'/' and: [spec arity = 2]]) ifFalse: [^spec isPrologVar ifTrue: [self instantiationError] ifFalse: [self typeError: #predicate_indicator culprit: spec]].
	found := OrderedCollection new.
	self predicatesDo: [:p | (p isDefined and: [p isLibrary not]) ifTrue: [found add: p]].
	^self pushAlternatives: (PrologAlts over: found asArray do: [:p |
		(self unify: spec first with: p name) and: [self unify: spec second with: p arity]])!
biPredicateProperty: a
	| head pred props |
	head := (a at: 1) plDeref.
	head isPrologVar ifTrue: [^false].
	(head isSymbol or: [head isPrologStruct]) ifFalse: [^false].
	pred := self lookup: (head isSymbol ifTrue: [head] ifFalse: [head functor]) arity: (head isSymbol ifTrue: [0] ifFalse: [head arity]).
	pred isNil ifTrue: [^false].
	props := OrderedCollection new.
	pred kind == #user
		ifTrue: [props add: #defined. pred isDynamic ifTrue: [props add: #dynamic] ifFalse: [props add: #static].
			props add: (PrologStruct functor: #number_of_clauses with: pred clauses size)]
		ifFalse: [props add: #defined; add: #built_in; add: #static].
	^self pushAlternatives: (PrologAlts over: props asArray do: [:p | self unify: (a at: 2) with: p])!
biThrow: a
	| b |
	b := (a at: 1) plDeref.
	b isPrologVar ifTrue: [^self instantiationError].
	^PrologThrow ball: (self copyTerm: b)!
biHalt0: a
	^PrologHalt new code: 0; signal!
biHalt1: a
	^PrologHalt new code: ((a at: 1) plDeref isInteger ifTrue: [(a at: 1) plDeref] ifFalse: [0]); signal!
biConsult: a
	| f items |
	f := (a at: 1) plDeref.
	f isPrologVar ifTrue: [^self instantiationError].
	items := (f isPrologStruct and: [f isList]) ifTrue: [self listToArray: f] ifFalse: [Array with: f].
	items do: [:each |
		| path |
		path := self textFor: each.
		(FileStream exists: path) ifFalse: [(FileStream exists: path, '.pl') ifTrue: [path := path, '.pl']].
		self consultFile: path].
	^true!
biInitialization: a
	^self solveOnce: (a at: 1)!
biOp: a
	| p t names |
	p := (a at: 1) plDeref. t := (a at: 2) plDeref.
	(p isInteger and: [p between: 0 and: 1200]) ifFalse: [^p isPrologVar ifTrue: [self instantiationError] ifFalse: [self domainError: #operator_priority culprit: p]].
	(t isSymbol and: [#(#xfx #xfy #yfx #fy #fx #xf #yf) includes: t]) ifFalse: [^self domainError: #operator_specifier culprit: t].
	names := (a at: 3) plDeref.
	(names isPrologStruct and: [names isList]) ifTrue: [names := self listToArray: names] ifFalse: [names := Array with: names].
	names do: [:n |
		| nm |
		nm := n plDeref.
		nm isSymbol ifFalse: [^self typeError: #atom culprit: nm].
		ops add: p type: t name: nm].
	^true!
biCurrentOp: a
	| sols |
	sols := OrderedCollection new.
	ops allDo: [:pri :type :name | sols add: (Array with: pri with: type with: name)].
	^self pushAlternatives: (PrologAlts over: sols asArray do: [:s |
		(self unify: (a at: 1) with: (s at: 1)) and: [(self unify: (a at: 2) with: (s at: 2)) and: [self unify: (a at: 3) with: (s at: 3)]]])!
biSetFlag: a
	| f v |
	f := (a at: 1) plDeref. v := (a at: 2) plDeref.
	f isSymbol ifFalse: [^f isPrologVar ifTrue: [self instantiationError] ifFalse: [self typeError: #atom culprit: f]].
	flags at: f put: v.
	^true!
biCurrentFlag: a
	| sols |
	sols := OrderedCollection new.
	flags keysAndValuesDo: [:k :v | sols add: (Array with: k with: v)].
	sols add: (Array with: #bounded with: #false); add: (Array with: #max_integer with: SmallInteger maxVal); add: (Array with: #min_integer with: SmallInteger minVal).
	^self pushAlternatives: (PrologAlts over: sols asArray do: [:s | (self unify: (a at: 1) with: (s at: 1)) and: [self unify: (a at: 2) with: (s at: 2)]])!
biSetVal: a
	| k |
	k := (a at: 1) plDeref.
	k isSymbol ifFalse: [^self typeError: #atom culprit: k].
	globals at: k put: (self copyTerm: (a at: 2)).
	^true!
biGetVal: a
	| k v |
	k := (a at: 1) plDeref.
	k isSymbol ifFalse: [^self typeError: #atom culprit: k].
	v := globals at: k ifAbsent: [^self existenceError: #variable what: k].
	^self unify: (a at: 2) with: v! !
