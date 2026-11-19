"The special functions and the distributions the tests need to turn a statistic into a p-value.

Everything here is a class-side method on Distribution, and everything is a Float. The two workhorses are the
regularized incomplete gamma and beta functions: between them they give the chi-square, t, F and normal tail
areas, which is every p-value this package reports.

The algorithms are the standard ones (Lanczos for the log gamma, a series below the mean and a continued
fraction above it for the incomplete gamma, a continued fraction for the incomplete beta), and they agree with
published tables to about ten digits."

Object subclass: #Distribution instanceVariableNames: '' classVariableNames: 'LanczosCoefficients' category: 'Stats-Distributions'!
Error subclass: #StatsError instanceVariableNames: '' classVariableNames: '' category: 'Stats'!

!Distribution class methodsFor: 'constants'!
epsilon
	^1.0e-14!
tiny
	^1.0e-300!
maximumIterations
	^300!
sqrtTwoPi
	^2.5066282746310002!
sqrtTwo
	^1.4142135623730951! !

!Distribution class methodsFor: 'the gamma function'!
lanczos
	"the coefficients of the Lanczos approximation, g = 7, n = 9"
	^LanczosCoefficients ifNil: [LanczosCoefficients := #(
		0.99999999999980993 676.5203681218851 -1259.1392167224028
		771.32342877765313 -176.61502916214059 12.507343278686905
		-0.13857109526572012 9.9843695780195716e-6 1.5056327351493116e-7)]!
lnGamma: x
	"the natural logarithm of the gamma function, by the Lanczos approximation"
	| c z sum t |
	x < 0.5 ifTrue: [
		"the reflection formula, for the left half of the line"
		^(Float pi ln) - ((Float pi * x) sin) abs ln - (self lnGamma: 1.0 - x)].
	c := self lanczos.
	z := x - 1.0.
	sum := c at: 1.
	1 to: 8 do: [:i | sum := sum + ((c at: i + 1) / (z + i))].
	t := z + 7.5.
	^(self sqrtTwoPi ln) + sum ln + ((z + 0.5) * t ln) - t!
gamma: x
	^(self lnGamma: x) exp!
lnBeta: a and: b
	^(self lnGamma: a) + (self lnGamma: b) - (self lnGamma: a + b)!
lnFactorial: n
	^self lnGamma: n + 1!
binomial: n choose: k
	(k < 0 or: [k > n]) ifTrue: [^0].
	^((self lnFactorial: n) - (self lnFactorial: k) - (self lnFactorial: n - k)) exp rounded! !

!Distribution class methodsFor: 'the incomplete gamma function'!
lowerGamma: a at: x
	"P(a,x): the regularized lower incomplete gamma function, which is the chi-square tail turned round"
	x < 0 ifTrue: [^StatsError new signal: 'the lower incomplete gamma wants x >= 0'].
	a <= 0 ifTrue: [^StatsError new signal: 'the lower incomplete gamma wants a > 0'].
	x = 0 ifTrue: [^0.0].
	x < (a + 1.0)
		ifTrue: [^self gammaSeries: a at: x]
		ifFalse: [^1.0 - (self gammaContinuedFraction: a at: x)]!
upperGamma: a at: x
	"Q(a,x) = 1 - P(a,x)"
	^1.0 - (self lowerGamma: a at: x)!
gammaSeries: a at: x
	"the series that converges quickly below the mean"
	| ap sum term |
	ap := a.
	sum := 1.0 / a.
	term := sum.
	self maximumIterations timesRepeat: [
		ap := ap + 1.0.
		term := term * x / ap.
		sum := sum + term.
		term abs < (sum abs * self epsilon) ifTrue: [
			^sum * (x ln * a - x - (self lnGamma: a)) exp]].
	^sum * (x ln * a - x - (self lnGamma: a)) exp!
