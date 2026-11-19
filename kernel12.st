"The machinery behind every tutorial in the system.

A tutorial is a class, not a document: a subclass of AbstractTutorial whose lessonSelectors name methods that
each answer a TutorialLesson. The lesson text is shown in an ordinary editable workspace window, so the
examples in it can be selected and run where they stand, which is the whole point.

Writing one takes a subclass, two class-side methods -- tutorialName, answering what to call it, and
lessonSelectors, answering the lesson selectors in reading order -- and one method per lesson answering
TutorialLesson title: ... text: ... . Then WidgetTutorial go opens it. (tutorial.st is the worked example,
and every package in packages/ has one.)

AbstractTutorial allTutorials finds every tutorial in the image, which is how the System menu lists them, so
a package that defines one needs to do nothing else to be found.

Where each reader has got to is remembered per tutorial, so several can be open at once without losing
anybody's place."

Object subclass: #TutorialLesson instanceVariableNames: 'title text' classVariableNames: '' category: 'Tutorial'!
Object subclass: #AbstractTutorial instanceVariableNames: '' classVariableNames: 'Positions' category: 'Tutorial'!

"---- one lesson ----"

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

"---- what a tutorial must say for itself ----"

!AbstractTutorial class methodsFor: 'subclasses must answer these'!
lessonSelectors
	"the class-side selectors of the lessons, in the order they should be read"
	^#()!
tutorialName
	"what to call this tutorial in a title and in a menu"
	^self name asString! !

!AbstractTutorial class methodsFor: 'finding the tutorials'!
isAbstract
	^self lessonSelectors isEmpty!
allTutorials
	"every tutorial class in the image, by name"
	^(AbstractTutorial allSubclasses reject: [:each | each isAbstract])
		asSortedCollection: [:a :b | a tutorialName <= b tutorialName]!
tutorialNames
	^(self allTutorials collect: [:each | each tutorialName]) asArray!
named: aName
	"the tutorial with that name, or nil"
	self allTutorials do: [:each |
		(each tutorialName asLowercase = aName asString asLowercase
			or: [each name asString asLowercase = aName asString asLowercase]) ifTrue: [^each]].
	^nil! !

!AbstractTutorial class methodsFor: 'the lessons'!
lessons
	^self lessonSelectors collect: [:sel | self perform: sel]!
lesson
	"the lesson being read"
	^self lessons at: self lessonNumber!
lessonCount
	^self lessonSelectors size!
titles
	^(self lessons collect: [:each | each title]) asArray!
tutorial
	"the lessons, as ProfStef calls them"
	^self lessons! !

!AbstractTutorial class methodsFor: 'where the reader is'!
positions
	"where the reader has got to in each tutorial, kept by class name so that several tutorials can be
	open at once without losing anybody's place"
	^Positions ifNil: [Positions := Dictionary new]!
lessonNumber
	^self positions at: self name ifAbsent: [1]!
lessonNumber: anInteger
	| n |
	n := anInteger.
	self lessonCount = 0 ifTrue: [^1].
	n := (n max: 1) min: self lessonCount.
	self positions at: self name put: n.
	^n!
reset
	self positions removeKey: self name ifAbsent: [nil]! !

!AbstractTutorial class methodsFor: 'navigation'!
go
	"start, or carry on where you were"
	^self show!
start
	self lessonNumber: 1.
	^self show!
first
	^self start!
last
	self lessonNumber: self lessonCount.
	^self show!
next
	self lessonNumber: self lessonNumber + 1.
	^self show!
previous
	self lessonNumber: self lessonNumber - 1.
	^self show!
goTo: aNumberOrTitle
	"a lesson number, or the beginning of a lesson title"
	| i |
	aNumberOrTitle isNumber
		ifTrue: [self lessonNumber: aNumberOrTitle truncated]
		ifFalse: [
			i := self lessons findFirst: [:l |
				l title asLowercase startsWith: aNumberOrTitle asString asLowercase].
			i = 0 ifTrue: [^self error: 'no lesson called ', aNumberOrTitle printString].
			self lessonNumber: i].
	^self show!
goOn: aNumber
	"ProfStef's name for goTo:"
	^self goTo: aNumber! !

