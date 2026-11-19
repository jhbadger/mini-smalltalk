"The Prolog tutorial: facts and rules, queries and backtracking, unification, lists, arithmetic, the cut,
findall, the database, DCGs, and the bridge to Smalltalk.  Start it with   PrologTutorial go"

AbstractTutorial subclass: #PrologTutorial instanceVariableNames: '' classVariableNames: '' category: 'Prolog'!

!PrologTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Prolog'!
lessonSelectors
	^#(#welcome #factsAndQueries #rules #unification #backtracking #lists #arithmetic
		#cutAndNegation #findall #theDatabase #dcg #callingSmalltalk #smalltalkCallingProlog
		#theWorkspace #whatNext)! !

!PrologTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'This is a different way of computing.  You do not tell the machine how to work
something out; you state what is true, and ask questions.  Finding the answers
is the system''s business.

This is a Prolog inside Smalltalk, in the spirit of the one Digitalk shipped
with Smalltalk/V.  Everything in this tutorial is live.  Select a line and
press ctrl-P (print it) to run it.

Here is a whole program and a question about it:

Prolog reset. Prolog consult: ''parent(tom, bob). parent(bob, ann).''
Prolog answer: ''parent(tom, Who)''
Prolog answer: ''parent(Who, ann)''

Notice the second question.  The same fact answered both who the child of tom
is and who the parent of ann is.  Nothing in the program said how to do either.
That is the whole idea, and everything else is detail.

Every lesson begins by forgetting the last one''s program, so each stands on
its own and you can jump straight to any of them.'!
factsAndQueries
	^TutorialLesson title: 'Facts and queries' text:
'A fact says that something holds.  It is a name, some arguments in brackets,
and a full stop.

Prolog reset. Prolog consult: ''likes(mary, food). likes(mary, wine). likes(john, wine).''

A query asks whether something holds.  The simplest kind has no variables and
answers yes or no:

Prolog succeeds: ''likes(mary, wine)''
Prolog succeeds: ''likes(john, food)''

A name beginning with a CAPITAL letter is a variable, and asking with one in it
means find me a value that makes this true:

Prolog answer: ''likes(mary, X)''
Prolog answer: ''likes(Who, wine)''

answer: gives you what a Prolog toplevel would print.  When you want the
answers as Smalltalk objects instead:

Prolog solve: ''likes(mary, X)''
Prolog solveFirst: ''likes(Who, wine)''
Prolog valueOf: ''X'' in: ''likes(john, X)''

Values come back as Smalltalk ones: an atom is a Symbol, a list is an Array,
numbers and strings are themselves.  A query with no solution answers false,
and solveFirst: answers nil:

Prolog answer: ''likes(fred, beer)''
(Prolog solveFirst: ''likes(fred, beer)'') printString'!
rules
	^TutorialLesson title: 'Rules' text:
'A rule says that something holds IF something else does.  The turnstile :- is
read as if, and the comma as and.

Prolog reset. Prolog consult: ''parent(tom, bob). parent(bob, ann). parent(bob, pat). grandparent(X, Z) :- parent(X, Y), parent(Y, Z).''
Prolog answer: ''grandparent(tom, Who)''

Read the rule aloud: X is a grandparent of Z if X is a parent of some Y and
that Y is a parent of Z.  Y appears twice in the body and nowhere in the head,
which is how the two steps are joined up.

A predicate can have several rules, and they are tried in order.  That is how
you say or:

Prolog reset. Prolog consult: ''parent(tom, bob). parent(bob, ann). ancestor(X, Y) :- parent(X, Y). ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).''
Prolog answer: ''ancestor(tom, Who)''

The second rule mentions ancestor in its own body.  Recursion is the only
looping construct Prolog has, and this shape -- one rule for the simple case,
one that takes a step and recurses -- is the one you will write over and over.

Order matters for termination, not for truth: put the simple case first.'!
unification
	^TutorialLesson title: 'Unification' text:
'There is no assignment in Prolog.  The one operation is UNIFICATION, written
=, which asks whether two terms can be made the same, and binds variables as
far as it must to do it.

Prolog reset.
Prolog answer: ''X = 3''
Prolog answer: ''f(X, b) = f(a, Y)''
Prolog answer: ''f(a) = f(b)''
Prolog answer: ''X = Y''

The second one is the interesting case: X must be a and Y must be b for the two
terms to be the same, so that is what they become.  Nothing was computed.

A variable once bound stays bound for the rest of that solution:

Prolog answer: ''X = 3, X = 4''
Prolog answer: ''X = 3, Y is X + 1''

Equality of terms as they stand, without binding anything, is a different
question and has its own operator:

Prolog answer: ''X == 3''
Prolog answer: ''X = 3, X == 3''
Prolog answer: ''a \== b''

Terms can be taken apart as well as put together:

Prolog answer: ''functor(point(1,2), Name, Arity)''
Prolog answer: ''arg(2, point(1,2), A)''
Prolog answer: ''point(1,2) =.. L'''!
backtracking
	^TutorialLesson title: 'Backtracking' text:
'When a goal can be satisfied in more than one way, Prolog takes the first, and
if something later fails it comes BACK and tries the next.  That is the whole
search strategy.

Prolog reset. Prolog consult: ''colour(red). colour(green). colour(blue). size(small). size(large).''
Prolog answer: ''colour(C)''
Prolog answer: ''colour(C), size(S)''

The second query gives all six combinations, in the order you would get from
two nested loops, without anybody writing a loop.

Add a condition and the failures prune the search:

Prolog answer: ''colour(C), C \= green''

between/3 is the usual way to make a range to search over:

Prolog answer: ''between(1, 5, X)''
Prolog answer: ''between(1, 20, X), 0 is X mod 7''

A goal that fails makes the system back up to the most recent choice it has not
yet used.  You can watch that by asking for something that only works at the
end:

Prolog reset. Prolog consult: ''n(1). n(2). n(3). n(4).''
Prolog answer: ''n(X), n(Y), X + Y =:= 7''

There is no cleverness here: it tries every pair until the arithmetic holds.
Keeping the most selective goal first is how you make a Prolog program fast.'!
lists
	^TutorialLesson title: 'Lists' text:
'A list is written in square brackets, and the bar separates the first element
from the rest:

Prolog reset.
Prolog answer: ''X = [a, b, c]''
Prolog answer: ''[H|T] = [a, b, c]''
Prolog answer: ''[A, B|Rest] = [1, 2, 3, 4]''

That is unification again, and it is how list predicates are written.  The
library has the usual ones:

Prolog answer: ''member(X, [a, b, c])''
Prolog answer: ''append([1,2], [3], L)''
Prolog answer: ''length([a,b,c], N)''
Prolog answer: ''reverse([1,2,3], R)''
Prolog answer: ''nth1(2, [a,b,c], E)''
Prolog answer: ''msort([3,1,2], S)''
Prolog answer: ''sum_list([1,2,3], Sum)''

append is worth a second look, because it runs backwards as well.  Asking for
the two pieces rather than the whole gives every way of splitting a list:

Prolog answer: ''append(X, Y, [1,2,3])''

maplist applies a predicate across a list, and the lambda notation saves
writing a predicate for something used once:

Prolog answer: ''maplist([X,Y]>>(Y is X*2), [1,2,3], L)''
Prolog answer: ''include([X]>>(X > 2), [1,2,3,4], L)''
Prolog answer: ''foldl([X,A0,A]>>(A is A0+X), [1,2,3], 0, Sum)'''!
arithmetic
	^TutorialLesson title: 'Arithmetic' text:
'Arithmetic is not unification.  X = 1 + 1 makes X the TERM 1+1; to work it out
you must ask for it with is:

Prolog reset.
Prolog answer: ''X = 1 + 1''
Prolog answer: ''X is 1 + 1''

is evaluates its right side, so everything in there must already be known.
Asking it to work out something with an unbound variable in it is an error, not
a failure:

