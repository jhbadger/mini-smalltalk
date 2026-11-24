"The primitive procedures, part 2: lists, characters, strings and symbols, vectors. The ones that take procedures (map, filter,
sort ...) are written in Scheme in prelude.scm, so that call/cc and tail calls work through them."

!SchemePrims class methodsFor: 'sequence helpers'!
str: x arg: i to: aName
	"a Scheme string (not a symbol)"
	(x isString and: [x isSymbol not]) ifFalse: [^self wrong: x arg: i to: aName].
	^x!
chr: x arg: i to: aName
	x isCharacter ifFalse: [^self wrong: x arg: i to: aName].
	^x!
index: i size: n arg: pos to: aName
	"i as an index into something of size n: 0-based, checked"
	i isInteger ifFalse: [^self wrong: i arg: pos to: aName].
	(i >= 0 and: [i < n]) ifFalse: [^self badRange: i arg: pos to: aName].
	^i!
range: args from: first of: n to: aName
	"the (start, end) given by the optional arguments at first and first+1, as 0-based bounds with end exclusive"
	| s e |
	s := args size >= first ifTrue: [args at: first] ifFalse: [0].
	e := args size >= (first + 1) ifTrue: [args at: first + 1] ifFalse: [n].
	(s isInteger and: [s >= 0 and: [s <= n]]) ifFalse: [^self badRange: s arg: first to: aName].
	(e isInteger and: [e >= s and: [e <= n]]) ifFalse: [^self badRange: e arg: first + 1 to: aName].
	^Array with: s with: e!
plainString: aString
	"a new String with the characters of aString (a Symbol gives a String)"
	| ws |
	ws := WriteStream on: String new.
	ws nextPutAll: aString.
	^ws contents!
compareStrings: args name: aName ci: ci with: aBlock
	| ok |
	1 to: args size do: [:i | self str: (args at: i) arg: i to: aName].
	ok := true.
	1 to: args size - 1 do: [:i |
		| a b |
		a := args at: i. b := args at: i + 1.
		ci ifTrue: [a := a asLowercase. b := b asLowercase].
		(aBlock value: a value: b) ifFalse: [ok := false]].
	^ok!
compareChars: args name: aName ci: ci with: aBlock
	| ok |
	1 to: args size do: [:i | self chr: (args at: i) arg: i to: aName].
	ok := true.
	1 to: args size - 1 do: [:i |
		| a b |
		a := (args at: i) value. b := (args at: i + 1) value.
		ci ifTrue: [a := (Character value: a) asLowercase value. b := (Character value: b) asLowercase value].
		(aBlock value: a value: b) ifFalse: [ok := false]].
	^ok!
displayText: x
	^SchemePrinter display: x! !

