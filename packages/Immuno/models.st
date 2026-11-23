"The binding models that come with the package: motifs for fifteen class I alleles and five class II alleles.

THESE ARE TEACHING MODELS. Each is written down from the published anchor preferences of the molecule - the
residues that fit its B and F pockets for class I, its P1, P4, P6 and P9 pockets for class II - not trained on
the thousands of measurements a real predictor uses. They find the anchor motif and are good for seeing how
the whole machinery fits together; they will miss what depends on the middle residues, they say nothing
about affinity in nanomolar, and they are not for clinical or research decisions. For those use a trained
predictor such as NetMHCpan or MHCflurry. To get a better model for an allele you know binders of, train one
with BindingMatrix trainOn:name:class: and add it with AlleleModels add:.

Each model is a list of #(position residues enrichment) rows - see BindingMatrix fromMotif:name:class:."

Object subclass: #AlleleModels instanceVariableNames: '' classVariableNames: 'Matrices Extra' category: 'Immuno-Binding'!

!AlleleModels class methodsFor: 'the registry'!
motifs
	"name, class and spec of every built-in model"
	| out |
	out := OrderedCollection new.
	#(#('HLA-A*01:01' 1 #a0101)
		#('HLA-A*02:01' 1 #a0201)
		#('HLA-A*03:01' 1 #a0301)
		#('HLA-A*11:01' 1 #a1101)
		#('HLA-A*24:02' 1 #a2402)
		#('HLA-B*07:02' 1 #b0702)
		#('HLA-B*08:01' 1 #b0801)
		#('HLA-B*15:01' 1 #b1501)
		#('HLA-B*27:05' 1 #b2705)
		#('HLA-B*35:01' 1 #b3501)
		#('HLA-B*40:01' 1 #b4001)
		#('HLA-B*44:02' 1 #b4402)
		#('HLA-B*51:01' 1 #b5101)
		#('HLA-B*57:01' 1 #b5701)
		#('HLA-B*58:01' 1 #b5801)
		#('HLA-DRB1*01:01' 2 #drb10101)
		#('HLA-DRB1*03:01' 2 #drb10301)
		#('HLA-DRB1*04:01' 2 #drb10401)
		#('HLA-DRB1*07:01' 2 #drb10701)
		#('HLA-DRB1*15:01' 2 #drb11501))
		do: [:row | out add: (Array with: (row at: 1) with: (row at: 2) with: (self perform: (row at: 3)))].
	^out asArray!
table
	"name (two fields, with HLA-) to BindingMatrix"
	Matrices isNil ifTrue: [
		Matrices := Dictionary new.
		self motifs do: [:row |
			Matrices at: (row at: 1) put: (BindingMatrix fromMotif: (row at: 3) name: (row at: 1) class: (row at: 2))]].
	Extra isNil ifTrue: [Extra := Dictionary new].
	^Matrices!
add: aMatrix
	"make a matrix you trained answer for its name, replacing a built-in one of the same name"
	self table.
	Extra at: aMatrix name put: aMatrix.
	^aMatrix!
removeAdded
	"forget every matrix added with add:"
	self table.
	Extra := Dictionary new!
alleles
	"the names of every allele with a model, in order"
	| names |
	self table.
	names := Set new.
	Matrices keysDo: [:k | names add: k].
	Extra keysDo: [:k | names add: k].
	^((names collect: [:n | HLAAllele named: n]) asSortedCollection: [:a :b | a <= b]) asArray!
nameOf: anAlleleOrString
	"the two-field name HLA-X*nn:nn under which a model is looked up"
	| a |
	a := anAlleleOrString isString ifTrue: [HLAAllele named: anAlleleOrString] ifFalse: [anAlleleOrString].
	a fieldCount < 2 ifTrue: [^ImmunoError new signal: 'a model needs at least two fields: ', a name].
	^a nameAt: 2!
hasModelFor: anAlleleOrString
	| n |
	n := self nameOf: anAlleleOrString.
	self table.
	^(Extra includesKey: n) or: [Matrices includesKey: n]!
matrixFor: anAlleleOrString
	"the model for an allele, whatever resolution it is named at; an error if there is none"
	| n |
	n := self nameOf: anAlleleOrString.
	self table.
	^Extra at: n ifAbsent: [Matrices at: n ifAbsent: [
		ImmunoError new signal: 'there is no binding model for ', n,
			'; AlleleModels alleles lists the ones there are']]! !

!AlleleModels class methodsFor: 'class I motifs'!
a0101
	^#(#(2 'T' 5) #(2 'S' 4) #(2 'LM' 2) #(2 'DEKRP' 0.3) #(3 'D' 6) #(3 'E' 5) #(7 'L' 2) #(9 'Y' 9) #(9 'FW' 1.5) #(9 'DEKRP' 0.3))!
a0201
	^#(#(2 'L' 8) #(2 'M' 6) #(2 'I' 5) #(2 'V' 4) #(2 'AQT' 2) #(2 'DEKRP' 0.2) #(9 'V' 8) #(9 'L' 7) #(9 'I' 4) #(9 'A' 3) #(9 'M' 2) #(9 'T' 1.5) #(9 'DEKRP' 0.2))!
