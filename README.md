# Mini Smalltalk-80 (TUI)

A small but functional Smalltalk-80 system written in C, with a text-mode
windowing environment driven by keyboard **and mouse**. It has the classic
tools: a four-pane **System Browser**, **Workspace**, **System Transcript**,
**Inspector**, error notifier with walkback, pop-up (right-button) menus,
overlapping draggable/resizable windows, and a persistent **changes file**.

```
make            # builds ./st and kernel.image (needs a C compiler, no other dependencies)
./st            # start the environment in an xterm-compatible terminal
make check      # headless VM test-suite (test_vm.c, test_lib.txt, the tutorials, and every package's tests; also run on a system loaded from an image)
./st -e '3 + 4' # evaluate expressions without the UI
```

The kernel sources (`kernel1.st` …) are loaded from the directory
containing the `st` executable, so you can put that directory on your `PATH`
(or symlink `st` into one) and run it from anywhere. When an **image** is available
(see [Images](#images)) it is used instead, and the system starts without parsing any source. The changes file
(`changes.st`, or the file named with `-c`) and any `-f` files are taken
relative to the directory you run it from, so each project gets its own
changes. `-k dir` overrides where the kernel sources are looked for (and means: no image). `-l package` loads an optional package.

## Using it

* **Tutorial**: choose *smalltalk tutorial* from the System menu (right-click the
  desktop), or file in `tutorial.st` and evaluate `Tutorial go`. Twenty-seven
  short lessons in the style of Pharo's ProfStef open in a live workspace; every
  example can be evaluated in place. `Tutorial next`, `previous`, `goTo: 7`,
  `goTo: 'Blocks'` and `contents` move around; the tutorial is itself a Smalltalk
  class you can browse and extend.
* **Mouse**: left click selects / positions the cursor, drag selects text,
  double-click selects a word, triple-click a line. **Right click** opens the pane's menu
  (the Smalltalk-80 "yellow button"); right click on the desktop opens the
  **System menu** (browser, workspace, transcript, file in, quit). Drag a
  window by its title bar, resize with the `╯` corner, close with `[x]`.
  The mouse wheel scrolls lists and text.
* **Keyboard**: `ctrl-D` do it, `ctrl-P` print it, `ctrl-T` inspect it,
  `ctrl-S` accept (browser), `ctrl-L` cancel, `ctrl-A/C/X/V` select-all/copy/cut/paste,
  `Esc` system menu, `Tab` cycles panes (in a text pane it inserts a tab; Shift-Tab cycles),
  `ctrl-O` opens the focused pane's menu, `ctrl-Q` quits. Arrows with Shift extend the selection. In lists, typing a letter
  jumps to the next matching item.
* **Touch screens** (e.g. Termux, where a finger swipe scrolls and long-press is
  Termux's own selection): `ctrl-Space` sets a mark at the cursor, then the next
  tap selects from the mark to the tapped spot. Double-tap selects a word,
  triple-tap a line, and `ctrl-O` stands in for the right button.
* **Browser**: category → class → protocol → selector → source. Select a
  category with no class to get a class-definition template; accept it to
  create the class. Select a protocol with no selector to get a method
  template. The `[instance]`/`[class]` button switches sides. Menus offer
  senders / implementors, file out, remove, add protocol, class comment.
* **Workspace / Inspector**: evaluate code with the menu or shortcuts.
  In an Inspector, `self` is the inspected object and its instance
  variables are visible by name.
* Every change to the code is saved automatically, with nothing to "save": new
  classes and methods (from the browser, from a workspace, from `compile:`),
  method and class removals, class comments, and anything you file in. Each is
  appended to `changes.st` in the directory you started from, and replayed at the
  next start, so your work persists between sessions. The status bar shows
  `saved to <path>` after each change; if the file cannot be written (for
  example a read-only directory) a warning window says so immediately. `-c file`
  picks another changes file. What is *not* saved: workspace text, window
  positions and variables; use *file out* in the browser to export a class or
  category as a `.st` file. Scripted `-e` runs do not write the changes file. To make that work permanent and quick to load, save an image.

## Images

An image is a snapshot of the whole object memory (every class, method and object reachable from
`Smalltalk`) in one file, so the system can start without loading the kernel sources.

```
Smalltalk snapshot              "save to st.image in the current directory (or the image you started from)"
Smalltalk snapshotAs: 'x.image' "save somewhere else"
Smalltalk imageName             "the file that #snapshot writes"
```

The System menu has **save image** too. `make` builds `kernel.image` (the kernel and nothing else) next to
the executable. At start-up `st` looks for, in order:

1. `-i file.image`, if given (an error if it cannot be loaded);
2. `st.image` in the current directory: your project's image;
3. `kernel.image` next to the executable;
4. the kernel sources (also with `-n`, or with `-k dir`, which never use an image).

An image is only used if it is **not older than the kernel sources**; otherwise it is ignored with a message
(and a dialog in the UI) and the sources are loaded. A project image ignored that way still holds your saved
work: start it with `st -i st.image`. An image that is damaged, truncated, or saved by a different build of
the virtual machine is refused with a message and the sources are loaded instead.

**The changes file.** Saving an image to the current image file absorbs the changes file: everything in it
is now in the image, so `changes.st` is renamed to `changes.st.bak` and later changes start a new one, replayed on top of the
image at the next start as usual. `snapshotAs:` some other file leaves the changes file alone.

An image does not hold processes (forked ones are not resumed; the interface starts afresh), windows, workspace text,
or open `FileStream`s. It is tied to the word size and byte order of the machine that wrote it.

## Implementation notes

| File | Role |
|------|------|
| `object.c` | object memory (tagged SmallIntegers, non-moving mark/sweep GC), symbols, C-level hashed collections that defer to Smalltalk `=`/`hash` for user objects, class bootstrap with real metaclasses |
| `bignum.c` | arbitrary-precision arithmetic behind LargePositiveInteger / LargeNegativeInteger |
| `lex.c`, `parse.c`, `compiler.c` | Smalltalk-80 syntax → bytecode; full closures, non-local return, cascades, literal arrays, inlined `ifTrue:`/`and:`/`whileTrue:` family |
| `interp.c` | bytecode interpreter with heap contexts, method cache, `perform:`, `doesNotUnderstand:`, walkbacks, and a priority process scheduler (Semaphore, Delay, yield, preemption by priority) |
| `prims.c` | ~120 primitives (arithmetic, floats, large integers, strings, dictionaries, classes, time, files, Transcript) |
| `fileio.c` | chunk ("bang") format file-in / file-out, changes log |
| `image.c` | binary images: save the object memory to a file, and start from one |
| `kernel1-6.st` | the class library in Smalltalk |
| `tui.c` | raw terminal, cell double-buffer, SGR mouse, key decoding |
| `widgets.c` | windows, list/text/button panes, pop-up menus, dialogs |
| `tools.c` | System Browser, Workspace, Transcript, Inspector, system menu, and the window hooks packages use |

## The class library

The Smalltalk-80 ("Blue Book") classes, except the graphics ones:

* **Kernel-Objects**: Object (with dependents: `changed`/`update:`), UndefinedObject, Boolean, True, False, LookupKey, Association, Message
* **Kernel-Classes**: Behavior, ClassDescription, Class, Metaclass, ClassOrganizer
* **Kernel-Methods**: CompiledMethod (which also records `tempNames` and a `sourceMap` of pc to source offset, so a
  debugger can show variables by name and mark the line being run), ContextPart, MethodContext, BlockContext, BlockClosure
* **Kernel-Processes**: Process, ProcessorScheduler (`Processor`), Semaphore, Delay, SharedQueue. Forked processes run cooperatively (`yield`, `wait`, `Delay`) and keep running in the background while the user interface is idle.
* **Kernel-Magnitudes**: Magnitude, Character (any Unicode code point, with case mapping for Latin, Greek and Cyrillic), Date, Time, **DateAndTime** and **Duration** with arithmetic: `Date today - (3 days)`, `(DateAndTime now + (90 minutes))`, `date2 - date1` answers a Duration, `addMonths:`, `addYears:`; Unix time conversion
* **Kernel-Numbers**: Number, Integer, SmallInteger, LargePositiveInteger, LargeNegativeInteger, Fraction, Float, Random. Arithmetic is exact: `1/3` is a Fraction, `100 factorial` is a LargePositiveInteger, and mixed operands coerce by generality. Bit operations (`bitAnd:`, `bitOr:`, `bitXor:`, `bitShift:`) work on negative LargeIntegers with two's-complement semantics. Floats have `Float nan`, `infinity`, `isNaN`, `isInfinite`, hyperbolic functions, and print in shortest round-trip form (`0.1`, `1.0e-5`, `NaN`, `Infinity`); `sqrt`/`ln`/`sin`... accept Fractions and LargeIntegers. Also `printStringRadix:`, `raisedTo:modulo:`, `isProbablyPrime`, `primeFactors`, `binomial:`, `bitCount`, `Number>>to:collect:`.
* **Collections**: Collection, Bag, Set, IdentitySet, Dictionary, IdentityDictionary, SystemDictionary (`Smalltalk`), SequenceableCollection, LinkedList, Link, Interval, ArrayedCollection, Array, ByteArray, String, Symbol, **WideString**, Text, RunArray, OrderedCollection, SortedCollection, MappedCollection. Sets and Dictionaries honour user-defined `=` and `hash`. A `String` is a string of bytes, so UTF-8 passes straight through the terminal, source files and `FileStream`s; `aString asWideString` (or `utf8Decoded`) decodes it into a `WideString` of real code points (`'héllo' size` is 6, `'héllo' asWideString size` is 5) and `utf8Encoded` goes back. Everyday protocol includes `sorted`/`sorted:`, `groupBy:`, `fold:`, `gather:`, `sum:`, `ifEmpty:`/`ifNotEmpty:`, `copyUpTo:`/`copyAfter:`, `join:`, `permutationsDo:`, `shuffled`, set `union:`/`intersection:`/`difference:`, `streamContents:`, string `format:` (`'{1} and {2}' format: {a. b}`), `bindWith:`, `trimBoth`, `findString:`, `keywords`.
* **Streams**: Stream, PositionableStream, ReadStream, WriteStream, ReadWriteStream, FileStream (incremental read/write/seek/append on a real file handle; binary mode; `Directory` lists, creates and deletes folders)
* **Graphics-Primitives**: Point and Rectangle (the arithmetic and geometry parts only: no display). Numbers are accepted wherever a Point is: `(3@4) + 1`, `rect insetBy: 2`. Point has `theta`, `unitVector`, `normal`, `rotateBy:about:`; Rectangle has the corner/centre accessors and mutators, `merge:`, `intersect:`, `Rectangle merging:`, `center:extent:`
* **System**: SystemDictionary, Compiler (evaluate:), TranscriptStream, **Directory** (`entries`, `fileNames`, `directoryNames`, `create`, `delete`, `deleteAll`, `fileExists:`, `sizeOf:`, `modificationTimeOf:`), and operating-system access from `Smalltalk`: `getenv:`, `os`, `hostName`, `currentDirectory`, `homeDirectory`, `microsecondClock`
* **Exceptions**: Exception, Error, Notification, Warning, ArithmeticError, ZeroDivide, MessageNotUnderstood, SubscriptOutOfBounds, KeyNotFound, ExceptionSet (`ZeroDivide, MessageNotUnderstood`). `on:do:` handlers run on top of the signalling stack and support `return:`, `retry`, `retryUsing:`, `resume:`, `pass`, `outer`, re-`signal`, `signalerContext`, `isResumable` and `messageText`; `ensure:` and `ifCurtailed:` run when their block is left by an exception return, a `^`, or an unhandled error. Unhandled errors still abort to the walkback window. `error:`, `doesNotUnderstand:`, zero division, subscript and missing-key errors all signal real exceptions, so they can be caught.
* **thisContext**: `sender`, `receiver`, `method`, `selector`, `home`, `pc`, `tempAt:` / `tempAt:put:`, `stack`, `stackDepth`, `isDead`, `backtrace`, plus control transfer with `return:` and `resume:` (both run pending `ensure:` blocks)

Deliberate simplifications: exceptions raised by the VM itself (`NonBoolean receiver`,
"Block cannot return", file-in and `compile:` failures, a deadlocked scheduler) are
not Smalltalk exceptions and cannot be caught, `terminate` does not run `ensure:`
blocks, no `become:`, no class-side
instance variables, no way to run an operating-system command (`system:` is
deliberately absent), a `FileStream` that is not closed keeps its handle (there are 128;
use the `...do:` forms), `String` comparison with `<` is by byte value rather than
case-insensitive, and an image does not hold processes or windows.

## Optional packages

The `packages/` folder holds optional systems that are not in the standard image. Load one on demand:

```smalltalk
Smalltalk availablePackages          "#('Bio' 'Debugger' 'Greek' 'Phylo' 'Prolog' 'Regex' 'Stats' 'SUnit')"
Smalltalk loadPackage: 'Prolog'      "also: System menu -> load package..., or  st -l Prolog"
```

The load is recorded in the changes file (one line) so the next session loads it again; saving an image keeps the package in
that image. These come with the system:

* [**Prolog**](packages/Prolog/README.md) — Edinburgh/ISO syntax, a standard library, DCGs, `format`, `assert`/`retract`,
  exceptions, a bridge in both directions between Prolog and Smalltalk objects, and a query window.
* [**SUnit**](packages/SUnit/README.md) — the testing framework: `TestCase`, assertions, suites and a test runner window.
* [**Debugger**](packages/Debugger/README.md) — a window on the stack of an error, with the failing line marked and
  variables by name. Load it and unhandled errors open it instead of the walkback.
* [**Regex**](packages/Regex/README.md) — regular expressions: matching, searching, replacing and splitting, with
  String messages such as `matchesRegex:`, `allRegexMatches:` and `copyWithRegex:replacedWith:`.
* [**Bio**](packages/Bio/README.md) — bioinformatics: FASTA, FASTQ and GenBank files, sequences and features, the NCBI genetic
  codes, ORFs, assembly statistics, IUPAC pattern search, k-mers, restriction enzymes, pairwise alignment, a sequence browser,
  and sequence features as Prolog facts.
* [**Phylo**](packages/Phylo/README.md) — phylogenetics, built on Bio: distance models, neighbour joining and UPGMA, Newick in
  and out, trees drawn with characters, progressive multiple alignment, the bootstrap, and a tree browser.
* [**Stats**](packages/Stats/README.md) — tables and statistics: CSV, a DataTable you can select, sort, group and join, the
  descriptive statistics, t tests, chi-square, the rank tests, analysis of variance, regression, and plots made of characters.

* [**Greek**](packages/Greek/README.md) — Modern Greek grammar: verbs in every tense and both voices (conjugations A, B1 and
  B2, the irregular verbs, deponents), nouns in all their inflection classes with the accent shifts, articles, adjectives that
  agree with their nouns, the strong and weak pronouns, a lexicon, and a 23-lesson tutorial on the grammar:
  `'γράφω' asGreekVerb conjugate: #aorist`, `GreekNoun plural: 'άνθρωπος'`.

See [packages/README.md](packages/README.md) for how packages work and how to write one.

## Testing the UI without a terminal

With `ST_HEADLESS=1` the program reads raw key and SGR-mouse byte sequences
from stdin instead of a terminal, and prints the final screen as text when
stdin is exhausted (`ST_COLS`/`ST_ROWS` set the size). For example, click in
the workspace, select all, type an expression and print it:

```bash
printf '\x1b[<0;6;20M\x1b[<0;6;20m\x013 + 4 factorial\x10' | ST_HEADLESS=1 ST_COLS=100 ST_ROWS=30 ./st -c /tmp/changes.st
```
