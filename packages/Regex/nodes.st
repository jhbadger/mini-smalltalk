"The pieces a compiled pattern is made of, and how each one matches.

Every node answers  matchAt: position then: aBlock  with the position just after the whole rest of the match,
or nil when it cannot match there. The block is the continuation: it is given the position after this node and
answers nil to make the node try another way, which is what gives backtracking."

Object subclass: #RxNode instanceVariableNames: '' classVariableNames: '' category: 'Regex-Nodes'!
RxNode subclass: #RxSingle instanceVariableNames: '' classVariableNames: '' category: 'Regex-Nodes'!
RxSingle subclass: #RxChar instanceVariableNames: 'char' classVariableNames: '' category: 'Regex-Nodes'!
RxSingle subclass: #RxAny instanceVariableNames: '' classVariableNames: '' category: 'Regex-Nodes'!
RxSingle subclass: #RxClass instanceVariableNames: 'members ranges negated' classVariableNames: '' category: 'Regex-Nodes'!
RxNode subclass: #RxSequence instanceVariableNames: 'children' classVariableNames: '' category: 'Regex-Nodes'!
RxNode subclass: #RxAlternation instanceVariableNames: 'children' classVariableNames: '' category: 'Regex-Nodes'!
RxNode subclass: #RxGroup instanceVariableNames: 'child index' classVariableNames: '' category: 'Regex-Nodes'!
RxNode subclass: #RxRepeat instanceVariableNames: 'child min max greedy' classVariableNames: '' category: 'Regex-Nodes'!
RxNode subclass: #RxAnchor instanceVariableNames: 'kind' classVariableNames: '' category: 'Regex-Nodes'!
RxNode subclass: #RxBackReference instanceVariableNames: 'index' classVariableNames: '' category: 'Regex-Nodes'!
Error subclass: #RegexError instanceVariableNames: '' classVariableNames: '' category: 'Regex'!

!RxNode methodsFor: 'matching'!
matchAt: pos then: aBlock
	^self subclassResponsibility!
matcher
	"the RxMatcher driving this match, set before matching starts"
	^RxMatcher current!
printOn: aStream
	aStream nextPutAll: self class name asString! !

"---- nodes that match exactly one character ----"

!RxSingle methodsFor: 'matching'!
matches: aCharacter
	^self subclassResponsibility!
matchAt: pos then: aBlock
	| m |
	m := self matcher.
	m step.
	pos > m subjectSize ifTrue: [^nil].
	(self matches: (m at: pos)) ifFalse: [^nil].
	^aBlock value: pos + 1!
isSingle
	^true! !

!RxNode methodsFor: 'testing'!
isSingle
	"true for a node that always consumes exactly one character, which lets repetition run without recursion"
	^false! !

!RxChar class methodsFor: 'instance creation'!
on: aCharacter
	^self basicNew setChar: aCharacter! !

!RxChar methodsFor: 'matching'!
setChar: aCharacter
	char := aCharacter!
char
	^char!
matches: aCharacter
	^self matcher sameCharacter: char as: aCharacter!
printOn: aStream
	aStream nextPutAll: 'char('; nextPut: char; nextPut: $)! !

!RxAny methodsFor: 'matching'!
matches: aCharacter
	"the dot matches anything but a line feed"
	^aCharacter ~= Character lf! !

!RxClass class methodsFor: 'instance creation'!
negated: aBoolean
	^self basicNew setNegated: aBoolean! !

!RxClass methodsFor: 'building'!
setNegated: aBoolean
	members := OrderedCollection new. ranges := OrderedCollection new. negated := aBoolean!
add: aCharacter
	members add: aCharacter!
addFrom: a to: b
	ranges add: (Array with: a with: b)!
addAll: aString
	aString do: [:c | members add: c]!
negated
	^negated! !

!RxClass methodsFor: 'matching'!
matches: aCharacter
	^negated = (self holds: aCharacter) not!
holds: aCharacter
	| m c |
	m := self matcher.
	members do: [:each | (m sameCharacter: each as: aCharacter) ifTrue: [^true]].
	ranges do: [:r |
		((m orderOf: aCharacter) between: (m orderOf: (r at: 1)) and: (m orderOf: (r at: 2))) ifTrue: [^true].
		m ignoresCase ifTrue: [
			c := aCharacter asLowercase.
			(c value between: (r at: 1) asLowercase value and: (r at: 2) asLowercase value) ifTrue: [^true].
			c := aCharacter asUppercase.
			(c value between: (r at: 1) asUppercase value and: (r at: 2) asUppercase value) ifTrue: [^true]]].
	^false! !

"---- nodes built from other nodes ----"

!RxSequence class methodsFor: 'instance creation'!
withAll: aCollection
	^self basicNew setChildren: aCollection asArray! !

!RxSequence methodsFor: 'matching'!
setChildren: anArray
	children := anArray!
children
	^children!
matchAt: pos then: aBlock
	^self matchFrom: 1 at: pos then: aBlock!
matchFrom: i at: pos then: aBlock
	i > children size ifTrue: [^aBlock value: pos].
	^(children at: i) matchAt: pos then: [:p | self matchFrom: i + 1 at: p then: aBlock]! !

!RxAlternation class methodsFor: 'instance creation'!
withAll: aCollection
	^self basicNew setChildren: aCollection asArray! !

!RxAlternation methodsFor: 'matching'!
setChildren: anArray
	children := anArray!
children
	^children!
