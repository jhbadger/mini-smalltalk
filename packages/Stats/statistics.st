"Descriptive statistics.

The work is in Statistics, which takes any collection of numbers; the Collection methods at the end simply
forward to it, so that  #(1 2 3) mean  reads the way it should. Everything that has a sample and a population
form has both, and the plain name is the sample form, which is what you almost always want: variance and
standardDeviation divide by n - 1, populationVariance and populationStandardDeviation by n.

Quantiles use the linear interpolation between order statistics that R calls type 7 and that most other
software uses too, so the numbers here agree with the ones you will get elsewhere."

Object subclass: #Statistics instanceVariableNames: '' classVariableNames: '' category: 'Stats-Descriptive'!

!Statistics class methodsFor: 'checking'!
numbersOf: aCollection
	"the collection as an Array of numbers, with nils left out, which is what a column read from a file
	is full of"
	| out |
	out := OrderedCollection new.
	aCollection do: [:each | (each isNil or: [each isNumber not]) ifFalse: [out add: each]].
	^out asArray!
need: aCollection atLeast: n for: aName
	aCollection size < n ifTrue: [
		^StatsError new signal: aName, ' needs at least ', n printString, ' values, and there ',
			(aCollection size = 1 ifTrue: ['is 1'] ifFalse: ['are ', aCollection size printString])].
	^aCollection! !

!Statistics class methodsFor: 'middle'!
sum: aCollection
	| total |
	total := 0.
	aCollection do: [:each | total := total + each].
	^total!
mean: aCollection
	| v |
	v := self numbersOf: aCollection.
	self need: v atLeast: 1 for: 'a mean'.
	^(self sum: v) / v size asFloat!
median: aCollection
	^self quantile: 0.5 of: aCollection!
mode: aCollection
	"the commonest value; the smallest of them when several tie"
	| counts best bestValue |
	counts := Dictionary new.
	(self numbersOf: aCollection) do: [:each | counts at: each put: (counts at: each ifAbsent: [0]) + 1].
	counts isEmpty ifTrue: [^StatsError new signal: 'a mode needs at least one value'].
	best := 0. bestValue := nil.
	(counts keys asSortedCollection: [:a :b | a <= b]) do: [:k |
		(counts at: k) > best ifTrue: [best := counts at: k. bestValue := k]].
	^bestValue!
geometricMean: aCollection
	| v total |
	v := self numbersOf: aCollection.
	self need: v atLeast: 1 for: 'a geometric mean'.
	(v anySatisfy: [:each | each <= 0]) ifTrue: [
		^StatsError new signal: 'a geometric mean wants every value to be above zero'].
	total := 0.0.
	v do: [:each | total := total + each asFloat ln].
	^(total / v size) exp!
harmonicMean: aCollection
	| v total |
	v := self numbersOf: aCollection.
	self need: v atLeast: 1 for: 'a harmonic mean'.
	(v anySatisfy: [:each | each = 0]) ifTrue: [^StatsError new signal: 'a harmonic mean cannot take a zero'].
	total := 0.0.
	v do: [:each | total := total + (1.0 / each)].
	^v size / total!
trimmedMean: aFraction of: aCollection
	"the mean with that share dropped from each end"
	| v k kept |
	v := self sorted: aCollection.
	self need: v atLeast: 1 for: 'a trimmed mean'.
	k := (v size * aFraction) truncated.
	kept := v copyFrom: k + 1 to: v size - k.
	kept isEmpty ifTrue: [^self median: v].
	^self mean: kept! !

!Statistics class methodsFor: 'spread'!
variance: aCollection
	"the sample variance, dividing by n - 1"
	| v m total |
	v := self numbersOf: aCollection.
	self need: v atLeast: 2 for: 'a sample variance'.
	m := self mean: v.
	total := 0.0.
	v do: [:each | total := total + ((each - m) * (each - m))].
	^total / (v size - 1)!
