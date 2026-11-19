"Pairwise alignment: Needleman-Wunsch (global) and Smith-Waterman (local), both with affine gap costs, over a
scoring matrix. The dynamic programming needs one cell per pair of residues, so alignments of a few thousand
residues a side are comfortable and whole chromosomes are not."

Object subclass: #ScoringMatrix instanceVariableNames: 'name order scores defaultScore' classVariableNames: 'Blosum62 Nucleotide' category: 'Bio-Alignment'!
Object subclass: #PairwiseAligner instanceVariableNames: 'matrix gapOpen gapExtend' classVariableNames: '' category: 'Bio-Alignment'!
Object subclass: #SequenceAlignment instanceVariableNames: 'first second firstAligned secondAligned score start1 start2 stop1 stop2 matrix kind' classVariableNames: '' category: 'Bio-Alignment'!

"---- scoring matrices ----"

!ScoringMatrix class methodsFor: 'instance creation'!
name: aName order: anOrder rows: rows default: aDefault
	^self basicNew setName: aName order: anOrder rows: rows default: aDefault!
match: matchScore mismatch: mismatchScore
	"the simplest matrix: one score for equal residues and another for different ones"
	| m |
	m := self basicNew setName: 'match ', matchScore printString, '/', mismatchScore printString
		order: '' rows: #() default: mismatchScore.
	m matchScore: matchScore.
	^m!
nucleotide
	"the usual DNA matrix: +5 for a match, -4 for a mismatch, with N scoring 0 against anything"
	^Nucleotide ifNil: [Nucleotide := self
		name: 'NUC'
		order: 'ACGTUN'
		rows: #( #(5 -4 -4 -4 -4 0) #(-4 5 -4 -4 -4 0) #(-4 -4 5 -4 -4 0) #(-4 -4 -4 5 5 0) #(-4 -4 -4 5 5 0) #(0 0 0 0 0 0) )
		default: -4]!
blosum62
	^Blosum62 ifNil: [Blosum62 := self name: 'BLOSUM62' order: 'ARNDCQEGHILKMFPSTWYVBZX*' rows: self blosum62Rows default: -4]!
blosum62Rows
	"the standard NCBI matrix, in the order A R N D C Q E G H I L K M F P S T W Y V B Z X *"
	^#(
	#( 4 -1 -2 -2  0 -1 -1  0 -2 -1 -1 -1 -1 -2 -1  1  0 -3 -2  0 -2 -1  0 -4)
	#(-1  5  0 -2 -3  1  0 -2  0 -3 -2  2 -1 -3 -2 -1 -1 -3 -2 -3 -1  0 -1 -4)
	#(-2  0  6  1 -3  0  0  0  1 -3 -3  0 -2 -3 -2  1  0 -4 -2 -3  3  0 -1 -4)
	#(-2 -2  1  6 -3  0  2 -1 -1 -3 -4 -1 -3 -3 -1  0 -1 -4 -3 -3  4  1 -1 -4)
	#( 0 -3 -3 -3  9 -3 -4 -3 -3 -1 -1 -3 -1 -2 -3 -1 -1 -2 -2 -1 -3 -3 -2 -4)
	#(-1  1  0  0 -3  5  2 -2  0 -3 -2  1  0 -3 -1  0 -1 -2 -1 -2  0  3 -1 -4)
	#(-1  0  0  2 -4  2  5 -2  0 -3 -3  1 -2 -3 -1  0 -1 -3 -2 -2  1  4 -1 -4)
	#( 0 -2  0 -1 -3 -2 -2  6 -2 -4 -4 -2 -3 -3 -2  0 -2 -2 -3 -3 -1 -2 -1 -4)
	#(-2  0  1 -1 -3  0  0 -2  8 -3 -3 -1 -2 -1 -2 -1 -2 -2  2 -3  0  0 -1 -4)
	#(-1 -3 -3 -3 -1 -3 -3 -4 -3  4  2 -3  1  0 -3 -2 -1 -3 -1  3 -3 -3 -1 -4)
	#(-1 -2 -3 -4 -1 -2 -3 -4 -3  2  4 -2  2  0 -3 -2 -1 -2 -1  1 -4 -3 -1 -4)
	#(-1  2  0 -1 -3  1  1 -2 -1 -3 -2  5 -1 -3 -1  0 -1 -3 -2 -2  0  1 -1 -4)
	#(-1 -1 -2 -3 -1  0 -2 -3 -2  1  2 -1  5  0 -2 -1 -1 -1 -1  1 -3 -1 -1 -4)
	#(-2 -3 -3 -3 -2 -3 -3 -3 -1  0  0 -3  0  6 -4 -2 -2  1  3 -1 -3 -3 -1 -4)
	#(-1 -2 -2 -1 -3 -1 -1 -2 -2 -3 -3 -1 -2 -4  7 -1 -1 -4 -3 -2 -2 -1 -2 -4)
	#( 1 -1  1  0 -1  0  0  0 -1 -2 -2  0 -1 -2 -1  4  1 -3 -2 -2  0  0  0 -4)
	#( 0 -1  0 -1 -1 -1 -1 -2 -2 -1 -1 -1 -1 -2 -1  1  5 -2 -2  0 -1 -1  0 -4)
	#(-3 -3 -4 -4 -2 -2 -3 -2 -2 -3 -2 -3 -1  1 -4 -3 -2 11  2 -3 -4 -3 -2 -4)
	#(-2 -2 -2 -3 -2 -1 -2 -3  2 -1 -1 -2 -1  3 -3 -2 -2  2  7 -1 -3 -2 -1 -4)
	#( 0 -3 -3 -3 -1 -2 -2 -3 -3  3  1 -2  1 -1 -2 -2  0 -3 -1  4 -3 -2 -1 -4)
	#(-2 -1  3  4 -3  0  1 -1  0 -3 -4  0 -3 -3 -2  0 -1 -4 -3 -3  4  1 -1 -4)
	#(-1  0  0  1 -3  3  4 -2  0 -3 -3  1 -1 -3 -1  0 -1 -3 -2 -2  1  4 -1 -4)
	#( 0 -1 -1 -1 -2 -1 -1 -1 -1 -1 -1 -1 -1 -1 -2  0  0 -2 -1 -1 -1 -1 -1 -4)
	#(-4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4  1) )!
