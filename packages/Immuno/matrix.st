"The binding model: a position-specific scoring matrix for the peptide groove of one MHC molecule.

A class I groove holds a peptide of about nine residues, anchored by pockets that take the second residue (P2) and
the last (P9, or P-omega) and fit the middle ones loosely. A matrix has nine columns and twenty rows of integers,
each the log2 odds, in tenths of a bit, of seeing that residue at that position in a binder rather than in a
random protein. Scoring a peptide adds one cell per position, so a peptide that fits every pocket scores high
and one that breaks an anchor scores low.

A matrix is made one of two ways: written down from a motif (fromMotif:, which is how the models in this
package are made) or trained from a list of known binders (trainOn:, which is how you make your own).

Scores of different molecules cannot be compared directly, because one matrix is more demanding than another.
What can be compared is the rank: the percentage of random peptides that would score at least as well, worked
out exactly from the background composition of proteins. For these motif models a rank of 1 or less is called a
strong binder and 5 or less a weak one (a class II peptide: 2 and 10); trained predictors usually use 0.5 and 2
for class I.

Peptides of eight to eleven residues are scored against the nine-column matrix by deleting residues from the
middle (they bulge out of the groove) or leaving a gap, and taking the best fit, with a small penalty for not
being nine. Class II grooves are open at both ends, so a peptide of any length from nine up is scored by
sliding the nine-residue core along it and keeping the best window."

Object subclass: #BindingMatrix instanceVariableNames: 'name mhcClass cells source survival' classVariableNames: '' category: 'Immuno-Binding'!
Object subclass: #BindingPrediction instanceVariableNames: 'peptide allele tenths rank core position mhcClass' classVariableNames: '' category: 'Immuno-Binding'!

!BindingMatrix class methodsFor: 'from a motif'!
fromMotif: aSpec name: aName class: aClass
	"aSpec is an Array of #(position residues enrichment): every residue in the string, at that position,
	is that many times more (or, below 1, less) common among binders than in proteins at large.
	Anything the spec does not mention is 1: no preference."
	| m |
	m := self basicNew setName: aName class: aClass source: 'a motif'.
	aSpec do: [:row |
		(row at: 2) do: [:c |
			m setCell: (row at: 1) residue: c tenths: ((row at: 3) ln / 2 ln * 10) rounded]].
	^m! !

!BindingMatrix class methodsFor: 'from binders'!
trainOn: somePeptides name: aName class: aClass
	^self trainOn: somePeptides name: aName class: aClass pseudocount: 5!
trainOn: somePeptides name: aName class: aClass pseudocount: beta
	"count the residues of the nine-mers among somePeptides column by column, weight the peptides so that a
	cluster of near-identical ones does not count for more than its share (Henikoff weights), add beta
	pseudo-counts spread like the background, and take the log odds against the background"
	| nines weights m total bg freq count |
	nines := (somePeptides collect: [:p | p asPeptide]) select: [:p | p size = 9].
	nines isEmpty ifTrue: [^ImmunoError new signal: 'training needs peptides nine residues long'].
	weights := self weightsFor: nines.
	total := weights inject: 0.0 into: [:a :b | a + b].
	bg := AminoAcid background.
	m := self basicNew setName: aName class: aClass
		source: 'trained on ', nines size printString, ' peptides'.
	1 to: 9 do: [:pos |
		1 to: 20 do: [:i |
			count := 0.0.
			nines doWithIndex: [:p :k |
				(p at: pos) = (AminoAcid order at: i) ifTrue: [count := count + (weights at: k)]].
			freq := (count + (beta * (bg at: i))) / (total + beta).
			m setCell: pos residue: (AminoAcid order at: i)
				tenths: ((freq / (bg at: i)) ln / 2 ln * 10) rounded]].
	^m!
