"APLFormat: how arrays are shown. Numbers are written the way J writes them (a high minus is an underscore, floats have six
significant digits, a rational is 3r4); a vector is its items separated by a blank, a table has its columns right
aligned, text is shown as it is, a boxed array is drawn with box characters, and an array of rank 3 or more is shown
plane by plane with blank lines between the planes."

!APLFormat class methodsFor: 'numbers'!
integer: n
	| s |
	s := n printString.
	n < 0 ifTrue: [^'_', (s copyFrom: 2 to: s size)].
	^s!
fraction: f
	^(self integer: f numerator), 'r', f denominator printString!
float: f precision: p
	"six significant digits by default; whole floats of moderate size are written in full"
	| s e neg ip fp raw point exp n up dot digits out |
	f isNaN ifTrue: [^'_.'].
	f = Float infinity ifTrue: [^'_'].
	f = Float infinity negated ifTrue: [^'__'].
	f = 0 ifTrue: [^'0'].
	(f abs < 1.0e15 and: [f = f truncated]) ifTrue: [^self integer: f truncated].
	neg := f < 0.
	s := f abs printString.
	e := s indexOf: $e.
	e > 0
		ifTrue: [exp := (s copyFrom: e + 1 to: s size) asInteger. s := s copyFrom: 1 to: e - 1]
		ifFalse: [exp := 0].
	dot := s indexOf: $..
	dot = 0
		ifTrue: [ip := s. fp := '']
		ifFalse: [ip := s copyFrom: 1 to: dot - 1. fp := s copyFrom: dot + 1 to: s size].
	raw := ip, fp.
	point := ip size + exp.
	[raw size > 1 and: [raw first = $0]] whileTrue: [raw := raw copyFrom: 2 to: raw size. point := point - 1].
	raw := self stripZeros: raw.
	raw size > p ifTrue: [
		up := (raw at: p + 1) >= $5.
		raw := raw copyFrom: 1 to: p.
		up ifTrue: [
			n := raw asInteger + 1.
			raw := n printString.
			raw size > p ifTrue: [raw := raw copyFrom: 1 to: p. point := point + 1]].
		raw := self stripZeros: raw].
	(point > p or: [point < -3])
		ifTrue: [
			digits := raw copyFrom: 1 to: 1.
			raw size > 1 ifTrue: [digits := digits, '.', (raw copyFrom: 2 to: raw size)].
			out := digits, 'e', (self integer: point - 1)]
		ifFalse: [
			point <= 0
				ifTrue: [out := '0.', (String new: point negated withAll: $0), raw]
				ifFalse: [
					point >= raw size
						ifTrue: [out := raw, (String new: point - raw size withAll: $0)]
						ifFalse: [out := (raw copyFrom: 1 to: point), '.', (raw copyFrom: point + 1 to: raw size)]]].
	^neg ifTrue: ['_', out] ifFalse: [out]!
stripZeros: raw
	| n |
	n := raw size.
	[n > 1 and: [(raw at: n) = $0]] whileTrue: [n := n - 1].
	^raw copyFrom: 1 to: n!
item: x precision: p
	x isInteger ifTrue: [^self integer: x].
	x isFraction ifTrue: [^self fraction: x].
	x isFloat ifTrue: [^self float: x precision: p].
	x isCharacter ifTrue: [^String with: x].
	^'<box>'! !

!APLFormat class methodsFor: 'boxes'!
width: aString
	"how many columns a line takes: the bytes of a UTF-8 text less its continuation bytes"
	| n |
	n := 0.
	aString do: [:c | | v | v := c value. (v < 128 or: [v >= 192]) ifTrue: [n := n + 1]].
	^n!
repeat: aString times: n
	| ws |
	ws := WriteStream on: String new.
	n timesRepeat: [ws nextPutAll: aString].
	^ws contents!
