"Bootstrapping: how much of the tree the data actually supports.

Draw as many columns as the alignment has, with replacement, build a tree from each draw, and count how often
each branch of the first tree turns up again. The count, as a percentage, is written onto the branch as its
support, and a majority-rule consensus of the replicates can be asked for as well.

The sampling uses a Random the Bootstrap holds, seeded at 42 unless you say otherwise, so that the same
alignment gives the same answer twice - which a test needs, and which anybody comparing two runs wants."

Object subclass: #Bootstrap instanceVariableNames: 'alignment replicates model builder random reference counts' classVariableNames: '' category: 'Phylo-Support'!

!Bootstrap class methodsFor: 'instance creation'!
new
	^self basicNew setUp!
on: anAlignment
	^self on: anAlignment replicates: 100!
on: anAlignment replicates: aCount
	^self new alignment: anAlignment; replicates: aCount; run!
of: anAlignment replicates: aCount model: aModel
	^self new alignment: anAlignment; replicates: aCount; model: aModel; run! !

!Bootstrap methodsFor: 'private'!
setUp
	replicates := 100.
	builder := #nj.
	random := Random seed: 42! !

!Bootstrap methodsFor: 'options'!
alignment
	^alignment!
alignment: anAlignment
	alignment := anAlignment!
replicates
	^replicates!
replicates: aCount
	replicates := aCount!
model
	^model ifNil: [model := alignment isProtein ifTrue: [PoissonModel new] ifFalse: [JukesCantorModel new]]!
model: aModel
	model := aModel isString ifTrue: [DistanceModel named: aModel] ifFalse: [aModel]!
builder: aSymbol
	"#nj or #upgma"
	builder := aSymbol!
seed: anInteger
	random := Random seed: anInteger!
random: aRandom
	random := aRandom! !

!Bootstrap methodsFor: 'running'!
run
	"build the tree from the real data, then from each replicate, and count the branches that agree"
	| replicate |
	alignment isNil ifTrue: [^PhyloError new signal: 'there is no alignment to bootstrap'].
	reference := self treeFor: alignment.
	counts := Dictionary new.
	replicates timesRepeat: [
		replicate := self treeFor: (alignment resampleColumnsWith: random).
		replicate splits do: [:split | counts at: split put: (counts at: split ifAbsent: [0]) + 1]].
	self annotate: reference.
	^self!
treeFor: anAlignment
	| d |
	d := DistanceMatrix fromAlignment: anAlignment model: self model.
	^builder == #upgma ifTrue: [d upgma] ifFalse: [d neighbourJoining]!
annotate: aTree
	"write the support onto every internal branch of the tree"
	| all reference2 |
	all := aTree taxa.
	reference2 := all isEmpty ifTrue: [nil] ifFalse: [all first].
	aTree root internalDo: [:node |
		node isRoot ifFalse: [
			| clade |
			clade := (node leafLabels asSortedCollection: [:a :b | a <= b]) asArray.
			(clade size between: 2 and: all size - 2) ifTrue: [
				(clade includes: reference2) ifTrue: [clade := (all reject: [:t | clade includes: t]) asArray].
				node support: (self percentFor: clade)]]].
	^aTree! !

!Bootstrap methodsFor: 'results'!
tree
	"the tree from the real data, with the support written onto its branches"
	^reference!
counts
	"how many replicates held each split"
	^counts ifNil: [Dictionary new]!
countFor: aSplit
	^self counts at: aSplit ifAbsent: [0]!
percentFor: aSplit
	replicates = 0 ifTrue: [^0].
	^((self countFor: aSplit) * 100.0 / replicates) rounded!
supportFor: someTaxa
	"how much of the data puts just these taxa together"
	| all clade |
	all := reference taxa.
	clade := (someTaxa asOrderedCollection collect: [:each | each asString]) asSortedCollection asArray.
	(clade includes: all first) ifTrue: [clade := (all reject: [:t | clade includes: t]) asArray].
	^self percentFor: clade!
splitsAbove: aPercent
	"the splits at least this well supported, best first"
	| wanted |
	wanted := (self counts keys select: [:each | (self percentFor: each) >= aPercent]) asOrderedCollection.
	^(wanted asSortedCollection: [:a :b | (self countFor: a) >= (self countFor: b)]) asArray! !

!Bootstrap methodsFor: 'consensus'!
consensus
	^self consensusAt: 50!
consensusAt: aPercent
	"the majority-rule consensus: a star tree with every well-enough supported branch added back, taking
	them best first and skipping any that will not fit with the ones already in"
	| all tree wanted |
	all := reference taxa.
	tree := PhyloTree star: all.
	wanted := self splitsAbove: aPercent.
	wanted do: [:split | self add: split to: tree].
	^tree!
add: aSplit to: aTree
	"group the leaves of the split under a node of their own, if they all hang off the same node"
	| chosen node |
	chosen := (aTree root children select: [:child |
		child leafLabels allSatisfy: [:each | aSplit includes: each]]) asOrderedCollection.
	"every taxon of the split must be accounted for, more than one child must move, and something
	must be left behind, or the split says nothing new"
	(chosen inject: 0 into: [:a :child | a + child leafCount]) = aSplit size ifFalse: [^aTree].
	chosen size < 2 ifTrue: [^aTree].
	aTree root children size - chosen size < 1 ifTrue: [^aTree].
	node := PhyloNode new.
	node support: (self percentFor: aSplit).
	chosen do: [:child | aTree root remove: child. node add: child].
	aTree root add: node.
	^aTree! !

!Bootstrap methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a Bootstrap('; print: replicates; nextPutAll: ' replicates)'!
report
	| out |
	out := WriteStream on: String new.
	out print: replicates; nextPutAll: ' replicates, '; nextPutAll: self model name; nl; nl.
	out nextPutAll: reference asText; nl.
	out nextPutAll: reference asNewick; nl; nl.
	out nextPutAll: 'the branches, best supported first:'; nl.
	(self splitsAbove: 0) do: [:split |
		out nextPutAll: ((self percentFor: split) printString, '%');
			nextPutAll: '  '; nextPutAll: (self describeSplit: split); nl].
	^out contents!
describeSplit: aSplit
	| out first |
	out := WriteStream on: String new.
	first := true.
	aSplit do: [:each |
		first ifFalse: [out nextPutAll: ', '].
		first := false.
		out nextPutAll: each].
	^out contents! !
