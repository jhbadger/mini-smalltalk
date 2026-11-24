"A workspace for trying APL out: select some lines and print them (or do them) to run them. What each line would print
comes back under it, and an error shows as a line starting with a bar. The session is the same every time, so the names
you define stay defined until you ask for a fresh one."

!APLTool class methodsFor: 'opening'!
open
	Smalltalk openTool: 'APLTool' title: 'APL' contents: self welcomeText!
welcomeText
	^'NB. Select some lines and print them (ctrl-P) or do them (ctrl-D).  What each
NB. prints comes back below it.  Names stay defined from one run to the next,
NB. until you run   FORGET-ALL   or close the window.  Everything is read from
NB. right to left:  2 * 3 + 4  is 14.

i. 10
+/ i. 10
2 3 $ i. 6
1 2 3 + 10 20 30
*: 1 2 3 4
mean =: +/ % #
mean 3 1 4 1 5 9
(i. 5) */ i. 5
fact =: 3 : ''if. y < 2 do. 1 else. y * fact y - 1 end.''
fact 25
''hello'' , '' '' , ''world''
|. ''hello''
/:~ 3 1 4 1 5 9 2 6
<;._1 '' the quick brown fox''

NB. a definition over several lines ends at a line with just a closing parenthesis:
area =: verb define
h =. y % 2
h * y
)
area 10
'!

!APLTool class methodsFor: 'evaluating'!
session
	"the session the workspace runs in"
	Session isNil ifTrue: [Session := APL new].
	^Session!
reset
	"a fresh session: every name forgotten"
	Session := APL new.
	^Session!
evaluate: aString
	"the report for the selected text: what each sentence prints, and the error if one fails"
	| ws |
	aString trimBoth = 'FORGET-ALL' ifTrue: [self reset. ^'a fresh APL session'].
	ws := WriteStream on: String new.
	[self session run: aString display: ws]
		on: APLError
		do: [:e |
			ws contents isEmpty ifFalse: [ws nextPut: Character lf].
			ws nextPut: $|.
			ws nextPutAll: e messageText].
	^ws contents! !
