"The Phylo tutorial: trees and Newick, drawing, distances and the models that correct them, neighbour joining
and UPGMA, multiple alignment and the bootstrap.  Start it with   PhyloTutorial go"

AbstractTutorial subclass: #PhyloTutorial instanceVariableNames: '' classVariableNames: '' category: 'Phylo'!

!PhyloTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Phylo'!
lessonSelectors
	^#(#welcome #treesAndNodes #newick #drawing #alongTheTree #reRooting #pruning #splits
		#theModels #theMatrix #neighbourJoining #upgma #multipleAlignment #theBootstrap
		#theBrowser #whatNext)! !

!PhyloTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'Phylogenetics is working out how a set of things are related from how alike
they are.  This package does the distance-based half of it: turn an alignment
into a table of distances, turn that into a tree, draw it, and ask how much of
it the data actually supports.

It builds on the Bio package, which it loads for you.

Everything here is live.  Select a line and press ctrl-P (print it) to run it.

The whole business in four lines:

| a t | a := Phylo exampleAlignment. t := a neighbourJoining. t asNewick
| a t | a := Phylo exampleAlignment. t := a neighbourJoining. t asText

The example data is not real: it was made by simulating sequence change along a
tree that is also in the package.  That is on purpose, because it lets you ask
a tree builder the only question that really matters -- does it get the right
tree back:

(Phylo exampleAlignment neighbourJoining) robinsonFouldsTo: Phylo exampleTree

Zero means the two trees have exactly the same shape.  Hold on to that trick;
it is how this package is tested.'!
treesAndNodes
	^TutorialLesson title: 'Trees and nodes' text:
'A PhyloTree is a root PhyloNode, and a node knows its label, the length of the
branch above it, its support, its children and its parent.  A node with no
children is a leaf, and its label is a taxon name.

| t | t := PhyloTree fromNewick: ''((A:0.1,B:0.2)95:0.05,C:0.3,D:0.4);''. t size
| t | t := PhyloTree fromNewick: ''((A:0.1,B:0.2)95:0.05,C:0.3,D:0.4);''. t taxa
| t | t := PhyloTree fromNewick: ''((A:0.1,B:0.2)95:0.05,C:0.3,D:0.4);''. t nodeCount
| t | t := PhyloTree fromNewick: ''((A:0.1,B:0.2)95:0.05,C:0.3,D:0.4);''. t leaves size
| t | t := PhyloTree fromNewick: ''((A:0.1,B:0.2)95:0.05,C:0.3,D:0.4);''. (t leafNamed: ''A'') branchLength

Walking a tree is by the four orders you would expect, each with a collecting
form:

| t | t := PhyloTree fromNewick: ''((A,B),C);''. t nodes size
| t | t := PhyloTree fromNewick: ''((A,B),C);''. t leaves size
| t | t := PhyloTree fromNewick: ''((A,B),C);''. t internalNodes size
| t n | t := PhyloTree fromNewick: ''((A,B),C);''. n := 0. t root preOrderDo: [:each | n := n + 1]. n

A tree with two branches at the root is rooted; one written with three is not.
That distinction matters, and the package keeps track of it:

(PhyloTree fromNewick: ''(A:1,B:2);'') isRooted
(PhyloTree fromNewick: ''(A,B,C);'') isRooted
(PhyloTree fromNewick: ''((A,B),(C,D));'') isBinary
(PhyloTree fromNewick: ''(A,B,C,D);'') isBinary'!
newick
	^TutorialLesson title: 'Newick' text:
'Newick is the parenthesised notation every phylogenetics program reads and
writes.  Nesting is grouping, a colon introduces a branch length, and a
semicolon ends the tree.

PhyloTree fromNewick: ''((A:0.1,B:0.2)95:0.05,C:0.3,D:0.4);''

The 95 after the closing bracket is read as that branch''s SUPPORT, because
that is what a number there almost always is.  A name there is kept as a
label:

(PhyloTree fromNewick: ''((A,B)95,C);'') internalNodes last support
(PhyloTree fromNewick: ''((A,B)Primates,C);'') internalNodes last label

A label may be quoted, in which case it can hold anything; an unquoted
underscore means a space, as the format says:

(PhyloTree fromNewick: ''(''''Homo sapiens'''':1,Gorilla:2);'') taxa
(PhyloTree fromNewick: ''(Homo_sapiens,Gorilla);'') taxa

Square brackets are a comment and are skipped:

(PhyloTree fromNewick: ''[a note](A,B[and another],C);'') taxa

Writing goes back the way it came, and the round trip is exact:

(PhyloTree fromNewick: ''((A:0.1,B:0.2)95:0.05,C:0.3);'') asNewick
(PhyloTree fromNewick: ''((A:0.1,B:0.2),C:0.3);'') asNewickWithoutLengths
PhyloTree readFrom: (Phylo exampleFile: ''example.tree'')

Nonsense is refused rather than half-read:

[PhyloTree fromNewick: ''((A,B);''] on: PhyloError do: [:e | e messageText]'!
drawing
	^TutorialLesson title: 'Drawing a tree' text:
'A tree you cannot see is hard to think about, so there is a renderer that
draws one with characters.

(PhyloTree fromNewick: ''((A:0.1,B:0.1)95:0.1,C:0.3,D:0.5);'') asText

Every leaf gets a row and every node a column.  In the default drawing -- a
PHYLOGRAM -- the column comes from the branch lengths, so the horizontal
distances mean something:

Phylo exampleTree asText

A CLADOGRAM throws the lengths away and shows only the shape, which is what
you want when the lengths are uninteresting or absent:

TreeRenderer cladogram: Phylo exampleTree

The width is yours to choose, and so is whether support values are drawn:

TreeRenderer render: Phylo exampleTree width: 25
TreeRenderer new showSupport: false; labelWidth: 10; render: Phylo exampleTree

A support value is written into the branch coming into its node when there is
room for it, which is why a bootstrapped tree reads so well:

(PhyloTree fromNewick: ''((A:0.2,B:0.2)97:0.2,C:0.4,D:0.4);'') asText

A tree with no lengths at all is drawn as a cladogram rather than as a single
vertical line, so you always see something:

(PhyloTree fromNewick: ''((A,B),C,D);'') asText

And for everything about a tree at once:

Phylo exampleTree report'!
alongTheTree
	^TutorialLesson title: 'Distances along the tree' text:
'Once a tree has branch lengths, the distance between two leaves is the lengths
along the path between them.  That is called the PATRISTIC distance, and it is
what the tree says about the pair:

| t | t := PhyloTree fromNewick: ''((A:0.1,B:0.2),C:0.3);''. t distanceBetween: ''A'' and: ''B''
| t | t := PhyloTree fromNewick: ''((A:0.1,B:0.2),C:0.3);''. t distanceBetween: ''A'' and: ''C''
Phylo exampleTree distanceBetween: ''Human'' and: ''Chimpanzee''
Phylo exampleTree distanceBetween: ''Human'' and: ''Lemur''

All of them at once gives you back a distance matrix, which is a good way to
see how much a tree has smoothed the data it was built from:

Phylo exampleTree distanceMatrix asText

The most recent common ancestor of a set of taxa is the node they all hang
under:

| t | t := PhyloTree fromNewick: ''((A,B),C);''. (t mrcaOf: #(''A'' ''B'')) leafCount
| t | t := PhyloTree fromNewick: ''((A,B),C);''. (t mrcaOf: #(''A'' ''C'')) isRoot
(Phylo exampleTree mrcaOf: #(''Human'' ''Gorilla'')) leafLabels

and the other measures you would expect:

Phylo exampleTree totalBranchLength
Phylo exampleTree height
(Phylo exampleTree leafNamed: ''Lemur'') distanceToRoot
(Phylo exampleTree leafNamed: ''Human'') depth'!
reRooting
	^TutorialLesson title: 'Re-rooting' text:
'A tree built from distances has no root: nothing in the data says which way is
up.  Neighbour joining therefore gives you an unrooted tree, written with three
branches at the root:

Phylo exampleAlignment neighbourJoining isRooted

Rooting it is a separate decision, and there are three ways to make it.

With an OUTGROUP, which is the honest one: something you know branched off
before everything else.

| t | t := Phylo exampleAlignment neighbourJoining. (t rootOn: ''Lemur'') isRooted
| t | t := Phylo exampleAlignment neighbourJoining. (t rootOnAll: #(''Lemur'' ''Marmoset'')) isRooted

At the MIDPOINT of the longest path between any two leaves, which is the usual
guess when you have no outgroup:

| t | t := Phylo exampleAlignment neighbourJoining. t rootOnMidpoint. t asText

Or on a particular branch, if you have a reason:

| t | t := PhyloTree fromNewick: ''((A:1,B:1):1,C:1,D:1);''. (t rootAt: (t leafNamed: ''C'')) asNewick

Going the other way turns the two branches at the root back into three:

| t | t := PhyloTree fromNewick: ''((A:1,B:1):1,(C:1,D:1):1);''. t unroot. t root children size

Re-rooting changes the drawing completely and the TOPOLOGY not at all, which
is the thing to keep hold of.  The next lesson but one shows how to check
that.'!
pruning
	^TutorialLesson title: 'Changing a tree' text:
'These all change the tree in place and answer it, so they can be strung
together.

Taking taxa out, which tidies up the branch lengths as it goes:

| t | t := PhyloTree fromNewick: ''((A:1,B:2):3,C:4);''. (t pruneTaxa: #(''A'')) asNewick

Note that B''s branch is now 5, not 2: the node that held A and B had only one
child left, so it went, and its length was given to the child.  A tree should
not acquire meaningless nodes just because something was removed.

Keeping only some taxa is the same thing said the other way:

| t | t := PhyloTree fromNewick: ''((A,B),(C,D));''. (t keepTaxa: #(''A'' ''C'')) taxa

Scaling every branch, for when the units are wrong:

| t | t := PhyloTree fromNewick: ''(A:1,B:2);''. (t scaleBy: 100) asNewick

Collapsing the branches that are too short to believe, which leaves a
polytomy -- a node with more than two children -- where the data could not
decide:

| t | t := PhyloTree fromNewick: ''((A:1,B:1):0.0001,C:1,D:1);''. (t collapseBranchesShorterThan: 0.01) root children size

Putting the smaller clade first everywhere, which makes the drawing read
tidily and changes nothing else:

| t | t := Phylo exampleTree copyTree. t ladderize. t asText

And when you want to change a tree without changing the one you were given:

| a b | a := PhyloTree fromNewick: ''(A:1,B:2);''. b := a copyTree. (b leafNamed: ''A'') branchLength: 99. (a leafNamed: ''A'') branchLength'!
splits
	^TutorialLesson title: 'Comparing two trees' text:
'Two trees can be written very differently and still be the same tree.  To
compare them you need something that does not depend on the drawing, and that
is the set of SPLITS: each internal branch cuts the taxa into two groups, and
the branch is that cut.

(PhyloTree fromNewick: ''((A,B),(C,D));'') splits

There is only one, because a four-taxon tree has one internal branch.  Each
split is written as the side that leaves out the first taxon alphabetically,
so the same cut always comes out the same way round whichever way the tree is
drawn or rooted:

| a b | a := PhyloTree fromNewick: ''((A,B),C,D);''. b := PhyloTree fromNewick: ''(D,C,(B,A));''. a hasSameTopologyAs: b
| a b | a := PhyloTree fromNewick: ''((A,B),C,D);''. b := PhyloTree fromNewick: ''(D,C,(B,A));''. a splits = b splits

The Robinson-Foulds distance counts the splits one tree has and the other has
not, both ways round.  Zero means identical:

| a b | a := PhyloTree fromNewick: ''((A,B),(C,D));''. b := PhyloTree fromNewick: ''((A,C),(B,D));''. a robinsonFouldsTo: b
| a | a := PhyloTree fromNewick: ''((A,B),(C,D));''. a robinsonFouldsTo: a

A star tree -- everything hanging off one node -- has no splits at all, which
is the right answer for a tree that says nothing:

(PhyloTree star: #(''A'' ''B'' ''C'' ''D'')) splits size

This is how the package tests itself, and how you should check any tree you
build against one you trust:

(Phylo exampleAlignment neighbourJoining) robinsonFouldsTo: Phylo exampleTree'!
theModels
	^TutorialLesson title: 'Distance models' text:
'The simplest distance between two aligned sequences is the share of columns
where they differ.  That is the p-distance, and it is an UNDERESTIMATE,
because a site that changed twice looks like a site that never changed:

PDistanceModel new distanceBetween: ''AAAAAAAAAA'' and: ''AAAAAAAATT''

A model corrects for those hidden changes.  Jukes-Cantor assumes every change
is as likely as every other:

JukesCantorModel new distanceBetween: ''AAAAAAAAAA'' and: ''AAAAAAAATT''

Always bigger than the raw count, and the gap grows as the sequences get
further apart.  Kimura''s two-parameter model goes further and counts
transitions (A to G, C to T) separately from transversions, because
transitions happen several times as often:

Kimura2ParameterModel new distanceBetween: ''AAAAAAAAAA'' and: ''GGAAAAAAAA''
Kimura2ParameterModel new distanceBetween: ''AAAAAAAAAA'' and: ''CCAAAAAAAA''

For protein there are two: a Poisson correction, and Kimura''s quick stand-in
for a PAM distance:

PoissonModel new distanceBetween: ''AAAAAAAAAA'' and: ''AAAAAAAAWW''
KimuraProteinModel new distanceBetween: ''AAAAAAAAAA'' and: ''AAAAAAAAWW''

The names they answer to, for when the model is a setting rather than a choice
in the code:

DistanceModel names
(DistanceModel named: ''k2p'') name

Two things worth knowing.  Only the columns where BOTH sequences have an
unambiguous residue are counted, so a gap costs you that column and no more:

PDistanceModel new distanceBetween: ''AN-A'' and: ''AGTT''

And when two sequences are so far apart that the correction has no answer, the
model gives up gracefully rather than failing in the middle of a matrix:

| m | m := JukesCantorModel new. m distanceBetween: ''AAAAAAAA'' and: ''CGCGCGCG''
| m | m := JukesCantorModel new. m distanceBetween: ''AAAAAAAA'' and: ''CGCGCGCG''. m sawSaturation'!
theMatrix
	^TutorialLesson title: 'The distance matrix' text:
'A DistanceMatrix is a square symmetric table with a label on each row.  Build
one from an alignment and a model:

DistanceMatrix fromAlignment: Phylo exampleAlignment model: ''jc69''
(DistanceMatrix fromAlignment: Phylo exampleAlignment model: ''jc69'') asText

Or by hand, which is what you do when the distances come from somewhere else
entirely -- morphology, or a table in a paper:

| m | m := DistanceMatrix labels: #(''A'' ''B'' ''C''). m at: 1 and: 2 put: 2. m at: 1 and: 3 put: 4. m at: 2 and: 3 put: 6. m asText

Setting one half sets the other, since the matrix is symmetric by
construction:

| m | m := DistanceMatrix labels: #(''A'' ''B''). m at: 1 and: 2 put: 5. m at: 2 and: 1
| m | m := DistanceMatrix labels: #(''A'' ''B''). m at: 1 and: 2 put: 5. m between: ''B'' and: ''A''

It answers the questions you would ask of it:

| m | m := DistanceMatrix fromAlignment: Phylo exampleAlignment model: ''jc69''. m minimum
| m | m := DistanceMatrix fromAlignment: Phylo exampleAlignment model: ''jc69''. m maximum
| m | m := DistanceMatrix fromAlignment: Phylo exampleAlignment model: ''jc69''. m mean
| m | m := DistanceMatrix fromAlignment: Phylo exampleAlignment model: ''jc69''. m closestPair

and it reads and writes the square PHYLIP form, which is how you get a matrix
in or out of another program:

| m | m := DistanceMatrix labels: #(''alpha'' ''beta''). m at: 1 and: 2 put: 0.25. m asPhylip
| m | m := DistanceMatrix labels: #(''alpha'' ''beta''). m at: 1 and: 2 put: 0.25. (DistanceMatrix fromPhylip: m asPhylip) between: ''alpha'' and: ''beta'''!
neighbourJoining
	^TutorialLesson title: 'Neighbour joining' text:
'Neighbour joining is the method to reach for.  At each step it joins the pair
that makes the TOTAL branch length least -- which is not the same as the
closest pair -- and it does not assume that change happens at the same rate
everywhere.

| m | m := DistanceMatrix fromAlignment: Phylo exampleAlignment model: ''jc69''. m neighbourJoining asText
Phylo exampleAlignment neighbourJoining asNewick
Phylo nj: Phylo exampleAlignment

Its great property is that if the distances really do come from a tree, it
gives that tree back exactly.  Build a tree, read the distances back off it,
and compare:

| t m | t := Phylo exampleAlignment neighbourJoining. m := t distanceMatrix. m between: ''Human'' and: ''Gorilla''
| a | a := Phylo exampleAlignment. (a distanceMatrixUsing: ''jc69'') between: ''Human'' and: ''Gorilla''

Those two numbers are close but not equal, because real data is never exactly
additive.  On data that is, they agree to the last digit, which is what the
package''s tests check.

And the test that matters, on data whose answer we know:

(Phylo exampleAlignment neighbourJoiningUsing: ''jc69'') robinsonFouldsTo: Phylo exampleTree
(Phylo exampleAlignment neighbourJoiningUsing: ''k2p'') robinsonFouldsTo: Phylo exampleTree

One judgement call worth knowing about: the method can produce a negative
branch length, which means nothing biologically.  Those are flattened to zero
and the length given to the sister branch, as every other program does:

Phylo exampleAlignment neighbourJoining nodes detect: [:each | each hasBranchLength and: [each branchLength < 0]] ifNone: [''none'']'!
upgma
	^TutorialLesson title: 'UPGMA, and why not' text:
'The obvious method is to join the closest pair, over and over, and that is
UPGMA.  It is quick, it gives a rooted tree, and the tree is ULTRAMETRIC --
every leaf the same distance from the root:

Phylo exampleAlignment upgma asText
Phylo exampleAlignment upgma isRooted
Phylo exampleAlignment upgma isUltrametric
Phylo exampleAlignment neighbourJoining isUltrametric

That last line is the point.  Ultrametric means UPGMA has assumed a molecular
clock: that every lineage has changed at the same rate since they split.  When
that is true, UPGMA is right and gives you a rooted tree for nothing.  When it
is not, UPGMA is confidently wrong, and it will put two fast-changing
lineages together whether or not they are related.

See whether the two methods agree on this data:

| a | a := Phylo exampleAlignment. a neighbourJoining robinsonFouldsTo: a upgma

Neighbour joining is the safe default.  UPGMA is here because it is quick
enough to use as a guide tree for progressive alignment, which is exactly the
job it is good at, and because being able to compare the two tells you
something about your data.

WPGMA is the variant where the two clusters joined count equally whatever
their size:

| m | m := DistanceMatrix fromAlignment: Phylo exampleAlignment model: ''jc69''. m wpgma name
| m | m := DistanceMatrix fromAlignment: Phylo exampleAlignment model: ''jc69''. m upgma name'!
multipleAlignment
	^TutorialLesson title: 'Multiple alignment' text:
'Everything so far has assumed the sequences are already aligned: column 17 of
one answers to column 17 of the rest.  A MultipleAlignment is that.

| a | a := Phylo exampleAlignment. a size
| a | a := Phylo exampleAlignment. a length
| a | a := Phylo exampleAlignment. a labels
| a | a := Phylo exampleAlignment. a rowNamed: ''Human''

An alignment answers the things you want to know about a set of rows:

| a | a := Phylo exampleAlignment. a consensus
| a | a := Phylo exampleAlignment. a invariantColumns
| a | a := Phylo exampleAlignment. a meanIdentity
| a | a := Phylo exampleAlignment. a identityBetween: 1 and: 2
| a | a := Phylo exampleAlignment. (a columnsFrom: 1 to: 40) asText

If your sequences are NOT aligned, the progressive aligner will do it.  It
works in the three usual steps: see how far apart every pair is, build a guide
tree from that, then work up the guide tree aligning a profile against a
profile.

| r | r := Phylo exampleSequences. r size
| r a | r := Phylo exampleSequences. a := Phylo align: r. a size
| r a | r := Phylo exampleSequences. a := Phylo align: r. a length
| r a | r := Phylo exampleSequences. a := Phylo align: r. (a columnsFrom: 1 to: 40) asText

The first step counts short words rather than aligning every pair, which is
how the real aligners do it too: a guide tree only has to get the close pairs
together, and that is cheap to do approximately.

Be honest about what this is: a progressive aligner and nothing more.  There
is no iterative refinement, so a mistake made early stays in.  For a guide
tree or a quick look it is fine; for a publication it is not.'!
theBootstrap
	^TutorialLesson title: 'The bootstrap' text:
'A tree built from data always looks definite.  The bootstrap asks how much of
it the data actually supports.

The idea: draw as many columns as the alignment has, WITH REPLACEMENT, build a
tree from that, and do it again and again.  The share of those trees that hold
each branch of the real tree is that branch''s support.

This takes a moment, so these examples use the first 150 columns and a handful
of replicates.  Real work wants the whole alignment and a hundred or more.

| a b | a := Phylo exampleAlignment columnsFrom: 1 to: 150. b := Bootstrap on: a replicates: 10. b tree asText

Read the numbers in the drawing: they are percentages.  Ask for one directly:

| a b | a := Phylo exampleAlignment columnsFrom: 1 to: 150. b := Bootstrap on: a replicates: 10. b supportFor: #(''Baboon'' ''Macaque'')
| a b | a := Phylo exampleAlignment columnsFrom: 1 to: 150. b := Bootstrap on: a replicates: 10. b supportFor: #(''Human'' ''Chimpanzee'')

The deep splits of this data are strong and the Human-Chimpanzee one is not,
which is the honest answer: 300 simulated columns are not many.

A consensus tree keeps only the branches that turned up often enough and
leaves the rest unresolved:

| a b | a := Phylo exampleAlignment columnsFrom: 1 to: 150. b := Bootstrap on: a replicates: 10. b consensus asText
| a b | a := Phylo exampleAlignment columnsFrom: 1 to: 150. b := Bootstrap on: a replicates: 10. (b consensusAt: 90) splits size

The sampling is seeded, so the same alignment gives the same answer twice --
which a test needs, and so does anybody comparing two runs:

| a | a := Phylo exampleAlignment columnsFrom: 1 to: 100. (Bootstrap new alignment: a; replicates: 4; seed: 7; run) tree asNewick
| a | a := Phylo exampleAlignment columnsFrom: 1 to: 100. (Bootstrap new alignment: a; replicates: 4; seed: 7; run) tree asNewick

Support is not a probability that the branch is true.  It says how stable the
branch is against resampling the columns you happen to have, and no more.'!
theBrowser
	^TutorialLesson title: 'The tree browser' text:
'For looking at a tree rather than computing with it, there is a window.  Open
it from the System menu (right-click the desktop, then tree browser), or from
here:

Phylo openBrowserOn: Phylo exampleTree

The list on the left holds the clades, innermost last, and then the taxa.  The
right pane shows the drawing with what you selected described underneath, and
the menu on the right button changes what it shows: the drawing, a cladogram,
the Newick, a summary, or the patristic distances.  It will also ladderize,
re-root on the midpoint or on the selected taxon, and unroot.

The same things without a window:

TreeBrowser openOn: Phylo exampleTree
TreeBrowser listItems
TreeBrowser detailAt: 2
TreeBrowser commandLabels

Opening it on a tree you have just built is the quick way to see what you
have:

Phylo openBrowserOn: (Phylo exampleAlignment neighbourJoining)

and writing it out again, for the program that will draw it properly:

Phylo exampleTree asNewick'!
whatNext
	^TutorialLesson title: 'Where to go next' text:
'That is the package.  What to carry away:

Correct your distances; the raw count of differences is always too small.

Neighbour joining unless you have a reason; UPGMA assumes a clock.

A tree from distances is unrooted.  Rooting it is a separate decision and an
outgroup is the honest way to make it.

Resample before you believe a branch, and remember that the support measures
stability against resampling, not truth.

What is NOT here: maximum likelihood, parsimony, rate heterogeneity across
sites, base-frequency parameters, tree searching, and NEXUS files.  Every tree
in this package comes from a distance matrix.  For anything you intend to
publish, use this to get your bearings and a real program to get your answer.

The package README is packages/Phylo/README.md.  The classes are in the
categories beginning with Phylo, and the sequence objects underneath come from
the Bio package:

Smalltalk isPackageLoaded: ''Bio''
BioTutorial lessonCount

The example data and what it is:

Phylo examples

Other tutorials in this image:

Smalltalk tutorialNames

and the one for the language itself:

Smalltalk tutorial'! !
