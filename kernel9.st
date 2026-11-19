"Mini Smalltalk-80 kernel, part 9: text and Unicode.
A String is a string of bytes (UTF-8 text typed in the browser or read from a file is stored as its bytes).
A WideString holds real code points, so that 'héllo' has five elements; String>>asWideString (or utf8Decoded)
decodes UTF-8 into one, and WideString>>utf8Encoded goes back. Bytes that are not valid UTF-8 decode as Latin-1."

ArrayedCollection variableSubclass: #WideString instanceVariableNames: '' classVariableNames: '' category: 'Collections-Text'!

"---- Character: any code point, and case/letter tests beyond ASCII ----"

!Character class methodsFor: 'instance creation'!
value: anInteger
	<primitive: 70>
	anInteger isInteger ifFalse: [^self error: 'character value must be an integer'].
	(anInteger < 0 or: [anInteger > 1114111]) ifTrue: [^self error: 'character value out of range'].
	^WideCharacterTable at: anInteger ifAbsentPut: [self basicNew setValue: anInteger]!
codePoint: anInteger
	^self value: anInteger!
nul
	^self value: 0!
null
	^self value: 0!
bell
	^self value: 7!
escape
	^self value: 27!
euro
	^self value: 8364! !

!Character methodsFor: 'private'!
setValue: anInteger
	value := anInteger! !

!Character methodsFor: 'accessing'!
codePoint
	^value!
isAscii
	^value < 128! !

!Character methodsFor: 'comparing'!
= aCharacter
	^self == aCharacter or: [(aCharacter isKindOf: Character) and: [value = aCharacter value]]! !

!Character methodsFor: 'case mapping'!
uppercaseValue
	"the code point of the upper case form (the receiver's own if it has none)"
	| v |
	v := value.
	v < 128 ifTrue: [^(v between: 97 and: 122) ifTrue: [v - 32] ifFalse: [v]].
	v = 181 ifTrue: [^924].
	v = 255 ifTrue: [^376].
	v = 305 ifTrue: [^73].
	(v between: 224 and: 254) ifTrue: [^v = 247 ifTrue: [v] ifFalse: [v - 32]].
	(v between: 256 and: 311) ifTrue: [^v odd ifTrue: [v - 1] ifFalse: [v]].
	(v between: 313 and: 328) ifTrue: [^v even ifTrue: [v - 1] ifFalse: [v]].
	(v between: 330 and: 375) ifTrue: [^v odd ifTrue: [v - 1] ifFalse: [v]].
	(v between: 377 and: 382) ifTrue: [^v even ifTrue: [v - 1] ifFalse: [v]].
	v = 940 ifTrue: [^902].
	(v between: 941 and: 943) ifTrue: [^v - 37].
	v = 962 ifTrue: [^931].
	(v between: 945 and: 969) ifTrue: [^v - 32].
	v = 972 ifTrue: [^908].
	(v between: 973 and: 974) ifTrue: [^v - 63].
	(v between: 1072 and: 1103) ifTrue: [^v - 32].
	(v between: 1104 and: 1119) ifTrue: [^v - 80].
	^v!
lowercaseValue
	"the code point of the lower case form (the receiver's own if it has none)"
	| v |
	v := value.
	v < 128 ifTrue: [^(v between: 65 and: 90) ifTrue: [v + 32] ifFalse: [v]].
	v = 304 ifTrue: [^105].
	v = 376 ifTrue: [^255].
	(v between: 192 and: 222) ifTrue: [^v = 215 ifTrue: [v] ifFalse: [v + 32]].
	(v between: 256 and: 311) ifTrue: [^v even ifTrue: [v + 1] ifFalse: [v]].
	(v between: 313 and: 328) ifTrue: [^v odd ifTrue: [v + 1] ifFalse: [v]].
	(v between: 330 and: 375) ifTrue: [^v even ifTrue: [v + 1] ifFalse: [v]].
	(v between: 377 and: 382) ifTrue: [^v odd ifTrue: [v + 1] ifFalse: [v]].
	v = 902 ifTrue: [^940].
	(v between: 904 and: 906) ifTrue: [^v + 37].
	(v between: 913 and: 937) ifTrue: [^v = 930 ifTrue: [v] ifFalse: [v + 32]].
	v = 908 ifTrue: [^972].
	(v between: 910 and: 911) ifTrue: [^v + 63].
	(v between: 1040 and: 1071) ifTrue: [^v + 32].
	(v between: 1024 and: 1039) ifTrue: [^v + 80].
	^v! !

