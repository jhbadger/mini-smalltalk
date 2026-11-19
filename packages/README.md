# Optional packages

This folder holds systems that are **not** part of the standard image. Load one when you want it:

```smalltalk
Smalltalk availablePackages            "#('Prolog')"
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
* Remember that in a chunk file a literal `!` inside source must be written `!!`.

Keep tests with the package (the Prolog package has `tests/tests.txt`, which `make check` runs).
