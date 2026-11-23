"The primitive words, part one: the stacks, arithmetic, logic, memory, printing, strings and numeric output.
Each is a block that is given the Forth system; none of them uses ^, since a block's return would be
from a method that has long since finished."

!Forth class methodsFor: 'the primitives'!
primitives
	"the words every Forth system starts with (a Dictionary of upper-case name -> word)"
	Primitives isNil ifTrue: [self buildPrimitives].
	^Primitives!
buildPrimitives
	Primitives := Dictionary new.
	self defineStackWords.
	self defineArithmetic.
	self defineDoubles.
	self defineMemory.
	self definePrinting.
	self defineStrings.
	self defineNumberFormatting.
	self defineCompilerWords.
	self defineControlWords.
	self defineDefiningWords.
	self defineFloatWords.
	self defineSystemWords.
	self defineSmalltalkBridge!
def: aName do: aBlock
	| w |
	w := (ForthPrimitive named: aName) block: aBlock; yourself.
	Primitives at: aName asUppercase put: w.
	^w!
defImmediate: aName do: aBlock
	^(self def: aName do: aBlock) immediate: true; yourself!
alias: aName for: anotherName
	Primitives at: aName asUppercase put: (Primitives at: anotherName asUppercase)!
defConstant: aName value: x
	Primitives at: aName asUppercase put: ((ForthLiteral value: x) name: aName; yourself)! !

!Forth class methodsFor: 'the primitives: stacks'!
defineStackWords
	self def: 'DUP' do: [:f | f push: f top].
	self def: 'DROP' do: [:f | f pop].
	self def: 'SWAP' do: [:f | | b a | b := f pop. a := f pop. f push: b; push: a].
	self def: 'OVER' do: [:f | | b a | b := f pop. a := f top. f push: b; push: a].
	self def: 'ROT' do: [:f | | c b a | c := f pop. b := f pop. a := f pop. f push: b; push: c; push: a].
	self def: '-ROT' do: [:f | | c b a | c := f pop. b := f pop. a := f pop. f push: c; push: a; push: b].
	self def: 'NIP' do: [:f | | b | b := f pop. f pop. f push: b].
	self def: 'TUCK' do: [:f | | b a | b := f pop. a := f pop. f push: b; push: a; push: b].
	self def: '?DUP' do: [:f | | x | x := f top. x = 0 ifFalse: [f push: x]].
	self def: 'DEPTH' do: [:f | f push: f depth].
	self def: 'PICK' do: [:f | | n | n := f popInteger. f push: (f pickAt: n)].
	self def: 'ROLL' do: [:f | f roll: f popInteger].
	self def: '2DUP' do: [:f | | b a | b := f pop. a := f pop. f push: a; push: b; push: a; push: b].
	self def: '2DROP' do: [:f | f pop. f pop].
	self def: '2SWAP' do: [:f | | d c b a | d := f pop. c := f pop. b := f pop. a := f pop.
		f push: c; push: d; push: a; push: b].
	self def: '2OVER' do: [:f | | d c b a | d := f pop. c := f pop. b := f pop. a := f pop.
		f push: a; push: b; push: c; push: d; push: a; push: b].
	self def: '2ROT' do: [:f | | x6 x5 x4 x3 x2 x1 | x6 := f pop. x5 := f pop. x4 := f pop. x3 := f pop. x2 := f pop. x1 := f pop.
		f push: x3; push: x4; push: x5; push: x6; push: x1; push: x2].
	self def: 'CLEARSTACK' do: [:f | f clear].
	self def: '>R' do: [:f | f rpush: f pop].
	self def: 'R>' do: [:f | f push: f rpop].
	self def: 'R@' do: [:f | f push: f rtop].
	self def: '2>R' do: [:f | | b a | b := f pop. a := f pop. f rpush: a; rpush: b].
	self def: '2R>' do: [:f | | b a | b := f rpop. a := f rpop. f push: a; push: b].
	self def: '2R@' do: [:f | | b a | b := f rpop. a := f rpop. f rpush: a; rpush: b. f push: a; push: b].
	self def: 'I' do: [:f | f push: (f loopIndex: 0)].
	self def: 'J' do: [:f | f push: (f loopIndex: 1)].
	self def: 'K' do: [:f | f push: (f loopIndex: 2)].
	self def: 'UNLOOP' do: [:f | f unloop]! !

