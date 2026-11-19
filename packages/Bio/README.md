# Bioinformatics in Smalltalk

Sequence data from FASTA, FASTQ and GenBank files, and the analyses one usually wants over it. An optional package:

```smalltalk
Smalltalk loadPackage: 'Bio'       "or: st -l Bio, or System menu → load package..."
```

Everything it answers is an ordinary object you keep working with — a `SequenceCollection` of `SeqRecord`s, each holding a
`DNASequence`, `RNASequence` or `ProteinSequence` — so the Inspector, the browser and plain Smalltalk all apply.

## Reading files

```smalltalk
Bio read: 'genome.gb'                     "the format is taken from the name, or the first line"
Bio readFasta: 'reads.fa'
Bio readFastq: 'reads.fq'
Bio readGenBank: 'NC_000913.gbk'
Bio parseFasta: '>a
ACGTACGT'                                 "from text instead of a file"
Bio fasta: 'huge.fa' do: [:record | ... ] "one record at a time: the file need not fit in memory"
```

A reader answers a `SequenceCollection`:

```smalltalk
| seqs |
seqs := Bio read: (Bio exampleFile: 'example.fasta').
seqs size.                 "3"
seqs ids.                  "#('sp|P69905|HBA_HUMAN' ...)"
seqs atId: 'sp|P69905|HBA_HUMAN'.
seqs totalLength. seqs n50. seqs l50. seqs gcPercent. seqs longest.
seqs statistics.           "the usual table: count, total, shortest, longest, mean, median, N50, L50, N90, GC"
(seqs select: [:r | r size > 100]) writeFastaTo: 'big.fasta'.
```

Writing is FASTA and FASTQ:

```smalltalk
Bio write: seqs toFasta: 'out.fasta'.
Bio write: reads toFastq: 'out.fastq'.
record asFasta.    record asFastq.    seqs asFasta.
```

A GenBank entry that has been parsed can be written out as FASTA like any other record; this package does not
write GenBank flat files.

## Records, features and locations

```smalltalk
| r |
r := (Bio read: 'NC_000913.gbk') first.
r id. r description. r organism. r accession. r version. r topology. r taxonomy. r isCircular.
r size. r gcPercent. r sequence.
r features size. r featureTypes. r cdsFeatures. r genes.
r featuresOfType: 'tRNA'.
r featuresAt: 50000.                       "every feature covering that base"
```

A `SeqFeature` has a key, a `SeqLocation` and its qualifiers:

```smalltalk
| f |
f := r cdsFeatures first.
f key. f start. f stop. f strand. f label.
f gene. f product. f locusTag. f proteinId.
f qualifierAt: 'codon_start'.
f qualifiersAt: 'db_xref'.                 "a qualifier may appear more than once"
f details.                                 "the feature as GenBank writes it"
r sequenceOf: f.                           "the bases, spliced and on the right strand"
r proteinOf: f.                            "the translation, as /translation holds it"
```

Locations keep their meaning, including joins, complements and fuzzy ends:

```smalltalk
SeqLocation fromString: 'complement(join(12..78,134..202))'.
(SeqLocation fromString: '<1..206') fuzzyStart.          "true"
(SeqLocation fromString: 'join(1..3,10..12)') extractFrom: (Bio dna: 'AAACCCGGGTTA').   "AAATTA"
```

## Sequences

```smalltalk
| s |
s := Bio dna: 'ATGAAATTTGGGTGA'.           "also Bio rna: , Bio protein: , Bio sequence: (guessed)"
s reverseComplement. s complement. s transcribe.
s size. s gc. s gcPercent. s gcSkew. s composition. s compositionReport.
s copyFrom: 4 to: 9. s first: 10. s allButLast: 3. s , 'ACGT'.
s isValid. s invalidCharacters.            "IUPAC ambiguity codes are part of the alphabet"
s wrappedAt: 60.
```

Translation uses any NCBI genetic code (1–6, 9–14, 16, 21–26):

```smalltalk
s translate.                               "the standard code, frame 1"
s translateToStop.
s translateFrame: -2.
s translateWith: (Bio geneticCode: 11).    "bacterial"
s sixFrameTranslations.
GeneticCode standard stopCodons.           "#('TAA' 'TAG' 'TGA')"
(GeneticCode id: 2) aminoAcidFor: 'TGA'.   "$W in vertebrate mitochondria"
GeneticCode bacterial isStartCodon: 'GTG'. "true"
(GeneticCode standard codonsFor: $W).
```

Open reading frames come back as features, so they behave like GenBank ones:

```smalltalk
s orfs.                                    "both strands, 30 bases or more"
s orfsLongerThan: 300.
s longestOrf.
(s orfsLongerThan: 300) first qualifierAt: 'translation'.
s codonUsage. s codonUsageReport.
```

Physical properties:

```smalltalk
(Bio dna: 'ACGTACGTAC') meltingTemperature.          "Wallace below 14 bases, the GC formula above"
(Bio dna: 'ACGT') molecularWeight.
(Bio protein: 'MKVLWAAL') molecularWeight.
(Bio protein: 'MKVLWAAL') isoelectricPoint.
(Bio protein: 'MKVLWAAL') chargeAtPH: 7.0.
(Bio protein: 'MKVLWAAL') aromaticity.
```

## Searching, k-mers and restriction sites

