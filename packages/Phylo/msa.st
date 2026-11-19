"Multiple alignment: the rows themselves, and the progressive aligner that makes them.

A MultipleAlignment is a list of labels and a list of equally long gapped strings. It is what the distance
models are fed and what a tree is built from, and it can be read straight out of an aligned FASTA file.

ProgressiveAligner does the usual three steps: align every pair to see how far apart they are, build a guide
tree from those distances, then work up the guide tree aligning a profile against a profile. The profile step
scores a pair of columns by the average of the substitution scores over the residues in them, and uses affine
gaps, so it is the same idea as the pairwise aligner one level up."

Object subclass: #MultipleAlignment instanceVariableNames: 'labels rows' classVariableNames: '' category: 'Phylo-Alignment'!
Object subclass: #ProgressiveAligner instanceVariableNames: 'matrix gapOpen gapExtend guideTree protein' classVariableNames: '' category: 'Phylo-Alignment'!

"---- the alignment ----"

!MultipleAlignment class methodsFor: 'instance creation'!
labels: someLabels rows: someRows
	^self basicNew setLabels: someLabels rows: someRows!
rows: someRows
	"unnamed rows, called seq1, seq2 and so on"
	^self labels: ((1 to: someRows size) collect: [:i | 'seq', i printString]) rows: someRows!
fromRecords: someRecords
	"a collection of SeqRecords whose sequences are already aligned"
	^self labels: (someRecords collect: [:each | each id])
		rows: (someRecords collect: [:each | each asString])!
readFasta: aPath
	"an aligned FASTA file"
	^self fromRecords: (Bio readFasta: aPath) records!
fromFasta: aString
	^self fromRecords: (Bio parseFasta: aString) records!
align: someRecords
	"align them first, then answer the result"
	^ProgressiveAligner new align: someRecords! !

!MultipleAlignment methodsFor: 'private'!
setLabels: someLabels rows: someRows
	| n |
	labels := (someLabels asOrderedCollection collect: [:each | each asString]) asArray.
	rows := (someRows asOrderedCollection collect: [:each | each asString]) asArray.
	labels size = rows size ifFalse: [^PhyloError new signal: 'there are not as many labels as rows'].
	rows isEmpty ifTrue: [^self].
	n := rows first size.
	rows do: [:each | each size = n ifFalse: [
		^PhyloError new signal: 'the rows are not all the same length: ', n printString, ' and ', each size printString]].
	^self! !

!MultipleAlignment methodsFor: 'accessing'!
labels
	^labels!
rows
	^rows!
size
	"how many sequences"
	^rows size!
length
	"how many columns"
	^rows isEmpty ifTrue: [0] ifFalse: [rows first size]!
isEmpty
	^rows isEmpty!
notEmpty
	^rows notEmpty!
at: anIndex
	^rows at: anIndex!
rowAt: anIndex
	^rows at: anIndex!
labelAt: anIndex
	^labels at: anIndex!
rowNamed: aLabel
	| i |
	i := labels indexOf: aLabel asString ifAbsent: [0].
	i = 0 ifTrue: [^PhyloError new signal: 'no row named ', aLabel printString].
	^rows at: i!
columnAt: anIndex
	^(rows collect: [:each | each at: anIndex]) asArray!
do: aBlock
	rows do: aBlock!
labelsAndRowsDo: aBlock
	1 to: self size do: [:i | aBlock value: (labels at: i) value: (rows at: i)]!
asRecords
	^(1 to: self size) collect: [:i |
		SeqRecord id: (labels at: i) sequence: (BioSequence guess: (rows at: i))]! !

!MultipleAlignment methodsFor: 'testing'!
isProtein
	"the letters say which it is; the gaps are left out of the question"
	^(BioSequence guess: self degapped) isProtein!
degapped
	"every row run together with the gaps taken out, only to be looked at"
	| out |
	out := WriteStream on: String new.
	rows do: [:row | row do: [:c | (c = $- or: [c = $.]) ifFalse: [out nextPut: c]]].
	^out contents!
isGapCharacter: aCharacter
	^aCharacter = $- or: [aCharacter = $. or: [aCharacter = $~]]! !

