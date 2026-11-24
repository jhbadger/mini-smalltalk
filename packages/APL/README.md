# APL

An array language in the family of APL and J, written in Smalltalk. The thing you compute with is an array of any number of axes; arithmetic and most verbs work on single items and are extended to arrays by the language, so a program is a short sentence of symbols read from right to left, with no loops and no precedence.

```smalltalk
Smalltalk loadPackage: 'APL'
APL eval: '+/ i. 10'                       "'45'"
APL eval: 'mean =: +/ % #'                 "names last between calls"
APL eval: 'mean 3 1 4 1 5 9'               "'3.83333'"
APL lines: '(i. 3) */ i. 4'                "#('0 0 0 0' '0 1 2 3' '0 2 4 6')"
```

From the UI use **System menu → apl workspace** (select lines of the language and *print it*), or `APLTutorial go` for a 20-lesson tutorial (it is also in the System menu's list of tutorials). From the shell start with `st -l APL`.

## The language

The spellings are those of J, which needs only the keys on a keyboard. A sentence is read from the right: a verb with a noun on its right (and nothing on its left) is a *monad*, with a noun on each side a *dyad*; an adverb takes the verb to its left, a conjunction the two things beside it; three verbs in a row are a fork (`+/ % #` is the mean), two a hook.

* **Arrays.** Items are numbers, characters or boxes (an array in a box, made by `<`). Shape, rank and the items in order are all there is. `i. 2 3`, `2 3 $ 'abcdef'`, `<'abc'`, `'it''s'`, `1 2 3`, `_5` (a high minus is an underscore), `3r4`, `2.5e3`, `_` and `__` (infinity). Whole numbers are exact and unbounded, rationals exact, anything else a float shown with six significant digits (`9!:11 (10)` changes that).
* **Atomic verbs** (scalar extension and the agreement of frames): `+ - * % ^ | < > <. >. <: >: = ~: *. +. *: -. %: ! o. x:`, and `^.` (log), `p:` and `q:` (primes and factors).
* **Structure:** `$ # , ,. ,: ; [ ] { {. {: }. }: |. |: i. e. I. ~. /: \: #. #: ": ". ;: -: %. ? ` (shape, tally, ravel and append, stitch, itemise and laminate, raze and link, from, take and drop, reverse and rotate, transpose, index of, member, interval index, nub, grade up and down, base and antibase, format, execute, words, match, matrix inverse and solve, roll and deal).
* **Adverbs:** `/` (insert; with a left argument, table), `\` (prefix; with a number on the left, windows), `\.` (suffix, outfix), `/.` (key; oblique), `~` (reflex, passive), `}` (amend), and `each` for `&.>`.
* **Conjunctions:** `"` rank, `@` and `@:` atop, `&` and `&:` compose and bond, `&.` under (needs a known inverse), `^:` power (also negative = inverse, `_` = until it stops changing, a list = all of them), `.` inner product (and the determinant as a monad), `;.` cut, `:` definition, `!:` (only `9!:10` and `9!:11`).
* **Definitions.** Explicit: `3 : 'x + y'`, `4 :` (dyad only), `1 :` (adverb), `2 :` (conjunction), `0 :` (noun); two texts make a monadic and a dyadic case. Over several lines: `name =: verb define` (also `monad`, `dyad`, `adverb`, `conjunction`, `noun`) to a line with only `)`, or `3 : 0`. Inside: `x y u v m n`, `=.` for locals, `=:` for globals, `$:` for recursion, and the control words `if. elseif. else. while. whilst. for. for_x. select. case. fcase. try. catch. assert. return. break. continue. end.` A `⋄` separates sentences on one line. Tacit: `mean =: +/ % #`, trains, `[:` caps, bonds like `3&*`.
* **Display.** Tables have their columns aligned, planes are separated by blank lines, boxes are drawn with box characters, rationals show as `3r4`. Errors are J's: `domain error`, `length error`, `rank error`, `index error`, `value error`, `syntax error`, `valence error`, `nonce error`.

### The classic glyphs

