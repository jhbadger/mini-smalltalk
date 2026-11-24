"Adverbs and conjunctions: / insert and table, \ prefix and infix, \. suffix and outfix, /. key and oblique, ~ reflex and
passive, } amend, and the conjunctions rank, @, @:, &, &:, &., ^:, ., :, ;. and the foreign conjunction.  Each is a block that is given
its operand(s) and answers a new verb (or, for : with 0 and 1 and 2, a noun, adverb or conjunction)."

!APLPrims class methodsFor: 'adverbs'!
needVerb: u
	u class == APLVerb ifFalse: [^APLError domain]!
insert: u
	| v |
	self needVerb: u.
	v := APLVerb derived: u display, '/' monad: [:y | self reduce: u over: y] dyad: [:x :y | self table: u x: x y: y].
	v foldOf: u.
	^v!
reduce: u over: y
	| n acc ys ad |
	y isAtom ifTrue: [^y].
	n := y tally.
	n = 0 ifTrue: [
		u identity isNil ifTrue: [^APLError domain].
		^u identity size = 1
			ifTrue: [(APLArray shape: y itemShape data: (Array new: y itemSize withAll: u identity first)) proto: y proto]
			ifFalse: [u identity]].
	n = 1 ifTrue: [^y itemAt: 1].
	(u isAtomicDyad and: [y rank = 1]) ifTrue: [
		ad := u adyad. ys := y data.
		acc := ys at: n.
		n - 1 to: 1 by: -1 do: [:i | acc := ad value: (ys at: i) value: acc].
		^(APLArray scalar: acc) proto: y proto].
	acc := y itemAt: n.
	n - 1 to: 1 by: -1 do: [:i | acc := u dyad: (y itemAt: i) y: acc].
	^acc!
table: u x: x y: y
	| xs ys res ad xd yd |
	(u isAtomicDyad and: [x rank <= 1 and: [y rank <= 1]]) ifTrue: [
		ad := u adyad. xd := x data. yd := y data.
		res := Array new: xd size * yd size.
		1 to: xd size do: [:i | 1 to: yd size do: [:j |
			res at: (i - 1) * yd size + j put: (ad value: (xd at: i) value: (yd at: j))]].
		^APLArray shape: (Array with: xd size with: yd size) data: res].
	^(u withRanks: (Array with: self infinity with: (u ranks at: 2) with: self infinity)) dyad: x y: y!
isAssociative: v
	^#('+' '*' '<.' '>.' '*.' '+.' '~:' '=') includes: v name!
prefix: u
	self needVerb: u.
	^APLVerb derived: u display, '\' monad: [:y | self prefixes: u of: y] dyad: [:x :y | self infix: u x: x y: y]!
prefixes: u of: y
	| n fold ad acc res ys |
	y isAtom ifTrue: [^u monad: y].
	n := y tally.
	n = 0 ifTrue: [^APLArray empty].
	fold := u foldOf.
	(fold notNil and: [fold isAtomicDyad and: [y rank = 1 and: [self isAssociative: fold]]]) ifTrue: [
		ad := fold adyad. ys := y data.
		acc := ys at: 1.
		res := Array new: n.
		res at: 1 put: acc.
		2 to: n do: [:i | acc := ad value: acc value: (ys at: i). res at: i put: acc].
		^APLArray vector: res].
	res := Array new: n.
	1 to: n do: [:k | res at: k put: (u monad: (self selectItems: (0 to: k - 1) asArray from: y))].
	^APLArray stack: res!
infix: u x: x y: y
	| k n res m s |
	k := x asInteger.
	y isAtom ifTrue: [^APLError rank].
	n := y tally.
	k = 0 ifTrue: [^APLError domain].
	res := OrderedCollection new.
	k > 0
		ifTrue: [1 to: n - k + 1 do: [:i | res add: (u monad: (self selectItems: (i - 1 to: i + k - 2) asArray from: y))]]
		ifFalse: [
			m := k negated.
			s := 0.
			[s < n] whileTrue: [
				res add: (u monad: (self selectItems: (s to: (s + m - 1 min: n - 1)) asArray from: y)).
				s := s + m]].
	res isEmpty ifTrue: [^APLArray empty].
	^APLArray stack: res asArray!
suffix: u
	self needVerb: u.
	^APLVerb derived: u display, '\.' monad: [:y | self suffixes: u of: y] dyad: [:x :y | self outfix: u x: x y: y]!
