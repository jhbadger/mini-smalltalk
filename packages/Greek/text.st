"Greek: the letters.  GreekText knows which letters are vowels, which carry the accent (the tonos), how a
word divides into syllables, and how to move the accent from one syllable to another, which is most of what
the inflection of nouns and verbs needs.  It works on WideStrings, where one element is one letter; what it
answers is an ordinary String holding UTF-8, which is what the rest of the system prints and stores.

GreekTable is a small table that prints itself as text, with columns lined up by letters rather than bytes.

The String messages at the end are the way in: 'gra/fw' asGreek, 'γράφω' greekStripped, greekUppercase,
greekTransliterated, greekSyllableCount, greekAccentPosition."

Object subclass: #GreekText instanceVariableNames: '' classVariableNames: 'Plain Accented Beta Latin' category: 'Greek-Grammar'!
Object subclass: #GreekTable instanceVariableNames: 'title header rows notes' classVariableNames: '' category: 'Greek-Grammar'!

!GreekText class methodsFor: 'letters'!
plainVowels
	"the vowels without an accent, the two with a diaeresis last"
	^Plain ifNil: [Plain := 'αεηιουωϊϋ' asWideString]!
accentedVowels
	"the same vowels with the tonos, in the same order"
	^Accented ifNil: [Accented := 'άέήίόύώΐΰ' asWideString]!
isVowel: aCharacter
	^(self plainVowels includes: aCharacter) or: [self accentedVowels includes: aCharacter]!
isAccented: aCharacter
	^self accentedVowels includes: aCharacter!
isConsonant: aCharacter
	^aCharacter isLetter and: [(self isVowel: aCharacter) not]!
stripCharacter: aCharacter
	| i |
	i := self accentedVowels indexOf: aCharacter.
	^i = 0 ifTrue: [aCharacter] ifFalse: [self plainVowels at: i]!
accentCharacter: aCharacter
	| i |
	i := self plainVowels indexOf: aCharacter.
	^i = 0 ifTrue: [aCharacter] ifFalse: [self accentedVowels at: i]!
iota
	^self plainVowels at: 4!
upsilon
	^self plainVowels at: 6! !

!GreekText class methodsFor: 'syllables'!
wide: aString
	^aString isWideString ifTrue: [aString] ifFalse: [aString asWideString]!
isDigraph: first with: second
	"two vowel letters that are read as one: αι ει οι υι, and αυ ευ ηυ ου. An accent on the first letter or
	a diaeresis on the second keeps them apart, as in Μάιος and κοροϊδεύω."
	| a |
	(self isAccented: first) ifTrue: [^false].
	a := first.
	((second = self iota) or: [second = (self accentCharacter: self iota)])
		ifTrue: [^'αεου' asWideString includes: a].
	((second = self upsilon) or: [second = (self accentCharacter: self upsilon)])
		ifTrue: [^'αεηο' asWideString includes: a].
	^false!
nucleiOf: aString
	"where the syllables of the word are: an Array of (first last) letter positions of each vowel sound.
	A digraph is one sound; so is an unaccented ι between a consonant and a vowel, which is said as a
	glide, as in παιδιά and σπιτιού (two syllables each), and in διαβάζω."
	| w n out i start stop c |
	w := self wide: aString.
	n := w size.
	out := OrderedCollection new.
	i := 1.
	[i <= n] whileTrue: [
		c := w at: i.
		(self isVowel: c)
			ifFalse: [i := i + 1]
			ifTrue: [
				start := i. stop := i.
				(c = self iota and: [i > 1 and: [i < n
					and: [(self isVowel: (w at: i - 1)) not and: [(w at: i - 1) isLetter
					and: [self isVowel: (w at: i + 1)]]]]])
						ifTrue: [stop := i + 1].
				(stop < n and: [self isDigraph: (w at: stop) with: (w at: stop + 1)])
					ifTrue: [stop := stop + 1].
				out add: (Array with: start with: stop).
				i := stop + 1]].
	^out asArray!
syllableCount: aString
	^(self nucleiOf: aString) size!
