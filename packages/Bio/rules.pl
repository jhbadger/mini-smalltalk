% Rules over the facts BioProlog asserts. Loaded automatically the first time facts are asserted.

gene(Id, Index, Name) :- qualifier(Id, Index, gene, Name).
product(Id, Index, Name) :- qualifier(Id, Index, product, Name).
locus_tag(Id, Index, Tag) :- qualifier(Id, Index, locus_tag, Tag).

cds(Id, Index, Start, Stop, Strand) :- feature(Id, Index, cds, Start, Stop, Strand).
gene_feature(Id, Index, Start, Stop, Strand) :- feature(Id, Index, gene, Start, Stop, Strand).

forward(Id, Index) :- feature(Id, Index, _, _, _, 1).
reverse_strand(Id, Index) :- feature(Id, Index, _, _, _, -1).

feature_length(Id, Index, Length) :-
    feature(Id, Index, _, Start, Stop, _),
    Length is Stop - Start + 1.

% two features of the same record that share at least one base
overlapping(Id, A, B) :-
    feature(Id, A, _, S1, E1, _),
    feature(Id, B, _, S2, E2, _),
    A \== B,
    S1 =< E2,
    S2 =< E1.

% a feature containing a position
feature_at(Id, Index, Position) :-
    feature(Id, Index, _, Start, Stop, _),
    Start =< Position,
    Position =< Stop.

% features sorted by where they start
features_by_start(Id, List) :-
    findall(Start-Index, feature(Id, Index, _, Start, _, _), Pairs),
    keysort(Pairs, List).

% the named gene's coordinates
gene_location(Id, Name, Start, Stop, Strand) :-
    gene(Id, Index, Name),
    feature(Id, Index, _, Start, Stop, Strand).

% records longer than N bases
longer_than(Id, N) :- sequence(Id, Length, _), Length > N.
