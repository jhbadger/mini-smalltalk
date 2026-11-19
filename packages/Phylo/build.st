"Building a tree from a distance matrix.

Neighbour joining (Saitou and Nei 1987) makes an unrooted tree and does not assume the distances are
clock-like; it is what you want unless you have a reason to want the other. UPGMA clusters the closest pair
over and over and makes a rooted, ultrametric tree, which is right only when the rate of change is the same
everywhere - it is kept because it is quick, it is what a guide tree for progressive alignment wants, and it
is worth being able to compare the two."

Object subclass: #TreeBuilder instanceVariableNames: 'labels d nodes n' classVariableNames: '' category: 'Phylo-Building'!
TreeBuilder subclass: #NeighbourJoining instanceVariableNames: '' classVariableNames: '' category: 'Phylo-Building'!
TreeBuilder subclass: #UPGMA instanceVariableNames: 'weighted sizes heights' classVariableNames: '' category: 'Phylo-Building'!

!TreeBuilder class methodsFor: 'building'!
on: aMatrix
	"the tree this method makes from the matrix"
	^self new build: aMatrix!
new
	^self basicNew setUp! !

!TreeBuilder methodsFor: 'private'!
setUp
	^self!
start: aMatrix
	"work on a copy, since building eats the matrix"
	labels := aMatrix labels copy.
	n := aMatrix size.
	d := (1 to: n) collect: [:i | aMatrix rowAt: i].
	nodes := (1 to: n) collect: [:i | PhyloNode named: (labels at: i)]!
at: i and: j
	^(d at: i) at: j!
at: i and: j put: aNumber
	(d at: i) at: j put: aNumber.
	(d at: j) at: i put: aNumber!
drop: someIndices
	"the indices still in play once these are taken out"
	^(1 to: n) reject: [:i | someIndices includes: i]!
name
	^self subclassResponsibility!
build: aMatrix
	^self subclassResponsibility! !

!TreeBuilder methodsFor: 'building'!
checkSize: aMatrix
	aMatrix size < 2 ifTrue: [^PhyloError new signal: 'a tree needs at least two taxa'].
	^aMatrix!
twoTaxonTree
	| root |
	root := PhyloNode new.
	root add: (nodes at: 1) length: ((self at: 1 and: 2) / 2.0).
	root add: (nodes at: 2) length: ((self at: 1 and: 2) / 2.0).
	^PhyloTree named: self name on: root! !

"---- neighbour joining ----"

!NeighbourJoining methodsFor: 'building'!
name
	^'neighbour joining'!
build: aMatrix
	"Saitou and Nei's method: at each step join the pair that makes the total branch length least, which
	is the pair with the smallest d(i,j) - r(i) - r(j), not simply the closest pair"
	| alive pair i j joined li lj |
	self checkSize: aMatrix.
	self start: aMatrix.
	aMatrix size = 2 ifTrue: [^self twoTaxonTree].
	alive := (1 to: n) asOrderedCollection.
	[alive size > 3] whileTrue: [
		pair := self bestPairAmong: alive.
		i := pair first. j := pair last.
		li := self branchFrom: i to: j among: alive.
		lj := (self at: i and: j) - li.
		"a negative branch means nothing: the usual fix is to flatten it and give the length to its sister"
		li < 0 ifTrue: [lj := ((self at: i and: j) max: 0) asFloat. li := 0.0].
		lj < 0 ifTrue: [li := ((self at: i and: j) max: 0) asFloat. lj := 0.0].
		joined := PhyloNode new.
		joined add: (nodes at: i) length: li asFloat.
		joined add: (nodes at: j) length: lj asFloat.
		self joinDistancesOf: i and: j among: alive.
		nodes at: i put: joined.
		alive remove: j.
		labels at: i put: '(', (labels at: i), ',', (labels at: j), ')'].
	^PhyloTree named: self name on: (self lastThree: alive)!
bestPairAmong: alive
	"the pair with the smallest d(i,j) - r(i) - r(j), where r is the mean distance to everything else"
	| r best pair m sum value |
	m := alive size.
	r := Dictionary new.
	alive do: [:i |
		sum := 0.
		alive do: [:k | k = i ifFalse: [sum := sum + (self at: i and: k)]].
		r at: i put: sum / (m - 2) asFloat].
	best := nil. pair := nil.
	alive do: [:i |
		alive do: [:j |
			i < j ifTrue: [
				value := (self at: i and: j) - (r at: i) - (r at: j).
				(best isNil or: [value < best]) ifTrue: [best := value. pair := Array with: i with: j]]]].
	^pair!
