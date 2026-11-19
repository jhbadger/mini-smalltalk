"Prolog terms. Atoms are Symbols, numbers are Smalltalk numbers, Prolog strings are Strings, lists are '.'(Head, Tail) ending in the
atom '[]', compound terms are PrologStructs and variables are PrologVars. Any other Smalltalk object is an opaque constant: it unifies
only with itself (compared with =), which is how Smalltalk objects travel through Prolog (see smalltalk/2).
A PrologArg stands for the Nth variable of a stored clause (clauses are copied on use)."

Object subclass: #PrologVar instanceVariableNames: 'value id' classVariableNames: 'Counter' category: 'Prolog-Terms'!
Object subclass: #PrologStruct instanceVariableNames: 'functor args ground source pred' classVariableNames: '' category: 'Prolog-Terms'!
Object subclass: #PrologArg instanceVariableNames: 'index' classVariableNames: '' category: 'Prolog-Terms'!
Error subclass: #PrologThrow instanceVariableNames: 'ball' classVariableNames: '' category: 'Prolog-Terms'!
Error subclass: #PrologHalt instanceVariableNames: 'code' classVariableNames: '' category: 'Prolog-Terms'!

!Object methodsFor: 'prolog'!
plDeref
	^self! !

!PrologVar class methodsFor: 'instance creation'!
new
	Counter := (Counter ifNil: [0]) + 1.
	^self basicNew setId: Counter! !

!PrologVar methodsFor: 'accessing'!
setId: anInteger
	id := anInteger!
id
	^id!
value
	^value!
value: aTerm
	value := aTerm!
isUnbound
	^value isNil!
plDeref
	"follow the chain of bindings to an unbound variable or a non-variable"
	| t |
	t := self.
	[t class == PrologVar and: [t value notNil]] whileTrue: [t := t value].
	^t!
printOn: aStream
	aStream nextPutAll: '_G'; print: id! !

!PrologArg class methodsFor: 'instance creation'!
index: anInteger
	^self basicNew setIndex: anInteger! !

!PrologArg methodsFor: 'accessing'!
setIndex: anInteger
	index := anInteger!
index
	^index!
printOn: aStream
	aStream nextPutAll: '_A'; print: index! !

!PrologStruct class methodsFor: 'instance creation'!
functor: aSymbol args: anArray
	^self basicNew setFunctor: aSymbol args: anArray!
functor: aSymbol with: a
	^self functor: aSymbol args: (Array with: a)!
functor: aSymbol with: a with: b
	^self functor: aSymbol args: (Array with: a with: b)!
functor: aSymbol with: a with: b with: c
	^self functor: aSymbol args: (Array with: a with: b with: c)!
list: aCollection
	"a Prolog list of the elements"
	^self list: aCollection tail: #'[]'!
list: aCollection tail: aTerm
	| l |
	l := aTerm.
	aCollection asArray reverseDo: [:e | l := self functor: #'.' with: e with: l].
	^l! !

!PrologStruct methodsFor: 'predicate cache'!
source
	"the stored clause term this goal was copied from (nil for a term built at run time)"
	^source!
source: aStruct
	source := aStruct!
cachedPredicate
	^pred!
cachedPredicate: aPredicate
	pred := aPredicate! !

!PrologStruct methodsFor: 'private'!
setFunctor: aSymbol args: anArray
	functor := aSymbol. args := anArray!
isGround
	^ground == true!
beGround
	ground := true! !

!PrologStruct methodsFor: 'accessing'!
functor
	^functor!
args
	^args!
arity
	^args size!
arg: i
	^args at: i!
first
	^args at: 1!
second
	^args at: 2!
isList
	^functor == #'.' and: [args size = 2]! !

!PrologStruct methodsFor: 'comparing'!
= other
	"structural equality of the terms as written (variables compare by identity)"
	| a b |
	other class == PrologStruct ifFalse: [^false].
	functor == other functor ifFalse: [^false].
	args size = other args size ifFalse: [^false].
	1 to: args size do: [:i |
		a := (args at: i) plDeref. b := (other args at: i) plDeref.
		(a == b or: [a = b]) ifFalse: [^false]].
	^true!
hash
	^functor hash bitXor: args size! !

!PrologStruct methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: (PrologWriter new quoted: true; stringFor: self)! !

!PrologThrow class methodsFor: 'signalling'!
ball: aTerm
	^self new ball: aTerm; signal! !

!PrologThrow methodsFor: 'accessing'!
ball
	^ball!
ball: aTerm
	ball := aTerm!
messageText
	^'Prolog exception: ', (PrologWriter new quoted: true; stringFor: ball)! !

!PrologHalt methodsFor: 'accessing'!
code
	^code ifNil: [0]!
code: anInteger
	code := anInteger! !

!Object methodsFor: 'prolog testing'!
isPrologVar
	^false!
isPrologStruct
	^false! !

!PrologVar methodsFor: 'prolog testing'!
isPrologVar
	^true! !

!PrologStruct methodsFor: 'prolog testing'!
isPrologStruct
	^true! !
