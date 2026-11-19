"Debugger: a window on the stack of an error - frames, source, variables, and evaluation in a frame"
| dir |
dir := Smalltalk packagePath: 'Debugger'.
#('debugger.st' 'tests.st') do: [:f | Smalltalk fileIn: dir, '/', f]!
