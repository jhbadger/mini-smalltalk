"DataTable: rows and named columns, the thing a CSV file turns into.

A table holds its column names and its rows, each row an Array of values in column order. Iterating gives
TableRows, which know their table and so can be asked for a column by name:

	(table select: [:row | (row at: 'age') > 30]) sortBy: 'name'

Every method that answers a table answers a new one; nothing changes a table in place except addRow: and
addColumn:, which are there for building one up. A cell may be nil, which is what an empty field in a file
becomes, and the statistics quietly leave nils out rather than failing on them."

Object subclass: #DataTable instanceVariableNames: 'name columnNames rows' classVariableNames: '' category: 'Stats-Tables'!
Object subclass: #TableRow instanceVariableNames: 'table values' classVariableNames: '' category: 'Stats-Tables'!

"---- one row ----"

!TableRow class methodsFor: 'instance creation'!
on: anArray of: aTable
	^self basicNew setValues: anArray of: aTable! !

!TableRow methodsFor: 'private'!
setValues: anArray of: aTable
	values := anArray.
	table := aTable! !

!TableRow methodsFor: 'accessing'!
table
	^table!
values
	^values!
asArray
	^values copy!
columnNames
	^table columnNames!
size
	^values size!
at: aName
	"the cell under that column name"
	| i |
	i := table indexOfColumn: aName.
	i = 0 ifTrue: [^StatsError new signal: 'there is no column called ', aName printString].
	^values at: i!
at: aName ifAbsent: aBlock
	| i |
	i := table indexOfColumn: aName.
	^i = 0 ifTrue: [aBlock value] ifFalse: [values at: i]!
at: aName put: anObject
	| i |
	i := table indexOfColumn: aName.
	i = 0 ifTrue: [^StatsError new signal: 'there is no column called ', aName printString].
	values at: i put: anObject.
	^anObject!
atIndex: anInteger
	^values at: anInteger!
numberAt: aName
	"the cell as a number, or nil when it is not one"
	| v |
	v := self at: aName ifAbsent: [nil].
	^(v notNil and: [v isNumber]) ifTrue: [v] ifFalse: [nil]!
do: aBlock
	values do: aBlock!
keysAndValuesDo: aBlock
	table columnNames doWithIndex: [:each :i | aBlock value: each value: (values at: i)]! !

!TableRow methodsFor: 'printing'!
printOn: aStream
	| first |
	aStream nextPutAll: 'a TableRow('.
	first := true.
	self keysAndValuesDo: [:k :v |
		first ifFalse: [aStream nextPutAll: ', '].
		first := false.
		aStream nextPutAll: k; nextPut: $=; print: v].
	aStream nextPut: $)! !

"---- the table ----"

!DataTable class methodsFor: 'instance creation'!
columns: someNames
	"an empty table with these columns"
	^self basicNew setColumns: someNames rows: OrderedCollection new!
columns: someNames rows: someRows
	^self basicNew setColumns: someNames rows: someRows!
fromRows: someRows
	"the first row is taken as the header"
	| all |
	all := someRows asOrderedCollection.
	all isEmpty ifTrue: [^StatsError new signal: 'there are no rows, so there is no header either'].
	^self columns: (all first collect: [:each | each displayString])
		rows: (all copyFrom: 2 to: all size)!
readCSV: aPath
	^CSVReader readFile: aPath!
readTSV: aPath
	^CSVReader new delimiter: (Character tab); readFile: aPath!
fromCSV: aString
	^CSVReader parse: aString!
fromTSV: aString
	^CSVReader new delimiter: (Character tab); parse: aString! !

!DataTable methodsFor: 'private'!
setColumns: someNames rows: someRows
	| n |
	columnNames := (someNames asOrderedCollection collect: [:each | each displayString]) asArray.
	n := columnNames size.
	rows := OrderedCollection new.
	someRows do: [:each | rows add: (self paddedRow: each to: n)].
	^self!
