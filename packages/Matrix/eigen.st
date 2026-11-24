"Matrix: eigenvalues and eigenvectors, the characteristic polynomial, matrix functions, and some applications
(Markov chains, PageRank, covariance, least squares fits, definiteness)."

!Matrix methodsFor: 'eigenvalues'!
jacobiEigen
	"the eigenvalues and eigenvectors of a symmetric matrix by cyclic Jacobi rotations: a MatrixEigen with the
	values largest first and unit vectors, each with its first significant component positive"
	| a v n sweep off p q apq theta t c s app aqq arp arq vrp vrq scale vals order vecs |
	self requireSquare: 'eigenvalues'.
	n := rows.
	a := self floatWork.
	v := (1 to: n) asArray collect: [:i | (1 to: n) asArray collect: [:j | i = j ifTrue: [1.0] ifFalse: [0.0]]].
	scale := self frobeniusNorm.
	sweep := 0.
	[sweep := sweep + 1.
	off := 0.0.
	1 to: n do: [:i | i + 1 to: n do: [:j | off := off + (((a at: i) at: j) * ((a at: i) at: j))]].
	off sqrt > (1.0e-15 * scale) and: [sweep <= 100]] whileTrue: [
		1 to: n - 1 do: [:pp |
			pp + 1 to: n do: [:qq |
				p := pp. q := qq.
				apq := (a at: p) at: q.
				apq abs > 1.0e-300 ifTrue: [
					app := (a at: p) at: p. aqq := (a at: q) at: q.
					theta := (aqq - app) / (2.0 * apq).
					t := 1.0 / (theta abs + ((theta * theta) + 1.0) sqrt).
					theta < 0 ifTrue: [t := t negated].
					c := 1.0 / ((t * t) + 1.0) sqrt.
					s := t * c.
					(a at: p) at: p put: app - (t * apq).
					(a at: q) at: q put: aqq + (t * apq).
					(a at: p) at: q put: 0.0. (a at: q) at: p put: 0.0.
					1 to: n do: [:r |
						(r ~= p and: [r ~= q]) ifTrue: [
							arp := (a at: r) at: p. arq := (a at: r) at: q.
							(a at: r) at: p put: (c * arp) - (s * arq).
							(a at: p) at: r put: (c * arp) - (s * arq).
							(a at: r) at: q put: (s * arp) + (c * arq).
							(a at: q) at: r put: (s * arp) + (c * arq)]].
					1 to: n do: [:r |
						vrp := (v at: r) at: p. vrq := (v at: r) at: q.
						(v at: r) at: p put: (c * vrp) - (s * vrq).
						(v at: r) at: q put: (s * vrp) + (c * vrq)]]]]].
	vals := (1 to: n) asArray collect: [:i | (a at: i) at: i].
	order := ((1 to: n) asArray asSortedCollection: [:x :y | (vals at: x) >= (vals at: y)]) asArray.
	vecs := order collect: [:k | self normalSign: ((1 to: n) asArray collect: [:r | (v at: r) at: k])].
	^MatrixEigen matrix: self values: (order collect: [:k | vals at: k]) vectors: (Matrix columns: vecs)!
normalSign: anArray
	"the vector, negated if its first significant component is negative"
	| first |
	first := anArray detect: [:x | x abs > 1.0e-9] ifNone: [0].
	^first < 0 ifTrue: [anArray collect: [:x | x negated]] ifFalse: [anArray]!