weightsFor: peptides
	"Henikoff position-based weights, scaled so that they add up to the number of peptides"
	| n w distinct counts sum |
	n := peptides size.
	w := Array new: n withAll: 0.0.
	1 to: 9 do: [:pos |
		counts := Dictionary new.
		peptides do: [:p | counts at: (p at: pos) put: (counts at: (p at: pos) ifAbsent: [0]) + 1].
		distinct := counts size.
		peptides doWithIndex: [:p :k |
			w at: k put: (w at: k) + (1.0 / (distinct * (counts at: (p at: pos))))]].
	sum := w inject: 0.0 into: [:a :b | a + b].
	^w collect: [:x | x * n / sum]! !

!BindingMatrix methodsFor: 'private'!
setName: aName class: aClass source: aString
	name := aName. mhcClass := aClass. source := aString.
	cells := (1 to: 9) collect: [:i | Array new: 20 withAll: 0]!
setCell: position residue: aCharacter tenths: anInteger
	(cells at: position) at: (AminoAcid checkedIndex: aCharacter) put: anInteger.
	survival := nil! !

!BindingMatrix methodsFor: 'accessing'!
name
	^name!
mhcClass
	^mhcClass!
source
	^source!
isClassI
	^mhcClass = 1!
cellAt: position residue: aCharacter
	"the score of the residue at the position, in bits"
	^((cells at: position) at: (AminoAcid checkedIndex: aCharacter)) / 10.0!
tenthsAt: position residue: aCharacter
	^(cells at: position) at: (AminoAcid checkedIndex: aCharacter)!
rangeAt: position
	"the best cell minus the worst cell in a column, in bits: how much the position matters"
	| col |
	col := cells at: position.
	^((col inject: col first into: [:a :b | a max: b]) - (col inject: col first into: [:a :b | a min: b])) / 10.0!
anchors
	"the positions where the range is at least two bits, most demanding first"
	^(((1 to: 9) select: [:p | (self rangeAt: p) >= 2.0])
		asSortedCollection: [:a :b | (self rangeAt: a) >= (self rangeAt: b)]) asArray!
topResidues: n at: position
	"the n residues that score best at a position, as a String, best first"
	| col idx |
	col := cells at: position.
	idx := ((1 to: 20) asSortedCollection: [:a :b |
		(col at: a) > (col at: b) or: [(col at: a) = (col at: b) and: [a < b]]]) asArray.
	^String withAll: ((1 to: n) collect: [:k | AminoAcid order at: (idx at: k)])!
maxTenths
	^(1 to: 9) inject: 0 into: [:sum :p | sum + ((cells at: p) inject: -1000 into: [:a :b | a max: b])]!
minTenths
	^(1 to: 9) inject: 0 into: [:sum :p | sum + ((cells at: p) inject: 1000 into: [:a :b | a min: b])]!
maxScore
	^self maxTenths / 10.0!
minScore
	^self minTenths / 10.0!
minimumLength
	^self isClassI ifTrue: [8] ifFalse: [9]!
maximumLength
	^self isClassI ifTrue: [11] ifFalse: [30]! !

!BindingMatrix methodsFor: 'scoring'!
tenthsOfNine: aString
	"the matrix score of exactly nine residues, as an integer in tenths of a bit"
	| t |
	t := 0.
	1 to: 9 do: [:p | t := t + ((cells at: p) at: (AminoAcid indexOf: (aString at: p)))].
	^t!
scoreOfNine: aString
	^(self tenthsOfNine: aString) / 10.0!
fitFor: aPeptide
	"how aPeptide sits in the groove, as an Array of the score in tenths and the nine residues of the
	core ('-' marks a gap); the best fit over every way to bulge the peptide or slide the core"
	| s best |
	s := aPeptide asString.
	(s size < self minimumLength or: [s size > self maximumLength]) ifTrue: [
		^ImmunoError new signal: name, ' scores peptides of ',
			self minimumLength printString, ' to ', self maximumLength printString,
			' residues, not ', s size printString].
	best := nil.
	self isClassI
		ifTrue: [self class18Candidates: s do: [:core :penalty |
			| t |
			t := (self tenthsOfGapped: core) - penalty.
			(best isNil or: [t > (best at: 1)]) ifTrue: [best := Array with: t with: core]]]
		ifFalse: [1 to: s size - 8 do: [:i |
			| core t |
			core := s copyFrom: i to: i + 8.
			t := self tenthsOfNine: core.
			(best isNil or: [t > (best at: 1)]) ifTrue: [best := Array with: t with: core]]].
	^best!
