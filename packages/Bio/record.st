"Records and their annotation. A SeqRecord is a named sequence with optional per-base quality, features and
annotations: what one entry of a FASTA, FASTQ or GenBank file holds. A SeqFeature has a key ('CDS', 'gene' ...),
a SeqLocation and qualifiers. A SequenceCollection is a set of records with the statistics one wants over an
assembly or a set of reads."

Object subclass: #SeqRecord instanceVariableNames: 'id description sequence quality features annotations' classVariableNames: '' category: 'Bio-Records'!
Object subclass: #SeqFeature instanceVariableNames: 'key location qualifiers' classVariableNames: '' category: 'Bio-Records'!
Object subclass: #SeqLocation instanceVariableNames: 'start stop strand parts operator fuzzyStart fuzzyEnd remote' classVariableNames: '' category: 'Bio-Records'!
Object subclass: #SequenceCollection instanceVariableNames: 'name records index' classVariableNames: '' category: 'Bio-Records'!

"---- SeqRecord ----"

!SeqRecord class methodsFor: 'instance creation'!
id: anId sequence: aSequence
	^self id: anId description: '' sequence: aSequence!
id: anId description: aString sequence: aSequence
	^self basicNew setId: anId description: aString sequence: aSequence!
on: aSequenceOrString
	^self id: 'unnamed' description: '' sequence: aSequenceOrString! !

!SeqRecord methodsFor: 'private'!
setId: anId description: aString sequence: aSequence
	id := anId asString.
	description := aString ifNil: [''].
	sequence := (aSequence isKindOf: BioSequence) ifTrue: [aSequence] ifFalse: [BioSequence guess: aSequence asString].
	features := OrderedCollection new.
	annotations := Dictionary new! !

!SeqRecord methodsFor: 'accessing'!
id
	^id!
id: aString
	id := aString asString!
name
	^id!
description
	^description!
description: aString
	description := aString ifNil: ['']!
sequence
	^sequence!
sequence: aSequence
	sequence := (aSequence isKindOf: BioSequence) ifTrue: [aSequence] ifFalse: [BioSequence guess: aSequence asString]!
quality
	"the Phred scores of a FASTQ read, or nil"
	^quality!
quality: anArray
	quality := anArray!
hasQuality
	^quality notNil!
features
	^features!
features: aCollection
	features := aCollection asOrderedCollection!
annotations
	^annotations!
annotationAt: aKey
	^annotations at: aKey asSymbol ifAbsent: [nil]!
annotationAt: aKey put: aValue
	^annotations at: aKey asSymbol put: aValue!
annotationAt: aKey ifAbsent: aBlock
	^annotations at: aKey asSymbol ifAbsent: aBlock! !

!SeqRecord methodsFor: 'annotation'!
accession
	^self annotationAt: #accession!
version
	^self annotationAt: #version!
organism
	^self annotationAt: #organism!
taxonomy
	^self annotationAt: #taxonomy ifAbsent: [#()]!
moleculeType
	^self annotationAt: #moleculeType!
topology
	^self annotationAt: #topology!
definition
	^self annotationAt: #definition ifAbsent: [description]!
keywords
	^self annotationAt: #keywords!
date
	^self annotationAt: #date!
isCircular
	^self topology = 'circular'! !

!SeqRecord methodsFor: 'sequence protocol'!
size
	^sequence size!
isEmpty
	^sequence isEmpty!
notEmpty
	^sequence notEmpty!
asString
	^sequence asString!
at: anInteger
	^sequence at: anInteger!
gc
	^sequence gc!
gcPercent
	^sequence gcPercent!
composition
	^sequence composition!
isNucleotide
	^sequence isNucleotide!
isProtein
	^sequence isProtein!
translate
	^sequence translate!
translateWith: aGeneticCode
	^aGeneticCode translate: sequence!
gcSkew
	^sequence gcSkew!
meltingTemperature
	^sequence meltingTemperature!
molecularWeight
	^sequence molecularWeight!
isoelectricPoint
	^sequence isoelectricPoint!
orfs
	^sequence orfs!
orfsLongerThan: n
	^sequence orfsLongerThan: n!
longestOrf
	^sequence longestOrf!
codonUsage
	^sequence codonUsage!
codonUsageReport
	^sequence codonUsageReport!
restrictionSites
	^sequence restrictionSites!
restrictionReport
	^sequence restrictionReport!
digestWith: aName
	^sequence digestWith: aName!
indicesOf: aPattern
	^sequence indicesOf: aPattern!
