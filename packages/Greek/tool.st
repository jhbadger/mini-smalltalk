"Greek: the System menu item.  'greek paradigm...' asks for a word and opens a window with its table: a
verb's tenses (and its passive), a noun's or an adjective's declension."

Object subclass: #GreekTool instanceVariableNames: '' classVariableNames: '' category: 'Greek-Grammar'!

!GreekTool class methodsFor: 'opening'!
open
	| word |
	word := Smalltalk promptFor: 'A Greek word (or beta code, e.g. gra/fw)' default: 'γράφω'.
	(word isNil or: [word isEmpty]) ifTrue: [^nil].
	^self openOn: word!
openOn: aWord
	| word text w |
	word := (aWord asWideString allSatisfy: [:c | c value < 128]) ifTrue: [aWord asGreek] ifFalse: [aWord].
	text := [self textFor: word] on: Error do: [:e | e messageText].
	^self openWindowNamed: 'Greek: ', word contents: text!
textFor: aWord
	| w out |
	w := GreekLexicon lookup: aWord.
	(w isNil or: [(w isKindOf: GreekVerb) not]) ifTrue: [^aWord greekParadigm printString].
	out := WriteStream on: String new.
	out print: w paradigm.
	w hasPassive ifTrue: [out cr; print: w passiveParadigm].
	^out contents!
openWindowNamed: aTitle contents: aString
	"shown in a window by the user interface; printed on the Transcript when there is none"
	<primitive: 180>
	Transcript show: aString; cr! !
