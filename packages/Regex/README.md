# Regex

Regular expressions: matching, searching, replacing and splitting, with the String messages to go with them.

```smalltalk
Smalltalk loadPackage: 'Regex'
```

## The quick way in

Most of the time you never mention `Regex` at all — the pattern goes straight into a String message:

```smalltalk
'2026-11-19' matchesRegex: '\d{4}-\d\d-\d\d'            "true -- the whole string"
'hello world' includesRegex: '\bw\w+'                   "true -- somewhere in it"
'x=1; y=22' allRegexMatches: '\d+'                      "OrderedCollection ('1' '22')"
'John Smith' copyWithRegex: '(\w+) (\w+)' replacedWith: '\2, \1'   "'Smith, John'"
'a, b ,c' splitOnRegex: '\s*,\s*'                       "OrderedCollection ('a' 'b' 'c')"
('key: value' regexMatch: '^(\w+):\s*(.*)$') groups     "#('key' 'value')"
```

The full set is `matchesRegex:`, `matchesRegexIgnoringCase:`, `includesRegex:`, `regexMatch:`,
`allRegexMatches:`, `tokensMatchingRegex:`, `regexMatchesDo:do:`, `copyWithRegex:replacedWith:`,
`copyWithFirstRegex:replacedWith:`, `copyWithRegex:matchesTranslatedUsing:`, `splitOnRegex:` and `asRegex`.

## The pattern language

| | |
|---|---|
| `abc` | the characters themselves |
| `.` | any character except a line feed |
| `[abc]` `[a-z]` `[^0-9]` | a class, a range, a class of everything else |
| `\d \D \w \W \s \S` | digit, non-digit, word character, non-word, space, non-space |
| `\n \t \r \f \v \a \e \0` `\x41` | the control characters, and a character by its hex code |
| `\.` `\*` `\\` | a metacharacter as itself |
| `*` `+` `?` | none or more, one or more, none or one |
| `{3}` `{2,4}` `{2,}` | exactly, between, at least |
| `*?` `+?` `??` `{2,4}?` | the same, but lazy: as few as will do |
| `a\|b` | either |
| `(...)` | a group, which is captured |
| `(?:...)` | a group that is not captured |
| `\1` … `\9` | the text an earlier group matched |
| `^` `$` | the start and the end of the subject |
| `\b` `\B` | a word boundary, and anywhere that is not one |

Inside `[...]` a `]` first or a `-` first or last is an ordinary character, and `\d \w \s` fold their
members into the class, so `[\da-f]` is what you would expect.

Anything the parser cannot make sense of raises a `RegexError` saying where in the pattern it gave up:

```smalltalk
Regex on: 'a('        "RegexError: expected ) in /a(/ at 3"
Regex on: 'a{3,1}'    "RegexError: the count runs backwards in /a{3,1}/ at 7"
```

## Working with the object

Compile a pattern once when you are going to use it a lot. (`Regex on:` remembers what it has compiled, so
even the String messages above do not re-parse a pattern they have seen.)

```smalltalk
| r |
r := Regex on: '(\w+)@(\w+)\.(\w+)'.
r matches: 'me@example.com'               "true -- the whole string"
r search: 'write to me@example.com now'   "a RegexMatch, or nil"
r matchesPrefixOf: 'me@example.com now'   "anchored at the start only"
r matchesIn: aString                      "all of them, as RegexMatches"
r matchesIn: aString do: [:m | ...]
r allMatchesIn: aString                   "just the matched text"
r occurrencesIn: aString
r replaceAllIn: aString with: '\1 at \2'
r replaceAllIn: aString using: [:m | (m at: 1) asUppercase]
r split: aString
r ignoreCase                              "the same pattern, matched without regard to case"
```

`Regex on: aPattern ignoreCase: true` does the same from the start. Case is ignored by back references and by
class ranges too, so `(ab)\1` matches `abAB`.

A `RegexMatch` answers `value` (the text that matched), `start`, `stop`, `size`, `isEmpty`, `prematch`,
`postmatch`, `subject`, `groupCount`, `groups`, `at: n` (group `n`, or the whole match for `0`, or nil when
the group took no part), `startOfGroup:` and `stopOfGroup:`.

In a replacement template, `\1` to `\9` stand for the groups, `\0` for the whole match, and `\\` for a
backslash. `replaceAllIn:using:` is the general form: the block is handed each `RegexMatch` and whatever it
answers is displayed into the result.

Matches never overlap, and a match of nothing still moves on by one character, so `'abc' allRegexMatches: 'x*'`
answers four empty strings rather than looping. `split:` skips empty matches for the same reason.

## The workspace

**System menu → regex workspace** opens a window for trying a pattern out. Select a pattern and the lines
under it, then *print it*:

```
(\w+)@([\w.]+)
write to me@example.com
no address on this line
```

```
/(\w+)@([\w.]+)/   2 group(s)

write to me@example.com
         ^^^^^^^^^^^^^^
    10..23  'me@example.com'  1='me'  2='example.com'
no address on this line
    (no match)

1 match in all
```

Write the first line bare, or as `/pattern/` with an `i` after the closing slash to ignore case. An empty
match is shown as `|` rather than `^`. `RegexTool evaluate: aString` does the same thing without a window.

## How it works

The pattern is parsed into a small tree of nodes — `RxChar`, `RxAny`, `RxClass`, `RxSequence`,
`RxAlternation`, `RxGroup`, `RxRepeat`, `RxAnchor`, `RxBackReference` — and matched by backtracking. Every
node answers one message:

```smalltalk
aNode matchAt: position then: aBlock
```

which answers the position just after the **whole rest of the match**, or nil when it cannot match there. The
block is the continuation: it is given the position after this node and answers nil to make the node try
another way. That is the whole of the backtracking, and it is why a group can undo its capture when the rest
of the pattern fails behind it.

Repetition of a node that always eats exactly one character (`isSingle`) runs as a loop rather than a
recursion, so `a*` over a long string costs no stack. `Regex on: 'a*'` answers the tree, so you can take one
apart and look at it.

Backtracking is backtracking, and some patterns — `(a+)+b` is the classic — can run for longer than anyone is
prepared to wait. Each attempt therefore has a budget:

```smalltalk
Regex stepLimit          "1000000 by default"
Regex stepLimit: 50000
Regex stepLimit: nil     "no budget at all"
```

Run it out and you get a `RegexError` rather than a system that has stopped answering. The budget is per
attempt, not per search, so looking through a long string does not use it up.

## What it does not do

No look-ahead or look-behind (`(?=`, `(?!`, `(?<=`), no named groups, no multiline or dot-all modes (`^` and
`$` mean the start and the end of the whole subject), no possessive quantifiers or atomic groups, and no
Unicode properties. A pattern does run over a `WideString` character by character, and `\b` asks
`Character>>isLetter`, which knows about letters outside ASCII; but `\w` and `\d` are the ASCII ranges.

## Notes

* 64 SUnit tests in `tests.st`, plus 141 checks in `tests/tests.txt` that `make check` runs.
* The package loads SUnit, since its tests are written in it.
