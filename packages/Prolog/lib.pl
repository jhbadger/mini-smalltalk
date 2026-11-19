% The Prolog library, loaded when the package is. Everything here is ordinary Prolog; a program may redefine any of it.

% ---- lists ----
append([], L, L).
append([H|T], L, [H|R]) :- append(T, L, R).

append(ListOfLists, List) :- '$append_lists'(ListOfLists, List).
'$append_lists'([], []).
'$append_lists'([L|Ls], As) :- append(L, Ws, As), '$append_lists'(Ls, Ws).

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

memberchk(X, L) :- member(X, L), !.

length(L, N) :-
    '$skip_list'(L, Len, Tail),
    (   Tail == []
    ->  N = Len
    ;   var(Tail)
    ->  '$length_open'(Tail, Len, N)
    ;   throw(error(type_error(list, L), context(length/2, _)))
    ).
'$length_open'(Tail, Len, N) :-
    integer(N), !,
    N >= Len,
    K is N - Len,
    '$make_list'(K, Tail).
'$length_open'(Tail, Len, N) :-
    var(N),
    '$length_enum'(Tail, Len, N).
'$length_enum'([], N, N).
'$length_enum'([_|T], Len, N) :- Len1 is Len + 1, '$length_enum'(T, Len1, N).
'$make_list'(0, []) :- !.
'$make_list'(K, [_|T]) :- K1 is K - 1, '$make_list'(K1, T).

reverse(L, R) :- '$reverse'(L, [], R).
'$reverse'([], A, A).
'$reverse'([H|T], A, R) :- '$reverse'(T, [H|A], R).

nth0(I, L, E) :- integer(I), !, I >= 0, '$nth_det'(I, L, E).
nth0(I, L, E) :- var(I), '$nth_gen'(L, E, 0, I).
nth1(I, L, E) :- integer(I), !, I >= 1, I0 is I - 1, '$nth_det'(I0, L, E).
nth1(I, L, E) :- var(I), '$nth_gen'(L, E, 1, I).
'$nth_det'(0, [E|_], E) :- !.
'$nth_det'(I, [_|T], E) :- I1 is I - 1, '$nth_det'(I1, T, E).
'$nth_gen'([E|_], E, B, B).
'$nth_gen'([_|T], E, B0, B) :- B1 is B0 + 1, '$nth_gen'(T, E, B1, B).

last([X|Xs], Last) :- '$last'(Xs, X, Last).
'$last'([], L, L).
'$last'([X|Xs], _, L) :- '$last'(Xs, X, L).

sum_list(L, S) :- '$sum_list'(L, 0, S).
'$sum_list'([], S, S).
'$sum_list'([H|T], A, S) :- A1 is A + H, '$sum_list'(T, A1, S).
sumlist(L, S) :- sum_list(L, S).

max_list([H|T], M) :- foldl('$max2', T, H, M).
min_list([H|T], M) :- foldl('$min2', T, H, M).
'$max2'(X, V0, V) :- V is max(X, V0).
'$min2'(X, V0, V) :- V is min(X, V0).

max_member(Max, List) :- msort(List, Sorted), last(Sorted, Max).
min_member(Min, List) :- msort(List, [Min|_]).

numlist(L, H, R) :- L =< H, '$numlist'(L, H, R).
'$numlist'(H, H, [H]) :- !.
'$numlist'(L, H, [L|T]) :- L1 is L + 1, '$numlist'(L1, H, T).

delete([], _, []).
delete([H|T], X, R) :- ( H \= X -> R = [H|R1] ; R = R1 ), delete(T, X, R1).

subtract([], _, []).
subtract([H|T], L, R) :- ( memberchk(H, L) -> R = R1 ; R = [H|R1] ), subtract(T, L, R1).

intersection([], _, []).
intersection([H|T], L, R) :- ( memberchk(H, L) -> R = [H|R1] ; R = R1 ), intersection(T, L, R1).

union([], L, L).
union([H|T], L, R) :- ( memberchk(H, L) -> R = R1 ; R = [H|R1] ), union(T, L, R1).

select(X, [X|T], T).
select(X, [H|T], [H|R]) :- select(X, T, R).

selectchk(X, L, R) :- select(X, L, R), !.

select(X, Xs, Y, Ys) :- '$select4'(Xs, X, Y, Ys).
'$select4'([X|T], X, Y, [Y|T]).
'$select4'([H|T], X, Y, [H|T2]) :- '$select4'(T, X, Y, T2).

exclude(_, [], []).
exclude(P, [H|T], R) :- ( call(P, H) -> R = R1 ; R = [H|R1] ), exclude(P, T, R1).

include(_, [], []).
include(P, [H|T], R) :- ( call(P, H) -> R = [H|R1] ; R = R1 ), include(P, T, R1).

partition(_, [], [], []).
partition(P, [H|T], I, E) :-
    (   call(P, H) -> I = [H|I1], E = E1 ; I = I1, E = [H|E1] ),
    partition(P, T, I1, E1).

