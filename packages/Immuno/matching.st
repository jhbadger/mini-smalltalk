"A person's HLA type, and matching one person to another.

HLAGenotype is the alleles a person carries, two at each typed locus. It is what decides which peptides they can
present (scan a protein against it), and it is what transplantation matches on: HLAMatch compares a recipient with
a donor locus by locus at a chosen resolution and counts the mismatches in each direction. The chance that a
random unrelated person is a match is the product of the genotype frequencies, which is why a registry needs
millions of donors before most patients find a fully matched one."

Object subclass: #HLAGenotype instanceVariableNames: 'pairs' classVariableNames: '' category: 'Immuno-Matching'!
Object subclass: #HLAMatch instanceVariableNames: 'recipient donor resolution loci' classVariableNames: '' category: 'Immuno-Matching'!

!HLAGenotype class methodsFor: 'instance creation'!
fromAlleles: someNames
	"alleles as names or HLAAlleles, two per locus in any order; a locus with only one allele listed is taken to be
	homozygous"
	| byGene |
	byGene := Dictionary new.
	someNames do: [:n |
		| a list |
		a := n isString ifTrue: [HLAAllele named: n] ifFalse: [n].
		list := byGene at: a gene ifAbsent: [byGene at: a gene put: OrderedCollection new].
		list size >= 2 ifTrue: [^ImmunoError new signal: 'more than two alleles at locus ', a gene].
		list add: a].
	^self basicNew setPairs: byGene!
fromString: aString
	"names separated by spaces, commas or semicolons: 'A*01:01 A*02:01 B*08:01 B*57:01'"
	| names |
	names := (aString copyReplaceAll: ',' with: ' ') copyReplaceAll: ';' with: ' '.
	^self fromAlleles: names substrings! !

!HLAGenotype methodsFor: 'private'!
setPairs: aDictionary
	pairs := Dictionary new.
	aDictionary keysAndValuesDo: [:gene :list |
		pairs at: gene put: (list size = 1
			ifTrue: [Array with: list first with: list first]
			ifFalse: [list asArray])]! !

!HLAGenotype methodsFor: 'accessing'!
loci
	"the typed loci, in order"
	^pairs keys asSortedCollection asArray!
allelesAt: aGene
	"the two alleles at a locus (the same one twice if homozygous)"
	^pairs at: aGene ifAbsent: [ImmunoError new signal: 'this genotype has no ', aGene, ' typing']!
hasLocus: aGene
	^pairs includesKey: aGene!
alleles
	"every allele once per chromosome, loci in order"
	| out |
	out := OrderedCollection new.
	self loci do: [:g | out addAll: (pairs at: g)].
	^out asArray!
distinctAlleles
	| out |
	out := OrderedCollection new.
	self alleles do: [:a | (out includes: a) ifFalse: [out add: a]].
	^out asArray!
isHomozygousAt: aGene
	| p |
	p := self allelesAt: aGene.
	^(p at: 1) = (p at: 2)!
homozygousLoci
	^self loci select: [:g | self isHomozygousAt: g]!
classI
	"the classical class I alleles, distinct"
	^self distinctAlleles select: [:a | a isClassIClassical]!
classII
	^self distinctAlleles select: [:a | a isClassII]!
modelled
	"the distinct alleles that have a binding model"
	^self distinctAlleles select: [:a | AlleleModels hasModelFor: a]!
supertypes
	"the supertypes of the class I alleles, distinct and in order"
	| out |
	out := Set new.
	self classI do: [:a | a supertype notNil ifTrue: [out add: a supertype]].
	^out asSortedCollection asArray!
truncatedTo: n
	"the same genotype with every allele cut to n fields"
	^HLAGenotype fromAlleles: (self alleles collect: [:a | a truncatedTo: (n min: a fieldCount)])! !

!HLAGenotype methodsFor: 'printing'!
printOn: aStream
	| first |
	first := true.
	self loci do: [:g |
		first ifFalse: [aStream space].
		first := false.
		aStream nextPutAll: g; nextPutAll: '*'.
		(pairs at: g) doWithIndex: [:a :i |
			i > 1 ifTrue: [aStream nextPut: $/].
			aStream nextPutAll: (a name copyFrom: (a name indexOf: $*) + 1 to: a name size)]]! !