tenthsOfGapped: aString
	"as tenthsOfNine:, where a '-' scores nothing"
	| t c |
	t := 0.
	1 to: 9 do: [:p |
		c := aString at: p.
		c = $- ifFalse: [t := t + ((cells at: p) at: (AminoAcid indexOf: c))]].
	^t!
class18Candidates: s do: aBlock
	"every nine-column reading of a class I peptide of 8 to 11 residues, with its penalty in tenths"
	| n |
	n := s size.
	n = 9 ifTrue: [^aBlock value: s value: 0].
	n = 8 ifTrue: [
		4 to: 6 do: [:gap |
			aBlock value: (s copyFrom: 1 to: gap - 1), '-', (s copyFrom: gap to: 8) value: 5].
		^self].
	(self deletions: n - 9 of: s from: 4 to: n - 3) do: [:core |
		aBlock value: core value: (n - 9) * 5]!
deletions: k of: aString from: lo to: hi
	"every string made by deleting k residues of aString at positions lo to hi"
	| out |
	k = 0 ifTrue: [^Array with: aString].
	out := OrderedCollection new.
	lo to: hi do: [:i |
		out addAll: (self deletions: k - 1
			of: (aString copyFrom: 1 to: i - 1), (aString copyFrom: i + 1 to: aString size)
			from: i to: hi - 1)].
	^out! !

!BindingMatrix methodsFor: 'ranking'!
survivalTable
	"survival at: t - minTenths + 1 is the fraction of random nine-mers scoring t tenths or more"
	| dist next bg lo hi acc |
	survival isNil ifFalse: [^survival].
	bg := AminoAcid background.
	dist := Dictionary new.
	dist at: 0 put: 1.0.
	1 to: 9 do: [:pos |
		next := Dictionary new.
		dist keysAndValuesDo: [:t :p |
			1 to: 20 do: [:i |
				| key |
				key := t + ((cells at: pos) at: i).
				next at: key put: (next at: key ifAbsent: [0.0]) + (p * (bg at: i))]].
		dist := next].
	lo := self minTenths. hi := self maxTenths.
	survival := Array new: hi - lo + 1 withAll: 0.0.
	acc := 0.0.
	hi to: lo by: -1 do: [:t |
		acc := acc + (dist at: t ifAbsent: [0.0]).
		survival at: t - lo + 1 put: acc].
	^survival!
rankOfTenths: t
	"the percentage of random nine-mers that score at least t tenths of a bit"
	| table i |
	table := self survivalTable.
	i := t - self minTenths + 1.
	i < 1 ifTrue: [^100.0].
	i > table size ifTrue: [^0.0].
	^(table at: i) * 100.0!
rankOfScore: bits
	^self rankOfTenths: (bits * 10) rounded!
rankOfTenths: t windows: k
	"the rank of the best of k windows that each score about t: the chance that at least one of k random
	windows does at least as well (the windows overlap, so this is a little generous)"
	| p |
	p := (self rankOfTenths: t) / 100.0.
	^(1.0 - ((1.0 - p) raisedTo: k)) * 100.0! !

!BindingMatrix methodsFor: 'predicting'!
predict: aPeptide
	"a BindingPrediction for the peptide against this molecule"
	| p fit |
	p := aPeptide asPeptide.
	fit := self fitFor: p.
	^BindingPrediction peptide: p allele: name tenths: (fit at: 1)
		rank: (self isClassI
			ifTrue: [self rankOfTenths: (fit at: 1)]
			ifFalse: [self rankOfTenths: (fit at: 1) windows: p size - 8])
		core: (fit at: 2) class: mhcClass!
