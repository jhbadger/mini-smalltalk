"The Forth tutorial: the stack, arithmetic, defining words, printing, decisions and loops, variables and
memory, strings, defining words that define words, extending the compiler, the outer interpreter, errors, doubles
and floats, the bridge to Smalltalk, and some programs.  Start it with   ForthTutorial go"

AbstractTutorial subclass: #ForthTutorial instanceVariableNames: '' classVariableNames: '' category: 'Forth'!

!ForthTutorial class methodsFor: 'the lessons'!
tutorialName
	^'Forth'!
lessonSelectors
	^#(#welcome #theStack #arithmetic #definitions #printing #decisions
		#loops #variables #memory #strings #definingwords #compiling
		#reading #errors #numbers #smalltalk #workspace #programs
		#whatNext)! !

!ForthTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'This is a language with almost no syntax. A Forth program is a stream of words
separated by spaces, and the words work on a stack of numbers. To add 2 and 3
you do not write 2 + 3: you put 2 and 3 on the stack, and then run the word +,
which takes the top two numbers and leaves their sum.

This is a Forth system inside Smalltalk. Everything in this tutorial is live:
select a line and press ctrl-P (print it) to run it.

The message eval: sent to Forth runs some Forth and answers whatever it printed.
The word . prints the number on top of the stack, followed by a space:

Forth reset
Forth eval: ''2 3 + .''
Forth eval: ''2 3 + 4 * .''
Forth eval: ''10 2 / .''

There are no parentheses and no precedence: the words run in the order they are
written, so  2 3 + 4 *  is (2 + 3) * 4. This way of writing is called postfix,
or reverse Polish.

What sets Forth apart is that you grow the language by defining new words, and
a word of yours is indistinguishable from a built-in one. Even the compiler is
made of words, and you can add to it. By the end of this tutorial you will have
done all of that.

The system keeps what you define between calls (it lives in Forth default), so
each lesson starts with Forth reset to forget the last one''s definitions and
leave you with a clean stack. Jump to any lesson you like.'!
theStack
	^TutorialLesson title: 'The stack' text:
'Every word takes its arguments from the stack and leaves its results there. The
stack is last in, first out. Numbers you type are pushed on it. The word .s
shows the whole stack without disturbing it, with the depth in angle brackets
and the top of the stack on the right:

Forth reset
Forth eval: ''1 2 3 .s''
Forth eval: ''.s''

The second one printed the same stack, because .s changes nothing. The word .
on the other hand takes the top number off and prints it:

Forth eval: ''.''
Forth eval: ''.''
Forth eval: ''.s''

When a word needs more than the stack holds you get an error, not a crash, and
the stack is emptied so you can start again:

Forth reset
[Forth eval: ''.''] on: ForthError do: [:e | e messageText]

The words that rearrange the stack are the first ones to learn. The comment in
brackets, called a stack effect, says what a word takes (before the two dashes)
and what it leaves (after them):

dup   ( a -- a a )         copy the top
drop  ( a -- )             throw the top away
swap  ( a b -- b a )       exchange the top two
over  ( a b -- a b a )     copy the second one to the top
rot   ( a b c -- b c a )   bring the third one to the top

Forth stackAfter: ''1 2 3 dup''
Forth stackAfter: ''1 2 3 drop''
Forth stackAfter: ''1 2 swap''
Forth stackAfter: ''1 2 over''
Forth stackAfter: ''1 2 3 rot''

stackAfter: runs the Forth in a brand new system and answers the stack, bottom
first, as an Array. Others to look up when you need them: nip tuck -rot ?dup
pick roll depth 2dup 2drop 2swap 2over.

