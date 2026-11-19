"The tree itself: a PhyloNode knows its label, its branch length, its support and its children, and a PhyloTree
is a root node with the whole-tree operations hung off it - walking, measuring, re-rooting, pruning, comparing
topologies, and writing Newick.

A node with no children is a leaf and its label is a taxon name. An internal node usually has no label; what a
Newick file writes where an internal label would go is normally a support value, and is read into support."

Object subclass: #PhyloNode instanceVariableNames: 'label branchLength support children parent' classVariableNames: '' category: 'Phylo-Trees'!
Object subclass: #PhyloTree instanceVariableNames: 'root name' classVariableNames: '' category: 'Phylo-Trees'!
Error subclass: #PhyloError instanceVariableNames: '' classVariableNames: '' category: 'Phylo'!

"---- nodes ----"

!PhyloNode class methodsFor: 'instance creation'!
new
	^self basicNew setLabel: nil!
named: aString
	"a leaf"
	^self basicNew setLabel: aString!
leaf: aString
	^self named: aString!
leaf: aString length: aNumber
	^(self named: aString) branchLength: aNumber; yourself!
withChildren: aCollection
	| node |
	node := self new.
	aCollection do: [:each | node add: each].
	^node!
with: aNode and: anotherNode
	^self withChildren: (Array with: aNode with: anotherNode)! !

!PhyloNode methodsFor: 'private'!
setLabel: aString
	label := aString.
	children := OrderedCollection new!
parent: aNode
	parent := aNode! !

!PhyloNode methodsFor: 'accessing'!
label
	^label!
label: aString
	label := aString!
branchLength
	"the length of the branch to the parent, or nil when the tree carries no lengths"
	^branchLength!
branchLength: aNumber
	branchLength := aNumber!
lengthOr: aDefault
	^branchLength ifNil: [aDefault]!
support
	"the support for the clade under this node, usually a bootstrap percentage"
	^support!
support: aNumber
	support := aNumber!
children
	^children!
parent
	^parent!
name
	"the label if there is one, otherwise something to call the node by"
	label notNil ifTrue: [^label].
	self isLeaf ifTrue: [^'(unnamed leaf)'].
	^'(', self leafCount printString, ' taxa)'! !

!PhyloNode methodsFor: 'testing'!
isLeaf
	^children isEmpty!
isInternal
	^children notEmpty!
isRoot
	^parent isNil!
hasBranchLength
	^branchLength notNil!
hasSupport
	^support notNil! !

!PhyloNode methodsFor: 'building'!
add: aNode
	aNode parent: self.
	children add: aNode.
	^aNode!
addAll: aCollection
	aCollection do: [:each | self add: each].
	^aCollection!
add: aNode length: aNumber
	aNode branchLength: aNumber.
	^self add: aNode!
remove: aNode
	children remove: aNode ifAbsent: [^nil].
	aNode parent: nil.
	^aNode!
detach
	"take this node out of its parent"
	parent ifNotNil: [:p | p remove: self].
	^self!
replaceChild: aNode with: anotherNode
	| i |
	i := children indexOf: aNode ifAbsent: [^nil].
	children at: i put: anotherNode.
	anotherNode parent: self.
	aNode parent: nil.
	^anotherNode! !

!PhyloNode methodsFor: 'walking'!
preOrderDo: aBlock
	"this node, then everything under it"
	aBlock value: self.
	children do: [:each | each preOrderDo: aBlock]!
postOrderDo: aBlock
	"everything under this node, then the node"
	children do: [:each | each postOrderDo: aBlock].
	aBlock value: self!
do: aBlock
	^self preOrderDo: aBlock!
leavesDo: aBlock
	self isLeaf ifTrue: [^aBlock value: self].
	children do: [:each | each leavesDo: aBlock]!
internalDo: aBlock
	self isInternal ifTrue: [
		aBlock value: self.
		children do: [:each | each internalDo: aBlock]]!
ancestorsDo: aBlock
	| c |
	c := parent.
	[c notNil] whileTrue: [aBlock value: c. c := c parent]! !

!PhyloNode methodsFor: 'enumerating'!
nodes
	| out |
	out := OrderedCollection new.
	self preOrderDo: [:each | out add: each].
	^out!
leaves
	| out |
	out := OrderedCollection new.
	self leavesDo: [:each | out add: each].
	^out!
