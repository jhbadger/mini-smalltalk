"The tests for the Regex package: the parser, each kind of node, the searching and replacing API,
the String messages, and the step budget that stops a runaway pattern."

TestCase subclass: #RegexTest instanceVariableNames: '' classVariableNames: '' category: 'Regex-Tests'!

!RegexTest methodsFor: 'helpers'!
assert: aPattern matches: aString
	self assert: ((Regex on: aPattern) matches: aString)
		description: '/', aPattern, '/ should match ', aString printString!
deny: aPattern matches: aString
	self deny: ((Regex on: aPattern) matches: aString)
		description: '/', aPattern, '/ should not match ', aString printString!
firstIn: aString of: aPattern
	| m |
	m := (Regex on: aPattern) search: aString.
	^m ifNil: [nil] ifNotNil: [:x | x value]! !

!RegexTest methodsFor: 'literals and the dot'!
testLiteral
	self assert: 'abc' matches: 'abc'.
	self deny: 'abc' matches: 'abd'.
	self deny: 'abc' matches: 'ab'.
	self deny: 'abc' matches: 'abcd'!
testEmptyPattern
	self assert: '' matches: ''.
	self deny: '' matches: 'a'!
testDot
	self assert: 'a.c' matches: 'abc'.
	self assert: 'a.c' matches: 'a c'.
	self deny: 'a.c' matches: 'ac'.
	self deny: 'a.c' matches: ('a', (String with: Character lf), 'c')!
testEscapedMetacharacters
	self assert: '3\+4' matches: '3+4'.
	self assert: 'a\.b' matches: 'a.b'.
	self deny: 'a\.b' matches: 'axb'.
	self assert: 'a\*' matches: 'a*'.
	self assert: '\(x\)' matches: '(x)'!
testControlEscapes
	self assert: ((Regex on: 'a\tb') matches: ('a', (String with: Character tab), 'b')).
	self assert: ((Regex on: 'a\nb') matches: ('a', (String with: Character lf), 'b')).
	self assert: 'x\x41y' matches: 'xAy'! !

!RegexTest methodsFor: 'character classes'!
testSimpleClass
	self assert: '[abc]+' matches: 'cabba'.
	self deny: '[abc]+' matches: 'cabda'!
testRange
	self assert: '[a-z]+' matches: 'hello'.
	self deny: '[a-z]+' matches: 'Hello'.
	self assert: '[a-zA-Z0-9]+' matches: 'Ab9'!
testNegatedClass
	self assert: '[^0-9]+' matches: 'abc'.
	self deny: '[^0-9]+' matches: 'ab3'!
testLiteralBracketAndDash
	self assert: '[]]' matches: ']'.
	self assert: '[a\-b]+' matches: 'a-b'.
	self assert: '[-a]+' matches: '-a'!
testShorthandClasses
	self assert: '\d+' matches: '2026'.
	self deny: '\d+' matches: '20a6'.
	self assert: '\w+' matches: 'a_1'.
	self deny: '\w+' matches: 'a-1'.
	self assert: '\s+' matches: ('  ', (String with: Character tab)).
	self assert: '\D+' matches: 'abc'.
	self assert: '\W+' matches: '!!?'.
	self assert: '\S+' matches: 'abc'!
testShorthandInsideClass
	self assert: '[\da-f]+' matches: '1a2f'.
	self deny: '[\da-f]+' matches: '1g'.
	self assert: '[\w.]+' matches: 'a.b_c'! !

!RegexTest methodsFor: 'repetition'!
testStar
	self assert: 'ab*' matches: 'a'.
	self assert: 'ab*' matches: 'abbbb'.
	self assert: 'a*' matches: ''!
testPlus
	self assert: 'ab+' matches: 'ab'.
	self deny: 'ab+' matches: 'a'!
testOptional
	self assert: 'colou?r' matches: 'color'.
	self assert: 'colou?r' matches: 'colour'.
	self deny: 'colou?r' matches: 'colouur'!
testCounts
	self assert: 'a{3}' matches: 'aaa'.
	self deny: 'a{3}' matches: 'aa'.
	self assert: 'a{2,4}' matches: 'aaa'.
	self deny: 'a{2,4}' matches: 'aaaaa'.
	self assert: 'a{2,}' matches: 'aaaaaa'.
	self deny: 'a{2,}' matches: 'a'!
testBraceThatIsNotACount
	"a brace with nothing countable after it is just a character"
	self assert: 'a{b' matches: 'a{b'.
	self assert: 'x{}' matches: 'x{}'!
testGreedyAndLazy
	self assert: (self firstIn: '<a><b>' of: '<.+>') equals: '<a><b>'.
	self assert: (self firstIn: '<a><b>' of: '<.+?>') equals: '<a>'.
	self assert: (self firstIn: 'aaa' of: 'a+?') equals: 'a'!
testRepeatedGroup
	self assert: '(ab)+' matches: 'ababab'.
	self deny: '(ab)+' matches: 'ababa'.
	self assert: '(ab|cd)*' matches: 'abcdab'!