`APL glyphs` answers the pairs *glyph, spelling* that are replaced, outside quoted strings, before a text is read: `⍳ ⍴ ⌽ ⊖ ⍉ ⍋ ⍒ ⌈ ⌊ ← ⍬ ⍕ ⍎ × ÷ ≠ ≤ ≥ ∊ ⊂ ⊃ ∪ ⌷ ↑ ↓ ⍪ ○ ⍟ ⍨ ¨ ∘ ⌿ ⍀ ⍤ ∧ ∨ ⍸ ⊣ ⊢ ≡ − ⍝ ¯ ⋄`. So `+/ ⍳ 10`, `x ← 3 4 ⋄ x × 2` and `(⌈/ ⍳ 4) ÷ 2` work. The glyphs only stand for the J spellings, so the meaning is that of the J verb (`↑` is take, `⍴` is both shape and reshape, `⍳` counts from 0), and the order of evaluation is J's right to left, which is also APL's.

## From Smalltalk

```smalltalk
APL eval: '2 3 $ i. 6'                     "the text the language prints (lines separated by line feeds)"
APL lines: '2 3 $ i. 6'                    "#('0 1 2' '3 4 5')"
APL evalValue: '1 2 3 + 4'                 "an APLArray: shape, data"
(APL evalValue: '2 3 $ i. 6') asSmalltalk  "#(#(0 1 2) #(3 4 5)): a number, a String, an Array of Arrays"
APL smalltalkValue: '+/ i. 5'              "10"
APLArray fromSmalltalk: #(#(1 2) #(3 4))   "a 2 2 table; equal rows make a table, anything else boxes; also #asAPL"
APL call: '+/' on: #(1 2 3)                "6: a verb in the language applied to a Smalltalk object"
APL call: '%' on: 1 and: 4                 "0.25"
| s | s := APL new.                        "a private session with its own names"
s at: 'v' put: #(3 1 4 1 5).               "a Smalltalk object into a name"
s eval: '+/ v'.
s defineVerb: 'dbl' monad: [:y | y collect: [:e | e * 2]] dyad: nil.   "a verb written in Smalltalk"
APL reset                                  "forget the default session"
```

An error is an `APLError` whose `messageText` is J's message. `APL debug: true` makes a Smalltalk error inside a primitive show its own message. In the language, `st` goes the other way: `st '3 + 4'` evaluates a string of Smalltalk and brings the answer back, and `1 2 3 st 'x inject: 0 into: [:a :b | a + b]'` has the left argument as `x`.

## Differences from J

* Whole numbers never overflow into floats (every integer is "extended"), and `x:` turns a float into the rational nearest it. `%.` (matrix inverse) is exact for integers and rationals.
* No complex numbers (the square root of a negative number is a domain error), no gerunds or agenda (`` ` `` and `@.`), no locales (`name_loc_`), no `d.` `t.` `L:` `S:` and no file or sparse facilities. `!:` knows only `9!:10` and `9!:11`; `;:` cuts a string at blanks only.
* `8!:` formatting is replaced by `":`: `8.2 ": y` is a width and decimals, a negative width pads on the right.
* Characters are bytes: a UTF-8 string has one item for each byte (box characters are made by the display, not stored).
* An explicit definition has the ranks of `_ _ _`; trains too.
* A float that is a whole number is shown without a decimal point, and 1e3 is an integer.

## The files

| file | what |
|---|---|
| `classes.st` | the classes: APLError, APLBox, APLArray, APLVerb, APLAdverb, APLConj, APLLexer, APLFormat, APLPrims, APL |
| `array.st` | the array: shape and data, stacking, padding, the scalar extension, conversion from and to Smalltalk |
| `words.st` | the lexer: word formation, numbers, strings, the glyph table, multi-line definitions |
| `verbs.st` | verbs with their ranks, cells and frames, adverbs and conjunctions |
| `parser.st` | the evaluator: J's parse table, assignment, trains, definitions, control structures |
| `display.st` | numbers, tables, planes and boxes as text |
| `prims1.st` .. `prims4.st` | the primitives: atomic, structural, searching and formatting, adverbs and conjunctions |
| `api.st`, `tool.st` | the front door and the workspace |
| `tutorial.st` | the tutorial: 20 lessons (`APLTutorial go`) |
| `tests/tests.txt` | `expression ==> printString` lines run by `make check`, also with the collector under pressure |

## Tests

`tests/tests.txt` has 630 checks: arithmetic and agreement, shape, selection, reduce and scan, rank, characters and boxes, definitions, trains and control structures, sorting and searching, matrices, numbers and formatting, the glyphs, programs (the sieve, Life, mean and variance, Fibonacci by matrix power, word frequency, the matrix inverse written out with a loop, the Collatz steps) and the Smalltalk interface. The 309 examples of the tutorial are all run (`APLTutorial exampleCheck` reports how many compile; each was run once by hand and the answers read).