a0301
	^#(#(2 'L' 5) #(2 'V' 4) #(2 'IM' 3) #(2 'FYT' 2) #(2 'DEP' 0.2) #(3 'FY' 1.5) #(9 'K' 9) #(9 'R' 6) #(9 'Y' 2) #(9 'DEP' 0.2))!
a1101
	^#(#(2 'T' 5) #(2 'V' 3) #(2 'ILM' 2) #(2 'DEP' 0.2) #(9 'K' 10) #(9 'R' 4) #(9 'DEP' 0.2))!
a2402
	^#(#(2 'Y' 9) #(2 'F' 5) #(2 'WM' 2) #(2 'DEKRP' 0.2) #(9 'F' 7) #(9 'L' 7) #(9 'I' 4) #(9 'WM' 3) #(9 'DEKRP' 0.2))!
b0702
	^#(#(1 'R' 2) #(2 'P' 12) #(2 'DE' 0.3) #(9 'L' 6) #(9 'F' 4) #(9 'M' 3) #(9 'VIA' 2) #(9 'DEKR' 0.2))!
b0801
	^#(#(3 'K' 5) #(3 'R' 3) #(5 'K' 5) #(5 'R' 3) #(9 'L' 6) #(9 'IM' 2) #(9 'DEKRP' 0.3))!
b1501
	^#(#(2 'Q' 6) #(2 'K' 3) #(2 'L' 2.5) #(2 'DEP' 0.2) #(9 'Y' 5) #(9 'F' 6) #(9 'L' 3) #(9 'M' 2) #(9 'DEKRP' 0.2))!
b2705
	^#(#(2 'R' 14) #(2 'DEP' 0.2) #(9 'L' 6) #(9 'KR' 3) #(9 'FY' 3) #(9 'M' 2) #(9 'DEP' 0.2))!
b3501
	^#(#(2 'P' 12) #(9 'Y' 6) #(9 'F' 5) #(9 'LM' 4) #(9 'I' 3) #(9 'A' 2) #(9 'DEKR' 0.2))!
b4001
	^#(#(2 'E' 12) #(2 'DKRP' 0.2) #(9 'L' 6) #(9 'VAM' 3) #(9 'I' 2) #(9 'DEKR' 0.2))!
b4402
	^#(#(2 'E' 12) #(2 'DKRP' 0.2) #(9 'Y' 6) #(9 'F' 6) #(9 'W' 3) #(9 'DEKR' 0.2))!
b5101
	^#(#(2 'A' 6) #(2 'P' 5) #(2 'G' 2) #(9 'IV' 6) #(9 'L' 2) #(9 'DEKR' 0.2))!
b5701
	^#(#(2 'A' 5) #(2 'ST' 4) #(2 'DEKRP' 0.2) #(9 'W' 9) #(9 'F' 4) #(9 'LMY' 2) #(9 'DEKRP' 0.2))!
b5801
	^#(#(2 'AST' 5) #(2 'DEKRP' 0.2) #(9 'W' 9) #(9 'F' 4) #(9 'LMY' 2) #(9 'DEKRP' 0.2))! !

!AlleleModels class methodsFor: 'class II motifs'!
drb10101
	"DR1: a large hydrophobic or aromatic residue at P1, a small hydrophobic one at P4, a small one at P6"
	^#(#(1 'YF' 7) #(1 'WL' 6) #(1 'IVM' 4) #(1 'DEKRP' 0.2) #(4 'LIAMV' 3) #(4 'FQ' 2) #(6 'AGSTN' 2.5) #(9 'AL' 2))!
drb10301
	"DR3: P1 aliphatic, P4 acidic, P6 acidic or polar"
	^#(#(1 'L' 5) #(1 'IFYM' 4) #(1 'V' 3) #(1 'DEKRP' 0.2) #(4 'D' 5) #(4 'EQ' 2.5) #(6 'E' 3) #(6 'QN' 2.5) #(9 'YST' 2))!
drb10401
	"DR4: P1 aromatic or aliphatic, P4 acidic or hydrophobic, P6 small polar"
	^#(#(1 'F' 7) #(1 'YW' 5.5) #(1 'LIMV' 4.5) #(1 'DEKRP' 0.2) #(4 'D' 3) #(4 'ELI' 2.5) #(4 'A' 2) #(6 'NSTGQ' 2.5))!
drb10701
	"DR7: P1 aromatic or aliphatic, P4 hydrophobic, P6 asparagine, P9 small"
	^#(#(1 'FY' 6.5) #(1 'WLI' 5) #(1 'VM' 4) #(1 'DEKRP' 0.2) #(4 'IL' 3) #(4 'AFMVG' 2) #(6 'N' 2.5) #(9 'GAS' 2))!
drb11501
	"DR15: P1 aliphatic, P4 hydrophobic, P9 aromatic or aliphatic"
	^#(#(1 'L' 6) #(1 'VI' 5) #(1 'MF' 4) #(1 'DEKRP' 0.2) #(4 'FILVM' 3) #(4 'A' 1.5) #(6 'AGS' 2) #(9 'FYL' 2.5))! !
