"The hypothesis tests and the regressions.

Every test is an object: you make it, run it, and ask it for its statistic, its degrees of freedom, its
p-value and a sentence saying what that means. They all answer a report, and they all print the one thing a
test is for, which is the p-value, rather than hiding it behind a boolean.

A p-value is not a verdict. isSignificant answers whether p is below the level the test holds (0.05 unless
you set another), and that is all it means; the report says so too."

Object subclass: #HypothesisTest instanceVariableNames: 'statistic degreesOfFreedom pValue level ran' classVariableNames: '' category: 'Stats-Tests'!
HypothesisTest subclass: #TTest instanceVariableNames: 'first second expected kind pooled meanDifference standardError' classVariableNames: '' category: 'Stats-Tests'!
HypothesisTest subclass: #ChiSquareTest instanceVariableNames: 'observed expected2 rows columns kind' classVariableNames: '' category: 'Stats-Tests'!
HypothesisTest subclass: #MannWhitneyTest instanceVariableNames: 'first second u1 u2 zScore' classVariableNames: '' category: 'Stats-Tests'!
HypothesisTest subclass: #WilcoxonSignedRankTest instanceVariableNames: 'first second w zScore pairs' classVariableNames: '' category: 'Stats-Tests'!
HypothesisTest subclass: #CorrelationTest instanceVariableNames: 'first second r method' classVariableNames: '' category: 'Stats-Tests'!
HypothesisTest subclass: #AnovaTest instanceVariableNames: 'groups betweenSS withinSS betweenDF withinDF' classVariableNames: '' category: 'Stats-Tests'!
Object subclass: #LinearRegression instanceVariableNames: 'x y slope intercept n residualSS totalSS slopeError interceptError' classVariableNames: '' category: 'Stats-Tests'!

!HypothesisTest class methodsFor: 'instance creation'!
new
	^self basicNew setUp! !

!HypothesisTest methodsFor: 'private'!
setUp
	level := 0.05.
	ran := false!
run
	^self subclassResponsibility!
ensureRan
	ran ifFalse: [self run].
	^self! !

!HypothesisTest methodsFor: 'accessing'!
name
	^self subclassResponsibility!
statistic
	^self ensureRan; basicStatistic!
basicStatistic
	^statistic!
degreesOfFreedom
	^self ensureRan; basicDegreesOfFreedom!
basicDegreesOfFreedom
	^degreesOfFreedom!
p
	"the p-value: how often a difference at least this big would turn up if nothing were going on"
	^self ensureRan; basicP!
basicP
	^pValue!
pValue
	^self p!
level
	^level!
level: aNumber
	level := aNumber!
hasRun
	^ran! !

!HypothesisTest methodsFor: 'interpreting'!
isSignificant
	"whether the p-value is below the level, and nothing more than that"
	^self p < level!
verdict
	^self isSignificant
		ifTrue: ['p is below ', level printString, ', so a difference this big would be unusual if nothing were going on']
		ifFalse: ['p is not below ', level printString, ', so this is the sort of difference that turns up anyway']!
formattedP
	| p |
	p := self p.
	p < 0.0001 ifTrue: [^'< 0.0001'].
	^p printShowingDecimalPlaces: 4! !

!HypothesisTest methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: self name; nextPutAll: '(p = '; nextPutAll: self formattedP; nextPut: $)!
report
	| out |
	out := WriteStream on: String new.
	out nextPutAll: self name; nl.
	out nextPutAll: (String new: (self name size min: 70) withAll: $-); nl.
	out nextPutAll: self details.
	out nextPutAll: 'p        '; nextPutAll: self formattedP; nl; nl.
	out nextPutAll: self verdict; nl.
	^out contents!
