"The front door, the example data, and a workspace.

Immuno has nothing but class-side methods: the short way to score a peptide, scan a protein, pick epitopes for a
population or match a donor. SelfProteome holds the peptides of a set of self proteins, for asking whether a
peptide is self or how near to it comes. ImmunoTool is a workspace in which a few lines of sequence and alleles
come back as a table.

The sequences and epitopes in this file were typed from published listings (UniProt and the IEDB) for use as
examples. Check against the databases before trusting any of them for anything but a demonstration."

Object subclass: #Immuno instanceVariableNames: '' classVariableNames: 'Epitopes' category: 'Immuno'!
Object subclass: #SelfProteome instanceVariableNames: 'kmers proteins' classVariableNames: '' category: 'Immuno'!
Object subclass: #ImmunoTool instanceVariableNames: '' classVariableNames: '' category: 'Immuno'!

!Immuno class methodsFor: 'the package'!
version
	^'1.0'!
directory
	^Smalltalk packagePath: 'Immuno'!
examples
	"what the package comes with, and where to find it"
	^#(#('Immuno knownEpitopes' 'about thirty epitopes with their alleles and sources: class I, and one class II')
		#('Immuno exampleProtein: #influenzaM1' 'matrix protein 1 of influenza A (PR8), 252 residues')
		#('Immuno exampleProtein: #ubiquitin' 'human ubiquitin, 76 residues')
		#('Immuno exampleProtein: #beta2microglobulin' 'human beta-2 microglobulin, 99 residues')
		#('AlleleFrequencies example' 'illustrative allele frequencies for A, B and DRB1')
		#('AlleleModels alleles' 'the alleles that have a built-in binding model'))! !

!Immuno class methodsFor: 'making things'!
peptide: aString
	^Peptide on: aString!
allele: aString
	^HLAAllele named: aString!
genotype: aString
	^HLAGenotype fromString: aString!
population
	^AlleleFrequencies example!
matrixFor: anAllele
	^AlleleModels matrixFor: anAllele! !

!Immuno class methodsFor: 'predicting'!
predict: aPeptide for: anAllele
	"a BindingPrediction: score in bits, rank among random peptides, and a verdict"
	^(AlleleModels matrixFor: anAllele) predict: aPeptide!
predict: aPeptide forAll: someAlleles
	"one prediction per allele, best rank first"
	^((someAlleles collect: [:a | self predict: aPeptide for: a])
		asSortedCollection: [:x :y | x rank <= y rank]) asArray!
rank: aPeptide for: anAllele
	^(self predict: aPeptide for: anAllele) rank!
isBinder: aPeptide to: anAllele
	^(self predict: aPeptide for: anAllele) isBinder!
