# Phylo

Phylogenetics: distances between aligned sequences, trees built from them, Newick in and out, trees drawn
with characters, progressive multiple alignment, and the bootstrap.

```smalltalk
Smalltalk loadPackage: 'Phylo'
```

It loads the [Bio](../Bio/README.md) package, whose sequences, records and scoring matrices it uses.

## The shortest useful example

```smalltalk
| alignment tree |
alignment := Phylo readAlignment: 'globins.fasta'.   "an aligned FASTA file"
tree := alignment neighbourJoining.
Transcript showCr: tree asText.                      "a drawing"
Transcript showCr: tree asNewick.                    "((A:0.1,B:0.2):0.05,C:0.3);"
tree writeTo: 'globins.tree'
```

and, if the sequences are not aligned yet:

```smalltalk
| records |
records := (Bio readFasta: 'globins.fasta') records.
(Phylo align: records) neighbourJoining asText
```

## Trees

`PhyloTree` holds a root `PhyloNode`; a node knows its `label`, `branchLength`, `support`, `children` and
`parent`, and a node with no children is a leaf whose label is a taxon name.

```smalltalk
| t |
t := PhyloTree fromNewick: '((A:0.1,B:0.2)95:0.05,C:0.3,D:0.4);'.
t taxa                            "#('A' 'B' 'C' 'D') -- in order"
t size                            "4 taxa"
t isRooted                        "false: three branches at the root"
t isBinary                        "true"
t hasBranchLengths                "true"
t leafNamed: 'A'                  "a PhyloNode"
t distanceBetween: 'A' and: 'C'   "0.45, along the branches"
t mrcaOf: #('A' 'B')              "their most recent common ancestor"
t totalBranchLength
t height
t distanceMatrix                  "the patristic distances, as a DistanceMatrix"
```

Walking is by `preOrderDo:`, `postOrderDo:`, `leavesDo:`, `internalDo:` and `ancestorsDo:`, each of which has
a collecting form (`leaves`, `internalNodes`, `nodes`, `leafLabels`, `ancestors`).

Changing a tree happens in place, and each of these answers the tree so they can be strung together:

```smalltalk
t ladderize                             "smaller clade first everywhere, so it reads tidily"
t pruneTaxa: #('D')                     "take taxa out, tidying the branch lengths"
t keepTaxa: #('A' 'B')
t scaleBy: 100
t collapseBranchesShorterThan: 0.001    "leave a polytomy where the data says nothing"
t unroot                                "two branches at the root become three"
t rootOn: 'D'                           "D as the outgroup"
t rootOnAll: #('C' 'D')                 "a clade as the outgroup"
t rootOnMidpoint                        "halfway along the longest path, when there is no outgroup"
t copyTree                              "a tree of new nodes you can change freely"
```

## Comparing two trees

A tree's shape is its set of **splits**: each internal branch cuts the taxa in two. Writing each split as the
side that leaves out the first taxon alphabetically makes it independent of how the tree happens to be drawn
or rooted, so two trees can be compared directly.

```smalltalk
a := PhyloTree fromNewick: '((A,B),C,D);'.
b := PhyloTree fromNewick: '(D,C,(B,A));'.
a splits                      "Set (#('C' 'D'))"
a hasSameTopologyAs: b        "true -- the same tree written two ways"
a robinsonFouldsTo: b         "0; it counts the splits one has and the other has not, both ways"
```

## Distances

A model turns two aligned strings into a number. Only the columns where both have an unambiguous residue are
counted — pairwise deletion — so two sequences are compared over whatever they share.

| | |
|---|---|
| `p` | the plain proportion of differences |
| `jc69` | Jukes-Cantor: `-3/4 ln(1 - 4p/3)` |
| `k2p` | Kimura two-parameter, which counts transitions apart from transversions |
| `tn93` | Tamura-Nei with equal base frequencies |
| `poisson` | the Poisson correction, for protein |
| `kimura` | Kimura's protein correction, his quick stand-in for a PAM distance |