internalNodes
	| out |
	out := OrderedCollection new.
	self internalDo: [:each | out add: each].
	^out!
leafLabels
	^self leaves collect: [:each | each label]!
leafCount
	| n |
	n := 0.
	self leavesDo: [:each | n := n + 1].
	^n!
nodeCount
	| n |
	n := 0.
	self preOrderDo: [:each | n := n + 1].
	^n!
ancestors
	| out |
	out := OrderedCollection new.
	self ancestorsDo: [:each | out add: each].
	^out!
includesNode: aNode
	self preOrderDo: [:each | each == aNode ifTrue: [^true]].
	^false! !

!PhyloNode methodsFor: 'measuring'!
depth
	"how many edges lie between this node and the root"
	^self ancestors size!
height
	"the greatest branch-length distance from here down to a leaf"
	| best |
	self isLeaf ifTrue: [^0].
	best := 0.
	children do: [:each | best := best max: (each lengthOr: 0) + each height].
	^best!
totalLength
	"the branch lengths of this node and everything under it, the branch above it included"
	| total |
	total := self lengthOr: 0.
	children do: [:each | total := total + each totalLength].
	^total!
distanceToRoot
	| total c |
	total := 0.
	c := self.
	[c notNil] whileTrue: [total := total + (c lengthOr: 0). c := c parent].
	^total! !

!PhyloNode methodsFor: 'copying'!
copyTree
	"a new tree of new nodes with the same shape and the same values"
	| copy |
	copy := PhyloNode named: label.
	copy branchLength: branchLength; support: support.
	children do: [:each | copy add: each copyTree].
	^copy!
postCopy
	^self copyTree! !

!PhyloNode methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a PhyloNode('; nextPutAll: self name.
	branchLength ifNotNil: [:x | aStream nextPut: $:; nextPutAll: (x printShowingDecimalPlaces: 5)].
	aStream nextPut: $)!
asNewick
	^NewickWriter write: (PhyloTree on: self copyTree)! !

"---- the tree ----"

!PhyloTree class methodsFor: 'instance creation'!
on: aNode
	^self basicNew setRoot: aNode!
named: aString on: aNode
	^(self on: aNode) name: aString; yourself!
fromNewick: aString
	^NewickReader parse: aString!
readFrom: aPath
	^NewickReader readFile: aPath!
star: someLabels
	"the tree that says nothing: every taxon hanging off one node"
	| root |
	root := PhyloNode new.
	someLabels do: [:each | root add: (PhyloNode named: each asString)].
	^self on: root! !

!PhyloTree methodsFor: 'private'!
setRoot: aNode
	root := aNode.
	aNode parent: nil! !

!PhyloTree methodsFor: 'accessing'!
root
	^root!
root: aNode
	self setRoot: aNode!
name
	^name!
name: aString
	name := aString!
nodes
	^root nodes!
leaves
	^root leaves!
internalNodes
	^root internalNodes!
size
	"the number of taxa"
	^root leafCount!
nodeCount
	^root nodeCount!
taxa
	"the taxon names, in order"
	^(root leafLabels asSortedCollection: [:a :b | a <= b]) asArray!
labels
	"the taxon names in the order the tree holds them"
	^root leafLabels asArray!
leafNamed: aString
	^self leafNamed: aString ifAbsent: [PhyloError new signal: 'no taxon named ', aString printString]!
leafNamed: aString ifAbsent: aBlock
	root leavesDo: [:each | each label = aString ifTrue: [^each]].
	^aBlock value!
includesTaxon: aString
	^(self leafNamed: aString ifAbsent: [nil]) notNil! !

!PhyloTree methodsFor: 'testing'!
isRooted
	"a rooted tree has two branches at the root; an unrooted one is written with three"
	^root children size = 2!
isBinary
	"every internal branch splits two ways; the root may split three ways, which is how an unrooted
	tree is written"
	root children size > 3 ifTrue: [^false].
	root preOrderDo: [:each |
		(each isRoot or: [each isLeaf]) ifFalse: [each children size = 2 ifFalse: [^false]]].
	^true!
hasBranchLengths
	root preOrderDo: [:each | (each isRoot or: [each hasBranchLength]) ifFalse: [^false]].
	^true!
