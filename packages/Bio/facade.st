"Bio: the front door of the package, and the sequence browser.

	Bio read: 'genome.gb'                every record, whatever the format
	Bio readFasta: 'reads.fa'
	Bio dna: 'ACGTTTGCA'
	Bio fetch: 'NM_000518'               download from NCBI by accession (Bio fetchGenBank: for GenBank)
	Bio openBrowser                      the window on the System menu

Everything it answers is an ordinary object you can keep working with: SequenceCollection, SeqRecord, DNASequence."

Object subclass: #Bio instanceVariableNames: '' classVariableNames: '' category: 'Bio'!
Object subclass: #SequenceBrowser instanceVariableNames: '' classVariableNames: 'Collection Path Mode' category: 'Bio'!

!Bio class methodsFor: 'reading'!
read: aPath
	"read a file, choosing the format from its name and its first line"
	| format |
	format := self formatOf: aPath.
	format == #fasta ifTrue: [^FastaReader readFile: aPath].
	format == #fastq ifTrue: [^FastqReader readFile: aPath].
	format == #genbank ifTrue: [^GenBankReader readFile: aPath].
	^BioError new signal: 'cannot tell what format ', aPath, ' is in'!
formatOf: aPath
	"#fasta, #fastq or #genbank, from the extension, falling back to the first line of the file"
	| lower first |
	lower := aPath asLowercase.
	((lower endsWith: '.fa') or: [(lower endsWith: '.fasta') or: [(lower endsWith: '.fna') or: [(lower endsWith: '.faa') or: [lower endsWith: '.fsa']]]])
		ifTrue: [^#fasta].
	((lower endsWith: '.fq') or: [lower endsWith: '.fastq']) ifTrue: [^#fastq].
	((lower endsWith: '.gb') or: [(lower endsWith: '.gbk') or: [(lower endsWith: '.genbank') or: [lower endsWith: '.gbff']]])
		ifTrue: [^#genbank].
	(FileStream exists: aPath) ifFalse: [^nil].
	first := FileStream readOnlyFileNamed: aPath do: [:f | f nextLine ifNil: ['']].
	first isEmpty ifTrue: [^nil].
	first first = $> ifTrue: [^#fasta].
	first first = $@ ifTrue: [^#fastq].
	(first startsWith: 'LOCUS') ifTrue: [^#genbank].
	^nil!
readFasta: aPath
	^FastaReader readFile: aPath!
readFastq: aPath
	^FastqReader readFile: aPath!
readGenBank: aPath
	^GenBankReader readFile: aPath!
parseFasta: aString
	^FastaReader parse: aString!
parseFastq: aString
	^FastqReader parse: aString!
parseGenBank: aString
	^GenBankReader parse: aString!
fasta: aPath do: aBlock
	"one record at a time, so that a file larger than memory can still be handled"
	^FastaReader file: aPath do: aBlock!
fastq: aPath do: aBlock
	^FastqReader file: aPath do: aBlock! !

!Bio class methodsFor: 'writing'!
write: aCollection toFasta: aPath
	^FastaWriter write: aCollection to: aPath!
write: aCollection toFastq: aPath
	^FastqWriter write: aCollection to: aPath! !

!Bio class methodsFor: 'downloading'!
fetch: anAccession
	"download a record from NCBI by accession (several may be given: 'U00096.3, NC_001416.1'), as FASTA"
	^SequenceFetcher fetch: anAccession format: #fasta!
fetchFasta: anAccession
	^SequenceFetcher fetch: anAccession format: #fasta!
fetchGenBank: anAccession
	"download as a GenBank flat file (GenPept for a protein), parsed with its features"
	^SequenceFetcher fetch: anAccession format: #genbank!
fetch: anAccession format: aFormat
	"aFormat is #fasta or #genbank"
	^SequenceFetcher fetch: anAccession format: aFormat!
fastaTextFor: anAccession
	^SequenceFetcher fastaFor: anAccession!
genBankTextFor: anAccession
	^SequenceFetcher genBankFor: anAccession!
download: anAccession format: aFormat to: aPath
	"save NCBI's text unchanged in a file, which Bio read: can read back; answers the path"
	^SequenceFetcher download: anAccession format: aFormat to: aPath!
downloadFasta: anAccession to: aPath
	^SequenceFetcher download: anAccession format: #fasta to: aPath!
downloadGenBank: anAccession to: aPath
	^SequenceFetcher download: anAccession format: #genbank to: aPath! !

!Bio class methodsFor: 'sequences'!
dna: aString
	^DNASequence on: aString!
rna: aString
	^RNASequence on: aString!
protein: aString
	^ProteinSequence on: aString!
sequence: aString
	"a DNA, RNA or protein sequence, guessed from the letters"
	^BioSequence guess: aString!
record: anId sequence: aString
	^SeqRecord id: anId sequence: aString!
collection: aCollectionOfRecords
	^SequenceCollection withAll: aCollectionOfRecords! !

!Bio class methodsFor: 'analysis'!
align: a with: b
	^(PairwiseAligner for: a) align: a with: b!
localAlign: a with: b
	^(PairwiseAligner for: a) localAlign: a with: b!
geneticCode: anInteger
	^GeneticCode id: anInteger!
geneticCodes
	^GeneticCode codes values asArray!
enzymes
	^RestrictionEnzyme enzymes asArray! !

!Bio class methodsFor: 'package'!
directory
	^Smalltalk packagePath: 'Bio'!
dataDirectory
	^self directory, '/data'!
exampleFile: aName
	^self dataDirectory, '/', aName!
examples
	"the example files that come with the package"
	| d |
	d := Directory on: self dataDirectory.
	^d exists ifTrue: [d fileNames] ifFalse: [Array new]!
openBrowser
	^SequenceBrowser open!
openBrowserOn: aPath
	^SequenceBrowser openOn: aPath!
version
	^'Bio 1.0'! !

"---- the sequence browser: a list of records on the left, a view of the selected one on the right ----"

!SequenceBrowser class methodsFor: 'opening'!
open
	Collection isNil ifTrue: [Collection := SequenceCollection named: 'no file loaded'].
	Mode isNil ifTrue: [Mode := #summary].
	Smalltalk openListTool: 'SequenceBrowser' title: 'Sequences'!
openOn: aPath
	self load: aPath.
	Smalltalk openListTool: 'SequenceBrowser' title: 'Sequences'!
load: aPath
	Collection := Bio read: aPath.
	Path := aPath.
	Mode isNil ifTrue: [Mode := #summary].
	^Collection!
collection
	^Collection ifNil: [Collection := SequenceCollection named: 'no file loaded']!
collection: aCollection
	Collection := aCollection. Path := aCollection name!
mode
	^Mode ifNil: [Mode := #summary]! !

!SequenceBrowser class methodsFor: 'the list'!
listItems
	| out |
	self collection isEmpty ifTrue: [^Array new].
	out := OrderedCollection new.
	self collection doWithIndex: [:r :i |
		| line |
		line := r id, '  ', r size printString, (r isNucleotide ifTrue: [' bp'] ifFalse: [' aa']).
		r description notEmpty ifTrue: [line := line, '  ', (r description truncateTo: 40)].
		out add: line].
	^out asArray!
detailAt: anIndex
	| r |
	self collection isEmpty ifTrue: [^self helpText].
	(anIndex between: 1 and: self collection size) ifFalse: [^self fileStatistics].
	r := self collection at: anIndex.
	^[self detailOf: r] on: Error do: [:e | 'could not show this record: ', e messageText]!
detailOf: r
	| mode |
	mode := self mode.
	mode == #summary ifTrue: [^r summary].
	mode == #sequence ifTrue: [^r asFasta].
	mode == #features ifTrue: [^self featuresOf: r].
	mode == #orfs ifTrue: [^self orfsOf: r].
	mode == #translation ifTrue: [^self translationOf: r].
	mode == #composition ifTrue: [^r id, (String with: Character lf), r sequence compositionReport].
	mode == #restriction ifTrue: [^r isNucleotide ifTrue: [r sequence restrictionReport] ifFalse: ['not a nucleotide sequence']].
	mode == #quality ifTrue: [^self qualityOf: r].
	^r summary!
featuresOf: r
	| out |
	r features isEmpty ifTrue: [^r id, ': no features (only GenBank files carry them)'].
	out := WriteStream on: String new.
	out nextPutAll: r id; nextPutAll: ': '; print: r features size; nextPutAll: ' features'; nl; nl.
	r features do: [:f | out nextPutAll: f details; nl].
	^out contents!
orfsOf: r
	| out orfs |
	r isNucleotide ifFalse: [^'not a nucleotide sequence'].
	orfs := r sequence orfsLongerThan: 90.
	out := WriteStream on: String new.
	out nextPutAll: r id; nextPutAll: ': '; print: orfs size; nextPutAll: ' open reading frames of 90 bases or more'; nl; nl.
	orfs do: [:f |
		out nextPutAll: f location printString; nextPutAll: '  frame '; print: (f qualifierAt: 'frame');
			nextPutAll: '  '; print: (f qualifierAt: 'length'); nextPutAll: ' bp'; nl;
			nextPutAll: '  '; nextPutAll: ((f qualifierAt: 'translation') truncateTo: 70); nl].
	^out contents!
translationOf: r
	| out |
	r isNucleotide ifFalse: [^r asFasta].
	out := WriteStream on: String new.
	out nextPutAll: r id; nextPutAll: ': six-frame translation'; nl; nl.
	r sequence sixFrameTranslations do: [:a |
		out nextPutAll: 'frame '; print: a key; nextPutAll: ': '; nl; nextPutAll: (a value wrappedAt: 60); nl].
	^out contents!
qualityOf: r
	| out |
	r hasQuality ifFalse: [^r id, ': no quality scores (only FASTQ files carry them)'].
	out := WriteStream on: String new.
	out nextPutAll: r id; nl;
		nextPutAll: 'mean quality   '; nextPutAll: (r meanQuality asFloat printShowingDecimalPlaces: 2); nl;
		nextPutAll: 'lowest         '; print: r minQuality; nl;
		nextPutAll: 'highest        '; print: r maxQuality; nl;
		nextPutAll: 'expected errors '; nextPutAll: (r expectedErrors printShowingDecimalPlaces: 3); nl; nl;
		nextPutAll: 'per base:'; nl.
	r quality doWithIndex: [:q :i |
		out print: q.
		i \\ 20 = 0 ifTrue: [out nl] ifFalse: [out nextPut: $ ]].
	^out contents!
fileStatistics
	| out |
	out := WriteStream on: String new.
	Path notNil ifTrue: [out nextPutAll: Path; nl; nl].
	out nextPutAll: self collection statistics.
	(self collection anySatisfy: [:r | r hasQuality]) ifTrue: [out nl; nextPutAll: self collection qualityReport].
	^out contents!
helpText
	^'No sequences loaded.

Use the right-button menu on this list:
  open file...     read a FASTA, FASTQ or GenBank file
  the example files that come with the package are in
  ', Bio dataDirectory, '

Once a file is open, the menu chooses what to show for the
selected record: its summary, the sequence itself, the
GenBank features, open reading frames, the six-frame
translation, base composition, restriction sites or (for
FASTQ) the quality scores.'! !

!SequenceBrowser class methodsFor: 'the menu'!
commandLabels
	^#('open file...' '-' 'summary' 'sequence' 'features' 'open reading frames' 'six-frame translation'
	   'composition' 'restriction sites' 'quality' '-' 'statistics of the file' 'write FASTA...' 'inspect record')!
command: aCommand at: anIndex
	| label |
	label := self commandLabels at: aCommand.
	label = 'open file...' ifTrue: [^self openFileCommand].
	label = 'summary' ifTrue: [Mode := #summary. ^nil].
	label = 'sequence' ifTrue: [Mode := #sequence. ^nil].
	label = 'features' ifTrue: [Mode := #features. ^nil].
	label = 'open reading frames' ifTrue: [Mode := #orfs. ^nil].
	label = 'six-frame translation' ifTrue: [Mode := #translation. ^nil].
	label = 'composition' ifTrue: [Mode := #composition. ^nil].
	label = 'restriction sites' ifTrue: [Mode := #restriction. ^nil].
	label = 'quality' ifTrue: [Mode := #quality. ^nil].
	label = 'statistics of the file' ifTrue: [^self fileStatistics].
	label = 'write FASTA...' ifTrue: [^self writeFastaCommand].
	label = 'inspect record' ifTrue: [^self inspectCommand: anIndex].
	^nil!
openFileCommand
	| path |
	path := Smalltalk promptFor: 'Open a FASTA, FASTQ or GenBank file' default: (Path ifNil: [Bio dataDirectory, '/']).
	(path isNil or: [path trimBoth isEmpty]) ifTrue: [^nil].
	^[self load: path trimBoth. 'loaded ', path trimBoth, (String with: Character lf), self fileStatistics]
		on: Error do: [:e | 'could not read ', path trimBoth, ': ', e messageText]!
writeFastaCommand
	| path |
	self collection isEmpty ifTrue: [^'there is nothing to write'].
	path := Smalltalk promptFor: 'Write the sequences as FASTA to' default: 'sequences.fasta'.
	(path isNil or: [path trimBoth isEmpty]) ifTrue: [^nil].
	^[| n | n := FastaWriter write: self collection to: path trimBoth.
	  'wrote ', n printString, ' sequences to ', path trimBoth]
		on: Error do: [:e | 'could not write ', path trimBoth, ': ', e messageText]!
inspectCommand: anIndex
	(anIndex between: 1 and: self collection size) ifFalse: [^'select a record first'].
	(self collection at: anIndex) inspect.
	^nil! !
