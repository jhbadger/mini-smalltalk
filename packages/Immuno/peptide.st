"Amino acids and peptides.

AminoAcid has nothing but class-side methods: the twenty residues in the order the BLOSUM matrices use
(A R N D C Q E G H I L K M F P S T W Y V), with their monoisotopic masses, Kyte-Doolittle hydrophobicity,
approximate background frequencies (the composition of a typical protein) and the BLOSUM62 substitution scores.

Peptide is a validated string of those residues. It knows its mass, hydrophobicity and charge, how to cut
itself into overlapping k-mers, and how alike it is to another peptide, which is the question behind
cross-reactivity. ImmunoRandom is a small repeatable random number generator, so that decoy peptides in the
tests and the tutorial come out the same every time."

Error subclass: #ImmunoError instanceVariableNames: '' classVariableNames: '' category: 'Immuno'!
Object subclass: #ImmunoFormat instanceVariableNames: '' classVariableNames: '' category: 'Immuno'!
Object subclass: #AminoAcid instanceVariableNames: '' classVariableNames: 'Order Masses Hydropathy Background Blosum Names' category: 'Immuno-Peptides'!
Object subclass: #Peptide instanceVariableNames: 'sequence' classVariableNames: '' category: 'Immuno-Peptides'!
Object subclass: #ImmunoRandom instanceVariableNames: 'state' classVariableNames: '' category: 'Immuno-Peptides'!

!AminoAcid class methodsFor: 'the residues'!
order
	"the one-letter codes, in BLOSUM order; every table in this package is indexed this way"
	^'ARNDCQEGHILKMFPSTWYV'!
size
	^20!
isResidue: aCharacter
	^(Order ifNil: [Order := self order]) includes: aCharacter!
indexOf: aCharacter
	"1 to 20, or 0 if it is not one of the twenty"
	^self order indexOf: aCharacter!
names
	^Names ifNil: [Names := #('alanine' 'arginine' 'asparagine' 'aspartate' 'cysteine' 'glutamine' 'glutamate'
		'glycine' 'histidine' 'isoleucine' 'leucine' 'lysine' 'methionine' 'phenylalanine' 'proline' 'serine'
		'threonine' 'tryptophan' 'tyrosine' 'valine')]!
nameOf: aCharacter
	^self names at: (self checkedIndex: aCharacter)!
checkedIndex: aCharacter
	| i |
	i := self indexOf: aCharacter.
	i = 0 ifTrue: [^ImmunoError new signal: 'not an amino acid: ', (String with: aCharacter)].
	^i! !

!AminoAcid class methodsFor: 'properties'!
masses
	"monoisotopic residue masses, in daltons"
	^Masses ifNil: [Masses := #(71.03711 156.10111 114.04293 115.02694 103.00919 128.05858 129.04259 57.02146
		137.05891 113.08406 113.08406 128.09496 131.04049 147.06841 97.05276 87.03203 101.04768 186.07931
		163.06333 99.06841)]!
massOf: aCharacter
	^self masses at: (self checkedIndex: aCharacter)!
hydropathy
	"Kyte-Doolittle: positive is hydrophobic"
	^Hydropathy ifNil: [Hydropathy := #(1.8 -4.5 -3.5 -3.5 2.5 -3.5 -3.5 -0.4 -3.2 4.5 3.8 -3.9 1.9 2.8 -1.6
		-0.8 -0.7 -0.9 -1.3 4.2)]!
hydropathyOf: aCharacter
	^self hydropathy at: (self checkedIndex: aCharacter)!
background
	"how often each residue turns up in proteins at large, as a fraction; sums to 1. The binding models
	measure everything against this."
	^Background ifNil: [Background := self normalized: #(8.25 5.53 4.06 5.45 1.37 3.93 6.75 7.07 2.27 5.96 9.66
		5.84 2.42 3.86 4.70 6.56 5.34 1.08 2.92 6.87)]!
normalized: anArray
	| total |
	total := anArray inject: 0 into: [:a :b | a + b].
	^anArray collect: [:x | x / total]!
backgroundOf: aCharacter
	^self background at: (self checkedIndex: aCharacter)!
isHydrophobic: aCharacter
	^(self hydropathyOf: aCharacter) > 1.5!
isBasic: aCharacter
	^'KR' includes: aCharacter!
isAcidic: aCharacter
	^'DE' includes: aCharacter!
isAromatic: aCharacter
	^'FWY' includes: aCharacter! !