details
	| out |
	out := WriteStream on: String new.
	out nextPutAll: 'statistic '; nextPutAll: (self statistic asFloat printShowingDecimalPlaces: 4); nl.
	self degreesOfFreedom ifNotNil: [:df |
		out nextPutAll: 'df       '; nextPutAll: (df asFloat printShowingDecimalPlaces: 2); nl].
	^out contents! !

"---- Student's t ----"

!TTest class methodsFor: 'instance creation'!
of: aCollection against: aNumber
	"the one-sample test: is the mean of this different from that number"
	^self new first: aCollection; expected: aNumber; kind: #oneSample; yourself!
of: aCollection
	^self of: aCollection against: 0!
of: aCollection and: anotherCollection
	"Welch's two-sample test, which does not assume the two spreads are the same; it is the safer
	default and the one most software now uses"
	^self new first: aCollection; second: anotherCollection; kind: #welch; yourself!
pooledOf: aCollection and: anotherCollection
	"the classic two-sample test, which does assume the spreads are the same"
	^self new first: aCollection; second: anotherCollection; kind: #pooled; yourself!
pairedOf: aCollection and: anotherCollection
	"the test on the differences, for before-and-after measurements of the same things"
	^self new first: aCollection; second: anotherCollection; kind: #paired; yourself! !

!TTest methodsFor: 'setting up'!
first: aCollection
	first := Statistics numbersOf: aCollection!
second: aCollection
	second := Statistics numbersOf: aCollection!
expected: aNumber
	expected := aNumber!
kind: aSymbol
	kind := aSymbol!
kind
	^kind!
meanDifference
	^self ensureRan; basicMeanDifference!
basicMeanDifference
	^meanDifference!
standardError
	^self ensureRan; basicStandardError!
basicStandardError
	^standardError! !

!TTest methodsFor: 'running'!
name
	kind == #oneSample ifTrue: [^'one-sample t test'].
	kind == #paired ifTrue: [^'paired t test'].
	kind == #pooled ifTrue: [^'two-sample t test, pooled variance'].
	^'two-sample t test, Welch'!
run
	ran := true.
	kind == #oneSample ifTrue: [^self runOneSample].
	kind == #paired ifTrue: [^self runPaired].
	kind == #pooled ifTrue: [^self runPooled].
	^self runWelch!
runOneSample
	| n m s |
	Statistics need: first atLeast: 2 for: 'a one-sample t test'.
	n := first size.
	m := Statistics mean: first.
	s := Statistics standardDeviation: first.
	s = 0 ifTrue: [^StatsError new signal: 'a t test wants values that are not all the same'].
	meanDifference := m - expected.
	standardError := s / n sqrt.
	statistic := meanDifference / standardError.
	degreesOfFreedom := n - 1.
	pValue := Distribution tTwoTail: statistic df: degreesOfFreedom.
	^self!
runPaired
	| differences |
	(first size = second size) ifFalse: [
		^StatsError new signal: 'a paired t test wants the same number of values on both sides'].
	differences := (1 to: first size) collect: [:i | (first at: i) - (second at: i)].
	Statistics need: differences atLeast: 2 for: 'a paired t test'.
	meanDifference := Statistics mean: differences.
	standardError := (Statistics standardDeviation: differences) / differences size sqrt.
	standardError = 0 ifTrue: [^StatsError new signal: 'a paired t test wants differences that are not all the same'].
	statistic := meanDifference / standardError.
	degreesOfFreedom := differences size - 1.
	pValue := Distribution tTwoTail: statistic df: degreesOfFreedom.
	^self!
runPooled
	| n1 n2 v1 v2 sp |
	Statistics need: first atLeast: 2 for: 'a two-sample t test'.
	Statistics need: second atLeast: 2 for: 'a two-sample t test'.
	n1 := first size. n2 := second size.
	v1 := Statistics variance: first. v2 := Statistics variance: second.
	sp := (((n1 - 1) * v1) + ((n2 - 1) * v2)) / (n1 + n2 - 2).
	meanDifference := (Statistics mean: first) - (Statistics mean: second).
	standardError := (sp * ((1.0 / n1) + (1.0 / n2))) sqrt.
	standardError = 0 ifTrue: [^StatsError new signal: 'a t test wants values that are not all the same'].
	statistic := meanDifference / standardError.
	degreesOfFreedom := n1 + n2 - 2.
	pValue := Distribution tTwoTail: statistic df: degreesOfFreedom.
	^self!