Forth stackAfter: ''10 20 30 2 pick''
Forth stackAfter: ''1 2 3 4 5 depth'''!
arithmetic
	^TutorialLesson title: 'Arithmetic and comparison' text:
'The arithmetic words take their numbers off the stack and leave the answer:

Forth reset
Forth eval: ''7 3 - .''
Forth eval: ''6 7 * .''
Forth eval: ''17 5 mod .''
Forth eval: ''17 5 /mod . .''
Forth eval: ''5 negate .   -5 abs .   3 4 max .   3 4 min .''

/mod leaves the remainder and then the quotient, so the quotient is printed
first. Division rounds towards minus infinity (it is floored), so the remainder
takes the sign of the divisor:

Forth eval: ''7 2 / .''
Forth eval: ''-7 2 / .''
Forth eval: ''-7 2 mod .''

Integers have no limit here, because they are Smalltalk integers:

Forth eval: ''1000000000000 1000000000000 * .''

*/ multiplies and then divides, with the product held at full size, which is
what you want for taking a fraction of something:

Forth eval: ''1000 355 113 */ .''

The comparison words answer with a FLAG: -1 for true and 0 for false. They are
numbers like any other, which is why  0=  is also the word for not.

Forth eval: ''3 4 < .''
Forth eval: ''4 3 < .''
Forth eval: ''3 3 = .   3 4 <> .   0 0= .''

-1 is chosen because every bit of it is set, so the logic words work on flags
and on bits alike:

Forth eval: ''5 3 and .   5 3 or .   5 3 xor .   5 invert .''
Forth eval: ''3 4 < 4 5 < and .''
Forth eval: ''1 3 lshift .   16 2 rshift .''
Forth eval: ''5 1 6 within .   9 1 6 within .''

within ( n lo hi -- flag ) is true when lo <= n < hi.

Numbers are read and printed in the current BASE. hex and decimal change it,
and a $, # or % in front of a number overrides it for that number:

Forth eval: ''255 hex . decimal''
Forth eval: ''$ff .   #10 .   %101 .''
Forth eval: ''hex ff .s decimal'''!
definitions
	^TutorialLesson title: 'Defining words' text:
'A colon starts a new word and a semicolon ends it. Between them is what the
word does, which is just other words. The comment in brackets after the name is
for people; the compiler ignores it.

Forth reset
Forth eval: '': square ( n -- n*n )  dup * ;   7 square .''

square is now as much a part of the language as dup is. You can use it in
further definitions, and so build up in layers, each word small enough to
understand at a glance:

Forth eval: '': cube ( n -- n*n*n )  dup square * ;   3 cube .''
Forth eval: '': circle-ish ( r -- 3r*r )  square 3 * ;   10 circle-ish .''

Case does not matter, so Square and SQUARE are the same word:

Forth eval: ''5 SQUARE .''

Words are looked up when they are compiled, so a definition keeps meaning what
it meant when it was written, even if you redefine something it uses:

Forth eval: '': greeting 1 ;   : twice-greeting greeting greeting + ;   twice-greeting .''
Forth eval: '': greeting 100 ;   twice-greeting .   greeting .''

A word that is not defined is an error, and the half-made definition is thrown
away:

[Forth eval: '': oops dup flibbert * ;''] on: ForthError do: [:e | e messageText]
[Forth eval: ''oops''] on: ForthError do: [:e | e messageText]

SEE shows how a word was compiled, and WORDS lists everything that is defined:

Forth eval: ''see square''
Forth eval: ''see dup''
Forth eval: ''words'''!
printing
	^TutorialLesson title: 'Printing' text:
'Everything so far printed with . which writes a number and a space. There are
words for the rest. ." prints the text up to the closing quote, and cr ends a
line. Note the space after ." which is part of the word''s name and is not
printed:

Forth reset
Forth eval: ''." Hello, world" cr''
Forth eval: '': greet ." Hello from a word" cr ;   greet greet''

emit prints one character, given as a code. space and spaces print blanks:

Forth eval: ''72 emit 105 emit''
Forth eval: ''3 spaces ." indented"''
Forth eval: '': star 42 emit ;   : stars ( n -- ) 0 ?do star loop ;   5 stars''

.r prints a number right-justified in a field, which is how you make columns
line up. u. prints as if the number were unsigned, and u.r is the field version:

Forth eval: ''42 6 .r   7 6 .r''
Forth eval: ''-1 u.''
Forth eval: '': row ( n -- ) 5 .r ;   : table 5 1 do 5 1 do i j * row loop cr loop ;   table''

.( prints at once, even in the middle of a definition being compiled, which is
useful for progress messages:

Forth eval: ''.( compiling...) : x 1 ; ." |"''

\ comments to the end of the line, and ( comments to the closing bracket:

Forth eval: ''1 ( this is ignored ) 2 + .   \ and so is the rest of this line''

Printed text goes into a buffer, and Forth eval: answers whatever is in it when
the evaluation ends. Printing is the one thing a Forth word can do that leaves
nothing on the stack.'!
decisions
	^TutorialLesson title: 'Decisions' text:
'if ... then runs the words between them when the flag on the stack is true, which
means non-zero. if consumes the flag. else gives the other branch. These are
compiling words, so they can only be used inside a definition:

Forth reset
Forth eval: '': sign ( n -- ) dup 0< if drop ." negative" else 0= if ." zero" else ." positive" then then ;   -5 sign cr 0 sign cr 8 sign''

Read it as: if n is less than zero, drop it and say negative; otherwise, if it
is zero... The flag-producing words (0< 0= < = and the rest) go before the if,
so the code reads in the order it happens, a little like English with the
verbs at the end.

Any non-zero value counts as true, which allows a short idiom for testing
whether a number is there at all:

Forth eval: '': maybe ( n -- ) if ." something" else ." nothing" then ;   0 maybe cr 7 maybe''

exit leaves a definition early. It is the way to write a guard at the top of a
word without nesting everything inside an else:

Forth eval: '': safe-div ( a b -- q ) dup 0= if drop drop 0 exit then / ;   10 2 safe-div .   10 0 safe-div .''

case is for choosing between several values. Each of compares the selector with
a value and, if they are equal, runs its branch up to endof and then skips to
the end. Whatever is left runs when none matched, with the selector on the stack:

Forth eval: '': name ( n -- ) case 1 of ." one" endof 2 of ." two" endof 3 of ." three" endof ." many" endcase ;   1 name cr 3 name cr 9 name''

A flag is just a number, so you can do arithmetic on it. Here -1 and 0 are
turned into  1 and 0  with negate:

Forth eval: '': positive? ( n -- 1|0 ) 0> negate ;   5 positive? .   -5 positive? .'''!
loops
	^TutorialLesson title: 'Loops' text:
'do ... loop repeats a block. It takes a limit and a starting index, and i is
the current index. The loop runs while i is below the limit:

Forth reset
Forth eval: '': count-up 5 0 do i . loop ;   count-up''
Forth eval: '': squares 6 1 do i dup * . loop ;   squares''

+loop takes its step from the stack, so you can count by any amount, even down:

Forth eval: '': by-threes 12 0 do i . 3 +loop ;   by-threes''
Forth eval: '': countdown 0 5 do i . -1 +loop ;   countdown''

?do skips the loop altogether when the limit and the index are equal, which is
what you want when the count might be zero. A plain do with equal numbers would
run for a very long time:

Forth eval: '': times ( n -- ) 0 ?do ." x" loop ;   0 times 3 times''

Loops nest, and j is the index of the loop outside:

Forth eval: '': grid 3 0 do 3 0 do j 3 * i + . loop cr loop ;   grid''

leave ends the loop at once. unloop discards the loop''s control values so that
you can exit the whole word from inside it:

Forth eval: '': first-over ( n -- ) 100 0 do i dup * over > if i . leave then loop drop ;   50 first-over''
Forth eval: '': find7 10 0 do i 7 = if ." found " i . unloop exit then loop ." not found" ;   find7''

When you do not know how many times, use begin. begin ... until repeats until
the flag at the end is true; begin ... while ... repeat tests in the middle:

Forth eval: '': halve ( n -- ) begin dup . 2/ dup 0= until drop ;   100 halve''
Forth eval: '': to-five 0 begin dup 5 < while dup . 1+ repeat drop ;   to-five''

begin ... again never ends by itself; exit gets out.

Forth eval: '': first-power ( n -- p ) 1 begin 2dup > while 2 * repeat nip ;   1000 first-power .'''!
variables
	^TutorialLesson title: 'Variables, constants and values' text:
'A variable is a word that leaves an ADDRESS. !! stores a number at an address and
@ fetches it back (people read them as store and fetch). +!! adds to what is there:

Forth reset
Forth eval: ''variable counter   0 counter !!   counter @ .''
Forth eval: ''5 counter +!!   5 counter +!!   counter @ .''
Forth eval: ''counter ?''

? is just  @ .  and it is defined, in Forth, in the part of the system that is
written in Forth (the prelude). Words that use a variable say what they mean:

Forth eval: '': bump  1 counter +!! ;   bump bump bump counter ?''

A constant is a word that leaves a number. Nothing can change it, and there is
no address:

Forth eval: ''1000 constant limit   limit 3 * .''
Forth eval: '': over-limit? ( n -- flag ) limit > ;   999 over-limit? .   1001 over-limit? .''

A value is in between. It is read by just naming it, like a constant, and
changed with to, like a variable but without the @:

Forth eval: ''10 value width   width .   25 to width   width .''
Forth eval: '': widen  width 2 * to width ;   widen widen   width .''

Use a variable when several words share a counter that they all update, a
constant for a name for a number that never changes, and a value for a setting
that is mostly read.

Every one of them is an ordinary word that you can see:

Forth eval: ''see counter''
Forth eval: ''see limit''
Forth eval: ''see width''

The words 2variable and 2constant do the same for a pair of cells, with 2@ and 2!!
to fetch and store them:

Forth eval: ''2variable pt   3 4 pt 2!!   pt 2@ . .''
Forth eval: ''1 2 2constant pair   pair . .'''!
memory
	^TutorialLesson title: 'Memory' text:
'Memory is a long row of cells, each one holding a number, and an address says
which cell. Here, a cell is the unit of address: the cell after address a is
a+1, and  1 cells  is 1. (Forth systems for real machines use 4 or 8 bytes per
cell. Write cells and cell+ and your programs will not care.)

