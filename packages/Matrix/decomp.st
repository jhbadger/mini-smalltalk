"Matrix: the decompositions - LU, QR, Cholesky, Gram-Schmidt, the SVD, the pseudoinverse - and the little classes
that hold their parts."

!MatrixLU class methodsFor: 'instance creation'!
matrix: a lower: l upper: u permutation: p sign: s singular: flag
	^self basicNew setMatrix: a lower: l upper: u permutation: p sign: s singular: flag! !

!MatrixLU methodsFor: 'private'!
setMatrix: a lower: l upper: u permutation: p sign: s singular: flag
	matrix := a. lower := l. upper := u. permutation := p. sign := s. singular := flag! !

!MatrixLU methodsFor: 'accessing'!
matrix
	^matrix!
lower
	"L: unit lower triangular"
	^lower!
upper
	"U: upper triangular"
	^upper!
permutation
	"the Array p such that row i of P A is row (p at: i) of A"
	^permutation!
permutationMatrix
	"P, with  P A = L U"
	^Matrix permutation: permutation!
sign
	"+1 or -1: the sign of the permutation"
	^sign!
isSingular
	^singular!
determinant
	| d |
	singular ifTrue: [^0].
	d := sign.
	upper diagonal do: [:x | d := d * x].
	^d!
reconstruct
	"P' L U, which is the original matrix again (to within rounding)"
	^self permutationMatrix transposed * (lower * upper)!
solve: b
	"solve  A x = b  by forward and back substitution (b is a Matrix, one right hand side per column)"
	| n k flat y x s |
	singular ifTrue: [^MatrixError new signal: 'the matrix is singular'].
	n := lower rowCount.
	k := b columnCount.
	flat := Array new: n * k.
	1 to: k do: [:c |
		y := Array new: n.
		1 to: n do: [:i |
			s := b at: (permutation at: i) at: c.
			1 to: i - 1 do: [:j | s := s - ((lower at: i at: j) * (y at: j))].
			y at: i put: s].
		x := Array new: n.
		n to: 1 by: -1 do: [:i |
			s := y at: i.
			i + 1 to: n do: [:j | s := s - ((upper at: i at: j) * (x at: j))].
			x at: i put: s / (upper at: i at: i)].
		1 to: n do: [:i | flat at: (i - 1) * k + c put: (x at: i)]].
	^Matrix rowCount: n columnCount: k cells: flat!
printOn: aStream
	aStream nextPutAll: 'an LU decomposition of a '; print: matrix rowCount; nextPutAll: ' x '; print: matrix columnCount;
		nextPutAll: ' matrix'! !

!MatrixQR class methodsFor: 'instance creation'!
matrix: a q: q r: r
	^self basicNew setMatrix: a q: q r: r! !

!MatrixQR methodsFor: 'accessing'!
setMatrix: a q: aq r: ar
	matrix := a. q := aq. r := ar!
matrix
	^matrix!
q
	"Q: square with orthonormal columns"
	^q!
r
	"R: upper triangular, the same shape as the matrix"
	^r!
reconstruct
	^q * r!
leastSquares: b
	"the x that minimises  |A x - b|, by back substitution in R; the columns of A must be independent"
	| m n qtb th flat x s k |
	m := r rowCount. n := r columnCount.
	m >= n ifFalse: [^MatrixError new signal: 'least squares needs at least as many rows as columns; use minimumNormSolution:'].
	th := r maxAbs * Matrix tolerance * 1000.
	1 to: n do: [:i | (r at: i at: i) abs <= th ifTrue: [^MatrixError new signal: 'the columns are dependent, so there is no single best fit; use minimumNormSolution:']].
	b rowCount = m ifFalse: [^MatrixError new signal: 'the right hand side has the wrong number of rows'].
	qtb := q transposed * b asFloats.
	k := b columnCount.
	flat := Array new: n * k.
	1 to: k do: [:c |
		x := Array new: n.
		n to: 1 by: -1 do: [:i |
			s := qtb at: i at: c.
			i + 1 to: n do: [:j | s := s - ((r at: i at: j) * (x at: j))].
			x at: i put: s / (r at: i at: i)].
		1 to: n do: [:i | flat at: (i - 1) * k + c put: (x at: i)]].
	^Matrix rowCount: n columnCount: k cells: flat!
