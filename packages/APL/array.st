"APLArray: the one data structure of the language. An array is a shape (a list of axis lengths, empty for a single
item) and the items in row-major order. An item is a number (an Integer, a Fraction or a Float), a Character, or an
APLBox holding another array. Nothing else is ever stored, so every value in the language is an APLArray. An empty
array remembers whether it is text (proto is then a Character) so that '' and 0$0 stay different."

!APLArray class methodsFor: 'instance creation'!
shape: aShape data: aData
	^self basicNew setShape: aShape data: aData!
scalar: anItem
	^self basicNew setShape: #() data: (Array with: anItem)!
vector: aCollection
	| d |
	d := aCollection asArray.
	^self basicNew setShape: (Array with: d size) data: d!
text: aString
	"a character vector, even for one character"
	| d |
	d := Array new: aString size.
	1 to: aString size do: [:i | d at: i put: (aString at: i)].
	^(self basicNew setShape: (Array with: d size) data: d) proto: $ !
literal: aString
	"what a quoted string in a sentence means: one character is a single item"
	aString size = 1 ifTrue: [^self scalar: (aString at: 1)].
	^self text: aString!
empty
	^self basicNew setShape: #(0) data: #()!
emptyText
	^self text: ''!
integers: n
	| d |
	d := Array new: n.
	1 to: n do: [:i | d at: i put: i - 1].
	^self basicNew setShape: (Array with: n) data: d!
boolean: aBoolean
	^self scalar: (aBoolean ifTrue: [1] ifFalse: [0])!
box: anArray
	^self scalar: (APLBox on: anArray)!
product: aShape
	| p |
	p := 1.
	aShape do: [:e | p := p * e].
	^p!
fromSmalltalk: anObject
	"an array from a number, a character, a string, a boolean, nil or a (nested) collection"
	anObject class == APLArray ifTrue: [^anObject].
	anObject isNumber ifTrue: [^self scalar: anObject].
	anObject isCharacter ifTrue: [^self scalar: anObject].
	anObject == true ifTrue: [^self scalar: 1].
	anObject == false ifTrue: [^self scalar: 0].
	anObject isNil ifTrue: [^self empty].
	anObject class == APLBox ifTrue: [^self scalar: anObject].
	anObject isString ifTrue: [^self text: anObject asString].
	(anObject isKindOf: Collection) ifTrue: [^self fromCollection: anObject].
	^APLError message: 'domain error: cannot make an array from ', anObject printString!
