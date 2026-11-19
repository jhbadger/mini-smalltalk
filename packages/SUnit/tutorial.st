"The SUnit tutorial: writing tests, the assertions, setUp and tearDown, suites, and the test runner window.
Start it with   SUnitTutorial go"

AbstractTutorial subclass: #SUnitTutorial instanceVariableNames: '' classVariableNames: '' category: 'SUnit'!

!SUnitTutorial class methodsFor: 'the lessons'!
tutorialName
	^'SUnit'!
lessonSelectors
	^#(#welcome #yourFirstTest #theAssertions #betterMessages #floatsAndCollections #expectingAnError
		#setUpAndTearDown #failureOrError #runningTests #readingTheResult #theRunner #whatNext)! !

!SUnitTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'SUnit is the testing framework Kent Beck wrote for Smalltalk, and the ancestor
of every xUnit since.  A test is a method; a group of tests is a class; running
them tells you which ones still work.

Everything in this tutorial is live.  Select a line and press ctrl-P (print it)
to run it and see the answer, or ctrl-D (do it) to run it without printing.

The system already has tests of its own.  Run all of them:

TestSuite all run

The answer is a TestResult, and it prints as a tally.  Ask it for more:

TestSuite all run report

If you have other packages loaded their tests are in there too, which is why
that may take a moment.  To see how many test classes the image holds:

(TestCase allSubclasses reject: [:each | each isAbstract]) size

The next lesson writes a test from scratch.'!
yourFirstTest
	^TutorialLesson title: 'Your first test' text:
'A test class is a subclass of TestCase.  Make one:

TestCase subclass: #MoneyTest instanceVariableNames: '''' classVariableNames: '''' category: ''Tutorial tests''

A test is a method whose name begins with test, and it takes no arguments.  You
would normally type one into a System Browser, but a method can also be compiled
from a string, which is how this tutorial will do it:

MoneyTest compile: ''testAdding   self assert: 1 + 1 equals: 2''

SUnit finds the tests by their names.  Ask the class what it has:

MoneyTest testSelectors

Now run them:

MoneyTest run

One run, one passed.  Add a test that does not hold:

MoneyTest compile: ''testSubtracting   self assert: 5 - 3 equals: 1''
MoneyTest run
MoneyTest run report

The report names the test that failed and says what it expected.  That message
is the whole point of a testing framework: a test that fails must tell you what
went wrong without your having to go and look.'!
theAssertions
	^TutorialLesson title: 'The assertions' text:
'Inside a test, self is the TestCase, and you make claims about the world by
sending it assertions.  The two simplest take a boolean:

TestCase subclass: #AssertTest instanceVariableNames: '''' classVariableNames: '''' category: ''Tutorial tests''
AssertTest compile: ''testPlain   self assert: 3 < 4. self deny: 4 < 3''
AssertTest run

An assertion that does not hold stops the test there and marks it failed; the
rest of the method does not run.  Each one can carry a description, which is
printed instead of the standard message:

AssertTest compile: ''testDescribed   self assert: 3 < 4 description: ''''three is less than four''''''
AssertTest run

You can also fail on purpose, which is useful while you are still working out
what a method should do:

AssertTest compile: ''testNotWrittenYet   self fail: ''''no rounding rule agreed yet''''''
AssertTest run report

How many assertions a test made is counted, so a test that quietly checks
nothing is easy to spot:

| t | t := AssertTest selector: #testPlain. t runCase. t assertionCount'!
betterMessages
	^TutorialLesson title: 'Saying what you expected' text:
'assert: takes a boolean, so by the time SUnit sees it the two values are gone
and all it can say is that something was false.  The comparing assertions keep
both values and put them in the message, which is almost always what you want:

TestCase subclass: #CompareTest instanceVariableNames: '''' classVariableNames: '''' category: ''Tutorial tests''
CompareTest compile: ''testWeak   self assert: 2 + 2 = 5''
CompareTest compile: ''testStrong   self assert: 2 + 2 equals: 5''
CompareTest run report

Read the two messages.  The first says only that an assertion failed; the second
says it expected 5 and got 4.  Prefer assert:equals: whenever you are comparing
two things.

Its opposite is deny:equals:, and there is a pair for identity, which asks for
the very same object rather than an equal one:

CompareTest compile: ''testIdentity   self assert: #abc identicalTo: #abc. self deny: ''''abc'''' copy identicalTo: ''''abc''''''
CompareTest run

Two Symbols that read the same are one object; two Strings that read the same
need not be.  That distinction is worth a test of its own when it matters.'!
floatsAndCollections
	^TutorialLesson title: 'Floats, collections and kinds' text:
'Floats hardly ever come out exactly equal, so comparing them with equals: is a
mistake waiting to happen:

0.1 + 0.2 = 0.3

Use closeTo: instead, which allows a small difference, or say how small:

TestCase subclass: #NearTest instanceVariableNames: '''' classVariableNames: '''' category: ''Tutorial tests''
NearTest compile: ''testFloats   self assert: 0.1 + 0.2 closeTo: 0.3. self assert: 1.0 closeTo: 1.001 within: 0.01''
NearTest run

For collections there are assertions that read better than poking at sizes:

NearTest compile: ''testCollections   self assert: #(1 2 3) includes: 2. self assertEmpty: Set new. self assertNotEmpty: #(1)''
NearTest run

And for the class of a thing, assert:isKindOf: says it in one line and gives a
good message when it is wrong:

NearTest compile: ''testKind   self assert: 3 isKindOf: Number. self assert: ''''a'''' isKindOf: String''
NearTest run
NearTest run report'!
expectingAnError
	^TutorialLesson title: 'Expecting an error' text:
'Code that should refuse bad input needs a test that the refusal happens.  Put
the offending code in a block and say what it must signal:

TestCase subclass: #RaiseTest instanceVariableNames: '''' classVariableNames: '''' category: ''Tutorial tests''
RaiseTest compile: ''testDivide   self should: [1/0] raise: ZeroDivide''
RaiseTest run

If the block runs to the end without signalling, the test fails:

RaiseTest compile: ''testNoError   self should: [1/1] raise: ZeroDivide''
RaiseTest run report

should:raise: answers the exception, so you can go on and check what it said:

| e | e := RaiseTest new should: [nil foo] raise: MessageNotUnderstood. e messageText

The other way round, shouldnt:raise: insists that something does not go wrong,
which is the test you write after fixing a bug:

RaiseTest compile: ''testSafe   self shouldnt: [1/1] raise: ZeroDivide''
RaiseTest run

An exception class you did not expect is not caught, so it is reported as an
error rather than quietly passing.'!
setUpAndTearDown
	^TutorialLesson title: 'setUp and tearDown' text:
'When several tests need the same thing to start from, build it in setUp.  SUnit
makes a fresh instance of the TestCase for every test, runs setUp, runs the
test, then runs tearDown, whatever happened in between.

TestCase subclass: #FixtureTest instanceVariableNames: ''items'' classVariableNames: '''' category: ''Tutorial tests''
FixtureTest compile: ''setUp   items := OrderedCollection new. items add: 1; add: 2''
FixtureTest compile: ''testSize   self assert: items size equals: 2''
FixtureTest compile: ''testAdding   items add: 3. self assert: items size equals: 3''
FixtureTest run

Both tests passed, and the second one added to items without upsetting the
first.  That is the point of the fresh instance: tests cannot leak into one
another, so they can be run in any order.

tearDown undoes anything setUp did to the world outside the test, such as a file
or a global.  It runs even when the test failed, which is why cleaning up there
rather than at the end of the test is the safer habit:

FixtureTest compile: ''tearDown   items := nil''
FixtureTest run

If setUp itself fails the test is reported as an error, with setUp named in the
walkback, which tells you at once that it was the fixture and not the test.'!
failureOrError
	^TutorialLesson title: 'Failure or error' text:
'SUnit separates two kinds of bad news, and the difference matters.

A FAILURE is an assertion that did not hold: the code ran, and the answer was
not what the test said it should be.

An ERROR is anything else going wrong: the code could not even finish.

