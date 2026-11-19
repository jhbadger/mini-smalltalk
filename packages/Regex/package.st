"Regex: regular expressions - matching, searching, replacing and splitting, with String messages to go with them"
| dir |
Smalltalk loadPackage: 'SUnit'.        "the tests are written in it"
dir := Smalltalk packagePath: 'Regex'.
#('nodes.st' 'parser.st' 'regex.st' 'tool.st' 'tests.st') do: [:f | Smalltalk fileIn: dir, '/', f]!
SystemMenu add: 'regex workspace' receiver: RegexTool selector: #open!