HERE is the next free cell, comma , stores a number there and moves on, and
create gives a name to the address:

Forth reset
Forth eval: ''create primes   2 , 3 , 5 , 7 , 11 ,   primes @ .   primes 1 + @ .   primes 4 + @ .''

create does only that, so primes leaves the address of its first cell and the
rest is arithmetic on addresses. cells scales an index:

Forth eval: '': nth ( i -- n ) cells primes + @ ;   0 nth .   3 nth .   4 nth .''

allot reserves cells without filling them. Combine it with create for an array,
and fill, erase, move and blank for the bulk operations:

Forth eval: ''create scores 10 cells allot   scores 10 0 fill   7 scores 3 cells + !!   scores 3 cells + @ .''
Forth eval: '': sum ( addr n -- total ) 0 swap 0 ?do over i cells + @ + loop nip ;   primes 5 sum .''

An array word that checks its index is worth having. This one is also the first
sight of  create  with  does> , which is the subject of a later lesson:

Forth eval: '': array create cells allot does> swap cells + ;   10 array squares   49 7 squares !!   7 squares @ .''

The memory can hold more than whole numbers: a cell may be a float, a Smalltalk
string or any object, because that is what the stack holds too. Floats have their
own stack and their own fetch and store, f@ and f!!, which come back in the
lesson on floating point:

Forth eval: ''variable x   3.25 x f!!   x f@ f.''

c@ and c!! fetch and store a single character, and here a character takes a
cell like everything else:

Forth eval: ''create buf 5 allot   72 buf c!!   105 buf 1 + c!!   buf 2 type''

Addresses that are out of range are an error, not a crash:

[Forth eval: ''0 @''] on: ForthError do: [:e | e messageText]
[Forth eval: ''1000000000 @''] on: ForthError do: [:e | e code]'!
strings
	^TutorialLesson title: 'Strings' text:
'There is no string type in Forth. A string is two numbers on the stack, an address
and a length, and the words that handle strings pass the pair around. s" leaves
one, and type prints one:

Forth reset
Forth eval: ''s" hello" type''
Forth eval: ''s" hello" .s''

The address is of the characters in memory. Take the pair apart and use the
pieces:

Forth eval: ''s" hello" nip .''
Forth eval: ''s" hello" drop c@ .''
Forth eval: ''s" hello world" 6 /string type''
Forth eval: ''s" hello" 1 /string 1 /string type''

/string drops characters from the front (it moves the address on and shortens
the length), which is how you walk along a string. compare answers -1, 0 or 1
and search looks for a piece inside a string:

Forth eval: ''s" apple" s" apple" compare .''
Forth eval: ''s" apple" s" banana" compare .''
Forth eval: ''s" banana" s" apple" compare .''
Forth eval: ''s" hello world" s" o w" search . type''
Forth eval: ''s" hello" s" xyz" search . nip .''

search leaves a flag and, when it found the piece, the string from there. In a
definition s" copies the text into memory for good; at the top level it uses a
buffer that the next couple of strings will overwrite, so use it straight away.

Forth eval: '': greeting s" good morning" ;   greeting type   greeting nip .''

Because a string is just an address and a length, a word that works through
one is a loop over the addresses. This one prints a string in capitals, by
taking 32 from each lower-case letter''s code:

Forth eval: '': shout ( addr n -- ) 0 ?do dup i + c@ 32 - emit loop drop ;   s" quiet" shout''

-trailing shortens a string by the blanks at its end:

Forth eval: ''s" trim   " -trailing nip .''

char takes the next word and leaves the code of its first letter, and [char]
does the same inside a definition. word and parse read the source text itself:

Forth eval: ''char A .''
Forth eval: '': letter-b [char] B emit ;   letter-b''
Forth eval: ''bl word hello count type''

evaluate runs a string as Forth, which closes the loop: a program can build text
and then run it.

Forth eval: ''s" 6 7 * ." evaluate'''!
definingwords
	^TutorialLesson title: 'Words that define words' text:
'create makes a word that leaves an address. does> says what that word will do
when it is run, as well as leaving the address. Together they make defining
words, the one idea most responsible for Forth''s reputation for being able to
do anything.

Forth reset
Forth eval: '': constant2 create , does> @ ;   42 constant2 answer   answer .''

Read it in two halves. Before does> is what happens when constant2 runs: create
makes the new word and  ,  stores the number from the stack as its data. After
does> is what the new word does each time it runs: it starts with its data
address on the stack, and @ fetches the number. This is exactly what constant
does.

Forth eval: '': adder create , does> @ + ;   5 adder add5   10 add5 .   100 add5 .''
Forth eval: '': array create cells allot does> swap cells + ;   5 array vec   9 3 vec !!   3 vec @ .''

Words made this way remember state, because their data is in memory:

Forth eval: '': counter create 0 , does> dup @ 1+ dup rot !! ;   counter hits   hits . hits . hits .''

Sometimes you want a word without a name: :noname makes one and leaves its
execution token, a handle on the word that execute runs. A tick ('') gives you
the token of a named word, and [''] does the same inside a definition:

Forth eval: '':noname dup * ;   7 swap execute .''
Forth eval: '': sq dup * ;   5 '''' sq execute .''

