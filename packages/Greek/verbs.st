"Greek: verbs.  A GreekVerb is one verb, known by its first person singular (γράφω, αγαπάω, μπορώ, έρχομαι),
and conjugates itself in both voices.

Modern Greek builds almost every tense from two stems: the imperfective stem of the present (γράφ-) and
the perfective stem of the aorist (γράψ-).  The present stem gives the present, the imperfect and the
continuous future; the aorist stem gives the aorist, the simple future (θα γράψω, which is the perfective
subjunctive after θα), and with έχω the perfect tenses (έχω γράψει).  The passive has its own aorist stem
(γράφτ-: γράφτηκα, θα γραφτώ, έχω γραφτεί).  So a verb needs only its stems; the endings and the rules
for the accent do the rest:

	the present keeps the accent of the dictionary form: γράφω, γράφουμε;
	the past tenses put it on the third syllable from the end, adding the augment έ- when the word would
	otherwise be too short to have one: έγραψα, έγραψες, έγραψε, but γράψαμε;
	the perfective subjunctive puts it on the last syllable of the stem: γράψω, αγαπήσω;
	a verb whose perfective stem has no vowel takes stressed endings: δω, δεις, δούμε.

Verbs that will not fit (είμαι, λέω, πάω, τρώω ...) keep whole tenses of their own in forms, and a
stem written WITH an accent (είδ-, πήγ-) is used just as it is, which is how εἶδα and πήγα keep their
accent and their augment in every person.

The lexicon (GreekLexicon) knows the stems of the common verbs; for any other verb they are guessed from
the ending, which is right for most regular verbs."

Object subclass: #GreekVerb instanceVariableNames: 'lemma gloss kind deponent stem imperfectStem augment aoristStem perfectiveStem passiveStem passiveAoristStem participle forms imperative hasPassive' classVariableNames: '' category: 'Greek-Grammar'!

!GreekVerb class methodsFor: 'instance creation'!
lemma: aString
	"a verb from its first person singular, with its stems guessed from the ending"
	^self new setLemma: aString!
lemma: aString gloss: english
	^(self lemma: aString) gloss: english; yourself!
named: aString
	"the verb from the lexicon, or guessed when the lexicon does not have it"
	^GreekLexicon verbNamed: aString! !

!GreekVerb class methodsFor: 'grammar'!
tenses
	"the tenses a verb answers to conjugate:, in the usual order"
	^#(#present #imperfect #aorist #futureContinuous #futureSimple #perfect #pluperfect #futurePerfect #subjunctive)!
voices
	^#(#active #passive)!
tenseNames
	"what Greek grammars call each tense"
	^GreekTable new setTitle: 'The tenses' ; header: #('tense' 'Greek name' 'example');
		add: #('present' 'ενεστώτας' 'γράφω');
		add: #('imperfect' 'παρατατικός' 'έγραφα');
		add: #('aorist (simple past)' 'αόριστος' 'έγραψα');
		add: #('future continuous' 'εξακολουθητικός μέλλοντας' 'θα γράφω');
		add: #('future simple' 'στιγμιαίος μέλλοντας' 'θα γράψω');
		add: #('perfect' 'παρακείμενος' 'έχω γράψει');
		add: #('pluperfect' 'υπερσυντέλικος' 'είχα γράψει');
		add: #('future perfect' 'συντελεσμένος μέλλοντας' 'θα έχω γράψει');
		add: #('subjunctive (perfective)' 'υποτακτική αορίστου' 'να γράψω');
		yourself!
persons
	^#('εγώ' 'εσύ' 'αυτός' 'εμείς' 'εσείς' 'αυτοί')!
labelFor: aTense
	^#('present' 'imperfect' 'aorist' 'future (cont.)' 'future (simple)' 'perfect' 'pluperfect' 'future perfect' 'subjunctive')
		at: (self tenses indexOf: aTense) ifAbsent: [aTense asString]!
