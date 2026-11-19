"The bridge to the Prolog package: a parsed GenBank record becomes facts you can query with Prolog rules.
Loading this file does not need Prolog; the methods report what to do when it is not there.

	Smalltalk loadPackage: 'Prolog'.
	BioProlog assertAll: (Bio read: 'genome.gb').
	Prolog answer: 'feature(Id, _, cds, Start, Stop, _), Stop - Start > 500'

The facts asserted for each record are

	sequence(Id, Length, Molecule)          molecule is dna, rna or protein
	description(Id, Text)                   text is an atom, so quote it: 'a description'
	organism(Id, Name)
	taxon(Id, Rank, Name)                   one per level of the lineage, Rank counting from 1
	feature(Id, Index, Key, Start, Stop, Strand)      positions 1-based, Strand 1 or -1
	qualifier(Id, Index, Name, Value)       values are atoms, except numbers and the bare /flag which is true

and the rules in rules.pl add gene/3, product/3, cds/5, overlapping/4 and feature_sequence/3."

Object subclass: #BioProlog instanceVariableNames: '' classVariableNames: 'Loaded' category: 'Bio'!

!BioProlog class methodsFor: 'testing'!
isAvailable
	"true when the Prolog package has been loaded"
	^(Smalltalk at: #Prolog ifAbsent: [nil]) notNil!
checkAvailable
	self isAvailable ifFalse: [
		^BioError new signal: 'the Prolog package is not loaded: evaluate  Smalltalk loadPackage: ''Prolog''  first'].
	^true! !

!BioProlog class methodsFor: 'asserting'!
engine
	self checkAvailable.
	^Prolog engine!
reset
	"forget every fact asserted so far by starting a fresh Prolog engine"
	self checkAvailable.
	Prolog reset.
	Loaded := nil.
	^true!
loadRules
	"consult the rules that come with the package (once per engine)"
	| path |
	Loaded == self engine ifTrue: [^true].
	path := Bio directory, '/rules.pl'.
	(FileStream exists: path) ifTrue: [self engine consultFile: path].
	Loaded := self engine.
	^true!
assertAll: aCollection
	"assert the facts of every record; answers how many records were asserted"
	| n |
	self checkAvailable.
	self loadRules.
	n := 0.
	aCollection do: [:r | self assertRecord: r. n := n + 1].
	^n!
assert: aRecordOrCollection
	(aRecordOrCollection isKindOf: SeqRecord)
		ifTrue: [^self assertAll: (Array with: aRecordOrCollection)].
	^self assertAll: aRecordOrCollection!
assertRecord: aRecord
	| id molecule |
	self checkAvailable.
	self loadRules.
	id := aRecord id asSymbol.
	molecule := aRecord isProtein ifTrue: [#protein] ifFalse: [aRecord sequence isRNA ifTrue: [#rna] ifFalse: [#dna]].
	self fact: #sequence with: (Array with: id with: aRecord size with: molecule).
	aRecord description notEmpty ifTrue: [self fact: #description with: (Array with: id with: aRecord description asSymbol)].
	aRecord organism notNil ifTrue: [self fact: #organism with: (Array with: id with: aRecord organism asSymbol)].
	aRecord taxonomy doWithIndex: [:t :i | self fact: #taxon with: (Array with: id with: i with: t asSymbol)].
	aRecord features doWithIndex: [:f :i | self assertFeature: f index: i of: id].
	^aRecord!
assertFeature: aFeature index: anIndex of: id
	self fact: #feature with: (Array with: id with: anIndex with: aFeature key asLowercase asSymbol
		with: aFeature start with: aFeature stop with: aFeature strand).
	aFeature qualifiers do: [:a |
		self fact: #qualifier with: (Array with: id with: anIndex with: a key asSymbol with: (self prologValueOf: a value))]!
prologValueOf: aValue
	"qualifier values: numbers stay numbers, everything else becomes an atom, so that a query can be
	written the way it reads -- gene(Id, I, alpha) and product(Id, I, 'hypothetical protein alpha')"
	aValue == true ifTrue: [^#true].
	aValue isNumber ifTrue: [^aValue].
	^aValue asString asSymbol!
fact: aName with: anArray
	"assert name(arg, ...) as a fact"
	| term |
	term := PrologStruct functor: aName args: anArray.
	self engine addClause: term atEnd: true.
	^term! !

!BioProlog class methodsFor: 'querying'!
solve: aQuery
	"the solutions of a Prolog query, as Dictionaries (see Prolog solve:)"
	self checkAvailable.
	^Prolog solve: aQuery!
answer: aQuery
	self checkAvailable.
	^Prolog answer: aQuery! !
