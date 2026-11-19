"Tests for the Stats package.

The distributions are checked against published values, the descriptive statistics against worked examples,
and the tests against figures taken from statistics textbooks, so that a change that breaks a formula shows
up as a wrong number rather than as nothing at all. The example data is simulated with known group
differences and a known correlation, so the tests can also ask whether the methods find what is there."

TestCase subclass: #DistributionTest instanceVariableNames: '' classVariableNames: '' category: 'Stats-Tests'!
TestCase subclass: #StatisticsTest instanceVariableNames: '' classVariableNames: '' category: 'Stats-Tests'!
TestCase subclass: #InferenceTest instanceVariableNames: '' classVariableNames: '' category: 'Stats-Tests'!
TestCase subclass: #DataTableTest instanceVariableNames: '' classVariableNames: '' category: 'Stats-Tests'!

"---- the distributions ----"

!DistributionTest methodsFor: 'the gamma function'!
testLnGamma
	self assert: (Distribution lnGamma: 0.5) closeTo: 0.5723649429247001 within: 1.0e-12.
	self assert: (Distribution lnGamma: 1.0) closeTo: 0.0 within: 1.0e-12.
	self assert: (Distribution lnGamma: 100.0) closeTo: 359.1342053695754 within: 1.0e-9!
testGammaOfAWholeNumberIsAFactorial
	self assert: (Distribution gamma: 5.0) closeTo: 24.0 within: 1.0e-9.
	self assert: (Distribution gamma: 7.0) closeTo: 720.0 within: 1.0e-6!
testLnGammaBelowAHalfUsesTheReflection
	self assert: (Distribution lnGamma: 0.25) closeTo: 1.2880225246980774 within: 1.0e-10!
testBinomial
	self assert: (Distribution binomial: 10 choose: 3) equals: 120.
	self assert: (Distribution binomial: 5 choose: 0) equals: 1.
	self assert: (Distribution binomial: 5 choose: 9) equals: 0! !

!DistributionTest methodsFor: 'the normal distribution'!
testErf
	self assert: (Distribution erf: 1.0) closeTo: 0.8427007929497149 within: 1.0e-12.
	self assert: (Distribution erf: 0.0) closeTo: 0.0 within: 1.0e-15.
	self assert: (Distribution erf: -1.0) closeTo: -0.8427007929497149 within: 1.0e-12!
testNormalCDF
	self assert: (Distribution normalCDF: 0.0) closeTo: 0.5 within: 1.0e-14.
	self assert: (Distribution normalCDF: 1.96) closeTo: 0.9750021048517795 within: 1.0e-12.
	self assert: (Distribution normalCDF: -1.0) closeTo: 0.15865525393145707 within: 1.0e-12!
testNormalIsSymmetric
	self assert: ((Distribution normalCDF: 1.3) + (Distribution normalCDF: -1.3))
		closeTo: 1.0 within: 1.0e-14!
testNormalQuantile
	self assert: (Distribution normalQuantile: 0.975) closeTo: 1.959963984540054 within: 1.0e-9.
	self assert: (Distribution normalQuantile: 0.5) closeTo: 0.0 within: 1.0e-9.
	self assert: (Distribution normalQuantile: 0.05) closeTo: -1.6448536269514729 within: 1.0e-9!
testQuantileUndoesTheCDF
	#(0.01 0.25 0.5 0.9 0.999) do: [:p |
		self assert: (Distribution normalCDF: (Distribution normalQuantile: p)) closeTo: p within: 1.0e-10]!
testQuantileWantsAProperProbability
	self should: [Distribution normalQuantile: 0] raise: StatsError.
	self should: [Distribution normalQuantile: 1] raise: StatsError! !

!DistributionTest methodsFor: 'the other distributions'!
testIncompleteBeta
	self assert: (Distribution incompleteBeta: 0.5 a: 2 b: 3) closeTo: 0.6875 within: 1.0e-12.
	self assert: (Distribution incompleteBeta: 0.0 a: 2 b: 3) equals: 0.0.
	self assert: (Distribution incompleteBeta: 1.0 a: 2 b: 3) equals: 1.0!
testTDistribution
	self assert: (Distribution tCDF: 0.0 df: 10) closeTo: 0.5 within: 1.0e-14.
	self assert: (Distribution tCDF: 2.0 df: 10) closeTo: 0.9633059826146299 within: 1.0e-10.
	self assert: (Distribution tTwoTail: 2.2281388519649385 df: 10) closeTo: 0.05 within: 1.0e-9!