runWelch
	| n1 n2 v1 v2 a b |
	Statistics need: first atLeast: 2 for: 'a two-sample t test'.
	Statistics need: second atLeast: 2 for: 'a two-sample t test'.
	n1 := first size. n2 := second size.
	v1 := Statistics variance: first. v2 := Statistics variance: second.
	a := v1 / n1. b := v2 / n2.
	meanDifference := (Statistics mean: first) - (Statistics mean: second).
	standardError := (a + b) sqrt.
	standardError = 0 ifTrue: [^StatsError new signal: 'a t test wants values that are not all the same'].
	statistic := meanDifference / standardError.
	"the Welch-Satterthwaite degrees of freedom, which need not be a whole number"
	degreesOfFreedom := ((a + b) * (a + b)) / ((a * a / (n1 - 1)) + (b * b / (n2 - 1))).
	pValue := Distribution tTwoTail: statistic df: degreesOfFreedom.
	^self!
confidenceInterval
	"the interval the mean difference is in, at one minus the level"
	| t |
	self ensureRan.
	t := Distribution tQuantile: 1.0 - (level / 2.0) df: degreesOfFreedom.
	^Array with: meanDifference - (t * standardError) with: meanDifference + (t * standardError)!
details
	| out ci |
	out := WriteStream on: String new.
	out nextPutAll: 't        '; nextPutAll: (self statistic printShowingDecimalPlaces: 4); nl.
	out nextPutAll: 'df       '; nextPutAll: (self degreesOfFreedom asFloat printShowingDecimalPlaces: 2); nl.
	out nextPutAll: 'mean difference '; nextPutAll: (self meanDifference asFloat printShowingDecimalPlaces: 4); nl.
	ci := self confidenceInterval.
	out nextPutAll: ((1.0 - level) * 100) rounded printString, '% interval   ';
		nextPutAll: (ci first asFloat printShowingDecimalPlaces: 4); nextPutAll: ' to ';
		nextPutAll: (ci last asFloat printShowingDecimalPlaces: 4); nl.
	^out contents! !

"---- chi-square ----"

!ChiSquareTest class methodsFor: 'instance creation'!
goodnessOf: someCounts against: someExpected
	^self new observed: someCounts; expectedCounts: someExpected; kind: #goodness; yourself!
goodnessOf: someCounts
	"against the flat expectation that every category is as likely as the others"
	| n |
	n := (Statistics sum: someCounts) / someCounts size asFloat.
	^self goodnessOf: someCounts against: (someCounts collect: [:each | n])!
independenceOf: aTable
	"a contingency table: a collection of rows, each a collection of counts"
	^self new table: aTable; kind: #independence; yourself! !

!ChiSquareTest methodsFor: 'setting up'!
observed: someCounts
	observed := someCounts asArray!
expectedCounts: someCounts
	expected2 := someCounts asArray!
table: aTable
	observed := (aTable collect: [:row | row asArray]) asArray.
	rows := observed size.
	columns := observed isEmpty ifTrue: [0] ifFalse: [observed first size]!
kind: aSymbol
	kind := aSymbol!
observed
	^observed!
expectedCounts
	^self ensureRan; basicExpected!
basicExpected
	^expected2! !

!ChiSquareTest methodsFor: 'running'!
name
	^kind == #independence ifTrue: ['chi-square test of independence'] ifFalse: ['chi-square goodness of fit']!
run
	ran := true.
	^kind == #independence ifTrue: [self runIndependence] ifFalse: [self runGoodness]!
