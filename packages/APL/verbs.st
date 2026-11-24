"APLVerb, APLAdverb and APLConj: the functions of the language. A verb has a monadic and a dyadic definition and three
ranks (what it wants for the monad, the left argument and the right argument); applying it to bigger arguments cuts
them into cells of that rank, applies it to each cell (or each pair of cells whose frames agree) and assembles the
results. An atomic verb is given as a block on single items and gets the scalar extension for free. An adverb or a
conjunction is a block that takes its operands (verbs or nouns) and answers a new function."

!APLVerb class methodsFor: 'constants'!
infinity
	^99999! !

!APLVerb class methodsFor: 'instance creation'!
name: aName monad: m dyad: d ranks: ranks
	"m and d are selectors sent to APLPrims, or blocks, or nil; ranks are the monadic, left and right ranks"
	^self basicNew setName: aName monad: m dyad: d ranks: ranks!
atomicName: aName monad: mBlock dyad: dBlock
	^(self basicNew setName: aName monad: nil dyad: nil ranks: #(0 0 0)) atomicMonad: mBlock dyad: dBlock!
derived: aText monad: m dyad: d
	^(self basicNew setName: aText monad: m dyad: d ranks: (Array with: self infinity with: self infinity with: self infinity))
		display: aText;
		yourself! !

!APLVerb methodsFor: 'initializing'!
setName: aName monad: m dyad: d ranks: ranks
	name := aName.
	monad := m.
	dyad := d.
	mr := ranks at: 1.
	lr := ranks at: 2.
	rr := ranks at: 3!
atomicMonad: mBlock dyad: dBlock
	amon := mBlock.
	adyad := dBlock!
name
	^name!
display
	^display isNil ifTrue: [name] ifFalse: [display]!
display: aText
	display := aText!
inverse
	"the inverse verb, or nil (a derived verb keeps a block that builds it when asked)"
	(inverse isNil or: [inverse class == APLVerb]) ifTrue: [^inverse].
	^inverse value!
inverse: aVerb
	inverse := aVerb!
identity
	^identity!
identity: anItem
	identity := anItem!
foldOf
	^foldOf!
foldOf: aVerb
	foldOf := aVerb!
hasMonad
	^monad notNil or: [amon notNil]!
setMonad: m dyad: d
	monad := m.
	dyad := d!
hasDyad
	^dyad notNil or: [adyad notNil]!
isAtomicDyad
	^adyad notNil!
adyad
	^adyad!
ranks
	^Array with: mr with: lr with: rr!
ranksMonad: a left: b right: c
	mr := a. lr := b. rr := c!
withRanks: ranks
	"a verb that runs this one on cells of the given ranks (a copy; this one is not changed)"
	| me v |
	me := self.
	v := APLVerb basicNew setName: name monad: (me hasMonad ifTrue: [[:y | me monad: y]]) dyad: (me hasDyad ifTrue: [[:x :y | me dyad: x y: y]]) ranks: ranks.
	v display: self display.
	^v!
copyWithRanks: ranks
	^self withRanks: ranks! !

!APLVerb methodsFor: 'applying'!
effectiveRank: n for: r
	n < 0 ifTrue: [^(r + n) max: 0].
	^n min: r!
callMonad: y
	monad isSymbol ifTrue: [^APLPrims perform: monad with: y].
	^monad value: y!
callDyad: x y: y
	dyad isSymbol ifTrue: [^APLPrims perform: dyad with: x with: y].
	^dyad value: x value: y!
monad: y
	| r k |
	amon notNil ifTrue: [^y mapAtoms: amon].
	monad isNil ifTrue: [^APLError valence].
	r := y rank.
	k := self effectiveRank: mr for: r.
	k >= r ifTrue: [^self callMonad: y].
	^self assemble: ((y cellsOfRank: k) collect: [:c | self callMonad: c]) frame: (y shape copyFrom: 1 to: r - k)!
dyad: x y: y
	| rx ry kx ky |
	adyad notNil ifTrue: [^APLArray atomic: adyad x: x y: y].
	dyad isNil ifTrue: [^APLError valence].
	rx := x rank. ry := y rank.
	kx := self effectiveRank: lr for: rx.
	ky := self effectiveRank: rr for: ry.
	(kx >= rx and: [ky >= ry]) ifTrue: [^self callDyad: x y: y].
	^self frameDyad: x y: y kx: kx ky: ky!
frameDyad: x y: y kx: kx ky: ky
	| fx fy long short extra n xc yc results xi yi |
	fx := x shape copyFrom: 1 to: x rank - kx.
	fy := y shape copyFrom: 1 to: y rank - ky.
	fx size <= fy size ifTrue: [short := fx. long := fy] ifFalse: [short := fy. long := fx].
	1 to: short size do: [:i | (short at: i) = (long at: i) ifFalse: [^APLError length]].
	extra := APLArray product: (long copyFrom: short size + 1 to: long size).
	n := APLArray product: long.
	xc := x cellsOfRank: kx.
	yc := y cellsOfRank: ky.
	results := Array new: n.
	1 to: n do: [:i |
		fx size = fy size
			ifTrue: [xi := i. yi := i]
			ifFalse: [
				fx size < fy size
					ifTrue: [xi := (i - 1) // extra + 1. yi := i]
					ifFalse: [yi := (i - 1) // extra + 1. xi := i]].
		results at: i put: (self callDyad: (xc at: xi) y: (yc at: yi))].
	^self assemble: results frame: long!
assemble: results frame: frame
	"the cells' results laid out under the frame, padded to a common shape"
	| stacked |
	results isEmpty ifTrue: [^APLArray shape: frame, #(0) data: #()].
	stacked := APLArray stack: results.
	^stacked reshaped: frame, stacked itemShape!
printOn: aStream
	aStream nextPutAll: 'APLVerb '; nextPutAll: self display! !

!APLVerb methodsFor: 'running'!
atTable: aBlock
	^aBlock value: self! !

!APLAdverb class methodsFor: 'instance creation'!
name: aName block: aBlock
	^self basicNew setName: aName block: aBlock! !

!APLAdverb methodsFor: 'applying'!
setName: aName block: aBlock
	name := aName.
	block := aBlock!
name
	^name!
display
	^name!
applyTo: operand
	^block value: operand!
printOn: aStream
	aStream nextPutAll: 'APLAdverb '; nextPutAll: name! !

!APLConj class methodsFor: 'instance creation'!
name: aName block: aBlock
	^self basicNew setName: aName block: aBlock! !

!APLConj methodsFor: 'applying'!
setName: aName block: aBlock
	name := aName.
	block := aBlock!
name
	^name!
display
	^name!
applyTo: u and: v
	^block value: u value: v!
printOn: aStream
	aStream nextPutAll: 'APLConj '; nextPutAll: name! !