named: aString
	| n |
	n := aString asLowercase.
	n = 'blosum62' ifTrue: [^self blosum62].
	(n = 'nuc' or: [n = 'nucleotide' or: [n = 'dna']]) ifTrue: [^self nucleotide].
	n = 'identity' ifTrue: [^self match: 1 mismatch: 0].
	^BioError new signal: 'no scoring matrix named ', aString! !

!ScoringMatrix methodsFor: 'private'!
setName: aName order: anOrder rows: rows default: aDefault
	| n table |
	name := aName. order := anOrder. defaultScore := aDefault.
	n := anOrder size.
	table := Array new: 256 * 256 withAll: nil.
	1 to: n do: [:i |
		1 to: n do: [:j |
			| a b v |
			a := anOrder at: i. b := anOrder at: j. v := (rows at: i) at: j.
			table at: a value * 256 + b value + 1 put: v.
			table at: a asLowercase value * 256 + b value + 1 put: v.
			table at: a value * 256 + b asLowercase value + 1 put: v.
			table at: a asLowercase value * 256 + b asLowercase value + 1 put: v]].
	scores := table!
matchScore: aNumber
	"used by the match/mismatch matrix, which has no table"
	order := nil.
	scores := aNumber! !

!ScoringMatrix methodsFor: 'accessing'!
name
	^name!
order
	^order!
defaultScore
	^defaultScore!
scoreFor: aCharacter and: anotherCharacter
	| v |
	order isNil ifTrue: [^aCharacter asUppercase = anotherCharacter asUppercase ifTrue: [scores] ifFalse: [defaultScore]].
	(aCharacter value < 256 and: [anotherCharacter value < 256]) ifFalse: [^defaultScore].
	v := scores at: aCharacter value * 256 + anotherCharacter value + 1.
	^v ifNil: [defaultScore]!
printOn: aStream
	aStream nextPutAll: 'ScoringMatrix('; nextPutAll: name; nextPut: $)! !

"---- the aligner ----"

!PairwiseAligner class methodsFor: 'instance creation'!
matrix: aMatrix gapOpen: anOpen gapExtend: anExtend
	"the gap costs are positive numbers: opening a gap costs anOpen, each further residue anExtend"
	^self basicNew setMatrix: aMatrix gapOpen: anOpen gapExtend: anExtend!
protein
	^self matrix: ScoringMatrix blosum62 gapOpen: 11 gapExtend: 1!
dna
	^self matrix: ScoringMatrix nucleotide gapOpen: 10 gapExtend: 1!
for: aSequence
	^aSequence isProtein ifTrue: [self protein] ifFalse: [self dna]! !

