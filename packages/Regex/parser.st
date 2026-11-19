"The pattern parser and the matcher that drives a compiled pattern over a subject."

Object subclass: #RxParser instanceVariableNames: 'pattern pos groupCount' classVariableNames: '' category: 'Regex'!
Object subclass: #RxMatcher instanceVariableNames: 'subject size starts stops ignoreCase steps limit' classVariableNames: 'Current' category: 'Regex'!

"---- the matcher: the state one attempt needs ----"

!RxMatcher class methodsFor: 'the current match'!
current
	"the matcher the nodes are running under"
	^Current!
on: aString groups: n ignoringCase: aBoolean
	^self basicNew setSubject: aString groups: n ignoringCase: aBoolean!
use: aMatcher during: aBlock
	"nodes find their matcher through RxMatcher current; matches do not nest, but restore it anyway"
	| saved |
	saved := Current.
	Current := aMatcher.
	^[aBlock value] ensure: [Current := saved]! !

!RxMatcher methodsFor: 'private'!
setSubject: aString groups: n ignoringCase: aBoolean
	subject := aString.
	size := aString size.
	ignoreCase := aBoolean.
	steps := 0.
	limit := Regex stepLimit.
	starts := Array new: n + 1.
	stops := Array new: n + 1! !

!RxMatcher methodsFor: 'the step budget'!
step
	"counted at every point a node can be entered again, so that a pattern which backtracks without
	end gives up with an error instead of hanging the system"
	^self step: 1!
step: n
	steps := steps + n.
	(limit notNil and: [steps > limit]) ifTrue: [
		^RegexError new signal: 'the match gave up after ', limit printString,
			' steps: this pattern backtracks too much (see Regex stepLimit:)'].
	^steps!
steps
	^steps!
resetSteps
	"the budget is per attempt, so searching a long string is not itself what runs it out"
	steps := 0!
limit
	^limit!
limit: anIntegerOrNil
	limit := anIntegerOrNil! !

!RxMatcher methodsFor: 'accessing'!
subject
	^subject!
subjectSize
	^size!
at: i
	^subject at: i!
ignoresCase
	^ignoreCase!
groupCount
	^starts size - 1!
startOfGroup: i
	^starts at: i + 1!
stopOfGroup: i
	^stops at: i + 1!
setGroup: i from: start to: stop
	starts at: i + 1 put: start.
	stops at: i + 1 put: stop!
clearGroups
	1 to: starts size do: [:i | starts at: i put: nil. stops at: i put: nil]!
groupStarts
	^starts!
groupStops
	^stops! !

!RxMatcher methodsFor: 'characters'!
sameCharacter: a as: b
	a == b ifTrue: [^true].
	a = b ifTrue: [^true].
	^ignoreCase and: [a asLowercase = b asLowercase]!
orderOf: aCharacter
	^aCharacter value!
isWordCharacter: aCharacter
	^aCharacter isLetter or: [aCharacter isDigit or: [aCharacter = $_]]! !

"---- the parser ----"

!RxParser class methodsFor: 'parsing'!
parse: aString
	"an Array of the root node and the number of capturing groups"
	^self basicNew parse: aString! !

!RxParser methodsFor: 'private'!
error: aMessage
	^RegexError new signal: aMessage, ' in /', pattern, '/ at ', pos printString!
atEnd
	^pos > pattern size!
peek
	^pos <= pattern size ifTrue: [pattern at: pos] ifFalse: [nil]!
peekAt: n
	^pos + n <= pattern size ifTrue: [pattern at: pos + n] ifFalse: [nil]!
next
	| c |
	c := self peek.
	c isNil ifTrue: [^self error: 'the pattern ends too soon'].
	pos := pos + 1.
	^c!
accept: aCharacter
	self peek = aCharacter ifFalse: [^false].
	pos := pos + 1.
	^true!
expect: aCharacter
	(self accept: aCharacter) ifFalse: [^self error: 'expected ', (String with: aCharacter)]! !

