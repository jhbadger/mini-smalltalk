# SUnit

The Smalltalk testing framework: tests are methods in a class, and the framework finds and runs them.

```smalltalk
Smalltalk loadPackage: 'SUnit'
```

## Writing tests

Subclass `TestCase` and write methods whose names begin with `test`:

```smalltalk
TestCase subclass: #AccountTest
    instanceVariableNames: 'account'
    classVariableNames: ''
    category: 'Bank-Tests'

!AccountTest methodsFor: 'running'!
setUp
    account := Account new!
tearDown
    account := nil! !

!AccountTest methodsFor: 'tests'!
testStartsEmpty
    self assert: account balance equals: 0!
testDepositAdds
    account deposit: 50.
    self assert: account balance equals: 50!
testCannotOverdraw
    self should: [account withdraw: 10] raise: Error! !
```

`setUp` runs before each test and `tearDown` after it, whether the test passed or not. Each test gets a fresh instance.

## Running them

```smalltalk
AccountTest run                     "every test in the class; answers a TestResult"
AccountTest run: #testDepositAdds   "one test"
AccountTest debug: #testDepositAdds "run it without catching anything, so an error reaches the debugger"
TestSuite all run                   "every TestCase in the system"
Smalltalk runTests                  "the same, with the report printed to the Transcript"
```

A `TestResult` answers `runCount`, `passedCount`, `failureCount`, `errorCount`, `hasPassed`, `passes`, `failures`,
`errors`, `outcomes`, and `report` (the summary with every failure under it). A failure is an assertion that did not
hold; an error is anything else. Each `TestOutcome` has `test`, `kind`, `message`, `walkback` and `details`; the
walkback holds the frames of your own code, with the framework's own frames left out.

*System menu → test runner* opens a window listing every test class and its tests, with `ok`, `F` or `E` beside each
one after a run. Its menu runs everything or just the selection, filters the list by class name, and shows the summary;
selecting a test shows its failure and its source.

## Assertions

```smalltalk
self assert: aBoolean.                      self assert: aBoolean description: 'why'.
self deny: aBoolean.                        self deny: aBoolean description: 'why'.
self assert: actual equals: expected.       self deny: actual equals: expected.
self assert: actual identicalTo: expected.
self assert: actual closeTo: expected.      self assert: actual closeTo: expected within: 0.001.
self assert: aCollection includes: anObject.
self assertEmpty: aCollection.              self assertNotEmpty: aCollection.
self assert: anObject isKindOf: aClass.
self should: [1/0] raise: ZeroDivide.       "answers the exception, so you can check it"
self shouldnt: [...] raise: Error.
self fail.                                  self fail: 'why'.
self assertionCount                         "how many assertions this test has made"
```

`should:raise:` answers the exception it caught, so a test can go on to check its message or its class.

## Notes

* A `TestCase` subclass with no `test` methods of its own is treated as abstract: `TestSuite all` skips it, so a shared
  superclass of several test classes works as you would expect.
* A class whose tests are meant to fail can answer `false` to `shouldRun` on the class side; `TestSuite all` leaves it
  out, but the test runner still lists it so you can run it deliberately. The package's own `SUnitExampleTest` does this.
* Errors the virtual machine raises outside Smalltalk (a non-boolean receiver, a deadlocked scheduler) abort the run
  rather than being recorded as a test error — the same as anywhere else in the system.
* The package tests itself: `tests.st` holds 37 tests that exercise every assertion, the failure/error distinction, the
  lifecycle and the runner. `make check` runs them, plus the checks in `tests/tests.txt`.
