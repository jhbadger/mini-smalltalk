"The Greek tutorial: Modern Greek grammar, taught with the Greek package -- the letters and the accent,
articles, the noun classes, adjectives, pronouns, and the verb in all its tenses and both voices.
Start it with   GreekTutorial go"

AbstractTutorial subclass: #GreekTutorial instanceVariableNames: '' classVariableNames: '' category: 'Greek-Tutorial'!

!GreekTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Greek'!
lessonSelectors
	^#(#welcome #lettersAndSounds #theAccent #theArticles #genderAndTheMasculine #masculineInAsAndIs
		#theFeminine #theNeuter #adjectives #pronouns #theVerbAndItsTwoStems #theSecondConjugation
		#theImperfect #theAorist #irregularAorists #theFuture #thePerfectTenses #thePassive
		#thePassiveAorist #deponentsAndEimai #theImperative #theLexicon #whatNext)! !

!GreekTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'Καλώς ήρθατε -- welcome.  This tutorial teaches the grammar of Modern Greek,
and a Smalltalk package that knows it.  Every example is live: select a line
and press ctrl-P (print it) to see the answer.

The package inflects words.  Ask a verb for a tense:

''γράφω'' asGreekVerb conjugate: #present
''γράφω'' asGreekVerb conjugate: #aorist

or a noun for its plural:

GreekNoun plural: ''θάλασσα''

and anything for its whole table:

''γράφω'' asGreekVerb paradigm
''θάλασσα'' asGreekNoun declension

If your keyboard has no Greek, type beta code -- Latin letters standing for
Greek ones, with / after the vowel that takes the accent:

''gra/fw'' asGreek
''qa/lassa'' asGreek
''gra/fw'' asGreek asGreekVerb aorist

The System menu has an item too: greek paradigm... asks for a word (Greek or
beta code) and opens a window with its table.

The lessons go from the letters and the accent, through the articles, nouns,
adjectives and pronouns, to the verb, which is where most of the grammar is.'!
lettersAndSounds
	^TutorialLesson title: 'Letters and sounds' text:
'The alphabet has 24 letters.  Seven are vowels: α ε η ι ο υ ω.  Three of them,
η ι υ, are all said [i], and ο and ω are both [o]; the spelling remembers
older Greek, the sound does not.

Some pairs of vowels make one sound: αι is [e], ει and οι are [i], ου is [u],
and αυ and ευ are [av]/[ev] or [af]/[ef].  A transliteration shows this:

''Ευχαριστώ'' greekTransliterated
''Καλημέρα'' greekTransliterated
''θάλασσα'' greekTransliterated

Sigma has two shapes: ς at the end of a word and σ everywhere else.  The
package puts the right one in by itself:

GreekText finalSigma: ''λογοσ''

Greek letters take two bytes each in UTF-8, so a String counts bytes, not
letters.  Ask for the letters themselves when you want to count them:

''γράφω'' size
''γράφω'' greekLetters
''γράφω'' greekLetters size
''γράφω'' asWideString size

Written in capitals, a word loses its accent:

''θάλασσα'' greekUppercase
''Αθήνα'' greekUppercase'!
theAccent
	^TutorialLesson title: 'The accent' text:
'Every Greek word of more than one syllable is written with an accent (the
tonos) on the vowel that is stressed.  It matters: πότε is "when?" and ποτέ is
"never".  Words of one syllable take no accent: και, να, θα, το.

The accent can only fall on one of the last three syllables.  The grammar
names them: on the last, a word is oxytone (οξύτονη); on the next to last,
paroxytone (παροξύτονη); on the third from last, proparoxytone (προπαροξύτονη).

''ουρανός'' greekAccentPosition
''δρόμος'' greekAccentPosition
''άνθρωπος'' greekAccentPosition
GreekText accentName: ''άνθρωπος''