indicesOfPattern: aPattern
	^sequence indicesOfPattern: aPattern!
kmerCounts: k
	^sequence kmerCounts: k!
alignWith: anotherRecordOrSequence
	^sequence alignWith: anotherRecordOrSequence asSequence!
localAlignWith: anotherRecordOrSequence
	^sequence localAlignWith: anotherRecordOrSequence asSequence!
asSequence
	^sequence!
reverseComplement
	"a new record holding the reverse complement (features are not carried over)"
	| r |
	r := SeqRecord id: id description: description, ' (reverse complement)' sequence: sequence reverseComplement.
	annotations keysAndValuesDo: [:k :v | r annotationAt: k put: v].
	^r!
subsequenceFrom: first to: last
	"a new record for part of this one, keeping the features that fall entirely inside it (renumbered)"
	| r |
	r := SeqRecord id: id, '_', first printString, '-', last printString
		description: description
		sequence: (sequence copyFrom: first to: last).
	features do: [:f |
		(f start >= first and: [f stop <= last]) ifTrue: [r features add: (f translatedBy: 1 - first)]].
	^r! !

!SeqRecord methodsFor: 'features'!
addFeature: aFeature
	features add: aFeature.
	^aFeature!
featuresOfType: aKey
	| k |
	k := aKey asString asLowercase.
	^(features select: [:f | f key asLowercase = k]) asArray!
featureTypes
	| seen |
	seen := OrderedCollection new.
	features do: [:f | (seen includes: f key) ifFalse: [seen add: f key]].
	^seen asArray!
featuresAt: aPosition
	^(features select: [:f | f location includes: aPosition]) asArray!
cdsFeatures
	^self featuresOfType: 'CDS'!
genes
	^self featuresOfType: 'gene'!
sequenceOf: aFeature
	"the (spliced, oriented) sequence a feature covers"
	^aFeature extractFrom: sequence!
rawProteinOf: aFeature
	"the literal translation of the bases a feature covers, using its /transl_table and /codon_start"
	| nt code offset |
	nt := self sequenceOf: aFeature.
	code := (aFeature qualifierAt: 'transl_table')
		ifNil: [GeneticCode standard]
		ifNotNil: [:t | GeneticCode id: t asNumber].
	offset := (aFeature qualifierAt: 'codon_start') ifNil: [1] ifNotNil: [:c | c asNumber].
	^code translate: nt from: offset!
proteinOf: aFeature
	"the protein of a CDS feature, as its /translation would hold it: a single trailing stop is dropped"
	| p s |
	p := self rawProteinOf: aFeature.
	s := p asString.
	^(s notEmpty and: [s last = $*])
		ifTrue: [ProteinSequence raw: (s copyFrom: 1 to: s size - 1)]
		ifFalse: [p]! !

!SeqRecord methodsFor: 'writing'!
asFasta
	^self asFastaWrapAt: 60!
asFastaWrapAt: n
	| out |
	out := WriteStream on: (String new: sequence size + 80).
	out nextPut: $>; nextPutAll: id.
	description notEmpty ifTrue: [out nextPut: $ ; nextPutAll: description].
	out nl; nextPutAll: (sequence wrappedAt: n).
	^out contents!
asFastq
	^self asFastqOffset: 33!
asFastqOffset: offset
	| out |
	quality isNil ifTrue: [^BioError new signal: 'record ', id, ' has no quality scores'].
	out := WriteStream on: (String new: sequence size * 2 + 80).
	out nextPut: $@; nextPutAll: id.
	description notEmpty ifTrue: [out nextPut: $ ; nextPutAll: description].
	out nl; nextPutAll: sequence asString; nl; nextPutAll: '+'; nl;
		nextPutAll: (FastqReader qualityString: quality offset: offset); nl.
	^out contents! !

!SeqRecord methodsFor: 'quality'!
meanQuality
	| sum |
	(quality isNil or: [quality isEmpty]) ifTrue: [^nil].
	sum := 0.
	quality do: [:q | sum := sum + q].
	^sum / quality size!
minQuality
	^(quality isNil or: [quality isEmpty]) ifTrue: [nil] ifFalse: [quality inject: (quality at: 1) into: [:a :b | a min: b]]!
maxQuality
	^(quality isNil or: [quality isEmpty]) ifTrue: [nil] ifFalse: [quality inject: (quality at: 1) into: [:a :b | a max: b]]!
errorProbabilities
	"the chance each base is wrong, from its Phred score"
	^quality isNil ifTrue: [nil] ifFalse: [quality collect: [:q | 10 raisedTo: q / -10.0]]!
