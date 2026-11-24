"The APL tutorial: arrays and their shape, arithmetic and agreement, reading right to left, indexing, reduce and scan, rank,
characters and boxes, defining verbs, trains and tacit definitions, control structures, sorting and searching, matrices,
numbers and formatting, statistics, adverbs and conjunctions of your own, the classic glyphs, the bridge to Smalltalk,
some famous one-liners.  The examples are live; start it with   APLTutorial go"

AbstractTutorial subclass: #APLTutorial instanceVariableNames: '' classVariableNames: '' category: 'APL'!

!APLTutorial class methodsFor: 'the lessons'!
tutorialName
	^'APL'!
lessonSelectors
	^#(#welcome #shape #arithmetic #direction #selecting
		#reduce #rank #boxes #defining #trains
		#control #sorting #matrices #numbers #statistics
		#operators #glyphs #bridge #oneliners #whatnext)! !

!APLTutorial class methodsFor: 'lessons'!
welcome
	^TutorialLesson title: 'Welcome' text:
'This is an array language, in the family of APL and J, running inside Smalltalk. Its one idea is that the thing you compute with is an array, and that most of the work of a loop is done for you: add two lists, and you add them item by item; sum a table, and you sum its columns. A program is a handful of symbols, read from right to left, with no precedence rules to remember.

Everything in this tutorial is live: select a line and press ctrl-P (print it) to run it. The message eval: sent to APL runs some text of the language and answers what the language would print, as a String. A table comes back with its line breaks in it, which print it shows inside quotes.

APL eval: ''2 + 3''
APL eval: ''1 2 3 + 10 20 30''
APL eval: ''+/ 1 2 3 4 5''
APL eval: ''2 * 3 + 4''

The last one is 14, not 10: the language has no precedence, it takes the rightmost part first, so 3 + 4 is done before 2 * the answer. The symbols are called verbs, and a verb with one argument (on its right) and a verb with two (one on each side) are two different functions that share a spelling: the first is the monad, the second the dyad.

The names you assign last from one call to the next, because they live in the default session. APL reset starts a clean one, and APL new makes a private one. There is also a workspace window, apl workspace in the System menu, where you select lines of the language itself and print them. A line that begins with NB. is a comment.

The spellings are those of J, which uses only the keys on a keyboard. If you know the classic APL glyphs you can type those instead, as the lesson about glyphs explains.'!
shape
	^TutorialLesson title: 'Arrays and shape' text:
'Everything is an array: a single number (a scalar), a list, a table, or something with more axes. What tells them apart is the shape, a list of the lengths of the axes. A scalar has the empty shape, a list of five has the shape 5, a table of 2 rows and 3 columns has the shape 2 3. The number of axes is the rank.

APL eval: ''i. 10''
APL eval: ''2 3 $ i. 6''
APL eval: ''$ 2 3 $ i. 6''
APL eval: ''# 1 2 3 4''
APL eval: ''$ 5''

i. (read it integers) makes the numbers from 0, $ with a list on its left reshapes (the right argument is used over and over if it is too short), $ on its own answers the shape, and # on its own counts the items along the first axis. A table is shown with its columns lined up, an array of three axes plane by plane.

APL eval: ''i. 2 3 4''
APL eval: ''3 $ 7''
APL eval: ''2 3 $ ''''abcdef''''''
APL eval: ''7 $ 1 2 3''

A list of characters is a string, written in single quotes, and is an array like any other. Two more verbs change the arrangement without changing the items: , (ravel) flattens, and |: turns a table on its side.

APL eval: '', 2 3 $ i. 6''
APL eval: ''|: 2 3 $ i. 6''
APL eval: ''1 2 , 3 4 5''
APL eval: ''$ '''''''''''!
arithmetic
	^TutorialLesson title: 'Arithmetic and agreement' text:
'The arithmetic verbs work on single numbers, and so on whole arrays: they are applied item by item. If one argument is a single number it is used against every item of the other, and if both are arrays they must have the same shape (or one shape must be the beginning of the other, so that a list with one number for each row is added to the rows of a table, a number to a row).

APL eval: ''1 2 3 * 4''
APL eval: ''1 2 3 * 4 5 6''
APL eval: ''10 20 + 2 3 $ i. 6''
APL eval: ''100 + 2 3 $ i. 6''
[APL eval: ''1 2 3 + 4 5''] on: APLError do: [:e | e messageText]