hessenbergForm
	"an upper Hessenberg matrix (zeros below the first subdiagonal) with the same eigenvalues, by Householder
	similarity transformations"
	| a n normx alpha v vn2 s |
	self requireSquare: 'the Hessenberg form'.
	n := rows.
	a := self floatWork.
	1 to: n - 2 do: [:k |
		normx := 0.0.
		k + 1 to: n do: [:i | normx := normx + (((a at: i) at: k) * ((a at: i) at: k))].
		normx := normx sqrt.
		normx > 0.0 ifTrue: [
			alpha := ((a at: k + 1) at: k) > 0 ifTrue: [normx negated] ifFalse: [normx].
			v := Array new: n withAll: 0.0.
			k + 1 to: n do: [:i | v at: i put: ((a at: i) at: k)].
			v at: k + 1 put: (v at: k + 1) - alpha.
			vn2 := 0.0.
			k + 1 to: n do: [:i | vn2 := vn2 + ((v at: i) * (v at: i))].
			vn2 > 0.0 ifTrue: [
				1 to: n do: [:j |
					s := 0.0.
					k + 1 to: n do: [:i | s := s + ((v at: i) * ((a at: i) at: j))].
					s := 2.0 * s / vn2.
					k + 1 to: n do: [:i | (a at: i) at: j put: ((a at: i) at: j) - (s * (v at: i))]].
				1 to: n do: [:i |
					s := 0.0.
					k + 1 to: n do: [:j | s := s + (((a at: i) at: j) * (v at: j))].
					s := 2.0 * s / vn2.
					k + 1 to: n do: [:j | (a at: i) at: j put: ((a at: i) at: j) - (s * (v at: j))]]]]].
	1 to: n do: [:i | 1 to: i - 2 do: [:j | (a at: i) at: j put: 0.0]].
	^self fromWork: a!
blockEigenvaluesP: p q: q r: r s: s
	"the two eigenvalues of the 2 x 2 matrix with rows p q and r s"
	| mean disc |
	mean := (p + s) / 2.0.
	disc := (((p - s) / 2.0) * ((p - s) / 2.0)) + (q * r).
	disc >= 0.0
		ifTrue: [^Array with: mean + disc sqrt with: mean - disc sqrt]
		ifFalse: [^Array with: (MatrixComplex re: mean im: disc negated sqrt) with: (MatrixComplex re: mean im: disc negated sqrt negated)]!
generalEigenvalues
	"the eigenvalues of a real square matrix (symmetric or not) by the shifted QR algorithm on the Hessenberg form;
	complex ones come as MatrixComplex conjugate pairs"
	| a m vals its sub scale eps t d w ident m2 qq sorted |
	a := self hessenbergForm.
	m := rows.
	vals := OrderedCollection new.
	its := 0.
	eps := 1.0e-14.
	[m > 0] whileTrue: [
		m = 1
			ifTrue: [vals add: (a at: 1 at: 1). m := 0]
			ifFalse: [
				sub := (a at: m at: m - 1) abs.
				scale := (a at: m at: m) abs + (a at: m - 1 at: m - 1) abs.
				scale = 0.0 ifTrue: [scale := a frobeniusNorm].
				sub <= (eps * scale)
					ifTrue: [
						vals add: (a at: m at: m).
						m := m - 1. its := 0.
						a := a submatrixRows: 1 to: m columns: 1 to: m]
					ifFalse: [
						(m = 2 or: [(a at: m - 1 at: m - 2) abs <= (eps * ((a at: m - 1 at: m - 1) abs + (a at: m - 2 at: m - 2) abs))])
							ifTrue: [
								vals addAll: (self blockEigenvaluesP: (a at: m - 1 at: m - 1) q: (a at: m - 1 at: m)
									r: (a at: m at: m - 1) s: (a at: m at: m)).
								m := m - 2. its := 0.
								m > 0 ifTrue: [a := a submatrixRows: 1 to: m columns: 1 to: m]]
							ifFalse: [
								its := its + 1.
								its > 500 ifTrue: [^self fail: 'the eigenvalue iteration did not converge'].
								t := (a at: m - 1 at: m - 1) + (a at: m at: m).
								d := ((a at: m - 1 at: m - 1) * (a at: m at: m)) - ((a at: m - 1 at: m) * (a at: m at: m - 1)).
								its \\ 11 = 10 ifTrue: [
									w := (a at: m at: m - 1) abs + (a at: m - 1 at: m - 2) abs.
									t := 1.5 * w. d := 0.5625 * w * w].
								ident := Matrix identity: m.
								m2 := ((a * a) - (a * t)) + (ident * d).
								qq := m2 qr q.
								a := qq transposed * a * qq.
								a := self cleanBelowSubdiagonal: a]]]].
	sorted := vals asArray asSortedCollection: [:x :y | self eigenvalue: x precedes: y].
	^sorted asArray!
