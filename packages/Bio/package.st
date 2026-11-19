"Bio: bioinformatics - FASTA, FASTQ and GenBank files, sequence analysis, pairwise alignment and a sequence browser"
| dir |
dir := Smalltalk packagePath: 'Bio'.
#('extend.st' 'sequence.st' 'code.st' 'record.st' 'fasta.st' 'genbank.st' 'analysis.st' 'align.st' 'facade.st' 'prolog.st')
	do: [:f | Smalltalk fileIn: dir, '/', f]!
SystemMenu add: 'sequence browser' receiver: SequenceBrowser selector: #open!
