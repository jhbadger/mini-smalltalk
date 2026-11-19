"SUnit testing itself: every assertion, the difference between a failure and an error, setUp and tearDown,
and what a TestResult reports. ExampleTestCase holds tests that are meant to fail, so the real tests can
check that they fail in the right way; it is not run by TestSuite all because its name is checked for."

TestCase subclass: #SUnitExampleTest instanceVariableNames: 'log' classVariableNames: 'Trace' category: 'SUnit-Tests'!
TestCase subclass: #SUnitTest instanceVariableNames: '' classVariableNames: '' category: 'SUnit-Tests'!

"---- the example tests: these are run on purpose by SUnitTest, not on their own ----"

!SUnitExampleTest class methodsFor: 'tracing'!
trace
	^Trace ifNil: [Trace := OrderedCollection new]!
resetTrace
	Trace := OrderedCollection new! !

!SUnitExampleTest methodsFor: 'running'!
setUp
	SUnitExampleTest trace add: 'setUp'!
tearDown
	SUnitExampleTest trace add: 'tearDown'! !

!SUnitExampleTest methodsFor: 'tests'!
testPasses
	SUnitExampleTest trace add: 'testPasses'.
	self assert: true!
testFails
	SUnitExampleTest trace add: 'testFails'.
	self assert: 1 equals: 2!
testErrors
	SUnitExampleTest trace add: 'testErrors'.
	self assert: (nil foo) equals: 2!
! !

!SUnitExampleTest class methodsFor: 'running'!
shouldRun
	"these tests fail on purpose, so the automatic suite leaves them out"
	^false! !

"---- the real tests ----"

!SUnitTest methodsFor: 'assertions that hold'!
testAssert
	self assert: true.
	self assert: 1 + 1 = 2 description: 'arithmetic'!
testDeny
	self deny: false.
	self deny: 1 = 2 description: 'one is not two'!
testAssertEquals
	self assert: 3 + 4 equals: 7.
	self assert: 'abc' equals: 'abc'.
	self assert: #(1 2 3) equals: #(1 2 3).
	self deny: 3 equals: 4!
testAssertIdentical
	| a |
	a := Object new.
	self assert: a identicalTo: a.
	self assert: #sym identicalTo: #sym.
	self deny: a identicalTo: Object new!
testAssertCloseTo
	self assert: 0.1 + 0.2 closeTo: 0.3.
	self assert: 1.0 closeTo: 1.001 within: 0.01!
testAssertIncludes
	self assert: #(1 2 3) includes: 2.
	self assert: 'hello' includes: $e!
testAssertEmpty
	self assertEmpty: #().
	self assertEmpty: ''.
	self assertNotEmpty: #(1)!
testAssertIsKindOf
	self assert: 3 isKindOf: Integer.
	self assert: 'x' isKindOf: String!
testShouldRaise
	self should: [1/0] raise: ZeroDivide.
	self should: [nil foo] raise: MessageNotUnderstood.
	self should: [Error signal: 'x'] raise: Error!
testShouldRaiseAnswersTheException
	| e |
	e := self should: [Error signal: 'the message'] raise: Error.
	self assert: e messageText equals: 'the message'!
testShouldntRaise
	self shouldnt: [1 + 1] raise: ZeroDivide!
testAssertionsAreCounted
	| n |
	self assert: true.
	self assert: true.
	n := self assertionCount.
	self assert: n equals: 2! !

!SUnitTest methodsFor: 'assertions that do not hold'!
runExample: aSelector
	"run one of the example tests and answer its TestResult"
	^SUnitExampleTest run: aSelector!
testAFailingAssertionIsAFailure
	| r |
	r := self runExample: #testFails.
	self assert: r runCount equals: 1.
	self assert: r failureCount equals: 1.
	self assert: r errorCount equals: 0.
	self deny: r hasPassed!
testAnErrorIsAnError
	| r |
	r := self runExample: #testErrors.
	self assert: r errorCount equals: 1.
	self assert: r failureCount equals: 0!
testAPassingTestPasses
	| r |
	r := self runExample: #testPasses.
	self assert: r passedCount equals: 1.
	self assert: r hasPassed!
testFailureMessage
	| r |
	r := self runExample: #testFails.
	self assert: (r failures first message includesSubstring: 'expected 2')!
