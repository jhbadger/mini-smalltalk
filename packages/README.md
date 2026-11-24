# Optional packages

This folder holds systems that are **not** part of the standard image. Load one when you want it:

```smalltalk
Smalltalk availablePackages            "#('Algebra' 'APL' 'Bio' 'Debugger' 'Forth' 'Greek' 'Immuno' 'Matrix' 'Phylo' 'Prolog' 'Regex' 'Scheme' 'Stats' 'SUnit')"
Smalltalk loadPackage: 'Prolog'        "files it in (once)"
Smalltalk isPackageLoaded: 'Prolog'
Smalltalk packageDescription: 'Prolog' "the first comment of its file"
```

From the UI use **System menu → load package...**; from the shell start with `st -l Prolog`
(`-l` may be repeated). A package can add items to the System menu (the Prolog package adds *prolog workspace*, Forth adds *forth workspace*, Immuno adds *immuno workspace*; Scheme, APL and Algebra add theirs too).

What loading does:

* The package's code is filed in without being copied into the changes file; instead **one line**,
  `Smalltalk loadPackage: 'Prolog'!`, is appended to it, so the next session loads the package again.
* If you then **save an image** (`Smalltalk snapshot`, or *save image* in the menu), the package becomes part of that image, and the
  changes file (with its `loadPackage:` line) is set aside as usual. The base `kernel.image` never contains packages.
* Loading a package that is already loaded does nothing.

## Writing a package

A package is either a single file `Name.st`, or a folder `Name/` containing `package.st`. Both are ordinary
chunk-format source (the same as the `kernel*.st` files). The first double-quoted comment in the file is its description.

A folder package can file in the rest of itself, and find its data files with `Smalltalk packagePath: 'Name'`:

```smalltalk
"Name: what it does, in one line"
| dir |
dir := Smalltalk packagePath: 'Name'.
#('classes.st' 'tools.st') do: [:f | Smalltalk fileIn: dir, '/', f]!
Name initialize!
SystemMenu add: 'name workspace' receiver: NameTool selector: #open!
```

Useful hooks:

* `SystemMenu add: 'label' receiver: anObject selector: #aSymbol` adds a System menu item
  (`SystemMenu remove: 'label'` removes it).
* `Smalltalk openTool: 'ToolClass' title: 'Title' contents: 'text'` opens a workspace window whose *do it* and *print it* send
  `ToolClass evaluate: aString` (answering a String, which *print it* inserts) instead of compiling Smalltalk. This is how the Prolog
  window works.
* `Smalltalk openListTool: 'ToolClass' title: 'Title'` opens a two-pane browser: a list on the left, details on the right. The class
  answers `listItems` (an Array of Strings), `detailAt: index` (the text for the selected row), `commandLabels` (the list's
  right-button menu, where `'-'` is a separator) and `command: labelIndex at: itemIndex` (a String answer replaces the detail pane).
  The list is refreshed after every command. This is how the sequence browser works.
* `Smalltalk promptFor: 'Question' default: 'text'` asks the user for a line of text, and answers nil when they cancel or when
  there is no user interface (so it is safe in a script).
* Remember that in a chunk file a literal `!` inside source must be written `!!`.

Keep tests with the package: both packages have a `tests/tests.txt` of `expression ==> expected printString` lines that
`make check` runs, normally and again with the garbage collector under pressure.

## The packages

* **[Prolog](Prolog/README.md)** — a Prolog system: Edinburgh/ISO syntax, the standard library, DCGs, `assert`/`retract`,
  exceptions, a bridge in both directions between Prolog and Smalltalk objects, and a query window.
* **[SUnit](SUnit/README.md)** — the Smalltalk testing framework: `TestCase`, assertions, suites, results, and a test
  runner window. Write tests as methods beginning with `test` in a subclass of `TestCase`.
