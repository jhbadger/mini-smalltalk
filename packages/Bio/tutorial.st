"The Bio tutorial: sequences, the genetic code, FASTA, FASTQ and GenBank files, collections of records,
analysis, pairwise alignment and the sequence browser.  Start it with   BioTutorial go"

AbstractTutorial subclass: #BioTutorial instanceVariableNames: '' classVariableNames: '' category: 'Bio'!

!BioTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Bio'!
lessonSelectors
	^#(#welcome #sequences #composition #complementAndReverse #theGeneticCode #otherCodes
		#readingFasta #collections #records #fastq #genbank #findingThings #openReadingFrames
		#restrictionEnzymes #alignment #theBrowser #whatNext)! !

!BioTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'This package reads and writes the file formats molecular biology runs on, and
gives you objects to work with rather than strings: a DNASequence knows how to
complement itself, a SeqRecord knows its features, a SequenceCollection knows
its N50.

Everything in this tutorial is live.  Select a line and press ctrl-P (print it)
to run it and see the answer.

A taste of the whole thing:

(Bio dna: ''ATGGCGTAA'') reverseComplement
(Bio dna: ''ATGGCGTAA'') translate
(Bio dna: ''ATGGCGTAA'') gcPercent

The package ships three small example files, which the lessons use so that you
need no data of your own:

Bio examples
Bio exampleFile: ''example.fasta''
(Bio read: (Bio exampleFile: ''example.fasta'')) size

The class called Bio is a facade: nothing but class-side methods, each a short
way to something the real classes do.  You can work through it or go round it,
whichever reads better.'!
sequences
	^TutorialLesson title: 'Sequences' text:
'There are three kinds of sequence, and they differ in what they know how to do,
not just in what letters they hold:

(Bio dna: ''ACGT'') class
(Bio rna: ''ACGU'') class
(Bio protein: ''MKWV'') class

If you do not want to say which, let the letters decide.  Anything with less
than about 85 per cent ACGTUN in it is taken for protein:

(BioSequence guess: ''ACGTACGTAA'') class
(BioSequence guess: ''MKWVTFISLL'') class
(Bio sequence: ''ACGUACGU'') class

A sequence behaves like a collection of characters, and the usual messages
work:

| s | s := Bio dna: ''ACGTACGTAA''. s size
| s | s := Bio dna: ''ACGTACGTAA''. s at: 3
| s | s := Bio dna: ''ACGTACGTAA''. s first
| s | s := Bio dna: ''ACGTACGTAA''. (s copyFrom: 2 to: 5) asString
| s | s := Bio dna: ''ACGTACGTAA''. s reverse asString
| s | s := (Bio dna: ''ACGT''), (Bio dna: ''AAAA''). s asString

Whitespace and digits are stripped on the way in, so a sequence pasted out of a
paper or a numbered listing just works.  Select both of the indented lines
below together and print them:

    (Bio dna: ''  1 ACGT ACGT
      9 AATT  '') asString

It will also tell you when it holds something it should not:

(Bio dna: ''ACGTXZ'') isValid
(Bio dna: ''ACGTXZ'') invalidCharacters'!
composition
	^TutorialLesson title: 'What is in a sequence' text:
'The first question about a stretch of DNA is usually what it is made of.

| s | s := Bio dna: ''ATGGCGCGCTTAA''. s composition
| s | s := Bio dna: ''ATGGCGCGCTTAA''. s compositionPercent
| s | s := Bio dna: ''ATGGCGCGCTTAA''. s countOf: $G

GC content has its own messages, because it is the one everybody wants:

| s | s := Bio dna: ''ATGGCGCGCTTAA''. s gc
| s | s := Bio dna: ''ATGGCGCGCTTAA''. s gcPercent
| s | s := Bio dna: ''ATGGCGCGCTTAA''. s gcCount

GC skew is the imbalance between the two strands, which shifts sign at a
replication origin:

| s | s := Bio dna: ''GGGGCCCCGGGG''. s gcSkew
| s | s := Bio dna: ''ATGGCGCGCTTAA''. s atSkew

