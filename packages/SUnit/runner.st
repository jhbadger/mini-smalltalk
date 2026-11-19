"The test runner: a window listing every test in the system, with its result beside it and the failure in the
detail pane. Choose 'run all' from the list's menu, or 'run' to run just the selected class or test."

Object subclass: #TestRunner instanceVariableNames: '' classVariableNames: 'Rows Result Filter' category: 'SUnit'!

!TestRunner class methodsFor: 'opening'!
open
	self refresh.
	Smalltalk openListTool: 'TestRunner' title: 'Test runner'!
openOn: aTestCaseClass
	Filter := aTestCaseClass name.
	self refresh.
	Smalltalk openListTool: 'TestRunner' title: 'Test runner'! !

!TestRunner class methodsFor: 'the tests'!
filter
	^Filter!
filter: aStringOrNil
	Filter := aStringOrNil.
	self refresh!
testClasses
	| all |
	all := TestCase allSubclasses reject: [:c | c isAbstract].
	Filter notNil ifTrue: [all := all select: [:c | c name asLowercase includesSubstring: Filter asLowercase]].
	^(all asSortedCollection: [:a :b | a name <= b name]) asArray!
refresh
	"rebuild the list: a row for each class, then a row for each of its tests"
	Rows := OrderedCollection new.
	self testClasses do: [:c |
		Rows add: (Array with: #class with: c with: nil).
		c testSelectors do: [:s | Rows add: (Array with: #test with: c with: s)]].
	^Rows!
rows
	Rows isNil ifTrue: [self refresh].
	^Rows!
result
	^Result!
outcomeFor: aRow
	"the TestOutcome of a row's test, or nil"
	| cls sel |
	Result isNil ifTrue: [^nil].
	(aRow at: 1) == #test ifFalse: [^nil].
	cls := aRow at: 2. sel := aRow at: 3.
	^Result outcomes detect: [:o | o test class == cls and: [o test selector == sel]] ifNone: [nil]!
wasRun: aRow
	| cls sel |
	Result isNil ifTrue: [^false].
	(aRow at: 1) == #test ifFalse: [^false].
	cls := aRow at: 2. sel := aRow at: 3.
	^(Result passes anySatisfy: [:t | t class == cls and: [t selector == sel]])
		or: [(self outcomeFor: aRow) notNil]! !

!TestRunner class methodsFor: 'running'!
runAll
	| suite |
	suite := TestSuite named: 'test runner'.
	self testClasses do: [:c | c testSelectors do: [:s | suite addTest: (c selector: s)]].
	Result := suite run.
	^Result printString!
runRow: anIndex
	| row suite |
	row := self rows at: anIndex ifAbsent: [^'select a test or a class first'].
	suite := TestSuite named: 'selection'.
	(row at: 1) == #class
		ifTrue: [(row at: 2) testSelectors do: [:s | suite addTest: ((row at: 2) selector: s)]]
		ifFalse: [suite addTest: ((row at: 2) selector: (row at: 3))].
	Result := suite run.
	^Result printString! !

!TestRunner class methodsFor: 'the list tool'!
listItems
	| out |
	self rows isEmpty ifTrue: [^Array with: '(no TestCase subclasses)'].
	out := OrderedCollection new.
	self rows do: [:row |
		| mark |
		(row at: 1) == #class
			ifTrue: [out add: (row at: 2) name asString]
			ifFalse: [
				mark := '  '.
				(self wasRun: row) ifTrue: [
					| o |
					o := self outcomeFor: row.
					mark := o isNil ifTrue: ['ok'] ifFalse: [o isFailure ifTrue: ['F '] ifFalse: ['E ']]].
				out add: '   ', mark, ' ', (row at: 3) asString]].
	^out asArray!
detailAt: anIndex
	| row |
	self rows isEmpty ifTrue: [^self helpText].
	row := self rows at: anIndex ifAbsent: [^self summaryText].
	(row at: 1) == #class ifTrue: [^self classDetail: (row at: 2)].
	^self testDetail: row!
classDetail: aClass
	| out |
	out := WriteStream on: String new.
	out nextPutAll: aClass name asString; nextPutAll: ': '; print: aClass testSelectors size; nextPutAll: ' tests'; nl.
	aClass comment notNil ifTrue: [aClass comment notEmpty ifTrue: [out nl; nextPutAll: aClass comment; nl]].
	out nl.
	aClass testSelectors do: [:s | out nextPutAll: s asString; nl].
	Result notNil ifTrue: [out nl; nextPutAll: self summaryText].
	^out contents!
testDetail: aRow
	| out outcome source |
	out := WriteStream on: String new.
	out nextPutAll: (aRow at: 2) name asString; nextPutAll: '>>'; nextPutAll: (aRow at: 3) asString; nl; nl.
	outcome := self outcomeFor: aRow.
	outcome notNil
		ifTrue: [out nextPutAll: outcome details; nl]
		ifFalse: [out nextPutAll: ((self wasRun: aRow) ifTrue: ['passed'] ifFalse: ['not run yet']); nl; nl].
	source := [(aRow at: 2) sourceCodeAt: (aRow at: 3)] on: Error do: [:e | nil].
	source notNil ifTrue: [out nextPutAll: source; nl].
	^out contents!
summaryText
	^Result isNil ifTrue: ['no tests have been run yet'] ifFalse: [Result report]!
helpText
	^'No tests found.

A test is a method whose name begins with test, in a subclass of TestCase:

    TestCase subclass: #MyTests
        instanceVariableNames: ''''
        classVariableNames: ''''
        category: ''My tests''

    !!MyTests methodsFor: ''tests''!!
    testAddition
        self assert: 3 + 4 equals: 7!! !!

Then reopen this window, or choose refresh from the menu.'!
commandLabels
	^#('run all' 'run selected' '-' 'refresh' 'filter...' 'show all classes' '-' 'summary')!
command: aCommand at: anIndex
	| label |
	label := self commandLabels at: aCommand.
	label = 'run all' ifTrue: [^self runAll].
	label = 'run selected' ifTrue: [^self runRow: anIndex].
	label = 'refresh' ifTrue: [self refresh. ^nil].
	label = 'show all classes' ifTrue: [Filter := nil. self refresh. ^nil].
	label = 'summary' ifTrue: [^self summaryText].
	label = 'filter...' ifTrue: [
		| f |
		f := Smalltalk promptFor: 'Show only test classes whose name contains' default: (Filter ifNil: ['']).
		f isNil ifTrue: [^nil].
		Filter := f trimBoth isEmpty ifTrue: [nil] ifFalse: [f trimBoth].
		self refresh.
		^nil].
	^nil! !
