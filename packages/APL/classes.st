"The classes of the APL system: the error, the array and its boxes, the three kinds of function (verbs, adverbs and
conjunctions), the library of primitives and the session that evaluates sentences. Their methods are in array.st,
words.st, parser.st, verbs.st, prims1.st, prims2.st, prims3.st, display.st and api.st."

Error subclass: #APLError instanceVariableNames: '' classVariableNames: '' category: 'APL'!

Object subclass: #APLBox instanceVariableNames: 'contents' classVariableNames: '' category: 'APL'!

Object subclass: #APLArray instanceVariableNames: 'shape data proto' classVariableNames: '' category: 'APL'!

Object subclass: #APLVerb
	instanceVariableNames: 'name display monad dyad mr lr rr amon adyad inverse identity foldOf'
	classVariableNames: '' category: 'APL'!

Object subclass: #APLAdverb instanceVariableNames: 'name block' classVariableNames: '' category: 'APL'!

Object subclass: #APLConj instanceVariableNames: 'name block' classVariableNames: '' category: 'APL'!

Object subclass: #APLLexer instanceVariableNames: 'src pos tokens' classVariableNames: 'Inflected' category: 'APL'!

Object subclass: #APLFormat instanceVariableNames: '' classVariableNames: '' category: 'APL'!

Object subclass: #APLPrims instanceVariableNames: '' classVariableNames: 'Table Cap' category: 'APL'!

Object subclass: #APL
	instanceVariableNames: 'names frames selfStack flow precision assigned lastValue term'
	classVariableNames: 'Default Current Generator Debug'
	category: 'APL'!

Object subclass: #APLTool instanceVariableNames: '' classVariableNames: 'Session' category: 'APL'!

!APLError class methodsFor: 'signalling'!
domain
	^self new signal: 'domain error'!
length
	^self new signal: 'length error'!
rank
	^self new signal: 'rank error'!
index
	^self new signal: 'index error'!
syntax
	^self new signal: 'syntax error'!
value: aName
	^self new signal: 'value error: ', aName!
valence
	^self new signal: 'valence error'!
nonce
	^self new signal: 'nonce error'!
limit
	^self new signal: 'limit error'!
message: aString
	^self new signal: aString! !

!APLBox class methodsFor: 'instance creation'!
on: anArray
	^self basicNew setContents: anArray! !

!APLBox methodsFor: 'accessing'!
setContents: anArray
	contents := anArray!
contents
	^contents!
= other
	^(other class == APLBox) and: [contents match: other contents]!
hash
	^contents size hash!
printOn: aStream
	aStream nextPutAll: 'a box'! !