testTQuantile
	self assert: (Distribution tQuantile: 0.975 df: 10) closeTo: 2.2281388519649385 within: 1.0e-8.
	self assert: (Distribution tQuantile: 0.975 df: 1) closeTo: 12.706204736432095 within: 1.0e-6!
testTApproachesTheNormal
	self assert: (Distribution tCDF: 1.96 df: 1000000) closeTo: (Distribution normalCDF: 1.96) within: 1.0e-5!
testChiSquare
	self assert: (Distribution chiSquareTail: 3.841458820694124 df: 1) closeTo: 0.05 within: 1.0e-9.
	self assert: (Distribution chiSquareQuantile: 0.95 df: 3) closeTo: 7.814727903251179 within: 1.0e-8.
	self assert: (Distribution chiSquareCDF: 0.0 df: 3) equals: 0.0!
testF
	self assert: (Distribution fQuantile: 0.95 df1: 3 df2: 12) closeTo: 3.4902948195 within: 1.0e-7.
	self assert: (Distribution fTail: 3.4902948195 df1: 3 df2: 12) closeTo: 0.05 within: 1.0e-8.
	self assert: (Distribution fCDF: 0.0 df1: 3 df2: 12) equals: 0.0! !

"---- descriptive statistics ----"

!StatisticsTest methodsFor: 'helpers'!
sample
	^#(5.1 4.9 6.2 5.8 5.5 5.3 6.0 5.7)!
other
	^#(6.3 6.8 7.1 6.5 6.9 7.4 6.2 7.0)! !

!StatisticsTest methodsFor: 'the middle'!
testMean
	self assert: #(1 2 3 4) mean closeTo: 2.5.
	self assert: self sample mean closeTo: 5.5625!
testMedian
	self assert: #(1 2 3) median equals: 2.
	self assert: #(1 2 3 4) median closeTo: 2.5.
	self assert: self sample median closeTo: 5.6!
testMode
	self assert: #(1 2 2 3) mode equals: 2.
	self assert: #(1 1 2 2) mode equals: 1!
testGeometricAndHarmonicMeans
	self assert: #(1 4 16) geometricMean closeTo: 4.0.
	self assert: #(1 2 4) harmonicMean closeTo: 12.0 / 7!
