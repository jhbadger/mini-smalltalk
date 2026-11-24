"Algebra: a computer algebra system - expressions in canonical form, simplify, expand, factor, partial fractions, derivatives, integrals, limits, series, equations, sums, and a workspace"
| dir |
dir := Smalltalk packagePath: 'Algebra'.
#('classes.st' 'expr.st' 'print.st' 'parser.st' 'poly.st' 'manip.st' 'calculus.st' 'solve.st' 'api.st' 'tool.st' 'tutorial.st')
	do: [:f | Smalltalk fileIn: dir, '/', f]!
SystemMenu add: 'algebra workspace' receiver: AlgebraTool selector: #open!