suffixes: u of: y
	| n res |
	y isAtom ifTrue: [^u monad: y].
	n := y tally.
	n = 0 ifTrue: [^APLArray empty].
	res := Array new: n.
	1 to: n do: [:k | res at: k put: (u monad: (self selectItems: (k - 1 to: n - 1) asArray from: y))].
	^APLArray stack: res!
outfix: u x: x y: y
	| k n res |
	k := x asInteger.
	n := y tally.
	res := OrderedCollection new.
	1 to: n - k + 1 do: [:i | | keep |
		keep := ((0 to: n - 1) asArray) reject: [:j | j >= (i - 1) and: [j < (i - 1 + k)]].
		res add: (u monad: (self selectItems: keep from: y))].
	res isEmpty ifTrue: [^APLArray empty].
	^APLArray stack: res asArray!
keyOrOblique: u
	self needVerb: u.
	^APLVerb derived: u display, '/.' monad: [:y | self oblique: u of: y] dyad: [:x :y | self key: u x: x y: y]!
oblique: u of: y
	| r c res |
	y rank = 2 ifFalse: [^APLError rank].
	r := y shape first. c := y shape last.
	res := OrderedCollection new.
	0 to: r + c - 2 do: [:s | | d |
		d := OrderedCollection new.
		(s - c + 1 max: 0) to: (s min: r - 1) do: [:i | d add: (y data at: i * c + (s - i) + 1)].
		res add: (u monad: (APLArray vector: d))].
	^APLArray stack: res asArray!
key: u x: x y: y
	| keys groups order dict key found |
	y isAtom ifTrue: [^APLError rank].
	keys := self keysOf: x.
	keys size = y tally ifFalse: [^APLError length].
	dict := Dictionary new.
	order := OrderedCollection new.
	keys doWithIndex: [:k :i |
		key := k class == APLArray ifTrue: [nil] ifFalse: [self keyOf: k].
		found := nil.
		key isNil
			ifTrue: [order do: [:g | (found isNil and: [(keys at: g first) = k]) ifTrue: [found := g]]]
			ifFalse: [found := dict at: key ifAbsent: [nil]].
		found isNil
			ifTrue: [found := OrderedCollection new. order add: found. key isNil ifFalse: [dict at: key put: found]].
		found add: i].
	groups := order collect: [:g | u monad: (self selectItems: (g collect: [:i | i - 1]) asArray from: y)].
	groups isEmpty ifTrue: [^APLArray empty].
	^APLArray stack: groups asArray!
reflex: u
	self needVerb: u.
	^APLVerb derived: u display, '~' monad: [:y | u dyad: y y: y] dyad: [:x :y | u dyad: y y: x]!
amend: m
	| v |
	^APLVerb derived: m display, '}'
		monad: nil
		dyad: [:x :y | self amend: y at: (m class == APLArray ifTrue: [m] ifFalse: [m monad: y]) with: x]!
amend: y at: idx with: x
	| lists offs d xs isz box |
	y isAtom ifTrue: [^APLError rank].
	(self compatible: x with: y) ifFalse: [^APLError domain].
	lists := Array new: y rank.
	1 to: y rank do: [:a | lists at: a put: (0 to: (y shape at: a) - 1) asArray].
	idx isBoxed
		ifTrue: [
			box := idx isAtom ifTrue: [idx first contents] ifFalse: [idx].
			1 to: box size do: [:a | | b |
				b := (box data at: a) contents.
				b size > 0 ifTrue: [lists at: a put: (self indexList: b count: (y shape at: a))]]]
		ifFalse: [lists at: 1 put: (self indexList: idx count: y tally)].
	offs := ((APLArray shape: y shape data: (1 to: y size) asArray) gatherAxes: lists fill: 0) data.
	d := y data copy.
	xs := x data.
	isz := y itemSize.
	xs size = 1
		ifTrue: [offs do: [:o | d at: o put: xs first]]
		ifFalse: [
			xs size = offs size
				ifTrue: [offs doWithIndex: [:o :i | d at: o put: (xs at: i)]]
				ifFalse: [
					(xs size = isz and: [offs size \\ isz = 0])
						ifTrue: [offs doWithIndex: [:o :i | d at: o put: (xs at: (i - 1) \\ isz + 1)]]
						ifFalse: [^APLError length]]].
	^(APLArray shape: y shape data: d) proto: y proto! !

