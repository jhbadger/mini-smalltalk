# Forth

A Forth system: an outer interpreter and compiler, the core of the ANS words and a good deal more, double-length numbers, a floating-point stack, exceptions, defining words with `create ... does>`, and a bridge in both directions between the Forth stack and Smalltalk objects. It is an optional package:

```smalltalk
Smalltalk loadPackage: 'Forth'          "or: st -l Forth, or System menu → load package..."
```

## From Smalltalk

```smalltalk
Forth eval: '2 3 + .'                                   "'5 '  -- what the program printed"
Forth eval: ': square dup * ;  7 square .'              "'49 ' -- definitions stay defined"
Forth valueOf: '6 7 *'                                  "42    -- the top of the stack, taken off"
Forth stackAfter: '1 2 3 swap'                          "#(1 3 2) -- in a new system"
Forth reset                                             "forget everything the default system knows"
Forth evalFile: 'program.fs'                            "run a source file"

f := Forth new.                                         "a system of your own"
f eval: '10 20'. f stack                                "#(10 20)"
f push: 5. f pop. f depth
f pushString: 'hello'. f popString                      "a Forth string is an address and a length"
f define: 'TRIPLE' do: [:forth | forth push: forth pop * 3]       "a word written in Smalltalk"
Forth define: 'TRIPLE' do: [:forth | ...]               "...in every system, present and future"
f input: 'typed text'                                   "what KEY and ACCEPT will read"
f words, f hasWord: 'dup', f output, f statusLine
```

`Forth eval:` answers what the program printed. An error clears the stacks and is signalled as a `ForthError`, whose `code` is the ANS throw code (`-4` stack underflow, `-10` division by zero, `-13` undefined word, ...) and whose `messageText` says what happened. What was printed before the error is still in `f output`, and `f errorWord` and `f errorLine` say where it went wrong.

```smalltalk
[Forth eval: '1 0 /'] on: ForthError do: [:e | e code]          "-10"
```

## The workspace

*System menu → forth workspace*, or `ForthTool open`. Select some Forth and **print it** or **do it**: the text runs, what it printed comes back, then `ok` and the stack if anything is left on it. What you define stays defined until you run `FORGET-ALL`. An error shows its message and line.

```
: square ( n -- n*n )  dup * ;
7 square .        ⇒  49 ok
1 2 3             ⇒  ok  <3> 1 2 3
nosuch            ⇒  error: undefined word: nosuch  (line 1)
```

`ForthTool evaluate: aString` does the same without a window, and `ForthTool system` is the system the window runs.

## The language

Case does not matter. Numbers are Smalltalk integers (no limit), so `1000000000000 1000000000000 *` is right; a flag is `-1` for true and `0` for false; division is floored. A cell is **one address unit**: the cell after address `a` is `a 1+`, and `1 cells` is `1`; programs that say `cells` and `cell+` do not care. Memory is an array of cells that grows as you `allot`, and a cell can hold a float, a string or any object as well as a number.

| | words |
|---|---|
| stack | `dup drop swap over rot -rot nip tuck ?dup pick roll depth 2dup 2drop 2swap 2over 2rot >r r> r@ 2>r 2r> 2r@ i j k clearstack` |
| arithmetic | `+ - * / mod /mod */ */mod negate abs min max 1+ 1- 2* 2/ lshift rshift and or xor invert sqrt random` |
| comparison | `= <> < > <= >= 0= 0<> 0< 0> u< u> within true false` |
| double | `s>d d>s m* um* m+ d+ d- dnegate dabs d2* d2/ d0= d0< d= d< dmax dmin fm/mod sm/rem um/mod 2@ 2! 2variable 2constant 2literal` |
| memory | `@ ! +! c@ c! , c, here allot align aligned cells cell+ chars char+ fill erase blank move cmove cmove> unused allocate free buffer: ? dump` |
| output | `. u. .r u.r d. d.r cr space spaces emit type .s .fs ." .( ( \` |
| strings | `s" count compare search /string -trailing char [char] word parse parse-name find evaluate source >in bl >number` |
| numeric output | `<# # #s hold sign #>` |
| definitions | `: ; :noname immediate recurse exit variable constant value to create does> defer is action-of marker postpone literal [ ] ' ['] execute compile, >body [compile]` |
| control | `if else then begin until while repeat again do ?do loop +loop leave unloop case of endof endcase [if] [else] [then] [defined] [undefined]` |
| errors | `catch throw abort abort" bye quit` |
| floating point | `f+ f- f* f/ f** fnegate fabs fsqrt fsin fcos ftan fatan fexp fln flog floor fround ftrunc fmax fmin fdup fdrop fswap fover frot fdepth f@ f! f. f0< f0= f< f> f= s>f f>s d>f f>d fvariable fconstant fliteral pi` |
| system | `words see include included require required` |
| Smalltalk | `st-eval send >st-string st-string> printstring st-nil st-nil?` |