runGoodness
	| total |
	observed size = expected2 size ifFalse: [
		^StatsError new signal: 'there must be as many expected counts as observed ones'].
	observed size < 2 ifTrue: [^StatsError new signal: 'a chi-square test wants at least two categories'].
	(expected2 anySatisfy: [:each | each <= 0]) ifTrue: [
		^StatsError new signal: 'every expected count must be above zero'].
	total := 0.0.
	1 to: observed size do: [:i |
		| o e |
		o := observed at: i. e := expected2 at: i.
		total := total + ((o - e) * (o - e) / e)].
	statistic := total.
	degreesOfFreedom := observed size - 1.
	pValue := Distribution chiSquareTail: statistic df: degreesOfFreedom.
	^self!
runIndependence
	| rowSums columnSums grand total e |
	(rows < 2 or: [columns < 2]) ifTrue: [
		^StatsError new signal: 'a test of independence wants at least two rows and two columns'].
	(observed allSatisfy: [:row | row size = columns]) ifFalse: [
		^StatsError new signal: 'the rows of the table are not all the same length'].
	rowSums := observed collect: [:row | Statistics sum: row].
	columnSums := (1 to: columns) collect: [:j | Statistics sum: (observed collect: [:row | row at: j])].
	grand := Statistics sum: rowSums.
	grand = 0 ifTrue: [^StatsError new signal: 'the table is all zeroes'].
	expected2 := (1 to: rows) collect: [:i |
		(1 to: columns) collect: [:j | (rowSums at: i) * (columnSums at: j) / grand asFloat]].
	total := 0.0.
	1 to: rows do: [:i |
		1 to: columns do: [:j |
			e := (expected2 at: i) at: j.
			e <= 0 ifTrue: [^StatsError new signal: 'a row or a column of the table is all zeroes'].
			total := total + ((((observed at: i) at: j) - e) squared / e)]].
	statistic := total.
	degreesOfFreedom := (rows - 1) * (columns - 1).
	pValue := Distribution chiSquareTail: statistic df: degreesOfFreedom.
	^self!
smallestExpected
	"below five in any cell and the approximation starts to wobble; it is the usual thing to check"
	| best |
	self ensureRan.
	best := nil.
	kind == #independence
		ifTrue: [expected2 do: [:row | row do: [:e | (best isNil or: [e < best]) ifTrue: [best := e]]]]
		ifFalse: [expected2 do: [:e | (best isNil or: [e < best]) ifTrue: [best := e]]].
	^best!
details
	| out |
	out := WriteStream on: String new.
	out nextPutAll: 'chi2     '; nextPutAll: (self statistic printShowingDecimalPlaces: 4); nl.
	out nextPutAll: 'df       '; print: self degreesOfFreedom; nl.
	out nextPutAll: 'smallest expected count '; nextPutAll: (self smallestExpected asFloat printShowingDecimalPlaces: 2); nl.
	self smallestExpected < 5 ifTrue: [
		out nextPutAll: '(an expected count under five: the chi-square approximation is shaky here)'; nl].
	^out contents! !

"---- Mann-Whitney ----"

!MannWhitneyTest class methodsFor: 'instance creation'!
of: aCollection and: anotherCollection
	"the rank test for two samples: does one tend to be above the other. It asks nothing about the
	shape of the distributions, which is why you reach for it when a t test looks wrong."
	^self new first: aCollection; second: anotherCollection; yourself! !

!MannWhitneyTest methodsFor: 'setting up'!
first: aCollection
	first := Statistics numbersOf: aCollection!
second: aCollection
	second := Statistics numbersOf: aCollection!
u
	"the smaller of the two U statistics, which is the one tables are written for"
	^self ensureRan; basicU!
basicU
	^u1 min: u2!
u1
	^self ensureRan; basicU1!
basicU1
	^u1!
u2
	^self ensureRan; basicU2!