!Forth class methodsFor: 'the primitives: arithmetic'!
defineArithmetic
	self def: '+' do: [:f | | b | b := f pop. f push: f pop + b].
	self def: '-' do: [:f | | b | b := f pop. f push: f pop - b].
	self def: '*' do: [:f | | b | b := f pop. f push: f pop * b].
	self def: '/' do: [:f | | b a | b := f pop. a := f pop. f push: a // (f divisor: b)].
	self def: 'MOD' do: [:f | | b a | b := f pop. a := f pop. f push: a \\ (f divisor: b)].
	self def: '/MOD' do: [:f | | b a | b := f pop. a := f pop. f divisor: b. f push: a \\ b; push: a // b].
	self def: '*/' do: [:f | | c b a | c := f pop. b := f pop. a := f pop. f push: a * b // (f divisor: c)].
	self def: '*/MOD' do: [:f | | c b a | c := f pop. b := f pop. a := f pop. f divisor: c.
		f push: a * b \\ c; push: a * b // c].
	self def: 'NEGATE' do: [:f | f push: f pop negated].
	self def: 'ABS' do: [:f | f push: f pop abs].
	self def: 'MIN' do: [:f | | b | b := f pop. f push: (f pop min: b)].
	self def: 'MAX' do: [:f | | b | b := f pop. f push: (f pop max: b)].
	self def: '1+' do: [:f | f push: f pop + 1].
	self def: '1-' do: [:f | f push: f pop - 1].
	self def: '2*' do: [:f | f push: f pop * 2].
	self def: '2/' do: [:f | f push: f pop // 2].
	self def: 'LSHIFT' do: [:f | | n | n := f popInteger. f push: (f popInteger bitShift: n)].
	self def: 'RSHIFT' do: [:f | | n x | n := f popInteger. x := f popInteger.
		x < 0 ifTrue: [x := x + Forth two64].
		f push: (x bitShift: n negated)].
	self def: 'AND' do: [:f | | b | b := f popInteger. f push: (f popInteger bitAnd: b)].
	self def: 'OR' do: [:f | | b | b := f popInteger. f push: (f popInteger bitOr: b)].
	self def: 'XOR' do: [:f | | b | b := f popInteger. f push: (f popInteger bitXor: b)].
	self def: 'INVERT' do: [:f | f push: -1 - f popInteger].
	self def: '=' do: [:f | | b | b := f pop. f push: (f flag: f pop = b)].
	self def: '<>' do: [:f | | b | b := f pop. f push: (f flag: f pop ~= b)].
	self def: '<' do: [:f | | b | b := f pop. f push: (f flag: f pop < b)].
	self def: '>' do: [:f | | b | b := f pop. f push: (f flag: f pop > b)].
	self def: '<=' do: [:f | | b | b := f pop. f push: (f flag: f pop <= b)].
	self def: '>=' do: [:f | | b | b := f pop. f push: (f flag: f pop >= b)].
	self def: 'U<' do: [:f | | b | b := f popInteger \\ Forth two64. f push: (f flag: f popInteger \\ Forth two64 < b)].
	self def: 'U>' do: [:f | | b | b := f popInteger \\ Forth two64. f push: (f flag: f popInteger \\ Forth two64 > b)].
	self def: '0=' do: [:f | f push: (f flag: f pop = 0)].
	self def: '0<>' do: [:f | f push: (f flag: f pop ~= 0)].
	self def: '0<' do: [:f | f push: (f flag: f pop < 0)].
	self def: '0>' do: [:f | f push: (f flag: f pop > 0)].
	self def: 'WITHIN' do: [:f | | hi lo n |
		hi := f popInteger. lo := f popInteger. n := f popInteger.
		f push: (f flag: (n - lo \\ Forth two64) < (hi - lo \\ Forth two64))].
	self defConstant: 'TRUE' value: -1.
	self defConstant: 'FALSE' value: 0.
	self def: 'RANDOM' do: [:f | f push: (Forth random: f popInteger)].
	self def: 'SQRT' do: [:f | | n | n := f popInteger. f push: (Forth integerSqrt: n)]! !

!Forth class methodsFor: 'the primitives: double-length'!
defineDoubles
	self def: 'S>D' do: [:f | f dpush: f popInteger].
	self def: 'D>S' do: [:f | f push: ((f splitDouble: f dpop) at: 1)].
	self def: 'M*' do: [:f | | b | b := f popInteger. f dpush: f popInteger * b].
	self def: 'UM*' do: [:f | | b | b := f popInteger \\ Forth two64. f dpush: (f popInteger \\ Forth two64) * b].
	self def: 'M+' do: [:f | | n | n := f popInteger. f dpush: f dpop + n].
	self def: 'D+' do: [:f | | b | b := f dpop. f dpush: f dpop + b].
	self def: 'D-' do: [:f | | b | b := f dpop. f dpush: f dpop - b].
	self def: 'DNEGATE' do: [:f | f dpush: f dpop negated].
	self def: 'DABS' do: [:f | f dpush: f dpop abs].
	self def: 'D2*' do: [:f | f dpush: f dpop * 2].
	self def: 'D2/' do: [:f | f dpush: f dpop // 2].
	self def: 'D0=' do: [:f | f push: (f flag: f dpop = 0)].
	self def: 'D0<' do: [:f | f push: (f flag: f dpop < 0)].
	self def: 'D=' do: [:f | | b | b := f dpop. f push: (f flag: f dpop = b)].
	self def: 'D<' do: [:f | | b | b := f dpop. f push: (f flag: f dpop < b)].
	self def: 'DMAX' do: [:f | | b | b := f dpop. f dpush: (f dpop max: b)].
	self def: 'DMIN' do: [:f | | b | b := f dpop. f dpush: (f dpop min: b)].
	self def: 'FM/MOD' do: [:f | | n d | n := f divisor: f popInteger. d := f dpop. f push: d \\ n; push: d // n].
	self def: 'SM/REM' do: [:f | | n d | n := f divisor: f popInteger. d := f dpop. f push: (d rem: n); push: (d quo: n)].
	self def: 'UM/MOD' do: [:f | | n d | n := f divisor: f popInteger \\ Forth two64. d := f dpop \\ (Forth two64 * Forth two64).
		f push: d \\ n; push: d // n].
	self def: '2@' do: [:f | | a | a := f popInteger. f push: (f fetch: a + 1); push: (f fetch: a)].
	self def: '2!!' do: [:f | | a | a := f popInteger. f store: f pop at: a. f store: f pop at: a + 1].
	self def: '2VARIABLE' do: [:f | | w | w := f createWord: f needName. f comma: 0; comma: 0]! !

!Forth class methodsFor: 'the primitives: memory'!
defineMemory
	self def: '@' do: [:f | f push: (f fetch: f popInteger)].
	self def: '!!' do: [:f | | a | a := f popInteger. f store: f pop at: a].
	self def: '+!!' do: [:f | | a | a := f popInteger. f store: (f fetch: a) + f pop at: a].
	self alias: 'C@' for: '@'.
	self alias: 'C!!' for: '!!'.
	self def: ',' do: [:f | f comma: f pop].
	self alias: 'C,' for: ','.
	self def: 'HERE' do: [:f | f push: f here].
	self def: 'ALLOT' do: [:f | f allot: f popInteger].
	self def: 'UNUSED' do: [:f | f push: 1000000].
	self def: 'ALIGN' do: [:f | f].
	self def: 'ALIGNED' do: [:f | f].
	self def: 'CELLS' do: [:f | f].
	self alias: 'CHARS' for: 'CELLS'.
	self def: 'CELL+' do: [:f | f push: f pop + 1].
	self alias: 'CHAR+' for: 'CELL+'.
	self def: 'FILL' do: [:f | | x n a | x := f pop. n := f popInteger. a := f popInteger.
		0 to: n - 1 do: [:i | f store: x at: a + i]].
	self def: 'MOVE' do: [:f | | n dst src | n := f popInteger. dst := f popInteger. src := f popInteger.
		f moveCells: n from: src to: dst].
	self alias: 'CMOVE' for: 'MOVE'.
	self alias: 'CMOVE>' for: 'MOVE'.
	self def: 'ALLOCATE' do: [:f | | n | n := f popInteger. f push: f here; push: 0. f allot: n].
	self def: 'FREE' do: [:f | f pop. f push: 0].
	self def: 'BUFFER:' do: [:f | | n | n := f popInteger. f createWord: f needName. f allot: n]! !

!Forth class methodsFor: 'the primitives: printing'!
definePrinting
	self def: '.' do: [:f | f type: (f numberString: f pop), ' '].
	self def: 'U.' do: [:f | f type: (f unsignedString: f popInteger), ' '].
	self def: '.R' do: [:f | | w s | w := f popInteger. s := f numberString: f pop.
		f spaces: w - s size. f type: s].
	self def: 'U.R' do: [:f | | w s | w := f popInteger. s := f unsignedString: f popInteger.
		f spaces: w - s size. f type: s].
	self def: 'D.' do: [:f | f type: (f numberString: f dpop), ' '].
	self def: 'D.R' do: [:f | | w s | w := f popInteger. s := f numberString: f dpop.
		f spaces: w - s size. f type: s].
	self def: 'CR' do: [:f | f type: (String with: Character lf)].
	self def: 'SPACE' do: [:f | f type: ' '].
	self def: 'SPACES' do: [:f | f spaces: f popInteger].
	self def: 'EMIT' do: [:f | f emit: f popInteger].
	self def: 'TYPE' do: [:f | f type: f popString].
	self def: '.S' do: [:f | f type: f stackText].
	self def: '.FS' do: [:f | f type: f floatStackText].
	self def: 'PAGE' do: [:f | f type: (String with: Character lf)].
	self def: 'KEY' do: [:f | f push: f nextKey].
	self def: 'ACCEPT' do: [:f | | n a line m |
		n := f popInteger. a := f popInteger.
		line := f nextInputLine ifNil: [''].
		m := line size min: n.
		f storeString: (line copyFrom: 1 to: m) at: a.
		f push: m]! !

!Forth class methodsFor: 'the primitives: strings'!
defineStrings
	self def: 'COUNT' do: [:f | | a | a := f popInteger. f push: a + 1; push: (f fetch: a)].
	self def: 'COMPARE' do: [:f | | b a |
		b := f popString. a := f popString. f push: (Forth compare: a with: b)].
	self def: 'SEARCH' do: [:f | | pattern text at u1 a1 |
		pattern := f popString.
		u1 := f popInteger. a1 := f popInteger.
		text := f stringAt: a1 length: u1.
		at := Forth indexOf: pattern in: text.
		at = 0
			ifTrue: [f push: a1; push: u1; push: 0]
			ifFalse: [f push: a1 + at - 1; push: u1 - at + 1; push: -1]].
	self def: '/STRING' do: [:f | | n u a | n := f popInteger. u := f popInteger. a := f popInteger.
		f push: a + n; push: u - n].
	self def: '-TRAILING' do: [:f | | u a |
		u := f popInteger. a := f popInteger.
		[u > 0 and: [(f fetch: a + u - 1) = 32]] whileTrue: [u := u - 1].
		f push: a; push: u].
	self defConstant: 'BL' value: 32.
	self defConstant: '>IN' value: 1.
	self defConstant: 'STATE' value: 2.
	self defConstant: 'BASE' value: 3.
	self defConstant: 'PAD' value: Forth padAddress.
	self def: 'HEX' do: [:f | f store: 16 at: 3].
	self def: 'DECIMAL' do: [:f | f store: 10 at: 3].
	self def: 'CHAR' do: [:f | f push: f needName first asInteger].
	self defImmediate: '[CHAR]' do: [:f | f needCompiling. f compileLiteral: f needName first asInteger].
	self def: 'WORD' do: [:f | f push: (f countedString: (f parseWord: f popInteger))].
	self def: 'PARSE' do: [:f | f pushString: (f parse: f popInteger)].
	self def: 'PARSE-NAME' do: [:f | f pushString: (f parseName ifNil: [''])].
	self def: 'FIND' do: [:f | | a w |
		a := f popInteger.
		w := f lookup: (f stringAt: a + 1 length: (f fetch: a)).
		w isNil
			ifTrue: [f push: a; push: 0]
			ifFalse: [f push: w; push: (w isImmediate ifTrue: [1] ifFalse: [-1])]].
	self def: 'EVALUATE' do: [:f | f evaluate: f popString].
	self def: 'SOURCE' do: [:f | | s n |
		s := f source. n := s size min: Forth tibSize.
		f storeString: (s copyFrom: 1 to: n) at: Forth tibStart.
		f push: Forth tibStart; push: n].
	self def: '>NUMBER' do: [:f | | u a d base v |
		u := f popInteger. a := f popInteger. d := f dpop. base := f base.
		[u > 0 and: [(v := f digitValue: (Character value: (f fetch: a)) in: base) >= 0]] whileTrue: [
			d := d * base + v. a := a + 1. u := u - 1].
		f dpush: d. f push: a; push: u]! !

!Forth class methodsFor: 'the primitives: numeric output'!
defineNumberFormatting
	self def: '<#' do: [:f | f startHold].
	self def: 'HOLD' do: [:f | f hold: f popInteger].
	self def: '#' do: [:f | | d b |
		b := f base. d := f dpop. f hold: (Forth digitCode: d \\ b). f dpush: d // b].
	self def: '#S' do: [:f | | d b |
		b := f base. d := f dpop.
		[f hold: (Forth digitCode: d \\ b). d := d // b. d > 0] whileTrue.
		f dpush: d].
	self def: 'SIGN' do: [:f | f pop < 0 ifTrue: [f hold: 45]].
	self def: '#>' do: [:f | f dpop. f pushString: f holdText]! !