expectedErrors
	| sum |
	quality isNil ifTrue: [^nil].
	sum := 0.
	self errorProbabilities do: [:p | sum := sum + p].
	^sum!
trimQualityBelow: threshold
	"a new record with low-quality bases trimmed from both ends"
	| first last |
	quality isNil ifTrue: [^self].
	first := 1. last := quality size.
	[first <= last and: [(quality at: first) < threshold]] whileTrue: [first := first + 1].
	[last >= first and: [(quality at: last) < threshold]] whileTrue: [last := last - 1].
	^self copyFrom: first to: last!
copyFrom: first to: last
	| r |
	last < first ifTrue: [
		r := SeqRecord id: id description: description sequence: (sequence copyFrom: 1 to: 0).
		quality notNil ifTrue: [r quality: Array new].
		^r].
	r := SeqRecord id: id description: description sequence: (sequence copyFrom: first to: last).
	quality notNil ifTrue: [r quality: (quality copyFrom: first to: last)].
	^r! !

!SeqRecord methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'SeqRecord('; nextPutAll: id; nextPutAll: ', '; print: sequence size;
		nextPutAll: ' '; nextPutAll: (sequence isNucleotide ifTrue: ['bp'] ifFalse: ['aa']).
	features notEmpty ifTrue: [aStream nextPutAll: ', '; print: features size; nextPutAll: ' features'].
	aStream nextPut: $)!
summary
	"a readable description of the record, for the browser and the Transcript"
	| out |
	out := WriteStream on: String new.
	out nextPutAll: id.
	description notEmpty ifTrue: [out nextPutAll: '  '; nextPutAll: description].
	out nl.
	out nextPutAll: sequence class moleculeName; nextPutAll: ', '; print: sequence size;
		nextPutAll: (sequence isNucleotide ifTrue: [' bp'] ifFalse: [' aa']).
	sequence isNucleotide ifTrue: [out nextPutAll: ', GC '; nextPutAll: (sequence gcPercent printShowingDecimalPlaces: 1); nextPut: $%].
	quality notNil ifTrue: [out nextPutAll: ', mean quality '; nextPutAll: (self meanQuality asFloat printShowingDecimalPlaces: 1)].
	out nl.
	self organism notNil ifTrue: [out nextPutAll: 'organism: '; nextPutAll: self organism; nl].
	self accession notNil ifTrue: [out nextPutAll: 'accession: '; nextPutAll: self accession asString; nl].
	features notEmpty ifTrue: [
		out nextPutAll: 'features: '; print: features size; nextPutAll: ' ('.
		self featureTypes doWithIndex: [:t :i |
			i > 1 ifTrue: [out nextPutAll: ', '].
			out nextPutAll: t; nextPut: $ ; print: (self featuresOfType: t) size].
		out nextPutAll: ')'; nl].
	out nl; nextPutAll: (sequence wrappedAt: 60).
	^out contents! !

"---- SeqFeature ----"

!SeqFeature class methodsFor: 'instance creation'!
key: aString location: aLocation
	^self basicNew setKey: aString location: aLocation! !

!SeqFeature methodsFor: 'private'!
setKey: aString location: aLocation
	key := aString. location := aLocation. qualifiers := OrderedCollection new! !

!SeqFeature methodsFor: 'accessing'!
key
	^key!
key: aString
	key := aString!
location
	^location!
location: aLocation
	location := aLocation!
qualifiers
	"an OrderedCollection of Associations (a qualifier may appear more than once)"
	^qualifiers!
addQualifier: aName value: aValue
	qualifiers add: aName -> aValue!
qualifierAt: aName
	"the value of the first qualifier with this name, or nil"
	| n |
	n := aName asString.
	qualifiers do: [:a | a key = n ifTrue: [^a value]].
	^nil!
qualifierAt: aName ifAbsent: aBlock
	^(self qualifierAt: aName) ifNil: [aBlock value]!
qualifiersAt: aName
	"every value with this name"
	| n |
	n := aName asString.
	^((qualifiers select: [:a | a key = n]) collect: [:a | a value]) asArray!
qualifierNames
	^(qualifiers collect: [:a | a key]) asArray!
start
	^location start!
stop
	^location stop!
strand
	^location strand!
size
	^location size! !

!SeqFeature methodsFor: 'common qualifiers'!
gene
	^self qualifierAt: 'gene'!
product
	^self qualifierAt: 'product'!
locusTag
	^self qualifierAt: 'locus_tag'!
