"Matrix: making one, looking inside it, changing its shape, and showing it."

!Matrix class methodsFor: 'tolerance'!
tolerance
	"what counts as zero for a Float entry, relative to the largest entry of the matrix (default 1.0e-10)"
	^Tolerance ifNil: [Tolerance := 1.0e-10]!
tolerance: aNumber
	Tolerance := aNumber!
fail: aString
	^MatrixError new signal: aString! !

!Matrix class methodsFor: 'instance creation'!
rowCount: r columnCount: c cells: aFlatArray
	"the cells are taken as they are, row by row"
	^self basicNew setRows: r columns: c cells: aFlatArray!
rows: rowArrays
	"a matrix from an Array of rows, each an Array of numbers:  Matrix rows: #(#(1 2) #(3 4))"
	| r c flat k |
	rowArrays isEmpty ifTrue: [^self fail: 'a matrix needs at least one row'].
	r := rowArrays size.
	c := (rowArrays at: 1) size.
	c = 0 ifTrue: [^self fail: 'a matrix needs at least one column'].
	flat := Array new: r * c.
	k := 0.
	rowArrays do: [:row |
		row size = c ifFalse: [^self fail: 'the rows are not all the same length'].
		row do: [:x |
			x isNumber ifFalse: [^self fail: 'a matrix holds numbers, not ', x printString].
			k := k + 1.
			flat at: k put: x]].
	^self rowCount: r columnCount: c cells: flat!
columns: columnArrays
	"a matrix from an Array of columns"
	^(self rows: columnArrays) transposed!
row: anArray
	"a row vector, 1 x n"
	^self rows: (Array with: anArray asArray)!
column: anArray
	"a column vector, n x 1"
	^self columns: (Array with: anArray asArray)!
rows: r columns: c fill: x
	^self rowCount: r columnCount: c cells: (Array new: r * c withAll: x)!
rows: r columns: c collect: aBlock
	"entry (i, j) is  aBlock value: i value: j"
	| flat k |
	flat := Array new: r * c.
	k := 0.
	1 to: r do: [:i | 1 to: c do: [:j | k := k + 1. flat at: k put: (aBlock value: i value: j)]].
	^self rowCount: r columnCount: c cells: flat!
zerosRows: r columns: c
	^self rows: r columns: c fill: 0!
zeros: n
	^self rows: n columns: n fill: 0!
onesRows: r columns: c
	^self rows: r columns: c fill: 1!
ones: n
	^self rows: n columns: n fill: 1!
identity: n
	^self rows: n columns: n collect: [:i :j | i = j ifTrue: [1] ifFalse: [0]]!
diagonal: anArray
	"a square matrix with those numbers on its diagonal and zeros elsewhere"
	| d |
	d := anArray asArray.
	^self rows: d size columns: d size collect: [:i :j | i = j ifTrue: [d at: i] ifFalse: [0]]!
fromString: aString
	"rows are separated by ; or by line breaks, numbers by spaces or commas; 3/4 is a fraction:
	Matrix fromString: '1 2; 3/4 5'"
	| rowsList cur tok flushTok flushRow |
	rowsList := OrderedCollection new.
	cur := OrderedCollection new.
	tok := WriteStream on: String new.
	flushTok := [
		tok contents isEmpty ifFalse: [cur add: (self parseNumber: tok contents)].
		tok := WriteStream on: String new].
	flushRow := [
		flushTok value.
		cur isEmpty ifFalse: [rowsList add: cur asArray. cur := OrderedCollection new]].
	aString do: [:ch |
		(ch = $; or: [ch value = 10 or: [ch value = 13]])
			ifTrue: [flushRow value]
			ifFalse: [
				(ch isSeparator or: [ch = $,])
					ifTrue: [flushTok value]
					ifFalse: [tok nextPut: ch]]].
	flushRow value.
	^self rows: rowsList asArray!