!HLAMatch class methodsFor: 'instance creation'!
recipient: aRecipient donor: aDonor
	"compared at two fields over the ten alleles of A, B, C, DRB1 and DQB1"
	^self recipient: aRecipient donor: aDonor resolution: 2 loci: #('A' 'B' 'C' 'DRB1' 'DQB1')!
recipient: aRecipient donor: aDonor loci: someGenes
	^self recipient: aRecipient donor: aDonor resolution: 2 loci: someGenes!
recipient: aRecipient donor: aDonor resolution: n loci: someGenes
	^self basicNew setRecipient: aRecipient donor: aDonor resolution: n loci: someGenes! !

!HLAMatch methodsFor: 'private'!
setRecipient: r donor: d resolution: n loci: someGenes
	recipient := r. donor := d. resolution := n. loci := someGenes.
	loci do: [:g |
		((r hasLocus: g) and: [d hasLocus: g]) ifFalse: [
			^ImmunoError new signal: 'both people must be typed at ', g]]!
same: a and: b
	"are two alleles the same at the resolution of the match (or the most both have, if a typing is coarser)"
	| n |
	n := (resolution min: a fieldCount) min: b fieldCount.
	^a matches: b atResolution: n! !

!HLAMatch methodsFor: 'accessing'!
recipient
	^recipient!
donor
	^donor!
loci
	^loci!
resolution
	^resolution!
matchesAt: aGene
	"0, 1 or 2: how many of the recipient's two alleles at the locus are met by the donor's"
	| r d |
	r := recipient allelesAt: aGene. d := donor allelesAt: aGene.
	((self same: (r at: 1) and: (d at: 1)) and: [self same: (r at: 2) and: (d at: 2)]) ifTrue: [^2].
	((self same: (r at: 1) and: (d at: 2)) and: [self same: (r at: 2) and: (d at: 1)]) ifTrue: [^2].
	r do: [:ra | d do: [:da | (self same: ra and: da) ifTrue: [^1]]].
	^0!
mismatchesAt: aGene
	^2 - (self matchesAt: aGene)!
matchCount
	"how many alleles match out of two per locus"
	^loci inject: 0 into: [:sum :g | sum + (self matchesAt: g)]!
mismatchCount
	^2 * loci size - self matchCount!
grade
	"the usual way to say it: '9/10' or '7/8'"
	^self matchCount printString, '/', (2 * loci size) printString!
isFullMatch
	^self mismatchCount = 0!
hostVersusGraft
	"the donor's alleles the recipient does not carry, which the recipient's immune system can attack: an Array
	of HLAAlleles, distinct, loci in order"
	| out |
	out := OrderedCollection new.
	loci do: [:g |
		(donor allelesAt: g) do: [:da |
			((recipient allelesAt: g) anySatisfy: [:ra | self same: ra and: da]) ifFalse: [
				(out includes: da) ifFalse: [out add: da]]]].
	^out asArray!
graftVersusHost
	"the recipient's alleles the donor does not carry, which donor T cells can attack"
	| out |
	out := OrderedCollection new.
	loci do: [:g |
		(recipient allelesAt: g) do: [:ra |
			((donor allelesAt: g) anySatisfy: [:da | self same: ra and: da]) ifFalse: [
				(out includes: ra) ifFalse: [out add: ra]]]].
	^out asArray! !

!HLAMatch methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'HLAMatch('; nextPutAll: self grade; nextPutAll: ' at '; print: resolution;
		nextPutAll: (resolution = 1 ifTrue: [' field)'] ifFalse: [' fields)'])!
report
	"one line per locus"
	| s |
	s := WriteStream on: String new.
	s nextPutAll: 'recipient '; print: recipient; nl; nextPutAll: 'donor     '; print: donor; nl.
	loci do: [:g |
		s nextPutAll: (ImmunoFormat padded: g to: 7); print: (self matchesAt: g); nextPutAll: ' of 2 match'; nl].
	s nextPutAll: 'grade '; nextPutAll: self grade.
	^s contents! !

!AlleleFrequencies methodsFor: 'matching'!
matchProbability: aGenotype loci: someGenes
	"the chance that a random unrelated person in this population is a full match for the genotype over these
	loci: the product over loci of the Hardy-Weinberg frequency of that pair, so loci are taken as independent
	(they are not, which is the reason for haplotype-based registry estimates)"
	| p |
	p := 1.0.
	someGenes do: [:g |
		| pair |
		pair := aGenotype allelesAt: g.
		p := p * (self genotypeFrequency: (pair at: 1) with: (pair at: 2))].
	^p! !
