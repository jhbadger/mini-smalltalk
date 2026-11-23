"Alleles in populations.

Which peptides a person can present depends on which HLA alleles they carry, and those differ between people and
between populations, so a vaccine or a screen has to be judged against a population: what fraction of people
carry an allele that presents at least one of its epitopes? AlleleFrequencies holds the frequency of each allele,
works out that coverage (assuming Hardy-Weinberg proportions at each locus and independence between loci, both of
which are approximations), and tests whether a sample of genotypes is in Hardy-Weinberg proportions.
LinkageDisequilibrium measures how much two loci are inherited together more than chance would allow.

ImmunoMath holds the one special function the tests need, the chi-square tail area."

Object subclass: #ImmunoMath instanceVariableNames: '' classVariableNames: '' category: 'Immuno-Population'!
Object subclass: #AlleleFrequencies instanceVariableNames: 'name freqs' classVariableNames: '' category: 'Immuno-Population'!
Object subclass: #HardyWeinbergResult instanceVariableNames: 'locus n chiSquare degrees observed expected' classVariableNames: '' category: 'Immuno-Population'!
Object subclass: #LinkageDisequilibrium instanceVariableNames: 'pA pB pAB' classVariableNames: '' category: 'Immuno-Population'!

!ImmunoMath class methodsFor: 'special functions'!
lnGamma: x
	"the natural logarithm of the gamma function (Lanczos), for x above a half"
	| c z sum t |
	c := #(0.99999999999980993 676.5203681218851 -1259.1392167224028 771.32342877765313 -176.61502916214059
		12.507343278686905 -0.13857109526572012 9.9843695780195716e-6 1.5056327351493116e-7).
	z := x - 1.0.
	sum := c at: 1.
	1 to: 8 do: [:i | sum := sum + ((c at: i + 1) / (z + i))].
	t := z + 7.5.
	^(2.5066282746310002 ln) + sum ln + ((z + 0.5) * t ln) - t!
upperGamma: a at: x
	"Q(a, x), the regularized upper incomplete gamma function: a series when x is below a + 1, a continued
	fraction above it"
	| sum term n b c d h del |
	x <= 0 ifTrue: [^1.0].
	x < (a + 1.0) ifTrue: [
		sum := 1.0 / a. term := sum. n := a.
		1 to: 500 do: [:i |
			n := n + 1.0. term := term * x / n. sum := sum + term].
		^1.0 - (sum * (x negated + (a * x ln) - (self lnGamma: a)) exp)].
	b := x + 1.0 - a. c := 1.0e300. d := 1.0 / b. h := d.
	1 to: 500 do: [:i |
		| an |
		an := i negated * (i - a).
		b := b + 2.0.
		d := an * d + b. d abs < 1.0e-300 ifTrue: [d := 1.0e-300].
		c := b + (an / c). c abs < 1.0e-300 ifTrue: [c := 1.0e-300].
		d := 1.0 / d.
		del := d * c. h := h * del].
	^h * (x negated + (a * x ln) - (self lnGamma: a)) exp!
chiSquareSurvival: x df: k
	"the probability that a chi-square variable with k degrees of freedom is at least x: the p-value of a
	chi-square statistic"
	^self upperGamma: k / 2.0 at: x / 2.0! !

!AlleleFrequencies class methodsFor: 'instance creation'!
named: aString
	^self basicNew setName: aString!
fromGenotypes: pairs name: aString
	"pairs: one Array of two allele names per person, for one locus; each allele is counted, and the
	frequency is its count over twice the number of people"
	| f counts |
	f := self named: aString.
	counts := Dictionary new.
	pairs do: [:pair |
		pair do: [:a |
			| key |
			key := AlleleModels nameOf: a.
			counts at: key put: (counts at: key ifAbsent: [0]) + 1]].
	counts keysAndValuesDo: [:k :v | f at: k put: v / (2 * pairs size)].
	^f!