!AbstractTutorial class methodsFor: 'checking the examples'!
lessonLines
	"every line of every lesson, as an Array of lesson number and line"
	| out |
	out := OrderedCollection new.
	self lessons doWithIndex: [:lesson :n |
		| start text |
		text := lesson text.
		start := 1.
		1 to: text size do: [:i |
			(text at: i) = Character lf ifTrue: [
				out add: (Array with: n with: (text copyFrom: start to: i - 1)).
				start := i + 1]].
		out add: (Array with: n with: (text copyFrom: start to: text size))].
	^out!
exampleLines
	"the lines of the lessons that are meant to be run: the ones at the left margin that begin with a
	bracket, a literal, a temporary declaration, or the name of something the system knows about.
	A line of prose starts with an ordinary word, and an example that is too long for one line is
	indented, so neither is picked up here."
	^((self lessonLines select: [:each | self isExampleLine: (each at: 2)])
		collect: [:each | each at: 2]) asArray!
isExampleLine: aLine
	"a trailing space can be part of an example -- think of  upTo: $  -- so the line is taken as it
	stands and only its first character decides"
	| src c i word |
	aLine isEmpty ifTrue: [^false].
	aLine first isSeparator ifTrue: [^false].
	src := aLine.
	c := src first.
	('(|[''#$' includes: c) ifTrue: [^true].
	c isDigit ifTrue: [^true].
	c isUppercase ifFalse: [^false].
	i := 1.
	[i <= src size and: [(src at: i) isLetter or: [(src at: i) isDigit]]] whileTrue: [i := i + 1].
	word := src copyFrom: 1 to: i - 1.
	i > src size ifTrue: [^self isKnownGlobal: word].
	^(src at: i) isSeparator and: [self isKnownGlobal: word]!
isKnownGlobal: aWord
	"a global that holds something -- a class, the Transcript, Smalltalk itself. Compiling an example
	registers any name it mentions, with nil in it, so merely being a key is not enough: without this
	a later line of prose beginning with that word would be mistaken for an example."
	^(Smalltalk at: aWord asSymbol ifAbsent: [nil]) notNil!
