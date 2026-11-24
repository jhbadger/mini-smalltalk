"Searching, sorting and formatting: index of, membership, nub, grade, match, the formatting verbs, matrix inverse and
product, the bridge verb st, and defineStructural, defineSearching and defineOthers, which put every verb above into
the table of primitives with its spelling and ranks."

!APLPrims class methodsFor: 'searching'!
indexOf: x with: y
	| cr cells xs dict res key n frame |
	n := x tally.
	cr := ((x rank - 1) max: 0) min: y rank.
	cells := y cellsOfRank: cr.
	frame := y shape copyFrom: 1 to: y rank - cr.
	(x rank <= 1 and: [cr = 0]) ifTrue: [
		dict := Dictionary new.
		xs := x data.
		1 to: xs size do: [:i |
			key := self keyOf: (xs at: i).
			key isNil ifFalse: [dict at: key ifAbsent: [dict at: key put: i - 1]]].
		res := cells collect: [:c |
			key := self keyOf: c first.
			key isNil
				ifTrue: [self linearIndex: c in: x]
				ifFalse: [dict at: key ifAbsent: [self linearIndexBoxes: c in: x ifNone: n]]].
		^APLArray shape: frame data: res].
	xs := x items.
	res := cells collect: [:c | | found |
		found := n.
		1 to: xs size do: [:i | (found = n and: [(xs at: i) match: c]) ifTrue: [found := i - 1]].
		found].
	^APLArray shape: frame data: res!
linearIndexBoxes: c in: x ifNone: n
	"the index of a cell that has a key but was not found: boxes in x may still match it"
	x isBoxed ifFalse: [^n].
	^n!
linearIndex: c in: x
	| xs |
	xs := x data.
	1 to: xs size do: [:i | (APLArray scalar: (xs at: i)) = c ifTrue: [^i - 1]].
	^xs size!
member: x with: y
	| cr cells ys dict key res frame |
	cr := ((y rank - 1) max: 0) min: x rank.
	cells := x cellsOfRank: cr.
	frame := x shape copyFrom: 1 to: x rank - cr.
	(y rank <= 1 and: [cr = 0]) ifTrue: [
		dict := Dictionary new.
		y data do: [:e | key := self keyOf: e. key isNil ifFalse: [dict at: key put: true]].
		res := cells collect: [:c |
			key := self keyOf: c first.
			key isNil
				ifTrue: [(y data anySatisfy: [:e | (APLArray scalar: e) = c]) ifTrue: [1] ifFalse: [0]]
				ifFalse: [(dict includesKey: key) ifTrue: [1] ifFalse: [0]]].
		^APLArray shape: frame data: res].
	ys := y isAtom ifTrue: [Array with: y] ifFalse: [y items].
	res := cells collect: [:c | (ys anySatisfy: [:e | e match: c]) ifTrue: [1] ifFalse: [0]].
	^APLArray shape: frame data: res!
indices: y
	| out |
	out := OrderedCollection new.
	y integers doWithIndex: [:c :i |
		c < 0 ifTrue: [^APLError domain].
		c timesRepeat: [out add: i - 1]].
	^APLArray vector: out!
interval: x with: y
	"x I. y: how many items of the ascending list x are not above each atom of y"
	| lo hi mid xs |
	xs := x data.
	^y mapAtoms: [:e |
		lo := 0. hi := xs size.
		[lo < hi] whileTrue: [
			mid := (lo + hi) // 2.
			(self cmp: (xs at: mid + 1) with: e) <= 0 ifTrue: [lo := mid + 1] ifFalse: [hi := mid]].
		lo]!
nub: y
	| seen out items key keep |
	y isAtom ifTrue: [^y ravel].
	items := y rank = 1 ifTrue: [y data] ifFalse: [y items].
	seen := Dictionary new.
	out := OrderedCollection new.
	keep := OrderedCollection new.
	items do: [:e | | dup |
		key := e class == APLArray ifTrue: [nil] ifFalse: [self keyOf: e].
		key isNil
			ifTrue: [dup := out anySatisfy: [:o | o = e]. dup ifFalse: [out add: e]]
			ifFalse: [(seen includesKey: key) ifFalse: [seen at: key put: true. out add: e]]].
	y rank = 1 ifTrue: [^(APLArray vector: out) proto: y proto].
	^APLArray stack: out asArray!
