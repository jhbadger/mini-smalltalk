"Matrix: linear algebra - exact and floating point matrices, elimination, determinants and inverses, LU, QR, Cholesky, eigenvalues, the SVD, and a tutorial"
| dir |
dir := Smalltalk packagePath: 'Matrix'.
#('classes.st' 'matrix.st' 'arith.st' 'elimination.st' 'decomp.st' 'eigen.st' 'tutorial.st')
	do: [:f | Smalltalk fileIn: dir, '/', f]!