basicU2
	^u2!
z
	^self ensureRan; basicZ!
basicZ
	^zScore! !

!MannWhitneyTest methodsFor: 'running'!
name
	^'Mann-Whitney U test'!
run
	| n1 n2 all ranks r1 mean sigma ties correction |
	ran := true.
	Statistics need: first atLeast: 1 for: 'a Mann-Whitney test'.
	Statistics need: second atLeast: 1 for: 'a Mann-Whitney test'.
	n1 := first size. n2 := second size.
	all := first, second.
	ranks := Statistics ranks: all.
	r1 := 0.0.
	1 to: n1 do: [:i | r1 := r1 + (ranks at: i)].
	u1 := r1 - (n1 * (n1 + 1) / 2.0).
	u2 := (n1 * n2) - u1.
	mean := n1 * n2 / 2.0.
	ties := Statistics tieCorrection: all.
	correction := ties / ((n1 + n2) * (n1 + n2 - 1)) asFloat.
	sigma := (n1 * n2 / 12.0 * (n1 + n2 + 1 - correction)) sqrt.
	sigma = 0 ifTrue: [
		statistic := self basicU. degreesOfFreedom := nil. zScore := 0.0. pValue := 1.0. ^self].
	"the normal approximation with a half taken off for the step from one whole number to the next"
	zScore := ((u1 - mean) abs - 0.5) / sigma.
	zScore := zScore max: 0.0.
	statistic := self basicU.
	degreesOfFreedom := nil.
	pValue := 2.0 * (Distribution normalTail: zScore) min: 1.0.
	^self!
details
	| out |
	out := WriteStream on: String new.
	out nextPutAll: 'U        '; nextPutAll: (self u asFloat printShowingDecimalPlaces: 2); nl.
	out nextPutAll: 'U1, U2   '; nextPutAll: (self u1 asFloat printShowingDecimalPlaces: 2);
		nextPutAll: ', '; nextPutAll: (self u2 asFloat printShowingDecimalPlaces: 2); nl.
	out nextPutAll: 'z        '; nextPutAll: (self z asFloat printShowingDecimalPlaces: 4); nl.
	out nextPutAll: '(the normal approximation, with a continuity correction and a correction for ties)'; nl.
	^out contents! !

"---- Wilcoxon signed rank ----"

!WilcoxonSignedRankTest class methodsFor: 'instance creation'!
of: aCollection and: anotherCollection
	"the paired rank test: the Mann-Whitney of before-and-after measurements"
	^self new first: aCollection; second: anotherCollection; yourself!
of: aCollection
	"against a median of zero"
	^self new first: aCollection; second: (aCollection collect: [:each | 0]); yourself! !

!WilcoxonSignedRankTest methodsFor: 'setting up'!
first: aCollection
	first := Statistics numbersOf: aCollection!
second: aCollection
	second := Statistics numbersOf: aCollection!
w
	^self ensureRan; basicW!
basicW
	^w!
z
	^self ensureRan; basicZ!
basicZ
	^zScore!
usedPairs
	^self ensureRan; basicPairs!
basicPairs
	^pairs! !

!WilcoxonSignedRankTest methodsFor: 'running'!
name
	^'Wilcoxon signed rank test'!
