"Reading and writing FASTA. A reader works the same way over a String or over a file: the file is read a line at a
time, so a multi-gigabyte FASTA does not have to fit in memory as long as you handle the records one by one with #do:."

Object subclass: #BioLineReader instanceVariableNames: 'text pos file pushed line' classVariableNames: '' category: 'Bio-IO'!
Object subclass: #BioReader instanceVariableNames: 'lines source' classVariableNames: '' category: 'Bio-IO'!
BioReader subclass: #FastaReader instanceVariableNames: '' classVariableNames: '' category: 'Bio-IO'!
BioReader subclass: #FastqReader instanceVariableNames: 'offset' classVariableNames: '' category: 'Bio-IO'!
Object subclass: #BioWriter instanceVariableNames: '' classVariableNames: '' category: 'Bio-IO'!
BioWriter subclass: #FastaWriter instanceVariableNames: '' classVariableNames: '' category: 'Bio-IO'!
BioWriter subclass: #FastqWriter instanceVariableNames: '' classVariableNames: '' category: 'Bio-IO'!

"---- a line source that works the same over a String and over a file ----"

!BioLineReader class methodsFor: 'instance creation'!
on: aString
	^self basicNew setText: aString!
onFile: aPath
	(FileStream exists: aPath) ifFalse: [^BioError new signal: 'no such file: ', aPath].
	^self basicNew setFile: (FileStream readOnlyFileNamed: aPath)! !

!BioLineReader methodsFor: 'private'!
setText: aString
	text := aString. pos := 1. pushed := nil!
setFile: aFileStream
	file := aFileStream. pushed := nil! !

!BioLineReader methodsFor: 'reading'!
nextLine
	"the next line without its terminator, or nil at the end"
	| start stop |
	pushed notNil ifTrue: [line := pushed. pushed := nil. ^line].
	file notNil ifTrue: [^line := file nextLine].
	pos > text size ifTrue: [^line := nil].
	start := pos.
	[pos <= text size and: [(text at: pos) ~= Character lf]] whileTrue: [pos := pos + 1].
	stop := pos - 1.
	(stop >= start and: [(text at: stop) value = 13]) ifTrue: [stop := stop - 1].
	pos := pos + 1.
	^line := text copyFrom: start to: stop!
peekLine
	| l |
	pushed notNil ifTrue: [^pushed].
	l := self nextLine.
	l notNil ifTrue: [pushed := l].
	^l!
pushBack: aLine
	pushed := aLine!
atEnd
	^self peekLine isNil!
close
	file notNil ifTrue: [file close. file := nil]!
skipBlankLines
	| l |
	[l := self peekLine. l notNil and: [l trimBoth isEmpty]] whileTrue: [self nextLine]! !

"---- the common part of the readers ----"

!BioReader class methodsFor: 'instance creation'!
on: aString
	^self basicNew setLines: (BioLineReader on: aString) source: 'string'!
onFile: aPath
	^self basicNew setLines: (BioLineReader onFile: aPath) source: aPath!
onLines: aLineReader
	^self basicNew setLines: aLineReader source: 'stream'! !

!BioReader class methodsFor: 'convenience'!
parse: aString
	"every record in the text, as a SequenceCollection"
	^(self on: aString) upToEnd!
readFile: aPath
	"every record in the file, as a SequenceCollection"
	| r c |
	r := self onFile: aPath.
	c := [r upToEnd] ensure: [r close].
	c name: aPath.
	^c!
file: aPath do: aBlock
	"evaluate aBlock with each record in turn, holding only one record at a time"
	| r |
	r := self onFile: aPath.
	[r do: aBlock] ensure: [r close]! !

!BioReader methodsFor: 'private'!
setLines: aLineReader source: aString
	lines := aLineReader. source := aString!
lines
	^lines! !

!BioReader methodsFor: 'reading'!
next
	"the next record, or nil at the end of the input"
	^self subclassResponsibility!
atEnd
	lines skipBlankLines.
	^lines atEnd!
do: aBlock
	| r |
	[(r := self next) notNil] whileTrue: [aBlock value: r]!
upToEnd
	"the remaining records as a SequenceCollection"
	| c |
	c := SequenceCollection named: source.
	self do: [:r | c add: r].
	^c!
next: n
	"at most n more records"
	| c r |
	c := OrderedCollection new.
	[c size < n and: [(r := self next) notNil]] whileTrue: [c add: r].
	^c asArray!
close
	lines close!
source
	^source! !

!BioReader methodsFor: 'parsing'!
idAndDescriptionOf: aHeader
	"an Array of the identifier and the rest of a > or @ line"
	| h i |
	h := aHeader trimBoth.
	i := 1.
	[i <= h size and: [(h at: i) isSeparator not]] whileTrue: [i := i + 1].
	^Array with: (h copyFrom: 1 to: i - 1) with: (h copyFrom: (i + 1 min: h size + 1) to: h size) trimBoth! !

