"The classes of the Algebra system: the error, the expression trees (a number, a symbol, a sum, a product, a power and
a function applied to an argument), a polynomial in one variable over the rationals, the reader, and the front door
(the methods of the trees are in expr.st, print.st, manip.st, calculus.st and solve.st)."

Error subclass: #SymError instanceVariableNames: '' classVariableNames: '' category: 'Algebra'!

Object subclass: #SymExpr
	instanceVariableNames: 'keyCache textCache sizeCache'
	classVariableNames: ''
	category: 'Algebra'!
SymExpr subclass: #SymNum instanceVariableNames: 'value' classVariableNames: '' category: 'Algebra'!
SymExpr subclass: #SymSym instanceVariableNames: 'name' classVariableNames: '' category: 'Algebra'!
SymExpr subclass: #SymAdd instanceVariableNames: 'terms' classVariableNames: '' category: 'Algebra'!
SymExpr subclass: #SymMul instanceVariableNames: 'factors' classVariableNames: '' category: 'Algebra'!
SymExpr subclass: #SymPow instanceVariableNames: 'base exponent' classVariableNames: '' category: 'Algebra'!
SymExpr subclass: #SymFn instanceVariableNames: 'name arg' classVariableNames: '' category: 'Algebra'!

Object subclass: #SymPoly instanceVariableNames: 'coeffs' classVariableNames: '' category: 'Algebra'!
Object subclass: #SymParser instanceVariableNames: 'source tokens pos defs funs' classVariableNames: '' category: 'Algebra'!
Object subclass: #SymLinear instanceVariableNames: '' classVariableNames: '' category: 'Algebra'!
Object subclass: #SymPretty instanceVariableNames: '' classVariableNames: '' category: 'Algebra'!
Object subclass: #Algebra instanceVariableNames: '' classVariableNames: '' category: 'Algebra'!
