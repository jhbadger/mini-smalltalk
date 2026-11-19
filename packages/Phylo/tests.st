"Tests for the Phylo package: the tree, Newick, the distance models, the two tree builders, the drawing, the
multiple alignment and the bootstrap.

The example data was made by simulating along a known tree under Jukes-Cantor, so the tests can ask the one
question that matters of a tree builder: does it get the right tree back."

TestCase subclass: #PhyloTreeTest instanceVariableNames: '' classVariableNames: '' category: 'Phylo-Tests'!
TestCase subclass: #PhyloDistanceTest instanceVariableNames: '' classVariableNames: '' category: 'Phylo-Tests'!
TestCase subclass: #PhyloBuildTest instanceVariableNames: '' classVariableNames: '' category: 'Phylo-Tests'!
TestCase subclass: #PhyloAlignmentTest instanceVariableNames: '' classVariableNames: 'SharedBootstrap' category: 'Phylo-Tests'!

"---- the tree, Newick and the drawing ----"

!PhyloTreeTest methodsFor: 'helpers'!
small
	^PhyloTree fromNewick: '((A:0.1,B:0.2)95:0.05,C:0.3,D:0.4);'!
cherry
	^PhyloTree fromNewick: '(A:1,B:2);'! !

!PhyloTreeTest methodsFor: 'reading Newick'!
testTaxa
	self assert: self small taxa equals: #('A' 'B' 'C' 'D')!
testCounts
	self assert: self small size equals: 4.
	self assert: self small nodeCount equals: 6.
	self assert: self small leaves size equals: 4.
	self assert: self small internalNodes size equals: 2!
testBranchLengths
	| t |
	t := self small.
	self assert: (t leafNamed: 'A') branchLength equals: 0.1.
	self assert: (t leafNamed: 'D') branchLength equals: 0.4.
	self assert: t hasBranchLengths!
testSupportIsRead
	| t inner |
	t := self small.
	inner := t internalNodes detect: [:each | each isRoot not].
	self assert: inner support equals: 95.
	self assert: t hasSupport!
testInternalLabelThatIsNotANumber
	| t inner |
	t := PhyloTree fromNewick: '((A,B)Primates,C);'.
	inner := t internalNodes detect: [:each | each isRoot not].
	self assert: inner label equals: 'Primates'.
	self deny: inner hasSupport!
testQuotedLabel
	| t |
	t := PhyloTree fromNewick: '((''Homo sapiens'':1,''Pan, troglodytes'':2),Gorilla);'.
	self assert: (t includesTaxon: 'Homo sapiens').
	self assert: (t includesTaxon: 'Pan, troglodytes')!
testUnderscoreIsASpace
	self assert: ((PhyloTree fromNewick: '(Homo_sapiens,Gorilla);') includesTaxon: 'Homo sapiens')!
testCommentsAreSkipped
	self assert: (PhyloTree fromNewick: '[a note](A,B[and another],C);') taxa equals: #('A' 'B' 'C')!
testWhitespaceIsSkipped
	self assert: (PhyloTree fromNewick: '( A : 1 , B : 2 ) ;') taxa equals: #('A' 'B')!
testNoSemicolonIsStillRead
	self assert: (PhyloTree fromNewick: '(A,B)') taxa equals: #('A' 'B')!
testParseAll
	self assert: (NewickReader parseAll: '(A,B);(C,D);') size equals: 2!
testBadNewick
	self should: [PhyloTree fromNewick: '((A,B);'] raise: PhyloError.
	self should: [PhyloTree fromNewick: ''] raise: PhyloError! !

!PhyloTreeTest methodsFor: 'writing Newick'!
testRoundTrip
	| text |
	text := '((A:0.1,B:0.2)95:0.05,C:0.3,D:0.4);'.
	self assert: (PhyloTree fromNewick: text) asNewick equals: text!
testWriteWithoutLengths
	self assert: (PhyloTree fromNewick: '((A:0.1,B:0.2),C:0.3);') asNewickWithoutLengths
		equals: '((A,B),C);'!