nubSieve: y
	| seen out items key firsts |
	y isAtom ifTrue: [^APLArray scalar: 1].
	items := y rank = 1 ifTrue: [y data] ifFalse: [y items].
	seen := Dictionary new.
	firsts := OrderedCollection new.
	out := Array new: items size.
	items doWithIndex: [:e :i | | dup |
		key := e class == APLArray ifTrue: [nil] ifFalse: [self keyOf: e].
		key isNil
			ifTrue: [dup := firsts anySatisfy: [:o | o = e]. dup ifFalse: [firsts add: e]. out at: i put: (dup ifTrue: [0] ifFalse: [1])]
			ifFalse: [
				(seen includesKey: key)
					ifTrue: [out at: i put: 0]
					ifFalse: [seen at: key put: true. out at: i put: 1]]].
	^APLArray vector: out!
keysOf: y
	"the items of y to sort or group by: single items for a vector, rows for a table"
	^y isAtom ifTrue: [Array with: y first] ifFalse: [y rank = 1 ifTrue: [y data] ifFalse: [y items]]!
cmpKeys: a with: b
	a class == APLArray ifTrue: [^self cmpArrays: a with: b].
	^self cmp: a with: b!
grade: y up: up
	| keys idx sorted |
	keys := self keysOf: y.
	idx := (1 to: keys size) asArray.
	sorted := idx asSortedCollection: [:i :j | | c |
		c := self cmpKeys: (keys at: i) with: (keys at: j).
		up ifTrue: [c < 0 or: [c = 0 and: [i <= j]]] ifFalse: [c > 0 or: [c = 0 and: [i <= j]]]].
	^APLArray vector: (sorted asArray collect: [:i | i - 1])!
gradeUp: y
	^self grade: y up: true!
gradeDown: y
	^self grade: y up: false!
sortBy: x with: y
	| p |
	x tally = y tally ifFalse: [^APLError length].
	p := self grade: x up: true.
	^self selectItems: p data from: y!
sortDownBy: x with: y
	| p |
	x tally = y tally ifFalse: [^APLError length].
	p := self grade: x up: false.
	^self selectItems: p data from: y!
matchD: x with: y
	^APLArray scalar: ((x match: y) ifTrue: [1] ifFalse: [0])!
less: x with: y
	| m keep |
	m := self member: x with: y.
	keep := OrderedCollection new.
	m data doWithIndex: [:f :i | f = 0 ifTrue: [keep add: i - 1]].
	^self selectItems: keep asArray from: x! !

!APLPrims class methodsFor: 'integers and dealing'!
integers: y
	| shp neg total base res lists |
	y isAtom ifTrue: [
		| n |
		n := y first.
		n isInteger ifFalse: [^APLError domain].
		^n >= 0
			ifTrue: [APLArray integers: n]
			ifFalse: [APLArray vector: ((n negated - 1 to: 0 by: -1) asArray)]].
	shp := y integers.
	neg := shp collect: [:e | e < 0].
	shp := shp collect: [:e | e abs].
	total := APLArray product: shp.
	base := APLArray shape: shp data: (0 to: total - 1) asArray.
	(neg anySatisfy: [:e | e]) ifFalse: [^base].
	lists := Array new: shp size.
	1 to: shp size do: [:a | | l |
		l := (0 to: (shp at: a) - 1) asArray.
		(neg at: a) ifTrue: [l := l reverse].
		lists at: a put: l].
	^base gatherAxes: lists fill: 0!
deal: x with: y
	| k n pool out j t |
	k := x asInteger. n := y asInteger.
	(k < 0 or: [k > n]) ifTrue: [^APLError domain].
	pool := (0 to: n - 1) asArray.
	out := Array new: k.
	1 to: k do: [:i |
		j := i + (self random next * (n - i + 1)) truncated.
		t := pool at: i. pool at: i put: (pool at: j). pool at: j put: t.
		out at: i put: (pool at: i)].
	^APLArray vector: out! !

!APLPrims class methodsFor: 'text'!
format: y
	| ls w data rows |
	ls := APLFormat render: y precision: APL current precision.
	ls size = 1 ifTrue: [^APLArray text: ls first].
	w := ls inject: 0 into: [:m :l | m max: l size].
	rows := ls size.
	data := OrderedCollection new.
	ls do: [:l | data addAll: l asArray. data addAll: (Array new: w - l size withAll: $ )].
	^(APLArray shape: (Array with: rows with: w) data: data asArray) proto: $ !
