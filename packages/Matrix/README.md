# Matrix

Linear algebra: dense matrices of exact or floating point numbers, elimination, determinants and inverses, LU, QR and
Cholesky decompositions, eigenvalues and eigenvectors, the singular value decomposition, the pseudoinverse, least
squares, and a tutorial of 18 lessons.

```smalltalk
Smalltalk loadPackage: 'Matrix'
```

## The shortest useful example

```smalltalk
| a |
a := Matrix fromString: '2 1; 1 3'.
a inverse.                       "Matrix(3/5 -1/5; -1/5 2/5): exact fractions"
a solve: #(3 5).                 "Matrix(4/5; 7/5)"
a determinant.                   "5"
a eigenvaluesRoundedTo: 4.       "#(3.618 1.382)"
a displayNl                      "writes the table on the Transcript"
```

## Exact or floating point

A `Matrix` holds ordinary Smalltalk numbers. A matrix of Integers and Fractions is **exact**: determinant, inverse,
rank, row reduction, null space, solving, powers and the pseudoinverse are done in fractions with no rounding. A
matrix with a Float anywhere in it is computed in floating point (with partial pivoting; entries under
`Matrix tolerance`, 1.0e-10 times the largest entry, count as zero). `asFloats` and `asExact` move between the two;
`isExact` asks which a matrix is.

Eigenvalues, the SVD, QR and the matrix exponential always compute in Floats, since they need square roots.

## Making matrices

```smalltalk
Matrix rows: #(#(1 2) #(3 4))              Matrix columns: #(#(1 2 3) #(4 5 6))
Matrix row: #(1 2 3)                       Matrix column: #(1 2 3)
Matrix fromString: '1 2; 3/4 5.5'          "rows by ; or line breaks, 3/4 is a fraction"
Matrix identity: 3        Matrix zeros: 2        Matrix ones: 2        Matrix diagonal: #(2 3 5)
Matrix rows: 3 columns: 3 collect: [:i :j | i * j]
Matrix rows: 2 columns: 3 fill: 7          Matrix zerosRows: 2 columns: 3
Matrix hilbert: 4     Matrix vandermonde: #(1 2 3)     Matrix toeplitz: #(1 2 3)
Matrix pascal: 4      Matrix companion: #(-6 11 -6)    Matrix permutation: #(2 3 1)
Matrix rotation: 0.5  Matrix rotationX: 0.5 (also Y and Z)
```

A vector is a matrix with one column or one row; there is no separate class. `dot:`, `cross:`, `outer:`, `norm`,
`normalized`, `projectOnto:`, `angleWith:` and `isOrthogonalTo:` work on any single row or column, and an Array
stands for a column wherever a matrix is expected (`a solve: #(3 5)`).

## Looking inside and reshaping

`at:at:`, `at:at:put:` (changes the receiver; use `copy`), `rowArray:`, `columnArray:`, `row:`, `column:`,
`diagonal`, `asArray`, `asArrays`, `rowCount`, `columnCount`, `dimensions`, `transposed`, `submatrixRows:to:columns:to:`,
`withoutRow:column:`, `rowsAt:`, `columnsAt:`, `augment:`, `stack:`, `reshapedRows:columns:`, `collect:`,
`collectWithIndexes:`, `with:collect:`, and the elementary row operations `swapRows:with:`, `scaleRow:by:` and
`addRow:times:to:`, each answering a new matrix. `=` is exact equality, `isCloseTo:` and `isCloseTo:within:` compare
with a tolerance, `roundedTo:` rounds Floats to a number of decimals.

## Arithmetic

`+`, `-`, `*` (matrix product, or times a number), `/` a number, `negated`, `hadamard:`, `kronecker:`, `raisedTo:`
(integer powers by squaring, negative through the inverse), `trace`, `norm1`, `normInf`, `frobeniusNorm`, `norm2`
(the largest singular value). A number on the left (`2 * m`) is not understood; write `m * 2`.

## Elimination and what comes of it