printOn: aStream
	aStream nextPutAll: 'a QR decomposition of a '; print: matrix rowCount; nextPutAll: ' x '; print: matrix columnCount;
		nextPutAll: ' matrix'! !

!MatrixSVD class methodsFor: 'instance creation'!
matrix: a u: u sigma: s v: v
	^self basicNew setMatrix: a u: u sigma: s v: v! !

!MatrixSVD methodsFor: 'accessing'!
setMatrix: a u: au sigma: s v: av
	matrix := a. u := au. sigma := s. v := av!
matrix
	^matrix!
u
	"U: orthonormal columns (a column is zero where its singular value is zero)"
	^u!
v
	"V: orthogonal"
	^v!
sigma
	"the singular values, largest first, as an Array"
	^sigma!
sigmaMatrix
	"Sigma as a diagonal matrix"
	^Matrix diagonal: sigma!
rank
	"how many singular values are not negligible"
	| th |
	th := (sigma isEmpty ifTrue: [0] ifFalse: [sigma first]) * (matrix rowCount max: matrix columnCount) * 1.0e-12.
	^(sigma select: [:s | s > th]) size!
reconstruct
	"U Sigma V^T"
	^(u * self sigmaMatrix) * v transposed!
approximationOfRank: k
	"the best approximation of the matrix by one of rank k (the sum of the first k terms sigma u v^T)"
	| kk uu vv |
	kk := k min: sigma size.
	uu := u submatrixRows: 1 to: u rowCount columns: 1 to: kk.
	vv := v submatrixRows: 1 to: v rowCount columns: 1 to: kk.
	^(uu * (Matrix diagonal: (sigma copyFrom: 1 to: kk))) * vv transposed!
conditionNumber
	| lo |
	lo := sigma last.
	lo = 0 ifTrue: [^Float infinity].
	^sigma first / lo!
printOn: aStream
	aStream nextPutAll: 'an SVD of a '; print: matrix rowCount; nextPutAll: ' x '; print: matrix columnCount;
		nextPutAll: ' matrix, singular values '.
	(sigma collect: [:s | MatrixFormat number: s digits: 4]) do: [:s | aStream nextPutAll: s] separatedBy: [aStream space]! !

!MatrixEigen class methodsFor: 'instance creation'!
matrix: a values: vals vectors: vecs
	^self basicNew setMatrix: a values: vals vectors: vecs! !

!MatrixEigen methodsFor: 'accessing'!
setMatrix: a values: vals vectors: vecs
	matrix := a. values := vals. vectors := vecs!
matrix
	^matrix!
values
	"the eigenvalues as an Array (Numbers, or MatrixComplex numbers in conjugate pairs)"
	^values!
vectors
	"a matrix whose columns are unit eigenvectors, in the order of the values; nil when the eigenvalues are not all
	real or the matrix is defective (too few eigenvectors)"
	^vectors!
isDiagonalizable
	^vectors notNil!
hasComplexValues
	^values anySatisfy: [:x | x isNumber not]!
vectorAt: i
	"eigenvector i as a column vector"
	vectors isNil ifTrue: [^MatrixError new signal: 'this matrix has no full set of real eigenvectors'].
	^vectors column: i!
valueAt: i
	^values at: i!
diagonal
	"the eigenvalues on the diagonal of a matrix"
	^Matrix diagonal: values!
reconstruct
	"V D V^-1: the original matrix again, to within rounding"
	vectors isNil ifTrue: [^MatrixError new signal: 'this matrix has no full set of real eigenvectors'].
	^vectors * self diagonal * vectors inverse!
residuals
	"for each eigenpair the length of  A v - lambda v : all of them should be tiny"
	^(1 to: values size) asArray collect: [:i |
		| v |
		v := self vectorAt: i.
		((matrix * v) - (v * (values at: i))) frobeniusNorm]!
printOn: aStream
	aStream nextPutAll: 'eigenvalues '.
	values do: [:x |
		aStream nextPutAll: (x isNumber ifTrue: [MatrixFormat number: x digits: 4] ifFalse: [x printStringDigits: 4])]
		separatedBy: [aStream space]! !