run
	| differences kept ranks positive negative n mean sigma ties |
	ran := true.
	first size = second size ifFalse: [
		^StatsError new signal: 'a signed rank test wants the same number of values on both sides'].
	differences := (1 to: first size) collect: [:i | (first at: i) - (second at: i)].
	kept := differences reject: [:each | each = 0].
	kept isEmpty ifTrue: [^StatsError new signal: 'every pair is the same, so there is nothing to test'].
	pairs := kept size.
	n := pairs.
	ranks := Statistics ranks: (kept collect: [:each | each abs]).
	positive := 0.0. negative := 0.0.
	1 to: n do: [:i |
		(kept at: i) > 0
			ifTrue: [positive := positive + (ranks at: i)]
			ifFalse: [negative := negative + (ranks at: i)]].
	w := positive min: negative.
	statistic := w.
	degreesOfFreedom := nil.
	mean := n * (n + 1) / 4.0.
	ties := Statistics tieCorrection: (kept collect: [:each | each abs]).
	sigma := ((n * (n + 1) * ((2 * n) + 1) / 24.0) - (ties / 48.0)) sqrt.
	sigma = 0 ifTrue: [zScore := 0.0. pValue := 1.0. ^self].
	zScore := (((w - mean) abs) - 0.5) / sigma.
	zScore := zScore max: 0.0.
	pValue := 2.0 * (Distribution normalTail: zScore) min: 1.0.
	^self!
details
	| out |
	out := WriteStream on: String new.
	out nextPutAll: 'W        '; nextPutAll: (self w asFloat printShowingDecimalPlaces: 2); nl.
	out nextPutAll: 'pairs    '; print: self usedPairs; nextPutAll: ' (pairs with no difference are dropped)'; nl.
	out nextPutAll: 'z        '; nextPutAll: (self z asFloat printShowingDecimalPlaces: 4); nl.
	^out contents! !

"---- is a correlation real ----"

!CorrelationTest class methodsFor: 'instance creation'!
of: aCollection and: anotherCollection
	"Pearson's r, and whether it is further from zero than chance would give"
	^self new first: aCollection; second: anotherCollection; method: #pearson; yourself!
spearmanOf: aCollection and: anotherCollection
	^self new first: aCollection; second: anotherCollection; method: #spearman; yourself! !

!CorrelationTest methodsFor: 'setting up'!
first: aCollection
	first := aCollection!
second: aCollection
	second := aCollection!
method: aSymbol
	method := aSymbol!
r
	^self ensureRan; basicR!
basicR
	^r! !

!CorrelationTest methodsFor: 'running'!
name
	^method == #spearman ifTrue: ['Spearman rank correlation'] ifFalse: ['Pearson correlation']!
run
	| pair n |
	ran := true.
	pair := Statistics pairsOf: first and: second.
	n := pair first size.
	Statistics need: pair first atLeast: 3 for: 'a correlation test'.
	r := method == #spearman
		ifTrue: [Statistics spearman: pair first with: pair last]
		ifFalse: [Statistics correlation: pair first with: pair last].
	r abs >= 1.0
		ifTrue: [statistic := r > 0 ifTrue: [1.0e10] ifFalse: [-1.0e10]]
		ifFalse: [statistic := r * ((n - 2) / (1.0 - (r * r))) sqrt].
	degreesOfFreedom := n - 2.
	pValue := Distribution tTwoTail: statistic df: degreesOfFreedom.
	^self!
details
	| out |
	out := WriteStream on: String new.
	out nextPutAll: 'r        '; nextPutAll: (self r asFloat printShowingDecimalPlaces: 4); nl.
	out nextPutAll: 't        '; nextPutAll: (self statistic asFloat printShowingDecimalPlaces: 4); nl.
	out nextPutAll: 'df       '; print: self degreesOfFreedom; nl.
	^out contents! !

"---- one-way analysis of variance ----"

!AnovaTest class methodsFor: 'instance creation'!
of: someGroups
	"a collection of collections: are the group means further apart than chance would make them"
	^self new groups: someGroups; yourself! !

!AnovaTest methodsFor: 'setting up'!
groups: someGroups
	groups := (someGroups collect: [:each | Statistics numbersOf: each]) asArray!
groups
	^groups!
betweenSS
	^self ensureRan; basicBetweenSS!
basicBetweenSS
	^betweenSS!
withinSS
	^self ensureRan; basicWithinSS!
basicWithinSS
	^withinSS!
etaSquared
	"the share of the variation the grouping accounts for"
	self ensureRan.
	^betweenSS / (betweenSS + withinSS)! !

