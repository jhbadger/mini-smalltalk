"Drawing a tree with characters.

Every leaf gets a row and every node a column: in a phylogram the column comes from the branch lengths, in a
cladogram simply from how deep the node is. Verticals are drawn first and the branches over them, so a corner
reads the way you expect.

	           /----------- Gorilla
	    /------|
	    |      \----------- Human
	----|
	    \------------------ Macaque
"

Object subclass: #TreeRenderer instanceVariableNames: 'tree width grid columns rows showSupport phylogram labelWidth' classVariableNames: '' category: 'Phylo-Drawing'!

!TreeRenderer class methodsFor: 'drawing'!
render: aTree
	^self new render: aTree!
render: aTree width: anInteger
	^self new width: anInteger; render: aTree!
cladogram: aTree
	"shape only: the branch lengths are not used"
	^self new phylogram: false; render: aTree!
new
	^self basicNew setUp! !

!TreeRenderer methodsFor: 'private'!
setUp
	width := 50.
	showSupport := true.
	phylogram := true.
	labelWidth := 30! !

!TreeRenderer methodsFor: 'options'!
width: anInteger
	"how many characters the longest branch path may use"
	width := anInteger max: 4!
phylogram: aBoolean
	"true to let the branch lengths set the horizontal positions"
	phylogram := aBoolean!
showSupport: aBoolean
	showSupport := aBoolean!
labelWidth: anInteger
	labelWidth := anInteger! !

!TreeRenderer methodsFor: 'drawing'!
render: aTree
	| out |
	tree := aTree.
	tree size = 0 ifTrue: [^'(an empty tree)'].
	tree size = 1 ifTrue: [^'---- ', (tree leaves first name), (String with: Character lf)].
	self layout.
	self paint.
	out := WriteStream on: String new.
	grid do: [:line | out nextPutAll: (self trimRight: line); nl].
	^out contents!
trimRight: aString
	| last |
	last := 0.
	1 to: aString size do: [:i | (aString at: i) = (Character value: 32) ifFalse: [last := i]].
	^aString copyFrom: 1 to: last! !

!TreeRenderer methodsFor: 'laying out'!
layout
	| leaves depths maxDepth scale maxCol |
	rows := Dictionary new.
	columns := Dictionary new.
	leaves := tree root leaves.
	leaves doWithIndex: [:leaf :i | rows at: leaf put: (i * 2) - 1].
	tree root postOrderDo: [:node |
		node isInternal ifTrue: [
			rows at: node put: ((rows at: node children first) + (rows at: node children last)) // 2]].
	depths := Dictionary new.
	self depthsInto: depths from: tree root at: 0.
	maxDepth := 0.
	depths do: [:each | maxDepth := maxDepth max: each].
	maxDepth = 0 ifTrue: [
		"nothing to scale by: fall back to one column per step, so the shape still shows"
		depths := Dictionary new.
		self depthsByStepInto: depths from: tree root at: 0.
		depths do: [:each | maxDepth := maxDepth max: each]].
	scale := maxDepth = 0 ifTrue: [0] ifFalse: [width / maxDepth asFloat].
	maxCol := 1.
	depths keysAndValuesDo: [:node :depth |
		| c |
		c := 4 + (depth * scale) rounded.
		columns at: node put: c.
		maxCol := maxCol max: c].
	self buildGridWidth: maxCol + 2 + labelWidth height: (leaves size * 2) - 1!
depthsInto: aDictionary from: aNode at: aDepth
	| step |
	aDictionary at: aNode put: aDepth.
	aNode children do: [:each |
		step := phylogram
			ifTrue: [(each lengthOr: 0) abs]
			ifFalse: [1].
		self depthsInto: aDictionary from: each at: aDepth + step]!
depthsByStepInto: aDictionary from: aNode at: aDepth
	aDictionary at: aNode put: aDepth.
	aNode children do: [:each | self depthsByStepInto: aDictionary from: each at: aDepth + 1]!
buildGridWidth: aWidth height: aHeight
	grid := OrderedCollection new.
	1 to: aHeight do: [:i | grid add: (String new: aWidth withAll: (Character value: 32))]! !

!TreeRenderer methodsFor: 'painting'!
paint
	"branches first and uprights over them, so that a junction shows as a corner and not as a dash"
	tree root preOrderDo: [:node | node isRoot ifTrue: [self paintStub: node] ifFalse: [self paintBranch: node]].
	tree root preOrderDo: [:node | node isInternal ifTrue: [self paintVertical: node]].
	tree root leavesDo: [:leaf | self paintLabel: leaf].
	showSupport ifTrue: [
		tree root internalDo: [:node | node isRoot ifFalse: [self paintSupport: node]]]!
paintVertical: aNode
	"the upright that holds a node's children together, with corners at the ends"
	| col top bottom |
	col := columns at: aNode.
	top := rows at: aNode children first.
	bottom := rows at: aNode children last.
	top to: bottom do: [:r |
		self at: r and: col put: (r = top ifTrue: [$/] ifFalse: [r = bottom ifTrue: [$\] ifFalse: [$|]])]!
paintBranch: aNode
	"the horizontal from the parent's upright across to the node"
	| row from to |
	row := rows at: aNode.
	from := (columns at: aNode parent) + 1.
	to := columns at: aNode.
	from to: to do: [:c | self at: row and: c put: $-]!
paintStub: aNode
	"the little line that comes into the root from nowhere"
	| row col |
	row := rows at: aNode.
	col := columns at: aNode.
	1 to: col - 1 do: [:c | self at: row and: c put: $-]!
paintLabel: aLeaf
	| row col text |
	row := rows at: aLeaf.
	col := columns at: aLeaf.
	text := aLeaf name truncateTo: labelWidth.
	1 to: text size do: [:i | self at: row and: col + 1 + i put: (text at: i)]!
paintSupport: aNode
	"the support value written into the branch coming into the node"
	| row col text start |
	aNode hasSupport ifFalse: [^self].
	text := self textForSupport: aNode support.
	row := rows at: aNode.
	start := (columns at: aNode) - text size.
	start := start max: (columns at: aNode parent) + 1.
	((columns at: aNode) - start) < text size ifTrue: [^self].
	1 to: text size do: [:i | self at: row and: start + i - 1 put: (text at: i)]!
textForSupport: aNumber
	aNumber isInteger ifTrue: [^aNumber printString].
	^aNumber asFloat printShowingDecimalPlaces: 2!
at: aRow and: aColumn
	| line |
	(aRow between: 1 and: grid size) ifFalse: [^(Character value: 32)].
	line := grid at: aRow.
	(aColumn between: 1 and: line size) ifFalse: [^(Character value: 32)].
	^line at: aColumn!
at: aRow and: aColumn put: aCharacter
	| line |
	(aRow between: 1 and: grid size) ifFalse: [^aCharacter].
	line := grid at: aRow.
	(aColumn between: 1 and: line size) ifFalse: [^aCharacter].
	line at: aColumn put: aCharacter.
	^aCharacter! !