```smalltalk
m rref                       m pivotColumns         m rank          m nullity
m rrefSteps                  "the elimination written out, one row operation at a time"
m nullspaceBasis             "Array of column vectors"      m leftNullspaceBasis
m columnSpaceBasis           m rowSpaceBasis
m determinant                m cofactorMatrix       m adjugate      m minorAt: 1 at: 2
m inverse                    m isInvertible         m isSingular
m solve: b                   "square, non-singular; b may have several columns"
m solveGeneral: b            "nil, or #(particular solution, null space vectors)"
m cramer: b                  m isConsistent: b
```

A singular matrix or a shape that does not fit signals `MatrixError`, with a message that says what is wrong.

## Decompositions

```smalltalk
m lu                         "a MatrixLU: lower, upper, permutation, permutationMatrix, sign, determinant, solve:, reconstruct"
m qr                         "a MatrixQR: q (square), r, leastSquares:, reconstruct; Householder reflections"
m cholesky                   "lower L with L L^T = m; exact where the roots are perfect squares"
m gramSchmidt                m gramSchmidtUnnormalized     "the second is exact"
m svd                        "a MatrixSVD: u, sigma, v, sigmaMatrix, rank, reconstruct, approximationOfRank:"
m singularValues             m conditionNumber       m numericalRank          m pseudoinverse
m leastSquares: b            m normalEquations: b    m minimumNormSolution: b
Matrix fitPolynomialDegree: 2 xs: xs ys: ys            "coefficients, constant term first"
```

The SVD is the thin one, by one-sided Jacobi rotations. `pseudoinverse` of an exact matrix is exact (from a full rank
factorisation).

## Eigenvalues

```smalltalk
m eigenvalues                "largest real part first; Floats, or MatrixComplex in conjugate pairs"
m eigenvaluesRoundedTo: 4    m eigen                 "a MatrixEigen: values, vectors, reconstruct, residuals, isDiagonalizable"
m eigenvectorFor: 3.0        m eigenspaceFor: 3      "the second is exact for an exact m and lambda"
m characteristicPolynomial   m characteristicPolynomialString    m polynomialValue: coefficients
m jacobiEigen                m hessenbergForm        m powerIteration: 50    m spectralRadius
m exponential                m isPositiveDefinite    m definiteness          m isSymmetric
```

A symmetric matrix is done by cyclic Jacobi (real eigenvalues, orthonormal eigenvectors); any other real matrix by
the shifted QR algorithm on its Hessenberg form, which also finds complex eigenvalues. `eigen vectors` is nil when
there are complex eigenvalues or the matrix is defective. The characteristic polynomial (Faddeev-LeVerrier) is exact
for an exact matrix, and `polynomialValue:` shows the Cayley-Hamilton theorem.

## Applications

`steadyState` (Markov chains, exact for fractions), `isRowStochastic`, `pageRank:`, `columnMeans`, `centered`,
`covarianceMatrix`, `correlationMatrix`, `principalComponents`.

## Showing a matrix

`printString` is one line, `Matrix(1 2; 3 4)`, with Floats rounded to six places; `displayString` (or
`displayString: digits`) is the aligned table, and `displayNl` or `display` writes it on the Transcript.

## Files

`classes.st` (the classes, number formatting, `MatrixComplex`), `matrix.st` (construction, accessing, shape, printing),
`arith.st` (arithmetic, norms, vectors), `elimination.st` (row reduction, determinant, solving), `decomp.st`
(LU, QR, Cholesky, SVD, pseudoinverse), `eigen.st` (eigenvalues, polynomials, applications), `tutorial.st` and
`tests/tests.txt` (`expression ==> expected printString` lines, run by `make check`).

## Tutorial

```smalltalk
MatrixTutorial go
```

Eighteen lessons: vectors, building and inspecting matrices, arithmetic, exact against floating point, determinants,
inverses and solving, elimination step by step, rank and the null space, LU, orthogonality and QR, least squares,
eigenvalues, symmetric matrices and definiteness, the SVD, applications, and what next. Every example is a line you can
run in place.

## Limits

Matrices are dense and meant for small problems (the algorithms are the textbook ones, at about n cubed cost). Complex
matrices are not supported, only complex eigenvalues of real matrices. Eigenvectors of complex eigenvalues are not
computed. `norm2`, `conditionNumber` and `pseudoinverse` of Float matrices use the SVD with a relative threshold of
1.0e-12.