gammaContinuedFraction: a at: x
	"the continued fraction that converges quickly above the mean, in Lentz's form"
	| b c d h an del |
	b := x + 1.0 - a.
	c := 1.0 / self tiny.
	d := 1.0 / b.
	h := d.
	1 to: self maximumIterations do: [:i |
		an := i negated * (i - a).
		b := b + 2.0.
		d := an * d + b.
		d abs < self tiny ifTrue: [d := self tiny].
		c := b + (an / c).
		c abs < self tiny ifTrue: [c := self tiny].
		d := 1.0 / d.
		del := d * c.
		h := h * del.
		(del - 1.0) abs < self epsilon ifTrue: [
			^(x ln * a - x - (self lnGamma: a)) exp * h]].
	^(x ln * a - x - (self lnGamma: a)) exp * h! !

!Distribution class methodsFor: 'the incomplete beta function'!
incompleteBeta: x a: a b: b
	"I_x(a,b), the regularized incomplete beta function, from which the t and F tails come"
	| front |
	(x < 0.0 or: [x > 1.0]) ifTrue: [^StatsError new signal: 'the incomplete beta wants x between 0 and 1'].
	x = 0.0 ifTrue: [^0.0].
	x = 1.0 ifTrue: [^1.0].
	front := ((a * x ln) + (b * (1.0 - x) ln) - (self lnBeta: a and: b)) exp.
	x < ((a + 1.0) / (a + b + 2.0))
		ifTrue: [^front * (self betaContinuedFraction: x a: a b: b) / a]
		ifFalse: [^1.0 - (front * (self betaContinuedFraction: 1.0 - x a: b b: a) / b)]!
betaContinuedFraction: x a: a b: b
	"Lentz's method on the continued fraction for the incomplete beta"
	| qab qap qam c d h m2 aa del |
	qab := a + b. qap := a + 1.0. qam := a - 1.0.
	c := 1.0.
	d := 1.0 - (qab * x / qap).
	d abs < self tiny ifTrue: [d := self tiny].
	d := 1.0 / d.
	h := d.
	1 to: self maximumIterations do: [:m |
		m2 := 2 * m.
		aa := m * (b - m) * x / ((qam + m2) * (a + m2)).
		d := 1.0 + (aa * d).
		d abs < self tiny ifTrue: [d := self tiny].
		c := 1.0 + (aa / c).
		c abs < self tiny ifTrue: [c := self tiny].
		d := 1.0 / d.
		h := h * d * c.
		aa := (a + m) negated * (qab + m) * x / ((a + m2) * (qap + m2)).
		d := 1.0 + (aa * d).
		d abs < self tiny ifTrue: [d := self tiny].
		c := 1.0 + (aa / c).
		c abs < self tiny ifTrue: [c := self tiny].
		d := 1.0 / d.
		del := d * c.
		h := h * del.
		(del - 1.0) abs < self epsilon ifTrue: [^h]].
	^h! !

!Distribution class methodsFor: 'the normal distribution'!
normalPDF: x
	^(x * x / -2.0) exp / self sqrtTwoPi!
normalCDF: x
	"the share of a standard normal below x"
	^0.5 * (1.0 + (self erf: x / self sqrtTwo))!
normalTail: x
	"the share above x"
	^1.0 - (self normalCDF: x)!
erf: x
	"the error function, from the incomplete gamma"
	x = 0.0 ifTrue: [^0.0].
	x < 0.0 ifTrue: [^(self lowerGamma: 0.5 at: x * x) negated].
	^self lowerGamma: 0.5 at: x * x!
erfc: x
	^1.0 - (self erf: x)!
normalQuantile: p
	"the x with that much of a standard normal below it; Acklam's rational approximation, then two
	steps of Newton's method, which takes it to the last digit or two"
	| q r x e u |
	(p <= 0.0 or: [p >= 1.0]) ifTrue: [^StatsError new signal: 'a quantile wants p strictly between 0 and 1'].
	x := self roughNormalQuantile: p.
	2 timesRepeat: [
		e := (self normalCDF: x) - p.
		u := e * self sqrtTwoPi * (x * x / 2.0) exp.
		x := x - (u / (1.0 + (x * u / 2.0)))].
	^x!