!Matrix methodsFor: 'LU and Cholesky'!
lu
	"LU decomposition with row exchanges, P A = L U, of a square matrix: first non-zero pivot for an exact matrix,
	largest pivot (partial pivoting) for a Float one. A singular matrix is decomposed too (U has a zero on its diagonal)."
	| w n perm sign p best th exact f singular v t lower upper zero one |
	self requireSquare: 'LU decomposition'.
	n := rows.
	w := self isExact ifTrue: [self workRows] ifFalse: [self floatWork].
	perm := (1 to: n) asArray.
	sign := 1.
	singular := false.
	th := self zeroThreshold.
	exact := self isExact.
	one := exact ifTrue: [1] ifFalse: [1.0].
	zero := one - one.
	1 to: n do: [:k |
		p := 0. best := th.
		k to: n do: [:i |
			v := ((w at: i) at: k) abs.
			exact
				ifTrue: [(p = 0 and: [v > 0]) ifTrue: [p := i]]
				ifFalse: [v > best ifTrue: [best := v. p := i]]].
		p = 0
			ifTrue: [
				singular := true.
				(w at: k) at: k put: zero.
				k + 1 to: n do: [:i | (w at: i) at: k put: zero]]
			ifFalse: [
				p ~= k ifTrue: [
					t := w at: k. w at: k put: (w at: p). w at: p put: t.
					t := perm at: k. perm at: k put: (perm at: p). perm at: p put: t.
					sign := sign negated].
				k + 1 to: n do: [:i |
					f := ((w at: i) at: k) / ((w at: k) at: k).
					(w at: i) at: k put: f.
					k + 1 to: n do: [:j |
						(w at: i) at: j put: ((w at: i) at: j) - (f * ((w at: k) at: j))]]]].
	lower := Matrix rows: n columns: n collect: [:i :j |
		i = j ifTrue: [one] ifFalse: [i > j ifTrue: [(w at: i) at: j] ifFalse: [zero]]].
	upper := Matrix rows: n columns: n collect: [:i :j | i <= j ifTrue: [(w at: i) at: j] ifFalse: [zero]].
	^MatrixLU matrix: self lower: lower upper: upper permutation: perm sign: sign singular: singular!
exactSqrt: x
	"the square root, exact when x is a perfect square (or a ratio of two)"
	| r n d rn rd |
	x isInteger ifTrue: [
		x < 0 ifTrue: [^x asFloat sqrt].
		r := x asFloat sqrt rounded.
		^r * r = x ifTrue: [r] ifFalse: [x asFloat sqrt]].
	x isFraction ifTrue: [
		rn := self exactSqrt: x numerator.
		rd := self exactSqrt: x denominator.
		^(rn isInteger and: [rd isInteger]) ifTrue: [rn / rd] ifFalse: [x asFloat sqrt]].
	^x sqrt!
isSymmetric
	| th |
	rows = cols ifFalse: [^false].
	th := self zeroThreshold.
	1 to: rows do: [:i | i + 1 to: cols do: [:j |
		((cells at: (i - 1) * cols + j) - (cells at: (j - 1) * cols + i)) abs > th ifTrue: [^false]]].
	^true!
cholesky
	"the lower triangular L with  L L^T = A, for a symmetric positive definite matrix (the square roots stay exact
	where they are perfect squares)"
	| l s n th |
	self requireSquare: 'the Cholesky decomposition'.
	self isSymmetric ifFalse: [^self fail: 'the Cholesky decomposition needs a symmetric matrix'].
	n := rows.
	th := self zeroThreshold.
	l := Matrix zeros: n.
	1 to: n do: [:j |
		s := self at: j at: j.
		1 to: j - 1 do: [:k | s := s - ((l at: j at: k) * (l at: j at: k))].
		s <= th ifTrue: [^self fail: 'the matrix is not positive definite'].
		l at: j at: j put: (self exactSqrt: s).
		j + 1 to: n do: [:i |
			s := self at: i at: j.
			1 to: j - 1 do: [:k | s := s - ((l at: i at: k) * (l at: j at: k))].
			l at: i at: j put: s / (l at: j at: j)]].
	^l! !