!MultipleAlignment methodsFor: 'measuring'!
gapCount
	| n |
	n := 0.
	rows do: [:row | row do: [:c | (self isGapCharacter: c) ifTrue: [n := n + 1]]].
	^n
!
gapPercent
	| cells |
	cells := self size * self length.
	^cells = 0 ifTrue: [0] ifFalse: [self gapCount * 100.0 / cells]!
conservationAt: anIndex
	"the share of the rows that carry the commonest residue in this column, gaps counted as a residue
	of their own"
	| counts best |
	self size = 0 ifTrue: [^0].
	counts := Dictionary new.
	rows do: [:row |
		| c |
		c := (row at: anIndex) asUppercase.
		counts at: c put: (counts at: c ifAbsent: [0]) + 1].
	best := 0.
	counts do: [:each | best := best max: each].
	^best / self size asFloat!
isColumnInvariant: anIndex
	^(self conservationAt: anIndex) = 1.0!
invariantColumns
	| n |
	n := 0.
	1 to: self length do: [:i | (self isColumnInvariant: i) ifTrue: [n := n + 1]].
	^n!
consensus
	^self consensusWithThreshold: 0.5!
consensusWithThreshold: aFraction
	"the commonest residue in each column, or an X (an N for nucleotides) where nothing reaches the
	threshold. A tie goes to whichever residue comes first in the alphabet, so the answer does not
	depend on the order a Dictionary happens to hand things back in."
	| out unknown |
	unknown := self isProtein ifTrue: [$X] ifFalse: [$N].
	out := WriteStream on: String new.
	1 to: self length do: [:i |
		| counts best bestChar k |
		counts := Dictionary new.
		rows do: [:row |
			| c |
			c := (row at: i) asUppercase.
			(self isGapCharacter: c) ifFalse: [counts at: c put: (counts at: c ifAbsent: [0]) + 1]].
		best := 0. bestChar := $-.
		(counts keys asSortedCollection: [:a :b | a <= b]) do: [:c |
			k := counts at: c.
			k > best ifTrue: [best := k. bestChar := c]].
		out nextPut: (best >= (aFraction * self size) ifTrue: [bestChar] ifFalse: [unknown])].
	^out contents!
matchLine
	"a star under a column where every row agrees, a colon where most do"
	| out c |
	out := WriteStream on: String new.
	1 to: self length do: [:i |
		c := self conservationAt: i.
		out nextPut: (c = 1.0 ifTrue: [$*] ifFalse: [c >= 0.5 ifTrue: [$:] ifFalse: [(Character value: 32)]])].
	^out contents!
identityBetween: i and: j
	"the share of the columns where both rows have a residue and the two agree"
	| a b same counted |
	a := rows at: i. b := rows at: j.
	same := 0. counted := 0.
	1 to: self length do: [:k |
		((self isGapCharacter: (a at: k)) or: [self isGapCharacter: (b at: k)]) ifFalse: [
			counted := counted + 1.
			(a at: k) asUppercase = (b at: k) asUppercase ifTrue: [same := same + 1]]].
	^counted = 0 ifTrue: [0] ifFalse: [same / counted asFloat]!
meanIdentity
	| total n |
	total := 0. n := 0.
	1 to: self size do: [:i | i + 1 to: self size do: [:j |
		total := total + (self identityBetween: i and: j). n := n + 1]].
	^n = 0 ifTrue: [0] ifFalse: [total / n]! !

!MultipleAlignment methodsFor: 'transforming'!
copy
	^MultipleAlignment labels: labels copy rows: (rows collect: [:each | each copy])!
withoutGapColumns
	"only the columns where every row has a residue, which is what a strict analysis wants"
	| keep |
	keep := (1 to: self length) select: [:i |
		(rows anySatisfy: [:row | self isGapCharacter: (row at: i)]) not].
	^self keepColumns: keep!
withoutColumnsGappierThan: aFraction
	| keep limit |
	limit := aFraction * self size.
	keep := (1 to: self length) select: [:i |
		(rows count: [:row | self isGapCharacter: (row at: i)]) <= limit].
	^self keepColumns: keep!
keepColumns: someIndices
	^MultipleAlignment labels: labels copy
		rows: (rows collect: [:row | self stringOf: row at: someIndices])!
