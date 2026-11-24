"The Matrix tutorial: vectors and matrices, arithmetic, exact and floating point numbers, determinants, inverses and
solving equations, elimination, rank and the null space, LU, orthogonality and QR, least squares, eigenvalues, symmetric
matrices, the SVD, and applications.  Start it with   MatrixTutorial go"

AbstractTutorial subclass: #MatrixTutorial instanceVariableNames: '' classVariableNames: '' category: 'Matrix'!

!MatrixTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Matrix'!
lessonSelectors
	^#(#welcome #vectors #making #inside #arithmetic #exact
		#determinant #inverse #elimination #rank #lu #qr
		#least #eigen #symmetric #svd #applications #whatnext)! !

!MatrixTutorial class methodsFor: 'lessons'!

welcome
	^TutorialLesson title: 'Welcome' text:
'A matrix is a rectangular table of numbers, and linear algebra is what you can do with such tables: combine them, invert them, solve equations with them, take them apart to see what they do. This package gives you a Matrix class whose entries are ordinary Smalltalk numbers.

Everything in this tutorial is live: select a line and press ctrl-P (print it) to run it. Every example stands on its own, so you can jump to any lesson.

The simplest way to make a matrix is from an Array of rows:
Matrix rows: #(#(1 2) #(3 4))

