"The Stats tutorial: statistics on collections, CSV and DataTable, grouping and joining, plots, and the
hypothesis tests with what their p-values do and do not mean.  Start it with   StatsTutorial go"

AbstractTutorial subclass: #StatsTutorial instanceVariableNames: '' classVariableNames: '' category: 'Stats'!

!StatsTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Stats'!
lessonSelectors
	^#(#welcome #onACollection #spreadAndQuantiles #readingACsv #queryingATable
		#groupingAndJoining #describing #plots #whatAPValueIs #theTTest #chiSquare
		#rankTests #analysisOfVariance #regression #theDistributions #theBrowser #whatNext)! !

!StatsTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'This package does two related things: it gives you a table you can query, and
it does statistics on what is in it.

Everything here is live.  Select a line and press ctrl-P (print it) to run it.

The statistics work on any collection of numbers:

#(2 4 4 4 5 5 7 9) mean
#(2 4 4 4 5 5 7 9) standardDeviation
#(2 4 4 4 5 5 7 9) median

A table read from a CSV file, queried and summarised:

Stats examplePlants
Stats examplePlants summary
(Stats examplePlants where: ''variety'' is: ''beta'') rowCount
Stats examplePlants meanBy: ''variety'' of: ''height''

And a question answered with a p-value:

(Stats examplePlants anovaOf: ''height'' by: ''variety'') report

The example data is simulated, and it was made with a real difference between
the varieties and a real relation between height and weight, so you can check
that the methods find what was put there.  Here is what comes with it:

Stats examples'!
onACollection
	^TutorialLesson title: 'Statistics on a collection' text:
'The work is in a class called Statistics, and the Collection methods forward
to it, so the short form reads the way it should:

#(1 2 3 4) mean
#(1 2 3) median
#(1 2 3 4) median
#(1 2 2 3) mode

Three other middles, each right for a different kind of data.  A geometric
mean for things that multiply, such as growth rates; a harmonic mean for
rates; a trimmed mean when a few wild values should not count:

#(1 4 16) geometricMean
#(1 2 4) harmonicMean
#(1 2 3 4 100) mean
#(1 2 3 4 100) trimmedMean: 0.2
#(1 2 3 4 100) median

Look at those last three together.  One value of 100 drags the mean to 22; the
median and the trimmed mean barely notice.  That is the whole argument for
robust statistics in three lines.

A nil in a collection is left out rather than causing an error, because that
is what an empty field in a file becomes:

(Array with: 1 with: nil with: 3) mean

and asking for something impossible says so rather than answering nonsense:

[#() mean] on: StatsError do: [:e | e messageText]'!
spreadAndQuantiles
	^TutorialLesson title: 'Spread and quantiles' text:
'Variance and standard deviation come in two forms.  The plain name is the
SAMPLE form, dividing by n minus 1, which is what you want when your numbers
are a sample from something bigger -- almost always:

#(2 4 4 4 5 5 7 9) variance
#(2 4 4 4 5 5 7 9) populationVariance
#(2 4 4 4 5 5 7 9) standardDeviation
#(2 4 4 4 5 5 7 9) populationStandardDeviation

The standard error is the standard deviation of the MEAN, which is the one
that shrinks as you collect more data:

#(2 4 4 4 5 5 7 9) standardError

Quantiles use the linear interpolation between order statistics that R calls
type 7, so these numbers agree with other software:

#(1 2 3 4 5 6 7 8) quantile: 0.25
#(1 2 3 4 5 6 7 8) percentile: 90
#(1 2 3 4 5 6 7 8) fiveNumberSummary
#(1 2 3 4 5 6 7 8) interquartileRange

The robust spreads, which outliers do not move:

#(1 2 3 4 100) standardDeviation
#(1 2 3 4 100) interquartileRange
#(1 2 3 4 100) medianAbsoluteDeviation

And the rule a box plot draws its whiskers by, which is also a reasonable
definition of an outlier:

#(1 2 3 4 5 100) outliers

Shape, for when you want to know whether the data is lopsided or heavy-tailed.
Both are zero for a normal distribution:

#(1 2 3 4 5 6 7 8) skewness
#(1 2 3 4 5 6 7 8) kurtosis'!
readingACsv
	^TutorialLesson title: 'Reading a CSV file' text:
'CSV is how data arrives.  The reader handles what actually turns up in files:
quoted fields with commas inside them, doubled quotes, missing values, and
either line ending.

Stats readCSV: (Stats exampleFile: ''plants.csv'')
Stats examplePlants columnNames
Stats examplePlants rowCount

Fields are read as numbers where they look like numbers and as text where they
do not; an empty field becomes nil.  These two examples are several lines
long, so select the whole of one before printing it:

    Stats csv: ''a,b,c
    1,2.5,hello''

    (Stats csv: ''i,f,s,e
    1,2.5,abc,'') rowArrays first

The second example file is deliberately awkward -- a comma inside a quoted
column name, doubled quotes inside a field, and holes in a column:

Stats exampleWeather columnNames
Stats exampleWeather rowCount
(Stats exampleWeather numbersIn: ''temperature, C'') size

Forty-eight rows but fewer temperatures, because some are missing.  That is
the point of leaving nils alone: the column is still a column of numbers to
everything that follows.

Writing goes back out the same way, quoting whatever needs it:

    (Stats csv: ''a
    one, two'') asCSV

Stats examplePlants asTSV size

Tabs instead of commas, and a file with no header at all, are settings:

DataTable readTSV: (Stats exampleFile: ''plants.csv'')
CSVReader new header: false; parse: ''1,2''

    CSVReader new delimiter: $;; parse: ''a;b
    1;2'''!
queryingATable
	^TutorialLesson title: 'Querying a table' text:
'A DataTable has named columns and rows.  Iterating gives you TableRows, which
know their table, so a block can ask for a column by name:

| t | t := Stats examplePlants. t select: [:row | (row at: ''height'') > 28]
| t | t := Stats examplePlants. (t select: [:row | (row at: ''height'') > 28]) rowCount
| t | t := Stats examplePlants. t count: [:row | (row at: ''leaves'') > 9]
| t | t := Stats examplePlants. (t collect: [:row | row at: ''height'']) size

For the common cases there are shorter forms:

| t | t := Stats examplePlants. (t where: ''variety'' is: ''alpha'') rowCount
| t | t := Stats examplePlants. (t where: ''height'' isAbove: 28) rowCount
| t | t := Stats examplePlants. (t where: ''height'' isBelow: 18) rowCount

Sorting, taking the ends, and picking columns.  None of these changes the
table you started with; each answers a new one:

| t | t := Stats examplePlants. (t sortBy: ''height'') first at: ''height''
| t | t := Stats examplePlants. (t sortBy: ''height'' descending: true) first at: ''height''
| t | t := Stats examplePlants. (t head: 3) asText
| t | t := Stats examplePlants. (t withColumns: #(''variety'' ''height'')) asText
| t | t := Stats examplePlants. (t withoutColumn: ''id'') columnNames

Getting at single values:

| t | t := Stats examplePlants. t at: 1 and: ''variety''
| t | t := Stats examplePlants. (t rowAt: 1) at: ''height''
| t | t := Stats examplePlants. (t column: ''variety'') size
| t | t := Stats examplePlants. (t numbersIn: ''height'') size

and a column name that is not there says so rather than answering nil:

[Stats examplePlants column: ''nonesuch''] on: StatsError do: [:e | e messageText]'!
groupingAndJoining
	^TutorialLesson title: 'Grouping and joining' text:
'The question you usually have is not about the rows but about the groups.

| t | t := Stats examplePlants. t distinctValuesOf: ''variety''
| t | t := Stats examplePlants. t countBy: ''variety''
| t | t := Stats examplePlants. (t countsBy: ''variety'') asText
| t | t := Stats examplePlants. (t groupBy: ''variety'') size

An aggregate answers a two-column table, which you can go on working with:

| t | t := Stats examplePlants. (t meanBy: ''variety'' of: ''height'') asText
| t | t := Stats examplePlants. (t sumBy: ''variety'' of: ''weight'') asText

and when the aggregate you want is not one of those, hand it a block.  The
block is given the group''s column as an Array:

| t | t := Stats examplePlants. (t groupBy: ''variety'' aggregate: ''height'' with: [:v | v max]) asText
| t | t := Stats examplePlants. (t groupBy: ''variety'' aggregate: ''height'' with: [:v | v standardDeviation]) asText

Joining puts two tables together on a shared column.  An INNER join keeps only
the rows that match on both sides; a LEFT join keeps every row of the first
and puts nils where the second has nothing:

Each of these spans several lines, so select the whole of one and print it:

    | a b | a := Stats csv: ''k,v
    x,1
    y,2''. b := Stats csv: ''k,w
    x,9''. (a join: b on: ''k'') asText

    | a b | a := Stats csv: ''k,v
    x,1
    y,2''. b := Stats csv: ''k,w
    x,9''. (a leftJoin: b on: ''k'') asText

The first answers one row and the second two.  Which you want depends on
whether a row with nothing to match is a row you still care about.'!
describing
	^TutorialLesson title: 'Looking at a table' text:
'Before testing anything, look at it.  The summary is one line per column
saying what is in it:

Stats examplePlants summary
Stats exampleWeather summary

A single column in more detail, which is where you notice that something is
wrong:

Stats examplePlants describe: ''height''
Stats examplePlants describe: ''variety''

The whole table the same way, column by column:

Stats examplePlants describe

The rows themselves, lined up, with as many as you ask for:

(Stats examplePlants head: 5) asText
Stats examplePlants asTextLimitedTo: 3

and the statistics of a column directly, when you want the number rather than
the description:

Stats examplePlants meanOf: ''height''
Stats examplePlants medianOf: ''height''
Stats examplePlants standardDeviationOf: ''height''
Stats examplePlants minimumOf: ''height''
Stats examplePlants maximumOf: ''height''

Which columns are numbers at all is worth asking, since it decides what you
can do with them:

Stats examplePlants numericColumnNames
Stats examplePlants isNumericColumn: ''variety'''!
plots
	^TutorialLesson title: 'Plots' text:
'None of these is a picture.  They are what you draw when all you have is a
screen full of letters, and they are enough to see the shape of something,
which is usually all you wanted.

A histogram, with as many bins as you like:

Stats examplePlants histogramOf: ''height''
TextPlot histogram: (Stats examplePlants numbersIn: ''height'') bins: 20

A box plot, which shows the five-number summary on a line and marks the
outliers:

Stats examplePlants boxPlotOf: ''height''
TextPlot boxPlot: #(1 2 3 4 5 6 7 8 100)

Bars for a count of categories:

Stats examplePlants barsOf: ''variety''

A scatter plot, which puts a digit rather than a star where several points
fall in the same cell:

Stats examplePlants scatterOf: ''weight'' against: ''height''
TextPlot scatter: #(1 2 3 4 5) and: #(2 4 6 8 10)

A sparkline, for the shape of a series in one line:

TextPlot sparkline: #(1 3 2 5 4 7 6 9)
(Stats examplePlants numbersIn: ''leaves'') sparkline

And the three things you look at first, together:

TextPlot distribution: (Stats examplePlants numbersIn: ''height'')'!
whatAPValueIs
	^TutorialLesson title: 'What a p-value is' text:
'Before the tests, the thing they all answer.

A p-value is the probability of seeing a difference AT LEAST AS BIG as the one
you saw, IF nothing were going on.  That is all it is.

It is NOT the probability that there is no difference.  It is NOT the
probability that you are wrong.  It is NOT a measure of how big the difference
is -- a tiny difference measured often enough gives a tiny p.

Every test here is an object, and it answers its statistic, its degrees of
freedom and its p:

| t | t := TTest of: #(5.1 4.9 6.2 5.8) and: #(6.3 6.8 7.1 6.5). t statistic
| t | t := TTest of: #(5.1 4.9 6.2 5.8) and: #(6.3 6.8 7.1 6.5). t degreesOfFreedom
| t | t := TTest of: #(5.1 4.9 6.2 5.8) and: #(6.3 6.8 7.1 6.5). t p
| t | t := TTest of: #(5.1 4.9 6.2 5.8) and: #(6.3 6.8 7.1 6.5). t report

isSignificant answers whether p is below the level the test holds, and that is
the whole of its meaning.  The level is yours to set:

| t | t := TTest of: #(5.1 4.9 6.2 5.8) and: #(6.3 6.8 7.1 6.5). t isSignificant
| t | t := TTest of: #(5.1 4.9 6.2 5.8) and: #(6.3 6.8 7.1 6.5). t level: 0.001. t isSignificant
| t | t := TTest of: #(5.1 4.9 6.2 5.8) and: #(6.3 6.8 7.1 6.5). t verdict

Which test to use is a question about your data, not about the answer you
want, and choosing after seeing the p-values is how people fool themselves.
The lessons that follow say what each one assumes.

The tests this package knows, and the question each one asks:

Stats tests'!
theTTest
	^TutorialLesson title: 'The t test' text:
'The t test asks whether two means differ by more than the scatter in the data
would explain.  It comes in four forms and the difference between them
matters.

TWO SAMPLES, when you have two separate groups.  The default is Welch''s
version, which does not assume the two groups have the same spread; it is the
safer one and what most software now uses:

TTest of: #(5.1 4.9 6.2 5.8 5.5) and: #(6.3 6.8 7.1 6.5 6.9)
(TTest of: #(5.1 4.9 6.2 5.8 5.5) and: #(6.3 6.8 7.1 6.5 6.9)) report

POOLED, the classic version, which does assume equal spreads.  Note the
degrees of freedom: a whole number here, and usually not one for Welch:

(TTest pooledOf: #(5.1 4.9 6.2 5.8 5.5) and: #(6.3 6.8 7.1 6.5 6.9)) degreesOfFreedom
(TTest of: #(5.1 4.9 6.2 5.8 5.5) and: #(6.3 6.8 7.1 6.5 6.9)) degreesOfFreedom

PAIRED, when the two columns are the same things measured twice.  It tests the
DIFFERENCES, which is a much more powerful thing to do when the pairing is
real -- and quite wrong when it is not:

(TTest pairedOf: #(5.1 4.9 6.2 5.8) and: #(6.3 6.8 7.1 6.5)) report

ONE SAMPLE, against a number you have in mind:

(TTest of: #(5.1 4.9 6.2 5.8) against: 5.0) report

The confidence interval is often more use than the p-value, because it says
how big the difference might be rather than only that it is there:

(TTest of: #(5.1 4.9 6.2 5.8) against: 5.0) confidenceInterval

On a table, split a column by a two-valued grouping column:

| w | w := Stats exampleWeather select: [:r | (r at: ''town'') = ''Bath'' or: [(r at: ''town'') = ''Hay-on-Wye'']]. (w tTestOf: ''rainfall'' by: ''town'') report'!
chiSquare
	^TutorialLesson title: 'Chi-square' text:
'Chi-square is for COUNTS rather than measurements, and it comes in two forms.

GOODNESS OF FIT asks whether a set of counts matches what you expected.  With
no expectation given, it assumes every category is equally likely -- a fair
die, say, thrown sixty times:

(ChiSquareTest goodnessOf: #(5 8 9 8 10 20)) report

Twenty sixes in sixty throws is a lot, and the p-value says so.  Against an
expectation of your own:

(ChiSquareTest goodnessOf: #(30 20) against: #(25 25)) report

INDEPENDENCE asks whether the rows and columns of a table are related.  Give
it a collection of rows:

(ChiSquareTest independenceOf: (Array with: #(20 30) with: #(30 20))) report
(ChiSquareTest independenceOf: (Array with: #(10 20 30) with: #(30 20 10))) report

The test rests on an approximation that goes wrong when the expected counts
are small, so it tells you the smallest one and warns you when it is under
five:

(ChiSquareTest independenceOf: (Array with: #(20 30) with: #(30 20))) smallestExpected
(ChiSquareTest goodnessOf: #(1 2 3)) report

Note what the second one did not do: it did not refuse.  A test will answer a
number for almost any input, and reading the warnings is your job.

The expected counts themselves, which are worth looking at when a result
surprises you:

(ChiSquareTest independenceOf: (Array with: #(20 30) with: #(30 20))) expectedCounts'!
rankTests
	^TutorialLesson title: 'The rank tests' text:
'A t test assumes the data is roughly normal.  When it is not -- small samples,
a long tail, or numbers that are really an ordering -- the rank tests ask the
same kind of question without that assumption.  They throw away the values and
keep only the order.

MANN-WHITNEY, for two separate groups, is the rank counterpart of the
two-sample t test.  It asks whether one group TENDS to be above the other:

(MannWhitneyTest of: #(5.1 4.9 6.2 5.8) and: #(6.3 6.8 7.1 6.5)) report

WILCOXON SIGNED RANK is the paired one.  Pairs with no difference are dropped,
which it tells you about:

(WilcoxonSignedRankTest of: #(5.1 4.9 6.2 5.8) and: #(6.3 6.8 7.1 6.5)) report
(WilcoxonSignedRankTest of: #(1 2 3 4) and: #(1 2 5 7)) usedPairs

Ranks are what they work on, and ties share the average rank:

#(10 20 30) ranks
#(10 20 20 30) ranks

Two things to know about these.  They use the normal approximation with a
continuity correction rather than the exact distribution, so they are at their
best with more than about ten values on each side.  And what they test is not
quite what a t test tests -- a difference in the tendency to be larger, not a
difference in means -- so do not quote one as if it were the other.

Correlation has its own test, for whether an r is further from zero than
chance would give:

(CorrelationTest of: #(1 2 3 4 5 6 7 8) and: #(2 4 5 4 5 7 8 9)) report
(CorrelationTest spearmanOf: #(1 2 3 4 5) and: #(1 4 9 16 25)) r

Spearman is Pearson on the ranks, which is why it answers 1 for that pair:
they rise together, even though the relation is not a straight line.'!
analysisOfVariance
	^TutorialLesson title: 'Analysis of variance' text:
'With more than two groups, running a t test on every pair is wrong: each test
has its own chance of a false alarm and they add up.  One-way analysis of
variance asks the question once -- are these group means further apart than
chance would make them:

AnovaTest of: (Array with: #(6 8 4 5) with: #(8 12 9 11) with: #(13 9 11 8))
(AnovaTest of: (Array with: #(6 8 4 5) with: #(8 12 9 11) with: #(13 9 11 8))) report

It works by splitting the total variation in two: the part BETWEEN the groups
and the part WITHIN them.  If the first is large compared with the second, the
grouping is explaining something:

| f | f := AnovaTest of: (Array with: #(6 8 4 5) with: #(8 12 9 11) with: #(13 9 11 8)). f betweenSS
| f | f := AnovaTest of: (Array with: #(6 8 4 5) with: #(8 12 9 11) with: #(13 9 11 8)). f withinSS
| f | f := AnovaTest of: (Array with: #(6 8 4 5) with: #(8 12 9 11) with: #(13 9 11 8)). f etaSquared

eta squared is the share of the variation the grouping accounts for, and it is
worth reporting next to the p-value, because it says how much rather than
whether.

On a table, split a column by a grouping column:

(Stats examplePlants anovaOf: ''height'' by: ''variety'') report
(Stats examplePlants anovaOf: ''weight'' by: ''variety'') etaSquared

That is the simulated data, which was built with a real difference between the
varieties, and the test duly finds it.  Look at the groups as well, because a
p-value never tells you WHICH groups differ:

(Stats examplePlants meanBy: ''variety'' of: ''height'') asText

Answering that properly needs a post-hoc test, which this package does not
have.'!
regression
	^TutorialLesson title: 'Regression' text:
'Least squares fits the straight line through a set of points that leaves the
smallest total squared distance.

LinearRegression of: #(1 2 3 4 5) and: #(2.1 4.2 5.8 8.1 9.9)
(LinearRegression of: #(1 2 3 4 5) and: #(2.1 4.2 5.8 8.1 9.9)) report

Note the argument order: the x values first, then the y.  Through a table it
reads the other way round, which is how you say it in words -- weight ON
height:

Stats examplePlants regressionOf: ''weight'' on: ''height''
(Stats examplePlants regressionOf: ''weight'' on: ''height'') report

The parts of the answer:

| r | r := Stats examplePlants regressionOf: ''weight'' on: ''height''. r slope
| r | r := Stats examplePlants regressionOf: ''weight'' on: ''height''. r intercept
| r | r := Stats examplePlants regressionOf: ''weight'' on: ''height''. r rSquared
| r | r := Stats examplePlants regressionOf: ''weight'' on: ''height''. r pForSlope
| r | r := Stats examplePlants regressionOf: ''weight'' on: ''height''. r confidenceIntervalForSlope

r squared is the share of the variation in y the line accounts for.  The
p-value is on the SLOPE: how often a slope this far from flat would turn up by
chance.

Using the line, and looking at what it did not explain:

| r | r := LinearRegression of: #(1 2 3 4 5) and: #(2.1 4.2 5.8 8.1 9.9). r valueAt: 6
| r | r := LinearRegression of: #(1 2 3 4 5) and: #(2.1 4.2 5.8 8.1 9.9). r predict: #(6 7)
| r | r := LinearRegression of: #(1 2 3 4 5) and: #(2.1 4.2 5.8 8.1 9.9). r residuals

Always look at the residuals, and at the scatter plot.  A line can have a
splendid r squared and still be the wrong shape entirely, and the only way to
notice is to look:

Stats examplePlants scatterOf: ''weight'' against: ''height'''!
theDistributions
	^TutorialLesson title: 'The distributions underneath' text:
'The p-values come from a class called Distribution, which is there to be used
directly as well.

The normal distribution, and its inverse:

Distribution normalCDF: 0.0
Distribution normalCDF: 1.96
Distribution normalQuantile: 0.975
Distribution normalQuantile: 0.025

That 1.96 is where the usual ninety-five per cent comes from, and you have
just derived it rather than looked it up.

Student''s t, which is the normal with fatter tails when you have few data.
Watch it approach the normal as the degrees of freedom grow:

Distribution tQuantile: 0.975 df: 1
Distribution tQuantile: 0.975 df: 10
Distribution tQuantile: 0.975 df: 1000

Chi-square and F, for the tests that use them:

Distribution chiSquareQuantile: 0.95 df: 1
Distribution chiSquareTail: 3.841458820694124 df: 1
Distribution fQuantile: 0.95 df1: 3 df2: 12
Distribution fTail: 3.4902948195 df1: 3 df2: 12

Underneath those are the regularized incomplete gamma and beta functions, by
the standard algorithms, and the log gamma by Lanczos:

Distribution lnGamma: 0.5
Distribution gamma: 5.0
Distribution erf: 1.0
Distribution incompleteBeta: 0.5 a: 2 b: 3
Distribution binomial: 10 choose: 3

They agree with published tables to about ten digits, which the package''s
tests check against figures worked out independently.  That matters more than
it sounds: a statistics library whose tail areas are a little bit wrong will
never tell you so.'!
theBrowser
	^TutorialLesson title: 'The table browser' text:
'For looking at a table rather than computing with it, there is a window.
Open it from the System menu (right-click the desktop, then table browser), or
from here:

Stats openBrowserOn: Stats examplePlants

The list on the left holds the columns, with a hash in front of the ones that
are numbers.  The right pane shows the rows, and the menu on the right button
changes what it shows: just that column, a description of it, a plot of it,
the whole table, the summary, the correlations between every pair of numeric
columns, or the CSV.  It will also sort by the selected column.

The same things without a window:

TableBrowser openOn: Stats examplePlants
TableBrowser listItems
TableBrowser detailAt: 1
TableBrowser commandLabels

The correlations view is the one to reach for first with a table you have
never seen, because it shows you in one screen which columns move together:

TableBrowser openOn: Stats examplePlants. TableBrowser correlations

Opening it on something you have just computed works too:

Stats openBrowserOn: (Stats examplePlants meanBy: ''variety'' of: ''height'')'!
whatNext
	^TutorialLesson title: 'Where to go next' text:
'That is the package.  What to carry away:

Look at the data before you test it.  summary, describe:, a histogram and a
scatter plot take four lines and will save you from most mistakes.

Choose the test from the question and the data, not from the answer.

A p-value is the chance of a difference this big if nothing were going on, and
nothing else.  Report the size of the effect next to it: a confidence
interval, an eta squared, an r squared.

What is NOT here: multiple regression, logistic regression, two-way analysis
of variance and interactions, post-hoc comparisons, corrections for testing
many things at once, exact distributions for the rank tests, time series and
clustering.  The tables are in memory and are not indexed, so a join over a
hundred thousand rows will be slow.

One thing that IS elsewhere: the Phylo package has a bootstrap, which is a
good way to put an interval round a statistic this package has no formula for.

The package README is packages/Stats/README.md.  The classes are in the
categories beginning with Stats, and the one to read first is Statistics
itself, which is short.

The example data and what was built into it:

Stats examples
Stats examplePlants correlationBetween: ''height'' and: ''weight''

Other tutorials in this image:

Smalltalk tutorialNames

and the one for the language itself:

Smalltalk tutorial'! !
