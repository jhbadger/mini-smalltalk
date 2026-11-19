"The front door, and the table browser.

Stats is a class with nothing but class-side methods: the short way to read a file, run a test, fit a line or
draw something. TableBrowser puts a table in a window - the columns on the left, and on the right the rows,
a description of the selected column, a histogram of it, or the correlations between the numeric columns."

Object subclass: #Stats instanceVariableNames: '' classVariableNames: '' category: 'Stats'!
Object subclass: #TableBrowser instanceVariableNames: '' classVariableNames: 'Table Mode Selected Note' category: 'Stats'!

!Stats class methodsFor: 'the package'!
version
	^'1.0'!
directory
	^Smalltalk packagePath: 'Stats'!
dataDirectory
	^self directory, '/data'!
exampleFile: aName
	^self dataDirectory, '/', aName!
examples
	"what is in data/, and what each one is"
	^#(
		#('plants.csv' '120 simulated plants of three varieties, with four measurements each')
		#('weather.csv' '48 simulated daily readings for four towns, with holes and quoted fields in it'))!
examplePlants
	^self readCSV: (self exampleFile: 'plants.csv')!
exampleWeather
	^self readCSV: (self exampleFile: 'weather.csv')!
exampleTable
	^self examplePlants! !

!Stats class methodsFor: 'tables'!
readCSV: aPath
	^DataTable readCSV: aPath!
readTSV: aPath
	^DataTable readTSV: aPath!
csv: aString
	^DataTable fromCSV: aString!
tsv: aString
	^DataTable fromTSV: aString!
table: someColumnNames rows: someRows
	^DataTable columns: someColumnNames rows: someRows!
fromRows: someRows
	^DataTable fromRows: someRows! !

!Stats class methodsFor: 'describing'!
summaryOf: aCollection
	^Statistics summaryOf: aCollection!
describe: aCollection
	^TextPlot distribution: aCollection!
mean: aCollection
	^Statistics mean: aCollection!
median: aCollection
	^Statistics median: aCollection!
standardDeviation: aCollection
	^Statistics standardDeviation: aCollection!
quantile: aFraction of: aCollection
	^Statistics quantile: aFraction of: aCollection!
correlation: aCollection with: anotherCollection
	^Statistics correlation: aCollection with: anotherCollection! !

!Stats class methodsFor: 'tests'!
tTestOf: aCollection and: anotherCollection
	^TTest of: aCollection and: anotherCollection!
tTestOf: aCollection against: aNumber
	^TTest of: aCollection against: aNumber!
pairedTTestOf: aCollection and: anotherCollection
	^TTest pairedOf: aCollection and: anotherCollection!
mannWhitneyOf: aCollection and: anotherCollection
	^MannWhitneyTest of: aCollection and: anotherCollection!
wilcoxonOf: aCollection and: anotherCollection
	^WilcoxonSignedRankTest of: aCollection and: anotherCollection!
chiSquareOf: someCounts
	^ChiSquareTest goodnessOf: someCounts!
chiSquareOf: someCounts against: someExpected
	^ChiSquareTest goodnessOf: someCounts against: someExpected!
independenceOf: aTable
	^ChiSquareTest independenceOf: aTable!
correlationTestOf: aCollection and: anotherCollection
	^CorrelationTest of: aCollection and: anotherCollection!
anovaOf: someGroups
	^AnovaTest of: someGroups!
regressionOf: yValues on: xValues
	^LinearRegression of: xValues and: yValues!
tests
	"the tests this package knows, and what each one asks"
	^#(
		#('TTest of:and:' 'are the means of two samples different (Welch)')
		#('TTest pooledOf:and:' 'the same, assuming the two spreads are equal')
		#('TTest pairedOf:and:' 'are before and after different, measurement by measurement')
		#('TTest of:against:' 'is the mean of one sample different from a number')
		#('MannWhitneyTest of:and:' 'does one sample tend to be above the other, without assuming a shape')
		#('WilcoxonSignedRankTest of:and:' 'the paired version of the same')
		#('ChiSquareTest goodnessOf:against:' 'do the counts match what was expected')
		#('ChiSquareTest independenceOf:' 'are the rows and columns of a table related')
		#('CorrelationTest of:and:' 'is the correlation further from zero than chance would give')
		#('AnovaTest of:' 'are the means of several groups further apart than chance would make them')
		#('LinearRegression of:and:' 'the least squares line, with a p-value on its slope'))! !

!Stats class methodsFor: 'distributions'!
normalCDF: x
	^Distribution normalCDF: x!
normalQuantile: p
	^Distribution normalQuantile: p!
tTail: t df: df
	^Distribution tTwoTail: t df: df!
chiSquareTail: x df: df
	^Distribution chiSquareTail: x df: df!
fTail: x df1: a df2: b
	^Distribution fTail: x df1: a df2: b! !

!Stats class methodsFor: 'plots'!
histogram: aCollection
	^TextPlot histogram: aCollection!
histogram: aCollection bins: n
	^TextPlot histogram: aCollection bins: n!
boxPlot: aCollection
	^TextPlot boxPlot: aCollection!
scatter: xValues and: yValues
	^TextPlot scatter: xValues and: yValues!
bars: aDictionary
	^TextPlot bars: aDictionary!
sparkline: aCollection
	^TextPlot sparkline: aCollection! !

!Stats class methodsFor: 'the browser'!
openBrowser
	^TableBrowser open!
