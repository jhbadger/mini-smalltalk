"Greek: nouns, articles, adjectives and pronouns.

A GreekNoun has a gender and belongs to an inflection class, which is named by its ending in the
nominative singular: masculine -ος (ο δρόμος), -ας (ο άντρας), -ης (ο μαθητής); feminine -α (η χώρα),
-η (η τέχνη), -η with a plural in -εις (η πόλη); neuter -ο (το βιβλίο), -ι (το παιδί), -μα (το όνομα),
-ος (το δάσος).  Each class gives eight endings -- nominative, genitive, accusative and vocative, singular
and plural -- and with each a rule for the accent:

	#s  the accent stays where it is in the nominative singular (δρόμος, δρόμου)
	#l  it moves to the next to last syllable when it would otherwise be three from the end of a word
	    with a long ending: άνθρωπος, ανθρώπου, ανθρώπων
	#u  it goes on the last syllable: χώρα, χωρών; σπίτι, σπιτιού
	#p  on the next to last: ονομάτων
	#a  on the third from last: ονόματος, πόλεων
	#g  on the last if the word has two syllables, otherwise as #l: αντρών but πατέρων

A noun that does something else again is given the odd form with form:at:."

Object subclass: #GreekNoun instanceVariableNames: 'lemma gender declension stem accent gloss overrides' classVariableNames: 'Declensions' category: 'Greek-Grammar'!
Object subclass: #GreekArticle instanceVariableNames: '' classVariableNames: '' category: 'Greek-Grammar'!
Object subclass: #GreekAdjective instanceVariableNames: 'lemma pattern stem accent gloss' classVariableNames: '' category: 'Greek-Grammar'!
Object subclass: #GreekNounPhrase instanceVariableNames: 'adjective noun' classVariableNames: '' category: 'Greek-Grammar'!
Object subclass: #GreekPronoun instanceVariableNames: '' classVariableNames: '' category: 'Greek-Grammar'!

"---- the shared vocabulary of cases ----"

!GreekNoun class methodsFor: 'grammar'!
cases
	^#(#nominative #genitive #accusative #vocative)!
numbers
	^#(#singular #plural)!
genders
	^#(#masculine #feminine #neuter)!
caseNames
	^#('ονομαστική' 'γενική' 'αιτιατική' 'κλητική')!