populationVariance: aCollection
	| v m total |
	v := self numbersOf: aCollection.
	self need: v atLeast: 1 for: 'a variance'.
	m := self mean: v.
	total := 0.0.
	v do: [:each | total := total + ((each - m) * (each - m))].
	^total / v size!
standardDeviation: aCollection
	^(self variance: aCollection) sqrt!
populationStandardDeviation: aCollection
	^(self populationVariance: aCollection) sqrt!
standardError: aCollection
	"the standard error of the mean"
	| v |
	v := self numbersOf: aCollection.
	^(self standardDeviation: v) / v size sqrt!
range: aCollection
	| v |
	v := self numbersOf: aCollection.
	self need: v atLeast: 1 for: 'a range'.
	^(self maximum: v) - (self minimum: v)!
minimum: aCollection
	| best |
	best := nil.
	(self numbersOf: aCollection) do: [:each | (best isNil or: [each < best]) ifTrue: [best := each]].
	best isNil ifTrue: [^StatsError new signal: 'a minimum needs at least one value'].
	^best!
maximum: aCollection
	| best |
	best := nil.
	(self numbersOf: aCollection) do: [:each | (best isNil or: [each > best]) ifTrue: [best := each]].
	best isNil ifTrue: [^StatsError new signal: 'a maximum needs at least one value'].
	^best!
interquartileRange: aCollection
	^(self quantile: 0.75 of: aCollection) - (self quantile: 0.25 of: aCollection)!
medianAbsoluteDeviation: aCollection
	"the median of the distances from the median: a spread that outliers do not move"
	| v m |
	v := self numbersOf: aCollection.
	m := self median: v.
	^self median: (v collect: [:each | (each - m) abs])!
coefficientOfVariation: aCollection
	| m |
	m := self mean: aCollection.
	m = 0 ifTrue: [^StatsError new signal: 'a coefficient of variation wants a mean that is not zero'].
	^(self standardDeviation: aCollection) / m abs! !

!Statistics class methodsFor: 'order'!
sorted: aCollection
	^(self numbersOf: aCollection) asSortedCollection: [:a :b | a <= b]!
sortedArray: aCollection
	^(self sorted: aCollection) asArray!
quantile: aFraction of: aCollection
	"linear interpolation between order statistics, the way R's type 7 and most other software do it"
	| v n h lower upper |
	(aFraction between: 0 and: 1) ifFalse: [^StatsError new signal: 'a quantile wants a fraction from 0 to 1'].
	v := self sortedArray: aCollection.
	self need: v atLeast: 1 for: 'a quantile'.
	n := v size.
	n = 1 ifTrue: [^v first].
	h := (n - 1) * aFraction asFloat.
	lower := h floor.
	upper := h ceiling.
	lower = upper ifTrue: [^v at: lower + 1].
	^(v at: lower + 1) + ((h - lower) * ((v at: upper + 1) - (v at: lower + 1)))!
percentile: aNumber of: aCollection
	^self quantile: aNumber / 100.0 of: aCollection!
firstQuartile: aCollection
	^self quantile: 0.25 of: aCollection!
thirdQuartile: aCollection
	^self quantile: 0.75 of: aCollection!
fiveNumberSummary: aCollection
	"the minimum, the quartiles with the median between them, and the maximum"
	^Array with: (self minimum: aCollection) with: (self firstQuartile: aCollection)
		with: (self median: aCollection) with: (self thirdQuartile: aCollection)
		with: (self maximum: aCollection)!
ranks: aCollection
	"the rank of each value in the order it was given, ties sharing the average of their ranks, which
	is what a rank test wants"
	| v n sorted ranks i j total |
	v := self numbersOf: aCollection.
	n := v size.
	sorted := ((1 to: n) asSortedCollection: [:a :b | (v at: a) <= (v at: b)]) asArray.
	ranks := Array new: n withAll: 0.
	i := 1.
	[i <= n] whileTrue: [
		j := i.
		[j < n and: [(v at: (sorted at: j + 1)) = (v at: (sorted at: i))]] whileTrue: [j := j + 1].
		total := (i + j) / 2.0.
		i to: j do: [:k | ranks at: (sorted at: k) put: total].
		i := j + 1].
	^ranks!