!RxParser methodsFor: 'parsing'!
parse: aString
	| node |
	pattern := aString. pos := 1. groupCount := 0.
	node := self parseAlternation.
	self atEnd ifFalse: [^self error: 'unexpected ', (String with: self peek)].
	^Array with: node with: groupCount!
parseAlternation
	| branches |
	branches := OrderedCollection new.
	branches add: self parseSequence.
	[self accept: $|] whileTrue: [branches add: self parseSequence].
	^branches size = 1 ifTrue: [branches first] ifFalse: [RxAlternation withAll: branches]!
parseSequence
	| items |
	items := OrderedCollection new.
	[self atEnd not and: [self peek ~= $| and: [self peek ~= $)]]] whileTrue: [items add: self parseQuantified].
	items size = 1 ifTrue: [^items first].
	^RxSequence withAll: items!
parseQuantified
	| atom |
	atom := self parseAtom.
	^self parseQuantifierOn: atom!
parseQuantifierOn: atom
	| c min max greedy |
	c := self peek.
	c isNil ifTrue: [^atom].
	(c = $* or: [c = $+ or: [c = $?]])
		ifTrue: [
			pos := pos + 1.
			c = $* ifTrue: [min := 0. max := nil].
			c = $+ ifTrue: [min := 1. max := nil].
			c = $? ifTrue: [min := 0. max := 1]]
		ifFalse: [
			c = ${ ifFalse: [^atom].
			(self looksLikeACount) ifFalse: [^atom].
			pos := pos + 1.
			min := self parseInteger.
			max := min.
			(self accept: $,) ifTrue: [max := self peek = $} ifTrue: [nil] ifFalse: [self parseInteger]].
			self expect: $}].
	greedy := (self accept: $?) not.
	(max notNil and: [max < min]) ifTrue: [^self error: 'the count runs backwards'].
	^RxRepeat on: atom min: min max: max greedy: greedy!
looksLikeACount
	"a { only starts a count when it holds digits and closes; otherwise it is an ordinary character"
	| i seen |
	i := pos + 1. seen := false.
	[i <= pattern size and: [(pattern at: i) isDigit]] whileTrue: [i := i + 1. seen := true].
	seen ifFalse: [^false].
	(i <= pattern size and: [(pattern at: i) = $,]) ifTrue: [
		i := i + 1.
		[i <= pattern size and: [(pattern at: i) isDigit]] whileTrue: [i := i + 1]].
	^i <= pattern size and: [(pattern at: i) = $}]!
parseInteger
	| n |
	n := 0.
	(self peek notNil and: [self peek isDigit]) ifFalse: [^self error: 'a number was expected'].
	[self peek notNil and: [self peek isDigit]] whileTrue: [n := n * 10 + self next digitValue].
	^n!
