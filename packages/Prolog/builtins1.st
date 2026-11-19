"Prolog built-in predicates, part 1: type tests, comparison, arithmetic, term construction, atoms and strings, lists, the clause database."

!PrologEngine class methodsFor: 'built-in table'!
builtinSpec
	"name arity selector; the selector is sent to the engine with the Array of arguments and answers true or false"
	^#('var' 1 #biVar: 'nonvar' 1 #biNonvar: 'atom' 1 #biAtom: 'number' 1 #biNumber: 'integer' 1 #biInteger: 'float' 1 #biFloat:
	   'atomic' 1 #biAtomic: 'compound' 1 #biCompound: 'callable' 1 #biCallable: 'is_list' 1 #biIsList: 'string' 1 #biString:
	   'ground' 1 #biGround: 'is_assoc' 1 #biFail1:
	   '=' 2 #biUnify: '\=' 2 #biNotUnify: '==' 2 #biIdentical: '\==' 2 #biNotIdentical:
	   '@<' 2 #biTermLess: '@>' 2 #biTermGreater: '@=<' 2 #biTermLessEq: '@>=' 2 #biTermGreaterEq: 'compare' 3 #biCompare:
	   'is' 2 #biIs: '=:=' 2 #biArEq: '=\=' 2 #biArNe: '<' 2 #biArLt: '>' 2 #biArGt: '=<' 2 #biArLe: '>=' 2 #biArGe:
	   'succ' 2 #biSucc: 'plus' 3 #biPlus: 'between' 3 #biBetween:
	   'functor' 3 #biFunctor: 'arg' 3 #biArg: '=..' 2 #biUniv: 'copy_term' 2 #biCopyTerm: 'term_variables' 2 #biTermVariables:
	   'numbervars' 3 #biNumberVars: 'setarg' 3 #biSetArg: 'nb_setarg' 3 #biSetArg:
	   'atom_codes' 2 #biAtomCodes: 'atom_chars' 2 #biAtomChars: 'char_code' 2 #biCharCode: 'atom_length' 2 #biAtomLength:
	   'atom_number' 2 #biAtomNumber: 'number_codes' 2 #biNumberCodes: 'number_chars' 2 #biNumberChars:
	   'atom_string' 2 #biAtomString: 'number_string' 2 #biNumberString: 'term_to_atom' 2 #biTermToAtom: 'term_string' 2 #biTermString: 'atom_to_term' 3 #biAtomToTerm:
	   'upcase_atom' 2 #biUpcaseAtom: 'downcase_atom' 2 #biDowncaseAtom: 'string_upper' 2 #biStringUpper: 'string_lower' 2 #biStringLower:
	   'atom_concat' 3 #biAtomConcat: 'string_concat' 3 #biStringConcat: 'sub_atom' 5 #biSubAtom: 'sub_string' 5 #biSubString:
	   'atomic_list_concat' 2 #biAtomicListConcat2: 'atomic_list_concat' 3 #biAtomicListConcat3: 'split_string' 4 #biSplitString:
	   'string_chars' 2 #biStringChars: 'string_codes' 2 #biStringCodes: 'string_to_atom' 2 #biStringToAtom: 'string_length' 2 #biAtomLength:
	   'string_code' 3 #biStringCode: 'text_to_string' 2 #biTextToString: 'char_type' 2 #biCharType: 'code_type' 2 #biCodeType:
	   'term_to_string' 2 #biTermString: 'text_concat' 3 #biAtomConcat: 'sformat' 3 #biSformat:
	   'msort' 2 #biMsort: 'sort' 2 #biSort2: 'sort' 4 #biSort4: 'keysort' 2 #biKeysort: '$skip_list' 3 #biSkipList:
	   '$bagof_prepare' 4 #biBagofPrepare: '$bagof_group' 2 #biBagofGroup:
	   'assert' 1 #biAssertz: 'assertz' 1 #biAssertz: 'asserta' 1 #biAsserta: 'retract' 1 #biRetract: 'retractall' 1 #biRetractAll:
	   'abolish' 1 #biAbolish: 'clause' 2 #biClause: 'dynamic' 1 #biDynamic: 'discontiguous' 1 #biTrue1: 'multifile' 1 #biTrue1:
	   'ensure_loaded' 1 #biTrue1: 'use_module' 1 #biTrue1: 'use_module' 2 #biTrue2: 'module' 2 #biTrue2: 'style_check' 1 #biTrue1:
	   'set_stream' 2 #biTrue2: 'garbage_collect' 0 #biTrue0: 'prolog_flag' 2 #biTrue2: 'license' 1 #biTrue1:
	   'current_predicate' 1 #biCurrentPredicate: 'predicate_property' 2 #biPredicateProperty:
	   'throw' 1 #biThrow: 'halt' 0 #biHalt0: 'halt' 1 #biHalt1:
	   'consult' 1 #biConsult: 'initialization' 1 #biInitialization:
	   'op' 3 #biOp: 'current_op' 3 #biCurrentOp:
	   'set_prolog_flag' 2 #biSetFlag: 'current_prolog_flag' 2 #biCurrentFlag:
	   'nb_setval' 2 #biSetVal: 'b_setval' 2 #biSetVal: 'nb_getval' 2 #biGetVal: 'b_getval' 2 #biGetVal:
	   'write' 1 #biWrite: 'print' 1 #biPrint: 'writeln' 1 #biWriteln: 'writeq' 1 #biWriteq: 'write_canonical' 1 #biWriteCanonical:
	   'write_term' 2 #biWriteTerm: 'write' 2 #biWrite2: 'writeln' 2 #biWriteln2: 'writeq' 2 #biWrite2q: 'nl' 0 #biNl0: 'nl' 1 #biNl1:
	   'tab' 1 #biTab: 'tab' 2 #biTab2: 'put_char' 1 #biPutChar: 'put_char' 2 #biPutChar2: 'flush_output' 0 #biTrue0: 'flush_output' 1 #biTrue1:
	   'format' 1 #biFormat1: 'format' 2 #biFormat2: 'format' 3 #biFormat3: 'with_output_to' 2 #biWithOutputTo:
	   'read' 1 #biRead: 'read_term' 2 #biReadTerm: 'read' 2 #biRead2: 'read_term' 3 #biReadTerm3:
	   'portray_clause' 1 #biPortrayClause: 'listing' 1 #biListing: 'listing' 0 #biListing0:
	   'statistics' 2 #biStatistics: 'get_time' 1 #biGetTime: 'sleep' 1 #biSleep: 'random' 1 #biRandom: 'random_between' 3 #biRandomBetween:
	   'smalltalk' 2 #biSmalltalk: 'smalltalk' 1 #biSmalltalk1: 'smalltalk_send' 4 #biSmalltalkSend: 'smalltalk_global' 2 #biSmalltalkGlobal: 'smalltalk_ref' 2 #biSmalltalkRef: 'smalltalk_send_ref' 4 #biSmalltalkSendRef:
	   'smalltalk_print' 2 #biSmalltalkPrint:)! !