specOf: s
	"width and decimals from a format number such as 8.2 (decimals nil when there are none)"
	| t dot |
	s isInteger ifTrue: [^Array with: s with: nil].
	t := s abs printString.
	dot := t indexOf: $..
	dot = 0 ifTrue: [^Array with: s truncated with: nil].
	^Array with: (s < 0 ifTrue: [(t copyFrom: 1 to: dot - 1) asInteger negated] ifFalse: [(t copyFrom: 1 to: dot - 1) asInteger])
		with: (t copyFrom: dot + 1 to: t size) asInteger!
fixed: n decimals: d
	| scaled s out neg |
	n isNumber ifFalse: [^APLError domain].
	scaled := (n abs * (10 raisedTo: d)) rounded.
	neg := n < 0 and: [scaled > 0].
	s := scaled printString.
	[s size <= d] whileTrue: [s := '0', s].
	out := d > 0 ifTrue: [(s copyFrom: 1 to: s size - d), '.', (s copyFrom: s size - d + 1 to: s size)] ifFalse: [s].
	^neg ifTrue: ['_', out] ifFalse: [out]!
formatItem: item spec: spec
	| w d t |
	w := spec at: 1. d := spec at: 2.
	t := d isNil
		ifTrue: [APLFormat item: item precision: APL current precision]
		ifFalse: [self fixed: item decimals: d].
	w = 0 ifTrue: [^t].
	t size > w abs ifTrue: [^String new: w abs withAll: $*].
	^w > 0 ifTrue: [(String new: w - t size withAll: $ ), t] ifFalse: [t, (String new: w negated - t size withAll: $ )]!