unreadableExamples
	"the examples the compiler cannot read, each with what it said. Should be empty; a tutorial whose
	examples do not even compile is worse than no tutorial. Whether they all ANSWER something sensible
	is a question only running them settles, and that is the author's job."
	| out |
	out := OrderedCollection new.
	self exampleLines do: [:src |
		| r |
		r := nil compileSafely: src.
		(r at: 1) ifFalse: [out add: (Array with: src with: (r at: 2))].
		((src occurrencesOf: $') odd) ifTrue: [
			out add: (Array with: src with: 'the string literal is never closed')]].
	^out asArray!
exampleCheck
	"how many examples there are and how many the compiler cannot read, in one pass over the lessons.
	Building the lessons is not free, so a test that wants both numbers should ask for them together."
	| lines bad |
	lines := self exampleLines.
	bad := 0.
	lines do: [:src |
		(((nil compileSafely: src) at: 1) not or: [(src occurrencesOf: $') odd])
			ifTrue: [bad := bad + 1]].
	^Array with: lines size with: bad!
checkExamples
	"a report on the examples: how many there are and anything the compiler cannot read"
	| bad out |
	bad := self unreadableExamples.
	out := WriteStream on: String new.
	out nextPutAll: self tutorialName; nextPutAll: ' tutorial: '; print: self lessonCount;
		nextPutAll: ' lessons, '; print: self exampleLines size; nextPutAll: ' examples'; nl.
	bad isEmpty
		ifTrue: [out nextPutAll: 'every example reads'; nl]
		ifFalse: [bad do: [:each |
			out nextPutAll: (each at: 1); nl; nextPutAll: '    --> '; nextPutAll: (each at: 2); nl]].
	^out contents! !

!AbstractTutorial class methodsFor: 'displaying'!
show
	| l s n |
	self lessonCount = 0 ifTrue: [^self error: self name, ' has no lessons'].
	l := self lesson. n := self lessonNumber.
	s := WriteStream on: String new.
	s nextPutAll: self tutorialName; nextPutAll: ' Tutorial  --  lesson '; print: n;
		nextPutAll: ' of '; print: self lessonCount; nextPutAll: ':  '; nextPutAll: l title; cr.
	s nextPutAll: (String new: 72 withAll: $-); cr; cr.
	s nextPutAll: l text; cr; cr.
	s nextPutAll: (String new: 72 withAll: $-); cr.
	s nextPutAll: 'Select a line below and do it (ctrl-D) to move on:'; cr.
	n < self lessonCount ifTrue: [s nextPutAll: '    ', self name, ' next'; cr].
	n > 1 ifTrue: [s nextPutAll: '    ', self name, ' previous'; cr].
	s nextPutAll: '    ', self name, ' contents'; cr.
	self openWindowNamed: self tutorialName, ' ', n printString, '/', self lessonCount printString,
		': ', l title contents: s contents.
	^l!
contents
	"the table of contents"
	| s here |
	s := WriteStream on: String new.
	here := self lessonNumber.
	s nextPutAll: self tutorialName; nextPutAll: ' Tutorial  --  contents'; cr; cr.
	self lessons doWithIndex: [:l :i |
		s nextPutAll: (i printPaddedWith: $  to: 3); nextPutAll: '.  '; nextPutAll: l title.
		i = here ifTrue: [s nextPutAll: '   <-- you are here'].
		s cr].
	s cr; nextPutAll: 'Jump to a lesson with, for example:   ', self name, ' goTo: 3',
		'      or      ', self name, ' goTo: ''', self lessons first title, ''''; cr.
	s nextPutAll: 'Carry on where you were with:          ', self name, ' show'; cr.
	self openWindowNamed: self tutorialName, ' tutorial: contents' contents: s contents!
help
	^self contents!
openWindowNamed: aTitle contents: aString
	"shown in a window by the user interface; printed on the Transcript when there is none"
	<primitive: 180>
	Transcript show: aString; cr! !

!SystemDictionary methodsFor: 'tutorials'!
tutorials
	"the tutorial classes in the image. A tutorial a package ships but has not been asked for yet is
	not in here; tutorialNames knows about those too."
	^AbstractTutorial allTutorials!
tutorialNames
	"every tutorial you can start: the ones in the image, the one for the language, and the one each
	loaded package ships. A tutorial is documentation rather than code the package needs, so it is
	left on disk until somebody asks for it; an image that never opens one does not carry any."
	| names |
	names := AbstractTutorial tutorialNames asOrderedCollection.
	((names includes: 'Smalltalk') not and: [(self tutorialFileFor: 'Smalltalk') notNil])
		ifTrue: [names add: 'Smalltalk'].
	self loadedPackages do: [:each |
		((names includes: each) not and: [(self tutorialFileFor: each) notNil])
			ifTrue: [names add: each]].
	^(names asSortedCollection: [:a :b | a <= b]) asArray!
tutorialFileFor: aName
	"the file that holds that tutorial, or nil. The language's own lives beside the kernel sources;
	a package's lives in its folder and is called tutorial.st."
	| path |
	aName = 'Smalltalk'
		ifTrue: [path := self kernelDirectory, '/tutorial.st']
		ifFalse: [
			(self isPackageLoaded: aName) ifFalse: [^nil].
			path := (self packagePath: aName), '/tutorial.st'].
	^(FileStream exists: path) ifTrue: [path] ifFalse: [nil]!
tutorialNamed: aName
	"the tutorial class, filing it in first when it is not in the image yet"
	| t file r |
	t := AbstractTutorial named: aName.
	t notNil ifTrue: [^t].
	file := self tutorialFileFor: aName.
	file isNil ifTrue: [^nil].
	r := self primLoadFile: file.      "not through fileIn:, so it is not copied into the changes file"
	r == true ifFalse: [^self error: 'could not read ', file, ': ', r].
	^AbstractTutorial named: aName!
startTutorial: aName
	"open that tutorial, reading it in if this is the first time it has been asked for"
	| t |
	t := self tutorialNamed: aName.
	t isNil ifTrue: [^self error: 'no tutorial called ', aName printString].
	^t go!
tutorial
	"the tutorial for the language itself"
	^self startTutorial: 'Smalltalk'!
tutorialListing
	"one line per tutorial for the menu: its name, and how many lessons it has once it is in"
	| names width |
	names := self tutorialNames.
	width := 4.
	names do: [:each | width := width max: each size].
	^names collect: [:each |
		| t |
		t := AbstractTutorial named: each.
		(each, (String new: width - each size + 3 withAll: (Character value: 32))),
			(t isNil ifTrue: ['not read in yet'] ifFalse: [t lessonCount printString, ' lessons'])]! !
