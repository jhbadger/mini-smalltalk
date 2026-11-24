# Algebra

A computer algebra system: formulas are worked on exactly, as expressions, not as numbers.

```smalltalk
Smalltalk loadPackage: 'Algebra'            "or  st -l Algebra ;  System menu -> load package..."
Algebra expand: '(x+1)^3'                   "x^3 + 3*x^2 + 3*x + 1"
Algebra factor: 'x^4 - 1'                   "(x^2 + 1)*(x - 1)*(x + 1)"
Algebra diff: 'x*sin(x)'                    "x*cos(x) + sin(x)"
Algebra integrate: 'x*exp(x)'               "x*exp(x) - exp(x)"
Algebra solve: 'x^2 - 2 = 0'                "#(-sqrt(2) sqrt(2))"
Algebra limit: 'sin(x)/x' at: 0             "1"
Algebra apart: '1/(x^2-1)'                  "-1/(2*(x + 1)) + 1/(2*(x - 1))"
AlgebraTutorial go                          "19 lessons;  Smalltalk tutorialNamed: 'Algebra'"
```

The System menu gets an **algebra workspace**: select a line such as `integrate x^2, x, 0, 3`, `factor x^6 - 1`,
`system x + y = 3 ; x - y = 1 for x y`, `let f(x) = x^2 + 1` or `f(3)`, and print it.

## What is in it

* **Expressions** (`SymExpr`: `SymNum`, `SymSym`, `SymAdd`, `SymMul`, `SymPow`, `SymFn`) are built only through `sum:`, `product:`,
  `power:to:` and `fn:of:`, which keep a standard form: sums and products flattened, like terms and equal bases combined,
  numbers folded, `x^0`, `sin(0)`, `exp(ln x)` and the like applied, square roots written as surds (`sqrt(8)` is
  `2*sqrt(2)`, `sqrt(2)*sqrt(3)` is `sqrt(6)`), `sqrt` of a negative number given with `i`. Equal expressions have equal keys,
  so `=` is a comparison of keys. Nothing is multiplied out or factored unless asked.
* **Reading and printing**: infix text with juxtaposition (`3x^2`, `(x+1)(x-1)`), `^` right-associative, the usual
  functions; printing with the highest power first, minimal brackets, quotients as `a/b`; `latex:`, and `pretty:` for a
  picture with fraction bars and raised exponents.
* **Algebra**: `expand`, `simplify`, `factor` (over the rationals: content, rational roots, Kronecker's method, homogeneous
  polynomials in two symbols, differences of squares and cubes), `together`, `cancel`, `apart` (partial fractions over the
  rationals), `collect:in:`, polynomial `quotient`, `remainder`, `gcd`, `roots` (Durand-Kerner), Horner form, Lagrange
  interpolation, exact Newton iterations, trigonometric `trigSimplify:` and `trigExpand:`, `expandLog:`, `isEqual:to:` (the
  difference simplifies to zero) and `seemsEqual:to:` (numerical agreement: evidence, not proof).
* **Calculus**: `diff:` (also by a named symbol, and several times), `integrate:` (standard forms, linear and u
  substitution, by parts, rational functions through partial fractions with logarithms and arctangents, reduction
  formulas for powers and products of sin and cos, `exp` times sin or cos), definite integrals (limits `oo` allowed),
  `limit:at:` (substitution, cancelling, l'Hopital, exp-log rewriting), `series:in:at:order:` and `taylor:order:`, finite
  sums with closed forms (`sum:in:from:to:`: Faulhaber for polynomials, geometric series) and products.
* **Solving**: `solve:` and `solve:for:` (linear, quadratic with surds and complex roots, higher degrees by factoring,
  equations in which the unknown occurs once by inverting the operations), `solveSystem:for:` (linear systems exactly,
  nonlinear ones by substitution).
* **Substituting and evaluating**: `substitute:with:` (simultaneous), `evaluate:with:`, `numeric:with:` (a Float).

Everything accepts text, numbers or expressions. A mistake in the text or in the mathematics signals a `SymError`.

## Limits worth knowing

* `factor` works over the rationals only (`x^2 - 2` stays); multivariate factoring covers common factors, the patterns above
  and homogeneous polynomials in two symbols. Kronecker's method gives up on very large coefficients.
* Irreducible factors of degree 3 or more are solved as numeric real roots (Floats), except pure powers (`x^3 - 2`).
* The inverse trigonometric functions give principal values only. Solutions that make a denominator zero are dropped.
* `ln` of a possibly negative argument stands for `ln` of its absolute value in integrals; `expandLog:` assumes positive
  factors. No assumptions are tracked, so `sqrt(x^2)` is not `abs(x)`.
* `integrate:` fails (with a `SymError`) on `exp(x^2)`, `sin(x)/x` and the like; `limit:at:` cannot do differences of
  growing roots such as `sqrt(x^2+x) - x`.
* `apart` needs rational numbers as coefficients (not `1/((x-a)(x-b))`); `collect:in:` and `degree:in:` need a polynomial.
* Decimals in text such as `0.25` are read as exact fractions. Names are runs of letters and digits, so write `x*y`, not `xy`.
* `simplify` picks the smallest of a few rewritings; it does not prove all identities.

## Files

`classes.st` the classes; `expr.st` nodes and their standard forms; `print.st` text, LaTeX and pictures; `parser.st`;
`poly.st` `SymPoly` (polynomials over the rationals, factoring, roots) and `SymLinear` (exact elimination);
`manip.st` expand, together, cancel, apart, factor, simplify, trigonometry, evaluation; `calculus.st`; `solve.st`;
`api.st` the front door `Algebra`; `tool.st` the workspace `AlgebraTool`; `tutorial.st` (`AlgebraTutorial`, 19 lessons);
`tests/tests.txt` (643 checks, each `expression ==> expected printString`).