hasSupport
	root internalDo: [:each | each hasSupport ifTrue: [^true]].
	^false!
isUltrametric
	"every leaf the same distance from the root, as a clock-like or UPGMA tree is"
	| first |
	first := nil.
	root leavesDo: [:each |
		first isNil
			ifTrue: [first := each distanceToRoot]
			ifFalse: [(each distanceToRoot - first) abs > 0.000001 ifTrue: [^false]]].
	^true! !

!PhyloTree methodsFor: 'measuring'!
totalBranchLength
	^root totalLength!
height
	^root height!
pathFrom: aNode to: anotherNode
	"the nodes from one to the other, both ends included, through their most recent common ancestor"
	| up down mrca c |
	mrca := self mrcaOfNodes: (Array with: aNode with: anotherNode).
	mrca isNil ifTrue: [^nil].
	up := OrderedCollection new.
	c := aNode.
	[c ~~ mrca and: [c notNil]] whileTrue: [up add: c. c := c parent].
	up add: mrca.
	down := OrderedCollection new.
	c := anotherNode.
	[c ~~ mrca and: [c notNil]] whileTrue: [down add: c. c := c parent].
	^up, down reverse!
lineageOf: aNode
	"the node, then its parent, and so on up to the root"
	| out c |
	out := OrderedCollection new.
	c := aNode.
	[c notNil] whileTrue: [out add: c. c := c parent].
	^out!
suffixFrom: aNode of: aCollection
	| out seen |
	out := OrderedCollection new.
	seen := false.
	aCollection do: [:each | (seen or: [each == aNode]) ifTrue: [seen := true. out add: each]].
	^out!
climbFrom: aNode to: anAncestor
	"the branch lengths between a node and one of its ancestors"
	| total c |
	total := 0.
	c := aNode.
	[c notNil and: [c ~~ anAncestor]] whileTrue: [total := total + (c lengthOr: 0). c := c parent].
	^total!
distanceFrom: aNode to: anotherNode
	"the patristic distance: the branch lengths along the path between them"
	| mrca |
	aNode == anotherNode ifTrue: [^0].
	mrca := self mrcaOfNodes: (Array with: aNode with: anotherNode).
	mrca isNil ifTrue: [^nil].
	^(self climbFrom: aNode to: mrca) + (self climbFrom: anotherNode to: mrca)!
distanceBetween: aLabel and: anotherLabel
	^self distanceFrom: (self leafNamed: aLabel) to: (self leafNamed: anotherLabel)!
mrcaOfNodes: someNodes
	"the most recent node that has all of them under it"
	| chain |
	someNodes isEmpty ifTrue: [^nil].
	chain := self lineageOf: someNodes first.
	someNodes do: [:node |
		| found |
		found := nil.
		(self lineageOf: node) do: [:c | (found isNil and: [chain includes: c]) ifTrue: [found := c]].
		found isNil ifTrue: [^nil].
		chain := self suffixFrom: found of: chain].
	^chain first!
mrcaOf: someLabels
	^self mrcaOfNodes: (someLabels collect: [:each | self leafNamed: each])!
distanceMatrix
	"the patristic distances between every pair of taxa"
	| labels m |
	labels := self labels.
	m := DistanceMatrix labels: labels.
	1 to: labels size do: [:i |
		i + 1 to: labels size do: [:j |
			m at: i and: j put: (self distanceBetween: (labels at: i) and: (labels at: j))]].
	^m! !

!PhyloTree methodsFor: 'transforming'!
ladderize
	"put the smaller clade first at every node, so the drawing reads tidily"
	^self ladderizeAscending: true!
ladderizeDescending
	^self ladderizeAscending: false!
ladderizeAscending: aBoolean
	| sorted |
	root preOrderDo: [:node |
		node isInternal ifTrue: [
			sorted := (node children asSortedCollection: [:a :b |
				a leafCount = b leafCount
					ifTrue: [a name <= b name]
					ifFalse: [aBoolean ifTrue: [a leafCount < b leafCount] ifFalse: [a leafCount > b leafCount]]]) asArray.
			node children removeAll.
			sorted do: [:each | node children add: each]]].
	^self!
scaleBy: aNumber
	root preOrderDo: [:each | each hasBranchLength ifTrue: [each branchLength: each branchLength * aNumber]].
	^self!