!SchemePrims class methodsFor: 'lists'!
installLists
	| combos |
	Scheme def: 'cons' do: [:a :b | SchemePair car: a cdr: b].
	Scheme def: 'car' do: [:p | p class == SchemePair ifTrue: [p car] ifFalse: [SchemePrims wrong: p arg: 1 to: 'car']].
	Scheme def: 'cdr' do: [:p | p class == SchemePair ifTrue: [p cdr] ifFalse: [SchemePrims wrong: p arg: 1 to: 'cdr']].
	Scheme def: 'set-car!!' do: [:p :v | p class == SchemePair ifTrue: [p car: v. SchemeUnspec] ifFalse: [SchemePrims wrong: p arg: 1 to: 'set-car!!']].
	Scheme def: 'set-cdr!!' do: [:p :v | p class == SchemePair ifTrue: [p cdr: v. SchemeUnspec] ifFalse: [SchemePrims wrong: p arg: 1 to: 'set-cdr!!']].
	combos := OrderedCollection new.
	#('a' 'd') do: [:x | #('a' 'd') do: [:y |
		combos add: x, y.
		#('a' 'd') do: [:z |
			combos add: x, y, z.
			#('a' 'd') do: [:w | combos add: x, y, z, w]]]].
	combos do: [:ops |
		| name |
		name := 'c', ops, 'r'.
		Scheme def: name do: [:x |
			| v |
			v := x.
			ops size to: 1 by: -1 do: [:i |
				v class == SchemePair ifFalse: [SchemePrims wrong: x arg: 1 to: name].
				v := (ops at: i) = $a ifTrue: [v car] ifFalse: [v cdr]].
			v]].
	Scheme def: 'pair?' do: [:x | x class == SchemePair].
	Scheme def: 'null?' do: [:x | x == SchemeNil].
	Scheme def: 'list?' do: [:x | x == SchemeNil or: [x class == SchemePair and: [x isList]]].
	Scheme def: 'list' min: 0 max: nil rest: [:args | SchemePair fromArray: args].
	Scheme def: 'cons*' min: 1 max: nil rest: [:args | SchemePair fromArray: (args copyFrom: 1 to: args size - 1) tail: args last].
	Scheme alias: 'list*' for: 'cons*'.
	Scheme def: 'make-list' min: 1 max: 2 rest: [:args |
		| n fill l |
		n := args at: 1.
		(n isInteger and: [n >= 0]) ifFalse: [SchemePrims wrong: n arg: 1 to: 'make-list'].
		fill := args size = 2 ifTrue: [args at: 2] ifFalse: [SchemeUnspec].
		l := SchemeNil.
		n timesRepeat: [l := SchemePair car: fill cdr: l].
		l].
	Scheme def: 'length' do: [:l |
		(l == SchemeNil or: [l class == SchemePair and: [l isList]]) ifFalse: [SchemePrims wrong: l arg: 1 to: 'length'].
		l length].
	Scheme def: 'append' min: 0 max: nil rest: [:args |
		| items |
		args isEmpty ifTrue: [SchemeNil] ifFalse: [
			items := OrderedCollection new.
			1 to: args size - 1 do: [:i | items addAll: (SchemePrims listArray: (args at: i) arg: i to: 'append')].
			SchemePair fromArray: items asArray tail: args last]].
	Scheme alias: 'append!!' for: 'append'.
	Scheme def: 'reverse' do: [:l |
		SchemePrims listArray: l arg: 1 to: 'reverse'.
		SchemePrims reverseOnto: l].
	Scheme alias: 'reverse!!' for: 'reverse'.
	Scheme def: 'append-reverse' do: [:l :tail |
		| r p |
		r := tail. p := l.
		[p class == SchemePair] whileTrue: [r := SchemePair car: p car cdr: r. p := p cdr].
		r].
	Scheme alias: 'append-reverse!!' for: 'append-reverse'.
	Scheme def: 'list-tail' do: [:l :k |
		| p |
		k isInteger ifFalse: [SchemePrims wrong: k arg: 2 to: 'list-tail'].
		p := l.
		k timesRepeat: [
			p class == SchemePair ifFalse: [SchemePrims badRange: k arg: 2 to: 'list-tail'].
			p := p cdr].
		p].
	Scheme def: 'list-head' do: [:l :k |
		| items p |
		k isInteger ifFalse: [SchemePrims wrong: k arg: 2 to: 'list-head'].
		items := OrderedCollection new. p := l.
		k timesRepeat: [
			p class == SchemePair ifFalse: [SchemePrims badRange: k arg: 2 to: 'list-head'].
			items add: p car. p := p cdr].
		SchemePair fromArray: items asArray].
	Scheme def: 'list-ref' do: [:l :k |
		| p |
		k isInteger ifFalse: [SchemePrims wrong: k arg: 2 to: 'list-ref'].
		p := l.
		k timesRepeat: [
			p class == SchemePair ifFalse: [SchemePrims badRange: k arg: 2 to: 'list-ref'].
			p := p cdr].
		p class == SchemePair ifFalse: [SchemePrims badRange: k arg: 2 to: 'list-ref'].
		p car].
	Scheme def: 'list-set!!' do: [:l :k :v |
		| p |
		k isInteger ifFalse: [SchemePrims wrong: k arg: 2 to: 'list-set!!'].
		p := l.
		k timesRepeat: [
			p class == SchemePair ifFalse: [SchemePrims badRange: k arg: 2 to: 'list-set!!'].
			p := p cdr].
		p class == SchemePair ifFalse: [SchemePrims badRange: k arg: 2 to: 'list-set!!'].
		p car: v.
		SchemeUnspec].
	Scheme def: 'sublist' do: [:l :s :e |
		| a |
		a := SchemePrims listArray: l arg: 1 to: 'sublist'.
		(s isInteger and: [s >= 0 and: [s <= a size]]) ifFalse: [SchemePrims badRange: s arg: 2 to: 'sublist'].
		(e isInteger and: [e >= s and: [e <= a size]]) ifFalse: [SchemePrims badRange: e arg: 3 to: 'sublist'].
		SchemePair fromArray: (a copyFrom: s + 1 to: e)].
	Scheme def: 'list-copy' do: [:l |
		| items p |
		items := OrderedCollection new. p := l.
		[p class == SchemePair] whileTrue: [items add: p car. p := p cdr].
		SchemePair fromArray: items asArray tail: p].
	Scheme def: 'last-pair' do: [:l |
		| p |
		l class == SchemePair ifFalse: [SchemePrims wrong: l arg: 1 to: 'last-pair'].
		p := l.
		[p cdr class == SchemePair] whileTrue: [p := p cdr].
		p].
	Scheme def: 'last' do: [:l |
		| p |
		l class == SchemePair ifFalse: [SchemePrims wrong: l arg: 1 to: 'last'].
		p := l.
		[p cdr class == SchemePair] whileTrue: [p := p cdr].
		p car].
	#('first' 'second' 'third' 'fourth' 'fifth') doWithIndex: [:name :i |
		Scheme def: name do: [:l |
			| p |
			p := l.
			(i - 1) timesRepeat: [p class == SchemePair ifTrue: [p := p cdr]].
			p class == SchemePair ifFalse: [SchemePrims wrong: l arg: 1 to: name].
			p car]].
	Scheme def: 'memq' do: [:x :l | SchemePrims memq: x in: l].
	Scheme alias: 'memv' for: 'memq'.
	Scheme def: '%member' do: [:x :l | SchemePrims member: x in: l].
	Scheme def: 'assq' do: [:x :l | SchemePrims assq: x in: l].
	Scheme alias: 'assv' for: 'assq'.
	Scheme def: '%assoc' do: [:x :l | SchemePrims assoc: x in: l].
	Scheme def: 'delete' min: 2 max: 3 rest: [:args |
		| items p x |
		x := args at: 1.
		items := OrderedCollection new. p := args at: 2.
		[p class == SchemePair] whileTrue: [
			(SchemePrims equal: x to: p car) ifFalse: [items add: p car].
			p := p cdr].
		SchemePair fromArray: items asArray].
	Scheme alias: 'delete!!' for: 'delete'.
	Scheme def: 'iota' min: 1 max: 3 rest: [:args |
		| n start step items |
		n := args at: 1.
		(n isInteger and: [n >= 0]) ifFalse: [SchemePrims wrong: n arg: 1 to: 'iota'].
		start := args size >= 2 ifTrue: [args at: 2] ifFalse: [0].
		step := args size >= 3 ifTrue: [args at: 3] ifFalse: [1].
		items := Array new: n.
		1 to: n do: [:i | items at: i put: start + ((i - 1) * step)].
		SchemePair fromArray: items].
	Scheme def: 'list->vector' do: [:l | (SchemePrims listArray: l arg: 1 to: 'list->vector') copy].
	Scheme def: 'vector->list' min: 1 max: 3 rest: [:args |
		| v r |
		v := args at: 1.
		v class == Array ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector->list'].
		r := SchemePrims range: args from: 2 of: v size to: 'vector->list'.
		SchemePair fromArray: (v copyFrom: (r at: 1) + 1 to: (r at: 2))]! !