The error is a length error: the shapes do not agree. The messages are those of J: domain error, length error, rank error, index error, value error, syntax error. A comparison answers 1 for true and 0 for false, which is exactly what you want for counting and for selecting.

APL eval: ''1 2 3 < 2''
APL eval: ''3 = 3 4''
APL eval: ''1 2 3 4 > 2''
APL eval: ''+/ 1 2 3 4 > 2''

Whole numbers are exact and as big as you like. A division that comes out even stays whole, one that does not gives a float, and a rational such as 3r4 stays exact. A high minus is written with an underscore, so that it cannot be mistaken for the verb that subtracts.

APL eval: ''7 % 2''
APL eval: ''6 % 3''
APL eval: ''2 ^ 100''
APL eval: ''3r4 + 1r4''
APL eval: ''_5 + 3''
APL eval: ''!! 20'''!
direction
	^TutorialLesson title: 'Reading right to left' text:
'The rule has no exceptions: the rightmost verb is applied first, to everything to its right. Parentheses change the order, as in school arithmetic, and nothing else does.

APL eval: ''10 - 4 - 3''
APL eval: ''(10 - 4) - 3''
APL eval: ''2 ^ 3 ^ 2''
APL eval: ''(2 ^ 3) ^ 2''
APL eval: ''2 * 3 + 4''

A verb with nothing to its left is the monad, and the monad of - is negate, the monad of % is the reciprocal, the monad of * is the sign, *: squares, %: takes the square root, !! the factorial, and so on.

APL eval: ''- 5''
APL eval: ''% 4''
APL eval: ''* _3 0 3''
APL eval: ''*: 1 2 3 4''
APL eval: ''%: 16''
APL eval: ''10 - 2 * 3''

Read the last one aloud from the right: 2 * 3 is 6, and 10 - 6 is 4. It is a habit that takes an afternoon to acquire, and then it is hard to give up, because a sentence reads in the order that the computation happens. A name that holds a number is used exactly like the number, and two names (or numbers) side by side make a list.

APL eval: ''a =: 3''
APL eval: ''b =: 4''
APL eval: ''a * b''
APL eval: ''a b'''!
selecting
	^TutorialLesson title: 'Indexing and selecting' text:
'Items are picked with { (from), which takes a list of positions, counting from 0 and from the end with negative numbers. A table is indexed by a box that holds a row and a column.

