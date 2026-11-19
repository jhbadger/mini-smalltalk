"Prolog: a Prolog system in Smalltalk (Edinburgh/ISO syntax, a library of list and atom predicates, a bridge to Smalltalk objects, and a query window)"
| dir |
dir := Smalltalk packagePath: 'Prolog'.
#('terms.st' 'reader.st' 'writer.st' 'engine.st' 'machine.st' 'builtins1.st' 'builtins2.st' 'builtins3.st' 'format.st' 'api.st')
	do: [:f | Smalltalk fileIn: dir, '/', f]!
Prolog reset.
SystemMenu add: 'prolog workspace' receiver: PrologTool selector: #openWorkspace!
