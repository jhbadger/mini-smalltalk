"The Debugger tutorial: reading the stack of an error, the marked source, variables by name, evaluating in a
frame, and the compiler support it rests on.  Start it with   DebuggerTutorial go"

AbstractTutorial subclass: #DebuggerTutorial instanceVariableNames: '' classVariableNames: '' category: 'Debugger'!

!DebuggerTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Debugger'!
lessonSelectors
	^#(#welcome #openingIt #theStack #theSource #theVariables #theReceiver #evaluatingInAFrame
		#whatItCannotDo #theCompilerSupport #thisContext #whatNext)! !

!DebuggerTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'The debugger is a window on the stack of an error: the frames, the source of
each one with the failing line marked, its variables by name, and a place to
evaluate expressions with self bound to that frame.

Loading the package is all the setting up there is.  From then on an error that
nobody handles opens the debugger instead of the plain walkback:

Smalltalk isPackageLoaded: ''Debugger''

Everything in this tutorial is live.  Select a line and press ctrl-P (print it)
to run it, or ctrl-D (do it) to run it without printing.

The lessons below open debugger windows on purpose.  Close each one when you
have finished looking, with the little x in its title bar; they stack up
otherwise.

One warning before you start.  The debugger is for LOOKING.  By the time an
error reaches it the run has already been abandoned, so there is no proceed, no
restart and no stepping.  The lesson called What it cannot do says why, and it
is worth reading before you form the opposite habit.'!
openingIt
	^TutorialLesson title: 'Opening it' text:
'The usual way in is an error you did not expect: evaluate anything that goes
wrong -- 1/0 will do -- and the window appears by itself.  Try that now, and
close the window it opens.

The deliberate way in is debug:, which runs a block and opens the debugger on
whatever goes wrong inside it.  Nothing escapes, so it is safe to leave in a
line you are only passing through:

Debugger debug: [1/0]
Debugger debug: [nil foo]
Debugger debug: [#(1 2 3) at: 99]

The block answers nil once you close the window, so debug: can be wrapped round
a line you are suspicious of without changing what the rest of the code does.

And you can open it on a stack that is not an error at all, which is how you
look at where you are:

Debugger openOn: thisContext message: ''just looking''

The message you pass is the line at the top of the right pane.  Whatever opened
it, the window is the same, and the rest of these lessons are about reading it.'!
theStack
	^TutorialLesson title: 'Reading the stack' text:
'The list on the left holds the frames, innermost first: the method that failed,
the method that called it, and so on out to the top.

Open one and look at the list, then come back here:

Debugger debug: [(OrderedCollection new) removeFirst]

The frames are objects, and the last thing opened leaves them where you can get
at them without the window:

Debugger frames size
(Debugger frames collect: [:each | each label]) asArray
Debugger fullStack

A frame knows rather more than its label:

Debugger frames first receiver
Debugger frames first method
Debugger frames first pc
Debugger frames last label

Frames of the Exception classes themselves are left out, and so are
doesNotUnderstand: and error:, which are only the universal way of raising an
error and say nothing the message text has not already said.  What is left is
your own code and the library methods it called.

Rows 1 and 2 above are inside the library, not inside your block; the frame you
usually want is the one in your own code, and you can find it by name rather
than by counting:

Debugger frames findFirst: [:each | each label startsWith: ''OrderedCollection>>'']

In the window you would just click the row.'!
theSource
	^TutorialLesson title: 'The source, with the line marked' text:
'The right pane normally shows the source of the selected frame with a > against
the statement that was running.  That mark is the first thing to look at: it
tells you how far the method got.

Open a debugger on something a few frames deep and read the marked source for
the second frame:

Debugger debug: [#(1 2 3) inject: 0 into: [:a :b | a / 0]]
Debugger markedSourceOf: (Debugger frames at: 2)

The mark comes from a line number the compiler recorded, which you can ask for
on its own:

Debugger lineOf: (Debugger frames at: 2)
Debugger lineOf: Debugger frames first

A block reports the line in the method it was written in, since that is the text
the source map refers to.

If you only want the text:

Debugger sourceOf: Debugger frames first

One warning about splitting source into lines yourself: String>>lines drops a
leading empty line, and a method filed in from a chunk begins with a newline, so
the numbers come out one short.  Use the debugger''s own splitter:

(Debugger linesOf: (Debugger sourceOf: Debugger frames first)) size'!
theVariables
	^TutorialLesson title: 'Variables by name' text:
'Choose variables from the right-button menu of the frame list and the right pane
shows self, then every argument and temporary of that frame BY NAME with its
value.  Names, not numbers, is the thing worth having: the virtual machine knows
temporaries only by their index, and the compiler keeps the names for this.

Open one and ask for the same text from here:

Debugger debug: [| total | total := 0. #(1 2 3) do: [:each | total := total + (each / 0)]. total]
Debugger describeVariablesOf: Debugger frames first

Try it on a method with arguments, where the difference is clearer:

Debugger debug: [3 between: 1 and: nil]
Debugger describeVariablesOf: Debugger frames first

You can also pull a single temporary out by name.  That reads the SELECTED
frame, which starts as the innermost one, so first choose the frame the
temporary is in -- clicking the row in the window does this, and detailAt: does
it from here:

Debugger debug: [| answer | answer := 42. answer / 0]
Debugger detailAt: (Debugger frames findFirst: [:each | each label endsWith: ''DoIt''])
Debugger tempNamed: ''answer''

A value that cannot be printed does not stop the pane: the debugger catches that
and writes a placeholder instead, because a debugger that fails while describing
a failure is no use to anybody.'!
theReceiver
	^TutorialLesson title: 'The receiver' text:
'The third thing the right pane can show is the receiver of the frame: what self
was, and each of its instance variables.

Make something with state in it and break inside one of its methods:

Object subclass: #Counter instanceVariableNames: ''count limit'' classVariableNames: '''' category: ''Tutorial''
Counter compile: ''bump   count := (count ifNil: [0]) + 1. ^count / (limit ifNil: [0])''
Debugger debug: [Counter new bump]
Debugger describeReceiverOf: (Debugger frames detect: [:each | each receiver isKindOf: Counter])

There are the two instance variables, count set to 1 and limit still nil, which
is the whole story of that bug in one line.

The menu also opens a full Inspector on the receiver, or on the frame itself,
which is worth knowing when the object is big enough that a list of values is
not enough:

(Debugger frames detect: [:each | each receiver isKindOf: Counter]) receiver class
(Debugger frames detect: [:each | each receiver isKindOf: Counter]) receiver inspect

An Inspector on the frame lets you look at the context object the same way, and
a context is an ordinary object here: it knows its sender, its receiver, its
method and its temporaries.'!
evaluatingInAFrame
	^TutorialLesson title: 'Evaluating in a frame' text:
'The most useful command in the menu is evaluate..., which asks for an expression
and runs it with self bound to the receiver of the selected frame.  Instance
variables are in scope, so you can ask the object questions it was never given a
method for.

Build one and try the same thing from here:

Object subclass: #Account instanceVariableNames: ''balance'' classVariableNames: '''' category: ''Tutorial''
Account compile: ''withdraw: anAmount   balance := (balance ifNil: [0]) - anAmount. ^balance / 0''
Debugger debug: [Account new withdraw: 10]
Debugger detailAt: (Debugger frames findFirst: [:each | each label startsWith: ''Account''])
Debugger receiver

Note the second line.  evaluate... works on the SELECTED frame, and the frame
selected to begin with is the innermost one, which here is inside the library
rather than inside withdraw:.  Clicking the row does this in the window.

evaluateSafely: is what does the work; it answers an Array of a boolean and the
value, so that a syntax error comes back as text rather than as another error:

Debugger receiver evaluateSafely: ''balance''
Debugger receiver evaluateSafely: ''balance abs + 1''
Debugger receiver evaluateSafely: ''balance +''

The last one is deliberately broken, and you get false and the compiler''s
complaint.  A mistake that only shows up when the code RUNS is a different
matter: that one is caught by the window, which prints it under your expression,
so you can try one thing after another without losing what you had.'!
whatItCannotDo
	^TutorialLesson title: 'What it cannot do' text:
'It cannot continue.

In some Smalltalks the debugger is a place you edit a method, restart the frame
and carry on.  Not here.  By the time an unhandled error reaches this debugger
the stack has already been abandoned, and the frames it is showing you are dead:

Debugger debug: [1/0]
Debugger frames first isDead

So the debugger is for reading, not for resuming.  Close the window, fix the
code, and run it again.

A live stack is a different matter, and the base system can do a surprising
amount with one.  thisContext is the running method as an object:

thisContext printString
thisContext sender printString

and a context that is still alive can be told to return a value:

| r | r := [:ctx | ctx return: 99. 1] value: thisContext. r

What you cannot do is that to a context the error machinery has already
unwound.  The next lesson is about the part of all this the compiler provides.

Two more things go to the plain walkback rather than the debugger: errors the
virtual machine raises outside Smalltalk, and a failure inside the debugger
itself, so that a broken debugger cannot hide an error from you.'!
theCompilerSupport
	^TutorialLesson title: 'What the compiler keeps' text:
'The debugger would have nothing to show without two things a CompiledMethod
records, both added for it and both part of the base system.

The names of the arguments and temporaries, arguments first:

(Integer compiledMethodAt: #factorial) tempNames
(Object compiledMethodAt: #printString) tempNames

and a source map: pairs of a bytecode position and an offset into the source,
one pair per statement.

(Integer compiledMethodAt: #factorial) sourceMap
(Integer compiledMethodAt: #factorial) sourceMap size

From those two the line being run can be worked out for any position:

(Integer compiledMethodAt: #factorial) lineForPC: 7
(Integer compiledMethodAt: #factorial) sourceOffsetForPC: 7

Make your own and look:

Object subclass: #Lines instanceVariableNames: '''' classVariableNames: '''' category: ''Tutorial''
Lines compile: ''three   | a b | a := 1. b := 2. ^a + b''
(Lines compiledMethodAt: #three) tempNames
(Lines compiledMethodAt: #three) lineForPC: 1

This is also why the debugger can show a method it has never seen before,
including one you compiled a moment ago from a string.'!
thisContext
	^TutorialLesson title: 'Looking around without an error' text:
'You do not have to break something to use the debugger.  Opening it on
thisContext shows the stack as it is right now, which is a good way to see what
the system is doing while it runs your code:

Debugger openOn: thisContext message: ''where am I''

Put it inside a method and you see the method it was called from:

Object subclass: #Peek instanceVariableNames: '''' classVariableNames: '''' category: ''Tutorial''
Peek compile: ''look   Debugger openOn: thisContext message: ''''inside look''''. ^thisContext sender printString''
Peek new look

The same idea without a window at all, for when you want the stack as text to
write into a log:

Debugger openOn: thisContext message: ''for the record''
Debugger fullStack

thisContext answers the same kind of object the debugger is built on, so
everything in the lesson about the stack works on it:

thisContext method
thisContext receiver printString
thisContext sender printString

Used sparingly this is a good way to answer where is this being called from,
which is a question a text search often cannot settle.'!
whatNext
	^TutorialLesson title: 'Where to go next' text:
'That is the debugger.  What to remember:

The > in the source is the statement that was running, and it is usually enough
on its own.

variables and receiver are where the answer actually is: a nil that should not
be nil, or a count that is one too many.

evaluate... lets you interrogate the object rather than guess.

It cannot continue; read, close, fix, run again.

Open it by hand on anything:

Debugger openOn: thisContext message: ''a look around''
Debugger debug: [self somethingSuspicious]

The package README is packages/Debugger/README.md, and the code is small enough
to read in one sitting: browse the Debugger category.

The debugger is also the reason the base system keeps tempNames and sourceMap on
every CompiledMethod, which anything else can use:

(Debugger class compiledMethodAt: #lineOf:) tempNames

Other tutorials in this image:

Smalltalk tutorialNames

and the one for the language itself, which is filed in on demand:

Smalltalk tutorial'! !
