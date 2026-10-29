/* test_vm.c - headless smoke test: load the kernel and evaluate expressions */
#include "st.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern oop pending_inspect;

static int failures = 0;
static void check(const char *expr, const char *expected) {
    char err[512];
    oop r = interp_eval(nilobj, expr, err, sizeof err);
    char *s;
    if (interp.failed) { s = malloc(strlen(interp.error) + 16); sprintf(s, "ERROR: %s", interp.error); interp.failed = false; }
    else s = str_cstr(interp_print_string(r));
    int ok = strcmp(s, expected) == 0;
    if (!ok) failures++;
    printf("%s  %-50s => %s%s%s\n", ok ? "ok  " : "FAIL", expr, s, ok ? "" : "   expected: ", ok ? "" : expected);
    free(s);
}

int main(int argc, char **argv) {
    st_init();
    gc_add_root(&pending_inspect);
    char err[512];
    if (!load_kernel(".", err, sizeof err)) printf("kernel: %s\n", err);
    if (argc > 1) {   /* evaluate expressions from the command line */
        for (int i = 1; i < argc; i++) {
            oop r = interp_eval(nilobj, argv[i], err, sizeof err);
            if (interp.failed) { printf("Error: %s\n%s", interp.error, interp.walkback); interp.failed = false; }
            else { char *s = str_cstr(interp_print_string(r)); printf("%s\n", s); free(s); }
        }
        if (transcript_len) printf("--- Transcript ---\n%s\n", transcript_text);
        return 0;
    }
    check("3 + 4", "7");
    check("3 + 4 * 2", "14");
    check("10 / 4", "(5/2)");
    check("10 // 4", "2");
    check("-7 \\\\ 3", "2");
    check("2 raisedTo: 10", "1024");
    check("1000000 * 1000000", "1000000000000");
    check("3.5 + 1", "4.5");
    check("(1/3) printString size > 3", "true");
    check("#(3 1 2) asSortedCollection asArray", "#(1 2 3)");
    check("'hello' reversed", "'olleh'");
    check("'hello' asUppercase", "'HELLO'");
    check("'hello', ' world'", "'hello world'");
    check("#foo", "#foo");
    check("#foo == #foo", "true");
    check("'abc' = 'abc'", "true");
    check("$a", "$a");
    check("$a < $b", "true");
    check("| x | x := 0. 1 to: 10 do: [:i | x := x + i]. x", "55");
    check("| oc | oc := OrderedCollection new. oc add: 1; add: 2; add: 3. oc", "OrderedCollection (1 2 3)");
    check("(1 to: 5) collect: [:i | i * i]", "#(1 4 9 16 25)");
    check("(1 to: 10) select: [:i | i even]", "#(2 4 6 8 10)");
    check("(1 to: 10) inject: 0 into: [:a :b | a + b]", "55");
    check("#(1 2 3) detect: [:e | e > 1]", "2");
    check("| d | d := Dictionary new. d at: #a put: 1. d at: #b put: 2. d at: #a", "1");
    check("| d | d := Dictionary new. d at: 'x' put: 5. d at: 'x'", "5");
    check("(Dictionary new) at: #zz ifAbsent: ['none']", "'none'");
    check("nil isNil", "true");
    check("nil foo", "ERROR: does not understand #foo");
    check("3 zork: 4", "ERROR: does not understand #zork:");
    check("true & false", "false");
    check("true and: [false]", "false");
    check("3 > 2 ifTrue: ['yes'] ifFalse: ['no']", "'yes'");
    check("[:a :b | a + b] value: 1 value: 2", "3");
    check("| b | b := [:x | x > 3 ifTrue: ['big'] ifFalse: ['small']]. b value: 5", "'big'");
    check("| f | f := nil. f := [:n | n <= 1 ifTrue: [1] ifFalse: [n * (f value: n - 1)]]. f value: 10", "3628800");
    check("[:x | ^x] value: 3", "3");
    check("Object subclass: #Foo instanceVariableNames: 'a' classVariableNames: '' category: 'Test'. Foo compile: 'a ^a'. Foo compile: 'a: x a := x'. (Foo new a: 42) a", "42");
    check("Foo new printString", "'a Foo'");
    check("Foo class", "Foo class");
    check("Foo class class", "Metaclass");
    check("Foo superclass", "Object");
    check("Foo compile: 'bar ^super printString'. Foo new bar", "'a Foo'");
    check("Foo subclass: #Bar instanceVariableNames: '' classVariableNames: '' category: 'Test'. Bar compile: 'a ^super a + 1'. (Bar new a: 1) a", "2");
    check("3 @ 4", "3@4");
    check("(3 @ 4) + (1 @ 1)", "4@5");
    check("| s | s := WriteStream on: String new. s nextPutAll: 'ab'; print: 12; nextPut: $!. s contents", "'ab12!'");
    check("| s | s := ReadStream on: #(1 2 3). s next. s next", "2");
    check("'one two three' substrings", "OrderedCollection ('one' 'two' 'three')");
    check("1000000000 * 1000000000 * 1000000000", "1000000000000000000000000000");
    check("100 factorial printString size > 10", "true");
    check("Smalltalk at: #Gx put: 3. Gx + 1", "4");
    check("Transcript show: 'hi'; cr. 1", "1");
    check("#(1 $a 'str' #sym (1 2) nil true) size", "7");
    check("{1+1. 2+2}", "#(2 4)");
    check("'3.25' asNumber", "3.25");
    check("12 printString: 2", "'1100'");
    check("255 printString: 16", "'FF'");
    check("16r1F", "31");
    check("1e3", "1000");
    check("(Set withAll: #(1 2 2 3)) size", "3");
    check("thisContext printString", "'UndefinedObject>>DoIt'");
    check("[1/0] value", "ERROR: division by zero");
    check("| a | a := Array new: 3. a at: 4 put: 1", "ERROR: subscript out of bounds: 4");
    check("Foo removeSelector: #bar. Foo includesSelector: #bar", "false");
    check("'abc' < 'abd'", "true");
    check("#(1 2 3) , #(4)", "#(1 2 3 4)");
    check("(1 to: 3) asOrderedCollection removeFirst", "1");
    check("| i | i := 0. [i < 5] whileTrue: [i := i + 1]. i", "5");
    check("| i | i := 0. [i >= 5] whileFalse: [i := i + 1]. i", "5");
    check("5 timesRepeat: []. 5 between: 1 and: 10", "true");
    check("Object new foo: 1 bar: 2", "ERROR: does not understand #foo:bar:");
    check("Bar allSuperclasses asArray", "#(Foo Object)");
    check("Foo subclasses asArray", "#(Bar)");
    check("Smalltalk allClasses size > 40", "true");
    check("(Foo >> #a) printString", "'Foo>>a'");
    check("Random new next < 1", "true");
    check("1 to: 3 do: [:i | i printNl]. 1", "1");
    check("(1 to: 10 by: 3) asArray", "#(1 4 7 10)");
    check("3 max: 9", "9");
    check("-3 abs", "3");
    check("2 sqrt * 2 sqrt", "2.0000000000000004");
    check("7 \\\\ 2 = 1", "true");
    check("'Hello World' occurrencesOf: $o", "2");
    check("'hello' indexOf: $l", "3");
    check("'hello' copyFrom: 2 to: 4", "'ell'");
    check("'hello world' copyReplaceAll: 'o' with: '0'", "'hell0 w0rld'");
    check("'  x  ' withBlanksTrimmed", "'x'");
    check("(2 ** 0.5) < 1.5", "true");
    check("1 = 1.0", "true");
    check("Error signal: 'boom'", "ERROR: boom");
    check("[:x | ] value: 3", "nil");
    check("| x | x := 3. [x := x + 1] value. x", "4");
    check("3 evaluate: 'self + 4'", "7");
    check("Smalltalk fileInString: '!Foo methodsFor: ''x''!\nzip ^#zip! !'. Foo new zip", "#zip");
    check("| s | s := SortedCollection sortBlock: [:a :b | a > b]. s add: 1; add: 3; add: 2. s asArray", "#(3 2 1)");
    /* ---- exact arithmetic: fractions and large integers ---- */
    check("(1/3) + (2/3)", "1");
    check("(1/3) + (1/6)", "(1/2)");
    check("(3/4) * 4", "3");
    check("(1/2) < (2/3)", "true");
    check("(1/2) = 0.5", "true");
    check("(1/2) + 0.5", "1.0");
    check("2 raisedTo: -2", "(1/4)");
    check("(2/3) reciprocal", "(3/2)");
    check("(7/2) truncated", "3");
    check("(7/2) floor", "3");
    check("(7/2) rounded", "4");
    check("(-7/2) negated", "(7/2)");
    check("(1/3) printString", "'(1/3)'");
    check("(1/3) asFloat < 0.34", "true");
    check("100 factorial printString size", "158");
    check("30 factorial", "265252859812191058636308480000000");
    check("(2 raisedTo: 100) printString", "'1267650600228229401496703205376'");
    check("(2 raisedTo: 100) - (2 raisedTo: 100) + 1", "1");
    check("(2 raisedTo: 100) // (2 raisedTo: 90)", "1024");
    check("(2 raisedTo: 100) \\\\ 7", "2");
    check("(2 raisedTo: 100) negated // 3", "-422550200076076467165567735126");
    check("(10 raisedTo: 20) / (10 raisedTo: 18)", "100");
    check("(10 raisedTo: 20) / 3", "(100000000000000000000/3)");
    check("(2 raisedTo: 64) class", "LargePositiveInteger");
    check("(2 raisedTo: 64) negated class", "LargeNegativeInteger");
    check("(2 raisedTo: 64) > (2 raisedTo: 63)", "true");
    check("(2 raisedTo: 64) = (2 raisedTo: 64)", "true");
    check("(2 raisedTo: 64) hash = (2 raisedTo: 64) hash", "true");
    check("| d | d := Dictionary new. d at: (2 raisedTo: 70) put: #big. d at: (2 raisedTo: 70)", "#big");
    check("(2 raisedTo: 64) asFloat", "1.8446744073709552e+19");
    check("1e20 truncated", "100000000000000000000");
    check("(2 raisedTo: 64) bitAnd: 255", "0");
    check("((2 raisedTo: 64) bitShift: -60)", "16");
    check("(1 bitShift: 70) printString: 16", "'400000000000000000'");
    check("12345678901234567890 printString", "'12345678901234567890'");
    check("12345678901234567890 * 98765432109876543210", "1219326311370217952237463801111263526900");
    check("(12345678901234567890 gcd: 9876543210)", "90");
    check("Number readFrom: (ReadStream on: '  -42abc')", "-42");
    check("Number readFrom: (ReadStream on: '3.25e2')", "325.0");
    check("Integer readFrom: (ReadStream on: '16r1F')", "31");
    check("'99' asNumber + 1", "100");
    check("0.1 + 0.2 = 0.3", "false");
    check("1.5 asExactFraction", "(3/2)");
    check("3 + (1/2)", "(7/2)");
    /* ---- dates and times ---- */
    check("(Date newDay: 28 month: #October year: 2026) printString", "'28 October 2026'");
    check("(Date newDay: 28 month: 10 year: 2026) dayName", "#Wednesday");
    check("(Date newDay: 1 month: 1 year: 1901) dayName", "#Tuesday");
    check("(Date newDay: 29 month: 2 year: 2024) dayOfYear", "60");
    check("(Date newDay: 1 month: 3 year: 2026) subtractDays: 1", "28 February 2026");
    check("(Date newDay: 31 month: 12 year: 2026) addDays: 1", "1 January 2027");
    check("(Date newDay: 1 month: 1 year: 2027) subtractDate: (Date newDay: 1 month: 1 year: 2026)", "365");
    check("Date today class", "Date");
    check("(Date readFrom: (ReadStream on: '4 July 1976')) monthIndex", "7");
    check("(Date leapYear: 2000) & (Date leapYear: 1900) not", "true");
    check("(Time hour: 13 minute: 5 second: 9) printString", "'1:05:09 pm'");
    check("(Time fromSeconds: 3661) hours", "1");
    check("((Time hour: 23 minute: 0 second: 0) addTime: (Time hour: 2 minute: 0 second: 0)) hours", "1");
    check("Time now class", "Time");
    /* ---- rectangles and points ---- */
    check("(1@2 corner: 5@6) area", "16");
    check("((0@0 corner: 10@10) intersect: (5@5 corner: 20@20))", "5@5 corner: 10@10");
    check("(0@0 corner: 10@10) containsPoint: 3@4", "true");
    check("((0@0 extent: 4@4) center)", "2@2");
    check("(3@4) r", "5.0");
    /* ---- collections ---- */
    check("| b | b := Bag new. b add: #a; add: #b; add: #a. b occurrencesOf: #a", "2");
    check("(Bag withAll: #(1 1 2)) size", "3");
    check("(IdentitySet new add: 'x' copy; add: 'x' copy; yourself) size", "2");
    check("(Set new add: 'x' copy; add: 'x' copy; yourself) size", "1");
    check("(Set withAll: #(3 1 2)) asSortedCollection asArray", "#(1 2 3)");
    check("(Set withAll: #(1 2)) = (Set withAll: #(2 1))", "true");
    check("| d | d := Dictionary new. d at: 3@4 put: 'pt'. d at: 3@4", "'pt'");
    check("| d | d := Dictionary new. d at: #(1 2) put: 'arr'. d at: #(1 2) copy", "'arr'");
    check("| s | Object subclass: #Key instanceVariableNames: 'k' classVariableNames: '' category: 'Test'. Key compile: 'k ^k'. Key compile: 'k: x k := x'. Key compile: '= o ^(o isKindOf: Key) and: [k = o k]'. Key compile: 'hash ^k hash'. s := Set new. s add: (Key new k: 1); add: (Key new k: 1). s size", "1");
    check("| d | d := Dictionary new. d at: 1 put: 2. d keys class", "Set");
    check("(Dictionary new at: 1 put: 10; at: 2 put: 20; yourself) collect: [:v | v * 2]", "Bag (20 40)");
    check("| l | l := LinkedList new. l add: (Link new); add: (Link new). l size", "2");
    check("| l a | l := LinkedList new. a := Link new. l add: a; add: Link new. l removeFirst == a", "true");
    check("(RunArray runs: #(2 3) values: #($a $b)) asArray", "#($a $a $b $b $b)");
    check("(RunArray new: 3 withAll: 7) size", "3");
    check("| r | r := RunArray new. r addLast: 1; addLast: 1; addLast: 2. r runs", "#(2 1)");
    check("(MappedCollection collection: #(10 20 30) map: #(3 1)) contents", "#(30 10)");
    check("'hello' asText size", "5");
    check("('hello' asText, ' world' asText) asString", "'hello world'");
    check("(OrderedCollection withAll: #(1 2 3)) collect: [:e | e * 2]", "OrderedCollection (2 4 6)");
    check("(OrderedCollection withAll: #(1 2 3)) reversed", "OrderedCollection (3 2 1)");
    check("(OrderedCollection withAll: #(1 2 3)) , #(4)", "OrderedCollection (1 2 3 4)");
    check("(OrderedCollection withAll: #(1 2 3 4)) copyFrom: 2 to: 3", "OrderedCollection (2 3)");
    check("(1 to: 5) asOrderedCollection removeFirst: 2", "OrderedCollection (1 2)");
    check("#(1 2 3) copyReplaceFrom: 2 to: 2 with: #(9 9)", "#(1 9 9 3)");
    check("#(3 1 2) detectMax: [:e | e]", "3");
    check("'h*o w#rld' match: 'Hello World'", "true");
    check("'h*x' match: 'hello'", "false");
    check("'a.b.c' copyUpTo: $.", "'a'");
    check("'a.b.c' copyAfterLast: $.", "'c'");
    check("#at:put: numArgs", "2");
    check("#at:put: keywords", "#(#at: #put:)");
    check("#+ isBinary", "true");
    check("#(1 $a 'b' #c) storeString", "'((Array new: 4) at: 1 put: 1; at: 2 put: $a; at: 3 put: ''b''; at: 4 put: #c; yourself)'");
    check("(3@4) storeString", "'(3 @ 4)'");
    check("(1->2) storeString", "'(1->2)'");
    check("| a | a := Array with: (OrderedCollection with: 1). a deepCopy first == a first", "false");
    check("| a | a := Array with: (OrderedCollection with: 1). a copy first == a first", "true");
    /* ---- streams and files ---- */
    check("(ReadStream on: #(1 2 3 4)) next: 2", "#(1 2)");
    check("(ReadStream on: 'abc def') upTo: $ ", "'abc'");
    check("| s | s := ReadWriteStream on: String new. s nextPutAll: 'xyz'. s reset. s next", "$x");
    check("| f | f := FileStream newFileNamed: 'test_out.txt'. f nextPutAll: 'hello file'; cr. f close. (FileStream oldFileNamed: 'test_out.txt') contentsOfEntireFile", "'hello file\n'");
    check("FileStream isAFileNamed: 'test_out.txt'", "true");
    check("FileStream remove: 'test_out.txt'. FileStream isAFileNamed: 'test_out.txt'", "false");
    check("(Random seed: 42) next class", "Float");
    check("Random new atEnd", "false");
    /* ---- processes ---- */
    check("| r | r := 0. [r := 1] fork. r", "0");
    check("| r | r := 0. [r := 1] fork. Processor yield. r", "1");
    check("| s r | s := Semaphore new. r := 0. [r := 5. s signal] fork. s wait. r", "5");
    check("| q | q := SharedQueue new. [q nextPut: 42] fork. q next", "42");
    check("| s | s := Semaphore forMutualExclusion. s critical: [3 + 4]", "7");
    check("| t | t := Time millisecondClock. (Delay forMilliseconds: 60) wait. Time millisecondClock - t >= 55", "true");
    check("| p | p := [Processor yield] newProcess. p isSuspended", "true");
    check("| p | p := [nil] newProcess. p resume. Processor yield. p isTerminated", "true");
    check("| r | r := OrderedCollection new. [r add: #low] forkAt: 3. [r add: #high] forkAt: 5. r", "OrderedCollection (#high)");
    check("| r | r := OrderedCollection new. [r add: #a] fork. [r add: #b] fork. Processor yield. r", "OrderedCollection (#a #b)");
    check("Processor activeProcess priority", "4");
    check("| p | p := [[true] whileTrue: [Processor yield]] fork. Processor yield. p terminate. p isTerminated", "true");
    check("| r d | r := 0. d := Delay forMilliseconds: 10. [d wait. r := 1] fork. d wait. (Delay forMilliseconds: 20) wait. r", "1");
    check("[Semaphore new wait] value", "ERROR: deadlock: every process is waiting");
    check("| s r | s := Semaphore new. r := nil. [s wait. r := #woken] fork. s signal. Processor yield. r", "#woken");
    /* ---- reflection ---- */
    check("thisContext class", "MethodContext");
    check("[thisContext] value class", "BlockContext");
    check("Key allInstances class", "Array");
    check("(Integer whichSelectorsReferTo: #primCompare:) includes: #<", "true");
    check("(Integer organization listAtCategoryNamed: 'private arithmetic') includes: #primAdd:", "true");
    check("Object organization categories class", "Array");
    check("(Boolean printHierarchy lines) size", "3");
    check("(Integer >> #+) messages includes: #isInteger", "true");
    check("Association superclass", "LookupKey");
    check("Set superclass", "Collection");
    check("Dictionary superclass", "Set");
    check("SystemDictionary superclass", "IdentityDictionary");
    check("Semaphore superclass", "LinkedList");
    check("Process superclass", "Link");
    check("Smalltalk allClasses size > 70", "true");
    check("| o | o := Object new. o addDependent: 3. o dependents size", "1");
    /* ---- the tutorial ---- */
    check("Smalltalk fileIn: 'tutorial.st'. Tutorial lessons size", "27");
    check("Tutorial lessons allSatisfy: [:l | l text size > 100 and: [l title size > 0]]", "true");
    check("Tutorial reset. Tutorial go title", "'Welcome'");
    check("Tutorial next title", "'Printing and doing'");
    check("Tutorial goTo: 'blocks'. Tutorial lessonNumber", "13");
    check("Tutorial last; previous. Tutorial lesson title", "'Processes'");
    check("Tutorial goOn: 99. Tutorial lessonNumber", "27");
    check("Tutorial lessonSelectors asSet size", "27");
    check("Tutorial tutorial size", "27");
    /* ---- the changes file: every route that changes code is logged, and replays ---- */
    {
        changes_path = "test_changes.st"; remove(changes_path);
        changes_logging = true; int before = changes_count;
        check("Object subclass: #Logged instanceVariableNames: 'a' classVariableNames: '' category: 'T'. Logged compile: 'a ^a ifNil: [7]' classified: 'x'. Logged new a", "7");
        check("Logged class compile: 'make ^self new' classified: 'y'. Logged make a", "7");
        check("Logged compile: 'gone ^1' classified: 'x'. Logged removeSelector: #gone. Logged includesSelector: #gone", "false");
        check("Smalltalk fileInString: '!Logged methodsFor: ''z''!\nb ^self a + 1! !'. Logged new b", "8");
        changes_logging = false;
        int logged = changes_count - before;
        printf("%s  changes logged: %d (expected 6: class, 2 compiles, 1 compile+1 removal, file-in method)\n", logged == 6 ? "ok  " : "FAIL", logged);
        if (logged != 6) failures++;
        FILE *f = fopen(changes_path, "rb"); char buf[4096] = ""; size_t got = f ? fread(buf, 1, sizeof buf - 1, f) : 0; buf[got] = 0; if (f) fclose(f);
        const char *want[] = { "Object subclass: #Logged", "instanceVariableNames: 'a'", "!Logged methodsFor: 'x'!\na ^a ifNil: [7]! !", "!Logged class methodsFor: 'y'!", "Logged removeSelector: #gone!", "!Logged methodsFor: 'z'!", "b ^self a + 1! !" };
        for (int i = 0; i < 6; i++) { int ok = strstr(buf, want[i]) != NULL; printf("%s  changes file contains: %s\n", ok ? "ok  " : "FAIL", want[i]); if (!ok) failures++; }
        /* with logging off (kernel load, -e scripts) nothing is written */
        int c0 = changes_count; check("Object subclass: #NotLogged instanceVariableNames: '' classVariableNames: '' category: 'T'. 1", "1");
        printf("%s  nothing logged while logging is off\n", changes_count == c0 ? "ok  " : "FAIL"); if (changes_count != c0) failures++;
        /* an unwritable changes file is reported, not silently ignored */
        changes_path = "/nonexistent-dir/changes.st"; changes_logging = true; int f0 = changes_failures;
        check("Object subclass: #Lost instanceVariableNames: '' classVariableNames: '' category: 'T'. 2", "2");
        changes_logging = false;
        printf("%s  failed write is counted (%d)\n", changes_failures > f0 ? "ok  " : "FAIL", changes_failures - f0); if (changes_failures <= f0) failures++;
        remove("test_changes.st");
    }
    printf("\n%d failures\n", failures);
    printf("Transcript:\n%s", transcript_text ? transcript_text : "");
    return failures ? 1 : 0;
}