formatWith: x with: y
	| specs cols rows lines ws cs |
	specs := x data collect: [:s | self specOf: s].
	specs isEmpty ifTrue: [^APLError length].
	cols := y isAtom ifTrue: [1] ifFalse: [y shape last].
	rows := cols = 0 ifTrue: [0] ifFalse: [y size // cols].
	lines := OrderedCollection new.
	0 to: rows - 1 do: [:r |
		ws := WriteStream on: String new.
		1 to: cols do: [:c |
			ws nextPutAll: (self formatItem: (y data at: r * cols + c) spec: (specs at: (c - 1) \\ specs size + 1))].
		lines add: ws contents].
	lines isEmpty ifTrue: [^APLArray emptyText].
	(y rank <= 1) ifTrue: [^APLArray text: lines first].
	cs := lines first size.
	ws := OrderedCollection new.
	lines do: [:l | ws addAll: l asArray].
	^(APLArray shape: (y shape copyFrom: 1 to: y rank - 1), (Array with: cs) data: ws asArray) proto: $ !
execute: y
	| v |
	y isText ifFalse: [^APLError domain].
	v := APL current valueOf: (y isAtom ifTrue: [String with: y first] ifFalse: [y text]).
	^v isNil ifTrue: [APLArray empty] ifFalse: [v]!
words: y
	| out cur ws |
	y isText ifFalse: [^APLError domain].
	out := OrderedCollection new.
	ws := WriteStream on: String new.
	y data do: [:c |
		c isSeparator
			ifTrue: [ws contents isEmpty ifFalse: [out add: (APLBox on: (APLArray text: ws contents)). ws := WriteStream on: String new]]
			ifFalse: [ws nextPut: c]].
	ws contents isEmpty ifFalse: [out add: (APLBox on: (APLArray text: ws contents))].
	^APLArray vector: out!
smalltalk: y
	| text r |
	y isText ifFalse: [^APLError domain].
	text := y isAtom ifTrue: [String with: y first] ifFalse: [y text].
	r := Smalltalk evaluate: text.
	^APLArray fromSmalltalk: r!
smalltalk: x with: y
	| text r |
	y isText ifFalse: [^APLError domain].
	text := y isAtom ifTrue: [String with: y first] ifFalse: [y text].
	Smalltalk at: #APLArgument put: x asSmalltalk.
	r := Smalltalk evaluate: '[:x | ', text, '] value: APLArgument'.
	^APLArray fromSmalltalk: r! !

!APLPrims class methodsFor: 'primes'!
nthPrime: a
	"the prime of that index, counting from 0"
	| n k c |
	(a isInteger and: [a >= 0]) ifFalse: [^APLError domain].
	n := 1. c := -1.
	[c < a] whileTrue: [
		n := n + 1.
		n isPrime ifTrue: [c := c + 1]].
	^n!
primeTest: x with: y
	x = 1 ifFalse: [^APLError domain].
	^self flag: (y isInteger and: [y > 1 and: [y isPrime]])!
factors: y
	"the prime factors of a positive integer, smallest first, as a list"
	| n out p |
	y isAtom ifFalse: [^APLError rank].
	n := y first.
	(n isInteger and: [n > 0]) ifFalse: [^APLError domain].
	out := OrderedCollection new.
	p := 2.
	[n > 1 and: [p * p <= n]] whileTrue: [
		[n \\ p = 0] whileTrue: [out add: p. n := n // p].
		p := p = 2 ifTrue: [3] ifFalse: [p + 2]].
	n > 1 ifTrue: [out add: n].
	^APLArray vector: out! !

!APLPrims class methodsFor: 'matrices'!
toExact: a
	^a isFloat ifTrue: [a] ifFalse: [a]!
matrixRows: m
	"the rows of a table as Arrays of items"
	m rank = 2 ifFalse: [^APLError rank].
	^(1 to: m shape first) asArray collect: [:i | m data copyFrom: (i - 1) * m shape last + 1 to: i * m shape last]!
inverse: m
	"the inverse of a square table by Gauss-Jordan elimination (exact for integers and rationals)"
	| n rows aug piv r t f |
	m rank = 2 ifFalse: [^APLError rank].
	n := m shape first.
	n = m shape last ifFalse: [^APLError length].
	rows := (self matrixRows: m) collect: [:row | row copy].
	aug := (1 to: n) asArray collect: [:i | | e |
		e := Array new: n withAll: 0.
		e at: i put: 1.
		(rows at: i), e].
	1 to: n do: [:c |
		piv := nil.
		c to: n do: [:i | (piv isNil and: [((aug at: i) at: c) ~= 0]) ifTrue: [piv := i]].
		piv isNil ifTrue: [^APLError message: 'domain error'].
		t := aug at: c. aug at: c put: (aug at: piv). aug at: piv put: t.
		f := (aug at: c) at: c.
		aug at: c put: ((aug at: c) collect: [:e | self divideExact: e by: f]).
		1 to: n do: [:i |
			i = c ifFalse: [| g |
				g := (aug at: i) at: c.
				g = 0 ifFalse: [
					r := aug at: c.
					aug at: i put: ((1 to: 2 * n) asArray collect: [:k | ((aug at: i) at: k) - (g * (r at: k))])]]]].
	^APLArray shape: (Array with: n with: n) data: (aug inject: OrderedCollection new into: [:acc :row | acc addAll: (row copyFrom: n + 1 to: 2 * n). acc]) asArray!
divideExact: a by: b
	(a isFloat or: [b isFloat]) ifTrue: [^a / b].
	^a / b!
solve: x with: y
	"x %. y: the solution z of y z = x"
	^self multiply: (self inverse: y) by: x!
multiply: a by: b
	"the matrix product of two arrays (a vector counts as a row or a column)"
	| ar br n k m d |
	a isAtom ifTrue: [^APLArray atomic: [:p :q | p * q] x: a y: b].
	b isAtom ifTrue: [^APLArray atomic: [:p :q | p * q] x: a y: b].
	n := a shape last.
	n = b tally ifFalse: [^APLError length].
	ar := a size // (n max: 1).
	n = 0 ifTrue: [^APLError length].
	m := b itemSize.
	d := Array new: ar * m.
	1 to: ar do: [:i |
		1 to: m do: [:j | | s |
			s := 0.
			1 to: n do: [:l | s := s + ((a data at: (i - 1) * n + l) * (b data at: (l - 1) * m + j))].
			d at: (i - 1) * m + j put: s]].
	^APLArray shape: (a shape copyFrom: 1 to: a rank - 1), b itemShape data: d! !

!APLPrims class methodsFor: 'defining'!
defineStructural
	| inf |
	inf := self infinity.
	self sv: '#' m: #tally: d: #copy:with: ranks: (Array with: inf with: 1 with: inf).
	self sv: '$' m: #shape: d: #reshape:with: ranks: (Array with: inf with: 1 with: inf).
	self sv: ',' m: #ravel: d: #append:with: ranks: (Array with: inf with: inf with: inf).
	self sv: ',.' m: #ravelItems: d: #stitch:with: ranks: (Array with: inf with: inf with: inf).
	self sv: ',:' m: #itemize: d: #laminate:with: ranks: (Array with: inf with: inf with: inf).
	self sv: ';' m: #raze: d: #link:with: ranks: (Array with: inf with: inf with: inf).
	self sv: '[' m: #same: d: #left:with: ranks: (Array with: inf with: inf with: inf).
	self sv: ']' m: #same: d: #right:with: ranks: (Array with: inf with: inf with: inf).
	self sv: '{.' m: #head: d: #take:with: ranks: (Array with: inf with: 1 with: inf).
	self sv: '{:' m: #tail: d: nil ranks: (Array with: inf with: inf with: inf).
	self sv: '}.' m: #behead: d: #drop:with: ranks: (Array with: inf with: 1 with: inf).
	self sv: '}:' m: #curtail: d: nil ranks: (Array with: inf with: inf with: inf).
	self sv: '{' m: nil d: #from:with: ranks: (Array with: inf with: 0 with: inf).
	self sv: '|.' m: #reverse: d: #rotate:with: ranks: (Array with: inf with: 1 with: inf).
	self sv: '|:' m: #transpose: d: #transpose:with: ranks: (Array with: inf with: 1 with: inf).
	self sv: '#.' m: #base2: d: #base:with: ranks: (Array with: 1 with: 1 with: 1).
	self sv: '#:' m: #antibase2: d: #antibase:with: ranks: (Array with: inf with: inf with: inf).
	self sv: '%.' m: #inverse: d: #solve:with: ranks: (Array with: 2 with: 2 with: 2)!
defineSearching
	| inf |
	inf := self infinity.
	self sv: 'i.' m: #integers: d: #indexOf:with: ranks: (Array with: 1 with: inf with: inf).
	self sv: 'e.' m: nil d: #member:with: ranks: (Array with: inf with: inf with: inf).
	self sv: 'I.' m: #indices: d: #interval:with: ranks: (Array with: 1 with: inf with: inf).
	self sv: '~.' m: #nub: d: nil ranks: (Array with: inf with: inf with: inf).
	self sv: '/:' m: #gradeUp: d: #sortBy:with: ranks: (Array with: inf with: inf with: inf).
	self sv: '\:' m: #gradeDown: d: #sortDownBy:with: ranks: (Array with: inf with: inf with: inf).
	self sv: '".' m: #execute: d: nil ranks: (Array with: 1 with: inf with: inf).
	self sv: '":' m: #format: d: #formatWith:with: ranks: (Array with: inf with: inf with: inf).
	self sv: ';:' m: #words: d: nil ranks: (Array with: 1 with: inf with: inf).
	self sv: '?' m: nil d: #deal:with: ranks: (Array with: 0 with: 0 with: 0).
	(Table at: '?') atomicMonad: [:a | self roll: a] dyad: nil!
defineOthers
	| me st |
	self av: 'p:' m: [:a | self nthPrime: a] d: [:a :b | self primeTest: a with: b].
	(self sv: 'q:' m: #factors: d: nil ranks: (Array with: 0 with: 0 with: 0)).
	Table at: 'name:each' put: (APLAdverb name: 'each' block: [:u | self under: u with: (Table at: '>')]).
	(self sv: '-:' m: nil d: #matchD:with: ranks: (Array with: 0 with: self infinity with: self infinity))
		atomicMonad: [:a | self divide: a by: 2] dyad: nil.
	Table at: '[:' put: (APLVerb name: '[:' monad: nil dyad: nil ranks: (Array with: self infinity with: self infinity with: self infinity)).
	Table at: '$:' put: (APLVerb derived: '$:'
		monad: [:y | APL current selfVerb monad: y]
		dyad: [:x :y | APL current selfVerb dyad: x y: y]).
	Table at: 'a.' put: (APLArray text: ((0 to: 255) asArray inject: '' into: [:s :i | s, (String with: (Character value: i))])).
	Table at: 'a:' put: (APLArray box: APLArray empty).
	(Table at: ',') identity: APLArray empty.
	st := self sv: 'name:st' m: #smalltalk: d: #smalltalk:with: ranks: (Array with: self infinity with: self infinity with: self infinity).
	st display: 'st'! !
