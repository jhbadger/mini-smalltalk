"The structural primitives: shape, reshape, ravel, append, take, drop, from, reverse, rotate, transpose, link, raze, box and
open, and the number-system verbs. A verb here is a method of APLPrims taking the argument(s) as APLArrays; the
table in defineStructural gives each its spelling, its ranks and its selectors."

!APLPrims class methodsFor: 'helpers'!
compatible: x with: y
	^x size = 0 or: [y size = 0 or: [x kind == y kind]]!
cmp: a with: b
	"-1, 0 or 1 for two items: numbers by value, characters by code, boxes by their contents"
	(a isNumber and: [b isNumber]) ifTrue: [^a < b ifTrue: [-1] ifFalse: [a > b ifTrue: [1] ifFalse: [0]]].
	(a isCharacter and: [b isCharacter]) ifTrue: [^a value < b value ifTrue: [-1] ifFalse: [a value > b value ifTrue: [1] ifFalse: [0]]].
	(a class == APLBox and: [b class == APLBox]) ifTrue: [^self cmpArrays: a contents with: b contents].
	^APLError domain!
cmpArrays: a with: b
	| n c |
	n := a size min: b size.
	1 to: n do: [:i |
		c := self cmp: (a data at: i) with: (b data at: i).
		c = 0 ifFalse: [^c]].
	^a size < b size ifTrue: [-1] ifFalse: [a size > b size ifTrue: [1] ifFalse: [0]]!
keyOf: item
	"a value that hashes the same for items that compare equal, or nil if the item has none"
	item isInteger ifTrue: [^item].
	item isCharacter ifTrue: [^item].
	item isFloat ifTrue: [^(item = item truncated and: [item abs < 1.0e15]) ifTrue: [item truncated] ifFalse: [item]].
	item isFraction ifTrue: [^item].
	^nil!
ints: x
	"the integers of an array, as an Array"
	^x integers!
selectItems: idxs from: y
	"the items of y at the 0-based indices, along the first axis"
	| lists r |
	r := y rank.
	lists := Array new: r.
	lists at: 1 put: idxs.
	2 to: r do: [:a | lists at: a put: (0 to: (y shape at: a) - 1) asArray].
	^y gatherAxes: lists fill: y fill!
indexList: x count: n
	"the 0-based indices of an index array (negatives count from the end), checked against n"
	^x integers collect: [:i |
		| j |
		j := i < 0 ifTrue: [i + n] ifFalse: [i].
		(j < 0 or: [j >= n]) ifTrue: [^APLError index].
		j]!
iotaList: n
	^(0 to: n - 1) asArray! !

!APLPrims class methodsFor: 'shape'!
tally: y
	^APLArray scalar: y tally!
shape: y
	^APLArray vector: y shape!
