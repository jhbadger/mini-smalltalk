# Greek

Modern Greek grammar: verbs in every tense and both voices, nouns, articles, adjectives and personal
pronouns, with a small lexicon and a tutorial that teaches the grammar.

```smalltalk
Smalltalk loadPackage: 'Greek'
GreekTutorial go                       "23 lessons; also System menu -> tutorial..."
```

## The quick way in

```smalltalk
'γράφω' asGreekVerb conjugate: #present     "#('γράφω' 'γράφεις' 'γράφει' 'γράφουμε' 'γράφετε' 'γράφουν')"
'γράφω' asGreekVerb aorist                  "#('έγραψα' 'έγραψες' 'έγραψε' 'γράψαμε' 'γράψατε' 'έγραψαν')"
'βλέπω' asGreekVerb futureSimple            "#('θα δω' 'θα δεις' 'θα δει' 'θα δούμε' 'θα δείτε' 'θα δουν')"
'αγαπάω' asGreekVerb passive: #aorist       "#('αγαπήθηκα' ... 'αγαπηθήκαμε' ...)"
'γράφω' asGreekVerb paradigm                "every tense, as a table"
GreekNoun plural: 'άνθρωπος'                "'άνθρωποι'"
'θάλασσα' asGreekNoun declension            "the four cases, singular and plural, with the article"
('μεγάλος' asGreekAdjective with: 'θάλασσα' asGreekNoun) case: #genitive number: #singular
                                            "'της μεγάλης θάλασσας'"
'gra/fw' asGreek                            "'γράφω' -- beta code, for a keyboard without Greek"
```

The System menu gets **greek paradigm...**, which asks for a word (in Greek or beta code) and opens a window
with its table.

## Verbs

`GreekVerb` builds the tenses from two stems, the imperfective one of the present (`γράφ-`) and the perfective
one of the aorist (`γράψ-`), plus a passive aorist stem (`γράφτ-`):

| tense | Greek name | `conjugate:` | example |
|---|---|---|---|
| present | ενεστώτας | `#present` | γράφω |
| imperfect | παρατατικός | `#imperfect` | έγραφα |
| aorist | αόριστος | `#aorist` | έγραψα |
| future continuous | εξακολουθητικός μέλλοντας | `#futureContinuous` | θα γράφω |
| future simple | στιγμιαίος μέλλοντας | `#futureSimple` | θα γράψω |
| perfect | παρακείμενος | `#perfect` | έχω γράψει |
| pluperfect | υπερσυντέλικος | `#pluperfect` | είχα γράψει |
| future perfect | συντελεσμένος μέλλοντας | `#futurePerfect` | θα έχω γράψει |
| perfective subjunctive | υποτακτική αορίστου | `#subjunctive` | (να) γράψω |

`conjugate: aTense voice: #passive` (or `passive: aTense`) gives the mediopassive: γράφομαι, γραφόμουν,
γράφτηκα, θα γραφτώ, έχω γραφτεί. Also `imperative` (γράψε, γράψτε), `participle` (γραμμένος, and
`participleAdjective` to decline it), `infinitive` (γράψει), `form: #aorist person: 1 number: #plural`,
`table: aTense`, `paradigm` and `passiveParadigm`. A tense the verb does not have answers nil.

The rules: the present keeps the accent of the dictionary form; the past tenses put it on the third syllable
from the end and add the augment έ- (ή- for θέλω, ξέρω) when the word is too short for that; the perfective
subjunctive accents the last syllable of its stem; a perfective stem with no vowel (δ-, π-, βρ-) takes stressed
endings, and a form of one syllable loses its accent. Conjugation A (γράφω), B1 (αγαπάω/αγαπώ) and B2 (μπορώ)
each have their endings; deponents (έρχομαι, σκέφτομαι, είμαι) are conjugated in the passive.

The lexicon has 46 common verbs, with the irregular ones described: είμαι, έχω, λέω, πάω, τρώω, βλέπω, κάνω,
ακούω, βρίσκω, παίρνω, μπαίνω, βγαίνω, πίνω, δίνω, μαθαίνω, έρχομαι and others. Any other verb is understood by
its ending, with its stems guessed (π β φ πτ ευ → ψ, κ γ χ σκ χν → ξ, ζ θ ν → σ; -ησ- for the B verbs), which is
right for most regular verbs. Give the stems of one that is not:

```smalltalk
GreekLexicon addVerb: ((GreekVerb lemma: 'φέρνω' gloss: 'bring') aorist: 'φερ'; passiveAorist: 'φερθ'; yourself)
```

A stem written with an accent (`'είδ'`) is used as it stands in the past; `perfective:` gives the subjunctive's
stem when it differs (`'δ'`); `tense:forms:` and `passive:forms:` give a whole tense; `imperative:`,
`augment:`, `imperfectStem:`, `participle:` and `noPassive` cover the rest. `GreekLexicon class>>buildVerbs` has
an example of each.

## Nouns, articles, adjectives, pronouns

`GreekNoun` declines by inflection class, named by the ending: masculine `#os` (δρόμος), `#as` (άντρας),
`#is` (μαθητής); feminine `#a` (χώρα), `#i` (τέχνη), `#polis` (πόλη, πόλεις); neuter `#o` (βιβλίο), `#iota`
(παιδί, σπίτι), `#ma` (όνομα), `#neuterOs` (δάσος). Each ending carries a rule for the accent, so ο άνθρωπος
gives του ανθρώπου, η θάλασσα των θαλασσών, το όνομα του ονόματος, το σπίτι του σπιτιού. Messages:
`case:number:`, `forms`, `singular`, `plurals`, `plural`, `genitive`, `withArticle:number:`,
`withIndefiniteArticle`, `declension`, and on the class `plural:`, `genitive:` and `decline:`. A noun not in the
lexicon is guessed from its ending; one that breaks the rules of its class gets the form with `form:at:number:`
(μητέρα, των μητέρων).

`GreekArticle` has the definite and indefinite articles (`table`), with the rule that drops the ν of την and
έναν before most consonants. `GreekAdjective` has the patterns -ος/-η/-ο, -ος/-α/-ο (after a vowel: ωραίος),
-ος/-ιά/-ο (γλυκός) and -ύς/-ιά/-ύ (βαθύς); `with: aNoun` makes a `GreekNounPhrase` that agrees in gender,
case and number. `GreekPronoun table` shows the strong and the weak (clitic) personal pronouns.

## Letters

`GreekText` holds the letter-level rules: `syllableCount:` (digraphs such as ου and αι are one vowel, and an
unaccented ι before a vowel is a glide, so παιδιά has two syllables), `accentPosition:`, `accent:onSyllable:`,
`strip:`, `finalSigma:`, `fromBetaCode:` and `transliterate:`. Strings get `asGreek`, `greekStripped`,
`greekUppercase` (no accents in capitals), `greekTransliterated`, `greekSyllableCount`, `greekAccentPosition`
and `greekLetters`. Everything answers ordinary UTF-8 Strings; the work is done on WideStrings, where one element
is one letter.

## What is not here

The continuous imperative (γράφε) and the passive imperative (γράψου); the older genitives (της πόλεως); verbs
with an internal augment (μετέφρασα); the nouns in -άς, -ές, -ούς, -ού with plurals in -άδες (ο παπάς, η
γιαγιά); and the second accent of a word followed by an enclitic (ο άνθρωπός μου). Character literals such as
`$ά` are not read by the compiler (it takes one byte after the `$`); write `'ά' asWideString first`.

## Files

| File | |
|---|---|
| `package.st` | loads the rest, adds the System menu item |
| `text.st` | GreekText, GreekTable, the String messages |
| `verbs.st` | GreekVerb |
| `nouns.st` | GreekNoun, GreekArticle, GreekAdjective, GreekNounPhrase, GreekPronoun |
| `lexicon.st` | GreekLexicon and its words; `asGreekVerb`, `asGreekNoun`, `asGreekAdjective`, `greekParadigm` |
| `tool.st` | the System menu's paradigm window |
| `tutorial.st` | GreekTutorial |
| `tests/tests.txt` | run by `make check` |
