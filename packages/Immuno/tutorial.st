"The Immuno tutorial: peptides and HLA names, the binding model and what a rank is, scanning proteins, building and
testing a model, antigen processing, a person's genotype, populations, matching and choosing epitopes.  The examples are
live; start it with   ImmunoTutorial go"

AbstractTutorial subclass: #ImmunoTutorial instanceVariableNames: '' classVariableNames: '' category: 'Immuno'!

!ImmunoTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Immuno'!
lessonSelectors
	^#(#welcome #peptides #names #groove #scoring
		#lengths #scanning #classII #building #testing
		#processing #self #genotypes #populations #hardy
		#matching #vaccine #whatnext)! !

!ImmunoTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'This package is about one question: given a peptide and a person, will the person''s MHC molecules show that peptide to their T cells?

Everything the immune system does with a virus begins there.  Cells chop up the proteins they make, load some of the pieces onto MHC molecules (called HLA in humans), and carry them to the surface.  A T cell that recognises a piece as foreign attacks the cell.  So the peptides a person can present, which depends on the HLA alleles they carry, decide what they can respond to.  This is why vaccines are designed against a population''s alleles, why transplant donors are matched by HLA type, and why some people control HIV and others do not.

Everything here is live.  Select a line and press ctrl-P (print it) to run it.

One peptide, one allele: the influenza matrix epitope that everyone starts with, against the commonest class I allele in Europeans:

Immuno predict: ''GILGFVFTL'' for: ''HLA-A*02:01''

Three numbers matter in the answer.  The score is in bits, the sum of how well each residue fits its pocket in the groove.  The rank is the percentage of random peptides that would score at least as well, which is the figure to compare across alleles.  The verdict is a rank cut-off: strong, weak, or nonbinder.

An important caution before anything else.  The binding models in this package are TEACHING MODELS, written down from the published anchor preferences of each molecule; they are not trained on thousands of measurements the way NetMHCpan or MHCflurry are.  They find the anchor motif, which is most of what a beginner needs to see, and they let every step of the pipeline be read and changed in a few lines.  They will miss what depends on the middle of the peptide, they say nothing about nanomolar affinity, and they are not for research or clinical decisions.  The last lesson says where to go for that.

What the package covers, in order: peptides and HLA names; the binding model and what a rank is; peptides of other lengths and class II; scanning a whole protein; building and testing your own model; antigen processing; self and non-self; a person''s genotype; allele frequencies in populations, Hardy-Weinberg and linkage; donor matching; and choosing epitopes for a vaccine.

What comes with it:

Immuno examples'!
peptides
	^TutorialLesson title: 'Peptides and residues' text:
'A peptide is a string of amino acids.  Peptide checks what you give it, ignores case and spaces, and knows some physical facts:

(Peptide on: ''GILGFVFTL'') mass
(Peptide on: ''GILGFVFTL'') hydropathy
(Peptide on: ''GILGFVFTL'') netCharge
''gilgfvftl'' asPeptide

The mass is the neutral monoisotopic mass in daltons, the number a mass spectrometer reports when it identifies peptides eluted from MHC molecules.  Hydropathy is the mean Kyte-Doolittle value: positive is hydrophobic, and MHC-bound peptides tend to be, especially at the anchors.  The net charge counts K and R as plus one and D and E as minus one.

The standard twenty residues come in BLOSUM order, which every table in the package uses:

AminoAcid order
AminoAcid nameOf: $W
AminoAcid massOf: $G
AminoAcid backgroundOf: $L

The background is how often each residue turns up in proteins generally.  It matters because a binding model asks not ''is there an L here'' but ''is there more L here than chance would put there''.

Anything that is not an amino acid is an error, with a message you can catch:

[Peptide on: ''GILGFVFTB''] on: ImmunoError do: [:e | e messageText]

Peptides get cut into overlapping pieces, which is how a protein is scanned:

(Peptide on: ''GILGFVFTL'') kmers: 8
(Peptide on: ''GILGFVFTL'') kmers: 7

And compared.  How alike two peptides are is the question behind cross-reactivity, where a T cell trained on one peptide also responds to another.  Hamming distance counts the positions that differ.  The BLOSUM62 similarity scores each position by how acceptable the swap is in evolution, so a conservative change costs little:

(Peptide on: ''GILGFVFTL'') hammingTo: (Peptide on: ''GILGFVFTI'')
(Peptide on: ''GILGFVFTL'') similarityTo: (Peptide on: ''GILGFVFTI'')
(Peptide on: ''GILGFVFTL'') similarityTo: (Peptide on: ''GILGFVFTD'')
(Peptide on: ''GILGFVFTL'') normalizedSimilarityTo: (Peptide on: ''GILGFVFTI'')

Leucine to isoleucine is nearly free; leucine to aspartate is not.  The normalised form divides by the best possible, so identical peptides score 1.'!
names
	^TutorialLesson title: 'HLA allele names' text:
'HLA genes are the most variable in the human genome, and the variation is catalogued in a naming scheme.  An allele name is the gene, a star, and up to four colon-separated fields of increasing resolution:

''HLA-A*02:01:01:01'' asHLA
''HLA-A*02:01:01:01'' asHLA gene
''HLA-A*02:01:01:01'' asHLA fields

The first field is the allele group, the second names the protein (two alleles that differ here differ in amino acid sequence, and so in the peptides they bind), the third is a change in the coding sequence that does not alter the protein, and the fourth a change outside it.  A suffix letter marks expression: N means the allele is not expressed at all.

''A*02:15N'' asHLA isNull
''HLA-A*02:01:01:02L'' asHLA suffix

Most work is done at two fields, because that is the protein.  A name can be cut to any resolution, and two names compared at any resolution:

''HLA-A*02:01:01:01'' asHLA nameAt: 2
''HLA-A*02:01:01:01'' asHLA group
''A*02:01'' asHLA includes: ''A*02:01:01:01'' asHLA
''A*02'' asHLA includes: ''A*02:01:01:01'' asHLA
''A*02:01:01:01'' asHLA matches: ''A*02:01:02'' asHLA atResolution: 2
''A*02:01:01:01'' asHLA matches: ''A*02:01:02'' asHLA atResolution: 3

Which class an allele belongs to follows from its gene.  Class I (A, B, C and the non-classical E, F, G) presents peptides made inside the cell to CD8 T cells; class II (DR, DQ, DP) presents peptides taken up from outside to CD4 T cells.

''A*02:01'' asHLA mhcClass
''DRB1*15:01'' asHLA mhcClass
''DRB1*15:01'' asHLA isClassII

Alleles with similar grooves bind similar peptides, and the class I ones are grouped into supertypes.  A2 is the group around A*02:01; B7 groups B*07:02 with B*35:01 and B*51:01.  Not every allele has one:

''A*02:01'' asHLA supertype
''A*24:02'' asHLA supertype
''B*08:01'' asHLA supertype
HLAAllele inSupertype: ''B58''
HLAAllele supertypeNames

Bad names are caught with a clear message:

[HLAAllele named: ''not an allele''] on: ImmunoError do: [:e | e messageText]'!
groove
	^TutorialLesson title: 'The groove and its anchors' text:
'A class I molecule holds a peptide in a groove closed at both ends, which fixes its length at about nine residues.  Its pockets take certain side chains: the second residue of the peptide (P2) goes into the B pocket, the last (P9, or P-omega) goes into the F pocket, and the ones in between mostly bulge out toward the T cell.  Each allele has pockets of a different shape, so a different pair of anchor preferences: HLA-A*02:01 wants a leucine or methionine at P2 and a valine or leucine at P9; HLA-B*07:02 wants a proline at P2; HLA-B*27:05 wants an arginine.

The model of an allele is a table, one column per position and one row per residue, of how much more likely a residue is at that position among binders than in an ordinary protein, as a log2 score in bits.  A matrix:

AlleleModels alleles
AlleleModels matrixFor: ''A*02:01''
(AlleleModels matrixFor: ''A*02:01'') motifString
(AlleleModels matrixFor: ''B*07:02'') motifString
(AlleleModels matrixFor: ''B*27:05'') motifString

Only the positions that matter show a list of residues; the rest say ''any''.  The range is the best cell minus the worst, so it measures how demanding the position is.  The anchors are the positions with a range of two bits or more:

(AlleleModels matrixFor: ''A*02:01'') anchors
(AlleleModels matrixFor: ''B*08:01'') anchors

HLA-B*08:01 is different from the others: it anchors P3 and P5 (lysine or arginine) as well as P9, which is what makes it one of the few alleles outside any supertype.

One cell, in bits.  A leucine at P2 scores three bits, an eightfold enrichment; a lysine there loses more than two:

(AlleleModels matrixFor: ''A*02:01'') cellAt: 2 residue: $L
(AlleleModels matrixFor: ''A*02:01'') cellAt: 2 residue: $K
(AlleleModels matrixFor: ''A*02:01'') topResidues: 5 at: 9

The best score a peptide can get, which is every position at its best cell:

(AlleleModels matrixFor: ''A*02:01'') maxScore
(AlleleModels matrixFor: ''A*02:01'') minScore

The class II groove is open at both ends and holds a longer peptide with a nine-residue core at the centre; the pockets that matter are P1, P4, P6 and P9.  Those models are in the table too:

(AlleleModels matrixFor: ''DRB1*01:01'') motifString'!
scoring
	^TutorialLesson title: 'Scoring a peptide and what a rank is' text:
'To score a peptide is to add one cell of the matrix per position.  The answer is a prediction:

| p | p := Immuno predict: ''NLVPMVATV'' for: ''A*02:01''. Array with: p score with: p rank with: p category
Immuno predict: ''NLVPMVATV'' for: ''A*02:01''
(Immuno predict: ''NLVPMVATV'' for: ''A*02:01'') core
(Immuno predict: ''NLVPMVATV'' for: ''A*02:01'') isStrong

The score cannot be compared between alleles, because one matrix is more demanding than another, and a score of five means different things.  So the figure that is compared is the rank: the percentage of random peptides, drawn from the composition of ordinary proteins, that would score at least as well.  Small is good.  For these models a rank of 1 or less is called strong and 5 or less weak:

(Immuno predict: ''KKKKKKKKK'' for: ''A*02:01'') category
(Immuno predict: ''KKKKKKKKK'' for: ''A*02:01'') rank
(Immuno predict: ''NLVPMVATV'' for: ''A*02:01'') rank

The same peptide against several alleles, best first:

Immuno predict: ''GILGFVFTL'' forAll: #(''A*02:01'' ''A*24:02'' ''B*07:02'' ''B*27:05'')
Immuno predict: ''RPQVPLRPM'' forAll: #(''A*02:01'' ''A*24:02'' ''B*07:02'' ''B*27:05'')

GILGFVFTL is an A2 peptide and RPQVPLRPM, from HIV Nef, a B7 one.  Neither fits the other molecule: this is what it means to say that MHC restriction decides what a person can respond to.

Where does the rank come from.  It is not estimated by sampling: the distribution of scores of random nine-mers is worked out exactly by adding the columns one at a time, each residue weighted by the background.  Here it is checked against sampling.  The first line asks for the rank of a score of 5.5 and multiplies by 50, which is how many peptides in 5000 should reach it; the second counts them in 5000 random peptides:

| m | m := AlleleModels matrixFor: ''A*02:01''. (m rankOfScore: 5.5) * 50
| m | m := AlleleModels matrixFor: ''A*02:01''. ((Immuno randomPeptides: 5000 length: 9 seed: 5) select: [:p | (m predict: p) score >= 5.5]) size

The two agree to within the noise of sampling.  Why a rank and not just a threshold on the score: a rank means the same thing for every allele and every length, and it puts a number on how surprising a match is.  The best nine-mer for HLA-A*02:01 still has a rank above half a percent, because even a perfect fit to the two anchors is shared by about one random peptide in a hundred.  The motif is a filter, not an oracle.

A rank also says nothing about whether a peptide is made, carried and presented: that is the processing lesson, and a rank of 1 for a peptide that is never produced is a false positive.'!
lengths
	^TutorialLesson title: 'Peptides of other lengths' text:
'Nine is the commonest length but not the only one: class I molecules also hold eights, tens and elevens, which bulge or lie in the groove with the middle residues arching out.  The nine-column matrix handles them by changing the peptide: an eight-mer gets a gap in one of the middle columns, and a ten or an eleven has a middle residue (or two) deleted.  Every way of doing it is tried and the best one kept, with a penalty of half a bit for each residue away from nine:

Immuno predict: ''GILGFVFTL'' for: ''A*02:01''
Immuno predict: ''ILGFVFTL'' for: ''A*02:01''
Immuno predict: ''GILGFVFTLT'' for: ''A*02:01''
Immuno predict: ''GILGFVFTLTV'' for: ''A*02:01''

The core in the answer is the nine columns that were scored, with a dash where there is a gap:

(Immuno predict: ''ILGFVFTL'' for: ''A*02:01'') core
(Immuno predict: ''GILGFVFTLT'' for: ''A*02:01'') core

Lengths outside eight to eleven are not scored, and say so:

[Immuno predict: ''GILG'' for: ''A*02:01''] on: ImmunoError do: [:e | e messageText]

A known epitope of ten and one of eleven, from HIV and EBV, against their alleles:

Immuno predict: ''TSTLQEQIGW'' for: ''B*57:01''
Immuno predict: ''HPVGEADYFEY'' for: ''B*35:01''

The ranks of the non-nine lengths are read off the nine-mer distribution, which is an approximation; trained predictors build a separate distribution for each length.'!
scanning
	^TutorialLesson title: 'Scanning a protein' text:
'A protein is cut into every window of the lengths the groove takes and each is scored.  Matrix protein 1 of influenza A is the example, because it contains the most famous epitope there is:

| p | p := Immuno exampleProtein: #influenzaM1. p size
(Immuno exampleProtein: #influenzaM1) indexOfSubCollection: ''GILGFVFTL''
| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''A*02:01''. r
| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''A*02:01''. r report

The report lists the best windows with their start position, score and rank.  A scan is a ScanResult, which answers the questions you would ask next:

| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''A*02:01''. r binders size
| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''A*02:01''. r strongBinders size
| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''A*02:01''. (r atLength: 9) size
| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''A*02:01''. (r best: 3) collect: [:p | p peptide asString]
| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''A*02:01''. r regions

Regions are the stretches covered by overlapping binders, each as its start, end and the number of binding windows in it, and coverage is the fraction of the protein inside any of them:

| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''A*02:01''. r coverage

Is the known epitope found.  Look it up among all the windows at its position:

| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''A*02:01''. (r select: [:p | p position = 58 and: [p peptide size = 9]]) predictions

A binder is not an epitope.  Of the many windows a protein offers, perhaps one in thirty binds a given allele, and only a few of those are made by the proteasome, carried by TAP, and recognised by a T cell in the repertoire.  The processing lesson deals with the first two.

Several alleles at once:

| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) forAll: #(''A*02:01'' ''A*01:01'' ''B*07:02'' ''A*03:01''). r
| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) forAll: #(''A*02:01'' ''A*01:01'' ''B*07:02'' ''A*03:01''). r coverage

A window containing a character that is not an amino acid (an X, a stop, a gap) is skipped, so a protein translated with ambiguity codes in it is still scanned.'!
classII
	^TutorialLesson title: 'Class II: the open groove' text:
'The class II groove is open at both ends, so the peptide hangs out of it and can be much longer than nine; what sits in the groove is a nine-residue core, with pockets P1, P4, P6 and P9.  To score a class II peptide, every nine-residue window is scored and the best kept; the core is the one that won.

Influenza haemagglutinin 306-318 is the classic DR1 peptide:

Immuno predict: ''PKYVKQNTLKLAT'' for: ''DRB1*01:01''
(Immuno predict: ''PKYVKQNTLKLAT'' for: ''DRB1*01:01'') core

Its core begins at the tyrosine, which is DR1''s favourite P1 residue.  Trim two residues off the ends and the core, and so the score, stay the same, but the rank improves:

Immuno predict: ''KYVKQNTLKLA'' for: ''DRB1*01:01''

That is the correction for choosing the best of several windows.  A long peptide has several chances to contain a good core, so the rank has to allow for them: it is the chance that at least one window does as well, worked out from the chance for a single window.  The 13-mer has five windows and the 11-mer three, and the cut-offs for class II are 2 and 10 percent.

Against two other DR alleles the model finds a poor fit:

Immuno predict: ''PKYVKQNTLKLAT'' for: ''DRB1*07:01''
Immuno predict: ''PKYVKQNTLKLAT'' for: ''DRB1*15:01''

HA 306-318 is usually described as a promiscuous binder, so these low ranks are a sign of how rough the class II sketches are.