stringOf: aRow at: someIndices
	| out |
	out := WriteStream on: String new.
	someIndices do: [:i | out nextPut: (aRow at: i)].
	^out contents!
columnsFrom: aStart to: aStop
	^self keepColumns: (aStart to: aStop)!
keepRows: someLabels
	| wanted keep |
	wanted := someLabels collect: [:each | each asString].
	keep := (1 to: self size) select: [:i | wanted includes: (labels at: i)].
	^MultipleAlignment labels: (keep collect: [:i | labels at: i]) rows: (keep collect: [:i | rows at: i])!
resampleColumnsWith: aRandom
	"a bootstrap replicate: as many columns as the original, drawn with replacement"
	| picked |
	picked := (1 to: self length) collect: [:i | aRandom nextInt: self length].
	^self keepColumns: picked! !

!MultipleAlignment methodsFor: 'trees'!
distanceMatrix
	^DistanceMatrix fromAlignment: self!
distanceMatrixUsing: aModel
	^DistanceMatrix fromAlignment: self model: aModel!
neighbourJoining
	^self distanceMatrix neighbourJoining!
neighbourJoiningUsing: aModel
	^(self distanceMatrixUsing: aModel) neighbourJoining!
upgma
	^self distanceMatrix upgma!
tree
	"the tree you get by just asking: neighbour joining on the default model for the alphabet"
	^self neighbourJoining!
bootstrap: aCount
	^Bootstrap on: self replicates: aCount! !