That three-syllable limit drives a great deal of the grammar.  When an ending
makes a word longer, the accent may have to move forward to stay inside it:
ο άνθρωπος, but του ανθρώπου.  And when a past tense is too short to have its
accent on the third syllable from the end, Greek adds one (the augment):
γράφω, but έγραψα.

To count syllables the package treats a pair like ου or αι as one vowel, and
an unaccented ι before another vowel as a glide: παιδιά has two syllables.

''παιδιά'' greekSyllableCount
''διαβάζω'' greekSyllableCount
GreekText accent: ''ανθρωπου'' onSyllable: 2
GreekText accent: ''εγραψα'' onSyllable: 3
GreekText strip: ''άνθρωπος'''!
theArticles
	^TutorialLesson title: 'The articles' text:
'Greek has three genders -- masculine, feminine, neuter -- and four cases:
the nominative (the subject), the genitive (of, and the indirect object), the
accusative (the object, and after most prepositions) and the vocative (calling
someone).  The article shows the gender and the case:

GreekArticle table

ο δρόμος, η χώρα, το παιδί: the road, the country, the child.  The genitive
plural των is the same for every gender.

The accusative την drops its ν before most consonants: την πόλη, but τη
χώρα.  The ν stays before a vowel, before κ π τ ξ ψ and before the pairs μπ ντ
γκ τσ τζ (the same rule applies to έναν, δεν and μην):

GreekArticle definite: #feminine case: #accusative number: #singular before: ''πόλη''
GreekArticle definite: #feminine case: #accusative number: #singular before: ''χώρα''
GreekArticle indefinite: #masculine case: #accusative before: ''φίλο''

The indefinite article is the number one, ένας μια ένα; it has no plural.

''χώρα'' asGreekNoun withArticle: #accusative number: #singular
''φίλος'' asGreekNoun withIndefiniteArticle'!
genderAndTheMasculine
	^TutorialLesson title: 'Masculine nouns in -ος' text:
'A noun''s ending in the nominative tells you, most of the time, both its
gender and how it declines.  Nouns in -ος are almost all masculine:

''δρόμος'' asGreekNoun
''δρόμος'' asGreekNoun declension

ο δρόμος (the road), του δρόμου, τον δρόμο, δρόμε; οι δρόμοι, των δρόμων,
τους δρόμους.  The vocative ends in -ε: φίλε (friend), as you will hear in
every Greek conversation.

When the accent is on the third syllable from the end, the long endings -ου,
-ων and -ους pull it forward one place:

''άνθρωπος'' asGreekNoun declension
''δάσκαλος'' asGreekNoun genitive

And when it is on the ending, it stays there:

''ουρανός'' asGreekNoun declension

The package knows which way each noun goes from where its accent is; you
can ask for any one form:

''άνθρωπος'' asGreekNoun case: #genitive number: #plural
GreekNoun plural: ''φίλος''
GreekNoun genitive: ''άνθρωπος'''!
masculineInAsAndIs
	^TutorialLesson title: 'Masculine nouns in -ας and -ης' text:
'The other masculines end in -ας or -ης.  They drop the ς for the other
singular cases, and make their plural in -ες:

''άντρας'' asGreekNoun declension
''μαθητής'' asGreekNoun declension

ο άντρας, του άντρα, τον άντρα; οι άντρες, των αντρών.  The genitive plural
is where these differ.  A word of two syllables moves its accent to the ending,
as in αντρών and μηνών; a longer one keeps it, or pulls it forward to the next to
last syllable:

''μήνας'' asGreekNoun case: #genitive number: #plural
''πατέρας'' asGreekNoun case: #genitive number: #plural
''χειμώνας'' asGreekNoun case: #genitive number: #plural

The nouns in -ης put it on the ending in the genitive plural, always:

''κλέφτης'' asGreekNoun case: #genitive number: #plural
''μαθητής'' asGreekNoun case: #genitive number: #plural'!
theFeminine
	^TutorialLesson title: 'Feminine nouns' text:
'Feminine nouns end in -α or -η.  The singular only adds ς in the genitive;
the plural is in -ες, and the genitive plural puts the accent on the ending:

''χώρα'' asGreekNoun declension
''θάλασσα'' asGreekNoun declension
''τέχνη'' asGreekNoun declension

η θάλασσα, της θάλασσας; οι θάλασσες, των θαλασσών.

A few words in -α keep the accent where it was, and a noun can be given such a
form of its own; the package''s μητέρα is one:

''μητέρα'' asGreekNoun case: #genitive number: #plural

Many feminines in -η, especially the abstract ones in -ση, -ξη and -ψη, come
from an older class and make their plural in -εις:

''πόλη'' asGreekNoun declension
''απόφαση'' asGreekNoun declension

η απόφαση (the decision), οι αποφάσεις, των αποφάσεων -- the long -εις pulls
the accent forward, and -εων keeps it three from the end.  A new word in -ση
is guessed to be one of these:

''στάση'' asGreekNoun plural'!
theNeuter
	^TutorialLesson title: 'Neuter nouns' text:
'Neuter nouns have the same form in the nominative, accusative and vocative,
and their plural ends in -α (or -η).  There are four common classes.

In -ο, like the masculine -ος:

''βιβλίο'' asGreekNoun declension
''πρόσωπο'' asGreekNoun declension

In -ι, where the endings -ιού, -ιά, -ιών are said with the ι as a glide (two
syllables, not three).  The genitive always puts the accent on the end:

''παιδί'' asGreekNoun declension
''σπίτι'' asGreekNoun declension

In -μα, which add -ατ- before the ending.  The accent stays three from the
end, and on the next to last in the genitive plural:

''όνομα'' asGreekNoun declension
''πρόβλημα'' asGreekNoun plural

And in -ος -- a neuter -ος, not to be confused with the masculine one:

''δάσος'' asGreekNoun declension
''λάθος'' asGreekNoun plural

So -ος alone does not settle the gender: ο δρόμος but το δάσος.  This is one
reason to learn every noun with its article.'!
adjectives
	^TutorialLesson title: 'Adjectives' text:
'An adjective agrees with its noun in gender, case and number.  Most end in
-ος, -η, -ο, and decline like the nouns of those endings -- except that the
accent stays where it is:

''καλός'' asGreekAdjective declension
''όμορφος'' asGreekAdjective masculine

After a vowel the feminine is in -α:  ωραίος, ωραία, ωραίο.

''ωραίος'' asGreekAdjective
''νέος'' asGreekAdjective feminine

A few in -ύς have a feminine in -ιά and a plural in -ιοί, -ιές, -ιά:

''βαθύς'' asGreekAdjective declension

Put an adjective with a noun and the package makes them agree, article and
all:

(''μεγάλος'' asGreekAdjective with: ''θάλασσα'' asGreekNoun) declension
(''καλός'' asGreekAdjective with: ''παιδί'' asGreekNoun) declension
(''ωραίος'' asGreekAdjective with: ''πόλη'' asGreekNoun) indefinite
''καλός'' asGreekAdjective agreeWith: ''χώρα'' asGreekNoun case: #genitive number: #plural

The adjective comes before the noun, and with the article each keeps its own:
η μεγάλη θάλασσα, but also η θάλασσα η μεγάλη, for emphasis.'!
pronouns
	^TutorialLesson title: 'Personal pronouns' text:
'Greek drops the subject pronoun -- the verb''s ending already says who --
and uses εγώ, εσύ and the rest only for emphasis or contrast.  Each person has
strong forms and weak ones (clitics):

GreekPronoun table

The weak forms are the everyday ones.  They stand right before the verb:

	μου γράφει -- he writes to me
	τον βλέπω -- I see him
	θα σε δω -- I will see you
	δεν το ξέρω -- I don''t know it

and right after an imperative:  γράψε μου, δώσ'' το.  When there are two, the
genitive comes first: μου το έδωσε, he gave it to me.

