"Greek: the lexicon.  The common words, with what English calls them and, for the verbs, the stems the
rules cannot guess: the irregular aorists (είδα, είπα, πήγα, ήρθα), the perfective stems with no vowel
(θα δω, θα πω, θα βρω), and the whole tenses of είμαι, λέω, πάω, τρώω and the rest.

	GreekLexicon verbNamed: 'βλέπω'
	GreekLexicon lookup: 'θάλασσα'
	GreekLexicon english: 'see'
	GreekLexicon verbs
	GreekLexicon glossary

A word that is not here is still understood: 'τρέχω' asGreekVerb guesses its stems from its ending.
Add a word of your own with GreekLexicon addVerb:, addNoun: or addAdjective:."

Object subclass: #GreekLexicon instanceVariableNames: '' classVariableNames: 'Verbs Nouns Adjectives' category: 'Greek-Grammar'!

!GreekLexicon class methodsFor: 'looking up'!
verbNamed: aString
	"the verb from the lexicon, or one guessed from its ending"
	^self verbTable at: (self normalize: aString) ifAbsent: [GreekVerb lemma: aString]!
nounNamed: aString
	^self nounTable at: aString ifAbsent: [GreekNoun lemma: aString]!
adjectiveNamed: aString
	^self adjectiveTable at: aString ifAbsent: [GreekAdjective lemma: aString]!
includes: aString
	^(self verbTable includesKey: (self normalize: aString)) or: [
		(self nounTable includesKey: aString) or: [self adjectiveTable includesKey: aString]]!
lookup: aString
	"whatever the word is: a verb, a noun or an adjective, or nil"
	^self verbTable at: (self normalize: aString) ifAbsent: [
		self nounTable at: aString ifAbsent: [
			self adjectiveTable at: aString ifAbsent: [nil]]]!
english: aString
	"every word whose gloss mentions aString"
	| out |
	out := OrderedCollection new.
	(self verbTable values asSet asArray , self nounTable values asArray , self adjectiveTable values asArray) do: [:w |
		(w gloss includesSubstring: aString) ifTrue: [out add: w]].
	^(out asSortedCollection: [:a :b | (GreekText strip: a lemma) <= (GreekText strip: b lemma)]) asArray!
normalize: aString
	"αγαπώ is another way of writing αγαπάω"
	^self aliases at: aString ifAbsent: [aString]!
aliases
	^Dictionary new
		at: 'αγαπώ' put: 'αγαπάω'; at: 'μιλώ' put: 'μιλάω'; at: 'ρωτώ' put: 'ρωτάω';
		at: 'ξεχνώ' put: 'ξεχνάω'; at: 'γελώ' put: 'γελάω'; at: 'ζητώ' put: 'ζητάω';
		at: 'απαντώ' put: 'απαντάω'; at: 'περνώ' put: 'περνάω'; at: 'ξυπνώ' put: 'ξυπνάω';
		at: 'κοιτώ' put: 'κοιτάω'; at: 'πεινώ' put: 'πεινάω'; at: 'τρώγω' put: 'τρώω';
		at: 'πηγαίνω' put: 'πάω';
		yourself! !

!GreekLexicon class methodsFor: 'listing'!
verbs
	^self sorted: self verbTable keys!
nouns
	^self sorted: self nounTable keys!
adjectives
	^self sorted: self adjectiveTable keys!
sorted: words
	"in alphabetical order, which for Greek means ignoring the accents"
	^(words asSortedCollection: [:a :b | (GreekText strip: a) <= (GreekText strip: b)]) asArray!
glossary
	"every word in the lexicon, with its English"
	| t |
	t := GreekTable title: 'The lexicon' header: #('Greek' 'English' 'kind').
	self verbs do: [:k | | v | v := self verbTable at: k. t add: (Array with: k with: v gloss with: 'verb ' , v conjugationName)].
	self nouns do: [:k | | n | n := self nounTable at: k. t add: (Array with: n article , ' ' , k with: n gloss with: 'noun ' , n gender)].
	self adjectives do: [:k | t add: (Array with: k with: (self adjectiveTable at: k) gloss with: 'adjective')].
	^t! !

!GreekLexicon class methodsFor: 'adding'!
addVerb: aVerb
	self verbTable at: aVerb lemma put: aVerb.
	^aVerb!
addNoun: aNoun
	self nounTable at: aNoun lemma put: aNoun.
	^aNoun!
addAdjective: anAdjective
	self adjectiveTable at: anAdjective lemma put: anAdjective.
	^anAdjective!
