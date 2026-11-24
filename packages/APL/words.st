"APLLexer: sentences to words, the way J does it. Blanks separate words, a quoted string is one word (with a doubled
quote for a quote), a run of numbers is one noun, a name that ends in a dot or colon is a primitive or a control word,
and any other symbol is looked up, longest first, among the spellings of the primitives. A token is an Array of the
kind (#num #str #name #prim #asgn #lparen #rparen #nl #ctrl), the text and, for a number or string, the array."

!APLLexer class methodsFor: 'lexing'!
tokens: aString
	"the tokens of a text, newlines included, as an OrderedCollection"
	^self new setSource: (self translateGlyphs: aString); run; tokens!
glyphPairs
	"the classic APL glyphs that may be typed in place of the J spelling: an Array of pairs (glyph spelling)"
	^#(#('⍳' 'i.') #('⍴' '$') #('⌽' '|.') #('⊖' '|.') #('⍉' '|:') #('⍋' '/:') #('⍒' '\:') #('⌈' '>.') #('⌊' '<.')
		#('←' '=:') #('⍬' '(0$0)') #('⍕' '":') #('⍎' '".') #('×' '*') #('÷' '%') #('≠' '~:') #('≤' '<:') #('≥' '>:')
		#('∊' 'e.') #('⊂' '<') #('⊃' '>') #('∪' '~.') #('⌷' '{') #('↑' '{.') #('↓' '}.') #('⍪' ',.') #('○' 'o.')
		#('⍟' '^.') #('⍨' '~') #('¨' '&.>') #('∘' '@:') #('⌿' '/') #('⍀' '\') #('⍤' '"') #('∧' '*.') #('∨' '+.')
		#('⍸' 'I.') #('⊣' '[') #('⊢' ']') #('≡' '-:') #('−' '-') #('⍝' 'NB.') #('¯' '_') #('⋄' '
'))!
translateGlyphs: aString
	"replace the APL glyphs outside quoted strings by their J spellings"
	| out seg inQuote c pairs |
	(aString anySatisfy: [:ch | ch value > 127]) ifFalse: [^aString].
	pairs := self glyphPairs.
	out := WriteStream on: String new.
	seg := WriteStream on: String new.
	inQuote := false.
	aString do: [:ch |
		ch = $'
			ifTrue: [
				inQuote ifFalse: [out nextPutAll: (self translateSegment: seg contents with: pairs). seg := WriteStream on: String new].
				out nextPut: ch.
				inQuote := inQuote not]
			ifFalse: [inQuote ifTrue: [out nextPut: ch] ifFalse: [seg nextPut: ch]]].
	out nextPutAll: (self translateSegment: seg contents with: pairs).
	^out contents!
translateSegment: aString with: pairs
	| t |
	t := aString.
	pairs do: [:p | | sp |
		sp := p at: 2.
		t := t copyReplaceAll: (p at: 1) with: (((sp = '_') or: [sp size = 1 and: [sp first = Character lf]]) ifTrue: [sp] ifFalse: [' ', sp, ' '])].
	^t!
inflected
	"the names that take a dot or colon to make a primitive"
	Inflected isNil ifTrue: [
		Inflected := #('i.' 'i:' 'e.' 'j.' 'o.' 'p.' 'p:' 'q:' 'x:' 'u:' 's:' 'a.' 'a:' 'A.' 'C.' 'E.' 'I.' 'L.' 'L:' 'S:' 'T.' 'b.' 'd.' 'D.' 'f.' 'F.' 'H.' 'M.' 't.' 't:' 'u.' 'x.' 'z:' 'NB.'
			'if.' 'else.' 'elseif.' 'end.' 'do.' 'for.' 'while.' 'whilst.' 'select.' 'case.' 'fcase.' 'return.' 'break.' 'continue.' 'try.' 'catch.' 'catchd.' 'catcht.' 'throw.' 'assert.')].
	^Inflected!
controlWords
	^#('if.' 'else.' 'elseif.' 'end.' 'do.' 'for.' 'while.' 'whilst.' 'select.' 'case.' 'fcase.' 'return.' 'break.' 'continue.' 'try.' 'catch.' 'catchd.' 'catcht.' 'throw.' 'assert.')!
