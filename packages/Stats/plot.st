"Plots made of characters, for a terminal.

None of these is a picture; they are what you draw when all you have is a screen full of letters, and they
are enough to see the shape of something, which is usually all you wanted. Every one answers a String."

Object subclass: #TextPlot instanceVariableNames: '' classVariableNames: '' category: 'Stats-Plots'!

!TextPlot class methodsFor: 'helpers'!
pad: aString to: aWidth
	^aString, (String new: (aWidth - aString size max: 0) withAll: (Character value: 32))!
padLeft: aString to: aWidth
	^(String new: (aWidth - aString size max: 0) withAll: (Character value: 32)), aString!
number: aNumber
	aNumber isInteger ifTrue: [^aNumber printString].
	^aNumber asFloat printShowingDecimalPlaces: 3!
bar: aLength
	^String new: (aLength max: 0) withAll: $#! !

!TextPlot class methodsFor: 'histograms'!
histogram: aCollection
	^self histogram: aCollection bins: 10!
histogram: aCollection bins: aCount
	^self histogram: aCollection bins: aCount width: 40!
histogram: aCollection bins: aCount width: aWidth
	"counts in equal-width bins, drawn as bars"
	| v lo hi step counts index out most labels labelWidth |
	v := Statistics numbersOf: aCollection.
	v isEmpty ifTrue: [^'(nothing to plot)', (String with: Character lf)].
	lo := Statistics minimum: v.
	hi := Statistics maximum: v.
	hi = lo ifTrue: [
		^'all ', v size printString, ' values are ', (self number: lo), (String with: Character lf)].
	step := (hi - lo) / aCount asFloat.
	counts := Array new: aCount withAll: 0.
	v do: [:each |
		index := ((each - lo) / step) truncated + 1.
		index > aCount ifTrue: [index := aCount].
		index < 1 ifTrue: [index := 1].
		counts at: index put: (counts at: index) + 1].
	most := 0.
	counts do: [:each | most := most max: each].
	labels := (1 to: aCount) collect: [:i |
		(self number: lo + ((i - 1) * step)), ' to ', (self number: lo + (i * step))].
	labelWidth := 0.
	labels do: [:each | labelWidth := labelWidth max: each size].
	out := WriteStream on: String new.
	1 to: aCount do: [:i |
		out nextPutAll: (self pad: (labels at: i) to: labelWidth + 2);
			nextPutAll: (self padLeft: (counts at: i) printString to: 5);
			nextPutAll: '  ';
			nextPutAll: (self bar: (most = 0 ifTrue: [0] ifFalse: [((counts at: i) * aWidth / most) rounded]));
			nl].
	out nextPutAll: 'n = '; print: v size; nl.
	^out contents!
bars: aDictionaryOrTable
	^self bars: aDictionaryOrTable width: 40!
bars: aDictionary width: aWidth
	"one bar per key, biggest first"
	| keys labelWidth most out value |
	aDictionary isEmpty ifTrue: [^'(nothing to plot)', (String with: Character lf)].
	keys := (aDictionary keys asSortedCollection: [:a :b |
		(aDictionary at: a) = (aDictionary at: b)
			ifTrue: [a displayString <= b displayString]
			ifFalse: [(aDictionary at: a) > (aDictionary at: b)]]) asArray.
	labelWidth := 0.
	keys do: [:each | labelWidth := labelWidth max: each displayString size].
	most := 0.
	aDictionary do: [:each | most := most max: each].
	out := WriteStream on: String new.
	keys do: [:key |
		value := aDictionary at: key.
		out nextPutAll: (self pad: key displayString to: labelWidth + 2);
			nextPutAll: (self padLeft: (self number: value) to: 8);
			nextPutAll: '  ';
			nextPutAll: (self bar: (most = 0 ifTrue: [0] ifFalse: [(value * aWidth / most) rounded]));
			nl].
	^out contents! !

!TextPlot class methodsFor: 'box plots'!
boxPlot: aCollection
	^self boxPlot: aCollection width: 60!
