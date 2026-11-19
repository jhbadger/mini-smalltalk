"Analysis: open reading frames and codon usage, physical properties, pattern search with IUPAC ambiguity codes,
k-mer profiles and restriction enzymes."

Object subclass: #RestrictionEnzyme instanceVariableNames: 'name site cut' classVariableNames: 'Enzymes' category: 'Bio-Analysis'!

"---- open reading frames ----"

!NucleotideSequence methodsFor: 'open reading frames'!
orfs
	"every open reading frame of at least 30 bases on both strands, as SeqFeatures keyed 'ORF'"
	^self orfsLongerThan: 30!
orfsLongerThan: minimumBases
	^self orfsLongerThan: minimumBases code: GeneticCode standard requireStart: true bothStrands: true!
orfsLongerThan: minimumBases code: aCode requireStart: needStart bothStrands: both
	"Reading frames 1..3 (and -1..-3 when both strands are wanted). An ORF runs from a start codon (or from the
	beginning of the frame when needStart is false) to the first stop codon. Locations are on the given sequence,
	so an ORF on the minus strand is a complement(...) location and its bases read in the right direction."
	| result frames |
	result := OrderedCollection new.
	frames := both ifTrue: [#(1 2 3 -1 -2 -3)] ifFalse: [#(1 2 3)].
	frames do: [:f | self orfsInFrame: f code: aCode requireStart: needStart longerThan: minimumBases into: result].
	^(result asSortedCollection: [:a :b | a start = b start ifTrue: [a stop >= b stop] ifFalse: [a start < b start]]) asArray!
orfsInFrame: frame code: aCode requireStart: needStart longerThan: minimumBases into: result
	| strandSeq n i codon start length feature location from to |
	strandSeq := frame < 0 ifTrue: [self reverseComplement asString] ifFalse: [self asString].
	n := strandSeq size.
	i := frame abs.
	start := needStart ifTrue: [nil] ifFalse: [i].
	[i + 2 <= n] whileTrue: [
		codon := strandSeq copyFrom: i to: i + 2.
		(start isNil and: [aCode isStartCodon: codon]) ifTrue: [start := i].
		(start notNil and: [aCode isStopCodon: codon]) ifTrue: [
			length := i + 2 - start + 1.
			length >= minimumBases ifTrue: [
				from := start. to := i + 2.
				location := frame < 0
					ifTrue: [SeqLocation from: n - to + 1 to: n - from + 1 strand: -1]
					ifFalse: [SeqLocation from: from to: to strand: 1].
				feature := SeqFeature key: 'ORF' location: location.
				feature addQualifier: 'frame' value: frame.
				feature addQualifier: 'length' value: length.
				feature addQualifier: 'translation' value: (aCode translate: (DNASequence raw: (strandSeq copyFrom: from to: to)) toStop: true) asString.
				result add: feature].
			start := needStart ifTrue: [nil] ifFalse: [i + 3]].
		i := i + 3].
	^result!
longestOrf
	"the longest open reading frame, or nil when there is none"
	| best |
	best := nil.
	self orfsLongerThan: 1 do: [:f | (best isNil or: [f size > best size]) ifTrue: [best := f]].
	^best!
orfsLongerThan: minimumBases do: aBlock
	(self orfsLongerThan: minimumBases) do: aBlock! !

!NucleotideSequence methodsFor: 'codon usage'!
codons
	"the sequence as an Array of three-letter Strings, reading frame 1"
	| s out i |
	s := self upper.
	out := OrderedCollection new.
	i := 1.
	[i + 2 <= s size] whileTrue: [out add: (s copyFrom: i to: i + 2). i := i + 3].
	^out asArray!
codonUsage
	"a Dictionary from codon to how often it appears in reading frame 1"
	| d |
	d := Dictionary new.
	self codons do: [:c | d at: c put: (d at: c ifAbsent: [0]) + 1].
	^d!
codonUsageReport
	^self codonUsageReportWith: GeneticCode standard!
codonUsageReportWith: aCode
	"codons grouped by the amino acid they encode, with counts and the share within each amino acid"
	| usage byAa out total |
	usage := self codonUsage.
	total := 0.
	usage valuesDo: [:v | total := total + v].
	byAa := Dictionary new.
	usage keysAndValuesDo: [:codon :count |
		| aa |
		aa := (aCode aminoAcidFor: codon) ifNil: [$X].
		(byAa at: aa ifAbsentPut: [OrderedCollection new]) add: codon -> count].
	out := WriteStream on: String new.
	out nextPutAll: 'codon usage over '; print: total; nextPutAll: ' codons'; nl.
	(byAa keys asSortedCollection) do: [:aa |
		| group sum |
		group := byAa at: aa.
		sum := group inject: 0 into: [:a :p | a + p value].
		out nextPut: aa; nextPutAll: '  '.
		(group asSortedCollection: [:a :b | a value = b value ifTrue: [a key <= b key] ifFalse: [a value > b value]]) do: [:p |
			out nextPutAll: p key; nextPut: $ ; print: p value;
				nextPutAll: ' ('; nextPutAll: (p value * 100.0 / sum printShowingDecimalPlaces: 1); nextPutAll: '%) '].
		out nl].
	^out contents! !

"---- physical properties ----"

!NucleotideSequence methodsFor: 'physical properties'!
meltingTemperature
	"an estimate in degrees Celsius: the Wallace rule below 14 bases, the GC formula above it"
	| a t g c n |
	a := self upper occurrencesOf: $A.
	t := (self upper occurrencesOf: $T) + (self upper occurrencesOf: $U).
	g := self upper occurrencesOf: $G.
	c := self upper occurrencesOf: $C.
	n := a + t + g + c.
	n = 0 ifTrue: [^0.0].
	n < 14 ifTrue: [^(2 * (a + t) + (4 * (g + c))) asFloat].
	^64.9 + (41.0 * (g + c - 16.4) / n)!
molecularWeight
	"the average mass of the single strand, in daltons"
	| a t g c u n |
	a := self upper occurrencesOf: $A.
	t := self upper occurrencesOf: $T.
	u := self upper occurrencesOf: $U.
	g := self upper occurrencesOf: $G.
	c := self upper occurrencesOf: $C.
	n := a + t + g + c + u.
	n = 0 ifTrue: [^0.0].
	self isRNA
		ifTrue: [^(a * 329.21) + (u * 306.17) + (c * 305.18) + (g * 345.21) + 159.0]
		ifFalse: [^(a * 313.21) + (t * 304.2) + (c * 289.18) + (g * 329.21) - 61.96]!
isRNA
	^false! !

!RNASequence methodsFor: 'testing'!
isRNA
	^true! !

!ProteinSequence methodsFor: 'physical properties'!
residueWeights
	"average residue masses in daltons (the mass of water is added once for the whole chain)"
	^#( $A 71.0788 $R 156.1875 $N 114.1038 $D 115.0886 $C 103.1388 $E 129.1155 $Q 128.1307 $G 57.0519
	    $H 137.1411 $I 113.1594 $L 113.1594 $K 128.1741 $M 131.1926 $F 147.1766 $P 97.1167 $S 87.0782
	    $T 101.1051 $W 186.2132 $Y 163.1760 $V 99.1326 $U 150.0388 $O 237.3018 )!
