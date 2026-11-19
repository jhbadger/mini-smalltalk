"Biological sequences. A BioSequence wraps a String of residues; the case of the letters is kept (so soft-masked
lowercase survives a round trip) but every analysis is case-insensitive. DNASequence, RNASequence and ProteinSequence
add the protocol that makes sense for each. IUPAC ambiguity codes are understood throughout."

Object subclass: #BioSequence instanceVariableNames: 'seq upper' classVariableNames: '' category: 'Bio-Sequences'!
BioSequence subclass: #NucleotideSequence instanceVariableNames: '' classVariableNames: '' category: 'Bio-Sequences'!
NucleotideSequence subclass: #DNASequence instanceVariableNames: '' classVariableNames: 'ComplementTable' category: 'Bio-Sequences'!
NucleotideSequence subclass: #RNASequence instanceVariableNames: '' classVariableNames: 'ComplementTable' category: 'Bio-Sequences'!
BioSequence subclass: #ProteinSequence instanceVariableNames: '' classVariableNames: '' category: 'Bio-Sequences'!
Error subclass: #BioError instanceVariableNames: '' classVariableNames: '' category: 'Bio-Sequences'!

!BioSequence class methodsFor: 'instance creation'!
on: aString
	"the sequence written in aString (white space and digits, as found in formatted files, are dropped)"
	^self basicNew setSequence: (self clean: aString)!
raw: aString
	"aString exactly as given, without removing anything"
	^self basicNew setSequence: aString!
new
	^self raw: ''!
clean: aString
	"drop the white space, digits and gap-like characters that formatted files put in a sequence"
	| out c |
	out := WriteStream on: (String new: aString size).
	1 to: aString size do: [:i |
		c := aString at: i.
		(c isSeparator or: [c isDigit]) ifFalse: [out nextPut: c]].
	^out contents!
guess: aString
	"a DNASequence, RNASequence or ProteinSequence, chosen from the letters in aString"
	| s counts n acgtu u |
	s := (self clean: aString) asUppercase.
	s isEmpty ifTrue: [^DNASequence raw: ''].
	n := 0. acgtu := 0. u := false.
	s do: [:c |
		c isLetter ifTrue: [
			n := n + 1.
			('ACGTUN' includes: c) ifTrue: [acgtu := acgtu + 1].
			c = $U ifTrue: [u := true]]].
	n = 0 ifTrue: [^DNASequence raw: aString].
	acgtu * 100 < (n * 85) ifTrue: [^ProteinSequence raw: aString].
	^u ifTrue: [RNASequence raw: aString] ifFalse: [DNASequence raw: aString]! !

!BioSequence methodsFor: 'private'!
setSequence: aString
	seq := aString. upper := nil!
upper
	"the residues in upper case, computed once"
	^upper ifNil: [upper := seq asUppercase]!
species
	^self class! !

!BioSequence methodsFor: 'accessing'!
asString
	^seq!
string
	^seq!
size
	^seq size!
isEmpty
	^seq isEmpty!
notEmpty
	^seq notEmpty!
at: anInteger
	^seq at: anInteger!
first
	^seq first!
last
	^seq last!
do: aBlock
	seq do: aBlock!
occurrencesOf: aCharacter
	"how many times the residue appears (either case)"
	| c |
	c := aCharacter asUppercase.
	^self upper occurrencesOf: c! !

!BioSequence methodsFor: 'copying'!
copyFrom: start to: stop
	"a sequence of the same kind holding residues start to stop (1-based, inclusive)"
	^self species raw: (seq copyFrom: start to: stop)!
from: start to: stop
	^self copyFrom: start to: stop!
first: n
	^self copyFrom: 1 to: (n min: seq size)!
last: n
	^self copyFrom: (seq size - n + 1 max: 1) to: seq size!
allButFirst: n
	^self copyFrom: (n + 1 min: seq size + 1) to: seq size!
allButLast: n
	^self copyFrom: 1 to: (seq size - n max: 0)!
, aSequenceOrString
	^self species raw: seq, aSequenceOrString asString!
