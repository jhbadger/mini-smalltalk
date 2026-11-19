"Genetic codes, in the form NCBI publishes them: a 64-character string of amino acids and a 64-character string marking
the start codons, both in the codon order TTT TTC TTA TTG TCT ... GGG (base 1, then base 2, then base 3, each T C A G).
Codons holding IUPAC ambiguity codes translate to the amino acid they all agree on, or to X."

Object subclass: #GeneticCode instanceVariableNames: 'id name aminoAcids starts cache' classVariableNames: 'Codes Order' category: 'Bio-Sequences'!

!GeneticCode class methodsFor: 'instance creation'!
id: anInteger
	"the NCBI translation table with this number"
	^self codes at: anInteger ifAbsent: [BioError new signal: 'there is no genetic code ', anInteger printString]!
named: aString
	| lower |
	lower := aString asLowercase.
	^self codes detect: [:c | c name asLowercase = lower] ifNone: [
		self codes detect: [:c | c name asLowercase includesSubstring: lower] ifNone: [
			BioError new signal: 'no genetic code named ', aString]]!
standard
	^self id: 1!
bacterial
	^self id: 11!
vertebrateMitochondrial
	^self id: 2!
default
	^self standard!
codes
	Codes isNil ifTrue: [self initializeCodes].
	^Codes!
ids
	^self codes keys asSortedCollection asArray!
id: anInteger name: aString aminoAcids: aa starts: st
	| c |
	c := self basicNew setId: anInteger name: aString aminoAcids: aa starts: st.
	Codes at: anInteger put: c.
	^c! !

!GeneticCode class methodsFor: 'codon order'!
codonOrder
	"the 64 codons in NCBI table order"
	| bases out |
	Order notNil ifTrue: [^Order].
	bases := 'TCAG'.
	out := OrderedCollection new.
	bases do: [:a | bases do: [:b | bases do: [:c | out add: (String with: a with: b with: c)]]].
	^Order := out asArray!
indexOfBase: aCharacter
	"0 for T or U, 1 for C, 2 for A, 3 for G, nil for anything else"
	aCharacter == $T ifTrue: [^0].
	aCharacter == $U ifTrue: [^0].
	aCharacter == $C ifTrue: [^1].
	aCharacter == $A ifTrue: [^2].
	aCharacter == $G ifTrue: [^3].
	^nil! !

!GeneticCode class methodsFor: 'tables'!
initializeCodes
	Codes := Dictionary new.
	self id: 1 name: 'Standard'
		aminoAcids: 'FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '---M------**--*----M---------------M----------------------------'.
	self id: 2 name: 'Vertebrate Mitochondrial'
		aminoAcids: 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG'
		starts:     '----------**--------------------MMMM----------------------------'.
	self id: 3 name: 'Yeast Mitochondrial'
		aminoAcids: 'FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '----------**----------------------MM---------------M------------'.
	self id: 4 name: 'Mold Mitochondrial'
		aminoAcids: 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '--MM------**-------M------------MMMM---------------M------------'.
	self id: 5 name: 'Invertebrate Mitochondrial'
		aminoAcids: 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG'
		starts:     '---M------**--------------------MMMM---------------M------------'.
	self id: 6 name: 'Ciliate Nuclear'
		aminoAcids: 'FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '--------------*--------------------M----------------------------'.
	self id: 9 name: 'Echinoderm Mitochondrial'
		aminoAcids: 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG'
		starts:     '----------**-----------------------M---------------M------------'.
	self id: 10 name: 'Euplotid Nuclear'
		aminoAcids: 'FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '----------**-----------------------M----------------------------'.
	self id: 11 name: 'Bacterial'
		aminoAcids: 'FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '---M------**--*----M------------MMMM---------------M------------'.
	self id: 12 name: 'Alternative Yeast Nuclear'
		aminoAcids: 'FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '----------**--*----M---------------M----------------------------'.
	self id: 13 name: 'Ascidian Mitochondrial'
		aminoAcids: 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG'
		starts:     '---M------**----------------------MM---------------M------------'.
	self id: 14 name: 'Alternative Flatworm Mitochondrial'
		aminoAcids: 'FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG'
		starts:     '-----------*-----------------------M----------------------------'.
	self id: 16 name: 'Chlorophycean Mitochondrial'
		aminoAcids: 'FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '----------*---*--------------------M----------------------------'.
	self id: 21 name: 'Trematode Mitochondrial'
		aminoAcids: 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG'
		starts:     '----------**-----------------------M---------------M------------'.
	self id: 22 name: 'Scenedesmus obliquus Mitochondrial'
		aminoAcids: 'FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '------*---*---*--------------------M----------------------------'.
	self id: 23 name: 'Thraustochytrium Mitochondrial'
		aminoAcids: 'FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '--*-------**--*-----------------M--M---------------M------------'.
	self id: 24 name: 'Rhabdopleuridae Mitochondrial'
		aminoAcids: 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG'
		starts:     '---M------**-------M---------------M---------------M------------'.
	self id: 25 name: 'Candidate Division SR1'
		aminoAcids: 'FFLLSSSSYY**CCGWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '---M------**-----------------------M---------------M------------'.
	self id: 26 name: 'Pachysolen tannophilus Nuclear'
		aminoAcids: 'FFLLSSSSYY**CC*WLLLAPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'
		starts:     '----------**--*----M---------------M----------------------------'.
	^Codes! !

