"Downloading sequences from NCBI by accession, as FASTA or GenBank (GenPept for proteins).

	SequenceFetcher fastaFor: 'NM_000518'          the FASTA text
	SequenceFetcher genBankFor: 'NM_000518'        the GenBank flat file text
	SequenceFetcher fetch: 'NM_000518' format: #genbank     parsed, as a SequenceCollection

The Bio class has the short forms (Bio fetch:, Bio fetchGenBank:, Bio download:format:to:). The request goes to NCBI's
E-utilities (efetch) through the system's curl program, so curl must be installed and the machine must be online.
The database (nucleotide or protein) is guessed from the accession and can be given explicitly. Several accessions may
be given at once, separated by commas or as an Array."

Object subclass: #SequenceFetcher instanceVariableNames: '' classVariableNames: 'ApiKey BaseUrl' category: 'Bio-IO'!

!SequenceFetcher class methodsFor: 'settings'!
baseUrl
	^BaseUrl ifNil: [BaseUrl := 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi']!
baseUrl: aString
	"another efetch-compatible server (or a mirror, for testing)"
	BaseUrl := aString!
apiKey
	^ApiKey!
apiKey: aString
	"an NCBI API key raises the permitted request rate from 3 to 10 a second; nil removes it"
	(aString isNil or: [self isSafeToken: aString]) ifFalse: [^BioError new signal: 'an API key is letters and digits only'].
	ApiKey := aString! !

!SequenceFetcher class methodsFor: 'accessions'!
isSafeToken: aString
	^aString notEmpty and: [aString allSatisfy: [:c | c isLetter or: [c isDigit or: [c = $_ or: [c = $. or: [c = $-]]]]]]!
accessionsIn: anObject
	"the accessions as an Array of trimmed Strings: from 'A1, B2', or from a collection of Strings"
	| list |
	list := anObject isString
		ifTrue: [(anObject subStrings: ', ') collect: [:s | s trimBoth]]
		ifFalse: [anObject collect: [:s | s asString trimBoth]].
	list := list reject: [:s | s isEmpty].
	list isEmpty ifTrue: [^BioError new signal: 'no accession given'].
	list do: [:s |
		(self isSafeToken: s)
			ifFalse: [^BioError new signal: 'not an accession: ', s printString, ' (letters, digits, _ . - only)']].
	^list asArray!
isProteinAccession: anAccession
	"a guess from the form of the accession: NP_ XP_ YP_ WP_ AP_ prefixes, three letters and digits (AAA12345),
	and UniProt accessions (O, P or Q first, as P69905)"
	| a letters number |
	a := (anAccession copyUpTo: $.) asUppercase.
	((a startsWith: 'NP_') or: [(a startsWith: 'XP_') or: [(a startsWith: 'YP_') or: [(a startsWith: 'WP_') or: [a startsWith: 'AP_']]]])
		ifTrue: [^true].
	(a includes: $_) ifTrue: [^false].
	letters := 0.
	[letters < a size and: [(a at: letters + 1) isLetter]] whileTrue: [letters := letters + 1].
	number := a copyFrom: letters + 1 to: a size.
	(letters = 3 and: [number size >= 5 and: [number allSatisfy: [:c | c isDigit]]]) ifTrue: [^true].
	(letters = 1 and: [a first = $O or: [a first = $P or: [a first = $Q]]]) ifTrue: [^true].
	^false!
databaseFor: anAccessionList
	"#protein if the first accession looks like a protein one, else #nuccore"
	^(self isProteinAccession: anAccessionList first) ifTrue: [#protein] ifFalse: [#nuccore]! !

!SequenceFetcher class methodsFor: 'urls'!
rettypeFor: aFormat database: aDatabase
	"the efetch rettype: fasta, or gb (nucleotide) / gp (protein) for GenBank"
	(aFormat == #fasta or: [aFormat == #fa]) ifTrue: [^'fasta'].
	(aFormat == #genbank or: [aFormat == #gb or: [aFormat == #genpept]])
		ifTrue: [^aDatabase == #protein ifTrue: ['gp'] ifFalse: ['gb']].
	^BioError new signal: 'unknown format ', aFormat printString, ' (use #fasta or #genbank)'!
urlFor: anAccessionList format: aFormat database: aDatabase
	| db url |
	db := aDatabase ifNil: [self databaseFor: anAccessionList].
	(db == #nuccore or: [db == #protein or: [db == #nucleotide]])
		ifFalse: [^BioError new signal: 'unknown database ', db printString, ' (use #nuccore or #protein)'].
	url := self baseUrl, '?db=', (db == #nucleotide ifTrue: ['nuccore'] ifFalse: [db asString]),
		'&id=', (', ' join: anAccessionList) , '&rettype=', (self rettypeFor: aFormat database: db),
		'&retmode=text'.
	url := url copyReplaceAll: ', ' with: ','.
	ApiKey notNil ifTrue: [url := url, '&api_key=', ApiKey].
	^url! !

!SequenceFetcher class methodsFor: 'fetching'!
textFor: anAccession format: aFormat database: aDatabase
	"the text NCBI answers, checked to be the format asked for; BioError when the accession is unknown or the transfer fails"
	| list url answer text |
	list := self accessionsIn: anAccession.
	url := self urlFor: list format: aFormat database: aDatabase.
	answer := self httpGet: url.
	(answer at: 1) ifFalse: [^BioError new signal: 'could not download ', (', ' join: list), ': ', (answer at: 2)].
	text := answer at: 2.
	(self looksLike: aFormat text: text)
		ifFalse: [^BioError new signal: 'NCBI returned no ', aFormat asString, ' record for ', (', ' join: list),
			(text trimBoth isEmpty ifTrue: [''] ifFalse: [': ', ((text trimBoth copyUpTo: Character lf) truncateTo: 100)])].
	^text!
looksLike: aFormat text: aString
	| t |
	t := aString trimBoth.
	t isEmpty ifTrue: [^false].
	(aFormat == #fasta or: [aFormat == #fa]) ifTrue: [^t first = $>].
	^t startsWith: 'LOCUS'!
fastaFor: anAccession
	^self textFor: anAccession format: #fasta database: nil!
genBankFor: anAccession
	^self textFor: anAccession format: #genbank database: nil!
fetch: anAccession format: aFormat
	"the records, parsed, as a SequenceCollection"
	^self fetch: anAccession format: aFormat database: nil!
fetch: anAccession format: aFormat database: aDatabase
	| text c |
	text := self textFor: anAccession format: aFormat database: aDatabase.
	c := (aFormat == #fasta or: [aFormat == #fa])
		ifTrue: [FastaReader parse: text]
		ifFalse: [GenBankReader parse: text].
	c name: (', ' join: (self accessionsIn: anAccession)).
	^c!
download: anAccession format: aFormat to: aPath
	"save the text NCBI sends, unchanged, in a file; answers the path"
	| text |
	text := self textFor: anAccession format: aFormat database: nil.
	FileStream newFileNamed: aPath do: [:f | f nextPutAll: text].
	^aPath! !

!SequenceFetcher class methodsFor: 'private'!
httpGet: aUrl
	"Array(true, body) or Array(false, message); the transfer is done by curl"
	<primitive: 206>
	^Array with: false with: 'this system cannot fetch URLs'! !
