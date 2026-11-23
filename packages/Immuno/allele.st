"HLA allele names.

An HLA allele is named by gene, then up to four colon-separated fields of increasing resolution, then an optional
expression suffix:  HLA-A*02:01:01:01N.  The first field is the allele group (usually what serology called the
antigen), the second names the protein, the third a synonymous change in the coding sequence, the fourth a
change outside it. Most work happens at two fields - the protein - which is why a name can be cut to any
resolution here and two names compared at any resolution.

HLAAllele also knows what class a gene belongs to, and the supertype of the common class I alleles, which is the
grouping of alleles that bind much the same peptides."

Object subclass: #HLAAllele instanceVariableNames: 'gene fields suffix' classVariableNames: 'Supertypes ClassI ClassII' category: 'Immuno-HLA'!

!HLAAllele class methodsFor: 'instance creation'!
named: aString
	"parse a name such as 'HLA-A*02:01', 'A*02:01:01:01' or 'B*57:01'; the 'HLA-' is optional"
	| text star rest parts last suf |
	text := aString trimBoth.
	(text size > 4 and: [(text copyFrom: 1 to: 4) asUppercase = 'HLA-']) ifTrue: [text := text copyFrom: 5 to: text size].
	star := text indexOf: $*.
	star < 2 ifTrue: [^ImmunoError new signal: 'not an HLA allele name: ', aString].
	rest := text copyFrom: star + 1 to: text size.
	rest isEmpty ifTrue: [^ImmunoError new signal: 'not an HLA allele name: ', aString].
	parts := (rest subStrings: ':') asArray.
	suf := ''.
	last := parts last.
	(last notEmpty and: [last last isLetter]) ifTrue: [
		suf := String with: last last asUppercase.
		parts at: parts size put: (last copyFrom: 1 to: last size - 1)].
	(parts isEmpty or: [parts size > 4]) ifTrue: [^ImmunoError new signal: 'not an HLA allele name: ', aString].
	parts do: [:p | (p size >= 2 and: [p allSatisfy: [:c | c isDigit]]) ifFalse: [
		^ImmunoError new signal: 'not an HLA allele name: ', aString]].
	(text copyFrom: 1 to: star - 1) do: [:c | (c isLetter or: [c isDigit]) ifFalse: [
		^ImmunoError new signal: 'not an HLA allele name: ', aString]].
	^self basicNew setGene: (text copyFrom: 1 to: star - 1) asUppercase fields: parts suffix: suf!
isValid: aString
	^[self named: aString. true] on: ImmunoError do: [:e | false]!
gene: aGene fields: someStrings
	^self basicNew setGene: aGene fields: someStrings suffix: ''! !

!HLAAllele methodsFor: 'private'!
setGene: aString fields: anArray suffix: aSuffix
	gene := aString. fields := anArray. suffix := aSuffix! !

!HLAAllele methodsFor: 'accessing'!
gene
	"the gene name without the HLA- prefix: 'A', 'B', 'DRB1'"
	^gene!
fields
	^fields!
fieldCount
	^fields size!
field: n
	^fields at: n!
suffix
	"'' for an ordinary allele; N null, L low, S secreted, Q questionable, A aberrant, C cytoplasmic"
	^suffix!
group
	"the allele group: 'A*02'"
	^gene, '*', (fields at: 1)!
protein
	"the two-field name, which names the protein: 'A*02:01'"
	^gene, '*', (self fieldsTo: 2)!
fieldsTo: n
	| s |
	s := WriteStream on: String new.
	1 to: (n min: fields size) do: [:i |
		i > 1 ifTrue: [s nextPut: $:].
		s nextPutAll: (fields at: i)].
	^s contents!
name
	"the full name, 'HLA-A*02:01:01:01'"
	^'HLA-', gene, '*', (self fieldsTo: fields size), suffix!
nameAt: n
	"the name cut to n fields: (HLAAllele named: 'A*02:01:01:01') nameAt: 2 is 'HLA-A*02:01'"
	^'HLA-', gene, '*', (self fieldsTo: n), (n >= fields size ifTrue: [suffix] ifFalse: [''])!
truncatedTo: n
	^HLAAllele named: (self nameAt: n)! !

!HLAAllele methodsFor: 'comparing'!
= anObject
	^(anObject isKindOf: HLAAllele) and: [self name = anObject name]!
hash
	^self name hash!