!PairwiseAligner methodsFor: 'private'!
setMatrix: aMatrix gapOpen: anOpen gapExtend: anExtend
	matrix := aMatrix. gapOpen := anOpen. gapExtend := anExtend!
gapOpen: n
	gapOpen := n!
gapExtend: n
	gapExtend := n! !

!PairwiseAligner methodsFor: 'accessing'!
matrix
	^matrix!
matrix: aMatrix
	matrix := aMatrix!
gapOpen
	^gapOpen!
gapExtend
	^gapExtend! !

!PairwiseAligner methodsFor: 'aligning'!
align: a with: b
	"a global alignment (Needleman-Wunsch)"
	^self align: a with: b local: false!
globalAlign: a with: b
	^self align: a with: b local: false!
localAlign: a with: b
	"the best-scoring pair of subsequences (Smith-Waterman)"
	^self align: a with: b local: true!
align: a with: b local: isLocal
	"Gotoh's algorithm: three matrices (match, gap in b, gap in a) so that a run of gaps costs
	gapOpen once and gapExtend for each further residue."
	| s1 s2 n m inf mScore xScore yScore mFrom xFrom yFrom width best bestI bestJ |
	s1 := a asString. s2 := b asString.
	n := s1 size. m := s2 size.
	(n + 1) * (m + 1) > 16000000 ifTrue: [^BioError new signal: 'the sequences are too long to align: ', n printString, ' x ', m printString].
	inf := -1000000000.
	width := m + 1.
	mScore := Array new: (n + 1) * width withAll: inf.
	xScore := Array new: (n + 1) * width withAll: inf.
	yScore := Array new: (n + 1) * width withAll: inf.
	mFrom := Array new: (n + 1) * width withAll: 0.
	xFrom := Array new: (n + 1) * width withAll: 0.
	yFrom := Array new: (n + 1) * width withAll: 0.
	mScore at: 1 put: 0.
	isLocal ifFalse: [
		1 to: n do: [:i | xScore at: i * width + 1 put: (gapOpen + (i - 1 * gapExtend)) negated].
		1 to: m do: [:j | yScore at: j + 1 put: (gapOpen + (j - 1 * gapExtend)) negated]].
	best := isLocal ifTrue: [0] ifFalse: [inf].
	bestI := 0. bestJ := 0.
	1 to: n do: [:i |
		1 to: m do: [:j |
			| here prev sc bm bx by v |
			here := i * width + j + 1.
			prev := (i - 1) * width + j.
			"match or mismatch"
			sc := matrix scoreFor: (s1 at: i) and: (s2 at: j).
			bm := mScore at: prev. bx := xScore at: prev. by := yScore at: prev.
			v := bm. mFrom at: here put: 1.
			bx > v ifTrue: [v := bx. mFrom at: here put: 2].
			by > v ifTrue: [v := by. mFrom at: here put: 3].
			v := v + sc.
			(isLocal and: [v < 0]) ifTrue: [v := 0. mFrom at: here put: 0].
			mScore at: here put: v.
			"a gap in the second sequence: s1 at: i against nothing"
			prev := (i - 1) * width + j + 1.
			bm := (mScore at: prev) - gapOpen. bx := (xScore at: prev) - gapExtend. by := (yScore at: prev) - gapOpen.
			v := bm. xFrom at: here put: 1.
			bx > v ifTrue: [v := bx. xFrom at: here put: 2].
			by > v ifTrue: [v := by. xFrom at: here put: 3].
			xScore at: here put: v.
			"a gap in the first sequence"
			prev := i * width + j.
			bm := (mScore at: prev) - gapOpen. bx := (xScore at: prev) - gapOpen. by := (yScore at: prev) - gapExtend.
			v := bm. yFrom at: here put: 1.
			bx > v ifTrue: [v := bx. yFrom at: here put: 2].
			by > v ifTrue: [v := by. yFrom at: here put: 3].
			yScore at: here put: v.
			(isLocal and: [(mScore at: here) > best]) ifTrue: [best := mScore at: here. bestI := i. bestJ := j]]].
	isLocal ifFalse: [
		bestI := n. bestJ := m.
		best := mScore at: n * width + m + 1.
		(xScore at: n * width + m + 1) > best ifTrue: [best := xScore at: n * width + m + 1].
		(yScore at: n * width + m + 1) > best ifTrue: [best := yScore at: n * width + m + 1]].
	^self traceback: (Array with: mScore with: xScore with: yScore)
		from: (Array with: mFrom with: xFrom with: yFrom)
		width: width best: best at: bestI and: bestJ
		sequences: (Array with: a with: b) local: isLocal!