testRepeatOfSomethingEmpty
	"an inner match of nothing must not loop for ever"
	self assert: '(a*)*' matches: 'aaa'.
	self assert: '(a*)*' matches: ''! !

!RegexTest methodsFor: 'groups, alternation and anchors'!
testAlternation
	self assert: 'cat|dog' matches: 'cat'.
	self assert: 'cat|dog' matches: 'dog'.
	self deny: 'cat|dog' matches: 'cow'.
	self assert: 'a(b|c|d)e' matches: 'ace'!
testAlternationPrefersTheFirstBranchThatWorks
	self assert: (self firstIn: 'abcd' of: 'ab|abcd') equals: 'ab'!
testGroupsAreCaptured
	| m |
	m := '2026-11-19' regexMatch: '(\d{4})-(\d\d)-(\d\d)'.
	self assert: m groupCount equals: 3.
	self assert: (m at: 0) equals: '2026-11-19'.
	self assert: (m at: 1) equals: '2026'.
	self assert: (m at: 2) equals: '11'.
	self assert: (m at: 3) equals: '19'.
	self assert: m groups equals: #('2026' '11' '19')!
testGroupThatTookNoPart
	| m |
	m := 'ac' regexMatch: 'a(b)?c'.
	self assert: m notNil.
	self assert: (m at: 1) isNil!
testNonCapturingGroup
	| m |
	m := 'abab' regexMatch: '(?:ab)+'.
	self assert: m value equals: 'abab'.
	self assert: m groupCount equals: 0!
testBackReference
	self assert: '(abc)\1' matches: 'abcabc'.
	self deny: '(abc)\1' matches: 'abcabd'.
	self assert: (self firstIn: 'say say what' of: '(\w+) \1') equals: 'say say'!
testAnchors
	self assert: ((Regex on: '^abc') matchesPrefixOf: 'abcdef') notNil.
	self assert: ((Regex on: '^bc') search: 'abcdef') isNil.
	self assert: (self firstIn: 'one two' of: '\w+$') equals: 'two'!
testWordBoundary
	self assert: ('the cat sat' allRegexMatches: '\bs\w+') equals: (OrderedCollection with: 'sat').
	self assert: ('abc' allRegexMatches: '\Bb\B') equals: (OrderedCollection with: 'b')! !

!RegexTest methodsFor: 'searching'!
testSearchFindsTheLeftmostMatch
	| m |
	m := 'xxabyy' regexMatch: 'ab'.
	self assert: m value equals: 'ab'.
	self assert: m start equals: 3.
	self assert: m stop equals: 4.
	self assert: m size equals: 2.
	self assert: m prematch equals: 'xx'.
	self assert: m postmatch equals: 'yy'!
testSearchThatFindsNothing
	self assert: ('hello' regexMatch: 'z+') isNil!
testSearchFrom
	self assert: (((Regex on: 'a') search: 'aaa' from: 2) start) equals: 2!
testAllMatches
	self assert: ('x=1; y=22; z=333' allRegexMatches: '\d+') asArray equals: #('1' '22' '333').
	self assert: ((Regex on: '\d+') occurrencesIn: 'a1b22c333') equals: 3!
testMatchesInDo
	| seen |
	seen := OrderedCollection new.
	(Regex on: '\w+') matchesIn: 'a bb ccc' do: [:m | seen add: m start].
	self assert: seen asArray equals: #(1 3 6)!
testMatchesDoNotOverlap
	self assert: ('aaaa' allRegexMatches: 'aa') asArray equals: #('aa' 'aa')!
testEmptyMatchesStillAdvance
	self assert: ('abc' allRegexMatches: 'x*') size equals: 4!
testIncludesRegex
	self assert: ('hello world' includesRegex: 'o w').
	self deny: ('hello world' includesRegex: '\d')!
testMatchesPrefixOf
	self assert: ((Regex on: '\d+') matchesPrefixOf: '123abc') value equals: '123'.
	self assert: ((Regex on: '\d+') matchesPrefixOf: 'abc123') isNil! !

!RegexTest methodsFor: 'replacing and splitting'!
testReplaceAll
	self assert: ('a1b2c3' copyWithRegex: '\d' replacedWith: '#') equals: 'a#b#c#'.
	self assert: ('hello' copyWithRegex: 'z' replacedWith: '#') equals: 'hello'!
testReplaceWithGroups
	self assert: ('John Smith' copyWithRegex: '(\w+) (\w+)' replacedWith: '\2, \1') equals: 'Smith, John'.
	self assert: ('ab' copyWithRegex: 'a' replacedWith: '[\0]') equals: '[a]b'!
testReplaceABackslash
	self assert: ('a' copyWithRegex: 'a' replacedWith: '\\') equals: '\'!
testReplaceFirst
	self assert: ('aaa bbb' copyWithFirstRegex: '\w+' replacedWith: 'X') equals: 'X bbb'!