boxedGrid: a precision: p
	"the lines of a boxed array of rank 2 or less drawn as a grid of boxes"
	| rows cols widths heights cells out line top bottom v mid |
	a rank = 0 ifTrue: [rows := 1. cols := 1]
		ifFalse: [
			a rank = 1 ifTrue: [rows := 1. cols := a shape first]
				ifFalse: [rows := a shape at: a rank - 1. cols := a shape at: a rank]].
	cells := Array new: rows * cols.
	1 to: rows * cols do: [:i | cells at: i put: (self render: (a data at: i) contents precision: p)].
	widths := Array new: cols withAll: 0.
	heights := Array new: rows withAll: 1.
	1 to: rows do: [:r |
		1 to: cols do: [:c | | ls |
			ls := cells at: (r - 1) * cols + c.
			ls do: [:l | widths at: c put: ((widths at: c) max: (self width: l))].
			heights at: r put: ((heights at: r) max: ls size)]].
	v := '│'.
	top := self rule: widths left: '┌' mid: '┬' right: '┐'.
	mid := self rule: widths left: '├' mid: '┼' right: '┤'.
	bottom := self rule: widths left: '└' mid: '┴' right: '┘'.
	out := OrderedCollection new.
	out add: top.
	1 to: rows do: [:r |
		r > 1 ifTrue: [out add: mid].
		1 to: (heights at: r) do: [:k |
			line := WriteStream on: String new.
			line nextPutAll: v.
			1 to: cols do: [:c | | ls t |
				ls := cells at: (r - 1) * cols + c.
				t := k <= ls size ifTrue: [ls at: k] ifFalse: [''].
				line nextPutAll: t.
				line nextPutAll: (String new: (widths at: c) - (self width: t) withAll: $ ).
				line nextPutAll: v].
			out add: line contents]].
	out add: bottom.
	^out!
rule: widths left: l mid: m right: r
	| ws |
	ws := WriteStream on: String new.
	ws nextPutAll: l.
	widths doWithIndex: [:w :i |
		i > 1 ifTrue: [ws nextPutAll: m].
		ws nextPutAll: (self repeat: '─' times: w)].
	ws nextPutAll: r.
	^ws contents! !

!APLFormat class methodsFor: 'arrays'!
text: a precision: p
	"the display of an array as one String, lines separated by line feeds"
	| ls ws |
	ls := self render: a precision: p.
	ws := WriteStream on: String new.
	ls doWithIndex: [:l :i | i > 1 ifTrue: [ws nextPut: Character lf]. ws nextPutAll: l].
	^ws contents!
render: a precision: p
	"the lines of the display of an array"
	| r rows cols planes out ls prod blanks leading boxed stop |
	a isAtom ifTrue: [
		a first class == APLBox ifTrue: [^self boxedGrid: a precision: p].
		^Array with: (self item: a first precision: p)].
	a size = 0 ifTrue: [^Array with: ''].
	r := a rank.
	rows := r = 1 ifTrue: [1] ifFalse: [a shape at: r - 1].
	cols := a shape at: r.
	planes := a size // (rows * cols).
	boxed := a isBoxed.
	leading := r > 2 ifTrue: [a shape copyFrom: 1 to: r - 2] ifFalse: [#()].
	out := OrderedCollection new.
	0 to: planes - 1 do: [:k |
		k > 0 ifTrue: [
			blanks := 1. prod := 1. stop := false.
			leading size to: 1 by: -1 do: [:ax |
				stop ifFalse: [
					prod := prod * (leading at: ax).
					k \\ prod = 0 ifTrue: [blanks := blanks + 1] ifFalse: [stop := true]]].
			1 to: blanks do: [:j | out add: '']].
		ls := boxed
			ifTrue: [self boxedGrid: (APLArray shape: (Array with: rows with: cols) data: (a data copyFrom: k * rows * cols + 1 to: (k + 1) * rows * cols)) precision: p]
			ifFalse: [self planeLines: a data from: k * rows * cols rows: rows cols: cols text: a isText precision: p].
		out addAll: ls].
	^out asArray!
planeLines: data from: offset rows: rows cols: cols text: isText precision: p
	| strs widths out line |
	isText ifTrue: [
		out := Array new: rows.
		1 to: rows do: [:r | | s |
			s := String new: cols.
			1 to: cols do: [:c | s at: c put: (data at: offset + (r - 1) * cols + c)].
			out at: r put: s].
		^out].
	strs := Array new: rows * cols.
	1 to: rows * cols do: [:i | strs at: i put: (self item: (data at: offset + i) precision: p)].
	widths := Array new: cols withAll: 0.
	1 to: rows do: [:r | 1 to: cols do: [:c | widths at: c put: ((widths at: c) max: (strs at: (r - 1) * cols + c) size)]].
	out := Array new: rows.
	1 to: rows do: [:r |
		line := WriteStream on: String new.
		1 to: cols do: [:c | | s |
			c > 1 ifTrue: [line nextPut: $ ].
			s := strs at: (r - 1) * cols + c.
			line nextPutAll: (String new: (widths at: c) - s size withAll: $ ).
			line nextPutAll: s].
		out at: r put: line contents].
	^out! !

!APLArray methodsFor: 'displaying'!
display
	"the text of this array as the language shows it"
	^APLFormat text: self precision: 6! !