molecularWeight
	"the average mass of the chain in daltons; unknown residues and stops are skipped"
	| table total found |
	table := self residueWeights.
	total := 18.01524.
	found := false.
	self upper do: [:c |
		1 to: table size by: 2 do: [:i |
			(table at: i) = c ifTrue: [total := total + (table at: i + 1). found := true]]].
	^found ifTrue: [total] ifFalse: [0.0]!
chargeAtPH: pH
	"the net charge of the chain at this pH, from the usual pKa values"
	| charge pos neg |
	charge := 0.0.
	"N and C termini"
	charge := charge + (1.0 / (1.0 + (10.0 raisedTo: pH - 9.69))).
	charge := charge - (1.0 / (1.0 + (10.0 raisedTo: 2.34 - pH))).
	pos := #( $K 10.54 $R 12.48 $H 6.04 ).
	neg := #( $D 3.65 $E 4.25 $C 8.18 $Y 10.07 ).
	1 to: pos size by: 2 do: [:i |
		| n pKa |
		n := self upper occurrencesOf: (pos at: i). pKa := pos at: i + 1.
		charge := charge + (n / (1.0 + (10.0 raisedTo: pH - pKa)))].
	1 to: neg size by: 2 do: [:i |
		| n pKa |
		n := self upper occurrencesOf: (neg at: i). pKa := neg at: i + 1.
		charge := charge - (n / (1.0 + (10.0 raisedTo: pKa - pH)))].
	^charge!