example
	"ROUND ILLUSTRATIVE FIGURES of the order seen in European-ancestry populations, for the tutorial; they are not
	a reference and not for research - take real frequencies from a database such as allelefrequencies.net"
	| f |
	f := self named: 'example population'.
	#(#('HLA-A*02:01' 0.27) #('HLA-A*01:01' 0.16) #('HLA-A*03:01' 0.13) #('HLA-A*24:02' 0.09)
	  #('HLA-A*11:01' 0.05) #('HLA-A*26:01' 0.03) #('HLA-A*32:01' 0.03)
	  #('HLA-B*07:02' 0.13) #('HLA-B*08:01' 0.11) #('HLA-B*44:02' 0.08) #('HLA-B*15:01' 0.07)
	  #('HLA-B*35:01' 0.06) #('HLA-B*51:01' 0.05) #('HLA-B*40:01' 0.05) #('HLA-B*44:03' 0.04)
	  #('HLA-B*27:05' 0.03) #('HLA-B*57:01' 0.03)
	  #('HLA-DRB1*15:01' 0.14) #('HLA-DRB1*03:01' 0.12) #('HLA-DRB1*07:01' 0.13)
	  #('HLA-DRB1*04:01' 0.09) #('HLA-DRB1*01:01' 0.09) #('HLA-DRB1*11:01' 0.07))
		do: [:row | f at: (row at: 1) put: (row at: 2)].
	^f! !

!AlleleFrequencies methodsFor: 'private'!
setName: aString
	name := aString. freqs := Dictionary new! !

!AlleleFrequencies methodsFor: 'accessing'!
name
	^name!
at: anAllele put: aFrequency
	freqs at: (AlleleModels nameOf: anAllele) put: aFrequency!
frequencyOf: anAllele
	"the frequency of an allele (any resolution is cut to two fields), 0 if it is not listed"
	^freqs at: (AlleleModels nameOf: anAllele) ifAbsent: [0]!
alleles
	"every listed allele, in order"
	^((freqs keys collect: [:n | HLAAllele named: n]) asSortedCollection: [:a :b | a <= b]) asArray!
loci
	"the genes with at least one allele listed, in order"
	| genes |
	genes := Set new.
	freqs keysDo: [:n | genes add: (HLAAllele named: n) gene].
	^genes asSortedCollection asArray!
allelesAt: aGene
	^self alleles select: [:a | a gene = aGene]!
totalAt: aGene
	"the summed frequency of the alleles listed at a locus; below 1 when some alleles are not listed"
	^(self allelesAt: aGene) inject: 0 into: [:sum :a | sum + (self frequencyOf: a)]!
remainderAt: aGene
	"the frequency not accounted for by the listed alleles"
	^(1 - (self totalAt: aGene)) max: 0! !

!AlleleFrequencies methodsFor: 'genotypes'!
carrierFrequency: anAllele
	"the fraction of people with at least one copy, 1 - (1 - p)^2 under Hardy-Weinberg"
	| p |
	p := self frequencyOf: anAllele.
	^1 - ((1 - p) * (1 - p))!
genotypeFrequency: a with: b
	"the Hardy-Weinberg frequency of a person with these two alleles at a locus: p squared if they are the same,
	2pq if not"
	| p q |
	p := self frequencyOf: a. q := self frequencyOf: b.
	^(AlleleModels nameOf: a) = (AlleleModels nameOf: b) ifTrue: [p * p] ifFalse: [2 * p * q]!
expectedHeterozygosity: aGene
	"the chance that a person has two different alleles at the locus, 1 minus the sum of the squared
	frequencies; alleles that are not listed are counted as all different from each other"
	| sum |
	sum := (self allelesAt: aGene) inject: 0 into: [:s :a | s + ((self frequencyOf: a) squared)].
	^1 - sum! !