"---- FASTA ----"

!FastaReader methodsFor: 'reading'!
next
	| line header parts seq out |
	lines skipBlankLines.
	line := lines nextLine.
	line isNil ifTrue: [^nil].
	[line notNil and: [line isEmpty or: [line first ~= $>]]] whileTrue: [
		(line notEmpty and: [line first = $;]) ifFalse: [
			line trimBoth notEmpty ifTrue: [^BioError new signal: 'FASTA: expected a > line, found: ', line]].
		line := lines nextLine].
	line isNil ifTrue: [^nil].
	header := line copyFrom: 2 to: line size.
	out := WriteStream on: (String new: 256).
	[lines atEnd not and: [lines peekLine isEmpty or: [lines peekLine first ~= $>]]] whileTrue: [
		| l |
		l := lines nextLine.
		(l notEmpty and: [l first = $;]) ifFalse: [out nextPutAll: l trimBoth]].
	parts := self idAndDescriptionOf: header.
	seq := BioSequence guess: out contents.
	^SeqRecord id: (parts at: 1) description: (parts at: 2) sequence: seq! !

!FastaReader class methodsFor: 'convenience'!
readDNA: aPath
	"read the file, keeping every sequence as DNA whatever its letters"
	| c |
	c := self readFile: aPath.
	c do: [:r | r sequence: r sequence asDNA].
	^c!
readProtein: aPath
	| c |
	c := self readFile: aPath.
	c do: [:r | r sequence: r sequence asProtein].
	^c! !

!FastaWriter class methodsFor: 'writing'!
write: aCollection to: aPath
	^self write: aCollection to: aPath wrapAt: 60!
write: aCollection to: aPath wrapAt: n
	"write the records to a file; answers how many were written"
	| count |
	count := 0.
	FileStream newFileNamed: aPath do: [:f |
		self recordsOf: aCollection do: [:r | f nextPutAll: (r asFastaWrapAt: n). count := count + 1]].
	^count!
append: aCollection to: aPath
	| count |
	count := 0.
	FileStream appendFileNamed: aPath do: [:f |
		self recordsOf: aCollection do: [:r | f nextPutAll: r asFasta. count := count + 1]].
	^count!
string: aCollection
	| out |
	out := WriteStream on: String new.
	self recordsOf: aCollection do: [:r | out nextPutAll: r asFasta].
	^out contents! !

!BioWriter class methodsFor: 'writing'!
recordsOf: aCollectionOrRecord do: aBlock
	"accept a SeqRecord, a SequenceCollection or any collection of records"
	(aCollectionOrRecord isKindOf: SeqRecord) ifTrue: [^aBlock value: aCollectionOrRecord].
	aCollectionOrRecord do: aBlock! !

"---- FASTQ ----"

!FastqReader class methodsFor: 'instance creation'!
on: aString offset: anInteger
	^(self on: aString) offset: anInteger; yourself!
onFile: aPath offset: anInteger
	^(self onFile: aPath) offset: anInteger; yourself! !

!FastqReader class methodsFor: 'quality'!
qualityString: scores offset: anInteger
	"the Phred scores as the characters a FASTQ file holds"
	| out |
	out := WriteStream on: (String new: scores size).
	scores do: [:q | out nextPut: (Character value: ((q + anInteger max: 33) min: 126))].
	^out contents!
scoresOf: aString offset: anInteger
	^(aString asArray collect: [:c | c value - anInteger]) asArray!
guessOffsetOf: aString
	"33 (Sanger, Illumina 1.8+) or 64 (Illumina 1.3 to 1.7). Phred+33 is assumed unless a character is too
	high to be one: scores above about 60 do not occur, so anything over '^' means the quality is Phred+64."
	| min max |
	aString isEmpty ifTrue: [^33].
	min := 126. max := 33.
	aString do: [:c | min := min min: c value. max := max max: c value].
	min < 64 ifTrue: [^33].
	max > 94 ifTrue: [^64].
	^33!
errorProbabilityOf: aScore
	^10 raisedTo: aScore / -10.0!
scoreOfProbability: p
	^(-10.0 * p log) rounded! !

!FastqReader methodsFor: 'accessing'!
offset
	"the ASCII offset of the quality characters; guessed from the first record when it was not set"
	^offset!
offset: anInteger
	offset := anInteger! !

