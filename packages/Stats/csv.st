"Reading and writing delimited files.

The CSV rules are the ones everybody means by CSV: fields separated by commas, a field holding a comma, a
quote or a newline wrapped in double quotes, and a quote inside such a field written twice. A line ending may
be a newline or a carriage return and a newline. The first line is the header unless you say otherwise.

Fields are read as numbers where they look like numbers and as Strings where they do not; an empty field
becomes nil, so a column with a hole in it is still a column of numbers to the statistics. Set
inferTypes: false to keep every field a String."

Object subclass: #CSVReader instanceVariableNames: 'delimiter header inferTypes quote' classVariableNames: '' category: 'Stats-IO'!
Object subclass: #CSVWriter instanceVariableNames: 'delimiter header quote' classVariableNames: '' category: 'Stats-IO'!

"---- reading ----"

!CSVReader class methodsFor: 'instance creation'!
new
	^self basicNew setUp!
parse: aString
	^self new parse: aString!
readFile: aPath
	^self new readFile: aPath!
parseRows: aString
	"just the fields, with no header taken off and nothing read as a number"
	^self new header: false; inferTypes: false; fields: aString! !

!CSVReader class methodsFor: 'converting'!
numberFrom: anObject
	"the object as a number when it can be read as one, nil when it cannot"
	| text |
	anObject isNil ifTrue: [^nil].
	anObject isNumber ifTrue: [^anObject].
	text := anObject displayString trimBoth.
	^self new numberOf: text! !

!CSVReader methodsFor: 'private'!
setUp
	delimiter := $,.
	quote := $".
	header := true.
	inferTypes := true! !

!CSVReader methodsFor: 'options'!
delimiter
	^delimiter!
delimiter: aCharacter
	delimiter := aCharacter!
quote: aCharacter
	quote := aCharacter!
header
	^header!
header: aBoolean
	"false when the file has no header line; the columns are then called column1, column2 and so on"
	header := aBoolean!
inferTypes
	^inferTypes!
inferTypes: aBoolean
	inferTypes := aBoolean! !

!CSVReader methodsFor: 'reading'!
readFile: aPath
	(FileStream exists: aPath) ifFalse: [^StatsError new signal: 'no such file: ', aPath].
	^(self parse: (FileStream contentsOf: aPath)) name: aPath; yourself!