isoelectricPoint
	"the pH at which the chain carries no net charge, found by bisection"
	| low high mid |
	self isEmpty ifTrue: [^0.0].
	low := 0.0. high := 14.0.
	40 timesRepeat: [
		mid := (low + high) / 2.0.
		(self chargeAtPH: mid) > 0 ifTrue: [low := mid] ifFalse: [high := mid]].
	^(low + high) / 2.0!
aromaticity
	"the share of phenylalanine, tryptophan and tyrosine"
	^self isEmpty ifTrue: [0.0] ifFalse: [(self countOf: 'FWY') * 1.0 / self size]! !

"---- searching ----"

!BioSequence methodsFor: 'searching'!
indicesOf: aPattern
	"every 1-based position where the text occurs, ignoring case (overlapping matches are all reported)"
	| pat text out n |
	pat := aPattern asString asUppercase.
	text := self upper.
	out := OrderedCollection new.
	pat isEmpty ifTrue: [^out asArray].
	n := text size - pat size + 1.
	1 to: n do: [:i | (self at: i matches: pat in: text exact: true) ifTrue: [out add: i]].
	^out asArray!
indicesOfPattern: aPattern
	"every position matching an IUPAC pattern: GGNTTY matches GGATTC, GGCTTT and so on"
	| pat text out n |
	pat := aPattern asString asUppercase.
	text := self upper.
	out := OrderedCollection new.
	pat isEmpty ifTrue: [^out asArray].
	n := text size - pat size + 1.
	1 to: n do: [:i | (self at: i matches: pat in: text exact: false) ifTrue: [out add: i]].
	^out asArray!
at: start matches: pat in: text exact: exact
	1 to: pat size do: [:k |
		| p t |
		p := pat at: k. t := text at: start + k - 1.
		exact
			ifTrue: [p = t ifFalse: [^false]]
			ifFalse: [(p = t or: [(p = $X and: [self isProtein]) or: [BioIUPAC code: p matches: t]]) ifFalse: [^false]]].
	^true!
occurrencesOfPattern: aPattern
	^(self indicesOfPattern: aPattern) size!
includesPattern: aPattern
	^(self indicesOfPattern: aPattern) notEmpty!
firstIndexOfPattern: aPattern
	| r |
	r := self indicesOfPattern: aPattern.
	^r isEmpty ifTrue: [0] ifFalse: [r first]!
indicesOfPatternBothStrands: aPattern
	"Associations position -> strand for a pattern and its reverse complement"
	| out |
	out := OrderedCollection new.
	(self indicesOfPattern: aPattern) do: [:i | out add: i -> 1].
	self isNucleotide ifTrue: [
		(self indicesOfPattern: (DNASequence raw: aPattern asString) reverseComplement asString) do: [:i | out add: i -> -1]].
	^(out asSortedCollection: [:a :b | a key <= b key]) asArray! !

!BioSequence methodsFor: 'k-mers'!
kmerCounts: k
	"a Dictionary from each k-mer present to how many times it occurs"
	| d text |
	d := Dictionary new.
	text := self upper.
	k < 1 ifTrue: [^d].
	1 to: text size - k + 1 do: [:i |
		| s |
		s := text copyFrom: i to: i + k - 1.
		d at: s put: (d at: s ifAbsent: [0]) + 1].
	^d!
kmers: k
	"every k-mer in order, with repeats"
	| text out |
	text := self upper.
	out := OrderedCollection new.
	1 to: text size - k + 1 do: [:i | out add: (text copyFrom: i to: i + k - 1)].
	^out asArray!
distinctKmers: k
	^self kmerCounts: k!
mostFrequentKmers: k count: n
	"the n commonest k-mers, as Associations kmer -> count, commonest first"
	| sorted |
	sorted := (self kmerCounts: k) associations asSortedCollection: [:a :b | a value = b value ifTrue: [a key <= b key] ifFalse: [a value > b value]].
	^(sorted asArray first: (n min: sorted size))! !

"---- restriction enzymes ----"

