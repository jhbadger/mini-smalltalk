"The primitive words, part two: compiling, control structures, defining words, floating point, the system,
and the bridge to Smalltalk."

!Forth class methodsFor: 'the primitives: compiling'!
defineCompilerWords
	self def: ':' do: [:f | f beginDefinition: (ForthColon named: f needName)].
	self defImmediate: ';' do: [:f | f endDefinition].
	self def: ':NONAME' do: [:f | f beginNoname].
	self def: 'IMMEDIATE' do: [:f | f latest isNil
		ifTrue: [f fail: 'nothing has been defined yet']
		ifFalse: [f latest immediate: true]].
	self defImmediate: '[' do: [:f | f store: 0 at: 2].
	self def: ']' do: [:f | f store: -1 at: 2].
	self defImmediate: 'LITERAL' do: [:f | f needCompiling. f compileLiteral: f pop].
	self defImmediate: '2LITERAL' do: [:f | | hi lo | f needCompiling. hi := f pop. lo := f pop.
		f compileLiteral: lo; compileLiteral: hi].
	self defImmediate: 'FLITERAL' do: [:f | f needCompiling. f compileFloat: f fpop].
	self defImmediate: 'POSTPONE' do: [:f | | w |
		f needCompiling.
		w := f wordNamed: f needName.
		w isImmediate
			ifTrue: [f compile: w]
			ifFalse: [f compile: ((ForthPrimitive named: nil) block: [:g | g compile: w]; yourself)]].
	self def: '''' do: [:f | f push: (f wordNamed: f needName)].
	self defImmediate: '['']' do: [:f | f needCompiling. f compileLiteral: (f wordNamed: f needName)].
	self def: 'EXECUTE' do: [:f | f execute: f pop].
	self def: 'COMPILE,' do: [:f | f needCompiling. f compile: f pop].
	self def: '>BODY' do: [:f | | w | w := f pop.
		(w isKindOf: ForthCreated)
			ifTrue: [f push: w address]
			ifFalse: [f fail: 'that word has no data area' code: -31]].
	self defImmediate: 'RECURSE' do: [:f | f needCompiling. f compile: f currentDefinition].
	self def: 'EXIT' do: [:f | f exitDefinition].
	self defImmediate: '(' do: [:f | f parse: 41].
	self defImmediate: '\' do: [:f | f parse: 10].
	self defImmediate: '.(' do: [:f | f type: (f parse: 41)].
	self defImmediate: '."' do: [:f | | text | text := f parse: 34.
		f compiling ifTrue: [f compile: (ForthText text: text)] ifFalse: [f type: text]].
	self defImmediate: 'S"' do: [:f | | text | text := f parse: 34.
		f compiling
			ifTrue: [f compileLiteral: (f keepString: text); compileLiteral: text size]
			ifFalse: [f pushString: text]].
	self defImmediate: 'ABORT"' do: [:f | | text | f needCompiling. text := f parse: 34.
		f compile: ((ForthPrimitive named: nil) block: [:g |
			g pop = 0 ifFalse: [ForthError code: -2 message: text]]; yourself)].
	self defImmediate: '[IF]' do: [:f | f pop = 0 ifTrue: [f skipConditional: true]].
	self defImmediate: '[ELSE]' do: [:f | f skipConditional: false].
	self defImmediate: '[THEN]' do: [:f | f].
	self defImmediate: '[DEFINED]' do: [:f | f push: (f flag: (f lookup: f needName) notNil)].
	self defImmediate: '[UNDEFINED]' do: [:f | f push: (f flag: (f lookup: f needName) isNil)]! !

!Forth class methodsFor: 'the primitives: control structures'!
defineControlWords
	self defImmediate: 'IF' do: [:f | | cell | f needCompiling.
		cell := ForthJump op: #zbranch. f compile: cell. f openControl: #if with: cell].
	self defImmediate: 'ELSE' do: [:f | | e br | f needCompiling.
		e := f closeControl: #(#if).
		br := ForthJump op: #branch. f compile: br.
		(e at: 2) target: f nextCell.
		f openControl: #else with: br].
	self defImmediate: 'THEN' do: [:f | | e | f needCompiling.
		e := f closeControl: #(#if #else).
		(e at: 2) target: f nextCell].
	self defImmediate: 'BEGIN' do: [:f | f needCompiling. f openControl: #begin with: f nextCell].
	self defImmediate: 'UNTIL' do: [:f | | e | f needCompiling.
		e := f closeControl: #(#begin).
		f compile: ((ForthJump op: #zbranch) target: (e at: 2); yourself)].
	self defImmediate: 'AGAIN' do: [:f | | e | f needCompiling.
		e := f closeControl: #(#begin).
		f compile: ((ForthJump op: #branch) target: (e at: 2); yourself)].
	self defImmediate: 'WHILE' do: [:f | | cell | f needCompiling.
		cell := ForthJump op: #zbranch. f compile: cell. f openControl: #while with: cell].
	self defImmediate: 'REPEAT' do: [:f | | w b | f needCompiling.
		w := f closeControl: #(#while).
		b := f closeControl: #(#begin).
		f compile: ((ForthJump op: #branch) target: (b at: 2); yourself).
		(w at: 2) target: f nextCell].
	self defImmediate: 'DO' do: [:f | f openLoop: #do].
	self defImmediate: '?DO' do: [:f | f openLoop: #qdo].
	self defImmediate: 'LOOP' do: [:f | f closeLoop: #loop].
	self defImmediate: '+LOOP' do: [:f | f closeLoop: #ploop].
	self defImmediate: 'LEAVE' do: [:f | | cell | f needCompiling.
		cell := ForthJump op: #leave. f compile: cell.
		(((f innermost: #do) at: 2) at: 2) add: cell].
	self defImmediate: 'CASE' do: [:f | f needCompiling. f openControl: #case with: OrderedCollection new].
	self defImmediate: 'OF' do: [:f | | cell | f needCompiling.
		cell := ForthJump op: #of. f compile: cell. f openControl: #of with: cell].
	self defImmediate: 'ENDOF' do: [:f | | e br | f needCompiling.
		e := f closeControl: #(#of).
		br := ForthJump op: #branch. f compile: br.
		(e at: 2) target: f nextCell.
		((f innermost: #case) at: 2) add: br].
	self defImmediate: 'ENDCASE' do: [:f | | e | f needCompiling.
		f compile: (f wordNamed: 'DROP').
		e := f closeControl: #(#case).
		(e at: 2) do: [:br | br target: f nextCell]]! !

!Forth class methodsFor: 'the primitives: defining words'!
defineDefiningWords
	self def: 'CREATE' do: [:f | f createWord: f needName].
	self def: 'VARIABLE' do: [:f | f createWord: f needName. f comma: 0].
	self def: 'CONSTANT' do: [:f | | n | n := f needName.
		f enter: ((ForthLiteral value: f pop) name: n; yourself)].
	self def: '2CONSTANT' do: [:f | | n hi lo | n := f needName. hi := f pop. lo := f pop.
		f enter: ((ForthPrimitive named: n) block: [:g | g push: lo; push: hi]; yourself)].
	self def: 'VALUE' do: [:f | | n w | n := f needName.
		w := (ForthValue named: n) address: f here; yourself.
		f comma: f pop.
		f enter: w].
	self defImmediate: 'TO' do: [:f | | w |
		w := f wordNamed: f needName.
		(w isKindOf: ForthValue) ifFalse: [f fail: 'TO needs a name made by VALUE' code: -32].
		f compiling
			ifTrue: [f compile: ((ForthPrimitive named: nil) block: [:g | g store: g pop at: w address]; yourself)]
			ifFalse: [f store: f pop at: w address]].
	self def: 'DEFER' do: [:f | f enter: (ForthDefer named: f needName)].
	self defImmediate: 'IS' do: [:f | | w |
		w := f wordNamed: f needName.
		(w isKindOf: ForthDefer) ifFalse: [f fail: 'IS needs a name made by DEFER' code: -32].
		f compiling
			ifTrue: [f compile: ((ForthPrimitive named: nil) block: [:g | w action: g pop]; yourself)]
			ifFalse: [w action: f pop]].
	self defImmediate: 'ACTION-OF' do: [:f | | w |
		w := f wordNamed: f needName.
		(w isKindOf: ForthDefer) ifFalse: [f fail: 'ACTION-OF needs a name made by DEFER' code: -32].
		f compiling
			ifTrue: [f compile: ((ForthPrimitive named: nil) block: [:g | g push: w action]; yourself)]
			ifFalse: [f push: w action]].
	self def: 'DEFER!!' do: [:f | | d | d := f pop. d action: f pop].
	self def: 'DEFER@' do: [:f | f push: f pop action].
	self defImmediate: 'DOES>' do: [:f | | def k |
		f needCompiling.
		def := f currentDefinition.
		k := f nextCell + 1.
		f compile: ((ForthPrimitive named: nil) block: [:g | g setDoesFor: def from: k]; yourself)].
	self def: 'MARKER' do: [:f | | n saved h |
		n := f needName.
		saved := f dictionary copy.
		h := f here.
		f enter: ((ForthPrimitive named: n) block: [:g | g restoreDictionary: saved here: h]; yourself)]! !

!Forth class methodsFor: 'the primitives: floating point'!
defineFloatWords
	self def: 'F+' do: [:f | | b | b := f fpop. f fpush: f fpop + b].
	self def: 'F-' do: [:f | | b | b := f fpop. f fpush: f fpop - b].
	self def: 'F*' do: [:f | | b | b := f fpop. f fpush: f fpop * b].
	self def: 'F/' do: [:f | | b | b := f fpop. f fpush: f fpop / b].
	self def: 'F**' do: [:f | | b | b := f fpop. f fpush: (f fpop raisedTo: b)].
	self def: 'FNEGATE' do: [:f | f fpush: f fpop negated].
	self def: 'FABS' do: [:f | f fpush: f fpop abs].
	self def: 'FSQRT' do: [:f | f fpush: f fpop sqrt].
	self def: 'FSIN' do: [:f | f fpush: f fpop sin].
	self def: 'FCOS' do: [:f | f fpush: f fpop cos].
	self def: 'FTAN' do: [:f | f fpush: f fpop tan].
	self def: 'FATAN' do: [:f | f fpush: f fpop arcTan].
	self def: 'FEXP' do: [:f | f fpush: f fpop exp].
	self def: 'FLN' do: [:f | f fpush: f fpop ln].
	self def: 'FLOG' do: [:f | f fpush: f fpop ln / 10 ln].
	self def: 'FLOOR' do: [:f | f fpush: f fpop floor asFloat].
	self def: 'FROUND' do: [:f | f fpush: f fpop rounded asFloat].
	self def: 'FTRUNC' do: [:f | f fpush: f fpop truncated asFloat].
	self def: 'FMAX' do: [:f | | b | b := f fpop. f fpush: (f fpop max: b)].
	self def: 'FMIN' do: [:f | | b | b := f fpop. f fpush: (f fpop min: b)].
	self def: 'FDUP' do: [:f | f fpush: f ftop].
	self def: 'FDROP' do: [:f | f fpop].
	self def: 'FSWAP' do: [:f | | b a | b := f fpop. a := f fpop. f fpush: b; fpush: a].
	self def: 'FOVER' do: [:f | | b a | b := f fpop. a := f ftop. f fpush: b; fpush: a].
	self def: 'FROT' do: [:f | | c b a | c := f fpop. b := f fpop. a := f fpop. f fpush: b; fpush: c; fpush: a].
	self def: 'FDEPTH' do: [:f | f push: f fstackList size].
	self def: 'F0<' do: [:f | f push: (f flag: f fpop < 0)].
	self def: 'F0=' do: [:f | f push: (f flag: f fpop = 0)].
	self def: 'F<' do: [:f | | b | b := f fpop. f push: (f flag: f fpop < b)].
	self def: 'F>' do: [:f | | b | b := f fpop. f push: (f flag: f fpop > b)].
	self def: 'F=' do: [:f | | b | b := f fpop. f push: (f flag: f fpop = b)].
	self def: 'F@' do: [:f | f fpush: (f fetch: f popInteger)].
	self def: 'F!!' do: [:f | | a | a := f popInteger. f store: f fpop at: a].
	self alias: 'DF@' for: 'F@'.
	self alias: 'DF!!' for: 'F!!'.
	self def: 'F.' do: [:f | f type: f fpop printString, ' '].
	self def: 'S>F' do: [:f | f fpush: f popInteger asFloat].
	self def: 'D>F' do: [:f | f fpush: f dpop asFloat].
	self def: 'F>S' do: [:f | f push: f fpop truncated].
	self def: 'F>D' do: [:f | f dpush: f fpop truncated].
	self def: 'FLOATS' do: [:f | f].
	self def: 'FLOAT+' do: [:f | f push: f pop + 1].
	self alias: 'DFLOATS' for: 'FLOATS'.
	self alias: 'DFLOAT+' for: 'FLOAT+'.
	self def: 'FVARIABLE' do: [:f | f createWord: f needName. f comma: 0.0].
	self def: 'FCONSTANT' do: [:f | | n | n := f needName.
		f enter: ((ForthFloatLiteral value: f fpop) name: n; yourself)].
	Primitives at: 'PI' put: ((ForthFloatLiteral value: 3.141592653589793) name: 'PI'; yourself)! !

!Forth class methodsFor: 'the primitives: the system'!
defineSystemWords
	self def: 'ABORT' do: [:f | ForthError code: -1 message: 'aborted'].
	self def: 'BYE' do: [:f | ForthStop new signal].
	self def: 'CATCH' do: [:f | f catch: f pop].
	self def: 'THROW' do: [:f | | n | n := f popInteger.
		n = 0 ifFalse: [ForthThrow new code: n; signal: (f messageForCode: n)]].
	self def: 'WORDS' do: [:f | f type: f wordList].
	self def: 'SEE' do: [:f | f type: (f decompile: (f wordNamed: f needName))].
	self def: 'INCLUDED' do: [:f | f includeFile: f popString].
	self def: 'INCLUDE' do: [:f | f includeFile: f needName].
	self alias: 'REQUIRED' for: 'INCLUDED'.
	self alias: 'REQUIRE' for: 'INCLUDE'.
	self def: 'QUIT' do: [:f | ForthStop new signal]! !

!Forth class methodsFor: 'the primitives: the bridge to Smalltalk'!
defineSmalltalkBridge
	self def: 'ST-EVAL' do: [:f | f push: (f evaluateSmalltalk: f popString)].
	self def: 'SEND' do: [:f | f sendMessage].
	self def: '>ST-STRING' do: [:f | f push: f popString].
	self def: 'ST-STRING>' do: [:f | f pushString: f pop asString].
	self def: 'PRINTSTRING' do: [:f | f pushString: f pop printString].
	self def: 'ST-NIL' do: [:f | f push: nil].
	self def: 'ST-NIL?' do: [:f | f push: (f flag: f pop isNil)]! !
