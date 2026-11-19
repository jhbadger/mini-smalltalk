"Prolog format/2: the directives ~w ~p ~q ~a ~d ~D ~s ~e ~f ~g ~n ~c ~r ~R ~i ~* ~~ and the column stops ~t ~| ~+"

Object subclass: #PrologFormatter instanceVariableNames: 'engine args ai out fills lastStop' classVariableNames: '' category: 'Prolog-Builtins'!

!PrologFormatter class methodsFor: 'instance creation'!
engine: anEngine args: argsTerm
	^self basicNew setEngine: anEngine args: argsTerm! !

!PrologFormatter methodsFor: 'private'!
setEngine: anEngine args: argsTerm
	| v |
	engine := anEngine.
	v := argsTerm plDeref.
	args := (v == #'[]' or: [v isPrologStruct and: [v isList]]) ifTrue: [engine listToArray: v] ifFalse: [Array with: v].
	ai := 0.
	out := WriteStream on: String new.
	fills := OrderedCollection new.
	lastStop := 0!
fail: aMessage
	^engine formatError: aMessage!
nextArg
	ai := ai + 1.
	ai > args size ifTrue: [^self fail: 'not enough arguments'].
	^args at: ai!
nextInteger
	| v |
	v := self nextArg plDeref.
	v isInteger ifFalse: [^self fail: 'integer argument expected'].
	^v!
lineText
	^out contents! !

!PrologFormatter methodsFor: 'running'!
run: fmt
	| i n c numArg |
	i := 1. n := fmt size.
	[i <= n] whileTrue: [
		c := fmt at: i.
		i := i + 1.
		c ~= $~
			ifTrue: [out nextPut: c]
			ifFalse: [
				i > n ifTrue: [^self fail: 'truncated format specification'].
				numArg := nil.
				c := fmt at: i.
				c = $* ifTrue: [numArg := self nextInteger. i := i + 1]
				ifFalse: [
					c = $` ifTrue: [numArg := (fmt at: i + 1) value. i := i + 2]
					ifFalse: [
						c isDigit ifTrue: [
							numArg := 0.
							[i <= n and: [(fmt at: i) isDigit]] whileTrue: [numArg := numArg * 10 + (fmt at: i) digitValue. i := i + 1]]]].
				i > n ifTrue: [^self fail: 'truncated format specification'].
				c := fmt at: i.
				i := i + 1.
				self directive: c numArg: numArg]].
	ai < args size ifTrue: [^self fail: 'too many arguments'].
	^out contents!
directive: c numArg: numArg
	c = $w ifTrue: [^out nextPutAll: (engine textOf: self nextArg quoted: false)].
	(c = $p or: [c = $q]) ifTrue: [^out nextPutAll: (engine textOf: self nextArg quoted: true)].
	(c = $a or: [c = $s]) ifTrue: [^out nextPutAll: (engine textFor: self nextArg)].
	c = $n ifTrue: [^(numArg ifNil: [1]) timesRepeat: [out nextPut: Character lf]].
	c = $~ ifTrue: [^out nextPut: $~].
	c = $i ifTrue: [^self nextArg].
	c = $c ifTrue: [^self charDirective: numArg].
	(c = $d or: [c = $D]) ifTrue: [^self integerDirective: c numArg: numArg].
	(c = $f or: [c = $e or: [c = $g]]) ifTrue: [^self floatDirective: c numArg: numArg].
	(c = $r or: [c = $R]) ifTrue: [^self radixDirective: c numArg: numArg].
	c = $t ifTrue: [^fills add: (Array with: out contents size with: (numArg ifNil: [32]))].
	(c = $| or: [c = $+]) ifTrue: [^self columnStop: c numArg: numArg].
	^self fail: 'unknown directive ~', (String with: c)!
charDirective: numArg
	| code |
	code := engine eval: self nextArg.
	(numArg ifNil: [1]) timesRepeat: [out nextPutAll: (Character value: code) utf8Encoded]!
integerDirective: c numArg: numArg
	| v text dot |
	v := self nextArg plDeref.
	v isInteger ifFalse: [v := engine eval: v. v isInteger ifFalse: [^self fail: '~d expects an integer argument']].
	text := engine formatFloat: v digits: (numArg ifNil: [0]).
	c = $D ifTrue: [
		dot := text indexOf: $..
		text := dot = 0
			ifTrue: [engine groupDigits: text]
			ifFalse: [(engine groupDigits: (text copyFrom: 1 to: dot - 1)), (text copyFrom: dot to: text size)]].
	out nextPutAll: text!
floatDirective: c numArg: numArg
	| v |
	v := engine eval: self nextArg.
	c = $f ifTrue: [^out nextPutAll: (engine formatFloat: v digits: (numArg ifNil: [6]))].
	c = $e ifTrue: [^out nextPutAll: (engine formatExp: v digits: (numArg ifNil: [6]))].
	out nextPutAll: v printString!
radixDirective: c numArg: numArg
	| v text |
	v := engine eval: self nextArg.
	v isInteger ifFalse: [^self fail: '~r expects an integer argument'].
	text := v printString: (numArg ifNil: [8]).
	out nextPutAll: (c = $r ifTrue: [text asLowercase] ifFalse: [text])!
columnStop: c numArg: numArg
	"~N| pads to column N, ~N+ to N columns after the previous stop; the fill points set by ~t take the padding"
	| soFar lineStart cur target pad |
	soFar := out contents.
	lineStart := (soFar lastIndexOf: Character lf) + 1.
	cur := soFar size - lineStart + 1.
	target := c = $|
		ifTrue: [numArg ifNil: [cur]]
		ifFalse: [lastStop + (numArg ifNil: [8])].
	pad := target - cur.
	pad > 0 ifTrue: [
		fills isEmpty ifTrue: [fills add: (Array with: soFar size with: 32)].
		out := WriteStream on: String new.
		out nextPutAll: (self apply: fills pad: pad to: soFar)].
	lastStop := pad > 0 ifTrue: [target] ifFalse: [cur].
	fills := OrderedCollection new!
apply: points pad: pad to: text
	"insert pad fill characters at the fill points, spread evenly (the remainder goes to the last)"
	| k each extra result last pos |
	k := points size.
	each := pad // k. extra := pad \\ k.
	result := WriteStream on: String new.
	last := 0.
	points doWithIndex: [:f :idx |
		pos := f at: 1.
		result nextPutAll: (text copyFrom: last + 1 to: pos).
		result nextPutAll: (String new: each + (idx = k ifTrue: [extra] ifFalse: [0]) withAll: (Character value: (f at: 2))).
		last := pos].
	result nextPutAll: (text copyFrom: last + 1 to: text size).
	^result contents! !