collapseBranchesShorterThan: aNumber
	"take out the internal branches that say nothing, making the tree less than binary where they were"
	| doomed |
	doomed := OrderedCollection new.
	root internalDo: [:each |
		(each isRoot not and: [(each lengthOr: 0) < aNumber]) ifTrue: [doomed add: each]].
	doomed do: [:each | self collapseNode: each].
	^self!
collapseNode: aNode
	"hand aNode's children to its parent and drop it, in aNode's place among them"
	| p kept |
	p := aNode parent.
	p isNil ifTrue: [^self].
	kept := OrderedCollection new.
	p children do: [:each |
		each == aNode
			ifTrue: [aNode children do: [:k |
					k branchLength: (k lengthOr: 0) + (aNode lengthOr: 0).
					k parent: p.
					kept add: k]]
			ifFalse: [kept add: each]].
	p children removeAll.
	kept do: [:each | p children add: each].
	aNode parent: nil.
	^self!
unroot
	"turn a two-branch root into a three-branch one, the way an unrooted tree is written"
	| kids victim |
	self isRooted ifFalse: [^self].
	kids := root children.
	victim := (kids first isInternal) ifTrue: [kids first] ifFalse: [kids last].
	victim isLeaf ifTrue: [^self].
	self collapseNode: victim.
	^self!
keepTaxa: someLabels
	"the tree with only these taxa left in it"
	| wanted |
	wanted := someLabels asOrderedCollection collect: [:each | each asString].
	^self pruneTaxa: (self labels reject: [:each | wanted includes: each])!
pruneTaxa: someLabels
	"the tree with these taxa taken out"
	| leaf |
	someLabels do: [:each |
		leaf := self leafNamed: each asString ifAbsent: [nil].
		leaf ifNotNil: [:l | self pruneLeaf: l]].
	self tidy.
	^self!
pruneLeaf: aLeaf
	| p |
	p := aLeaf parent.
	aLeaf detach.
	^p!
tidy
	"take out the internal nodes left with one child, adding their branch length to the child"
	| again |
	again := true.
	[again] whileTrue: [
		again := false.
		root nodes do: [:node |
			(node isRoot not and: [node isInternal and: [node children size = 1]]) ifTrue: [
				| only |
				only := node children first.
				only branchLength: (only lengthOr: 0) + (node lengthOr: 0).
				node parent replaceChild: node with: only.
				again := true]].
		(root isInternal and: [root children size = 1 and: [root children first isInternal]]) ifTrue: [
			root := root children first.
			root parent: nil.
			again := true]].
	^self! !

!PhyloTree methodsFor: 're-rooting'!
rootAt: aNode
	"re-root on the branch above aNode, the new root halfway along it"
	| half |
	aNode isRoot ifTrue: [^self].
	half := (aNode lengthOr: 0) / 2.
	^self rootAt: aNode distance: half!
rootAt: aNode distance: aNumber
	"re-root on the branch above aNode, aNumber of it below the new root"
	| old newRoot above rest |
	aNode isRoot ifTrue: [^self].
	old := aNode parent.
	above := (aNode lengthOr: 0) - aNumber max: 0.
	newRoot := PhyloNode new.
	old remove: aNode.
	self reverseParentsFrom: old.
	rest := old.
	newRoot add: aNode.
	aNode branchLength: aNumber.
	newRoot add: rest.
	rest branchLength: above.
	root := newRoot.
	root parent: nil.
	self tidy.
	^self!
reverseParentsFrom: aNode
	"turn the chain of parents above aNode round so that aNode is the top of its part of the tree"
	| p |
	p := aNode parent.
	p isNil ifTrue: [^self].
	self reverseParentsFrom: p.
	p remove: aNode.
	aNode add: p.
	p branchLength: (aNode lengthOr: 0).
	aNode parent: nil.
	^self!