reset
	"build the tables again from the methods below"
	Verbs := nil. Nouns := nil. Adjectives := nil! !

!GreekLexicon class methodsFor: 'private-building'!
v: lemma gloss: english
	^self addVerb: (GreekVerb lemma: lemma gloss: english)!
n: lemma as: aDeclension gloss: english
	^self addNoun: (GreekNoun lemma: lemma declension: aDeclension gloss: english)!
a: lemma gloss: english
	^self addAdjective: ((GreekAdjective lemma: lemma) gloss: english; yourself)!
a: lemma pattern: aPattern gloss: english
	^self addAdjective: ((GreekAdjective lemma: lemma pattern: aPattern) gloss: english; yourself)! !

!GreekLexicon class methodsFor: 'the words'!
verbTable
	^Verbs ifNil: [Verbs := Dictionary new. self buildVerbs. Verbs]!
nounTable
	^Nouns ifNil: [Nouns := Dictionary new. self buildNouns. Nouns]!
adjectiveTable
	^Adjectives ifNil: [Adjectives := Dictionary new. self buildAdjectives. Adjectives]!
buildVerbs
	"conjugation A: the stem ends in a consonant and the endings are unstressed"
	(self v: 'γράφω' gloss: 'write') aorist: 'γραψ'.
	(self v: 'διαβάζω' gloss: 'read') aorist: 'διαβασ'.
	(self v: 'ανοίγω' gloss: 'open') aorist: 'ανοιξ'.
	(self v: 'κλείνω' gloss: 'close') aorist: 'κλεισ'.
	(self v: 'δουλεύω' gloss: 'work') aorist: 'δουλεψ'; noPassive.
	(self v: 'τρέχω' gloss: 'run') aorist: 'τρεξ'; noPassive.
	(self v: 'ψάχνω' gloss: 'look for') aorist: 'ψαξ'.
	(self v: 'κάνω' gloss: 'do, make') aorist: 'καν'; noPassive.
	(self v: 'μένω' gloss: 'stay, live') aorist: 'μειν'; noPassive.
	(self v: 'φεύγω' gloss: 'leave') aorist: 'φυγ'; noPassive.
	(self v: 'μαθαίνω' gloss: 'learn') aorist: 'μαθ'; passiveAorist: 'μαθευτ'; participle: 'μαθημένος'.
	(self v: 'δίνω' gloss: 'give') aorist: 'δωσ'; passiveAorist: 'δοθ'; participle: 'δοσμένος'.
	(self v: 'παίρνω' gloss: 'take') aorist: 'πήρ'; perfective: 'παρ'; passiveAorist: 'παρθ';
		participle: 'παρμένος'; imperative: #('πάρε' 'πάρτε').
	(self v: 'θέλω' gloss: 'want') augment: 'η'; aorist: 'θελησ'; noPassive.
	(self v: 'ξέρω' gloss: 'know') augment: 'η'; aorist: nil; noPassive.
	(self v: 'έχω' gloss: 'have') aorist: nil; noPassive;
		tense: #imperfect forms: #('είχα' 'είχες' 'είχε' 'είχαμε' 'είχατε' 'είχαν').
	(self v: 'βλέπω' gloss: 'see') aorist: 'είδ'; perfective: 'δ'; passiveAorist: 'ειδωθ';
		participle: 'ιδωμένος'; imperative: #('δες' 'δείτε').
	(self v: 'βρίσκω' gloss: 'find') aorist: 'βρήκ'; perfective: 'βρ'; passiveAorist: 'βρεθ';
		participle: nil; imperative: #('βρες' 'βρείτε').
	(self v: 'μπαίνω' gloss: 'go in') aorist: 'μπήκ'; perfective: 'μπ'; noPassive;
		imperative: #('μπες' 'μπείτε').
	(self v: 'βγαίνω' gloss: 'go out') aorist: 'βγήκ'; perfective: 'βγ'; noPassive;
		imperative: #('βγες' 'βγείτε').
	(self v: 'λέω' gloss: 'say') imperfectStem: 'λεγ'; aorist: 'είπ'; perfective: 'π';
		passiveStem: 'λεγ'; passiveAorist: 'ειπωθ'; participle: 'ειπωμένος';
		tense: #present forms: #('λέω' 'λες' 'λέει' 'λέμε' 'λέτε' 'λένε');
		imperative: #('πες' 'πείτε').
	(self v: 'τρώω' gloss: 'eat') imperfectStem: 'τρωγ'; aorist: 'φαγ';
		passiveStem: 'τρωγ'; passiveAorist: 'φαγωθ'; participle: 'φαγωμένος';
		tense: #present forms: #('τρώω' 'τρως' 'τρώει' 'τρώμε' 'τρώτε' 'τρώνε');
		tense: #subjunctive forms: #('φάω' 'φας' 'φάει' 'φάμε' 'φάτε' 'φάνε');
		imperative: #('φάε' 'φάτε').
	(self v: 'πάω' gloss: 'go') kind: #A; imperfectStem: 'πηγαιν'; aorist: 'πήγ'; noPassive;
		tense: #present forms: #('πάω' 'πας' 'πάει' 'πάμε' 'πάτε' 'πάνε');
		tense: #subjunctive forms: #('πάω' 'πας' 'πάει' 'πάμε' 'πάτε' 'πάνε');
		imperative: #('πήγαινε' 'πηγαίνετε').
	(self v: 'ακούω' gloss: 'hear') imperfectStem: 'ακουγ'; aorist: 'ακουσ';
		passiveStem: 'ακουγ'; passiveAorist: 'ακουστ'; participle: 'ακουσμένος';
		tense: #present forms: #('ακούω' 'ακούς' 'ακούει' 'ακούμε' 'ακούτε' 'ακούνε').
	(self v: 'πίνω' gloss: 'drink') aorist: 'ήπι'; perfective: 'πι'; passiveAorist: 'πιωθ';
		participle: 'πιωμένος';
		tense: #subjunctive forms: #('πιω' 'πιεις' 'πιει' 'πιούμε' 'πιείτε' 'πιουν');
		imperative: #('πιες' 'πιείτε').
	"deponents: passive endings, no active"
	(self v: 'σκέφτομαι' gloss: 'think') imperative: #('σκέψου' 'σκεφτείτε').
	(self v: 'έρχομαι' gloss: 'come') aorist: 'ήρθ'; perfective: 'ερθ'; imperative: #('έλα' 'ελάτε').
	(self v: 'είμαι' gloss: 'be') beDeponent;
		passive: #present forms: #('είμαι' 'είσαι' 'είναι' 'είμαστε' 'είστε' 'είναι');
		passive: #imperfect forms: #('ήμουν' 'ήσουν' 'ήταν' 'ήμασταν' 'ήσασταν' 'ήταν');
		passive: #futureSimple forms: #('θα είμαι' 'θα είσαι' 'θα είναι' 'θα είμαστε' 'θα είστε' 'θα είναι');
		passive: #aorist forms: nil; passive: #subjunctive forms: nil.
	"conjugation B1: stressed endings in -άω, -άς; aorist in -ησα or -ασα"
	(self v: 'αγαπάω' gloss: 'love') aorist: 'αγαπησ'.
	(self v: 'μιλάω' gloss: 'speak') aorist: 'μιλησ'.
	(self v: 'ρωτάω' gloss: 'ask') aorist: 'ρωτησ'.
	(self v: 'ζητάω' gloss: 'ask for') aorist: 'ζητησ'.
	(self v: 'απαντάω' gloss: 'answer') aorist: 'απαντησ'.
	(self v: 'ξυπνάω' gloss: 'wake up') aorist: 'ξυπνησ'; noPassive.
	(self v: 'περνάω' gloss: 'pass') aorist: 'περασ'; noPassive.
	(self v: 'ξεχνάω' gloss: 'forget') aorist: 'ξεχασ'.
	(self v: 'γελάω' gloss: 'laugh') aorist: 'γελασ'.
	(self v: 'πεινάω' gloss: 'be hungry') aorist: 'πεινασ'; noPassive.
	(self v: 'κοιτάω' gloss: 'look at') aorist: 'κοιταξ'; noPassive.
	"conjugation B2: stressed endings in -ώ, -είς"
	(self v: 'μπορώ' gloss: 'can, be able') aorist: 'μπορεσ'; noPassive.
	(self v: 'ζω' gloss: 'live') kind: #B2; aorist: 'ζησ'; noPassive.
	(self v: 'θεωρώ' gloss: 'consider') aorist: 'θεωρησ'.
	(self v: 'οδηγώ' gloss: 'drive, lead') aorist: 'οδηγησ'.
	(self v: 'τηλεφωνώ' gloss: 'telephone') aorist: 'τηλεφωνησ'; noPassive.
	(self v: 'προσπαθώ' gloss: 'try') aorist: 'προσπαθησ'; noPassive.
	(self v: 'χρησιμοποιώ' gloss: 'use') aorist: 'χρησιμοποιησ'!