!Character methodsFor: 'testing'!
isUppercase
	^value < 128 ifTrue: [value between: 65 and: 90] ifFalse: [self lowercaseValue ~= value]!
isLowercase
	^value < 128 ifTrue: [value between: 97 and: 122] ifFalse: [self uppercaseValue ~= value or: [value = 223]]!
isLetter
	value < 128 ifTrue: [^(value between: 65 and: 90) or: [value between: 97 and: 122]].
	^self isUppercase or: [self isLowercase or: [self isOtherLetter]]!
isOtherLetter
	"letters without case"
	^value = 170 or: [value = 186 or: [(value between: 1488 and: 1514) or: [(value between: 1568 and: 1610)
		or: [(value between: 12353 and: 12543) or: [(value between: 19968 and: 40959) or: [value between: 44032 and: 55203]]]]]]!
isSpace
	^self isSeparator!
isDigit: radix
	^self digitValue between: 0 and: radix - 1! !

!Character methodsFor: 'converting'!
asUppercase
	^value < 128
		ifTrue: [(value between: 97 and: 122) ifTrue: [Character value: value - 32] ifFalse: [self]]
		ifFalse: [Character value: self uppercaseValue]!
asLowercase
	^value < 128
		ifTrue: [(value between: 65 and: 90) ifTrue: [Character value: value + 32] ifFalse: [self]]
		ifFalse: [Character value: self lowercaseValue]!
asString
	^value < 256 ifTrue: [String with: self] ifFalse: [(WideString new: 1) at: 1 put: self; yourself]!