cleanBelowSubdiagonal: aMatrix
	^aMatrix collectWithIndexes: [:x :i :j | i > (j + 1) ifTrue: [0.0] ifFalse: [x]]!
eigenvalue: x precedes: y
	| rx ry ix iy |
	rx := x isNumber ifTrue: [x] ifFalse: [x re].
	ry := y isNumber ifTrue: [y] ifFalse: [y re].
	ix := x isNumber ifTrue: [0] ifFalse: [x im].
	iy := y isNumber ifTrue: [0] ifFalse: [y im].
	(rx - ry) abs > (1.0e-9 * ((rx abs max: ry abs) max: 1.0)) ifTrue: [^rx > ry].
	^ix >= iy!
eigenvalues
	"the eigenvalues as an Array, largest real part first: Floats, or MatrixComplex numbers where the matrix has
	complex ones. A symmetric matrix uses Jacobi's method (always real); any other the QR algorithm."
	self requireSquare: 'eigenvalues'.
	rows = 1 ifTrue: [^Array with: (cells at: 1) asFloat].
	self isSymmetric ifTrue: [^self jacobiEigen values].
	^self generalEigenvalues!
eigenvaluesRoundedTo: digits
	"the eigenvalues rounded to that many decimals, to hide the noise in the last places"
	^self eigenvalues collect: [:x |
		x isNumber
			ifTrue: [self roundNumber: x to: digits]
			ifFalse: [MatrixComplex re: (self roundNumber: x re to: digits) im: (self roundNumber: x im to: digits)]]!
roundNumber: x to: digits
	| unit |
	unit := 10 raisedTo: digits.
	^(x * unit) rounded / unit asFloat!
eigenvectorFor: lambda
	"a unit eigenvector for the real eigenvalue lambda (inverse iteration), a column vector"
	| n shifted lu x delta scale tries |
	self requireSquare: 'an eigenvector'.
	n := rows.
	scale := (lambda abs max: self maxAbs) max: 1.0.
	delta := 1.0e-8 * scale.
	tries := 0.
	[shifted := self asFloats - ((Matrix identity: n) * (lambda + delta)).
	lu := shifted lu.
	lu isSingular and: [tries < 4]] whileTrue: [delta := delta * 100. tries := tries + 1].
	lu isSingular ifTrue: [^self fail: 'could not find an eigenvector'].
	x := Matrix column: ((1 to: n) asArray collect: [:i | 1.0 + (i * 0.1)]).
	1 to: 4 do: [:it |
		x := lu solve: x.
		x := x / x frobeniusNorm].
	^Matrix column: (self normalSign: x asArray)!
eigenspaceFor: lambda
	"an Array of column vectors spanning the eigenspace of the eigenvalue lambda, exact when the matrix and lambda
	are exact: the null space of A - lambda I"
	self requireSquare: 'an eigenspace'.
	^(self - ((Matrix identity: rows) * lambda)) nullspaceBasis!
isEigenvalue: lambda
	^(self - ((Matrix identity: rows) * lambda)) determinant = 0!
