"Mini Smalltalk-80 kernel, part 13: notebooks.

A notebook is a text file of prose with Smalltalk in it, written the way Markdown writes code: the code goes
between fence lines of three backquotes -- a bare ``` or one followed by smalltalk or st -- and a ```result
block under a cell holds the value it printed last time. A fence followed by any other word is code in some
other language, kept but not run.

	Notebook open: 'notes.md'                 a notebook window on the file (a new file is saved when you save it)
	Notebook run: 'notes.md'                  runs every Smalltalk cell from the top; answers the last value
	Notebook codeCellsIn: aString             the code of each Smalltalk cell, in order

In the window, print it (ctrl-P) with the cursor in a cell runs the whole cell and writes its value in a
result block under it; ctrl-R runs every cell, ctrl-S saves. The System menu's notebook... item opens one."

Object subclass: #Notebook instanceVariableNames: '' classVariableNames: '' category: 'System-Support'!

!Notebook class methodsFor: 'opening'!
open: aPath
	"a notebook window on the file: true, or false when there is no user interface to show it in"
	<primitive: 205>
	^self error: 'cannot open a notebook on ', aPath printString! !

!Notebook class methodsFor: 'running'!
run: aPath
	"run every Smalltalk cell of the file in order, and answer the value of the last one"
	^self runString: (FileStream contentsOf: aPath)!
runString: aString
	| value |
	value := nil.
	(self codeCellsIn: aString) do: [:code | value := Compiler evaluate: code].
	^value! !

!Notebook class methodsFor: 'reading'!
codeCellsIn: aString
	"the code of each Smalltalk cell in aString, in order"
	^((self cellsIn: aString) select: [:c | (c at: 1) = #code]) collect: [:c | c at: 2]!
resultsIn: aString
	"the text of each result block in aString, in order"
	^((self cellsIn: aString) select: [:c | (c at: 1) = #result]) collect: [:c | c at: 2]!
cellsIn: aString
	"Array of (kind body) pairs for the fenced blocks of aString; kind is #code, #result or #other"
	| cells kind body |
	cells := OrderedCollection new.
	kind := nil.
	(self linesOf: aString) do: [:line |
		kind isNil
			ifTrue: [
				(self fenceKind: line) ifNotNil: [:k | kind := k. body := WriteStream on: String new]]
			ifFalse: [
				(self isClosingFence: line)
					ifTrue: [cells add: (Array with: kind with: body contents). kind := nil]
					ifFalse: [body nextPutAll: line; nextPut: Character lf]]].
	kind isNil ifFalse: [cells add: (Array with: kind with: body contents)].
	^cells asArray!
fenceKind: aLine
	"#code, #result or #other when aLine opens a fenced block, else nil"
	| rest word |
	rest := self afterFence: aLine.
	rest isNil ifTrue: [^nil].
	word := (rest trimBoth copyUpTo: Character space) asLowercase.
	(word isEmpty or: [word = 'smalltalk' or: [word = 'st']]) ifTrue: [^#code].
	word = 'result' ifTrue: [^#result].
	^#other!
isClosingFence: aLine
	| rest |
	rest := self afterFence: aLine.
	^rest notNil and: [rest trimBoth isEmpty]!
afterFence: aLine
	"what follows the backquotes when aLine is a fence (up to three spaces, then ```), else nil"
	| i |
	i := 1.
	[i <= 3 and: [i <= aLine size and: [(aLine at: i) = Character space]]] whileTrue: [i := i + 1].
	(aLine size >= (i + 2) and: [(aLine copyFrom: i to: i + 2) = '```']) ifFalse: [^nil].
	i := i + 3.
	[i <= aLine size and: [(aLine at: i) = $`]] whileTrue: [i := i + 1].
	^aLine copyFrom: i to: aLine size!
linesOf: aString
	| out start |
	out := OrderedCollection new.
	start := 1.
	1 to: aString size do: [:i |
		(aString at: i) = Character lf ifTrue: [out add: (aString copyFrom: start to: i - 1). start := i + 1]].
	start <= aString size ifTrue: [out add: (aString copyFrom: start to: aString size)].
	^out! !
