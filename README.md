# Mini Smalltalk-80 (TUI)

A small but functional Smalltalk-80 system written in C, with a text-mode
windowing environment driven by keyboard **and mouse**. It has the classic
tools: a four-pane **System Browser**, **Workspace**, **System Transcript**,
**Inspector**, error notifier with walkback, pop-up (right-button) menus,
overlapping draggable/resizable windows, and a persistent **changes file**.

```
make            # builds ./st (needs a C compiler, no other dependencies)
./st            # start the environment in an xterm-compatible terminal
make check      # headless VM test-suite
./st -e '3 + 4' # evaluate expressions without the UI
```

The kernel sources (`kernel1.st` … `kernel6.st`) are loaded from the directory
containing the `st` executable, so you can put that directory on your `PATH`
(or symlink `st` into one) and run it from anywhere. The changes file
(`changes.st`, or the file named with `-c`) and any `-f` files are taken
relative to the directory you run it from, so each project gets its own
changes. `-k dir` overrides where the kernel is looked for.

## Using it

* **Tutorial**: choose *smalltalk tutorial* from the System menu (right-click the
  desktop), or file in `tutorial.st` and evaluate `Tutorial go`. Twenty-seven
  short lessons in the style of Pharo's ProfStef open in a live workspace; every
  example can be evaluated in place. `Tutorial next`, `previous`, `goTo: 7`,
  `goTo: 'Blocks'` and `contents` move around; the tutorial is itself a Smalltalk
  class you can browse and extend.
* **Mouse**: left click selects / positions the cursor, drag selects text,
  double-click selects a word. **Right click** opens the pane's menu
  (the Smalltalk-80 "yellow button"); right click on the desktop opens the
  **System menu** (browser, workspace, transcript, file in, quit). Drag a
  window by its title bar, resize with the `╯` corner, close with `[x]`.
  The mouse wheel scrolls lists and text.
* **Keyboard**: `ctrl-D` do it, `ctrl-P` print it, `ctrl-T` inspect it,
  `ctrl-S` accept (browser), `ctrl-L` cancel, `ctrl-A/C/X/V` select-all/copy/cut/paste,
  `Esc` system menu, `Tab` cycles panes (in a text pane it inserts a tab; Shift-Tab cycles),
  `ctrl-Q` quits. Arrows with Shift extend the selection. In lists, typing a letter
  jumps to the next matching item.
* **Browser**: category → class → protocol → selector → source. Select a
  category with no class to get a class-definition template; accept it to
  create the class. Select a protocol with no selector to get a method
  template. The `[instance]`/`[class]` button switches sides. Menus offer
  senders / implementors, file out, remove, add protocol, class comment.
* **Workspace / Inspector**: evaluate code with the menu or shortcuts.
  In an Inspector, `self` is the inspected object and its instance
  variables are visible by name.
* Everything you accept in the browser (and class definitions, removals,
  comments) is appended to `changes.st`, which is filed in again at start-up,
  so your work persists between sessions. `-c file` picks another changes file.

## Implementation notes

| File | Role |
|------|------|
| `object.c` | object memory (tagged SmallIntegers, non-moving mark/sweep GC), symbols, C-level hashed collections that defer to Smalltalk `=`/`hash` for user objects, class bootstrap with real metaclasses |
| `bignum.c` | arbitrary-precision arithmetic behind LargePositiveInteger / LargeNegativeInteger |
| `lex.c`, `parse.c`, `compiler.c` | Smalltalk-80 syntax → bytecode; full closures, non-local return, cascades, literal arrays, inlined `ifTrue:`/`and:`/`whileTrue:` family |
| `interp.c` | bytecode interpreter with heap contexts, method cache, `perform:`, `doesNotUnderstand:`, walkbacks, and a priority process scheduler (Semaphore, Delay, yield, preemption by priority) |
| `prims.c` | ~120 primitives (arithmetic, floats, large integers, strings, dictionaries, classes, time, files, Transcript) |
| `fileio.c` | chunk ("bang") format file-in / file-out, changes log |
| `kernel1-6.st` | the class library in Smalltalk |
| `tui.c` | raw terminal, cell double-buffer, SGR mouse, key decoding |
| `widgets.c` | windows, list/text/button panes, pop-up menus, dialogs |
| `tools.c` | System Browser, Workspace, Transcript, Inspector, system menu |

## The class library

The Smalltalk-80 ("Blue Book") classes, except the graphics ones:

* **Kernel-Objects**: Object (with dependents: `changed`/`update:`), UndefinedObject, Boolean, True, False, LookupKey, Association, Message
* **Kernel-Classes**: Behavior, ClassDescription, Class, Metaclass, ClassOrganizer
* **Kernel-Methods**: CompiledMethod, ContextPart, MethodContext, BlockContext, BlockClosure
* **Kernel-Processes**: Process, ProcessorScheduler (`Processor`), Semaphore, Delay, SharedQueue. Forked processes run cooperatively (`yield`, `wait`, `Delay`) and keep running in the background while the user interface is idle.
* **Kernel-Magnitudes**: Magnitude, Character, Date, Time
* **Kernel-Numbers**: Number, Integer, SmallInteger, LargePositiveInteger, LargeNegativeInteger, Fraction, Float, Random. Arithmetic is exact: `1/3` is a Fraction, `100 factorial` is a LargePositiveInteger, and mixed operands coerce by generality.
* **Collections**: Collection, Bag, Set, IdentitySet, Dictionary, IdentityDictionary, SystemDictionary (`Smalltalk`), SequenceableCollection, LinkedList, Link, Interval, ArrayedCollection, Array, ByteArray, String, Symbol, Text, RunArray, OrderedCollection, SortedCollection, MappedCollection. Sets and Dictionaries honour user-defined `=` and `hash`.
* **Streams**: Stream, PositionableStream, ReadStream, WriteStream, ReadWriteStream, FileStream (whole-file read on open, write on `close`)
* **Graphics-Primitives**: Point and Rectangle (the arithmetic parts only)
* **System**: SystemDictionary, Compiler (evaluate:), TranscriptStream, Exception/Error (minimal: `signal:` reports an error)

Deliberate simplifications: no exception handling beyond `error:` aborting to a
walkback (`on:do:` just evaluates the block), no `become:`, no class-side
instance variables, bit operations are not defined on negative LargeIntegers,
and there is no binary image (the kernel sources plus the changes file are the image).

## Testing the UI without a terminal

With `ST_HEADLESS=1` the program reads raw key and SGR-mouse byte sequences
from stdin instead of a terminal, and prints the final screen as text when
stdin is exhausted (`ST_COLS`/`ST_ROWS` set the size). For example, click in
the workspace, select all, type an expression and print it:

```bash
printf '\x1b[<0;6;20M\x1b[<0;6;20m\x013 + 4 factorial\x10' | ST_HEADLESS=1 ST_COLS=100 ST_ROWS=30 ./st -c /tmp/changes.st
```