lengthsFor: anAllele
	"the window lengths a scan should use for an allele: 8 to 11 for class I, 15 for class II"
	^(AlleleModels matrixFor: anAllele) isClassI ifTrue: [#(8 9 10 11)] ifFalse: [#(15)]! !

!Immuno class methodsFor: 'scanning'!
scan: aProtein for: anAllele
	^self scan: aProtein forAll: (Array with: anAllele)!
scan: aProtein forAll: someAlleles
	"every window of the protein scored for every allele, at the lengths each kind of allele takes"
	| classI classII results |
	classI := someAlleles select: [:a | (AlleleModels matrixFor: a) isClassI].
	classII := someAlleles reject: [:a | (AlleleModels matrixFor: a) isClassI].
	results := OrderedCollection new.
	classI isEmpty ifFalse: [results add: (ScanResult scan: aProtein alleles: classI lengths: #(8 9 10 11))].
	classII isEmpty ifFalse: [results add: (ScanResult scan: aProtein alleles: classII lengths: #(15))].
	results size = 1 ifTrue: [^results first].
	^ScanResult basicNew setProtein: (ScanResult cleanProtein: aProtein)
		predictions: (results first predictions, results last predictions)
		alleles: (results first alleles, results last alleles)!
scan: aProtein genotype: aGenotype
	"scan against every allele of a person's genotype that has a model"
	^self scan: aProtein forAll: aGenotype modelled! !

!Immuno class methodsFor: 'choosing epitopes'!
selectEpitopes: n from: aScanResult population: frequencies
	"choose n peptides, one at a time, each adding the most population coverage to what has been chosen already:
	the answer is an Array of #(peptide alleles coverage), where coverage is the fraction of the population that
	carries an allele presenting at least one chosen peptide, counting only binders"
	| table chosen union pool |
	table := aScanResult presentation.
	pool := (table keys asSortedCollection: [:a :b | a <= b]) asArray asOrderedCollection.
	chosen := OrderedCollection new.
	union := Set new.
	[chosen size < n and: [pool notEmpty]] whileTrue: [
		| best bestCover |
		best := nil. bestCover := -1.
		pool do: [:p |
			| c |
			c := frequencies coverageOf: ((union copy addAll: (table at: p); yourself) asArray).
			c > bestCover ifTrue: [best := p. bestCover := c]].
		union addAll: (table at: best).
		chosen add: (Array with: best with: (table at: best) with: bestCover).
		pool remove: best].
	^chosen asArray! !

!Immuno class methodsFor: 'testing a model'!
decoysFor: aPeptideCollection seed: aSeed
	"for each peptide a shuffled copy: the same residues, in a random order, so that the only thing that
	differs is whether they fit the groove"
	| rnd |
	rnd := ImmunoRandom seed: aSeed.
	^aPeptideCollection collect: [:p | (p asPeptide shuffledUsing: rnd) asString]!
randomPeptides: count length: n seed: aSeed
	"count random peptides with the composition of proteins at large"
	| rnd |
	rnd := ImmunoRandom seed: aSeed.
	^(1 to: count) collect: [:i | (Peptide random: n using: rnd) asString]!
evaluate: anAllele
	"the AUC of an allele's model on the known epitopes for it, against 200 random nine-mers: 1 would be perfect,
	0.5 no better than chance. Needs at least one known epitope."
	| known |
	known := self epitopesFor: anAllele.
	known isEmpty ifTrue: [^ImmunoError new signal: 'no known epitopes for ', (AlleleModels nameOf: anAllele)].
	^(AlleleModels matrixFor: anAllele) aucFor: known against: (self randomPeptides: 200 length: 9 seed: 7)! !

!Immuno class methodsFor: 'known epitopes'!
knownEpitopes
	"an Array of #(peptide allele source): epitopes shown to be presented by the allele, the ones the textbooks use;
	typed in as examples"
	Epitopes isNil ifTrue: [Epitopes := #(
		#('GILGFVFTL' 'HLA-A*02:01' 'influenza M1 58-66')
		#('NLVPMVATV' 'HLA-A*02:01' 'CMV pp65 495-503')
		#('GLCTLVAML' 'HLA-A*02:01' 'EBV BMLF1 280-288')
		#('SLYNTVATL' 'HLA-A*02:01' 'HIV-1 Gag p17 77-85')
		#('ILKEPVHGV' 'HLA-A*02:01' 'HIV-1 RT 309-317')
		#('LLFGYPVYV' 'HLA-A*02:01' 'HTLV-1 Tax 11-19')
		#('KLVALGINAV' 'HLA-A*02:01' 'HCV NS3 1406-1415')
		#('YLQPRTFLL' 'HLA-A*02:01' 'SARS-CoV-2 spike 269-277')
		#('CLGGLLTMV' 'HLA-A*02:01' 'EBV LMP2 426-434')
		#('RMFPNAPYL' 'HLA-A*02:01' 'WT1 126-134')
		#('LLWNGPMAV' 'HLA-A*02:01' 'yellow fever NS4B 214-222')
		#('KVAELVHFL' 'HLA-A*02:01' 'MAGE-A3 112-120')
		#('ELAGIGILTV' 'HLA-A*02:01' 'MART-1 26-35')
		#('FLPSDFFPSV' 'HLA-A*02:01' 'HBV core 18-27')
		#('VTEHDTLLY' 'HLA-A*01:01' 'CMV pp50 245-253')
		#('CTELKLSDY' 'HLA-A*01:01' 'influenza NP 44-52')
		#('ATDALMTGY' 'HLA-A*01:01' 'HCV NS3 1436-1444')
		#('ILRGSVAHK' 'HLA-A*03:01' 'influenza NP 91-99')
		#('RLRAEAQVK' 'HLA-A*03:01' 'EBV EBNA3A 603-611')
		#('AIFQSSMTK' 'HLA-A*03:01' 'HIV-1 Nef 73-82')
		#('QYDPVAALF' 'HLA-A*24:02' 'CMV pp65 341-349')
		#('CYTWNQMNL' 'HLA-A*24:02' 'WT1 235-243')
		#('RPQVPLRPM' 'HLA-B*07:02' 'HIV-1 Nef 128-136')
		#('TPQDLNTML' 'HLA-B*07:02' 'HIV-1 Gag p24 180-188')
		#('SPRWYFYYL' 'HLA-B*07:02' 'SARS-CoV-2 N 105-113')
		#('FLRGRAYGL' 'HLA-B*08:01' 'EBV EBNA3A 325-333')
		#('ELRRKMMYM' 'HLA-B*08:01' 'EBV BZLF1')
		#('SRYWAIRTR' 'HLA-B*27:05' 'influenza NP 383-391')
		#('RRIYDLIEL' 'HLA-B*27:05' 'EBV EBNA3C 258-266')
		#('YPLHEQHGM' 'HLA-B*35:01' 'EBV EBNA3A 458-466')
		#('FPVRPQVPL' 'HLA-B*35:01' 'HIV-1 Nef 84-92')
		#('ISPRTLNAW' 'HLA-B*57:01' 'HIV-1 Gag p24 147-155')
		#('PKYVKQNTLKLAT' 'HLA-DRB1*01:01' 'influenza HA 306-318'))].
	^Epitopes!
epitopesFor: anAllele
	"the peptides in knownEpitopes for an allele, as strings"
	| n |
	n := AlleleModels nameOf: anAllele.
	^((self knownEpitopes select: [:row | (row at: 2) = n]) collect: [:row | row at: 1]) asArray! !

!Immuno class methodsFor: 'example proteins'!
exampleProtein: aName
	"#influenzaM1, #ubiquitin or #beta2microglobulin, as a String"
	aName = #influenzaM1 ifTrue: [^'MSLLTEVETYVLSIIPSGPLKAEIAQRLEDVFAGKNTDLEVLMEWLKTRPILSPLTKGILGFVFTLTVPSERGLQRRRFVQNALNGNGDPNNMDKAVKLYRKLKREITFHGAKEISLSYSAGALASCMGLIYNRMGAVTTEVAFGLVCATCEQIADSQHRSHRQMVTTTNPLIRHENRMVLASTTAKAMEQMAGSSEQAAEAMEVASQARQMVQAMRTIGTHPSSSAGLKNDLLENLQAYQKRMGVQMQRFK'].
	aName = #ubiquitin ifTrue: [^'MQIFVKTLTGKTITLEVEPSDTIENVKAKIQDKEGIPPDQQRLIFAGKQLEDGRTLSDYNIQKESTLHLVLRLRGG'].
	aName = #beta2microglobulin ifTrue: [^'IQRTPKIQVYSRHPAENGKSNFLNCYVSGFHPSDIEVDLLKNGERIEKVEHSDLSFSKDWSFYLLYYTEFTPTEKDEYACRVNHVTLSQPKIVKWDRDM'].
	^ImmunoError new signal: 'no example protein called ', aName printString! !

!SelfProteome class methodsFor: 'instance creation'!
new
	^self basicNew setUp!
withProteins: someStrings
	| p |
	p := self new.
	someStrings do: [:s | p addProtein: s].
	^p! !

!SelfProteome methodsFor: 'private'!
setUp
	kmers := Set new. proteins := 0! !

!SelfProteome methodsFor: 'building'!
addProtein: aString
	"add every 8-, 9-, 10- and 11-mer of the protein, and the 15-mers, to what counts as self"
	| text |
	text := ScanResult cleanProtein: aString.
	#(8 9 10 11 15) do: [:len |
		ScanResult windowsOf: text length: len do: [:start :w | kmers add: w]].
	proteins := proteins + 1!
proteinCount
	^proteins!
size
	^kmers size! !

!SelfProteome methodsFor: 'asking'!
includes: aPeptide
	"true when the peptide is exactly a piece of one of the proteins"
	^kmers includes: aPeptide asString!
nearest: aPeptide
	"the piece of the same length most like the peptide, as #(piece normalizedSimilarity), or nil if there is
	none of that length"
	| p best bestScore |
	p := aPeptide asPeptide.
	best := nil. bestScore := -2.0.
	kmers do: [:k |
		k size = p size ifTrue: [
			| s |
			s := p normalizedSimilarityTo: (Peptide on: k).
			s > bestScore ifTrue: [best := k. bestScore := s]]].
	best isNil ifTrue: [^nil].
	^Array with: best with: bestScore!
mismatchesToNearest: aPeptide
	"the fewest positions at which the peptide differs from a piece of the same length: 0 if it is self"
	| p best |
	p := aPeptide asPeptide.
	best := nil.
	kmers do: [:k |
		k size = p size ifTrue: [
			| h |
			h := p hammingTo: (Peptide on: k).
			(best isNil or: [h < best]) ifTrue: [best := h]]].
	^best! !

!ImmunoTool class methodsFor: 'opening'!
open
	Smalltalk openTool: 'ImmunoTool' title: 'Immuno' contents: self welcomeText!
welcomeText
	^'"Select some lines and print it (or do it).  A line with a * in it names alleles, separated by spaces;
every other line is a sequence: a short one is scored as a peptide against each allele, a long one is
scanned for binders.  These are teaching models: see packages/Immuno/README.md."

HLA-A*02:01 HLA-B*07:02
GILGFVFTL
RPQVPLRPM
NLVPMVATV

HLA-A*03:01
MQIFVKTLTGKTITLEVEPSDTIENVKAKIQDKEGIPPDQQRLIFAGKQLEDGRTLSDYNIQKESTLHLVLRLRGG
' ! !

!ImmunoTool class methodsFor: 'evaluating'!
evaluate: aString
	"the report for the selected text"
	| alleles out |
	alleles := OrderedCollection new.
	out := WriteStream on: String new.
	(self linesOf: (self stripComments: aString)) do: [:raw |
		| line |
		line := raw trimBoth.
		line isEmpty ifFalse: [
			(line includes: $*)
				ifTrue: [
					alleles := OrderedCollection new.
					line substrings do: [:w |
						[alleles add: (HLAAllele named: w)]
							on: ImmunoError do: [:e | out nextPutAll: 'skipped ', w, ': ', e messageText; nl]].
					out nextPutAll: 'alleles: '; print: alleles asArray; nl]
				ifFalse: [self describe: line against: alleles on: out]]].
	out contents isEmpty ifTrue: [^'nothing to score: give some alleles (A*02:01) and a sequence'].
	^out contents!
stripComments: aString
	"the text without anything inside double quotes"
	| out inside |
	out := WriteStream on: String new.
	inside := false.
	aString do: [:c |
		c = $" ifTrue: [inside := inside not] ifFalse: [inside ifFalse: [out nextPut: c]]].
	^out contents!
linesOf: aString
	| out start |
	out := OrderedCollection new.
	start := 1.
	1 to: aString size do: [:i |
		(aString at: i) = Character lf ifTrue: [out add: (aString copyFrom: start to: i - 1). start := i + 1]].
	out add: (aString copyFrom: start to: aString size).
	^out!
describe: aLine against: alleles on: out
	| seq |
	alleles isEmpty ifTrue: [out nextPutAll: 'no alleles yet for '; nextPutAll: aLine; nl. ^self].
	(Peptide isValid: aLine) ifFalse: [out nextPutAll: 'not a sequence: '; nextPutAll: aLine; nl. ^self].
	seq := aLine asPeptide.
	seq size <= 30
		ifTrue: [alleles do: [:a |
			[out print: (Immuno predict: seq for: a)]
				on: ImmunoError do: [:e | out nextPutAll: seq asString; nextPutAll: ' / '; nextPutAll: a name; nextPutAll: ': '; nextPutAll: e messageText].
			out nl]]
		ifFalse: [out nextPutAll: (Immuno scan: seq forAll: alleles asArray) report; nl]! !
