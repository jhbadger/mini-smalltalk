% Programs used by tests.txt.

% ---- control and cut ----
t1(X) :- member(X, [1,2,3]), X > 1, !.
t2(X) :- ( member(X, [1,2,3]), X > 1 -> true ; X = none ).
t3(X) :- member(X, [1,2,3]), ( X > 1, ! ; fail ).
t4(a). t4(b). t4(c).
t5(X) :- t4(X), !.
t5(z).
t6(X) :- \+ \+ X = 1, var(X).
t7(X) :- call((member(X, [1,2,3]), !)).
t8(X) :- member(X, [1,2,3]), call(!).
t9(X, Y) :- ( X = 1 ; X = 2 ), ( Y = a ; Y = b ).
t10(X) :- once((member(X, [1,2,3]), X > 1)).
t11 :- ( fail -> true ; fail ).
t12(X) :- ( true ; X = 2 ), X = 1.
t14(X) :- catch(member(X, [1,2,3]), _, true).
t15(X) :- catch((member(X, [1,2,3]), X > 1), _, true), !.
t16(R) :- catch(t16b, E, R = caught(E)).
t16b :- throw(oops).
t17(N) :- ( member(N, [1,2,3]), N > 1 *-> true ; N = 0 ).
t18(N) :- ( member(N, [1,2,3]), N > 5 *-> true ; N = 0 ).
t19(X) :- member(X, [1,2,3]), \+ X = 2.
t20(L) :- findall(X-Y, (member(X, [1,2]), \+ X = 1, member(Y, [a,b])), L).

% ---- recursion ----
len([], 0).
len([_|T], N) :- len(T, M), N is M + 1.
count(N, N) :- !.
count(I, N) :- I1 is I + 1, count(I1, N).
nrev([], []).
nrev([H|T], R) :- nrev(T, RT), append(RT, [H], R).
fib(0, 0).
fib(1, 1).
fib(N, F) :- N > 1, A is N - 1, B is N - 2, fib(A, FA), fib(B, FB), F is FA + FB.
hanoi(0, _, _, _) :- !.
hanoi(N, F, T, V) :- N1 is N - 1, hanoi(N1, F, V, T), hanoi(N1, V, T, F).
queens(N, Qs) :- numlist(1, N, Ns), permutation(Ns, Qs), safe(Qs).
safe([]).
safe([Q|Qs]) :- no_attack(Q, Qs, 1), safe(Qs).
no_attack(_, [], _).
no_attack(Q, [Q1|Qs], D) :- Q =\= Q1 + D, Q =\= Q1 - D, D1 is D + 1, no_attack(Q, Qs, D1).
qsort([], []).
qsort([P|Xs], S) :- partition([X]>>(X < P), Xs, L, G), qsort(L, SL), qsort(G, SG), append(SL, [P|SG], S).
gcd_(A, 0, A) :- !.
gcd_(A, B, G) :- C is A mod B, gcd_(B, C, G).
fact(0, 1) :- !.
fact(N, F) :- N1 is N - 1, fact(N1, F1), F is N * F1.

% ---- a family ----
parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
parent(bob, pat).
parent(pat, jim).
grandparent(X, Z) :- parent(X, Y), parent(Y, Z).
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
sibling(X, Y) :- parent(P, X), parent(P, Y), X \== Y.

% ---- grammars ----
greeting --> [hello], name.
name --> [world].
name --> [prolog].
digits([D|T]) --> digit(D), digits(T).
digits([D]) --> digit(D).
digit(D) --> [D], { code_type(D, digit) }.
expr(X) --> term(X0), expr_rest(X0, X).
expr_rest(Acc, X) --> "+", !, term(Y), { Acc1 is Acc + Y }, expr_rest(Acc1, X).
expr_rest(Acc, X) --> "-", !, term(Y), { Acc1 is Acc - Y }, expr_rest(Acc1, X).
expr_rest(X, X) --> [].
term(X) --> digits(Ds), { number_codes(X, Ds) }.
anbn --> [].
anbn --> [a], anbn, [b].
ws --> [C], { code_type(C, space) }, !, ws.
ws --> [].

% ---- operators, directives, error recovery ----
:- op(700, xfx, ===>).
:- op(200, xfy, **).
rule(a ===> b).
rule(c ===> d).
:- dynamic counter/1.
counter(0).
bump :- retract(counter(N)), N1 is N + 1, assertz(counter(N1)).
:- initialization(assertz(init_ran(yes))).
this is a syntax error.
after_error(1).
:- fail.
after_failing_directive(1).
:- atom_length(X, Y).
after_error_directive(1).
