"The public face of APL: evaluating text, a session of your own, reading and setting names, calling a verb on Smalltalk
objects, and defining a verb with a Smalltalk block."

!APL class methodsFor: 'evaluating'!
eval: aString
	"run APL text in the default session and answer what it would print"
	^self default eval: aString!
evalValue: aString
	"run APL text in the default session and answer the value of its last sentence (an APLArray, or a verb)"
	^self default evalValue: aString!
lines: aString
	"what eval: prints, as an Array of its lines"
	^self default lines: aString!
smalltalkValue: aString
	"run APL text and answer its value as a Smalltalk number, string or Array"
	^self default smalltalkValue: aString!
call: verbText on: anObject
	^self default call: verbText on: anObject!
call: verbText on: x and: y
	^self default call: verbText on: x and: y!
version
	^'1.0'!
directory
	^Smalltalk packagePath: 'APL'!
glyphs
	"the APL glyphs that can be typed for the J spellings, as an Array of pairs (glyph spelling)"
	^APLLexer glyphPairs! !

!APL methodsFor: 'evaluating'!
eval: aString
	"run the text, a sentence per line, and answer what each would print (one after the other, line by line)"
	| ws |
	ws := WriteStream on: String new.
	self run: aString display: ws.
	^ws contents!
evalValue: aString
	^self valueOf: aString!
lines: aString
	| t out cur |
	t := self eval: aString.
	out := OrderedCollection new.
	cur := WriteStream on: String new.
	t do: [:c |
		c = Character lf
			ifTrue: [out add: cur contents. cur := WriteStream on: String new]
			ifFalse: [cur nextPut: c]].
	out add: cur contents.
	^out asArray!
smalltalkValue: aString
	| v |
	v := self valueOf: aString.
	v class == APLArray ifFalse: [^APLError domain].
	^v asSmalltalk!
at: aName
	"the value of a name (an APLArray or a function)"
	^names at: aName asString ifAbsent: [APLError value: aName]!
at: aName put: anObject
	"set a name to an APL value, or to a Smalltalk number, string or Array"
	| v |
	v := (anObject class == APLVerb or: [anObject class == APLAdverb or: [anObject class == APLConj]])
		ifTrue: [anObject] ifFalse: [APLArray fromSmalltalk: anObject].
	names at: aName asString put: v.
	^v!
includesName: aName
	^names includesKey: aName asString!
define: aName as: sourceText
	"aName =: sourceText"
	^self evalValue: aName, ' =: ', sourceText!
defineVerb: aName monad: mBlock dyad: dBlock
	"a verb made of Smalltalk blocks, which get and answer numbers, strings and Arrays"
	| v |
	v := APLVerb derived: aName
		monad: (mBlock isNil ifTrue: [nil] ifFalse: [[:y | APLArray fromSmalltalk: (mBlock value: y asSmalltalk)]])
		dyad: (dBlock isNil ifTrue: [nil] ifFalse: [[:x :y | APLArray fromSmalltalk: (dBlock value: x asSmalltalk value: y asSmalltalk)]]).
	names at: aName put: v.
	^v!
verbFor: verbText
	| v |
	v := self valueOf: verbText.
	v class == APLVerb ifFalse: [^APLError message: 'domain error: not a verb'].
	^v!
call: verbText on: anObject
	"apply the verb written in verbText to a Smalltalk object and answer a Smalltalk object"
	| prev r |
	prev := Current.
	Current := self.
	r := [self guard: [(self verbFor: verbText) monad: (APLArray fromSmalltalk: anObject)]] ensure: [Current := prev].
	^r asSmalltalk!
call: verbText on: x and: y
	| prev r |
	prev := Current.
	Current := self.
	r := [self guard: [(self verbFor: verbText) dyad: (APLArray fromSmalltalk: x) y: (APLArray fromSmalltalk: y)]] ensure: [Current := prev].
	^r asSmalltalk! !

!Object methodsFor: 'APL'!
asAPL
	"this number, character, string or collection as an APLArray"
	^APLArray fromSmalltalk: self! !