```smalltalk
s indicesOf: 'GAATTC'.                     "exact, ignoring case"
s indicesOfPattern: 'GGNTTY'.              "IUPAC ambiguity codes in the pattern"
s indicesOfPatternBothStrands: 'GAATTC'.   "position -> strand"
s includesPattern: 'GAATTC'. s occurrencesOfPattern: 'ACG'.
s kmerCounts: 6.
s mostFrequentKmers: 6 count: 10.
s gcContentIn: 1000 step: 500.             "a sliding window: start -> GC"

s restrictionSites.                        "every enzyme in the table that cuts, and where"
s restrictionReport.
s restrictionSitesOf: 'EcoRI'.
s digestWith: 'EcoRI'.                     "the fragments"
RestrictionEnzyme names.                   "29 common enzymes"
```

## Alignment

Needleman-Wunsch (global) and Smith-Waterman (local), both with affine gap costs:

```smalltalk
| a |
a := (Bio protein: 'HEAGAWGHEE') localAlignWith: (Bio protein: 'PAWHEAE').
a score. a identities. a identityPercent. a gaps. a start1. a stop1.
a firstAligned. a secondAligned. a matchLine.
a report.                                  "the alignment in blocks, with positions and a match line"

(Bio dna: 'ACGTTACGT') alignWith: (Bio dna: 'ACGTACGT').
(Bio protein: 'MKVLWAAL') identityWith: (Bio protein: 'MKVIWSAAL').

"the costs and the matrix can be chosen"
| aligner |
aligner := PairwiseAligner matrix: ScoringMatrix blosum62 gapOpen: 11 gapExtend: 1.
aligner localAlign: p1 with: p2.
ScoringMatrix nucleotide. ScoringMatrix blosum62. ScoringMatrix match: 1 mismatch: 0.
```

The matrices fill one cell per pair of residues, so a few thousand residues a side is comfortable;
whole chromosomes are not.

## FASTQ quality

```smalltalk
| reads |
reads := Bio readFastq: 'reads.fq'.
reads qualityReport.                       "reads, bases, mean quality, the share at Q20 and Q30"
reads meanQualityByPosition.               "for a per-cycle quality plot"
reads trimQualityBelow: 20.
(reads at: 1) quality.                     "the Phred scores as an Array"
(reads at: 1) meanQuality. (reads at: 1) expectedErrors.
(reads at: 1) trimQualityBelow: 20.
```

Phred+33 is assumed unless a quality character is too high to be one, in which case Phred+64 is used; writing is
always Phred+33. `FastqReader onFile: path offset: 64` forces the encoding.

## The sequence browser

*System menu → sequence browser* (or `Bio openBrowser`, `Bio openBrowserOn: 'file.gb'`) opens a window with the records on
the left and a view of the selected one on the right. The right-button menu on the list opens a file and chooses what the
right pane shows: the summary, the sequence, the GenBank features, open reading frames, the six-frame translation, base
composition, restriction sites, or (for FASTQ) the quality scores. It can also show the statistics of the whole file,
write the records as FASTA, and open an Inspector on the selected record.

## Querying features with Prolog

With the Prolog package loaded, a parsed record becomes facts:

```smalltalk
Smalltalk loadPackage: 'Prolog'.
BioProlog assertAll: (Bio read: 'genome.gb').
Prolog answer: 'cds(Id, I, S, E, -1), feature_length(Id, I, L), L > 500'
```

The facts are `sequence(Id, Length, Molecule)`, `description(Id, Text)`, `organism(Id, Name)`, `taxon(Id, Rank, Name)`,
`feature(Id, Index, Key, Start, Stop, Strand)` and `qualifier(Id, Index, Name, Value)`; text is asserted as atoms, so
queries read naturally (`gene(Id, I, alpha)`). `rules.pl` adds `gene/3`, `product/3`, `locus_tag/3`, `cds/5`,
`feature_length/3`, `overlapping/3`, `feature_at/3`, `features_by_start/2`, `gene_location/5` and `longer_than/2`.
`BioProlog reset` starts again with an empty engine.

## Example data

`data/example.fasta` (two haemoglobin chains and a synthetic promoter), `data/example.fastq` (four reads of differing
quality) and `data/example.gb` (a 420 bp synthetic construct with two CDS features, one on each strand). `Bio examples`
lists them and `Bio exampleFile: 'example.gb'` gives the path.

## Notes

* Sequences keep the case they were given, so soft-masked lowercase survives a round trip, but every analysis is
  case-insensitive.
* The physical properties are the usual textbook approximations: the Wallace and GC rules for melting temperature
  (not nearest-neighbour), average residue masses, and Henderson-Hasselbalch with one standard set of pKa values
  for the isoelectric point. Expect them to differ from ProtParam or EMBOSS in the first decimal place.
* A record forwards the common analyses to its sequence (`record gcPercent`, `record orfs`, `record alignWith:`);
  anything else is `record sequence`.
* A `SequenceCollection` is not a Smalltalk `Collection`; it answers `do:`, `select:`, `collect:`, `detect:ifNone:`,
  `at:`, `size` and the statistics, and `records` gives the underlying `OrderedCollection`.
* Not implemented: multiple alignment, BLAST-style database search, phylogenetics, SAM/BAM/VCF/BED, GFF, writing
  GenBank, and indexed random access to a FASTA file.
* The package adds one method to a kernel class: `Number>>printShowingDecimalPlaces:`, in `extend.st`, which is the
  standard Smalltalk method of that name.
* Tests are in `tests/tests.txt` and run as part of `make check`.