reverse
	"the residues in the opposite order (no complementing)"
	^self species raw: seq reversed!
reversed
	^self reverse!
asUppercase
	^self species raw: seq asUppercase!
asLowercase
	^self species raw: seq asLowercase!
copy
	^self species raw: seq copy!
windowsOfSize: n step: step do: aBlock
	"evaluate aBlock with each window (a subsequence) and its 1-based start"
	| i |
	i := 1.
	[i + n - 1 <= seq size] whileTrue: [
		aBlock value: (self copyFrom: i to: i + n - 1) value: i.
		i := i + step]! !

!BioSequence methodsFor: 'comparing'!
= other
	^(other isKindOf: BioSequence) and: [self class == other class and: [self upper = other upper]]!
hash
	^self upper hash!
sameAs: other
	"equal residues, whatever the kind of sequence and the case"
	^self upper = other asString asUppercase! !

!BioSequence methodsFor: 'converting'!
asDNA
	^DNASequence raw: seq!
asRNA
	^RNASequence raw: seq!
asProtein
	^ProteinSequence raw: seq!
asSequence
	^self! !

!BioSequence methodsFor: 'testing'!
isNucleotide
	^false!
isProtein
	^false!
isValid
	^self invalidCharacters isEmpty!
invalidCharacters
	"the distinct letters that are not in the alphabet, in order of appearance"
	| bad ok |
	bad := OrderedCollection new.
	ok := self class alphabet.
	self upper do: [:c | ((ok includes: c) or: [bad includes: c]) ifFalse: [bad add: c]].
	^bad asArray!
isAmbiguous
	^self upper anySatisfy: [:c | self class unambiguousAlphabet includes: c] not! !

!BioSequence methodsFor: 'composition'!
composition
	"a Dictionary from each residue present (upper case) to how often it occurs"
	| d |
	d := Dictionary new.
	self upper do: [:c | d at: c put: (d at: c ifAbsent: [0]) + 1].
	^d!
compositionPercent
	| d n |
	n := seq size max: 1.
	d := Dictionary new.
	self composition keysAndValuesDo: [:k :v | d at: k put: v * 100.0 / n].
	^d!
countOf: aCollection
	"how many residues are in aCollection (a String of residues)"
	| set n |
	set := aCollection asString asUppercase asSet.
	n := 0.
	self upper do: [:c | (set includes: c) ifTrue: [n := n + 1]].
	^n!
compositionReport
	"the composition as a table, commonest first"
	| out total pairs |
	total := seq size max: 1.
	pairs := self composition associations asSortedCollection: [:a :b | a value = b value ifTrue: [a key <= b key] ifFalse: [a value > b value]].
	out := WriteStream on: String new.
	pairs do: [:a |
		out nextPutAll: (String with: a key); nextPutAll: '  ';
			nextPutAll: (a value printPaddedWith: $  to: 8); nextPutAll: '  ';
			nextPutAll: (a value * 100.0 / total printShowingDecimalPlaces: 2); nextPutAll: '%'; nl].
	^out contents! !

