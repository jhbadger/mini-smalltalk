"Newick: the parenthesised notation every phylogenetics program reads and writes.

	((A:0.1,B:0.2)95:0.05,C:0.3);

A label may be quoted with single quotes, in which case a doubled quote stands for one; an unquoted label
may not hold parentheses, commas, colons, semicolons or square brackets, and an underscore in one stands for
a space, as the format says. Square brackets hold a comment and are skipped. The number after an internal
node's closing bracket is read as its support; a name there is kept as its label."

Object subclass: #NewickReader instanceVariableNames: 'text pos' classVariableNames: '' category: 'Phylo-Newick'!
Object subclass: #NewickWriter instanceVariableNames: 'lengths support decimals quoting' classVariableNames: '' category: 'Phylo-Newick'!

"---- reading ----"

!NewickReader class methodsFor: 'reading'!
parse: aString
	"the first tree in the text"
	^self basicNew setText: aString; readTree!
parseAll: aString
	"every tree in the text, one per semicolon"
	^self basicNew setText: aString; readTrees!
readFile: aPath
	(FileStream exists: aPath) ifFalse: [^PhyloError new signal: 'no such file: ', aPath].
	^self parse: (FileStream contentsOf: aPath)!
readAllFrom: aPath
	(FileStream exists: aPath) ifFalse: [^PhyloError new signal: 'no such file: ', aPath].
	^self parseAll: (FileStream contentsOf: aPath)! !

!NewickReader methodsFor: 'private'!
setText: aString
	text := aString.
	pos := 1!
error: aMessage
	^PhyloError new signal: aMessage, ' at character ', pos printString!
atEnd
	^pos > text size!
peek
	self skipSpace.
	^self atEnd ifTrue: [nil] ifFalse: [text at: pos]!
next
	| c |
	c := self peek.
	c isNil ifTrue: [^self error: 'the tree ends too soon'].
	pos := pos + 1.
	^c!