eigen
	"a MatrixEigen with the eigenvalues and, when the matrix is diagonalizable with real eigenvalues, a matrix of
	unit eigenvectors for them: symmetric matrices get orthonormal ones. Complex eigenvalues, or a defective matrix,
	leave vectors nil."
	| vals n vecs cluster groups svd ident k nullVectors thr |
	self requireSquare: 'eigen'.
	(self isSymmetric or: [rows = 1]) ifTrue: [^rows = 1
		ifTrue: [MatrixEigen matrix: self values: (Array with: (cells at: 1) asFloat) vectors: (Matrix rows: 1 columns: 1 fill: 1.0)]
		ifFalse: [self jacobiEigen]].
	vals := self generalEigenvalues.
	(vals anySatisfy: [:x | x isNumber not]) ifTrue: [^MatrixEigen matrix: self values: vals vectors: nil].
	n := rows.
	ident := Matrix identity: n.
	vecs := OrderedCollection new.
	k := 1.
	[k <= n] whileTrue: [
		| lambda count |
		lambda := vals at: k.
		count := 1.
		[k + count <= n and: [((vals at: k + count) - lambda) abs <= (1.0e-6 * (lambda abs max: 1.0))]] whileTrue: [count := count + 1].
		count = 1
			ifTrue: [vecs add: (self eigenvectorFor: lambda) asArray]
			ifFalse: [
				svd := (self asFloats - (ident * lambda)) svd.
				thr := svd sigma first * 1.0e-7.
				nullVectors := OrderedCollection new.
				1 to: n do: [:c | (svd sigma at: c) <= thr ifTrue: [nullVectors add: (svd v columnArray: c)]].
				nullVectors size < count ifTrue: [^MatrixEigen matrix: self values: vals vectors: nil].
				1 to: count do: [:c | vecs add: (self normalSign: (nullVectors at: c))]].
		k := k + count].
	^MatrixEigen matrix: self values: vals vectors: (Matrix columns: vecs asArray)!
isDiagonalizable
	"does the matrix have a full set of real eigenvectors?"
	^self eigen isDiagonalizable!
diagonalize
	"same as eigen: the matrix V of eigenvectors and the eigenvalues, with  A = V D V^-1"
	^self eigen!
spectralRadius
	"the largest absolute value of an eigenvalue"
	^(self eigenvalues collect: [:x | x abs]) inject: 0 into: [:a :b | a max: b]!
powerIteration: steps
	"an approximation of the dominant eigenvalue and its unit eigenvector, after that many steps of the power
	method: an Array  #(eigenvalue vector)"
	| x y lambda |
	self requireSquare: 'power iteration'.
	x := Matrix column: ((1 to: rows) asArray collect: [:i | 1.0]).
	x := x / x frobeniusNorm.
	lambda := 0.0.
	steps timesRepeat: [
		y := self * x.
		lambda := x dot: y.
		y frobeniusNorm = 0.0 ifTrue: [^Array with: 0.0 with: x].
		x := y / y frobeniusNorm].
	^Array with: lambda with: x! !

!Matrix methodsFor: 'polynomials and functions'!
characteristicPolynomial
	"the coefficients, constant term first, of  det(x I - A) , exact for an exact matrix (Faddeev-LeVerrier)"
	| n c m ident |
	self requireSquare: 'the characteristic polynomial'.
	n := rows.
	c := Array new: n + 1 withAll: 0.
	c at: n + 1 put: 1.
	m := Matrix zeros: n.
	ident := Matrix identity: n.
	1 to: n do: [:k |
		m := (self * m) + (ident * (c at: n - k + 2)).
		c at: n - k + 1 put: (self * m) trace negated / k].
	^c!
polynomialString: coefficients
	"coefficients, constant term first, written as  x^2 - 5x + 6"
	| out first |
	out := WriteStream on: String new.
	first := true.
	coefficients size to: 1 by: -1 do: [:i |
		| c e mag |
		c := coefficients at: i.
		e := i - 1.
		c = 0 ifFalse: [
			mag := c abs.
			first
				ifTrue: [c < 0 ifTrue: [out nextPutAll: '-']]
				ifFalse: [out nextPutAll: (c < 0 ifTrue: [' - '] ifFalse: [' + '])].
			(mag = 1 and: [e > 0]) ifFalse: [
				mag isFraction
					ifTrue: [out nextPut: $(; nextPutAll: (MatrixFormat number: mag digits: 4); nextPut: $)]
					ifFalse: [out nextPutAll: (MatrixFormat number: mag digits: 4)]].
			e > 0 ifTrue: [out nextPut: $x].
			e > 1 ifTrue: [out nextPut: $^; print: e].
			first := false]].
	first ifTrue: [^'0'].
	^out contents!