parseAtom
	| c |
	c := self peek.
	c isNil ifTrue: [^self error: 'the pattern ends too soon'].
	c = $( ifTrue: [^self parseGroup].
	c = $[ ifTrue: [^self parseClass].
	c = $. ifTrue: [pos := pos + 1. ^RxAny new].
	c = $^ ifTrue: [pos := pos + 1. ^RxAnchor kind: #start].
	c = $$ ifTrue: [pos := pos + 1. ^RxAnchor kind: #end].
	c = $\ ifTrue: [^self parseEscape].
	(c = $* or: [c = $+ or: [c = $?]]) ifTrue: [^self error: 'nothing to repeat'].
	c = $) ifTrue: [^self error: 'unmatched )'].
	pos := pos + 1.
	^RxChar on: c!
parseGroup
	| capturing index node |
	self expect: $(.
	capturing := true.
	(self peek = $? and: [(self peekAt: 1) = $:]) ifTrue: [pos := pos + 2. capturing := false].
	(self peek = $? and: [(self peekAt: 1) ~= $:]) ifTrue: [^self error: 'only (?: ...) is supported'].
	capturing ifTrue: [groupCount := groupCount + 1. index := groupCount].
	node := self parseAlternation.
	self expect: $).
	^RxGroup on: node index: (capturing ifTrue: [index] ifFalse: [nil])!
parseEscape
	| c |
	self expect: $\.
	c := self next.
	(c isDigit and: [c ~= $0]) ifTrue: [^RxBackReference index: c digitValue].
	c = $b ifTrue: [^RxAnchor kind: #wordBoundary].
	c = $B ifTrue: [^RxAnchor kind: #notWordBoundary].
	^self nodeForEscape: c!
nodeForEscape: c
	"the shorthand classes, the control characters, and anything else as itself"
	| class |
	c = $d ifTrue: [class := RxClass negated: false. class addFrom: $0 to: $9. ^class].
	c = $D ifTrue: [class := RxClass negated: true. class addFrom: $0 to: $9. ^class].
	c = $w ifTrue: [^self wordClassNegated: false].
	c = $W ifTrue: [^self wordClassNegated: true].
	c = $s ifTrue: [^self spaceClassNegated: false].
	c = $S ifTrue: [^self spaceClassNegated: true].
	^RxChar on: (self characterForEscape: c)!
characterForEscape: c
	c = $n ifTrue: [^Character lf].
	c = $t ifTrue: [^Character tab].
	c = $r ifTrue: [^Character value: 13].
	c = $f ifTrue: [^Character value: 12].
	c = $v ifTrue: [^Character value: 11].
	c = $a ifTrue: [^Character value: 7].
	c = $e ifTrue: [^Character value: 27].
	c = $0 ifTrue: [^Character value: 0].
	c = $x ifTrue: [^self hexEscape].
	^c!
hexEscape
	| n d |
	n := 0.
	2 timesRepeat: [
		d := self peek.
		(d notNil and: [d digitValue between: 0 and: 15]) ifTrue: [n := n * 16 + d digitValue. pos := pos + 1]].
	^Character value: n!
wordClassNegated: aBoolean
	| class |
	class := RxClass negated: aBoolean.
	class addFrom: $a to: $z; addFrom: $A to: $Z; addFrom: $0 to: $9; add: $_.
	^class!
spaceClassNegated: aBoolean
	| class |
	class := RxClass negated: aBoolean.
	class add: (Character value: 32); add: Character tab; add: Character lf; add: (Character value: 13); add: (Character value: 12); add: (Character value: 11).
	^class!
parseClass
	| class first c |
	self expect: $[.
	class := RxClass negated: (self accept: $^).
	first := true.
	[self atEnd not and: [self peek ~= $] or: [first]]] whileTrue: [
		first := false.
		c := self next.
		(c = $\ and: [self atEnd not])
			ifTrue: [self addEscapeTo: class]
			ifFalse: [
				(self peek = $- and: [(self peekAt: 1) notNil and: [(self peekAt: 1) ~= $]]])
					ifTrue: [
						pos := pos + 1.
						class addFrom: c to: (self classMemberCharacter)]
					ifFalse: [class add: c]]].
	self expect: $].
	^class!
addEscapeTo: class
	"an escape inside [...]: a shorthand class folds into this one, anything else is a literal"
	| c sub |
	c := self next.
	(c = $d or: [c = $w or: [c = $s or: [c = $D or: [c = $W or: [c = $S]]]]])
		ifTrue: [
			sub := self nodeForEscape: c.
			sub negated
				ifTrue: [^self error: 'a negated shorthand inside a class is not supported']
				ifFalse: [^self merge: sub into: class]].
	class add: (self characterForEscape: c)!
merge: aClass into: anotherClass
	aClass membersDo: [:m | anotherClass add: m].
	aClass rangesDo: [:r | anotherClass addFrom: (r at: 1) to: (r at: 2)]!
classMemberCharacter
	"the character after a - in a class, with escapes honoured"
	| c |
	c := self next.
	^c = $\ ifTrue: [self characterForEscape: self next] ifFalse: [c]! !

!RxClass methodsFor: 'building'!
membersDo: aBlock
	members do: aBlock!
rangesDo: aBlock
	ranges do: aBlock! !