indexFor: person number: aNumber
	"1, 2 or 3 and #singular or #plural, to an index in a conjugation"
	^person + (aNumber = #plural ifTrue: [3] ifFalse: [0])! !

!GreekVerb class methodsFor: 'endings'!
presentA
	^#('ω' 'εις' 'ει' 'ουμε' 'ετε' 'ουν')!
presentB1
	^#('άω' 'άς' 'άει' 'άμε' 'άτε' 'άνε')!
presentB2
	^#('ώ' 'είς' 'εί' 'ούμε' 'είτε' 'ούν')!
pastEndings
	^#('α' 'ες' 'ε' 'αμε' 'ατε' 'αν')!
imperfectB
	^#('ούσα' 'ούσες' 'ούσε' 'ούσαμε' 'ούσατε' 'ούσαν')!
subjunctiveEndings
	^#('ω' 'εις' 'ει' 'ουμε' 'ετε' 'ουν')!
stressedEndings
	^#('ώ' 'είς' 'εί' 'ούμε' 'είτε' 'ούν')!
passivePresentA
	^#('ομαι' 'εσαι' 'εται' 'ομαστε' 'εστε' 'ονται')!
passiveImperfectA
	"the accent is on the -ό- of the ending, except in the third person plural: γραφόμουν, γράφονταν"
	^#('όμουν' 'όσουν' 'όταν' 'όμασταν' 'όσασταν' 'ονταν')!
passivePresentB1
	^#('ιέμαι' 'ιέσαι' 'ιέται' 'ιόμαστε' 'ιέστε' 'ιούνται')!
passiveImperfectB1
	^#('ιόμουν' 'ιόσουν' 'ιόταν' 'ιόμασταν' 'ιόσασταν' 'ιούνταν')!
passivePresentB2
	^#('ούμαι' 'είσαι' 'είται' 'ούμαστε' 'είστε' 'ούνται')!
passiveImperfectB2
	^#('ούμουν' 'ούσουν' 'ούνταν' 'ούμασταν' 'ούσασταν' 'ούνταν')!
passiveAoristEndings
	^#('ηκα' 'ηκες' 'ηκε' 'ηκαμε' 'ηκατε' 'ηκαν')!
havepresent
	"έχω, the auxiliary of the perfect"
	^#('έχω' 'έχεις' 'έχει' 'έχουμε' 'έχετε' 'έχουν')!
havePast
	^#('είχα' 'είχες' 'είχε' 'είχαμε' 'είχατε' 'είχαν')! !

!GreekVerb methodsFor: 'initializing'!
setLemma: aString
	lemma := aString.
	gloss := ''.
	deponent := false.
	hasPassive := true.
	augment := 'ε'.
	forms := Dictionary new.
	(aString endsWith: 'ομαι')
		ifTrue: [kind := #A. deponent := true. stem := self lemmaWithout: 'ομαι'. passiveStem := stem]
		ifFalse: [
			(aString endsWith: 'άω')
				ifTrue: [kind := #B1. stem := GreekText strip: (self lemmaWithout: 'άω')]
				ifFalse: [
					(aString endsWith: 'ώ')
						ifTrue: [kind := #B2. stem := GreekText strip: (self lemmaWithout: 'ώ')]
						ifFalse: [kind := #A. stem := self lemmaWithout: 'ω']]].
	deponent ifFalse: [
		aoristStem := self guessAoristStem.
		passiveAoristStem := self guessPassiveAoristStem]
	ifTrue: [passiveAoristStem := GreekText strip: stem].
	participle := self guessParticiple!
lemmaWithout: anEnding
	^lemma copyFrom: 1 to: lemma size - anEnding size!
guessAoristStem
	"the perfective stem a regular verb would have: γράφω γράψ-, ανοίγω ανοίξ-, διαβάζω διαβάσ-,
	κλείνω κλείσ-, δουλεύω δουλέψ-, and -ησ- for the second conjugation"
	| s w last two |
	s := GreekText strip: stem.
	kind = #A ifFalse: [^s , 'ησ'].
	w := s asWideString.
	w isEmpty ifTrue: [^s , 'σ'].
	last := w last utf8Encoded.
	two := w size >= 2 ifTrue: [(w copyFrom: w size - 1 to: w size) utf8Encoded] ifFalse: [''].
	(#('ευ' 'αυ') includes: two) ifTrue: [^(w copyFrom: 1 to: w size - 1) utf8Encoded , 'ψ'].
	(#('πτ' 'φτ') includes: two) ifTrue: [^(w copyFrom: 1 to: w size - 2) utf8Encoded , 'ψ'].
	(#('σκ' 'χν') includes: two) ifTrue: [^(w copyFrom: 1 to: w size - 2) utf8Encoded , 'ξ'].
	(#('π' 'β' 'φ') includes: last) ifTrue: [^(w copyFrom: 1 to: w size - 1) utf8Encoded , 'ψ'].
	(#('κ' 'γ' 'χ') includes: last) ifTrue: [^(w copyFrom: 1 to: w size - 1) utf8Encoded , 'ξ'].
	(#('ζ' 'θ' 'ν') includes: last) ifTrue: [^(w copyFrom: 1 to: w size - 1) utf8Encoded , 'σ'].
	^s , 'σ'!
guessPassiveAoristStem
	"γράψ- γράφτ-, ανοίξ- ανοίχτ-, αγαπήσ- αγαπήθ-, διαβάσ- διαβάστ-"
	| s |
	aoristStem isNil ifTrue: [^nil].
	s := GreekText strip: aoristStem.
	(s endsWith: 'ψ') ifTrue: [^(s copyFrom: 1 to: s size - 2) , 'φτ'].
	(s endsWith: 'ξ') ifTrue: [^(s copyFrom: 1 to: s size - 2) , 'χτ'].
	(s endsWith: 'ησ') ifTrue: [^(s copyFrom: 1 to: s size - 2) , 'θ'].
	(s endsWith: 'σ') ifTrue: [^s , 'τ'].
	^s , 'θ'!
guessParticiple
	"the passive perfect participle, from the passive aorist stem: γραφτ- γραμμένος, ανοιχτ- ανοιγμένος,
	διαβαστ- διαβασμένος, αγαπηθ- αγαπημένος"
	| s base |
	passiveAoristStem isNil ifTrue: [^nil].
	deponent ifTrue: [^nil].
	s := GreekText strip: passiveAoristStem.
	(s endsWith: 'φτ') ifTrue: [base := (s copyFrom: 1 to: s size - 4) , 'μμ'].
	(base isNil and: [s endsWith: 'χτ']) ifTrue: [base := (s copyFrom: 1 to: s size - 4) , 'γμ'].
	(base isNil and: [s endsWith: 'στ']) ifTrue: [base := (s copyFrom: 1 to: s size - 2) , 'μ'].
	(base isNil and: [s endsWith: 'ηθ']) ifTrue: [base := (s copyFrom: 1 to: s size - 2) , 'μ'].
	base isNil ifTrue: [^nil].
	^base , 'ένος'! !

!GreekVerb methodsFor: 'describing'!
gloss: english
	gloss := english!
kind: aSymbol
	"#A, #B1 or #B2; changing it recomputes the stem and the guesses that depend on it"
	kind := aSymbol!
aorist: aStem
	"the perfective stem. Written without an accent it follows the rules (γραψ: έγραψα, γράψαμε, θα γράψω);
	written with one it is used as it stands in the past (είδ: είδα, είδαμε)"
	aoristStem := aStem.
	hasPassive ifTrue: [passiveAoristStem := self guessPassiveAoristStem. participle := self guessParticiple]!
perfective: aStem
	"the stem of the subjunctive and the simple future when it is not the aorist's: δ (θα δω) for είδα"
	perfectiveStem := aStem!
imperfectStem: aStem
	imperfectStem := aStem!
augment: aString
	"the augment of the past tenses: έ- normally, ή- for θέλω (ήθελα) and ξέρω (ήξερα)"
	augment := aString!
passiveStem: aStem
	passiveStem := aStem!
passiveAorist: aStem
	passiveAoristStem := aStem.
	participle := self guessParticiple!
participle: aString
	participle := aString!
noPassive
	hasPassive := false.
	passiveAoristStem := nil.
	participle := nil!
beDeponent
	"a verb with passive endings and no active (είμαι, which the endings alone do not show)"
	deponent := true. hasPassive := false. aoristStem := nil. passiveAoristStem := nil. participle := nil!
imperative: anArray
	"the second person singular and plural of the imperative, when they are irregular"
	imperative := anArray!
tense: aTense forms: anArray
	"a whole tense that does not follow the rules: είμαι, λέω, πάω"
	forms at: aTense put: anArray!
passive: aTense forms: anArray
	forms at: (self passiveKey: aTense) put: anArray! !

!GreekVerb methodsFor: 'accessing'!
lemma
	^lemma!
gloss
	^gloss!
kind
	^kind!
conjugationName
	^kind = #A ifTrue: ['A'] ifFalse: [kind = #B1 ifTrue: ['B1'] ifFalse: ['B2']]!
stem
	^stem!
aoristStem
	^aoristStem!
perfectiveStem
	^perfectiveStem ifNil: [
		aoristStem isNil ifTrue: [nil] ifFalse: [
			(GreekText accentPosition: aoristStem) > 0 ifTrue: [nil] ifFalse: [aoristStem]]]!
passiveAoristStem
	^passiveAoristStem!
participle
	"the passive perfect participle (γραμμένος), or nil"
	^participle!
participleAdjective
	"the participle declined like any adjective in -ος, -η, -ο"
	^participle isNil ifTrue: [nil] ifFalse: [GreekAdjective lemma: participle]!
hasPassive
	^hasPassive and: [deponent not]!
isDeponent
	"a verb with passive endings and no active (έρχομαι, σκέφτομαι)"
	^deponent!
defaultVoice
	^deponent ifTrue: [#passive] ifFalse: [#active]!
printOn: aStream
	aStream nextPutAll: lemma; nextPutAll: ' (verb, '.
	deponent ifTrue: [aStream nextPutAll: 'deponent, '].
	aStream nextPutAll: 'class '; nextPutAll: self conjugationName.
	gloss isEmpty ifFalse: [aStream nextPutAll: ': '; nextPutAll: gloss].
	aStream nextPut: $)! !

!GreekVerb methodsFor: 'conjugating'!
conjugate: aTense
	"the six forms of a tense, εγώ to αυτοί, in the verb's usual voice (passive for έρχομαι); nil for a
	tense the verb does not have"
	^self conjugate: aTense voice: self defaultVoice!
conjugate: aTense voice: aVoice
	| key |
	(self class tenses includes: aTense) ifFalse: [^self error: 'no tense called ', aTense printString,
		'; the tenses are ', self class tenses printString].
	(self class voices includes: aVoice) ifFalse: [^self error: 'the voices are #active and #passive'].
	aVoice = #active ifTrue: [
		deponent ifTrue: [^nil].
		^forms at: aTense ifAbsent: [self perform: ('active' , aTense asString capitalized) asSymbol]].
	key := self passiveKey: aTense.
	^forms at: key ifAbsent: [self perform: key]!
passiveKey: aTense
	^('passive' , aTense asString capitalized) asSymbol!
form: aTense person: person number: aNumber
	"one form: verb form: #aorist person: 1 number: #plural"
	^self form: aTense person: person number: aNumber voice: self defaultVoice!
form: aTense person: person number: aNumber voice: aVoice
	| all |
	all := self conjugate: aTense voice: aVoice.
	^all isNil ifTrue: [nil] ifFalse: [all at: (self class indexFor: person number: aNumber)]!
present
	^self conjugate: #present!
imperfect
	^self conjugate: #imperfect!
aorist
	^self conjugate: #aorist!
futureContinuous
	^self conjugate: #futureContinuous!
futureSimple
	^self conjugate: #futureSimple!
perfect
	^self conjugate: #perfect!
pluperfect
	^self conjugate: #pluperfect!
futurePerfect
	^self conjugate: #futurePerfect!
subjunctive
	^self conjugate: #subjunctive!
passive: aTense
	^self conjugate: aTense voice: #passive!
infinitive
	"the form after έχω in the perfect (γράψει), which is the old infinitive (απαρέμφατο)"
	^self infinitiveVoice: self defaultVoice!
infinitiveVoice: aVoice
	| s |
	s := self conjugate: #subjunctive voice: aVoice.
	^s isNil ifTrue: [nil] ifFalse: [s at: 3]!
imperative
	"the perfective imperative, singular and plural: γράψε, γράψτε"
	| p bare |
	imperative notNil ifTrue: [^imperative].
	deponent ifTrue: [^nil].
	p := self perfectiveStem.
	p isNil ifTrue: [^nil].
	bare := GreekText strip: p.
	(GreekText syllableCount: bare) = 0 ifTrue: [^nil].
	^Array
		with: (GreekText accent: bare , 'ε' onSyllable: 3)
		with: (GreekText finalSigma: (GreekText accentLastOfStem: bare) ,
			((#('σ' 'ψ' 'ξ') includes: bare asWideString last utf8Encoded) ifTrue: ['τε'] ifFalse: ['ετε']))! !

!GreekVerb methodsFor: 'private-rules'!
fix: aString
	^GreekText finalSigma: (GreekText unaccentMonosyllable: aString)!
past: aStem endings: endings
	"the past tense rule: the accent on the third syllable from the end, and the augment when the word
	has fewer than three syllables to put it on. A stem with an accent of its own is used as it stands."
	^endings collect: [:e | self past: aStem ending: e]!
past: aStem ending: anEnding
	| w |
	(GreekText accentPosition: aStem) > 0 ifTrue: [^GreekText finalSigma: aStem , anEnding].
	w := (GreekText strip: aStem) , anEnding.
	((GreekText syllableCount: w) < 3 and: [GreekText startsWithConsonant: w])
		ifTrue: [w := augment , w].
	^GreekText accent: w onSyllable: 3!
recessive: aStem endings: endings
	"the accent as far back as it can go: on the third syllable from the end. An ending written with an
	accent keeps it."
	^endings collect: [:e |
		(GreekText accentPosition: e) > 0
			ifTrue: [self fix: (GreekText strip: aStem) , e]
			ifFalse: [GreekText accent: (GreekText strip: aStem) , e onSyllable: 3]]!
plain: aStem endings: endings
	"an unaccented stem and endings that carry the accent"
	^endings collect: [:e | self fix: (GreekText strip: aStem) , e]!
perfectiveFrom: aStem
	| bare |
	aStem isNil ifTrue: [^nil].
	bare := GreekText strip: aStem.
	(GreekText syllableCount: bare) = 0 ifTrue: [^self plain: bare endings: self class stressedEndings].
	^self class subjunctiveEndings collect: [:e | GreekText finalSigma: (GreekText accentLastOfStem: bare) , e]!
withAuxiliary: auxForms
	| inf |
	inf := self infinitiveVoice: #active.
	^inf isNil ifTrue: [nil] ifFalse: [auxForms collect: [:a | a , ' ' , inf]]!
passiveWithAuxiliary: auxForms
	| inf |
	inf := self infinitiveVoice: #passive.
	^inf isNil ifTrue: [nil] ifFalse: [auxForms collect: [:a | a , ' ' , inf]]!
future: anArray
	^anArray isNil ifTrue: [nil] ifFalse: [anArray collect: [:f | 'θα ' , f]]! !

!GreekVerb methodsFor: 'private-active'!
activePresent
	kind = #A ifTrue: [^self class presentA collect: [:e | GreekText finalSigma: stem , e]].
	kind = #B1 ifTrue: [^self plain: stem endings: self class presentB1].
	^self plain: stem endings: self class presentB2!
activeImperfect
	kind = #A ifTrue: [^self past: (imperfectStem ifNil: [GreekText strip: stem]) endings: self class pastEndings].
	^self plain: stem endings: self class imperfectB!
activeAorist
	aoristStem isNil ifTrue: [^nil].
	^self past: aoristStem endings: self class pastEndings!
activeSubjunctive
	^self perfectiveFrom: self perfectiveStem!
activeFutureContinuous
	^self future: (self conjugate: #present voice: #active)!
activeFutureSimple
	^self future: (self conjugate: #subjunctive voice: #active)!
activePerfect
	^self withAuxiliary: self class havepresent!
activePluperfect
	^self withAuxiliary: self class havePast!
activeFuturePerfect
	^self withAuxiliary: (self class havepresent collect: [:f | 'θα ' , f])! !

!GreekVerb methodsFor: 'private-passive'!
passivePresent
	self hasPassive | deponent ifFalse: [^nil].
	kind = #A ifTrue: [^self recessive: (passiveStem ifNil: [stem]) endings: self class passivePresentA].
	kind = #B1 ifTrue: [^self plain: stem endings: self class passivePresentB1].
	^self plain: stem endings: self class passivePresentB2!
passiveImperfect
	self hasPassive | deponent ifFalse: [^nil].
	kind = #A ifTrue: [^self recessive: (passiveStem ifNil: [stem]) endings: self class passiveImperfectA].
	kind = #B1 ifTrue: [^self plain: stem endings: self class passiveImperfectB1].
	^self plain: stem endings: self class passiveImperfectB2!
passiveAorist
	"a deponent with an active aorist (έρχομαι: ήρθα) is given one with aorist:"
	(deponent and: [aoristStem notNil]) ifTrue: [^self activeAoristOf: aoristStem].
	passiveAoristStem isNil ifTrue: [^nil].
	^self recessive: passiveAoristStem endings: self class passiveAoristEndings!
activeAoristOf: aStem
	^self past: aStem endings: self class pastEndings!
passiveSubjunctive
	(deponent and: [aoristStem notNil]) ifTrue: [^self perfectiveFrom: self perfectiveStem].
	passiveAoristStem isNil ifTrue: [^nil].
	^self plain: passiveAoristStem endings: self class stressedEndings!
passiveFutureContinuous
	^self future: (self conjugate: #present voice: #passive)!
passiveFutureSimple
	^self future: (self conjugate: #subjunctive voice: #passive)!
passivePerfect
	^self passiveWithAuxiliary: self class havepresent!
passivePluperfect
	^self passiveWithAuxiliary: self class havePast!
passiveFuturePerfect
	^self passiveWithAuxiliary: (self class havepresent collect: [:f | 'θα ' , f])! !

!GreekVerb methodsFor: 'tables'!
table: aTense
	"one tense as a table: verb table: #aorist"
	^self table: aTense voice: self defaultVoice!
table: aTense voice: aVoice
	| t f |
	f := self conjugate: aTense voice: aVoice.
	t := GreekTable title: lemma , ' -- ' , (self class labelFor: aTense) ,
		(aVoice = #passive & deponent not ifTrue: [' (passive)'] ifFalse: ['']).
	f isNil ifTrue: [t note: '(the verb has no such form)'. ^t].
	1 to: 3 do: [:i | t add: (Array with: (self class persons at: i) with: (f at: i)
		with: (self class persons at: i + 3) with: (f at: i + 3))].
	^t!
paradigm
	"every tense in the verb's usual voice, as a table"
	^self paradigmVoice: self defaultVoice!
passiveParadigm
	^self paradigmVoice: #passive!
paradigmVoice: aVoice
	| t groups imp part |
	t := GreekTable title: (self printString , (aVoice = #passive & deponent not ifTrue: ['  -- passive'] ifFalse: [''])).
	groups := #(#(#present #imperfect #aorist) #(#futureContinuous #futureSimple #perfect) #(#subjunctive #pluperfect #futurePerfect)).
	groups do: [:g |
		| cols |
		cols := g collect: [:tense | self conjugate: tense voice: aVoice].
		t add: (Array with: '') , (g collect: [:tense | self class labelFor: tense]).
		1 to: 6 do: [:i |
			t add: (Array with: (self class persons at: i)) ,
				(cols collect: [:c | c isNil ifTrue: [nil] ifFalse: [c at: i]])].
		t add: #()].
	aVoice = #active | deponent ifTrue: [
		imp := self imperative.
		imp notNil ifTrue: [t note: 'imperative: ' , imp first , ', ' , imp last]].
	part := self participle.
	(part notNil and: [aVoice = #passive]) ifTrue: [t note: 'participle: ' , part].
	^t! !