fromCollection: aCollection
	| items kinds first same d isz |
	items := aCollection asArray collect: [:e | self fromSmalltalk: e].
	items isEmpty ifTrue: [^self empty].
	kinds := items collect: [:e | e kind].
	first := items first.
	same := (kinds allSatisfy: [:k | k == kinds first]) and: [kinds first ~~ #box and: [kinds first ~~ #mixed]].
	same ifTrue: [same := items allSatisfy: [:e | e shape = first shape]].
	same ifFalse: [^self vector: (items collect: [:e | APLBox on: e])].
	first isAtom ifTrue: [^self vector: (items collect: [:e | e first])].
	isz := first size.
	d := Array new: items size * isz.
	items doWithIndex: [:e :i | d replaceFrom: (i - 1) * isz + 1 to: i * isz with: e data startingAt: 1].
	^(self shape: (Array with: items size), first shape data: d) proto: first proto!
stack: someArrays
	"the arrays as the items of a new one, padded with fill to the largest shape if they differ"
	| first same r dims d isz out n |
	n := someArrays size.
	n = 0 ifTrue: [^self empty].
	first := someArrays first.
	same := someArrays allSatisfy: [:e | e shape = first shape].
	same ifTrue: [
		isz := first size.
		d := Array new: n * isz.
		someArrays doWithIndex: [:e :i | d replaceFrom: (i - 1) * isz + 1 to: i * isz with: e data startingAt: 1].
		^(self shape: (Array with: n), first shape data: d) proto: first proto].
	r := someArrays inject: 0 into: [:m :e | m max: e rank].
	dims := Array new: r withAll: 0.
	someArrays do: [:e | | lead |
		lead := r - e rank.
		1 to: e rank do: [:k | dims at: lead + k put: ((dims at: lead + k) max: (e shape at: k))]].
	isz := self product: dims.
	d := Array new: n * isz.
	someArrays doWithIndex: [:e :i | | p |
		p := e paddedTo: dims.
		d replaceFrom: (i - 1) * isz + 1 to: i * isz with: p data startingAt: 1].
	out := self shape: (Array with: n), dims data: d.
	^out proto: first proto!
atomic: aBlock x: x y: y
	"aBlock applied to the items of x and y in step, with the scalar extension and the agreement of frames of the language"
	| sx sy dx dy out extra a |
	sx := x shape. sy := y shape. dx := x data. dy := y data.
	sx = sy ifTrue: [
		out := Array new: dx size.
		1 to: dx size do: [:i | out at: i put: (aBlock value: (dx at: i) value: (dy at: i))].
		^self shape: sx data: out].
	sx isEmpty ifTrue: [
		a := dx first.
		^self shape: sy data: (dy collect: [:b | aBlock value: a value: b])].
	sy isEmpty ifTrue: [
		a := dy first.
		^self shape: sx data: (dx collect: [:b | aBlock value: b value: a])].
	sx size < sy size
		ifTrue: [
			1 to: sx size do: [:i | (sx at: i) = (sy at: i) ifFalse: [^APLError length]].
			extra := self product: (sy copyFrom: sx size + 1 to: sy size).
			out := Array new: dy size.
			1 to: dy size do: [:i | out at: i put: (aBlock value: (dx at: i - 1 // extra + 1) value: (dy at: i))].
			^self shape: sy data: out]
		ifFalse: [
			1 to: sy size do: [:i | (sx at: i) = (sy at: i) ifFalse: [^APLError length]].
			extra := self product: (sx copyFrom: sy size + 1 to: sx size).
			out := Array new: dx size.
			1 to: dx size do: [:i | out at: i put: (aBlock value: (dx at: i) value: (dy at: i - 1 // extra + 1))].
			^self shape: sx data: out]! !

!APLArray methodsFor: 'accessing'!
setShape: aShape data: aData
	shape := aShape.
	data := aData!
shape
	^shape!
data
	^data!
proto
	^proto!
proto: anItem
	proto := anItem!
rank
	^shape size!
size
	^data size!
tally
	^shape isEmpty ifTrue: [1] ifFalse: [shape at: 1]!
isAtom
	^shape isEmpty!
first
	^data first!
at: i
	^data at: i!
itemShape
	^shape isEmpty ifTrue: [#()] ifFalse: [shape copyFrom: 2 to: shape size]!
itemSize
	"how many single items make up one item (a row of a table, say)"
	| p |
	shape isEmpty ifTrue: [^1].
	p := 1.
	2 to: shape size do: [:i | p := p * (shape at: i)].
	^p!
kind
	"#number, #text, #box, #mixed (never made by the language), or #empty-less answer for the type of the first item"
	| k |
	data isEmpty ifTrue: [^proto isNil ifTrue: [#number] ifFalse: [proto isCharacter ifTrue: [#text] ifFalse: [#number]]].
	k := self kindOfItem: data first.
	data do: [:e | (self kindOfItem: e) == k ifFalse: [^#mixed]].
	^k!
kindOfItem: x
	x isNumber ifTrue: [^#number].
	x isCharacter ifTrue: [^#text].
	^#box!
isText
	^self kind == #text!
isBoxed
	^self kind == #box!
isNumeric
	^self kind == #number!
fill
	"what pads this array: zero, a blank, or an empty box"
	| k |
	k := self kind.
	k == #text ifTrue: [^$ ].
	k == #box ifTrue: [^APLBox on: APLArray empty].
	^0!
itemAt: i
	"the i-th item along the first axis, itself an array"
	| isz |
	shape isEmpty ifTrue: [^self].
	isz := self itemSize.
	shape size = 1 ifTrue: [^(APLArray scalar: (data at: i)) proto: proto].
	^(APLArray shape: self itemShape data: (data copyFrom: (i - 1) * isz + 1 to: i * isz)) proto: proto!
items
	| out |
	out := Array new: self tally.
	1 to: out size do: [:i | out at: i put: (self itemAt: i)].
	^out!
cellsOfRank: k
	"the cells of the given rank, as an Array of arrays (the frame is the leading part of the shape)"
	| cs cshape n out |
	cshape := shape copyFrom: shape size - k + 1 to: shape size.
	cs := APLArray product: cshape.
	n := (cs = 0) ifTrue: [APLArray product: (shape copyFrom: 1 to: shape size - k)] ifFalse: [data size // cs].
	out := Array new: n.
	1 to: n do: [:i |
		out at: i put: ((APLArray shape: cshape data: (data copyFrom: (i - 1) * cs + 1 to: i * cs)) proto: proto)].
	^out!
ravel
	^(APLArray shape: (Array with: data size) data: data) proto: proto!
reshaped: aShape
	^(APLArray shape: aShape data: data) proto: proto!
withProtoOf: anArray
	proto := anArray proto.
	data isEmpty ifFalse: [proto := data first].
	^self!
asInteger
	"the single integer in this array, or an error"
	data size = 1 ifFalse: [^APLError length].
	data first isNumber ifFalse: [^APLError domain].
	data first isInteger ifTrue: [^data first].
	(data first isFloat and: [data first = data first truncated]) ifTrue: [^data first truncated].
	(data first isFraction) ifTrue: [^APLError domain].
	^APLError domain!
integers
	"every item as an Integer"
	^data collect: [:e |
		e isInteger ifTrue: [e] ifFalse: [
			(e isNumber and: [e = e truncated]) ifTrue: [e truncated] ifFalse: [^APLError domain]]]! !

!APLArray methodsFor: 'shaping'!
paddedTo: dims
	"this array with leading axes of length 1 added and every axis padded (or cut) to dims"
	| r lead lists |
	r := dims size.
	lead := r - shape size.
	lists := Array new: r.
	1 to: r do: [:a |
		a <= lead
			ifTrue: [| l0 |
				l0 := Array new: (dims at: a) withAll: -1.
				(dims at: a) > 0 ifTrue: [l0 at: 1 put: 0].
				lists at: a put: l0]
			ifFalse: [| n m l |
				n := shape at: a - lead. m := dims at: a.
				l := Array new: m.
				1 to: m do: [:i | l at: i put: (i <= n ifTrue: [i - 1] ifFalse: [-1])].
				lists at: a put: l]].
	^(self reshaped: ((Array new: lead withAll: 1), shape)) gatherAxes: lists fill: self fill!
gatherAxes: lists fill: fillItem
	"the array whose axis a runs over the 0-based source indices lists at: a (a negative index is a pad)"
	| r newShape total out strides idx pos off ok a s |
	r := shape size.
	newShape := Array new: r.
	1 to: r do: [:i | newShape at: i put: (lists at: i) size].
	total := APLArray product: newShape.
	out := Array new: total.
	total = 0 ifTrue: [^(APLArray shape: newShape data: out) proto: self fill].
	r = 0 ifTrue: [out at: 1 put: data first. ^APLArray shape: newShape data: out].
	strides := Array new: r.
	strides at: r put: 1.
	r - 1 to: 1 by: -1 do: [:i | strides at: i put: (strides at: i + 1) * (shape at: i + 1)].
	idx := Array new: r withAll: 1.
	pos := 1.
	[pos <= total] whileTrue: [
		off := 0. ok := true.
		1 to: r do: [:k |
			s := (lists at: k) at: (idx at: k).
			s < 0 ifTrue: [ok := false] ifFalse: [off := off + (s * (strides at: k))]].
		out at: pos put: (ok ifTrue: [data at: off + 1] ifFalse: [fillItem]).
		pos := pos + 1.
		a := r.
		[a >= 1] whileTrue: [
			idx at: a put: (idx at: a) + 1.
			(idx at: a) > (newShape at: a)
				ifTrue: [idx at: a put: 1. a := a - 1]
				ifFalse: [a := 0]]].
	^(APLArray shape: newShape data: out) proto: proto!
mapAtoms: aBlock
	^(APLArray shape: shape data: (data collect: aBlock)) proto: proto! !

!APLArray methodsFor: 'comparing'!
match: other
	"the same shape and the same items; numbers match by value"
	| d |
	other class == APLArray ifFalse: [^false].
	shape = other shape ifFalse: [^false].
	d := other data.
	1 to: data size do: [:i | (data at: i) = (d at: i) ifFalse: [^false]].
	^true!
= other
	^self match: other!
hash
	^data size hash!
printOn: aStream
	aStream nextPutAll: 'APLArray '; print: shape; space; print: data! !

!APLArray methodsFor: 'converting'!
asSmalltalk
	"a number or character for a single item, a String for text, otherwise an Array (of Arrays for a table)"
	| out |
	shape isEmpty ifTrue: [^self itemToSmalltalk: data first].
	(shape size = 1 and: [self isText]) ifTrue: [^self text].
	shape size = 1 ifTrue: [^data collect: [:e | self itemToSmalltalk: e]].
	out := Array new: self tally.
	1 to: out size do: [:i | out at: i put: (self itemAt: i) asSmalltalk].
	^out!
itemToSmalltalk: x
	x class == APLBox ifTrue: [^x contents asSmalltalk].
	^x!
text
	"the characters of a vector as a String"
	| s |
	s := String new: data size.
	1 to: data size do: [:i | s at: i put: (data at: i)].
	^s! !