```smalltalk
JukesCantorModel new distanceBetween: 'ACGTACGT' and: 'ACGTACGA'
DistanceModel named: 'k2p'
DistanceModel names                "#('p' 'jc69' 'k2p' 'tn93' 'poisson' 'kimura')"
```

Where the correction has no answer — two sequences so far apart that the logarithm would be of something not
positive — the model answers its `maximumDistance` (10 by default) and remembers it in `sawSaturation`,
rather than failing in the middle of filling a matrix.

`DistanceMatrix` is a square symmetric table with a label per row:

```smalltalk
m := DistanceMatrix fromAlignment: anAlignment model: 'jc69'.
m between: 'Human' and: 'Gorilla'
m at: 1 and: 2
m closestPair                 "#(i j)"
m minimum. m maximum. m mean.
m withoutTaxon: 'Lemur'.  m keepTaxa: #('Human' 'Gorilla')
m asText                      "the lower triangle"
m asPhylip                    "the square form other programs read"
DistanceMatrix fromPhylip: aString
DistanceMatrix readFrom: 'distances.phy'
```

## Building a tree

```smalltalk
m neighbourJoining   "or m nj"
m upgma
m wpgma
```

**Neighbour joining** (Saitou and Nei 1987) makes an unrooted tree and does not assume the rate of change is
the same everywhere; it is what you want unless you have a reason to want the other. At each step it joins
the pair that makes the total branch length least — not simply the closest pair — which is why it gets an
additive matrix back exactly, as the tests check. A branch that comes out negative is flattened to zero and
its length given to its sister, as everybody does.

**UPGMA** clusters the closest pair over and over and makes a rooted, ultrametric tree. That is only right
when the rate of change really is the same everywhere, so it is here because it is quick, because a guide
tree for progressive alignment wants exactly that, and because it is worth being able to compare the two.
`wpgma` is the variant where the two clusters joined count equally whatever their size.

## Newick

```smalltalk
PhyloTree fromNewick: '((A:0.1,B:0.2)95:0.05,C:0.3);'
PhyloTree readFrom: 'tree.nwk'
NewickReader parseAll: aStringWithSeveralTrees
aTree asNewick
aTree asNewickWithoutLengths
aTree writeTo: 'tree.nwk'
NewickWriter new decimals: 3; support: false; write: aTree
```

A label may be quoted with single quotes, in which case a doubled quote stands for one; in an unquoted label
an underscore stands for a space, as the format says, and the writer puts the underscores back. Square
brackets hold a comment and are skipped. A number where an internal node's label would go is read as that
node's support, anything else as its label.

## Drawing

```smalltalk
aTree asText                              "a phylogram: the branch lengths set the widths"
TreeRenderer cladogram: aTree             "shape only"
TreeRenderer render: aTree width: 30
TreeRenderer new showSupport: false; labelWidth: 12; render: aTree
```

```
    /----- Human
   /|
   |\- Chimpanzee
   |
   |---- Gorilla
---|
   |      /------------ Orangutan
   |      |
   |      |                         /----- Baboon
   \---100|               /------100|
          |     /------100|         \----- Macaque
          |     |         |
          \----97|        \------------------ Marmoset
                |
                \------------------------------------- Lemur
```

Every leaf gets a row and every node a column; the uprights are drawn over the branches, so a junction reads
as a corner. A support value is written into the branch coming into its node when there is room for it. A
tree with no branch lengths is drawn as a cladogram rather than as a single vertical line.

## Multiple alignment

`MultipleAlignment` is a list of labels and a list of equally long gapped strings.

```smalltalk
a := MultipleAlignment readFasta: 'aligned.fasta'.
a size. a length.                   "rows and columns"
a rowNamed: 'Human'.  a columnAt: 17.
a consensus.  a consensusWithThreshold: 0.8.
a matchLine                         "* where every row agrees, : where most do"
a conservationAt: 17.  a invariantColumns.
a identityBetween: 1 and: 2.  a meanIdentity.
a gapCount.  a gapPercent.
a withoutGapColumns.  a withoutColumnsGappierThan: 0.5.  a columnsFrom: 20 to: 80.
a keepRows: #('Human' 'Gorilla').
a asFasta.  a writeTo: 'out.fasta'.  a asText.  a report.
a distanceMatrix.  a neighbourJoining.  a upgma.  a bootstrap: 100.
```