It prints on one line, rows separated by semicolons. To see it as a table, ask for its displayString (or send displayNl, which writes the table on the Transcript):
(Matrix rows: #(#(1 2) #(3 4))) displayString
Matrix fromString: ''1 2 3; 4 5 6''

The size of a matrix, rows then columns, is its dimensions:
(Matrix fromString: ''1 2 3; 4 5 6'') dimensions

The idea that runs through the whole package: the entries can be Integers and Fractions, in which case every answer is exact, or Floats, in which case the answers are rounded the way floating point always is. You choose by what you put in. Lesson 6 is about the difference.

Things that go wrong, such as multiplying matrices that do not fit, signal a MatrixError with a message that says what was wrong:
[(Matrix fromString: ''1 2; 3 4'') * (Matrix fromString: ''1 2 3'')] on: MatrixError do: [:e | e messageText]'!
vectors
	^TutorialLesson title: 'Vectors' text:
'A vector is just a matrix with one column (a column vector) or one row. There is no separate Vector class: the methods that make sense for vectors work on any matrix that has a single row or column.
Matrix column: #(3 4)
Matrix row: #(3 4)

The length of a vector is its norm, and the dot product of two vectors adds up the products of their entries. A row and a column may be mixed freely, and an Array stands for a column:
(Matrix column: #(3 4)) norm
(Matrix column: #(1 2 3)) dot: #(4 5 6)

Two vectors whose dot product is zero are orthogonal, at right angles. The angle between any two is found from the dot product, in radians:
(Matrix column: #(1 0)) isOrthogonalTo: #(0 5)
(Matrix column: #(1 0)) angleWith: #(1 1)
((Matrix column: #(1 0)) angleWith: #(1 1)) * 180 / Float pi

The cross product of two 3-vectors is orthogonal to both:
(Matrix column: #(1 0 0)) cross: #(0 1 0)
(Matrix column: #(1 2 3)) cross: #(4 5 6)

The outer product of two vectors is a whole matrix, entry (i, j) being the i-th entry of the first times the j-th of the second:
(Matrix column: #(1 2 3)) outer: #(1 10)

To project one vector onto the line through another, and to make a vector of length one:
(Matrix column: #(3 4)) projectOnto: #(1 0)
(Matrix column: #(3 4)) normalized

Notice that norm and normalized answer Floats because of the square root, while dot and cross stay exact when the entries are exact.'!
making
	^TutorialLesson title: 'Making matrices' text:
'Besides rows: there are several ways to build a matrix. columns: takes an Array of columns, and fromString: reads rows separated by semicolons, with fractions written 3/4:
Matrix columns: #(#(1 2 3) #(4 5 6))
Matrix fromString: ''1/2 1/3; 1/4 1/5''

The special matrices:
Matrix identity: 3
Matrix zerosRows: 2 columns: 3
Matrix diagonal: #(2 3 5)
Matrix rows: 2 columns: 3 fill: 7

To build one from a rule, give the number of rows and columns and a block that takes the row and column index (counting from 1):
Matrix rows: 3 columns: 3 collect: [:i :j | i * j]
Matrix rows: 4 columns: 4 collect: [:i :j | i = j ifTrue: [2] ifFalse: [(i - j) abs = 1 ifTrue: [-1] ifFalse: [0]]]

Some famous matrices come ready made. The Hilbert matrix has entries 1/(i + j - 1), a standard test of numerical care. A Vandermonde matrix has a row 1, x, x^2 ... for each point x. A Toeplitz matrix is constant along its diagonals, and Pascal''s holds the binomial coefficients:
Matrix hilbert: 3
Matrix vandermonde: #(1 2 3)
Matrix toeplitz: #(1 2 3)
Matrix pascal: 4

Rotations by an angle in radians (in the plane, and about the three axes) are there too, and so are the permutation matrices:
Matrix rotation: 0.5
Matrix permutation: #(2 3 1)'!
inside
	^TutorialLesson title: 'Looking inside' text:
'Entries are read with at:at: (row, then column), and changed with at:at:put:, which changes the matrix itself; use copy first if you want to keep the original.
(Matrix fromString: ''1 2; 3 4'') at: 2 at: 1
| m | m := (Matrix fromString: ''1 2; 3 4'') copy. m at: 1 at: 1 put: 99. m

Whole rows and columns come out as Arrays (rowArray:, columnArray:) or as matrices (row:, column:). The diagonal is an Array, and asArray lists all the entries row by row:
(Matrix fromString: ''1 2 3; 4 5 6'') rowArray: 2
(Matrix fromString: ''1 2 3; 4 5 6'') column: 3
(Matrix fromString: ''1 2 3; 4 5 6'') diagonal
(Matrix fromString: ''1 2 3; 4 5 6'') asArray

The transpose turns rows into columns. Blocks of a matrix are taken with submatrix, and withoutRow:column: leaves out one row and one column:
(Matrix fromString: ''1 2 3; 4 5 6'') transposed
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') submatrixRows: 1 to: 2 columns: 2 to: 3
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') withoutRow: 2 column: 2

Matrices are glued side by side with augment: and one above the other with stack:. The augmented matrix [A | b] of a system of equations is exactly this:
(Matrix fromString: ''1 2; 3 4'') augment: (Matrix column: #(5 6))
(Matrix fromString: ''1 2; 3 4'') stack: (Matrix row: #(5 6))

collect: applies a block to every entry and answers a new matrix; the row operations of elimination are there as well, each answering a new matrix:
(Matrix fromString: ''1 2; 3 4'') collect: [:x | x * x]
(Matrix fromString: ''1 2; 3 4'') swapRows: 1 with: 2
(Matrix fromString: ''1 2; 3 4'') addRow: 1 times: -3 to: 2'!
arithmetic
	^TutorialLesson title: 'Arithmetic' text:
'Matrices of the same shape are added and subtracted entry by entry, and a number multiplies every entry. (A number on the left, 2 * m, is not understood by Smalltalk numbers: write m * 2 or m scaledBy: 2.)
(Matrix fromString: ''1 2; 3 4'') + (Matrix fromString: ''10 20; 30 40'')
(Matrix fromString: ''1 2; 3 4'') * 3
(Matrix fromString: ''1 2; 3 4'') - (Matrix identity: 2)

Multiplying two matrices is not entry by entry: entry (i, j) of the product is row i of the first dotted with column j of the second. So the columns of the first must match the rows of the second, and the answer has the rows of the first and the columns of the second:
(Matrix fromString: ''1 2; 3 4'') * (Matrix fromString: ''5 6; 7 8'')
(Matrix fromString: ''1 2 3; 4 5 6'') * (Matrix fromString: ''1; 0; 2'')

Order matters: A * B is usually not B * A, while the identity changes nothing:
| a b | a := Matrix fromString: ''1 2; 3 4''. b := Matrix fromString: ''0 1; 1 0''. (a * b) = (b * a)
| a | a := Matrix fromString: ''1 2; 3 4''. (a * (Matrix identity: 2)) = a

The entry by entry (Hadamard) product and the Kronecker product, which puts a scaled copy of the second matrix in every entry of the first, have their own names:
(Matrix fromString: ''1 2; 3 4'') hadamard: (Matrix fromString: ''5 6; 7 8'')
(Matrix fromString: ''1 2; 3 4'') kronecker: (Matrix fromString: ''1 1; 1 1'')

A square matrix can be raised to a whole power (by repeated squaring), and has a trace, the sum of its diagonal:
(Matrix fromString: ''1 1; 0 1'') raisedTo: 10
(Matrix fromString: ''1 2; 3 4'') trace

The norms of a matrix measure its size: the largest column sum, the largest row sum, the Frobenius norm (the length of the matrix as one long vector) and the spectral norm (which lesson 16 explains):
(Matrix fromString: ''1 -2; 3 4'') norm1
(Matrix fromString: ''1 -2; 3 4'') normInf
(Matrix fromString: ''1 -2; 3 4'') frobeniusNorm'!
exact
	^TutorialLesson title: 'Exact and floating point' text:
'This is the central idea of the package. A matrix whose entries are Integers and Fractions is exact: nothing is ever rounded, so a determinant is really the determinant and an inverse is really the inverse. Add one Float and the whole computation is done in floating point, which is fast and approximate.
(Matrix fromString: ''1 2; 3 4'') inverse
(Matrix fromString: ''1.0 2; 3 4'') inverse

The first shows exact fractions. The second shows Floats, rounded to six places for display (the entries themselves are full Floats). The rounding of floating point is why 0.1 + 0.2 is not quite 0.3, and why Floats must be compared with a tolerance:
0.1 + 0.2 = 0.3
| a b | a := Matrix fromString: ''0.1 0.2''. b := Matrix fromString: ''0.3 0.4''. (a + b) isCloseTo: (Matrix fromString: ''0.4 0.6'')

isCloseTo: compares matrices with a tolerance, and two matrices are = only if every entry is equal. Whether a Float counts as zero in the algorithms is decided by Matrix tolerance, relative to the largest entry (1.0e-10 unless you change it).

The classic trap is the Hilbert matrix. Its exact inverse has whole numbers in it, but in floating point the rounding errors are blown up by its condition number, which grows fast with the size:
(Matrix hilbert: 5) inverse
(Matrix hilbert: 8) asFloats conditionNumber

You can move between the two worlds: asFloats turns every entry into a Float, and asExact turns every Float into the exact fraction it holds. roundedTo: rounds to a number of decimal places to tidy up Floats:
(Matrix fromString: ''1/3 1/7'') asFloats
(Matrix fromString: ''0.5 0.25'') asExact
(Matrix fromString: ''3.14159 2.71828'') roundedTo: 2

The rule of thumb: stay exact while you can (small integer problems, teaching, anything where the answer should be a fraction), and use Floats for eigenvalues, SVDs, and anything with square roots, which are Float computations anyway.'!
determinant
	^TutorialLesson title: 'Determinants' text:
'The determinant of a square matrix is a single number that says whether the matrix can be inverted (not zero) and by what factor it scales areas or volumes. For an exact matrix it is computed without any rounding (fraction-free elimination), for a Float one by an LU decomposition.
(Matrix fromString: ''1 2; 3 4'') determinant
(Matrix fromString: ''2 0 1; 1 3 2; 1 1 4'') determinant
(Matrix hilbert: 4) determinant

A matrix with determinant zero is singular. It happens when a row is a combination of the others:
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') determinant
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') isSingular

The determinant of a product is the product of the determinants, and transposing changes nothing. Exchanging two rows changes the sign:
| a b | a := Matrix fromString: ''1 2; 3 4''. b := Matrix fromString: ''5 6; 7 9''. (a * b) determinant = (a determinant * b determinant)
| a | a := Matrix fromString: ''1 2 3; 0 4 5; 1 0 6''. a determinant = a transposed determinant
| a | a := Matrix fromString: ''1 2 3; 0 4 5; 1 0 6''. (a swapRows: 1 with: 3) determinant = a determinant negated

The textbook definition expands along a row using cofactors. The cofactor matrix and its transpose, the adjugate, give the formula for the inverse: A times its adjugate is the determinant times the identity.
(Matrix fromString: ''1 2; 3 4'') cofactorMatrix
| a | a := Matrix fromString: ''2 0 1; 1 3 2; 1 1 4''. (a * a adjugate) = ((Matrix identity: 3) * a determinant)

Cofactor expansion is shown for understanding only; for big matrices it is hopeless (n!! terms), whereas elimination costs about n cubed steps.'!
inverse
	^TutorialLesson title: 'The inverse and solving equations' text:
'A square matrix A is invertible when there is a matrix inverse with A * inverse = I. Then the system A x = b has the one solution x = inverse * b:
(Matrix fromString: ''2 1; 1 3'') inverse
| a | a := Matrix fromString: ''2 1; 1 3''. (a * a inverse) = (Matrix identity: 2)

You rarely need the inverse itself. solve: finds x directly, which is faster and, with Floats, more accurate. The right hand side is a matrix, or an Array taken as one column:
(Matrix fromString: ''2 1; 1 3'') solve: #(3 5)
(Matrix fromString: ''2 1; 1 3'') solve: (Matrix identity: 2)

The second one solved for two right hand sides at once, and so gave the inverse. A system of three equations in three unknowns, written with the unknowns x, y, z as
    x + 2y + 3z = 14, 2x + 5y + 3z = 18, x + 8z = 17:
(Matrix fromString: ''1 2 3; 2 5 3; 1 0 8'') solve: #(14 18 17)

Check an answer by multiplying back:
| a | a := Matrix fromString: ''1 2 3; 2 5 3; 1 0 8''. a * (a solve: #(14 18 17))

A singular matrix has no inverse, and asking for it is an error, not a wrong answer:
[(Matrix fromString: ''1 2; 2 4'') inverse] on: MatrixError do: [:e | e messageText]

For a tiny system you can also use Cramer''s rule, which gives each unknown as a ratio of determinants; it is there to see the rule, not to use:
(Matrix fromString: ''2 1; 1 3'') cramer: #(3 5)'!
elimination
	^TutorialLesson title: 'Elimination step by step' text:
'Gaussian elimination is how all of this is really done: add multiples of one row to another to create zeros, until the matrix is in a simple form. The reduced row echelon form has a 1 as the first non-zero entry of each row (a pivot), zeros above and below every pivot, and the pivots stepping to the right as you go down.
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 10'') rref
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') rref

The columns holding the pivots tell you a great deal, and are found with pivotColumns. In the second matrix above there are only two pivots (the third column has none) and so the matrix is singular:
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') pivotColumns

To see the elimination itself, rrefSteps answers the whole story as text: every row operation and the matrix after it. Print it, or open it in an inspector:
(Matrix fromString: ''2 1 -1; -3 -1 2; -2 1 2'') rrefSteps

To solve a system by hand, eliminate on the augmented matrix [A | b]. When the left part becomes the identity the right part is the solution:
((Matrix fromString: ''2 1 -1; -3 -1 2; -2 1 2'') augment: (Matrix column: #(8 -11 -3))) rref

The solution is x = 2, y = 3, z = -1, and solve: gives it directly:
(Matrix fromString: ''2 1 -1; -3 -1 2; -2 1 2'') solve: #(8 -11 -3)

Elimination of an exact matrix chooses the first non-zero pivot in each column, as you would by hand. For Floats it chooses the largest entry in the column (partial pivoting), which keeps rounding errors small. Entries below the zero threshold count as zero.'!
rank
	^TutorialLesson title: 'Rank and the null space' text:
'The rank of a matrix is the number of pivots: the number of independent rows (which is also the number of independent columns). The nullity is what is left over, the number of columns without a pivot, and rank plus nullity is always the number of columns:
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') rank
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') nullity
(Matrix fromString: ''1 2 3 4; 2 4 6 8'') rank

The null space is every vector x with A x = 0. nullspaceBasis answers an Array of vectors that span it; every solution is a combination of them:
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') nullspaceBasis
| a | a := Matrix fromString: ''1 2 3; 4 5 6; 7 8 9''. a * (a nullspaceBasis at: 1)

An invertible matrix has only the zero vector in its null space, so its basis is empty:
(Matrix fromString: ''2 1; 1 3'') nullspaceBasis

The column space is everything A x can be. A basis for it is the pivot columns of the original matrix, and a basis for the row space is the non-zero rows of the echelon form:
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') columnSpaceBasis
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') rowSpaceBasis

A system A x = b can have no solution, one, or infinitely many. solveGeneral: answers nil for none, and otherwise a particular solution together with the null space vectors that may be added to it:
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') solveGeneral: #(1 2 3)
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') solveGeneral: #(1 2 4)
(Matrix fromString: ''1 1; 1 2; 1 3'') solveGeneral: #(1 2 3)

The first has a whole line of solutions, the second has none (the equations contradict each other), and the third, with more equations than unknowns, happens to have exactly one.'!
lu
	^TutorialLesson title: 'LU decomposition' text:
'Elimination can be recorded as a factorisation. Every square matrix, after exchanging rows, is a lower triangular matrix L (with ones on its diagonal, holding the multipliers used) times an upper triangular matrix U (the result of the elimination): P A = L U, where P is a permutation matrix that records the row exchanges.
(Matrix fromString: ''2 1 1; 4 3 3; 8 7 9'') lu lower
(Matrix fromString: ''2 1 1; 4 3 3; 8 7 9'') lu upper
(Matrix fromString: ''2 1 1; 4 3 3; 8 7 9'') lu permutationMatrix

Multiply the pieces back together to check them (reconstruct puts the permutation back):
| a | a := Matrix fromString: ''2 1 1; 4 3 3; 8 7 9''. a lu reconstruct = a
| a lu | a := Matrix fromString: ''2 1 1; 4 3 3; 8 7 9''. lu := a lu. ((lu permutationMatrix * a) = (lu lower * lu upper))

When an exchange is needed the permutation shows it. Here the first pivot is zero:
(Matrix fromString: ''0 1; 1 1'') lu permutation
(Matrix fromString: ''0 1; 1 1'') lu sign

The point of the factorisation: once you have it, solving for any right hand side is cheap (a forward and a back substitution), and the determinant is the product of the diagonal of U with the sign of the permutation. That is exactly what solve: and determinant do for Float matrices:
(Matrix fromString: ''2 1 1; 4 3 3; 8 7 9'') lu solve: (Matrix column: #(1 2 3))
(Matrix fromString: ''2 1 1; 4 3 3; 8 7 9'') lu determinant

A singular matrix still has an LU decomposition, but U has a zero on its diagonal, and the decomposition says so:
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') lu isSingular'!
qr
	^TutorialLesson title: 'Orthogonality, Gram-Schmidt and QR' text:
'A matrix Q whose columns have length one and are at right angles to each other is called orthogonal. It has a lovely property: Q transposed is its inverse, so it rotates and reflects without ever stretching.
Matrix rotation: 0.5
(Matrix rotation: 0.5) isOrthogonal
| q | q := Matrix rotation: 0.5. (q transposed * q) roundedTo: 10

Any independent set of vectors can be turned into an orthonormal one by the Gram-Schmidt process: take each vector, subtract its shadow on those before it, and scale to length one. The result spans the same space. gramSchmidt does it for the columns of a matrix in Floats, and gramSchmidtUnnormalized keeps everything exact by skipping the scaling:
(Matrix fromString: ''1 1 0; 1 0 1; 0 1 1'') gramSchmidt
(Matrix fromString: ''1 1 0; 1 0 1; 0 1 1'') gramSchmidtUnnormalized

The QR decomposition is Gram-Schmidt written as a factorisation: A = Q R, with Q orthogonal and R upper triangular. It is computed with Householder reflections, which are very stable. For a tall matrix, Q is square and R has rows of zeros at the bottom:
(Matrix fromString: ''1 2; 3 4; 5 6'') qr q
(Matrix fromString: ''1 2; 3 4; 5 6'') qr r
| a | a := Matrix fromString: ''1 2; 3 4; 5 6''. (a qr q * a qr r) isCloseTo: a
(Matrix fromString: ''1 2; 3 4; 5 6'') qr q isOrthogonal

R has a non-negative diagonal here, which makes the decomposition unique for a matrix of independent columns. QR is the workhorse of the next lesson, and of the eigenvalue method of lesson 14.'!
least
	^TutorialLesson title: 'Least squares' text:
'When there are more equations than unknowns, as with data, usually no x satisfies them all. The least squares solution is the x for which A x is as close as possible to b, in the sense of the smallest sum of squared errors. leastSquares: finds it using the QR decomposition.

To fit a line y = c0 + c1 x through the points (0, 1), (1, 3), (2, 5), (3, 7.5) build the matrix with a column of ones and a column of x values, and solve for the coefficients:
Matrix vandermonde: #(0 1 2 3) degree: 1
(Matrix vandermonde: #(0 1 2 3) degree: 1) leastSquares: #(1 3 5 7.5)
Matrix fitPolynomialDegree: 1 xs: #(0 1 2 3) ys: #(1 3 5 7.5)

The last is the same thing in one step, for a polynomial of any degree (the coefficients come constant term first). A parabola through the same four points:
Matrix fitPolynomialDegree: 2 xs: #(0 1 2 3) ys: #(1 3 5 7.5)

The classic way to write the answer is the normal equations: x solves (A transposed A) x = A transposed b. With exact data they give the exact answer, in fractions:
(Matrix vandermonde: #(0 1 2 3) degree: 1) normalEquations: #(1 3 5 8)
Matrix fitPolynomialDegree: 1 xs: #(0 1 2 3) ys: #(1 3 5 8) exactly: true

With Floats QR is better. Forming A transposed A squares the condition number, and an ill-conditioned fit loses digits it need not have lost. A degree 9 polynomial fit has a badly conditioned Vandermonde matrix:
| a | a := Matrix vandermonde: ((0 to: 11) collect: [:i | i / 11.0]) degree: 9. a conditionNumber > 1.0e5

The residual, the part of b that A x cannot reach, is orthogonal to every column of A. That is what makes it the best fit:
| a b x | a := Matrix vandermonde: #(0 1 2 3) degree: 1. b := Matrix column: #(1 3 5 7.5). x := a leastSquares: b. ((a transposed * (b - (a * x))) roundedTo: 8)

If the columns of A are dependent there is no single best fit, and leastSquares: says so; the pseudoinverse of lesson 16 then gives the shortest of the best fits.'!
eigen
	^TutorialLesson title: 'Eigenvalues and eigenvectors' text:
'Most vectors change direction when a matrix acts on them. Some do not: A v = lambda v, the vector only stretches by a factor lambda. Such a v is an eigenvector and lambda an eigenvalue. They show what a matrix does at its core.

The eigenvalues are the roots of the characteristic polynomial det(x I - A), which comes exactly for an exact matrix:
(Matrix fromString: ''2 1; 1 2'') characteristicPolynomialString
(Matrix fromString: ''1 2; 3 4'') characteristicPolynomialString
(Matrix fromString: ''2 0 0; 1 3 0; 4 5 6'') characteristicPolynomial

The eigenvalues themselves are found numerically (with Floats), by the QR algorithm. The result is largest first, and has the little rounding noise of floating point, which eigenvaluesRoundedTo: hides:
(Matrix fromString: ''2 1; 1 2'') eigenvalues
(Matrix fromString: ''2 0 0; 1 3 0; 4 5 6'') eigenvaluesRoundedTo: 6
(Matrix companion: #(-6 11 -6)) eigenvaluesRoundedTo: 6

The last matrix is the companion matrix of x^3 - 6x^2 + 11x - 6, so its eigenvalues are the roots 1, 2 and 3 of that polynomial: this is how polynomial roots are found.

For an eigenvalue you know exactly, the eigenvectors are the null space of A - lambda I, exact for an exact matrix:
(Matrix fromString: ''2 1; 1 2'') eigenspaceFor: 3
(Matrix fromString: ''2 1; 1 2'') eigenspaceFor: 1

eigen finds all the eigenvalues and vectors together, answering an object with values and vectors (unit eigenvectors as columns). A matrix with a full set of them can be diagonalized: A = V D V^-1 with D the diagonal matrix of eigenvalues:
| a | a := Matrix fromString: ''4 1 2; 0 3 1; 1 0 2''. a eigen values
| a | a := Matrix fromString: ''4 1 2; 0 3 1; 1 0 2''. a eigen vectors
| a | a := Matrix fromString: ''4 1 2; 0 3 1; 1 0 2''. a eigen reconstruct

A real matrix can have complex eigenvalues, always in conjugate pairs. A rotation has none that are real: no direction survives a turn. They come as MatrixComplex numbers:
(Matrix fromString: ''0 -1; 1 0'') eigenvalues
(Matrix fromString: ''1 2 0; -2 1 0; 0 0 3'') eigenvalues
(Matrix fromString: ''0 -1; 1 0'') eigen isDiagonalizable

Not every matrix is diagonalizable even when its eigenvalues are real: a shear has only one eigenvector direction. It is called defective:
(Matrix fromString: ''1 1; 0 1'') isDiagonalizable

The Cayley-Hamilton theorem says a matrix satisfies its own characteristic polynomial. polynomialValue: puts a matrix into a polynomial (constant term first):
| a | a := Matrix fromString: ''1 2; 3 4''. a polynomialValue: a characteristicPolynomial'!
symmetric
	^TutorialLesson title: 'Symmetric matrices and definiteness' text:
'Symmetric matrices, equal to their transpose, are the well behaved ones: their eigenvalues are always real, their eigenvectors can be chosen at right angles, and they are diagonalized by an orthogonal matrix: A = Q D Q^T. They arise everywhere: covariance matrices, energy forms, graph Laplacians. Their eigenvalues are found with Jacobi''s method, rotating away the off diagonal entries one by one:
(Matrix fromString: ''2 -1 0; -1 2 -1; 0 -1 2'') isSymmetric
(Matrix fromString: ''2 -1 0; -1 2 -1; 0 -1 2'') eigenvaluesRoundedTo: 6
(Matrix fromString: ''2 -1 0; -1 2 -1; 0 -1 2'') eigen vectors isOrthogonal
| a | a := Matrix fromString: ''2 -1 0; -1 2 -1; 0 -1 2''. a eigen reconstruct isCloseTo: a

A symmetric matrix is positive definite when x^T A x is positive for every non-zero x, which happens exactly when all its eigenvalues are positive. definiteness classifies it, and isPositiveDefinite is a quick test (exactly, by the leading minors, for an exact matrix):
(Matrix fromString: ''2 -1 0; -1 2 -1; 0 -1 2'') definiteness
(Matrix fromString: ''1 2; 2 1'') definiteness
(Matrix fromString: ''1 1; 1 1'') definiteness
(Matrix fromString: ''2 -1 0; -1 2 -1; 0 -1 2'') isPositiveDefinite

A positive definite matrix has a Cholesky decomposition, A = L L^T with L lower triangular, a kind of square root. It is the cheapest way to solve such systems, and it fails (with an error) if the matrix is not positive definite, which makes it a test too. Where the square roots are perfect squares they stay exact:
(Matrix fromString: ''4 2; 2 3'') cholesky
(Matrix fromString: ''4 2; 2 10'') cholesky
[(Matrix fromString: ''1 2; 2 1'') cholesky] on: MatrixError do: [:e | e messageText]

The power method is the simplest eigenvalue algorithm: multiply a vector by A again and again and it turns towards the eigenvector of the largest eigenvalue. powerIteration: answers the eigenvalue and the vector after that many steps:
((Matrix fromString: ''2 1; 1 2'') powerIteration: 30) first'!
svd
	^TutorialLesson title: 'The singular value decomposition' text:
'Every matrix, of any shape, factors as A = U S V^T: V and U orthogonal (rotations and reflections) and S diagonal, with the singular values on its diagonal, largest first. In words: any matrix turns some orthogonal frame into another, stretching each axis by a singular value. It is the most informative decomposition there is.
(Matrix fromString: ''1 2; 3 4'') svd
(Matrix fromString: ''1 2; 3 4'') singularValues
| s | s := (Matrix fromString: ''1 2; 3 4; 5 6'') svd. s reconstruct

Here the decomposition is the thin one: for an m by n matrix U is m by k and V is n by k with k the smaller of m and n. The largest singular value is the spectral norm of the matrix, the most it can stretch a vector:
(Matrix fromString: ''1 2; 3 4'') norm2
(Matrix fromString: ''1 2; 3 4'') svd u isOrthonormalColumns

The singular values reveal the rank: the number of non-zero ones. For floating point matrices this is the robust way to find rank, because elimination can be fooled by rounding:
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') singularValues
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') numericalRank

The ratio of the largest to the smallest singular value is the condition number: how much the answer of a linear system can change when the data change a little. A huge one (or infinity) means the matrix is nearly (or exactly) singular:
(Matrix fromString: ''1 2; 3 4'') conditionNumber
(Matrix fromString: ''1 2 3; 4 5 6; 7 8 9'') conditionNumber > 1.0e15
(Matrix hilbert: 6) asFloats conditionNumber

Keeping only the largest singular values gives the best approximation of lower rank. This is how images are compressed and how noise is removed from data:
| a | a := Matrix fromString: ''1 2 3; 4 5 6; 7 8 9.5''. (a svd approximationOfRank: 2) roundedTo: 2

The pseudoinverse generalizes the inverse to any matrix, square or not, invertible or not: it gives the shortest of the least squares solutions. For an exact matrix it is computed exactly, in fractions:
(Matrix fromString: ''1 2; 3 4; 5 6'') pseudoinverse
(Matrix fromString: ''1 2; 2 4'') pseudoinverse
(Matrix fromString: ''1 2; 2 4'') minimumNormSolution: #(5 10)'!
applications
	^TutorialLesson title: 'Applications' text:
'Linear algebra is useful because so many things turn out to be linear. A few examples.

A Markov chain moves between states with fixed probabilities. Put the probabilities in a matrix whose rows sum to one; after many steps the chain settles into a steady state that no longer changes. steadyState finds it by solving (P transposed - I) pi = 0, exactly if the probabilities are fractions. Here a sunny day is followed by a sunny one nine times in ten, a rainy one by a sunny one half the time:
(Matrix fromString: ''9/10 1/10; 1/2 1/2'') steadyState
(Matrix fromString: ''9/10 1/10; 1/2 1/2'') isRowStochastic
((Matrix fromString: ''9/10 1/10; 1/2 1/2'') raisedTo: 50) roundedTo: 6

After 50 steps every row of the power has become the steady state: the weather forgets where it started. In the long run, five days in six are sunny.

The Fibonacci numbers 1, 1, 2, 3, 5, 8 come from powers of a 2 by 2 matrix: the power n of the matrix with rows (1 1) and (1 0) holds F(n+1), F(n) and F(n-1). Repeated squaring computes F(90) in a handful of multiplications, exactly:
((Matrix fromString: ''1 1; 1 0'') raisedTo: 90) at: 1 at: 2
((Matrix fromString: ''1 1; 1 0'') raisedTo: 300) at: 1 at: 2

Rotations turn the plane (or space). Turning the vector (1, 0) by 90 degrees gives (0, 1), and turning it twice by 45 degrees is the same as once by 90:
((Matrix rotation: Float pi / 2) * (Matrix column: #(1 0))) roundedTo: 6
((Matrix rotation: Float pi / 4) raisedTo: 2) isCloseTo: (Matrix rotation: Float pi / 2)
(Matrix rotationZ: 0.3) isOrthogonal

PageRank ranks web pages by the steady state of a random surfer. The matrix says which page links to which (entry (i, j) non-zero: page i links to page j), and pageRank: with a damping factor answers the rank of each page:
(Matrix fromString: ''0 1 1; 0 0 1; 1 0 0'') pageRank: 0.85

Statistics: arrange data with one row per observation and one column per variable. Subtracting the column means centres it, and the covariance matrix says how the variables vary together. Its eigenvectors are the principal components, and its eigenvalues the variance along each:
| d | d := Matrix fromString: ''2 1; 4 3; 6 5; 8 8''. d covarianceMatrix
| d | d := Matrix fromString: ''2 1; 4 3; 6 5; 8 8''. d principalComponents
| d | d := Matrix fromString: ''2 1; 4 3; 6 5; 8 8''. d correlationMatrix roundedTo: 4'!
whatnext
	^TutorialLesson title: 'What next' text:
'You now know the main tools of linear algebra, and how to see them at work. A few things to try.

Take a system of equations from a textbook and solve it three ways: by eliminating on the augmented matrix, with solve:, and by hand with rrefSteps next to you. Then make it ill conditioned and compare the exact and Float answers. Multiply the Hilbert matrix of size 8 by its inverse and see how far from the identity matrix the product is (normInf is the largest row sum of absolute values), first in Floats:
((Matrix hilbert: 8) asFloats inverse * (Matrix hilbert: 8) asFloats - (Matrix identity: 8)) normInf

and then exactly, where the answer is not nearly zero but zero:
((Matrix hilbert: 8) inverse * (Matrix hilbert: 8) - (Matrix identity: 8)) normInf

The Float answer is about a million times the rounding unit of a Float: that is the lesson of lesson 6 at work. Make the matrix a little bigger and the Float elimination gives up and calls it singular, because a pivot has fallen below the tolerance:
[(Matrix hilbert: 10) asFloats inverse] on: MatrixError do: [:e | e messageText]

Everything is ordinary Smalltalk, so you can browse the classes: Matrix holds almost all of it, with MatrixLU, MatrixQR, MatrixSVD and MatrixEigen for the decompositions, MatrixComplex for complex eigenvalues and MatrixError for what goes wrong. Look at the method categories in the browser (elimination, decompositions, eigenvalues, applications) for the whole list, and the senders of the methods you use.

Ideas to build next: a function that finds the roots of a polynomial from its companion matrix; image compression with the SVD on a small matrix of pixel values; a Markov chain for a board game; or finite differences, where a differential equation turns into a tridiagonal system:
Matrix rows: 5 columns: 5 collect: [:i :j | i = j ifTrue: [2] ifFalse: [(i - j) abs = 1 ifTrue: [-1] ifFalse: [0]]]

Its eigenvalues and its inverse are well worth a look.
((Matrix rows: 5 columns: 5 collect: [:i :j | i = j ifTrue: [2] ifFalse: [(i - j) abs = 1 ifTrue: [-1] ifFalse: [0]]]) eigenvaluesRoundedTo: 4)
((Matrix rows: 5 columns: 5 collect: [:i :j | i = j ifTrue: [2] ifFalse: [(i - j) abs = 1 ifTrue: [-1] ifFalse: [0]]]) inverse)'! !