!MultipleAlignment methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a MultipleAlignment('; print: self size; nextPutAll: ' x '; print: self length; nextPut: $)!
asFasta
	| out |
	out := WriteStream on: String new.
	self labelsAndRowsDo: [:label :row |
		out nextPut: $>; nextPutAll: label; nl.
		1 to: row size by: 60 do: [:i |
			out nextPutAll: (row copyFrom: i to: (i + 59 min: row size)); nl]].
	^out contents!
writeTo: aPath
	FileStream newFileNamed: aPath do: [:f | f nextPutAll: self asFasta].
	^aPath!
asText
	^self asTextWrappedAt: 60!
asTextWrappedAt: aWidth
	"the rows in blocks, with the agreement marked under each one"
	| out width match |
	self isEmpty ifTrue: [^'(an empty alignment)'].
	width := 0.
	labels do: [:each | width := width max: (each size min: 20)].
	match := self matchLine.
	out := WriteStream on: String new.
	1 to: self length by: aWidth do: [:start |
		| stop |
		stop := start + aWidth - 1 min: self length.
		self labelsAndRowsDo: [:label :row |
			out nextPutAll: (self pad: (label truncateTo: width) to: width + 1);
				nextPutAll: (row copyFrom: start to: stop); nl].
		out nextPutAll: (String new: width + 1 withAll: (Character value: 32));
			nextPutAll: (match copyFrom: start to: stop); nl; nl].
	^out contents!
pad: aString to: aWidth
	^aString, (String new: (aWidth - aString size max: 1) withAll: (Character value: 32))!
report
	| out |
	out := WriteStream on: String new.
	out print: self size; nextPutAll: ' sequences, '; print: self length; nextPutAll: ' columns, ';
		nextPutAll: (self isProtein ifTrue: ['protein'] ifFalse: ['nucleotide']); nl.
	out print: self invariantColumns; nextPutAll: ' columns are the same all the way down, ';
		nextPutAll: (self gapPercent printShowingDecimalPlaces: 1); nextPutAll: '% of the cells are gaps'; nl.
	out nextPutAll: 'mean identity '; nextPutAll: ((self meanIdentity * 100) printShowingDecimalPlaces: 1);
		nextPutAll: '%'; nl; nl.
	out nextPutAll: self asText.
	^out contents! !

"---- the progressive aligner ----"

!ProgressiveAligner class methodsFor: 'instance creation'!
new
	^self basicNew setUp!
align: someRecords
	^self new align: someRecords!
protein
	^self new matrix: ScoringMatrix blosum62; protein: true; gapOpen: 11; gapExtend: 1; yourself!
dna
	^self new matrix: ScoringMatrix nucleotide; protein: false; gapOpen: 10; gapExtend: 1; yourself! !

!ProgressiveAligner methodsFor: 'private'!
setUp
	matrix := nil.
	protein := nil.
	gapOpen := 11.
	gapExtend := 1! !

!ProgressiveAligner methodsFor: 'options'!
matrix
	^matrix!
matrix: aMatrix
	matrix := aMatrix!
gapOpen
	^gapOpen!
gapOpen: aNumber
	"the cost of starting a gap, a positive number"
	gapOpen := aNumber!
gapExtend
	^gapExtend!
gapExtend: aNumber
	gapExtend := aNumber!
protein: aBoolean
	"which alphabet the sequences are in; worked out from them when it is not said"
	protein := aBoolean!
isProtein
	^protein ifNil: [false]!
guideTree
	"the tree the last alignment was built along"
	^guideTree! !

!ProgressiveAligner methodsFor: 'aligning'!
align: someRecords
	"the multiple alignment of a collection of SeqRecords, BioSequences or Strings"
	| items labels strings |
	items := someRecords asOrderedCollection.
	items size < 2 ifTrue: [
		items isEmpty ifTrue: [^PhyloError new signal: 'there is nothing to align'].
		^MultipleAlignment labels: (Array with: (self labelOf: items first at: 1))
			rows: (Array with: (self stringOf: items first))].
	labels := (1 to: items size) collect: [:i | self labelOf: (items at: i) at: i].
	strings := items collect: [:each | self stringOf: each].
	self chooseMatrixFor: strings.
	guideTree := self guideTreeFor: labels and: strings.
	^self alignAlong: guideTree labels: labels strings: strings!
labelOf: anItem at: anIndex
	(anItem respondsTo: #id) ifTrue: [^anItem id asString].
	^'seq', anIndex printString!
stringOf: anItem
	| text out |
	text := anItem asString.
	out := WriteStream on: String new.
	text do: [:c | (c = $- or: [c = $. or: [c isSeparator]]) ifFalse: [out nextPut: c]].
	^out contents!
chooseMatrixFor: someStrings
	protein isNil ifTrue: [protein := (BioSequence guess: someStrings first) isProtein].
	matrix isNil ifFalse: [^matrix].
	matrix := protein ifTrue: [ScoringMatrix blosum62] ifFalse: [ScoringMatrix nucleotide].
	^matrix!
guideTreeFor: someLabels and: someStrings
	"UPGMA on a k-mer distance: the share of short words the two sequences do not have in common.
	A guide tree only has to put the close pairs together first, and counting words does that in a
	fraction of the time aligning every pair would take - which is how the real aligners do it too."
	| n d counts |
	n := someStrings size.
	counts := someStrings collect: [:each | self wordCountsOf: each].
	d := DistanceMatrix labels: someLabels.
	1 to: n do: [:i |
		i + 1 to: n do: [:j |
			d at: i and: j put: (self wordDistanceBetween: (counts at: i) and: (counts at: j))]].
	^d upgma!
wordSize
	"three for protein, where the alphabet is wide; four for nucleotides, where it is not"
	^self isProtein ifTrue: [3] ifFalse: [4]!
wordCountsOf: aString
	| counts k word text |
	k := self wordSize.
	counts := Dictionary new.
	text := aString asUppercase.
	1 to: text size - k + 1 do: [:i |
		word := text copyFrom: i to: i + k - 1.
		counts at: word put: (counts at: word ifAbsent: [0]) + 1].
	^counts!
wordDistanceBetween: aDictionary and: anotherDictionary
	| shared total mine theirs |
	shared := 0.
	aDictionary keysAndValuesDo: [:word :count |
		shared := shared + (count min: (anotherDictionary at: word ifAbsent: [0]))].
	mine := 0. aDictionary do: [:each | mine := mine + each].
	theirs := 0. anotherDictionary do: [:each | theirs := theirs + each].
	total := mine min: theirs.
	^total = 0 ifTrue: [1.0] ifFalse: [1.0 - (shared / total asFloat)]! !

!ProgressiveAligner methodsFor: 'walking the guide tree'!
alignAlong: aTree labels: someLabels strings: someStrings
	"work up the guide tree: every leaf is a one-row profile, every internal node is the two profiles
	under it aligned together"
	| index profile |
	index := Dictionary new.
	1 to: someLabels size do: [:i | index at: (someLabels at: i) put: i].
	profile := Dictionary new.
	aTree root postOrderDo: [:node |
		node isLeaf
			ifTrue: [
				| i |
				i := index at: node label ifAbsent: [nil].
				i isNil ifTrue: [^PhyloError new signal: 'the guide tree names a sequence that is not here'].
				profile at: node put: (MultipleAlignment
					labels: (Array with: (someLabels at: i)) rows: (Array with: (someStrings at: i)))]
			ifFalse: [
				| merged |
				merged := profile at: node children first.
				2 to: node children size do: [:k |
					merged := self merge: merged with: (profile at: (node children at: k))].
				profile at: node put: merged]].
	^self reorder: (profile at: aTree root) like: someLabels! !

!ProgressiveAligner methodsFor: 'profiles'!
reorder: anAlignment like: someLabels
	"put the rows back in the order they were given in, which the guide tree will have shuffled"
	| wanted |
	wanted := someLabels asOrderedCollection collect: [:each | each asString].
	^MultipleAlignment
		labels: wanted asArray
		rows: (wanted collect: [:each | anAlignment rowNamed: each]) asArray!
merge: anAlignment with: anotherAlignment
	"align two profiles against each other and answer the one alignment that comes out"
	| plan |
	(anAlignment length + 1) * (anotherAlignment length + 1) > 1000000
		ifTrue: [^PhyloError new signal: 'these profiles are too long to align'].
	plan := self planFor: anAlignment and: anotherAlignment.
	^self buildFrom: plan of: anAlignment and: anotherAlignment!
countsOf: anAlignment
	"for each column, a flat Array of character value and count, character value and count, and the
	number of residues in the column: enough to score it against another column quickly"
	^(1 to: anAlignment length) collect: [:i |
		| tally n out |
		tally := Array new: 128 withAll: 0.
		n := 0.
		anAlignment rows do: [:row |
			| c |
			c := (row at: i) asUppercase value.
			(c < 128 and: [(anAlignment isGapCharacter: (Character value: c)) not]) ifTrue: [
				tally at: c put: (tally at: c) + 1.
				n := n + 1]].
		out := OrderedCollection new.
		1 to: 127 do: [:c | (tally at: c) > 0 ifTrue: [out add: c; add: (tally at: c)]].
		Array with: out asArray with: n]!
profilesOf: anAlignment
	"for each column, an Array holding, for every character, the average substitution score of that
	character against the whole column, in thousandths. Working this out once per column turns the
	inner loop of the table into one multiply per residue."
	| columns |
	columns := self countsOf: anAlignment.
	^columns collect: [:column |
		| pairs n row total |
		pairs := column first.
		n := column last.
		row := Array new: 128 withAll: 0.
		n > 0 ifTrue: [
			1 to: 127 do: [:y |
				total := 0.
				1 to: pairs size by: 2 do: [:k |
					total := total + ((pairs at: k + 1) *
						(matrix scoreFor: (Character value: (pairs at: k)) and: (Character value: y)))].
				row at: y put: (total * 1000) // n]].
		row]!
score: aProfileRow against: aColumn
	"the average substitution score between the two columns, in thousandths"
	| pairs n total |
	pairs := aColumn first.
	n := aColumn last.
	n = 0 ifTrue: [^0].
	total := 0.
	1 to: pairs size by: 2 do: [:k |
		total := total + ((pairs at: k + 1) * (aProfileRow at: (pairs at: k)))].
	^total // n!
planFor: anAlignment and: anotherAlignment
	"Needleman-Wunsch with affine gaps over the columns; answers the list of steps, each #diagonal,
	#up (a column of the first profile against a gap) or #left (a column of the second against a gap).
	Everything is in thousandths of a score so that no Floats are made inside the table."
	| n m left right m0 ix iy score best plan i j state open extend floor
	  mPrev mThis xPrev xThis yPrev yThis leftRow |
	left := self profilesOf: anAlignment.
	right := self countsOf: anotherAlignment.
	n := anAlignment length.
	m := anotherAlignment length.
	open := (gapOpen * 1000) rounded.
	extend := (gapExtend * 1000) rounded.
	floor := -1000000000.
	m0 := (0 to: n) collect: [:a | Array new: m + 1 withAll: floor].
	ix := (0 to: n) collect: [:a | Array new: m + 1 withAll: floor].
	iy := (0 to: n) collect: [:a | Array new: m + 1 withAll: floor].
	(m0 at: 1) at: 1 put: 0.
	1 to: n do: [:a | (ix at: a + 1) at: 1 put: (open + (extend * (a - 1))) negated].
	1 to: m do: [:b | (iy at: 1) at: b + 1 put: (open + (extend * (b - 1))) negated].
	1 to: n do: [:a |
		mPrev := m0 at: a.  mThis := m0 at: a + 1.
		xPrev := ix at: a.  xThis := ix at: a + 1.
		yPrev := iy at: a.  yThis := iy at: a + 1.
		leftRow := left at: a.
		1 to: m do: [:b |
			score := self score: leftRow against: (right at: b).
			mThis at: b + 1 put: score + (((mPrev at: b) max: (xPrev at: b)) max: (yPrev at: b)).
			xThis at: b + 1 put: (((mPrev at: b + 1) - open) max: ((xPrev at: b + 1) - extend)).
			yThis at: b + 1 put: (((mThis at: b) - open) max: ((yThis at: b) - extend))]].
	plan := OrderedCollection new.
	i := n. j := m.
	best := (m0 at: n + 1) at: m + 1.
	state := #m.
	(((ix at: n + 1) at: m + 1) > best) ifTrue: [best := (ix at: n + 1) at: m + 1. state := #x].
	(((iy at: n + 1) at: m + 1) > best) ifTrue: [state := #y].
	[i > 0 or: [j > 0]] whileTrue: [
		i = 0 ifTrue: [state := #y].
		j = 0 ifTrue: [state := #x].
		state == #m
			ifTrue: [
				plan addFirst: #diagonal.
				state := self stateBehind: i and: j in: m0 and: ix and: iy.
				i := i - 1. j := j - 1]
			ifFalse: [
				state == #x
					ifTrue: [
						plan addFirst: #up.
						state := (((m0 at: i) at: j + 1) - open) >= (((ix at: i) at: j + 1) - extend)
							ifTrue: [#m] ifFalse: [#x].
						i := i - 1]
					ifFalse: [
						plan addFirst: #left.
						state := (((m0 at: i + 1) at: j) - open) >= (((iy at: i + 1) at: j) - extend)
							ifTrue: [#m] ifFalse: [#y].
						j := j - 1]]].
	^plan!
stateBehind: i and: j in: m0 and: ix and: iy
	| a b c |
	a := (m0 at: i) at: j.
	b := (ix at: i) at: j.
	c := (iy at: i) at: j.
	(a >= b and: [a >= c]) ifTrue: [^#m].
	b >= c ifTrue: [^#x].
	^#y!
buildFrom: aPlan of: anAlignment and: anotherAlignment
	"follow the steps, taking a column from one side, the other, or both"
	| leftStreams rightStreams i j gapLeft gapRight |
	leftStreams := anAlignment rows collect: [:each | WriteStream on: String new].
	rightStreams := anotherAlignment rows collect: [:each | WriteStream on: String new].
	gapLeft := String new: anAlignment size withAll: $-.
	gapRight := String new: anotherAlignment size withAll: $-.
	i := 0. j := 0.
	aPlan do: [:step |
		step == #diagonal ifTrue: [
			i := i + 1. j := j + 1.
			self put: (anAlignment columnAt: i) into: leftStreams.
			self put: (anotherAlignment columnAt: j) into: rightStreams].
		step == #up ifTrue: [
			i := i + 1.
			self put: (anAlignment columnAt: i) into: leftStreams.
			self put: gapRight into: rightStreams].
		step == #left ifTrue: [
			j := j + 1.
			self put: gapLeft into: leftStreams.
			self put: (anotherAlignment columnAt: j) into: rightStreams]].
	^MultipleAlignment
		labels: anAlignment labels, anotherAlignment labels
		rows: (leftStreams collect: [:each | each contents]), (rightStreams collect: [:each | each contents])!
put: aColumn into: someStreams
	1 to: someStreams size do: [:k | (someStreams at: k) nextPut: (aColumn at: k)]! !
