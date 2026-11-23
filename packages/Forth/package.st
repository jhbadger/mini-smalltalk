"Forth: a Forth system - an outer interpreter and a compiler, the ANS core words and more, floating point, and a bridge to Smalltalk objects"
| dir |
dir := Smalltalk packagePath: 'Forth'.
#('classes.st' 'machine.st' 'compiler.st' 'primitives1.st' 'primitives2.st' 'api.st' 'tool.st')
	do: [:f | Smalltalk fileIn: dir, '/', f]!
Forth prelude: (FileStream contentsOf: (Smalltalk packagePath: 'Forth'), '/prelude.fs').
Forth template.
Forth reset.
SystemMenu add: 'forth workspace' receiver: ForthTool selector: #open!