The strong forms go where a clitic cannot: alone, after a preposition, and
for contrast:  σε μένα, εμένα με ξέρει.

GreekPronoun weak: 3 number: #singular gender: #feminine case: #accusative
GreekPronoun weak: 1 number: #plural case: #genitive
GreekPronoun strong: 2 number: #singular case: #accusative
GreekPronoun strong: 3 number: #plural gender: #neuter case: #genitive'!
theVerbAndItsTwoStems
	^TutorialLesson title: 'The verb and its two stems' text:
'A Greek verb is named by its first person singular present: γράφω, I write.
Its six persons are εγώ, εσύ, αυτός (he, she, it), εμείς, εσείς, αυτοί:

''γράφω'' asGreekVerb conjugate: #present
GreekVerb persons

Almost every tense comes from one of two stems.  The imperfective stem of the
present (γράφ-) says that an action goes on or repeats; the perfective stem
of the aorist (γράψ-) says that it happens once, as a whole:

''γράφω'' asGreekVerb stem
''γράφω'' asGreekVerb aoristStem

Here are all the tenses, by their English and their Greek names:

GreekVerb tenseNames

and the whole verb:

''γράφω'' asGreekVerb paradigm

The perfective stem of most first-conjugation verbs follows from the last
consonant of the present: π β φ πτ ευ give ψ, κ γ χ σκ χν give ξ, and ζ θ ν
give σ.

''κρύβω'' asGreekVerb aoristStem
''ανοίγω'' asGreekVerb aoristStem
''διαβάζω'' asGreekVerb aoristStem
''κλείνω'' asGreekVerb aoristStem
''δουλεύω'' asGreekVerb aoristStem'!
theSecondConjugation
	^TutorialLesson title: 'The second conjugation: B1 and B2' text:
'Verbs like γράφω, with the accent on the stem, are the first conjugation (A).
The second conjugation stresses the ending, and comes in two kinds.

B1, like αγαπάω (love), has -άω, -άς, -άει, -άμε, -άτε, -άνε:

''αγαπάω'' asGreekVerb present
''μιλάω'' asGreekVerb present

The first person is also written αγαπώ, and the third persons αγαπά and
αγαπούν: both sets are correct, and the package understands both names.

''αγαπώ'' asGreekVerb lemma

B2, like μπορώ (can), has -ώ, -είς, -εί, -ούμε, -είτε, -ούν:

''μπορώ'' asGreekVerb present
''θεωρώ'' asGreekVerb present

Short ones lose the accent where a form has a single syllable:

''ζω'' asGreekVerb present

The perfective stem of both kinds usually ends in -ησ- (αγάπησα, θεώρησα),
sometimes in -ασ- or -εσ- (ξέχασα, μπόρεσα):

''αγαπάω'' asGreekVerb aorist
''ξεχνάω'' asGreekVerb aorist
''μπορώ'' asGreekVerb aorist

A verb in -ώ that the lexicon does not have is taken to be B2; tell it
otherwise with kind:.'!
theImperfect
	^TutorialLesson title: 'The imperfect and the augment' text:
'The imperfect (παρατατικός) is the past of the present stem: what was going
on, or used to happen.  έγραφα, I was writing, I used to write.

''γράφω'' asGreekVerb imperfect
''διαβάζω'' asGreekVerb imperfect

The past tenses put the accent on the third syllable from the end.  When the
word has only two syllables, there is nowhere to put it, so the verb adds a
syllable in front, the augment έ-, and accents that:  έγραφα, έγραφες, έγραφε,
but γράφαμε, γράφατε, and έγραφαν again.  A longer verb needs no augment:
διάβαζα.

A few verbs take ή- instead:

''θέλω'' asGreekVerb imperfect
''ξέρω'' asGreekVerb imperfect

The second conjugation makes its imperfect differently, with -ούσα and no
augment at all:

''αγαπάω'' asGreekVerb imperfect
''μπορώ'' asGreekVerb imperfect

The rule is a method you can read: browse GreekVerb>>past:ending:.'!
theAorist
	^TutorialLesson title: 'The aorist' text:
'The aorist (αόριστος) is the simple past: something that happened, once,
as a whole.  έγραψα, I wrote.  It has the same endings and the same accent
rule as the imperfect, on the perfective stem:

''γράφω'' asGreekVerb aorist
''ανοίγω'' asGreekVerb aorist
''διαβάζω'' asGreekVerb aorist
''αγαπάω'' asGreekVerb aorist

The difference between the two pasts is aspect, not time:

	έγραφα ένα γράμμα -- I was writing a letter (and maybe never finished)
	έγραψα ένα γράμμα -- I wrote a letter (and it is done)

One form at a time:

''γράφω'' asGreekVerb form: #aorist person: 1 number: #plural
''γράφω'' asGreekVerb form: #imperfect person: 3 number: #singular

Many common verbs have a perfective stem that is only loosely related to the
present, but regular from there on:

''φεύγω'' asGreekVerb aorist
''μένω'' asGreekVerb aorist
''δίνω'' asGreekVerb aorist
''μαθαίνω'' asGreekVerb aorist'!
irregularAorists
	^TutorialLesson title: 'Irregular aorists' text:
'Some of the commonest verbs have an aorist that keeps its accent and its
augment in every person:  είδα, είδαμε (not *ίδαμε).  The package writes such a
stem with its accent, and uses it as it stands:

''βλέπω'' asGreekVerb aorist
''λέω'' asGreekVerb aorist
''πάω'' asGreekVerb aorist
''βρίσκω'' asGreekVerb aorist
''παίρνω'' asGreekVerb aorist
''μπαίνω'' asGreekVerb aorist
''πίνω'' asGreekVerb aorist

The perfective stem of these, for the future and the subjunctive, is
different again, and for some it has no vowel at all: θα δω (I will see), θα
πω (I will say), θα βρω (I will find).  Then the endings take the accent, and
the forms of one syllable lose it: δω, δεις, δει, δούμε, δείτε, δουν.

''βλέπω'' asGreekVerb subjunctive
''λέω'' asGreekVerb subjunctive
''παίρνω'' asGreekVerb subjunctive
''βλέπω'' asGreekVerb perfectiveStem

τρώω (eat) has the aorist έφαγα and the future θα φάω, and πάω is θα πάω:

''τρώω'' asGreekVerb aorist
''τρώω'' asGreekVerb subjunctive
''πάω'' asGreekVerb futureSimple'!
theFuture
	^TutorialLesson title: 'The future and the subjunctive' text:
'The future is θα before a verb, and the two stems give two futures.  θα with
the present says something will be going on, or will happen again and again;
θα with the perfective says it will happen, once:

''γράφω'' asGreekVerb futureContinuous
''γράφω'' asGreekVerb futureSimple

	θα σου γράφω -- I will write to you (regularly)
	θα σου γράψω -- I will write to you (a letter)

What follows θα in the simple future is the perfective subjunctive, which also
follows να (to, that) and ας (let''s):

''γράφω'' asGreekVerb subjunctive
''αγαπάω'' asGreekVerb subjunctive

	θέλω να γράψω -- I want to write
	πρέπει να φύγουμε -- we must leave
	ας πάμε -- let''s go

Greek has no infinitive: "I want to write" is "I want that I write", with the
person in both verbs: θέλεις να γράψεις, θέλουμε να γράψουμε.

The subjunctive puts the accent on the last syllable of the stem:

''διαβάζω'' asGreekVerb futureSimple
''ακούω'' asGreekVerb futureSimple'!
thePerfectTenses
	^TutorialLesson title: 'The perfect tenses' text:
'The perfect (παρακείμενος) is έχω with an unchanging form, the old
infinitive, which is the same as the third person singular of the
subjunctive:  έχω γράψει, I have written.