!AlleleFrequencies methodsFor: 'coverage'!
hitDistributionOf: someAlleles
	"an Array whose k + 1 element is the fraction of people who carry exactly k of the alleles (counting each of
	their two chromosomes at each locus), loci independent: so the first element is the fraction recognizing nothing"
	| dist byLocus |
	byLocus := Dictionary new.
	someAlleles do: [:a |
		| al |
		al := a isString ifTrue: [HLAAllele named: a] ifFalse: [a].
		byLocus at: al gene put: (byLocus at: al gene ifAbsent: [0]) + (self frequencyOf: al)].
	dist := Array with: 1.0.
	byLocus keysAndValuesDo: [:gene :p |
		| next q |
		q := 1.0 - p.
		next := Array new: dist size + 2 withAll: 0.0.
		dist doWithIndex: [:d :i |
			next at: i put: (next at: i) + (d * q * q).
			next at: i + 1 put: (next at: i + 1) + (d * 2 * p * q).
			next at: i + 2 put: (next at: i + 2) + (d * p * p)].
		dist := next].
	^dist!
coverageOf: someAlleles
	"the fraction of people who carry at least one of the alleles: the population coverage of an epitope set whose
	presenting alleles these are"
	^1.0 - (self hitDistributionOf: someAlleles) first!
coverageOf: someAlleles atLeast: n
	"the fraction of people who carry at least n hits: coverage 3 is how many are likely to respond to three
	epitopes, which is a better guide to protection than one"
	| dist sum |
	dist := self hitDistributionOf: someAlleles.
	sum := 0.0.
	n + 1 to: dist size do: [:i | sum := sum + (dist at: i)].
	^sum!
averageHitsOf: someAlleles
	"the mean number of the alleles a person carries: twice the sum of their frequencies"
	^2 * (someAlleles inject: 0 into: [:s :a | s + (self frequencyOf: a)])!
bestAlleles: n from: candidates
	"the n alleles, chosen one at a time to add the most coverage, as an Array: the smallest panel that reaches
	the widest part of the population"
	| chosen pool |
	chosen := OrderedCollection new.
	pool := OrderedCollection withAll: candidates.
	[chosen size < n and: [pool notEmpty]] whileTrue: [
		| best bestCover |
		best := nil. bestCover := -1.
		pool do: [:a |
			| c |
			c := self coverageOf: (chosen copyWith: a).
			c > bestCover ifTrue: [best := a. bestCover := c]].
		chosen add: best.
		pool remove: best].
	^chosen asArray! !

!AlleleFrequencies class methodsFor: 'testing proportions'!
hardyWeinbergTest: pairs
	| n counts observed alleles freq chi k expected cells |
	n := pairs size.
	n = 0 ifTrue: [^ImmunoError new signal: 'no genotypes to test'].
	counts := Dictionary new.
	observed := Dictionary new.
	pairs do: [:pair |
		| a b key |
		a := AlleleModels nameOf: (pair at: 1). b := AlleleModels nameOf: (pair at: 2).
		counts at: a put: (counts at: a ifAbsent: [0]) + 1.
		counts at: b put: (counts at: b ifAbsent: [0]) + 1.
		key := a <= b ifTrue: [a, ' / ', b] ifFalse: [b, ' / ', a].
		observed at: key put: (observed at: key ifAbsent: [0]) + 1].
	alleles := (counts keys asSortedCollection: [:x :y | x <= y]) asArray.
	k := alleles size.
	k < 2 ifTrue: [^ImmunoError new signal: 'the sample has only one allele, so there is nothing to test'].
	freq := Dictionary new.
	counts keysAndValuesDo: [:a :c | freq at: a put: c / (2 * n)].
	expected := Dictionary new.
	chi := 0.0.
	1 to: k do: [:i |
		i to: k do: [:j |
			| a b e key o |
			a := alleles at: i. b := alleles at: j.
			e := n * (i = j ifTrue: [(freq at: a) * (freq at: a)] ifFalse: [2 * (freq at: a) * (freq at: b)]).
			key := a, ' / ', b.
			expected at: key put: e.
			o := observed at: key ifAbsent: [0].
			chi := chi + (((o - e) squared) / e)]].
	^HardyWeinbergResult locus: (HLAAllele named: (alleles at: 1)) gene n: n chiSquare: chi degrees: k * (k - 1) / 2
		observed: observed expected: expected! !

!HardyWeinbergResult class methodsFor: 'instance creation'!
locus: aGene n: n chiSquare: chi degrees: df observed: o expected: e
	^self basicNew setLocus: aGene n: n chiSquare: chi degrees: df observed: o expected: e! !