tieCorrection: aCollection
	"the sum of t cubed less t over the groups of tied values, which the rank tests need"
	| sorted total i j run |
	sorted := self sortedArray: aCollection.
	total := 0. i := 1.
	[i <= sorted size] whileTrue: [
		j := i.
		[j < sorted size and: [(sorted at: j + 1) = (sorted at: i)]] whileTrue: [j := j + 1].
		run := j - i + 1.
		total := total + (run * run * run) - run.
		i := j + 1].
	^total! !

!Statistics class methodsFor: 'shape'!
skewness: aCollection
	"the sample skewness, the adjusted Fisher-Pearson form most software reports"
	| v n m s total |
	v := self numbersOf: aCollection.
	self need: v atLeast: 3 for: 'a skewness'.
	n := v size.
	m := self mean: v.
	s := self standardDeviation: v.
	s = 0 ifTrue: [^StatsError new signal: 'a skewness wants values that are not all the same'].
	total := 0.0.
	v do: [:each | total := total + (((each - m) / s) raisedTo: 3)].
	^n * total / ((n - 1) * (n - 2))!
kurtosis: aCollection
	"the excess kurtosis: zero for a normal distribution"
	| v n m s total g |
	v := self numbersOf: aCollection.
	self need: v atLeast: 4 for: 'a kurtosis'.
	n := v size.
	m := self mean: v.
	s := self populationStandardDeviation: v.
	s = 0 ifTrue: [^StatsError new signal: 'a kurtosis wants values that are not all the same'].
	total := 0.0.
	v do: [:each | total := total + (((each - m) / s) raisedTo: 4)].
	g := total / n - 3.0.
	^((n - 1) * ((n + 1) * g + 6)) / ((n - 2) * (n - 3))!
zScores: aCollection
	| v m s |
	v := self numbersOf: aCollection.
	m := self mean: v.
	s := self standardDeviation: v.
	s = 0 ifTrue: [^StatsError new signal: 'z scores want values that are not all the same'].
	^v collect: [:each | (each - m) / s]!
normalized: aCollection
	"everything moved onto the range 0 to 1"
	| v lo hi |
	v := self numbersOf: aCollection.
	lo := self minimum: v.
	hi := self maximum: v.
	hi = lo ifTrue: [^v collect: [:each | 0.0]].
	^v collect: [:each | (each - lo) / (hi - lo) asFloat]!
outliers: aCollection
	"the values more than one and a half interquartile ranges outside the quartiles, which is the rule
	a box plot draws its whiskers by"
	| q1 q3 iqr |
	q1 := self firstQuartile: aCollection.
	q3 := self thirdQuartile: aCollection.
	iqr := q3 - q1.
	^(self numbersOf: aCollection) select: [:each |
		each < (q1 - (1.5 * iqr)) or: [each > (q3 + (1.5 * iqr))]]! !

!Statistics class methodsFor: 'two samples'!
pairsOf: aCollection and: anotherCollection
	"the pairs where both sides have a number, as two Arrays"
	| left right a b n |
	a := aCollection asOrderedCollection asArray.
	b := anotherCollection asOrderedCollection asArray.
	n := a size min: b size.
	left := OrderedCollection new. right := OrderedCollection new.
	1 to: n do: [:i |
		(((a at: i) isNil or: [(a at: i) isNumber not]) or: [(b at: i) isNil or: [(b at: i) isNumber not]])
			ifFalse: [left add: (a at: i). right add: (b at: i)]].
	^Array with: left asArray with: right asArray!
covariance: aCollection with: anotherCollection
	| pair a b ma mb total |
	pair := self pairsOf: aCollection and: anotherCollection.
	a := pair first. b := pair last.
	self need: a atLeast: 2 for: 'a covariance'.
	ma := self mean: a. mb := self mean: b.
	total := 0.0.
	1 to: a size do: [:i | total := total + (((a at: i) - ma) * ((b at: i) - mb))].
	^total / (a size - 1)!
