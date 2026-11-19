"Regex and RegexMatch: what you use a regular expression through, and the String messages that go with them."

Object subclass: #Regex instanceVariableNames: 'pattern root groupCount ignoreCase' classVariableNames: 'Cache StepLimit' category: 'Regex'!
Object subclass: #RegexMatch instanceVariableNames: 'regex subject start end starts stops' classVariableNames: '' category: 'Regex'!

!Regex class methodsFor: 'instance creation'!
on: aString
	"a compiled pattern; patterns are remembered, so building the same one twice is cheap"
	^self on: aString ignoreCase: false!
on: aString ignoreCase: aBoolean
	| key found |
	Cache isNil ifTrue: [Cache := Dictionary new].
	key := (aBoolean ifTrue: ['i'] ifFalse: ['-']), aString.
	found := Cache at: key ifAbsent: [nil].
	found notNil ifTrue: [^found].
	found := self basicNew setPattern: aString ignoreCase: aBoolean.
	Cache size > 200 ifTrue: [Cache := Dictionary new].
	Cache at: key put: found.
	^found!
new
	^self error: 'use Regex on: aPatternString'!
flushCache
	Cache := Dictionary new! !

!Regex class methodsFor: 'the step budget'!
stepLimit
	"how much work one attempt at a match may do before it gives up with a RegexError. Some patterns,
	(a+)+b is the classic one, can backtrack for longer than anybody is prepared to wait; the budget
	turns that into an error you can see rather than a system that has stopped answering."
	^StepLimit ifNil: [StepLimit := 1000000]!
stepLimit: anIntegerOrNil
	"nil for no budget at all"
	StepLimit := anIntegerOrNil! !

!Regex methodsFor: 'private'!
setPattern: aString ignoreCase: aBoolean
	| parsed |
	pattern := aString.
	ignoreCase := aBoolean.
	parsed := RxParser parse: aString.
	root := parsed at: 1.
	groupCount := parsed at: 2!
matcherOn: aString
	^RxMatcher on: aString groups: groupCount ignoringCase: ignoreCase!
matchIn: aMatcher at: aPosition
	"the position just after a match starting exactly at aPosition, or nil"
	aMatcher clearGroups.
	aMatcher resetSteps.
	^root matchAt: aPosition then: [:p | p]! !

!Regex methodsFor: 'accessing'!
pattern
	^pattern!
groupCount
	^groupCount!
ignoresCase
	^ignoreCase!
ignoreCase
	"the same pattern, matched without regard to case"
	^Regex on: pattern ignoreCase: true!
root
	"the root node of the compiled pattern, for anyone curious about the parse"
	^root!
printOn: aStream
	aStream nextPut: $/; nextPutAll: pattern; nextPut: $/.
	ignoreCase ifTrue: [aStream nextPut: $i]! !

!Regex methodsFor: 'matching'!
search: aString
	"the first match anywhere in the string, or nil"
	^self search: aString from: 1!
search: aString from: anIndex
	| m answer stop p |
	m := self matcherOn: aString.
	answer := nil.
	RxMatcher use: m during: [
		p := anIndex max: 1.
		[answer isNil and: [p <= (aString size + 1)]] whileTrue: [
			stop := self matchIn: m at: p.
			stop isNil
				ifTrue: [p := p + 1]
				ifFalse: [answer := RegexMatch on: self subject: aString from: p to: stop matcher: m]]].
	^answer!
matches: aString
	"true when the pattern matches the whole string"
	^(self matchWholly: aString) notNil!
matchWholly: aString
	"the match covering the whole string, or nil"
	| m answer stop |
	m := self matcherOn: aString.
	answer := nil.
	RxMatcher use: m during: [
		stop := root matchAt: 1 then: [:p | p = (aString size + 1) ifTrue: [p] ifFalse: [nil]].
		stop notNil ifTrue: [answer := RegexMatch on: self subject: aString from: 1 to: stop matcher: m]].
	^answer!