!BioSequence methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: self class name; nextPut: $(.
	seq size <= 48
		ifTrue: [aStream nextPutAll: seq]
		ifFalse: [aStream nextPutAll: (seq copyFrom: 1 to: 24); nextPutAll: '...'; nextPutAll: (seq copyFrom: seq size - 11 to: seq size)].
	aStream nextPutAll: ', '; print: seq size; nextPutAll: ' bp)'!
displayString
	^seq!
wrappedAt: n
	"the residues in lines of at most n characters"
	| out i |
	out := WriteStream on: (String new: seq size + seq size // n + 2).
	i := 1.
	[i <= seq size] whileTrue: [
		out nextPutAll: (seq copyFrom: i to: (i + n - 1 min: seq size)); nl.
		i := i + n].
	^out contents!
wrapped
	^self wrappedAt: 60! !

!BioSequence class methodsFor: 'alphabet'!
alphabet
	^self subclassResponsibility!
unambiguousAlphabet
	^self alphabet!
moleculeName
	^'sequence'! !

"---- nucleotides ----"

!NucleotideSequence methodsFor: 'testing'!
isNucleotide
	^true! !

!NucleotideSequence methodsFor: 'composition'!
gcCount
	"G and C, counting ambiguity codes that can only be G or C"
	| n |
	n := 0.
	self upper do: [:c | ('GCS' includes: c) ifTrue: [n := n + 1]].
	^n!
atCount
	| n |
	n := 0.
	self upper do: [:c | ('ATUW' includes: c) ifTrue: [n := n + 1]].
	^n!
gc
	"the fraction of G+C among the unambiguous bases (0.0 when there are none)"
	| gc at |
	gc := self gcCount. at := self atCount.
	gc + at = 0 ifTrue: [^0.0].
	^gc / (gc + at)!
gcPercent
	^self gc * 100.0!
gcSkew
	"(G - C) / (G + C), the strand asymmetry, or 0.0 when there is no G or C"
	| g c |
	g := self upper occurrencesOf: $G. c := self upper occurrencesOf: $C.
	g + c = 0 ifTrue: [^0.0].
	^(g - c) / (g + c)!
atSkew
	| a t |
	a := self upper occurrencesOf: $A. t := (self upper occurrencesOf: $T) + (self upper occurrencesOf: $U).
	a + t = 0 ifTrue: [^0.0].
	^(a - t) / (a + t)!
ambiguousCount
	^self size - (self countOf: self class unambiguousAlphabet)!
gcContentIn: window step: step
	"an Array of Associations start -> GC fraction (a Float, for plotting), one per sliding window"
	| r |
	r := OrderedCollection new.
	self windowsOfSize: window step: step do: [:sub :start | r add: start -> sub gc asFloat].
	^r asArray! !

!NucleotideSequence methodsFor: 'converting'!
complement
	"the complementary bases, in the same order (IUPAC codes complemented too)"
	| table out c |
	table := self class complementTable.
	out := String new: seq size.
	1 to: seq size do: [:i |
		c := seq at: i.
		out at: i put: (table at: c value + 1)].
	^self species raw: out!
reverseComplement
	^self complement reverse!
rc
	^self reverseComplement! !

!NucleotideSequence class methodsFor: 'alphabet'!
buildComplementTable: pairs
	"a 256-character table mapping each base to its complement (both cases); anything else maps to itself"
	| t |
	t := String new: 256.
	0 to: 255 do: [:i | t at: i + 1 put: (Character value: i)].
	1 to: pairs size by: 2 do: [:i |
		| a b |
		a := (pairs at: i) first. b := (pairs at: i + 1) first.
		t at: a value + 1 put: b.
		t at: a asLowercase value + 1 put: b asLowercase].
	^t! !

!DNASequence class methodsFor: 'alphabet'!
alphabet
	^'ACGTRYSWKMBDHVN-'!
unambiguousAlphabet
	^'ACGT'!
moleculeName
	^'DNA'!
complementTable
	^ComplementTable ifNil: [ComplementTable := self buildComplementTable:
		#('A' 'T' 'T' 'A' 'C' 'G' 'G' 'C' 'U' 'A' 'R' 'Y' 'Y' 'R' 'S' 'S' 'W' 'W' 'K' 'M' 'M' 'K' 'B' 'V' 'V' 'B' 'D' 'H' 'H' 'D' 'N' 'N')]! !

!RNASequence class methodsFor: 'alphabet'!
alphabet
	^'ACGURYSWKMBDHVN-'!
unambiguousAlphabet
	^'ACGU'!
moleculeName
	^'RNA'!
complementTable
	^ComplementTable ifNil: [ComplementTable := self buildComplementTable:
		#('A' 'U' 'U' 'A' 'T' 'A' 'C' 'G' 'G' 'C' 'R' 'Y' 'Y' 'R' 'S' 'S' 'W' 'W' 'K' 'M' 'M' 'K' 'B' 'V' 'V' 'B' 'D' 'H' 'H' 'D' 'N' 'N')]! !

!DNASequence methodsFor: 'converting'!
transcribe
	"the messenger RNA of this (coding) strand: T becomes U"
	^RNASequence raw: ((seq copyReplacing: $T with: $U) copyReplacing: $t with: $u)!
asDNA
	^self! !

!RNASequence methodsFor: 'converting'!
reverseTranscribe
	^DNASequence raw: ((seq copyReplacing: $U with: $T) copyReplacing: $u with: $t)!
asDNA
	^self reverseTranscribe!
asRNA
	^self! !

"---- proteins ----"

!ProteinSequence class methodsFor: 'alphabet'!
alphabet
	^'ACDEFGHIKLMNPQRSTVWYBXZUO*-'!
unambiguousAlphabet
	^'ACDEFGHIKLMNPQRSTVWY'!
moleculeName
	^'protein'! !

!ProteinSequence methodsFor: 'testing'!
isProtein
	^true! !

!ProteinSequence methodsFor: 'accessing'!
stopCount
	^self upper occurrencesOf: $*!
hasStop
	^self stopCount > 0!
withoutStops
	^ProteinSequence raw: (seq reject: [:c | c = $*])! !

"---- IUPAC ambiguity codes ----"

Object subclass: #BioIUPAC instanceVariableNames: '' classVariableNames: 'BasesTable CodeTable' category: 'Bio-Sequences'!

!BioIUPAC class methodsFor: 'codes'!
table
	"each nucleotide code and the unambiguous bases it stands for"
	^#( $A 'A' $C 'C' $G 'G' $T 'T' $U 'T'
	    $R 'AG' $Y 'CT' $S 'CG' $W 'AT' $K 'GT' $M 'AC'
	    $B 'CGT' $D 'AGT' $H 'ACT' $V 'ACG' $N 'ACGT' $X 'ACGT' )!
basesTable
	| t spec |
	BasesTable notNil ifTrue: [^BasesTable].
	t := Array new: 256 withAll: ''.
	spec := self table.
	1 to: spec size by: 2 do: [:i |
		t at: (spec at: i) value + 1 put: (spec at: i + 1).
		t at: (spec at: i) asLowercase value + 1 put: (spec at: i + 1)].
	^BasesTable := t!
basesFor: aCharacter
	"the unambiguous bases a code stands for, as a String ('' when it is not a nucleotide code)"
	| v |
	v := aCharacter value.
	v > 255 ifTrue: [^''].
	^self basesTable at: v + 1!
codeFor: aCollectionOfBases
	"the single IUPAC code covering exactly these bases, or $N"
	| want spec |
	want := aCollectionOfBases asString asUppercase asSet.
	spec := self table.
	1 to: spec size by: 2 do: [:i |
		((spec at: i + 1) asSet = want and: [(spec at: i) ~= $U and: [(spec at: i) ~= $X]]) ifTrue: [^spec at: i]].
	^$N!
code: aCode matches: aBase
	"true when the ambiguity code covers the base (either may be ambiguous; N matches anything)"
	| a b |
	a := self basesFor: aCode. b := self basesFor: aBase.
	(a isEmpty or: [b isEmpty]) ifTrue: [^aCode asUppercase = aBase asUppercase].
	^b anySatisfy: [:c | a includes: c]!
isAmbiguous: aCharacter
	^(self basesFor: aCharacter) size > 1!
expand: aPattern
	"every unambiguous sequence the pattern stands for, as an Array of Strings (nil when there would be more than 4096)"
	| results total |
	total := 1.
	aPattern do: [:c | total := total * ((self basesFor: c) size max: 1)].
	total > 4096 ifTrue: [^nil].
	results := OrderedCollection with: ''.
	aPattern do: [:c |
		| bases next |
		bases := self basesFor: c.
		bases isEmpty ifTrue: [bases := String with: c].
		next := OrderedCollection new.
		results do: [:prefix | bases do: [:b | next add: prefix, (String with: b)]].
		results := next].
	^results asArray! !
