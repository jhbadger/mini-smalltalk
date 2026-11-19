# Debugger

A window on the stack of an error: the frames, the source of each one with the failing line marked, its receiver
and its variables by name, and evaluation in the frame's context.

```smalltalk
Smalltalk loadPackage: 'Debugger'
```

Once it is loaded, an unhandled error opens it instead of the walkback window. Nothing else needs doing.

## What it shows

The list on the left holds the frames, innermost first. The pane on the right shows, for the selected frame:

| menu item | what it shows |
|---|---|
| source | the method's source with `>` against the statement being run |
| variables | `self`, then each argument and temporary **by name** with its value |
| receiver | the receiver and each of its instance variables |
| whole stack | every frame with its line number |

The menu also opens an Inspector on the receiver or on the frame itself, copies the stack to the Transcript, and
evaluates an expression with `self` bound to that frame's receiver — so instance variables are in scope.

Frames of the exception machinery are left out, as are `Object>>doesNotUnderstand:` and `Object>>error:`: they are
the universal way of raising an error and say nothing the message text does not. What is left is your own code and
the library methods it called.

## Opening it by hand

```smalltalk
Debugger debug: [self somethingThatFails]    "run the block, open on whatever goes wrong"
Debugger openOn: thisContext message: 'a look around'
Debugger frames                              "the frames of the last thing opened"
Debugger fullStack                           "them as text"
Debugger tempNamed: 'count'                  "a temporary of the selected frame, for use in evaluate..."
Debugger receiver                            "the selected frame's receiver"
```

A `DebuggerFrame` answers `label`, `pc`, `receiver`, `method`, `home`, `sender`, `context` and `isDead`.

## What it cannot do

**It cannot continue.** By the time an error reaches the debugger the run has already been abandoned, so the
debugger is for looking, not for resuming: there is no proceed, no restart and no stepping. Close the window when
you are done. (`thisContext resume:` and `return:` do work while a stack is still live — see the main README — but
that is not the situation after an unhandled error.)

A frame's `pc` is copied when the debugger captures it. This matters because a handler that unwinds the stack marks
the frames it leaves as dead, and the debugger is usually looked at after that has happened; without the copy the
line numbers would be lost.

## The compiler support it needs

The package relies on two things `CompiledMethod` records, which were added for it and are part of the base system:

```smalltalk
(Integer compiledMethodAt: #factorial) tempNames      "#('r') -- arguments first, then temporaries"
(Integer compiledMethodAt: #factorial) sourceMap      "#(pc offset pc offset ...), one pair per statement"
(Integer compiledMethodAt: #factorial) lineForPC: 7   "the line of sourceCode being run at that pc"
(Integer compiledMethodAt: #factorial) sourceOffsetForPC: 7
```

Use `Debugger linesOf:` rather than `String>>lines` when you want line numbers to line up with those offsets:
`lines` drops a leading empty line, and a method filed in from a chunk begins with a newline.

## Notes

* Errors the virtual machine raises outside Smalltalk (a non-boolean receiver, "Block cannot return", a deadlocked
  scheduler) still go to the walkback window: there is no Smalltalk exception and no live context to open on.
* If the debugger itself fails while opening, the system falls back to the walkback window, so a broken debugger
  cannot hide an error from you.
* 30 SUnit tests in `tests.st`, plus 35 checks in `tests/tests.txt` that `make check` runs.
