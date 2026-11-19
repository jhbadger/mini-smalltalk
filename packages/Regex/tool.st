"A workspace for trying a pattern out: the first line of what you select is the pattern, the rest is the text
to run it over, and print it answers a report of what matched where."

Object subclass: #RegexTool instanceVariableNames: '' classVariableNames: '' category: 'Regex'!

!RegexTool class methodsFor: 'opening'!
open
	Smalltalk openTool: 'RegexTool' title: 'Regex' contents: self welcomeText!
welcomeText
	^'"Select a pattern and the lines under it, then print it (or do it).
The first line is the pattern - write it bare, or as /pattern/ with an i after
the closing slash to ignore case.  Every line below it is tried against it."

(\w+)@([\w.]+)
write to me@example.com
and to someone.else@sub.example.org
no address on this line

/^\s*(\w+)\s*:\s*(.*?)\s*$/
  name  :  Ada Lovelace
  born  :  1815

/[acgt]+/i
ACGTnnnACGT
' ! !

!RegexTool class methodsFor: 'evaluating'!
evaluate: aString
	"the report for the selected text: its first line is the pattern, the rest the subject lines"
	| lines pattern regex |
	lines := (self linesOf: aString) reject: [:each | each trimBoth isEmpty].
	lines isEmpty ifTrue: [^'select a pattern, and under it the lines to try it on'].
	pattern := lines first trimBoth.
	regex := [self regexFor: pattern]
		on: RegexError
		do: [:e | ^'could not read the pattern: ', (e messageText ifNil: ['?'])].
	^self report: regex over: (lines copyFrom: 2 to: lines size)!
linesOf: aString
	| out start |
	out := OrderedCollection new.
	start := 1.
	1 to: aString size do: [:i |
		(aString at: i) = Character lf ifTrue: [out add: (aString copyFrom: start to: i - 1). start := i + 1]].
	out add: (aString copyFrom: start to: aString size).
	^out!
regexFor: aLine
	"a bare pattern, or /pattern/ with an i after it to ignore case"
	| close |
	(aLine size >= 2 and: [aLine first = $/]) ifFalse: [^Regex on: aLine].
	close := nil.
	aLine size to: 2 by: -1 do: [:i | (close isNil and: [(aLine at: i) = $/]) ifTrue: [close := i]].
	close isNil ifTrue: [^Regex on: aLine].
	^Regex on: (aLine copyFrom: 2 to: close - 1)
		ignoreCase: ((aLine copyFrom: close + 1 to: aLine size) includes: $i)! !

!RegexTool class methodsFor: 'reporting'!
report: aRegex over: someLines
	| out total |
	out := WriteStream on: String new.
	out nextPutAll: aRegex printString.
	aRegex groupCount > 0 ifTrue: [out nextPutAll: '   '; print: aRegex groupCount; nextPutAll: ' group(s)'].
	out nl; nl.
	someLines isEmpty ifTrue: [
		out nextPutAll: 'the pattern reads, but there is nothing under it to try it on'; nl.
		^out contents].
	total := 0.
	someLines do: [:line |
		| found |
		found := aRegex matchesIn: line.
		total := total + found size.
		out nextPutAll: line; nl.
		found isEmpty
			ifTrue: [out nextPutAll: '    (no match)'; nl]
			ifFalse: [found do: [:m | self describe: m on: out]]].
	out nl; print: total; nextPutAll: (total = 1 ifTrue: [' match in all'] ifFalse: [' matches in all']); nl.
	^out contents!
describe: aMatch on: aStream
	"a rule under what matched, then the match and each of its groups"
	| text |
	aStream nextPutAll: (String new: (aMatch start - 1 max: 0) withAll: (Character value: 32)).
	aStream nextPutAll: (String new: (aMatch size max: 1)
		withAll: (aMatch isEmpty ifTrue: [$|] ifFalse: [$^])); nl.
	aStream nextPutAll: '    '; print: aMatch start; nextPutAll: '..'; print: aMatch stop;
		nextPutAll: '  '; print: aMatch value.
	1 to: aMatch groupCount do: [:i |
		text := aMatch at: i.
		aStream nextPutAll: '  '; print: i; nextPut: $=;
			nextPutAll: (text isNil ifTrue: ['-'] ifFalse: [text printString])].
	aStream nl! !