!APLPrims class methodsFor: 'conjunctions'!
rankValue: e
	(e isFloat and: [e = Float infinity]) ifTrue: [^self infinity].
	e isInteger ifTrue: [^e].
	(e isFloat and: [e = e truncated]) ifTrue: [^e truncated].
	^APLError domain!
rank: u with: n
	| rs |
	self needVerb: u.
	n class == APLArray ifFalse: [^APLError domain].
	rs := n data collect: [:e | self rankValue: e].
	rs size = 1 ifTrue: [^u withRanks: (Array with: rs first with: rs first with: rs first)].
	rs size = 2 ifTrue: [^u withRanks: (Array with: (rs at: 2) with: (rs at: 1) with: (rs at: 2))].
	rs size = 3 ifTrue: [^u withRanks: rs].
	^APLError length!
compose: u with: v keepRanks: keep
	"u@v and u@:v: u applied to the result of v"
	| r rk |
	self needVerb: u. self needVerb: v.
	r := APLVerb derived: u display, '@', (keep ifTrue: [''] ifFalse: [':']), v display
		monad: [:y | u monad: (v monad: y)]
		dyad: [:x :y | u monad: (v dyad: x y: y)].
	keep ifTrue: [rk := v ranks. r ranksMonad: (rk at: 1) left: (rk at: 2) right: (rk at: 3)].
	r inverse: [(u inverse notNil and: [v inverse notNil]) ifTrue: [self compose: v inverse with: u inverse keepRanks: keep] ifFalse: [nil]].
	^r!
bond: u with: v keepRanks: keep
	"u&v: u applied to v of each argument; u&n and n&v fix one argument"
	| r rk m |
	(u class == APLVerb and: [v class == APLVerb]) ifTrue: [
		r := APLVerb derived: u display, '&', (keep ifTrue: [''] ifFalse: [':']), v display
			monad: [:y | u monad: (v monad: y)]
			dyad: [:x :y | u dyad: (v monad: x) y: (v monad: y)].
		keep ifTrue: [rk := v ranks at: 1. r ranksMonad: rk left: rk right: rk].
		r inverse: [(u inverse notNil and: [v inverse notNil]) ifTrue: [self bond: v inverse with: u inverse keepRanks: keep] ifFalse: [nil]].
		^r].
	(u class == APLVerb and: [v class == APLArray]) ifTrue: [
		r := APLVerb derived: u display, '&', (APLFormat text: v precision: 6)
			monad: [:y | u dyad: y y: v]
			dyad: nil.
		r inverse: [self bondInverse: u operand: v right: true].
		^r].
	(u class == APLArray and: [v class == APLVerb]) ifTrue: [
		r := APLVerb derived: (APLFormat text: u precision: 6), '&', v display
			monad: [:y | v dyad: u y: y]
			dyad: nil.
		r inverse: [self bondInverse: v operand: u right: false].
		^r].
	^APLError domain!
bondInverse: u operand: n right: isRight
	"the inverse of  y u n  (or  n u y) for the verbs that have one"
	| nm |
	nm := u name.
	nm = '+' ifTrue: [^self bond: (Table at: '-') with: n keepRanks: true].
	nm = '*' ifTrue: [^self bond: (Table at: '%') with: n keepRanks: true].
	isRight
		ifTrue: [
			nm = '-' ifTrue: [^self bond: (Table at: '+') with: n keepRanks: true].
			nm = '%' ifTrue: [^self bond: (Table at: '*') with: n keepRanks: true].
			nm = '^' ifTrue: [^self bond: n with: (Table at: '%:') keepRanks: true]]
		ifFalse: [
			nm = '-' ifTrue: [^self bond: n with: (Table at: '-') keepRanks: true].
			nm = '%' ifTrue: [^self bond: n with: (Table at: '%') keepRanks: true].
			nm = '^' ifTrue: [^self bond: n with: (Table at: '^.') keepRanks: true]].
	^nil!
under: u with: v
	| r rk |
	self needVerb: u. self needVerb: v.
	r := APLVerb derived: u display, '&.', v display
		monad: [:y | self inverseOf: v monad: (u monad: (v monad: y))]
		dyad: [:x :y | self inverseOf: v monad: (u dyad: (v monad: x) y: (v monad: y))].
	rk := v ranks.
	r ranksMonad: (rk at: 1) left: (rk at: 1) right: (rk at: 1).
	^r!