!FastqReader methodsFor: 'reading'!
next
	| header seq qual parts r nseq nqual |
	lines skipBlankLines.
	header := lines nextLine.
	header isNil ifTrue: [^nil].
	(header notEmpty and: [header first = $@]) ifFalse: [^BioError new signal: 'FASTQ: expected a @ line, found: ', header].
	seq := WriteStream on: (String new: 256).
	nseq := 0.
	[lines atEnd not and: [lines peekLine isEmpty or: [lines peekLine first ~= $+]]] whileTrue: [
		| l |
		l := lines nextLine trimBoth. seq nextPutAll: l. nseq := nseq + l size].
	lines atEnd ifTrue: [^BioError new signal: 'FASTQ: record ', header, ' has no + line'].
	lines nextLine.
	qual := WriteStream on: (String new: 256).
	nqual := 0.
	[nqual < nseq and: [lines atEnd not]] whileTrue: [
		| l |
		l := lines nextLine trimBoth. qual nextPutAll: l. nqual := nqual + l size].
	nqual = nseq ifFalse: [
		^BioError new signal: 'FASTQ: record ', header, ' has ', nseq printString, ' bases but ', nqual printString, ' quality characters'].
	offset isNil ifTrue: [offset := FastqReader guessOffsetOf: qual contents].
	parts := self idAndDescriptionOf: (header copyFrom: 2 to: header size).
	r := SeqRecord id: (parts at: 1) description: (parts at: 2) sequence: (DNASequence raw: seq contents).
	r quality: (FastqReader scoresOf: qual contents offset: offset).
	^r! !

!FastqWriter class methodsFor: 'writing'!
write: aCollection to: aPath
	^self write: aCollection to: aPath offset: 33!
write: aCollection to: aPath offset: anInteger
	| count |
	count := 0.
	FileStream newFileNamed: aPath do: [:f |
		self recordsOf: aCollection do: [:r | f nextPutAll: (r asFastqOffset: anInteger). count := count + 1]].
	^count!
string: aCollection
	| out |
	out := WriteStream on: String new.
	self recordsOf: aCollection do: [:r | out nextPutAll: r asFastq].
	^out contents! !

"---- quality statistics over a set of reads ----"

!SequenceCollection methodsFor: 'quality'!
qualityReport
	"the usual read-quality summary of a FASTQ file"
	| n withQ sumLen sumQ minQ maxQ q20 q30 totalBases out |
	n := records size.
	withQ := 0. sumLen := 0. sumQ := 0. minQ := nil. maxQ := nil. q20 := 0. q30 := 0. totalBases := 0.
	records do: [:r |
		sumLen := sumLen + r size.
		r hasQuality ifTrue: [
			withQ := withQ + 1.
			r quality do: [:v |
				totalBases := totalBases + 1.
				sumQ := sumQ + v.
				minQ := minQ isNil ifTrue: [v] ifFalse: [minQ min: v].
				maxQ := maxQ isNil ifTrue: [v] ifFalse: [maxQ max: v].
				v >= 20 ifTrue: [q20 := q20 + 1].
				v >= 30 ifTrue: [q30 := q30 + 1]]]].
	out := WriteStream on: String new.
	out nextPutAll: self name; nextPutAll: ': '; print: n; nextPutAll: ' reads, '; print: sumLen; nextPutAll: ' bases'; nl.
	withQ = 0 ifTrue: [out nextPutAll: 'no quality scores'; nl. ^out contents].
	out nextPutAll: 'mean length    '; nextPutAll: ((sumLen / n) asFloat printShowingDecimalPlaces: 1); nl.
	out nextPutAll: 'mean quality   '; nextPutAll: ((sumQ / totalBases) asFloat printShowingDecimalPlaces: 2); nl.
	out nextPutAll: 'quality range  '; print: minQ; nextPutAll: ' to '; print: maxQ; nl.
	out nextPutAll: 'bases >= Q20   '; nextPutAll: (q20 * 100.0 / totalBases printShowingDecimalPlaces: 2); nextPut: $%; nl.
	out nextPutAll: 'bases >= Q30   '; nextPutAll: (q30 * 100.0 / totalBases printShowingDecimalPlaces: 2); nextPut: $%; nl.
	^out contents!
meanQualityByPosition
	"the mean Phred score at each position across the reads, as an Array"
	| sums counts n |
	n := 0.
	records do: [:r | r hasQuality ifTrue: [n := n max: r size]].
	n = 0 ifTrue: [^Array new].
	sums := Array new: n withAll: 0.
	counts := Array new: n withAll: 0.
	records do: [:r |
		r hasQuality ifTrue: [
			r quality doWithIndex: [:v :i |
				sums at: i put: (sums at: i) + v.
				counts at: i put: (counts at: i) + 1]]].
	^(1 to: n) collect: [:i | (counts at: i) = 0 ifTrue: [0.0] ifFalse: [((sums at: i) / (counts at: i)) asFloat]]!
trimQualityBelow: threshold
	"every read trimmed at both ends, dropping the ones left empty"
	^SequenceCollection withAll: ((records collect: [:r | r trimQualityBelow: threshold]) reject: [:r | r isEmpty])! !