!RestrictionEnzyme class methodsFor: 'instance creation'!
name: aName site: aSite cut: anOffset
	"anOffset is how many bases of the site lie before the cut on the top strand"
	^self basicNew setName: aName site: aSite cut: anOffset! !

!RestrictionEnzyme class methodsFor: 'the table'!
enzymes
	"a small table of common enzymes: name, recognition site (IUPAC) and cut offset"
	| spec |
	Enzymes notNil ifTrue: [^Enzymes].
	spec := #( 'AatII' 'GACGTC' 5  'AluI' 'AGCT' 2  'ApaI' 'GGGCCC' 5  'BamHI' 'GGATCC' 1  'BglII' 'AGATCT' 1
	   'ClaI' 'ATCGAT' 2  'DpnI' 'GATC' 2  'EcoRI' 'GAATTC' 1  'EcoRV' 'GATATC' 3  'HaeIII' 'GGCC' 2
	   'HindIII' 'AAGCTT' 1  'HinfI' 'GANTC' 1  'HpaII' 'CCGG' 1  'KpnI' 'GGTACC' 5  'MboI' 'GATC' 0
	   'NcoI' 'CCATGG' 1  'NdeI' 'CATATG' 2  'NotI' 'GCGGCCGC' 2  'PstI' 'CTGCAG' 5  'PvuII' 'CAGCTG' 3
	   'SacI' 'GAGCTC' 5  'SalI' 'GTCGAC' 1  'SmaI' 'CCCGGG' 3  'SpeI' 'ACTAGT' 1  'SphI' 'GCATGC' 5
	   'TaqI' 'TCGA' 1  'XbaI' 'TCTAGA' 1  'XhoI' 'CTCGAG' 1  'XmaI' 'CCCGGG' 1 ).
	Enzymes := OrderedCollection new.
	1 to: spec size by: 3 do: [:i | Enzymes add: (self name: (spec at: i) site: (spec at: i + 1) cut: (spec at: i + 2))].
	^Enzymes!
named: aName
	^self enzymes detect: [:e | e name asLowercase = aName asLowercase] ifNone: [BioError new signal: 'no enzyme named ', aName]!
names
	^(self enzymes collect: [:e | e name]) asArray! !

!RestrictionEnzyme methodsFor: 'accessing'!
setName: aName site: aSite cut: anOffset
	name := aName. site := aSite. cut := anOffset!
name
	^name!
site
	^site!
cut
	^cut!
size
	^site size!
printOn: aStream
	aStream nextPutAll: name; nextPutAll: ' ('; nextPutAll: site; nextPut: $)! !

!RestrictionEnzyme methodsFor: 'cutting'!
sitesIn: aSequence
	"the 1-based positions where the recognition site starts"
	^aSequence indicesOfPattern: site!
cutPositionsIn: aSequence
	"the positions just after each cut on the top strand"
	^(self sitesIn: aSequence) collect: [:i | i + cut - 1]!
digest: aSequence
	"the fragments the enzyme leaves, in order"
	| cuts out last |
	cuts := self cutPositionsIn: aSequence.
	out := OrderedCollection new.
	last := 0.
	cuts do: [:p |
		(p > last and: [p <= aSequence size]) ifTrue: [
			out add: (aSequence copyFrom: last + 1 to: p).
			last := p]].
	out add: (aSequence copyFrom: last + 1 to: aSequence size).
	^out asArray! !

!NucleotideSequence methodsFor: 'restriction'!
restrictionSites
	"a Dictionary from the name of every enzyme that cuts to the positions of its sites"
	| d |
	d := Dictionary new.
	RestrictionEnzyme enzymes do: [:e |
		| sites |
		sites := e sitesIn: self.
		sites notEmpty ifTrue: [d at: e name put: sites]].
	^d!
restrictionSitesOf: aName
	^(RestrictionEnzyme named: aName) sitesIn: self!
digestWith: aName
	^(RestrictionEnzyme named: aName) digest: self!
restrictionReport
	| d out |
	d := self restrictionSites.
	out := WriteStream on: String new.
	d isEmpty ifTrue: [^'no sites for the enzymes in the table'].
	(d keys asSortedCollection) do: [:k |
		out nextPutAll: k; nextPutAll: (String new: (10 - k size max: 1) withAll: $ );
			print: (d at: k) size; nextPutAll: ' site(s) at '; nextPutAll: (d at: k) printString; nl].
	^out contents! !
