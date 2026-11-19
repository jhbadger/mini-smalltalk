"Reading GenBank flat files: the header fields, the FEATURES table with its qualifiers, and the ORIGIN sequence.
Locations are parsed into SeqLocations, so join(12..78,134..202) and complement(<1..206) keep their meaning and can
pull the right bases out of the sequence."

BioReader subclass: #GenBankReader instanceVariableNames: '' classVariableNames: '' category: 'Bio-IO'!
Object subclass: #GenBankLocationParser instanceVariableNames: 'text pos' classVariableNames: '' category: 'Bio-IO'!

"---- locations ----"

!SeqLocation class methodsFor: 'parsing'!
fromString: aString
	"a GenBank location: 467, 340..565, complement(1..10), join(12..78,134..202), <1..206, J00194.1:1..10"
	^(GenBankLocationParser on: aString) parse! !

!GenBankLocationParser class methodsFor: 'instance creation'!
on: aString
	^self basicNew setText: aString! !

!GenBankLocationParser methodsFor: 'private'!
setText: aString
	text := aString reject: [:c | c isSeparator].
	pos := 1!
atEnd
	^pos > text size!
peek
	^pos <= text size ifTrue: [text at: pos] ifFalse: [nil]!
next
	| c |
	c := self peek. pos := pos + 1. ^c!
error: aMessage
	^BioError new signal: 'bad location ', text printString, ': ', aMessage!
accept: aString
	"true (and move past it) if the text continues with aString"
	(pos + aString size - 1 <= text size and: [(text copyFrom: pos to: pos + aString size - 1) = aString])
		ifFalse: [^false].
	pos := pos + aString size.
	^true!
number
	| start |
	start := pos.
	[self peek notNil and: [self peek isDigit]] whileTrue: [pos := pos + 1].
	start = pos ifTrue: [^self error: 'a number was expected'].
	^(text copyFrom: start to: pos - 1) asNumber!
identifier
	"an accession before a colon, or nil"
	| start save |
	save := pos.
	start := pos.
	[self peek notNil and: [self peek isLetter or: [self peek isDigit or: ['._' includes: self peek]]]] whileTrue: [pos := pos + 1].
	(self peek = $: and: [pos > start]) ifTrue: [
		| id |
		id := text copyFrom: start to: pos - 1.
		pos := pos + 1.
		^id].
	pos := save.
	^nil! !

!GenBankLocationParser methodsFor: 'parsing'!
parse
	| l |
	text isEmpty ifTrue: [^self error: 'it is empty'].
	l := self location.
	self atEnd ifFalse: [^self error: 'unexpected ', (text copyFrom: pos to: text size)].
	^l!