characteristicPolynomialString
	^self polynomialString: self characteristicPolynomial!
polynomialValue: coefficients
	"the matrix polynomial  c0 I + c1 A + c2 A^2 ...  (constant term first), by Horner's rule: with the
	characteristic polynomial it is the zero matrix (Cayley-Hamilton)"
	| result ident |
	self requireSquare: 'a polynomial of a matrix'.
	ident := Matrix identity: rows.
	result := Matrix zeros: rows.
	coefficients size to: 1 by: -1 do: [:i |
		result := (result * self) + (ident * (coefficients at: i))].
	^result!
exponential
	"the matrix exponential e^A, in Floats, by scaling and squaring and the Taylor series"
	| a nrm s term sum ident |
	self requireSquare: 'the matrix exponential'.
	a := self asFloats.
	nrm := a normInf.
	s := 0.
	[nrm > 0.5] whileTrue: [nrm := nrm / 2.0. s := s + 1].
	a := a / (2 raisedTo: s) asFloat.
	ident := (Matrix identity: rows) asFloats.
	term := ident. sum := ident.
	1 to: 24 do: [:k | term := (term * a) / k asFloat. sum := sum + term].
	s timesRepeat: [sum := sum * sum].
	^sum!
zeroMatrixLike
	^Matrix rows: rows columns: cols fill: 0! !

!Matrix methodsFor: 'definiteness'!
isPositiveDefinite
	"symmetric with every eigenvalue positive: exact (all leading minors positive) for an exact matrix"
	| k |
	self isSymmetric ifFalse: [^false].
	self isExact ifTrue: [
		1 to: rows do: [:n | (self submatrixRows: 1 to: n columns: 1 to: n) determinant > 0 ifFalse: [^false]].
		^true].
	^[self cholesky. true] on: MatrixError do: [:e | false]!
