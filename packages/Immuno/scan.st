"Scanning a protein for epitopes.

A protein is cut into every window of the lengths the groove takes and each window is scored against the model of
one or more alleles. ScanResult holds what came back and answers the questions that follow: which windows bind,
how strongly, where they cluster, how much of the protein is covered, and which alleles of a person's genotype
present which peptide.

A window that holds a character that is not an amino acid (X, a stop, a gap) is skipped."

Object subclass: #ScanResult instanceVariableNames: 'protein predictions alleles' classVariableNames: '' category: 'Immuno-Scanning'!

!ScanResult class methodsFor: 'scanning'!
scan: aProtein alleles: someAlleles lengths: someLengths
	"every window of aProtein of the given lengths, scored for every allele; windows shorter than an allele's model
	takes are skipped for that allele"
	| text out names |
	text := self cleanProtein: aProtein.
	out := OrderedCollection new.
	names := OrderedCollection new.
	someAlleles do: [:a |
		| m |
		m := AlleleModels matrixFor: a.
		names add: m name.
		someLengths do: [:len |
			(len >= m minimumLength and: [len <= m maximumLength]) ifTrue: [
				self windowsOf: text length: len do: [:start :window |
					| p |
					p := m predict: (Peptide on: window).
					p position: start.
					out add: p]]]].
	^self basicNew setProtein: text predictions: out asArray alleles: names asArray!
cleanProtein: aProtein
	"upper case, white space and digits taken out (so that a pasted GenBank or FASTA body works); asString is
	used on anything that is not a string, which is how a Bio sequence comes in"
	| s |
	s := aProtein isString ifTrue: [aProtein] ifFalse: [aProtein asString].
	^(s select: [:c | c isLetter or: [c = $*]]) asUppercase!
windowsOf: text length: len do: aBlock
	"aBlock is given the start and the window for every window of len valid residues"
	| runStart |
	runStart := 1.
	1 to: text size + 1 do: [:i |
		(i > text size or: [(AminoAcid isResidue: (text at: i)) not]) ifTrue: [
			runStart to: i - len do: [:s | aBlock value: s value: (text copyFrom: s to: s + len - 1)].
			runStart := i + 1]]! !

!ScanResult methodsFor: 'private'!
setProtein: aString predictions: anArray alleles: names
	protein := aString. predictions := anArray. alleles := names! !

!ScanResult methodsFor: 'accessing'!
protein
	^protein!
predictions
	^predictions!
size
	^predictions size!
do: aBlock
	predictions do: aBlock!
alleles
	^alleles!
at: i
	^predictions at: i!
sortedByRank
	"all the predictions, best (lowest rank) first; ties by higher score, then position"
	^(predictions asSortedCollection: [:a :b |
		a rank < b rank or: [a rank = b rank and: [
			a tenths > b tenths or: [a tenths = b tenths and: [a position <= b position]]]]]) asArray!
best: n
	| all |
	all := self sortedByRank.
	^all copyFrom: 1 to: (n min: all size)! !

!ScanResult methodsFor: 'selecting'!
select: aBlock
	^ScanResult basicNew setProtein: protein predictions: (predictions select: aBlock) alleles: alleles!
binders
	"the strong and weak binders"
	^self select: [:p | p isBinder]!
strongBinders
	^self select: [:p | p isStrong]!
forAllele: aName
	| n |
	n := AlleleModels nameOf: aName.
	^self select: [:p | p allele = n]!
atLength: n
	^self select: [:p | p peptide size = n]!
peptides
	"the distinct peptides, as strings, in order of first appearance"
	| seen out |
	seen := Set new. out := OrderedCollection new.
	predictions do: [:p | (seen includes: p peptide asString) ifFalse: [
		seen add: p peptide asString. out add: p peptide asString]].
	^out asArray! !

!ScanResult methodsFor: 'regions'!
regions
	"the stretches of the protein covered by overlapping binders, as an Array of #(start stop count): count is
	how many binding windows lie in the stretch (any allele)"
	| sorted out cur |
	sorted := (self binders predictions asSortedCollection: [:a :b | a position <= b position]) asArray.
	out := OrderedCollection new.
	cur := nil.
	sorted do: [:p |
		(cur notNil and: [p position <= ((cur at: 2) + 1)])
			ifTrue: [
				cur at: 2 put: ((cur at: 2) max: p endPosition).
				cur at: 3 put: (cur at: 3) + 1]
			ifFalse: [
				cur notNil ifTrue: [out add: cur].
				cur := Array with: p position with: p endPosition with: 1]].
	cur notNil ifTrue: [out add: cur].
	^out asArray!
coverage
	"the fraction of the residues of the protein that lie in at least one binding window"
	| n |
	protein isEmpty ifTrue: [^0].
	n := (self regions inject: 0 into: [:sum :r | sum + ((r at: 2) - (r at: 1) + 1)]).
	^n / protein size asFloat!
presentation
	"a Dictionary from each binding peptide (a String) to the Array of alleles whose models call it a binder"
	| d |
	d := Dictionary new.
	self binders do: [:p |
		| list |
		list := d at: p peptide asString ifAbsent: [d at: p peptide asString put: OrderedCollection new].
		(list includes: p allele) ifFalse: [list add: p allele]].
	d keysAndValuesDo: [:k :v | d at: k put: v asArray].
	^d! !

!ScanResult methodsFor: 'reporting'!
report
	"the best fifteen windows as a table"
	^self reportBest: 15!
reportBest: n
	| s width |
	s := WriteStream on: String new.
	width := ((self best: n) inject: 7 into: [:w :p | w max: p peptide size]) + 2.
	s nextPutAll: 'scanned '; print: protein size; nextPutAll: ' residues against ';
		print: alleles size; nextPutAll: ' allele(s): '; print: predictions size; nextPutAll: ' windows, ';
		print: self binders size; nextPutAll: ' binders ('; print: self strongBinders size; nextPutAll: ' strong)'; nl.
	s nextPutAll: (ImmunoFormat padded: 'start' to: 7); nextPutAll: (ImmunoFormat padded: 'peptide' to: width);
		nextPutAll: (ImmunoFormat padded: 'allele' to: 17); nextPutAll: (ImmunoFormat right: 'score' to: 7);
		nextPutAll: (ImmunoFormat right: 'rank%' to: 8); nextPutAll: '  class'; nl.
	(self best: n) do: [:p |
		s nextPutAll: (ImmunoFormat padded: p position printString to: 7);
			nextPutAll: (ImmunoFormat padded: p peptide asString to: width);
			nextPutAll: (ImmunoFormat padded: p allele to: 17);
			nextPutAll: (ImmunoFormat right: (ImmunoFormat number: p score places: 1) to: 7);
			nextPutAll: (ImmunoFormat right: (ImmunoFormat number: p rank places: 2) to: 8);
			nextPutAll: '  '; nextPutAll: p category; nl].
	^s contents! !

!ScanResult methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'ScanResult('; print: predictions size; nextPutAll: ' windows, ';
		print: self binders size; nextPutAll: ' binders)'! !