parseNumber: aString
	| i n d |
	i := aString indexOf: $/.
	i > 0 ifTrue: [
		n := self parseNumber: (aString copyFrom: 1 to: i - 1).
		d := self parseNumber: (aString copyFrom: i + 1 to: aString size).
		d = 0 ifTrue: [^self fail: 'a zero denominator in ', aString].
		^n / d].
	n := aString asNumber.
	n isNil ifTrue: [^self fail: 'not a number: ', aString].
	^n! !

!Matrix class methodsFor: 'special matrices'!
hilbert: n
	"entry (i, j) is 1/(i + j - 1): exact, and famously hard to invert in floating point"
	^self rows: n columns: n collect: [:i :j | 1 / (i + j - 1)]!
vandermonde: points
	"row i is 1, x, x^2 ... for the i-th point x: the matrix of polynomial interpolation"
	| p |
	p := points asArray.
	^self rows: p size columns: p size collect: [:i :j | (p at: i) raisedTo: j - 1]!
vandermonde: points degree: d
	"a tall Vandermonde matrix with d + 1 columns, for fitting a polynomial of degree d"
	| p |
	p := points asArray.
	^self rows: p size columns: d + 1 collect: [:i :j | (p at: i) raisedTo: j - 1]!
toeplitz: firstColumn
	"a symmetric Toeplitz matrix: entry (i, j) depends only on |i - j|"
	| c |
	c := firstColumn asArray.
	^self rows: c size columns: c size collect: [:i :j | c at: (i - j) abs + 1]!
companion: coefficients
	"the companion matrix of the monic polynomial a0 + a1 x + ... + a(n-1) x^(n-1) + x^n, given a0 ... a(n-1);
	its eigenvalues are the roots of the polynomial"
	| a n |
	a := coefficients asArray.
	n := a size.
	^self rows: n columns: n collect: [:i :j |
		j = n ifTrue: [(a at: i) negated] ifFalse: [i = (j + 1) ifTrue: [1] ifFalse: [0]]]!
pascal: n
	"entry (i, j) is the binomial coefficient C(i+j-2, i-1)"
	^self rows: n columns: n collect: [:i :j | ((i + j - 2) factorial) / ((i - 1) factorial * (j - 1) factorial)]!
rotation: radians
	"the 2 x 2 matrix that turns a plane vector counterclockwise by that angle"
	| c s |
	c := radians cos. s := radians sin.
	^self rows: (Array with: (Array with: c with: s negated) with: (Array with: s with: c))!