Tokens can be stored and passed around, so you can write words that take other
words as arguments:

Forth eval: '': apply-twice ( x xt -- y ) dup >r execute r> execute ;   3 '''' sq apply-twice .''
Forth eval: '': each-to ( n xt -- ) swap 0 ?do i over execute loop drop ;   5 '''' . each-to''

defer makes a word whose behaviour is chosen later with is, so a word can be
used before the thing it calls has been written:

Forth eval: ''defer greeting   : hello ." hello" ;   : bonjour ." bonjour" ;   '''' hello is greeting   greeting   '''' bonjour is greeting   greeting''

Words with a reach into the compiler come next.'!
compiling
	^TutorialLesson title: 'Extending the compiler' text:
'When Forth reads a word it either executes it or compiles it. The variable state
says which: zero is interpreting, and non-zero is compiling.

Forth reset
Forth eval: ''state @ .''
Forth eval: '': whatstate state @ ;   whatstate .''

A word marked immediate is executed even when compiling. That is how if, do,
the semicolon and all the other compiling words work: they run while your
definition is being built, and what they do is add pieces to it. You can
write your own. This one prints a message while its caller is compiled:

Forth eval: '': note ." (compiling) " ; immediate   : x note 1 ;''
Forth eval: ''x .''

The words [ and ] switch to interpreting for a moment inside a definition, and
literal compiles the number that is on the stack. Together they let you do a
calculation once, at compile time, instead of every time the word runs:

Forth eval: '': seconds-per-day [ 24 60 * 60 * ] literal ;   seconds-per-day .''
Forth eval: ''see seconds-per-day''

postpone compiles a word''s compile-time behaviour into the word being defined.
That is how you write a word that builds code, such as a new control structure.
This one adds an unless, which is if with the test the other way up:

Forth eval: '': unless postpone 0= postpone if ; immediate''
Forth eval: '': check ( n -- ) unless ." was zero" then ;   0 check   7 check''

Look at what was compiled: unless used 0= and if, so  see  shows just those.
The number after 0BRANCH is the cell that the branch jumps to when the flag is
false, which is how an if is built out of nothing but a jump:

Forth eval: ''see check''

A new name for an old compiling word is the same trick:

Forth eval: '': endif postpone then ; immediate''
Forth eval: '': positive? 1 > if ." big" endif ;   5 positive?''

recurse compiles a call to the word being defined, which a definition cannot
otherwise do because the word is not visible until the semicolon:

Forth eval: '': fact ( n -- n!! ) dup 2 < if drop 1 else dup 1- recurse * then ;   10 fact .   25 fact .''

The compiler is not hidden: every word of this lesson is in the dictionary,
and see shows which are written in Smalltalk and which in Forth.

Forth eval: ''see if''
Forth eval: ''see ?'''!
reading
	^TutorialLesson title: 'How Forth reads' text:
'The outer interpreter is a loop: read a word from the source; look it up; if it
is found, execute it (or compile it, if state says so); if it is not found, try
reading it as a number; if it is not that either, stop with an error. It is
worth seeing because every part of it is reachable from Forth.

Forth reset
Forth eval: ''1 2 + .   \ words, a number, words''

source gives the text being interpreted, as an address and length, and >in holds
how far along it is. parse-name takes the next word and leaves it as a string,
and so lets a word read ahead of itself:

Forth eval: ''source type''
Forth eval: '': spell parse-name type ;   spell hello''

A word that reads its own argument from the source is how defining words get
their names: create, variable and the colon all read the name that follows
them. You can write one too:

Forth eval: '': shout-next parse-name 0 ?do dup i + c@ 32 - emit loop drop ;   shout-next quiet''

find looks a name up in the dictionary: it leaves the token and a flag, 1 for an
immediate word and -1 for an ordinary one, or the string and 0 when there is no
such word:

Forth eval: ''bl word swap find . drop''
Forth eval: ''bl word nonesuch find . drop''
Forth eval: ''bl word if find nip .''

Numbers are read by the rules of base, or by prefix:

Forth eval: ''2 base !!   101 decimal .''
Forth eval: ''hex ff . decimal   $ff .   %11111111 .''

A character in quotes is the number of that character, and a number with a
trailing point is a double-cell number:

Forth eval: ''''''A'''' .''
Forth eval: ''123456789012. d.''