skipSpace
	[pos <= text size and: [((text at: pos) isSeparator) or: [(text at: pos) = $[]]] whileTrue: [
		(text at: pos) = $[
			ifTrue: [self skipComment]
			ifFalse: [pos := pos + 1]]!
skipComment
	"a square-bracketed comment, which may hold brackets of its own"
	| depth c |
	depth := 0.
	[pos <= text size] whileTrue: [
		c := text at: pos.
		pos := pos + 1.
		c = $[ ifTrue: [depth := depth + 1].
		c = $] ifTrue: [depth := depth - 1. depth = 0 ifTrue: [^self]]]!
accept: aCharacter
	self peek = aCharacter ifFalse: [^false].
	pos := pos + 1.
	^true! !

!NewickReader methodsFor: 'reading'!
readTree
	| node |
	self peek isNil ifTrue: [^PhyloError new signal: 'there is no tree here'].
	node := self readNode.
	self accept: $;.
	^PhyloTree on: node!
readTrees
	| out |
	out := OrderedCollection new.
	[self peek notNil] whileTrue: [out add: self readTree].
	^out!
readNode
	| node |
	(self peek = $()
		ifTrue: [node := self readInternal]
		ifFalse: [node := PhyloNode named: self readLabel].
	self readLengthInto: node.
	^node!
readInternal
	| node |
	self expect: $(.
	node := PhyloNode new.
	[node add: self readNode.
	 self accept: $,] whileTrue.
	self expect: $).
	self readNodeLabelInto: node.
	^node!
expect: aCharacter
	(self accept: aCharacter) ifFalse: [
		^self error: 'expected ', (String with: aCharacter), ' but found ',
			(self peek ifNil: ['the end'] ifNotNil: [:c | String with: c])]!
readNodeLabelInto: aNode
	"what stands after the closing bracket: a number is the support, anything else is a label"
	| raw |
	raw := self readLabel.
	raw isEmpty ifTrue: [^aNode].
	(self looksNumeric: raw)
		ifTrue: [aNode support: raw asNumber]
		ifFalse: [aNode label: raw].
	^aNode!
readLengthInto: aNode
	(self accept: $:) ifFalse: [^aNode].
	aNode branchLength: self readNumber.
	^aNode!
looksNumeric: aString
	| seen |
	seen := false.
	aString do: [:c |
		c isDigit
			ifTrue: [seen := true]
			ifFalse: [(c = $. or: [c = $- or: [c = $+ or: [c = $e or: [c = $E]]]]) ifFalse: [^false]]].
	^seen!
readNumber
	| start |
	self skipSpace.
	start := pos.
	[pos <= text size and: [self isNumberCharacter: (text at: pos)]] whileTrue: [pos := pos + 1].
	pos = start ifTrue: [^self error: 'a branch length was expected'].
	^(text copyFrom: start to: pos - 1) asNumber!
isNumberCharacter: c
	^c isDigit or: [c = $. or: [c = $- or: [c = $+ or: [c = $e or: [c = $E]]]]]!
readLabel
	self skipSpace.
	self peek = $' ifTrue: [^self readQuotedLabel].
	^self readBareLabel!
readBareLabel
	| start raw |
	start := pos.
	[pos <= text size and: [self isLabelCharacter: (text at: pos)]] whileTrue: [pos := pos + 1].
	raw := (text copyFrom: start to: pos - 1) copy.
	raw replaceAll: $_ with: (Character value: 32).
	^raw!
isLabelCharacter: c
	c isSeparator ifTrue: [^false].
	^('(),:;[]''' includes: c) not!
readQuotedLabel
	| out c |
	self expect: $'.
	out := WriteStream on: String new.
	[pos <= text size] whileTrue: [
		c := text at: pos.
		pos := pos + 1.
		c = $'
			ifTrue: [
				(pos <= text size and: [(text at: pos) = $'])
					ifTrue: [out nextPut: $'. pos := pos + 1]
					ifFalse: [^out contents]]
			ifFalse: [out nextPut: c]].
	^self error: 'the quoted label never ends'! !

"---- writing ----"

!NewickWriter class methodsFor: 'writing'!
new
	^self basicNew setUp!
write: aTree
	^self new write: aTree!
write: aTree toFile: aPath
	^self new write: aTree toFile: aPath! !

!NewickWriter methodsFor: 'private'!
setUp
	lengths := true.
	support := true.
	quoting := true.
	decimals := 6! !

!NewickWriter methodsFor: 'options'!
lengths: aBoolean
	"write the branch lengths"
	lengths := aBoolean!
support: aBoolean
	"write the support values where an internal label would go"
	support := aBoolean!
quoting: aBoolean
	"quote a label that holds something the format would choke on"
	quoting := aBoolean!
decimals: anInteger
	decimals := anInteger! !

!NewickWriter methodsFor: 'writing'!
write: aTree
	| out |
	out := WriteStream on: String new.
	self write: aTree root on: out.
	out nextPut: $;.
	^out contents!
write: aTree toFile: aPath
	FileStream newFileNamed: aPath do: [:f | f nextPutAll: (self write: aTree); nl].
	^aPath!
write: aNode on: aStream
	| first |
	aNode isLeaf
		ifTrue: [aStream nextPutAll: (self labelFor: aNode label)]
		ifFalse: [
			aStream nextPut: $(.
			first := true.
			aNode children do: [:each |
				first ifFalse: [aStream nextPut: $,].
				first := false.
				self write: each on: aStream].
			aStream nextPut: $).
			self writeInternalLabelOf: aNode on: aStream].
	(lengths and: [aNode hasBranchLength]) ifTrue: [
		aStream nextPut: $:; nextPutAll: (self numberFor: aNode branchLength)]!
writeInternalLabelOf: aNode on: aStream
	aNode label notNil ifTrue: [^aStream nextPutAll: (self labelFor: aNode label)].
	(support and: [aNode hasSupport]) ifTrue: [aStream nextPutAll: (self numberFor: aNode support)]!
numberFor: aNumber
	| text |
	aNumber isInteger ifTrue: [^aNumber printString].
	text := aNumber asFloat printShowingDecimalPlaces: decimals.
	"drop the zeroes the format does not need, but keep one digit after the point"
	[text size > 3 and: [text last = $0 and: [(text at: text size - 1) ~= $.]]]
		whileTrue: [text := text copyFrom: 1 to: text size - 1].
	^text!
labelFor: aLabel
	| text |
	text := (aLabel ifNil: ['']) asString copy.
	quoting ifFalse: [^text].
	(self needsQuoting: text) ifFalse: [
		text replaceAll: (Character value: 32) with: $_.
		^text].
	^'''', (self doubleQuotesIn: text), ''''!
needsQuoting: aString
	aString isEmpty ifTrue: [^false].
	aString do: [:c | ('(),:;[]''' includes: c) ifTrue: [^true]].
	^false!
doubleQuotesIn: aString
	| out |
	out := WriteStream on: String new.
	aString do: [:c | c = $' ifTrue: [out nextPutAll: ''''''] ifFalse: [out nextPut: c]].
	^out contents! !