traceback: scoreArrays from: fromArrays width: width best: best at: bestI and: bestJ sequences: seqs local: isLocal
	| mScore xScore yScore mFrom xFrom yFrom i j state out1 out2 s1 s2 alignment here stop1 stop2 |
	mScore := scoreArrays at: 1. xScore := scoreArrays at: 2. yScore := scoreArrays at: 3.
	mFrom := fromArrays at: 1. xFrom := fromArrays at: 2. yFrom := fromArrays at: 3.
	s1 := (seqs at: 1) asString. s2 := (seqs at: 2) asString.
	out1 := WriteStream on: String new.
	out2 := WriteStream on: String new.
	i := bestI. j := bestJ.
	stop1 := i. stop2 := j.
	state := 1.
	isLocal ifFalse: [
		here := i * width + j + 1.
		state := 1.
		((xScore at: here) >= (mScore at: here) and: [(xScore at: here) >= (yScore at: here)]) ifTrue: [state := 2].
		((yScore at: here) > (mScore at: here) and: [(yScore at: here) > (xScore at: here)]) ifTrue: [state := 3]].
	[(i > 0 or: [j > 0]) and: [isLocal not or: [i > 0 and: [j > 0]]]] whileTrue: [
		here := i * width + j + 1.
		(isLocal and: [state = 1 and: [(mScore at: here) <= 0]]) ifTrue: [
			^self alignmentOf: seqs first: out1 second: out2 score: best
				from: i + 1 and: j + 1 to: stop1 and: stop2 local: isLocal].
		(i = 0 or: [j = 0])
			ifTrue: [
				i > 0
					ifTrue: [out1 nextPut: (s1 at: i). out2 nextPut: $-. i := i - 1]
					ifFalse: [out1 nextPut: $-. out2 nextPut: (s2 at: j). j := j - 1]]
			ifFalse: [
				state = 1
					ifTrue: [
						out1 nextPut: (s1 at: i). out2 nextPut: (s2 at: j).
						state := mFrom at: here.
						i := i - 1. j := j - 1]
					ifFalse: [
						state = 2
							ifTrue: [
								out1 nextPut: (s1 at: i). out2 nextPut: $-.
								state := xFrom at: here.
								i := i - 1]
							ifFalse: [
								out1 nextPut: $-. out2 nextPut: (s2 at: j).
								state := yFrom at: here.
								j := j - 1]]]].
	^self alignmentOf: seqs first: out1 second: out2 score: best
		from: i + 1 and: j + 1 to: stop1 and: stop2 local: isLocal!
