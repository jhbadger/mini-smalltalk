"The front door, and the tree browser.

Phylo is a class with nothing but class-side methods: the short way to read a file, build a tree, draw one, or
find the package's own example data. TreeBrowser puts a tree in a window - the clades on the left, the drawing
and what is under the selected clade on the right."

Object subclass: #Phylo instanceVariableNames: '' classVariableNames: '' category: 'Phylo'!
Object subclass: #TreeBrowser instanceVariableNames: '' classVariableNames: 'Tree Mode Selected Note' category: 'Phylo'!

!Phylo class methodsFor: 'the package'!
version
	^'1.0'!
directory
	^Smalltalk packagePath: 'Phylo'!
dataDirectory
	^self directory, '/data'!
exampleFile: aName
	^self dataDirectory, '/', aName!
examples
	"what is in data/, and what each one is"
	^#(
		#('example.fasta' 'eight sequences of 300 columns, already aligned')
		#('example.tree' 'the tree example.fasta was simulated along, in Newick')
		#('unaligned.fasta' 'six of the same sequences with indels put in, to align'))!
exampleAlignment
	^MultipleAlignment readFasta: (self exampleFile: 'example.fasta')!
exampleTree
	^PhyloTree readFrom: (self exampleFile: 'example.tree')!
exampleSequences
	^(Bio readFasta: (self exampleFile: 'unaligned.fasta')) records! !

!Phylo class methodsFor: 'trees'!
tree: aNewickString
	^PhyloTree fromNewick: aNewickString!
readTree: aPath
	^PhyloTree readFrom: aPath!
readTrees: aPath
	^NewickReader readAllFrom: aPath!
writeTree: aTree to: aPath
	^aTree writeTo: aPath!
draw: aTree
	^TreeRenderer render: aTree!
draw: aTree width: anInteger
	^TreeRenderer render: aTree width: anInteger!
star: someLabels
	^PhyloTree star: someLabels! !

!Phylo class methodsFor: 'alignments'!
readAlignment: aPath
	^MultipleAlignment readFasta: aPath!
alignment: aFastaString
	^MultipleAlignment fromFasta: aFastaString!
align: someSequences
	"progressive multiple alignment of records, sequences or plain Strings"
	^ProgressiveAligner new align: someSequences!
alignFile: aPath
	^self align: (Bio readFasta: aPath) records! !

!Phylo class methodsFor: 'distances'!
models
	^DistanceModel names!
model: aName
	^DistanceModel named: aName!
distances: anAlignment
	^DistanceMatrix fromAlignment: anAlignment!
distances: anAlignment using: aModel
	^DistanceMatrix fromAlignment: anAlignment model: aModel!
readMatrix: aPath
	^DistanceMatrix readFrom: aPath!
matrix: aPhylipString
	^DistanceMatrix fromPhylip: aPhylipString! !

!Phylo class methodsFor: 'building'!
nj: aMatrixOrAlignment
	^self asMatrix: aMatrixOrAlignment thenSend: #neighbourJoining!
upgma: aMatrixOrAlignment
	^self asMatrix: aMatrixOrAlignment thenSend: #upgma!
asMatrix: anObject thenSend: aSelector
	| m |
	m := (anObject isKindOf: DistanceMatrix) ifTrue: [anObject] ifFalse: [DistanceMatrix fromAlignment: anObject].
	^m perform: aSelector!
bootstrap: anAlignment
	^Bootstrap on: anAlignment!
bootstrap: anAlignment replicates: aCount
	^Bootstrap on: anAlignment replicates: aCount! !

!Phylo class methodsFor: 'the browser'!
openBrowser
	^self openBrowserOn: self exampleTree!
openBrowserOn: aTree
	^TreeBrowser openOn: aTree!
open
	^TreeBrowser open! !

"---- the browser ----"

!TreeBrowser class methodsFor: 'opening'!
open
	Tree isNil ifTrue: [Tree := [Phylo exampleTree] on: Error do: [:e | PhyloTree fromNewick: '(A,B,C);']].
	^self openWindow!
openOn: aTree
	"a new tree starts on the drawing, whatever the window was last showing"
	Tree := aTree.
	Selected := 1.
	Mode := #drawing.
	^self openWindow!