!Matrix methodsFor: 'QR and Gram-Schmidt'!
qr
	"QR decomposition by Householder reflections: A = Q R with Q orthogonal (m x m) and R upper triangular (m x n),
	with a non-negative diagonal in R. Answers a MatrixQR."
	| m n a q normx alpha v vn2 s |
	m := rows. n := cols.
	a := self floatWork.
	q := (1 to: m) asArray collect: [:i | (1 to: m) asArray collect: [:j | i = j ifTrue: [1.0] ifFalse: [0.0]]].
	1 to: (m - 1 min: n) do: [:k |
		normx := 0.0.
		k to: m do: [:i | normx := normx + (((a at: i) at: k) * ((a at: i) at: k))].
		normx := normx sqrt.
		normx > 0.0 ifTrue: [
			alpha := ((a at: k) at: k) > 0 ifTrue: [normx negated] ifFalse: [normx].
			v := Array new: m withAll: 0.0.
			k to: m do: [:i | v at: i put: ((a at: i) at: k)].
			v at: k put: (v at: k) - alpha.
			vn2 := 0.0.
			k to: m do: [:i | vn2 := vn2 + ((v at: i) * (v at: i))].
			vn2 > 0.0 ifTrue: [
				k to: n do: [:j |
					s := 0.0.
					k to: m do: [:i | s := s + ((v at: i) * ((a at: i) at: j))].
					s := 2.0 * s / vn2.
					k to: m do: [:i | (a at: i) at: j put: ((a at: i) at: j) - (s * (v at: i))]].
				1 to: m do: [:i |
					s := 0.0.
					k to: m do: [:j | s := s + (((q at: i) at: j) * (v at: j))].
					s := 2.0 * s / vn2.
					k to: m do: [:j | (q at: i) at: j put: ((q at: i) at: j) - (s * (v at: j))]]]]].
	1 to: m do: [:i | 1 to: (i - 1 min: n) do: [:j | (a at: i) at: j put: 0.0]].
	1 to: (m min: n) do: [:k |
		((a at: k) at: k) < 0 ifTrue: [
			k to: n do: [:j | (a at: k) at: j put: ((a at: k) at: j) negated].
			1 to: m do: [:i | (q at: i) at: k put: ((q at: i) at: k) negated]]].
	^MatrixQR matrix: self q: (self fromWork: q rows: m columns: m) r: (self fromWork: a rows: m columns: n)!
gramSchmidt
	"orthonormal vectors (as the columns of a matrix) spanning the same space as the columns of this one; a column
	that depends on the ones before it is left out. Modified Gram-Schmidt, in Floats."
	| basis th v n |
	basis := OrderedCollection new.
	th := self maxAbs * Matrix tolerance * 1000.
	1 to: cols do: [:j |
		v := Matrix column: ((self columnArray: j) collect: [:x | x asFloat]).
		basis do: [:b | v := v - (b * (b dot: v))].
		n := v frobeniusNorm.
		n > th ifTrue: [basis add: (v / n)]].
	basis isEmpty ifTrue: [^self fail: 'every column is zero'].
	^Matrix columns: (basis collect: [:b | b asArray]) asArray!
gramSchmidtUnnormalized
	"orthogonal (not unit length) vectors spanning the column space, exact for an exact matrix: no square roots"
	| basis v |
	basis := OrderedCollection new.
	1 to: cols do: [:j |
		v := Matrix column: (self columnArray: j).
		basis do: [:b | v := v - (b * ((b dot: v) / (b dot: b)))].
		(self isNegligible: v normSquared sqrt) ifFalse: [basis add: v]].
	basis isEmpty ifTrue: [^self fail: 'every column is zero'].
	^Matrix columns: (basis collect: [:b | b asArray]) asArray!
isOrthogonal
	"are the columns orthonormal: Q^T Q = I (to within rounding)?"
	^rows = cols and: [(self transposed * self) isCloseTo: (Matrix identity: rows) within: 1.0e-9]!
isOrthonormalColumns
	^(self transposed * self) isCloseTo: (Matrix identity: cols) within: 1.0e-9! !