!GeneticCode methodsFor: 'private'!
setId: anInteger name: aString aminoAcids: aa starts: st
	aa size = 64 ifFalse: [^BioError new signal: 'genetic code ', anInteger printString, ' needs 64 amino acids'].
	st size = 64 ifFalse: [^BioError new signal: 'genetic code ', anInteger printString, ' needs 64 start flags'].
	id := anInteger. name := aString. aminoAcids := aa. starts := st. cache := Dictionary new!
indexOfCodon: aString
	"the 0-based position of an unambiguous codon in the table, or nil"
	| n b |
	aString size = 3 ifFalse: [^nil].
	n := 0.
	1 to: 3 do: [:i |
		b := GeneticCode indexOfBase: (aString at: i) asUppercase.
		b isNil ifTrue: [^nil].
		n := n * 4 + b].
	^n! !

!GeneticCode methodsFor: 'accessing'!
id
	^id!
name
	^name!
aminoAcids
	^aminoAcids!
startFlags
	^starts!
printOn: aStream
	aStream nextPutAll: 'GeneticCode '; print: id; nextPutAll: ' ('; nextPutAll: name; nextPut: $)! !

!GeneticCode methodsFor: 'codons'!
aminoAcidFor: aCodon
	"the amino acid of a three-letter codon as a Character; X when ambiguity leaves it open, and nil when the codon is not three bases"
	| codon i aa |
	codon := aCodon asString asUppercase.
	codon size = 3 ifFalse: [^nil].
	i := self indexOfCodon: codon.
	i notNil ifTrue: [^aminoAcids at: i + 1].
	aa := cache at: codon ifAbsent: [nil].
	aa notNil ifTrue: [^aa].
	aa := self ambiguousAminoAcidFor: codon.
	cache at: codon put: aa.
	^aa!
ambiguousAminoAcidFor: codon
	"the amino acid every base the ambiguity codes allow would give, or X"
	| options all found |
	options := codon asArray collect: [:c | BioIUPAC basesFor: c].
	(options anySatisfy: [:o | o isEmpty]) ifTrue: [^$X].
	found := nil.
	(options at: 1) do: [:a |
		(options at: 2) do: [:b |
			(options at: 3) do: [:c |
				| aa |
				aa := aminoAcids at: (self indexOfCodon: (String with: a with: b with: c)) + 1.
				found isNil ifTrue: [found := aa] ifFalse: [found = aa ifFalse: [^$X]]]]].
	^found ifNil: [$X]!
isStartCodon: aCodon
	| i |
	i := self indexOfCodon: aCodon asString asUppercase.
	^i notNil and: [(starts at: i + 1) = $M]!
isStopCodon: aCodon
	^(self aminoAcidFor: aCodon) = $*!
startCodons
	| r |
	r := OrderedCollection new.
	GeneticCode codonOrder doWithIndex: [:c :i | (starts at: i) = $M ifTrue: [r add: c]].
	^r asArray!
stopCodons
	| r |
	r := OrderedCollection new.
	GeneticCode codonOrder doWithIndex: [:c :i | (aminoAcids at: i) = $* ifTrue: [r add: c]].
	^r asArray!
codonsFor: anAminoAcid
	"every codon that gives this amino acid"
	| aa r |
	aa := anAminoAcid asString first asUppercase.
	r := OrderedCollection new.
	GeneticCode codonOrder doWithIndex: [:c :i | (aminoAcids at: i) = aa ifTrue: [r add: c]].
	^r asArray! !

!GeneticCode methodsFor: 'translating'!
translate: aSequence
	"the protein of the whole (reading-frame 1) sequence; a trailing partial codon is ignored"
	^self translate: aSequence from: 1!
translate: aSequence from: start
	| s out n |
	s := aSequence asString.
	out := WriteStream on: (String new: s size // 3 + 1).
	n := start.
	[n + 2 <= s size] whileTrue: [
		out nextPut: ((self aminoAcidFor: (s copyFrom: n to: n + 2)) ifNil: [$X]).
		n := n + 3].
	^ProteinSequence raw: out contents!
translate: aSequence toStop: aBoolean
	| p i |
	p := self translate: aSequence.
	aBoolean ifFalse: [^p].
	i := p asString indexOf: $*.
	^i = 0 ifTrue: [p] ifFalse: [ProteinSequence raw: (p asString copyFrom: 1 to: i - 1)]! !

"---- translating a nucleotide sequence ----"

!NucleotideSequence methodsFor: 'translating'!
translate
	"the protein of reading frame 1, with the standard genetic code"
	^GeneticCode standard translate: self!
translateWith: aGeneticCode
	^aGeneticCode translate: self!
translateToStop
	^GeneticCode standard translate: self toStop: true!
translateFrame: n
	"frames 1, 2 and 3 read the sequence as given; -1, -2 and -3 read the reverse complement"
	^self translateFrame: n with: GeneticCode standard!
translateFrame: n with: aGeneticCode
	| s |
	(n between: 1 and: 3) ifTrue: [^aGeneticCode translate: self from: n].
	(n between: -3 and: -1) ifTrue: [
		s := self reverseComplement.
		^aGeneticCode translate: s from: n negated].
	^BioError new signal: 'reading frame must be 1, 2, 3, -1, -2 or -3'!
sixFrameTranslations
	^self sixFrameTranslationsWith: GeneticCode standard!
sixFrameTranslationsWith: aGeneticCode
	"the six translations as an Array of Associations frame -> ProteinSequence"
	^(#(1 2 3 -1 -2 -3) collect: [:f | f -> (self translateFrame: f with: aGeneticCode)]) asArray! !