testTrimmedMean
	self assert: (#(1 2 3 4 100) trimmedMean: 0.2) closeTo: 3.0!
testNilsAreLeftOut
	self assert: (Array with: 1 with: nil with: 3) mean closeTo: 2.0!
testAMeanOfNothing
	self should: [#() mean] raise: StatsError! !

!StatisticsTest methodsFor: 'spread'!
testVariance
	self assert: #(2 4 4 4 5 5 7 9) variance closeTo: 4.571428571428571.
	self assert: #(2 4 4 4 5 5 7 9) populationVariance closeTo: 4.0!
testStandardDeviation
	self assert: #(2 4 4 4 5 5 7 9) populationStandardDeviation closeTo: 2.0.
	self assert: self sample standardDeviation closeTo: 0.447013901988997!
testStandardError
	self assert: self sample standardError closeTo: 0.15804929529368938!
testRangeAndIQR
	self assert: #(1 5 9) range equals: 8.
	self assert: #(1 2 3 4 5 6 7 8) interquartileRange closeTo: 3.5!
testMedianAbsoluteDeviation
	self assert: #(1 2 3 4 100) medianAbsoluteDeviation equals: 1!
testCoefficientOfVariation
	self assert: #(2 4 4 4 5 5 7 9) coefficientOfVariation closeTo: 4.571428571428571 sqrt / 5.0!
testVarianceNeedsTwo
	self should: [#(1) variance] raise: StatsError! !

!StatisticsTest methodsFor: 'order'!
testQuantiles
	"the linear interpolation R calls type 7"
	self assert: (self sample quantile: 0.25) closeTo: 5.25.
	self assert: (self sample quantile: 0.75) closeTo: 5.85.
	self assert: (self sample quantile: 0.0) closeTo: 4.9.
	self assert: (self sample quantile: 1.0) closeTo: 6.2!
testPercentile
	self assert: (#(1 2 3 4 5) percentile: 50) closeTo: 3.0!
testFiveNumberSummary
	self assert: self sample fiveNumberSummary equals: #(4.9 5.25 5.6 5.85 6.2)!
testQuantileOfOneValue
	self assert: (#(7) quantile: 0.3) equals: 7!
testBadQuantile
	self should: [#(1 2 3) quantile: 1.5] raise: StatsError!
testRanks
	self assert: #(10 20 30) ranks equals: #(1.0 2.0 3.0).
	self assert: #(30 10 20) ranks equals: #(3.0 1.0 2.0).
	self assert: #(10 20 20 30) ranks equals: #(1.0 2.5 2.5 4.0)!
testTieCorrection
	self assert: (Statistics tieCorrection: #(1 2 3)) equals: 0.
	self assert: (Statistics tieCorrection: #(1 1 2)) equals: 6!
testOutliers
	self assert: (#(1 2 3 4 5 100) outliers) equals: #(100)! !

!StatisticsTest methodsFor: 'shape and pairs'!
testSkewness
	self assert: self sample skewness closeTo: -0.10495622143219926 within: 1.0e-12!
testKurtosis
	self assert: self sample kurtosis closeTo: -1.048845316217326 within: 1.0e-10!
testZScores
	| z |
	z := #(2 4 4 4 5 5 7 9) zScores.
	self assert: z mean closeTo: 0.0 within: 1.0e-12.
	self assert: z standardDeviation closeTo: 1.0 within: 1.0e-12!
testNormalized
	self assert: #(10 20 30) normalized equals: #(0.0 0.5 1.0)!
testCovariance
	self assert: (#(1 2 3) covarianceWith: #(2 4 6)) closeTo: 2.0!
testCorrelation
	self assert: (#(1 2 3) correlationWith: #(2 4 6)) closeTo: 1.0.
	self assert: (#(1 2 3) correlationWith: #(6 4 2)) closeTo: -1.0.
	self assert: (self sample correlationWith: self other) closeTo: -0.036740038512353246 within: 1.0e-12!
testSpearmanIgnoresTheShape
	self assert: (#(1 2 3 4) spearmanWith: #(1 4 9 16)) closeTo: 1.0!
testCorrelationWantsBothSidesToVary
	self should: [#(1 1 1) correlationWith: #(1 2 3)] raise: StatsError!
testSummary
	self assert: (self sample statisticsSummary includesSubstring: 'median')! !

"---- the tests themselves ----"

!InferenceTest methodsFor: 'helpers'!
a
	^#(5.1 4.9 6.2 5.8 5.5 5.3 6.0 5.7)!
b
	^#(6.3 6.8 7.1 6.5 6.9 7.4 6.2 7.0)! !

!InferenceTest methodsFor: 'the t test'!
testOneSample
	| t |
	t := TTest of: self a against: 5.0.
	self assert: t statistic closeTo: 3.5591516294920362 within: 1.0e-12.
	self assert: t degreesOfFreedom equals: 7.
	self assert: t p closeTo: 0.009229914920208025 within: 1.0e-12.
	self assert: t isSignificant!
testWelch
	| t |
	t := TTest of: self a and: self b.
	self assert: t statistic closeTo: -5.6339333346497025 within: 1.0e-9.
	self assert: t degreesOfFreedom closeTo: 13.914139117500277 within: 1.0e-9.
	self assert: t p < 0.001.
	self assert: t meanDifference closeTo: -1.2125!
testPooled
	| t |
	t := TTest pooledOf: self a and: self b.
	"the two samples are the same size and much the same spread, so pooled and Welch agree on t"
	self assert: t statistic closeTo: -5.6339333346497025 within: 1.0e-9.
	self assert: t degreesOfFreedom equals: 14!
testPaired
	| t |
	t := TTest pairedOf: self a and: self b.
	self assert: t degreesOfFreedom equals: 7.
	self assert: t meanDifference closeTo: -1.2125.
	self assert: t p < 0.01!
testPairedWantsTheSameNumberOfValues
	self should: [(TTest pairedOf: #(1 2 3) and: #(1 2)) run] raise: StatsError!
testNoDifference
	| t |
	t := TTest of: #(1 2 3 4 5) and: #(1 2 3 4 5).
	self assert: t statistic closeTo: 0.0.
	self assert: t p closeTo: 1.0.
	self deny: t isSignificant!
testConfidenceInterval
	| t ci |
	t := TTest of: self a against: 5.0.
	ci := t confidenceInterval.
	self assert: ci first closeTo: 0.18878 within: 0.0001.
	self assert: ci last closeTo: 0.93622 within: 0.0001!
testTTestWantsSomethingToWorkOn
	self should: [(TTest of: #(1) against: 0) run] raise: StatsError.
	self should: [(TTest of: #(2 2 2) against: 0) run] raise: StatsError!
testTheReportSaysWhatItFound
	| text |
	text := (TTest of: self a and: self b) report.
	self assert: (text includesSubstring: 'Welch').
	self assert: (text includesSubstring: 'p')! !

!InferenceTest methodsFor: 'chi-square'!
testGoodnessOfFit
	"a textbook die: 60 throws, expected ten of each"
	| c |
	c := ChiSquareTest goodnessOf: #(5 8 9 8 10 20).
	self assert: c statistic closeTo: 13.4 within: 1.0e-9.
	self assert: c degreesOfFreedom equals: 5.
	self assert: c p closeTo: 0.019905220334774376 within: 1.0e-12!
testGoodnessAgainstGivenExpectations
	| c |
	c := ChiSquareTest goodnessOf: #(30 20) against: #(25 25).
	self assert: c statistic closeTo: 2.0.
	self assert: c degreesOfFreedom equals: 1!
testIndependence
	| c |
	c := ChiSquareTest independenceOf: (Array with: #(20 30) with: #(30 20)).
	self assert: c statistic closeTo: 4.0 within: 1.0e-9.
	self assert: c degreesOfFreedom equals: 1.
	self assert: c p closeTo: 0.04550026389635833 within: 1.0e-12!
testIndependenceOfABiggerTable
	| c |
	c := ChiSquareTest independenceOf: (Array with: #(10 20 30) with: #(30 20 10)).
	self assert: c degreesOfFreedom equals: 2.
	self assert: c statistic > 0!
testExpectedCounts
	| c |
	c := ChiSquareTest independenceOf: (Array with: #(20 30) with: #(30 20)).
	self assert: c smallestExpected closeTo: 25.0!
testAPerfectFit
	| c |
	c := ChiSquareTest goodnessOf: #(10 10 10).
	self assert: c statistic closeTo: 0.0.
	self assert: c p closeTo: 1.0!
testBadChiSquare
	self should: [(ChiSquareTest goodnessOf: #(1 2) against: #(1 2 3)) run] raise: StatsError.
	self should: [(ChiSquareTest goodnessOf: #(5)) run] raise: StatsError.
	self should: [(ChiSquareTest independenceOf: (Array with: #(1 2))) run] raise: StatsError! !

!InferenceTest methodsFor: 'the rank tests'!
testMannWhitney
	| m |
	m := MannWhitneyTest of: self a and: self b.
	self assert: m u closeTo: 0.5 within: 1.0e-9.
	self assert: (m u1 + m u2) closeTo: 64.0.
	self assert: m p < 0.01.
	self assert: m isSignificant!
testMannWhitneyOnSamplesThatOverlapCompletely
	| m |
	m := MannWhitneyTest of: #(1 2 3 4 5) and: #(1 2 3 4 5).
	self assert: m u closeTo: 12.5 within: 1.0e-9.
	self deny: m isSignificant!
testMannWhitneyHandlesTies
	| m |
	m := MannWhitneyTest of: #(1 1 1 2) and: #(1 1 2 2).
	self assert: m p <= 1.0.
	self assert: m p >= 0.0!
testWilcoxon
	| w |
	w := WilcoxonSignedRankTest of: self a and: self b.
	self assert: w w closeTo: 0.0.
	self assert: w usedPairs equals: 8.
	self assert: w p < 0.05!
testWilcoxonDropsThePairsThatAreTheSame
	| w |
	w := WilcoxonSignedRankTest of: #(1 2 3 4) and: #(1 2 5 7).
	self assert: w usedPairs equals: 2!
testWilcoxonWithNothingToSay
	self should: [(WilcoxonSignedRankTest of: #(1 2 3) and: #(1 2 3)) run] raise: StatsError! !

!InferenceTest methodsFor: 'correlation and variance'!
testCorrelationTest
	| c |
	c := CorrelationTest of: #(1 2 3 4 5 6 7 8) and: #(2 4 5 4 5 7 8 9).
	self assert: c r closeTo: 0.9511897312113419 within: 1.0e-12.
	self assert: c statistic closeTo: 7.54983443527075 within: 1.0e-10.
	self assert: c degreesOfFreedom equals: 6.
	self assert: c p closeTo: 0.0002801804615488687 within: 1.0e-12!
testAPerfectCorrelation
	| c |
	c := CorrelationTest of: #(1 2 3 4) and: #(2 4 6 8).
	self assert: c r closeTo: 1.0.
	self assert: c p closeTo: 0.0 within: 1.0e-9!
testSpearmanTest
	| c |
	c := CorrelationTest spearmanOf: #(1 2 3 4 5) and: #(1 4 9 16 25).
	self assert: c r closeTo: 1.0!
testAnova
	"three groups of four, from a worked example"
	| f |
	f := AnovaTest of: (Array with: #(6 8 4 5) with: #(8 12 9 11) with: #(13 9 11 8)).
	self assert: f degreesOfFreedom equals: 2.
	self assert: f betweenSS closeTo: 51.16666666666667 within: 1.0e-10.
	self assert: f withinSS closeTo: 33.5 within: 1.0e-10.
	self assert: f statistic closeTo: 6.873134328358209 within: 1.0e-10.
	self assert: f p closeTo: 0.01541684667047416 within: 1.0e-10!
testAnovaWantsTwoGroups
	self should: [(AnovaTest of: (Array with: #(1 2 3))) run] raise: StatsError!
testEtaSquared
	| f |
	f := AnovaTest of: (Array with: #(1 1 1) with: #(5 5 5)).
	self assert: f etaSquared closeTo: 1.0! !

!InferenceTest methodsFor: 'regression'!
testALineThroughPointsOnALine
	| r |
	r := LinearRegression of: #(1 2 3 4) and: #(3 5 7 9).
	self assert: r slope closeTo: 2.0.
	self assert: r intercept closeTo: 1.0.
	self assert: r rSquared closeTo: 1.0!
testARealFit
	| r |
	r := LinearRegression of: #(1 2 3 4 5) and: #(2.1 4.2 5.8 8.1 9.9).
	self assert: r slope closeTo: 1.95 within: 1.0e-9.
	self assert: r intercept closeTo: 0.17 within: 1.0e-9.
	self assert: r rSquared closeTo: 0.9978219796368216 within: 1.0e-12.
	self assert: r pForSlope < 0.001!
testPrediction
	| r |
	r := LinearRegression of: #(1 2 3 4) and: #(3 5 7 9).
	self assert: (r valueAt: 10) closeTo: 21.0.
	self assert: (r predict: #(0 1)) equals: #(1.0 3.0)!
testResiduals
	| r |
	r := LinearRegression of: #(1 2 3 4) and: #(3 5 7 9).
	r residuals do: [:each | self assert: each abs < 1.0e-9]!
testTheSlopeHasAnInterval
	| r ci |
	r := LinearRegression of: #(1 2 3 4 5) and: #(2.1 4.2 5.8 8.1 9.9).
	ci := r confidenceIntervalForSlope.
	self assert: ci first < r slope.
	self assert: ci last > r slope!
testRegressionWantsThreePoints
	self should: [LinearRegression of: #(1 2) and: #(3 4)] raise: StatsError!
testRegressionWantsTheXToVary
	self should: [LinearRegression of: #(2 2 2) and: #(3 4 5)] raise: StatsError!
testTheEquationReads
	self assert: ((LinearRegression of: #(1 2 3 4) and: #(3 5 7 9)) equation includesSubstring: 'y =')! !

"---- tables, CSV and plots ----"

!DataTableTest methodsFor: 'helpers'!
small
	^DataTable columns: #('name' 'age' 'town')
		rows: (Array
			with: #('Ada' 36 'London')
			with: #('Grace' 45 'New York')
			with: #('Alan' 41 'London'))!
copyForTest
	"a table of its own to change, since addRow: and addColumn: work in place"
	^DataTable columns: self small columnNames
		rows: (self small rowArrays collect: [:each | each copy])! !

!DataTableTest methodsFor: 'the table'!
testShape
	self assert: self small rowCount equals: 3.
	self assert: self small columnCount equals: 3.
	self assert: self small columnNames equals: #('name' 'age' 'town').
	self assert: self small printString equals: 'a DataTable(3 x 3)'!
testRowsAndCells
	self assert: ((self small rowAt: 1) at: 'name') equals: 'Ada'.
	self assert: (self small at: 2 and: 'age') equals: 45.
	self assert: ((self small rowAt: 3) atIndex: 3) equals: 'London'!
testAMissingColumn
	self should: [self small column: 'height'] raise: StatsError.
	self should: [(self small rowAt: 1) at: 'height'] raise: StatsError.
	self deny: (self small includesColumn: 'height')!
testColumn
	self assert: (self small column: 'age') equals: #(36 45 41).
	self assert: (self small numbersIn: 'age') equals: #(36 45 41)!
testShortRowsAreFilledOut
	| t |
	t := DataTable columns: #('a' 'b' 'c') rows: (Array with: #(1 2)).
	self assert: ((t rowAt: 1) at: 'c') isNil!
testSelect
	| t |
	t := self small select: [:row | (row at: 'town') = 'London'].
	self assert: t rowCount equals: 2.
	self assert: (t column: 'name') equals: #('Ada' 'Alan')!
testWhere
	self assert: (self small where: 'town' is: 'London') rowCount equals: 2.
	self assert: (self small where: 'age' isAbove: 40) rowCount equals: 2.
	self assert: (self small where: 'age' isBelow: 40) rowCount equals: 1!
testCollectAndCount
	self assert: (self small collect: [:row | row at: 'age']) asArray equals: #(36 45 41).
	self assert: (self small count: [:row | (row at: 'age') > 40]) equals: 2.
	self assert: (self small anySatisfy: [:row | (row at: 'name') = 'Ada'])!
testDetect
	self assert: ((self small detect: [:row | (row at: 'age') > 40]) at: 'name') equals: 'Grace'.
	self assert: (self small detect: [:row | false] ifNone: ['none']) equals: 'none'!
testSort
	self assert: ((self small sortBy: 'age') column: 'name') equals: #('Ada' 'Alan' 'Grace').
	self assert: ((self small sortBy: 'age' descending: true) column: 'name') equals: #('Grace' 'Alan' 'Ada').
	self assert: ((self small sortBy: 'name') column: 'name') equals: #('Ada' 'Alan' 'Grace')!
testHeadAndTail
	self assert: (self small head: 2) rowCount equals: 2.
	self assert: (self small tail: 1) rowCount equals: 1.
	self assert: ((self small tail: 1) at: 1 and: 'name') equals: 'Alan'.
	self assert: (self small head: 99) rowCount equals: 3!
testColumnsIn
	self assert: (self small withColumns: #('name' 'age')) columnNames equals: #('name' 'age').
	self assert: (self small withoutColumn: 'town') columnCount equals: 2.
	self assert: (self small renameColumn: 'town' to: 'city') columnNames equals: #('name' 'age' 'city')!
testAddColumn
	| t |
	t := self copyForTest.
	t addColumn: 'decade' computedBy: [:row | (row at: 'age') // 10].
	self assert: (t column: 'decade') equals: #(3 4 4)!
testAddRow
	| t |
	t := self copyForTest.
	t addRow: #('Edsger' 50 'Austin').
	self assert: t rowCount equals: 4.
	self assert: (t at: 4 and: 'name') equals: 'Edsger'!
testConvertColumn
	self assert: ((self small convertColumn: 'age' using: [:v | v * 2]) column: 'age') equals: #(72 90 82)!
testReversed
	self assert: (self small reversed column: 'name') equals: #('Alan' 'Grace' 'Ada')! !

!DataTableTest methodsFor: 'grouping and joining'!
testDistinctAndCount
	self assert: (self small distinctValuesOf: 'town') equals: #('London' 'New York').
	self assert: ((self small countBy: 'town') at: 'London') equals: 2!
testGroupBy
	| g |
	g := self small groupBy: 'town'.
	self assert: g size equals: 2.
	self assert: (g at: 'London') rowCount equals: 2!
testAggregate
	| t |
	t := self small meanBy: 'town' of: 'age'.
	self assert: t rowCount equals: 2.
	self assert: (t at: 1 and: 'age') closeTo: 38.5!
testCountsBy
	| t |
	t := self small countsBy: 'town'.
	self assert: t columnNames equals: #('town' 'count').
	self assert: (t at: 1 and: 'count') equals: 2!
testJoin
	| other joined |
	other := DataTable columns: #('town' 'country') rows: (Array with: #('London' 'UK') with: #('New York' 'US')).
	joined := self small join: other on: 'town'.
	self assert: joined columnNames equals: #('name' 'age' 'town' 'country').
	self assert: joined rowCount equals: 3.
	self assert: (joined at: 1 and: 'country') equals: 'UK'!
testLeftJoinKeepsTheUnmatched
	| other joined |
	other := DataTable columns: #('town' 'country') rows: (Array with: #('London' 'UK')).
	joined := self small leftJoin: other on: 'town'.
	self assert: joined rowCount equals: 3.
	self assert: (joined at: 2 and: 'country') isNil!
testInnerJoinDropsTheUnmatched
	| other |
	other := DataTable columns: #('town' 'country') rows: (Array with: #('London' 'UK')).
	self assert: (self small join: other on: 'town') rowCount equals: 2!
testJoinWantsTheColumnOnBothSides
	| other |
	other := DataTable columns: #('place') rows: #().
	self should: [self small join: other on: 'town'] raise: StatsError!
testConcatenate
	self assert: (self small , self small) rowCount equals: 6.
	self should: [self small , (DataTable columns: #('x') rows: #())] raise: StatsError! !

!DataTableTest methodsFor: 'CSV'!
testReadCSV
	| t |
	t := DataTable fromCSV: 'a,b,c
1,2,hello
3,4,world'.
	self assert: t columnNames equals: #('a' 'b' 'c').
	self assert: t rowCount equals: 2.
	self assert: (t column: 'a') equals: #(1 3).
	self assert: (t at: 1 and: 'c') equals: 'hello'!
testTypesAreWorkedOut
	| t |
	t := DataTable fromCSV: 'i,f,s,e
1,2.5,abc,'.
	self assert: (t at: 1 and: 'i') equals: 1.
	self assert: (t at: 1 and: 'f') closeTo: 2.5.
	self assert: (t at: 1 and: 's') equals: 'abc'.
	self assert: (t at: 1 and: 'e') isNil!
testQuotedFields
	| t |
	t := DataTable fromCSV: 'a,b
"one, two","he said ""hi"""'.
	self assert: (t at: 1 and: 'a') equals: 'one, two'.
	self assert: (t at: 1 and: 'b') equals: 'he said "hi"'!
testQuotedHeader
	| t |
	t := DataTable fromCSV: '"first name",age
Ada,36'.
	self assert: t columnNames equals: #('first name' 'age')!
testNoHeader
	| t |
	t := CSVReader new header: false; parse: '1,2
3,4'.
	self assert: t columnNames equals: #('column1' 'column2').
	self assert: t rowCount equals: 2!
testTabs
	| t |
	t := DataTable fromTSV: 'a	b
1	2'.
	self assert: t columnNames equals: #('a' 'b').
	self assert: (t at: 1 and: 'b') equals: 2!
testRoundTrip
	| back |
	back := DataTable fromCSV: self small asCSV.
	self assert: back columnNames equals: self small columnNames.
	self assert: back rowCount equals: self small rowCount.
	self assert: (back at: 2 and: 'town') equals: 'New York'!
testWritingQuotesWhatItMust
	| t text |
	t := DataTable columns: #('a') rows: (Array with: (Array with: 'one, two')).
	text := t asCSV.
	self assert: (text includesSubstring: '"one, two"')!
testNumberReading
	self assert: (CSVReader numberFrom: '42') equals: 42.
	self assert: (CSVReader numberFrom: '-2.5') closeTo: -2.5.
	self assert: (CSVReader numberFrom: '1e3') closeTo: 1000.0.
	self assert: (CSVReader numberFrom: 'abc') isNil.
	self assert: (CSVReader numberFrom: '1.2.3') isNil.
	self assert: (CSVReader numberFrom: '') isNil!
testEmptyLinesAreSkipped
	self assert: (DataTable fromCSV: 'a,b
1,2

3,4
') rowCount equals: 2!
testMissingFile
	self should: [DataTable readCSV: '/no/such/file.csv'] raise: StatsError! !

!DataTableTest methodsFor: 'statistics on a table'!
testColumnStatistics
	self assert: (self small meanOf: 'age') closeTo: 40.666666666666664 within: 1.0e-9.
	self assert: (self small medianOf: 'age') equals: 41.
	self assert: (self small sumOf: 'age') equals: 122.
	self assert: (self small minimumOf: 'age') equals: 36.
	self assert: (self small maximumOf: 'age') equals: 45!
testNumericColumns
	self assert: self small numericColumnNames equals: #('age').
	self assert: (self small isNumericColumn: 'age').
	self deny: (self small isNumericColumn: 'name')!
testDescribe
	self assert: ((self small describe: 'age') includesSubstring: 'median').
	self assert: ((self small describe: 'name') includesSubstring: 'distinct').
	self assert: (self small describe includesSubstring: 'rows')!
testAsText
	| text |
	text := self small asText.
	self assert: (text includesSubstring: 'Ada').
	self assert: (text includesSubstring: 'name')! !

!DataTableTest methodsFor: 'the example data'!
testTheExampleFilesAreThere
	self assert: (FileStream exists: (Stats exampleFile: 'plants.csv')).
	self assert: (FileStream exists: (Stats exampleFile: 'weather.csv'))!
testThePlants
	| t |
	t := Stats examplePlants.
	self assert: t rowCount equals: 120.
	self assert: t columnNames equals: #('id' 'variety' 'height' 'width' 'weight' 'leaves').
	self assert: (t distinctValuesOf: 'variety') asSortedCollection asArray equals: #('alpha' 'beta' 'gamma').
	self assert: ((t countBy: 'variety') at: 'alpha') equals: 40!
testThePlantsWereMadeWithAStrongCorrelation
	self assert: (Stats examplePlants correlationBetween: 'height' and: 'weight') > 0.9!
testTheVarietiesReallyDoDiffer
	| f |
	f := Stats examplePlants anovaOf: 'height' by: 'variety'.
	self assert: f p < 0.001.
	self assert: f degreesOfFreedom equals: 2!
testTheRegressionFindsTheLineTheDataWasMadeOn
	"weight was made as about two parts height and a bit, so the slope should be near two"
	| r |
	r := Stats examplePlants regressionOf: 'weight' on: 'height'.
	self assert: (r slope between: 1.8 and: 2.4).
	self assert: r rSquared > 0.85.
	self assert: r pForSlope < 0.001!
testTheWeatherFileHasHolesAndQuotesInIt
	| w |
	w := Stats exampleWeather.
	self assert: w rowCount equals: 48.
	self assert: (w includesColumn: 'temperature, C').
	self assert: (w numbersIn: 'temperature, C') size < 48.
	self assert: (w distinctValuesOf: 'town') size equals: 4! !

!DataTableTest methodsFor: 'plots'!
testHistogram
	| text |
	text := TextPlot histogram: #(1 2 2 3 3 3 4 4 5) bins: 5.
	self assert: (text includesSubstring: '#').
	self assert: (text includesSubstring: 'n = 9')!
testHistogramOfOneValue
	self assert: ((TextPlot histogram: #(5 5 5)) includesSubstring: 'all 3 values are 5')!
testHistogramOfNothing
	self assert: ((TextPlot histogram: #()) includesSubstring: 'nothing to plot')!
testBoxPlot
	| text |
	text := TextPlot boxPlot: #(1 2 3 4 5 6 7 8 100).
	self assert: (text includesSubstring: 'median').
	self assert: (text includesSubstring: 'outliers')!
testBars
	| text |
	text := TextPlot bars: (self small countBy: 'town').
	self assert: (text includesSubstring: 'London').
	self assert: (text includesSubstring: '#')!
testScatter
	| text |
	text := TextPlot scatter: #(1 2 3 4 5) and: #(2 4 6 8 10).
	self assert: (text includesSubstring: '*')!
testSparkline
	self assert: (TextPlot sparkline: #(1 2 3 4 5)) size equals: 5.
	self assert: (TextPlot sparkline: #()) equals: ''.
	self assert: ((TextPlot sparkline: #(1 2 3)) last) equals: $@!
testDistributionPlot
	self assert: ((TextPlot distribution: #(1 2 3 4 5 6 7 8)) includesSubstring: 'median')! !

!DataTableTest methodsFor: 'the facade and the browser'!
testFacade
	self assert: Stats version equals: '1.0'.
	self assert: Stats examples size equals: 2.
	self assert: Stats tests size >= 10.
	self assert: (Stats mean: #(1 2 3)) closeTo: 2.0.
	self assert: (Stats csv: 'a,b
1,2') rowCount equals: 1.
	self assert: (Stats tTestOf: #(1 2 3 4) and: #(1 2 3 4)) p closeTo: 1.0.
	self assert: ((Stats regressionOf: #(2 4 6) on: #(1 2 3)) slope) closeTo: 2.0!
testBrowser
	TableBrowser openOn: self small.
	self assert: TableBrowser listItems size equals: 4.
	self assert: TableBrowser listItems first equals: '* the whole table'.
	self assert: ((TableBrowser detailAt: 1) includesSubstring: 'Ada').
	self assert: ((TableBrowser detailAt: 2) includesSubstring: 'Ada')!
testBrowserCommands
	TableBrowser openOn: self small.
	TableBrowser command: 2 at: 3.
	self assert: ((TableBrowser detailAt: 3) includesSubstring: 'median').
	TableBrowser command: 5 at: 1.
	self assert: ((TableBrowser detailAt: 1) includesSubstring: 'number').
	TableBrowser command: 9 at: 3.
	self assert: (TableBrowser table at: 1 and: 'name') equals: 'Ada'.
	TableBrowser command: 1 at: 1!
testBrowserNeedsAColumnToSortBy
	TableBrowser openOn: self small.
	self assert: (TableBrowser command: 9 at: 1) equals: 'select a column first'! !