parseNumber: w
	"the number a word stands for, or nil if it is not one"
	| s neg r e mant ex val dot |
	w = '_' ifTrue: [^Float infinity].
	w = '__' ifTrue: [^Float infinity negated].
	s := w.
	neg := false.
	(s size > 1 and: [s first = $_]) ifTrue: [neg := true. s := s copyFrom: 2 to: s size].
	(s isEmpty or: [s first isDigit not]) ifTrue: [^nil].
	(s last = $x) ifTrue: [
		s := s copyFrom: 1 to: s size - 1.
		(s allSatisfy: [:c | c isDigit]) ifFalse: [^nil].
		val := s asInteger.
		^neg ifTrue: [val negated] ifFalse: [val]].
	r := s indexOf: $r.
	r > 0 ifTrue: [
		| n d |
		n := s copyFrom: 1 to: r - 1. d := s copyFrom: r + 1 to: s size.
		((n allSatisfy: [:c | c isDigit]) and: [d notEmpty and: [d allSatisfy: [:c | c isDigit]]]) ifFalse: [^nil].
		d asInteger = 0 ifTrue: [^nil].
		val := n asInteger / d asInteger.
		^neg ifTrue: [val negated] ifFalse: [val]].
	e := s indexOf: $e.
	ex := 0.
	e > 0
		ifTrue: [
			| es |
			mant := s copyFrom: 1 to: e - 1. es := s copyFrom: e + 1 to: s size.
			(es notEmpty and: [es first = $_]) ifTrue: [es := es copyFrom: 2 to: es size. ex := -1].
			(es notEmpty and: [es allSatisfy: [:c | c isDigit]]) ifFalse: [^nil].
			ex := ex = -1 ifTrue: [es asInteger negated] ifFalse: [es asInteger]]
		ifFalse: [mant := s].
	dot := mant indexOf: $..
	val := self decimal: mant.
	val isNil ifTrue: [^nil].
	val := val * (10 raisedTo: ex).
	(dot = 0 and: [ex >= 0]) ifFalse: [val := val asFloat].
	^neg ifTrue: [val negated] ifFalse: [val]!
decimal: aString
	"the exact value of digits with an optional point, or nil"
	| dot ip fp |
	dot := aString indexOf: $..
	dot = 0
		ifTrue: [ip := aString. fp := '']
		ifFalse: [ip := aString copyFrom: 1 to: dot - 1. fp := aString copyFrom: dot + 1 to: aString size].
	ip isEmpty ifTrue: [^nil].
	((ip allSatisfy: [:c | c isDigit]) and: [fp allSatisfy: [:c | c isDigit]]) ifFalse: [^nil].
	^(ip, fp) asInteger / (10 raisedTo: fp size)! !

!APLLexer methodsFor: 'running'!
setSource: aString
	src := aString.
	pos := 1.
	tokens := OrderedCollection new!
tokens
	^tokens!
run
	[pos <= src size] whileTrue: [self step]!
add: kind text: aString value: v
	tokens add: (Array with: kind with: aString with: v)!
peek: k
	^pos + k <= src size ifTrue: [src at: pos + k] ifFalse: [nil]!
