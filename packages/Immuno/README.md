# Immuno

Computational immunology, with the MHC at its centre: the question of which peptides a person's HLA molecules can show to their T cells. It is an optional package:

```smalltalk
Smalltalk loadPackage: 'Immuno'         "or: st -l Immuno, or System menu → load package..."
ImmunoTutorial go                       "the 18-lesson tutorial"
```

> **These are teaching models.** The binding models are written down from the published anchor preferences of each molecule; they are not trained on the large measured data sets that real predictors use. They find the anchor motif and let every step of the pipeline be read and changed, but they miss what depends on the middle of a peptide, say nothing about affinity in nanomolar, and are not for research or clinical decisions. Use NetMHCpan, NetMHCIIpan or MHCflurry for that. The example sequences, epitopes and allele frequencies were typed in as examples; check them against UniProt, the IEDB, IPD-IMGT/HLA and allelefrequencies.net before relying on them.

## Predicting binding

```smalltalk
Immuno predict: 'GILGFVFTL' for: 'HLA-A*02:01'     "GILGFVFTL / HLA-A*02:01  score 5.1  rank 2.99%  weak"
p := Immuno predict: 'NLVPMVATV' for: 'A*02:01'.
p score. p rank. p category. p isStrong. p core     "6.0  0.67  #strong  true  'NLVPMVATV'"
Immuno predict: 'GILGFVFTL' forAll: #('A*02:01' 'B*07:02')    "one prediction per allele, best first"
```

A model is a position-specific scoring matrix: nine columns by twenty residues of log2 odds in tenths of a bit. The **score** is the sum of one cell per position. The **rank** is the percentage of random peptides (drawn with the composition of ordinary proteins) that would score at least as well, worked out exactly rather than by sampling, so it means the same thing for every allele. For these motif models a rank of 1 or less is *strong* and 5 or less *weak* (class II: 2 and 10).

Class I peptides of 8 to 11 residues are scored by leaving a gap in, or deleting residues from, the middle of the nine columns and keeping the best fit (half a bit off for each residue away from nine). Class II peptides of 9 to 30 residues are scored by sliding the nine-residue core along them, with the rank corrected for having several windows to choose from.

`AlleleModels alleles` lists the twenty alleles with a model: A\*01:01, A\*02:01, A\*03:01, A\*11:01, A\*24:02, B\*07:02, B\*08:01, B\*15:01, B\*27:05, B\*35:01, B\*40:01, B\*44:02, B\*51:01, B\*57:01, B\*58:01 and the class II DRB1\*01:01, \*03:01, \*04:01, \*07:01, \*15:01 (the class II ones are sketches of the P1, P4, P6 and P9 pockets). Any name at two or more fields is accepted: `'HLA-A*02:01:01:01'` finds the A\*02:01 model.

## Your own models

```smalltalk
m := BindingMatrix fromMotif: #(#(2 'W' 10) #(9 'K' 10)) name: 'HLA-X*01:01' class: 1.   "rows of #(position residues enrichment)"
m := BindingMatrix trainOn: (Immuno epitopesFor: 'A*02:01') name: 'HLA-A*02:01' class: 1. "log odds with pseudo-counts and Henikoff weights"
AlleleModels add: m.            "now every call that takes 'A*02:01' uses it"
AlleleModels removeAdded.
m motifString. m anchors. m cellAt: 2 residue: $L. m topResidues: 3 at: 9
m aucFor: someBinders against: someNonBinders       "area under the ROC curve"
Immuno evaluate: 'A*02:01'                           "AUC on the known epitopes against 200 random nine-mers"
```

## Scanning proteins

```smalltalk
m1 := Immuno exampleProtein: #influenzaM1.           "also #ubiquitin, #beta2microglobulin"
r := Immuno scan: m1 for: 'A*02:01'.                 "every 8-11-mer (class II: every 15-mer), scored"
r report. r binders. r strongBinders. r best: 5. r atLength: 9. r forAllele: 'A*02:01'
r regions. r coverage                                "stretches covered by overlapping binders, and their fraction"
r presentation                                       "peptide -> the alleles that present it"
Immuno scan: m1 forAll: #('A*02:01' 'B*07:02' 'DRB1*01:01')
Immuno scan: m1 genotype: (Immuno genotype: 'A*02:01 A*24:02 B*07:02 B*07:02')
```