slotFor: aCase number: aNumber
	| c |
	c := self cases indexOf: aCase.
	c = 0 ifTrue: [^self error: 'the cases are ', self cases printString].
	(self numbers includes: aNumber) ifFalse: [^self error: 'the numbers are #singular and #plural'].
	^c + (aNumber = #plural ifTrue: [4] ifFalse: [0])!
declensions
	"each class: its gender, then eight (ending rule) pairs, singular then plural"
	^Declensions ifNil: [
		Declensions := Dictionary new.
		Declensions
			at: #os put: #(#masculine 'ος' #s 'ου' #l 'ο' #s 'ε' #s 'οι' #s 'ων' #l 'ους' #l 'οι' #s);
			at: #as put: #(#masculine 'ας' #s 'α' #s 'α' #s 'α' #s 'ες' #s 'ων' #g 'ες' #s 'ες' #s);
			at: #is put: #(#masculine 'ης' #s 'η' #s 'η' #s 'η' #s 'ες' #s 'ων' #u 'ες' #s 'ες' #s);
			at: #a put: #(#feminine 'α' #s 'ας' #s 'α' #s 'α' #s 'ες' #s 'ων' #u 'ες' #s 'ες' #s);
			at: #i put: #(#feminine 'η' #s 'ης' #s 'η' #s 'η' #s 'ες' #s 'ων' #u 'ες' #s 'ες' #s);
			at: #polis put: #(#feminine 'η' #s 'ης' #s 'η' #s 'η' #s 'εις' #l 'εων' #a 'εις' #l 'εις' #l);
			at: #o put: #(#neuter 'ο' #s 'ου' #l 'ο' #s 'ο' #s 'α' #s 'ων' #l 'α' #s 'α' #s);
			at: #iota put: #(#neuter 'ι' #s 'ιου' #u 'ι' #s 'ι' #s 'ια' #s 'ιων' #u 'ια' #s 'ια' #s);
			at: #ma put: #(#neuter 'α' #s 'ατος' #a 'α' #s 'α' #s 'ατα' #a 'ατων' #p 'ατα' #a 'ατα' #a);
			at: #neuterOs put: #(#neuter 'ος' #s 'ους' #l 'ος' #s 'ος' #s 'η' #l 'ων' #u 'η' #l 'η' #l);
			yourself]!
guessDeclensionOf: aWord
	"the class a noun most likely belongs to, from its ending"
	| w |
	w := GreekText strip: aWord.
	(w endsWith: 'μα') ifTrue: [^#ma].
	(w endsWith: 'ος') ifTrue: [^#os].
	(w endsWith: 'ας') ifTrue: [^#as].
	(w endsWith: 'ης') ifTrue: [^#is].
	(w endsWith: 'α') ifTrue: [^#a].
	((w endsWith: 'ση') or: [(w endsWith: 'ξη') or: [w endsWith: 'ψη']]) ifTrue: [^#polis].
	(w endsWith: 'η') ifTrue: [^#i].
	(w endsWith: 'ο') ifTrue: [^#o].
	(w endsWith: 'ι') ifTrue: [^#iota].
	^self error: 'cannot tell how ', aWord, ' declines'! !

!GreekNoun class methodsFor: 'instance creation'!
lemma: aString
	^self lemma: aString declension: (self guessDeclensionOf: aString)!
lemma: aString declension: aSymbol
	^self new setLemma: aString declension: aSymbol!
lemma: aString declension: aSymbol gloss: english
	^(self lemma: aString declension: aSymbol) gloss: english; yourself!
named: aString
	^GreekLexicon nounNamed: aString! !

!GreekNoun class methodsFor: 'quick answers'!
plural: aString
	"the nominative plural: GreekNoun plural: 'δρόμος'  -->  'δρόμοι'"
	^(self named: aString) plural!
genitive: aString
	^(self named: aString) genitive!
decline: aString
	^(self named: aString) declension! !

!GreekNoun class methodsFor: 'accent rules'!
inflect: aStem ending: anEnding rule: aRule lemmaAccent: p syllables: n
	"the form, given the stem as it is in the nominative singular (with its accent, unless the accent is
	on the ending) and the position of the accent there"
	| plain |
	plain := (GreekText strip: aStem) , anEnding.
	aRule = #u ifTrue: [^GreekText accentLast: plain].
	aRule = #p ifTrue: [^GreekText accentPenult: plain].
	aRule = #a ifTrue: [^GreekText accentAntepenult: plain].
	aRule = #g ifTrue: [
		n = 2 ifTrue: [^GreekText accentLast: plain].
		^self inflect: aStem ending: anEnding rule: #l lemmaAccent: p syllables: n].
	(aRule = #l and: [p = 3]) ifTrue: [^GreekText accentPenult: plain].
	"#s, and #l without a shift"
	p <= 1 ifTrue: [^GreekText accentLast: plain].
	^GreekText finalSigma: aStem , anEnding! !

!GreekNoun methodsFor: 'initializing'!
setLemma: aString declension: aSymbol
	| table ending |
	lemma := aString.
	declension := aSymbol.
	table := self class declensions at: aSymbol ifAbsent: [^self error: 'no declension called ', aSymbol printString].
	gender := table first.
	ending := table at: 2.
	((GreekText strip: aString) endsWith: ending) ifFalse: [^self error: aString, ' does not end in -', ending].
	stem := aString copyFrom: 1 to: aString size - ending size.
	accent := GreekText accentPosition: aString.
	gloss := ''.
	overrides := Dictionary new!
gloss: english
	gloss := english!
gender: aSymbol
	"for the nouns whose gender is not the usual one for their class (η οδός)"
	gender := aSymbol!
form: aString at: aCase number: aNumber
	"a form that does not follow the rules of the class: μητέρα has των μητέρων"
	overrides at: (self class slotFor: aCase number: aNumber) put: aString! !

!GreekNoun methodsFor: 'accessing'!
lemma
	^lemma!
gender
	^gender!
declensionClass
	^declension!
gloss
	^gloss!
article
	"the definite article of the nominative singular: ο, η or το"
	^GreekArticle definite: gender case: #nominative number: #singular!
printOn: aStream
	aStream nextPutAll: self article; space; nextPutAll: lemma; nextPutAll: ' (noun, '; nextPutAll: gender.
	gloss isEmpty ifFalse: [aStream nextPutAll: ': '; nextPutAll: gloss].
	aStream nextPut: $)! !

!GreekNoun methodsFor: 'inflecting'!
case: aCase number: aNumber
	"one form: noun case: #genitive number: #plural"
	| slot table |
	slot := self class slotFor: aCase number: aNumber.
	overrides at: slot ifPresent: [:f | ^f].
	table := self class declensions at: declension.
	^self class inflect: stem ending: (table at: slot * 2) rule: (table at: slot * 2 + 1)
		lemmaAccent: accent syllables: (GreekText syllableCount: lemma)!
forms
	"all eight: the four cases singular, then the four plural"
	^(self class numbers inject: OrderedCollection new into: [:all :num |
		self class cases do: [:c | all add: (self case: c number: num)]. all]) asArray!
singular
	^self class cases collect: [:c | self case: c number: #singular]!
plurals
	^self class cases collect: [:c | self case: c number: #plural]!
plural
	"the nominative plural"
	^self case: #nominative number: #plural!
genitive
	^self case: #genitive number: #singular!
accusative
	^self case: #accusative number: #singular!
vocative
	^self case: #vocative number: #singular!
withArticle: aCase number: aNumber
	"the form with its article: noun withArticle: #accusative number: #singular  -->  'τη χώρα'"
	| f a |
	f := self case: aCase number: aNumber.
	a := GreekArticle definite: gender case: aCase number: aNumber before: f.
	^a isNil ifTrue: [f] ifFalse: [a , ' ' , f]!
withArticle
	^self withArticle: #nominative number: #singular!
withIndefiniteArticle
	^(GreekArticle indefinite: gender case: #nominative) , ' ' , lemma!
declension
	"the whole paradigm with the articles, as a table"
	| t |
	t := GreekTable title: self printString.
	t header: #('' 'singular' 'plural').
	self class cases doWithIndex: [:c :i |
		t add: (Array with: (self class caseNames at: i)
			with: (self withArticle: c number: #singular)
			with: (self withArticle: c number: #plural))].
	^t! !

"---- articles ----"

!GreekArticle class methodsFor: 'forms'!
definiteTable
	"gender -> the eight forms, nil for the vocative, which has no article"
	^Dictionary new
		at: #masculine put: #('ο' 'του' 'τον' nil 'οι' 'των' 'τους' nil);
		at: #feminine put: #('η' 'της' 'την' nil 'οι' 'των' 'τις' nil);
		at: #neuter put: #('το' 'του' 'το' nil 'τα' 'των' 'τα' nil);
		yourself!
indefiniteTable
	^Dictionary new
		at: #masculine put: #('ένας' 'ενός' 'έναν');
		at: #feminine put: #('μια' 'μιας' 'μια');
		at: #neuter put: #('ένα' 'ενός' 'ένα');
		yourself!
definite: aGender case: aCase number: aNumber
	^(self definiteTable at: aGender) at: (GreekNoun slotFor: aCase number: aNumber)!
definite: aGender case: aCase number: aNumber before: aWord
	"την loses its ν before most consonants: την πόλη, τη χώρα. (τον keeps it, by the usual spelling rule.)"
	| a |
	a := self definite: aGender case: aCase number: aNumber.
	(a = 'την' and: [(GreekText keepsFinalN: aWord) not]) ifTrue: [^'τη'].
	^a!
indefinite: aGender case: aCase
	"the indefinite article, which has no plural and no vocative"
	| i |
	i := #(#nominative #genitive #accusative) indexOf: aCase.
	i = 0 ifTrue: [^nil].
	^(self indefiniteTable at: aGender) at: i!
indefinite: aGender case: aCase before: aWord
	| a |
	a := self indefinite: aGender case: aCase.
	(a = 'έναν' and: [(GreekText keepsFinalN: aWord) not]) ifTrue: [^'ένα'].
	^a!
table
	"both articles, as a table"
	| t |
	t := GreekTable title: 'The articles' header: #('' 'm. sg.' 'f. sg.' 'n. sg.' '' 'm. pl.' 'f. pl.' 'n. pl.').
	#(#nominative #genitive #accusative) doWithIndex: [:c :i |
		t add: (Array with: (GreekNoun caseNames at: i)) ,
			(GreekNoun genders collect: [:g | self definite: g case: c number: #singular]) , #('') ,
			(GreekNoun genders collect: [:g | self definite: g case: c number: #plural])].
	t add: #().
	t add: #('' 'indefinite').
	#(#nominative #genitive #accusative) doWithIndex: [:c :i |
		t add: (Array with: (GreekNoun caseNames at: i)) ,
			(GreekNoun genders collect: [:g | self indefinite: g case: c])].
	t note: 'την becomes τη, and έναν ένα, before a consonant other than κ π τ ξ ψ (or μπ ντ γκ τσ τζ).'.
	^t! !

"---- adjectives ----"

!GreekAdjective class methodsFor: 'patterns'!
patterns
	"the masculine, feminine and neuter endings of each pattern, eight each; all keep the accent of the
	masculine where it is, unlike the nouns"
	^Dictionary new
		at: #osIO put: #(#('ος' 'ου' 'ο' 'ε' 'οι' 'ων' 'ους' 'οι') #('η' 'ης' 'η' 'η' 'ες' 'ων' 'ες' 'ες') #('ο' 'ου' 'ο' 'ο' 'α' 'ων' 'α' 'α'));
		at: #osAO put: #(#('ος' 'ου' 'ο' 'ε' 'οι' 'ων' 'ους' 'οι') #('α' 'ας' 'α' 'α' 'ες' 'ων' 'ες' 'ες') #('ο' 'ου' 'ο' 'ο' 'α' 'ων' 'α' 'α'));
		at: #osIA put: #(#('ος' 'ου' 'ο' 'ε' 'οι' 'ων' 'ους' 'οι') #('ια' 'ιας' 'ια' 'ια' 'ιες' 'ιων' 'ιες' 'ιες') #('ο' 'ου' 'ο' 'ο' 'α' 'ων' 'α' 'α'));
		at: #ys put: #(#('υς' 'ιου' 'υ' 'υ' 'ιοι' 'ιων' 'ιους' 'ιοι') #('ια' 'ιας' 'ια' 'ια' 'ιες' 'ιων' 'ιες' 'ιες') #('υ' 'ιου' 'υ' 'υ' 'ια' 'ιων' 'ια' 'ια'));
		yourself!
guessPatternOf: aWord
	| w |
	w := GreekText strip: aWord.
	(w endsWith: 'υς') ifTrue: [^#ys].
	(w endsWith: 'ος') ifFalse: [^self error: 'an adjective here ends in -ος or -ύς'].
	"after a vowel the feminine is in -α: ωραίος ωραία, νέος νέα"
	^(GreekText isVowel: (w asWideString at: w asWideString size - 2)) ifTrue: [#osAO] ifFalse: [#osIO]! !

!GreekAdjective class methodsFor: 'instance creation'!
lemma: aString
	^self lemma: aString pattern: (self guessPatternOf: aString)!
lemma: aString pattern: aSymbol
	^self new setLemma: aString pattern: aSymbol!
named: aString
	^GreekLexicon adjectiveNamed: aString! !

!GreekAdjective methodsFor: 'initializing'!
setLemma: aString pattern: aSymbol
	lemma := aString.
	pattern := aSymbol.
	stem := aString copyFrom: 1 to: aString size - 4.
	accent := GreekText accentPosition: aString.
	gloss := ''!
gloss: english
	gloss := english! !

!GreekAdjective methodsFor: 'accessing'!
lemma
	^lemma!
gloss
	^gloss!
pattern
	^pattern!
printOn: aStream
	aStream nextPutAll: lemma; nextPutAll: ', '; nextPutAll: (self gender: #feminine case: #nominative number: #singular);
		nextPutAll: ', '; nextPutAll: (self gender: #neuter case: #nominative number: #singular);
		nextPutAll: ' (adjective'.
	gloss isEmpty ifFalse: [aStream nextPutAll: ': '; nextPutAll: gloss].
	aStream nextPut: $)! !

!GreekAdjective methodsFor: 'inflecting'!
gender: aGender case: aCase number: aNumber
	| endings e |
	endings := (self class patterns at: pattern) at: (GreekNoun genders indexOf: aGender).
	e := endings at: (GreekNoun slotFor: aCase number: aNumber).
	accent <= 1 ifTrue: [^GreekText accentLast: (GreekText strip: stem) , e].
	^GreekText finalSigma: stem , e!
agreeWith: aNoun case: aCase number: aNumber
	"the form that goes with the noun: same gender, case and number"
	^self gender: aNoun gender case: aCase number: aNumber!
with: aNoun
	"the adjective and a noun together: ('καλός' asGreekAdjective with: 'δρόμος' asGreekNoun) declension"
	^GreekNounPhrase adjective: self noun: aNoun!
masculine
	^self forms: #masculine!
feminine
	^self forms: #feminine!
neuter
	^self forms: #neuter!
forms: aGender
	^(GreekNoun numbers inject: OrderedCollection new into: [:all :num |
		GreekNoun cases do: [:c | all add: (self gender: aGender case: c number: num)]. all]) asArray!
declension
	| t |
	t := GreekTable title: self printString.
	t header: #('' 'masc.' 'fem.' 'neut.').
	GreekNoun numbers do: [:num |
		t add: (Array with: num asString).
		GreekNoun cases doWithIndex: [:c :i |
			t add: (Array with: (GreekNoun caseNames at: i)) ,
				(GreekNoun genders collect: [:g | self gender: g case: c number: num])]].
	^t! !

"---- an adjective with its noun ----"

!GreekNounPhrase class methodsFor: 'instance creation'!
adjective: anAdjective noun: aNoun
	^self new setAdjective: anAdjective noun: aNoun! !

!GreekNounPhrase methodsFor: 'accessing'!
setAdjective: anAdjective noun: aNoun
	adjective := anAdjective isString ifTrue: [GreekAdjective named: anAdjective] ifFalse: [anAdjective].
	noun := aNoun isString ifTrue: [GreekNoun named: aNoun] ifFalse: [aNoun]!
case: aCase number: aNumber
	"the article, the adjective and the noun: 'της μεγάλης θάλασσας'"
	| a adj |
	adj := adjective agreeWith: noun case: aCase number: aNumber.
	a := GreekArticle definite: noun gender case: aCase number: aNumber before: adj.
	^(a isNil ifTrue: [''] ifFalse: [a , ' ']) , adj , ' ' , (noun case: aCase number: aNumber)!
indefinite
	"ένας καλός δρόμος"
	| adj |
	adj := adjective agreeWith: noun case: #nominative number: #singular.
	^(GreekArticle indefinite: noun gender case: #nominative) , ' ' , adj , ' ' , noun lemma!
printOn: aStream
	aStream nextPutAll: (self case: #nominative number: #singular)!
declension
	| t |
	t := GreekTable title: self printString header: #('' 'singular' 'plural').
	GreekNoun cases doWithIndex: [:c :i |
		t add: (Array with: (GreekNoun caseNames at: i)
			with: (self case: c number: #singular) with: (self case: c number: #plural))].
	^t! !

"---- personal pronouns ----"

!GreekPronoun class methodsFor: 'forms'!
strong
	"person -> nominative, genitive, accusative; persons 1 2 3 singular then plural, the third by gender"
	^#(	#('εγώ' 'εμένα' 'εμένα') #('εσύ' 'εσένα' 'εσένα')
		#('αυτός' 'αυτού' 'αυτόν') #('αυτή' 'αυτής' 'αυτήν') #('αυτό' 'αυτού' 'αυτό')
		#('εμείς' 'εμάς' 'εμάς') #('εσείς' 'εσάς' 'εσάς')
		#('αυτοί' 'αυτών' 'αυτούς') #('αυτές' 'αυτών' 'αυτές') #('αυτά' 'αυτών' 'αυτά'))!
weak
	"the clitics, which have only a genitive and an accusative"
	^#(	#('μου' 'με') #('σου' 'σε')
		#('του' 'τον') #('της' 'την') #('του' 'το')
		#('μας' 'μας') #('σας' 'σας')
		#('τους' 'τους') #('τους' 'τις') #('τους' 'τα'))!
labels
	^#('1 sg' '2 sg' '3 sg m' '3 sg f' '3 sg n' '1 pl' '2 pl' '3 pl m' '3 pl f' '3 pl n')!
rowFor: person number: aNumber gender: aGender
	| base |
	person < 3 ifTrue: [^person + (aNumber = #plural ifTrue: [5] ifFalse: [0])].
	base := aNumber = #plural ifTrue: [8] ifFalse: [3].
	^base + (GreekNoun genders indexOf: aGender) - 1!
strong: person number: aNumber case: aCase
	^self strong: person number: aNumber gender: #masculine case: aCase!
strong: person number: aNumber gender: aGender case: aCase
	"GreekPronoun strong: 1 number: #singular gender: #masculine case: #accusative  -->  'εμένα'"
	^(self strong at: (self rowFor: person number: aNumber gender: aGender))
		at: (#(#nominative #genitive #accusative) indexOf: aCase)!
weak: person number: aNumber case: aCase
	^self weak: person number: aNumber gender: #masculine case: aCase!
weak: person number: aNumber gender: aGender case: aCase
	"the clitic: GreekPronoun weak: 3 number: #singular gender: #feminine case: #accusative  -->  'την'"
	| i |
	i := #(#genitive #accusative) indexOf: aCase.
	i = 0 ifTrue: [^nil].
	^(self weak at: (self rowFor: person number: aNumber gender: aGender)) at: i!
table
	| t |
	t := GreekTable title: 'Personal pronouns' header: #('' 'nominative' 'genitive' 'accusative' '' 'weak gen.' 'weak acc.').
	self labels doWithIndex: [:l :i |
		t add: (Array with: l) , (self strong at: i) , #('') , (self weak at: i)].
	t note: 'The weak forms go before the verb (μου το έδωσε, θα σε δω) and after an imperative (δώσ'' μου το).'.
	^t! !
