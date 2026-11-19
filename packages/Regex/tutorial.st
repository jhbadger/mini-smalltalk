"The Regex tutorial: the pattern language, searching, groups, replacing, splitting, and the workspace for
trying a pattern out.  Start it with   RegexTutorial go"

AbstractTutorial subclass: #RegexTutorial instanceVariableNames: '' classVariableNames: '' category: 'Regex'!

!RegexTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Regex'!
lessonSelectors
	^#(#welcome #matchingAWholeString #literalsAndTheDot #characterClasses #repetition #greedyAndLazy
		#alternationAndGroups #searching #theMatchObject #anchorsAndBackReferences #replacing #splitting
		#caseAndTheObject #whenItGoesWrong #theWorkspace #whatNext)! !

!RegexTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'A regular expression is a small pattern language for describing shapes that
text might have: a date, an address, a word, a number with a sign on it.  This
package reads such a pattern and matches it against a String.

Everything in this tutorial is live.  Select a line and press ctrl-P (print it)
to run it and see the answer.

Most of the time you never mention the Regex class at all; the pattern goes
straight into a String message:

''2026-11-19'' matchesRegex: ''\d{4}-\d\d-\d\d''
''hello world'' includesRegex: ''\bw\w+''
''x=1; y=22'' allRegexMatches: ''\d+''
''a, b ,c'' splitOnRegex: ''\s*,\s*''
''John Smith'' copyWithRegex: ''(\w+) (\w+)'' replacedWith: ''\2, \1''

Those five lines are the whole package in miniature: match, find, find all,
split, replace.  The lessons that follow take the pattern language first and
then each of those in turn.'!
matchingAWholeString
	^TutorialLesson title: 'Matching a whole string' text:
'The simplest question is whether a pattern describes the WHOLE of a string.
That is matchesRegex:, and it is all or nothing:

''hello'' matchesRegex: ''hello''
''hello'' matchesRegex: ''hell''
''hello'' matchesRegex: ''h.*o''

The second one answers false.  This catches people out, because in many other
languages the same call would look for the pattern anywhere in the string.
Here, asking whether it is in there somewhere is a different message:

''hello'' includesRegex: ''hell''

Keep the two apart in your head: matchesRegex: validates, includesRegex: finds.
Validation is usually what you want when you are checking a field:

''2026-11-19'' matchesRegex: ''\d{4}-\d\d-\d\d''
''19/11/2026'' matchesRegex: ''\d{4}-\d\d-\d\d''
''badgerjh@nih.gov'' matchesRegex: ''[\w.%+-]+@[\w.-]+\.[a-zA-Z]{2,}''
''not an address'' matchesRegex: ''[\w.%+-]+@[\w.-]+\.[a-zA-Z]{2,}''

An empty pattern matches only an empty string:

'''' matchesRegex: ''''
''a'' matchesRegex: '''''!
literalsAndTheDot
	^TutorialLesson title: 'Literals, the dot and escapes' text:
'Most characters in a pattern stand for themselves:

''abc'' matchesRegex: ''abc''

A dot stands for any character except a line feed:

''abc'' matchesRegex: ''a.c''
''a c'' matchesRegex: ''a.c''
''ac'' matchesRegex: ''a.c''

The characters that mean something else -- . * + ? ( ) [ ] { } | \ ^ $ -- are
made ordinary by a backslash:

''3+4'' matchesRegex: ''3\+4''
''a.b'' matchesRegex: ''a\.b''
''axb'' matchesRegex: ''a\.b''
''(x)'' matchesRegex: ''\(x\)''

A backslash also makes the control characters, and a character by its code:

''xAy'' matchesRegex: ''x\x41y''
(''a'', (String with: Character tab), ''b'') matchesRegex: ''a\tb''

The full set is \n \t \r \f \v \a \e \0 and \xNN.  Note what this means for
writing patterns in Smalltalk: the backslash is NOT special to a Smalltalk
string literal, so you write the pattern exactly as you would say it, with one
backslash and not two.'!
characterClasses
	^TutorialLesson title: 'Character classes' text:
'Square brackets mean any one of these:

''cab'' matchesRegex: ''[abc]+''
''cad'' matchesRegex: ''[abc]+''

A dash inside gives a range, and several ranges can sit together:

''hello'' matchesRegex: ''[a-z]+''
''Hello'' matchesRegex: ''[a-z]+''
''Ab9'' matchesRegex: ''[a-zA-Z0-9]+''

A caret first means anything BUT these:

''abc'' matchesRegex: ''[^0-9]+''
''ab3'' matchesRegex: ''[^0-9]+''

Six shorthands cover the classes you want most often: \d a digit, \w a word
character (letter, digit or underscore), \s a space, and \D \W \S for their
opposites:

''2026'' matchesRegex: ''\d+''
''a_1'' matchesRegex: ''\w+''
''a-1'' matchesRegex: ''\w+''
''abc'' matchesRegex: ''\D+''

They work inside a class too, which is how you write a hexadecimal digit:

''1a2f'' matchesRegex: ''[\da-f]+''
''1g'' matchesRegex: ''[\da-f]+''

A ] first, or a - first or last, is an ordinary character:

'']'' matchesRegex: ''[]]''
''a-b'' matchesRegex: ''[-ab]+'''!
repetition
	^TutorialLesson title: 'Repetition' text:
'A quantifier after something says how many of it:

* none or more, + one or more, ? none or one.

''a'' matchesRegex: ''ab*''
''abbbb'' matchesRegex: ''ab*''
''a'' matchesRegex: ''ab+''
''color'' matchesRegex: ''colou?r''
''colour'' matchesRegex: ''colou?r''

Braces give exact counts: {3} exactly three, {2,4} between two and four, {2,}
at least two.

''aaa'' matchesRegex: ''a{3}''
''aa'' matchesRegex: ''a{3}''
''aaa'' matchesRegex: ''a{2,4}''
''aaaaa'' matchesRegex: ''a{2,4}''
''aaaaaa'' matchesRegex: ''a{2,}''

A brace with nothing countable after it is just a character, so you do not have
to escape it when you mean one:

''a{b'' matchesRegex: ''a{b''

A quantifier applies to the one thing in front of it.  To repeat more than one
character, put them in a group, which the lesson after next covers:

''ababab'' matchesRegex: ''(ab)+'''!
greedyAndLazy
	^TutorialLesson title: 'Greedy and lazy' text:
'A quantifier is GREEDY by default: it takes as much as it can and gives some
back only if the rest of the pattern then cannot match.  That is usually right
and occasionally a disaster:

(''<a><b>'' regexMatch: ''<.+>'') value

You asked for a tag and got both tags, because .+ ate the whole line and then
gave back just enough for the final >.

A question mark after the quantifier makes it LAZY: take as little as will do.

(''<a><b>'' regexMatch: ''<.+?>'') value
(''aaa'' regexMatch: ''a+?'') value

Every quantifier has the lazy form: *? +? ?? and {2,4}?.

The usual fix for the tag is not laziness but saying what you really mean,
which is a run of characters that are not the closing bracket:

(''<a><b>'' regexMatch: ''<[^>]+>'') value

That version cannot run past the > in the first place, so it needs no
backtracking at all, and it is the one to prefer in anything that matters.'!
alternationAndGroups
	^TutorialLesson title: 'Alternation and groups' text:
'A vertical bar means either:

''cat'' matchesRegex: ''cat|dog''
''dog'' matchesRegex: ''cat|dog''
''cow'' matchesRegex: ''cat|dog''

Parentheses group, so a quantifier or a bar applies to the whole of what is
inside them:

''ababab'' matchesRegex: ''(ab)+''
''ace'' matchesRegex: ''a(b|c|d)e''
''abcdab'' matchesRegex: ''(ab|cd)*''

Alternation takes the FIRST branch that lets the rest of the pattern match, not
the longest one.  Searching for this pattern finds ab, not abcd:

(''abcd'' regexMatch: ''ab|abcd'') value

A group also CAPTURES: it remembers the text it matched so you can ask for it
afterwards.  That is what the next lesson but one is about.  When you want the
grouping but not the capturing, write (?: at the front:

(''abab'' regexMatch: ''(?:ab)+'') groupCount
(''abab'' regexMatch: ''(ab)+'') groupCount

Not capturing is tidier when a group is there only to hold a quantifier, since
it keeps the numbering of the groups you do care about from shifting.'!
searching
	^TutorialLesson title: 'Searching' text:
'includesRegex: answers whether the pattern is in there; regexMatch: answers
WHERE, as a RegexMatch, or nil when it is nowhere:

''hello world'' includesRegex: ''o w''
''xxabyy'' regexMatch: ''ab''
''hello'' regexMatch: ''z+''

For every match rather than the first, allRegexMatches: answers the matched
text:

''x=1; y=22; z=333'' allRegexMatches: ''\d+''
''the cat sat on the mat'' allRegexMatches: ''\w+at''

Matches never overlap, and the search goes left to right:

''aaaa'' allRegexMatches: ''aa''

An empty match still moves on by one character rather than looping for ever, so
a pattern that can match nothing answers one empty string per position:

''abc'' allRegexMatches: ''x*''

To do something with each match in turn rather than collect them:

| sizes | sizes := OrderedCollection new. ''a bb ccc'' regexMatchesDo: ''\w+'' do: [:m | sizes add: m value size]. sizes

And to count them without building anything:

(Regex on: ''\d+'') occurrencesIn: ''a1b22c333'''!
theMatchObject
	^TutorialLesson title: 'What a match knows' text:
'regexMatch: answers a RegexMatch, which knows rather more than the text:

| m | m := ''xxabyy'' regexMatch: ''ab''. m value
| m | m := ''xxabyy'' regexMatch: ''ab''. m start
| m | m := ''xxabyy'' regexMatch: ''ab''. m stop
| m | m := ''xxabyy'' regexMatch: ''ab''. m size
| m | m := ''xxabyy'' regexMatch: ''ab''. m prematch
| m | m := ''xxabyy'' regexMatch: ''ab''. m postmatch

The groups are the point of it, though.  Each pair of parentheses captures what
it matched, numbered from the left by its opening bracket:

| m | m := ''2026-11-19'' regexMatch: ''(\d{4})-(\d\d)-(\d\d)''. m groups
| m | m := ''2026-11-19'' regexMatch: ''(\d{4})-(\d\d)-(\d\d)''. m at: 2
| m | m := ''2026-11-19'' regexMatch: ''(\d{4})-(\d\d)-(\d\d)''. m groupCount

Group 0 is the whole match, which saves a special case when you are walking
through them:

| m | m := ''key: value'' regexMatch: ''^(\w+):\s*(.*)$''. m at: 0

A group that took no part in the match answers nil, which is different from
having matched an empty string:

| m | m := ''ac'' regexMatch: ''a(b)?c''. (m at: 1) printString
| m | m := ''ac'' regexMatch: ''a(b?)c''. (m at: 1) printString

and you can ask where a group was as well as what it was:

| m | m := ''abc'' regexMatch: ''a(b)c''. Array with: (m startOfGroup: 1) with: (m stopOfGroup: 1)'!
anchorsAndBackReferences
	^TutorialLesson title: 'Anchors and back references' text:
'An anchor matches a POSITION rather than a character, so it consumes nothing.

^ is the start of the subject and $ is the end:

(''one two'' regexMatch: ''\w+$'') value
((Regex on: ''^bc'') search: ''abcdef'') printString

\b is a word boundary -- the place between a word character and something that
is not one -- and \B is anywhere that is not such a place:

''the cat sat'' allRegexMatches: ''\bs\w+''
''abc'' allRegexMatches: ''\Bb\B''

Word boundaries are the right way to look for a whole word, which [^a-z] is
not, because it fails at the ends of the string:

''a cat here'' includesRegex: ''\bcat\b''
''concatenate'' includesRegex: ''\bcat\b''

A back reference, \1 to \9, matches the same TEXT an earlier group matched.
This asks for something, then the very same thing again:

''abcabc'' matchesRegex: ''(abc)\1''
''abcabd'' matchesRegex: ''(abc)\1''
(''say say what'' regexMatch: ''(\w+) \1'') value

That is a thing no amount of character classes can say, and the usual reason to
reach for it is finding a doubled word in prose.'!
replacing
	^TutorialLesson title: 'Replacing' text:
'The simplest replacement puts the same text in place of every match:

''a1b2c3'' copyWithRegex: ''\d'' replacedWith: ''#''
''hello'' copyWithRegex: ''z'' replacedWith: ''#''

In the replacement, \1 to \9 stand for the groups and \0 for the whole match,
which is how you rearrange rather than discard:

''John Smith'' copyWithRegex: ''(\w+) (\w+)'' replacedWith: ''\2, \1''
''ab'' copyWithRegex: ''a'' replacedWith: ''[\0]''
''camelCaseWord'' copyWithRegex: ''([a-z])([A-Z])'' replacedWith: ''\1_\2''

A doubled backslash puts a backslash in:

''a'' copyWithRegex: ''a'' replacedWith: ''\\''

To replace only the first:

''aaa bbb'' copyWithFirstRegex: ''\w+'' replacedWith: ''X''

And when the replacement has to be computed rather than written out, hand it a
block.  The block is given each RegexMatch and whatever it answers is used:

''a1b22'' copyWithRegex: ''\d+'' matchesTranslatedUsing: [:m | m value size]
''hello world'' copyWithRegex: ''\w+'' matchesTranslatedUsing: [:m | m value asUppercase]

Trimming is a replacement with an empty string and an alternation of the two
ends:

''  padded  '' copyWithRegex: ''^\s+|\s+$'' replacedWith: '''''!
splitting
	^TutorialLesson title: 'Splitting' text:
'splitOnRegex: cuts a string at every match and answers the pieces between:

''a, b,c ,d'' splitOnRegex: ''\s*,\s*''
''a1b22c'' splitOnRegex: ''\d+''
''one'' splitOnRegex: '',''

An empty piece is kept, since it says something -- two separators in a row:

''a,,b'' splitOnRegex: '',''

A pattern that can match nothing is skipped when it does, so splitting cannot
fall apart into one piece per character:

''abc'' splitOnRegex: ''x*''

The opposite of splitting is keeping the pieces that DO match, which is what
allRegexMatches: already does; it has a second name that reads better when you
think of it as cutting text into tokens:

''x = 1 + 22'' tokensMatchingRegex: ''\w+|[=+]''

Which of the two you want depends on whether the interesting part is the
separators or the things between them.'!
caseAndTheObject
	^TutorialLesson title: 'Ignoring case, and the Regex object' text:
'Matching without regard to case has its own messages:

''HeLLo'' matchesRegexIgnoringCase: ''hello''
''HeLLo'' matchesRegex: ''hello''

Case is ignored by ranges and by back references too, not only by plain
letters:

(Regex on: ''[a-c]+'' ignoreCase: true) matches: ''ABC''
(Regex on: ''(ab)\1'' ignoreCase: true) matches: ''abAB''

Behind all the String messages is a Regex object, which is what you reach for
when a pattern is used a lot or when you want more than one answer from it:

| r | r := Regex on: ''(\w+)@(\w+)''. r matches: ''me@here''
| r | r := Regex on: ''(\w+)@(\w+)''. r search: ''write to me@here now''
| r | r := Regex on: ''(\w+)@(\w+)''. r allMatchesIn: ''a@b and c@d''
| r | r := Regex on: ''(\w+)@(\w+)''. r groupCount
| r | r := Regex on: ''(\w+)@(\w+)''. r pattern
(Regex on: ''abc'') ignoreCase matches: ''ABC''

You do not have to do this for speed: compiled patterns are remembered, so a
pattern that has been seen before is not parsed again.

(Regex on: ''a+'') == (Regex on: ''a+'')

There is also matchesPrefixOf:, which anchors at the start only, and is what a
reader or a lexer wants:

((Regex on: ''\d+'') matchesPrefixOf: ''123abc'') value
((Regex on: ''\d+'') matchesPrefixOf: ''abc123'') printString'!
whenItGoesWrong
	^TutorialLesson title: 'When it goes wrong' text:
'A pattern the parser cannot read raises a RegexError saying where it gave up:

[Regex on: ''a(''] on: RegexError do: [:e | e messageText]
[Regex on: ''a{3,1}''] on: RegexError do: [:e | e messageText]
[Regex on: ''[abc''] on: RegexError do: [:e | e messageText]
[Regex on: ''*a''] on: RegexError do: [:e | e messageText]

The other way a pattern goes wrong is not an error at all in most systems: it
simply never finishes.  Matching here is by backtracking, and a pattern with a
repeat inside a repeat can try an astronomical number of ways before giving up.
The classic is (a+)+b against a run of a with no b at the end.

So every ATTEMPT at a match has a budget, and running it out gives you an error
you can see rather than a system that has stopped answering:

Regex stepLimit
[(Regex on: ''(a+)+b'') matches: (String new: 40 withAll: $a)] on: RegexError do: [:e | ''gave up'']

You can raise it, lower it, or turn it off with nil:

| n | n := Regex stepLimit. Regex stepLimit: 50000. Regex stepLimit: n

The budget is per attempt and not per search, so looking through a long string
does not use it up.  If you hit it, the answer is almost never a bigger budget:
it is a pattern that cannot backtrack, like [^>]+ in place of .+ .'!
theWorkspace
	^TutorialLesson title: 'The workspace' text:
'Trying a pattern out by editing a line of Smalltalk over and over is tedious.
The System menu has a regex workspace for it: right-click the desktop, then
regex workspace.

RegexTool open

Select a pattern and the lines under it, then print it.  The first line is the
pattern and every line below is tried against it.  Try selecting these four
lines in the window that just opened (they are indented here only so that they
are not mistaken for something to run on their own):

    (\w+)@([\w.]+)
    write to me@example.com
    and to someone.else@sub.example.org
    no address on this line

The report puts a rule under each match and lists the groups, so you can see at
a glance which part of the pattern caught which part of the line.

Write the pattern bare, or between slashes with an i after the closing slash to
ignore case:

RegexTool regexFor: ''/ab/i''
RegexTool regexFor: ''/ab/''

The same thing without a window, which is useful in a test:

RegexTool evaluate: (''a+'', (String with: Character lf), ''xaaay'')

An empty match is shown as | rather than as a rule, so you can tell the
difference between matching nothing somewhere and not matching at all.'!
whatNext
	^TutorialLesson title: 'Where to go next' text:
'That is the package.  A few things worth carrying away:

matchesRegex: is all or nothing; includesRegex: looks anywhere.

Prefer a pattern that cannot backtrack ([^>]+) to one that can (.+?) whenever
you have the choice.

Capture with (...) when you want the piece, and with (?:...) when you only want
the grouping.

What is NOT here: look-ahead and look-behind, named groups, multiline and
dot-all modes, possessive quantifiers, and Unicode properties.  ^ and $ mean the
start and the end of the whole subject, not of a line.

The matcher itself is worth a look if you have never written one.  It is a tree
of nodes, and every node answers one message: matchAt: position then: aBlock,
where the block is the rest of the pattern.  You can take a compiled pattern
apart:

(Regex on: ''a|b'') root class name
(Regex on: ''a*'') root class name
(Regex on: ''a{2,5}'') root max
(Regex on: ''\b'') root kind

The package README is packages/Regex/README.md, and the classes are in the two
categories whose names begin with Regex.

Other tutorials in this image:

Smalltalk tutorialNames

and the one for the language itself:

Smalltalk tutorial'! !
