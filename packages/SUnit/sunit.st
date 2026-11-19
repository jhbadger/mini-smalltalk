"SUnit: the Smalltalk testing framework.

	TestCase subclass: #MyTests instanceVariableNames: '' classVariableNames: '' category: 'My tests'

then write methods whose names begin with test:

	testAddition
		self assert: 3 + 4 equals: 7

and run them:

	MyTests run                     every test in the class, answering a TestResult
	MyTests run: #testAddition      one test
	TestSuite all run                every TestCase in the system
	Smalltalk runTests               the same, printed to the Transcript

setUp runs before each test and tearDown after it, whether the test passed or not."

Object subclass: #TestCase instanceVariableNames: 'testSelector assertions' classVariableNames: '' category: 'SUnit'!
Object subclass: #TestResult instanceVariableNames: 'passes failures errors started stopped' classVariableNames: '' category: 'SUnit'!
Object subclass: #TestSuite instanceVariableNames: 'name tests' classVariableNames: '' category: 'SUnit'!
Object subclass: #TestOutcome instanceVariableNames: 'test kind message walkback' classVariableNames: '' category: 'SUnit'!
Error subclass: #TestFailure instanceVariableNames: '' classVariableNames: '' category: 'SUnit'!

"---- TestCase ----"

!TestCase class methodsFor: 'instance creation'!
selector: aSymbol
	^self basicNew setSelector: aSymbol!
testSelectors
	"every method of the class whose name begins with test, in order"
	^(self selectors select: [:s | (s size > 4 and: [(s copyFrom: 1 to: 4) = 'test'])]) asSortedCollection asArray!
isAbstract
	"a TestCase with no tests of its own is a superclass for other tests, not a test itself"
	^self testSelectors isEmpty!
shouldRun
	"false for a class whose tests are meant to fail (an example used by other tests); TestSuite all skips those"
	^true!
suite
	| suite |
	suite := TestSuite named: self name.
	self testSelectors do: [:s | suite addTest: (self selector: s)].
	^suite! !

!TestCase class methodsFor: 'running'!
run
	"run every test in this class and answer the TestResult"
	^self suite run!
run: aSelector
	| result |
	result := TestResult new.
	(self selector: aSelector) run: result.
	^result!
debug: aSelector
	"run one test without catching anything, so an error opens the debugger (or the walkback)"
	^(self selector: aSelector) runCase! !

!TestCase methodsFor: 'private'!
setSelector: aSymbol
	testSelector := aSymbol. assertions := 0! !

!TestCase methodsFor: 'accessing'!
selector
	^testSelector!
assertionCount
	"how many assertions the test made (a test that makes none is suspicious)"
	^assertions ifNil: [0]!
name
	^self class name, '>>', testSelector!
printOn: aStream
	aStream nextPutAll: self name! !

!TestCase methodsFor: 'running'!
setUp
	"run before each test; subclasses override it"!
tearDown
	"run after each test, whether it passed or not; subclasses override it"!
runCase
	"set up, run the test, tear down; anything that goes wrong is left to the caller"
	assertions := 0.
	self setUp.
	[self perform: testSelector] ensure: [self tearDown]!
run: aResult
	"run the test, recording what happened: a failed assertion is a failure, anything else is an error"
	aResult startTest: self.
	[[self runCase.
	  aResult addPass: self]
		on: TestFailure
		do: [:e | aResult addFailure: self message: e messageText walkback: (self walkbackOf: e)]]
		on: Error
		do: [:e | aResult addError: self message: (e messageText ifNil: [e class name]) walkback: (self walkbackOf: e)].
	^aResult!
