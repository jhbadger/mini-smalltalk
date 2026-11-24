"Scheme: a Scheme system - R5RS and much of R7RS, with proper tail calls, full call/cc, syntax-rules macros, records, hash tables, string ports, and a bridge to Smalltalk objects"
| dir |
dir := Smalltalk packagePath: 'Scheme'.
#('classes.st' 'printer.st' 'reader.st' 'macro.st' 'nodes.st' 'compiler.st' 'machine.st' 'api.st'
  'prims1.st' 'prims2.st' 'prims3.st' 'tool.st' 'tutorial.st')
	do: [:f | Smalltalk fileIn: dir, '/', f]!
Scheme initPrimitives.
Scheme prelude: (FileStream contentsOf: (Smalltalk packagePath: 'Scheme'), '/prelude.scm').
Scheme template.
Scheme reset.
SystemMenu add: 'scheme workspace' receiver: SchemeTool selector: #open!