inverseOf: v monad: y
	| i |
	i := v inverse.
	i isNil ifTrue: [^APLError message: 'domain error: no inverse'].
	^i monad: y!
power: u with: n
	self needVerb: u.
	n class == APLArray ifFalse: [^APLError domain].
	^APLVerb derived: u display, '^:', (APLFormat text: n precision: 6)
		monad: [:y | self iterate: u count: n on: y with: nil]
		dyad: [:x :y | self iterate: u count: n on: y with: x]!
iterate: u count: n on: y with: x
	| k acc step prev inv guard res |
	n isAtom ifFalse: [
		res := n data collect: [:e | self iterate: u count: (APLArray scalar: e) on: y with: x].
		^APLArray stack: res].
	k := n first.
	(k isFloat and: [k = Float infinity]) ifTrue: [
		acc := y. guard := 0.
		[prev := acc.
		acc := x isNil ifTrue: [u monad: acc] ifFalse: [u dyad: x y: acc].
		guard := guard + 1.
		(acc match: prev) or: [guard > 100000]] whileFalse.
		^acc].
	(k isFloat and: [k = k truncated]) ifTrue: [k := k truncated].
	k isInteger ifFalse: [^APLError domain].
	acc := y.
	k >= 0
		ifTrue: [k timesRepeat: [acc := x isNil ifTrue: [u monad: acc] ifFalse: [u dyad: x y: acc]]]
		ifFalse: [
			inv := u inverse.
			inv isNil ifTrue: [^APLError message: 'domain error: no inverse'].
			k negated timesRepeat: [acc := inv monad: acc]].
	^acc!
inner: u with: v
	self needVerb: u. self needVerb: v.
	^APLVerb derived: u display, ' . ', v display
		monad: [:y | self determinant: y u: u v: v]
		dyad: [:x :y | self innerProduct: x y: y u: u v: v]!