location
	| remote l |
	(self accept: 'complement(') ifTrue: [
		l := self location.
		(self accept: ')') ifFalse: [^self error: 'a ) was expected'].
		^self complementOf: l].
	(self accept: 'join(') ifTrue: [^self groupWithOperator: #join].
	(self accept: 'order(') ifTrue: [^self groupWithOperator: #order].
	(self accept: 'bond(') ifTrue: [^self groupWithOperator: #bond].
	(self accept: 'gap(') ifTrue: [^self gap].
	remote := self identifier.
	l := self span.
	remote notNil ifTrue: [l remote: remote].
	^l!
groupWithOperator: aSymbol
	| parts l |
	parts := OrderedCollection new.
	[parts add: self location.
	 self accept: ','] whileTrue.
	(self accept: ')') ifFalse: [^self error: 'a ) was expected'].
	parts size = 1 ifTrue: [^parts first].
	l := SeqLocation join: parts strand: 1.
	l setParts: parts asArray operator: aSymbol.
	^l!
gap
	"gap(100) or gap(unk100): a run of unknown bases, kept as a zero-based placeholder"
	| n |
	self accept: 'unk'.
	n := (self peek notNil and: [self peek isDigit]) ifTrue: [self number] ifFalse: [0].
	(self accept: ')') ifFalse: [^self error: 'a ) was expected'].
	^SeqLocation from: 1 to: n!
span
	"467, 340..565, <1..206, 102.110, 123^124"
	| fuzzyStart start fuzzyEnd stop l |
	fuzzyStart := self accept: '<'.
	self accept: '>'.
	start := self number.
	fuzzyEnd := false.
	stop := start.
	(self accept: '..') ifTrue: [
		fuzzyEnd := self accept: '>'.
		self accept: '<'.
		stop := self number]
	ifFalse: [
		((self accept: '^') or: [self accept: '.']) ifTrue: [stop := self number]].
	l := SeqLocation from: start to: stop strand: 1.
	l fuzzyStart: fuzzyStart; fuzzyEnd: fuzzyEnd.
	^l!
complementOf: aLocation
	"the same location read on the other strand"
	aLocation isJoin
		ifTrue: [^SeqLocation join: aLocation parts strand: aLocation strand negated]
		ifFalse: [^aLocation strand: aLocation strand negated; yourself]! !

"---- the reader ----"

!GenBankReader methodsFor: 'reading'!
next
	"the next entry, up to its // line, or nil at the end of the input"
	| record line indent word rest |
	lines skipBlankLines.
	lines atEnd ifTrue: [^nil].
	record := SeqRecord id: 'unnamed' description: '' sequence: (DNASequence raw: '').
	[line := lines nextLine.
	 line notNil] whileTrue: [
		line trimBoth = '//' ifTrue: [^self finish: record].
		line trimBoth isEmpty ifFalse: [
			indent := self indentOf: line.
			word := line trimBoth substrings isEmpty ifTrue: [''] ifFalse: [line trimBoth substrings first].
			rest := (line trimBoth copyFrom: (word size + 1 min: line trimBoth size + 1) to: line trimBoth size) trimBoth.
			indent = 1
				ifTrue: [
					word = 'FEATURES'
						ifTrue: [self readFeaturesInto: record]
						ifFalse: [
							word = 'ORIGIN'
								ifTrue: [self readOriginInto: record]
								ifFalse: [self handle: word value: rest into: record]]]
				ifFalse: [indent <= 12 ifTrue: [self handleSub: word value: rest into: record]]]].
	^self finish: record!
keywordOf: aLine
	"the keyword of a header line (columns 1 to 12), or nil for a continuation line"
	| i |
	(aLine isEmpty or: [aLine first isSeparator]) ifTrue: [^nil].
	i := aLine indexOf: $ .
	^i = 0 ifTrue: [aLine trimBoth] ifFalse: [(aLine copyFrom: 1 to: i - 1) trimBoth]!
valueOf: aLine
	| i |
	i := aLine indexOf: $ .
	^i = 0 ifTrue: [''] ifFalse: [(aLine copyFrom: i to: aLine size) trimBoth]!
continuationLines
	"the following lines that continue the field just read (indented to column 13 or beyond), joined as they come"
	| out l |
	out := OrderedCollection new.
	[l := lines peekLine.
	 l notNil and: [l trimBoth notEmpty and: [(self indentOf: l) >= 13]]] whileTrue: [out add: lines nextLine trimBoth].
	^out!
handleSub: word value: value into: record
	"a sub-field: ORGANISM under SOURCE, AUTHORS / TITLE / JOURNAL under REFERENCE"
	| rest all |
	rest := self continuationLines.
	word = 'ORGANISM' ifTrue: [
		record annotationAt: #organism put: value.
		record annotationAt: #taxonomy put: (self taxonomyFrom: rest).
		^record].
	all := value.
	rest do: [:l | all := all isEmpty ifTrue: [l] ifFalse: [all, ' ', l]].
	record annotationAt: ('reference_', word asLowercase) asSymbol put: all.
	^record!
finish: aRecord
	aRecord description isEmpty ifTrue: [
		aRecord definition notNil ifTrue: [aRecord description: aRecord definition]].
	^aRecord! !

!GenBankReader methodsFor: 'header fields'!
handle: keyword value: value into: record
	| rest all |
	keyword = 'LOCUS' ifTrue: [^self readLocus: value into: record].
	rest := self continuationLines.
	all := value.
	keyword = 'ORGANISM'
		ifTrue: [
			record annotationAt: #organism put: value.
			record annotationAt: #taxonomy put: (self taxonomyFrom: rest).
			^record].
	rest do: [:l | all := all isEmpty ifTrue: [l] ifFalse: [all, ' ', l]].
	keyword = 'DEFINITION' ifTrue: [
		(all notEmpty and: [all last = $.]) ifTrue: [all := all copyFrom: 1 to: all size - 1].
		record annotationAt: #definition put: all.
		record description: all.
		^record].
	keyword = 'ACCESSION' ifTrue: [
		record annotationAt: #accession put: (all substrings isEmpty ifTrue: [all] ifFalse: [all substrings first]).
		^record].
	keyword = 'VERSION' ifTrue: [
		record annotationAt: #version put: (all substrings isEmpty ifTrue: [all] ifFalse: [all substrings first]).
		^record].
	keyword = 'KEYWORDS' ifTrue: [record annotationAt: #keywords put: all. ^record].
	keyword = 'SOURCE' ifTrue: [
		record annotationAt: #source put: all.
		(record annotationAt: #organism) isNil ifTrue: [record annotationAt: #organism put: all].
		^record].
	keyword = 'REFERENCE' ifTrue: [
		(record annotationAt: #references ifAbsent: [nil]) isNil ifTrue: [record annotationAt: #references put: OrderedCollection new].
		(record annotationAt: #references) add: all.
		^record].
	keyword = 'COMMENT' ifTrue: [record annotationAt: #comment put: all. ^record].
	"anything else is kept under its own name"
	record annotationAt: keyword asLowercase asSymbol put: all.
	^record!
taxonomyFrom: continuation
	"the lineage under ORGANISM, split on semicolons"
	| all |
	all := ''.
	continuation do: [:l | all := all isEmpty ifTrue: [l] ifFalse: [all, ' ', l]].
	(all notEmpty and: [all last = $.]) ifTrue: [all := all copyFrom: 1 to: all size - 1].
	all isEmpty ifTrue: [^Array new].
	^((all subStrings: ';') collect: [:t | t trimBoth]) asArray!
readLocus: value into: record
	"LOCUS  name  length bp  molecule  topology  division  date"
	| parts |
	parts := value substrings asArray.
	parts isEmpty ifTrue: [^record].
	record id: (parts at: 1).
	record annotationAt: #locus put: (parts at: 1).
	parts doWithIndex: [:p :i |
		| lower |
		lower := p asLowercase.
		(lower = 'bp' or: [lower = 'aa']) ifTrue: [
			i > 1 ifTrue: [record annotationAt: #length put: (parts at: i - 1) asNumber].
			record annotationAt: #units put: lower].
		(lower = 'linear' or: [lower = 'circular']) ifTrue: [record annotationAt: #topology put: lower].
		((lower includesSubstring: 'dna') or: [lower includesSubstring: 'rna']) ifTrue: [
			(record annotationAt: #moleculeType) isNil ifTrue: [record annotationAt: #moleculeType put: p]].
		(i = parts size and: [p includes: $-]) ifTrue: [record annotationAt: #date put: p]].
	(record annotationAt: #units) = 'aa' ifTrue: [record sequence: (ProteinSequence raw: '')].
	^record! !

!GenBankReader methodsFor: 'features'!
readFeaturesInto: record
	"the FEATURES table: a key in columns 6 to 20, the location from column 22, then /qualifier lines"
	| line key rest feature |
	[line := lines peekLine.
	 line notNil and: [line isEmpty or: [line first isSeparator]]] whileTrue: [
		line := lines nextLine.
		line trimBoth isEmpty ifFalse: [
			(self indentOf: line) >= 21
				ifTrue: [
					"only a qualifier can start here: a location that ran on was taken with its feature line"
					(feature notNil and: [line trimBoth first = $/]) ifTrue: [self readQualifier: line trimBoth into: feature]]
				ifFalse: [
					key := line trimBoth substrings isEmpty ifTrue: [''] ifFalse: [line trimBoth substrings first].
					rest := (line trimBoth copyFrom: (key size + 1 min: line trimBoth size + 1) to: line trimBoth size) trimBoth.
					key notEmpty ifTrue: [
						feature := SeqFeature key: key location: (self locationFrom: (self locationTextFrom: rest)).
						record addFeature: feature]]]].
	^record!
locationTextFrom: aString
	"a location may run over several lines; every continuation line is indented and does not start with a /"
	| out next |
	out := aString.
	[next := lines peekLine.
	 next notNil and: [next notEmpty and: [next first isSeparator
		and: [(self indentOf: next) >= 21 and: [next trimBoth notEmpty and: [next trimBoth first ~= $/]]]]]]
		whileTrue: [out := out, lines nextLine trimBoth].
	^out!
indentOf: aLine
	| i |
	i := 1.
	[i <= aLine size and: [(aLine at: i) isSeparator]] whileTrue: [i := i + 1].
	^i!
locationFrom: aString
	^[SeqLocation fromString: aString] on: BioError do: [:e | SeqLocation from: 1 to: 1]!
readQualifier: aString into: aFeature
	"/name=value (quoted or bare) or a bare /name; a quoted value may run over several lines"
	| body eq name value |
	body := aString copyFrom: 2 to: aString size.
	eq := body indexOf: $=.
	eq = 0 ifTrue: [^aFeature addQualifier: body trimBoth value: true].
	name := (body copyFrom: 1 to: eq - 1) trimBoth.
	value := (body copyFrom: eq + 1 to: body size) trimBoth.
	(value notEmpty and: [value first = $"])
		ifTrue: [value := self quotedValueFrom: value joinedWithSpaces: name ~= 'translation']
		ifFalse: [value := self unquotedValueFrom: value].
	^aFeature addQualifier: name value: value!
quotedValueFrom: aFirstLine joinedWithSpaces: withSpaces
	"the text of a quoted qualifier, continuing over the following lines until the closing quote mark"
	| out part line done |
	out := WriteStream on: String new.
	part := aFirstLine copyFrom: 2 to: aFirstLine size.
	done := false.
	[done] whileFalse: [
		(part notEmpty and: [part last = $"])
			ifTrue: [out nextPutAll: (part copyFrom: 1 to: part size - 1). done := true]
			ifFalse: [
				out nextPutAll: part.
				line := lines peekLine.
				(line notNil and: [line notEmpty and: [line first isSeparator and: [(self indentOf: line) >= 21 and: [line trimBoth notEmpty and: [line trimBoth first ~= $/]]]]])
					ifTrue: [
						withSpaces ifTrue: [out nextPut: $ ].
						part := lines nextLine trimBoth]
					ifFalse: [done := true]]].
	^(out contents copyReplaceAll: '""' with: '"')!
unquotedValueFrom: aString
	"a bare value, which may also run on (rare); numbers become Integers"
	| v |
	v := aString.
	(v notEmpty and: [v allSatisfy: [:c | c isDigit]]) ifTrue: [^v asNumber].
	^v! !

!GenBankReader methodsFor: 'sequence'!
readOriginInto: record
	"the lines after ORIGIN: a position then blocks of bases, until // or the end"
	| out line |
	out := WriteStream on: (String new: 4096).
	[line := lines peekLine.
	 line notNil and: [line trimBoth ~= '//']] whileTrue: [
		line := lines nextLine.
		line do: [:c | c isLetter ifTrue: [out nextPut: c]]].
	record sequence: ((record annotationAt: #units) = 'aa'
		ifTrue: [ProteinSequence raw: out contents]
		ifFalse: [self nucleotideFor: record string: out contents]).
	^record!
nucleotideFor: record string: aString
	| molecule |
	molecule := (record annotationAt: #moleculeType) ifNil: [''].
	^(molecule asLowercase includesSubstring: 'rna')
		ifTrue: [RNASequence raw: aString]
		ifFalse: [DNASequence raw: aString]! !

!GenBankReader class methodsFor: 'convenience'!
readString: aString
	"the first (or only) entry in the text"
	^(self on: aString) next! !