`ProgressiveAligner` aligns sequences that are not aligned yet, in the three usual steps: see how far apart
every pair is, build a guide tree from that, then work up the guide tree aligning a profile against a
profile.

```smalltalk
Phylo align: someRecords                 "SeqRecords, BioSequences or plain Strings"
ProgressiveAligner protein align: ...
ProgressiveAligner new matrix: ScoringMatrix blosum62; gapOpen: 11; gapExtend: 1; align: ...
aligner guideTree                        "the tree it went up"
```

The first step counts short words (4 letters for nucleotides, 3 for protein) rather than aligning every
pair: a guide tree only has to put the close pairs together first, and counting words does that in a
fraction of the time — which is how the real aligners do it too. The profile step is Needleman-Wunsch with
affine gaps over columns rather than residues, scoring a pair of columns by the average of the substitution
scores over the residues in them. It works in thousandths of a score so that the table holds whole numbers
and no Floats are made inside the inner loop. Two profiles longer than about a thousand columns each are
refused rather than filling memory.

This is a progressive aligner and nothing more: there is no iterative refinement and no consistency scoring,
so a mistake made early stays in. For a guide tree, a quick look, or sequences that are not too far apart it
is fine; for a publication it is not.

## The bootstrap

```smalltalk
b := Bootstrap on: anAlignment replicates: 100.
b tree                          "the tree from the real data, with support on every branch"
b supportFor: #('Human' 'Chimpanzee')
b splitsAbove: 70
b consensus                     "the majority-rule consensus of the replicates"
b consensusAt: 70
b report
Bootstrap new alignment: a; replicates: 500; model: 'k2p'; builder: #upgma; seed: 99; run
```

Each replicate draws as many columns as the alignment has, with replacement, and builds a tree; the share of
replicates that hold each branch of the real tree becomes that branch's support. The consensus starts from a
star tree and adds the well-enough supported splits back, best first, skipping any that will not fit with
the ones already in.

The sampling uses a `Random` the Bootstrap holds, seeded at 42 unless you say otherwise, so the same
alignment gives the same answer twice.

## The browser

**System menu → tree browser** opens a tree in a window: the clades and the taxa on the left, and on the
right the drawing, the Newick, a summary, or the patristic distances. The menu ladderizes, re-roots on the
midpoint or on the selected taxon, unroots, and opens another Newick file.

```smalltalk
Phylo openBrowserOn: aTree
```

## The example data

`data/` holds eight sequences of 300 columns simulated along a known tree under Jukes-Cantor, the tree they
were simulated along, and six of the same sequences with indels put into them to be aligned. Simulated data
is used on purpose: it lets the tests ask a tree builder the only question that really matters, which is
whether it gets the right tree back.

```smalltalk
Phylo exampleAlignment            "the 8 x 300 alignment"
Phylo exampleTree                 "the tree it was made along"
Phylo exampleSequences            "the six unaligned ones"
Phylo examples                    "what is in data/, and what each file is"

(Phylo exampleAlignment neighbourJoining) robinsonFouldsTo: Phylo exampleTree    "0"
```

## What it does not do

No maximum likelihood and no parsimony: every tree here comes from a distance matrix. No rate heterogeneity
(no gamma), no base-frequency parameters, so the models are the equal-frequency forms. No tree searching, no
rooting by a molecular clock, and no NEXUS or PHYLIP sequence formats — FASTA in, Newick out.

## Notes

* 108 SUnit tests in `tests.st`, plus 143 checks in `tests/tests.txt` that `make check` runs.
* `PhyloError` is the error this package signals; it is a subclass of `Error`.