matchAt: pos then: aBlock
	self matcher step.
	children do: [:c |
		| r |
		r := c matchAt: pos then: aBlock.
		r notNil ifTrue: [^r]].
	^nil! !

!RxGroup class methodsFor: 'instance creation'!
on: aNode index: anIndexOrNil
	^self basicNew setChild: aNode index: anIndexOrNil! !

!RxGroup methodsFor: 'matching'!
setChild: aNode index: anIndexOrNil
	child := aNode. index := anIndexOrNil!
child
	^child!
index
	^index!
matchAt: pos then: aBlock
	| m savedStart savedStop r |
	index isNil ifTrue: [^child matchAt: pos then: aBlock].
	m := self matcher.
	savedStart := m startOfGroup: index.
	savedStop := m stopOfGroup: index.
	r := child matchAt: pos then: [:p |
		m setGroup: index from: pos to: p.
		aBlock value: p].
	r isNil ifTrue: [m setGroup: index from: savedStart to: savedStop].
	^r! !

!RxRepeat class methodsFor: 'instance creation'!
on: aNode min: aMin max: aMax greedy: aBoolean
	"aMax is nil for no limit"
	^self basicNew setChild: aNode min: aMin max: aMax greedy: aBoolean! !

!RxRepeat methodsFor: 'accessing'!
setChild: aNode min: aMin max: aMax greedy: aBoolean
	child := aNode. min := aMin. max := aMax. greedy := aBoolean!
child
	^child!
min
	^min!
max
	^max!
isGreedy
	^greedy! !

!RxRepeat methodsFor: 'matching'!
matchAt: pos then: aBlock
	"a repetition of a single-character node runs as a loop; anything else recurses"
	child isSingle ifTrue: [^self matchSingleAt: pos then: aBlock].
	^greedy
		ifTrue: [self matchGreedyAt: pos count: 0 then: aBlock]
		ifFalse: [self matchLazyAt: pos count: 0 then: aBlock]!
matchSingleAt: pos then: aBlock
	"count how many the child matches from here, then hand back the longest (or shortest) first"
	| m n limit p r |
	m := self matcher.
	n := 0.
	limit := max ifNil: [m subjectSize - pos + 1] ifNotNil: [:x | x min: m subjectSize - pos + 1].
	[n < limit and: [child matches: (m at: pos + n)]] whileTrue: [n := n + 1].
	m step: n + 1.
	n < min ifTrue: [^nil].
	greedy
		ifTrue: [
			p := n.
			[p >= min] whileTrue: [
				r := aBlock value: pos + p.
				r notNil ifTrue: [^r].
				p := p - 1]]
		ifFalse: [
			p := min.
			[p <= n] whileTrue: [
				r := aBlock value: pos + p.
				r notNil ifTrue: [^r].
				p := p + 1]].
	^nil!
matchGreedyAt: pos count: n then: aBlock
	| r |
	self matcher step.
	(max isNil or: [n < max]) ifTrue: [
		r := child matchAt: pos then: [:p |
			p = pos ifTrue: [nil] ifFalse: [self matchGreedyAt: p count: n + 1 then: aBlock]].
		r notNil ifTrue: [^r]].
	n >= min ifTrue: [^aBlock value: pos].
	^nil!
matchLazyAt: pos count: n then: aBlock
	| r |
	self matcher step.
	n >= min ifTrue: [
		r := aBlock value: pos.
		r notNil ifTrue: [^r]].
	(max isNil or: [n < max]) ifTrue: [
		^child matchAt: pos then: [:p |
			p = pos ifTrue: [nil] ifFalse: [self matchLazyAt: p count: n + 1 then: aBlock]]].
	^nil! !

"---- anchors and back references ----"

!RxAnchor class methodsFor: 'instance creation'!
kind: aSymbol
	"#start, #end, #wordBoundary or #notWordBoundary"
	^self basicNew setKind: aSymbol! !

!RxAnchor methodsFor: 'matching'!
setKind: aSymbol
	kind := aSymbol!
kind
	^kind!
matchAt: pos then: aBlock
	^(self holdsAt: pos) ifTrue: [aBlock value: pos] ifFalse: [nil]!
holdsAt: pos
	| m |
	m := self matcher.
	kind == #start ifTrue: [^pos = 1].
	kind == #end ifTrue: [^pos = (m subjectSize + 1)].
	kind == #wordBoundary ifTrue: [^self isBoundaryAt: pos].
	kind == #notWordBoundary ifTrue: [^(self isBoundaryAt: pos) not].
	^false!
isBoundaryAt: pos
	| m before after |
	m := self matcher.
	before := pos > 1 and: [m isWordCharacter: (m at: pos - 1)].
	after := pos <= m subjectSize and: [m isWordCharacter: (m at: pos)].
	^before ~= after! !

!RxBackReference class methodsFor: 'instance creation'!
index: anInteger
	^self basicNew setIndex: anInteger! !

!RxBackReference methodsFor: 'matching'!
setIndex: anInteger
	index := anInteger!
index
	^index!
matchAt: pos then: aBlock
	| m start stop size |
	m := self matcher.
	start := m startOfGroup: index.
	stop := m stopOfGroup: index.
	start isNil ifTrue: [^nil].
	size := stop - start.
	pos + size - 1 > m subjectSize ifTrue: [^nil].
	1 to: size do: [:k |
		(m sameCharacter: (m at: start + k - 1) as: (m at: pos + k - 1)) ifFalse: [^nil]].
	^aBlock value: pos + size! !