testLabelsAreQuotedWhenTheyMustBe
	| t |
	t := PhyloTree fromNewick: '(A,B);'.
	(t leafNamed: 'A') label: 'has, a comma'.
	self assert: (t asNewick includesSubstring: '''has, a comma''')!
testSpacesBecomeUnderscores
	| t |
	t := PhyloTree fromNewick: '(A,B);'.
	(t leafNamed: 'A') label: 'Homo sapiens'.
	self assert: (t asNewick includesSubstring: 'Homo_sapiens')! !

!PhyloTreeTest methodsFor: 'measuring'!
testPatristicDistance
	| t |
	t := self small.
	self assert: (t distanceBetween: 'A' and: 'B') closeTo: 0.3.
	self assert: (t distanceBetween: 'A' and: 'C') closeTo: 0.45.
	self assert: (t distanceBetween: 'C' and: 'D') closeTo: 0.7!
testDistanceToItself
	self assert: (self small distanceBetween: 'A' and: 'A') equals: 0!
testTotalBranchLength
	self assert: self small totalBranchLength closeTo: 1.05!
testMrca
	| t |
	t := self small.
	self assert: (t mrcaOf: #('A' 'B')) leafCount equals: 2.
	self assert: (t mrcaOf: #('A' 'C')) isRoot.
	self assert: (t mrcaOf: #('A' 'B' 'C')) isRoot!
testPath
	| t path |
	t := self small.
	path := t pathFrom: (t leafNamed: 'A') to: (t leafNamed: 'B').
	self assert: path size equals: 3!
testHeightAndDepth
	| t |
	t := self small.
	self assert: (t leafNamed: 'A') depth equals: 2.
	self assert: (t leafNamed: 'C') depth equals: 1.
	self assert: t height closeTo: 0.4!
testPatristicMatrixAgreesWithTheTree
	| t m |
	t := self small.
	m := t distanceMatrix.
	self assert: m size equals: 4.
	self assert: (m between: 'A' and: 'C') closeTo: (t distanceBetween: 'A' and: 'C')!
testMissingTaxon
	self should: [self small leafNamed: 'Z'] raise: PhyloError! !

!PhyloTreeTest methodsFor: 'shape'!
testRootedAndUnrooted
	self deny: self small isRooted.
	self assert: self cherry isRooted!
testIsBinary
	self assert: (PhyloTree fromNewick: '((A,B),(C,D));') isBinary.
	self deny: (PhyloTree fromNewick: '(A,B,C,D);') isBinary!
testStar
	| t |
	t := PhyloTree star: #('A' 'B' 'C' 'D').
	self assert: t size equals: 4.
	self assert: t splits isEmpty!
testSplits
	| t |
	t := PhyloTree fromNewick: '((A,B),(C,D));'.
	self assert: t splits size equals: 1.
	self assert: (t splits includes: #('C' 'D'))!
testRobinsonFoulds
	| a b |
	a := PhyloTree fromNewick: '((A,B),(C,D));'.
	b := PhyloTree fromNewick: '((A,C),(B,D));'.
	self assert: (a robinsonFouldsTo: a) equals: 0.
	self assert: (a robinsonFouldsTo: b) equals: 2.
	self assert: (a hasSameTopologyAs: a).
	self deny: (a hasSameTopologyAs: b)!
testTheSameTreeWrittenDifferently
	| a b |
	a := PhyloTree fromNewick: '((A,B),C,D);'.
	b := PhyloTree fromNewick: '(D,C,(B,A));'.
	self assert: (a hasSameTopologyAs: b)!
testLadderize
	| t |
	t := (PhyloTree fromNewick: '(((A,B),C),D);') ladderize.
	self assert: t root children first leafCount <= t root children last leafCount! !

!PhyloTreeTest methodsFor: 'changing the tree'!
testPrune
	| t |
	t := (PhyloTree fromNewick: '((A:1,B:1):1,(C:1,D:1):1);') pruneTaxa: #('A').
	self assert: t taxa equals: #('B' 'C' 'D').
	self assert: t size equals: 3!
testKeep
	| t |
	t := (PhyloTree fromNewick: '((A,B),(C,D));') keepTaxa: #('A' 'C').
	self assert: t taxa equals: #('A' 'C')!
testPruneKeepsTheLengths
	| t |
	t := (PhyloTree fromNewick: '((A:1,B:2):3,C:4);') pruneTaxa: #('A').
	self assert: (t leafNamed: 'B') branchLength closeTo: 5!
testScale
	| t |
	t := (PhyloTree fromNewick: '(A:1,B:2);') scaleBy: 10.
	self assert: (t leafNamed: 'A') branchLength closeTo: 10!
testCollapseShortBranches
	| t |
	t := (PhyloTree fromNewick: '((A:1,B:1):0.0001,C:1,D:1);') collapseBranchesShorterThan: 0.01.
	self assert: t root children size equals: 4!
testUnroot
	| t |
	t := (PhyloTree fromNewick: '((A:1,B:1):1,(C:1,D:1):1);') unroot.
	self assert: t root children size equals: 3.
	self deny: t isRooted!
testRootOnATaxon
	| t |
	t := (PhyloTree fromNewick: '((A:1,B:1):1,C:1,D:1);') rootOn: 'D'.
	self assert: t isRooted.
	self assert: t size equals: 4!
testMidpointRoot
	| t |
	t := (PhyloTree fromNewick: '((A:0.1,B:0.1):0.1,C:0.1,D:5.0);') rootOnMidpoint.
	self assert: t size equals: 4.
	self assert: t isRooted!
testCopyIsIndependent
	| a b |
	a := PhyloTree fromNewick: '(A:1,B:2);'.
	b := a copyTree.
	(b leafNamed: 'A') branchLength: 99.
	self assert: (a leafNamed: 'A') branchLength equals: 1! !

!PhyloTreeTest methodsFor: 'drawing'!
testDrawing
	| text |
	text := self small asText.
	self assert: (text includesSubstring: 'A').
	self assert: (text includesSubstring: 'D').
	self assert: (text includesSubstring: '---')!
testDrawingHasOneRowPerTaxonPlusTheGaps
	self assert: (self small asText lines size) equals: 7!
testCladogramOfATreeWithNoLengths
	| text |
	text := TreeRenderer cladogram: (PhyloTree fromNewick: '((A,B),C);').
	self assert: (text includesSubstring: 'A')!
testSupportIsDrawn
	self assert: (self small asText includesSubstring: '95')!
testReport
	| text |
	text := self small report.
	self assert: (text includesSubstring: '4 taxa').
	self assert: (text includesSubstring: 'unrooted')! !

"---- the distance models and the matrix ----"

!PhyloDistanceTest methodsFor: 'the models'!
testPDistance
	self assert: (PDistanceModel new distanceBetween: 'AAAA' and: 'AAAT') closeTo: 0.25.
	self assert: (PDistanceModel new distanceBetween: 'AAAA' and: 'AAAA') closeTo: 0!
testJukesCantorIsBiggerThanTheRawCount
	| p jc |
	p := PDistanceModel new distanceBetween: 'ACGTACGTAC' and: 'ACGTACGTTT'.
	jc := JukesCantorModel new distanceBetween: 'ACGTACGTAC' and: 'ACGTACGTTT'.
	self assert: jc > p!
testJukesCantorValue
	"two differences in ten sites: -3/4 ln(1 - 4(0.2)/3)"
	self assert: (JukesCantorModel new distanceBetween: 'AAAAAAAAAA' and: 'AAAAAAAATT')
		closeTo: 0.2326161962278796!
testKimuraSeparatesTheTwoKindsOfChange
	| transitions transversions |
	transitions := Kimura2ParameterModel new distanceBetween: 'AAAAAAAAAA' and: 'GGAAAAAAAA'.
	transversions := Kimura2ParameterModel new distanceBetween: 'AAAAAAAAAA' and: 'CCAAAAAAAA'.
	self deny: transitions = transversions!
testPoisson
	self assert: (PoissonModel new distanceBetween: 'AAAAAAAAAA' and: 'AAAAAAAAWW')
		closeTo: 0.22314355131420976!
testKimuraProtein
	self assert: (KimuraProteinModel new distanceBetween: 'AAAAAAAAAA' and: 'AAAAAAAAWW') > 0.22!
testGapsAndAmbiguitiesAreLeftOut
	"the N and the gap are not counted either way, so this is one difference in two usable columns"
	self assert: (PDistanceModel new distanceBetween: 'AN-A' and: 'AGTT') closeTo: 0.5!
testSaturationAnswersTheMaximum
	| m |
	m := JukesCantorModel new.
	self assert: (m distanceBetween: 'AAAAAAAA' and: 'CGCGCGCG') equals: m maximumDistance.
	self assert: m sawSaturation!
testNothingInCommon
	| m |
	m := PDistanceModel new.
	self assert: (m distanceBetween: '----' and: 'ACGT') equals: m maximumDistance!
testModelsByName
	self assert: (DistanceModel named: 'jc69') class equals: JukesCantorModel.
	self assert: (DistanceModel named: 'K2P') class equals: Kimura2ParameterModel.
	self assert: (DistanceModel named: 'p') class equals: PDistanceModel.
	self assert: (DistanceModel named: 'poisson') isForProtein.
	self should: [DistanceModel named: 'nonesuch'] raise: PhyloError!
testModelNames
	self assert: (DistanceModel names includes: 'jc69')! !

!PhyloDistanceTest methodsFor: 'the matrix'!
testEmptyMatrix
	| m |
	m := DistanceMatrix labels: #('A' 'B' 'C').
	self assert: m size equals: 3.
	self assert: (m at: 1 and: 2) equals: 0!
testSettingIsSymmetric
	| m |
	m := DistanceMatrix labels: #('A' 'B').
	m at: 1 and: 2 put: 5.
	self assert: (m at: 2 and: 1) equals: 5.
	self assert: (m between: 'A' and: 'B') equals: 5.
	self assert: m isSymmetric!
testMeasures
	| m |
	m := DistanceMatrix labels: #('A' 'B' 'C').
	m at: 1 and: 2 put: 2. m at: 1 and: 3 put: 4. m at: 2 and: 3 put: 6.
	self assert: m minimum equals: 2.
	self assert: m maximum equals: 6.
	self assert: m mean closeTo: 4.
	self assert: m closestPair equals: #(1 2)!
testKeepAndDrop
	| m |
	m := DistanceMatrix labels: #('A' 'B' 'C').
	m at: 1 and: 3 put: 7.
	self assert: (m withoutTaxon: 'B') labels equals: #('A' 'C').
	self assert: ((m withoutTaxon: 'B') at: 1 and: 2) equals: 7.
	self assert: (m keepTaxa: #('A' 'B')) size equals: 2!
testUnknownTaxon
	self should: [(DistanceMatrix labels: #('A')) between: 'A' and: 'Z'] raise: PhyloError!
testPhylipRoundTrip
	| m back |
	m := DistanceMatrix labels: #('alpha' 'beta' 'gamma').
	m at: 1 and: 2 put: 0.25. m at: 1 and: 3 put: 0.5. m at: 2 and: 3 put: 0.75.
	back := DistanceMatrix fromPhylip: m asPhylip.
	self assert: back labels equals: #('alpha' 'beta' 'gamma').
	self assert: (back at: 1 and: 3) closeTo: 0.5!
testBadPhylip
	self should: [DistanceMatrix fromPhylip: ''] raise: PhyloError.
	self should: [DistanceMatrix fromPhylip: 'not a number'] raise: PhyloError!
testFromAnAlignment
	| a m |
	a := MultipleAlignment labels: #('A' 'B') rows: #('ACGT' 'ACGA').
	m := DistanceMatrix fromAlignment: a model: 'p'.
	self assert: (m at: 1 and: 2) closeTo: 0.25! !

"---- the builders ----"

!PhyloBuildTest methodsFor: 'helpers'!
saitouNei
	"the matrix from the paper that introduced neighbour joining; it is additive, so the method should
	get the tree back exactly"
	| m |
	m := DistanceMatrix labels: #('A' 'B' 'C' 'D' 'E' 'F').
	m at: 1 and: 2 put: 5. m at: 1 and: 3 put: 4. m at: 1 and: 4 put: 7.
	m at: 1 and: 5 put: 6. m at: 1 and: 6 put: 8. m at: 2 and: 3 put: 7.
	m at: 2 and: 4 put: 10. m at: 2 and: 5 put: 9. m at: 2 and: 6 put: 11.
	m at: 3 and: 4 put: 7. m at: 3 and: 5 put: 6. m at: 3 and: 6 put: 8.
	m at: 4 and: 5 put: 5. m at: 4 and: 6 put: 9. m at: 5 and: 6 put: 8.
	^m! !

!PhyloBuildTest methodsFor: 'neighbour joining'!
testNeighbourJoiningGetsTheTaxaBack
	| t |
	t := self saitouNei neighbourJoining.
	self assert: t taxa equals: #('A' 'B' 'C' 'D' 'E' 'F')!
testAnAdditiveMatrixComesBackExactly
	"the real test of neighbour joining: the tree it makes must give back the distances it was given"
	| m t |
	m := self saitouNei.
	t := m neighbourJoining.
	1 to: m size do: [:i |
		i + 1 to: m size do: [:j |
			self assert: (t distanceBetween: (m labelAt: i) and: (m labelAt: j))
				closeTo: (m at: i and: j)]]!
testNeighbourJoiningIsUnrooted
	self deny: self saitouNei neighbourJoining isRooted.
	self assert: self saitouNei neighbourJoining root children size equals: 3!
testTwoTaxa
	| m t |
	m := DistanceMatrix labels: #('A' 'B').
	m at: 1 and: 2 put: 4.
	t := m neighbourJoining.
	self assert: t size equals: 2.
	self assert: (t distanceBetween: 'A' and: 'B') closeTo: 4!
testThreeTaxa
	| m t |
	m := DistanceMatrix labels: #('A' 'B' 'C').
	m at: 1 and: 2 put: 2. m at: 1 and: 3 put: 4. m at: 2 and: 3 put: 4.
	t := m neighbourJoining.
	self assert: (t distanceBetween: 'A' and: 'B') closeTo: 2.
	self assert: (t distanceBetween: 'B' and: 'C') closeTo: 4!
testTooFewTaxa
	self should: [(DistanceMatrix labels: #('A')) neighbourJoining] raise: PhyloError!
testNoNegativeBranches
	self saitouNei neighbourJoining nodes do: [:each |
		each hasBranchLength ifTrue: [self assert: each branchLength >= 0]]! !

!PhyloBuildTest methodsFor: 'UPGMA'!
testUpgmaIsRootedAndUltrametric
	| t |
	t := self saitouNei upgma.
	self assert: t isRooted.
	self assert: t isUltrametric!
testUpgmaClustersTheClosestFirst
	| m t |
	m := DistanceMatrix labels: #('A' 'B' 'C').
	m at: 1 and: 2 put: 1. m at: 1 and: 3 put: 9. m at: 2 and: 3 put: 9.
	t := m upgma.
	self assert: ((t mrcaOf: #('A' 'B')) leafCount) equals: 2!
testWpgma
	| t |
	t := self saitouNei wpgma.
	self assert: t size equals: 6.
	self assert: t isUltrametric!
testTheTwoMethodsNeedNotAgree
	self assert: (self saitouNei neighbourJoining robinsonFouldsTo: self saitouNei upgma) >= 0! !

!PhyloBuildTest methodsFor: 'the simulated data'!
testTheExampleFilesAreThere
	self assert: (FileStream exists: (Phylo exampleFile: 'example.fasta')).
	self assert: (FileStream exists: (Phylo exampleFile: 'example.tree')).
	self assert: (FileStream exists: (Phylo exampleFile: 'unaligned.fasta'))!
testNeighbourJoiningFindsTheTreeTheDataCameFrom
	| a tree truth |
	a := Phylo exampleAlignment.
	tree := a neighbourJoiningUsing: 'jc69'.
	truth := Phylo exampleTree.
	self assert: (tree robinsonFouldsTo: truth) equals: 0.
	self assert: (tree hasSameTopologyAs: truth)!
testTheAlignmentIsWhatWeThink
	| a |
	a := Phylo exampleAlignment.
	self assert: a size equals: 8.
	self assert: a length equals: 300.
	self deny: a isProtein.
	self assert: a gapCount equals: 0! !

"---- multiple alignment and bootstrap ----"

!PhyloAlignmentTest methodsFor: 'helpers'!
small
	^MultipleAlignment labels: #('A' 'B' 'C')
		rows: #('ACGT-ACGT' 'ACGTTACGT' 'ACGA-ACGA')!
shortExample
	"the first 150 columns of the simulated alignment: enough to recover the tree, quick enough to
	bootstrap in a test suite"
	^Phylo exampleAlignment columnsFrom: 1 to: 150!
sharedBootstrap
	"a bootstrap is slow, and several tests only look at the same one, so it is worked out once"
	^SharedBootstrap ifNil: [
		SharedBootstrap := Bootstrap new alignment: self shortExample; replicates: 8; run]!
shortSequences
	"the first 70 residues of the unaligned example, so that aligning them is quick"
	^Phylo exampleSequences collect: [:each |
		SeqRecord id: each id sequence: (each asString copyFrom: 1 to: 70)]! !

!PhyloAlignmentTest methodsFor: 'the alignment'!
testShape
	self assert: self small size equals: 3.
	self assert: self small length equals: 9.
	self assert: self small labels equals: #('A' 'B' 'C')!
testRowsMustBeTheSameLength
	self should: [MultipleAlignment labels: #('A' 'B') rows: #('ACGT' 'ACG')] raise: PhyloError!
testThereMustBeALabelForEveryRow
	self should: [MultipleAlignment labels: #('A') rows: #('ACGT' 'ACGT')] raise: PhyloError!
testRowNamed
	self assert: (self small rowNamed: 'B') equals: 'ACGTTACGT'.
	self should: [self small rowNamed: 'Z'] raise: PhyloError!
testColumn
	self assert: (self small columnAt: 4) equals: #($T $T $A)!
testGaps
	self assert: self small gapCount equals: 2.
	self assert: self small gapPercent closeTo: 200.0 / 27!
testConservation
	self assert: (self small conservationAt: 1) closeTo: 1.0.
	self assert: (self small isColumnInvariant: 1).
	self deny: (self small isColumnInvariant: 4)!
testConsensus
	self assert: self small consensus size equals: 9.
	self assert: (self small consensus first) equals: $A!
testMatchLine
	self assert: self small matchLine size equals: 9.
	self assert: self small matchLine first equals: $*!
testIdentity
	self assert: (self small identityBetween: 1 and: 2) closeTo: 1.0.
	self assert: (self small identityBetween: 1 and: 3) closeTo: 6.0 / 8!
testWithoutGapColumns
	self assert: self small withoutGapColumns length equals: 8!
testKeepColumns
	self assert: (self small columnsFrom: 1 to: 4) length equals: 4.
	self assert: ((self small columnsFrom: 1 to: 4) rowAt: 1) equals: 'ACGT'!
testKeepRows
	self assert: (self small keepRows: #('A' 'C')) size equals: 2!
testFastaRoundTrip
	| text back |
	text := self small asFasta.
	back := MultipleAlignment fromFasta: text.
	self assert: back labels equals: self small labels.
	self assert: back rows equals: self small rows!
testAsText
	self assert: (self small asText includesSubstring: 'ACGT')!
testReport
	self assert: (self small report includesSubstring: '3 sequences')!
testResamplingKeepsTheWidth
	self assert: (self small resampleColumnsWith: (Random seed: 1)) length equals: 9! !

!PhyloAlignmentTest methodsFor: 'the progressive aligner'!
testAligningTwoSequences
	| a |
	a := ProgressiveAligner new align: (Array with: 'ACGTACGT' with: 'ACGTACGT').
	self assert: a size equals: 2.
	self assert: a length equals: 8.
	self assert: (a identityBetween: 1 and: 2) closeTo: 1.0!
testAGapIsPutWhereTheInsertIs
	| a row |
	a := ProgressiveAligner new align: (Array with: 'ACGTTTTACGT' with: 'ACGTACGT').
	self assert: a length equals: 11.
	row := a rowAt: 2.
	self assert: (row occurrencesOf: $-) equals: 3.
	self assert: (row reject: [:c | c = $-]) equals: 'ACGTACGT'.
	"the three gaps must sit together, where the extra Ts of the first row are"
	self assert: (row includesSubstring: '---')!
testTheRowsComeBackInTheOrderTheyWereGiven
	| a |
	a := ProgressiveAligner new align: (Array with: 'ACGTACGTAA' with: 'TTTTTTTTTT' with: 'ACGTACGTAA').
	self assert: a size equals: 3.
	self assert: ((a rowAt: 2) includesSubstring: 'TTTT')!
testAligningRecords
	| a |
	a := ProgressiveAligner new align: self shortSequences.
	self assert: a size equals: 6.
	self assert: a labels first equals: 'Human'.
	self assert: a length >= 70!
testEveryRowStillHoldsItsOwnSequence
	"the aligner may only add gaps; take them out again and the sequence must be what went in"
	| records a |
	records := self shortSequences.
	a := ProgressiveAligner new align: records.
	1 to: a size do: [:i |
		self assert: ((a rowAt: i) reject: [:c | c = $-]) equals: (records at: i) asString]!
testGuideTreeIsKept
	| aligner |
	aligner := ProgressiveAligner new.
	aligner align: (Array with: 'ACGTACGT' with: 'ACGTACGA' with: 'TTTTTTTT').
	self assert: aligner guideTree size equals: 3!
testNothingToAlign
	self should: [ProgressiveAligner new align: #()] raise: PhyloError!
testOneSequence
	self assert: (ProgressiveAligner new align: (Array with: 'ACGT')) length equals: 4! !

!PhyloAlignmentTest methodsFor: 'the bootstrap'!
testBootstrapGivesEveryBranchASupport
	self sharedBootstrap tree root internalDo: [:node |
		node isRoot ifFalse: [self assert: node hasSupport]]!
testTheStrongBranchesAreStronglySupported
	| b |
	b := self sharedBootstrap.
	self assert: (b supportFor: #('Baboon' 'Macaque')) >= 80.
	self assert: (b supportFor: #('Human' 'Chimpanzee' 'Gorilla')) >= 80.
	self assert: (b countFor: (b splitsAbove: 90) first) > 0!
testTheSameSeedGivesTheSameAnswer
	| a b |
	a := Bootstrap new alignment: self shortExample; replicates: 4; seed: 7; run.
	b := Bootstrap new alignment: self shortExample; replicates: 4; seed: 7; run.
	self assert: a tree asNewick equals: b tree asNewick.
	self assert: a counts equals: b counts!
testConsensus
	| c |
	c := self sharedBootstrap consensus.
	self assert: c size equals: 8.
	self assert: (c splits size between: 1 and: 5)!
testBootstrapWithNoAlignment
	self should: [Bootstrap new run] raise: PhyloError!
testReport
	self assert: (self sharedBootstrap report includesSubstring: '8 replicates')! !

!PhyloAlignmentTest methodsFor: 'the facade'!
testFacade
	self assert: (Phylo tree: '(A,B,C);') size equals: 3.
	self assert: (Phylo models includes: 'jc69').
	self assert: (Phylo draw: (Phylo tree: '(A,B,C);')) notEmpty.
	self assert: Phylo examples size equals: 3.
	self assert: (Phylo nj: Phylo exampleAlignment) size equals: 8.
	self assert: (Phylo upgma: Phylo exampleAlignment) isUltrametric! !