''γράφω'' asGreekVerb infinitive
''γράφω'' asGreekVerb perfect
''βλέπω'' asGreekVerb perfect
''τρώω'' asGreekVerb perfect

The pluperfect (υπερσυντέλικος) has είχα, and the future perfect θα έχω:

''γράφω'' asGreekVerb pluperfect
''γράφω'' asGreekVerb futurePerfect

The perfect is used less than the English one.  For something that just
happened, Greek usually says the aorist: Έφαγες; -- have you eaten?  (The
Greek question mark is the semicolon.)

A verb with no perfective stem has no perfect tenses, and the package says so
with nil:

''ξέρω'' asGreekVerb perfect
''ξέρω'' asGreekVerb table: #perfect'!
thePassive
	^TutorialLesson title: 'The passive' text:
'The passive voice (it is really a mediopassive: reflexive and reciprocal as
well) has endings of its own:  γράφομαι, I am written.

''γράφω'' asGreekVerb passive: #present
''γράφω'' asGreekVerb passive: #imperfect
''γράφω'' asGreekVerb table: #present voice: #passive

In the first conjugation the accent goes as far back as it can -- γράφομαι,
γραφόμαστε -- and in the imperfect it sits on the -ό- of the ending:
γραφόμουν, γραφόσουν, γραφόταν.

B1 verbs have -ιέμαι, B2 verbs -ούμαι:

''αγαπάω'' asGreekVerb passive: #present
''θεωρώ'' asGreekVerb passive: #present
''αγαπάω'' asGreekVerb passive: #imperfect

So many passives mean "oneself" or "each other" that it is worth knowing
them as words of their own:  ντύνομαι, I get dressed; βλεπόμαστε, we see each
other (and so: see you).

Not every verb has a passive:

''μπορώ'' asGreekVerb hasPassive
''πάω'' asGreekVerb passive: #present'!
thePassiveAorist
	^TutorialLesson title: 'The passive aorist and the participle' text:
'The passive has its own perfective stem, usually the active one with
-τ- or -θ-: γράψ- becomes γράφτ-, ανοίξ- ανοίχτ-, διαβάσ- διαβάστ-, and
αγαπήσ- αγαπήθ-.  The aorist adds -ηκα, -ηκες, -ηκε, -ήκαμε, -ήκατε, -ηκαν:

''γράφω'' asGreekVerb passive: #aorist
''αγαπάω'' asGreekVerb passive: #aorist
''βλέπω'' asGreekVerb passive: #aorist

The subjunctive -- and so the simple future -- has stressed endings, and the
perfect has -εί:

''γράφω'' asGreekVerb passive: #futureSimple
''γράφω'' asGreekVerb passive: #perfect

The passive perfect participle ends in -μένος, and is an ordinary adjective:

''γράφω'' asGreekVerb participle
''ανοίγω'' asGreekVerb participle
''αγαπάω'' asGreekVerb participle
''γράφω'' asGreekVerb participleAdjective feminine

	το γράμμα είναι γραμμένο -- the letter is written
	η πόρτα είναι ανοιγμένη -- the door has been opened

The whole passive at once:

''διαβάζω'' asGreekVerb passiveParadigm'!
deponentsAndEimai
	^TutorialLesson title: 'Deponents, and είμαι' text:
'Some verbs have passive endings and no active: they are called deponents.
έρχομαι (come), σκέφτομαι (think), κάθομαι (sit).  The package conjugates
them in the passive by default:

''σκέφτομαι'' asGreekVerb
''σκέφτομαι'' asGreekVerb present
''σκέφτομαι'' asGreekVerb aorist

έρχομαι is passive in the present but has an active aorist, ήρθα, and a
future θα έρθω:

''έρχομαι'' asGreekVerb aorist
''έρχομαι'' asGreekVerb futureSimple
''έρχομαι'' asGreekVerb paradigm