accentPosition: aString
	"which syllable carries the accent, counting from the end: 1 for the last (οξύτονη), 2 for the one
	before (παροξύτονη), 3 for the one before that (προπαροξύτονη); 0 when there is none"
	| w nuclei |
	w := self wide: aString.
	nuclei := self nucleiOf: w.
	nuclei doWithIndex: [:each :k |
		((each at: 1) to: (each at: 2)) do: [:i |
			(self isAccented: (w at: i)) ifTrue: [^nuclei size - k + 1]]].
	^0!
accentName: aString
	^#('oxytone (on the last syllable)' 'paroxytone (on the next to last)' 'proparoxytone (on the third from last)')
		at: (self accentPosition: aString) ifAbsent: ['unaccented']! !

!GreekText class methodsFor: 'accents'!
strip: aString
	"the word without any accent (a diaeresis stays)"
	^((self wide: aString) collect: [:c | self stripCharacter: c]) utf8Encoded!
accent: aString onSyllable: k
	"the word with its accent on the k-th syllable from the end, or on the first syllable if it has fewer.
	A word of one syllable takes no accent at all."
	| w nuclei target pos |
	w := (self wide: (self strip: aString)) copy.
	nuclei := self nucleiOf: w.
	nuclei size <= 1 ifTrue: [^self finalSigma: w utf8Encoded].
	target := nuclei at: ((nuclei size - k + 1) max: 1).
	pos := target at: 2.
	w at: pos put: (self accentCharacter: (w at: pos)).
	^self finalSigma: w utf8Encoded!
accentLast: aString
	^self accent: aString onSyllable: 1!
accentPenult: aString
	^self accent: aString onSyllable: 2!
accentAntepenult: aString
	^self accent: aString onSyllable: 3!
accentLastOfStem: aStem
	"the stem with the accent on its own last syllable (θα γράψω, θα αγαπήσω); a stem with no vowel is
	answered as it is"
	| w nuclei pos |
	w := (self wide: (self strip: aStem)) copy.
	nuclei := self nucleiOf: w.
	nuclei isEmpty ifTrue: [^w utf8Encoded].
	pos := nuclei last at: 2.
	w at: pos put: (self accentCharacter: (w at: pos)).
	^w utf8Encoded!
unaccentMonosyllable: aString
	"a word of one syllable is written without an accent: δω, δεις, ζει, but δούμε"
	^(self syllableCount: aString) <= 1 ifTrue: [self strip: aString] ifFalse: [aString]!
finalSigma: aString
	"σ at the end of a word is written ς, and ς anywhere else is σ"
	| w sigma finalSigma |
	w := (self wide: aString) copy.
	sigma := Character value: 963. finalSigma := Character value: 962.
	1 to: w size do: [:i |
		((w at: i) = sigma or: [(w at: i) = finalSigma]) ifTrue: [
			w at: i put: ((i = w size or: [(w at: i + 1) isLetter not]) ifTrue: [finalSigma] ifFalse: [sigma])]].
	^w utf8Encoded!
startsWithVowel: aString
	| w |
	w := self wide: aString.
	^w notEmpty and: [self isVowel: w first]!
startsWithConsonant: aString
	| w |
	w := self wide: aString.
	^w notEmpty and: [self isConsonant: w first]!
keepsFinalN: aWord
	"whether τον, την, έναν, δεν and μην keep their ν before aWord: before a vowel, before κ π τ ξ ψ, and
	before the pairs μπ ντ γκ τσ τζ"
	| w |
	w := self wide: (self strip: aWord).
	w isEmpty ifTrue: [^false].
	(self isVowel: w first) ifTrue: [^true].
	('κπτξψ' asWideString includes: w first) ifTrue: [^true].
	w size < 2 ifTrue: [^false].
	^#('μπ' 'ντ' 'γκ' 'τσ' 'τζ') includes: (w copyFrom: 1 to: 2) utf8Encoded! !

