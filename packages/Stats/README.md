# Stats

Tables and statistics: CSV in and out, a `DataTable` you can select, sort, group and join, the descriptive
statistics, the hypothesis tests with real p-values, least squares regression, and plots made of characters.

```smalltalk
Smalltalk loadPackage: 'Stats'
```

## The shortest useful example

```smalltalk
| t |
t := Stats readCSV: 'measurements.csv'.
t summary.                                   "one line per column"
t describe: 'height'.                        "n, mean, sd, the quartiles"
(t where: 'variety' is: 'beta') meanOf: 'height'.
(t anovaOf: 'height' by: 'variety') report.  "are the varieties really different"
(t regressionOf: 'weight' on: 'height') report.
t histogramOf: 'height'
```

## Statistics on any collection

The work is in `Statistics`, and the Collection methods forward to it, so `#(1 2 3) mean` reads the way it
should. A nil in a collection is left out rather than causing an error, since that is what an empty field in
a file becomes.

```smalltalk
#(2 4 4 4 5 5 7 9) mean                     "5"
#(2 4 4 4 5 5 7 9) median
#(2 4 4 4 5 5 7 9) mode
#(2 4 4 4 5 5 7 9) variance                 "4.571… -- the sample form, n - 1"
#(2 4 4 4 5 5 7 9) populationVariance       "4 -- divided by n"
#(2 4 4 4 5 5 7 9) standardDeviation
#(2 4 4 4 5 5 7 9) standardError
#(2 4 4 4 5 5 7 9) range
#(2 4 4 4 5 5 7 9) interquartileRange
#(2 4 4 4 5 5 7 9) medianAbsoluteDeviation  "a spread outliers do not move"
#(2 4 4 4 5 5 7 9) coefficientOfVariation
#(2 4 4 4 5 5 7 9) quantile: 0.9
#(2 4 4 4 5 5 7 9) percentile: 90
#(2 4 4 4 5 5 7 9) fiveNumberSummary        "min, Q1, median, Q3, max"
#(2 4 4 4 5 5 7 9) skewness
#(2 4 4 4 5 5 7 9) kurtosis                 "excess: zero for a normal distribution"
#(2 4 4 4 5 5 7 9) zScores
#(2 4 4 4 5 5 7 9) normalized               "onto 0 to 1"
#(2 4 4 4 5 5 7 9) ranks                    "ties share the average rank"
#(2 4 4 4 5 5 7 9) outliers                 "the 1.5 interquartile range rule"
#(1 2 3) correlationWith: #(2 4 7)          "Pearson's r"
#(1 2 3) spearmanWith: #(2 4 7)             "on the ranks"
#(1 2 3) covarianceWith: #(2 4 7)
#(1 2 3) geometricMean.  #(1 2 3) harmonicMean.  #(1 2 3) trimmedMean: 0.1
#(2 4 4 4 5 5 7 9) statisticsSummary        "all of it as text"
```

Anything with a sample and a population form has both, and the plain name is the sample form: `variance` and
`standardDeviation` divide by n − 1. Quantiles use the linear interpolation between order statistics that R
calls type 7 and that most other software uses too, so the numbers here agree with the ones you will get
elsewhere.

## Tables

`DataTable` holds named columns and rows. Iterating gives `TableRow`s, which know their table and so can be
asked for a column by name.

```smalltalk
| t |
t := Stats readCSV: 'plants.csv'.
t rowCount.  t columnCount.  t columnNames.
t column: 'height'.                        "the whole column, as an Array"
t numbersIn: 'height'.                     "the same with the nils and the non-numbers dropped"
t at: 3 and: 'height'.
(t rowAt: 3) at: 'variety'.

t select: [:row | (row at: 'height') > 25]
t reject: [:row | (row at: 'variety') = 'beta']
t where: 'variety' is: 'alpha'
t where: 'height' isAbove: 25
t detect: [:row | (row at: 'id') = 7]
t count: [:row | (row at: 'leaves') > 9]
t collect: [:row | (row at: 'height') * 2]      "an OrderedCollection of values"

t sortBy: 'height'.  t sortBy: 'height' descending: true.  t reversed.
t head: 10.  t tail: 10.  t rowsFrom: 20 to: 30.
t withColumns: #('variety' 'height').  t withoutColumn: 'id'.
t renameColumn: 'height' to: 'tallness'.
t convertColumn: 'height' using: [:v | v * 10].
t columnToNumbers: 'height'.                    "read a column of text as numbers"
```