!HardyWeinbergResult methodsFor: 'private'!
setLocus: aGene n: count chiSquare: chi degrees: df observed: o expected: e
	locus := aGene. n := count. chiSquare := chi. degrees := df. observed := o. expected := e! !

!HardyWeinbergResult methodsFor: 'accessing'!
locus
	^locus!
n
	^n!
chiSquare
	^chiSquare!
degrees
	^degrees!
pValue
	"the chance of a statistic at least this large if the sample really is in Hardy-Weinberg proportions"
	^ImmunoMath chiSquareSurvival: chiSquare df: degrees!
observed
	"a Dictionary from genotype ('a / b') to the number of people"
	^observed!
expected
	^expected!
isConsistent
	"true when the p-value is above 0.05: no evidence against the proportions"
	^self pValue > 0.05!
printOn: aStream
	aStream nextPutAll: 'Hardy-Weinberg at '; nextPutAll: locus; nextPutAll: ': chi-square ';
		nextPutAll: (ImmunoFormat number: chiSquare places: 2); nextPutAll: ' on ';
		print: degrees; nextPutAll: ' df, p = '; nextPutAll: (ImmunoFormat number: self pValue places: 3)! !

!LinkageDisequilibrium class methodsFor: 'instance creation'!
pA: a pB: b pAB: ab
	"the frequency of allele A at one locus, of B at another, and of the haplotype that has both"
	^self basicNew setPA: a pB: b pAB: ab!
fromHaplotypes: pairs allele: a and: b
	"pairs: one Array of two allele names (one per locus) for each haplotype in a sample"
	| na nb nab |
	na := 0. nb := 0. nab := 0.
	pairs do: [:h |
		| hasA hasB |
		hasA := (AlleleModels nameOf: (h at: 1)) = (AlleleModels nameOf: a).
		hasB := (AlleleModels nameOf: (h at: 2)) = (AlleleModels nameOf: b).
		hasA ifTrue: [na := na + 1].
		hasB ifTrue: [nb := nb + 1].
		(hasA and: [hasB]) ifTrue: [nab := nab + 1]].
	^self pA: na / pairs size pB: nb / pairs size pAB: nab / pairs size! !

!LinkageDisequilibrium methodsFor: 'private'!
setPA: a pB: b pAB: ab
	pA := a. pB := b. pAB := ab! !

!LinkageDisequilibrium methodsFor: 'measures'!
pA
	^pA!
pB
	^pB!
pAB
	^pAB!
expected
	"the haplotype frequency if the two alleles were independent: pA times pB"
	^pA * pB!
d
	"D: the observed haplotype frequency minus the expected one; zero when the loci are in equilibrium"
	^pAB - (pA * pB)!
dMax
	"the largest D could be with these allele frequencies, taking the sign of D"
	^self d >= 0
		ifTrue: [(pA * (1 - pB)) min: ((1 - pA) * pB)]
		ifFalse: [(pA * pB) min: ((1 - pA) * (1 - pB))]!
dPrime
	"D as a fraction of its largest possible value: 1 means the alleles are never found apart"
	self dMax = 0 ifTrue: [^0].
	^self d / self dMax!
rSquared
	"the squared correlation between the two alleles: 1 when each predicts the other perfectly"
	| den |
	den := pA * (1 - pA) * pB * (1 - pB).
	den = 0 ifTrue: [^0].
	^(self d squared) / den!
chiSquare: haplotypeCount
	"n times r squared, on one degree of freedom, for a sample of that many haplotypes"
	^haplotypeCount * self rSquared!
pValue: haplotypeCount
	^ImmunoMath chiSquareSurvival: (self chiSquare: haplotypeCount) df: 1!
printOn: aStream
	aStream nextPutAll: 'LinkageDisequilibrium(D '; nextPutAll: (ImmunoFormat number: self d places: 4);
		nextPutAll: ', D'' '; nextPutAll: (ImmunoFormat number: self dPrime places: 2);
		nextPutAll: ', r2 '; nextPutAll: (ImmunoFormat number: self rSquared places: 2); nextPut: $)! !