"---- type tests and unification ----"

!PrologEngine methodsFor: 'type tests'!
biVar: a
	^(a at: 1) plDeref isPrologVar!
biNonvar: a
	^(a at: 1) plDeref isPrologVar not!
biAtom: a
	^(a at: 1) plDeref isSymbol!
biNumber: a
	^(a at: 1) plDeref isNumber!
biInteger: a
	^(a at: 1) plDeref isInteger!
biFloat: a
	^(a at: 1) plDeref isFloat!
biAtomic: a
	| x |
	x := (a at: 1) plDeref.
	^x isPrologVar not and: [x isPrologStruct not]!
biCompound: a
	^(a at: 1) plDeref isPrologStruct!
biCallable: a
	| x |
	x := (a at: 1) plDeref.
	^x isSymbol or: [x isPrologStruct]!
biString: a
	| x |
	x := (a at: 1) plDeref.
	^x isString and: [x isSymbol not]!
biIsList: a
	| t |
	t := (a at: 1) plDeref.
	[t isPrologStruct and: [t isList]] whileTrue: [t := t second plDeref].
	^t == #'[]'!
biGround: a
	^self isGround: (a at: 1)!
isGround: t
	| x |
	x := t plDeref.
	x isPrologVar ifTrue: [^false].
	x isPrologStruct ifFalse: [^true].
	x args do: [:e | (self isGround: e) ifFalse: [^false]].
	^true!
biFail1: a
	^false!
biTrue0: a
	^true!
biTrue1: a
	^true!
biTrue2: a
	^true!
biUnify: a
	^self unify: (a at: 1) with: (a at: 2)!