!AminoAcid class methodsFor: 'substitution scores'!
blosum62
	"the BLOSUM62 matrix, as an Array of 20 rows in BLOSUM order"
	^Blosum ifNil: [Blosum := #(
		#(4 -1 -2 -2 0 -1 -1 0 -2 -1 -1 -1 -1 -2 -1 1 0 -3 -2 0)
		#(-1 5 0 -2 -3 1 0 -2 0 -3 -2 2 -1 -3 -2 -1 -1 -3 -2 -3)
		#(-2 0 6 1 -3 0 0 0 1 -3 -3 0 -2 -3 -2 1 0 -4 -2 -3)
		#(-2 -2 1 6 -3 0 2 -1 -1 -3 -4 -1 -3 -3 -1 0 -1 -4 -3 -3)
		#(0 -3 -3 -3 9 -3 -4 -3 -3 -1 -1 -3 -1 -2 -3 -1 -1 -2 -2 -1)
		#(-1 1 0 0 -3 5 2 -2 0 -3 -2 1 0 -3 -1 0 -1 -2 -1 -2)
		#(-1 0 0 2 -4 2 5 -2 0 -3 -3 1 -2 -3 -1 0 -1 -3 -2 -2)
		#(0 -2 0 -1 -3 -2 -2 6 -2 -4 -4 -2 -3 -3 -2 0 -2 -2 -3 -3)
		#(-2 0 1 -1 -3 0 0 -2 8 -3 -3 -1 -2 -1 -2 -1 -2 -2 2 -3)
		#(-1 -3 -3 -3 -1 -3 -3 -4 -3 4 2 -3 1 0 -3 -2 -1 -3 -1 3)
		#(-1 -2 -3 -4 -1 -2 -3 -4 -3 2 4 -2 2 0 -3 -2 -1 -2 -1 1)
		#(-1 2 0 -1 -3 1 1 -2 -1 -3 -2 5 -1 -3 -1 0 -1 -3 -2 -2)
		#(-1 -1 -2 -3 -1 0 -2 -3 -2 1 2 -1 5 0 -2 -1 -1 -1 -1 1)
		#(-2 -3 -3 -3 -2 -3 -3 -3 -1 0 0 -3 0 6 -4 -2 -2 1 3 -1)
		#(-1 -2 -2 -1 -3 -1 -1 -2 -2 -3 -3 -1 -2 -4 7 -1 -1 -4 -3 -2)
		#(1 -1 1 0 -1 0 0 0 -1 -2 -2 0 -1 -2 -1 4 1 -3 -2 -2)
		#(0 -1 0 -1 -1 -1 -1 -2 -2 -1 -1 -1 -1 -2 -1 1 5 -2 -2 0)
		#(-3 -3 -4 -4 -2 -2 -3 -2 -2 -3 -2 -3 -1 1 -4 -3 -2 11 2 -3)
		#(-2 -2 -2 -3 -2 -1 -2 -3 2 -1 -1 -2 -1 3 -3 -2 -2 2 7 -1)
		#(0 -3 -3 -3 -1 -2 -2 -3 -3 3 1 -2 1 -1 -2 -2 0 -3 -1 4))]!
blosum: aCharacter with: anotherCharacter
	^((self blosum62 at: (self checkedIndex: aCharacter)) at: (self checkedIndex: anotherCharacter))! !

!Peptide class methodsFor: 'instance creation'!
on: aString
	"a peptide from a string of one-letter codes; case and white space are ignored, anything else that is
	not an amino acid is an error"
	| clean |
	clean := (aString select: [:c | c isSeparator not]) asUppercase.
	clean isEmpty ifTrue: [^ImmunoError new signal: 'a peptide needs at least one residue'].
	clean do: [:c | (AminoAcid isResidue: c) ifFalse: [
		^ImmunoError new signal: 'not an amino acid: ', (String with: c)]].
	^self basicNew setSequence: clean!
isValid: aString
	"true when aString would make a peptide"
	| clean |
	clean := (aString select: [:c | c isSeparator not]) asUppercase.
	^clean notEmpty and: [clean allSatisfy: [:c | AminoAcid isResidue: c]]!
random: n using: aRandom
	"a peptide of n residues drawn from the background composition"
	| s |
	s := WriteStream on: String new.
	n timesRepeat: [s nextPut: (aRandom residue)].
	^self on: s contents! !

!Peptide methodsFor: 'private'!
setSequence: aString
	sequence := aString! !

!Peptide methodsFor: 'accessing'!
asString
	^sequence copy!
size
	^sequence size!
at: i
	"the residue at position i, a Character"
	^sequence at: i!
do: aBlock
	sequence do: aBlock!
first
	^sequence first!
last
	^sequence last!
residues
	^sequence asArray!
copyFrom: start to: stop
	^Peptide on: (sequence copyFrom: start to: stop)!
, aPeptide
	^Peptide on: sequence, aPeptide asString!
asPeptide
	^self!
reversed
	^Peptide on: sequence reversed!
shuffledUsing: aRandom
	"the same residues in a random order: a decoy with the composition of the original"
	| a j t |
	a := sequence asArray copy.
	a size to: 2 by: -1 do: [:i |
		j := aRandom nextInt: i.
		t := a at: i. a at: i put: (a at: j). a at: j put: t].
	^Peptide on: (String withAll: a)! !

!Peptide methodsFor: 'comparing'!
= anObject
	^(anObject isKindOf: Peptide) and: [sequence = anObject asString]!
hash
	^sequence hash! !

!Peptide methodsFor: 'physical properties'!
mass
	"the neutral monoisotopic mass in daltons: the residues plus one water"
	^(sequence inject: 18.01056 into: [:sum :c | sum + (AminoAcid massOf: c)])!
hydropathy
	"the mean Kyte-Doolittle value (GRAVY): positive means hydrophobic"
	^(sequence inject: 0.0 into: [:sum :c | sum + (AminoAcid hydropathyOf: c)]) / sequence size!
netCharge
	"the charge near pH 7 from the side chains alone: +1 for K and R, -1 for D and E, a tenth for H"
	^sequence inject: 0.0 into: [:sum :c |
		sum + (('KR' includes: c) ifTrue: [1.0] ifFalse: [
			('DE' includes: c) ifTrue: [-1.0] ifFalse: [
				c = $H ifTrue: [0.1] ifFalse: [0.0]]])]!
composition
	"a Dictionary from residue to how many times it occurs"
	| d |
	d := Dictionary new.
	sequence do: [:c | d at: c put: (d at: c ifAbsent: [0]) + 1].
	^d!
count: aCharacter
	^sequence occurrencesOf: aCharacter! !

!Peptide methodsFor: 'cutting'!
kmers: k
	"every k-residue piece, in order, as an Array of Peptides"
	| out |
	out := OrderedCollection new.
	1 to: sequence size - k + 1 do: [:i | out add: (self copyFrom: i to: i + k - 1)].
	^out asArray!
windows: k
	"the same as kmers:"
	^self kmers: k!
kmerStrings: k
	| out |
	out := OrderedCollection new.
	1 to: sequence size - k + 1 do: [:i | out add: (sequence copyFrom: i to: i + k - 1)].
	^out asArray! !

!Peptide methodsFor: 'similarity'!
hammingTo: aPeptide
	"how many positions differ; the peptides must be the same length"
	| n |
	self size = aPeptide size ifFalse: [^ImmunoError new signal: 'peptides of different lengths'].
	n := 0.
	1 to: self size do: [:i | (self at: i) = (aPeptide at: i) ifFalse: [n := n + 1]].
	^n!
identityTo: aPeptide
	"the fraction of positions that agree, for peptides of the same length"
	^(self size - (self hammingTo: aPeptide)) / self size!
similarityTo: aPeptide
	"the sum of BLOSUM62 scores down the two peptides, for peptides of the same length: how much
	alike they are as the T cell might see it, with a conservative change costing little"
	| n |
	self size = aPeptide size ifFalse: [^ImmunoError new signal: 'peptides of different lengths'].
	n := 0.
	1 to: self size do: [:i | n := n + (AminoAcid blosum: (self at: i) with: (aPeptide at: i))].
	^n!
normalizedSimilarityTo: aPeptide
	"similarityTo: as a fraction of the best possible, which is each peptide scored against itself (the
	geometric mean of the two); 1 for identical peptides, below 0 for unrelated ones"
	| a b |
	a := self similarityTo: self. b := aPeptide similarityTo: aPeptide.
	^(self similarityTo: aPeptide) / ((a * b) sqrt)! !