!Matrix methodsFor: 'SVD'!
svd
	"the singular value decomposition A = U Sigma V^T by one-sided Jacobi rotations, in Floats. Answers a MatrixSVD
	(thin: U is m x k, V is n x k, with k = the smaller of m and n)."
	| wide a ucols vcols m n sweeps rotated alpha beta gamma zeta t c s up uq vp vq sig order uArr vArr sigmas maxs |
	wide := rows < cols.
	a := wide ifTrue: [self transposed] ifFalse: [self].
	m := a rowCount. n := a columnCount.
	ucols := a asColumnArrays collect: [:col | col collect: [:x | x asFloat]].
	vcols := (1 to: n) asArray collect: [:i | (1 to: n) asArray collect: [:j | i = j ifTrue: [1.0] ifFalse: [0.0]]].
	sweeps := 0.
	[rotated := false. sweeps := sweeps + 1.
	1 to: n - 1 do: [:p |
		p + 1 to: n do: [:q |
			up := ucols at: p. uq := ucols at: q.
			alpha := 0.0. beta := 0.0. gamma := 0.0.
			1 to: m do: [:i |
				alpha := alpha + ((up at: i) * (up at: i)).
				beta := beta + ((uq at: i) * (uq at: i)).
				gamma := gamma + ((up at: i) * (uq at: i))].
			(gamma ~= 0.0 and: [gamma abs > (1.0e-15 * (alpha * beta) sqrt)]) ifTrue: [
				rotated := true.
				zeta := (beta - alpha) / (2.0 * gamma).
				t := 1.0 / (zeta abs + (1.0 + (zeta * zeta)) sqrt).
				zeta < 0 ifTrue: [t := t negated].
				c := 1.0 / (1.0 + (t * t)) sqrt.
				s := c * t.
				1 to: m do: [:i |
					| x y |
					x := up at: i. y := uq at: i.
					up at: i put: (c * x) - (s * y).
					uq at: i put: (s * x) + (c * y)].
				vp := vcols at: p. vq := vcols at: q.
				1 to: n do: [:i |
					| x y |
					x := vp at: i. y := vq at: i.
					vp at: i put: (c * x) - (s * y).
					vq at: i put: (s * x) + (c * y)]]]].
	rotated and: [sweeps < 60]] whileTrue.
	sig := ucols collect: [:col | (col inject: 0.0 into: [:acc :x | acc + (x * x)]) sqrt].
	order := (1 to: n) asArray asSortedCollection: [:x :y | (sig at: x) >= (sig at: y)].
	order := order asArray.
	maxs := sig isEmpty ifTrue: [0.0] ifFalse: [sig inject: 0.0 into: [:acc :x | acc max: x]].
	sigmas := order collect: [:k | sig at: k].
	uArr := order collect: [:k |
		(sig at: k) > (maxs * 1.0e-14)
			ifTrue: [(ucols at: k) collect: [:x | x / (sig at: k)]]
			ifFalse: [Array new: m withAll: 0.0]].
	vArr := order collect: [:k | vcols at: k].
	wide
		ifTrue: [^MatrixSVD matrix: self u: (Matrix columns: vArr) sigma: sigmas v: (Matrix columns: uArr)]
		ifFalse: [^MatrixSVD matrix: self u: (Matrix columns: uArr) sigma: sigmas v: (Matrix columns: vArr)]!
singularValues
	"the singular values, largest first, as an Array of Floats"
	^self svd sigma!
conditionNumber
	"the ratio of the largest to the smallest singular value (infinity for a singular matrix)"
	^self svd conditionNumber!
numericalRank
	"the rank counted from the singular values: how many are not negligible"
	^self svd rank!
pseudoinverse
	"the Moore-Penrose pseudoinverse, which is the inverse for an invertible matrix and gives the minimum norm
	least squares solution otherwise. Exact for an exact matrix (from a full rank factorization A = C R:
	A+ = R^T (R R^T)^-1 (C^T C)^-1 C^T), by the SVD for a Float one."
	| s th inv r c rr piv |
	self isExact ifTrue: [
		piv := self pivotColumns.
		piv isEmpty ifTrue: [^Matrix rows: cols columns: rows fill: 0].
		r := self rank.
		c := self columnsAt: piv.
		rr := self reducedRowEchelon submatrixRows: 1 to: r columns: 1 to: cols.
		^(rr transposed * (rr * rr transposed) inverse) * ((c transposed * c) inverse * c transposed)].
	s := self svd.
	th := s sigma first * (rows max: cols) * 1.0e-12.
	inv := s sigma collect: [:x | x > th ifTrue: [1.0 / x] ifFalse: [0.0]].
	^(s v * (Matrix diagonal: inv)) * s u transposed! !