proteinId
	^self qualifierAt: 'protein_id'!
note
	^self qualifierAt: 'note'!
translation
	^self qualifierAt: 'translation'!
label
	"the most useful name the feature has"
	^self gene ifNil: [self locusTag ifNil: [self product ifNil: [self proteinId ifNil: [key]]]]! !

!SeqFeature methodsFor: 'operations'!
extractFrom: aSequence
	^location extractFrom: aSequence!
translatedBy: delta
	| f |
	f := SeqFeature key: key location: (location translatedBy: delta).
	qualifiers do: [:a | f addQualifier: a key value: a value].
	^f!
overlaps: aFeature
	^location overlaps: aFeature location! !

!SeqFeature methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: key; nextPut: $ ; print: location.
	self label = key ifFalse: [aStream nextPutAll: ' '; nextPutAll: self label]!
details
	| out |
	out := WriteStream on: String new.
	out nextPutAll: key; nextPutAll: '  '; print: location; nl.
	qualifiers do: [:a |
		out nextPutAll: '    /'; nextPutAll: a key.
		a value = true ifFalse: [out nextPut: $=; nextPutAll: a value asString].
		out nl].
	^out contents! !

"---- SeqLocation ----"

!SeqLocation class methodsFor: 'instance creation'!
from: aStart to: aStop
	^self from: aStart to: aStop strand: 1!
from: aStart to: aStop strand: aStrand
	^self basicNew setFrom: aStart to: aStop strand: aStrand!
join: aCollection strand: aStrand
	"a spliced location: the parts in the order they are joined"
	| l parts |
	parts := aCollection asArray.
	parts isEmpty ifTrue: [^self from: 0 to: 0].
	l := self from: (parts inject: (parts first) start into: [:a :p | a min: p start])
		to: (parts inject: (parts first) stop into: [:a :p | a max: p stop])
		strand: aStrand.
	l setParts: parts operator: #join.
	^l! !

!SeqLocation methodsFor: 'private'!
setFrom: aStart to: aStop strand: aStrand
	start := aStart. stop := aStop. strand := aStrand.
	parts := nil. operator := #single. fuzzyStart := false. fuzzyEnd := false!
setParts: anArray operator: aSymbol
	parts := anArray. operator := aSymbol! !

!SeqLocation methodsFor: 'accessing'!
start
	"the leftmost base, 1-based inclusive"
	^start!
stop
	"the rightmost base, 1-based inclusive"
	^stop!
strand
	"1 for the given strand, -1 for the complement"
	^strand!
strand: anInteger
	strand := anInteger!
parts
	"the pieces of a join, or an Array with just the receiver"
	^parts ifNil: [Array with: self]!
operator
	^operator!
remote
	"the accession of another record this location points into, or nil"
	^remote!
remote: aString
	remote := aString!
fuzzyStart
	"true for a <123 location whose real start is unknown"
	^fuzzyStart == true!
fuzzyStart: aBoolean
	fuzzyStart := aBoolean!
fuzzyEnd
	^fuzzyEnd == true!
fuzzyEnd: aBoolean
	fuzzyEnd := aBoolean!
size
	"the number of bases the location covers (a join counts its parts)"
	parts isNil ifTrue: [^stop - start + 1 max: 0].
	^parts inject: 0 into: [:a :p | a + p size]! !

!SeqLocation methodsFor: 'testing'!
isJoin
	^parts notNil!
isComplement
	^strand = -1!
isRemote
	^remote notNil!
includes: aPosition
	parts isNil ifTrue: [^aPosition between: start and: stop].
	^parts anySatisfy: [:p | p includes: aPosition]!
overlaps: aLocation
	^(start <= aLocation stop) and: [aLocation start <= stop]! !

!SeqLocation methodsFor: 'operations'!
translatedBy: delta
	| l |
	parts isNil ifTrue: [
		l := SeqLocation from: start + delta to: stop + delta strand: strand.
		l fuzzyStart: self fuzzyStart; fuzzyEnd: self fuzzyEnd.
		^l].
	^SeqLocation join: (parts collect: [:p | p translatedBy: delta]) strand: strand!