walkbackOf: anException
	"where the exception came from: the frames above the framework, without the plumbing"
	| out c n cls |
	out := WriteStream on: String new.
	c := anException signalerContext.
	n := 0.
	[c notNil and: [n < 40]] whileTrue: [
		cls := c method methodClass.
		cls notNil ifTrue: [
			cls isMeta ifTrue: [cls := cls theNonMetaClass].
			cls == TestCase
				ifTrue: [
					"the assertion helpers are passed over; runCase is where the framework begins"
					(c selector == #runCase or: [c selector == #run:]) ifTrue: [^out contents]]
				ifFalse: [(self isPlumbing: cls) ifFalse: [out nextPutAll: c printString; nl. n := n + 1]]].
		c := c sender].
	^out contents!
isPlumbing: aClass
	"the framework and the blocks it runs the test in, which say nothing about why the test failed"
	^aClass == BlockClosure
		or: [aClass == TestSuite
		or: [aClass == Exception or: [aClass inheritsFrom: Exception]]]!
!TestCase methodsFor: 'asserting'!
countAssertion
	assertions := (assertions ifNil: [0]) + 1!
assert: aBoolean
	self countAssertion.
	aBoolean == true ifFalse: [^self signalFailure: 'assertion failed']!
assert: aBoolean description: aString
	self countAssertion.
	aBoolean == true ifFalse: [^self signalFailure: aString]!
deny: aBoolean
	self countAssertion.
	aBoolean == false ifFalse: [^self signalFailure: 'denial failed']!
deny: aBoolean description: aString
	self countAssertion.
	aBoolean == false ifFalse: [^self signalFailure: aString]!
assert: actual equals: expected
	self countAssertion.
	actual = expected ifFalse: [
		^self signalFailure: 'expected ', (self describe: expected), ' but got ', (self describe: actual)]!
deny: actual equals: expected
	self countAssertion.
	actual = expected ifTrue: [^self signalFailure: 'did not expect ', (self describe: expected)]!
assert: actual identicalTo: expected
	self countAssertion.
	actual == expected ifFalse: [
		^self signalFailure: 'expected the very object ', (self describe: expected), ' but got ', (self describe: actual)]!
deny: actual identicalTo: expected
	self countAssertion.
	actual == expected ifTrue: [^self signalFailure: 'did not expect the very object ', (self describe: expected)]!
assert: actual closeTo: expected
	^self assert: actual closeTo: expected within: 0.0001!
assert: actual closeTo: expected within: epsilon
	self countAssertion.
	(actual - expected) abs <= epsilon ifFalse: [
		^self signalFailure: 'expected ', (self describe: expected), ' to within ', epsilon printString, ' but got ', (self describe: actual)]!
assert: aCollection includes: anObject
	self countAssertion.
	(aCollection includes: anObject) ifFalse: [
		^self signalFailure: (self describe: aCollection), ' does not include ', (self describe: anObject)]!
assertEmpty: aCollection
	self countAssertion.
	aCollection isEmpty ifFalse: [^self signalFailure: (self describe: aCollection), ' is not empty']!
assertNotEmpty: aCollection
	self countAssertion.
	aCollection isEmpty ifTrue: [^self signalFailure: 'the collection is empty']!
assert: anObject isKindOf: aClass
	self countAssertion.
	(anObject isKindOf: aClass) ifFalse: [
		^self signalFailure: (self describe: anObject), ' is a ', anObject class name, ', not a ', aClass name]!
should: aBlock raise: anExceptionClass
	"the block must signal that exception (or one of its subclasses)"
	self countAssertion.
	^[aBlock value.
	  self signalFailure: 'expected ', anExceptionClass name, ' but nothing was signalled']
		on: anExceptionClass
		do: [:e | e return: e]!
should: aBlock raise: anExceptionClass description: aString
	self countAssertion.
	^[aBlock value. self signalFailure: aString]
		on: anExceptionClass
		do: [:e | e return: e]!
shouldnt: aBlock raise: anExceptionClass
	self countAssertion.
	^[aBlock value]
		on: anExceptionClass
		do: [:e | self signalFailure: 'unexpected ', anExceptionClass name, ': ', e messageText]!
fail
	^self signalFailure: 'failed'!
fail: aString
	^self signalFailure: aString!
describe: anObject
	^[anObject printStringLimitedTo: 120] on: Error do: [:e | '<an object that cannot be printed>']!
signalFailure: aString
	^TestFailure new signal: aString! !

"---- what went wrong ----"

!TestOutcome class methodsFor: 'instance creation'!
test: aTest kind: aSymbol message: aString walkback: aWalkback
	^self basicNew setTest: aTest kind: aSymbol message: aString walkback: aWalkback! !

!TestOutcome methodsFor: 'accessing'!
setTest: aTest kind: aSymbol message: aString walkback: aWalkback
	test := aTest. kind := aSymbol. message := aString. walkback := aWalkback!
test
	^test!
kind
	"#failure for an assertion that did not hold, #error for anything else"
	^kind!
message
	^message ifNil: ['']!
walkback
	^walkback ifNil: ['']!
isFailure
	^kind == #failure!
isError
	^kind == #error!
printOn: aStream
	aStream nextPutAll: (self isFailure ifTrue: ['FAILURE '] ifFalse: ['ERROR   ']);
		nextPutAll: test name; nextPutAll: ': '; nextPutAll: self message!
details
	| out |
	out := WriteStream on: String new.
	out nextPutAll: self printString; nl.
	self walkback notEmpty ifTrue: [out nl; nextPutAll: self walkback].
	^out contents! !

"---- TestResult ----"

!TestResult class methodsFor: 'instance creation'!
new
	^self basicNew init! !

!TestResult methodsFor: 'private'!
init
	passes := OrderedCollection new.
	failures := OrderedCollection new.
	errors := OrderedCollection new! !

!TestResult methodsFor: 'recording'!
startTest: aTest
	started := aTest!
addPass: aTest
	passes add: aTest!
addFailure: aTest message: aString walkback: aWalkback
	failures add: (TestOutcome test: aTest kind: #failure message: aString walkback: aWalkback)!
addError: aTest message: aString walkback: aWalkback
	errors add: (TestOutcome test: aTest kind: #error message: aString walkback: aWalkback)!
addResult: another
	passes addAll: another passes.
	failures addAll: another failures.
	errors addAll: another errors! !

!TestResult methodsFor: 'accessing'!
passes
	^passes!
failures
	^failures!
errors
	^errors!
outcomes
	"the failures and the errors together, in that order"
	^failures, errors!
passedCount
	^passes size!
failureCount
	^failures size!
errorCount
	^errors size!
runCount
	^passes size + failures size + errors size!
hasPassed
	^failures isEmpty and: [errors isEmpty]!
isSuccessful
	^self hasPassed! !

!TestResult methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: self runCount printString, ' run, ', self passedCount printString, ' passed, ',
		self failureCount printString, ' failed, ', self errorCount printString, ' errors'!
summary
	^self printString!
report
	"the summary and, under it, every failure and error"
	| out |
	out := WriteStream on: String new.
	out nextPutAll: self printString; nl.
	self outcomes do: [:o | out nl; nextPutAll: o details].
	^out contents! !

"---- TestSuite ----"

!TestSuite class methodsFor: 'instance creation'!
named: aString
	^self basicNew setName: aString!
new
	^self named: 'tests'!
all
	"every test in every TestCase subclass in the system"
	| suite |
	suite := self named: 'all tests'.
	TestCase allSubclasses do: [:c |
		(c isAbstract not and: [c shouldRun]) ifTrue: [c testSelectors do: [:s | suite addTest: (c selector: s)]]].
	^suite!
forClasses: aCollection
	| suite |
	suite := self named: 'tests'.
	aCollection do: [:c | c testSelectors do: [:s | suite addTest: (c selector: s)]].
	^suite! !

!TestSuite methodsFor: 'accessing'!
setName: aString
	name := aString. tests := OrderedCollection new!
name
	^name!
name: aString
	name := aString!
tests
	^tests!
size
	^tests size!
addTest: aTestCase
	tests add: aTestCase!
addTests: aCollection
	tests addAll: aCollection!
do: aBlock
	tests do: aBlock!
printOn: aStream
	aStream nextPutAll: 'TestSuite('; nextPutAll: name; nextPutAll: ', '; print: tests size; nextPutAll: ' tests)'! !

!TestSuite methodsFor: 'running'!
run
	| result |
	result := TestResult new.
	self run: result.
	^result!
run: aResult
	tests do: [:t | t run: aResult].
	^aResult! !

"---- running everything ----"

!SystemDictionary methodsFor: 'testing'!
runTests
	"run every test in the system and report to the Transcript"
	| result |
	result := TestSuite all run.
	Transcript showCr: result report.
	^result!
testSuite
	^TestSuite all! !
