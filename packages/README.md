# Optional packages

This folder holds systems that are **not** part of the standard image. Load one when you want it:

```smalltalk
Smalltalk availablePackages            "#('Bio' 'Debugger' 'Phylo' 'Prolog' 'Regex' 'SUnit')"
Smalltalk loadPackage: 'Prolog'        "files it in (once)"
Smalltalk isPackageLoaded: 'Prolog'
Smalltalk packageDescription: 'Prolog' "the first comment of its file"
```

From the UI use **System menu → load package...**; from the shell start with `st -l Prolog`
(`-l` may be repeated). A package can add items to the System menu (the Prolog package adds *prolog workspace*).

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
* **[Bio](Bio/README.md)** — bioinformatics: FASTA, FASTQ and GenBank files, sequence and feature objects, translation with
  the NCBI genetic codes, ORFs, composition and assembly statistics, IUPAC pattern search, k-mers, restriction enzymes,
  Needleman-Wunsch and Smith-Waterman alignment, a sequence browser, and (with Prolog loaded) features as Prolog facts.
* **[Phylo](Phylo/README.md)** — phylogenetics, which loads Bio: the usual distance models, neighbour joining and UPGMA, Newick
  reading and writing, trees drawn with characters, re-rooting and Robinson-Foulds comparison, progressive multiple alignment,
  the bootstrap with a majority-rule consensus, and a tree browser.