reshape: x with: y
	| n count d ys |
	n := x integers.
	(n anySatisfy: [:e | e < 0]) ifTrue: [^APLError domain].
	count := APLArray product: n.
	ys := y size.
	count = 0 ifTrue: [^(APLArray shape: n data: #()) proto: y fill].
	d := Array new: count.
	ys = 0
		ifTrue: [d atAllPut: y fill]
		ifFalse: [
			ys = 1 ifTrue: [d atAllPut: y first]
				ifFalse: [1 to: count do: [:i | d at: i put: (y data at: (i - 1) \\ ys + 1)]]].
	^(APLArray shape: n data: d) proto: y proto!
ravel: y
	^y ravel!
ravelItems: y
	y isAtom ifTrue: [^y reshaped: #(1 1)].
	^y reshaped: (Array with: y tally with: y itemSize)!
itemize: y
	^y reshaped: (Array with: 1), y shape!
laminate: x with: y
	^APLArray stack: (Array with: x with: y)!
append: x with: y
	| h l i rx ry d |
	(self compatible: x with: y) ifFalse: [^APLError domain].
	rx := x rank. ry := y rank.
	(rx = 0 and: [ry = 0]) ifTrue: [^(APLArray shape: #(2) data: (Array with: x first with: y first)) proto: x proto].
	rx = ry ifTrue: [
		x itemShape = y itemShape ifFalse: [^APLError length].
		^(APLArray shape: (Array with: x tally + y tally), x itemShape data: x data, y data) proto: x proto].
	rx > ry ifTrue: [h := x. l := y] ifFalse: [h := y. l := x].
	i := h itemShape.
	l isAtom
		ifTrue: [l := (APLArray shape: i data: (Array new: (APLArray product: i) withAll: l first)) proto: l proto]
		ifFalse: [l shape = i ifFalse: [^APLError length]].
	d := rx > ry ifTrue: [x data, l data] ifFalse: [l data, y data].
	^(APLArray shape: (Array with: h tally + 1), i data: d) proto: h proto!
stitch: x with: y
	| n out |
	n := x isAtom ifTrue: [y tally] ifFalse: [x tally].
	(x isAtom or: [y isAtom or: [x tally = y tally]]) ifFalse: [^APLError length].
	out := Array new: n.
	1 to: n do: [:i | out at: i put: (self append: (x itemAt: (x isAtom ifTrue: [1] ifFalse: [i])) with: (y itemAt: (y isAtom ifTrue: [1] ifFalse: [i])))].
	^APLArray stack: out!
raze: y
	| col contents |
	y isBoxed ifFalse: [^y ravel].
	contents := y data collect: [:b | b contents].
	(contents allSatisfy: [:c | c rank <= 1]) ifTrue: [
		col := OrderedCollection new.
		contents do: [:c | col addAll: c data].
		^(APLArray vector: col) proto: contents first proto].
	^contents inject: nil into: [:acc :c | acc isNil ifTrue: [c] ifFalse: [self append: acc with: c]]!
link: x with: y
	| bx |
	bx := APLArray box: x.
	^y isBoxed
		ifTrue: [self append: bx with: y]
		ifFalse: [self append: bx with: (APLArray box: y)]!
box: y
	^APLArray box: y!
open: y
	y isAtom ifFalse: [^APLError rank].
	y first class == APLBox ifTrue: [^y first contents].
	^y!
same: y
	^y!
left: x with: y
	^x!
right: x with: y
	^y! !

!APLPrims class methodsFor: 'selection'!
head: y
	y isAtom ifTrue: [^y].
	y tally = 0 ifTrue: [^(APLArray shape: y itemShape data: (Array new: y itemSize withAll: y fill)) proto: y fill].
	^y itemAt: 1!
tail: y
	y isAtom ifTrue: [^y].
	y tally = 0 ifTrue: [^self head: y].
	^y itemAt: y tally!
behead: y
	^self drop: (APLArray scalar: 1) with: y!
curtail: y
	^self drop: (APLArray scalar: -1) with: y!
take: x with: y
	| ns yy lists r |
	ns := x integers.
	yy := y isAtom ifTrue: [y reshaped: #(1)] ifFalse: [y].
	r := yy rank.
	ns size > r ifTrue: [^APLError length].
	lists := Array new: r.
	1 to: r do: [:a | | n k l |
		n := yy shape at: a.
		a <= ns size
			ifTrue: [
				k := ns at: a.
				l := Array new: k abs.
				k >= 0
					ifTrue: [1 to: k do: [:i | l at: i put: (i <= n ifTrue: [i - 1] ifFalse: [-1])]]
					ifFalse: [1 to: k negated do: [:i | | s | s := n + k + i - 1. l at: i put: (s >= 0 ifTrue: [s] ifFalse: [-1])]]]
			ifFalse: [l := (0 to: n - 1) asArray].
		lists at: a put: l].
	^yy gatherAxes: lists fill: yy fill!
drop: x with: y
	| ns yy lists r |
	ns := x integers.
	yy := y isAtom ifTrue: [y reshaped: #(1)] ifFalse: [y].
	r := yy rank.
	ns size > r ifTrue: [^APLError length].
	lists := Array new: r.
	1 to: r do: [:a | | n k l |
		n := yy shape at: a.
		a <= ns size
			ifTrue: [
				k := ns at: a.
				k >= 0
					ifTrue: [l := (k to: n - 1) asArray]
					ifFalse: [l := (0 to: n + k - 1) asArray]]
			ifFalse: [l := (0 to: n - 1) asArray].
		lists at: a put: l].
	^yy gatherAxes: lists fill: yy fill!
from: x with: y
	| item n box lists res shp k |
	y isAtom ifTrue: [^APLError rank].
	item := x first.
	item class == APLBox ifFalse: [
		item isInteger ifFalse: [^APLError domain].
		n := y tally.
		item < 0 ifTrue: [item := item + n].
		(item < 0 or: [item >= n]) ifTrue: [^APLError index].
		^y itemAt: item + 1].
	box := item contents.
	box isBoxed ifFalse: [^APLError domain].
	k := box size.
	k > y rank ifTrue: [^APLError length].
	lists := Array new: y rank.
	shp := OrderedCollection new.
	1 to: y rank do: [:a | | idx |
		a <= k
			ifTrue: [
				idx := (box data at: a) contents.
				idx size = 0 ifTrue: [lists at: a put: (0 to: (y shape at: a) - 1) asArray. shp add: (y shape at: a)]
					ifFalse: [
						lists at: a put: (self indexList: idx count: (y shape at: a)).
						shp addAll: idx shape]]
			ifFalse: [
				lists at: a put: (0 to: (y shape at: a) - 1) asArray.
				shp add: (y shape at: a)]].
	res := y gatherAxes: lists fill: y fill.
	^res reshaped: shp asArray!
reverse: y
	| lists |
	y isAtom ifTrue: [^y].
	lists := Array new: y rank.
	1 to: y rank do: [:a | lists at: a put: ((0 to: (y shape at: a) - 1) asArray)].
	lists at: 1 put: (lists at: 1) reverse.
	^y gatherAxes: lists fill: y fill!
rotate: x with: y
	| ns lists |
	y isAtom ifTrue: [^y].
	ns := x integers.
	ns size > y rank ifTrue: [^APLError length].
	lists := Array new: y rank.
	1 to: y rank do: [:a | | n |
		n := y shape at: a.
		(a <= ns size and: [n > 0])
			ifTrue: [lists at: a put: ((0 to: n - 1) asArray collect: [:i | (i + (ns at: a)) \\ n])]
			ifFalse: [lists at: a put: (0 to: n - 1) asArray]].
	^y gatherAxes: lists fill: y fill!
permute: y by: perm
	"the array whose axis j is axis (perm at: j) of y (both 1-based)"
	| r nshape strides sstr total out idx pos off a |
	r := y rank.
	nshape := perm collect: [:p | y shape at: p].
	strides := Array new: r.
	r > 0 ifTrue: [
		strides at: r put: 1.
		r - 1 to: 1 by: -1 do: [:i | strides at: i put: (strides at: i + 1) * (y shape at: i + 1)]].
	sstr := perm collect: [:p | strides at: p].
	total := APLArray product: nshape.
	out := Array new: total.
	total = 0 ifTrue: [^(APLArray shape: nshape data: out) proto: y proto].
	idx := Array new: r withAll: 0.
	off := 0.
	1 to: total do: [:k |
		out at: k put: (y data at: off + 1).
		a := r.
		[a >= 1] whileTrue: [
			idx at: a put: (idx at: a) + 1.
			off := off + (sstr at: a).
			(idx at: a) >= (nshape at: a)
				ifTrue: [off := off - ((nshape at: a) * (sstr at: a)). idx at: a put: 0. a := a - 1]
				ifFalse: [a := 0]]].
	^(APLArray shape: nshape data: out) proto: y proto!
transpose: y
	| perm |
	y rank < 2 ifTrue: [^y].
	perm := (y rank to: 1 by: -1) asArray.
	^self permute: y by: perm!
transpose: x with: y
	| ns r perm used next |
	r := y rank.
	ns := x integers.
	ns size > r ifTrue: [^APLError length].
	perm := Array new: r withAll: 0.
	used := Array new: r withAll: false.
	1 to: ns size do: [:i | | slot |
		slot := (ns at: i) + 1.
		(slot < 1 or: [slot > r or: [used at: slot]]) ifTrue: [^APLError domain].
		used at: slot put: true.
		perm at: slot put: i].
	next := ns size + 1.
	1 to: r do: [:slot |
		(perm at: slot) = 0 ifTrue: [perm at: slot put: next. next := next + 1]].
	^self permute: y by: perm! !

!APLPrims class methodsFor: 'copy and counting'!
copy: x with: y
	"x # y: each item of y repeated as often as the matching item of x says"
	| xs yy n idx |
	xs := x integers.
	(xs anySatisfy: [:e | e < 0]) ifTrue: [^APLError domain].
	yy := y isAtom ifTrue: [y reshaped: (Array with: (xs size = 1 ifTrue: [1] ifFalse: [xs size]))] ifFalse: [y].
	xs size = 1 ifTrue: [xs := Array new: yy tally withAll: xs first].
	xs size = yy tally ifFalse: [^APLError length].
	idx := OrderedCollection new.
	xs doWithIndex: [:c :i | c timesRepeat: [idx add: i - 1]].
	^self selectItems: idx asArray from: yy! !

!APLPrims class methodsFor: 'number systems'!
base2: y
	^self base: (APLArray scalar: 2) with: y!
base: x with: y
	| rs acc |
	y isAtom ifTrue: [^y].
	rs := x isAtom ifTrue: [Array new: y size withAll: x first] ifFalse: [x data].
	rs size = y size ifFalse: [^APLError length].
	acc := 0.
	1 to: y size do: [:i | acc := acc * (rs at: i) + (y data at: i)].
	^APLArray scalar: acc!
digits: n radix: rs
	"the digits of n in the given radices (a list, last radix first), the last digit taking the rest"
	| out m |
	out := Array new: rs size.
	m := n.
	rs size to: 1 by: -1 do: [:i | | r |
		r := rs at: i.
		r = 0 ifTrue: [out at: i put: m. m := 0] ifFalse: [out at: i put: m \\ r. m := m // r]].
	^out!
antibase2: y
	| ns len rows out |
	ns := y integers.
	ns := ns collect: [:e | e abs].
	len := ns inject: 1 into: [:m :e | m max: (self bitLength: e)].
	out := OrderedCollection new.
	ns do: [:e | out addAll: (self digits: e radix: (Array new: len withAll: 2))].
	^APLArray shape: y shape, (Array with: len) data: out asArray!
bitLength: n
	| k m |
	k := 0. m := n.
	[m > 0] whileTrue: [k := k + 1. m := m // 2].
	^k max: 1!
antibase: x with: y
	| ns rs len out |
	ns := y integers.
	x isAtom
		ifTrue: [
			len := ns inject: 1 into: [:m :e | m max: ((self digitCount: e abs radix: x first))].
			rs := Array new: len withAll: x first]
		ifFalse: [rs := x integers. len := rs size].
	out := Array new: len * ns size.
	ns doWithIndex: [:e :j | | ds |
		ds := self digits: e radix: rs.
		1 to: len do: [:i | out at: (i - 1) * ns size + j put: (ds at: i)]].
	^APLArray shape: (Array with: len), y shape data: out!
digitCount: n radix: r
	| k m |
	(r isInteger and: [r > 1]) ifFalse: [^APLError domain].
	k := 0. m := n.
	[m > 0] whileTrue: [k := k + 1. m := m // r].
	^k max: 1! !