maplist(_, []).
maplist(G, [A|As]) :- call(G, A), maplist(G, As).
maplist(_, [], []).
maplist(G, [A|As], [B|Bs]) :- call(G, A, B), maplist(G, As, Bs).
maplist(_, [], [], []).
maplist(G, [A|As], [B|Bs], [C|Cs]) :- call(G, A, B, C), maplist(G, As, Bs, Cs).
maplist(_, [], [], [], []).
maplist(G, [A|As], [B|Bs], [C|Cs], [D|Ds]) :- call(G, A, B, C, D), maplist(G, As, Bs, Cs, Ds).

foldl(G, L, V0, V) :- '$foldl'(L, G, V0, V).
'$foldl'([], _, V, V).
'$foldl'([X|Xs], G, V0, V) :- call(G, X, V0, V1), '$foldl'(Xs, G, V1, V).
foldl(G, L1, L2, V0, V) :- '$foldl'(L1, L2, G, V0, V).
'$foldl'([], [], _, V, V).
'$foldl'([X|Xs], [Y|Ys], G, V0, V) :- call(G, X, Y, V0, V1), '$foldl'(Xs, Ys, G, V1, V).

permutation([], []).
permutation(L, [H|T]) :- select(H, L, R), permutation(R, T).

flatten(List, Flat) :- '$flatten'(List, [], Flat0), !, Flat = Flat0.
'$flatten'(Var, Tl, [Var|Tl]) :- var(Var), !.
'$flatten'([], Tl, Tl) :- !.
'$flatten'([Hd|Tl], Tail, List) :- !,
    '$flatten'(Hd, FlatHeadTail, List),
    '$flatten'(Tl, Tail, FlatHeadTail).
'$flatten'(NonList, Tl, [NonList|Tl]).

list_to_set(L, S) :- '$list_to_set'(L, [], S).
'$list_to_set'([], _, []).
'$list_to_set'([H|T], Seen, R) :-
    (   '$memberchk_eq'(H, Seen) -> R = R1 ; R = [H|R1] ),
    '$list_to_set'(T, [H|Seen], R1).
'$memberchk_eq'(X, [Y|T]) :- ( X == Y -> true ; '$memberchk_eq'(X, T) ).

list_to_ord_set(L, S) :- sort(L, S).
ord_union(A, B, C) :- append(A, B, D), sort(D, C).
ord_subtract(A, B, C) :- subtract(A, B, C).
ord_memberchk(X, L) :- memberchk(X, L).

nextto(X, Y, [X,Y|_]).
nextto(X, Y, [_|T]) :- nextto(X, Y, T).

sumlist(L, A, S) :- '$sum_list'(L, A, S).

pairs_keys_values([], [], []).
pairs_keys_values([K-V|T], [K|Ks], [V|Vs]) :- pairs_keys_values(T, Ks, Vs).
pairs_keys([], []).
pairs_keys([K-_|T], [K|Ks]) :- pairs_keys(T, Ks).
pairs_values([], []).
pairs_values([_-V|T], [V|Vs]) :- pairs_values(T, Vs).

predsort(P, L, Sorted) :-
    length(L, N),
    '$predsort'(P, N, L, _, Sorted1), !,
    Sorted = Sorted1.
'$predsort'(P, 2, [X1,X2|L], L, R) :- !,
    call(P, Delta, X1, X2),
    '$psort2'(Delta, X1, X2, R).
'$predsort'(_, 1, [X|L], L, [X]) :- !.
'$predsort'(_, 0, L, L, []) :- !.
'$predsort'(P, N, L1, L3, R) :-
    N1 is N // 2,
    plus(N1, N2, N),
    '$predsort'(P, N1, L1, L2, R1),
    '$predsort'(P, N2, L2, L3, R2),
    '$predmerge'(P, R1, R2, R).
'$psort2'(<, X1, X2, [X1,X2]).
'$psort2'(=, X1, _, [X1]).
'$psort2'(>, X1, X2, [X2,X1]).
'$predmerge'(_, [], R, R) :- !.
'$predmerge'(_, R, [], R) :- !.
'$predmerge'(P, [H1|T1], [H2|T2], Result) :-
    call(P, Delta, H1, H2), !,
    '$predmerge_'(Delta, P, H1, H2, T1, T2, Result).
'$predmerge_'(<, P, H1, H2, T1, T2, [H1|R]) :- '$predmerge'(P, T1, [H2|T2], R).
'$predmerge_'(=, P, H1, _, T1, T2, [H1|R]) :- '$predmerge'(P, T1, T2, R).
'$predmerge_'(>, P, H1, H2, T1, T2, [H2|R]) :- '$predmerge'(P, [H1|T1], T2, R).

% ---- all solutions ----
bagof(T, G, L) :-
    '$bagof_prepare'(T, G, Goal, W),
    (   W == none
    ->  findall(T, Goal, L), L \== []
    ;   findall(W-T, Goal, Pairs), Pairs \== [],
        keysort(Pairs, Sorted),
        '$bagof_group'(Sorted, Groups),
        member(W-L, Groups)
    ).

