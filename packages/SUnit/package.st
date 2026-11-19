"SUnit: the Smalltalk testing framework - TestCase, assertions, suites and a test runner window"
| dir |
dir := Smalltalk packagePath: 'SUnit'.
#('sunit.st' 'runner.st' 'tests.st') do: [:f | Smalltalk fileIn: dir, '/', f]!
SystemMenu add: 'test runner' receiver: TestRunner selector: #open!
