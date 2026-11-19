"Phylo: phylogenetics - distance models, neighbour joining and UPGMA, Newick, tree drawing and progressive multiple alignment"
| dir |
Smalltalk loadPackage: 'Bio'.          "the sequences and the scoring matrices come from there"
Smalltalk loadPackage: 'SUnit'.        "the tests are written in it"
dir := Smalltalk packagePath: 'Phylo'.
#('tree.st' 'distance.st' 'newick.st' 'build.st' 'render.st' 'msa.st' 'bootstrap.st' 'facade.st' 'tests.st')
	do: [:f | Smalltalk fileIn: dir, '/', f]!
SystemMenu add: 'tree browser' receiver: TreeBrowser selector: #open!
