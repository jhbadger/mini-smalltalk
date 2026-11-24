"The Algebra tutorial: writing formulas, exact numbers, expanding and simplifying, factoring, substituting, polynomials,
rational functions, solving equations and systems, derivatives, integrals, limits and series, sums, trigonometry and
logarithms, the workspace, printing, how it works inside, and what it cannot do.  The examples are live; start it with
AlgebraTutorial go"

AbstractTutorial subclass: #AlgebraTutorial instanceVariableNames: '' classVariableNames: '' category: 'Algebra'!

!AlgebraTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Algebra'!
lessonSelectors
	^#(#welcome #reading #exact #expanding #factoring #evaluating #polynomials #fractions #solving #systems #derivatives #integrals #limits #sums #trig #workspace #pretty #inside #whatnext)! !

!AlgebraTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'This package is a small computer algebra system: it works with formulas rather than with numbers. Where 2 + 3 gives 5, the formula x + x gives 2*x, and (x+1)^2 can be multiplied out, factored, differentiated, integrated, or solved for x, all exactly, with no rounding.

Everything here is live. Select a line and press ctrl-P (print it) to run it.

The front door is the class Algebra. You give it formulas as text, and it answers with a formula, which prints as text:

Algebra expand: ''(x+1)^3''
Algebra factor: ''x^4 - 1''
Algebra diff: ''x*sin(x)''
Algebra integrate: ''x*exp(x)''
Algebra solve: ''x^2 - 2 = 0''

Exact means exact. Square roots stay as roots, fractions stay as fractions, and whole numbers have no limit in size:

Algebra parse: ''sqrt(8)''
Algebra parse: ''1/3 + 1/6''
Algebra parse: ''2^100''

When something is wrong, either with the text or with the mathematics, you get a SymError whose message says what:

[Algebra parse: ''1/0''] on: SymError do: [:e | e messageText]
[Algebra parse: ''2 +''] on: SymError do: [:e | e messageText]

The lessons go from writing formulas, through algebra and calculus, to the workspace and a look at how it works inside.'!
reading
	^TutorialLesson title: 'Writing formulas' text:
'A formula is written the way you would type it. Juxtaposition means multiplication, so 3x^2 is 3*x^2 and (x+1)(x-1) is a product. The power ^ binds tighter than * and /, and is right-associative, so 2^3^2 is 2^9. A minus sign in front of a power applies after it: -x^2 is -(x^2).

Algebra parse: ''3x^2 + 2*x - 5''
Algebra parse: ''(x+1)(x-1)''
Algebra parse: ''2^3^2''
Algebra parse: ''-x^2''
Algebra parse: ''(-x)^2''

A name is a run of letters and digits, so xy is one symbol called xy. Write x*y or x y for a product. The names pi, e and i are constants, and oo is infinity (used in limits). The functions are sin cos tan cot sec csc asin acos atan sinh cosh tanh exp ln log sqrt and abs. Their arguments always go in brackets. log(a, b) is the logarithm of b to base a.

Algebra parse: ''sin(x)^2 + cos(x)^2''
Algebra parse: ''log(2, 8)''
Algebra parse: ''e^x''
Algebra parse: ''pi*r^2''

Decimals are read as exact fractions: 0.25 is one quarter.

Algebra parse: ''0.25 x''

The answer is always put in a standard form: the highest power first, the constant last, like terms collected and numbers worked out. That is why two ways of writing the same thing print the same:

Algebra parse: ''5 - 3x + x^2''
Algebra parse: ''y*x + x*y''
Algebra parse: ''x/y/z''

You can also pass a number or an expression you built already; the methods of Algebra accept all three.

Algebra parse: 3/4'!
exact
	^TutorialLesson title: 'Exact numbers' text:
'Whole numbers and fractions are exact, and roots of them are kept exact as surds, with squares taken out of the root:

Algebra parse: ''sqrt(12)''
Algebra parse: ''sqrt(1/2)''
Algebra parse: ''sqrt(2)*sqrt(8)''
Algebra parse: ''sqrt(2)*sqrt(3)''
Algebra parse: ''8^(1/3)''
Algebra parse: ''2^(3/2)''