paddedRow: aRow to: n
	"a row that is short is filled out with nils, and one that is long is cut: a file is never tidy"
	| v out |
	v := aRow isNil ifTrue: [#()] ifFalse: [aRow asArray].
	v size = n ifTrue: [^v copy].
	out := Array new: n.
	1 to: (n min: v size) do: [:i | out at: i put: (v at: i)].
	^out! !

!DataTable methodsFor: 'accessing'!
name
	^name ifNil: ['a table']!
name: aString
	name := aString!
columnNames
	^columnNames!
columnCount
	^columnNames size!
rowCount
	^rows size!
size
	^rows size!
isEmpty
	^rows isEmpty!
notEmpty
	^rows notEmpty!
indexOfColumn: aName
	| text |
	text := aName displayString.
	^columnNames indexOf: text ifAbsent: [0]!
includesColumn: aName
	^(self indexOfColumn: aName) > 0!
rowAt: anIndex
	^TableRow on: (rows at: anIndex) of: self!
rowArrays
	^rows!
at: aRowIndex and: aName
	^(self rowAt: aRowIndex) at: aName!
column: aName
	"the whole column, as an Array"
	| i |
	i := self indexOfColumn: aName.
	i = 0 ifTrue: [^StatsError new signal: 'there is no column called ', aName displayString printString].
	^(rows collect: [:each | each at: i]) asArray!
columnAt: anIndex
	^(rows collect: [:each | each at: anIndex]) asArray!
numbersIn: aName
	"the column with the nils and anything that is not a number left out"
	^Statistics numbersOf: (self column: aName)!
first
	^self rowAt: 1!
last
	^self rowAt: rows size! !

!DataTable methodsFor: 'enumerating'!
do: aBlock
	1 to: rows size do: [:i | aBlock value: (self rowAt: i)]!
doWithIndex: aBlock
	1 to: rows size do: [:i | aBlock value: (self rowAt: i) value: i]!
collect: aBlock
	"the block's answer for each row, as an OrderedCollection; use withColumns: to pick columns"
	| out |
	out := OrderedCollection new.
	self do: [:row | out add: (aBlock value: row)].
	^out!
detect: aBlock
	^self detect: aBlock ifNone: [StatsError new signal: 'no row answers that']!
detect: aBlock ifNone: anotherBlock
	self do: [:row | (aBlock value: row) ifTrue: [^row]].
	^anotherBlock value!
count: aBlock
	| n |
	n := 0.
	self do: [:row | (aBlock value: row) ifTrue: [n := n + 1]].
	^n!
anySatisfy: aBlock
	self do: [:row | (aBlock value: row) ifTrue: [^true]].
	^false!
inject: a into: aBlock
	| total |
	total := a.
	self do: [:row | total := aBlock value: total value: row].
	^total! !

!DataTable methodsFor: 'building'!
addRow: aRow
	| v |
	v := (aRow isKindOf: TableRow) ifTrue: [aRow asArray] ifFalse: [aRow].
	rows add: (self paddedRow: v to: columnNames size).
	^aRow!
addRows: someRows
	someRows do: [:each | self addRow: each].
	^self!
addColumn: aName values: someValues
	"a new column, in place; a short list is filled out with nils"
	| v |
	(self includesColumn: aName) ifTrue: [
		^StatsError new signal: 'there is already a column called ', aName displayString printString].
	v := someValues asOrderedCollection asArray.
	columnNames := columnNames copyWith: aName displayString.
	1 to: rows size do: [:i |
		rows at: i put: ((rows at: i) copyWith: (i <= v size ifTrue: [v at: i] ifFalse: [nil]))].
	^self!
addColumn: aName computedBy: aBlock
	"a new column worked out from each row as it stands"
	| v |
	v := self collect: aBlock.
	^self addColumn: aName values: v! !

!DataTable methodsFor: 'choosing rows'!
select: aBlock
	| out |
	out := OrderedCollection new.
	self do: [:row | (aBlock value: row) ifTrue: [out add: row asArray]].
	^(DataTable columns: columnNames rows: out) name: self name; yourself!
reject: aBlock
	^self select: [:row | (aBlock value: row) not]!
where: aName is: aValue
	^self select: [:row | (row at: aName) = aValue]!
where: aName isAbove: aValue
	^self select: [:row | | v | v := row numberAt: aName. v notNil and: [v > aValue]]!
where: aName isBelow: aValue
	^self select: [:row | | v | v := row numberAt: aName. v notNil and: [v < aValue]]!
head: n
	^(DataTable columns: columnNames rows: (rows copyFrom: 1 to: (n min: rows size)))
		name: self name; yourself!
tail: n
	| k |
	k := n min: rows size.
	^(DataTable columns: columnNames rows: (rows copyFrom: rows size - k + 1 to: rows size))
		name: self name; yourself!
rowsFrom: a to: b
	^(DataTable columns: columnNames rows: (rows copyFrom: (a max: 1) to: (b min: rows size)))
		name: self name; yourself!
withoutRowsWhereNil: aName
	^self select: [:row | (row at: aName) notNil]! !

!DataTable methodsFor: 'choosing columns'!
withColumns: someNames
	| indices |
	indices := someNames collect: [:each |
		| i |
		i := self indexOfColumn: each.
		i = 0 ifTrue: [^StatsError new signal: 'there is no column called ', each displayString printString].
		i].
	^(DataTable columns: (indices collect: [:i | columnNames at: i])
		rows: (rows collect: [:r | (indices collect: [:i | r at: i]) asArray]))
		name: self name; yourself!
withoutColumn: aName
	^self withColumns: (columnNames reject: [:each | each = aName displayString])!
renameColumn: aName to: anotherName
	| i copy |
	i := self indexOfColumn: aName.
	i = 0 ifTrue: [^StatsError new signal: 'there is no column called ', aName displayString printString].
	copy := columnNames copy.
	copy at: i put: anotherName displayString.
	^(DataTable columns: copy rows: (rows collect: [:r | r copy])) name: self name; yourself!
convertColumn: aName using: aBlock
	"a new table with that column put through the block"
	| i out |
	i := self indexOfColumn: aName.
	i = 0 ifTrue: [^StatsError new signal: 'there is no column called ', aName displayString printString].
	out := rows collect: [:r |
		| copy |
		copy := r copy.
		copy at: i put: (aBlock value: (r at: i)).
		copy].
	^(DataTable columns: columnNames rows: out) name: self name; yourself!
columnToNumbers: aName
	"everything in that column read as a number where it can be, and left as nil where it cannot"
	^self convertColumn: aName using: [:each | CSVReader numberFrom: each]! !

!DataTable methodsFor: 'sorting'!
sortBy: aName
	^self sortBy: aName descending: false!
sortBy: aName descending: aBoolean
	| i sorted |
	i := self indexOfColumn: aName.
	i = 0 ifTrue: [^StatsError new signal: 'there is no column called ', aName displayString printString].
	sorted := rows asSortedCollection: [:a :b |
		aBoolean
			ifTrue: [self is: (b at: i) before: (a at: i)]
			ifFalse: [self is: (a at: i) before: (b at: i)]].
	^(DataTable columns: columnNames rows: sorted asOrderedCollection) name: self name; yourself!
sortByBlock: aBlock
	"the block is given two TableRows and answers whether the first comes first"
	| sorted |
	sorted := rows asSortedCollection: [:a :b |
		aBlock value: (TableRow on: a of: self) value: (TableRow on: b of: self)].
	^(DataTable columns: columnNames rows: sorted asOrderedCollection) name: self name; yourself!
is: a before: b
	"an order that can cope with nils and with numbers and strings mixed, which a file will have"
	a isNil ifTrue: [^true].
	b isNil ifTrue: [^false].
	(a isNumber and: [b isNumber]) ifTrue: [^a <= b].
	^a displayString <= b displayString!
reversed
	^(DataTable columns: columnNames rows: rows asArray reversed asOrderedCollection)
		name: self name; yourself! !

!DataTable methodsFor: 'grouping'!
distinctValuesOf: aName
	"the values in that column, each once, in the order they first turn up"
	| seen out |
	seen := Set new.
	out := OrderedCollection new.
	(self column: aName) do: [:each |
		(seen includes: each) ifFalse: [seen add: each. out add: each]].
	^out asArray!
countBy: aName
	"how many rows have each value, as a Dictionary"
	| counts |
	counts := Dictionary new.
	(self column: aName) do: [:each | counts at: each put: (counts at: each ifAbsent: [0]) + 1].
	^counts!
groupBy: aName
	"a Dictionary from each value of that column to the table of the rows that have it"
	| groups i |
	i := self indexOfColumn: aName.
	i = 0 ifTrue: [^StatsError new signal: 'there is no column called ', aName displayString printString].
	groups := Dictionary new.
	rows do: [:r |
		| key |
		key := r at: i.
		(groups at: key ifAbsent: [nil]) isNil
			ifTrue: [groups at: key put: (DataTable columns: columnNames rows: OrderedCollection new)].
		(groups at: key) addRow: r].
	^groups!
groupBy: aName aggregate: anotherName with: aBlock
	"a two-column table: each value of aName, and what the block makes of that group's anotherName
	column (an Array of its values)"
	| groups out keys |
	groups := self groupBy: aName.
	keys := self distinctValuesOf: aName.
	out := DataTable columns: (Array with: aName displayString with: anotherName displayString).
	keys do: [:key |
		out addRow: (Array with: key with: (aBlock value: ((groups at: key) column: anotherName)))].
	^out name: self name, ' by ', aName displayString; yourself!
countsBy: aName
	"a two-column table of each value and how often it turns up"
	| out |
	out := DataTable columns: (Array with: aName displayString with: 'count').
	(self distinctValuesOf: aName) do: [:key |
		out addRow: (Array with: key with: (self count: [:row | (row at: aName) = key]))].
	^out name: self name, ' by ', aName displayString; yourself!
meanBy: aName of: anotherName
	^self groupBy: aName aggregate: anotherName with: [:values | Statistics mean: values]!
sumBy: aName of: anotherName
	^self groupBy: aName aggregate: anotherName with: [:values | Statistics sum: (Statistics numbersOf: values)]! !

!DataTable methodsFor: 'joining'!
join: anotherTable on: aName
	"an inner join: the rows that match on that column, with the other table's other columns added"
	^self join: anotherTable on: aName keepingUnmatched: false!
leftJoin: anotherTable on: aName
	"every row of this table, with nils where the other has nothing to match it"
	^self join: anotherTable on: aName keepingUnmatched: true!
join: anotherTable on: aName keepingUnmatched: aBoolean
	| mine theirs otherNames out index blank |
	mine := self indexOfColumn: aName.
	theirs := anotherTable indexOfColumn: aName.
	(mine = 0 or: [theirs = 0]) ifTrue: [
		^StatsError new signal: 'both tables need a column called ', aName displayString printString].
	otherNames := anotherTable columnNames reject: [:each | each = aName displayString].
	index := Dictionary new.
	anotherTable rowArrays do: [:r |
		| key |
		key := r at: theirs.
		(index at: key ifAbsent: [nil]) isNil ifTrue: [index at: key put: OrderedCollection new].
		(index at: key) add: r].
	blank := Array new: otherNames size.
	out := DataTable columns: columnNames, otherNames.
	rows do: [:r |
		| matches |
		matches := index at: (r at: mine) ifAbsent: [nil].
		matches isNil
			ifTrue: [aBoolean ifTrue: [out addRow: r, blank]]
			ifFalse: [matches do: [:other |
				out addRow: r, (otherNames collect: [:each | other at: (anotherTable indexOfColumn: each)])]]].
	^out name: self name, ' joined with ', anotherTable name; yourself!
, anotherTable
	"the rows of both, which wants the same columns in the same order"
	columnNames = anotherTable columnNames ifFalse: [
		^StatsError new signal: 'the two tables do not have the same columns'].
	^(DataTable columns: columnNames rows: rows, anotherTable rowArrays) name: self name; yourself! !

!DataTable methodsFor: 'statistics'!
meanOf: aName
	^Statistics mean: (self numbersIn: aName)!
medianOf: aName
	^Statistics median: (self numbersIn: aName)!
sumOf: aName
	^Statistics sum: (self numbersIn: aName)!
minimumOf: aName
	^Statistics minimum: (self numbersIn: aName)!
maximumOf: aName
	^Statistics maximum: (self numbersIn: aName)!
standardDeviationOf: aName
	^Statistics standardDeviation: (self numbersIn: aName)!
correlationBetween: aName and: anotherName
	^Statistics correlation: (self column: aName) with: (self column: anotherName)!
regressionOf: aName on: anotherName
	"the least squares line of aName against anotherName"
	^LinearRegression of: (self column: anotherName) and: (self column: aName)!
tTestOf: aName by: aGroupName
	"split the column by a two-valued grouping column and compare the two halves"
	| values |
	values := self distinctValuesOf: aGroupName.
	values size = 2 ifFalse: [
		^StatsError new signal: 'a t test wants exactly two groups, and there are ', values size printString].
	^TTest of: ((self where: aGroupName is: values first) numbersIn: aName)
		and: ((self where: aGroupName is: values last) numbersIn: aName)!
anovaOf: aName by: aGroupName
	^AnovaTest of: ((self distinctValuesOf: aGroupName)
		collect: [:each | (self where: aGroupName is: each) numbersIn: aName])!
isNumericColumn: aName
	| all numbers |
	all := (self column: aName) reject: [:each | each isNil].
	all isEmpty ifTrue: [^false].
	numbers := all select: [:each | each isNumber].
	^numbers size = all size!
numericColumnNames
	^columnNames select: [:each | self isNumericColumn: each]! !

!DataTable methodsFor: 'describing'!
describe: aName
	| out v |
	out := WriteStream on: String new.
	out nextPutAll: aName displayString; nl.
	(self isNumericColumn: aName)
		ifTrue: [
			v := self numbersIn: aName.
			out nextPutAll: (Statistics summaryOf: v)]
		ifFalse: [
			out nextPutAll: 'not numbers'; nl.
			out nextPutAll: 'distinct '; print: (self distinctValuesOf: aName) size; nl.
			out nextPutAll: 'missing  '; print: (self count: [:row | (row at: aName) isNil]); nl].
	^out contents!
describe
	| out |
	out := WriteStream on: String new.
	out nextPutAll: self name; nextPutAll: ': '; print: self rowCount; nextPutAll: ' rows, ';
		print: self columnCount; nextPutAll: ' columns'; nl; nl.
	columnNames do: [:each | out nextPutAll: (self describe: each); nl].
	^out contents!
summary
	"one line per column: its name, what is in it, and the middle of it"
	| out width |
	out := WriteStream on: String new.
	width := 8.
	columnNames do: [:each | width := width max: each size].
	columnNames do: [:each |
		out nextPutAll: (self pad: each to: width + 2).
		(self isNumericColumn: each)
			ifTrue: [
				| v |
				v := self numbersIn: each.
				out nextPutAll: 'number   mean ';
					nextPutAll: (v isEmpty ifTrue: ['-'] ifFalse: [(Statistics mean: v) asFloat printShowingDecimalPlaces: 3]);
					nextPutAll: '   min '; nextPutAll: (v isEmpty ifTrue: ['-'] ifFalse: [(Statistics minimum: v) printString]);
					nextPutAll: '   max '; nextPutAll: (v isEmpty ifTrue: ['-'] ifFalse: [(Statistics maximum: v) printString])]
			ifFalse: [
				out nextPutAll: 'other    '; print: (self distinctValuesOf: each) size; nextPutAll: ' distinct'].
		out nl].
	^out contents! !

!DataTable methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a DataTable('; print: self rowCount; nextPutAll: ' x '; print: self columnCount; nextPut: $)!
pad: aString to: aWidth
	^aString, (String new: (aWidth - aString size max: 1) withAll: (Character value: 32))!
cellText: anObject
	"a cell as text: a Float that prints short prints as itself, and a long one is cut to four places
	so that the columns stay narrow"
	| text |
	anObject isNil ifTrue: [^''].
	anObject isString ifTrue: [^anObject].
	(anObject isKindOf: Float) ifTrue: [
		text := anObject printString.
		^text size <= 8 ifTrue: [text] ifFalse: [anObject printShowingDecimalPlaces: 4]].
	^anObject displayString!
asText
	^self asTextLimitedTo: 20!
asTextLimitedTo: aCount
	"the table drawn with its columns lined up, at most this many rows"
	| out widths shown |
	self isEmpty ifTrue: [^self name, ': no rows', (String with: Character lf)].
	shown := aCount min: rows size.
	widths := columnNames collect: [:each | each size].
	1 to: shown do: [:i |
		1 to: columnNames size do: [:j |
			widths at: j put: ((widths at: j) max: (self cellText: ((rows at: i) at: j)) size)]].
	out := WriteStream on: String new.
	1 to: columnNames size do: [:j |
		out nextPutAll: (self pad: (columnNames at: j) to: (widths at: j) + 2)].
	out nl.
	1 to: columnNames size do: [:j |
		out nextPutAll: (self pad: (String new: (widths at: j) withAll: $-) to: (widths at: j) + 2)].
	out nl.
	1 to: shown do: [:i |
		1 to: columnNames size do: [:j |
			out nextPutAll: (self pad: (self cellText: ((rows at: i) at: j)) to: (widths at: j) + 2)].
		out nl].
	shown < rows size ifTrue: [
		out nextPutAll: '... and '; print: rows size - shown; nextPutAll: ' more rows'; nl].
	^out contents!
report
	^self summary, (String with: Character lf), self asText!
asCSV
	^CSVWriter write: self!
asTSV
	^CSVWriter new delimiter: (Character tab); write: self!
writeCSVTo: aPath
	^CSVWriter new write: self toFile: aPath!
writeTSVTo: aPath
	^CSVWriter new delimiter: (Character tab); write: self toFile: aPath! !

!DataTable methodsFor: 'plotting'!
histogramOf: aName
	^TextPlot histogram: (self numbersIn: aName)!
barsOf: aName
	^TextPlot bars: (self countBy: aName)!
scatterOf: aName against: anotherName
	^TextPlot scatter: (self column: anotherName) and: (self column: aName)!
boxPlotOf: aName
	^TextPlot boxPlot: (self numbersIn: aName)! !