aucFor: binders against: nonBinders
	"the area under the ROC curve: the chance that a binder chosen at random scores above a non-binder
	chosen at random (ties count half). 1 is perfect, 0.5 is no better than guessing."
	| pos neg wins |
	pos := binders collect: [:p | (self fitFor: p asPeptide) at: 1].
	neg := nonBinders collect: [:p | (self fitFor: p asPeptide) at: 1].
	wins := 0.
	pos do: [:a | neg do: [:b |
		a > b ifTrue: [wins := wins + 2] ifFalse: [a = b ifTrue: [wins := wins + 1]]]].
	^wins / (2.0 * pos size * neg size)! !

!BindingMatrix methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'BindingMatrix('; nextPutAll: name; nextPutAll: ', '; nextPutAll: source; nextPut: $)!
motifString
	"the model as text: for each position the residues that score best, with the size of the effect"
	| s |
	s := WriteStream on: String new.
	s nextPutAll: name; nextPutAll: '  ('; nextPutAll: source; nextPut: $); nl.
	1 to: 9 do: [:p |
		| good |
		good := (self topResidues: 5 at: p) select: [:c | (self cellAt: p residue: c) > 0].
		s nextPutAll: 'P'; print: p; nextPutAll: '  '; nextPutAll: (ImmunoFormat padded: (good isEmpty ifTrue: ['any'] ifFalse: [good]) to: 7);
			nextPutAll: 'range '; nextPutAll: (ImmunoFormat number: (self rangeAt: p) places: 1); nextPutAll: ' bits'; nl].
	^s contents! !

!BindingPrediction class methodsFor: 'instance creation'!
peptide: aPeptide allele: aName tenths: t rank: r core: aCore class: aClass
	^self basicNew setPeptide: aPeptide allele: aName tenths: t rank: r core: aCore class: aClass! !

!BindingPrediction methodsFor: 'private'!
setPeptide: aPeptide allele: aName tenths: t rank: r core: aCore class: aClass
	peptide := aPeptide. allele := aName. tenths := t. rank := r. core := aCore. mhcClass := aClass! !

!BindingPrediction methodsFor: 'accessing'!
peptide
	^peptide!
allele
	"the name of the molecule, as the model knows it"
	^allele!
score
	"the matrix score in bits"
	^tenths / 10.0!
tenths
	^tenths!
rank
	"the percentage of random peptides that would score at least this well; smaller is better"
	^rank!
core
	"the nine residues that sat in the groove ('-' is a gap)"
	^core!
position
	"where the peptide starts in the protein that was scanned, or nil"
	^position!
position: anInteger
	position := anInteger!
endPosition
	^position + peptide size - 1!
strongRank
	"the rank at or below which a peptide is called a strong binder: 1 percent for class I, 2 for class II.
	A trained predictor can use 0.5 for class I; a motif cannot tell a binder from the one random peptide
	in a hundred that happens to fit the anchors, so these models do not claim more"
	^mhcClass = 1 ifTrue: [1.0] ifFalse: [2.0]!
weakRank
	^mhcClass = 1 ifTrue: [5.0] ifFalse: [10.0]!
isStrong
	^rank <= self strongRank!
isBinder
	"a strong or weak binder"
	^rank <= self weakRank!
category
	"#strong, #weak or #nonbinder"
	self isStrong ifTrue: [^#strong].
	self isBinder ifTrue: [^#weak].
	^#nonbinder! !

!BindingPrediction methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: peptide asString; nextPutAll: ' / '; nextPutAll: allele;
		nextPutAll: '  score '; nextPutAll: (ImmunoFormat number: self score places: 1);
		nextPutAll: '  rank '; nextPutAll: (ImmunoFormat number: rank places: 2);
		nextPutAll: '%  '; nextPutAll: self category!
displayString
	^self printString! !