setof(T, G, S) :- bagof(T, G, L), sort(L, S).

aggregate_all(count, G, C) :- !, findall(x, G, L), length(L, C).
aggregate_all(sum(E), G, S) :- !, findall(E, G, L), sum_list(L, S).
aggregate_all(max(E), G, M) :- !, findall(E, G, L), L \== [], '$max_of'(L, M).
aggregate_all(min(E), G, M) :- !, findall(E, G, L), L \== [], '$min_of'(L, M).
aggregate_all(bag(E), G, L) :- !, findall(E, G, L).
aggregate_all(set(E), G, S) :- !, findall(E, G, L), sort(L, S).
'$max_of'([H|T], M) :- foldl('$max_term', T, H, M).
'$min_of'([H|T], M) :- foldl('$min_term', T, H, M).
'$max_term'(X, M0, M) :- ( '$agg_less'(M0, X) -> M = X ; M = M0 ).
'$min_term'(X, M0, M) :- ( '$agg_less'(X, M0) -> M = X ; M = M0 ).
'$agg_less'(A, B) :- number(A), number(B), !, A < B.
'$agg_less'(A, B) :- A @< B.

% ---- control and utilities ----
apply(G, Args) :- G =.. L0, append(L0, Args, L1), G2 =.. L1, call(G2).

concat_atom(L, R) :- atomic_list_concat(L, R).
concat_atom(L, Sep, R) :- atomic_list_concat(L, Sep, R).

assertion(G) :- ( \+ \+ call(G) -> true ; throw(error(assertion_failed(G), _)) ).

must_be(Type, X) :- '$must_be'(Type, X).
'$must_be'(integer, X) :- !, ( integer(X) -> true ; var(X) -> throw(error(instantiation_error, _)) ; throw(error(type_error(integer, X), _)) ).
'$must_be'(atom, X) :- !, ( atom(X) -> true ; var(X) -> throw(error(instantiation_error, _)) ; throw(error(type_error(atom, X), _)) ).
'$must_be'(callable, X) :- !, ( callable(X) -> true ; var(X) -> throw(error(instantiation_error, _)) ; throw(error(type_error(callable, X), _)) ).
'$must_be'(var, X) :- !, ( var(X) -> true ; throw(error(uninstantiation_error(X), _)) ).
'$must_be'(boolean, X) :- !, ( (X == true ; X == false) -> true ; var(X) -> throw(error(instantiation_error, _)) ; throw(error(type_error(bool, X), _)) ).
'$must_be'(list, X) :- !, ( is_list(X) -> true ; throw(error(type_error(list, X), _)) ).
'$must_be'(positive_integer, X) :- !, ( integer(X) -> ( X > 0 -> true ; throw(error(type_error(positive_integer, X), _)) ) ; var(X) -> throw(error(instantiation_error, _)) ; throw(error(type_error(integer, X), _)) ).
'$must_be'(nonneg, X) :- !, ( integer(X) -> ( X >= 0 -> true ; throw(error(type_error(nonneg, X), _)) ) ; var(X) -> throw(error(instantiation_error, _)) ; throw(error(type_error(integer, X), _)) ).
'$must_be'(_, _).

print_message(_, _).

% ---- lambda expressions (library yall): Params>>Body, optionally Free/Params>>Body ----
'>>'(Ps, L) :- '$yall'(Ps, L, []).
'>>'(Ps, L, A1) :- '$yall'(Ps, L, [A1]).
'>>'(Ps, L, A1, A2) :- '$yall'(Ps, L, [A1,A2]).
'>>'(Ps, L, A1, A2, A3) :- '$yall'(Ps, L, [A1,A2,A3]).
'>>'(Ps, L, A1, A2, A3, A4) :- '$yall'(Ps, L, [A1,A2,A3,A4]).
'>>'(Ps, L, A1, A2, A3, A4, A5) :- '$yall'(Ps, L, [A1,A2,A3,A4,A5]).
'>>'(Ps, L, A1, A2, A3, A4, A5, A6) :- '$yall'(Ps, L, [A1,A2,A3,A4,A5,A6]).
'>>'(Ps, L, A1, A2, A3, A4, A5, A6, A7) :- '$yall'(Ps, L, [A1,A2,A3,A4,A5,A6,A7]).

'$yall'(Ps, L, Args) :-
    '$yall_copy'(Ps, L, Ps1, L1),
    '$yall_bind'(Ps1, Args, Rest),
    (   Rest == []
    ->  call(L1)
    ;   G =.. [call, L1|Rest],
        call(G)
    ).
'$yall_copy'(Free/Ps, L, Ps1, L1) :- !, copy_term(Free/Ps>>L, Free/Ps1>>L1).
'$yall_copy'(Ps, L, Ps1, L1) :- copy_term(Ps>>L, Ps1>>L1).
'$yall_bind'([], Rest, Rest) :- !.
'$yall_bind'([P|Ps], [A|As], Rest) :- !, P = A, '$yall_bind'(Ps, As, Rest).
'$yall_bind'(_, [], []).