!AnovaTest methodsFor: 'running'!
name
	^'one-way analysis of variance'!
run
	| all grand total |
	ran := true.
	groups size < 2 ifTrue: [^StatsError new signal: 'an analysis of variance wants at least two groups'].
	(groups allSatisfy: [:each | each size >= 1]) ifFalse: [
		^StatsError new signal: 'every group must have something in it'].
	all := OrderedCollection new.
	groups do: [:each | all addAll: each].
	total := all size.
	total <= groups size ifTrue: [^StatsError new signal: 'there is nothing left to measure the groups against'].
	grand := Statistics mean: all.
	betweenSS := 0.0. withinSS := 0.0.
	groups do: [:g |
		| m |
		m := Statistics mean: g.
		betweenSS := betweenSS + (g size * (m - grand) squared).
		g do: [:each | withinSS := withinSS + (each - m) squared]].
	betweenDF := groups size - 1.
	withinDF := total - groups size.
	withinSS = 0 ifTrue: [
		statistic := 1.0e10. degreesOfFreedom := betweenDF. pValue := 0.0. ^self].
	statistic := (betweenSS / betweenDF) / (withinSS / withinDF).
	degreesOfFreedom := betweenDF.
	pValue := Distribution fTail: statistic df1: betweenDF df2: withinDF.
	^self!
details
	| out |
	out := WriteStream on: String new.
	self ensureRan.
	out nextPutAll: 'F        '; nextPutAll: (self statistic asFloat printShowingDecimalPlaces: 4); nl.
	out nextPutAll: 'df       '; print: betweenDF; nextPutAll: ', '; print: withinDF; nl.
	out nextPutAll: 'between  '; nextPutAll: (betweenSS printShowingDecimalPlaces: 4); nl.
	out nextPutAll: 'within   '; nextPutAll: (withinSS printShowingDecimalPlaces: 4); nl.
	out nextPutAll: 'eta2     '; nextPutAll: (self etaSquared printShowingDecimalPlaces: 4); nl.
	^out contents! !

"---- fitting a straight line ----"

!LinearRegression class methodsFor: 'instance creation'!
of: xValues and: yValues
	"least squares: the line through the points that leaves the smallest total squared distance"
	^self basicNew setX: xValues y: yValues! !

!LinearRegression methodsFor: 'private'!
setX: xValues y: yValues
	| pair mx my sxx sxy |
	pair := Statistics pairsOf: xValues and: yValues.
	x := pair first. y := pair last.
	Statistics need: x atLeast: 3 for: 'a regression'.
	n := x size.
	mx := Statistics mean: x. my := Statistics mean: y.
	sxx := 0.0. sxy := 0.0.
	1 to: n do: [:i |
		sxx := sxx + ((x at: i) - mx) squared.
		sxy := sxy + (((x at: i) - mx) * ((y at: i) - my))].
	sxx = 0 ifTrue: [^StatsError new signal: 'a regression wants the x values to vary'].
	slope := sxy / sxx.
	intercept := my - (slope * mx).
	residualSS := 0.0. totalSS := 0.0.
	1 to: n do: [:i |
		residualSS := residualSS + ((y at: i) - (self valueAt: (x at: i))) squared.
		totalSS := totalSS + ((y at: i) - my) squared].
	slopeError := n > 2 ifTrue: [((residualSS / (n - 2)) / sxx) sqrt] ifFalse: [0.0].
	interceptError := n > 2
		ifTrue: [((residualSS / (n - 2)) * ((1.0 / n) + (mx * mx / sxx))) sqrt]
		ifFalse: [0.0].
	^self! !

!LinearRegression methodsFor: 'the line'!
slope
	^slope!
intercept
	^intercept!
n
	^n!
valueAt: aNumber
	"what the line says y is for that x"
	^intercept + (slope * aNumber)!