buildNouns
	self n: 'δρόμος' as: #os gloss: 'road, street'.
	self n: 'άνθρωπος' as: #os gloss: 'person, human being'.
	self n: 'φίλος' as: #os gloss: 'friend'.
	self n: 'δάσκαλος' as: #os gloss: 'teacher'.
	self n: 'ουρανός' as: #os gloss: 'sky'.
	self n: 'άντρας' as: #as gloss: 'man, husband'.
	self n: 'πατέρας' as: #as gloss: 'father'.
	self n: 'μήνας' as: #as gloss: 'month'.
	self n: 'χειμώνας' as: #as gloss: 'winter'.
	self n: 'μαθητής' as: #is gloss: 'pupil'.
	self n: 'κλέφτης' as: #is gloss: 'thief'.
	self n: 'χώρα' as: #a gloss: 'country'.
	self n: 'θάλασσα' as: #a gloss: 'sea'.
	self n: 'ώρα' as: #a gloss: 'hour, time'.
	self n: 'γλώσσα' as: #a gloss: 'language, tongue'.
	(self n: 'μητέρα' as: #a gloss: 'mother') form: 'μητέρων' at: #genitive number: #plural.
	self n: 'τέχνη' as: #i gloss: 'art'.
	self n: 'αδελφή' as: #i gloss: 'sister'.
	self n: 'φωνή' as: #i gloss: 'voice'.
	self n: 'πόλη' as: #polis gloss: 'city'.
	self n: 'λέξη' as: #polis gloss: 'word'.
	self n: 'απόφαση' as: #polis gloss: 'decision'.
	self n: 'παιδί' as: #iota gloss: 'child'.
	self n: 'σπίτι' as: #iota gloss: 'house, home'.
	self n: 'τραγούδι' as: #iota gloss: 'song'.
	self n: 'βιβλίο' as: #o gloss: 'book'.
	self n: 'πρόσωπο' as: #o gloss: 'face, person'.
	self n: 'νερό' as: #o gloss: 'water'.
	self n: 'αυτοκίνητο' as: #o gloss: 'car'.
	self n: 'όνομα' as: #ma gloss: 'name'.
	self n: 'γράμμα' as: #ma gloss: 'letter'.
	self n: 'πρόβλημα' as: #ma gloss: 'problem'.
	self n: 'δάσος' as: #neuterOs gloss: 'forest'.
	self n: 'λάθος' as: #neuterOs gloss: 'mistake'!
buildAdjectives
	self a: 'καλός' gloss: 'good'.
	self a: 'μεγάλος' gloss: 'big'.
	self a: 'μικρός' gloss: 'small'.
	self a: 'όμορφος' gloss: 'beautiful'.
	self a: 'κόκκινος' gloss: 'red'.
	self a: 'άσπρος' gloss: 'white'.
	self a: 'γρήγορος' gloss: 'fast'.
	self a: 'ελληνικός' gloss: 'Greek'.
	self a: 'ωραίος' gloss: 'beautiful, nice'.
	self a: 'νέος' gloss: 'new, young'.
	self a: 'παλιός' gloss: 'old'.
	self a: 'κρύος' gloss: 'cold'.
	self a: 'γλυκός' pattern: #osIA gloss: 'sweet'.
	self a: 'βαθύς' gloss: 'deep'.
	self a: 'μακρύς' gloss: 'long'.
	self a: 'φαρδύς' gloss: 'wide'! !

"---- the way in from a String ----"

!String methodsFor: 'greek'!
asGreekVerb
	"'γράφω' asGreekVerb conjugate: #present"
	^GreekLexicon verbNamed: self!
asGreekNoun
	^GreekLexicon nounNamed: self!
asGreekAdjective
	^GreekLexicon adjectiveNamed: self!
greekParadigm
	"the table for whatever the word is"
	| w |
	w := GreekLexicon lookup: self.
	w isNil ifTrue: [
		w := [GreekVerb lemma: self] on: Error do: [:e | nil].
		((self endsWith: 'ω') or: [(self endsWith: 'ώ') or: [self endsWith: 'μαι']]) ifFalse: [
			w := [GreekNoun lemma: self] on: Error do: [:e | nil]]].
	w isNil ifTrue: [^self error: 'not a word I can inflect: ', self].
	^(w isKindOf: GreekVerb) ifTrue: [w paradigm] ifFalse: [w declension]! !