testReplaceUsingABlock
	self assert: ('a1b22' copyWithRegex: '\d+' matchesTranslatedUsing: [:m | m value size]) equals: 'a1b2'!
testSplit
	self assert: ('a, b,c ,d' splitOnRegex: '\s*,\s*') asArray equals: #('a' 'b' 'c' 'd').
	self assert: ('one' splitOnRegex: ',') asArray equals: #('one')!
testSplitKeepsEmptyPieces
	self assert: ('a,,b' splitOnRegex: ',') asArray equals: #('a' '' 'b')! !

!RegexTest methodsFor: 'case'!
testIgnoringCase
	self assert: ('HeLLo' matchesRegexIgnoringCase: 'hello').
	self deny: ('HeLLo' matchesRegex: 'hello').
	self assert: ((Regex on: '[a-c]+' ignoreCase: true) matches: 'ABC').
	self assert: ((Regex on: '(ab)\1' ignoreCase: true) matches: 'abAB')!
testIgnoreCaseMessage
	self assert: ((Regex on: 'abc') ignoreCase matches: 'ABC')! !

!RegexTest methodsFor: 'the object itself'!
testPatternIsRemembered
	self assert: (Regex on: 'a+b') identicalTo: (Regex on: 'a+b').
	self deny: (Regex on: 'a+b') identicalTo: (Regex on: 'a+b' ignoreCase: true)!
testPrinting
	self assert: (Regex on: 'a+b') printString equals: '/a+b/'.
	self assert: (Regex on: 'x' ignoreCase: true) printString equals: '/x/i'!
testAccessors
	| r |
	r := Regex on: '(a)(b)'.
	self assert: r pattern equals: '(a)(b)'.
	self assert: r groupCount equals: 2.
	self deny: r ignoresCase!
testAsRegex
	self assert: ('\d+' asRegex matches: '42').
	self assert: (#testing asRegex matches: 'testing')! !

!RegexTest methodsFor: 'errors'!
testUnclosedGroup
	self should: [Regex on: 'a('] raise: RegexError!
testUnmatchedCloseParen
	self should: [Regex on: 'a)'] raise: RegexError!
testNothingToRepeat
	self should: [Regex on: '*a'] raise: RegexError!
testBackwardsCount
	self should: [Regex on: 'a{3,1}'] raise: RegexError!
testUnclosedClass
	self should: [Regex on: '[abc'] raise: RegexError!
testTheErrorSaysWhereItWas
	| text |
	text := [Regex on: 'a(' ] on: RegexError do: [:e | e messageText].
	self assert: (text includesSubstring: 'a(')! !

!RegexTest methodsFor: 'the step budget'!
testARunawayPatternGivesUp
	| saved |
	saved := Regex stepLimit.
	Regex stepLimit: 2000.
	[self should: [(Regex on: '(a+)+b') matches: 'aaaaaaaaaaaaaaaaaaaaaaaaX'] raise: RegexError]
		ensure: [Regex stepLimit: saved]!
testTheBudgetIsPerAttempt
	"searching a long string is many attempts, so it must not run the budget out by itself"
	| saved |
	saved := Regex stepLimit.
	Regex stepLimit: 2000.
	[self assert: ((String new: 3000 withAll: $a) allRegexMatches: 'a') size equals: 3000]
		ensure: [Regex stepLimit: saved]! !

!RegexTest methodsFor: 'the workspace'!
toolOn: aPattern over: aSubject
	^RegexTool evaluate: aPattern, (String with: Character lf), aSubject!
testToolReportsAMatch
	| report |
	report := self toolOn: 'a+' over: 'xaaay'.
	self assert: (report includesSubstring: '2..4').
	self assert: (report includesSubstring: '1 match in all')!
testToolReportsNoMatch
	self assert: ((self toolOn: 'z+' over: 'abc') includesSubstring: '(no match)')!
testToolShowsTheGroups
	| report |
	report := self toolOn: '(\w+)@(\w+)' over: 'me@here'.
	self assert: (report includesSubstring: '2 group(s)').
	self assert: (report includesSubstring: '1=''me''').
	self assert: (report includesSubstring: '2=''here''')!
testToolReadsSlashesAndFlags
	self assert: (RegexTool regexFor: '/ab/i') ignoresCase.
	self deny: (RegexTool regexFor: '/ab/') ignoresCase.
	self assert: (RegexTool regexFor: '/ab/i') pattern equals: 'ab'.
	self assert: (RegexTool regexFor: 'a/b') pattern equals: 'a/b'!
testToolOnABadPattern
	self assert: ((RegexTool evaluate: 'a(') includesSubstring: 'could not read the pattern')!
testToolOnNothing
	self assert: (RegexTool evaluate: '  ') equals: 'select a pattern, and under it the lines to try it on'.
	self assert: ((RegexTool evaluate: 'a+') includesSubstring: 'nothing under it')!
testToolSplitsLines
	self assert: (RegexTool linesOf: ('a', (String with: Character lf), 'b')) asArray equals: #('a' 'b')! !