branchFrom: i to: j among: alive
	"the length of the branch from the new node down to i"
	| m sumI sumJ |
	m := alive size.
	sumI := 0. sumJ := 0.
	alive do: [:k |
		k = i ifFalse: [sumI := sumI + (self at: i and: k)].
		k = j ifFalse: [sumJ := sumJ + (self at: j and: k)]].
	^((self at: i and: j) / 2.0) + ((sumI - sumJ) / (2.0 * (m - 2)))!
joinDistancesOf: i and: j among: alive
	"row i becomes the new node: d(new,k) = (d(i,k) + d(j,k) - d(i,j)) / 2"
	| dij |
	dij := self at: i and: j.
	alive do: [:k |
		(k = i or: [k = j]) ifFalse: [
			self at: i and: k put: (((self at: i and: k) + (self at: j and: k) - dij) / 2.0)]]!
lastThree: alive
	"three left: they meet at one node, and each branch comes out of the three distances"
	| a b c root dab dac dbc |
	alive size = 2 ifTrue: [^self lastTwo: alive].
	a := alive at: 1. b := alive at: 2. c := alive at: 3.
	dab := self at: a and: b. dac := self at: a and: c. dbc := self at: b and: c.
	root := PhyloNode new.
	root add: (nodes at: a) length: (((dab + dac - dbc) / 2.0) max: 0.0).
	root add: (nodes at: b) length: (((dab + dbc - dac) / 2.0) max: 0.0).
	root add: (nodes at: c) length: (((dac + dbc - dab) / 2.0) max: 0.0).
	^root!
lastTwo: alive
	| a b root |
	a := alive at: 1. b := alive at: 2.
	root := PhyloNode new.
	root add: (nodes at: a) length: (self at: a and: b) / 2.0.
	root add: (nodes at: b) length: (self at: a and: b) / 2.0.
	^root! !

"---- UPGMA and WPGMA ----"

!UPGMA class methodsFor: 'building'!
weighted: aMatrix
	"WPGMA: the two clusters joined count equally, whatever their size"
	^self new weighted: true; build: aMatrix! !

!UPGMA methodsFor: 'private'!
setUp
	weighted := false! !

!UPGMA methodsFor: 'options'!
weighted
	^weighted!
weighted: aBoolean
	"true for WPGMA, where the two clusters count equally; false for UPGMA, where each taxon does"
	weighted := aBoolean! !

!UPGMA methodsFor: 'building'!
name
	^weighted ifTrue: ['WPGMA'] ifFalse: ['UPGMA']!
build: aMatrix
	| alive pair i j joined height |
	self checkSize: aMatrix.
	self start: aMatrix.
	sizes := (1 to: n) collect: [:k | 1].
	heights := (1 to: n) collect: [:k | 0].
	alive := (1 to: n) asOrderedCollection.
	[alive size > 1] whileTrue: [
		pair := self closestPairAmong: alive.
		i := pair first. j := pair last.
		height := (self at: i and: j) / 2.0.
		joined := PhyloNode new.
		joined add: (nodes at: i) length: ((height - (heights at: i)) max: 0).
		joined add: (nodes at: j) length: ((height - (heights at: j)) max: 0).
		self mergeDistancesOf: i and: j among: alive.
		nodes at: i put: joined.
		sizes at: i put: (sizes at: i) + (sizes at: j).
		heights at: i put: height.
		alive remove: j].
	^PhyloTree named: self name on: (nodes at: alive first)!
closestPairAmong: alive
	| best pair value |
	best := nil. pair := nil.
	alive do: [:i |
		alive do: [:j |
			i < j ifTrue: [
				value := self at: i and: j.
				(best isNil or: [value < best]) ifTrue: [best := value. pair := Array with: i with: j]]]].
	^pair!
mergeDistancesOf: i and: j among: alive
	| wi wj |
	weighted
		ifTrue: [wi := 0.5. wj := 0.5]
		ifFalse: [
			wi := (sizes at: i) / ((sizes at: i) + (sizes at: j)) asFloat.
			wj := 1.0 - wi].
	alive do: [:k |
		(k = i or: [k = j]) ifFalse: [
			self at: i and: k put: (wi * (self at: i and: k)) + (wj * (self at: j and: k))]]! !