The verb "to be", είμαι, is a deponent too, and has only a present and an
imperfect (θα είμαι is its future):

''είμαι'' asGreekVerb present
''είμαι'' asGreekVerb imperfect
''είμαι'' asGreekVerb futureContinuous
''είμαι'' asGreekVerb aorist

είναι is both "he is" and "they are".  έχω, to have, is regular in the
present but has the imperfect είχα, and no aorist:

''έχω'' asGreekVerb imperfect'!
theImperative
	^TutorialLesson title: 'The imperative' text:
'The imperative has a second person singular and plural.  The perfective one,
which is the commoner, is made on the aorist stem: γράψε, γράψτε.

''γράφω'' asGreekVerb imperative
''διαβάζω'' asGreekVerb imperative
''αγαπάω'' asGreekVerb imperative
''φεύγω'' asGreekVerb imperative

The singular puts the accent as far back as it can (διάβασε, αγάπησε); the
plural adds -τε after σ, ψ or ξ and -ετε otherwise (φύγετε, μείνετε).

The short verbs have short imperatives, and some take them from another verb
altogether:

''βλέπω'' asGreekVerb imperative
''λέω'' asGreekVerb imperative
''τρώω'' asGreekVerb imperative
''έρχομαι'' asGreekVerb imperative
''πάω'' asGreekVerb imperative

A weak pronoun follows the imperative:  γράψε το, πες μου, δώσ'' του το.  To
forbid, Greek uses μη(ν) with the subjunctive, not the imperative:  μη γράψεις,
don''t write.'!
theLexicon
	^TutorialLesson title: 'The lexicon, and new words' text:
'The package has a small lexicon of common words, with their English:

GreekLexicon verbs
GreekLexicon nouns
GreekLexicon adjectives
GreekLexicon glossary
GreekLexicon english: ''look''
GreekLexicon lookup: ''θάλασσα''

A word that is not in it is still understood, by its ending.  For a regular
verb the guess is usually right:

''τρέχω'' asGreekVerb aorist
''λύνω'' asGreekVerb aorist
''κρύβω'' asGreekVerb passive: #aorist
''ψάχνω'' asGreekVerb participle
''πόρτα'' asGreekNoun declension
''θέση'' asGreekNoun plural

For one that is not, give the stems yourself, and add it:

GreekLexicon addVerb: ((GreekVerb lemma: ''φέρνω'' gloss: ''bring'') aorist: ''φερ''; passiveAorist: ''φερθ''; yourself)
''φέρνω'' asGreekVerb aorist
''φέρνω'' asGreekVerb futureSimple

That is φέρνω, έφερα, θα φέρω.  A stem written with an accent is used just as it is
in the past, the way βλέπω has είδ-; a perfective stem with no vowel takes
stressed endings, the way βλέπω has δ-.  Look at GreekLexicon class>>buildVerbs
for every way a verb in the lexicon is described.'!
whatNext
	^TutorialLesson title: 'What next' text:
'That is the core of Greek inflection: two stems for every verb, the
augment, θα and να, έχω for the perfect, the passive with its own aorist, and
nouns and adjectives that agree in gender, case and number, all held in
place by the three-syllable rule for the accent.

What the package does not do: the continuous imperative (γράφε), the passive
imperative (γράψου), the older genitives (της πόλεως), compound verbs with an
internal augment (μετέφρασα), and the many nouns in -άς, -ές, -ούς and -ού with
plurals in -άδες (ο παπάς, η γιαγιά).  Each would be a small addition.

The classes are in the categories Greek-Grammar and Greek-Tutorial:

GreekText
GreekVerb
GreekNoun
GreekAdjective
GreekLexicon

and the package README is packages/Greek/README.md.  A table for any word:

''μαθαίνω'' greekParadigm
''πρόβλημα'' greekParadigm

Other tutorials in this image:

Smalltalk tutorialNames

Καλή συνέχεια -- good luck with the rest.'! !