correlation: aCollection with: anotherCollection
	"Pearson's r"
	| pair a b sa sb |
	pair := self pairsOf: aCollection and: anotherCollection.
	a := pair first. b := pair last.
	self need: a atLeast: 2 for: 'a correlation'.
	sa := self standardDeviation: a.
	sb := self standardDeviation: b.
	(sa = 0 or: [sb = 0]) ifTrue: [
		^StatsError new signal: 'a correlation wants both sides to vary'].
	^(self covariance: a with: b) / (sa * sb)!
spearman: aCollection with: anotherCollection
	"Spearman's rho: Pearson's r on the ranks"
	| pair |
	pair := self pairsOf: aCollection and: anotherCollection.
	^self correlation: (self ranks: pair first) with: (self ranks: pair last)! !

!Statistics class methodsFor: 'reporting'!
summaryOf: aCollection
	| v out |
	v := self numbersOf: aCollection.
	out := WriteStream on: String new.
	v isEmpty ifTrue: [^'(no numbers)'].
	out nextPutAll: 'n       '; print: v size; nl.
	out nextPutAll: 'mean    '; nextPutAll: (self mean: v) asFloat printString; nl.
	v size > 1 ifTrue: [
		out nextPutAll: 'sd      '; nextPutAll: (self standardDeviation: v) asFloat printString; nl].
	out nextPutAll: 'min     '; nextPutAll: (self minimum: v) printString; nl.
	out nextPutAll: 'Q1      '; nextPutAll: (self firstQuartile: v) asFloat printString; nl.
	out nextPutAll: 'median  '; nextPutAll: (self median: v) asFloat printString; nl.
	out nextPutAll: 'Q3      '; nextPutAll: (self thirdQuartile: v) asFloat printString; nl.
	out nextPutAll: 'max     '; nextPutAll: (self maximum: v) printString; nl.
	^out contents! !

"---- the same thing said the short way ----"

!Collection methodsFor: 'statistics'!
mean
	^Statistics mean: self!
median
	^Statistics median: self!
mode
	^Statistics mode: self!
geometricMean
	^Statistics geometricMean: self!
harmonicMean
	^Statistics harmonicMean: self!
trimmedMean: aFraction
	^Statistics trimmedMean: aFraction of: self!
variance
	"the sample variance, dividing by n - 1"
	^Statistics variance: self!
populationVariance
	^Statistics populationVariance: self!
standardDeviation
	^Statistics standardDeviation: self!
populationStandardDeviation
	^Statistics populationStandardDeviation: self!
standardError
	^Statistics standardError: self!
range
	"the largest value less the smallest"
	^Statistics range: self!
interquartileRange
	^Statistics interquartileRange: self!
medianAbsoluteDeviation
	^Statistics medianAbsoluteDeviation: self!
coefficientOfVariation
	^Statistics coefficientOfVariation: self!
quantile: aFraction
	^Statistics quantile: aFraction of: self!
percentile: aNumber
	^Statistics percentile: aNumber of: self!
firstQuartile
	^Statistics firstQuartile: self!
thirdQuartile
	^Statistics thirdQuartile: self!
fiveNumberSummary
	^Statistics fiveNumberSummary: self!
ranks
	^Statistics ranks: self!
skewness
	^Statistics skewness: self!
kurtosis
	^Statistics kurtosis: self!
zScores
	^Statistics zScores: self!
normalized
	^Statistics normalized: self!
outliers
	^Statistics outliers: self!
covarianceWith: aCollection
	^Statistics covariance: self with: aCollection!
correlationWith: aCollection
	^Statistics correlation: self with: aCollection!
spearmanWith: aCollection
	^Statistics spearman: self with: aCollection!
statisticsSummary
	^Statistics summaryOf: self!
histogram
	^TextPlot histogram: self!
histogramWithBins: n
	^TextPlot histogram: self bins: n!
boxPlot
	^TextPlot boxPlot: self!
sparkline
	^TextPlot sparkline: self! !
