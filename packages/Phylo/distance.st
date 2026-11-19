"Distances: the models that turn a pair of aligned sequences into a number, and the square symmetric
DistanceMatrix the tree builders work from.

A model counts only the columns where both sequences have an unambiguous residue - pairwise deletion - so two
sequences are compared over whatever they share. Where a correction has no answer because the sequences are too
far apart for it (the logarithm would be of something not positive) the model answers its maximumDistance and
says so through sawSaturation, rather than failing."

Object subclass: #DistanceModel instanceVariableNames: 'maximumDistance sawSaturation' classVariableNames: '' category: 'Phylo-Distances'!
DistanceModel subclass: #PDistanceModel instanceVariableNames: '' classVariableNames: '' category: 'Phylo-Distances'!
DistanceModel subclass: #JukesCantorModel instanceVariableNames: '' classVariableNames: '' category: 'Phylo-Distances'!
DistanceModel subclass: #Kimura2ParameterModel instanceVariableNames: '' classVariableNames: '' category: 'Phylo-Distances'!
DistanceModel subclass: #TamuraNeiModel instanceVariableNames: '' classVariableNames: '' category: 'Phylo-Distances'!
DistanceModel subclass: #PoissonModel instanceVariableNames: '' classVariableNames: '' category: 'Phylo-Distances'!
DistanceModel subclass: #KimuraProteinModel instanceVariableNames: '' classVariableNames: '' category: 'Phylo-Distances'!
Object subclass: #DistanceMatrix instanceVariableNames: 'labels rows' classVariableNames: '' category: 'Phylo-Distances'!

"---- the models ----"

!DistanceModel class methodsFor: 'instance creation'!
new
	^self basicNew setUp!
named: aName
	"p, jc69, k2p, tn93, poisson or kimura; also their longer names"
	| key |
	key := aName asString asLowercase.
	(key = 'p' or: [key = 'pdistance' or: [key = 'p-distance' or: [key = 'uncorrected']]])
		ifTrue: [^PDistanceModel new].
	(key = 'jc' or: [key = 'jc69' or: [key = 'jukes-cantor' or: [key = 'jukescantor']]])
		ifTrue: [^JukesCantorModel new].
	(key = 'k2p' or: [key = 'k80' or: [key = 'kimura2' or: [key = 'kimura2p']]])
		ifTrue: [^Kimura2ParameterModel new].
	(key = 'tn93' or: [key = 'tamura-nei' or: [key = 'tamuranei']])
		ifTrue: [^TamuraNeiModel new].
	key = 'poisson' ifTrue: [^PoissonModel new].
	(key = 'kimura' or: [key = 'kimura-protein']) ifTrue: [^KimuraProteinModel new].
	^PhyloError new signal: 'no distance model named ', aName printString!
all
	^Array with: PDistanceModel new with: JukesCantorModel new with: Kimura2ParameterModel new
		with: PoissonModel new!
names
	^#('p' 'jc69' 'k2p' 'tn93' 'poisson' 'kimura')! !

!DistanceModel methodsFor: 'private'!
setUp
	maximumDistance := 10.0.
	sawSaturation := false! !

!DistanceModel methodsFor: 'accessing'!
name
	^self subclassResponsibility!
shortName
	^self subclassResponsibility!
isForProtein
	^false!
maximumDistance
	"what the model answers when the correction has no answer"
	^maximumDistance!
maximumDistance: aNumber
	maximumDistance := aNumber!
sawSaturation
	"true when some pair was too far apart for the correction to be worked out"
	^sawSaturation!
resetSaturation
	sawSaturation := false!
printOn: aStream
	aStream nextPutAll: self name! !

!DistanceModel methodsFor: 'counting'!
isGap: aCharacter
	^aCharacter = $- or: [aCharacter = $. or: [aCharacter = $~ or: [aCharacter = $?]]]!
isUsable: aCharacter
	"a residue the model can count: not a gap and not an ambiguity code"
	(self isGap: aCharacter) ifTrue: [^false].
	self isForProtein
		ifTrue: [^aCharacter asUppercase ~= $X and: [aCharacter isLetter]]
		ifFalse: [^'ACGTU' includes: aCharacter asUppercase]!
isTransition: a and: b
	"A<->G or C<->T, the changes that happen more often"
	| x y |
	x := a asUppercase. y := b asUppercase.
	x = $U ifTrue: [x := $T]. y = $U ifTrue: [y := $T].
	(x = $A and: [y = $G]) ifTrue: [^true].
	(x = $G and: [y = $A]) ifTrue: [^true].
	(x = $C and: [y = $T]) ifTrue: [^true].
	(x = $T and: [y = $C]) ifTrue: [^true].
	^false!
