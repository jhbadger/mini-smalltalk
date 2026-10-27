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

## Using it

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
| `object.c` | object memory (tagged SmallIntegers, non-moving mark/sweep GC), symbols, C-level dictionaries, class bootstrap with real metaclasses |
| `lex.c`, `parse.c`, `compiler.c` | Smalltalk-80 syntax → bytecode; full closures, non-local return, cascades, literal arrays, inlined `ifTrue:`/`and:`/`whileTrue:` family |
| `interp.c` | bytecode interpreter with heap contexts, method cache, `perform:`, `doesNotUnderstand:`, walkbacks |
| `prims.c` | ~90 primitives (arithmetic, floats, strings, dictionaries, classes, Transcript) |
| `fileio.c` | chunk ("bang") format file-in / file-out, changes log |
| `kernel1-3.st` | the class library in Smalltalk (Object, Boolean, Magnitude, Number, Collections, Streams, Blocks, …) |
| `tui.c` | raw terminal, cell double-buffer, SGR mouse, key decoding |
| `widgets.c` | windows, list/text/button panes, pop-up menus, dialogs |
| `tools.c` | System Browser, Workspace, Transcript, Inspector, system menu |

Deliberate simplifications: no LargeIntegers (overflow goes to Float), no
Fractions (`1/3` is a Float), no exception handling (`on:do:` just evaluates
the block; `error:` aborts to the top level with a walkback), no processes,
no binary image (the kernel sources plus the changes file are the image).

## Testing the UI without a terminal

With `ST_HEADLESS=1` the program reads raw key and SGR-mouse byte sequences
from stdin instead of a terminal, and prints the final screen as text when
stdin is exhausted (`ST_COLS`/`ST_ROWS` set the size). For example, click in
the workspace, select all, type an expression and print it:

```bash
printf '\x1b[<0;6;20M\x1b[<0;6;20m\x013 + 4 factorial\x10' | ST_HEADLESS=1 ST_COLS=100 ST_ROWS=30 ./st -c /tmp/changes.st
```