The SUnit package ships a class of tests that go wrong on purpose, so that SUnit
can be tested with them.  Run them and see both:

SUnitExampleTest run
SUnitExampleTest run report

Count them separately:

SUnitExampleTest run failureCount
SUnitExampleTest run errorCount
(SUnitExampleTest run: #testFails) failures first isFailure
(SUnitExampleTest run: #testErrors) errors first isError

A failure usually means the code is wrong or the test is out of date.  An error
usually means something is wrong further away than the test was looking.  When
you have both, read the errors first.

An outcome also carries a walkback, trimmed down to your own code:

(SUnitExampleTest run: #testFails) failures first walkback

Those example tests would spoil a run of everything, so the class answers false
to shouldRun and TestSuite all leaves it out:

SUnitExampleTest shouldRun'!
runningTests
	^TutorialLesson title: 'Running tests' text:
'There are four ways to run tests, from one test to the whole image.

One test on its own, which is what you do while writing it:

SUnitTest run: #testAssert

Every test in a class:

SUnitTest run

A suite you put together yourself, which is how you run two packages worth of
tests and nothing else:

(TestSuite forClasses: (Array with: SUnitTest with: SUnitExampleTest)) run

Everything in the image, leaving out the classes that answer false to shouldRun:

TestSuite all run

A suite knows its tests before it runs them, which is sometimes what you want to
look at:

SUnitTest suite size
(TestSuite forClasses: (Array with: SUnitTest)) printString

There is also a shortcut that runs everything and writes the report to the
System Transcript; do it (ctrl-D) rather than print it:

Smalltalk runTests

And when a test goes wrong and you want the debugger rather than a report, debug:
runs it with nothing caught:

SUnitTest debug: #testAssert'!
readingTheResult
	^TutorialLesson title: 'Reading a TestResult' text:
'Every way of running answers a TestResult.  It prints as a tally:

TestSuite all run printString

and answers each part of it:

| r | r := SUnitTest run. Array with: r runCount with: r passedCount with: r failureCount with: r errorCount

The one question you usually want is whether anything went wrong, which is what
a build script asks:

SUnitTest run hasPassed

The outcomes themselves are objects.  Each knows its test, whether it was a
failure or an error, its message and its walkback:

| r | r := SUnitExampleTest run. r failures first test name
| r | r := SUnitExampleTest run. r failures first message
| r | r := SUnitExampleTest run. (r outcomes collect: [:each | each kind]) asArray

report puts all of that together as text, which is what the test runner shows
and what make check prints:

SUnitExampleTest run report'!
theRunner
	^TutorialLesson title: 'The test runner window' text:
'Open the test runner from the System menu (right-click the desktop, then test
runner), or from here:

TestRunner open

The left pane lists every test class with its tests underneath.  The menu on the
right button runs all of them, or just the selected class, or just the selected
test; the right pane shows the result, and for a failure the message and the
walkback.  After a run each row is marked with a space for a pass, F for a
failure and E for an error.

A filter narrows the list, which is what you want when the image holds hundreds
of tests and you care about ten:

TestRunner filter: ''SUnit''
TestRunner listItems
TestRunner runAll

Clear it again with nil:

TestRunner filter: nil
TestRunner testClasses size

You can also open the runner already narrowed to one class:

TestRunner openOn: SUnitTest'!
whatNext
	^TutorialLesson title: 'Where to go next' text:
'That is SUnit.  What to do with it:

Write the test first.  A test written before the code says what the code is for,
and it fails for the right reason to begin with, which is the only proof that it
is testing anything at all.

Keep each test small and give it a name that says what it claims.  When it
fails, the name is the first thing you read.

Browse the real thing: the class SUnit-Tests category holds SUnit testing itself,
and every package in packages/ has a tests.st written this way.  They are worth
reading as examples of how much a test should try to say.

The package README is packages/SUnit/README.md.

To see how the rest of the system is tested from outside Smalltalk, look at the
tests/tests.txt file in any package: one expression and one expected answer per
line, run by make check.

Other tutorials in this image:

Smalltalk tutorialNames

and to start one:

Tutorial go'! !
