"An interactive tutorial for Mini Smalltalk-80, in the spirit of ProfStef.
 File this in (System menu > smalltalk tutorial, or: Smalltalk fileIn: 'tutorial.st') and evaluate:   Tutorial go"

Object subclass: #TutorialLesson instanceVariableNames: 'title text' classVariableNames: '' category: 'Tutorial'!
Object subclass: #Tutorial instanceVariableNames: '' classVariableNames: 'Current' category: 'Tutorial'!

!TutorialLesson class methodsFor: 'instance creation'!
title: aString text: lessonText
	^self new setTitle: aString text: lessonText! !

!TutorialLesson methodsFor: 'accessing'!
setTitle: aString text: lessonText
	title := aString. text := lessonText!
title
	^title!
text
	^text!
printOn: aStream
	aStream nextPutAll: 'a TutorialLesson: '; nextPutAll: title! !

!Tutorial class methodsFor: 'navigation'!
go
	"start (or resume) the tutorial"
	Current isNil ifTrue: [Current := 1].
	^self show!
start
	Current := 1.
	^self show!
first
	^self start!
last
	Current := self lessons size.
	^self show!
next
	Current := ((Current ifNil: [0]) + 1) min: self lessons size.
	^self show!
previous
	Current := ((Current ifNil: [2]) - 1) max: 1.
	^self show!
goTo: aNumberOrTitle
	"a lesson number, or the beginning of a lesson title"
	aNumberOrTitle isNumber
		ifTrue: [Current := (aNumberOrTitle truncated max: 1) min: self lessons size]
		ifFalse: [| i |
			i := self lessons findFirst: [:l | l title asLowercase startsWith: aNumberOrTitle asString asLowercase].
			i = 0 ifTrue: [^self error: 'no lesson called ', aNumberOrTitle printString].
			Current := i].
	^self show!
reset
	Current := nil!
contents
	"show the table of contents"
	| s |
	s := WriteStream on: String new.
	s nextPutAll: 'Smalltalk Tutorial  --  contents'; cr; cr.
	self lessons doWithIndex: [:l :i |
		s nextPutAll: (i printPaddedWith: $  to: 3); nextPutAll: '.  '; nextPutAll: l title.
		i = Current ifTrue: [s nextPutAll: '   <-- you are here'].
		s cr].
	s cr; nextPutAll: 'Jump to a lesson with, for example:   Tutorial goTo: 7      or      Tutorial goTo: ''Blocks'''; cr.
	s nextPutAll: 'Carry on where you were with:          Tutorial show'; cr.
	self openWindowNamed: 'Tutorial contents' contents: s contents!
help
	^self contents! !

!Tutorial class methodsFor: 'accessing'!
lesson
	"the current lesson"
	^self lessons at: (Current ifNil: [1])!
lessonNumber
	^Current ifNil: [1]!
lessons
	^self lessonSelectors collect: [:sel | self perform: sel]!
lessonSelectors
	^#(#welcome #printingAndDoing #everythingIsAnObject #commentsAndReservedWords #literals #unaryMessages #binaryMessages #keywordMessages
		#precedence #cascades #variables #booleans #blocks #loops #numbers #stringsAndSymbols #collections
		#iterating #streams #classesAndMetaclasses #definingAClass #instanceVariablesSelfAndSuper #theBrowser #reflection #errors #processes #whatNext)!
tutorial
	"the lessons, as ProfStef calls them"
	^self lessons!
goOn: aNumber
	"ProfStef's name for goTo:"
	^self goTo: aNumber! !

!Tutorial class methodsFor: 'displaying'!
show
	| l s n |
	l := self lesson. n := self lessonNumber.
	s := WriteStream on: String new.
	s nextPutAll: 'Smalltalk Tutorial  --  lesson '; print: n; nextPutAll: ' of '; print: self lessons size; nextPutAll: ':  '; nextPutAll: l title; cr.
	s nextPutAll: (String new: 72 withAll: $-); cr; cr.
	s nextPutAll: l text; cr; cr.
	s nextPutAll: (String new: 72 withAll: $-); cr.
	s nextPutAll: 'Select a line below and do it (ctrl-D) to move on:'; cr.
	n < self lessons size ifTrue: [s nextPutAll: '    Tutorial next'; cr].
	n > 1 ifTrue: [s nextPutAll: '    Tutorial previous'; cr].
	s nextPutAll: '    Tutorial contents'; cr.
	self openWindowNamed: 'Tutorial ', n printString, '/', self lessons size printString, ': ', l title contents: s contents.
	^l!