same: a and: b
	| x y |
	x := a asUppercase. y := b asUppercase.
	x = $U ifTrue: [x := $T]. y = $U ifTrue: [y := $T].
	^x = y!
countsFor: aString and: anotherString
	"an Array of the usable columns, the differences, the transitions and the transversions"
	| sites diffs ts tv n a b |
	n := aString size min: anotherString size.
	sites := 0. diffs := 0. ts := 0. tv := 0.
	1 to: n do: [:i |
		a := aString at: i.
		b := anotherString at: i.
		((self isUsable: a) and: [self isUsable: b]) ifTrue: [
			sites := sites + 1.
			(self same: a and: b) ifFalse: [
				diffs := diffs + 1.
				self isForProtein ifFalse: [
					(self isTransition: a and: b) ifTrue: [ts := ts + 1] ifFalse: [tv := tv + 1]]]]].
	^Array with: sites with: diffs with: ts with: tv! !

!DistanceModel methodsFor: 'distances'!
distanceBetween: aString and: anotherString
	"the two must already be aligned, so that column i of one answers to column i of the other"
	^self fromCounts: (self countsFor: aString asString and: anotherString asString)!
fromCounts: counts
	^self subclassResponsibility!
saturated
	sawSaturation := true.
	^maximumDistance!
comparedSitesBetween: aString and: anotherString
	^(self countsFor: aString asString and: anotherString asString) first! !

!PDistanceModel methodsFor: 'distances'!
name
	^'uncorrected p-distance'!
shortName
	^'p'!
fromCounts: counts
	| sites |
	sites := counts at: 1.
	sites = 0 ifTrue: [^self saturated].
	^(counts at: 2) / sites asFloat! !

!JukesCantorModel methodsFor: 'distances'!
name
	^'Jukes-Cantor (1969)'!
shortName
	^'jc69'!
fromCounts: counts
	"d = -3/4 ln(1 - 4p/3)"
	| p inside |
	(counts at: 1) = 0 ifTrue: [^self saturated].
	p := (counts at: 2) / (counts at: 1) asFloat.
	inside := 1.0 - (4.0 * p / 3.0).
	inside <= 0.0 ifTrue: [^self saturated].
	^-0.75 * inside ln! !

!Kimura2ParameterModel methodsFor: 'distances'!
name
	^'Kimura two-parameter (1980)'!
shortName
	^'k2p'!
fromCounts: counts
	"d = -1/2 ln(1 - 2P - Q) - 1/4 ln(1 - 2Q), with P the transitions and Q the transversions"
	| sites pp qq first second |
	sites := counts at: 1.
	sites = 0 ifTrue: [^self saturated].
	pp := (counts at: 3) / sites asFloat.
	qq := (counts at: 4) / sites asFloat.
	first := 1.0 - (2.0 * pp) - qq.
	second := 1.0 - (2.0 * qq).
	(first <= 0.0 or: [second <= 0.0]) ifTrue: [^self saturated].
	^(-0.5 * first ln) - (0.25 * second ln)! !

!TamuraNeiModel methodsFor: 'distances'!
name
	^'Tamura-Nei, equal base frequencies'!
shortName
	^'tn93'!
fromCounts: counts
	"the three-parameter form with equal base frequencies, which keeps the two kinds of transition apart
	from the transversions; with equal frequencies it reduces to Kimura two-parameter"
	| sites pp qq first second |
	sites := counts at: 1.
	sites = 0 ifTrue: [^self saturated].
	pp := (counts at: 3) / sites asFloat.
	qq := (counts at: 4) / sites asFloat.
	first := 1.0 - (2.0 * pp) - qq.
	second := 1.0 - (2.0 * qq).
	(first <= 0.0 or: [second <= 0.0]) ifTrue: [^self saturated].
	^(-0.5 * first ln) - (0.25 * second ln)! !

!PoissonModel methodsFor: 'distances'!
name
	^'Poisson correction (protein)'!
shortName
	^'poisson'!
isForProtein
	^true!
fromCounts: counts
	"d = -ln(1 - p)"
	| p |
	(counts at: 1) = 0 ifTrue: [^self saturated].
	p := (counts at: 2) / (counts at: 1) asFloat.
	p >= 1.0 ifTrue: [^self saturated].
	^(1.0 - p) ln negated! !

!KimuraProteinModel methodsFor: 'distances'!
name
	^'Kimura protein correction (1983)'!