alignmentOf: seqs first: out1 second: out2 score: best from: from1 and: from2 to: to1 and: to2 local: isLocal
	| a |
	a := SequenceAlignment new.
	a setFirst: (seqs at: 1) second: (seqs at: 2)
		firstAligned: out1 contents reversed secondAligned: out2 contents reversed
		score: best start: from1 and: from2 stop: to1 and: to2
		matrix: matrix kind: (isLocal ifTrue: [#local] ifFalse: [#global]).
	^a! !

"---- the result ----"

!SequenceAlignment methodsFor: 'private'!
setFirst: a second: b firstAligned: fa secondAligned: sa score: aScore start: s1 and: s2 stop: e1 and: e2 matrix: aMatrix kind: aSymbol
	first := a. second := b. firstAligned := fa. secondAligned := sa.
	score := aScore. start1 := s1. start2 := s2. stop1 := e1. stop2 := e2.
	matrix := aMatrix. kind := aSymbol! !

!SequenceAlignment methodsFor: 'accessing'!
first
	^first!
second
	^second!
firstAligned
	"the first sequence with gap characters, as a String"
	^firstAligned!
secondAligned
	^secondAligned!
score
	^score!
kind
	^kind!
matrix
	^matrix!
start1
	"where the alignment starts in the first sequence (1-based)"
	^start1!
start2
	^start2!
stop1
	^stop1!
stop2
	^stop2!
size
	^firstAligned size! !

!SequenceAlignment methodsFor: 'measuring'!
identities
	"how many columns hold the same residue"
	| n |
	n := 0.
	1 to: firstAligned size do: [:i |
		((firstAligned at: i) asUppercase = (secondAligned at: i) asUppercase and: [(firstAligned at: i) ~= $-])
			ifTrue: [n := n + 1]].
	^n!
identityPercent
	^firstAligned isEmpty ifTrue: [0.0] ifFalse: [self identities * 100.0 / firstAligned size]!
positives
	"columns whose pair scores above zero in the matrix"
	| n |
	n := 0.
	1 to: firstAligned size do: [:i |
		| a b |
		a := firstAligned at: i. b := secondAligned at: i.
		(a ~= $- and: [b ~= $- and: [(matrix scoreFor: a and: b) > 0]]) ifTrue: [n := n + 1]].
	^n!
positivePercent
	^firstAligned isEmpty ifTrue: [0.0] ifFalse: [self positives * 100.0 / firstAligned size]!
gaps
	| n |
	n := 0.
	firstAligned do: [:c | c = $- ifTrue: [n := n + 1]].
	secondAligned do: [:c | c = $- ifTrue: [n := n + 1]].
	^n!
gapPercent
	^firstAligned isEmpty ifTrue: [0.0] ifFalse: [self gaps * 100.0 / (firstAligned size * 2)]!
matchLine
	"| for identical residues, : for a positive score, a space otherwise"
	| out |
	out := WriteStream on: (String new: firstAligned size).
	1 to: firstAligned size do: [:i |
		| a b |
		a := firstAligned at: i. b := secondAligned at: i.
		(a = $- or: [b = $-])
			ifTrue: [out nextPut: $ ]
			ifFalse: [
				a asUppercase = b asUppercase
					ifTrue: [out nextPut: $|]
					ifFalse: [out nextPut: ((matrix scoreFor: a and: b) > 0 ifTrue: [$:] ifFalse: [$ ])]]].
	^out contents! !

!SequenceAlignment methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'SequenceAlignment('; nextPutAll: kind asString; nextPutAll: ', score '; print: score;
		nextPutAll: ', '; nextPutAll: (self identityPercent printShowingDecimalPlaces: 1); nextPutAll: '% identity)'!
report
	^self reportWrappedAt: 60!
reportWrappedAt: width
	"the alignment in blocks, with position numbers and a match line between the rows"
	| out match i n p1 p2 a b label1 label2 labelWidth |
	out := WriteStream on: String new.
	out nextPutAll: kind asString; nextPutAll: ' alignment, score '; print: score;
		nextPutAll: ', '; print: self identities; nextPut: $/; print: firstAligned size;
		nextPutAll: ' identical ('; nextPutAll: (self identityPercent printShowingDecimalPlaces: 1); nextPutAll: '%), ';
		print: self gaps; nextPutAll: ' gaps'; nl; nl.
	match := self matchLine.
	label1 := self labelFor: first default: 'seq1'.
	label2 := self labelFor: second default: 'seq2'.
	labelWidth := label1 size max: label2 size.
	p1 := start1. p2 := start2.
	i := 1. n := firstAligned size.
	[i <= n] whileTrue: [
		| stop part1 part2 used1 used2 |
		stop := i + width - 1 min: n.
		part1 := firstAligned copyFrom: i to: stop.
		part2 := secondAligned copyFrom: i to: stop.
		used1 := (part1 reject: [:c | c = $-]) size.
		used2 := (part2 reject: [:c | c = $-]) size.
		out nextPutAll: (label1, (String new: labelWidth - label1 size + 1 withAll: $ ));
			nextPutAll: (p1 printPaddedWith: $  to: 6); nextPut: $ ; nextPutAll: part1;
			nextPut: $ ; print: (used1 = 0 ifTrue: [p1] ifFalse: [p1 + used1 - 1]); nl.
		out nextPutAll: (String new: labelWidth + 8 withAll: $ ); nextPutAll: (match copyFrom: i to: stop); nl.
		out nextPutAll: (label2, (String new: labelWidth - label2 size + 1 withAll: $ ));
			nextPutAll: (p2 printPaddedWith: $  to: 6); nextPut: $ ; nextPutAll: part2;
			nextPut: $ ; print: (used2 = 0 ifTrue: [p2] ifFalse: [p2 + used2 - 1]); nl; nl.
		p1 := p1 + used1. p2 := p2 + used2.
		i := stop + 1].
	^out contents!
labelFor: aSequence default: aString
	(aSequence isKindOf: SeqRecord) ifTrue: [^aSequence id].
	^aString! !

"---- convenient entry points on the sequences themselves ----"

!BioSequence methodsFor: 'aligning'!
alignWith: aSequence
	"a global alignment with the usual costs for this kind of sequence"
	^(PairwiseAligner for: self) align: self with: aSequence!
localAlignWith: aSequence
	^(PairwiseAligner for: self) localAlign: self with: aSequence!
identityWith: aSequence
	"the percentage of identical columns in a global alignment"
	^(self alignWith: aSequence) identityPercent! !