evaluate runs a string as Forth, with its own source, and the original comes
back afterwards:

Forth eval: ''s" 3 4 + ." evaluate''
Forth eval: '': twice-eval ( addr n -- ) 2dup evaluate evaluate ;   s" 7 ." twice-eval''

The last piece is how an error unwinds, which is the next lesson.'!
errors
	^TutorialLesson title: 'Errors, catch and throw' text:
'When something goes wrong Forth throws. Every throw has a number: -4 is a stack
underflow, -13 an unknown word, -10 division by zero, -9 a bad address. Used
at the top level, the effect is that the evaluation stops, the stacks are
emptied, and from Smalltalk you get a ForthError:

Forth reset
[Forth eval: ''1 0 /''] on: ForthError do: [:e | e code]
[Forth eval: ''1 0 /''] on: ForthError do: [:e | e messageText]
[Forth eval: ''flibbert''] on: ForthError do: [:e | Array with: e code with: e messageText]

throw throws a number of your own, and nothing at all when it is zero. catch
runs a word from its token and answers 0 if all went well, or the number that
was thrown. The stacks are put back to the depth they had when catch began:

Forth eval: '': risky 3 throw ." not reached" ;   '''' risky catch .''
Forth eval: '': fine ." ok " ;   '''' fine catch .''
Forth eval: '': tries 1 2 [''''] risky catch . . . depth . ;   tries''

That printed the code that catch answered, then the two numbers it kept on the
stack, and finally the depth, which is zero because they were all printed.

A catch can sit anywhere, and an inner one catches first. Rethrowing passes the
problem outwards:

Forth eval: '': inner 7 throw ;   : middle [''''] inner catch ?dup if throw then ;   : outer [''''] middle catch . ;   outer''

Smalltalk''s own errors are caught too. Division by zero is -10, and an address
outside memory is -9, because that is what they are called in the standard:

Forth eval: '': div0 1 0 / ;   '''' div0 catch .''
Forth eval: '': badaddr 0 @ ;   '''' badaddr catch .''

abort" is for checks: if the flag is true it throws -2 with your message, and
the message is what comes back as the ForthError''s text:

Forth eval: '': positive ( n -- n ) dup 0< abort" negative number" ;   5 positive .''
[Forth eval: ''-5 positive''] on: ForthError do: [:e | e messageText]

Some other things worth knowing. abort throws -1. bye and quit stop the
evaluation without an error; that is how a program says it is finished:

Forth eval: '': finish ." done" bye ." never shown" ;   finish ." nor this"''

After any error the partial output is still available:

| f | f := Forth new. [f eval: ''1 . 2 . oops 3 .''] on: ForthError do: [:e | nil]. f output
| f | f := Forth new. [f eval: ''1 . 2 . oops 3 .''] on: ForthError do: [:e | nil]. Array with: f errorWord with: f errorLine'!
numbers
	^TutorialLesson title: 'Doubles, formatting and floating point' text:
'A double-cell number holds two cells'' worth of integer. Here integers have no
limit anyway, but the double words are there because real Forth programs use
them, and because they are how numbers are formatted. A number with a trailing
point is a double; s>d turns an ordinary one into a double and d. prints it:

Forth reset
Forth eval: ''123456789012. d.''
Forth eval: ''-5 s>d d.''
Forth eval: ''10. 20. d+ d.''
Forth eval: ''1000000 1000000 m* d.''
Forth eval: ''10. 3 fm/mod . .''

A double sits on the stack as two cells, the low part under the high part. Take
the top away and you have the single number back: that is d>s.

Forth eval: ''5 s>d .s 2drop''
Forth eval: ''1000000 1000000 m* 7. d+ d.''

m* multiplies two singles to a double, um/mod and fm/mod divide a double, and
*/ does the whole sum at full size, which for a Forth with fixed-size cells
is what you reach for when ordinary multiplication would overflow.

Printing a number with your own layout uses pictured numeric output: <# begins,
The word # turns one digit into a character, #s turns all the rest, hold adds a
character, sign adds the minus, and #> ends and leaves the string.

Forth eval: '': .money ( cents -- ) s>d <# # # [char] . hold #s [char] $ hold #> type ;   12345 .money''
Forth eval: '': .2digits ( n -- ) s>d <# # # #> type ;   7 .2digits   42 .2digits''
Forth eval: '': .signed ( n -- ) dup abs s>d <# #s rot sign #> type ;   -42 .signed   42 .signed''

Floating point has a stack of its own, so floats and integers do not get in each
other''s way. Write a float with an e in it (or a decimal point and digits), and
f. prints one. The words begin with f:

Forth eval: ''1.5e0 2.5e0 f+ f.''
Forth eval: ''2e0 fsqrt f.''
Forth eval: ''10 s>f 4 s>f f/ f.''
Forth eval: ''pi f.''
Forth eval: ''3.7e0 floor f.   3.7e0 f>s .''
Forth eval: ''1e0 2e0 f< .''

f@ and f!! work on memory, fvariable and fconstant make words, and the float stack
is separate from the data stack, with .fs to show it:

Forth eval: ''fvariable radius   2.5e0 radius f!!   radius f@ f.''
Forth eval: '': area ( r -- area ) fdup f* pi f* ;   2e0 area f.''
Forth reset
Forth eval: ''1e0 2e0 3e0 .fs''
Forth reset
Forth eval: ''1e0 2 3 .s .fs''

The usual functions are there: fsqrt fsin fcos ftan fatan fexp fln flog f**
fabs fnegate fmax fmin floor fround ftrunc, and s>f, f>s, d>f and f>d to cross
between the stacks. Floats are Smalltalk floats, so they print the same way
that any Smalltalk float does.'!
smalltalk
	^TutorialLesson title: 'Forth and Smalltalk' text:
'Forth''s stack holds anything, not just numbers, so Smalltalk objects can ride
on it. Two words reach into Smalltalk. st-eval evaluates a string as a Smalltalk
expression and pushes the answer. send sends a message: it takes the receiver,
then the arguments, then how many arguments there are, then the selector as a
string.

Forth reset
Forth eval: ''s" 3 factorial" st-eval .''
Forth eval: ''s" 100 factorial printString size" st-eval .''
Forth eval: ''3 4 1 s" +" send .''
Forth eval: ''5 0 s" factorial" send .''
Forth eval: ''10 3 1 s" max:" send .''

A Smalltalk String is not a Forth string, which is an address and a length, so
there are words to convert: >st-string makes a String from an address and a
length, and st-string> turns a String into a Forth string again.

Forth eval: ''s" hello" >st-string 0 s" reversed" send st-string> type''
Forth eval: ''s" hello" >st-string 0 s" asUppercase" send st-string> type''
Forth eval: ''12345 printstring type''

Collections are objects, and so are ordinary stack items:

Forth eval: ''s" OrderedCollection new" st-eval   dup 7 1 s" add:" send drop   dup 9 1 s" add:" send drop   0 s" printString" send st-string> type''
Forth eval: ''s" #(3 1 2) asSortedCollection asArray" st-eval 0 s" printString" send st-string> type''

An object that came back from Smalltalk is just a value to Forth: dup it,
swap it, put it in a variable. . prints it the way Smalltalk would. st-nil
pushes nil and st-nil? tests for it.

Forth eval: ''s" 1/3" st-eval .''
Forth eval: ''s" Smalltalk" st-eval 0 s" class" send .''
Forth eval: ''st-nil st-nil? .   5 st-nil? .''

The other direction is just as easy. From Smalltalk, the stack is yours:

| f | f := Forth new. f push: 6. f push: 7. f eval: ''*''. f pop
| f | f := Forth new. f eval: ''1 2 3''. f stack
| f | f := Forth new. f pushString: ''a string''. f eval: ''type''
Forth valueOf: ''6 7 *''
Forth stackAfter: ''3 4 5''

And you can write a Forth word in Smalltalk. The block is given the Forth system
and works on its stack:

| f | f := Forth new. f define: ''TRIPLE'' do: [:forth | forth push: forth pop * 3]. f eval: ''14 triple .''
| f | f := Forth new. f define: ''UPCASE'' do: [:forth | forth push: forth pop asCharacter asUppercase value]. f eval: ''97 upcase emit''

Sending define:do: to the class Forth does the same for every system, present and
future, which is how you extend the language for good.

The classes that make up the system are in the category Forth: ForthWord and its
subclasses are the things a dictionary holds, Forth is the machine, ForthError
is what you catch, and ForthTool is the workspace.

ForthWord allSubclasses collect: [:c | c name]'!
workspace
	^TutorialLesson title: 'The workspace' text:
'The workspace is a window for Forth. Open it with System menu, forth workspace,
or:

ForthTool open

Select some Forth in the window and print it (ctrl-P) or do it (ctrl-D). What it
prints comes back, then ok, and the stack if anything is left on it. What you
define stays defined from one run to the next, and the window shows what a
terminal would. An error shows its message and the line it was on. To start
again with a clean system, select the word FORGET-ALL and run it.

This is what the report looks like, here without a window:

ForthTool reset
ForthTool evaluate: ''2 3 + .''
ForthTool evaluate: '': square dup * ;   7 square .''
ForthTool evaluate: ''1 2 3''
ForthTool evaluate: ''nosuch''
ForthTool evaluate: ''1 . 2 . oops''
ForthTool evaluate: ''FORGET-ALL''

The window''s system is separate from Forth default, so what you do in the window
and what you do in a Smalltalk workspace do not mix. To get at it from
Smalltalk:

ForthTool system eval: ''10 20 +''
ForthTool system stack

A Forth program in a file is run with include or included, and from Smalltalk
with Forth evalFile: ''path''. The prelude, the part of the system written in
Forth, is a good thing to read as an example of the style:

Smalltalk packagePath: ''Forth'''!
programs
	^TutorialLesson title: 'A few programs' text:
'The way to learn Forth is to write words. Here are some, each built the usual
way: small words, tested as you go, composed into bigger ones.

Forth reset
Forth eval: '': fizzbuzz ( n -- ) 1+ 1 do i 15 mod 0= if ." FizzBuzz " else i 3 mod 0= if ." Fizz " else i 5 mod 0= if ." Buzz " else i . then then then loop ;   15 fizzbuzz''

The greatest common divisor, by Euclid''s method, with a loop that has no index:

Forth eval: '': gcd ( a b -- g ) begin dup while tuck mod repeat drop ;   48 18 gcd .   17 5 gcd .''

Is a number prime? Try each divisor up to the number. unloop is needed because
exit is called from inside the loop:

Forth eval: '': prime? ( n -- flag ) dup 2 < if drop 0 exit then dup 2 ?do dup i mod 0= if drop 0 unloop exit then loop drop -1 ;   13 prime? .   15 prime? .''
Forth eval: '': primes ( n -- ) 2 ?do i prime? if i . then loop ;   40 primes''

Powers and factorials, which show off the unlimited integers:

Forth eval: '': power ( base n -- b^n ) 1 swap 0 ?do over * loop nip ;   2 100 power .''
Forth eval: '': factorial ( n -- n!! ) 1 swap 1+ 1 ?do i * loop ;   30 factorial .''

The Collatz sequence, which every number seems to reach 1 along:

Forth eval: '': collatz ( n -- ) begin dup . dup 1 > while dup 2 mod if 3 * 1+ else 2/ then repeat drop ;   27 collatz''

The towers of Hanoi, counting moves with recursion:

Forth eval: '': hanoi ( n -- moves ) dup 0= if exit then dup 1- recurse 2* 1+ ;   10 hanoi .''

The sieve of Eratosthenes, which uses memory:

Forth eval: ''100 constant limit   create sieve limit 1+ allot   : sieve!! sieve limit 1+ 1 fill 0 sieve !!   0 sieve 1 + !!   limit 1+ 2 do i dup * limit > if leave then sieve i + @ if limit 1+ i dup * do 0 sieve i + !! j +loop then loop ;   : sieve. limit 1+ 2 do sieve i + @ if i . then loop ;   sieve!! sieve.''

The sieve is the longest of these and the trickiest to read. Redo it as small
words if you like: a word to clear multiples of a number, one to run it for each
number still marked, and one to print. That is the Forth way, and it is why
the definitions are short.'!
whatNext
	^TutorialLesson title: 'Where to go next' text:
'That is the system. Worth carrying away:

The stack is the only way words talk to each other, so every word''s stack
effect is its whole interface. Write it down every time.

Keep words small. A Forth definition longer than a few lines is usually two or
three definitions that have not been separated yet. The system makes this
cheap: there is no overhead to a call that you would want to avoid.

Test each word as you write it, from the top level, with its arguments on the
stack and .s to look. That is the Forth equivalent of a REPL.

What is not here: vocabularies and the search order, block words, the file
access words (open-file and its relatives, though include and included are
there), the facility and tools word sets beyond what you have seen, and the
locals word set. The
cell is one address unit, not four or eight, and integers have no limit. Where
the standard says a thing is implementation-defined, this system takes the
friendliest option: division is floored, a true flag is -1, and words are not
case sensitive.

The control structures are checked while compiling and an unfinished one is an
error. The control-flow stack is separate from the data stack, so unlike many
systems you cannot juggle its entries with the data stack words.

The package README is packages/Forth/README.md. The source is short enough to
read: the inner interpreter is Forth>>run: and the compiler words are in
primitives2.st. Read them in that order and you will see that a whole Forth is
only a few hundred lines.

Other tutorials in this image:

Smalltalk tutorialNames

and the one for the language itself:

Smalltalk tutorial'! !