definiteness
	"#positiveDefinite, #positiveSemidefinite, #negativeDefinite, #negativeSemidefinite, #indefinite, or #notSymmetric"
	| ev th |
	self isSymmetric ifFalse: [^#notSymmetric].
	ev := self eigenvalues.
	th := (ev inject: 0 into: [:a :b | a max: b abs]) * 1.0e-9.
	(ev allSatisfy: [:x | x > th]) ifTrue: [^#positiveDefinite].
	(ev allSatisfy: [:x | x < th negated]) ifTrue: [^#negativeDefinite].
	(ev allSatisfy: [:x | x >= th negated]) ifTrue: [^#positiveSemidefinite].
	(ev allSatisfy: [:x | x <= th]) ifTrue: [^#negativeSemidefinite].
	^#indefinite! !

!Matrix methodsFor: 'testing the shape'!
isDiagonal
	1 to: rows do: [:i | 1 to: cols do: [:j |
		i ~= j ifTrue: [(self isNegligible: (cells at: (i - 1) * cols + j)) ifFalse: [^false]]]].
	^true!
isUpperTriangular
	1 to: rows do: [:i | 1 to: (i - 1 min: cols) do: [:j | (self isNegligible: (cells at: (i - 1) * cols + j)) ifFalse: [^false]]].
	^true!
isLowerTriangular
	1 to: rows do: [:i | i + 1 to: cols do: [:j | (self isNegligible: (cells at: (i - 1) * cols + j)) ifFalse: [^false]]].
	^true!
isIdentity
	rows = cols ifFalse: [^false].
	1 to: rows do: [:i | 1 to: cols do: [:j |
		| x |
		x := cells at: (i - 1) * cols + j.
		i = j
			ifTrue: [(x - 1) abs <= self zeroThreshold ifFalse: [^false]]
			ifFalse: [(self isNegligible: x) ifFalse: [^false]]]].
	^true!
isZeroMatrix
	^cells allSatisfy: [:x | self isNegligible: x]! !

!Matrix methodsFor: 'applications'!
isRowStochastic
	"non-negative entries and every row summing to 1"
	^(cells allSatisfy: [:x | x >= 0]) and: [(1 to: rows) allSatisfy: [:i | ((self rowArray: i) inject: 0 into: [:a :b | a + b]) = 1]]!
steadyState
	"for a row stochastic transition matrix P (rows sum to 1) the probability vector pi with  pi P = pi : a column
	vector, exact for an exact matrix; a MatrixError if it is not unique"
	| a sol |
	self requireSquare: 'the steady state'.
	a := self transposed - (Matrix identity: rows).
	a := (a submatrixRows: 1 to: rows - 1 columns: 1 to: cols) stack: (Matrix rows: 1 columns: cols fill: 1).
	sol := (Matrix rows: rows columns: 1 collect: [:i :j | i = rows ifTrue: [1] ifFalse: [0]]).
	a rank = cols ifFalse: [^self fail: 'the steady state is not unique'].
	^a solve: sol!
pageRank: damping
	"treat this matrix as an adjacency matrix (entry (i, j) non-zero: page i links to page j) and answer the PageRank
	vector, a column of Floats summing to 1, by power iteration; a page with no links is taken to link to all pages"
	| n p g x |
	self requireSquare: 'PageRank'.
	n := rows.
	p := Matrix rows: n columns: n collect: [:i :j |
		| out |
		out := (self rowArray: i) inject: 0 into: [:a :b | b ~= 0 ifTrue: [a + 1] ifFalse: [a]].
		out = 0 ifTrue: [1.0 / n] ifFalse: [(self at: i at: j) ~= 0 ifTrue: [1.0 / out] ifFalse: [0.0]]].
	g := (p * damping asFloat) + ((Matrix rows: n columns: n fill: 1.0 / n) * (1.0 - damping)).
	x := Matrix column: (Array new: n withAll: 1.0 / n).
	200 timesRepeat: [x := g transposed * x].
	^x!
columnMeans
	"a row vector of the mean of each column"
	^Matrix row: ((1 to: cols) asArray collect: [:j | ((self columnArray: j) inject: 0 into: [:a :b | a + b]) / rows])!
centered
	"every column minus its mean (rows are observations, columns are variables)"
	| mu |
	mu := self columnMeans.
	^self collectWithIndexes: [:x :i :j | x - (mu at: 1 at: j)]!
covarianceMatrix
	"the sample covariance matrix of the columns (rows are observations): exact for an exact matrix"
	| c |
	rows > 1 ifFalse: [^self fail: 'covariance needs at least two observations'].
	c := self centered.
	^(c transposed * c) / (rows - 1)!
correlationMatrix
	| cov s |
	cov := self covarianceMatrix.
	s := cov diagonal collect: [:x | x asFloat sqrt].
	^cov collectWithIndexes: [:x :i :j | x / ((s at: i) * (s at: j))]!
principalComponents
	"the eigen decomposition of the covariance matrix: values are the variances along the components"
	^self covarianceMatrix jacobiEigen! !

!Matrix class methodsFor: 'fitting'!
fitPolynomialDegree: d xs: xs ys: ys
	"the coefficients, constant term first, of the least squares polynomial of degree d through the points (QR)"
	| a |
	a := self vandermonde: xs degree: d.
	^(a leastSquares: (Matrix column: ys)) asArray!
fitPolynomialDegree: d xs: xs ys: ys exactly: aBoolean
	"with true, the exact normal equations (for exact data the exact answer)"
	| a |
	a := self vandermonde: xs degree: d.
	^(a normalEquations: (Matrix column: ys)) asArray! !
