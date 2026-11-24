"Matrix: Gaussian elimination and what comes of it - reduced row echelon form, rank, null space, determinant,
inverse, and solving systems of equations."

!Matrix methodsFor: 'elimination'!
eliminate: w rows: m limit: limit log: log
	"reduce w, an Array of m row Arrays, in place to reduced row echelon form, choosing pivots only in the first
	limit columns, and answer the Array of the pivot columns. An exact matrix takes the first non-zero entry of
	a column as pivot, a Float matrix the largest one (and treats anything under the zero threshold as zero).
	If log is a WriteStream every step is written to it, with the matrix after it."
	| r c pivots th exact n p best pv f rowR rowI v t |
	n := (w at: 1) size.
	th := self zeroThreshold.
	exact := self isExact.
	exact ifFalse: [w do: [:row | 1 to: n do: [:j | row at: j put: (row at: j) asFloat]]].
	pivots := OrderedCollection new.
	r := 1. c := 1.
	[c <= limit and: [r <= m]] whileTrue: [
		p := 0. best := th.
		r to: m do: [:i |
			v := ((w at: i) at: c) abs.
			exact
				ifTrue: [(p = 0 and: [v > 0]) ifTrue: [p := i]]
				ifFalse: [v > best ifTrue: [best := v. p := i]]].
		p = 0
			ifTrue: [c := c + 1]
			ifFalse: [
				p ~= r ifTrue: [
					t := w at: r. w at: r put: (w at: p). w at: p put: t.
					self logStep: 'swap rows ', r printString, ' and ', p printString work: w rows: m to: log].
				rowR := w at: r.
				pv := rowR at: c.
				pv = 1 ifFalse: [
					1 to: n do: [:j | rowR at: j put: (rowR at: j) / pv].
					self logStep: 'row ', r printString, ' divided by ', (self showNumber: pv) work: w rows: m to: log].
				rowR at: c put: pv / pv.
				1 to: m do: [:i |
					i ~= r ifTrue: [
						rowI := w at: i.
						f := rowI at: c.
						f = 0 ifFalse: [
							1 to: n do: [:j | rowI at: j put: (rowI at: j) - (f * (rowR at: j))].
							rowI at: c put: f - f.
							self logStep: 'row ', i printString, ' minus ', (self showNumber: f), ' times row ', r printString
								work: w rows: m to: log]]].
				pivots add: c.
				r := r + 1. c := c + 1]].
	exact ifFalse: [
		w do: [:row | 1 to: n do: [:j | (row at: j) abs <= th ifTrue: [row at: j put: (row at: j) * 0]]]].
	^pivots asArray!
showNumber: x
	| s |
	s := MatrixFormat number: x digits: 4.
	^(x < 0 or: [x isFraction]) ifTrue: ['(', s, ')'] ifFalse: [s]!
logStep: aString work: w rows: m to: log
	log isNil ifTrue: [^self].
	log nextPutAll: aString; nextPut: $:; nl.
	log nextPutAll: (self fromWork: w rows: m columns: (w at: 1) size) displayString; nl; nl!
reducedRowEchelon
	"the reduced row echelon form: pivots are 1, with zeros above and below them"
	| w |
	w := self workRows.
	self eliminate: w rows: rows limit: cols log: nil.
	^self fromWork: w!
rref
	^self reducedRowEchelon!
pivotColumns
	"the columns that hold a pivot in the echelon form, as an Array"
	| w |
	w := self workRows.
	^self eliminate: w rows: rows limit: cols log: nil!
rank
	^self pivotColumns size!
nullity
	"the dimension of the null space: columns minus rank"
	^cols - self rank!
rrefSteps
	"the Gaussian elimination written out: every row operation, and the matrix after it, as text"
	| w log |
	w := self workRows.
	log := WriteStream on: String new.
	log nextPutAll: 'start:'; nl; nextPutAll: self displayString; nl; nl.
	self eliminate: w rows: rows limit: cols log: log.
	log nextPutAll: 'done: the reduced row echelon form'.
	^log contents!
stepsFor: aString
	"the elimination as text, labelled"
	^aString, (String with: Character lf), self rrefSteps!
nullspaceBasis
	"an Array of column vectors that span the null space (the solutions of A x = 0); empty when only x = 0 solves it"
	| w pivots free v one zero |
	w := self workRows.
	pivots := self eliminate: w rows: rows limit: cols log: nil.
	free := (1 to: cols) asArray reject: [:j | pivots includes: j].
	one := self isExact ifTrue: [1] ifFalse: [1.0].
	zero := one - one.
	^free collect: [:f |
		v := Array new: cols withAll: zero.
		v at: f put: one.
		pivots doWithIndex: [:pc :k | v at: pc put: ((w at: k) at: f) negated].
		Matrix column: v]!
leftNullspaceBasis
	"the null space of the transpose"
	^self transposed nullspaceBasis!
columnSpaceBasis
	"an Array of columns of this matrix that span its column space (the pivot columns)"
	^self pivotColumns collect: [:j | self column: j]!