Prolog answer: ''Y = 3, X is Y * 2''
Prolog answer: ''catch(X is Y + 1, E, true)''

Comparison has its own operators, which evaluate both sides:

Prolog answer: ''5 > 3''
Prolog answer: ''2 + 2 =:= 4''
Prolog answer: ''2 + 2 = 4''

The last one is false, and that catches everybody once: = is unification, and
the term 2+2 is not the term 4.

Integers are of any size, and the usual functions are there:

Prolog valueOf: ''X'' in: ''X is 2 ** 100''
Prolog valueOf: ''X'' in: ''X is 7 // 2''
Prolog valueOf: ''X'' in: ''X is 7 mod 2''
Prolog valueOf: ''X'' in: ''X is max(3, 4) + abs(-2)''
Prolog valueOf: ''X'' in: ''X is sqrt(2)''
Prolog valueOf: ''X'' in: ''X is pi''

Division gives an integer when it is exact and a float when it is not:

Prolog valueOf: ''X'' in: ''X is 6 / 3''
Prolog valueOf: ''X'' in: ''X is 7 / 2'''!
cutAndNegation
	^TutorialLesson title: 'The cut, and negation' text:
'The cut, written as a single exclamation mark, commits to the choices made so
far in the current predicate.  Everything before it in this clause, and the
choice of this clause itself, is final.

Prolog reset. Prolog consult: ''first(X, [X|_]) :- !!. first(X, [_|T]) :- first(X, T).''
Prolog answer: ''first(F, [a,b,c])''

Without the cut that would offer b and c as well on backtracking, which is not
what first means.  The cut is how you say I have my answer, stop looking.

Its commonest use is a default:

Prolog reset. Prolog consult: ''kind(N, negative) :- N < 0, !!. kind(0, zero) :- !!. kind(_, positive).''
Prolog answer: ''kind(-5, K)''
Prolog answer: ''kind(0, K)''
Prolog answer: ''kind(5, K)''

Negation is written \+ and means not provable.  It succeeds when its goal
fails:

Prolog reset. Prolog consult: ''bird(tweety). bird(polly). penguin(polly).''
Prolog answer: ''bird(X), \+ penguin(X)''

Be careful with it.  \+ asks whether the system can PROVE the goal, not
whether the goal is false in the world; anything it has never been told is
treated as untrue.  And it binds nothing, so put it after the goals that do:

Prolog succeeds: ''\+ penguin(X), bird(X)'''!
findall
	^TutorialLesson title: 'Collecting all the answers' text:
'Backtracking gives you the answers one at a time.  findall gathers them into a
list, so that a program can work with the lot:

Prolog reset. Prolog consult: ''age(peter, 7). age(ann, 11). age(pat, 8). age(tom, 5).''
Prolog answer: ''findall(N, age(N, _), L)''
Prolog answer: ''findall(N-A, age(N, A), L)''
Prolog answer: ''findall(N, (age(N, A), A > 7), L)''

findall always succeeds, with the empty list when there is nothing:

Prolog answer: ''findall(X, age(X, 99), L)''

setof sorts and removes duplicates, and FAILS when there is nothing, which is
often what you want:

Prolog answer: ''setof(A, N^age(N, A), L)''

The N^ says that N is not something to group by.  Without it, setof gives you
one solution per value of the free variable, which is how you group:

Prolog answer: ''setof(N, age(N, A), L)''

aggregate_all does the counting and summing in one step:

Prolog answer: ''aggregate_all(count, age(_, _), N)''
Prolog answer: ''aggregate_all(sum(A), age(_, A), Total)''
Prolog answer: ''aggregate_all(max(A), age(_, A), Oldest)''

From Smalltalk, solve: is findall by another route, and often the easier one:

(Prolog solve: ''age(N, A)'') size
(Prolog solve: ''age(N, A)'') first'!
theDatabase
	^TutorialLesson title: 'Changing the program' text:
'A Prolog program is a database, and a running program can change it.