A number is read in the current `base`; `$ff`, `#10` and `%101` override it, `'A'` is a character, `123.` is a double and a number with an `e` in it (or a point and digits, like `1.5`) is a float. Floats have a stack of their own.

`see` shows how a word was compiled; the control words show up as jumps with cell numbers:

```
: check
  1  0=
  2  0BRANCH 4
  3  ." was zero"
;
```

## Forth and Smalltalk

The stack holds any object, so two words are all the bridge needs:

```smalltalk
Forth eval: 's" 3 factorial" st-eval .'                  "'6 '"
Forth eval: '3 4 1 s" max:" send .'                      "'4 '  -- receiver, arguments, how many, selector"
Forth eval: 's" hello" >st-string 0 s" reversed" send st-string> type'    "'olleh'"
```

`st-eval ( c-addr u -- x )` evaluates a Smalltalk expression and pushes the answer. `send ( rcvr arg1 .. argN N c-addr u -- result )` sends a message. `>st-string` and `st-string>` convert between a Smalltalk String and a Forth string, `printstring` makes the printString of anything, and `st-nil` and `st-nil?` push and test `nil`. Smalltalk errors inside either one come out as a `ForthError` with code `-21`.

## How it works

`Forth>>interpret` is the outer interpreter: it takes the next word from the source (`parseName`), looks it up in the dictionary (a Smalltalk Dictionary of upper-case names), and executes it or, while compiling, adds it to the definition. A word that is not found is read as a number (`parseNumber:`).

A word is an object that answers `executeIn: aForth`:

| class | what it is |
|---|---|
| `ForthPrimitive` | a Smalltalk block that is given the Forth system |
| `ForthColon` | a definition: an Array of cells, each of which is itself a word |
| `ForthLiteral` `ForthFloatLiteral` | a number to push; also what `constant` makes |
| `ForthJump` | the control cells: `0BRANCH`, `BRANCH`, `DO`, `?DO`, `LOOP`, `+LOOP`, `LEAVE`, `OF` |
| `ForthCreated` `ForthValue` | what `create`, `variable` and `value` make |
| `ForthDefer` `ForthText` | a deferred word; the text of `."` |

The inner interpreter is `Forth>>run:`, a loop over the cells of a definition. A colon word runs by recursing into `run:`, so the Smalltalk stack is the Forth return address stack and the Forth return stack is free for `>r` and the loop parameters. `if`, `begin`, `do` and the rest are immediate primitives that lay down jump cells and patch their targets when the matching `then`, `until` or `loop` comes; they keep their bookkeeping on a control stack of their own, not on the data stack. `does>` gives the most recent `create`d word the rest of the definition as its behaviour.

Most of the words are Smalltalk blocks (`primitives1.st` and `primitives2.st`), and a few are written in Forth in `prelude.fs`, which is read once when the package loads, so every new `Forth new` starts as a copy of a system that already knows them.

## Differences from the standard

* Integers are unbounded. `invert`, `and`, `or` and `xor` behave as if two's complement went on for ever, and `rshift` and the double-length words treat a cell as 64 bits.
* A cell is one address unit, and a character takes a whole cell; `c@` and `@` are the same word, and `char+` is `cell+`.
* The control-flow stack is separate from the data stack, so the standard's `cs-roll` tricks do not work, and `while` can only be used once per loop.
* `abort"`, `s"` and `."` read to the closing quote with no escapes. `s"` outside a definition uses one of two buffers that take turns.
* `allocate` hands out memory from the dictionary and `free` does nothing.
* No vocabularies or search order, no block or file-access words beyond `include`, no locals, no `ms` delay (it is there and does nothing).
* `.` prints floats and other objects the way Smalltalk prints them.

## Notes

* 539 checks in `tests/tests.txt` that `make check` runs, normally and again under GC stress.
* `ForthTutorial go` is a tutorial of 19 lessons (also on the System menu): the stack, arithmetic, defining words, printing, decisions and loops, variables, memory, strings, `create ... does>`, extending the compiler, how Forth reads, `catch` and `throw`, doubles and floats, the bridge to Smalltalk, the workspace, and some programs.