step
	| c |
	c := src at: pos.
	c = Character lf ifTrue: [self add: #nl text: '
' value: nil. pos := pos + 1. ^self].
	c isSeparator ifTrue: [pos := pos + 1. ^self].
	c = $' ifTrue: [^self string].
	c = $( ifTrue: [self add: #lparen text: '(' value: nil. pos := pos + 1. ^self].
	c = $) ifTrue: [self add: #rparen text: ')' value: nil. pos := pos + 1. ^self].
	(c isDigit or: [c = $_]) ifTrue: [^self numbers].
	c isLetter ifTrue: [^self name].
	^self symbol!
string
	| ws done c |
	ws := WriteStream on: String new.
	pos := pos + 1.
	done := false.
	[done] whileFalse: [
		pos > src size ifTrue: [^APLError message: 'open quote'].
		c := src at: pos.
		c = $'
			ifTrue: [
				(self peek: 1) = $'
					ifTrue: [ws nextPut: $'. pos := pos + 2]
					ifFalse: [done := true. pos := pos + 1]]
			ifFalse: [ws nextPut: c. pos := pos + 1]].
	self add: #str text: ws contents value: (APLArray literal: ws contents)!
blankToEndOfLine
	"true if only blanks lie between here and the end of the line"
	| i |
	i := pos.
	[i <= src size and: [(src at: i) ~= Character lf]] whileTrue: [
		(src at: i) isSeparator ifFalse: [^false].
		i := i + 1].
	^true!
numbers
	"a run of numbers separated by blanks is one noun"
	| vals w start done last |
	vals := OrderedCollection new.
	done := false.
	[done] whileFalse: [
		start := pos.
		[pos <= src size and: [(src at: pos) isAlphaNumeric or: [(src at: pos) = $_ or: [(src at: pos) = $.]]]]
			whileTrue: [pos := pos + 1].
		w := src copyFrom: start to: pos - 1.
		last := self class parseNumber: w.
		last isNil ifTrue: [^APLError message: 'spelling error: ', w].
		vals add: last.
		"another number after blanks?"
		[pos <= src size and: [(src at: pos) = $  or: [(src at: pos) = Character tab]]] whileTrue: [pos := pos + 1].
		done := (pos > src size) or: [((src at: pos) isDigit or: [(src at: pos) = $_]) not]].
	(self isBodyMarker: vals) ifTrue: [^self captureBody].
	self add: #num text: (String new: 0) value: (vals size = 1 ifTrue: [APLArray scalar: vals first] ifFalse: [APLArray vector: vals])!
isBodyMarker: vals
	"3 : 0 starts a definition that runs to a line holding only a closing parenthesis"
	| n |
	(vals size = 1 and: [vals first = 0]) ifFalse: [^false].
	n := tokens size.
	n < 2 ifTrue: [^false].
	((tokens at: n) at: 1) == #prim ifFalse: [^false].
	((tokens at: n) at: 2) = ':' ifFalse: [^false].
	^self blankToEndOfLine!
captureBody
	| lines line start body |
	[pos <= src size and: [(src at: pos) ~= Character lf]] whileTrue: [pos := pos + 1].
	pos := pos + 1.
	lines := OrderedCollection new.
	[pos <= src size] whileTrue: [
		start := pos.
		[pos <= src size and: [(src at: pos) ~= Character lf]] whileTrue: [pos := pos + 1].
		line := src copyFrom: start to: pos - 1.
		pos := pos + 1.
		line trimBoth = ')' ifTrue: [
			body := self join: lines.
			self add: #str text: body value: (APLArray text: body).
			self add: #nl text: '
' value: nil.
			^self].
		lines add: line].
	^APLError message: 'open definition'!
join: lines
	| ws |
	ws := WriteStream on: String new.
	lines doWithIndex: [:l :i | i > 1 ifTrue: [ws nextPut: Character lf]. ws nextPutAll: l].
	^ws contents!
name
	| start nm nxt text |
	start := pos.
	[pos <= src size and: [(src at: pos) isAlphaNumeric or: [(src at: pos) = $_]]] whileTrue: [pos := pos + 1].
	nm := src copyFrom: start to: pos - 1.
	nxt := self peek: 0.
	((nxt = $. or: [nxt = $:]) and: [self isInflected: nm with: nxt]) ifTrue: [
		pos := pos + 1.
		text := nm, (String with: nxt).
		text = 'NB.' ifTrue: [
			[pos <= src size and: [(src at: pos) ~= Character lf]] whileTrue: [pos := pos + 1].
			^self].
		(self class controlWords includes: text) ifTrue: [^self add: #ctrl text: text value: nil].
		(text startsWith: 'for_') ifTrue: [^self add: #ctrl text: text value: nil].
		^self add: #prim text: text value: nil].
	(nm = 'define' and: [self isDefineWord and: [self blankToEndOfLine]]) ifTrue: [^self defineBlock].
	self add: #name text: nm value: nil!
isInflected: nm with: ch
	| text |
	text := nm, (String with: ch).
	(self class inflected includes: text) ifTrue: [^true].
	^(nm startsWith: 'for_') and: [ch = $.]!
isDefineWord
	| n w |
	n := tokens size.
	n < 1 ifTrue: [^false].
	(((tokens at: n) at: 1) == #name) ifFalse: [^false].
	w := (tokens at: n) at: 2.
	^#('verb' 'monad' 'dyad' 'adverb' 'conjunction' 'noun') includes: w!
defineBlock
	"verb define (and its relatives) followed by lines to a closing parenthesis"
	| w k |
	w := (tokens removeLast) at: 2.
	k := w = 'noun' ifTrue: [0] ifFalse: [w = 'adverb' ifTrue: [1] ifFalse: [w = 'conjunction' ifTrue: [2] ifFalse: [w = 'dyad' ifTrue: [4] ifFalse: [3]]]].
	self add: #num text: (String new: 0) value: (APLArray scalar: k).
	self add: #prim text: ':' value: nil.
	self captureBody!
symbol
	| len cand |
	len := 3.
	[len >= 1] whileTrue: [
		pos + len - 1 <= src size ifTrue: [
			cand := src copyFrom: pos to: pos + len - 1.
			(cand = '=.' or: [cand = '=:']) ifTrue: [self add: #asgn text: cand value: nil. pos := pos + len. ^self].
			(APLPrims isSpelling: cand) ifTrue: [self add: #prim text: cand value: nil. pos := pos + len. ^self]].
		len := len - 1].
	^APLError message: 'spelling error: ', (String with: (src at: pos))! !