Prolog reset. Prolog consult: ''counter(0).''
Prolog answer: ''counter(X)''

assert adds a clause and retract takes one away:

Prolog consult: '':- retract(counter(0)), assert(counter(1)).''
Prolog answer: ''counter(X)''

From Smalltalk the same thing reads better:

Prolog assert: ''likes(mary, wine)''
Prolog assert: ''likes(john, beer)''
Prolog answer: ''likes(Who, What)''

asserta puts the clause first and assertz last, which decides the order
answers come in.  retractall removes everything that matches:

Prolog consult: '':- retractall(likes(_, _)).''
Prolog answer: ''likes(Who, What)''

The program itself can be looked at:

Prolog reset. Prolog consult: ''double(X, Y) :- Y is X * 2.''
Prolog answer: ''clause(double(A, B), Body)''
Prolog succeeds: ''current_predicate(double/2)''

Used in moderation this is how you memoise an expensive computation or keep
state between queries.  Used heavily it makes a program that is hard to think
about, for the same reason a program full of global variables is.'!
dcg
	^TutorialLesson title: 'Grammars' text:
'A definite clause grammar is Prolog''s notation for parsing.  Rules are written
with --> and the system turns them into ordinary clauses that thread the input
through for you.

Prolog reset. Prolog consult: ''greeting --> [hello], name. name --> [world]. name --> [prolog].''
Prolog succeeds: ''phrase(greeting, [hello, world])''
Prolog succeeds: ''phrase(greeting, [hello, there])''

Curly braces let a rule do ordinary Prolog work, which is how a grammar builds
a result as it parses rather than only saying yes or no:

Prolog reset. Prolog consult: ''sum(N) --> num(A), [plus], num(B), { N is A + B }. num(N) --> [N], { number(N) }.''

Prolog answer: ''phrase(sum(N), [2, plus, 3])''
Prolog succeeds: ''phrase(sum(N), [2, times, 3])''

A grammar also runs backwards, GENERATING rather than parsing.  This one
describes any number of a followed by the same number of b:

Prolog reset. Prolog consult: ''ab --> []. ab --> [a], ab, [b].''
Prolog answer: ''length(L, 4), phrase(ab, L)''
Prolog succeeds: ''phrase(ab, [a,a,b,b])''
Prolog succeeds: ''phrase(ab, [a,a,b])''

Note the length(L, 4) in front.  Asking for phrase(ab, L) on its own would go
on answering for ever, each solution one pair longer than the last; a generator
has to be bounded by something, and that is true of any Prolog predicate that
can make terms rather than only test them.

That is a grammar no regular expression can write, and it took two lines.
phrase/3 leaves the rest of the input for you, which is what you want when the
grammar does not cover the whole of it:

Prolog answer: ''phrase(ab, [a,b,c,d], Rest)'''!
callingSmalltalk
	^TutorialLesson title: 'Prolog calling Smalltalk' text:
'The language here is not sealed off: a Prolog goal can evaluate Smalltalk and
use the answer.

Prolog reset.
Prolog answer: ''smalltalk(''''3 + 4'''', X)''
Prolog answer: ''smalltalk(''''Date today printString'''', S)''

smalltalk_send/4 sends a message, with the arguments as a list:

Prolog answer: ''smalltalk_send(10, ''''between:and:'''', [1, 20], B)''
Prolog answer: ''smalltalk_send(''''hello'''', ''''asUppercase'''', [], S)''

A collection comes across as a Prolog list, which is usually what you want:

Prolog answer: ''smalltalk(''''#(3 1 2) asSortedCollection asArray'''', L)''

and a global, such as a class, can be reached by name:

Prolog succeeds: ''smalltalk_global(''''Date'''', D)''

Mixing the two is where this earns its keep.  A rule can use Smalltalk for the
part Smalltalk is better at:

Prolog reset. Prolog consult: ''shouty(Word, Loud) :- smalltalk_send(Word, ''''asUppercase'''', [], Loud).''
Prolog answer: ''shouty(''''hello'''', X)''

If the Smalltalk raises an error, the Prolog goal throws, and you can catch it
the Prolog way:

Prolog answer: ''catch(smalltalk(''''1/0'''', X), E, (E = error(smalltalk_error(M), _)))'''!
smalltalkCallingProlog
	^TutorialLesson title: 'Smalltalk calling Prolog' text:
'The other direction is the one you will use most: Prolog as a query engine
inside a Smalltalk program.

Prolog reset. Prolog consult: ''route(london, paris). route(paris, rome). route(rome, cairo). reaches(A, B) :- route(A, B). reaches(A, B) :- route(A, C), reaches(C, B).''

Ask for all of the solutions as Smalltalk objects:

(Prolog solve: ''reaches(london, X)'') collect: [:each | each at: ''X'']

one solution:

Prolog solveFirst: ''reaches(london, X)''

one value:

Prolog valueOf: ''X'' in: ''reaches(paris, X)''

just a yes or no:

Prolog succeeds: ''reaches(london, cairo)''

or handle each solution as it is found, which avoids building a collection:

| n | n := 0. Prolog solve: ''reaches(london, X)'' do: [:each | n := n + 1]. n

A predicate can also be written in Smalltalk when that is easier, and from the
other side it looks like any other predicate:

Prolog define: #double arity: 2 as: [:engine :args | engine unify: (args at: 2) with: (engine eval: (args at: 1)) * 2].
Prolog valueOf: ''Y'' in: ''double(21, Y)''

Engines are separate: Prolog newEngine answers one with its own database, which
is how you keep two unrelated programs apart.

Prolog newEngine == Prolog engine'!
theWorkspace
	^TutorialLesson title: 'The query window' text:
'Typing Prolog inside Smalltalk string literals gets old quickly.  The System
menu has a prolog workspace for it: right-click the desktop, then prolog
workspace.

PrologTool openWorkspace

It is an ordinary window with one difference: ctrl-P does not evaluate
Smalltalk, it hands the text to Prolog.  Text beginning with ?- is run as a
query and the answers are inserted below it; anything else is added to the
program.  Several lines can be selected at once.

The window opens with an example in it.  Try selecting these lines in it, one
group at a time:

    parent(tom, bob).
    parent(bob, ann).

    ?- parent(tom, Who).

The same thing without a window is what the tool does underneath, and it is
useful in a test:

PrologTool evaluate: ''?- member(X, [a,b,c]).''
PrologTool evaluate: ''extra(fact).''
PrologTool evaluate: ''?- extra(X).''

Writing to the console from Prolog goes to the window, or to the Transcript
when there is none:

Prolog answer: ''format("~w and ~w~n", [this, that])'''!
whatNext
	^TutorialLesson title: 'Where to go next' text:
'That is the language.  A few things to carry away:

State what is true, then ask.  The order of the clauses decides the order of
the answers and whether the search ends, not what is true.

= is unification and is is arithmetic; mixing them up is the commonest mistake.

A predicate that can be run backwards is worth more than one that cannot, so
prefer unification to arithmetic when you have the choice.

What is here: the Edinburgh and ISO syntax, the control constructs, catch and
throw, findall, bagof and setof, DCGs, assert and retract, format, the standard
list library in lib.pl (ordinary Prolog you can read and override), and
arbitrary-sized integers.

Prolog valueOf: ''X'' in: ''X is 50 * 49 * 48 * 47 * 46 * 45''

What is not: modules, tabling, attributed variables, streams other than the
console, and dicts.

It is an interpreter written in Smalltalk, so expect on the order of a hundred
thousand goals a second.  Write the selective goal first, use between/3 and
findall rather than very deep search, and it is fast enough for real work.

The library itself is worth reading:

(Smalltalk packagePath: ''Prolog''), ''/lib.pl''

The package README is packages/Prolog/README.md, and the classes are in the
categories beginning with Prolog.

Other tutorials in this image:

Smalltalk tutorialNames

and the one for the language this is written in:

Smalltalk tutorial'! !