matchesPrefixOf: aString
	"the match anchored at the start, or nil; the rest of the string may be anything"
	| m answer stop |
	m := self matcherOn: aString.
	answer := nil.
	RxMatcher use: m during: [
		stop := self matchIn: m at: 1.
		stop notNil ifTrue: [answer := RegexMatch on: self subject: aString from: 1 to: stop matcher: m]].
	^answer!
matchesIn: aString
	"all the matches, left to right and not overlapping"
	| out |
	out := OrderedCollection new.
	self matchesIn: aString do: [:each | out add: each].
	^out!
matchesIn: aString do: aBlock
	| m p stop |
	m := self matcherOn: aString.
	RxMatcher use: m during: [
		p := 1.
		[p <= (aString size + 1)] whileTrue: [
			stop := self matchIn: m at: p.
			stop isNil
				ifTrue: [p := p + 1]
				ifFalse: [
					aBlock value: (RegexMatch on: self subject: aString from: p to: stop matcher: m).
					p := stop > p ifTrue: [stop] ifFalse: [p + 1]]]]!
allMatchesIn: aString
	"the matched text of every match, as Strings"
	^(self matchesIn: aString) collect: [:each | each value]!
occurrencesIn: aString
	| n |
	n := 0.
	self matchesIn: aString do: [:each | n := n + 1].
	^n!
includedIn: aString
	^(self search: aString) notNil! !

!Regex methodsFor: 'replacing'!
replaceAllIn: aString with: aTemplate
	"every match replaced by the template, in which \1 to \9 stand for the groups, \0 for the whole match,
	and \\ for a backslash"
	^self replaceAllIn: aString using: [:each | self expand: aTemplate for: each]!
replaceFirstIn: aString with: aTemplate
	| found |
	found := self search: aString.
	found isNil ifTrue: [^aString copy].
	^(aString copyFrom: 1 to: found start - 1), (self expand: aTemplate for: found),
		(aString copyFrom: found stop + 1 to: aString size)!
replaceAllIn: aString using: aBlock
	"every match replaced by whatever the block answers for it (a String, or anything printable)"
	| out last |
	out := WriteStream on: String new.
	last := 1.
	self matchesIn: aString do: [:each |
		out nextPutAll: (aString copyFrom: last to: each start - 1).
		out nextPutAll: (aBlock value: each) displayString.
		last := each stop + 1].
	out nextPutAll: (aString copyFrom: last to: aString size).
	^out contents!
expand: aTemplate for: aMatch
	| out i c d text |
	out := WriteStream on: String new.
	i := 1.
	[i <= aTemplate size] whileTrue: [
		c := aTemplate at: i.
		d := i < aTemplate size ifTrue: [aTemplate at: i + 1] ifFalse: [nil].
		(c = $\ and: [d notNil])
			ifTrue: [
				d isDigit
					ifTrue: [text := aMatch at: d digitValue. out nextPutAll: (text ifNil: [''])]
					ifFalse: [out nextPut: d].
				i := i + 2]
			ifFalse: [out nextPut: c. i := i + 1]].
	^out contents! !

!Regex methodsFor: 'splitting'!
split: aString
	"the pieces of the string between the matches; a match of nothing is skipped so that the pattern
	cannot cut between every character"
	| out last |
	out := OrderedCollection new.
	last := 1.
	self matchesIn: aString do: [:each |
		each isEmpty ifFalse: [
			out add: (aString copyFrom: last to: each start - 1).
			last := each stop + 1]].
	out add: (aString copyFrom: last to: aString size).
	^out!
tokenize: aString
	"the pieces the pattern matches, rather than the pieces between them"
	^self allMatchesIn: aString! !

"---- what one match found ----"

!RegexMatch class methodsFor: 'instance creation'!
on: aRegex subject: aString from: aStart to: anEnd matcher: aMatcher
	"anEnd is the position just after the match"
	^self basicNew setRegex: aRegex subject: aString from: aStart to: anEnd matcher: aMatcher! !

