"Matrix: arithmetic, norms and vectors."

!Matrix methodsFor: 'arithmetic'!
+ other
	"a matrix or a number (added to every entry)"
	other isNumber ifTrue: [^self collect: [:x | x + other]].
	^self with: other collect: [:a :b | a + b]!
- other
	other isNumber ifTrue: [^self collect: [:x | x - other]].
	^self with: other collect: [:a :b | a - b]!
* other
	"matrix product, or every entry times a number.  (A number on the left,  2 * m,  is not understood: write m * 2.)"
	| o flat k s |
	other isNumber ifTrue: [^self collect: [:x | x * other]].
	o := self coerce: other.
	cols = o rowCount ifFalse: [^self fail: 'cannot multiply a ', rows printString, ' x ', cols printString,
		' matrix by a ', o rowCount printString, ' x ', o columnCount printString, ' one'].
	flat := Array new: rows * o columnCount.
	k := 0.
	1 to: rows do: [:i |
		1 to: o columnCount do: [:j |
			s := 0.
			1 to: cols do: [:t | s := s + ((cells at: (i - 1) * cols + t) * (o cells at: (t - 1) * o columnCount + j))].
			k := k + 1.
			flat at: k put: s]].
	^Matrix rowCount: rows columnCount: o columnCount cells: flat!
/ aNumber
	"every entry divided by a number"
	aNumber isNumber ifFalse: [^self fail: 'a matrix can be divided only by a number; for A inverse * B write A solve: B'].
	aNumber = 0 ifTrue: [^self fail: 'division by zero'].
	^self collect: [:x | x / aNumber]!
scaledBy: aNumber
	^self collect: [:x | x * aNumber]!
negated
	^self collect: [:x | x negated]!
hadamard: other
	"the entry by entry product"
	^self with: other collect: [:a :b | a * b]!
dividedElementwiseBy: other
	^self with: other collect: [:a :b | a / b]!
kronecker: other
	"the Kronecker product: a block matrix with a copy of other, scaled, for every entry of this one"
	| o |
	o := self coerce: other.
	^Matrix rows: rows * o rowCount columns: cols * o columnCount collect: [:i :j |
		(cells at: ((i - 1) // o rowCount) * cols + ((j - 1) // o columnCount) + 1)
			* (o at: (i - 1) \\ o rowCount + 1 at: (j - 1) \\ o columnCount + 1)]!
raisedTo: n
	"an integer power by repeated squaring; a negative power uses the inverse"
	| result base e |
	self requireSquare: 'a power'.
	n isInteger ifFalse: [^self fail: 'a matrix can be raised only to an integer power'].
	n < 0 ifTrue: [^self inverse raisedTo: n negated].
	result := Matrix identity: rows.
	base := self.
	e := n.
	[e > 0] whileTrue: [
		(e bitAnd: 1) = 1 ifTrue: [result := result * base].
		e := e bitShift: -1.
		e > 0 ifTrue: [base := base * base]].
	^result!
squared
	^self * self!
trace
	self requireSquare: 'the trace'.
	^self diagonal inject: 0 into: [:a :b | a + b]! !

!Matrix methodsFor: 'norms'!
norm1
	"the largest column sum of absolute values"
	^(1 to: cols) inject: 0 into: [:m :j | m max: ((self columnArray: j) inject: 0 into: [:a :b | a + b abs])]!
normInf
	"the largest row sum of absolute values"
	^(1 to: rows) inject: 0 into: [:m :i | m max: ((self rowArray: i) inject: 0 into: [:a :b | a + b abs])]!
frobeniusNorm
	"the square root of the sum of the squares of all the entries"
	^(cells inject: 0 into: [:a :b | a + (b * b)]) asFloat sqrt!
norm2
	"the spectral norm: the largest singular value"
	^self singularValues first!
norm
	"the Euclidean length of a vector; the Frobenius norm of a matrix"
	^self frobeniusNorm!
normSquared
	"the sum of the squares of the entries (exact for an exact matrix)"
	^cells inject: 0 into: [:a :b | a + (b * b)]! !

!Matrix methodsFor: 'vectors'!
requireVector: aString
	self isVector ifFalse: [^self fail: aString, ' needs a vector (a matrix with one row or one column)']!
dot: other
	"the dot product of two vectors of the same length (a row and a column vector may be mixed)"
	| a b |
	self requireVector: 'dot:'.
	a := cells.
	b := (self coerce: other) asArray.
	a size = b size ifFalse: [^self fail: 'dot: needs vectors of the same length'].
	^(1 to: a size) inject: 0 into: [:s :i | s + ((a at: i) * (b at: i))]!
cross: other
	"the cross product of two 3-vectors, a column vector"
	| a b |
	self requireVector: 'cross:'.
	a := cells.
	b := (self coerce: other) asArray.
	(a size = 3 and: [b size = 3]) ifFalse: [^self fail: 'cross: needs two vectors of length 3'].
	^Matrix column: (Array
		with: ((a at: 2) * (b at: 3)) - ((a at: 3) * (b at: 2))
		with: ((a at: 3) * (b at: 1)) - ((a at: 1) * (b at: 3))
		with: ((a at: 1) * (b at: 2)) - ((a at: 2) * (b at: 1)))!
outer: other
	"the outer product of two vectors: a matrix with entry (i, j) = a(i) b(j)"
	| a b |
	self requireVector: 'outer:'.
	a := cells.
	b := (self coerce: other) asArray.
	^Matrix rows: a size columns: b size collect: [:i :j | (a at: i) * (b at: j)]!
normalized
	"the vector scaled to length 1 (Floats)"
	| n |
	n := self frobeniusNorm.
	n = 0 ifTrue: [^self fail: 'the zero vector cannot be normalized'].
	^self collect: [:x | x / n]!
projectOnto: other
	"the projection of this vector onto the line through other"
	| o d |
	o := self coerce: other.
	d := o normSquared.
	d = 0 ifTrue: [^self fail: 'cannot project onto the zero vector'].
	^(Matrix column: o asArray) * ((self dot: o) / d)!
angleWith: other
	"the angle between two vectors in radians"
	| o c |
	o := self coerce: other.
	c := ((self dot: o) / (self frobeniusNorm * o frobeniusNorm)) asFloat.
	c >= 1.0 ifTrue: [^0.0].
	c <= -1.0 ifTrue: [^Float pi].
	^c arcCos!
isOrthogonalTo: other
	"true when the dot product is zero (within tolerance for Floats)"
	| d |
	d := self dot: other.
	^d abs <= (Matrix tolerance * 1000 * (self frobeniusNorm * (self coerce: other) frobeniusNorm) max: 0)! !