rowSpaceBasis
	"an Array of row vectors that span the row space (the non-zero rows of the echelon form)"
	| r |
	r := self reducedRowEchelon.
	^(1 to: self rank) asArray collect: [:i | r row: i]!
isInvertible
	^rows = cols and: [self rank = rows]!
isSingular
	^self isInvertible not! !

!Matrix methodsFor: 'determinant'!
determinant
	"exact (fraction-free elimination) for an exact matrix, by LU decomposition for a Float one"
	self requireSquare: 'the determinant'.
	self isExact ifTrue: [^self bareissDeterminant].
	^self lu determinant!
det
	^self determinant!
bareissDeterminant
	| w n sign prev p t |
	n := rows.
	w := self workRows.
	sign := 1. prev := 1.
	1 to: n - 1 do: [:k |
		p := (k to: n) asArray detect: [:i | ((w at: i) at: k) ~= 0] ifNone: [0].
		p = 0 ifTrue: [^0].
		p ~= k ifTrue: [
			t := w at: k. w at: k put: (w at: p). w at: p put: t.
			sign := sign negated].
		k + 1 to: n do: [:i |
			k + 1 to: n do: [:j |
				(w at: i) at: j put:
					((((w at: i) at: j) * ((w at: k) at: k)) - (((w at: i) at: k) * ((w at: k) at: j))) / prev]].
		prev := (w at: k) at: k].
	^sign * ((w at: n) at: n)!
minorAt: i at: j
	"the determinant of the matrix without row i and column j"
	rows = 1 ifTrue: [^1].
	^(self withoutRow: i column: j) determinant!
cofactorAt: i at: j
	^((i + j) even ifTrue: [1] ifFalse: [-1]) * (self minorAt: i at: j)!
cofactorMatrix
	self requireSquare: 'the cofactor matrix'.
	^Matrix rows: rows columns: cols collect: [:i :j | self cofactorAt: i at: j]!
adjugate
	"the transpose of the cofactor matrix: A * adjugate = determinant * I"
	^self cofactorMatrix transposed! !

!Matrix methodsFor: 'solving'!
inverse
	"the inverse (exact for an exact matrix); a MatrixError if the matrix is singular"
	self requireSquare: 'the inverse'.
	^self lu solve: (Matrix identity: rows)!
solve: b
	"the x that solves  self * x = b, for a square non-singular matrix. b is a matrix (one column per right
	hand side) or an Array, taken as one column. Exact in, exact out."
	| o |
	self requireSquare: 'solve:'.
	o := self coerce: b.
	o rowCount = rows ifFalse: [^self fail: 'the right hand side has ', o rowCount printString, ' rows, the matrix has ', rows printString].
	^self lu solve: o!
solveGeneral: b
	"all the solutions of  self * x = b (one right hand side), for any shape: an Array with a particular solution
	(a column vector) and the Array of null space vectors that can be added to it in any multiple; nil when the
	system has no solution"
	| o aug w pivots x allZero zero |
	o := self coerce: b.
	(o rowCount = rows and: [o columnCount = 1]) ifFalse: [^self fail: 'solveGeneral: needs one right hand side with ', rows printString, ' entries'].
	aug := self augment: o.
	w := aug workRows.
	pivots := aug eliminate: w rows: rows limit: cols log: nil.
	1 to: rows do: [:i |
		allZero := true.
		1 to: cols do: [:j | ((w at: i) at: j) ~= 0 ifTrue: [allZero := false]].
		(allZero and: [((w at: i) at: cols + 1) ~= 0]) ifTrue: [^nil]].
	zero := aug isExact ifTrue: [0] ifFalse: [0.0].
	x := Array new: cols withAll: zero.
	pivots doWithIndex: [:pc :k | x at: pc put: ((w at: k) at: cols + 1)].
	^Array with: (Matrix column: x) with: self nullspaceBasis!
isConsistent: b
	"does  self * x = b  have a solution?"
	^(self solveGeneral: b) notNil!
leastSquares: b
	"the x that minimises the length of  self * x - b  (a tall matrix with independent columns), by QR decomposition"
	^self qr leastSquares: (self coerce: b)!
normalEquations: b
	"the least squares solution by solving  A^T A x = A^T b : exact for an exact matrix, but it squares the
	condition number, so with Floats QR (leastSquares:) is more accurate"
	| t |
	t := self transposed.
	^(t * self) solve: t * (self coerce: b)!
minimumNormSolution: b
	"of all the solutions (or all the least squares solutions) the one of smallest length, from the pseudoinverse"
	^self pseudoinverse * (self coerce: b)!
cramer: b
	"solve a small square system by Cramer's rule (to see the rule; elimination is much faster)"
	| o d |
	self requireSquare: 'cramer:'.
	o := self coerce: b.
	d := self determinant.
	d = 0 ifTrue: [^self fail: 'the matrix is singular'].
	^Matrix column: ((1 to: cols) asArray collect: [:j |
		| t |
		t := self copy.
		1 to: rows do: [:i | t at: i at: j put: (o at: i at: 1)].
		t determinant / d])! !
