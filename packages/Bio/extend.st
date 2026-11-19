"A few general methods the Bio package needs that the kernel does not have. They are ordinary Smalltalk and mean
what they do in other Smalltalks, so they are kept apart here rather than hidden inside the bioinformatics classes."

!Number methodsFor: 'printing'!
printShowingDecimalPlaces: places
	"the receiver with exactly this many digits after the point: 3.14159 printShowingDecimalPlaces: 2  is  '3.14'"
	| neg scaled digits text |
	self isNaN ifTrue: [^'NaN'].
	self isInfinite ifTrue: [^self > 0 ifTrue: ['Infinity'] ifFalse: ['-Infinity']].
	places <= 0 ifTrue: [^self rounded printString].
	neg := self < 0.
	scaled := (self abs * (10 raisedTo: places)) rounded.
	digits := scaled printString.
	[digits size <= places] whileTrue: [digits := '0', digits].
	text := (digits copyFrom: 1 to: digits size - places), '.', (digits copyFrom: digits size - places + 1 to: digits size).
	^neg ifTrue: ['-', text] ifFalse: [text]! !