innerProduct: x y: y u: u v: v
	| xr yc yy res n frame shp stacked |
	(x isAtom or: [y isAtom]) ifTrue: [^u monad: (v dyad: x y: y)].
	n := x shape last.
	n = y tally ifFalse: [^APLError length].
	(u foldOf notNil and: [u foldOf name = '+' and: [v name = '*' and: [x rank <= 2 and: [y rank <= 2]]]]) ifTrue: [^self multiply: x by: y].
	xr := x cellsOfRank: 1.
	yy := y rank = 1 ifTrue: [y] ifFalse: [self permute: y by: ((2 to: y rank) asArray, (Array with: 1))].
	yc := y rank = 1 ifTrue: [Array with: y] ifFalse: [yy cellsOfRank: 1].
	res := OrderedCollection new.
	xr do: [:a | yc do: [:b | res add: (u monad: (v dyad: a y: b))]].
	shp := (x shape copyFrom: 1 to: x rank - 1), (y shape copyFrom: 2 to: y rank).
	res isEmpty ifTrue: [^APLArray shape: shp data: #()].
	stacked := APLArray stack: res asArray.
	^stacked reshaped: shp, stacked itemShape!
determinant: y u: u v: v
	| n terms |
	y rank = 2 ifFalse: [^APLError rank].
	n := y shape first.
	n = y shape last ifFalse: [^APLError length].
	n = 0 ifTrue: [^APLArray scalar: 1].
	n = 1 ifTrue: [^APLArray scalar: y data first].
	terms := (1 to: n) asArray collect: [:j | | minor lists |
		lists := Array with: (1 to: n - 1) asArray with: (((0 to: n - 1) asArray) reject: [:c | c = (j - 1)]).
		minor := y gatherAxes: lists fill: 0.
		(v dyad: (APLArray scalar: (y data at: j)) y: (self determinant: minor u: u v: v)) first].
	^u monad: (APLArray vector: terms)!
colon: x with: y
	"3 : 'text' (and 0 1 2 4); two verbs make a verb with a monadic and a dyadic case; two texts likewise"
	| k |
	(x class == APLArray and: [y class == APLArray]) ifTrue: [
		(x isText and: [y isText]) ifTrue: [
			^APL current defineVerb: (x isAtom ifTrue: [String with: x first] ifFalse: [x text])
				dyad: (y isAtom ifTrue: [String with: y first] ifFalse: [y text])
				display: 'm : n' bindings: Dictionary new].
		k := x asInteger.
		y isText ifFalse: [^APLError domain].
		^APL current defineKind: k text: (y isAtom ifTrue: [String with: y first] ifFalse: [y text])].
	(x class == APLVerb and: [y class == APLVerb]) ifTrue: [
		^APLVerb derived: x display, ' : ', y display
			monad: [:a | x monad: a]
			dyad: [:a :b | y dyad: a y: b]].
	^APLError domain!
cut: u with: n
	self needVerb: u.
	n class == APLArray ifFalse: [^APLError domain].
	^APLVerb derived: u display, ';.', (APLFormat text: n precision: 6)
		monad: [:y | self cut: u by: nil mode: n asInteger on: y]
		dyad: [:x :y | self cut: u by: x mode: n asInteger on: y]!
cut: u by: marks mode: mode on: y
	| n flags starts res pieces |
	y isAtom ifTrue: [^APLError rank].
	n := y tally.
	flags := Array new: n withAll: false.
	marks isNil
		ifTrue: [
			n = 0 ifTrue: [^APLArray empty].
			1 to: n do: [:i | flags at: i put: ((y itemAt: i) match: (y itemAt: (mode abs = 1 ifTrue: [1] ifFalse: [n])))]]
		ifFalse: [
			marks tally = n ifFalse: [^APLError length].
			marks data doWithIndex: [:f :i | flags at: i put: f ~= 0]].
	mode = 0 ifTrue: [^APLError domain].
	pieces := OrderedCollection new.
	(mode abs = 1)
		ifTrue: [
			| begin |
			begin := nil.
			1 to: n + 1 do: [:i |
				(i > n or: [flags at: i]) ifTrue: [
					begin isNil ifFalse: [
						pieces add: (self selectItems: ((mode < 0 ifTrue: [begin + 1] ifFalse: [begin]) - 1 to: i - 2) asArray from: y)].
					begin := i]]]
		ifFalse: [
			| begin |
			begin := 1.
			1 to: n do: [:i |
				(flags at: i) ifTrue: [
					pieces add: (self selectItems: (begin - 1 to: (mode < 0 ifTrue: [i - 2] ifFalse: [i - 1])) asArray from: y).
					begin := i + 1]]].
	res := pieces collect: [:p | u monad: p].
	res isEmpty ifTrue: [^APLArray empty].
	^APLArray stack: res asArray!
foreign: x with: y
	"the few foreign functions: 9 and 10 read, 9 and 11 set, the printing precision"
	| a b |
	(x class == APLArray and: [y class == APLArray]) ifFalse: [^APLError domain].
	a := x asInteger. b := y asInteger.
	(a = 9 and: [b = 10]) ifTrue: [
		^APLVerb derived: '9!!:10' monad: [:v | APLArray scalar: APL current precision] dyad: nil].
	(a = 9 and: [b = 11]) ifTrue: [
		^APLVerb derived: '9!!:11' monad: [:v | | old |
			old := APL current precision.
			APL current precision: v asInteger.
			APLArray scalar: old] dyad: nil].
	^APLError nonce! !

!APLPrims class methodsFor: 'defining'!
adverb: spelling block: aBlock
	Table at: spelling put: (APLAdverb name: spelling block: aBlock)!
conj: spelling block: aBlock
	Table at: spelling put: (APLConj name: spelling block: aBlock)!
defineAdverbs
	self adverb: '/' block: [:u | self insert: u].
	self adverb: '\' block: [:u | self prefix: u].
	self adverb: '\.' block: [:u | self suffix: u].
	self adverb: '/.' block: [:u | self keyOrOblique: u].
	self adverb: '~' block: [:u | self reflex: u].
	self adverb: '}' block: [:u | self amend: u]!
defineConjunctions
	self conj: '"' block: [:u :n | self rank: u with: n].
	self conj: '@' block: [:u :v | self compose: u with: v keepRanks: true].
	self conj: '@:' block: [:u :v | self compose: u with: v keepRanks: false].
	self conj: '&' block: [:u :v | self bond: u with: v keepRanks: true].
	self conj: '&:' block: [:u :v | self bond: u with: v keepRanks: false].
	self conj: '&.' block: [:u :v | self under: u with: v].
	self conj: '^:' block: [:u :n | self power: u with: n].
	self conj: '.' block: [:u :v | self inner: u with: v].
	self conj: ':' block: [:x :y | self colon: x with: y].
	self conj: ';.' block: [:u :n | self cut: u with: n].
	self conj: '!!:' block: [:x :y | self foreign: x with: y]! !
