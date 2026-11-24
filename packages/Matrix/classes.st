"The classes of the Matrix package.

A Matrix is a dense table of numbers with a fixed number of rows and columns. Its entries are ordinary Smalltalk
numbers, so a matrix of Integers and Fractions is exact (determinants, inverses, ranks and solutions come out as
exact fractions) and a matrix with a Float in it is computed in floating point. A vector is a Matrix with one column
(a column vector) or one row.

The decompositions answer small objects that hold their parts: MatrixLU, MatrixQR, MatrixSVD and MatrixEigen.
Complex eigenvalues are MatrixComplex numbers. Every failure the package detects is a MatrixError."

Error subclass: #MatrixError instanceVariableNames: '' classVariableNames: '' category: 'Matrix'!

Object subclass: #MatrixFormat instanceVariableNames: '' classVariableNames: '' category: 'Matrix'!
Object subclass: #MatrixComplex instanceVariableNames: 're im' classVariableNames: '' category: 'Matrix'!
Object subclass: #Matrix instanceVariableNames: 'rows cols cells' classVariableNames: 'Tolerance' category: 'Matrix'!
Object subclass: #MatrixLU instanceVariableNames: 'matrix lower upper permutation sign singular' classVariableNames: '' category: 'Matrix'!
Object subclass: #MatrixQR instanceVariableNames: 'matrix q r' classVariableNames: '' category: 'Matrix'!
Object subclass: #MatrixSVD instanceVariableNames: 'matrix u sigma v' classVariableNames: '' category: 'Matrix'!
Object subclass: #MatrixEigen instanceVariableNames: 'matrix values vectors' classVariableNames: '' category: 'Matrix'!

"---- showing numbers ----"

!MatrixFormat class methodsFor: 'numbers'!
number: x digits: d
	"an Integer as it is, a Fraction as 3/4, a Float rounded to d decimals with noise like 0.30000000000000004 gone"
	| scaled unit neg ip fp fs |
	x isInteger ifTrue: [^x printString].
	x isFloat ifFalse: [
		x isNumber ifFalse: [^x printString].
		^x numerator printString, '/', x denominator printString].
	(x isNaN or: [x isInfinite]) ifTrue: [^x printString].
	x abs >= 1.0e15 ifTrue: [^x printString].
	unit := 10 raisedTo: d.
	scaled := (x abs * unit) rounded.
	neg := x < 0 and: [scaled > 0].
	ip := scaled // unit.
	fp := scaled \\ unit.
	fs := fp printString.
	[fs size < d] whileTrue: [fs := '0', fs].
	[fs size > 1 and: [fs last = $0]] whileTrue: [fs := fs copyFrom: 1 to: fs size - 1].
	d = 0 ifTrue: [fs := '0'].
	^(neg ifTrue: ['-'] ifFalse: ['']), ip printString, '.', fs!
number: x
	^self number: x digits: 6!
padLeft: aString to: width
	| s |
	s := aString.
	[s size < width] whileTrue: [s := ' ', s].
	^s!
padRight: aString to: width
	| s |
	s := aString.
	[s size < width] whileTrue: [s := s, ' '].
	^s! !

"---- a complex number, for the eigenvalues of a real matrix ----"

!MatrixComplex class methodsFor: 'instance creation'!
re: a im: b
	^self basicNew setRe: a im: b!
real: a
	^self basicNew setRe: a im: 0! !

!MatrixComplex methodsFor: 'accessing'!
setRe: a im: b
	re := a. im := b!
re
	^re!
im
	^im!
real
	^re!
imaginary
	^im!
isReal
	^im = 0!
conjugate
	^MatrixComplex re: re im: im negated!
abs
	^((re * re) + (im * im)) asFloat sqrt!
argument
	^im asFloat arcTan2: re asFloat!
squaredAbs
	^(re * re) + (im * im)! !

!MatrixComplex methodsFor: 'arithmetic'!
coerce: other
	^other class == MatrixComplex ifTrue: [other] ifFalse: [MatrixComplex re: other im: 0]!
+ other
	| o |
	o := self coerce: other.
	^MatrixComplex re: re + o re im: im + o im!
- other
	| o |
	o := self coerce: other.
	^MatrixComplex re: re - o re im: im - o im!
* other
	| o |
	o := self coerce: other.
	^MatrixComplex re: (re * o re) - (im * o im) im: (re * o im) + (im * o re)!
/ other
	| o d |
	o := self coerce: other.
	d := o squaredAbs.
	d = 0 ifTrue: [^MatrixError new signal: 'division by a complex zero'].
	^MatrixComplex re: ((re * o re) + (im * o im)) / d im: ((im * o re) - (re * o im)) / d!
negated
	^MatrixComplex re: re negated im: im negated!
squared
	^self * self!
raisedTo: n
	| r |
	r := MatrixComplex re: 1 im: 0.
	n timesRepeat: [r := r * self].
	^r! !

!MatrixComplex methodsFor: 'comparing'!
= other
	^other class == MatrixComplex and: [re = other re and: [im = other im]]!
hash
	^re hash bitXor: im hash!
isCloseTo: other within: eps
	| o |
	o := self coerce: other.
	^(re - o re) abs <= eps and: [(im - o im) abs <= eps]!
isCloseTo: other
	^self isCloseTo: other within: Matrix tolerance * 1000! !

!MatrixComplex methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: (self printStringDigits: 6)!
printStringDigits: d
	| r i |
	r := MatrixFormat number: re digits: d.
	i := MatrixFormat number: im abs digits: d.
	im = 0 ifTrue: [^r].
	i = '0.0' ifTrue: [^r].
	(r = '0' or: [r = '0.0' or: [r = '-0.0']]) ifTrue: [^(im < 0 ifTrue: ['-'] ifFalse: ['']), i, 'i'].
	^r, (im < 0 ifTrue: ['-'] ifFalse: ['+']), i, 'i'! !
