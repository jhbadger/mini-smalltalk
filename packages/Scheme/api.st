"The public face of Scheme: making an interpreter, evaluating text, converting between Scheme and Smalltalk data, and the
helpers that the primitive procedures are defined with."

!Scheme class methodsFor: 'instance creation'!
new
	^self basicNew initializeFrom: self template!
template
	"an interpreter with the primitives and the prelude installed; every new interpreter starts as a copy of it"
	Template isNil ifTrue: [self buildTemplate].
	^Template!
buildTemplate
	| f |
	f := self basicNew initializeEmpty.
	Prelude isNil ifFalse: [f evalString: Prelude].
	Template := f!
prelude: aString
	"the Scheme source every interpreter starts with (the package reads prelude.scm and passes it here)"
	Prelude := aString.
	Template := nil.
	Shared := nil!
default
	"the interpreter that  Scheme eval:  and friends use, so that what you define stays defined"
	Shared isNil ifTrue: [Shared := self new].
	^Shared!
reset
	"start the default interpreter again from scratch"
	Shared := self new.
	^Shared! !

!Scheme class methodsFor: 'evaluating'!
eval: aString
	"run Scheme source in the default interpreter and answer the value of the last form, written"
	^self default eval: aString!
run: aString
	"run Scheme source in the default interpreter and answer what it displayed"
	^self default run: aString!
evalValue: aString
	"the value of the last form as a Smalltalk object: lists and vectors become Arrays"
	^self default evalValue: aString!
load: aPath
	^self default load: aPath!
define: aName do: aBlock
	"a procedure written in Smalltalk, in every interpreter present and future (the block's arity is the procedure's)"
	| p |
	p := self makePrimitive: aName do: aBlock.
	self default definePrimitive: p.
	self template definePrimitive: p.
	^p! !

!Scheme class methodsFor: 'primitives'!
primitives
	^Primitives!
initPrimitives
	"build the table of primitive procedures, from the SchemePrims install methods"
	Primitives := Dictionary new.
	SchemePrims installControl.
	SchemePrims installEquivalence.
	SchemePrims installNumbers.
	SchemePrims installLists.
	SchemePrims installChars.
	SchemePrims installStrings.
	SchemePrims installVectors.
	SchemePrims installTables.
	SchemePrims installIO.
	SchemePrims installBridge.
	SchemePrims installRecords.
	Template := nil. Shared := nil!
availablePrimitives
	"the names of the primitive procedures written in Smalltalk"
	^Primitives keys asSortedCollection asArray!
primitiveNamed: aString
	^Primitives at: aString!
makePrimitive: aName do: aBlock
	| n |
	n := aBlock numArgs.
	^SchemePrimitive name: aName min: n max: n kind: #fixed block: aBlock!
def: aName do: aBlock
	"a procedure of a fixed number of arguments: the block takes them"
	| p |
	p := self makePrimitive: aName do: aBlock.
	Primitives at: aName put: p.
	^p!
def: aName min: lo max: hi rest: aBlock
	"a procedure taking between lo and hi arguments (hi nil: any number): the block takes them as an Array"
	| p |
	p := SchemePrimitive name: aName min: lo max: hi kind: #rest block: aBlock.
	Primitives at: aName put: p.
	^p!
def: aName min: lo max: hi value: aBlock
	"the block takes the interpreter and the Array of arguments and answers the value"
	| p |
	p := SchemePrimitive name: aName min: lo max: hi kind: #value block: aBlock.
	Primitives at: aName put: p.
	^p!
def: aName min: lo max: hi machine: aBlock
	"the block takes the interpreter and the Array of arguments and answers the next node to run (or nil with val set)"
	| p |
	p := SchemePrimitive name: aName min: lo max: hi kind: #machine block: aBlock.
	Primitives at: aName put: p.
	^p!
alias: newName for: oldName
	Primitives at: newName put: (Primitives at: oldName)! !

!Scheme methodsFor: 'initialize'!
initializeEmpty
	globals := Dictionary new.
	macros := Dictionary new.
	counter := 0.
	self makePorts.
	Primitives keysAndValuesDo: [:name :p | (self cellFor: name asSymbol) value: p].
	self bindPorts!
initializeFrom: aTemplate
	globals := Dictionary new.
	aTemplate globals keysAndValuesDo: [:s :c | globals at: s put: c copyCell].
	macros := aTemplate macros copy.
	counter := aTemplate counter.
	self makePorts.
	self bindPorts!
counter
	^counter!
makePorts
	output := SchemeOutPort on: (WriteStream on: String new).
	outParam := SchemeParameter value: output converter: nil.
	inParam := SchemeParameter value: (SchemeInPort on: '') converter: nil!
bindPorts
	(self cellFor: #'current-output-port') value: outParam.
	(self cellFor: #'current-error-port') value: outParam.
	(self cellFor: #'current-input-port') value: inParam!
definePrimitive: aPrimitive
	(self cellFor: aPrimitive name asSymbol) value: aPrimitive! !

!Scheme methodsFor: 'evaluating from Smalltalk'!
eval: aString
	"the value of the last form, as write shows it (nothing for an unspecified value)"
	^self writeString: (self evalString: aString)!
evalRaw: aString
	^self evalString: aString!
evalValue: aString
	^self toSmalltalk: (self evalString: aString)!
run: aString
	"run the program and answer what it displayed (and nothing from before)"
	self takeOutput.
	self evalString: aString.
	^self takeOutput!
load: aPath
	"read and run a file of Scheme: the value of the last form, written"
	^self eval: (FileStream contentsOf: aPath)!
takeOutput
	"what has been displayed since the last time, which is forgotten"
	| text |
	text := output contents.
	output setStream: (WriteStream on: String new) path: nil.
	^text!
outputText
	^output contents!
writeString: v
	v == SchemeUnspec ifTrue: [^''].
	^SchemePrinter write: v!
displayString: v
	v == SchemeUnspec ifTrue: [^''].
	^SchemePrinter display: v!
at: aName
	"the value of a global variable"
	| c |
	c := globals at: aName asSymbol ifAbsent: [nil].
	(c isNil or: [c value isNil]) ifTrue: [^SchemeError message: 'Unbound variable:' with: aName asSymbol].
	^c value!
at: aName put: anObject
	(self cellFor: aName asSymbol) value: anObject.
	^anObject!
define: aName do: aBlock
	"a procedure written in Smalltalk, in this interpreter only"
	^self definePrimitive: (Scheme makePrimitive: aName do: aBlock)!
call: aName with: anArray
	"call the Scheme procedure bound to a name with an Array of arguments: the Scheme value"
	^self applyProcedure: (self at: aName) to: anArray!
toSmalltalk: x
	"Scheme data as Smalltalk: lists and vectors become Arrays, () an empty Array, the unspecified value nil"
	x == SchemeUnspec ifTrue: [^nil].
	x == SchemeNil ifTrue: [^#()].
	x class == SchemePair ifTrue: [
		x isList ifFalse: [^x].
		^x asArray collect: [:e | self toSmalltalk: e]].
	x class == Array ifTrue: [^x collect: [:e | self toSmalltalk: e]].
	x class == SchemeValues ifTrue: [^x items collect: [:e | self toSmalltalk: e]].
	^x!
fromSmalltalk: x
	"Smalltalk data as Scheme: nil is the unspecified value; Arrays are vectors, other collections are left alone"
	x isNil ifTrue: [^SchemeUnspec].
	^x! !
