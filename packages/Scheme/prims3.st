"The primitive procedures, part 3: hash tables, ports and input/output, the bridge to Smalltalk, and records."

!SchemeTable class methodsFor: 'instance creation'!
new
	^self basicNew setDict!
initMarks
	StringMark isNil ifTrue: [
		StringMark := Object new. FloatMark := Object new. PairMark := Object new. VectorMark := Object new]! !

!SchemeTable methodsFor: 'accessing'!
setDict
	dict := Dictionary new!
keyFor: x
	"what stands for a Scheme key in the Dictionary: equal? keys must be equal there, and 1 and 1.0 must not be"
	| items p |
	x isSymbol ifTrue: [^x].
	x isString ifTrue: [^Array with: StringMark with: (SchemePrims plainString: x)].
	x isFloat ifTrue: [^Array with: FloatMark with: x].
	x class == SchemePair ifTrue: [
		items := OrderedCollection new. p := x.
		items add: PairMark.
		[p class == SchemePair] whileTrue: [items add: (self keyFor: p car). p := p cdr].
		items add: (self keyFor: p).
		^items asArray].
	x class == Array ifTrue: [
		items := OrderedCollection new.
		items add: VectorMark.
		x do: [:e | items add: (self keyFor: e)].
		^items asArray].
	^x!
count
	^dict size!
entryAt: key
	"the (key, value) association, or nil"
	^dict at: (self keyFor: key) ifAbsent: [nil]!
at: key put: value
	| e |
	e := dict at: (self keyFor: key) ifAbsent: [nil].
	e isNil
		ifTrue: [dict at: (self keyFor: key) put: (Association key: key value: value)]
		ifFalse: [e value: value]!
removeKey: key
	dict removeKey: (self keyFor: key) ifAbsent: [nil]!
clear
	dict := Dictionary new!
associations
	^dict values!
copyTable
	| t |
	t := SchemeTable new.
	dict values do: [:a | t at: a key put: a value].
	^t!
printOn: aStream
	aStream nextPutAll: '#[hash-table '; print: dict size; nextPut: $]! !

!SchemePrims class methodsFor: 'tables'!
table: x arg: i to: aName
	x class == SchemeTable ifFalse: [^self wrong: x arg: i to: aName].
	^x!