extractFrom: aSequence
	"the bases this location covers, spliced in order and reverse-complemented when it is on the minus strand"
	| sub |
	parts isNil
		ifTrue: [
			(start < 1 or: [stop > aSequence size]) ifTrue: [^BioError new signal: 'location ', self printString, ' is outside the sequence'].
			sub := aSequence copyFrom: start to: stop]
		ifFalse: [
			sub := nil.
			parts do: [:p |
				| piece |
				piece := p extractFromUnoriented: aSequence.
				sub := sub isNil ifTrue: [piece] ifFalse: [sub , piece]].
			sub isNil ifTrue: [^aSequence copyFrom: 1 to: 0]].
	^strand = -1 ifTrue: [sub reverseComplement] ifFalse: [sub]!
extractFromUnoriented: aSequence
	"the bases of one part, complemented only if the part itself says so"
	| sub |
	parts isNil ifFalse: [^self extractFrom: aSequence].
	(start < 1 or: [stop > aSequence size]) ifTrue: [^BioError new signal: 'location ', self printString, ' is outside the sequence'].
	sub := aSequence copyFrom: start to: stop.
	^strand = -1 ifTrue: [sub reverseComplement] ifFalse: [sub]! !

!SeqLocation methodsFor: 'printing'!
printOn: aStream
	"the location as GenBank writes it"
	| body |
	body := WriteStream on: String new.
	remote notNil ifTrue: [body nextPutAll: remote; nextPut: $:].
	parts isNil
		ifTrue: [
			self fuzzyStart ifTrue: [body nextPut: $<].
			body print: start.
			stop = start ifFalse: [
				body nextPutAll: '..'.
				self fuzzyEnd ifTrue: [body nextPut: $>].
				body print: stop]]
		ifFalse: [
			body nextPutAll: operator asString; nextPut: $(.
			parts doWithIndex: [:p :i | i > 1 ifTrue: [body nextPut: $,]. body nextPutAll: p printString].
			body nextPut: $)].
	strand = -1
		ifTrue: [aStream nextPutAll: 'complement('; nextPutAll: body contents; nextPut: $)]
		ifFalse: [aStream nextPutAll: body contents]! !

"---- SequenceCollection ----"

!SequenceCollection class methodsFor: 'instance creation'!
new
	^self basicNew setRecords: OrderedCollection new!
withAll: aCollection
	^self basicNew setRecords: aCollection asOrderedCollection!
named: aString
	^self new name: aString; yourself! !

!SequenceCollection methodsFor: 'private'!
setRecords: aCollection
	records := aCollection. index := nil! !

!SequenceCollection methodsFor: 'accessing'!
name
	^name ifNil: ['sequences']!
name: aString
	name := aString!
records
	^records!
size
	^records size!
isEmpty
	^records isEmpty!
notEmpty
	^records notEmpty!
at: anInteger
	^records at: anInteger!
first
	^records first!
last
	^records last!
do: aBlock
	records do: aBlock!
doWithIndex: aBlock
	records doWithIndex: aBlock!
add: aRecord
	index := nil.
	^records add: aRecord!
addAll: aCollection
	index := nil.
	^records addAll: ((aCollection isKindOf: SequenceCollection) ifTrue: [aCollection records] ifFalse: [aCollection])!
, aCollection
	^SequenceCollection withAll: records, ((aCollection isKindOf: SequenceCollection) ifTrue: [aCollection records] ifFalse: [aCollection])!
select: aBlock
	^SequenceCollection withAll: (records select: aBlock)!
reject: aBlock
	^SequenceCollection withAll: (records reject: aBlock)!
collect: aBlock
	"an OrderedCollection of whatever the block answers (use select: to get another SequenceCollection)"
	^records collect: aBlock!
detect: aBlock ifNone: aNoneBlock
	^records detect: aBlock ifNone: aNoneBlock!
detect: aBlock
	^records detect: aBlock!
anySatisfy: aBlock
	^records anySatisfy: aBlock!
allSatisfy: aBlock
	^records allSatisfy: aBlock!
count: aBlock
	^records count: aBlock!
includes: aRecord
	^records includes: aRecord!
inject: a into: aBlock
	^records inject: a into: aBlock!
asArray
	^records asArray!
asOrderedCollection
	^records copy! !

!SequenceCollection methodsFor: 'searching'!
idIndex
	index notNil ifTrue: [^index].
	index := Dictionary new.
	records do: [:r | (index includesKey: r id) ifFalse: [index at: r id put: r]].
	^index!
atId: aString
	"the record with this id, or nil"
	^self idIndex at: aString ifAbsent: [nil]!
atId: aString ifAbsent: aBlock
	^self idIndex at: aString ifAbsent: aBlock!
includesId: aString
	^self idIndex includesKey: aString!
ids
	^(records collect: [:r | r id]) asArray!