Two methods change a table in place, for building one up; everything else answers a new table.

```smalltalk
t addRow: #(121 'alpha' 22.0 9.1 45.0 8).
t addColumn: 'ratio' computedBy: [:row | (row at: 'weight') / (row at: 'height')].
t addColumn: 'flag' values: someCollection.
```

Grouping and joining:

```smalltalk
t distinctValuesOf: 'variety'                   "#('alpha' 'beta' 'gamma')"
t countBy: 'variety'                            "a Dictionary"
t countsBy: 'variety'                           "the same as a two-column table"
t groupBy: 'variety'                            "a Dictionary of name -> table"
t meanBy: 'variety' of: 'height'
t sumBy: 'variety' of: 'weight'
t groupBy: 'variety' aggregate: 'height' with: [:values | values max]

plants join: varieties on: 'variety'            "inner"
plants leftJoin: varieties on: 'variety'        "keeping the unmatched, with nils"
oneTable , anotherTable                         "the rows of both"
```

and the statistics of a table:

```smalltalk
t meanOf: 'height'.  t medianOf: 'height'.  t sumOf: 'height'.
t minimumOf: 'height'.  t maximumOf: 'height'.  t standardDeviationOf: 'height'.
t correlationBetween: 'height' and: 'weight'.
t regressionOf: 'weight' on: 'height'.
t tTestOf: 'height' by: 'variety'               "wants exactly two groups"
t anovaOf: 'height' by: 'variety'
t isNumericColumn: 'height'.  t numericColumnNames.
t describe: 'height'.  t describe.  t summary.  t asText.  t asTextLimitedTo: 100.
```

## CSV

The rules are the ones everybody means by CSV: fields separated by commas, a field holding a comma, a quote
or a newline wrapped in double quotes, and a quote inside such a field written twice. A line ending may be a
newline or a carriage return and a newline, and a blank line is skipped.

```smalltalk
DataTable readCSV: 'file.csv'
DataTable readTSV: 'file.tsv'
DataTable fromCSV: aString
aTable asCSV.  aTable writeCSVTo: 'out.csv'.  aTable asTSV.
CSVReader new header: false; delimiter: $;; parse: aString
CSVReader new inferTypes: false; readFile: 'file.csv'
CSVReader numberFrom: '1e3'                     "1000.0, and nil for anything that is not a number"
```

Fields are read as numbers where they look like numbers and as Strings where they do not; an empty field
becomes nil. Two columns with the same name would make a table you cannot ask questions of, so the later one
gets a number put on the end of it.

## Hypothesis tests

Every test is an object: make it, and ask it for its statistic, its degrees of freedom, its p-value, and a
report.

| | |
|---|---|
| `TTest of:and:` | are the means of two samples different (Welch, which does not assume equal spreads) |
| `TTest pooledOf:and:` | the same, assuming they are equal |
| `TTest pairedOf:and:` | before and after, measurement by measurement |
| `TTest of:against:` | is the mean of one sample different from a number |
| `MannWhitneyTest of:and:` | does one sample tend to be above the other, asking nothing about the shape |
| `WilcoxonSignedRankTest of:and:` | the paired version of the same |
| `ChiSquareTest goodnessOf:against:` | do the counts match what was expected |
| `ChiSquareTest independenceOf:` | are the rows and columns of a contingency table related |
| `CorrelationTest of:and:` | is the correlation further from zero than chance would give |
| `AnovaTest of:` | are the means of several groups further apart than chance would make them |

```smalltalk
| t |
t := TTest of: #(5.1 4.9 6.2 5.8) and: #(6.3 6.8 7.1 6.5).
t statistic.  t degreesOfFreedom.  t p.  t meanDifference.  t confidenceInterval.
t isSignificant.                       "whether p is below the level, and nothing more"
t level: 0.01.
t report
```

```
two-sample t test, Welch
------------------------
t        -5.6339
df       13.91
mean difference -1.2125
95% interval   -1.6744 to -0.7506
p        < 0.0001

p is below 0.05, so a difference this big would be unusual if nothing were going on
```

`isSignificant` answers whether the p-value is below the level the test holds, which is 0.05 unless you set
another, and **that is all it means**. A p-value is not a verdict, and the report says so in words rather
than printing a star.