!RegexMatch methodsFor: 'private'!
setRegex: aRegex subject: aString from: aStart to: anEnd matcher: aMatcher
	regex := aRegex.
	subject := aString.
	start := aStart.
	end := anEnd.
	starts := aMatcher groupStarts copy.
	stops := aMatcher groupStops copy! !

!RegexMatch methodsFor: 'accessing'!
subject
	^subject!
regex
	^regex!
start
	"the index of the first character of the match"
	^start!
stop
	"the index of the last character of the match; one less than start when the match is empty"
	^end - 1!
size
	^end - start!
isEmpty
	^end = start!
notEmpty
	^end ~= start!
value
	"the text that matched"
	^subject copyFrom: start to: end - 1!
groupCount
	^starts size - 1!
at: anIndex
	"the text of group anIndex, nil when the group took no part in the match; group 0 is the whole match"
	| s e |
	anIndex = 0 ifTrue: [^self value].
	(anIndex between: 1 and: self groupCount) ifFalse: [^nil].
	s := starts at: anIndex + 1.
	s isNil ifTrue: [^nil].
	e := stops at: anIndex + 1.
	^subject copyFrom: s to: e - 1!
startOfGroup: anIndex
	anIndex = 0 ifTrue: [^start].
	^(anIndex between: 1 and: self groupCount) ifTrue: [starts at: anIndex + 1] ifFalse: [nil]!
stopOfGroup: anIndex
	| e |
	anIndex = 0 ifTrue: [^end - 1].
	(anIndex between: 1 and: self groupCount) ifFalse: [^nil].
	e := stops at: anIndex + 1.
	^e ifNotNil: [:x | x - 1]!
groups
	"an Array of the group texts, group 1 first"
	^(1 to: self groupCount) collect: [:i | self at: i]!
prematch
	^subject copyFrom: 1 to: start - 1!
postmatch
	^subject copyFrom: end to: subject size!
printOn: aStream
	aStream nextPutAll: 'a RegexMatch('; print: self value; nextPutAll: ' at '; print: start; nextPut: $).
	self groupCount > 0 ifTrue: [aStream nextPutAll: ' groups: '; print: self groups]! !

"---- the String messages ----"

!String methodsFor: 'regular expressions'!
asRegex
	^Regex on: self!
matchesRegex: aPatternString
	"true when the pattern matches the whole receiver"
	^(Regex on: aPatternString) matches: self!
matchesRegexIgnoringCase: aPatternString
	^(Regex on: aPatternString ignoreCase: true) matches: self!
includesRegex: aPatternString
	"true when the pattern matches anywhere in the receiver"
	^((Regex on: aPatternString) search: self) notNil!
regexMatch: aPatternString
	"the first match, as a RegexMatch, or nil"
	^(Regex on: aPatternString) search: self!
allRegexMatches: aPatternString
	"the matched text of every match, as Strings"
	^(Regex on: aPatternString) allMatchesIn: self!
regexMatchesDo: aPatternString do: aBlock
	^(Regex on: aPatternString) matchesIn: self do: aBlock!
copyWithRegex: aPatternString replacedWith: aTemplate
	^(Regex on: aPatternString) replaceAllIn: self with: aTemplate!
copyWithFirstRegex: aPatternString replacedWith: aTemplate
	^(Regex on: aPatternString) replaceFirstIn: self with: aTemplate!
copyWithRegex: aPatternString matchesTranslatedUsing: aBlock
	^(Regex on: aPatternString) replaceAllIn: self using: aBlock!
splitOnRegex: aPatternString
	^(Regex on: aPatternString) split: self!
tokensMatchingRegex: aPatternString
	^(Regex on: aPatternString) allMatchesIn: self! !

!Symbol methodsFor: 'regular expressions'!
asRegex
	^Regex on: self asString! !