shortName
	^'kimura'!
isForProtein
	^true!
fromCounts: counts
	"d = -ln(1 - p - 0.2 p^2), Kimura's quick stand-in for a PAM distance"
	| p inside |
	(counts at: 1) = 0 ifTrue: [^self saturated].
	p := (counts at: 2) / (counts at: 1) asFloat.
	inside := 1.0 - p - (0.2 * p * p).
	inside <= 0.0 ifTrue: [^self saturated].
	^inside ln negated! !

"---- the matrix ----"

!DistanceMatrix class methodsFor: 'instance creation'!
labels: someLabels
	"an empty square matrix of zeroes"
	^self basicNew setLabels: someLabels!
labels: someLabels rows: someRows
	^self basicNew setLabels: someLabels rows: someRows!
fromAlignment: anAlignment model: aModel
	"the distances between every pair of rows of a multiple alignment"
	| model m rows labels |
	model := aModel isString ifTrue: [DistanceModel named: aModel] ifFalse: [aModel].
	labels := anAlignment labels.
	rows := anAlignment rows collect: [:each | each asString].
	m := self labels: labels.
	1 to: labels size do: [:i |
		i + 1 to: labels size do: [:j |
			m at: i and: j put: (model distanceBetween: (rows at: i) and: (rows at: j))]].
	^m!
fromAlignment: anAlignment
	"Jukes-Cantor for nucleotides, the Poisson correction for protein"
	^self fromAlignment: anAlignment
		model: (anAlignment isProtein ifTrue: [PoissonModel new] ifFalse: [JukesCantorModel new])!
fromPhylip: aString
	"read the square or lower-triangular form PHYLIP writes"
	| lines n m labels values parts |
	lines := (aString lines) reject: [:each | each trimBoth isEmpty].
	lines isEmpty ifTrue: [^PhyloError new signal: 'the distance matrix is empty'].
	n := lines first trimBoth asInteger.
	n isNil ifTrue: [^PhyloError new signal: 'the first line should be the number of taxa'].
	labels := OrderedCollection new.
	values := OrderedCollection new.
	2 to: n + 1 do: [:k |
		k > lines size ifTrue: [^PhyloError new signal: 'the matrix stops after ', (k - 2) printString, ' rows'].
		parts := (lines at: k) substrings.
		labels add: parts first.
		values add: ((parts copyFrom: 2 to: parts size) collect: [:each | each asNumber])].
	m := self labels: labels asArray.
	1 to: n do: [:i |
		1 to: ((values at: i) size min: n) do: [:j |
			i = j ifFalse: [m at: i and: j put: ((values at: i) at: j)]]].
	^m!
readFrom: aPath
	(FileStream exists: aPath) ifFalse: [^PhyloError new signal: 'no such file: ', aPath].
	^self fromPhylip: (FileStream contentsOf: aPath)! !

!DistanceMatrix methodsFor: 'private'!
setLabels: someLabels
	labels := someLabels asArray collect: [:each | each asString].
	rows := (1 to: labels size) collect: [:i | Array new: labels size withAll: 0].
	^self!
setLabels: someLabels rows: someRows
	labels := someLabels asArray collect: [:each | each asString].
	rows := someRows asArray collect: [:each | each asArray].
	^self! !

!DistanceMatrix methodsFor: 'accessing'!
labels
	^labels!
size
	^labels size!
labelAt: i
	^labels at: i!
indexOf: aLabel
	^labels indexOf: aLabel asString ifAbsent: [0]!
at: i and: j
	^(rows at: i) at: j!
at: i and: j put: aNumber
	"the matrix is symmetric, so both halves are set"
	(rows at: i) at: j put: aNumber.
	(rows at: j) at: i put: aNumber.
	^aNumber!
between: aLabel and: anotherLabel
	| i j |
	i := self indexOf: aLabel.
	j := self indexOf: anotherLabel.
	(i = 0 or: [j = 0]) ifTrue: [^PhyloError new signal: 'no such taxon in the matrix'].
	^self at: i and: j!
rowAt: i
	^(rows at: i) copy!
rows
	^rows!
asArray
	^rows collect: [:each | each copy]! !

!DistanceMatrix methodsFor: 'measuring'!
isEmpty
	^labels isEmpty!
notEmpty
	^labels notEmpty!
maximum
	| best |
	best := 0.
	1 to: self size do: [:i | i + 1 to: self size do: [:j | best := best max: (self at: i and: j)]].
	^best!