rotationX: radians
	| c s |
	c := radians cos. s := radians sin.
	^self rows: (Array with: #(1 0 0) with: (Array with: 0 with: c with: s negated) with: (Array with: 0 with: s with: c))!
rotationY: radians
	| c s |
	c := radians cos. s := radians sin.
	^self rows: (Array with: (Array with: c with: 0 with: s) with: #(0 1 0) with: (Array with: s negated with: 0 with: c))!
rotationZ: radians
	| c s |
	c := radians cos. s := radians sin.
	^self rows: (Array with: (Array with: c with: s negated with: 0) with: (Array with: s with: c with: 0) with: #(0 0 1))!
permutation: anArray
	"the permutation matrix P with  (P x) at: i = x at: (anArray at: i)"
	| n |
	n := anArray size.
	^self rows: n columns: n collect: [:i :j | (anArray at: i) = j ifTrue: [1] ifFalse: [0]]! !

!Matrix methodsFor: 'private'!
setRows: r columns: c cells: flat
	rows := r. cols := c. cells := flat!
cells
	^cells!
fail: aString
	^MatrixError new signal: aString!
index: i at: j
	^((i - 1) * cols) + j!
checkIndex: i at: j
	(i isInteger and: [j isInteger and: [i >= 1 and: [i <= rows and: [j >= 1 and: [j <= cols]]]]])
		ifFalse: [^self fail: 'there is no entry (', i printString, ', ', j printString, ') in a ',
			rows printString, ' x ', cols printString, ' matrix']!
workRows
	"a private copy of the entries as an Array of row Arrays, for algorithms that change them in place"
	^(1 to: rows) asArray collect: [:i | cells copyFrom: (i - 1) * cols + 1 to: i * cols]!
fromWork: anArrayOfRows
	^Matrix rows: anArrayOfRows!
fromWork: work rows: r columns: c
	| flat k |
	flat := Array new: r * c.
	k := 0.
	1 to: r do: [:i | 1 to: c do: [:j | k := k + 1. flat at: k put: ((work at: i) at: j)]].
	^Matrix rowCount: r columnCount: c cells: flat!
coerce: other
	"a Matrix from a Matrix or an Array (taken as a column vector)"
	other class == Matrix ifTrue: [^other].
	(other isKindOf: Matrix) ifTrue: [^other].
	other isNumber ifTrue: [^Matrix rows: 1 columns: 1 fill: other].
	^Matrix column: other!
requireSquare: aString
	rows = cols ifFalse: [^self fail: aString, ' needs a square matrix, and this one is ', rows printString, ' x ', cols printString]!
asFloats
	"the same matrix with every entry a Float"
	^Matrix rowCount: rows columnCount: cols cells: (cells collect: [:x | x asFloat])!
floatWork
	^(1 to: rows) asArray collect: [:i | (cells copyFrom: (i - 1) * cols + 1 to: i * cols) collect: [:x | x asFloat]]!
maxAbs
	| m |
	m := 0.
	cells do: [:x | x abs > m ifTrue: [m := x abs]].
	^m!
zeroThreshold
	"entries no bigger than this are taken as zero: nothing for an exact matrix"
	^self isExact ifTrue: [0] ifFalse: [self maxAbs * Matrix tolerance]!
isNegligible: x
	^x abs <= self zeroThreshold! !

!Matrix methodsFor: 'accessing'!
rowCount
	^rows!
columnCount
	^cols!
dimensions
	"#(rows columns)"
	^Array with: rows with: cols!
size
	"how many entries"
	^rows * cols!
isSquare
	^rows = cols!
isVector
	^rows = 1 or: [cols = 1]!
isColumnVector
	^cols = 1!
isRowVector
	^rows = 1!
isExact
	"true when no entry is a Float"
	^cells allSatisfy: [:x | x isFloat not]!
at: i at: j
	self checkIndex: i at: j.
	^cells at: ((i - 1) * cols) + j!
at: i at: j put: x
	"changes this matrix; see copy"
	self checkIndex: i at: j.
	x isNumber ifFalse: [^self fail: 'a matrix holds numbers, not ', x printString].
	cells at: ((i - 1) * cols) + j put: x.
	^x!
at: i
	"for a vector, its i-th entry"
	self isVector ifFalse: [^self fail: 'at: needs a vector; use at:at:'].
	^cells at: i!
rowArray: i
	"row i as an Array"
	(i isInteger and: [i >= 1 and: [i <= rows]]) ifFalse: [^self fail: 'there is no row ', i printString].
	^cells copyFrom: (i - 1) * cols + 1 to: i * cols!
columnArray: j
	"column j as an Array"
	| a |
	(j isInteger and: [j >= 1 and: [j <= cols]]) ifFalse: [^self fail: 'there is no column ', j printString].
	a := Array new: rows.
	1 to: rows do: [:i | a at: i put: (cells at: (i - 1) * cols + j)].
	^a!
row: i
	"row i as a 1 x n matrix"
	^Matrix row: (self rowArray: i)!
column: j
	"column j as an n x 1 matrix"
	^Matrix column: (self columnArray: j)!
diagonal
	"the main diagonal as an Array"
	^(1 to: (rows min: cols)) asArray collect: [:i | cells at: (i - 1) * cols + i]!
asArray
	"every entry, row by row, as one Array"
	^cells copy!
asArrays
	"an Array of row Arrays"
	^self workRows!
asColumnArrays
	^(1 to: cols) asArray collect: [:j | self columnArray: j]!
do: aBlock
	cells do: aBlock!
rowsDo: aBlock
	1 to: rows do: [:i | aBlock value: (self rowArray: i)]!
columnsDo: aBlock
	1 to: cols do: [:j | aBlock value: (self columnArray: j)]!
doWithIndexes: aBlock
	"aBlock value: entry value: i value: j"
	1 to: rows do: [:i | 1 to: cols do: [:j | aBlock value: (cells at: (i - 1) * cols + j) value: i value: j]]!
sum
	^cells inject: 0 into: [:a :b | a + b]!
max
	^cells inject: (cells at: 1) into: [:a :b | a max: b]!
min
	^cells inject: (cells at: 1) into: [:a :b | a min: b]! !

!Matrix methodsFor: 'copying and shape'!
copy
	^Matrix rowCount: rows columnCount: cols cells: cells copy!
collect: aBlock
	"a new matrix with aBlock applied to every entry"
	^Matrix rowCount: rows columnCount: cols cells: (cells collect: aBlock)!
collectWithIndexes: aBlock
	"aBlock value: entry value: i value: j"
	^Matrix rows: rows columns: cols collect: [:i :j | aBlock value: (cells at: (i - 1) * cols + j) value: i value: j]!
with: other collect: aBlock
	| o |
	o := self coerce: other.
	(o rowCount = rows and: [o columnCount = cols]) ifFalse: [^self dimensionMismatch: o for: 'elementwise operation'].
	^Matrix rowCount: rows columnCount: cols cells: (cells with: o cells collect: aBlock)!
dimensionMismatch: other for: aString
	^self fail: aString, ' needs matrices of the same shape, not ', rows printString, ' x ', cols printString,
		' and ', other rowCount printString, ' x ', other columnCount printString!
transposed
	^Matrix rows: cols columns: rows collect: [:i :j | cells at: (j - 1) * cols + i]!
submatrixRows: r1 to: r2 columns: c1 to: c2
	"the block of rows r1 to r2 and columns c1 to c2"
	(r1 >= 1 and: [r2 <= rows and: [r1 <= r2 and: [c1 >= 1 and: [c2 <= cols and: [c1 <= c2]]]]])
		ifFalse: [^self fail: 'that block is outside the matrix'].
	^Matrix rows: r2 - r1 + 1 columns: c2 - c1 + 1 collect: [:i :j | cells at: (r1 + i - 2) * cols + (c1 + j - 1)]!
withoutRow: i column: j
	"the minor: this matrix with row i and column j taken out"
	(rows > 1 and: [cols > 1]) ifFalse: [^self fail: 'nothing would be left'].
	^Matrix rows: rows - 1 columns: cols - 1 collect: [:a :b |
		cells at: ((a < i ifTrue: [a] ifFalse: [a + 1]) - 1) * cols + (b < j ifTrue: [b] ifFalse: [b + 1])]!
rowsAt: anArrayOfIndexes
	"a matrix made of those rows, in that order"
	^Matrix rows: (anArrayOfIndexes asArray collect: [:i | self rowArray: i])!
columnsAt: anArrayOfIndexes
	^Matrix columns: (anArrayOfIndexes asArray collect: [:j | self columnArray: j])!
augment: other
	"this matrix with the columns of other on its right"
	| o |
	o := self coerce: other.
	o rowCount = rows ifFalse: [^self fail: 'augment: needs the same number of rows'].
	^Matrix rows: rows columns: cols + o columnCount collect: [:i :j |
		j <= cols ifTrue: [cells at: (i - 1) * cols + j] ifFalse: [o at: i at: j - cols]]!
stack: other
	"this matrix with the rows of other underneath"
	| o |
	o := self coerce: other.
	o columnCount = cols ifFalse: [^self fail: 'stack: needs the same number of columns'].
	^Matrix rows: rows + o rowCount columns: cols collect: [:i :j |
		i <= rows ifTrue: [cells at: (i - 1) * cols + j] ifFalse: [o at: i - rows at: j]]!
reshapedRows: r columns: c
	"the same entries, row by row, in a different shape"
	r * c = self size ifFalse: [^self fail: 'cannot make ', self size printString, ' entries into ', r printString, ' x ', c printString].
	^Matrix rowCount: r columnCount: c cells: cells copy!
swapRows: i with: j
	"a copy with two rows exchanged"
	| w t |
	w := self workRows.
	t := w at: i. w at: i put: (w at: j). w at: j put: t.
	^self fromWork: w!
scaleRow: i by: k
	"a copy with row i multiplied by k"
	| w |
	w := self workRows.
	w at: i put: ((w at: i) collect: [:x | x * k]).
	^self fromWork: w!
addRow: i times: k to: j
	"a copy with k times row i added to row j"
	| w |
	w := self workRows.
	w at: j put: ((w at: j) with: (w at: i) collect: [:a :b | a + (k * b)]).
	^self fromWork: w!
roundedTo: digits
	"every entry as a Float rounded to that many decimal places (negative digits round to tens ...)"
	| unit |
	unit := 10 raisedTo: digits abs.
	^self collect: [:x |
		digits >= 0
			ifTrue: [(x * unit) rounded / unit asFloat]
			ifFalse: [((x / unit) rounded * unit) asFloat]]!
asExact
	"every Float entry as the exact Fraction it holds"
	^self collect: [:x | x isFloat ifTrue: [x asExactFraction] ifFalse: [x]]! !

!Matrix methodsFor: 'comparing'!
= other
	^(other isKindOf: Matrix) and: [rows = other rowCount and: [cols = other columnCount and: [cells = other cells]]]!
hash
	^(rows * 31 + cols) bitXor: cells hash!
isCloseTo: other
	^self isCloseTo: other within: (self maxAbs max: other maxAbs) * Matrix tolerance * 1000!
isCloseTo: other within: eps
	"true when the matrices have the same shape and no two corresponding entries differ by more than eps"
	| o |
	o := self coerce: other.
	(o rowCount = rows and: [o columnCount = cols]) ifFalse: [^false].
	1 to: cells size do: [:k | ((cells at: k) - (o cells at: k)) abs > eps ifTrue: [^false]].
	^true! !

!Matrix methodsFor: 'printing'!
printOn: aStream
	"on one line:  Matrix(1 2; 3 4)  (Floats are shown to six places)"
	aStream nextPutAll: 'Matrix('.
	1 to: rows do: [:i |
		i > 1 ifTrue: [aStream nextPutAll: '; '].
		1 to: cols do: [:j |
			j > 1 ifTrue: [aStream space].
			aStream nextPutAll: (MatrixFormat number: (cells at: (i - 1) * cols + j))]].
	aStream nextPut: $)!
displayString
	^self displayString: 4!
displayString: digits
	"the matrix as lines of text with the columns lined up; Floats are rounded to that many decimals"
	| strs widths out |
	strs := cells collect: [:x | MatrixFormat number: x digits: digits].
	widths := (1 to: cols) asArray collect: [:j |
		(1 to: rows) inject: 0 into: [:m :i | m max: (strs at: (i - 1) * cols + j) size]].
	out := WriteStream on: String new.
	1 to: rows do: [:i |
		i > 1 ifTrue: [out nl].
		out nextPutAll: '[ '.
		1 to: cols do: [:j |
			j > 1 ifTrue: [out nextPutAll: '  '].
			out nextPutAll: (MatrixFormat padLeft: (strs at: (i - 1) * cols + j) to: (widths at: j))].
		out nextPutAll: ' ]'].
	^out contents!
display
	"print the aligned text of the matrix on the Transcript"
	Transcript show: self displayString; cr!
printString: digits
	^self displayString: digits! !