biNotUnify: a
	| mark ok |
	mark := trail size.
	ok := self unify: (a at: 1) with: (a at: 2).
	self undoTo: mark.
	^ok not! !

!PrologEngine methodsFor: 'standard order'!
rankOf: x
	"the class of a term in the standard order: variables, numbers, atoms, strings, compounds"
	x isPrologVar ifTrue: [^0].
	x isNumber ifTrue: [^1].
	x isSymbol ifTrue: [^3].
	x isString ifTrue: [^4].
	x isPrologStruct ifTrue: [^5].
	^6!
compare: a with: b
	"-1, 0 or 1 in the standard order of terms"
	| x y rx ry c n |
	x := a plDeref. y := b plDeref.
	x == y ifTrue: [^0].
	rx := self rankOf: x. ry := self rankOf: y.
	rx ~= ry ifTrue: [^rx < ry ifTrue: [-1] ifFalse: [1]].
	rx = 0 ifTrue: [^x id < y id ifTrue: [-1] ifFalse: [1]].
	rx = 1 ifTrue: [
		x = y ifTrue: [^x isFloat ifTrue: [y isFloat ifTrue: [0] ifFalse: [-1]] ifFalse: [y isFloat ifTrue: [1] ifFalse: [0]]].
		^x < y ifTrue: [-1] ifFalse: [1]].
	(rx = 3 or: [rx = 4]) ifTrue: [^x asString caseSensitiveCompareTo: y asString].
	rx = 5 ifTrue: [
		x arity ~= y arity ifTrue: [^x arity < y arity ifTrue: [-1] ifFalse: [1]].
		x functor ~~ y functor ifTrue: [^x functor asString caseSensitiveCompareTo: y functor asString].
		1 to: x arity do: [:i |
			c := self compare: (x args at: i) with: (y args at: i).
			c ~= 0 ifTrue: [^c]].
		^0].
	^(x printString caseSensitiveCompareTo: y printString)!
biIdentical: a
	^(self compare: (a at: 1) with: (a at: 2)) = 0!
biNotIdentical: a
	^(self compare: (a at: 1) with: (a at: 2)) ~= 0!
biTermLess: a
	^(self compare: (a at: 1) with: (a at: 2)) < 0!
biTermGreater: a
	^(self compare: (a at: 1) with: (a at: 2)) > 0!
biTermLessEq: a
	^(self compare: (a at: 1) with: (a at: 2)) <= 0!
biTermGreaterEq: a
	^(self compare: (a at: 1) with: (a at: 2)) >= 0!