boxPlot: aCollection width: aWidth
	"the five-number summary drawn on a line, with the outliers marked"
	| v five lo hi line scale place out outliers |
	v := Statistics numbersOf: aCollection.
	v size < 2 ifTrue: [^'(too little to plot)', (String with: Character lf)].
	five := Statistics fiveNumberSummary: v.
	lo := five first. hi := five last.
	hi = lo ifTrue: [^'all ', v size printString, ' values are ', (self number: lo), (String with: Character lf)].
	scale := (aWidth - 1) / (hi - lo) asFloat.
	place := [:x | ((x - lo) * scale) rounded + 1].
	line := String new: aWidth withAll: (Character value: 32).
	((place value: (five at: 2)) to: (place value: (five at: 4))) do: [:i | line at: i put: $-].
	line at: (place value: (five at: 2)) put: $[.
	line at: (place value: (five at: 4)) put: $].
	line at: (place value: (five at: 3)) put: $|.
	line at: (place value: lo) put: $<.
	line at: (place value: hi) put: $>.
	out := WriteStream on: String new.
	out nextPutAll: line; nl.
	out nextPutAll: 'min '; nextPutAll: (self number: lo);
		nextPutAll: '   Q1 '; nextPutAll: (self number: (five at: 2));
		nextPutAll: '   median '; nextPutAll: (self number: (five at: 3));
		nextPutAll: '   Q3 '; nextPutAll: (self number: (five at: 4));
		nextPutAll: '   max '; nextPutAll: (self number: hi); nl.
	outliers := Statistics outliers: v.
	outliers isEmpty ifFalse: [
		out nextPutAll: 'outliers: '.
		outliers do: [:each | out nextPutAll: (self number: each); nextPutAll: ' '].
		out nl].
	^out contents! !

!TextPlot class methodsFor: 'scatter'!
scatter: xValues and: yValues
	^self scatter: xValues and: yValues width: 60 height: 20!
scatter: xValues and: yValues width: aWidth height: aHeight
	"a grid with a mark where there is a point, and a digit where several fall together"
	| pair x y minX maxX minY maxY grid out col row counts n |
	pair := Statistics pairsOf: xValues and: yValues.
	x := pair first. y := pair last.
	x size < 2 ifTrue: [^'(too little to plot)', (String with: Character lf)].
	minX := Statistics minimum: x. maxX := Statistics maximum: x.
	minY := Statistics minimum: y. maxY := Statistics maximum: y.
	maxX = minX ifTrue: [maxX := minX + 1].
	maxY = minY ifTrue: [maxY := minY + 1].
	grid := (1 to: aHeight) collect: [:i | String new: aWidth withAll: (Character value: 32)].
	counts := Dictionary new.
	1 to: x size do: [:i |
		col := (((x at: i) - minX) * (aWidth - 1) / (maxX - minX) asFloat) rounded + 1.
		row := aHeight - ((((y at: i) - minY) * (aHeight - 1) / (maxY - minY) asFloat) rounded).
		row := (row max: 1) min: aHeight.
		col := (col max: 1) min: aWidth.
		n := (counts at: (Array with: row with: col) ifAbsent: [0]) + 1.
		counts at: (Array with: row with: col) put: n.
		(grid at: row) at: col put: (n = 1 ifTrue: [$*] ifFalse: [n < 10 ifTrue: [(Character value: 48 + n)] ifFalse: [$@]])].
	out := WriteStream on: String new.
	out nextPutAll: (self padLeft: (self number: maxY) to: 10); nextPutAll: ' +';
		nextPutAll: (String new: aWidth withAll: $-); nl.
	grid doWithIndex: [:line :i |
		out nextPutAll: (self padLeft: '' to: 10); nextPutAll: ' |'; nextPutAll: line; nl].
	out nextPutAll: (self padLeft: (self number: minY) to: 10); nextPutAll: ' +';
		nextPutAll: (String new: aWidth withAll: $-); nl.
	out nextPutAll: (self padLeft: '' to: 11);
		nextPutAll: (self pad: (self number: minX) to: aWidth - (self number: maxX) size);
		nextPutAll: (self number: maxX); nl.
	^out contents!
scatter: xValues and: yValues withLine: aRegression
	"the same, with the fitted line written under it"
	^(self scatter: xValues and: yValues), aRegression equation, (String with: Character lf)! !

!TextPlot class methodsFor: 'sparklines'!
sparkline: aCollection
	"the shape of a series in one line, using nine steps of ASCII"
	| v lo hi steps out index |
	v := Statistics numbersOf: aCollection.
	v isEmpty ifTrue: [^''].
	lo := Statistics minimum: v.
	hi := Statistics maximum: v.
	steps := '_.:-=+*#@'.
	hi = lo ifTrue: [^String new: v size withAll: $-].
	out := WriteStream on: String new.
	v do: [:each |
		index := ((each - lo) * (steps size - 1) / (hi - lo) asFloat) rounded + 1.
		out nextPut: (steps at: index)].
	^out contents!
line: aCollection
	^self line: aCollection width: 60 height: 15!
line: aCollection width: aWidth height: aHeight
	"the series plotted against its position"
	| v |
	v := Statistics numbersOf: aCollection.
	^self scatter: (1 to: v size) and: v width: aWidth height: aHeight! !

!TextPlot class methodsFor: 'tables of numbers'!
distribution: aCollection
	"the histogram, the box plot and the summary together: the three things you look at first"
	| v out |
	v := Statistics numbersOf: aCollection.
	out := WriteStream on: String new.
	out nextPutAll: (Statistics summaryOf: v); nl.
	out nextPutAll: (self histogram: v); nl.
	out nextPutAll: (self boxPlot: v).
	^out contents! !
