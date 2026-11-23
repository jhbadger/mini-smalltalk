"Immuno: computational immunology, focused on MHC - peptides, HLA names, binding models, epitope scanning, antigen processing, population coverage and transplant matching"
| dir |
dir := Smalltalk packagePath: 'Immuno'.
#('peptide.st' 'allele.st' 'matrix.st' 'models.st' 'scan.st' 'processing.st' 'population.st' 'matching.st' 'facade.st')
	do: [:f | Smalltalk fileIn: dir, '/', f]!
SystemMenu add: 'immuno workspace' receiver: ImmunoTool selector: #open!