biCompare: a
	| c o |
	o := (a at: 1) plDeref.
	(o isPrologVar not and: [(#(#< #> #=) includes: o) not]) ifTrue: [^o isSymbol ifTrue: [self domainError: #order culprit: o] ifFalse: [self typeError: #atom culprit: o]].
	c := self compare: (a at: 2) with: (a at: 3).
	^self unify: o with: (c < 0 ifTrue: [#<] ifFalse: [c > 0 ifTrue: [#>] ifFalse: [#'=']])!
variant: a with: b map: map
	"are the two terms equal up to renaming of variables?"
	| x y |
	x := a plDeref. y := b plDeref.
	x isPrologVar ifTrue: [
		y isPrologVar ifFalse: [^false].
		^(map at: x ifAbsent: [map at: x put: y]) == y].
	y isPrologVar ifTrue: [^false].
	x isPrologStruct ifTrue: [
		y isPrologStruct ifFalse: [^false].
		(x functor == y functor and: [x arity = y arity]) ifFalse: [^false].
		1 to: x arity do: [:i | (self variant: (x args at: i) with: (y args at: i) map: map) ifFalse: [^false]].
		^true].
	y isPrologStruct ifTrue: [^false].
	^PrologEngine atomic: x equals: y! !

"---- arithmetic ----"

!PrologEngine class methodsFor: 'arithmetic table'!
arithSpec
	^#('+' 2 #aAdd:with: '-' 2 #aSub:with: '*' 2 #aMul:with: '/' 2 #aDiv:with: '//' 2 #aQuo:with: 'mod' 2 #aMod:with: 'rem' 2 #aRem:with: 'div' 2 #aFloorDiv:with:
	  'min' 2 #aMin:with: 'max' 2 #aMax:with: '**' 2 #aPower:with: '^' 2 #aIntPower:with: 'atan2' 2 #aAtan2:with: 'atan' 2 #aAtan2:with:
	  'gcd' 2 #aGcd:with: '>>' 2 #aShiftRight:with: '<<' 2 #aShiftLeft:with: '/\' 2 #aAnd:with: '\/' 2 #aOr:with: 'xor' 2 #aXor:with: 'log' 2 #aLog2Arg:with:
	  'copysign' 2 #aCopysign:with: 'plus' 2 #aAdd:with:
	  'truncate' 1 #aTruncate: '-' 1 #aNegate: '+' 1 #aIdentity: 'abs' 1 #aAbs: 'sign' 1 #aSign: 'sqrt' 1 #aSqrt: 'sin' 1 #aSin: 'cos' 1 #aCos: 'tan' 1 #aTan:
	  'asin' 1 #aAsin: 'acos' 1 #aAcos: 'atan' 1 #aAtan: 'exp' 1 #aExp: 'log' 1 #aLog: 'log2' 1 #aLog2: 'sinh' 1 #aSinh: 'cosh' 1 #aCosh: 'tanh' 1 #aTanh:
	  'ceiling' 1 #aCeiling: 'floor' 1 #aFloor: 'round' 1 #aRound: 'integer' 1 #aRound: 'float' 1 #aFloat: 'float_integer_part' 1 #aIntegerPart:
	  'float_fractional_part' 1 #aFractionPart: '\' 1 #aBitNot: 'msb' 1 #aMsb: 'succ' 1 #aSucc: 'random' 1 #aRandom: 'cot' 1 #aCot: 'acot' 1 #aAcot:)!
arithSelectors
	"functor -> Array of selectors indexed by arity + 1"
	| spec row |
	ControlTable notNil ifTrue: [^ControlTable].
	spec := self arithSpec.
	ControlTable := Dictionary new.
	1 to: spec size by: 3 do: [:i |
		row := ControlTable at: (spec at: i) asSymbol ifAbsent: [ControlTable at: (spec at: i) asSymbol put: (Array new: 3)].
		row at: (spec at: i + 1) + 1 put: (spec at: i + 2)].
	^ControlTable! !

!PrologEngine methodsFor: 'arithmetic'!
eval: t
	"the value of an arithmetic expression"
	| x row sel n |
	x := t plDeref.
	x isInteger ifTrue: [^x].
	x isFloat ifTrue: [^x].
	x isPrologVar ifTrue: [^self instantiationError].
	x isSymbol ifTrue: [^self evalAtom: x].
	x isPrologStruct ifFalse: [
		(x isString and: [x size = 1]) ifTrue: [^x first value].
		^self typeError: #evaluable culprit: x].
	n := x args size.
	n = 2 ifTrue: [
		| f |
		f := x functor.
		f == #'+' ifTrue: [^(self eval: (x args at: 1)) + (self eval: (x args at: 2))].
		f == #'-' ifTrue: [^(self eval: (x args at: 1)) - (self eval: (x args at: 2))].
		f == #'*' ifTrue: [^(self eval: (x args at: 1)) * (self eval: (x args at: 2))]].
	(x isList and: [(x second plDeref) == #'[]']) ifTrue: [^self eval: x first].
	row := PrologEngine arithSelectors at: x functor ifAbsent: [nil].
	(row isNil or: [n > 2 or: [(row at: n + 1) isNil]]) ifTrue: [^self typeError: #evaluable culprit: (self indicator: x functor arity: n)].
	sel := row at: n + 1.
	n = 1 ifTrue: [^self perform: sel with: (self eval: (x args at: 1))].
	^self perform: sel with: (self eval: (x args at: 1)) with: (self eval: (x args at: 2))!
evalAtom: a
	a == #pi ifTrue: [^Float pi].
	a == #e ifTrue: [^Float e].
	a == #inf ifTrue: [^Float infinity].
	a == #infinite ifTrue: [^Float infinity].
	a == #nan ifTrue: [^Float nan].
	a == #epsilon ifTrue: [^Float epsilon].
	a == #max_tagged_integer ifTrue: [^SmallInteger maxVal].
	a == #min_tagged_integer ifTrue: [^SmallInteger minVal].
	a == #random ifTrue: [^Random default next].
	a == #random_float ifTrue: [^Random default next].
	a == #cputime ifTrue: [^Time millisecondClock / 1000.0].
	a == #realtime ifTrue: [^Smalltalk microsecondClock // 1000000].
	a == #'[]' ifTrue: [^self typeError: #evaluable culprit: a].
	^self typeError: #evaluable culprit: (self indicator: a arity: 0)!
needInteger: x
	x isInteger ifFalse: [^self typeError: #integer culprit: x].
	^x!
aAdd: a with: b
	^a + b!
aSub: a with: b
	^a - b!
aMul: a with: b
	^a * b!
aDiv: a with: b
	b = 0 ifTrue: [^self evaluationError: #zero_divisor].
	(a isInteger and: [b isInteger]) ifTrue: [^a \\ b = 0 ifTrue: [a // b] ifFalse: [a asFloat / b asFloat]].
	^a asFloat / b asFloat!
aQuo: a with: b
	self needInteger: a. self needInteger: b.
	b = 0 ifTrue: [^self evaluationError: #zero_divisor].
	^a quo: b!
aMod: a with: b
	self needInteger: a. self needInteger: b.
	b = 0 ifTrue: [^self evaluationError: #zero_divisor].
	^a \\ b!
aRem: a with: b
	self needInteger: a. self needInteger: b.
	b = 0 ifTrue: [^self evaluationError: #zero_divisor].
	^a rem: b!
aFloorDiv: a with: b
	self needInteger: a. self needInteger: b.
	b = 0 ifTrue: [^self evaluationError: #zero_divisor].
	^a // b!
aMin: a with: b
	^(a <= b) ifTrue: [a] ifFalse: [b]!
aMax: a with: b
	^(a >= b) ifTrue: [a] ifFalse: [b]!
aPower: a with: b
	"**: integer powers of integers stay integers; a negative exponent gives a Float"
	(a isInteger and: [b isInteger]) ifTrue: [
		b >= 0 ifTrue: [^a raisedTo: b].
		a = 0 ifTrue: [^self evaluationError: #zero_divisor].
		^a asFloat raisedTo: b].
	^a asFloat raisedTo: b asFloat!
aIntPower: a with: b
	(a isInteger and: [b isInteger]) ifTrue: [
		b >= 0 ifTrue: [^a raisedTo: b].
		a = 1 ifTrue: [^1].
		a = -1 ifTrue: [^b even ifTrue: [1] ifFalse: [-1]].
		a = 0 ifTrue: [^self evaluationError: #zero_divisor].
		^self typeError: #float culprit: a].
	^a asFloat raisedTo: b asFloat!
aAtan2: a with: b
	^a asFloat arcTan: b asFloat!
aGcd: a with: b
	self needInteger: a. self needInteger: b.
	^a gcd: b!
aShiftRight: a with: b
	self needInteger: a. self needInteger: b.
	^a bitShift: b negated!
aShiftLeft: a with: b
	self needInteger: a. self needInteger: b.
	^a bitShift: b!
aAnd: a with: b
	self needInteger: a. self needInteger: b.
	^a bitAnd: b!
aOr: a with: b
	self needInteger: a. self needInteger: b.
	^a bitOr: b!
aXor: a with: b
	self needInteger: a. self needInteger: b.
	^a bitXor: b!
aLog2Arg: base with: x
	(x <= 0 or: [base <= 0]) ifTrue: [^self evaluationError: #undefined].
	^x ln / base ln!
aCopysign: a with: b
	^a asFloat withSign: b!
aNegate: a
	^a negated!
aIdentity: a
	^a!
aAbs: a
	^a abs!
aSign: a
	^a isInteger ifTrue: [a sign] ifFalse: [a > 0 ifTrue: [1.0] ifFalse: [a < 0 ifTrue: [-1.0] ifFalse: [0.0]]]!
aSqrt: a
	a < 0 ifTrue: [^self evaluationError: #undefined].
	^a asFloat sqrt!
aSin: a
	^a asFloat sin!
aCos: a
	^a asFloat cos!
aTan: a
	^a asFloat tan!
aAsin: a
	(a > 1 or: [a < -1]) ifTrue: [^self evaluationError: #undefined].
	^a asFloat arcSin!
aAcos: a
	(a > 1 or: [a < -1]) ifTrue: [^self evaluationError: #undefined].
	^a asFloat arcCos!
aAtan: a
	^a asFloat arcTan!
aExp: a
	^a asFloat exp!
aLog: a
	a <= 0 ifTrue: [^a = 0 ifTrue: [self evaluationError: #undefined] ifFalse: [self evaluationError: #undefined]].
	^a asFloat ln!
aLog2: a
	a <= 0 ifTrue: [^self evaluationError: #undefined].
	^a asFloat ln / Float ln2!
aSinh: a
	^a asFloat sinh!
aCosh: a
	^a asFloat cosh!
aTanh: a
	^a asFloat tanh!
aCeiling: a
	^a isInteger ifTrue: [a] ifFalse: [a ceiling]!
aFloor: a
	^a isInteger ifTrue: [a] ifFalse: [a floor]!
aRound: a
	^a isInteger ifTrue: [a] ifFalse: [a rounded]!
aTruncate: a
	^a isInteger ifTrue: [a] ifFalse: [a truncated]!
aFloat: a
	^a asFloat!
aIntegerPart: a
	^a truncated asFloat!
aFractionPart: a
	^a - a truncated!
aBitNot: a
	self needInteger: a.
	^a bitInvert!
aMsb: a
	self needInteger: a.
	^a highBit - 1!
aSucc: a
	^a + 1!
aCot: a
	a = 0 ifTrue: [^self evaluationError: #undefined].
	^1 / a asFloat tan!
aAcot: a
	a = 0 ifTrue: [^Float halfPi].
	^(1 / a asFloat) arcTan!
aRandom: a
	self needInteger: a.
	^(Random default nextInt: a) - 1!
biIs: a
	^self unify: (a at: 1) with: (self eval: (a at: 2))!
biArEq: a
	^(self eval: (a at: 1)) = (self eval: (a at: 2))!
biArNe: a
	^(self eval: (a at: 1)) ~= (self eval: (a at: 2))!
biArLt: a
	^(self eval: (a at: 1)) < (self eval: (a at: 2))!
biArGt: a
	^(self eval: (a at: 1)) > (self eval: (a at: 2))!
biArLe: a
	^(self eval: (a at: 1)) <= (self eval: (a at: 2))!
biArGe: a
	^(self eval: (a at: 1)) >= (self eval: (a at: 2))!
biSucc: a
	| x y |
	x := (a at: 1) plDeref. y := (a at: 2) plDeref.
	x isInteger ifTrue: [
		x < 0 ifTrue: [^self typeError: #not_less_than_zero culprit: x].
		^self unify: y with: x + 1].
	y isInteger ifTrue: [
		y < 0 ifTrue: [^self typeError: #not_less_than_zero culprit: y].
		y = 0 ifTrue: [^false].
		^self unify: x with: y - 1].
	(x isPrologVar and: [y isPrologVar]) ifTrue: [^self instantiationError].
	^self typeError: #integer culprit: (x isPrologVar ifTrue: [y] ifFalse: [x])!
biPlus: a
	| x y z |
	x := (a at: 1) plDeref. y := (a at: 2) plDeref. z := (a at: 3) plDeref.
	(x isInteger and: [y isInteger]) ifTrue: [^self unify: z with: x + y].
	(x isInteger and: [z isInteger]) ifTrue: [^self unify: y with: z - x].
	(y isInteger and: [z isInteger]) ifTrue: [^self unify: x with: z - y].
	^self instantiationError!
biBetween: a
	| low high x |
	low := (a at: 1) plDeref. high := (a at: 2) plDeref. x := (a at: 3) plDeref.
	low isPrologVar ifTrue: [^self instantiationError].
	high isPrologVar ifTrue: [^self instantiationError].
	low isInteger ifFalse: [^self typeError: #integer culprit: low].
	(high isInteger or: [high == #inf or: [high == #infinite]]) ifFalse: [^self typeError: #integer culprit: high].
	x isPrologVar ifFalse: [
		x isInteger ifFalse: [^self typeError: #integer culprit: x].
		^x >= low and: [(high isInteger not) or: [x <= high]]].
	^self pushAlternatives: (PrologBetween from: low to: (high isInteger ifTrue: [high] ifFalse: [nil]) var: x)! !

"---- term construction and inspection ----"

!PrologEngine methodsFor: 'terms'!
biFunctor: a
	| t n name args |
	t := (a at: 1) plDeref.
	t isPrologVar ifFalse: [
		t isPrologStruct ifTrue: [^(self unify: (a at: 2) with: t functor) and: [self unify: (a at: 3) with: t arity]].
		^(self unify: (a at: 2) with: t) and: [self unify: (a at: 3) with: 0]].
	name := (a at: 2) plDeref. n := (a at: 3) plDeref.
	(name isPrologVar or: [n isPrologVar]) ifTrue: [^self instantiationError].
	n isInteger ifFalse: [^self typeError: #integer culprit: n].
	n = 0 ifTrue: [^self unify: t with: name].
	name isPrologStruct ifTrue: [^self typeError: #atomic culprit: name].
	name isSymbol ifFalse: [^self typeError: #atom culprit: name].
	n < 0 ifTrue: [^self domainError: #not_less_than_zero culprit: n].
	args := Array new: n.
	1 to: n do: [:i | args at: i put: PrologVar new].
	^self unify: t with: (PrologStruct functor: name args: args)!
biArg: a
	| n t |
	n := (a at: 1) plDeref. t := (a at: 2) plDeref.
	t isPrologStruct ifFalse: [^self typeError: #compound culprit: t].
	n isInteger ifTrue: [
		^(n between: 1 and: t arity) and: [self unify: (a at: 3) with: (t args at: n)]].
	n isPrologVar ifFalse: [^self typeError: #integer culprit: n].
	^self pushAlternatives: (PrologAlts over: (1 to: t arity) asArray do: [:i | (self unify: n with: i) and: [self unify: (a at: 3) with: (t args at: i)]])!
biUniv: a
	| t l items |
	t := (a at: 1) plDeref.
	t isPrologVar ifFalse: [
		t isPrologStruct
			ifTrue: [^self unify: (a at: 2) with: (PrologStruct list: (Array with: t functor), t args)]
			ifFalse: [^self unify: (a at: 2) with: (PrologStruct list: (Array with: t))]].
	l := (a at: 2) plDeref.
	l isPrologVar ifTrue: [^self instantiationError].
	items := self listToArray: l.
	items isEmpty ifTrue: [^self domainError: #non_empty_list culprit: l].
	items size = 1 ifTrue: [^self unify: t with: (items at: 1)].
	(items at: 1) plDeref isSymbol ifFalse: [^(items at: 1) plDeref isPrologVar ifTrue: [self instantiationError] ifFalse: [self typeError: #atom culprit: (items at: 1)]].
	^self unify: t with: (PrologStruct functor: (items at: 1) plDeref args: (items copyFrom: 2 to: items size))!
biCopyTerm: a
	^self unify: (a at: 2) with: (self copyTerm: (a at: 1))!
variablesOf: t into: acc
	| x |
	x := t plDeref.
	x isPrologVar ifTrue: [(acc anySatisfy: [:v | v == x]) ifFalse: [acc add: x]. ^self].
	x isPrologStruct ifTrue: [x args do: [:e | self variablesOf: e into: acc]]!
biTermVariables: a
	| acc |
	acc := OrderedCollection new.
	self variablesOf: (a at: 1) into: acc.
	^self unify: (a at: 2) with: (PrologStruct list: acc)!
biNumberVars: a
	| acc n |
	n := (a at: 2) plDeref.
	n isInteger ifFalse: [^self typeError: #integer culprit: n].
	acc := OrderedCollection new.
	self variablesOf: (a at: 1) into: acc.
	acc do: [:v | self bind: v to: (PrologStruct functor: #'$VAR' with: n). n := n + 1].
	^self unify: (a at: 3) with: n!
biSetArg: a
	| n t |
	n := (a at: 1) plDeref. t := (a at: 2) plDeref.
	(n isInteger and: [t isPrologStruct and: [n between: 1 and: t arity]]) ifFalse: [^false].
	t args at: n put: (self copyTerm: (a at: 3)).
	^true!
listToArray: l
	"the elements of a proper list as an Array"
	| items t |
	items := OrderedCollection new.
	t := l plDeref.
	[t isPrologStruct and: [t isList]] whileTrue: [items add: t first. t := t second plDeref].
	t isPrologVar ifTrue: [^self instantiationError].
	t == #'[]' ifFalse: [^self typeError: #list culprit: l].
	^items asArray!
biSkipList: a
	"'$skip_list'(List, Length, Tail): the number of cells of a (possibly partial) list and what follows them"
	| t n |
	t := (a at: 1) plDeref. n := 0.
	[t isPrologStruct and: [t isList]] whileTrue: [n := n + 1. t := t second plDeref].
	^(self unify: (a at: 2) with: n) and: [self unify: (a at: 3) with: t]! !