openWindowNamed: aTitle contents: aString
	"shown in a window by the user interface; printed on the Transcript when there is none"
	<primitive: 180>
	Transcript show: aString; cr! !

!Tutorial class methodsFor: 'lessons - basics'!
welcome
	^TutorialLesson title: 'Welcome' text:
'Welcome to Mini Smalltalk-80.

This tutorial is itself written in Smalltalk (browse the class Tutorial), and it
runs inside the system you are learning.  Every example in these lessons is live:

   1.  Select an expression with the mouse, or just leave the cursor on its line.
   2.  Press ctrl-P ("print it") to evaluate it and see the answer inserted after it.
       Press ctrl-D ("do it") to evaluate without printing.  ctrl-T inspects the answer.
       The same commands are on the right-button menu of this window.

Try it now with the line below:

3 + 4

You can type anything you like into this window; it is an ordinary workspace.
When you are ready, select the line "Tutorial next" at the bottom and do it.'!
printingAndDoing
	^TutorialLesson title: 'Printing and doing' text:
'"Print it" (ctrl-P) evaluates the selection and shows the result.  Try each line:

100 factorial
''Hello'' reversed
(1 to: 10) asOrderedCollection

"Do it" (ctrl-D) evaluates for the effect only.  Output usually goes to the
System Transcript window:

Transcript show: ''Hello from the tutorial''; cr
Transcript show: 100 factorial printString; cr

"Inspect it" (ctrl-T) opens an Inspector on the result; try it on:

Date today

In an Inspector you can click each instance variable, and evaluate code in the
lower pane where "self" is the inspected object.  Close windows with the [x] in
their title bar.  Drag the title bar to move a window, drag the bottom-right
corner to resize it.'!
everythingIsAnObject
	^TutorialLesson title: 'Everything is an object' text:
'In Smalltalk every value is an object, and all computation happens by sending
messages to objects.  3 is an object, so is a string, a class, a block of code,
even the running method.  Ask any object for its class:

3 class
''abc'' class
3 class class
Transcript class
[:x | x + 1] class
nil class

A message consists of a receiver, a selector (the message name) and arguments.
In  3 + 4  the receiver is 3, the selector is #+, the argument is 4.  The object
that receives the message decides what to do with it: 3 knows how to add, and a
string knows how to reverse itself:

3 + 4
''abc'' reversed
#(3 1 2) asSortedCollection

There are only six reserved words: nil, true, false, self, super and thisContext.
Everything else, including control flow, is a message send.'!
commentsAndReservedWords
	^TutorialLesson title: 'Comments and reserved words' text:
'Comments are written between double quotes and may span lines.  The compiler
ignores them, so this evaluates to 7:

3 + 4   "the answer"

Strings use single quotes; do not confuse the two:

''this is a string''
"this is a comment and evaluates to nothing"

The six reserved words, the only names with built-in meaning:

nil               "the undefined object, the only instance of UndefinedObject"
true              "the only instance of True"
false             "the only instance of False"
thisContext       "the running method or block activation"

self and super can only be used inside a method: self is the receiver of the
current message, and super is also the receiver, but the search for a method
starts in the superclass of the class where the method was defined.  Here they
are seen through the compiler:

(Integer >> #factorial) sourceCode
(Fraction >> #+) sourceCode

Everything else that looks like syntax is punctuation:  ^ answers a value from
a method, := assigns, . ends a statement, ; cascades, | | declares temporaries,
[ ] delimits a block, # introduces a symbol or literal array, $ a character.'!
literals
	^TutorialLesson title: 'Literals' text:
'Numbers:
42                     "a SmallInteger"
-17
3.14159                "a Float"
2r1010                 "radix notation: binary 10"
16rFF                  "hexadecimal 255"
1e6                    "an Integer with an exponent"
100 factorial          "a LargePositiveInteger"
(1/3)                  "a Fraction; arithmetic is exact"

Characters and strings:
$a                     "a Character"
Character cr
''a string''             "double a quote to include it: ''it''''s''"

Symbols are unique strings used as names; there is only one #foo in the system:
#foo
#at:put:
#foo == #foo           "identical"
''foo'' == ''foo''         "two different string objects..."
''foo'' = ''foo''          "...that are equal"

Arrays:
#(1 2 3)               "a literal Array"
#(1 $a ''str'' #sym (2 3) nil true)   "elements may be any literal; nested parens are arrays"
#[1 2 255]             "a ByteArray"
{1 + 1. ''two''. 3 factorial}       "a brace array: elements are evaluated"'!
unaryMessages
	^TutorialLesson title: 'Unary messages' text:
'A unary message has no arguments.  It is written as an identifier after the receiver:

5 factorial
''smalltalk'' asUppercase
''smalltalk'' size
#(1 2 3) reversed
3.7 rounded
10 isPrime
Date today dayName

Unary messages read left to right, so each result becomes the receiver of the next:

5 factorial printString size
''hello world'' reversed asUppercase first
Date today monthName size

Classes are objects too, so they receive unary messages such as "new":

OrderedCollection new
Object new
Set new'!
binaryMessages
	^TutorialLesson title: 'Binary messages' text:
'A binary message has one argument and a selector made of one or two special
characters, such as  +  -  *  /  //  \\  <  >  <=  >=  =  ~=  ==  ,  @  ->

3 + 4
10 / 4                "exact: a Fraction"
10 // 4               "integer division"
10 \\ 4               "remainder"
2 ** 10               "raisedTo:"
''abc'' , ''def''         "concatenation"
3 @ 4                 "a Point"
#a -> 1               "an Association"
3 < 4
3 = 3.0
''abc'' = ''abc''
''abc'' == ''abc''        "identity: two distinct string objects"

Binary messages are evaluated strictly from left to right, with no arithmetic
precedence.  There is nothing special about + and *:

2 + 3 * 4             "20, not 14"
2 + (3 * 4)           "use parentheses when you mean it"'!
keywordMessages
	^TutorialLesson title: 'Keyword messages' text:
'A keyword message has one or more arguments, each introduced by a keyword ending
in a colon.  The selector is all the keywords joined together:

#(10 20 30) at: 2                     "selector #at:"
#(10 20 30) copyFrom: 2 to: 3         "selector #copyFrom:to:"
''hello'' copyReplaceAll: ''l'' with: ''L''
3 between: 1 and: 5
7 max: 12
Array new: 3
10 printString: 2                     "radix 2"
Date newDay: 4 month: #July year: 1976

The keywords describe the arguments, so the order can never be confused.  Compare
this with  t.rotate(a, v)  in other languages:  t rotateBy: angle around: axis.

A keyword message extends as far as it can to the right.  To use the result of one
keyword message as the argument of another, add parentheses:

#(1 2 3) at: (#(3 2 1) at: 1)
(Array new: 3) at: 1 put: ''x''; yourself'!
precedence
	^TutorialLesson title: 'Precedence' text:
'The complete rule:  parentheses first, then unary messages, then binary messages,
then keyword messages; otherwise left to right.

2 + 3 factorial               "unary before binary: 2 + 6"
2 + 3 factorial * 2           "binary left to right: (2 + 6) * 2"
#(1 2 3) at: 1 + 1             "binary before keyword: at: 2"
(1 to: 10) inject: 0 into: [:sum :each | sum + each]

Read  3 + 4 factorial between: 1 and: 100  as:
   4 factorial  ->  24,  then  3 + 24  ->  27,  then  27 between: 1 and: 100  ->  true

3 + 4 factorial between: 1 and: 100

When in doubt, parenthesize.  A statement ends with a period; several statements
can be written on one line.  Select both of these and print it:

Transcript show: ''one''; cr. 3 + 4'!
cascades
	^TutorialLesson title: 'Cascades' text:
'To send several messages to the same receiver, separate them with semicolons
instead of repeating the receiver.  This is a cascade:

Transcript show: ''Hello''; show: '' ''; show: ''world''; cr

The cascade sends all the messages to the receiver of the first message.  The
value of the whole expression is the value of the LAST message, which is often
not what you want when building objects:

OrderedCollection new add: 1; add: 2; add: 3

That answers 3 (the result of the last add:).  Finish the cascade with "yourself"
to get the collection itself:

OrderedCollection new add: 1; add: 2; add: 3; yourself
(Set new) add: #a; add: #b; add: #a; yourself

Remember:  a period separates statements, a semicolon continues a cascade.'!
variables
	^TutorialLesson title: 'Variables' text:
'Temporary variables are declared between vertical bars and assigned with  :=
Variables are untyped: any variable may hold any object.  Select all three lines
and print it:

| x y |
x := 3 + 4.
y := x * 2

In a workspace, a name you have not declared is quietly created as a global
variable when you use it, so you can also work without declarations:

total := 0.
total := total + 10.
total

Names starting with a capital letter are globals by convention: the classes,
Smalltalk (the dictionary of all globals), Transcript, Processor.

Smalltalk at: #total
Smalltalk at: #Greeting put: ''hello''.
Greeting reversed

Instance variables (declared when a class is defined) are visible to all the
methods of that class, and to its subclasses, but to nobody else: there are no
public fields in Smalltalk, only messages.'!
booleans
	^TutorialLesson title: 'Booleans and conditionals' text:
'true and false are the two instances of the classes True and False.  Comparisons
answer them, and they understand the logical messages:

3 < 4
(3 < 4) & (4 < 5)
(3 < 4) | false
(3 > 4) not
(3 < 4) and: [4 < 5]          "and: only evaluates its block when needed"
(3 > 4) or: [1 / 0]            "so the division is never attempted"

Conditionals are messages to booleans, with blocks (square brackets) as arguments:

3 < 4 ifTrue: [''yes''] ifFalse: [''no'']
3 > 4 ifTrue: [''yes'']            "answers nil when not taken"
(3 > 4) ifFalse: [''it was false'']

| n | n := 15. (n \\ 3 = 0) & (n \\ 5 = 0) ifTrue: [''FizzBuzz''] ifFalse: [n printString]

nil is the single instance of UndefinedObject; test it with isNil / notNil / ifNil:

nil isNil
3 isNil
nil ifNil: [''there was nothing there'']'!
blocks
	^TutorialLesson title: 'Blocks' text:
'A block is a piece of code in square brackets that is not run until it is sent
the message value (or value: with arguments).  Blocks are objects: they can be
stored in variables, passed as arguments and answered from methods.

[3 + 4] value
[:x | x * x] value: 7
[:a :b | a + b] value: 3 value: 4
| square | square := [:x | x * x]. (1 to: 5) collect: square

Blocks can have their own temporaries and several statements; the value of the
block is the value of its last statement:

[:n | | half | half := n // 2. half * half] value: 9

Blocks are closures: they remember the variables of the place they were written.

| counter makeCounter |
makeCounter := [| n | n := 0. [n := n + 1]].
counter := makeCounter value.
counter value. counter value. counter value

A caret (^) inside a block returns from the METHOD that contains the block, not
just from the block.  That is how detect: can stop early:

#(1 2 3 4) detect: [:e | e > 2]

Blocks with no arguments can also be forked as processes (see the lesson on processes).'!
loops
	^TutorialLesson title: 'Loops' text:
'There is no loop syntax; loops are messages that take blocks.

1 to: 5 do: [:i | Transcript show: i printString; cr]
10 to: 1 by: -3 do: [:i | Transcript show: i printString; space]
5 timesRepeat: [Transcript show: ''*'']
#(1 2 3) do: [:e | Transcript show: e printString] separatedBy: [Transcript show: '', '']
#(''a'' ''b'') doWithIndex: [:e :i | Transcript show: i printString, e; cr]

whileTrue: and whileFalse: are sent to a block that answers a boolean:

| i | i := 1. [i < 1000] whileTrue: [i := i * 2]. i
| i | i := 10. [i <= 0] whileFalse: [i := i - 3]. i

Collections iterate themselves (next lesson), so explicit index loops are rare.
The compiler inlines ifTrue:, and:, whileTrue: and friends when their arguments are
literal blocks, so they cost nothing extra; but they are still ordinary messages,
and True, False and BlockClosure really do implement them.  Look:

(True >> #ifTrue:ifFalse:) sourceCode'!
numbers
	^TutorialLesson title: 'Numbers' text:
'Integers are exact and unbounded:

2 raisedTo: 200
(2 raisedTo: 200) class
1000 factorial printString size
12345678901234567890 * 98765432109876543210
(2 raisedTo: 64) printString: 16

Division answers a Fraction when it is not exact; fractions are reduced and exact:

1 / 3
(1 / 3) + (1 / 6)
(1 / 3) * 3
(2 / 3) reciprocal
(1 / 3) asFloat

Mixing kinds of numbers coerces to the most general: Integer -> Fraction -> Float.

3 + (1 / 2)
(1 / 2) + 0.5
3.7 truncated
3.7 rounded
7 \\ 3
-7 \\ 3                "modulo is always non-negative for a positive divisor"
-7 rem: 3              "rem: truncates toward zero"
2 sqrt
Float pi
100 ln / 10 ln
17 isPrime
(1 to: 20) select: [:n | n isPrime]
24 gcd: 36

Dates, times and random numbers are numbers too, more or less:

Date today
Date today addDays: 100
Time now
Random new next
(Random seed: 42) between: 1 and: 6'!
stringsAndSymbols
	^TutorialLesson title: 'Strings and Symbols' text:
'Strings are indexable collections of Characters; indices start at 1.

''hello'' size
''hello'' at: 1
''hello'' first
''hello'' reversed
''hello'' asUppercase
''hello'' , '' world''
''hello world'' substrings
''hello'' indexOf: $l
''hello'' occurrencesOf: $l
''hello'' copyFrom: 2 to: 4
''hello world'' copyReplaceAll: ''o'' with: ''0''
''hello'' includesSubstring: ''ell''
''h*o'' match: ''hello''             "wildcards: * any run, # one character"
''42'' asNumber + 1
42 printString , '' apples''
''  padded  '' withBlanksTrimmed
''abc'' < ''abd''

Strings are mutable; copy a literal before changing it:

| s | s := ''hello'' copy. s at: 1 put: $j. s

Symbols are immutable, unique strings, mostly used as selectors and names.
Converting between them:

''hello'' asSymbol
#hello asString
#at:put: numArgs
#at:put: keywords
3 respondsTo: #factorial
3 perform: #factorial
3 perform: #+ with: 4

Building a string piece by piece is best done with a WriteStream (see the
lesson on streams) or with printString / displayString:

#(1 2 3) printString
''it''''s'' printString            "printString shows the quotes..."
''it''''s'' displayString          "...displayString does not"'!
collections
	^TutorialLesson title: 'Collections' text:
'The collection classes are the heart of the library.  The main ones:

Array: fixed size, indexable.
   #(10 20 30) at: 2
   (Array new: 3) at: 1 put: ''x''; yourself
   Array with: 1 with: 2 with: 3

OrderedCollection: grows as you add, keeps order.
   OrderedCollection new add: 3; add: 1; addFirst: 0; yourself
   (OrderedCollection withAll: #(1 2 3)) removeFirst
Interval: a lazy arithmetic sequence.
   (1 to: 10 by: 2) asArray
Set: no duplicates, no order; Bag: counts duplicates.
   (Set withAll: #(1 2 2 3 3 3)) size
   (Bag withAll: #(1 2 2 3 3 3)) occurrencesOf: 3
Dictionary: keys to values.
   | d | d := Dictionary new. d at: #one put: 1; at: #two put: 2. d at: #two
   | d | d := Dictionary new. d at: #one put: 1. d at: #three ifAbsent: [0]
   | d | d := Dictionary new. d at: #a put: 1; at: #b put: 2. d keys
   | d | d := Dictionary new. d at: #a put: 1; at: #b put: 2. d associations
SortedCollection: keeps itself sorted by a block.
   (SortedCollection sortBlock: [:a :b | a > b]) addAll: #(3 1 2); yourself
   #(''pear'' ''apple'' ''fig'') asSortedCollection: [:a :b | a size <= b size]
LinkedList, RunArray, MappedCollection, Text, Symbol, String, ByteArray round out the set.

Conversions move between them freely:

#(3 1 2) asOrderedCollection
#(3 1 2) asSortedCollection asArray
''hello'' asSet size
''hello'' asBag occurrencesOf: $l

Equality of collections is by contents; Sets and Dictionaries use = and hash,
so your own classes work as elements and keys if they define both.'!
iterating
	^TutorialLesson title: 'Iterating over collections' text:
'All collections share one enumeration protocol.  Learn these five and you can
read most Smalltalk code:

#(1 2 3 4) do: [:e | Transcript show: e printString; cr]
#(1 2 3 4) collect: [:e | e * e]               "map"
#(1 2 3 4) select: [:e | e even]               "filter"
#(1 2 3 4) reject: [:e | e even]
#(1 2 3 4) detect: [:e | e > 2]                "first match"
#(1 2 3 4) detect: [:e | e > 9] ifNone: [''none'']
#(1 2 3 4) inject: 0 into: [:sum :e | sum + e] "fold"

More:

#(1 2 3 4) anySatisfy: [:e | e > 3]
#(1 2 3 4) allSatisfy: [:e | e > 0]
#(1 2 3 4) count: [:e | e odd]
#(3 1 2) detectMax: [:e | e]
#(1 2 3) with: #(10 20 30) collect: [:a :b | a + b]
#(1 2 3) reverseDo: [:e | Transcript show: e printString]
#(1 2 3) , #(4 5)
(1 to: 10) inject: 1 into: [:p :e | p * e]
''hello'' collect: [:c | c asUppercase]
''hello'' select: [:c | c isVowel]
''hello world'' asBag sortedCounts first

Dictionaries enumerate their values with do:, or both with keysAndValuesDo:

| d | d := Dictionary new. d at: #a put: 1; at: #b put: 2.
d keysAndValuesDo: [:k :v | Transcript show: k; show: ''=''; show: v printString; cr]

Sorting:

#(3 1 2) asSortedCollection asArray
(#(3 1 2) asArray sort: [:a :b | a > b]) yourself
#(''pear'' ''apple'' ''fig'') asSortedCollection asArray'!
streams
	^TutorialLesson title: 'Streams' text:
'Streams read from or write to a sequence one element at a time.

| r | r := ReadStream on: #(1 2 3 4 5). r next. r next. r upToEnd
| r | r := ReadStream on: ''hello world''. r upTo: $
| r | r := ReadStream on: ''a,b,,c''. r upTo: $,. r upTo: $,. r atEnd

A WriteStream is the efficient way to build a String:

| w | w := WriteStream on: String new.
w nextPutAll: ''The answer is ''; print: 6 * 7; nextPut: $.; cr; tab; nextPutAll: ''done''.
w contents

print: writes an object''s printString; << writes strings as they are and prints
everything else.  Read and write at once with a ReadWriteStream, and use a
FileStream for files (the whole file is read when opened and written on close):

| f | f := FileStream newFileNamed: ''tutorial-demo.txt''. f nextPutAll: ''some text''; cr. f close
(FileStream oldFileNamed: ''tutorial-demo.txt'') contentsOfEntireFile
FileStream remove: ''tutorial-demo.txt''

Every object prints itself by implementing printOn: aStream; printString and the
Transcript are built on that.  Random is a stream of Floats:

Random new next
(Random new next: 3)'!
classesAndMetaclasses
	^TutorialLesson title: 'Classes and metaclasses' text:
'Every object is an instance of a class, and classes are objects too.

3 class
3 class superclass
3 class allSuperclasses
Integer subclasses
Object subclasses size
3 isKindOf: Number
3 isMemberOf: Integer
3 respondsTo: #printString
Integer inheritsFrom: Magnitude
Boolean printHierarchy

A class is the only instance of its metaclass, which holds the class-side
methods (such as "new").  Metaclasses are instances of Metaclass:

Integer class
Integer class class
Integer class class class
Integer class selectors
OrderedCollection class includesSelector: #new

Instance variables and methods:

Point allInstVarNames
Point selectors asSortedCollection asArray
(Point >> #+) sourceCode
Point category
Point comment

Smalltalk, the global dictionary, knows every class:

Smalltalk allClasses size
Smalltalk classNamed: ''Fraction''
Smalltalk classesInCategory: ''Kernel-Numbers''
Smalltalk classCategories'!
definingAClass
	^TutorialLesson title: 'Defining a class' text:
'A class is created by sending a message to its superclass.  Do it on this (select
all four lines):

Object subclass: #Counter
	instanceVariableNames: ''count''
	classVariableNames: ''''
	category: ''Tutorial-Examples''

Methods are added with compile: (or, more comfortably, in the browser; next lesson).
The source of a method is its pattern followed by its body.  Do each of these:

Counter compile: ''increment  count := self count + 1. ^count'' classified: ''accessing''
Counter compile: ''count  ^count ifNil: [0]'' classified: ''accessing''
Counter compile: ''printOn: aStream  aStream nextPutAll: ''''a Counter at ''''; print: self count'' classified: ''printing''

Now use it:

Counter new
Counter new increment; increment; yourself
| c | c := Counter new. 5 timesRepeat: [c increment]. c count

Class-side methods go on the metaclass:

Counter class compile: ''startingAt: n  ^self new setCount: n'' classified: ''instance creation''
Counter compile: ''setCount: n  count := n'' classified: ''private''
(Counter startingAt: 10) increment

Everything you define this way is also written to changes.st in the directory
you started from, and reloaded next time you start.'!
instanceVariablesSelfAndSuper
	^TutorialLesson title: 'Instance variables, self and super' text:
'Each Counter has its own count: an instance variable is private state, visible
only to the methods of its class and subclasses.  Nobody outside can read it
without an accessor method, which is why we wrote "count" and "setCount:".

| a b | a := Counter new. b := Counter new. a increment; increment. b increment. a count @ b count

Inside a method, self is the object the message was sent to.  Sending a message
to self is how a method uses other methods of the same object, and it is also
what makes inheritance work: a subclass may redefine the method that self finds.

Counter subclass: #DoubleCounter instanceVariableNames: '''' classVariableNames: '''' category: ''Tutorial-Examples''

DoubleCounter inherits everything from Counter.  Override increment; super runs
the inherited version:

DoubleCounter compile: ''increment  super increment. ^super increment'' classified: ''accessing''
DoubleCounter new increment; increment
DoubleCounter new increment; increment; count

Overriding printOn: changes how an object prints everywhere, including print it
and the Inspector; we did that for Counter in the previous lesson.  Overriding
= and hash makes objects usable as Set elements and Dictionary keys:

Counter compile: ''= other  ^(other isKindOf: Counter) and: [self count = other count]'' classified: ''comparing''
Counter compile: ''hash  ^self count hash'' classified: ''comparing''
(Set new add: (Counter startingAt: 3); add: (Counter startingAt: 3); yourself) size

Instance variables are added to a class by redefining it (or in the browser):

Counter instanceVariableNames: ''count step''
Counter allInstVarNames

The class-definition message answers the class, so this can be done at any time;
existing instances simply have nil in the new variable.'!
theBrowser
	^TutorialLesson title: 'The System Browser' text:
'The System Browser is where Smalltalk programming really happens.  Open one from
the System menu (right-click the desktop, or press Esc) or do it:

Smalltalk at: #Counter ifAbsent: [''do the previous lesson first'']

Its four lists are, left to right:
   class category  >  class  >  message protocol  >  selector
and the pane below shows source.  Click Tutorial-Examples, then Counter, then
"accessing", then "increment" to see the method you compiled in the last lesson.

To add a method: pick a protocol (right-click the protocol list for "add protocol"
to make a new one), type the method into the code pane and accept it with ctrl-S
or "accept" on the right-button menu.  Try adding to Counter:

reset
	count := 0

To add a class: click a category with no class selected; the pane shows a class
definition template.  Edit the name and instance variables and accept.
The [instance]/[class] button switches to class-side methods.
Right-click a selector for "senders" and "implementors", a class for "file out"
or "remove class".  Typing a letter in a list jumps to the next matching entry.

Everything accepted in the browser goes to changes.st, so it survives a restart.
"file out" writes a class as a .st file that can be filed in elsewhere with
Smalltalk fileIn: ''Counter.st''  or from the System menu.'!
reflection
	^TutorialLesson title: 'Reflection' text:
'The system can examine and change itself at run time; the tools are built from
these same messages.

Integer selectors size
Integer whichSelectorsReferTo: #primCompare:
(Integer >> #factorial) sourceCode
(Integer >> #factorial) messages
Integer organization categories
Integer organization listAtCategoryNamed: ''bit manipulation''
| c | c := Counter new. Counter allInstances size
Counter allInstances class
3 class canUnderstand: #sqrt
3 respondsTo: #fly
(Smalltalk classNamed: ''Point'') comment

Methods and contexts are objects too.  thisContext is the running activation:

thisContext
thisContext method
thisContext class
[thisContext] value class
[:x | x] numArgs

perform: sends a message chosen at run time; the compiler is available as well:

3 perform: #between:and: with: 1 with: 5
Compiler evaluate: ''3 + 4''
nil evaluate: ''Date today''
Integer compile: ''double ^self * 2''.
21 double

The inspector (ctrl-T) shows an object''s instance variables; try it on a Dictionary,
a CompiledMethod, or a class.'!
errors
	^TutorialLesson title: 'Errors and walkbacks' text:
'When something goes wrong, an error window shows the message and the walkback,
the list of the methods that were active, innermost first.  Try:

nil foo
3 + ''four''
#(1 2 3) at: 5
Object new bar: 1 baz: 2
1 / 0

The most common error is "does not understand": the receiver has no method for
that selector.  Read the walkback from the top to find your own method in it.

You can raise errors yourself with error:, and Error signal: does the same:

self error: ''something is wrong''
Error signal: ''the widget is broken''
[1 / 0] on: ZeroDivide do: [:e | ''handled'']     "this Smalltalk has no exception handlers: the error wins"

Every Object understands halt, which simply raises an error named halt.  In the
classic Smalltalk-80 a debugger would open; here the error window plays that part.
A lot of debugging can also be done by printing:

| x | x := 3 + 4. Transcript show: ''x = ''; show: x printString; cr. x
thisContext backtrace'!
processes
	^TutorialLesson title: 'Processes' text:
'Any zero-argument block can run as a separate Process.  Processes are
cooperative: they switch when one waits, yields or finishes, and they also get
time while the user interface is idle.

[Transcript show: ''hello from a process''; cr] fork
[1 to: 5 do: [:i | Transcript show: ''tick ''; show: i printString; cr. (Delay forSeconds: 1) wait]] fork

Do the second one and watch the Transcript window for five seconds.  Semaphores
synchronise processes:

| s | s := Semaphore new. [Transcript show: ''worker done''; cr. s signal] fork. s wait. ''main continues''

A SharedQueue passes objects between processes, blocking the reader until
something arrives:

| q | q := SharedQueue new. [(Delay forMilliseconds: 500) wait. q nextPut: 42] fork. q next

Processes have priorities 1 to 8; a higher priority process runs first:

| r | r := OrderedCollection new. [r add: #low] forkAt: 3. [r add: #high] forkAt: 6. r

Processor is the scheduler; Processor activeProcess is the one running now,
Processor yield lets others at the same priority run:

Processor activeProcess
Processor activePriority
[(Delay forSeconds: 60) wait] fork             "a process that just sleeps..."
Processor activeProcess                         "...you are still the active one"

A process that waits on a semaphore nobody signals, with nothing else runnable,
is reported as a deadlock rather than hanging the system:

Semaphore new wait'!
whatNext
	^TutorialLesson title: 'Where to go next' text:
'You have seen the whole language: objects, messages of three kinds, blocks,
and a class library that does everything else.  Some suggestions:

Read code.  The entire system is in the browser, and it is small enough to read
in an evening.  Start with Object, Collection and OrderedCollection, then look at
how Date or Fraction are built.  Senders and implementors in the browser answer
most "how does this work" questions.

Change code.  Add a method to Integer (for instance isPerfect), or a new class in
your own category, and use it from a workspace.  Your work is kept in changes.st.
   Integer compile: ''isPerfect  ^((1 to: self - 1) select: [:d | self \\ d = 0]) sum = self''.
   (1 to: 500) select: [:n | n isPerfect]

Save and share.  Right-click a class or a category in the browser and choose
"file out" to write it as a .st file; file it in again with the System menu or
Smalltalk fileIn: ''SomeFile.st''.  Smalltalk fileIn: is also how this tutorial
itself was loaded; browse the class Tutorial to see how a lesson is written, and
feel free to add lessons of your own.

Further reading, in order of patience required:
   The Pharo cheat sheet (two pages, the syntax at a glance)
   "I Can Read C++ and Java But I Can''t Read Smalltalk", Wilf LaLonde
   Pharo by Example (free book; its first six chapters apply almost unchanged here)
   Smalltalk-80: The Language and its Implementation, Goldberg and Robson (the Blue Book,
   which this system follows)

Tutorial contents       "shows the list of lessons at any time"
Tutorial reset          "forgets where you were"'! !