parse: aString
	| all names body |
	all := self fields: aString.
	all isEmpty ifTrue: [^DataTable columns: #()].
	header
		ifTrue: [
			names := all first collect: [:each | each displayString].
			body := all copyFrom: 2 to: all size]
		ifFalse: [
			names := (1 to: all first size) collect: [:i | 'column', i printString].
			body := all].
	names := self uniqueNames: names.
	^DataTable columns: names rows: (body collect: [:row | self convert: row to: names size])!
uniqueNames: someNames
	"two columns with the same name make a table you cannot ask questions of, so the later one is
	given a number"
	| seen out text |
	seen := Set new.
	out := OrderedCollection new.
	someNames doWithIndex: [:each :i |
		text := each trimBoth.
		text isEmpty ifTrue: [text := 'column', i printString].
		(seen includes: text) ifTrue: [text := text, '_', i printString].
		seen add: text.
		out add: text].
	^out asArray!
convert: aRow to: n
	| out |
	out := Array new: n.
	1 to: (n min: aRow size) do: [:i | out at: i put: (self valueOf: (aRow at: i))].
	^out!
valueOf: aString
	| text number |
	text := aString trimBoth.
	text isEmpty ifTrue: [^nil].
	inferTypes ifFalse: [^aString].
	number := self numberOf: text.
	^number ifNil: [aString]!
numberOf: aString
	"the string as an Integer or a Float, or nil when it is not a number; written out rather than
	leaning on asNumber, which answers 0 for anything it cannot read"
	| i n c seen point exponent sign |
	aString isEmpty ifTrue: [^nil].
	i := 1.
	sign := 1.
	((aString at: 1) = $- or: [(aString at: 1) = $+]) ifTrue: [
		(aString at: 1) = $- ifTrue: [sign := -1].
		i := 2].
	seen := false. point := false. exponent := false.
	n := i.
	[n <= aString size] whileTrue: [
		c := aString at: n.
		c isDigit
			ifTrue: [seen := true]
			ifFalse: [
				c = $. ifTrue: [
					(point or: [exponent]) ifTrue: [^nil].
					point := true]
				ifFalse: [
					(c = $e or: [c = $E])
						ifTrue: [
							(exponent or: [seen not]) ifTrue: [^nil].
							exponent := true.
							(n < aString size and: [((aString at: n + 1) = $-) or: [(aString at: n + 1) = $+]])
								ifTrue: [n := n + 1]]
						ifFalse: [^nil]]].
		n := n + 1].
	seen ifFalse: [^nil].
	^(point or: [exponent])
		ifTrue: [aString asNumber asFloat]
		ifFalse: [sign * (aString copyFrom: i to: aString size) asInteger]!
fields: aString
	"every row of the text as an Array of Strings, honouring the quoting"
	| rows row field i c size inQuotes |
	rows := OrderedCollection new.
	row := OrderedCollection new.
	field := WriteStream on: String new.
	inQuotes := false.
	i := 1.
	size := aString size.
	[i <= size] whileTrue: [
		c := aString at: i.
		inQuotes
			ifTrue: [
				c = quote
					ifTrue: [
						(i < size and: [(aString at: i + 1) = quote])
							ifTrue: [field nextPut: quote. i := i + 1]
							ifFalse: [inQuotes := false]]
					ifFalse: [field nextPut: c]]
			ifFalse: [
				c = quote ifTrue: [inQuotes := true]
				ifFalse: [
					c = delimiter
						ifTrue: [row add: field contents. field := WriteStream on: String new]
						ifFalse: [
							(c = Character lf or: [c = (Character value: 13)])
								ifTrue: [
									(c = (Character value: 13) and: [i < size and: [(aString at: i + 1) = Character lf]])
										ifTrue: [i := i + 1].
									row add: field contents.
									field := WriteStream on: String new.
									(row size = 1 and: [row first isEmpty])
										ifTrue: ["an empty line says nothing"]
										ifFalse: [rows add: row asArray].
									row := OrderedCollection new]
								ifFalse: [field nextPut: c]]]].
		i := i + 1].
	(field contents isEmpty and: [row isEmpty])
		ifFalse: [
			row add: field contents.
			(row size = 1 and: [row first isEmpty]) ifFalse: [rows add: row asArray]].
	^rows asArray! !

"---- writing ----"

!CSVWriter class methodsFor: 'writing'!
new
	^self basicNew setUp!
write: aTable
	^self new write: aTable!
write: aTable toFile: aPath
	^self new write: aTable toFile: aPath! !

!CSVWriter methodsFor: 'private'!
setUp
	delimiter := $,.
	quote := $".
	header := true! !

!CSVWriter methodsFor: 'options'!
delimiter: aCharacter
	delimiter := aCharacter!
header: aBoolean
	header := aBoolean! !

!CSVWriter methodsFor: 'writing'!
write: aTable
	| out |
	out := WriteStream on: String new.
	header ifTrue: [self putRow: aTable columnNames on: out].
	aTable rowArrays do: [:row | self putRow: row on: out].
	^out contents!
write: aTable toFile: aPath
	FileStream newFileNamed: aPath do: [:f | f nextPutAll: (self write: aTable)].
	^aPath!
putRow: aRow on: aStream
	| first |
	first := true.
	aRow do: [:each |
		first ifFalse: [aStream nextPut: delimiter].
		first := false.
		aStream nextPutAll: (self fieldFor: each)].
	aStream nl!
fieldFor: anObject
	| text |
	anObject isNil ifTrue: [^''].
	text := anObject isString ifTrue: [anObject] ifFalse: [anObject displayString].
	^(self needsQuoting: text) ifTrue: [self quoted: text] ifFalse: [text]!
needsQuoting: aString
	aString do: [:c |
		(c = delimiter or: [c = quote or: [c = Character lf or: [c = (Character value: 13)]]])
			ifTrue: [^true]].
	^false!
quoted: aString
	| out |
	out := WriteStream on: String new.
	out nextPut: quote.
	aString do: [:c |
		c = quote ifTrue: [out nextPut: quote].
		out nextPut: c].
	out nextPut: quote.
	^out contents! !