!GreekText class methodsFor: 'converting'!
upper: aString
	"in capitals, where Greek leaves the accent off: ΓΡΑΦΩ"
	^((self wide: (self strip: aString)) collect: [:c | c asUppercase]) utf8Encoded!
betaTable
	"the Latin letters of beta code and the Greek letters they stand for"
	^Beta ifNil: [
		Beta := Dictionary new.
		'abgdezhqiklmncoprstufxyw' asWideString with: 'αβγδεζηθικλμνξοπρστυφχψω' asWideString do: [:l :g |
			Beta at: l put: g.
			Beta at: l asUppercase put: g asUppercase].
		Beta]!
fromBetaCode: aString
	"Greek letters from Latin ones, the way classicists type them: a b g d e z h q i k l m n c o p r s t u f
	x y w for α β γ δ ε ζ η θ ι κ λ μ ν ξ ο π ρ σ τ υ φ χ ψ ω; a / after a vowel puts the accent on it, and
	a + a diaeresis. A final s becomes ς by itself.
		'gra/fw' asGreek  -->  'γράφω'"
	| out w c prev |
	out := OrderedCollection new.
	w := self wide: aString.
	w do: [:ch |
		c := ch.
		(c = $/ and: [out notEmpty and: [self plainVowels includes: (prev := out last)]])
			ifTrue: [
				out removeLast.
				out add: (prev = (self plainVowels at: 8)
					ifTrue: [self accentedVowels at: 8]
					ifFalse: [prev = (self plainVowels at: 9)
						ifTrue: [self accentedVowels at: 9]
						ifFalse: [self accentCharacter: prev]])]
			ifFalse: [
				(c = $+ and: [out notEmpty and: [(out last = self iota) or: [out last = self upsilon]]])
					ifTrue: [out add: (out removeLast = self iota
						ifTrue: [self plainVowels at: 8] ifFalse: [self plainVowels at: 9])]
					ifFalse: [
						(c = $+ and: [out notEmpty and: [out last = (self accentCharacter: self iota)]])
							ifTrue: [out removeLast. out add: (self accentedVowels at: 8)]
							ifFalse: [out add: (self betaTable at: c ifAbsent: [c])]]]].
	^self finalSigma: (WideString withAll: out) utf8Encoded!
latinTable
	^Latin ifNil: [
		Latin := Dictionary new.
		'αβγδεζηθικλμνξοπρσςτυφχψωάέήίόύώϊϋΐΰ' asWideString
			with: #('a' 'v' 'g' 'd' 'e' 'z' 'i' 'th' 'i' 'k' 'l' 'm' 'n' 'x' 'o' 'p' 'r' 's' 's' 't' 'y' 'f' 'ch' 'ps' 'o'
				'á' 'é' 'í' 'í' 'ó' 'ý' 'ó' 'i' 'y' 'í' 'ý')
			do: [:g :l | Latin at: g put: l].
		Latin]!
transliterate: aString
	"the word in Latin letters, roughly as it sounds (ου is ou, αυ and ευ are av and ev)"
	| w out i c next pair |
	w := self wide: aString.
	out := WriteStream on: String new.
	i := 1.
	[i <= w size] whileTrue: [
		c := w at: i.
		next := i < w size ifTrue: [w at: i + 1] ifFalse: [nil].
		pair := nil.
		(c asLowercase = (self plainVowels at: 5) and: [next notNil and: [(self stripCharacter: next asLowercase) = self upsilon]])
			ifTrue: [pair := next asLowercase = self upsilon ifTrue: ['ou'] ifFalse: ['oú']].
		(('αε' asWideString includes: c asLowercase) and: [next notNil and: [(self stripCharacter: next asLowercase) = self upsilon]])
			ifTrue: [pair := (c asLowercase = (self plainVowels at: 1) ifTrue: ['a'] ifFalse: ['e']),
				(next asLowercase = self upsilon ifTrue: ['v'] ifFalse: ['ý'])].
		(pair notNil and: [c isUppercase]) ifTrue: [pair := pair copy. pair at: 1 put: pair first asUppercase].
		pair notNil
			ifTrue: [out nextPutAll: pair. i := i + 2]
			ifFalse: [
				| l |
				l := self latinTable at: c asLowercase ifAbsent: [c utf8Encoded].
				(c isUppercase and: [l notEmpty]) ifTrue: [l := l copy. l at: 1 put: l first asUppercase].
				out nextPutAll: l.
				i := i + 1]].
	^out contents! !