predict: aCollection
	^aCollection collect: [:each | self valueAt: each]!
residuals
	^(1 to: n) collect: [:i | (y at: i) - (self valueAt: (x at: i))]!
fittedValues
	^(1 to: n) collect: [:i | self valueAt: (x at: i)]! !

!LinearRegression methodsFor: 'how good the fit is'!
rSquared
	"the share of the variation in y the line accounts for"
	totalSS = 0 ifTrue: [^1.0].
	^1.0 - (residualSS / totalSS)!
r
	"the correlation, which carries the sign the r squared has lost"
	^slope >= 0 ifTrue: [self rSquared sqrt] ifFalse: [self rSquared sqrt negated]!
residualSumOfSquares
	^residualSS!
totalSumOfSquares
	^totalSS!
residualStandardError
	n <= 2 ifTrue: [^0.0].
	^(residualSS / (n - 2)) sqrt!
slopeStandardError
	^slopeError!
interceptStandardError
	^interceptError!
degreesOfFreedom
	^n - 2!
tForSlope
	slopeError = 0 ifTrue: [^0.0].
	^slope / slopeError!
pForSlope
	"the p-value of the slope: how often a slope this far from flat would turn up by chance"
	slopeError = 0 ifTrue: [^1.0].
	^Distribution tTwoTail: self tForSlope df: self degreesOfFreedom!
confidenceIntervalForSlopeAt: aLevel
	| t |
	slopeError = 0 ifTrue: [^Array with: slope with: slope].
	t := Distribution tQuantile: 1.0 - (aLevel / 2.0) df: self degreesOfFreedom.
	^Array with: slope - (t * slopeError) with: slope + (t * slopeError)!
confidenceIntervalForSlope
	^self confidenceIntervalForSlopeAt: 0.05! !

!LinearRegression methodsFor: 'printing'!
equation
	^'y = ', (slope printShowingDecimalPlaces: 4), 'x ',
		(intercept < 0 ifTrue: ['- '] ifFalse: ['+ ']), (intercept abs printShowingDecimalPlaces: 4)!
printOn: aStream
	aStream nextPutAll: 'a LinearRegression('; nextPutAll: self equation; nextPut: $)!
report
	| out ci |
	out := WriteStream on: String new.
	out nextPutAll: 'least squares line'; nl.
	out nextPutAll: (String new: 40 withAll: $-); nl.
	out nextPutAll: self equation; nl; nl.
	out nextPutAll: 'n        '; print: n; nl.
	out nextPutAll: 'slope    '; nextPutAll: (slope printShowingDecimalPlaces: 6);
		nextPutAll: '  (se '; nextPutAll: (slopeError printShowingDecimalPlaces: 6); nextPut: $); nl.
	out nextPutAll: 'intercept '; nextPutAll: (intercept printShowingDecimalPlaces: 6);
		nextPutAll: '  (se '; nextPutAll: (interceptError printShowingDecimalPlaces: 6); nextPut: $); nl.
	out nextPutAll: 'r2       '; nextPutAll: (self rSquared printShowingDecimalPlaces: 4); nl.
	out nextPutAll: 'residual se '; nextPutAll: (self residualStandardError printShowingDecimalPlaces: 4); nl.
	out nextPutAll: 't on the slope '; nextPutAll: (self tForSlope printShowingDecimalPlaces: 4);
		nextPutAll: ' on '; print: self degreesOfFreedom; nextPutAll: ' df'; nl.
	out nextPutAll: 'p on the slope '; nextPutAll: (self pForSlope printShowingDecimalPlaces: 6); nl.
	ci := self confidenceIntervalForSlope.
	out nextPutAll: '95% interval for the slope  '; nextPutAll: (ci first printShowingDecimalPlaces: 4);
		nextPutAll: ' to '; nextPutAll: (ci last printShowingDecimalPlaces: 4); nl.
	^out contents! !