A window containing a character that is not an amino acid is skipped. Scans are a `ScanResult`; each prediction in it knows its `position` and `endPosition`.

## Antigen processing, self and non-self

```smalltalk
AntigenProcessing cleavageProfile: m1               "proteasome score for cutting after each residue, in bits"
AntigenProcessing transportScore: 'GILGFVFTL'       "TAP, from the C-terminus"
AntigenProcessing processingScoreOf: 'GILGFVFTL' at: 58 in: m1
AntigenProcessing rank: r                           "a scan ranked by binding plus processing"

s := SelfProteome withProteins: (Array with: (Immuno exampleProtein: #ubiquitin)).
s includes: 'KTLTGKTIT'. s nearest: 'KTLAGKTIT'. s mismatchesToNearest: 'KTLAGKTIT'
(Peptide on: 'GILGFVFTL') similarityTo: (Peptide on: 'GILGFVFTI')      "BLOSUM62, for cross-reactivity"
```

## Peptides and HLA names

```smalltalk
p := Peptide on: 'GILGFVFTL'.        "or 'GILGFVFTL' asPeptide; case and spaces ignored, anything else an ImmunoError"
p mass. p hydropathy. p netCharge. p kmers: 8. p hammingTo: q. p similarityTo: q. p shuffledUsing: (ImmunoRandom seed: 1)
a := 'HLA-A*02:01:01:01' asHLA.      "gene, up to four fields, an optional suffix such as N or L"
a gene. a fields. a nameAt: 2. a group. a supertype. a mhcClass. a isClassI. a isNull
a includes: 'A*02:01' asHLA          "A*02 includes A*02:01:01"
a matches: b atResolution: 2
HLAAllele inSupertype: 'B58'
```

Supertypes are those of Sette and Sidney (A1, A2, A3, A24, B7, B27, B44, B58, B62); an allele outside them (B\*08:01, say) answers nil.

## Populations and matching

```smalltalk
f := AlleleFrequencies example.       "ILLUSTRATIVE frequencies for A, B and DRB1 - use a real database for real work"
f frequencyOf: 'A*02:01'. f carrierFrequency: 'A*02:01'. f expectedHeterozygosity: 'A'
f coverageOf: #('A*02:01' 'B*07:02')                         "fraction of people with at least one"
f coverageOf: someAlleles atLeast: 3                         "...with at least three hits"
f hitDistributionOf: someAlleles. f bestAlleles: 4 from: candidates
Immuno selectEpitopes: 4 from: r population: f               "greedy: each peptide adds the most coverage"

AlleleFrequencies hardyWeinbergTest: #(#('A*02:01' 'A*02:01') #('A*02:01' 'A*01:01') ...)    "chi-square, df, p"
ld := LinkageDisequilibrium pA: 0.2 pB: 0.3 pAB: 0.15.  ld d. ld dPrime. ld rSquared. ld pValue: 500
ImmunoMath chiSquareSurvival: 3.84 df: 1

a := Immuno genotype: 'A*01:01 A*02:01 B*08:01 B*57:01 C*07:01 C*06:02 DRB1*03:01 DRB1*07:01 DQB1*02:01 DQB1*03:03'.
m := HLAMatch recipient: a donor: b.            "10 alleles at two fields"
m grade. m hostVersusGraft. m graftVersusHost. m report
f matchProbability: a loci: #('A' 'B')          "chance a random person is a full match; loci taken as independent"
```

Coverage and match probability assume Hardy-Weinberg proportions and independent loci, both approximations (HLA loci are in strong linkage disequilibrium).

## The workspace

*System menu → immuno workspace*, or `ImmunoTool open`. A line with a `*` in it names alleles; every other line is a sequence: a short one is scored against each allele, a long one is scanned. `ImmunoTool evaluate: aString` does the same without a window.

## Files

`peptide.st` amino acids, BLOSUM62, peptides, a repeatable random number generator · `allele.st` HLA names and supertypes · `matrix.st` the binding matrix, ranks, training, predictions · `models.st` the twenty built-in models · `scan.st` scanning · `processing.st` cleavage and TAP · `population.st` frequencies, coverage, Hardy-Weinberg, linkage · `matching.st` genotypes and donor matching · `facade.st` the `Immuno` front door, the epitope list, example proteins, the self proteome and the workspace · `tutorial.st` · `tests/tests.txt`.