minimum
	| best |
	self size < 2 ifTrue: [^0].
	best := nil.
	1 to: self size do: [:i | i + 1 to: self size do: [:j |
		(best isNil or: [(self at: i and: j) < best]) ifTrue: [best := self at: i and: j]]].
	^best!
mean
	| total n |
	total := 0. n := 0.
	1 to: self size do: [:i | i + 1 to: self size do: [:j | total := total + (self at: i and: j). n := n + 1]].
	^n = 0 ifTrue: [0] ifFalse: [total / n asFloat]!
closestPair
	"the indices of the two taxa with the smallest distance between them"
	| best pair |
	best := nil. pair := nil.
	1 to: self size do: [:i | i + 1 to: self size do: [:j |
		(best isNil or: [(self at: i and: j) < best])
			ifTrue: [best := self at: i and: j. pair := Array with: i with: j]]].
	^pair!
isSymmetric
	1 to: self size do: [:i | 1 to: self size do: [:j |
		((self at: i and: j) - (self at: j and: i)) abs > 0.000001 ifTrue: [^false]]].
	^true! !

!DistanceMatrix methodsFor: 'transforming'!
copy
	^DistanceMatrix labels: labels rows: self asArray!
withoutIndex: anIndex
	| keep |
	keep := (1 to: self size) reject: [:i | i = anIndex].
	^self keepIndices: keep!
withoutTaxon: aLabel
	| i |
	i := self indexOf: aLabel.
	i = 0 ifTrue: [^self copy].
	^self withoutIndex: i!
keepIndices: someIndices
	| out n |
	n := someIndices size.
	out := DistanceMatrix labels: (someIndices collect: [:i | labels at: i]).
	1 to: n do: [:a | a + 1 to: n do: [:b |
		out at: a and: b put: (self at: (someIndices at: a) and: (someIndices at: b))]].
	^out!
keepTaxa: someLabels
	| wanted |
	wanted := someLabels collect: [:each | each asString].
	^self keepIndices: ((1 to: self size) select: [:i | wanted includes: (labels at: i)])! !

!DistanceMatrix methodsFor: 'building trees'!
neighbourJoining
	^NeighbourJoining on: self!
nj
	^self neighbourJoining!
upgma
	^UPGMA on: self!
wpgma
	^UPGMA new weighted: true; build: self! !

!DistanceMatrix methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a DistanceMatrix('; print: self size; nextPutAll: ' taxa)'!
asPhylip
	"the square form PHYLIP and friends read"
	| out width |
	out := WriteStream on: String new.
	out print: self size; nl.
	width := 10.
	labels do: [:each | width := width max: each size + 1].
	1 to: self size do: [:i |
		out nextPutAll: ((labels at: i), (String new: (width - (labels at: i) size max: 1) withAll: (Character value: 32))).
		1 to: self size do: [:j |
			out nextPutAll: ((self at: i and: j) asFloat printShowingDecimalPlaces: 5); nextPut: (Character value: 32)].
		out nl].
	^out contents!
writeTo: aPath
	FileStream newFileNamed: aPath do: [:f | f nextPutAll: self asPhylip].
	^aPath!
asText
	"the lower triangle, which is all there is to see"
	| out width |
	out := WriteStream on: String new.
	width := 8.
	labels do: [:each | width := width max: each size].
	width := width min: 20.
	out nextPutAll: (String new: width + 1 withAll: (Character value: 32)).
	1 to: self size do: [:j | out nextPutAll: (self pad: ((labels at: j) truncateTo: 9) to: 10)].
	out nl.
	1 to: self size do: [:i |
		out nextPutAll: (self pad: ((labels at: i) truncateTo: width) to: width + 1).
		1 to: i - 1 do: [:j |
			out nextPutAll: (self pad: ((self at: i and: j) asFloat printShowingDecimalPlaces: 5) to: 10)].
		out nl].
	^out contents!
pad: aString to: aWidth
	^aString, (String new: (aWidth - aString size max: 1) withAll: (Character value: 32))!
report
	| out |
	out := WriteStream on: String new.
	out print: self size; nextPutAll: ' taxa'; nl; nl.
	out nextPutAll: self asText; nl.
	self size > 1 ifTrue: [
		out nextPutAll: 'smallest '; nextPutAll: (self minimum asFloat printShowingDecimalPlaces: 5);
			nextPutAll: ', largest '; nextPutAll: (self maximum asFloat printShowingDecimalPlaces: 5);
			nextPutAll: ', mean '; nextPutAll: (self mean asFloat printShowingDecimalPlaces: 5); nl].
	^out contents! !