installTables
	SchemeTable initMarks.
	#('make-equal-hash-table' 'make-strong-eqv-hash-table' 'make-strong-eq-hash-table' 'make-key-weak-eqv-hash-table'
	  'make-key-weak-eq-hash-table' 'make-eqv-hash-table' 'make-eq-hash-table' 'make-string-hash-table' 'make-hash-table')
		do: [:name | Scheme def: name min: 0 max: nil rest: [:args | SchemeTable new]].
	Scheme def: 'hash-table?' do: [:x | x class == SchemeTable].
	Scheme def: 'hash-table-set!!' do: [:t :k :v |
		(SchemePrims table: t arg: 1 to: 'hash-table-set!!') at: k put: v.
		SchemeUnspec].
	Scheme alias: 'hash-table/put!!' for: 'hash-table-set!!'.
	Scheme def: 'hash-table-ref/default' do: [:t :k :default |
		| e |
		e := (SchemePrims table: t arg: 1 to: 'hash-table-ref/default') entryAt: k.
		e isNil ifTrue: [default] ifFalse: [e value]].
	Scheme alias: 'hash-table/get' for: 'hash-table-ref/default'.
	Scheme def: '%hash-table-entry' do: [:t :k |
		| e |
		e := (SchemePrims table: t arg: 1 to: 'hash-table-ref') entryAt: k.
		e isNil ifTrue: [false] ifFalse: [SchemePair car: e key cdr: e value]].
	Scheme def: 'hash-table-delete!!' do: [:t :k |
		(SchemePrims table: t arg: 1 to: 'hash-table-delete!!') removeKey: k.
		SchemeUnspec].
	Scheme alias: 'hash-table/remove!!' for: 'hash-table-delete!!'.
	Scheme def: 'hash-table-contains?' do: [:t :k | ((SchemePrims table: t arg: 1 to: 'hash-table-contains?') entryAt: k) notNil].
	Scheme alias: 'hash-table-exists?' for: 'hash-table-contains?'.
	Scheme def: 'hash-table-count' do: [:t | (SchemePrims table: t arg: 1 to: 'hash-table-count') count].
	Scheme alias: 'hash-table-size' for: 'hash-table-count'.
	Scheme alias: 'hash-table/count' for: 'hash-table-count'.
	Scheme def: 'hash-table-empty?' do: [:t | (SchemePrims table: t arg: 1 to: 'hash-table-empty?') count = 0].
	Scheme def: 'hash-table-keys' do: [:t | SchemePair fromArray: ((SchemePrims table: t arg: 1 to: 'hash-table-keys') associations collect: [:a | a key])].
	Scheme alias: 'hash-table/key-list' for: 'hash-table-keys'.
	Scheme def: 'hash-table-values' do: [:t | SchemePair fromArray: ((SchemePrims table: t arg: 1 to: 'hash-table-values') associations collect: [:a | a value])].
	Scheme alias: 'hash-table/datum-list' for: 'hash-table-values'.
	Scheme def: 'hash-table->alist' do: [:t |
		SchemePair fromArray: ((SchemePrims table: t arg: 1 to: 'hash-table->alist') associations collect: [:a | SchemePair car: a key cdr: a value])].
	Scheme def: 'hash-table-clear!!' do: [:t | (SchemePrims table: t arg: 1 to: 'hash-table-clear!!') clear. SchemeUnspec].
	Scheme alias: 'hash-table/clear!!' for: 'hash-table-clear!!'.
	Scheme def: 'hash-table-copy' min: 1 max: 2 rest: [:args | (SchemePrims table: (args at: 1) arg: 1 to: 'hash-table-copy') copyTable].
	Scheme def: 'alist->hash-table' min: 1 max: nil rest: [:args |
		| t |
		t := SchemeTable new.
		(SchemePrims listArray: (args at: 1) arg: 1 to: 'alist->hash-table') do: [:a |
			a class == SchemePair ifFalse: [SchemePrims wrong: a arg: 1 to: 'alist->hash-table'].
			(t entryAt: a car) isNil ifTrue: [t at: a car put: a cdr]].
		t].
	Scheme def: 'hash' min: 1 max: 2 rest: [:args | (SchemePrinter write: (args at: 1)) hash \\ 1000000007].
	Scheme alias: 'equal-hash' for: 'hash'.
	Scheme alias: 'eq-hash' for: 'hash'.
	Scheme alias: 'eqv-hash' for: 'hash'! !

!SchemePrims class methodsFor: 'ports'!
outPortIn: m args: args at: i to: aName
	"the output port named by the optional argument at i, or the current one"
	| p |
	(args size >= i and: [(args at: i) ~~ SchemeDefault]) ifFalse: [^m outPort].
	p := args at: i.
	p class == SchemeOutPort ifFalse: [^self wrong: p arg: i to: aName].
	^p!
inPortIn: m args: args at: i to: aName
	| p |
	(args size >= i and: [(args at: i) ~~ SchemeDefault]) ifFalse: [^m inPort].
	p := args at: i.
	p class == SchemeInPort ifFalse: [^self wrong: p arg: i to: aName].
	^p!