!SchemePrims class methodsFor: 'lists helpers'!
memq: x in: l
	| p |
	p := l.
	[p class == SchemePair] whileTrue: [
		(self eqv: x to: p car) ifTrue: [^p].
		p := p cdr].
	^false!
member: x in: l
	| p |
	p := l.
	[p class == SchemePair] whileTrue: [
		(self equal: x to: p car) ifTrue: [^p].
		p := p cdr].
	^false!
assq: x in: l
	| p |
	p := l.
	[p class == SchemePair] whileTrue: [
		(p car class == SchemePair and: [self eqv: x to: p car car]) ifTrue: [^p car].
		p := p cdr].
	^false!
assoc: x in: l
	| p |
	p := l.
	[p class == SchemePair] whileTrue: [
		(p car class == SchemePair and: [self equal: x to: p car car]) ifTrue: [^p car].
		p := p cdr].
	^false!
reverseOnto: l
	| r p |
	r := SchemeNil. p := l.
	[p class == SchemePair] whileTrue: [r := SchemePair car: p car cdr: r. p := p cdr].
	^r! !

!SchemePrims class methodsFor: 'characters'!
installChars
	Scheme def: 'char?' do: [:x | x isCharacter].
	Scheme def: 'char->integer' do: [:c | (SchemePrims chr: c arg: 1 to: 'char->integer') value].
	Scheme def: 'integer->char' do: [:n |
		(n isInteger and: [n >= 0 and: [n < 1114112]]) ifFalse: [SchemePrims wrong: n arg: 1 to: 'integer->char'].
		Character value: n].
	Scheme def: 'char-upcase' do: [:c | (SchemePrims chr: c arg: 1 to: 'char-upcase') asUppercase].
	Scheme def: 'char-downcase' do: [:c | (SchemePrims chr: c arg: 1 to: 'char-downcase') asLowercase].
	Scheme def: 'char-alphabetic?' do: [:c | (SchemePrims chr: c arg: 1 to: 'char-alphabetic?') isLetter].
	Scheme def: 'char-numeric?' do: [:c | (SchemePrims chr: c arg: 1 to: 'char-numeric?') isDigit].
	Scheme def: 'char-whitespace?' do: [:c | (SchemePrims chr: c arg: 1 to: 'char-whitespace?') isSeparator].
	Scheme def: 'char-upper-case?' do: [:c | (SchemePrims chr: c arg: 1 to: 'char-upper-case?') isUppercase].
	Scheme def: 'char-lower-case?' do: [:c | (SchemePrims chr: c arg: 1 to: 'char-lower-case?') isLowercase].
	Scheme def: 'char-ascii?' do: [:c | (SchemePrims chr: c arg: 1 to: 'char-ascii?') value < 128].
	Scheme def: 'char=?' min: 1 max: nil rest: [:args | SchemePrims compareChars: args name: 'char=?' ci: false with: [:a :b | a = b]].
	Scheme def: 'char<?' min: 1 max: nil rest: [:args | SchemePrims compareChars: args name: 'char<?' ci: false with: [:a :b | a < b]].
	Scheme def: 'char>?' min: 1 max: nil rest: [:args | SchemePrims compareChars: args name: 'char>?' ci: false with: [:a :b | a > b]].
	Scheme def: 'char<=?' min: 1 max: nil rest: [:args | SchemePrims compareChars: args name: 'char<=?' ci: false with: [:a :b | a <= b]].
	Scheme def: 'char>=?' min: 1 max: nil rest: [:args | SchemePrims compareChars: args name: 'char>=?' ci: false with: [:a :b | a >= b]].
	Scheme def: 'char-ci=?' min: 1 max: nil rest: [:args | SchemePrims compareChars: args name: 'char-ci=?' ci: true with: [:a :b | a = b]].
	Scheme def: 'char-ci<?' min: 1 max: nil rest: [:args | SchemePrims compareChars: args name: 'char-ci<?' ci: true with: [:a :b | a < b]].
	Scheme def: 'digit-value' do: [:c |
		(SchemePrims chr: c arg: 1 to: 'digit-value') isDigit ifTrue: [c value - 48] ifFalse: [false]].
	Scheme def: 'char->digit' min: 1 max: 2 rest: [:args |
		| d |
		d := SchemeReader digitOf: (SchemePrims chr: (args at: 1) arg: 1 to: 'char->digit') radix: (args size = 2 ifTrue: [args at: 2] ifFalse: [10]).
		d isNil ifTrue: [false] ifFalse: [d]].
	Scheme def: 'digit->char' min: 1 max: 2 rest: [:args |
		| d r |
		d := args at: 1. r := args size = 2 ifTrue: [args at: 2] ifFalse: [10].
		(d isInteger and: [d >= 0 and: [d < r]]) ifTrue: [('0123456789abcdefghijklmnopqrstuvwxyz' at: d + 1)] ifFalse: [false]].
	Scheme def: 'char->string' do: [:c | String with: (SchemePrims chr: c arg: 1 to: 'char->string')]! !