openWindow
	Mode isNil ifTrue: [Mode := #drawing].
	Note := nil.
	Smalltalk openListTool: 'TreeBrowser' title: 'Tree: ', (self tree size printString), ' taxa'.
	^true!
tree
	^Tree ifNil: [Tree := PhyloTree fromNewick: '(A,B,C);']!
tree: aTree
	Tree := aTree.
	Selected := 1! !

!TreeBrowser class methodsFor: 'the list'!
listItems
	"the clades, innermost last, then the taxa"
	| out |
	out := OrderedCollection new.
	out add: '* the whole tree'.
	self tree root internalDo: [:node |
		node isRoot ifFalse: [
			out add: '  clade of ', node leafCount printString, ' (',
				((node leafLabels asOrderedCollection first: (node leafCount min: 3)) inject: ''
					into: [:a :b | a isEmpty ifTrue: [b] ifFalse: [a, ' ', b]]),
				(node leafCount > 3 ifTrue: ['...'] ifFalse: ['']), ')',
				(node hasSupport ifTrue: ['  ', node support printString, '%'] ifFalse: [''])]].
	self tree root leavesDo: [:leaf | out add: '- ', leaf name].
	^out asArray!
nodeAt: anIndex
	"the tree node the row stands for, or nil for the first row"
	| out |
	anIndex <= 1 ifTrue: [^nil].
	out := OrderedCollection new.
	self tree root internalDo: [:node | node isRoot ifFalse: [out add: node]].
	self tree root leavesDo: [:leaf | out add: leaf].
	^(anIndex - 1) <= out size ifTrue: [out at: anIndex - 1] ifFalse: [nil]!
detailAt: anIndex
	Selected := anIndex.
	^[self detailFor: (self nodeAt: anIndex)]
		on: Error
		do: [:e | 'could not show this: ', (e messageText ifNil: [e class name asString])]!
detailFor: aNode
	| out |
	out := WriteStream on: String new.
	Note ifNotNil: [:n | out nextPutAll: n; nl; nl].
	Mode == #newick ifTrue: [^out nextPutAll: self tree asNewick; nl; contents].
	Mode == #summary ifTrue: [^out nextPutAll: self tree report; contents].
	Mode == #distances ifTrue: [^out nextPutAll: self tree distanceMatrix report; contents].
	out nextPutAll: (Mode == #cladogram
		ifTrue: [TreeRenderer cladogram: self tree]
		ifFalse: [self tree asText]); nl.
	aNode ifNotNil: [:node | out nextPutAll: (self describe: node)].
	^out contents!
describe: aNode
	| out |
	out := WriteStream on: String new.
	out nextPutAll: (String new: 60 withAll: $-); nl.
	aNode isLeaf
		ifTrue: [
			out nextPutAll: 'the taxon '; nextPutAll: aNode name; nl.
			aNode hasBranchLength ifTrue: [
				out nextPutAll: 'branch '; nextPutAll: (aNode branchLength printShowingDecimalPlaces: 5); nl].
			out nextPutAll: 'distance from the root ';
				nextPutAll: (aNode distanceToRoot printShowingDecimalPlaces: 5); nl]
		ifFalse: [
			out nextPutAll: 'a clade of '; print: aNode leafCount; nextPutAll: ' taxa'; nl.
			aNode hasSupport ifTrue: [out nextPutAll: 'support '; print: aNode support; nextPutAll: '%'; nl].
			aNode hasBranchLength ifTrue: [
				out nextPutAll: 'branch '; nextPutAll: (aNode branchLength printShowingDecimalPlaces: 5); nl].
			out nextPutAll: 'height '; nextPutAll: (aNode height printShowingDecimalPlaces: 5); nl; nl.
			aNode leafLabels do: [:each | out nextPutAll: '  '; nextPutAll: each; nl]].
	^out contents! !

!TreeBrowser class methodsFor: 'the menu'!
commandLabels
	^#('drawing' 'cladogram' 'newick' 'summary' 'distances' '-' 'ladderize' 'midpoint root'
	   'root on this taxon' 'unroot' '-' 'open newick file...' 'copy newick to Transcript')!
command: aCommand at: anIndex
	| label node |
	label := self commandLabels at: aCommand.
	Selected := anIndex.
	node := self nodeAt: anIndex.
	Note := nil.
	label = 'drawing' ifTrue: [Mode := #drawing. ^nil].
	label = 'cladogram' ifTrue: [Mode := #cladogram. ^nil].
	label = 'newick' ifTrue: [Mode := #newick. ^nil].
	label = 'summary' ifTrue: [Mode := #summary. ^nil].
	label = 'distances' ifTrue: [Mode := #distances. ^nil].
	label = 'ladderize' ifTrue: [self tree ladderize. ^nil].
	label = 'midpoint root' ifTrue: [self tree rootOnMidpoint. ^nil].
	label = 'root on this taxon' ifTrue: [^self rootOn: node].
	label = 'unroot' ifTrue: [self tree unroot. ^nil].
	label = 'open newick file...' ifTrue: [^self openFileCommand].
	label = 'copy newick to Transcript' ifTrue: [
		Transcript showCr: self tree asNewick.
		^'copied to the Transcript'].
	^nil!
rootOn: aNode
	aNode isNil ifTrue: [^'select a taxon or a clade first'].
	aNode isRoot ifTrue: [^'that is the root already'].
	self tree rootAt: aNode.
	^nil!
openFileCommand
	| path |
	path := Smalltalk promptFor: 'Newick file' default: (Phylo exampleFile: 'example.tree').
	(path isNil or: [path trimBoth isEmpty]) ifTrue: [^nil].
	^[Tree := PhyloTree readFrom: path trimBoth. Selected := 1. nil]
		on: Error
		do: [:e | 'could not read it: ', (e messageText ifNil: [e class name asString])]! !