and you can run a window along the sequence to see how it varies:

| s | s := Bio dna: (String new: 200 withAll: $A), (String new: 200 withAll: $G). s gcContentIn: 100 step: 100

For a sequence you are looking at rather than computing with, there is a report:

(Bio dna: ''ATGGCGCGCTTAACGT'') compositionReport'!
complementAndReverse
	^TutorialLesson title: 'Complement and reverse complement' text:
'Double-stranded DNA has two readings, and almost every mistake in this corner
of biology is reading the wrong one.  The complement swaps each base for its
partner:

(Bio dna: ''ATGC'') complement asString

The reverse complement is that read the other way round, which is what the
other strand actually says:

(Bio dna: ''ATGC'') reverseComplement asString
(Bio dna: ''ATGC'') rc asString

Do it twice and you are back where you started:

(Bio dna: ''ATGGCGTAA'') rc rc asString

RNA differs from DNA by one letter, and the two conversions are named after
what the cell does:

(Bio dna: ''ATGGCGTAA'') transcribe asString
(Bio rna: ''AUGGCGUAA'') reverseTranscribe asString

Ambiguity codes are understood as well, and they complement correctly, which is
easy to get wrong by hand:

(Bio dna: ''ARYKM'') reverseComplement asString
(BioIUPAC basesFor: $R)
(BioIUPAC code: $N matches: $A)
BioIUPAC expand: ''ARY'''!
theGeneticCode
	^TutorialLesson title: 'The genetic code' text:
'Translation turns a nucleotide sequence into a protein, three letters at a
time.  The plain message uses the standard code and starts at the first base:

(Bio dna: ''ATGGCGCATTAA'') translate
(Bio dna: ''ATGGCGCATTAA'') translate asString

A star is a stop codon.  Usually you want everything up to the first one:

(Bio dna: ''ATGGCGCATTAAGGGCCC'') translateToStop asString

DNA can be read in three frames on each strand, and which one is right is not
obvious from the sequence alone:

(Bio dna: ''ATGGCGCATTAA'') translateFrame: 1
(Bio dna: ''ATGGCGCATTAA'') translateFrame: 2
(Bio dna: ''ATGGCGCATTAA'') translateFrame: -1

so there is a message for all six at once:

(Bio dna: ''ATGGCGCATTAA'') sixFrameTranslations

The code itself is an object you can ask questions of:

GeneticCode standard translate: ''ATGGCG''
GeneticCode standard isStartCodon: ''ATG''
GeneticCode standard isStopCodon: ''TAA''
GeneticCode standard stopCodons
GeneticCode standard name'!
otherCodes
	^TutorialLesson title: 'The other genetic codes' text:
'The standard code is not universal.  Mitochondria and several groups of
organisms read some codons differently, and using the wrong table quietly gives
you the wrong protein.

Bio geneticCodes
GeneticCode codes size

Each has the NCBI number everybody uses:

(Bio geneticCode: 1) name
(Bio geneticCode: 2) name
(Bio geneticCode: 11) name

The difference is easy to see.  In the standard code AGA is arginine; in the
vertebrate mitochondrial code it is a stop:

GeneticCode standard translate: ''AGA''
GeneticCode vertebrateMitochondrial translate: ''AGA''
(Bio dna: ''ATGAGATAA'') translateWith: GeneticCode vertebrateMitochondrial

Bacteria use the standard table but with more start codons, which matters when
you are looking for genes rather than translating a known one:

GeneticCode bacterial startCodons
GeneticCode standard startCodons
GeneticCode bacterial isStartCodon: ''TTG''

You can also look a code up by name rather than by number:

(GeneticCode named: ''Vertebrate Mitochondrial'') id'!
readingFasta
	^TutorialLesson title: 'Reading a FASTA file' text:
'FASTA is the lowest common denominator of sequence formats: a line beginning
with a greater-than sign holding an identifier and a description, then the
sequence on the lines below.

Read one, and let the package work out the format from the file itself:

Bio read: (Bio exampleFile: ''example.fasta'')
Bio formatOf: (Bio exampleFile: ''example.fasta'')
Bio readFasta: (Bio exampleFile: ''example.fasta'')

You can also parse text you already have in hand, which is what a test does.
Select all five indented lines together:

    Bio parseFasta: ''>one hello
    ACGTACGT
    >two
    GGGCCC''

What comes back is a SequenceCollection, which the next lesson is about.
Writing it out again is one message:

(Bio read: (Bio exampleFile: ''example.fasta'')) asFasta

A very large file need not be held in memory at all; this reads one record at a
time and keeps only what you ask it to:

| n | n := 0. Bio fasta: (Bio exampleFile: ''example.fasta'') do: [:each | n := n + each size]. n'!
collections
	^TutorialLesson title: 'Collections of sequences' text:
'A SequenceCollection is a list of records that also knows the things you want
to know about a set of sequences.

| c | c := Bio read: (Bio exampleFile: ''example.fasta''). c size
| c | c := Bio read: (Bio exampleFile: ''example.fasta''). c ids
| c | c := Bio read: (Bio exampleFile: ''example.fasta''). c first id

Records can be fetched by identifier rather than by position:

| c | c := Bio read: (Bio exampleFile: ''example.fasta''). (c atId: ''lcl|promoter'') size
| c | c := Bio read: (Bio exampleFile: ''example.fasta''). c includesId: ''nothing''

The usual collection messages are there, and answer plain collections:

| c | c := Bio read: (Bio exampleFile: ''example.fasta''). (c select: [:r | r size > 100]) size
| c | c := Bio read: (Bio exampleFile: ''example.fasta''). c lengths
| c | c := Bio read: (Bio exampleFile: ''example.fasta''). c sortedByLength first size

and the statistics an assembly is judged by:

| c | c := Bio read: (Bio exampleFile: ''example.fasta''). c totalLength
| c | c := Bio read: (Bio exampleFile: ''example.fasta''). c meanLength
| c | c := Bio read: (Bio exampleFile: ''example.fasta''). c n50
| c | c := Bio read: (Bio exampleFile: ''example.fasta''). c statistics

N50 is the length such that half of all the bases sit in contigs at least that
long.  It is a better summary of an assembly than the mean, because one long
contig and a thousand short ones should not look good.'!
records
	^TutorialLesson title: 'Records' text:
'A SeqRecord is an identifier, a description and a sequence, kept together.
Most of what the sequence can do, the record can do as well, so you rarely have
to unwrap it:

| r | r := (Bio read: (Bio exampleFile: ''example.fasta'')) first. r id
| r | r := (Bio read: (Bio exampleFile: ''example.fasta'')) first. r description
| r | r := (Bio read: (Bio exampleFile: ''example.fasta'')) first. r size
| r | r := (Bio read: (Bio exampleFile: ''example.fasta'')) first. r isProtein
| r | r := (Bio read: (Bio exampleFile: ''example.fasta'')) first. r sequence class

Make one by hand:

Bio record: ''test1'' sequence: ''ATGGCGTAA''
(Bio record: ''test1'' sequence: ''ATGGCGTAA'') translate asString
(Bio record: ''test1'' sequence: ''ATGGCGTAA'') gcPercent
(Bio record: ''test1'' sequence: ''ATGGCGTAA'') reverseComplement asString

A record carries a summary for when you just want to look at it:

(Bio record: ''test1'' sequence: ''ATGGCGTAACCCGGGTTTAAA'') summary

and it writes itself back out in the format it came from:

(Bio record: ''test1'' sequence: ''ATGGCGTAA'') asFasta'!
fastq
	^TutorialLesson title: 'FASTQ and quality' text:
'FASTQ is FASTA with a quality score for every base, which is what a sequencing
machine actually produces.  The scores are stored as characters.

| c | c := Bio readFastq: (Bio exampleFile: ''example.fastq''). c size
| c | c := Bio readFastq: (Bio exampleFile: ''example.fastq''). c first id
| c | c := Bio readFastq: (Bio exampleFile: ''example.fastq''). c first hasQuality

A quality of Q means the machine thinks the chance of that base being wrong is
ten to the minus Q over ten.  So 20 is one in a hundred and 30 is one in a
thousand:

| r | r := (Bio readFastq: (Bio exampleFile: ''example.fastq'')) first. r quality
| r | r := (Bio readFastq: (Bio exampleFile: ''example.fastq'')) first. r meanQuality
| r | r := (Bio readFastq: (Bio exampleFile: ''example.fastq'')) first. r minQuality
| r | r := (Bio readFastq: (Bio exampleFile: ''example.fastq'')) first. r maxQuality

The useful one for deciding whether to keep a read is the expected number of
wrong bases in it, which is the sum of the error probabilities:

| r | r := (Bio readFastq: (Bio exampleFile: ''example.fastq'')) first. r expectedErrors
| r | r := (Bio readFastq: (Bio exampleFile: ''example.fastq'')) first. r errorProbabilities first

There are two conventions for how a score is written as a character, differing
by 31, and reading a file with the wrong one gives you quality scores that are
wildly wrong.  The reader works out which is in use from the characters it
sees, assuming the modern one unless the file says otherwise.'!
genbank
	^TutorialLesson title: 'GenBank and features' text:
'A GenBank file says far more than a sequence: what organism it came from, and
where the genes, the coding sequences and everything else sit on it.  That is
what a feature is.

| r | r := (Bio readGenBank: (Bio exampleFile: ''example.gb'')) first. r id
| r | r := (Bio readGenBank: (Bio exampleFile: ''example.gb'')) first. r organism
| r | r := (Bio readGenBank: (Bio exampleFile: ''example.gb'')) first. r definition
| r | r := (Bio readGenBank: (Bio exampleFile: ''example.gb'')) first. r moleculeType
| r | r := (Bio readGenBank: (Bio exampleFile: ''example.gb'')) first. r taxonomy

The features are objects, each with a key, a location and some qualifiers:

| r | r := (Bio readGenBank: (Bio exampleFile: ''example.gb'')) first. r features size
| r | r := (Bio readGenBank: (Bio exampleFile: ''example.gb'')) first. r featureTypes
| r | r := (Bio readGenBank: (Bio exampleFile: ''example.gb'')) first. r cdsFeatures size
| r | r := (Bio readGenBank: (Bio exampleFile: ''example.gb'')) first. r genes

A location knows which strand it is on, which is the thing to watch:

| f | f := ((Bio readGenBank: (Bio exampleFile: ''example.gb'')) first) cdsFeatures first. f key
| f | f := ((Bio readGenBank: (Bio exampleFile: ''example.gb'')) first) cdsFeatures first. f location printString
| f | f := ((Bio readGenBank: (Bio exampleFile: ''example.gb'')) first) cdsFeatures first. f qualifierNames

and the sequence a feature covers is cut out, complemented when it should be:

| r f | r := (Bio readGenBank: (Bio exampleFile: ''example.gb'')) first. f := r cdsFeatures last. (r sequenceOf: f) asString'!
findingThings
	^TutorialLesson title: 'Finding things in a sequence' text:
'Looking for an exact stretch is an ordinary search:

| s | s := Bio dna: ''ACGTACGTAAGGTT''. s indicesOf: ''ACGT''
| s | s := Bio dna: ''ACGTACGTAAGGTT''. s includesPattern: ''AAGG''
| s | s := Bio dna: ''ACGTACGTAAGGTT''. s firstIndexOfPattern: ''GGTT''

Biology more often wants a pattern with ambiguity in it, and the IUPAC codes
are exactly that: N is anything, R is a purine, Y is a pyrimidine, W is A or T.
A pattern search understands them:

| s | s := Bio dna: ''ACGTACGTAAGGTT''. s indicesOfPattern: ''ACNT''
| s | s := Bio dna: ''ACGTACGTAAGGTT''. s indicesOfPattern: ''RRGG''
| s | s := Bio dna: ''ACGTACGTAAGGTT''. s occurrencesOfPattern: ''ACNT''

and because a site can sit on either strand, there is a message for both:

| s | s := Bio dna: ''ACGTACGTAAGGTT''. s indicesOfPatternBothStrands: ''AACC''

The other way of looking at composition is by words of length k, which is what
assemblers and the quick distance methods are built on:

| s | s := Bio dna: ''ACGTACGTAA''. s kmers: 3
| s | s := Bio dna: ''ACGTACGTAA''. s distinctKmers: 3
| s | s := Bio dna: ''ACGTACGTAA''. (s kmerCounts: 3) at: ''ACG''
| s | s := Bio dna: ''ACGTACGTAA''. s mostFrequentKmers: 3 count: 2'!
openReadingFrames
	^TutorialLesson title: 'Open reading frames' text:
'An open reading frame is a run from a start codon to a stop codon with no stop
in between: a guess at where a gene might be.  Asking for them is the first
thing you do with a stretch of DNA nobody has annotated.

| s | s := Bio dna: ''GGGATGGCGCATTTATAAGGG''. s orfs size
| s | s := Bio dna: ''GGGATGGCGCATTTATAAGGG''. s longestOrf printString

What comes back is a SeqFeature, the same kind of object a GenBank file gives
you, so an ORF you predicted and a gene somebody annotated are the same sort of
thing.  It knows where it is, which strand it is on, and what it codes for:

| o | o := (Bio dna: ''GGGATGGCGCATTTATAAGGG'') longestOrf. o start
| o | o := (Bio dna: ''GGGATGGCGCATTTATAAGGG'') longestOrf. o stop
| o | o := (Bio dna: ''GGGATGGCGCATTTATAAGGG'') longestOrf. o strand
| o | o := (Bio dna: ''GGGATGGCGCATTTATAAGGG'') longestOrf. o size
| o | o := (Bio dna: ''GGGATGGCGCATTTATAAGGG'') longestOrf. o translation
| o | o := (Bio dna: ''GGGATGGCGCATTTATAAGGG'') longestOrf. o qualifierAt: ''frame''

Both strands are searched, so an ORF on the reverse strand is found too.

Short ORFs turn up by chance all the time, so a minimum length is the usual
filter, and you can ask for one directly:

| s | s := Bio dna: ''GGGATGGCGCATTTATAAGGG''. (s orfsLongerThan: 5) size
| s | s := Bio dna: ''GGGATGGCGCATTTATAAGGG''. (s orfsLongerThan: 500) size

Once you have a coding sequence, its codon usage says something about the
organism it came from:

(Bio dna: ''ATGGCGCATTTATAA'') codonUsageReport'!
restrictionEnzymes
	^TutorialLesson title: 'Restriction enzymes' text:
'A restriction enzyme cuts DNA wherever a particular short sequence appears.
The package knows a set of the common ones:

Bio enzymes size
RestrictionEnzyme names
(RestrictionEnzyme named: ''EcoRI'') site
(RestrictionEnzyme named: ''EcoRI'') cut

The site is often a palindrome, which is what lets the enzyme cut both strands
the same way.  Find where one would cut:

| s | s := Bio dna: ''GGGGAATTCGGGGAATTCGG''. (RestrictionEnzyme named: ''EcoRI'') sitesIn: s
| s | s := Bio dna: ''GGGGAATTCGGGGAATTCGG''. (RestrictionEnzyme named: ''EcoRI'') cutPositionsIn: s
| s | s := Bio dna: ''GGGGAATTCGGGGAATTCGG''. ((RestrictionEnzyme named: ''EcoRI'') digest: s) collect: [:each | each asString]

Or go the other way and ask which enzymes cut a sequence at all, which is how
you choose one for a cloning experiment:

| s | s := Bio dna: ''GGGGAATTCGGGGGATCCGG''. s restrictionSites
| s | s := Bio dna: ''GGGGAATTCGGGGGATCCGG''. s restrictionReport

An enzyme that cuts once is useful; one that cuts ten times is not.  The report
is sorted so that the single cutters are easy to pick out.'!
alignment
	^TutorialLesson title: 'Pairwise alignment' text:
'Two sequences that are related are not identical, so comparing them means
lining them up with gaps where one has lost or gained something.  That is what
Needleman and Wunsch solved, and what the aligner does.

| a | a := Bio align: (Bio dna: ''ACGTACGTAA'') with: (Bio dna: ''ACGTCGTAA''). a firstAligned
| a | a := Bio align: (Bio dna: ''ACGTACGTAA'') with: (Bio dna: ''ACGTCGTAA''). a secondAligned
| a | a := Bio align: (Bio dna: ''ACGTACGTAA'') with: (Bio dna: ''ACGTCGTAA''). a score
| a | a := Bio align: (Bio dna: ''ACGTACGTAA'') with: (Bio dna: ''ACGTCGTAA''). a identityPercent
| a | a := Bio align: (Bio dna: ''ACGTACGTAA'') with: (Bio dna: ''ACGTCGTAA''). a matchLine

Note that those are sequences and not plain Strings.  The aligner asks what
alphabet it is dealing with before it chooses a scoring matrix, and a String
cannot answer.

The report puts the two rows together with the agreement marked between them:

(Bio align: (Bio dna: ''ACGTACGTAA'') with: (Bio dna: ''ACGTCGTAA'')) report

There are two kinds of alignment and the difference matters.  A GLOBAL one
lines up the whole of both sequences end to end; a LOCAL one finds the
best-matching stretch and ignores the rest, which is what you want when a short
thing sits inside a long one:

(Bio align: (Bio dna: ''GGGGGACGTACGTGGGGG'') with: (Bio dna: ''ACGTACGT'')) identityPercent
(Bio localAlign: (Bio dna: ''GGGGGACGTACGTGGGGG'') with: (Bio dna: ''ACGTACGT'')) identityPercent

Protein alignment needs a substitution matrix, because some swaps cost far less
than others.  The aligner picks one for you from the alphabet, or you can say:

(ScoringMatrix blosum62 scoreFor: $W and: $W)
(ScoringMatrix blosum62 scoreFor: $I and: $V)
(ScoringMatrix blosum62 scoreFor: $W and: $P)
(PairwiseAligner matrix: ScoringMatrix blosum62 gapOpen: 11 gapExtend: 1) align: (Bio protein: ''MKWVTF'') with: (Bio protein: ''MKWITF'')'!
theBrowser
	^TutorialLesson title: 'The sequence browser' text:
'For looking at a file rather than computing with it, there is a window.  Open
it from the System menu (right-click the desktop, then sequence browser), or
from here:

Bio openBrowser
Bio openBrowserOn: (Bio exampleFile: ''example.gb'')

The list on the left holds the records; the right pane shows the one you
select, and the menu on the right button changes what it shows: the sequence,
the features, the open reading frames, the translation, or the quality scores
for a FASTQ file.

The same text without a window, which is handy in a script:

SequenceBrowser load: (Bio exampleFile: ''example.gb'')
SequenceBrowser listItems
SequenceBrowser detailAt: 1
SequenceBrowser fileStatistics

The menu also writes the collection back out as FASTA, which is the quickest
way to convert a GenBank file into something another program will read:

(Bio readGenBank: (Bio exampleFile: ''example.gb'')) asFasta'!
whatNext
	^TutorialLesson title: 'Where to go next' text:
'That is the package.  Things worth remembering:

A sequence is an object, not a string: ask it rather than slicing it.

Reverse complement, and the frame, are where the bugs are.  The six-frame
translation exists because guessing is not safe.

Use the right genetic code; the standard one is not universal.

The classes are in the categories beginning with Bio.  The facade class Bio is
the short way in, and everything it does, the real classes do too.

Not in this package: multiple alignment, trees, BLAST-style database search,
read mapping, or variant calling.  The first two are in the Phylo package,
which builds on this one:

Smalltalk availablePackages

Try it, if you have not:

Smalltalk loadPackage: ''Phylo''

The package README is packages/Bio/README.md, and there is a Prolog bridge as
well: load Prolog and a sequence''s features can be queried as Prolog facts.

Other tutorials in this image:

Smalltalk tutorialNames

and the one for the language itself:

Smalltalk tutorial'! !