!SchemePrims class methodsFor: 'strings'!
installStrings
	Scheme def: 'string?' do: [:x | x isString and: [x isSymbol not]].
	Scheme def: 'symbol?' do: [:x | x isSymbol].
	Scheme def: 'make-string' min: 1 max: 2 rest: [:args |
		| n |
		n := args at: 1.
		(n isInteger and: [n >= 0]) ifFalse: [SchemePrims wrong: n arg: 1 to: 'make-string'].
		String new: n withAll: (args size = 2 ifTrue: [SchemePrims chr: (args at: 2) arg: 2 to: 'make-string'] ifFalse: [Character space])].
	Scheme def: 'string' min: 0 max: nil rest: [:args |
		| ws |
		ws := WriteStream on: String new.
		args do: [:a | a isCharacter ifTrue: [ws nextPut: a] ifFalse: [ws nextPutAll: (SchemePrinter display: a)]].
		ws contents].
	Scheme def: 'string-length' do: [:s | (SchemePrims str: s arg: 1 to: 'string-length') size].
	Scheme def: 'string-ref' do: [:s :i |
		(SchemePrims str: s arg: 1 to: 'string-ref').
		s at: (SchemePrims index: i size: s size arg: 2 to: 'string-ref') + 1].
	Scheme def: 'string-set!!' do: [:s :i :c |
		(SchemePrims str: s arg: 1 to: 'string-set!!').
		SchemePrims chr: c arg: 3 to: 'string-set!!'.
		s at: (SchemePrims index: i size: s size arg: 2 to: 'string-set!!') + 1 put: c.
		SchemeUnspec].
	Scheme def: 'string=?' min: 1 max: nil rest: [:args | SchemePrims compareStrings: args name: 'string=?' ci: false with: [:a :b | a = b]].
	Scheme def: 'string<?' min: 1 max: nil rest: [:args | SchemePrims compareStrings: args name: 'string<?' ci: false with: [:a :b | a < b]].
	Scheme def: 'string>?' min: 1 max: nil rest: [:args | SchemePrims compareStrings: args name: 'string>?' ci: false with: [:a :b | a > b]].
	Scheme def: 'string<=?' min: 1 max: nil rest: [:args | SchemePrims compareStrings: args name: 'string<=?' ci: false with: [:a :b | a <= b]].
	Scheme def: 'string>=?' min: 1 max: nil rest: [:args | SchemePrims compareStrings: args name: 'string>=?' ci: false with: [:a :b | a >= b]].
	Scheme def: 'string-ci=?' min: 1 max: nil rest: [:args | SchemePrims compareStrings: args name: 'string-ci=?' ci: true with: [:a :b | a = b]].
	Scheme def: 'string-ci<?' min: 1 max: nil rest: [:args | SchemePrims compareStrings: args name: 'string-ci<?' ci: true with: [:a :b | a < b]].
	Scheme def: 'substring' min: 2 max: 3 rest: [:args |
		| s r |
		s := SchemePrims str: (args at: 1) arg: 1 to: 'substring'.
		r := SchemePrims range: args from: 2 of: s size to: 'substring'.
		s copyFrom: (r at: 1) + 1 to: (r at: 2)].
	Scheme def: 'string-head' do: [:s :e |
		SchemePrims str: s arg: 1 to: 'string-head'.
		(e isInteger and: [e >= 0 and: [e <= s size]]) ifFalse: [SchemePrims badRange: e arg: 2 to: 'string-head'].
		s copyFrom: 1 to: e].
	Scheme def: 'string-tail' do: [:s :b |
		SchemePrims str: s arg: 1 to: 'string-tail'.
		(b isInteger and: [b >= 0 and: [b <= s size]]) ifFalse: [SchemePrims badRange: b arg: 2 to: 'string-tail'].
		s copyFrom: b + 1 to: s size].
	Scheme def: 'string-append' min: 0 max: nil rest: [:args |
		| ws |
		ws := WriteStream on: String new.
		1 to: args size do: [:i | ws nextPutAll: (SchemePrims str: (args at: i) arg: i to: 'string-append')].
		ws contents].
	Scheme def: 'string-copy' min: 1 max: 3 rest: [:args |
		| s r |
		s := SchemePrims str: (args at: 1) arg: 1 to: 'string-copy'.
		r := SchemePrims range: args from: 2 of: s size to: 'string-copy'.
		s copyFrom: (r at: 1) + 1 to: (r at: 2)].
	Scheme def: 'string-copy!!' min: 3 max: 5 rest: [:args |
		| to at from r |
		to := SchemePrims str: (args at: 1) arg: 1 to: 'string-copy!!'.
		at := args at: 2.
		from := SchemePrims str: (args at: 3) arg: 3 to: 'string-copy!!'.
		r := SchemePrims range: args from: 4 of: from size to: 'string-copy!!'.
		(at isInteger and: [at >= 0 and: [at + ((r at: 2) - (r at: 1)) <= to size]]) ifFalse: [SchemePrims badRange: at arg: 2 to: 'string-copy!!'].
		(from copyFrom: (r at: 1) + 1 to: (r at: 2)) doWithIndex: [:c :i | to at: at + i put: c].
		SchemeUnspec].
	Scheme def: 'string-fill!!' min: 2 max: 4 rest: [:args |
		| s r |
		s := SchemePrims str: (args at: 1) arg: 1 to: 'string-fill!!'.
		SchemePrims chr: (args at: 2) arg: 2 to: 'string-fill!!'.
		r := SchemePrims range: args from: 3 of: s size to: 'string-fill!!'.
		(r at: 1) + 1 to: (r at: 2) do: [:i | s at: i put: (args at: 2)].
		SchemeUnspec].
	Scheme def: 'string->list' min: 1 max: 3 rest: [:args |
		| s r |
		s := SchemePrims str: (args at: 1) arg: 1 to: 'string->list'.
		r := SchemePrims range: args from: 2 of: s size to: 'string->list'.
		SchemePair fromArray: ((s copyFrom: (r at: 1) + 1 to: (r at: 2)) asArray)].
	Scheme def: 'list->string' do: [:l |
		| ws |
		ws := WriteStream on: String new.
		(SchemePrims listArray: l arg: 1 to: 'list->string') do: [:c | ws nextPut: (SchemePrims chr: c arg: 1 to: 'list->string')].
		ws contents].
	Scheme def: 'string->vector' do: [:s | (SchemePrims str: s arg: 1 to: 'string->vector') asArray].
	Scheme def: 'vector->string' do: [:v |
		| ws |
		v class == Array ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector->string'].
		ws := WriteStream on: String new.
		v do: [:c | ws nextPut: (SchemePrims chr: c arg: 1 to: 'vector->string')].
		ws contents].
	Scheme def: 'string->symbol' do: [:s | (SchemePrims str: s arg: 1 to: 'string->symbol') asSymbol].
	Scheme alias: 'intern' for: 'string->symbol'.
	Scheme def: 'symbol->string' do: [:s |
		s isSymbol ifFalse: [SchemePrims wrong: s arg: 1 to: 'symbol->string'].
		SchemePrims plainString: s].
	Scheme def: 'symbol-append' min: 0 max: nil rest: [:args |
		| ws |
		ws := WriteStream on: String new.
		args do: [:a | ws nextPutAll: a].
		ws contents asSymbol].
	Scheme def: 'symbol<?' min: 1 max: nil rest: [:args |
		| ok |
		ok := true.
		1 to: args size - 1 do: [:i | (SchemePrims plainString: (args at: i)) < (SchemePrims plainString: (args at: i + 1)) ifFalse: [ok := false]].
		ok].
	Scheme def: 'string-upcase' do: [:s | (SchemePrims str: s arg: 1 to: 'string-upcase') asUppercase].
	Scheme def: 'string-downcase' do: [:s | (SchemePrims str: s arg: 1 to: 'string-downcase') asLowercase].
	Scheme def: 'string-null?' do: [:s | (SchemePrims str: s arg: 1 to: 'string-null?') isEmpty].
	Scheme def: 'string-reverse' do: [:s | (SchemePrims str: s arg: 1 to: 'string-reverse') reverse].
	Scheme def: 'string-index' do: [:s :c |
		| i |
		SchemePrims str: s arg: 1 to: 'string-index'.
		i := s indexOf: (SchemePrims chr: c arg: 2 to: 'string-index').
		i = 0 ifTrue: [false] ifFalse: [i - 1]].
	Scheme def: 'string-search-forward' do: [:pat :s :start |
		| i |
		SchemePrims str: pat arg: 1 to: 'string-search-forward'. SchemePrims str: s arg: 2 to: 'string-search-forward'.
		i := s indexOfSubCollection: pat startingAt: start + 1.
		i = 0 ifTrue: [false] ifFalse: [i - 1]].
	Scheme def: 'string-search-backward' do: [:pat :s :end |
		| i found |
		SchemePrims str: pat arg: 1 to: 'string-search-backward'. SchemePrims str: s arg: 2 to: 'string-search-backward'.
		found := false.
		end - pat size + 1 to: 1 by: -1 do: [:from |
			found == false ifTrue: [
				(from >= 1 and: [(s copyFrom: from to: from + pat size - 1) = pat]) ifTrue: [found := from + pat size - 1]]].
		found].
	Scheme def: 'string-search-all' do: [:pat :s |
		| items i |
		SchemePrims str: pat arg: 1 to: 'string-search-all'. SchemePrims str: s arg: 2 to: 'string-search-all'.
		items := OrderedCollection new. i := 1.
		[i := s indexOfSubCollection: pat startingAt: i. i > 0] whileTrue: [items add: i - 1. i := i + 1].
		SchemePair fromArray: items asArray].
	Scheme def: 'string-contains' do: [:s :pat |
		| i |
		SchemePrims str: s arg: 1 to: 'string-contains'. SchemePrims str: pat arg: 2 to: 'string-contains'.
		pat isEmpty ifTrue: [0] ifFalse: [
			i := s indexOfSubCollection: pat startingAt: 1.
			i = 0 ifTrue: [false] ifFalse: [i - 1]]].
	Scheme def: 'string-prefix?' do: [:p :s |
		SchemePrims str: p arg: 1 to: 'string-prefix?'. SchemePrims str: s arg: 2 to: 'string-prefix?'.
		p size <= s size and: [(s copyFrom: 1 to: p size) = p]].
	Scheme def: 'string-suffix?' do: [:p :s |
		SchemePrims str: p arg: 1 to: 'string-suffix?'. SchemePrims str: s arg: 2 to: 'string-suffix?'.
		p size <= s size and: [(s copyFrom: s size - p size + 1 to: s size) = p]].
	Scheme def: 'string-trim' do: [:s | (SchemePrims str: s arg: 1 to: 'string-trim') trimBoth].
	Scheme def: 'string-trim-left' do: [:s |
		| i |
		SchemePrims str: s arg: 1 to: 'string-trim-left'.
		i := 1.
		[i <= s size and: [(s at: i) isSeparator]] whileTrue: [i := i + 1].
		s copyFrom: i to: s size].
	Scheme def: 'string-trim-right' do: [:s |
		| i |
		SchemePrims str: s arg: 1 to: 'string-trim-right'.
		i := s size.
		[i >= 1 and: [(s at: i) isSeparator]] whileTrue: [i := i - 1].
		s copyFrom: 1 to: i].
	Scheme def: 'string-pad-left' min: 2 max: 3 rest: [:args |
		| s n c |
		s := SchemePrims str: (args at: 1) arg: 1 to: 'string-pad-left'. n := args at: 2.
		c := args size = 3 ifTrue: [args at: 3] ifFalse: [Character space].
		(n isInteger and: [n >= 0]) ifFalse: [SchemePrims wrong: n arg: 2 to: 'string-pad-left'].
		n <= s size
			ifTrue: [s copyFrom: s size - n + 1 to: s size]
			ifFalse: [(String new: n - s size withAll: c), s]].
	Scheme def: 'string-pad-right' min: 2 max: 3 rest: [:args |
		| s n c |
		s := SchemePrims str: (args at: 1) arg: 1 to: 'string-pad-right'. n := args at: 2.
		c := args size = 3 ifTrue: [args at: 3] ifFalse: [Character space].
		(n isInteger and: [n >= 0]) ifFalse: [SchemePrims wrong: n arg: 2 to: 'string-pad-right'].
		n <= s size
			ifTrue: [s copyFrom: 1 to: n]
			ifFalse: [s, (String new: n - s size withAll: c)]].
	Scheme def: 'string-join' min: 1 max: 2 rest: [:args |
		| ws first delim |
		delim := args size = 2 ifTrue: [SchemePrims str: (args at: 2) arg: 2 to: 'string-join'] ifFalse: [' '].
		ws := WriteStream on: String new. first := true.
		(SchemePrims listArray: (args at: 1) arg: 1 to: 'string-join') do: [:each |
			first ifFalse: [ws nextPutAll: delim].
			first := false.
			ws nextPutAll: (SchemePrims str: each arg: 1 to: 'string-join')].
		ws contents].
	Scheme def: 'string-split' min: 2 max: 3 rest: [:args |
		| s delim parts start i |
		s := SchemePrims str: (args at: 1) arg: 1 to: 'string-split'.
		delim := (args at: 2) isCharacter ifTrue: [String with: (args at: 2)] ifFalse: [SchemePrims str: (args at: 2) arg: 2 to: 'string-split'].
		parts := OrderedCollection new. start := 1.
		delim isEmpty
			ifTrue: [s do: [:c | parts add: (String with: c)]]
			ifFalse: [
				[i := s indexOfSubCollection: delim startingAt: start. i > 0] whileTrue: [
					parts add: (s copyFrom: start to: i - 1).
					start := i + delim size].
				parts add: (s copyFrom: start to: s size)].
		SchemePair fromArray: parts asArray].
	Scheme def: 'string-count-char' do: [:s :c | (SchemePrims str: s arg: 1 to: 'string-count-char') occurrencesOf: c].
	Scheme def: 'string-hash' do: [:s | (SchemePrims str: s arg: 1 to: 'string-hash') hash]! !