* **[Debugger](Debugger/README.md)** — a window on the stack of an error: frames, source with the failing line
  marked, variables by name, and evaluation in a frame. Loading it is enough; unhandled errors open it by themselves.
* **[Regex](Regex/README.md)** — regular expressions: the usual pattern language matched by backtracking, with
  searching, replacing and splitting, and String messages such as `matchesRegex:` and `copyWithRegex:replacedWith:`.
* **[Forth](Forth/README.md)** — a Forth system: an outer interpreter and compiler, the ANS core words and many more,
  `create ... does>`, double-length numbers, a floating-point stack, `catch` and `throw`, a bridge in both directions between
  the Forth stack and Smalltalk objects, a workspace, and a tutorial of 19 lessons.
* **[Bio](Bio/README.md)** — bioinformatics: FASTA, FASTQ and GenBank files, sequence and feature objects, translation with
  the NCBI genetic codes, ORFs, composition and assembly statistics, IUPAC pattern search, k-mers, restriction enzymes,
  Needleman-Wunsch and Smith-Waterman alignment, a sequence browser, and (with Prolog loaded) features as Prolog facts.
* **[Phylo](Phylo/README.md)** — phylogenetics, which loads Bio: the usual distance models, neighbour joining and UPGMA, Newick
  reading and writing, trees drawn with characters, re-rooting and Robinson-Foulds comparison, progressive multiple alignment,
  the bootstrap with a majority-rule consensus, and a tree browser.
* **[Stats](Stats/README.md)** — tables and statistics: a CSV reader and writer that copes with quoting and holes, a DataTable
  with select, sort, group and join, the descriptive statistics on any collection, t tests, chi-square, Mann-Whitney, Wilcoxon,
  analysis of variance and correlation tests with real p-values, least squares regression, text plots, and a table browser.
* **[Greek](Greek/README.md)** — Modern Greek grammar: verbs conjugated in every tense and both voices from their two stems,
  the irregular verbs, nouns in each inflection class with their accent shifts, articles, adjective agreement, the personal
  pronouns strong and weak, a lexicon of common words, beta-code input, and a tutorial that teaches the grammar itself.
* **[Immuno](Immuno/README.md)** — computational immunology around the MHC: peptides and HLA allele names, position-specific
  binding models for twenty class I and class II alleles (teaching models, with exact percentile ranks), protein scanning,
  models you train yourself and test by AUC, antigen processing, self and non-self, genotypes, population coverage,
  Hardy-Weinberg and linkage, donor matching, epitope selection for a vaccine, a workspace, and an 18-lesson tutorial.
* **[Scheme](Scheme/README.md)** — a Scheme system: R5RS and much of R7RS-small, evaluated by a register machine with heap
  continuations so tail calls are proper and `call/cc` is full and re-entrant; `dynamic-wind`, `syntax-rules` macros, records,
  hash tables, string ports, `guard`, a bridge in both directions with Smalltalk, a workspace, and a 21-lesson tutorial.
* **[APL](APL/README.md)** — an array language in the APL and J family: J-style ASCII words read right to left, multi-axis
  arrays, rank and agreement, adverbs and conjunctions, explicit and tacit definitions, boxes, exact integers and rationals,
  classic APL glyphs as alternate spellings, a workspace, and a 20-lesson tutorial.
* **[Matrix](Matrix/README.md)** — linear algebra with entries that are exact Integers and Fractions or Floats: elimination
  (with a step-by-step text trace), determinant, inverse, rank, null space, LU, Cholesky, QR, eigenvalues (including complex
  pairs), the SVD, pseudoinverse, least squares, matrix functions, and an 18-lesson tutorial.
* **[Algebra](Algebra/README.md)** — a computer algebra system with canonical-form expressions: an infix reader, printing and
  LaTeX, expand, factor over the rationals, partial fractions, polynomial GCD, derivatives, integrals, limits, series, solving
  equations and linear systems, summation, a command workspace, and a 19-lesson tutorial.