< anAllele
	"genes in name order, then the fields as numbers"
	| a b |
	gene = anAllele gene ifFalse: [^gene < anAllele gene].
	1 to: (fields size min: anAllele fields size) do: [:i |
		a := (fields at: i) asNumber. b := (anAllele field: i) asNumber.
		a = b ifFalse: [^a < b]].
	^fields size < anAllele fields size!
<= anAllele
	^(anAllele < self) not!
matches: anAllele atResolution: n
	"true when both names agree on the first n fields; an allele with fewer fields only agrees if it
	has all of them"
	| m |
	gene = anAllele gene ifFalse: [^false].
	(fields size >= n and: [anAllele fieldCount >= n]) ifFalse: [^false].
	1 to: n do: [:i | (fields at: i) = (anAllele field: i) ifFalse: [^false]].
	^true!
includes: anAllele
	"true when anAllele is this allele or a more specific version of it: A*02 includes A*02:01:01"
	gene = anAllele gene ifFalse: [^false].
	anAllele fieldCount < fields size ifTrue: [^false].
	1 to: fields size do: [:i | (fields at: i) = (anAllele field: i) ifFalse: [^false]].
	^true! !

!HLAAllele methodsFor: 'what it is'!
isNull
	^suffix = 'N'!
isClassI
	"the heavy chains of class I: the classical A, B and C and the non-classical E, F, G"
	^#('A' 'B' 'C' 'E' 'F' 'G') includes: gene!
isClassIClassical
	^#('A' 'B' 'C') includes: gene!
isClassII
	^(#('DRA' 'DRB1' 'DRB3' 'DRB4' 'DRB5' 'DQA1' 'DQB1' 'DPA1' 'DPB1') includes: gene)!
mhcClass
	"1 or 2, or nil for a gene that is neither"
	self isClassI ifTrue: [^1].
	self isClassII ifTrue: [^2].
	^nil!
supertype
	"the supertype of a common class I allele (A1, A2, A3, A24, B7, B27, B44, B58, B62), or nil where none is
	assigned"
	^HLAAllele supertypes at: self protein ifAbsent: [nil]!
locus
	"the locus the allele belongs to; the beta chain genes name it: DRB1 is at locus DRB1"
	^gene! !

!HLAAllele class methodsFor: 'supertypes'!
supertypes
	"allele (two fields, no HLA-) to supertype, after Sette and Sidney (1999) and Sidney et al. (2008)"
	| d |
	Supertypes isNil ifTrue: [
		d := Dictionary new.
		#(#('A1' 'A*01:01' 'A*26:01' 'A*29:02' 'A*30:02' 'A*32:01')
		  #('A2' 'A*02:01' 'A*02:02' 'A*02:03' 'A*02:05' 'A*02:06' 'A*02:07' 'A*68:02' 'A*69:01')
		  #('A3' 'A*03:01' 'A*11:01' 'A*31:01' 'A*33:01' 'A*68:01')
		  #('A24' 'A*23:01' 'A*24:02')
		  #('B7' 'B*07:02' 'B*35:01' 'B*35:03' 'B*51:01' 'B*53:01' 'B*54:01' 'B*55:01' 'B*56:01' 'B*67:01' 'B*78:01')
		  #('B27' 'B*14:01' 'B*27:05' 'B*38:01' 'B*39:01' 'B*48:01')
		  #('B44' 'B*18:01' 'B*37:01' 'B*40:01' 'B*44:02' 'B*44:03' 'B*45:01')
		  #('B58' 'B*57:01' 'B*58:01')
		  #('B62' 'B*15:01' 'B*52:01'))
			do: [:row | 2 to: row size do: [:i | d at: (row at: i) put: (row at: 1)]].
		Supertypes := d].
	^Supertypes!
supertypeNames
	^#('A1' 'A2' 'A3' 'A24' 'B7' 'B27' 'B44' 'B58' 'B62')!
inSupertype: aName
	"the alleles in a supertype, as HLAAlleles in order"
	| out |
	out := OrderedCollection new.
	self supertypes keysAndValuesDo: [:k :v | v = aName ifTrue: [out add: (self named: k)]].
	^(out asSortedCollection: [:a :b | a <= b]) asArray! !

!HLAAllele methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: self name!
displayString
	^self name! !

!String methodsFor: '*immuno'!
asHLA
	^HLAAllele named: self! !