The chi-square tests also answer `smallestExpected`, and the report says so when a cell expects fewer than
five, because that is where the approximation starts to wobble. The rank tests use the normal approximation
with a continuity correction and a correction for ties, not the exact distribution, so they are at their
best when there are more than about ten values on each side.

## Regression

```smalltalk
| r |
r := LinearRegression of: #(1 2 3 4 5) and: #(2.1 4.2 5.8 8.1 9.9).
r slope.  r intercept.  r equation.          "'y = 1.9500x + 0.1700'"
r rSquared.  r r.  r residualStandardError.
r valueAt: 6.  r predict: #(6 7).  r residuals.  r fittedValues.
r tForSlope.  r pForSlope.  r confidenceIntervalForSlope.
r report
```

## Distributions

The tests get their p-values from `Distribution`, which is there to be used directly as well:

```smalltalk
Distribution normalCDF: 1.96                 "0.975…"
Distribution normalQuantile: 0.975           "1.959963…"
Distribution tCDF: 2.0 df: 10
Distribution tTwoTail: 2.228 df: 10          "the two-sided p-value"
Distribution tQuantile: 0.975 df: 10
Distribution chiSquareTail: 3.841 df: 1
Distribution chiSquareQuantile: 0.95 df: 3
Distribution fTail: 4.26 df1: 3 df2: 12
Distribution lnGamma: 0.5.  Distribution erf: 1.0.  Distribution binomial: 10 choose: 3
```

Underneath are the regularized incomplete gamma and beta functions, by the standard algorithms — Lanczos for
the log gamma, a series below the mean and a continued fraction above it for the gamma, a continued fraction
for the beta. They agree with published tables to about ten digits, which the tests check.

## Plots

```smalltalk
TextPlot histogram: values.  TextPlot histogram: values bins: 20.
TextPlot boxPlot: values
TextPlot scatter: xValues and: yValues
TextPlot bars: aDictionary
TextPlot sparkline: values                   "the shape of a series in one line"
TextPlot line: values
TextPlot distribution: values                "the summary, the histogram and the box plot together"
values histogram.  values boxPlot.  values sparkline.
aTable histogramOf: 'height'.  aTable barsOf: 'variety'.  aTable scatterOf: 'weight' against: 'height'.
```

```
16.920 to 18.385      3  #####
18.385 to 19.850      9  ##############
19.850 to 21.315     16  ##########################
21.315 to 22.780     25  ########################################
22.780 to 24.245     15  ########################

<                 [--------|---------]                     >
min 16.920   Q1 21.428   median 23.710   Q3 26.040   max 31.570
```

## The browser

**System menu → table browser** opens a table: the columns on the left (a `#` marks the ones that are
numbers), and on the right the rows, a description of the selected column, a plot of it, the whole table,
the correlations between the numeric columns, or the CSV. The menu sorts by the selected column and opens
another file.

```smalltalk
Stats openBrowserOn: aTable
```

## The example data

`data/` holds two simulated files. `plants.csv` is 120 plants of three varieties with four measurements each,
made with a real difference between the varieties and a real relation between height and weight, so the
tests can ask whether the methods find what was put there. `weather.csv` is 48 daily readings for four
towns, written with a comma inside a quoted column name, doubled quotes inside a field, and some missing
values, so that the CSV reader is tested against the things that actually break readers.

```smalltalk
Stats examplePlants.  Stats exampleWeather.  Stats examples.
(Stats examplePlants anovaOf: 'height' by: 'variety') p      "below 0.001"
(Stats examplePlants correlationBetween: 'height' and: 'weight')   "about 0.95"
```

## What it does not do

One grouping variable at a time: no two-way analysis of variance and no interactions. One predictor at a
time: no multiple regression, no logistic regression, no generalised linear models. No exact distributions
for the rank tests, no post-hoc comparisons, no correction for testing many things at once, no time series,
no clustering, and no bootstrap or permutation tests (though the [Phylo](../Phylo/README.md) package has a
bootstrap of its own). The tables are in memory and are not indexed, so a join over a hundred thousand rows
will be slow.

## Notes

* 141 SUnit tests in `tests.st`, plus 160 checks in `tests/tests.txt` that `make check` runs. The
  distributions and the tests are checked against published values, so a broken formula shows up as a wrong
  number rather than as nothing at all.
* `StatsError` is the error this package signals; it is a subclass of `Error`.