Scanning for class II uses 15-mers, the usual length of the overlapping peptides used to test T cell responses:

| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''DRB1*01:01''. r
| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''DRB1*01:01''. r report
| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''DRB1*01:01''. r regions

Because the windows overlap by fourteen, the class II hits come in long runs.  These class II models are sketches of the P1, P4, P6 and P9 pockets, and weaker than the class I ones; class II binding is less well understood, the peptide is less constrained, and real predictors are much less accurate for it.'!
building
	^TutorialLesson title: 'Building your own model' text:
'Any model of the groove is a list of rows, each a position, some residues and an enrichment: how many times more likely those residues are at that position among binders than in ordinary protein.  An enrichment of eight is three bits; of a half, minus one.  This is the format the package models are written in, and writing your own takes one line.

Here is a made-up allele that needs a tryptophan at P2 and a lysine at P9, and hates a proline anywhere in the middle:

| m | m := BindingMatrix fromMotif: #(#(2 ''W'' 10) #(9 ''K'' 10) #(3 ''P'' 0.2) #(4 ''P'' 0.2) #(5 ''P'' 0.2) #(6 ''P'' 0.2) #(7 ''P'' 0.2)) name: ''HLA-X*01:01'' class: 1. m motifString
| m | m := BindingMatrix fromMotif: #(#(2 ''W'' 10) #(9 ''K'' 10)) name: ''HLA-X*01:01'' class: 1. (m predict: ''AWAAAAAAK'') score
| m | m := BindingMatrix fromMotif: #(#(2 ''W'' 10) #(9 ''K'' 10)) name: ''HLA-X*01:01'' class: 1. (m predict: ''AWAAAAAAK'') rank

With real binders instead of an idea of what they should look like, the model can be learned.  A matrix is trained by counting the residues at each position among the nine-mers, taking the log odds against the background, with pseudo-counts so that a residue that happens not to be in the list is not ruled out for ever, and weights so that a cluster of near-identical peptides counts as one.  Here is one made from the HIV and EBV epitopes of HLA-B*07:02 that this package knows, plus two more:

Immuno epitopesFor: ''B*07:02''
| m | m := BindingMatrix trainOn: (Immuno epitopesFor: ''B*07:02''), #(''RPHERNGFT'' ''LPRRSGAAG'') name: ''HLA-B*07:02'' class: 1. m
| m | m := BindingMatrix trainOn: (Immuno epitopesFor: ''B*07:02''), #(''RPHERNGFT'' ''LPRRSGAAG'') name: ''HLA-B*07:02'' class: 1. m anchors

Only nine-mers are used for training; a ten-mer in the list is left out.  With a handful of peptides the matrix is noisy: look how many positions come out looking like anchors, in an order that means nothing.  A larger pseudo-count shrinks every column toward the background, so the noise goes, and some of the signal with it:

| m | m := BindingMatrix trainOn: (Immuno epitopesFor: ''B*07:02'') name: ''x'' class: 1 pseudocount: 20. m anchors

A trained matrix can be registered under an allele name, and then every function that takes an allele uses it in place of the built-in one:

| m | m := BindingMatrix trainOn: (Immuno epitopesFor: ''A*02:01'') name: ''HLA-A*02:01'' class: 1. AlleleModels add: m. (AlleleModels matrixFor: ''A*02:01'') source
AlleleModels removeAdded. (AlleleModels matrixFor: ''A*02:01'') source

The second line removes it again, and the built-in model is back.'!
testing
	^TutorialLesson title: 'Does it work' text:
'A model that has not been tested is a guess.  The standard test is the area under the ROC curve (AUC): take a set of true binders and a set of non-binders and ask how often a binder, picked at random, outscores a non-binder.  An AUC of 1 means every time, 0.5 means no better than a coin.

The built-in models are tested against the known epitopes in the package, with 200 random nine-mers as the non-binders:

Immuno evaluate: ''A*02:01''
Immuno evaluate: ''B*07:02''
Immuno evaluate: ''A*24:02''

Look at these numbers sceptically.  The models were written from the very motifs that these epitopes are the textbook examples of, so a high AUC is no surprise, and random peptides are an easy negative class: most of them have no anchors at all.  A harder test uses decoys that keep the amino acid composition of the real peptides, which is what shuffling does, and decoys that share the anchors but differ in the middle:

Immuno decoysFor: (Immuno epitopesFor: ''A*02:01'') seed: 3

A model trained on a few examples has more to prove.  Train on half of the known A2 epitopes and test on the other half, always testing on peptides the model has not seen:

| known train test m dec | known := (Immuno epitopesFor: ''A*02:01'') select: [:p | p size = 9]. train := known copyFrom: 1 to: 6. test := known copyFrom: 7 to: known size. m := BindingMatrix trainOn: train name: ''x'' class: 1. dec := Immuno randomPeptides: 200 length: 9 seed: 3. Array with: (m aucFor: train against: dec) with: (m aucFor: test against: dec)

The first number is the AUC on the peptides the model was trained on; the second is on peptides it has not seen.  The first is higher, because the model has memorised its training peptides: it is the second that says how well it will do on new ones.  When the two are far apart, the model has more parameters than the data can support: a nine-column, twenty-row matrix has 180 numbers.

What the AUC does not tell you is whether the rank is calibrated: whether a peptide with a rank of one percent has a hundred-to-one chance of being a binder.  It also does not tell you about other lengths, other alleles, or about presentation.  The proper test of a binding predictor is on measured peptides from an independent source, such as the IEDB, which is where its builders test theirs.'!
processing
	^TutorialLesson title: 'Antigen processing' text:
'A peptide has to be made before it can bind.  The proteasome cuts proteins into pieces; TAP carries them into the endoplasmic reticulum; and only then are they offered to class I.  A peptide that would bind perfectly but is never made, or is cut in half on the way, is never presented.

Two crude rules capture most of the known preferences.  The proteasome cuts after large hydrophobic residues, and less after basic ones, and not in front of a proline.  TAP prefers a peptide that ends in a hydrophobic or basic residue and refuses one ending in proline, aspartate or glutamate.  Both are in bits, so they can be added to a binding score:

AntigenProcessing cleavageProfile: ''AALPLKFGD''
AntigenProcessing cleavageSites: (Immuno exampleProtein: #influenzaM1)
AntigenProcessing transportScore: ''GILGFVFTL''
AntigenProcessing transportScore: ''GILGFVFTD''

The cleavage profile is the score for cutting after each residue; the last residue is a free cut.  The score for a peptide in place combines the cut that frees its C-terminus, the transport score, and a small penalty for each strong site inside the peptide (an internal cut destroys it):

AntigenProcessing processingScoreOf: ''GILGFVFTL'' at: 58 in: (Immuno exampleProtein: #influenzaM1)

Adding it to the binding score gives a presentation score, and ranking a scan by it puts the binders that are likely to be made above the ones that fit the groove but would never get there:

| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) for: ''A*02:01''. ((AntigenProcessing rank: r) copyFrom: 1 to: 4) collect: [:row | Array with: (row at: 1) peptide asString with: (row at: 1) position with: (((row at: 2) * 10) rounded / 10.0)]

Compare the order with the one the binding rank gave in the scanning lesson.

Real processing involves more: the immunoproteasome and the other cleavages, trimming by the aminopeptidase ERAP1 once the peptide is in the ER, and the loading complex that edits peptides.  These two rules are what is left when everything else is thrown away, and the evidence that they add anything to a binding model is real but modest.'!
self
	^TutorialLesson title: 'Self and non-self' text:
'An immune system that attacked every peptide it could bind would attack itself.  T cells that react strongly to self peptides are removed in the thymus, so what is left looks for peptides that differ from self.  Two questions follow for an epitope: is it self, and if not, how close does it come.

A self proteome holds every window of a set of proteins.  Ubiquitin and beta-2 microglobulin (the light chain of every class I molecule) are the stand-ins for self here:

| s | s := SelfProteome withProteins: (Array with: (Immuno exampleProtein: #ubiquitin) with: (Immuno exampleProtein: #beta2microglobulin)). s size
| s | s := SelfProteome withProteins: (Array with: (Immuno exampleProtein: #ubiquitin) with: (Immuno exampleProtein: #beta2microglobulin)). s includes: ''KTLTGKTIT''
| s | s := SelfProteome withProteins: (Array with: (Immuno exampleProtein: #ubiquitin) with: (Immuno exampleProtein: #beta2microglobulin)). s includes: ''GILGFVFTL''

A peptide that is not self may still be a near-miss.  The nearest self peptide, with its normalised BLOSUM similarity, and the fewest positions at which the peptide differs from self:

| s | s := SelfProteome withProteins: (Array with: (Immuno exampleProtein: #ubiquitin)). s nearest: ''KTLAGKTIT''
| s | s := SelfProteome withProteins: (Array with: (Immuno exampleProtein: #ubiquitin)). s mismatchesToNearest: ''KTLAGKTIT''
| s | s := SelfProteome withProteins: (Array with: (Immuno exampleProtein: #ubiquitin)). s mismatchesToNearest: ''GILGFVFTL''

This is the question behind neoantigens: a tumour mutation changes one residue, and the mutant peptide is one position from self.  Whether it is a good target depends on whether the change falls on an anchor, which affects binding, or on a position that points at the T cell, which affects recognition.  The binding model gives an answer for the first:

| m | m := AlleleModels matrixFor: ''A*02:01''. Array with: (m predict: ''KTLTGKTIT'') rank with: (m predict: ''KLLTGKTIT'') rank

Cross-reactivity is the same question seen from the other side: a T cell that recognises a viral peptide may also recognise a self or other peptide that looks similar from above the groove.  The BLOSUM similarity of the two is a first guide:

(Peptide on: ''GILGFVFTL'') similarityTo: (Peptide on: ''GILGFVFTL'')
(Peptide on: ''GILGFVFTL'') similarityTo: (Peptide on: ''GLLGFVFTL'')
(Peptide on: ''GILGFVFTL'') similarityTo: (Peptide on: ''AAAAAAAAA'')

A fuller treatment would weight the positions that face the T cell more than the anchors, which face the groove, and that is a sensible next exercise.'!
genotypes
	^TutorialLesson title: 'A person''s genotype' text:
'Each person has two alleles at each classical locus, so up to six class I alleles and a handful of class II ones.  A genotype is built from a string of allele names:

| g | g := Immuno genotype: ''A*02:01 A*24:02 B*07:02 B*07:02 C*07:02 C*04:01 DRB1*01:01 DRB1*15:01''. g
| g | g := Immuno genotype: ''A*02:01 A*24:02 B*07:02 B*07:02 C*07:02 C*04:01 DRB1*01:01 DRB1*15:01''. g loci
| g | g := Immuno genotype: ''A*02:01 A*24:02 B*07:02 B*07:02 C*07:02 C*04:01 DRB1*01:01 DRB1*15:01''. g allelesAt: ''B''
| g | g := Immuno genotype: ''A*02:01 A*24:02 B*07:02 B*07:02 C*07:02 C*04:01 DRB1*01:01 DRB1*15:01''. g homozygousLoci

This person is homozygous at B, so they have five distinct class I alleles rather than six: homozygosity shrinks the set of peptides a person can present, and is associated with faster progression in HIV.  A locus given with one allele only is taken as homozygous.

Which of the alleles have models, which supertypes the class I alleles fall in, and the class I and II alleles on their own:

| g | g := Immuno genotype: ''A*02:01 A*24:02 B*07:02 B*07:02 C*07:02 C*04:01 DRB1*01:01 DRB1*15:01''. g modelled
| g | g := Immuno genotype: ''A*02:01 A*24:02 B*07:02 B*07:02 C*07:02 C*04:01 DRB1*01:01 DRB1*15:01''. g supertypes
| g | g := Immuno genotype: ''A*02:01 A*24:02 B*07:02 B*07:02 C*07:02 C*04:01 DRB1*01:01 DRB1*15:01''. g classII

There is no model for HLA-C here, so nothing in it can be scored.  A real person''s repertoire of presentation includes C.

Scanning a protein against everything the person carries and has a model for:

| g r | g := Immuno genotype: ''A*02:01 A*24:02 B*07:02 B*07:02 DRB1*01:01''. r := Immuno scan: (Immuno exampleProtein: #influenzaM1) genotype: g. r alleles
| g r | g := Immuno genotype: ''A*02:01 A*24:02 B*07:02 B*07:02 DRB1*01:01''. r := Immuno scan: (Immuno exampleProtein: #influenzaM1) genotype: g. r coverage

presentation answers which alleles bind each peptide, which is what matters for deciding whether one peptide serves several people.  Most are presented by just one allele; a few by two or more, which makes them better vaccine candidates:

| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) forAll: #(''A*02:01'' ''A*01:01'' ''A*03:01'' ''B*07:02''). (r presentation select: [:alleles | alleles size > 1]) size
| r | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) forAll: #(''A*02:01'' ''A*01:01'' ''A*03:01'' ''B*07:02''). r presentation size'!
populations
	^TutorialLesson title: 'Alleles in populations' text:
'What matters for a vaccine or a screening panel is not one person but a population: what fraction of people carry an allele that presents at least one of its epitopes.  That is the population coverage, and it needs allele frequencies.

The frequencies that come with the package are rounded and illustrative, of the order seen in European-ancestry populations; for anything real, use a database such as allelefrequencies.net, and use one for the population you care about, because HLA frequencies differ widely between populations.

| f | f := AlleleFrequencies example. f loci
| f | f := AlleleFrequencies example. f frequencyOf: ''A*02:01''
| f | f := AlleleFrequencies example. f carrierFrequency: ''A*02:01''
| f | f := AlleleFrequencies example. f totalAt: ''A''
| f | f := AlleleFrequencies example. f expectedHeterozygosity: ''A''

A frequency of 0.27 means 27 percent of chromosomes carry the allele; but the person has two, so the fraction of people with at least one is 1 - (1 - p)^2, which is 47 percent.  The total at a locus is below one because not every allele is listed.  Under Hardy-Weinberg proportions the chance of the genotype a/b is 2pq if the alleles differ and p squared if they do not:

| f | f := AlleleFrequencies example. f genotypeFrequency: ''A*02:01'' with: ''A*01:01''
| f | f := AlleleFrequencies example. f genotypeFrequency: ''A*02:01'' with: ''A*02:01''

Coverage of a set of alleles combines them, locus by locus, assuming the loci are independent (they are not, which is an approximation the Hardy-Weinberg lesson says more about):

| f | f := AlleleFrequencies example. f coverageOf: #(''A*02:01'')
| f | f := AlleleFrequencies example. f coverageOf: #(''A*02:01'' ''A*01:01'' ''A*03:01'')
| f | f := AlleleFrequencies example. f coverageOf: #(''A*02:01'' ''A*01:01'' ''A*03:01'' ''B*07:02'' ''B*08:01'')

One epitope is not enough to protect most people, because a person may carry an allele that presents it and still not respond.  The number of hits a person carries is the better figure: the distribution of hits per person, and the fraction with at least three:

| f | f := AlleleFrequencies example. f hitDistributionOf: #(''A*02:01'' ''A*01:01'' ''A*03:01'' ''B*07:02'' ''B*08:01'')
| f | f := AlleleFrequencies example. f coverageOf: #(''A*02:01'' ''A*01:01'' ''A*03:01'' ''B*07:02'' ''B*08:01'') atLeast: 2
| f | f := AlleleFrequencies example. f averageHitsOf: #(''A*02:01'' ''A*01:01'' ''A*03:01'' ''B*07:02'' ''B*08:01'')

And the smallest panel for a target: choose alleles one at a time, each adding the most coverage.  The first few alleles cover a lot, and then the returns fall:

| f | f := AlleleFrequencies example. f bestAlleles: 4 from: (f alleles select: [:a | a gene = ''A'' or: [a gene = ''B'']])'!
hardy
	^TutorialLesson title: 'Hardy-Weinberg and linkage' text:
'Two properties of populations the lessons so far assumed are worth checking against data.

The first is Hardy-Weinberg proportions: if people mate without regard to their allele and the population is large, the genotypes appear at p squared, 2pq and q squared.  A sample of genotypes that deviates from this suggests inbreeding, population structure, selection, or genotyping errors; HLA typing has all of these, so the test is a standard check on data.  Take allele frequencies from the sample, work out the expected genotype counts, and compare with a chi-square statistic with k(k-1)/2 degrees of freedom for k alleles.

A sample of 200 people at HLA-A with two alleles, in the proportions an equilibrium predicts:

| s | s := (Array new: 50 withAll: #(''A*02:01'' ''A*02:01'')), (Array new: 100 withAll: #(''A*02:01'' ''A*01:01'')), (Array new: 50 withAll: #(''A*01:01'' ''A*01:01'')). (AlleleFrequencies hardyWeinbergTest: s)

The same allele frequencies, but too few heterozygotes, as an inbred population would show:

| s | s := (Array new: 80 withAll: #(''A*02:01'' ''A*02:01'')), (Array new: 40 withAll: #(''A*02:01'' ''A*01:01'')), (Array new: 80 withAll: #(''A*01:01'' ''A*01:01'')). (AlleleFrequencies hardyWeinbergTest: s)
| s | s := (Array new: 80 withAll: #(''A*02:01'' ''A*02:01'')), (Array new: 40 withAll: #(''A*02:01'' ''A*01:01'')), (Array new: 80 withAll: #(''A*01:01'' ''A*01:01'')). (AlleleFrequencies hardyWeinbergTest: s) pValue
| s | s := (Array new: 80 withAll: #(''A*02:01'' ''A*02:01'')), (Array new: 40 withAll: #(''A*02:01'' ''A*01:01'')), (Array new: 80 withAll: #(''A*01:01'' ''A*01:01'')). (AlleleFrequencies hardyWeinbergTest: s) observed

The p-value comes from the chi-square tail area, which the package computes itself:

ImmunoMath chiSquareSurvival: 3.841 df: 1
ImmunoMath chiSquareSurvival: 10 df: 3

The test is plain: with many alleles most genotype classes are rare, the chi-square approximation is poor, and exact tests are the right tool.

The second property is linkage.  HLA loci lie within a few million bases of each other on chromosome 6, and alleles at neighbouring loci are inherited together far more often than their frequencies predict.  Linkage disequilibrium measures this: D is the observed haplotype frequency minus the product of the allele frequencies, D'' scales it by its largest possible value so 1 means the two alleles never appear apart, and r squared is the squared correlation between the two.  With an allele A at 20 percent, B at 30 percent and the haplotype AB at 15 percent, where independence predicts 6 percent:

| ld | ld := LinkageDisequilibrium pA: 0.2 pB: 0.3 pAB: 0.15. ld
| ld | ld := LinkageDisequilibrium pA: 0.2 pB: 0.3 pAB: 0.15. ld expected
| ld | ld := LinkageDisequilibrium pA: 0.2 pB: 0.3 pAB: 0.15. ld d
| ld | ld := LinkageDisequilibrium pA: 0.2 pB: 0.3 pAB: 0.15. ld dPrime
| ld | ld := LinkageDisequilibrium pA: 0.2 pB: 0.3 pAB: 0.15. ld rSquared
| ld | ld := LinkageDisequilibrium pA: 0.2 pB: 0.3 pAB: 0.15. ld pValue: 500

The same, counted from a sample of haplotypes, each an allele at each locus:

| h ld | h := (Array new: 15 withAll: #(''A*01:01'' ''B*08:01'')), (Array new: 5 withAll: #(''A*01:01'' ''B*07:02'')), (Array new: 15 withAll: #(''A*02:01'' ''B*08:01'')), (Array new: 65 withAll: #(''A*02:01'' ''B*07:02'')). ld := LinkageDisequilibrium fromHaplotypes: h allele: ''A*01:01'' and: ''B*08:01''. ld

Linkage matters here in two ways.  The population coverage in the populations lesson assumed independent loci, which overstates the coverage of alleles that are linked, and the probability of a match in the matching lesson does too.  And it is why HLA matching is done on haplotypes: the extended haplotype of A*01:01, B*08:01 and DRB1*03:01, one of the most common in Europeans, is inherited as a single block.'!
matching
	^TutorialLesson title: 'Matching donors' text:
'Transplantation is the other great reason to type HLA.  A graft carries the donor''s HLA; if the recipient lacks some of those alleles, their T cells will see the graft as foreign and reject it (host versus graft).  In a stem cell transplant the donor''s T cells come with it and may attack a recipient who has alleles the donor lacks (graft versus host).  The closer the match, the better the outcome.

Two genotypes, typed at A, B, C, DRB1 and DQB1, differing at A and at DQB1:

| a b | a := Immuno genotype: ''A*01:01 A*02:01 B*08:01 B*57:01 C*07:01 C*06:02 DRB1*03:01 DRB1*07:01 DQB1*02:01 DQB1*03:03''. b := Immuno genotype: ''A*01:01 A*03:01 B*08:01 B*57:01 C*07:01 C*06:02 DRB1*03:01 DRB1*07:01 DQB1*02:01 DQB1*03:02''. HLAMatch recipient: a donor: b
| a b | a := Immuno genotype: ''A*01:01 A*02:01 B*08:01 B*57:01 C*07:01 C*06:02 DRB1*03:01 DRB1*07:01 DQB1*02:01 DQB1*03:03''. b := Immuno genotype: ''A*01:01 A*03:01 B*08:01 B*57:01 C*07:01 C*06:02 DRB1*03:01 DRB1*07:01 DQB1*02:01 DQB1*03:02''. (HLAMatch recipient: a donor: b) report
| a b | a := Immuno genotype: ''A*01:01 A*02:01 B*08:01 B*57:01 C*07:01 C*06:02 DRB1*03:01 DRB1*07:01 DQB1*02:01 DQB1*03:03''. b := Immuno genotype: ''A*01:01 A*03:01 B*08:01 B*57:01 C*07:01 C*06:02 DRB1*03:01 DRB1*07:01 DQB1*02:01 DQB1*03:02''. (HLAMatch recipient: a donor: b) hostVersusGraft
| a b | a := Immuno genotype: ''A*01:01 A*02:01 B*08:01 B*57:01 C*07:01 C*06:02 DRB1*03:01 DRB1*07:01 DQB1*02:01 DQB1*03:03''. b := Immuno genotype: ''A*01:01 A*03:01 B*08:01 B*57:01 C*07:01 C*06:02 DRB1*03:01 DRB1*07:01 DQB1*02:01 DQB1*03:02''. (HLAMatch recipient: a donor: b) graftVersusHost

The grade, 8/10, counts the alleles that match out of ten; hostVersusGraft lists the donor alleles the recipient lacks and graftVersusHost the recipient''s alleles the donor lacks.  A locus where the donor is homozygous for one of the recipient''s alleles is a match in one direction and a mismatch in the other.

Resolution matters: a match at one field, the allele group, may be a mismatch at two.  Here two alleles of the same group differ in protein:

| a b | a := Immuno genotype: ''A*02:01 B*07:02''. b := Immuno genotype: ''A*02:05 B*07:02''. Array with: (HLAMatch recipient: a donor: b resolution: 1 loci: #(''A'' ''B'')) grade with: (HLAMatch recipient: a donor: b resolution: 2 loci: #(''A'' ''B'')) grade

How likely is a random unrelated person in a population to be a full match.  The chance for one locus is the Hardy-Weinberg frequency of the recipient''s pair, and the loci are multiplied (again assuming independence, which overstates the rarity of a haplotype-matched donor):

| a f | a := Immuno genotype: ''A*01:01 A*02:01 B*08:01 B*57:01''. f := AlleleFrequencies example. f matchProbability: a loci: #(''A'' ''B'')
| a f | a := Immuno genotype: ''A*02:01 A*02:01 B*07:02 B*07:02''. f := AlleleFrequencies example. f matchProbability: a loci: #(''A'' ''B'')

At just these two loci the chance is about one in a thousand to one in two thousand, and a homozygote is easier to match than a heterozygote.  Every further locus multiplies the chance down again, by an order of magnitude or more, which is why registries need millions of donors and why there are still patients with none.'!
vaccine
	^TutorialLesson title: 'Choosing epitopes for a vaccine' text:
'An epitope-based vaccine carries a few peptides rather than a whole protein.  Choosing them is a coverage problem: each peptide is presented by some alleles, each allele is carried by some of the population, and the aim is to reach the most people with the fewest peptides, ideally more than once.

The step is greedy: pick the peptide that adds the most coverage, then the one that adds the most to that, and so on.  Take influenza M1 and the commonest A and B alleles:

| r f | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) forAll: #(''A*02:01'' ''A*01:01'' ''A*03:01'' ''A*24:02'' ''B*07:02'' ''B*08:01'' ''B*44:02''). f := AlleleFrequencies example. Immuno selectEpitopes: 4 from: r population: f
| r f | r := Immuno scan: (Immuno exampleProtein: #influenzaM1) forAll: #(''A*02:01'' ''A*01:01'' ''A*03:01'' ''A*24:02'' ''B*07:02'' ''B*08:01'' ''B*44:02''). f := AlleleFrequencies example. (Immuno selectEpitopes: 1 from: r population: f) first

Each row is a peptide, the alleles that present it, and the coverage reached with the peptides so far.  The first peptide presented by the most common alleles gets the largest jump; later ones add less.  The coverage here counts the fraction of people with at least one presenting allele: whether those people then mount a response is another matter.

What the procedure ignores matters as much as what it uses.  It takes the binding rank as a stand-in for presentation, without regard for processing, for whether the T cell repertoire has anything to recognise the peptide with, or for whether the peptide is conserved: an epitope in a region the virus changes freely is useless in a year.  Real pipelines add processing predictions (as in the processing lesson), a measure of immunogenicity from a model trained on T cell data, conservation across strains, and the crossreactivity with self (as in the lesson on self).

And the coverage is an estimate for the average person from a table of rounded frequencies.  It assumes independence between loci and between people, ignores the population it was not built for, and is no stronger than the frequencies it is built on.'!
whatnext
	^TutorialLesson title: 'Limits, and what next' text:
'Everything in this package is a simplification, and the places where it is simplest are the places a real predictor works hardest.

The binding models are motifs.  Modern predictors such as NetMHCpan and MHCflurry are neural networks trained on hundreds of thousands of measurements, mostly binding affinities and, increasingly, peptides eluted from cells and identified by mass spectrometry.  They represent an allele by the residues lining its groove, so they predict for alleles that have never been measured.  The models here know twenty alleles, each from a handful of anchor rules.

Binding is necessary for presentation but not sufficient; processing is a rough guess; and presentation is necessary for a T cell response but not sufficient: the T cell receptor repertoire, tolerance, and the context of infection decide the rest, and immunogenicity prediction is an open problem.

Harder still is class II.  The groove is open, the peptide register is not fixed, the binding data is sparser, and the models here are sketches.

HLA frequencies differ widely between populations and the table here is illustrative only.

What the package is good for is seeing how the pieces fit, and what each one adds.  Some things to try:

Write a motif for an allele of your own, from a paper, and see which known epitopes it recovers.
Train a matrix on binders you collect from the IEDB, and compare it with the built-in one by AUC on held-out peptides.
Scan a protein you work on against a genotype, and rank the windows by presentation score.
Change the penalty for non-nine lengths, or the thresholds for strong and weak, and see what moves.
Add a model for HLA-C, which has none here.

To go further:

NetMHCpan and NetMHCIIpan (DTU Health Tech) and MHCflurry for binding and presentation; the IEDB (iedb.org) for measured epitopes and a collection of prediction tools; the IPD-IMGT/HLA database (ebi.ac.uk/ipd/imgt/hla) for allele sequences and the naming; allelefrequencies.net for frequencies by population; Janeway''s Immunobiology for the biology under all of it.'! !