testErrorMessage
	| r |
	r := self runExample: #testErrors.
	self assert: (r errors first message includesSubstring: 'foo')!
testOutcomeKinds
	| r |
	r := self runExample: #testFails.
	self assert: r failures first isFailure.
	self deny: r failures first isError.
	r := self runExample: #testErrors.
	self assert: r errors first isError!
testOutcomeNamesTheTest
	| r |
	r := self runExample: #testFails.
	self assert: r failures first test name equals: 'SUnitExampleTest>>testFails'!
testWalkbackNamesTheTestAndNotTheFramework
	| w |
	w := (self runExample: #testFails) failures first walkback.
	self assert: (w includesSubstring: 'SUnitExampleTest>>testFails').
	self deny: (w includesSubstring: 'TestCase>>').
	self deny: (w includesSubstring: 'BlockClosure>>')!
testFailMethod
	| r |
	r := [self fail: 'on purpose'. #notReached] on: TestFailure do: [:e | e messageText].
	self assert: r equals: 'on purpose'! !

!SUnitTest methodsFor: 'the test lifecycle'!
testSetUpAndTearDownRunAroundEachTest
	| trace |
	SUnitExampleTest resetTrace.
	SUnitExampleTest run: #testPasses.
	trace := SUnitExampleTest trace asArray.
	self assert: trace equals: #('setUp' 'testPasses' 'tearDown')!
testTearDownRunsAfterAFailure
	| trace |
	SUnitExampleTest resetTrace.
	SUnitExampleTest run: #testFails.
	trace := SUnitExampleTest trace asArray.
	self assert: trace equals: #('setUp' 'testFails' 'tearDown')!
testTearDownRunsAfterAnError
	| trace |
	SUnitExampleTest resetTrace.
	SUnitExampleTest run: #testErrors.
	self assert: (SUnitExampleTest trace includes: 'tearDown')! !

!SUnitTest methodsFor: 'suites and results'!
testTestSelectorsAreFound
	self assert: (SUnitExampleTest testSelectors includes: #testPasses).
	self deny: (SUnitExampleTest testSelectors includes: #setUp).
	self deny: (SUnitExampleTest testSelectors includes: #runExample:)!
testSuiteOfAClass
	| suite |
	suite := SUnitExampleTest suite.
	self assert: suite size equals: SUnitExampleTest testSelectors size!
testSuiteRunsEveryTest
	| r |
	r := SUnitExampleTest suite run.
	self assert: r runCount equals: SUnitExampleTest testSelectors size.
	self assert: r failureCount equals: 1.
	self assert: r errorCount equals: 1!
testResultCounts
	| r |
	r := SUnitExampleTest suite run.
	self assert: r runCount equals: r passedCount + r failureCount + r errorCount!
testResultPrintString
	| r |
	r := self runExample: #testPasses.
	self assert: r printString equals: '1 run, 1 passed, 0 failed, 0 errors'!
testResultReportMentionsFailures
	| r |
	r := self runExample: #testFails.
	self assert: (r report includesSubstring: 'FAILURE')!
testEmptySuite
	| r |
	r := (TestSuite named: 'empty') run.
	self assert: r runCount equals: 0.
	self assert: r hasPassed!
testSuiteOfSeveralClasses
	| suite |
	suite := TestSuite forClasses: (Array with: SUnitExampleTest).
	self assert: suite size equals: SUnitExampleTest testSelectors size!
testAbstractTestCaseHasNoTests
	self assert: TestCase isAbstract.
	self deny: SUnitTest isAbstract!
testTestCaseName
	self assert: (SUnitExampleTest selector: #testPasses) name equals: 'SUnitExampleTest>>testPasses'! !

!SUnitTest methodsFor: 'the runner'!
testRunnerListsTests
	TestRunner filter: 'SUnitExample'.
	self assert: (TestRunner listItems anySatisfy: [:i | i includesSubstring: 'testPasses']).
	TestRunner filter: nil!
testRunnerRunsAll
	| text |
	TestRunner filter: 'SUnitExample'.
	text := TestRunner runAll.
	TestRunner filter: nil.
	self assert: (text includesSubstring: 'run')!
testRunnerDetailForAClass
	| text |
	TestRunner filter: 'SUnitExample'.
	text := TestRunner detailAt: 1.
	TestRunner filter: nil.
	self assert: (text includesSubstring: 'SUnitExampleTest')! !