roughNormalQuantile: p
	| a b c d plow phigh q r |
	a := #(-39.69683028665376 220.9460984245205 -275.9285104469687 138.3577518672690 -30.66479806614716 2.506628277459239).
	b := #(-54.47609879822406 161.5858368580409 -155.6989798598866 66.80131188771972 -13.28068155288572).
	c := #(-0.007784894002430293 -0.3223964580411365 -2.400758277161838 -2.549732539343734 4.374664141464968 2.938163982698783).
	d := #(0.007784695709041462 0.3224671290700398 2.445134137142996 3.754408661907416).
	plow := 0.02425.
	phigh := 1.0 - plow.
	p < plow ifTrue: [
		q := (-2.0 * p ln) sqrt.
		^((((((c at: 1) * q + (c at: 2)) * q + (c at: 3)) * q + (c at: 4)) * q + (c at: 5)) * q + (c at: 6))
			/ (((((d at: 1) * q + (d at: 2)) * q + (d at: 3)) * q + (d at: 4)) * q + 1.0)].
	p > phigh ifTrue: [
		q := (-2.0 * (1.0 - p) ln) sqrt.
		^(((((((c at: 1) * q + (c at: 2)) * q + (c at: 3)) * q + (c at: 4)) * q + (c at: 5)) * q + (c at: 6))
			/ (((((d at: 1) * q + (d at: 2)) * q + (d at: 3)) * q + (d at: 4)) * q + 1.0)) negated].
	q := p - 0.5.
	r := q * q.
	^((((((a at: 1) * r + (a at: 2)) * r + (a at: 3)) * r + (a at: 4)) * r + (a at: 5)) * r + (a at: 6)) * q
		/ ((((((b at: 1) * r + (b at: 2)) * r + (b at: 3)) * r + (b at: 4)) * r + (b at: 5)) * r + 1.0)! !

!Distribution class methodsFor: 'Student t'!
tCDF: t df: df
	"the share of a t distribution with df degrees of freedom below t"
	| x p |
	df <= 0 ifTrue: [^StatsError new signal: 'a t distribution wants more than nothing to go on'].
	x := df / (df + (t * t)) asFloat.
	p := 0.5 * (self incompleteBeta: x a: df / 2.0 b: 0.5).
	^t > 0 ifTrue: [1.0 - p] ifFalse: [p]!
tTail: t df: df
	"the one-sided p-value: the share further out than t in one direction"
	^1.0 - (self tCDF: t abs df: df)!
tTwoTail: t df: df
	"the two-sided p-value"
	| p |
	p := 2.0 * (self tTail: t df: df).
	^p min: 1.0!
tQuantile: p df: df
	"the t with that much below it, found by bisection on the CDF"
	^self invert: [:x | self tCDF: x df: df] for: p from: -200.0 to: 200.0! !

!Distribution class methodsFor: 'chi-square'!
chiSquareCDF: x df: df
	x <= 0 ifTrue: [^0.0].
	^self lowerGamma: df / 2.0 at: x / 2.0!
chiSquareTail: x df: df
	"the p-value of a chi-square statistic"
	^1.0 - (self chiSquareCDF: x df: df)!
chiSquareQuantile: p df: df
	^self invert: [:x | self chiSquareCDF: x df: df] for: p from: 0.0 to: 100000.0! !

!Distribution class methodsFor: 'F'!
fCDF: x df1: d1 df2: d2
	x <= 0 ifTrue: [^0.0].
	^self incompleteBeta: (d1 * x) / ((d1 * x) + d2) a: d1 / 2.0 b: d2 / 2.0!
fTail: x df1: d1 df2: d2
	"the p-value of an F statistic, which is always the upper tail"
	^1.0 - (self fCDF: x df1: d1 df2: d2)!
fQuantile: p df1: d1 df2: d2
	^self invert: [:x | self fCDF: x df1: d1 df2: d2] for: p from: 0.0 to: 100000.0! !

!Distribution class methodsFor: 'inverting'!
invert: aBlock for: p from: low to: high
	"bisection: slow, but it cannot wander off, and a quantile is not asked for in an inner loop"
	| a b mid value |
	(p <= 0.0 or: [p >= 1.0]) ifTrue: [^StatsError new signal: 'a quantile wants p strictly between 0 and 1'].
	a := low. b := high.
	200 timesRepeat: [
		mid := (a + b) / 2.0.
		value := aBlock value: mid.
		(b - a) abs < 1.0e-12 ifTrue: [^mid].
		value < p ifTrue: [a := mid] ifFalse: [b := mid]].
	^(a + b) / 2.0! !