!SchemePrims class methodsFor: 'vectors'!
installVectors
	Scheme def: 'vector?' do: [:x | x class == Array].
	Scheme def: 'make-vector' min: 1 max: 2 rest: [:args |
		| n |
		n := args at: 1.
		(n isInteger and: [n >= 0]) ifFalse: [SchemePrims wrong: n arg: 1 to: 'make-vector'].
		Array new: n withAll: (args size = 2 ifTrue: [args at: 2] ifFalse: [false])].
	Scheme def: 'vector' min: 0 max: nil rest: [:args | args copy].
	Scheme def: 'vector-length' do: [:v | v class == Array ifTrue: [v size] ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector-length']].
	Scheme def: 'vector-ref' do: [:v :i |
		v class == Array ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector-ref'].
		(i isInteger and: [i >= 0 and: [i < v size]]) ifFalse: [
			i isInteger ifFalse: [SchemePrims wrong: i arg: 2 to: 'vector-ref'].
			SchemePrims badRange: i arg: 2 to: 'vector-ref'].
		v at: i + 1].
	Scheme def: 'vector-set!!' do: [:v :i :x |
		v class == Array ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector-set!!'].
		(i isInteger and: [i >= 0 and: [i < v size]]) ifFalse: [
			i isInteger ifFalse: [SchemePrims wrong: i arg: 2 to: 'vector-set!!'].
			SchemePrims badRange: i arg: 2 to: 'vector-set!!'].
		v at: i + 1 put: x.
		SchemeUnspec].
	Scheme def: 'vector-fill!!' min: 2 max: 4 rest: [:args |
		| v r |
		v := args at: 1.
		v class == Array ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector-fill!!'].
		r := SchemePrims range: args from: 3 of: v size to: 'vector-fill!!'.
		(r at: 1) + 1 to: (r at: 2) do: [:i | v at: i put: (args at: 2)].
		SchemeUnspec].
	Scheme def: 'vector-grow' do: [:v :n |
		| new |
		v class == Array ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector-grow'].
		(n isInteger and: [n >= v size]) ifFalse: [SchemePrims badRange: n arg: 2 to: 'vector-grow'].
		new := Array new: n withAll: false.
		new replaceFrom: 1 to: v size with: v startingAt: 1.
		new].
	Scheme def: 'vector-copy' min: 1 max: 3 rest: [:args |
		| v r |
		v := args at: 1.
		v class == Array ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector-copy'].
		r := SchemePrims range: args from: 2 of: v size to: 'vector-copy'.
		v copyFrom: (r at: 1) + 1 to: (r at: 2)].
	Scheme def: 'subvector' do: [:v :s :e |
		| r |
		v class == Array ifFalse: [SchemePrims wrong: v arg: 1 to: 'subvector'].
		r := SchemePrims range: (Array with: v with: s with: e) from: 2 of: v size to: 'subvector'.
		v copyFrom: s + 1 to: e].
	Scheme def: 'vector-head' do: [:v :e |
		v class == Array ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector-head'].
		(e isInteger and: [e >= 0 and: [e <= v size]]) ifFalse: [SchemePrims badRange: e arg: 2 to: 'vector-head'].
		v copyFrom: 1 to: e].
	Scheme def: 'vector-tail' do: [:v :b |
		v class == Array ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector-tail'].
		(b isInteger and: [b >= 0 and: [b <= v size]]) ifFalse: [SchemePrims badRange: b arg: 2 to: 'vector-tail'].
		v copyFrom: b + 1 to: v size].
	Scheme def: 'vector-copy!!' min: 3 max: 5 rest: [:args |
		| to at from r piece |
		to := args at: 1. at := args at: 2. from := args at: 3.
		(to class == Array) ifFalse: [SchemePrims wrong: to arg: 1 to: 'vector-copy!!'].
		(from class == Array) ifFalse: [SchemePrims wrong: from arg: 3 to: 'vector-copy!!'].
		r := SchemePrims range: args from: 4 of: from size to: 'vector-copy!!'.
		(at isInteger and: [at >= 0 and: [at + ((r at: 2) - (r at: 1)) <= to size]]) ifFalse: [SchemePrims badRange: at arg: 2 to: 'vector-copy!!'].
		piece := from copyFrom: (r at: 1) + 1 to: (r at: 2).
		piece doWithIndex: [:x :i | to at: at + i put: x].
		SchemeUnspec].
	Scheme def: 'vector-append' min: 0 max: nil rest: [:args |
		| out |
		out := OrderedCollection new.
		1 to: args size do: [:i |
			(args at: i) class == Array ifFalse: [SchemePrims wrong: (args at: i) arg: i to: 'vector-append'].
			out addAll: (args at: i)].
		out asArray].
	Scheme def: 'vector-first' do: [:v | (v class == Array and: [v notEmpty]) ifTrue: [v first] ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector-first']].
	Scheme def: 'vector-last' do: [:v | (v class == Array and: [v notEmpty]) ifTrue: [v last] ifFalse: [SchemePrims wrong: v arg: 1 to: 'vector-last']]! !