withDescriptionMatching: aString
	| pat |
	pat := aString asLowercase.
	^self select: [:r | r description asLowercase includesSubstring: pat]! !

!SequenceCollection methodsFor: 'statistics'!
lengths
	^(records collect: [:r | r size]) asArray!
totalLength
	^records inject: 0 into: [:a :r | a + r size]!
minLength
	^records isEmpty ifTrue: [0] ifFalse: [self lengths inject: records first size into: [:a :b | a min: b]]!
maxLength
	^records isEmpty ifTrue: [0] ifFalse: [self lengths inject: 0 into: [:a :b | a max: b]]!
meanLength
	^records isEmpty ifTrue: [0] ifFalse: [self totalLength / records size]!
medianLength
	| sorted n |
	records isEmpty ifTrue: [^0].
	sorted := self lengths asSortedCollection asArray.
	n := sorted size.
	^n odd ifTrue: [sorted at: n + 1 // 2] ifFalse: [((sorted at: n // 2) + (sorted at: n // 2 + 1)) / 2]!
nStatistic: percent
	"the length such that sequences at least that long hold this percentage of all the bases (N50 is nStatistic: 50)"
	| sorted target sum |
	records isEmpty ifTrue: [^0].
	sorted := (self lengths asSortedCollection: [:a :b | a >= b]) asArray.
	target := self totalLength * percent / 100.
	sum := 0.
	sorted do: [:l | sum := sum + l. sum >= target ifTrue: [^l]].
	^sorted last!
lStatistic: percent
	"how many sequences are needed to reach this percentage of all the bases (L50 is lStatistic: 50)"
	| sorted target sum n |
	records isEmpty ifTrue: [^0].
	sorted := (self lengths asSortedCollection: [:a :b | a >= b]) asArray.
	target := self totalLength * percent / 100.
	sum := 0. n := 0.
	sorted do: [:l | sum := sum + l. n := n + 1. sum >= target ifTrue: [^n]].
	^n!
n50
	^self nStatistic: 50!
l50
	^self lStatistic: 50!
n90
	^self nStatistic: 90!
gcPercent
	"the GC of all the nucleotide records together"
	| gc at |
	gc := 0. at := 0.
	records do: [:r | r isNucleotide ifTrue: [gc := gc + r sequence gcCount. at := at + r sequence atCount]].
	gc + at = 0 ifTrue: [^0.0].
	^gc * 100.0 / (gc + at)!
sortedByLength
	^SequenceCollection withAll: (records asSortedCollection: [:a :b | a size >= b size]) asOrderedCollection!
longest
	^records isEmpty ifTrue: [nil] ifFalse: [records inject: records first into: [:a :r | a size >= r size ifTrue: [a] ifFalse: [r]]]!
shortest
	^records isEmpty ifTrue: [nil] ifFalse: [records inject: records first into: [:a :r | a size <= r size ifTrue: [a] ifFalse: [r]]]!
statistics
	"the usual summary of a set of sequences"
	| out |
	out := WriteStream on: String new.
	out nextPutAll: self name; nextPutAll: ': '; print: records size; nextPutAll: ' sequences'; nl.
	records isEmpty ifTrue: [^out contents].
	out nextPutAll: 'total length   '; print: self totalLength; nl.
	out nextPutAll: 'shortest       '; print: self minLength; nl.
	out nextPutAll: 'longest        '; print: self maxLength; nl.
	out nextPutAll: 'mean           '; nextPutAll: (self meanLength asFloat printShowingDecimalPlaces: 1); nl.
	out nextPutAll: 'median         '; nextPutAll: (self medianLength asFloat printShowingDecimalPlaces: 1); nl.
	out nextPutAll: 'N50            '; print: self n50; nl.
	out nextPutAll: 'L50            '; print: self l50; nl.
	out nextPutAll: 'N90            '; print: self n90; nl.
	out nextPutAll: 'GC             '; nextPutAll: (self gcPercent printShowingDecimalPlaces: 2); nextPut: $%; nl.
	^out contents! !

!SequenceCollection methodsFor: 'writing'!
asFasta
	| out |
	out := WriteStream on: (String new: self totalLength + records size * 80).
	records do: [:r | out nextPutAll: r asFasta].
	^out contents!
writeFastaTo: aPath
	^FastaWriter write: self to: aPath!
writeFastqTo: aPath
	^FastqWriter write: self to: aPath! !

!SequenceCollection methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'SequenceCollection('; print: records size; nextPutAll: ' records, '; print: self totalLength; nextPutAll: ' bp)'! !