!Peptide methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'Peptide('; nextPutAll: sequence; nextPut: $)!
displayString
	^sequence! !

!String methodsFor: '*immuno'!
asPeptide
	^Peptide on: self! !

!ImmunoRandom class methodsFor: 'instance creation'!
seed: anInteger
	^self basicNew setSeed: anInteger!
new
	^self seed: 42! !

!ImmunoRandom methodsFor: 'private'!
setSeed: anInteger
	state := (anInteger abs \\ 2147483646) + 1! !

!ImmunoRandom methodsFor: 'random numbers'!
next
	"a Float in [0,1): the Park-Miller generator, the same sequence for the same seed on every machine"
	state := (state * 16807) \\ 2147483647.
	^(state - 1) / 2147483646.0!
nextInt: n
	"an integer from 1 to n"
	^(self next * n) truncated + 1!
residue
	"a residue chosen with the background frequencies of proteins"
	| r sum |
	r := self next. sum := 0.0.
	1 to: 20 do: [:i |
		sum := sum + ((AminoAcid background) at: i).
		r < sum ifTrue: [^AminoAcid order at: i]].
	^$V! !

!ImmunoFormat class methodsFor: 'numbers'!
number: aNumber places: places
	"3.14159 with 2 places is '3.14'; always shows the places"
	| neg scaled digits text |
	places <= 0 ifTrue: [^aNumber rounded printString].
	neg := aNumber < 0.
	scaled := (aNumber abs * (10 raisedTo: places)) rounded.
	digits := scaled printString.
	[digits size <= places] whileTrue: [digits := '0', digits].
	text := (digits copyFrom: 1 to: digits size - places), '.',
		(digits copyFrom: digits size - places + 1 to: digits size).
	^(neg and: [scaled > 0]) ifTrue: ['-', text] ifFalse: [text]!
percent: aFraction
	^(self number: aFraction * 100 places: 1), '%'!
padded: aString to: n
	"aString on the left of a field n wide"
	^aString size >= n ifTrue: [aString] ifFalse: [aString, (String new: n - aString size withAll: $ )]!
right: aString to: n
	^aString size >= n ifTrue: [aString] ifFalse: [(String new: n - aString size withAll: $ ), aString]! !
