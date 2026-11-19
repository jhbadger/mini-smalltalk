# Prolog in Smalltalk

A Prolog system in the spirit of Digitalk's Smalltalk/V Prolog: Edinburgh/ISO syntax, a library of standard predicates, and a
two-way bridge to Smalltalk objects. It is an optional package:

```smalltalk
Smalltalk loadPackage: 'Prolog'          "or: st -l Prolog, or System menu → load package..."
```

## From Smalltalk

```smalltalk
Prolog consult: 'parent(tom, bob). parent(bob, ann).
                 grandparent(X, Z) :- parent(X, Y), parent(Y, Z).'.
Prolog solve: 'grandparent(tom, W)'        "an OrderedCollection of Dictionaries: 'W' -> #ann"
Prolog solveFirst: 'parent(X, ann)'        "a Dictionary, or nil"
Prolog succeeds: 'parent(tom, bob)'        "true"
Prolog valueOf: 'L' in: 'findall(X, member(X, [3,1,2]), L), msort(L, S)'
Prolog answer: 'member(X, [a,b])'          "'X = a ;\nX = b.'  -- what a toplevel would print"
Prolog solve: 'between(1, 3, X)' do: [:solution | Transcript showCr: (solution at: 'X') printString].
Prolog assert: 'parent(ann, joe)'          "add a clause"
Prolog consultFile: 'family.pl'
Prolog reset                               "forget every program"
Prolog newEngine                           "a separate engine; use its #consultString:, #solveOnce: ..."
```

Prolog values come back as Smalltalk ones: integers, floats and strings as they are, atoms are Symbols, lists are Arrays,
`true`/`false`/`nil` are the Smalltalk objects, compound terms are `PrologStruct`s (they print as Prolog).

**Predicates written in Smalltalk:**

```smalltalk
Prolog define: #double arity: 2 as: [:engine :args |
    engine unify: (args at: 2) with: (engine eval: (args at: 1)) * 2].
Prolog valueOf: 'Y' in: 'double(21, Y)'    "42"
```

## Prolog calling Smalltalk

| predicate | meaning |
|---|---|
| `smalltalk(Expr, Result)` | evaluate Smalltalk source (a string/atom): `smalltalk('3 + 4', X)` |
| `smalltalk(Expr)` | evaluate; fails if the result is `false` |
| `smalltalk_send(Receiver, Selector, Args, Result)` | `smalltalk_send(10, 'between:and:', [1, 20], B)` |
| `smalltalk_global(Name, Object)` | a global such as a class: `smalltalk_global('Date', D)` |
| `smalltalk_ref(Expr, Object)`, `smalltalk_send_ref/4` | like the above, but the result stays a live Smalltalk object |
| `smalltalk_print(Object, String)` | `printString` |

Results that are collections become Prolog lists (and Prolog lists passed to Smalltalk become Arrays); use the `_ref` forms to keep a
collection as an object you can send messages to. Any other Smalltalk object appears in Prolog as an opaque constant that unifies only
with itself. A Smalltalk error inside `smalltalk/2` is a Prolog exception, `error(smalltalk_error(Message), _)`; a syntax
error is `error(syntax_error(Message), _)`.

## The query window

*System menu → prolog workspace* opens a window with some example text. Select text (or leave the cursor on a line) and press
**ctrl-P** (print it): text starting with `?-` runs the query and inserts the answers (and anything the goal wrote) below it; any
other text is added to the program. **ctrl-D** does the same without inserting anything. Several lines can be selected at once.

## The language

* **Syntax**: standard operators (and `op/3`), quoted atoms with escapes, `0'c`, `0x1F`, strings `"..."` (a string type;
  `set_prolog_flag(double_quotes, codes)` for code lists), `` `codes` ``, `{}`/1, comments, block comments.
  Argument priority is relaxed as in SWI-Prolog, so `f(a:-b)` and `f(a;b)` are accepted.
* **Control**: `,` `;` `->` `*->` `\+` `!`, `call/1..8`, `once`, `ignore`, `forall`, `catch/throw` (with ISO error terms),
  `findall/3,4`, `bagof`/`setof` (with `^`), `aggregate_all(count|sum|max|min|bag|set, ...)`, `between`, `phrase/2,3`.
* **DCG**: `-->` rules (terminals, strings, `{}`/1, `!`, `\+`, `call//N`, pushback).
* **Terms**: `=` `\=` `==` `\==` `@<`... `compare/3`, `functor`, `arg`, `=..`, `copy_term`, `term_variables`, `numbervars`,
  `setarg`, type tests, standard order of terms.
* **Arithmetic**: `is`, `=:=` `<` ..., integers of any size, floats; `+ - * / // mod rem div ** ^ min max abs sign gcd sqrt sin cos tan
  asin acos atan atan2 exp log log2 ceiling floor round truncate float integer msb << >> /\ \/ xor`, `pi e inf nan epsilon random cputime`.
  `/` gives an integer when exact; `**` and `^` of integers are exact.
* **Atoms and strings**: `atom_codes/chars/length/number/string`, `char_code`, `atom_concat` (also splitting), `sub_atom`/`sub_string`,
  `atomic_list_concat/2,3` (also splitting), `split_string`, `upcase_atom`, `string_concat`..., `term_to_atom`, `atom_to_term`, `char_type`,
  `format/1,2,3` (`~w ~p ~q ~a ~d ~D ~s ~e ~f ~g ~n ~c ~r ~R ~i ~* ~~` and column stops `~t ~| ~+`), `with_output_to/2`, `sformat`.
  Text is UTF-8; lengths and positions count characters.
* **Database**: `assert/asserta/assertz`, `retract`, `retractall`, `abolish`, `clause`, `dynamic`, `listing`, `portray_clause`,
  `current_predicate`, `predicate_property`; the logical update view is respected. `consult/1`, `initialization/1`, `:- Directive.`
* **Lists** (in `lib.pl`, ordinary Prolog you can read and override): `append member memberchk length reverse nth0 nth1 last sum_list max_list
  min_list numlist delete subtract intersection union select selectchk permutation flatten list_to_set exclude include partition
  maplist/2..5 foldl/4,5 predsort pairs_* nextto msort sort/2,4 keysort`, and yall lambdas: `maplist([X,Y]>>(Y is X*2), L, M)`.
* **Other**: `read/1` (from `engine input:`), `op/3`, `current_op/3`, flags, global variables `nb_setval`/`nb_getval`, `statistics`, `get_time`.

Errors are reported in words (`Unknown procedure: foo/1`), and a bad clause in a consulted file is reported and skipped.

## Notes

* It is an interpreter written in Smalltalk: expect on the order of 100,000 goals a second, and use `between/3`, `findall` and
  first-argument indexing (clauses that cannot match on the first argument are skipped without leaving a choicepoint) rather than
  very deep search. Deep recursion is fine: the machine keeps its stack on the heap.
* Not implemented: modules, tabling, attributed variables, streams other than the console, dicts, `read_term` options.
* `Prolog reset` (or `Prolog newEngine`) reloads `lib.pl`. Tests: `tests/tests.txt`, run by `make check`.