APL eval: ''2 { ''''hello''''''
APL eval: ''1 3 { ''''hello''''''
APL eval: ''_1 { ''''hello''''''
APL eval: ''(<1;2) { 3 3 $ i. 9''

{. (head) and its relatives take and drop from the ends: with a number on the left {. takes that many (a negative number takes from the end, and taking more than there are pads with zeros or blanks), and }. drops them. Without a left argument they answer the first item, the rest, the last item, and all but the last.

APL eval: ''3 {. i. 10''
APL eval: ''_3 {. i. 10''
APL eval: ''3 }. i. 10''
APL eval: ''{. ''''hello''''''
APL eval: ''}. ''''hello''''''
APL eval: ''{: ''''hello''''''
APL eval: ''}: ''''hello''''''
APL eval: ''7 {. 1 2 3''

The verb |. reverses, and with a left argument rotates. To get a list of positions from a test, I. answers where the ones are, and { with its arguments the other way round is {~, which reads best when the indexed thing is already on the left.

APL eval: ''|. i. 5''
APL eval: ''2 |. i. 5''
APL eval: ''I. 3 1 4 1 5 > 2''
APL eval: ''3 1 4 1 5 {~ 0 2 4''
APL eval: ''(3 1 4 1 5 > 2) # 3 1 4 1 5''

The last of these is # with a list of copy counts, and it is the way to filter: copy each item as often as its flag says. To change items, } (amend) takes the positions on its left and answers a verb that puts the left argument there.

APL eval: ''9 (1}) i. 5''
APL eval: ''0 0 (0 4}) i. 5'''!
reduce
	^TutorialLesson title: 'Reduce, scan and table' text:
'An adverb takes a verb and answers a new verb. The most used is / (insert), which writes the verb between the items of the list. +/ is the sum, */ the product, >./ the largest, <./ the smallest. On a table it works down the columns, because the first axis is the one that is reduced.

APL eval: ''+/ i. 11''
APL eval: ''*/ 1 + i. 5''
APL eval: ''>./ 3 1 4 1 5''
APL eval: ''-/ 1 2 3''
APL eval: ''+/ 2 3 $ i. 6''
APL eval: ''+/ ''''''''''

The fourth of these is 1 - (2 - 3), because a verb is always applied from the right. The sum of nothing is 0, and the product of nothing is 1: each verb knows its identity element. With a left argument, / makes a table of the verb applied to every pair, the way a multiplication table is made.

APL eval: ''1 2 3 */ 1 2 3''
APL eval: ''(i. 3) +/ i. 4''
APL eval: ''=/~ i. 4''

The last uses ~ (reflex), which gives the verb the same list on both sides: =/~ i. 4 is the identity matrix, since each item is compared with each. The adverb \ (prefix) applies a verb to the first item, the first two, the first three and so on. With +/ in front it gives the running totals, which is why +/\ is among the best known phrases of the language.

APL eval: ''+/\ 1 2 3 4''
APL eval: ''*/\ 1 + i. 5''
APL eval: ''+\ 1 2 3''
APL eval: ''3 +/\ i. 6''
APL eval: ''2 <\ i. 5''

A number on the left of \ makes windows of that many items (and a negative number cuts a list into pieces that do not overlap). \. (suffix) does the same from the other end.'!
rank
	^TutorialLesson title: 'Rank' text:
'Every verb has a rank for each of its arguments: the rank of the cell it wants to be given. Hand it something with more axes and it is applied to each cell in turn, and the results are laid out under the leftover axes, the frame. Atomic verbs like + have rank 0: they want single items, and the frame is the whole array. +/ wants a list, so on a table it works on the columns, the table being a list of rows. The conjunction " (rank) changes a verb''s rank:

APL eval: ''$ i. 2 3 4''
APL eval: ''+/ i. 2 3 4''
APL eval: ''+/"1 i. 2 3 4''
APL eval: ''+/"2 i. 2 3 4''
APL eval: ''+/"1 (2 3 $ i. 6)''

With rank 1 each row is summed on its own, so the sums along the rows are what you get. The same idea explains the way arguments agree: the frames must match, or one must be a prefix of the other.

APL eval: ''10 20 +"0 1 (2 3 $ i. 6)''
APL eval: ''10 20 30 +"1 1 (2 3 $ i. 6)''
APL eval: ''<"1 i. 2 3''
APL eval: ''|."1 i. 2 3''
APL eval: ''|. i. 2 3''

The last two show the difference rank makes: |."1 reverses each row, and |. alone reverses the order of the rows. A rank of _ (infinity, written as an underscore) means the whole argument, and a negative rank n means all but n axes.

APL eval: ''$ <"0 i. 2 3''
APL eval: ''+/"_1 i. 2 3'''!
boxes
	^TutorialLesson title: 'Characters and boxes' text:
'Characters are an ordinary type of item, so the structural verbs work on strings as they do on numbers. Quote marks are written twice inside a string.

APL eval: ''''''hello'''' , '''' '''' , ''''world''''''
APL eval: ''|. ''''hello''''''
APL eval: ''''''it''''''''s''''''
APL eval: ''/:~ ''''banana''''''
APL eval: ''''''banana'''' i. ''''n''''''
APL eval: ''~. ''''banana''''''

An array can only hold items of one kind, so to put things of different shapes side by side you box them: < puts any array in a box, which is a single item, and > opens it again. The box is drawn with box characters in the display.

APL eval: ''<''''abc''''''
APL eval: ''''''one'''' ; ''''three'''' ; ''''a''''''
APL eval: ''> ''''one'''' ; ''''three'''' ; ''''a''''''
APL eval: '';: ''''the quick brown fox''''''
APL eval: ''# &> ;: ''''the quick brown fox''''''

; (link) boxes its arguments and joins them into a list of boxes, and monadic ; (raze) does the reverse. ;: cuts a string into its words. The phrase &> means each: apply the verb to what is inside each box. It is spelt as a conjunction (&. is under) followed by the open verb, and the word each names it:

APL eval: ''*: each 1 2 3''
APL eval: ''# each (i. 3) ; (i. 5)''
APL eval: ''(i. 3) ; ''''x'''' ; 2 2 $ 1 2 3 4''
APL eval: ''; ''''ab'''' ; ''''cd'''' ; ''''ef''''''

;. (cut) with a verb on its left and 1, _1, 2 or _2 on its right splits a list at the places where its first (or last) item turns up: <;._1 '' a b c'' is the words of a string.

APL eval: ''<;._1 '''' a b c''''''
APL eval: ''<;._1 '''',red,green,blue'''''''!
defining
	^TutorialLesson title: 'Defining verbs' text:
'A verb you write is made with the conjunction : whose left argument says what to make (3 for a verb) and whose right argument is the text of the definition. Inside the text, y is the right argument and x the left. A name assigned with =. is local to the definition, and one assigned with =: is global.

APL eval: ''sq =: 3 : ''''y * y''''''
APL eval: ''sq 5''
APL eval: ''sq 1 2 3''
APL eval: ''plus =: 3 : ''''x + y''''''
APL eval: ''3 plus 4''
APL eval: ''hyp =: 3 : ''''%: +/ *: y''''''
APL eval: ''hyp 3 4''

The definition may have several sentences: in a string they are separated by the diamond, the character that looks like a small lozenge (and in a text file or a workspace by line breaks). The value of the definition is the value of its last sentence.

APL eval: ''area =: 3 : ''''h =. y % 2 ⋄ h * y''''''
APL eval: ''area 10''
APL eval: ''hms =: 3 : ''''24 60 60 #: y''''''
APL eval: ''hms 3661''

In a file or a workspace a definition runs over several lines, between verb define and a line that holds only a closing parenthesis. From Smalltalk the whole text is just a string with line breaks in it:

	APL eval: ''perimeter =: verb define
	2 * +/ y
	)''

Two texts joined by : make a verb with a different definition for each case, the first for the monad and the second for the dyad:

APL eval: ''both =: ''''y * y'''' : ''''x * y''''''
APL eval: ''both 5''
APL eval: ''3 both 5'''!
trains
	^TutorialLesson title: 'Tacit definitions and trains' text:
'You can also define a verb without mentioning its argument at all. Write the verbs in a row and the language reads three in a row as a fork: (f g h) y is (f y) g (h y), so that +/ % # is the sum divided by the count, the mean.

APL eval: ''mean =: +/ % #''
APL eval: ''mean 3 1 4 1 5 9''
APL eval: ''mean 1 2 3 4''
APL eval: ''(+/ , */) 1 2 3 4''
APL eval: ''(] , |.) ''''abc''''''

A fork whose first tine is a noun uses it as a constant. Two verbs in a row make a hook: (f g) y is y f (g y). When only the second of a fork is to apply to the result of the third, write [: for the first tine, a cap that means nothing here.

APL eval: ''(- +) 5''
APL eval: ''3 (- +) 5''
APL eval: ''([: +/ *:) 1 2 3''
APL eval: ''(+/ % #) 2 4 6 8''

Longer trains are read from the right in threes. The conjunctions @ (atop) and & (compose) join two verbs end to end: @ applies the right one on each cell its own rank asks for, and @: applies it to the whole argument. The bond u & n fixes one argument.

APL eval: ''+/ @: *: 1 2 3''
APL eval: ''*: @ (- mean) 1 2 3 4''
APL eval: ''var =: (+/ @: *: @: (- mean)) % #''
APL eval: ''var 1 2 3 4''
APL eval: ''sd =: %: @ var''
APL eval: ''sd 2 4 4 4 5 5 7 9''
APL eval: ''(3 & *) 1 2 3''
APL eval: ''(+ & 1) 1 2 3''

^: (power) applies a verb a number of times: a list of numbers gives all the intermediate results, a negative number applies the inverse, and an infinite one repeats until nothing changes.

APL eval: ''(*: ^: 3) 2''
APL eval: ''>: ^: (i. 5) 0''
APL eval: ''(2 & *) ^: (i. 6) 1''
APL eval: ''%: ^: _ (1000)'''!
control
	^TutorialLesson title: 'Control structures' text:
'Inside a definition the words if., else., elseif., while., for., select., case., try. and catch. work as they do in J, each ending with end. The condition of if. is true when the first item of its value is not 0. The control words can follow each other on one line; the diamond separates sentences.

APL eval: ''abs2 =: 3 : ''''if. y < 0 do. - y else. y end.''''''
APL eval: ''abs2 _7''
APL eval: ''fact =: 3 : ''''if. y < 2 do. 1 else. y * fact y - 1 end.''''''
APL eval: ''fact 20''
APL eval: ''fact 25''

Numbers never overflow, as you saw, so 25!! comes out exactly. Recursion can name the verb being defined with $: so that the definition does not depend on its own name. return. leaves a definition early with the value of the last sentence so far.

APL eval: ''fib =: 3 : ''''if. y < 2 do. y return. end. (($: y - 1) + $: y - 2)''''''
APL eval: ''fib 15''
APL eval: ''collatz =: 3 : ''''n =. 0 ⋄ while. y > 1 do. y =. (0 = 2 | y) { (1 + 3 * y), y % 2 ⋄ n =. n + 1 end. n''''''
APL eval: ''collatz 27''

for. runs a block once for each item of a list, and for_x. also sets the local names x and x_index. select. compares its value with each case., and else. catches the rest. try. runs a block and, if any error happens in it, catch. runs instead.

APL eval: ''sumsq =: 3 : ''''s =. 0 ⋄ for_k. i. y do. s =. s + *: k end. s''''''
APL eval: ''sumsq 10''
APL eval: ''grade =: 3 : ''''select. y case. 1 do. ''''''''one'''''''' case. 2 do. ''''''''two'''''''' else. ''''''''many'''''''' end.''''''
APL eval: ''grade 2''
APL eval: ''grade 9''
APL eval: ''safe =: 3 : ''''try. %: y catch. ''''''''negative'''''''' end.''''''
APL eval: ''safe 16''
APL eval: ''safe _16''

There is no goto, and few definitions need the loops: the point of an array language is that the arrays make them unnecessary, as the next lessons show.'!
sorting
	^TutorialLesson title: 'Sorting and searching' text:
'/: (grade up) answers the positions that would sort a list, and \: sorts downwards. With a list on the left, it sorts the right argument by those keys. The sort of a list is /:~ , the grade of the list applied to itself.

APL eval: ''/: 3 1 4 1 5''
APL eval: ''\: 3 1 4 1 5''
APL eval: ''/:~ 3 1 4 1 5''
APL eval: ''\:~ 3 1 4 1 5''
APL eval: ''3 1 2 /: ''''abc''''''
APL eval: ''/:~ ;: ''''the quick brown fox''''''

The grade is stable: items that are equal keep their order. Searching has its own verbs: x i. y answers where each of y is in x (the length of x when it is missing), e. says whether it is there at all, ~. removes the duplicates, -. removes from the left list what is in the right one, and ~: marks the first of each.

APL eval: ''''''hello'''' i. ''''l''''''
APL eval: ''''''hello'''' i. ''''lz''''''
APL eval: ''2 e. 1 2 3''
APL eval: ''''''aeiou'''' e. ''''education''''''
APL eval: ''~. 3 1 4 1 5 9 2 6 5 3 5''
APL eval: ''~: 3 1 4 1 5''
APL eval: ''1 2 3 4 5 -. 2 4''

A key adverb counts: x u/. y applies u to each group of the items of y whose key in x is the same. #/.~ y counts how often each distinct item turns up, in order of first appearance, and the words of a text show the idiom at work.

APL eval: ''#/.~ ''''mississippi''''''
APL eval: ''~. ''''mississippi''''''
APL eval: ''(~. ''''mississippi'''') ,. ": ,. #/.~ ''''mississippi''''''
APL eval: ''w =: ;: ''''the cat and the dog and the bird''''''
APL eval: ''(~. w) ,. <"0 #/.~ w''
APL eval: ''0 10 20 30 I. 5 15 25 35 45'''!
matrices
	^TutorialLesson title: 'Matrices and the inner product' text:
'The inner product is a conjunction, because it takes two verbs: x f . g y combines the rows of x with the columns of y by g, then f. With +/ and * it is the matrix product, and on lists the dot product.

APL eval: ''m =: 2 2 $ 1 2 3 4''
APL eval: ''m +/ . * m''
APL eval: ''1 2 3 +/ . * 4 5 6''
APL eval: ''|: m''
APL eval: ''m +/ . * |: m''

Other verb pairs are useful in the same place: >./ . + is the best total over choices (the tropical product of path problems), and a monad of the inner product is the determinant when it is -/ . * because it expands along the first row. %. is the matrix inverse (exact when the numbers are whole or rational), and with a left argument it solves a system: b %. m is x such that m +/ . * x is b.

APL eval: ''-/ . * m''
APL eval: ''-/ . * 3 3 $ 2 0 1 1 3 2 1 1 4''
APL eval: ''%. m''
APL eval: ''m +/ . * %. m''
APL eval: ''5 6 %. m''
APL eval: ''=/~ i. 3''

Conway''s game of life is a favourite. Count the neighbours with rotations: the board rotated up, as it is, and down, summed, gives the three in a column; do the same sideways. A cell is alive in the next generation if the count with itself is 3, or it is 4 and the cell is alive.

APL eval: ''life =: 3 : ''''r =. _1 0 1 ⋄ n =. |: +/ r |."0 _ |: +/ r |."0 _ y ⋄ (3 = n) +. y *. 4 = n''''''
APL eval: ''g =: 5 5 $ 0 1 0 0 0 0 0 1 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0''
APL eval: ''life g''
APL eval: ''life life g''
APL eval: ''+/ , life ^: 4 g'''!
numbers
	^TutorialLesson title: 'Numbers and formatting' text:
'Whole numbers are exact however large, rationals are exact, and anything else is a float printed with six significant digits. x: turns a float into the rational that best matches it, so that the arithmetic can go on exactly.

APL eval: ''!! 30''
APL eval: ''x: 1 % 3''
APL eval: ''(x: 1 % 3) + 1r6''
APL eval: ''1 % 3''
APL eval: ''0.1 + 0.2''
APL eval: ''x: 0.75''
APL eval: ''2 ^ 0.5''

Floor and ceiling are <. and >. (as monads), and they are also minimum and maximum (as dyads). #. converts digits to a number in a base and #: converts back; a list on the left of #: gives mixed radices, which is how seconds become hours, minutes and seconds.

APL eval: ''<. 2.7''
APL eval: ''>. 2.1''
APL eval: ''3 <. 5''
APL eval: ''#. 1 0 1 0''
APL eval: ''10 #. 1 2 3''
APL eval: ''2 #: 10''
APL eval: ''24 60 60 #: 3661''

": (format) turns numbers into text. Monadically it gives what is shown, and with a left argument it gives a fixed width: 8.2 means eight columns and two decimals, and a plain whole number means that width alone. A negative width pads on the right.

APL eval: ''": 3.14159''
APL eval: ''8.2 ": 3.14159''
APL eval: ''8.2 ": 3 4.5 _1.25''
APL eval: ''5 ": 1 2 3''
APL eval: ''''''pi is '''' , 8.3 ": 3.14159265''
APL eval: ''9!!:11 (10)''
APL eval: ''% 3''
APL eval: ''9!!:11 (6)''

The verb 9!!:11 sets how many digits are shown, and answers the old setting. The mathematics is not affected: it is only the display that is rounded.'!
statistics
	^TutorialLesson title: 'Statistics' text:
'A few lines make a small statistics library, and each is a sentence with no loop in it. The mean is +/ % # and the deviations are what is left after subtracting it.

APL eval: ''data =: 4 8 15 16 23 42''
APL eval: ''mean =: +/ % #''
APL eval: ''mean data''
APL eval: ''data - mean data''
APL eval: ''var =: (+/ @: *: @: (- mean)) % #''
APL eval: ''sd =: %: @ var''
APL eval: ''var data''
APL eval: ''sd data''
APL eval: ''median =: 3 : ''''m =. <. -: # y ⋄ s =. /:~ y ⋄ if. 2 | # y do. m { s else. -: +/ (m - 1 0) { s end.''''''
APL eval: ''median data''
APL eval: ''median 3 1 4 1 5''

The correlation of two lists is the covariance over the product of the standard deviations. The explicit form below is a transcription of the formula, with x and y as in the text.

APL eval: ''x =: 1 2 3 4 5''
APL eval: ''y =: 2 4 5 4 5''
APL eval: ''cor =: 4 : ''''(+/ (x - mean x) * (y - mean y)) % %: (+/ *: x - mean x) * +/ *: y - mean y''''''
APL eval: ''x cor y''
APL eval: ''x cor 2 * x''

A histogram is a count of how many values fall in each interval: I. says which interval of a sorted list of limits each value is in, and comparing that with the interval numbers gives a table of 0 and 1 whose row sums are the counts.

APL eval: ''limits =: 10 20 30''
APL eval: ''limits I. data''
APL eval: ''+/"1 (i. 4) =/ limits I. data''
APL eval: ''(<. data % 10) { ''''abcde'''''''!
operators
	^TutorialLesson title: 'Adverbs and conjunctions of your own' text:
'A definition whose left argument is 1 makes an adverb and one with 2 makes a conjunction. In their text, u (and v) are the verbs given to them, m (and n) the nouns, and x and y the arguments of the verb that results.

APL eval: ''twice =: 1 : ''''u u y''''''
APL eval: ''*: twice 3''
APL eval: ''+ twice 10''
APL eval: ''compose2 =: 2 : ''''u v y''''''
APL eval: ''(*: compose2 >:) 4''
APL eval: ''repeat =: 2 : ''''u ^: n y''''''
APL eval: ''(*: repeat 3) 2''

Some of the primitive conjunctions deserve a second look. &. (under) applies a verb under a transformation: u &. v y is the inverse of v applied to u of v y. It needs the inverse to be known, which it is for the arithmetic verbs, reversal, transposition, boxing and the bonds of them.

APL eval: ''+: &. - 3''
APL eval: ''|. &. > ''''ab'''' ; ''''cd''''''
APL eval: ''- &. > 1 ; 2''
APL eval: ''<: &. (^&2) 9''
APL eval: ''(*&2) ^: _1 (8)''
APL eval: ''(-&1) ^: _1 (5)''

The power with an infinite right argument runs until the result stops changing, which is how a fixed point or a converging sequence is written. Newton''s method for a square root is a good example: each step replaces y by the average of y and x divided by y.

APL eval: ''sqrtn =: 3 : ''''(-: @: (+ y & %)) ^: _ ] y''''''
APL eval: ''9!!:11 (12)''
APL eval: ''sqrtn 2''
APL eval: ''9!!:11 (6)'''!
glyphs
	^TutorialLesson title: 'The classic APL glyphs' text:
'The spellings of this language are J''s: one or two keys for each verb. The glyphs of classic APL can be typed instead, wherever you can type them, and are replaced by the J spelling when the text is read (except inside a quoted string). A high minus on a number is written with the usual high minus sign. The glyph for the diamond that separates statements is accepted too, and the glyph for a comment starts one.

APL eval: ''⍳ 5''
APL eval: ''⍴ 2 3 ⍴ ⍳ 6''
APL eval: ''+/ ⍳ 10''
APL eval: ''x ← 3 4''
APL eval: ''x × 2''
APL eval: ''⌽ ⍳ 4''
APL eval: ''⍉ 2 3 ⍴ ⍳ 6''
APL eval: ''⍋ 3 1 2''
APL eval: ''¯5 + 3''
APL eval: ''(⌈/ ⍳ 4) ÷ 2''

The correspondence is a table you can read from Smalltalk: each element is the glyph followed by its spelling.

APL glyphs

It covers the monads and dyads that exist in both languages. The glyph for the each operator becomes &.> and the glyph for transposing a table becomes |: . What differs in meaning is not hidden: the glyph for reshape also means shape, as $ does, and the glyph for the first axis reversal is the same as for the last, since the only reversal is of the first axis. A language that is not APL, however many glyphs it accepts, behaves as its spellings say.'!
bridge
	^TutorialLesson title: 'The bridge to Smalltalk' text:
'Values cross the bridge in both directions. APL evalValue: answers the value of the last sentence as an object, an APLArray, and asSmalltalk turns an array into the nearest Smalltalk thing: a number, a character, a String, or an Array (an Array of Arrays for a table).

