"Antigen processing: what happens to a peptide before it can meet an MHC molecule.

A protein is cut by the proteasome, the pieces are carried into the endoplasmic reticulum by the transporter TAP,
trimmed there at the amino end, and only then offered to class I. A peptide that would bind perfectly but is never
made, or is cut in half on the way, is never presented. These models are the two crude rules that capture most of
what is known: the proteasome cuts after large hydrophobic residues (and, less, basic ones) and not before a
proline, and TAP prefers peptides ending in a hydrophobic or basic residue and refuses those ending in P, D or E.

Like the binding models these are rules of thumb written from the published preferences, not trained
predictors, and their scores are in bits so that they can be added to a binding score."

Object subclass: #AntigenProcessing instanceVariableNames: '' classVariableNames: 'Cleavage CleavageNext Transport' category: 'Immuno-Processing'!

!AntigenProcessing class methodsFor: 'the rules'!
cleavageBefore
	"the score for cutting after a residue (it is P1 of the cleavage site), in bits"
	^Cleavage ifNil: [Cleavage := self tableFrom: #(#($L 1.5) #($F 1.5) #($Y 1.2) #($M 1.2) #($W 1.0) #($I 1.0)
		#($V 0.8) #($K 0.5) #($R 0.5) #($A 0.3) #($D -0.5) #($E -0.5) #($P -1.0))]!
cleavageAfter
	"the score for cutting in front of a residue (P1 prime): nothing cuts before a proline"
	^CleavageNext ifNil: [CleavageNext := self tableFrom: #(#($P -3.0) #($D -0.5) #($E -0.5))]!
transport
	"the TAP score for the last residue of a peptide, in bits"
	^Transport ifNil: [Transport := self tableFrom: #(#($F 1.5) #($Y 1.5) #($W 1.2) #($L 1.2) #($M 1.0) #($I 1.0)
		#($V 1.0) #($R 0.8) #($K 0.8) #($A 0.3) #($G -0.5) #($E -1.0) #($D -1.5) #($P -2.0))]!
tableFrom: pairs
	| d |
	d := Dictionary new.
	pairs do: [:pair | d at: (pair at: 1) put: (pair at: 2)].
	^d! !

!AntigenProcessing class methodsFor: 'cleavage'!
cleavageScoreAfter: i in: aProtein
	"the score for the proteasome cutting between residue i and residue i + 1 of the protein, in bits;
	the end of the protein is a free cut"
	| s |
	s := aProtein asString.
	i >= s size ifTrue: [^1.0].
	^(self cleavageBefore at: (s at: i) ifAbsent: [0.0]) + (self cleavageAfter at: (s at: i + 1) ifAbsent: [0.0])!
cleavageProfile: aProtein
	"the cleavage score after every residue, as an Array"
	| s |
	s := aProtein asString.
	^(1 to: s size) collect: [:i | self cleavageScoreAfter: i in: s]!
cleavageSites: aProtein
	"the positions after which the proteasome is likely to cut (a score of 1.5 bits or more)"
	^((1 to: aProtein asString size) select: [:i | (self cleavageScoreAfter: i in: aProtein) >= 1.5]) asArray! !

!AntigenProcessing class methodsFor: 'transport'!
transportScore: aPeptide
	"how well TAP carries a peptide, from its last residue and a penalty for a proline near the amino end"
	| p n |
	p := aPeptide asPeptide.
	n := self transport at: p last ifAbsent: [0.0].
	1 to: (3 min: p size) do: [:i | (p at: i) = $P ifTrue: [n := n - 0.5]].
	^n! !

!AntigenProcessing class methodsFor: 'together'!
processingScoreOf: aPeptide at: start in: aProtein
	"the score, in bits, for the peptide at position start in the protein being made and carried: the cleavage
	that frees its carboxyl end, less a quarter bit for every strong cut inside it that would destroy it, plus
	the transport score"
	| p end n |
	p := aPeptide asPeptide.
	end := start + p size - 1.
	n := (self cleavageScoreAfter: end in: aProtein) + (self transportScore: p).
	start to: end - 1 do: [:i |
		(self cleavageScoreAfter: i in: aProtein) >= 1.5 ifTrue: [n := n - 0.25]].
	^n!
presentationScoreOf: aPrediction in: aProtein
	"the binding score plus the processing score, in bits; a prediction made by scanning knows where it starts"
	^aPrediction score + (self processingScoreOf: aPrediction peptide at: aPrediction position in: aProtein)!
rank: aScanResult
	"the predictions of a scan as an Array of #(prediction presentationScore), best first; this puts the binders
	that are also likely to be made and carried above the ones that fit the groove but would never get there"
	| rows |
	rows := aScanResult predictions collect: [:p |
		Array with: p with: (self presentationScoreOf: p in: aScanResult protein)].
	^(rows asSortedCollection: [:a :b | (a at: 2) >= (b at: 2)]) asArray! !