openBrowserOn: aTable
	^TableBrowser openOn: aTable! !

"---- the browser ----"

!TableBrowser class methodsFor: 'opening'!
open
	Table isNil ifTrue: [
		Table := [Stats examplePlants] on: Error do: [:e |
			DataTable columns: #('x' 'y') rows: (Array with: #(1 2) with: #(3 4))]].
	^self openWindow!
openOn: aTable
	Table := aTable.
	Selected := 1.
	Mode := #rows.
	^self openWindow!
openWindow
	Mode isNil ifTrue: [Mode := #rows].
	Note := nil.
	Smalltalk openListTool: 'TableBrowser'
		title: 'Table: ', self table rowCount printString, ' x ', self table columnCount printString.
	^true!
table
	^Table ifNil: [Table := DataTable columns: #('x') rows: #()]!
table: aTable
	Table := aTable.
	Selected := 1! !

!TableBrowser class methodsFor: 'the list'!
listItems
	| out |
	out := OrderedCollection new.
	out add: '* the whole table'.
	self table columnNames do: [:each |
		out add: ((self table isNumericColumn: each) ifTrue: ['# '] ifFalse: ['  ']), each].
	^out asArray!
columnAt: anIndex
	anIndex <= 1 ifTrue: [^nil].
	^(anIndex - 1) <= self table columnCount
		ifTrue: [self table columnNames at: anIndex - 1]
		ifFalse: [nil]!
detailAt: anIndex
	Selected := anIndex.
	^[self detailFor: (self columnAt: anIndex)]
		on: Error
		do: [:e | 'could not show this: ', (e messageText ifNil: [e class name asString])]!
detailFor: aName
	| out |
	out := WriteStream on: String new.
	Note ifNotNil: [:n | out nextPutAll: n; nl; nl].
	Mode == #summary ifTrue: [^out nextPutAll: self table summary; contents].
	Mode == #correlations ifTrue: [^out nextPutAll: self correlations; contents].
	Mode == #csv ifTrue: [^out nextPutAll: (self table head: 50) asCSV; contents].
	aName isNil ifTrue: [^out nextPutAll: (self table asTextLimitedTo: 40); contents].
	Mode == #describe ifTrue: [^out nextPutAll: (self table describe: aName); contents].
	Mode == #histogram ifTrue: [^out nextPutAll: (self plotOf: aName); contents].
	out nextPutAll: ((self table withColumns: (Array with: aName)) asTextLimitedTo: 40).
	^out contents!
plotOf: aName
	(self table isNumericColumn: aName)
		ifTrue: [^TextPlot distribution: (self table numbersIn: aName)].
	^TextPlot bars: (self table countBy: aName)!
correlations
	"Pearson's r between every pair of numeric columns"
	| names out |
	names := self table numericColumnNames.
	names size < 2 ifTrue: [^'there are fewer than two columns of numbers'].
	out := WriteStream on: String new.
	out nextPutAll: 'Pearson correlations'; nl; nl.
	1 to: names size do: [:i |
		i + 1 to: names size do: [:j |
			out nextPutAll: (names at: i); nextPutAll: ' and '; nextPutAll: (names at: j);
				nextPutAll: '   r = ';
				nextPutAll: ([(self table correlationBetween: (names at: i) and: (names at: j))
						printShowingDecimalPlaces: 4]
					on: Error do: [:e | '-']); nl]].
	^out contents! !

!TableBrowser class methodsFor: 'the menu'!
commandLabels
	^#('the column' 'describe it' 'plot it' 'the whole table' 'summary' 'correlations' 'as CSV' '-'
	   'sort by this column' 'sort the other way' '-' 'open CSV file...' 'copy to Transcript')!
command: aCommand at: anIndex
	| label column |
	label := self commandLabels at: aCommand.
	Selected := anIndex.
	column := self columnAt: anIndex.
	Note := nil.
	label = 'the column' ifTrue: [Mode := #rows. ^nil].
	label = 'describe it' ifTrue: [Mode := #describe. ^nil].
	label = 'plot it' ifTrue: [Mode := #histogram. ^nil].
	label = 'the whole table' ifTrue: [Mode := #rows. Selected := 1. ^nil].
	label = 'summary' ifTrue: [Mode := #summary. ^nil].
	label = 'correlations' ifTrue: [Mode := #correlations. ^nil].
	label = 'as CSV' ifTrue: [Mode := #csv. ^nil].
	label = 'sort by this column' ifTrue: [^self sortBy: column descending: false].
	label = 'sort the other way' ifTrue: [^self sortBy: column descending: true].
	label = 'open CSV file...' ifTrue: [^self openFileCommand].
	label = 'copy to Transcript' ifTrue: [
		Transcript showCr: (self table asTextLimitedTo: 200).
		^'copied to the Transcript'].
	^nil!
sortBy: aName descending: aBoolean
	aName isNil ifTrue: [^'select a column first'].
	Table := self table sortBy: aName descending: aBoolean.
	^nil!
openFileCommand
	| path |
	path := Smalltalk promptFor: 'CSV file' default: (Stats exampleFile: 'plants.csv').
	(path isNil or: [path trimBoth isEmpty]) ifTrue: [^nil].
	^[Table := DataTable readCSV: path trimBoth. Selected := 1. Mode := #rows. nil]
		on: Error
		do: [:e | 'could not read it: ', (e messageText ifNil: [e class name asString])]! !