!GreekText class methodsFor: 'layout'!
widthOf: aString
	"how many columns the text takes: one per letter, not per byte"
	^(self wide: aString) size!
pad: aString to: n
	^aString , (String new: ((n - (self widthOf: aString)) max: 0) withAll: (Character value: 32))! !

"---- a table that prints itself ----"

!GreekTable class methodsFor: 'instance creation'!
title: aString
	^self new setTitle: aString!
title: aString header: anArray
	^(self title: aString) header: anArray; yourself! !

!GreekTable methodsFor: 'building'!
setTitle: aString
	title := aString. rows := OrderedCollection new. notes := OrderedCollection new!
header: anArray
	header := anArray!
add: anArray
	"a row: an Array of Strings (nil shows as a dash)"
	rows add: anArray!
note: aString
	notes add: aString! !

!GreekTable methodsFor: 'accessing'!
title
	^title!
rows
	^rows asArray!
header
	^header!
column: n
	^(rows collect: [:each | each at: n ifAbsent: [nil]]) asArray! !

!GreekTable methodsFor: 'printing'!
cellText: x
	x isNil ifTrue: [^'—'].
	^x isString ifTrue: [x isWideString ifTrue: [x utf8Encoded] ifFalse: [x]] ifFalse: [x printString]!
widths
	| all w |
	all := OrderedCollection new.
	header notNil ifTrue: [all add: header].
	all addAll: rows.
	w := Array new: (all inject: 0 into: [:m :r | m max: r size]) withAll: 0.
	all do: [:r | r doWithIndex: [:x :i |
		w at: i put: ((w at: i) max: (GreekText widthOf: (self cellText: x)))]].
	^w!
printLine: anArray widths: w on: aStream
	| line |
	line := WriteStream on: String new.
	anArray doWithIndex: [:x :i |
		i < anArray size
			ifTrue: [line nextPutAll: (GreekText pad: (self cellText: x) to: (w at: i)); nextPutAll: '   ']
			ifFalse: [line nextPutAll: (self cellText: x)]].
	aStream nextPutAll: line contents; cr!
printOn: aStream
	| w |
	w := self widths.
	title notNil ifTrue: [aStream nextPutAll: title; cr].
	header notNil ifTrue: [
		self printLine: header widths: w on: aStream.
		aStream nextPutAll: (String new: ((w inject: 0 into: [:a :b | a + b]) + (3 * (w size - 1) max: 0)) withAll: $-); cr].
	rows do: [:r | self printLine: r widths: w on: aStream].
	notes do: [:n | aStream nextPutAll: n; cr]!
contents
	^self printString!
displayString
	^self printString! !

"---- the String messages ----"

!String methodsFor: 'greek'!
asGreek
	"Greek letters typed as beta code: 'gra/fw' asGreek is 'γράφω'"
	^GreekText fromBetaCode: self!
greekStripped
	^GreekText strip: self!
greekUppercase
	^GreekText upper: self!
greekTransliterated
	^GreekText transliterate: self!
greekSyllableCount
	^GreekText syllableCount: self!
greekAccentPosition
	^GreekText accentPosition: self!
greekLetters
	"the letters one by one, each a String: 'γράφω' greekLetters size is 5, although 'γράφω' size is 10"
	^self asWideString asArray collect: [:c | c utf8Encoded]! !

!WideString methodsFor: 'greek'!
asGreek
	^GreekText fromBetaCode: self!
greekStripped
	^GreekText strip: self!
greekUppercase
	^GreekText upper: self!
greekTransliterated
	^GreekText transliterate: self!
greekLetters
	^self asArray collect: [:c | c utf8Encoded]! !