The square root of a negative number brings in i, and the powers of i cycle through i, -1, -i, 1:

Algebra parse: ''sqrt(-4)''
Algebra parse: ''i^2''
Algebra parse: ''i^5''
Algebra expand: ''(2+3i)(1-i)''

Trigonometric functions of the usual angles, multiples of pi/6 and pi/4, come out exactly:

Algebra parse: ''sin(pi/6)''
Algebra parse: ''cos(pi/4)''
Algebra parse: ''tan(pi/3)''
Algebra parse: ''sin(7*pi/6)''

When you do want a decimal, ask for one. numeric: answers a Float, so it is only for formulas with no unknowns left (apart from pi):

Algebra numeric: ''sqrt(2) + pi''
Algebra numeric: ''x^2 + 1'' with: ''x=3''

The few things that are not exact are Floats that you put in yourself, and the numeric roots of polynomials that do not factor (see the lesson on polynomials).'!
expanding
	^TutorialLesson title: 'Expanding and simplifying' text:
'expand multiplies everything out and collects like terms. The standard form never multiplies out behind your back: (x+1)^2 stays as it is until you ask.

Algebra parse: ''(x+1)^2''
Algebra expand: ''(x+1)^2''
Algebra expand: ''(x+y)^2 - (x-y)^2''
Algebra expand: ''(a+b+c)^2''
Algebra expand: ''(sqrt(2)+1)(sqrt(2)-1)''
Algebra expand: ''(x+1)^2/x''

The binomial theorem and Pascal''s triangle are in there too:

Algebra binomial: ''a'' with: ''b'' power: 4
Algebra pascalRow: 6

simplify tries several rewritings (multiplying out, cancelling common factors, the trigonometric identities) and keeps the smallest result:

Algebra simplify: ''(x+1)^2 - x^2''
Algebra simplify: ''(x^2-1)/(x-1)''
Algebra simplify: ''1/(x+1) + x/(x+1)''
Algebra simplify: ''sin(x)^2 + cos(x)^2''
Algebra simplify: ''1 - sin(x)^2''

To ask whether two formulas are the same, isEqual:to: simplifies their difference. It answers false when it cannot prove them equal, so false means not shown equal. seemsEqual:to: instead compares numbers at several points, which is evidence and not proof:

Algebra isEqual: ''(x+1)^2'' to: ''x^2 + 2x + 1''
Algebra isEqual: ''(x+1)^2'' to: ''x^2 + 1''
Algebra seemsEqual: ''sin(2x)'' to: ''2 sin(x) cos(x)''

collect:in: groups a polynomial by the powers of one symbol:

Algebra collect: ''a x + b x + c'' in: ''x''
Algebra collect: ''x^2 y + x y + x^2 + 3'' in: ''x'''!
factoring
	^TutorialLesson title: 'Factoring' text:
'factor writes a polynomial as a product of irreducible factors over the rationals. It takes out common factors, finds rational roots, and uses Kronecker''s method for what is left, so it gets factors that are not found by inspection:

Algebra factor: ''x^2 - 5x + 6''
Algebra factor: ''x^4 - 1''
Algebra factor: ''x^6 - 1''
Algebra factor: ''x^4 + 4''
Algebra factor: ''12x^3 - 8x^2 + 3x - 2''
Algebra factor: ''x^10 - 1''

A polynomial with no factors over the rationals is left alone, even when it has roots that are not rational:

Algebra factor: ''x^2 - 2''
Algebra factor: ''x^2 + 1''
Algebra factor: ''x^4 + 1''

A numeric factor goes in front, and the sign too:

Algebra factor: ''2x^2 - 8''
Algebra factor: ''4 - x^2''

With several symbols, common factors come out, and so do differences of squares, sums and differences of cubes, perfect squares, and any polynomial whose terms all have the same total degree:

Algebra factor: ''x^3 - x*y^2''
Algebra factor: ''a^3 + b^3''
Algebra factor: ''a^2 + 2 a b + b^2''
Algebra factor: ''x^2 + 3 x y + 2 y^2''

A function counts as a symbol while factoring:

Algebra factor: ''sin(x)^2 - 1''

Factoring a fraction factors the top and the bottom and cancels:

Algebra factor: ''(x^2-1)/(x^2-2x+1)''

A check you can always make is to expand the answer again:

Algebra isEqual: (Algebra factor: ''x^6 - 1'') to: ''x^6 - 1'''!
evaluating
	^TutorialLesson title: 'Substituting and evaluating' text:
'substitute:with: replaces symbols, all at once. The bindings are text like ''x=3, y=a+1'', or an Association, or an Array of Associations:

Algebra substitute: ''x^2 + y'' with: ''x=3, y=a''
Algebra substitute: ''x^2'' with: ''x=y+1''
Algebra substitute: ''sin(x)'' with: ''x=pi/6''
Algebra substitute: ''x*y'' with: (''x'' -> 4)

Because it is all at once, you can swap two symbols:

Algebra substitute: ''x + 2*y'' with: ''x=y, y=x''

evaluate:with: also works out what can be worked out, and numeric:with: gives a Float:

Algebra evaluate: ''(x^2-1)/(x-1)'' with: ''x=3''
Algebra numeric: ''exp(x)'' with: ''x=1''
[Algebra evaluate: ''1/x'' with: ''x=0''] on: SymError do: [:e | e messageText]

You can also build expressions without text. SymExpr has the constructors, and + - * / work on expressions:

(SymExpr sym: ''x'') * (SymExpr sym: ''x'') + 1
(SymExpr sym: ''x'') squared + ((SymExpr num: 2) * (SymExpr sym: ''x''))

variables: lists the symbols in a formula, and size: counts the nodes of its tree:

Algebra variables: ''a*x^2 + b*x + c + pi''
Algebra size: ''x^2 + 1'''!
polynomials
	^TutorialLesson title: 'Polynomials' text:
'degree:in:, coefficients:in: and the arithmetic of polynomials work with one symbol at a time. The coefficients come lowest power first, and may themselves be formulas:

Algebra degree: ''x^3 + 2x'' in: ''x''
Algebra coefficients: ''3x^2 + 2x + 1'' in: ''x''
Algebra coefficients: ''a x^2 + b x + c'' in: ''x''

Division with a remainder, and the greatest common divisor, which is how fractions are cancelled:

Algebra quotient: ''x^3 + 2x + 5'' by: ''x^2 + 1'' in: ''x''
Algebra remainder: ''x^3 + 2x + 5'' by: ''x^2 + 1'' in: ''x''
Algebra gcd: ''x^3 - 1'' with: ''x^2 - 1''

Roots as numbers. roots: answers the real roots as Floats, in order, and complexRoots: all of them as pairs of real and imaginary parts:

Algebra roots: ''x^3 - 6x^2 + 11x - 6''
Algebra roots: ''x^3 + x + 1''
Algebra complexRoots: ''x^2 + 1''

Horner form is the cheapest way to evaluate a polynomial by hand:

Algebra horner: ''2x^3 - 3x^2 + 5x - 7'' in: ''x''

The polynomial through some points (Lagrange interpolation), each point an Array of x and y:

Algebra lagrange: #(#(0 1) #(1 3) #(2 7)) in: ''x''
Algebra lagrange: #(#(1 1) #(2 4) #(3 9) #(4 16)) in: ''x''

Newton''s method, run exactly, shows the fractions that converge on the square root of 2. Each step roughly doubles the number of correct digits:

Algebra newton: ''x^2 - 2'' from: 1 steps: 4

Underneath, the class SymPoly is a polynomial with rational coefficients, lowest power first. You can use it directly:

(SymPoly coefficients: #(-1 0 1)) factor
((SymPoly coefficients: #(-1 0 0 1)) divMod: (SymPoly coefficients: #(-1 1))) first coeffs'!
fractions
	^TutorialLesson title: 'Rational functions' text:
'together puts a sum of fractions over one denominator, using the least common denominator it can see:

Algebra together: ''1/x + 1/y''
Algebra together: ''1/(x-1) + 1/(x+1)''
Algebra together: ''x + 1/x''

cancel removes what the top and the bottom have in common, by polynomial gcd for one symbol, and by factoring when there are several:

Algebra cancel: ''(x^2-1)/(x-1)''
Algebra cancel: ''(x^2-y^2)/(x-y)''
Algebra cancel: ''(x^3-1)/(x^2-1)''
Algebra cancel: ''(2x+2)/(4x+4)''

apart goes the other way, into partial fractions over the rationals. The denominator is factored first, and the pieces of the answer have a constant over each linear factor and a linear numerator over each irreducible quadratic:

Algebra apart: ''1/(x^2-1)''
Algebra apart: ''1/(x(x+1))''
Algebra apart: ''(x^3+1)/(x^2-1)''
Algebra apart: ''1/(x^2*(x+1))''
Algebra apart: ''(3x+5)/((x^2+1)(x-2))''

When the top is at least as big as the bottom you get the quotient polynomial first, as in the third one above. The result is a sum you can check by putting it together again:

Algebra isEqual: (Algebra apart: ''(5x-3)/(x^2-2x-3)'') to: ''(5x-3)/(x^2-2x-3)''

apart is what makes the integration of rational functions work, as the calculus lessons will show. It needs coefficients that are numbers, so it will not split 1/((x-a)(x-b)) with symbolic a and b:

[Algebra apart: ''1/((x-a)(x-b))'' in: ''x''] on: SymError do: [:e | e messageText]'!
solving
	^TutorialLesson title: 'Solving equations' text:
'solve: takes an equation as text, with an = sign (or just an expression, to be set equal to zero), and answers an Array of the solutions. If you do not name the unknown it uses the only symbol, or x.

Algebra solve: ''3x + 2 = 11''
Algebra solve: ''x^2 - 5x + 6 = 0''
Algebra solve: ''x^2 - 2 = 0''
Algebra solve: ''x^2 + 2x + 5 = 0''
Algebra solve: ''2x^2 - 4x + 1 = 0''

Cubics and beyond are solved by factoring over the rationals first. A factor that does not split further, of degree 3 or more, gives its real roots as Floats, except for the pure powers like x^3 - 2, which give exact roots:

Algebra solve: ''x^3 - 6x^2 + 11x - 6 = 0''
Algebra solve: ''2x^3 - 3x^2 - 8x + 12 = 0''
Algebra solve: ''x^4 - 5x^2 + 4 = 0''
Algebra solve: ''x^3 - 2 = 0''

Letters other than the unknown are treated as constants, so you get formulas back:

Algebra solve: ''a x^2 + b x + c = 0'' for: ''x''
Algebra solve: ''x*y = 6'' for: ''y''

When the unknown occurs once, it is peeled off like an onion, using inverse functions. Solutions that do not satisfy the original equation (the price of squaring) are thrown out:

Algebra solve: ''exp(x) = 5''
Algebra solve: ''2*exp(x) + 1 = 5''
Algebra solve: ''sqrt(x+1) = 3''
Algebra solve: ''sqrt(x) = -3''
Algebra solve: ''2^x = 8''

The inverse trigonometric functions give principal values only: sin(x) = 1/2 has infinitely many solutions, and you get the two in the first period.

Algebra solve: ''sin(x) = 1/2''

Solutions that would make a denominator zero are removed:

Algebra solve: ''(x^2-1)/(x-1) = 2''
Algebra solve: ''1/x + 1/(x+1) = 1'''!
systems
	^TutorialLesson title: 'Systems of equations' text:
'solveSystem:for: takes the equations and the unknowns. A linear system is solved exactly by elimination, and the answer can use letters:

Algebra solveSystem: #(''x+y=3'' ''x-y=1'') for: #(''x'' ''y'')
Algebra solveSystem: #(''2x+3y=7'' ''x-y=-1'') for: #(''x'' ''y'')
Algebra solveSystem: #(''x+y=a'' ''x-y=b'') for: #(''x'' ''y'')
Algebra solveSystem: #(''x+y+z=6'' ''x-y+z=2'' ''2x+y-z=1'') for: #(''x'' ''y'' ''z'')

The answer is an Array of solutions, each an Array of name -> value. A system with no solution gives an empty Array, and one that leaves an unknown free is an error:

Algebra solveSystem: #(''x+y=1'' ''x+y=2'') for: #(''x'' ''y'')
[Algebra solveSystem: #(''x+y=1'') for: #(''x'' ''y'')] on: SymError do: [:e | e messageText]

Nonlinear systems are solved by substitution: one equation is solved for one unknown, which is put into the rest. There may be several solutions:

Algebra solveSystem: #(''x+y=3'' ''x*y=2'') for: #(''x'' ''y'')
Algebra solveSystem: #(''x^2+y^2=25'' ''x-y=1'') for: #(''x'' ''y'')

Linear algebra on its own, with matrices, is in another package; this one only does what an elimination of equations needs.'!
derivatives
	^TutorialLesson title: 'Derivatives' text:
'diff: differentiates with respect to the only symbol (or x). The rules for sums, products, quotients, powers and the chain rule are all in, and so are the derivatives of the functions:

Algebra diff: ''x^3 + 2x^2 - 5x + 7''
Algebra diff: ''x*sin(x)''
Algebra diff: ''sin(x^2)''
Algebra diff: ''sqrt(x^2+1)''
Algebra diff: ''ln(x^2+1)''
Algebra diff: ''atan(x)''
Algebra diff: ''x^x''
Algebra diff: ''x^n''

The result is not tidied up: derivatives of quotients come out as written by the rules. Use simplify or cancel when you want them tidy, or isEqual:to: to check against a formula you expect:

Algebra diff: ''(x+1)/(x-1)''
Algebra simplify: (Algebra diff: ''(x+1)/(x-1)'')
Algebra isEqual: (Algebra diff: ''(x+1)/(x-1)'') to: ''-2/(x-1)^2''

Name the symbol to differentiate by, for partial derivatives; add times: for higher ones:

Algebra diff: ''x^2*y + y^3'' by: ''x''
Algebra diff: ''x^2*y + y^3'' by: ''y''
Algebra diff: ''x^5'' by: ''x'' times: 3
Algebra diff: ''sin(x)'' by: ''x'' times: 4

A Newton iteration, a tangent line, or a maximum all begin with a derivative. To find where a function has its flat points, solve its derivative for zero:

Algebra solve: (Algebra diff: ''x^3 - 3x'') for: ''x'''!
integrals
	^TutorialLesson title: 'Integrals' text:
'integrate: finds an antiderivative (with no constant added) by trying, in turn: a table of standard forms, also of a linear function of x; the reduction formulas for powers of sin and cos and for products of sines and cosines; partial fractions for rational functions, with logarithms and arctangents; substitution u = g(x); and integration by parts.

Algebra integrate: ''3x^2 + 2x + 1''
Algebra integrate: ''sin(3x+1)''
Algebra integrate: ''(2x+1)^3''
Algebra integrate: ''x*exp(x)''
Algebra integrate: ''x^2*sin(x)''
Algebra integrate: ''x*ln(x)''
Algebra integrate: ''2x*cos(x^2)''
Algebra integrate: ''sin(x)^2''
Algebra integrate: ''exp(x)*sin(x)''
Algebra integrate: ''1/(x^2-1)''
Algebra integrate: ''1/(x^2+2x+5)''
Algebra integrate: ''(3x+5)/((x^2+1)(x-2))''

The logarithm of an expression that may be negative stands for the logarithm of its absolute value, which is the usual convention. When no method works you get an error rather than a wrong answer:

[Algebra integrate: ''exp(x^2)''] on: SymError do: [:e | e messageText]

The surest test of an integral is to differentiate it:

Algebra isEqual: (Algebra diff: (Algebra integrate: ''x*exp(x)'')) to: ''x*exp(x)''
Algebra seemsEqual: (Algebra diff: (Algebra integrate: ''1/(x^2+x+1)'')) to: ''1/(x^2+x+1)''

A definite integral is the antiderivative at the two ends. The ends can be oo, which takes the limit:

Algebra integrate: ''x^2'' by: ''x'' from: 0 to: 3
Algebra integrate: ''sin(x)'' by: ''x'' from: 0 to: ''pi''
Algebra integrate: ''exp(-x)'' by: ''x'' from: 0 to: ''oo''
Algebra integrate: ''1/(1+x^2)'' by: ''x'' from: ''-oo'' to: ''oo''

Remember that this is only the difference of the antiderivative: if the integrand has a pole between the limits, the answer means nothing.'!
limits
	^TutorialLesson title: 'Limits and series' text:
'limit:at: finds what a formula approaches. The point is a number, oo or -oo. First it just substitutes. If that fails (0/0, or infinity), it cancels, then looks at the limits of the parts, and then uses l''Hopital''s rule, differentiating top and bottom. A power with the unknown in it is rewritten with exp and ln.

Algebra limit: ''sin(x)/x'' at: 0
Algebra limit: ''(x^2-1)/(x-1)'' at: 1
Algebra limit: ''(1-cos(x))/x^2'' at: 0
Algebra limit: ''(3x^2+1)/(2x^2-5)'' at: ''oo''
Algebra limit: ''x*ln(x)'' at: 0
Algebra limit: ''x*exp(-x)'' at: ''oo''
Algebra limit: ''(1+1/x)^x'' at: ''oo''
Algebra limit: ''atan(x)'' at: ''oo''

Infinity is a result as well as a place to go. When the two sides of a point disagree, there is no limit, and you are told:

Algebra limit: ''1/x^2'' at: 0
Algebra limit: ''x^2 - x^3'' at: ''oo''
[Algebra limit: ''1/x'' at: 0] on: SymError do: [:e | e messageText]

Differences of two quantities that both grow, such as sqrt(x^2+x) - x, are beyond the method, and give an error.

series:in:at:order: is the Taylor polynomial through a given power of (x - a), and taylor:order: the same at 0:

Algebra series: ''exp(x)'' in: ''x'' at: 0 order: 4
Algebra series: ''sin(x)'' in: ''x'' at: 0 order: 5
Algebra series: ''ln(x)'' in: ''x'' at: 1 order: 3
Algebra series: ''sqrt(x)'' in: ''x'' at: 1 order: 2
Algebra taylor: ''sin(x)*cos(x)'' order: 3

Compare with the function: the polynomial agrees closely near the point.

Algebra numeric: ''exp(x)'' with: ''x=0.1''
Algebra numeric: (Algebra substitute: (Algebra taylor: ''exp(x)'' order: 4) with: ''x=0.1'')'!
sums
	^TutorialLesson title: 'Sums and products' text:
'sum:in:from:to: adds a formula over a range. With whole-number bounds the terms are simply added:

Algebra sum: ''k'' in: ''k'' from: 1 to: 100
Algebra sum: ''1/2^k'' in: ''k'' from: 1 to: 4
Algebra product: ''k'' in: ''k'' from: 1 to: 5

With a symbolic upper bound you get a closed form. For polynomials in the index it comes from Faulhaber''s formulas, found by interpolating the first few sums:

Algebra sum: ''k'' in: ''k'' from: 1 to: ''n''
Algebra sum: ''k^2'' in: ''k'' from: 1 to: ''n''
Algebra sum: ''k^3'' in: ''k'' from: 1 to: ''n''
Algebra sum: ''2k+1'' in: ''k'' from: 0 to: ''n''
Algebra sum: ''a*k + b'' in: ''k'' from: 1 to: ''n''

The sum of a geometric series, a ratio to the power of the index, has its closed form too:

Algebra sum: ''2^k'' in: ''k'' from: 0 to: ''n''

The lower bound can be anything:

Algebra sum: ''k'' in: ''k'' from: 5 to: ''n''

A sum that has no closed form of this kind is an error:

[Algebra sum: ''1/k'' in: ''k'' from: 1 to: ''n''] on: SymError do: [:e | e messageText]

You can use a closed form to check a guess: the first sums of odd numbers are squares.

Algebra sum: ''2k-1'' in: ''k'' from: 1 to: ''n''
Algebra fibonacci: 12'!
trig
	^TutorialLesson title: 'Trigonometry and logarithms' text:
'The trigonometric identities that the system knows are used by simplify and trigSimplify:, which pairs up sin^2 and cos^2:

Algebra trigSimplify: ''sin(x)^2 + cos(x)^2''
Algebra trigSimplify: ''3 sin(y)^2 x + 3 cos(y)^2 x''
Algebra simplify: ''1 - cos(x)^2''

trigExpand: writes sines and cosines of sums and of multiples in terms of the parts, and multiplies out:

Algebra trigExpand: ''sin(x+y)''
Algebra trigExpand: ''cos(2x)''
Algebra trigExpand: ''sin(3x)''
Algebra trigExpand: ''cos(x-y)''

Some are automatic, because they are true everywhere: sin of minus x, and the inverse functions undoing their functions:

Algebra parse: ''sin(-x)''
Algebra parse: ''cos(asin(x))''
Algebra parse: ''exp(ln(x))''
Algebra parse: ''exp(x)*exp(y)''

Logarithms of whole numbers that are powers are reduced, so that natural logarithms of related numbers cancel:

Algebra parse: ''ln(8)''
Algebra parse: ''log(2, 8)''

expandLog: splits the logarithm of a product or a power. It assumes that the factors are positive, which is not always true, so it is not done automatically:

Algebra expandLog: ''ln(x*y)''
Algebra expandLog: ''ln(2*x^3)''
Algebra seemsEqual: ''ln(x*y)'' to: ''ln(x) + ln(y)''

The last one is false because at some points both x and y are negative, where ln(x*y) exists and the two logs do not.'!
workspace
	^TutorialLesson title: 'The workspace' text:
'The System menu has an item called algebra workspace. In it you select a line and print it. Each line is a command followed by its arguments, which are separated by commas, or just a formula. You can also start one from code:

AlgebraTool open

Here is the same thing without a window: evaluate: answers the text a window would show. Several lines give several lines of answer.

AlgebraTool evaluate: ''expand (x+1)^3''
AlgebraTool evaluate: ''diff x*sin(x), x''
AlgebraTool evaluate: ''integrate x^2, x, 0, 3''
AlgebraTool evaluate: ''limit sin(x)/x, x, 0''
AlgebraTool evaluate: ''solve x^2 = 4''
AlgebraTool evaluate: ''system x + y = 3 ; x - y = 1 for x y''
AlgebraTool evaluate: ''sum k^2, k, 1, 10''
AlgebraTool evaluate: ''subs x^2 + y, x=3, y=1''

let defines names. let p = ... names a formula, and let f(x) = ... defines a function. What you define is used in what you write afterwards:

AlgebraTool evaluate: ''let f(x) = x^2 + 1''
AlgebraTool evaluate: ''f(3)''
AlgebraTool evaluate: ''diff f(x), x''
AlgebraTool evaluate: ''let p = x^2 - 1''
AlgebraTool evaluate: ''factor p''
AlgebraTool evaluate: ''forget all''

Mistakes are reported in the answer, in place of the result:

AlgebraTool evaluate: ''1/0''
AlgebraTool evaluate: ''expand (x+1''

The commands are expand factor simplify together cancel apart diff integrate limit series solve system sum subs eval roots horner latex pretty. The last two give LaTeX source and a picture in characters:

AlgebraTool evaluate: ''latex (x+1)/(x^2+2)''
Algebra latex: ''sqrt(x)/2 + sin(x)^2'''!
pretty
	^TutorialLesson title: 'Printing formulas' text:
'A formula prints as text that you can type back in. For a picture, pretty answers a string with fraction bars and raised exponents, which you can show with displayNl. For documents, latex answers LaTeX source.

Algebra latex: ''x^2 + 3x - 5''
Algebra latex: ''(x+1)/(x^2+2)''
Algebra latex: ''pi*r^2''

The shape of the text is chosen for reading: highest powers first, constant last, a quotient as a/b, brackets only where needed. Negative terms are subtracted, and a minus in front of a sum has its bracket:

Algebra parse: ''a - (b + c)''
Algebra parse: ''-(x+1)''
Algebra parse: ''3x/2''
Algebra parse: ''1/(2*x)''
Algebra parse: ''sqrt(x)/2''

A formula remembers its text, so printing the same one again costs nothing. An expression also answers its kind, which is how you take one apart:

(Algebra parse: ''x+1'') isAdd
(Algebra parse: ''2x'') isMul
(Algebra parse: ''x^2'') isPow
(Algebra parse: ''sin(x)'') isFn
(Algebra parse: ''x+1'') terms

Pictures:

(Algebra pretty: ''(x+1)/(x^2+2)'') lines asArray
(Algebra pretty: ''sin(x)^2'') lines asArray'!
inside
	^TutorialLesson title: 'How it works' text:
'There are six kinds of node: SymNum (an Integer, Fraction or Float), SymSym (a symbol), SymAdd, SymMul, SymPow and SymFn (a function of one argument). Subtraction is adding a product with -1, and division is multiplying by a power of -1; there are no other kinds.

The nodes are built only by four class methods of SymExpr, and each of them puts the result in a standard form: sum:, product:, power:to: and fn:of:. They flatten, collect like terms, combine equal bases, fold the numbers, and apply identities. The form is unique for what it can see, so two formulas that are equal in that sense have the same key, and = compares keys:

(SymExpr sum: (Array with: (SymExpr sym: ''x'') with: (SymExpr sym: ''x''))) text
(Algebra parse: ''x+y'') key
(Algebra parse: ''y+x'') key
(Algebra parse: ''x+y'') = (Algebra parse: ''y+x'')

Two things are never done automatically: multiplying out, and factoring. A sum is never distributed over a product, since you might want it either way. Those are the methods expanded and factored of an expression. The operations on expressions are methods you can send:

(Algebra parse: ''(x+1)^2'') expanded
(Algebra parse: ''x^2-1'') factored
(Algebra parse: ''x^2'') diffIn: ''x''
(Algebra parse: ''sin(x)'') antiderivativeIn: ''x''

Polynomials in one symbol with rational coefficients are converted to SymPoly (asPolyIn:) for the heavy work: division, gcd, square-free decomposition, rational roots, Kronecker''s method for factors, and numeric roots by the Durand-Kerner iteration.

To teach the system a function, add a case to a few methods. For the derivative of a function, add one to SymFn>>slope; for its numeric value, one to SymExpr class>>floatFn:of:; for an exact special value, one to SymExpr class>>exactFn:of:. Here is how you can browse them:

Smalltalk at: #SymFn
(SymFn includesSelector: #slope)
(SymExpr class includesSelector: #exactFn:of:)'!
whatnext
	^TutorialLesson title: 'Limits and what next' text:
'Things this system does not do, so that you are not surprised: it does not factor over extensions of the rationals (x^2 - 2 stays), nor modulo a prime; it solves polynomial systems only by substitution; it has no inequalities and no assumptions (so sqrt(x^2) is not simplified to abs(x), and logarithms of products are not split unless you ask); the principal values of the inverse functions are the only ones given; the cubic and quartic formulas are not used (the real roots of irreducible factors of degree 3 or more come as Floats); integration does not know the special functions (so the integral of exp(x^2) is an error), and limits cannot do differences of growing roots; symbols are real, complex numbers are limited to i in exact results; and the answers are not always in the form you would choose, so simplify, expand, factor and cancel are there to push them into shape.

What it does well is the algebra of school and first-year courses, done exactly, with answers that you can check by differentiating, expanding, or substituting.

Things to try. Write a numerical check: compare Algebra numeric: of an integral with a sum of rectangles. Prove an identity with isEqual:to:. Build a table of Taylor polynomials for functions of your choice. Use solveSystem:for: to find the intersections of curves. Use Algebra lagrange: to fit the polynomial through the values of some sequence and guess a formula, then check it with sum:in:from:to:.

The package README is packages/Algebra/README.md. The source files are short: expr.st (the nodes and their standard forms), parser.st, print.st, poly.st (polynomials and factoring), manip.st (expand, together, cancel, apart, factor, simplify), calculus.st, solve.st, api.st, and tool.st (the workspace).

Other tutorials in this image:

Smalltalk tutorialNames

and the one for the language itself:

Smalltalk tutorial'! !