utf8Encoded
	"the UTF-8 bytes of the character, as a String"
	| v |
	v := value.
	v < 128 ifTrue: [^String with: (Character value: v)].
	v < 2048 ifTrue: [^String with: (Character value: 192 + (v // 64)) with: (Character value: 128 + (v \\ 64))].
	v < 65536 ifTrue: [^String with: (Character value: 224 + (v // 4096)) with: (Character value: 128 + (v // 64 \\ 64)) with: (Character value: 128 + (v \\ 64))].
	^String with: (Character value: 240 + (v // 262144)) with: (Character value: 128 + (v // 4096 \\ 64)) with: (Character value: 128 + (v // 64 \\ 64)) with: (Character value: 128 + (v \\ 64))! !

!Character methodsFor: 'printing'!
displayString
	^value < 256 ifTrue: [self asString] ifFalse: [self utf8Encoded]!
printOn: aStream
	aStream nextPut: $$.
	value < 256 ifTrue: [aStream nextPut: self] ifFalse: [aStream nextPutAll: self utf8Encoded]! !

"---- WideString ----"

!WideString class methodsFor: 'instance creation'!
new: n
	"filled with spaces"
	| s space |
	s := self basicNew: n.
	space := Character value: 32.
	1 to: n do: [:i | s basicAt: i put: space].
	^s!
new
	^self new: 0! !

!WideString methodsFor: 'accessing'!
size
	^self basicSize!
at: index
	^self basicAt: index!
at: index put: aCharacter
	(aCharacter isKindOf: Character) ifFalse: [^self error: 'a WideString holds Characters'].
	^self basicAt: index put: aCharacter!
codePointAt: index
	^(self basicAt: index) value! !

!WideString methodsFor: 'testing'!
isString
	^true!
isWideString
	^true!
isSymbol
	^false! !

!WideString methodsFor: 'comparing'!
= aString
	| n |
	(aString isKindOf: WideString) ifFalse: [^false].
	n := self size.
	n = aString size ifFalse: [^false].
	1 to: n do: [:i | (self basicAt: i) value = (aString basicAt: i) value ifFalse: [^false]].
	^true!
hash
	| h |
	h := self size.
	1 to: (self size min: 16) do: [:i | h := (h * 31 + (self basicAt: i) value) bitAnd: 1073741823].
	^h!
< aString
	| n |
	n := self size min: aString size.
	1 to: n do: [:i |
		(self basicAt: i) value < (aString at: i) value ifTrue: [^true].
		(self basicAt: i) value > (aString at: i) value ifTrue: [^false]].
	^self size < aString size!
> aString
	^aString < self!
<= aString
	^(aString < self) not!
>= aString
	^(self < aString) not! !

!WideString methodsFor: 'copying'!
species
	^WideString!
, aString
	| other r |
	other := aString isWideString ifTrue: [aString] ifFalse: [aString asWideString].
	r := WideString new: self size + other size.
	r replaceFrom: 1 to: self size with: self startingAt: 1.
	r replaceFrom: self size + 1 to: r size with: other startingAt: 1.
	^r! !

!WideString methodsFor: 'converting'!
asWideString
	^self!
utf8Decoded
	^self!
utf8Encoded
	"the text as UTF-8 bytes, in a String"
	| out |
	out := WriteStream on: (String new: 16).
	self do: [:c | out nextPutAll: c utf8Encoded].
	^out contents!
asString
	^self utf8Encoded!
asSymbol
	^self utf8Encoded asSymbol!
asUppercase
	^self collect: [:c | c asUppercase]!
asLowercase
	^self collect: [:c | c asLowercase]!
asArray
	| r |
	r := Array new: self size.
	1 to: self size do: [:i | r at: i put: (self basicAt: i)].
	^r! !

!WideString methodsFor: 'printing'!
displayString
	^self utf8Encoded!
printOn: aStream
	"quoted, in UTF-8"
	aStream nextPut: $'.
	self do: [:c | c = $' ifTrue: [aStream nextPut: $']. aStream nextPutAll: c utf8Encoded].
	aStream nextPut: $'!
storeOn: aStream
	aStream nextPutAll: '(' ; print: self utf8Encoded; nextPutAll: ' utf8Decoded)'! !

"---- String ----"

!Object methodsFor: 'testing'!
isWideString
	^false! !

!String methodsFor: 'unicode'!
asWideString
	"decode the bytes as UTF-8 (bytes that are not valid UTF-8 are taken as Latin-1) into a WideString"
	| points i n b extra cp k cb ok |
	points := OrderedCollection new.
	i := 1. n := self size.
	[i <= n] whileTrue: [
		b := (self at: i) value.
		extra := b >= 240 ifTrue: [b < 248 ifTrue: [3] ifFalse: [0]] ifFalse: [b >= 224 ifTrue: [2] ifFalse: [b >= 192 ifTrue: [1] ifFalse: [0]]].
		cp := b.
		ok := extra > 0 and: [i + extra <= n].
		ok ifTrue: [
			cp := extra = 3 ifTrue: [b bitAnd: 7] ifFalse: [extra = 2 ifTrue: [b bitAnd: 15] ifFalse: [b bitAnd: 31]].
			k := 1.
			[ok and: [k <= extra]] whileTrue: [
				cb := (self at: i + k) value.
				(cb bitAnd: 192) = 128 ifTrue: [cp := cp * 64 + (cb bitAnd: 63)] ifFalse: [ok := false].
				k := k + 1]].
		ok
			ifTrue: [points add: (Character value: cp). i := i + extra + 1]
			ifFalse: [points add: (Character value: b). i := i + 1]].
	^WideString withAll: points!
utf8Decoded
	^self asWideString!
utf8Encoded
	"a String's bytes are already UTF-8"
	^self copy!
codePointAt: index
	^(self at: index) value! !

!String methodsFor: 'comparing'!
caseSensitiveCompareTo: aString
	"-1, 0 or 1, comparing byte values"
	1 to: (self size min: aString size) do: [:i |
		(self at: i) value < (aString at: i) value ifTrue: [^-1].
		(self at: i) value > (aString at: i) value ifTrue: [^1]].
	^self size < aString size ifTrue: [-1] ifFalse: [self size > aString size ifTrue: [1] ifFalse: [0]]! !

!String methodsFor: 'testing'!
beginsWith: aString
	^self startsWith: aString!
isAllDigits
	^self notEmpty and: [self allSatisfy: [:c | c isDigit]]!
includesSubString: aString
	^self includesSubstring: aString! !

!String methodsFor: 'searching'!
findString: aString
	^self indexOfSubCollection: aString startingAt: 1!
findString: aString startingAt: start
	^self indexOfSubCollection: aString startingAt: start! !

!String methodsFor: 'converting'!
capitalized
	| r |
	self isEmpty ifTrue: [^self].
	r := self copy.
	r at: 1 put: (r at: 1) asUppercase.
	^r!
asFloat
	| n |
	n := self asNumber.
	^n isNil ifTrue: [nil] ifFalse: [n asFloat]!
keywords
	"the parts of a selector, each with its colon: 'at:put:' keywords is #('at:' 'put:')"
	| r start |
	r := OrderedCollection new.
	start := 1.
	1 to: self size do: [:i | (self at: i) = $: ifTrue: [r add: (self copyFrom: start to: i). start := i + 1]].
	start <= self size ifTrue: [r add: (self copyFrom: start to: self size)].
	^r asArray!
numArgs
	^self asSymbol numArgs!
findTokens: delimiters
	^self substrings: (delimiters isCharacter ifTrue: [String with: delimiters] ifFalse: [delimiters])!
substrings: separators
	^self subStrings: separators!
subStrings
	^self substrings! !

!String methodsFor: 'trimming'!
trimLeft
	| i |
	i := 1.
	[i <= self size and: [(self at: i) isSeparator]] whileTrue: [i := i + 1].
	^self copyFrom: i to: self size!
trimRight
	| j |
	j := self size.
	[j >= 1 and: [(self at: j) isSeparator]] whileTrue: [j := j - 1].
	^self copyFrom: 1 to: j!
trimBoth
	^self trimLeft trimRight!
truncateTo: n
	^self size <= n ifTrue: [self] ifFalse: [self copyFrom: 1 to: n]! !

!String methodsFor: 'formatting'!
format: anArrayOrDictionary
	"substitute {1}, {2}... (positions in an Array) or {name} (keys of a Dictionary) with displayStrings"
	| out i n close token key |
	out := WriteStream on: (String new: self size + 16).
	i := 1. n := self size.
	[i <= n] whileTrue: [
		(self at: i) = ${
			ifTrue: [
				close := self indexOf: $} startingAt: i.
				close = 0 ifTrue: [^self error: 'unterminated { in format string'].
				token := self copyFrom: i + 1 to: close - 1.
				key := token isAllDigits ifTrue: [token asNumber] ifFalse: [token].
				out nextPutAll: (self formatValueFor: key in: anArrayOrDictionary) displayString.
				i := close + 1]
			ifFalse: [out nextPut: (self at: i). i := i + 1]].
	^out contents!
indexOf: aCharacter startingAt: start
	start to: self size do: [:i | (self at: i) = aCharacter ifTrue: [^i]].
	^0!
formatValueFor: key in: anArrayOrDictionary
	^anArrayOrDictionary isDictionary
		ifTrue: [anArrayOrDictionary at: key ifAbsent: [anArrayOrDictionary at: key asString asSymbol]]
		ifFalse: [anArrayOrDictionary at: key]!
% anArray
	^self format: anArray!
bindWith: a
	^self bindWithArguments: (Array with: a)!
bindWith: a with: b
	^self bindWithArguments: (Array with: a with: b)!
bindWith: a with: b with: c
	^self bindWithArguments: (Array with: a with: b with: c)!
bindWith: a with: b with: c with: d
	^self bindWithArguments: (Array with: a with: b with: c with: d)!
bindWithArguments: anArray
	"substitute %1 to %9 with displayStrings; %% is a single percent sign"
	| out i n c |
	out := WriteStream on: (String new: self size + 16).
	i := 1. n := self size.
	[i <= n] whileTrue: [
		c := self at: i.
		(c = $% and: [i < n])
			ifTrue: [
				(self at: i + 1) = $%
					ifTrue: [out nextPut: $%]
					ifFalse: [out nextPutAll: (anArray at: (self at: i + 1) digitValue) displayString].
				i := i + 2]
			ifFalse: [out nextPut: c. i := i + 1]].
	^out contents! !

!Symbol methodsFor: 'converting'!
capitalized
	^self asString capitalized asSymbol! !

!Text methodsFor: 'testing'!
isText
	^true! !

"---- ByteArray ----"

!ByteArray methodsFor: 'converting'!
asString
	"the bytes as a String"
	<primitive: 66>
	^self error: 'cannot convert to a String'!
asByteArray
	^self!
hex
	"two lower case hexadecimal digits per byte"
	| out |
	out := WriteStream on: (String new: self size * 2).
	self do: [:b |
		out nextPut: ('0123456789abcdef' at: b // 16 + 1).
		out nextPut: ('0123456789abcdef' at: b \\ 16 + 1)].
	^out contents!
asInteger
	"the bytes as a big-endian unsigned number"
	| n |
	n := 0.
	self do: [:b | n := n * 256 + b].
	^n! !

!ByteArray methodsFor: 'accessing'!
byteAt: index
	^self at: index!
isByteArray
	^true! !

!Object methodsFor: 'testing'!
isByteArray
	^false! !

!Collection methodsFor: 'converting'!
asByteArray
	^ByteArray withAll: self! !

"Characters above 255 are interned here, so that equal ones are identical (hashed collections compare Characters by identity)"
WideCharacterTable := Dictionary new!