installIO
	Scheme def: 'display' min: 1 max: 3 value: [:m :args |
		(SchemePrims outPortIn: m args: args at: 2 to: 'display') write: ((args at: 1) == SchemeUnspec ifTrue: [''] ifFalse: [SchemePrinter display: (args at: 1)]).
		SchemeUnspec].
	Scheme def: 'write' min: 1 max: 3 value: [:m :args |
		(SchemePrims outPortIn: m args: args at: 2 to: 'write') write: ((args at: 1) == SchemeUnspec ifTrue: [''] ifFalse: [SchemePrinter write: (args at: 1)]).
		SchemeUnspec].
	Scheme alias: 'write-shared' for: 'write'.
	Scheme alias: 'write-simple' for: 'write'.
	Scheme def: 'write-string' min: 1 max: 4 value: [:m :args |
		SchemePrims str: (args at: 1) arg: 1 to: 'write-string'.
		(SchemePrims outPortIn: m args: args at: 2 to: 'write-string') write: (args at: 1).
		SchemeUnspec].
	Scheme def: 'write-char' min: 1 max: 2 value: [:m :args |
		SchemePrims chr: (args at: 1) arg: 1 to: 'write-char'.
		(SchemePrims outPortIn: m args: args at: 2 to: 'write-char') writeChar: (args at: 1).
		SchemeUnspec].
	Scheme def: 'newline' min: 0 max: 1 value: [:m :args |
		(SchemePrims outPortIn: m args: args at: 1 to: 'newline') writeChar: Character nl.
		SchemeUnspec].
	Scheme def: 'fresh-line' min: 0 max: 1 value: [:m :args |
		| p |
		p := SchemePrims outPortIn: m args: args at: 1 to: 'fresh-line'.
		p atLineStart ifFalse: [p writeChar: Character nl].
		SchemeUnspec].
	Scheme def: 'write-line' min: 1 max: 2 value: [:m :args |
		| p |
		p := SchemePrims outPortIn: m args: args at: 2 to: 'write-line'.
		p write: (SchemePrinter write: (args at: 1)).
		p writeChar: Character nl.
		SchemeUnspec].
	Scheme def: 'pp' min: 1 max: 2 value: [:m :args |
		| p |
		p := SchemePrims outPortIn: m args: args at: 2 to: 'pp'.
		p write: (SchemePrinter write: (args at: 1)).
		p writeChar: Character nl.
		SchemeUnspec].
	Scheme def: 'flush-output' min: 0 max: 1 value: [:m :args | SchemeUnspec].
	Scheme alias: 'flush-output-port' for: 'flush-output'.
	Scheme def: 'open-input-string' do: [:s | SchemeInPort on: (SchemePrims str: s arg: 1 to: 'open-input-string') copy].
	Scheme def: 'open-output-string' min: 0 max: 0 value: [:m :args | SchemeOutPort on: (WriteStream on: String new)].
	Scheme def: 'get-output-string' do: [:p |
		p class == SchemeOutPort ifFalse: [SchemePrims wrong: p arg: 1 to: 'get-output-string'].
		p contents].
	Scheme def: '%swap-output-port!!' min: 1 max: 1 value: [:m :args |
		| old |
		old := m outPort.
		m outParam value: (args at: 1).
		old].
	Scheme def: '%swap-input-port!!' min: 1 max: 1 value: [:m :args |
		| old |
		old := m inPort.
		m inParam value: (args at: 1).
		old].
	Scheme def: 'read-char' min: 0 max: 1 value: [:m :args |
		| c |
		c := (SchemePrims inPortIn: m args: args at: 1 to: 'read-char') next.
		c isNil ifTrue: [SchemeEofObject] ifFalse: [c]].
	Scheme def: 'peek-char' min: 0 max: 1 value: [:m :args |
		| c |
		c := (SchemePrims inPortIn: m args: args at: 1 to: 'peek-char') peek.
		c isNil ifTrue: [SchemeEofObject] ifFalse: [c]].
	Scheme def: 'read-line' min: 0 max: 1 value: [:m :args |
		| s |
		s := (SchemePrims inPortIn: m args: args at: 1 to: 'read-line') readLine.
		s isNil ifTrue: [SchemeEofObject] ifFalse: [s]].
	Scheme def: 'read-string' min: 1 max: 2 value: [:m :args |
		| s k p |
		k := args at: 1. p := args size = 2 ifTrue: [args at: 2] ifFalse: [nil].
		k class == SchemeInPort ifTrue: [p := k. k := args at: 2].
		p isNil ifTrue: [p := m inPort].
		(k isInteger and: [k >= 0]) ifFalse: [SchemePrims wrong: k arg: 1 to: 'read-string'].
		s := p readString: k.
		s isNil ifTrue: [SchemeEofObject] ifFalse: [s]].
	Scheme def: 'char-ready?' min: 0 max: 1 value: [:m :args | true].
	Scheme def: 'read' min: 0 max: 1 value: [:m :args |
		| p r d |
		p := SchemePrims inPortIn: m args: args at: 1 to: 'read'.
		r := SchemeReader on: p text position: p position.
		d := r read.
		p position: r position.
		d].
	Scheme def: 'eof-object' min: 0 max: 0 value: [:m :args | SchemeEofObject].
	Scheme def: 'eof-object?' do: [:x | x == SchemeEofObject].
	Scheme def: 'port?' do: [:x | x class == SchemeInPort or: [x class == SchemeOutPort]].
	Scheme def: 'input-port?' do: [:x | x class == SchemeInPort].
	Scheme def: 'output-port?' do: [:x | x class == SchemeOutPort].
	Scheme alias: 'textual-port?' for: 'port?'.
	Scheme def: 'close-port' do: [:p | p class == SchemeOutPort ifTrue: [p close]. SchemeUnspec].
	Scheme alias: 'close-input-port' for: 'close-port'.
	Scheme alias: 'close-output-port' for: 'close-port'.
	Scheme def: 'open-input-file' do: [:path |
		SchemePrims str: path arg: 1 to: 'open-input-file'.
		[SchemeInPort on: (FileStream contentsOf: path)]
			on: FileError do: [:e | SchemeError new payload: (SchemeCondition message: e messageText irritants: (SchemePair with: path) kind: #file); signal]].
	Scheme def: 'open-output-file' do: [:path | SchemeOutPort toFile: (SchemePrims str: path arg: 1 to: 'open-output-file')].
	Scheme def: 'file-exists?' do: [:path | FileStream exists: (SchemePrims str: path arg: 1 to: 'file-exists?')].
	Scheme def: 'delete-file' do: [:path | FileStream remove: (SchemePrims str: path arg: 1 to: 'delete-file'). SchemeUnspec].
	Scheme def: 'load' min: 1 max: 2 value: [:m :args |
		| text |
		SchemePrims str: (args at: 1) arg: 1 to: 'load'.
		text := [FileStream contentsOf: (args at: 1)]
			on: FileError do: [:e | SchemeError new payload: (SchemeCondition message: e messageText irritants: (SchemePair with: (args at: 1)) kind: #file); signal].
		m evalString: text.
		SchemeUnspec]! !

!SchemePrims class methodsFor: 'bridge'!
selectorFrom: x
	"a Smalltalk selector from a Scheme symbol or string"
	(x isString) ifFalse: [^self wrong: x arg: 2 to: 'st-send'].
	^(self plainString: x) asSymbol!
installBridge
	Scheme def: 'st-eval' do: [:s |
		| r v |
		r := nil evaluateSafely: (SchemePrims str: s arg: 1 to: 'st-eval').
		(r at: 1) ifFalse: [SchemeError message: 'st-eval: ', (r at: 2)].
		v := r at: 2.
		v isNil ifTrue: [SchemeUnspec] ifFalse: [v]].
	Scheme def: 'st-class' do: [:name |
		| c |
		c := name isString
			ifTrue: [Smalltalk at: (SchemePrims plainString: name) asSymbol ifAbsent: [nil]]
			ifFalse: [SchemePrims wrong: name arg: 1 to: 'st-class'].
		c isNil ifTrue: [SchemeError message: 'No Smalltalk class or global named' with: name].
		c].
	Scheme alias: 'st-global' for: 'st-class'.
	Scheme def: 'st-send' min: 2 max: nil rest: [:args |
		| sel rcv v rest |
		sel := SchemePrims selectorFrom: (args at: 2).
		rcv := args at: 1.
		rest := args copyFrom: 3 to: args size.
		sel numArgs = rest size ifFalse: [
			SchemeError message: 'st-send: wrong number of arguments for' with: sel].
		(rcv respondsTo: sel) ifFalse: [SchemeError message: 'Smalltalk object does not understand' with: sel].
		v := rcv perform: sel withArguments: rest.
		v isNil ifTrue: [SchemeUnspec] ifFalse: [v]].
	Scheme def: 'st-new' min: 1 max: nil rest: [:args |
		| c v |
		c := args at: 1.
		c isString ifTrue: [c := Smalltalk at: (SchemePrims plainString: c) asSymbol ifAbsent: [nil]].
		c isNil ifTrue: [SchemeError message: 'No Smalltalk class named' with: (args at: 1)].
		v := args size = 1 ifTrue: [c new] ifFalse: [c perform: (SchemePrims selectorFrom: (args at: 2)) withArguments: (args copyFrom: 3 to: args size)].
		v].
	Scheme def: 'st-class-of' do: [:x | x class].
	Scheme def: 'st-print' do: [:x | x printString].
	Scheme def: 'st->list' do: [:x |
		x isNil ifTrue: [SchemeNil] ifFalse: [
			x class == SchemePair ifTrue: [x] ifFalse: [
				x == SchemeNil ifTrue: [x] ifFalse: [SchemePair fromArray: x asArray]]]].
	Scheme def: 'st-nil?' do: [:x | x isNil].
	Scheme def: 'st-object?' do: [:x |
		(x isNumber or: [x isString or: [x isCharacter or: [x == true or: [x == false or: [x class == Array]]]]]) not and: [
			(x class name startsWith: 'Scheme') not]]! !

!SchemePrims class methodsFor: 'records'!
installRecords
	Scheme def: '%make-record-type' do: [:name :fields |
		| text |
		text := SchemePrims plainString: name.
		(text size > 2 and: [text first = $< and: [text last = $>]]) ifTrue: [text := text copyFrom: 2 to: text size - 1].
		SchemeRecordType name: text fields: (SchemePrims listArray: fields arg: 2 to: 'make-record-type') copy].
	Scheme alias: 'make-record-type' for: '%make-record-type'.
	Scheme def: '%record-constructor' do: [:type :names |
		| idx n size p |
		idx := (SchemePrims listArray: names arg: 2 to: 'record-constructor') collect: [:f | type indexOf: f].
		n := idx size. size := type fields size.
		p := SchemePrimitive name: type name min: n max: n kind: #rest block: [:args |
			| vals |
			vals := Array new: size withAll: false.
			1 to: n do: [:i | vals at: (idx at: i) put: (args at: i)].
			SchemeRecord type: type values: vals].
		p].
	Scheme def: '%record-predicate' do: [:type |
		SchemePrimitive name: type name, '?' min: 1 max: 1 kind: #fixed block: [:x | x class == SchemeRecord and: [x type == type]]].
	Scheme def: '%record-accessor' do: [:type :field |
		| i pname |
		i := type indexOf: field.
		pname := type name, '-', field asString.
		SchemePrimitive name: pname min: 1 max: 1 kind: #fixed block: [:r |
			(r class == SchemeRecord and: [r type == type]) ifFalse: [SchemePrims wrong: r arg: 1 to: pname].
			r at: i]].
	Scheme def: '%record-modifier' do: [:type :field |
		| i pname |
		i := type indexOf: field.
		pname := 'set-', type name, '-', field asString, '!!'.
		SchemePrimitive name: pname min: 2 max: 2 kind: #fixed block: [:r :v |
			(r class == SchemeRecord and: [r type == type]) ifFalse: [SchemePrims wrong: r arg: 1 to: pname].
			r at: i put: v.
			SchemeUnspec]].
	Scheme def: 'record?' do: [:x | x class == SchemeRecord]! !

!Scheme methodsFor: 'ports'!
outParam
	^outParam!
inParam
	^inParam! !