APL evalValue: ''1 2 3 + 4''
(APL evalValue: ''2 3 $ i. 6'') asSmalltalk
(APL evalValue: ''''''abc'''''') asSmalltalk
(APLArray fromSmalltalk: #(#(1 2) #(3 4))) shape
#(1 2 3) asAPL
(APLArray fromSmalltalk: #(''ab'' ''cde'')) asSmalltalk

Collections of Smalltalk objects become arrays with a shape that matches: rows of the same length make a table, and anything ragged or mixed becomes boxes. A private session has its own names, and at:put: puts a Smalltalk object into a name.

| s | s := APL new. s at: ''v'' put: #(3 1 4 1 5). s eval: ''+/ v''
| s | s := APL new. s eval: ''sq =: 3 : ''''y * y''''''. s eval: ''sq 1 2 3''
APL call: ''+/'' on: #(1 2 3)
APL call: ''%'' on: 1 and: 4

call:on: applies a verb written in the language to an object and answers an object. A verb can also be written in Smalltalk: the blocks get and answer ordinary Smalltalk objects.

| s | s := APL new. s defineVerb: ''rev'' monad: [:y | y reverse] dyad: nil. s eval: ''rev 1 2 3''

The other direction is the verb st, which evaluates a string of Smalltalk and brings the answer back as an array. With a left argument that argument is x in the text.

APL eval: ''st ''''3 + 4''''''
APL eval: ''st ''''#(1 2 3) reverse''''''
APL eval: ''1 2 3 st ''''x inject: 0 into: [:a :b | a + b]''''''
APL eval: ''''''hello'''' st ''''x asUppercase''''''

An error inside the language is an APLError, with the J message as its text.

[APL eval: ''1 + ''''a''''''] on: APLError do: [:e | e messageText]
[APL eval: ''nonesuch''] on: APLError do: [:e | e messageText]'!
oneliners
	^TutorialLesson title: 'Some famous one-liners' text:
'The same few ideas, combined in different ways, solve many problems in one line. The primes are a verb: p: makes them, q: factors a number, and 1 p: tests one. To filter a list of numbers by a condition use the hook (#~ test ]), which copies each item as many times as its flag says.

APL eval: ''p: i. 10''
APL eval: ''q: 360''
APL eval: ''1 p: 7 8 9''
APL eval: ''(#~ 1 p: ]) i. 50''
APL eval: ''(2 }. i. 30) -. , (2 }. i. 6) */ 2 }. i. 15''

The second of the two prime sieves is the oldest: take the numbers from 2, remove every product of two of them (the table of the small ones times all the others is enough). And the Fibonacci numbers come out of a matrix power as well, the second of the next pair. Triangular numbers, factorials and the table of binomial coefficients are scans and tables:

APL eval: ''+/\ >: i. 10''
APL eval: ''*/\ >: i. 8''
APL eval: ''!!/~ i. 6''
APL eval: ''(+/ , */) 1 2 3 4''
APL eval: ''*/ !! 1 2 3 4''

The Fibonacci numbers by power: start with the list 0 1 and apply a step that appends the sum of the last two.

APL eval: ''(, +/ @ (_2 & {.)) ^: 8 (0 1)''
APL eval: ''(2 2 $ 1 1 1 0) +/ . * ^: 10 (1 0)''

A word count is a key adverb, and the count of the vowels in a text is a membership test and a sum:

APL eval: ''w =: ;: ''''to be or not to be that is the question''''''
APL eval: ''(~. w) ,. <"0 #/.~ w''
APL eval: ''+/ ''''aeiou'''' e.~ ''''the quick brown fox jumps over the lazy dog''''''
APL eval: ''/:~ ~. w''
APL eval: ''|. &. > w''

A palindrome test is the string equal to its reverse, and the decimal digits of a number are the base ten antibase:

APL eval: ''pal =: 3 : ''''y -: |. y''''''
APL eval: ''pal ''''racecar''''''
APL eval: ''pal ''''racecars''''''
APL eval: ''10 #: 2 ^ 20''
APL eval: ''+/ 10 #: 2 ^ 100'''!
whatnext
	^TutorialLesson title: 'What next' text:
'You have seen the whole design: arrays of any rank, verbs that work item by item or cell by cell, adverbs and conjunctions that make new verbs from old, definitions with and without mentioning arguments, boxes for things that do not fit an array, and a bridge to Smalltalk.

The differences from J that are worth knowing: whole numbers never overflow into floats, and a float that is whole is shown as one; there are no complex numbers, so the square root of a negative number is a domain error; gerunds and the agenda conjunction, locales, the foreign conjunction beyond a few precision settings, and most of the sparse and file facilities are not here. The dictionary of J (on the J Software site) is the reference for the rest, and nearly every sentence in it that uses what is here will run. The J primer, Learning J, is a good second book.

To see what a primitive is called, evaluate its spelling alone: a verb prints as its spelling. To see what a name holds, evaluate the name. To follow a long sentence, break it at the verbs and run the right-hand parts first, which is exactly the order the language uses.

APL eval: ''+/ % #''
APL eval: ''mean''
APL eval: ''(+/ % #) &. >''
APL glyphs size

The classes are small enough to read: APLLexer reads a sentence into words, APL (the parser file) reduces them with the rules of J''s parse table, APLVerb applies a verb with its ranks, APLPrims holds the primitives, and APLFormat draws the arrays. The workspace is APLTool open, or apl workspace in the System menu.

To start this tutorial again send APLTutorial go, and APLTutorial goTo: ''Rank'' jumps to a lesson.'! !