rootOnMidpoint
	"re-root halfway along the longest path between any two leaves, which is the usual guess when
	there is no outgroup. The walk follows that path, up to the common ancestor and down again, until
	the halfway mark falls on the branch it is standing on."
	| leaves best bestPair path need prev node edge |
	leaves := self leaves.
	leaves size < 2 ifTrue: [^self].
	best := -1. bestPair := nil.
	1 to: leaves size do: [:i |
		i + 1 to: leaves size do: [:j |
			| d |
			d := self distanceFrom: (leaves at: i) to: (leaves at: j).
			d > best ifTrue: [best := d. bestPair := Array with: (leaves at: i) with: (leaves at: j)]]].
	bestPair isNil ifTrue: [^self].
	path := self pathFrom: bestPair first to: bestPair last.
	path isNil ifTrue: [^self].
	need := best / 2.
	prev := path first.
	2 to: path size do: [:k |
		node := path at: k.
		edge := node parent == prev ifTrue: [node lengthOr: 0] ifFalse: [prev lengthOr: 0].
		need <= edge ifTrue: [
			^node parent == prev
				ifTrue: [self rootAt: node distance: edge - need]
				ifFalse: [self rootAt: prev distance: need]].
		need := need - edge.
		prev := node].
	^self!
rootOn: aLabel
	"re-root with this taxon as the outgroup"
	^self rootAt: (self leafNamed: aLabel)!
rootOnAll: someLabels
	"re-root with these taxa, which must form a clade, as the outgroup"
	| mrca |
	someLabels size = 1 ifTrue: [^self rootOn: someLabels first].
	mrca := self mrcaOf: someLabels.
	mrca isNil ifTrue: [^self].
	^self rootAt: mrca! !

!PhyloTree methodsFor: 'comparing topologies'!
splits
	"the bipartitions of the taxa the internal branches make, each written as the side that leaves out
	the first taxon in alphabetical order, so that two trees can be compared whatever shape they are
	drawn in"
	| all out reference |
	all := self taxa.
	all size < 4 ifTrue: [^Set new].
	reference := all first.
	out := Set new.
	root internalDo: [:node |
		node isRoot ifFalse: [
			| clade |
			clade := (node leafLabels asSortedCollection: [:a :b | a <= b]) asArray.
			(clade size between: 2 and: all size - 2) ifTrue: [
				(clade includes: reference) ifTrue: [clade := all reject: [:t | clade includes: t]].
				out add: clade asArray]]].
	^out!
splitCount
	^self splits size!
robinsonFouldsTo: anotherTree
	"how many splits one tree has that the other has not, counted both ways; 0 means the same topology"
	| mine theirs |
	mine := self splits.
	theirs := anotherTree splits.
	^(mine reject: [:each | theirs includes: each]) size + (theirs reject: [:each | mine includes: each]) size!
hasSameTopologyAs: anotherTree
	^self taxa = anotherTree taxa and: [(self robinsonFouldsTo: anotherTree) = 0]!
sharesSplit: aSplit
	^self splits includes: aSplit! !

!PhyloTree methodsFor: 'copying'!
postCopy
	root := root copyTree.
	root parent: nil!
copyTree
	^(PhyloTree on: root copyTree) name: name; yourself! !

!PhyloTree methodsFor: 'printing'!
asNewick
	^NewickWriter write: self!
asNewickWithoutLengths
	^NewickWriter new lengths: false; write: self!
asText
	^TreeRenderer render: self!
writeTo: aPath
	^NewickWriter write: self toFile: aPath!
printOn: aStream
	aStream nextPutAll: 'a PhyloTree('; print: self size; nextPutAll: ' taxa'.
	name ifNotNil: [:n | aStream nextPutAll: ', '; nextPutAll: n].
	aStream nextPut: $)!
report
	| out |
	out := WriteStream on: String new.
	out nextPutAll: (name ifNil: ['a tree']); nl.
	out nextPutAll: (String new: 60 withAll: $-); nl.
	out print: self size; nextPutAll: ' taxa, '; print: self nodeCount; nextPutAll: ' nodes, ';
		print: self splitCount; nextPutAll: ' internal splits'; nl.
	out nextPutAll: (self isRooted ifTrue: ['rooted'] ifFalse: ['unrooted']);
		nextPutAll: ', '; nextPutAll: (self isBinary ifTrue: ['fully resolved'] ifFalse: ['with polytomies']); nl.
	self hasBranchLengths ifTrue: [
		out nextPutAll: 'total branch length '; nextPutAll: (self totalBranchLength printShowingDecimalPlaces: 5); nl].
	out nl; nextPutAll: self asText; nl.
	out nextPutAll: self asNewick; nl.
	^out contents! !
