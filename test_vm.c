/* test_vm.c - headless smoke test: load the kernel and evaluate expressions */
#include "st.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern oop pending_inspect;

static int failures = 0;
static int quiet = 0;      /* when set, check() reports only failures */
static void check(const char *expr, const char *expected) {
    char err[512];
    oop r = interp_eval(nilobj, expr, err, sizeof err);
    char *s;
    if (interp.failed) { s = malloc(strlen(interp.error) + 16); sprintf(s, "ERROR: %s", interp.error); interp.failed = false; }
    else s = str_cstr(interp_print_string(r));
    int ok = strcmp(s, expected) == 0;
    if (!ok) failures++;
    if (!ok || !quiet) printf("%s  %-50s => %s%s%s\n", ok ? "ok  " : "FAIL", expr, s, ok ? "" : "   expected: ", ok ? "" : expected);
    free(s);
}

/* test_lib.txt: one test per line, "expression ==> expected printString" (# starts a comment) */
static int run_lib_tests(const char *path) {
    FILE *f = fopen(path, "r"); if (!f) { printf("FAIL  cannot open %s\n", path); failures++; return 0; }
    char line[8192]; int n = 0; quiet = 1;
    while (fgets(line, sizeof line, f)) {
        size_t len = strlen(line); while (len && (line[len - 1] == '\n' || line[len - 1] == '\r')) line[--len] = 0;
        if (!len || (line[0] == '#' && line[1] == ' ')) continue;   /* a comment starts with '# ' (a literal array or symbol starts with '#' directly) */
        if (!strncmp(line, "@consult ", 9)) { char expr[4096]; snprintf(expr, sizeof expr, "Prolog consultFile: '%s'", line + 9); check(expr, "true"); n++; continue; }
        char *sep = NULL, *p = line; while ((p = strstr(p, " ==> "))) { sep = p; p += 5; }   /* the last separator */
        if (!sep) { printf("FAIL  bad test line: %s\n", line); failures++; continue; }
        *sep = 0;
        if (!strncmp(line, "?- ", 3)) {        /* a Prolog goal: compare the text of Prolog answerLine: */
            char expr[8192], want[8192]; int e = 0, w = 0;
            e += snprintf(expr + e, sizeof expr - e, "Prolog answerLine: '");
            for (const char *c = line + 3; *c && e < (int)sizeof expr - 4; c++) { if (*c == '\'') expr[e++] = '\''; expr[e++] = *c; }
            expr[e++] = '\''; expr[e] = 0;
            want[w++] = '\''; for (const char *c = sep + 5; *c && w < (int)sizeof want - 4; c++) { if (*c == '\'') want[w++] = '\''; want[w++] = *c; }
            want[w++] = '\''; want[w] = 0;
            check(expr, want);
        } else check(line, sep + 5);
        n++;
    }
    fclose(f); quiet = 0; return n;
}

int main(int argc, char **argv) {
    char err[512];
    const char *test_image = getenv("ST_TEST_IMAGE");   /* run the whole suite on a system loaded from an image */
    if (test_image) {
        if (!image_load(test_image, err, sizeof err)) { printf("FAIL  cannot load image %s: %s\n", test_image, err); return 1; }
        printf("--- running on the image %s ---\n", test_image);
    } else {
        st_init();
        if (!load_kernel(".", err, sizeof err)) printf("kernel: %s\n", err);
    }
    gc_add_root(&pending_inspect);
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
    check("(2 raisedTo: 64) asFloat", "1.8446744073709552e19");
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
    /* ---- exceptions, unwinding, thisContext (run twice: normally, then with a GC every few allocations) ---- */
    for (int pass = 0; pass < 2; pass++) {
        size_t saved_threshold = gc_threshold;
        if (pass == 1) { gc_threshold = 2000; gc_growth_pct = 0; printf("--- exceptions again under GC stress ---\n"); }
        check("[1/0] on: ZeroDivide do: [:e | e return: 5]", "5");
        check("[1/0. 'not reached'] on: ZeroDivide do: [:e | 'handled']", "'handled'");
        check("[1/0] on: ZeroDivide do: [:e | e messageText]", "'division by zero'");
        check("[1/0] on: ZeroDivide do: [:e | e dividend]", "1");
        check("[(1/0) + 10] on: ZeroDivide do: [:e | e resume: 5]", "15");
        check("[Error signal: 'x'. 7] on: Error do: [:e | e retryUsing: [8]]", "8");
        check("| n | n := 0. [n := n + 1. n < 3 ifTrue: [Error signal: 'again']. n] on: Error do: [:e | e retry]", "3");
        check("[Error signal: 'a'. 5] on: Error do: [:e | e return]", "nil");
        check("[Error new signal. 5] on: Error do: [:e | e messageText]", "'An exception has occurred'");
        check("[Error signal: 'no'] on: Error do: [:e | e resume: 1]", "ERROR: IllegalResumeAttempt: this exception is not resumable");
        check("[(Warning signal: 'w') + 1] on: Warning do: [:e | e resume: 7]", "8");
        check("(Notification signal: 'n') printString", "'nil'");
        check("[nil foo] on: MessageNotUnderstood do: [:e | e message selector]", "#foo");
        check("[nil foo: 1 bar: 2] on: MessageNotUnderstood do: [:e | e message arguments]", "#(1 2)");
        check("[nil foo. 5] on: MessageNotUnderstood do: [:e | e resume: 3]", "5");
        check("[#(1 2 3) at: 10] on: SubscriptOutOfBounds do: [:e | e messageText]", "'subscript out of bounds: 10'");
        check("[Dictionary new at: #zz] on: KeyNotFound do: [:e | e key]", "#zz");
        check("[1/0] on: Error do: [:e | 'ZeroDivide is an Error']", "'ZeroDivide is an Error'");
        check("[nil foo] on: ZeroDivide, MessageNotUnderstood do: [:e | 'set']", "'set'");
        check("[nil foo] on: ZeroDivide do: [:e | 'wrong']", "ERROR: does not understand #foo");
        check("[[1/0] on: MessageNotUnderstood do: [:e | 'inner']] on: ZeroDivide do: [:e | 'outer']", "'outer'");
        check("[[1/0] on: ZeroDivide do: [:e | e pass]] on: ZeroDivide do: [:e | 'passed']", "'passed'");
        check("[[1/0] on: ZeroDivide do: [:e | e signal]] on: ZeroDivide do: [:e | 'resignaled']", "'resignaled'");
        check("[Error signal: 'x'] on: Error do: [:e | [e signal] on: Error do: [:e2 | 'nested']]", "'nested'");
        check("[[Error signal: 'q'] on: Error do: [:e | e outer. 'after outer']] on: Error do: [:e | e return: 'outer returned']", "'outer returned'");
        check("[[Warning signal: 'q'. 'resumed'] on: Warning do: [:e | e outer. e resume: 1]] on: Warning do: [:e | e resume: 2]", "'resumed'");
        check("[[Warning signal: 'q'] on: Warning do: [:e | e outer printString]] on: Warning do: [:e | e resume: 42]", "'42'");
        check("[[1/0] on: ZeroDivide do: [:e | Error signal: 'in handler']] on: Error do: [:e | e messageText]", "'in handler'");
        check("[[1/0] on: ZeroDivide do: [:e | 1/0]] on: ZeroDivide do: [:e | 'outside']", "'outside'");
        check("Error subclass: #MyErr instanceVariableNames: 'code' classVariableNames: '' category: 'T'. MyErr compile: 'code ^code'. MyErr compile: 'code: c code := c'. [MyErr new code: 42; signal: 'm'] on: MyErr do: [:e | e code]", "42");
        check("MyErr new signal: 'unhandled'", "ERROR: unhandled");
        /* ensure: / ifCurtailed: */
        check("| log | log := OrderedCollection new. [[log add: 1. 1/0. log add: 2] ensure: [log add: 3]] on: ZeroDivide do: [:e | log add: 4]. log", "OrderedCollection (1 4 3)");
        check("| log | log := OrderedCollection new. [[1/0] ifCurtailed: [log add: 3]] on: ZeroDivide do: [:e | log add: 4]. log", "OrderedCollection (4 3)");
        check("| log | log := OrderedCollection new. [[(1/0) printString. log add: 2] ensure: [log add: 3]] on: ZeroDivide do: [:e | e resume: 0]. log", "OrderedCollection (2 3)");
        check("| log | log := OrderedCollection new. [[(1/0) printString] ifCurtailed: [log add: 3]] on: ZeroDivide do: [:e | e resume: 0]. log", "OrderedCollection ()");
        check("| log | log := OrderedCollection new. [[[1/0] ensure: [log add: #inner]] ensure: [log add: #outer]] on: ZeroDivide do: [:e | log add: #handler]. log", "OrderedCollection (#handler #inner #outer)");
        check("Object subclass: #Nl instanceVariableNames: 'log' classVariableNames: '' category: 'T'. Nl compile: 'run log := OrderedCollection new. #(1 2 3) do: [:i | [i = 2 ifTrue: [^log]. log add: i] ensure: [log add: i negated]]. ^log'. Nl new run", "OrderedCollection (1 -1 -2)");
        check("[^3] ensure: [Transcript show: 'ensure ran on ^'; cr]", "3");
        check("[[1/0] ensure: [Transcript show: 'ensure ran on error'; cr]] value", "ERROR: division by zero");
        check("| log | log := OrderedCollection new. [[1/0] ensure: [log add: 1]] on: Error do: [:e | e retryUsing: [log add: 2]]. log", "OrderedCollection (1 2)");
        check("| s | s := 0. 1 to: 500 do: [:i | s := s + ([i \\\\ 2 = 0 ifTrue: [Error signal: 'e']. 1] on: Error do: [:e | e return: 2])]. s", "750");
        /* thisContext */
        check("Object subclass: #CtxT instanceVariableNames: '' classVariableNames: '' category: 'T'. CtxT compile: 'who ^thisContext sender selector'. CtxT compile: 'caller ^self who'. CtxT new caller", "#caller");
        check("CtxT compile: 'early thisContext return: 5. ^6'. CtxT new early", "5");
        check("CtxT compile: 'tmps | a b | a := 10. b := 20. ^thisContext tempAt: 2'. CtxT new tmps", "20");
        check("CtxT compile: 'setTmp | a | a := 1. thisContext tempAt: 1 put: 99. ^a'. CtxT new setTmp", "99");
        check("CtxT compile: 'blk ^[thisContext] value'. CtxT new blk isBlockContext", "true");
        check("CtxT compile: 'kept ^thisContext'. CtxT new kept isDead", "true");
        check("CtxT compile: 'inner thisContext sender resume: 100. ^0'. CtxT compile: 'outer ^1 + self inner'. CtxT new outer", "101");
        check("CtxT compile: 'ens | log | log := OrderedCollection new. [self kill: log] ensure: [log add: #ensure]. ^log'. CtxT compile: 'kill: log log add: #before. thisContext sender sender return: 7. log add: #never'. CtxT new ens", "OrderedCollection (#before #ensure)");
        check("CtxT new kept printString", "'CtxT>>kept'");
        check("[CtxT new kept resume: 1] on: Error do: [:e | e messageText]", "'cannot resume a dead context'");
        gc_threshold = saved_threshold; gc_growth_pct = 100;
    }
    /* ---- the class library: test_lib.txt, run normally and then with a GC every few allocations ---- */
    for (int pass = 0; pass < 2; pass++) {
        size_t saved_threshold = gc_threshold;
        if (pass == 1) { gc_threshold = 2000; gc_growth_pct = 0; }    /* stress: no proportional growth, collect every few allocations */
        int n = run_lib_tests("test_lib.txt");
        printf("ok    library tests%s: %d run\n", pass ? " under GC stress" : "", n);
        check("Smalltalk loadPackage: 'Prolog'", "true");
        if (pass == 1) gc_threshold = 400000;     /* the packages' heaps are large: collect often, but not after every few allocations */
        n = run_lib_tests("packages/Prolog/tests/tests.txt");
        printf("ok    Prolog package tests%s: %d run\n", pass ? " under GC stress" : "", n);
        check("Smalltalk loadPackage: 'Bio'", "true");
        n = run_lib_tests("packages/Bio/tests/tests.txt");
        printf("ok    Bio package tests%s: %d run\n", pass ? " under GC stress" : "", n);
        check("Smalltalk loadPackage: 'SUnit'", "true");
        n = run_lib_tests("packages/SUnit/tests/tests.txt");
        printf("ok    SUnit package tests%s: %d run\n", pass ? " under GC stress" : "", n);
        check("Smalltalk loadPackage: 'Debugger'", "true");
        n = run_lib_tests("packages/Debugger/tests/tests.txt");
        printf("ok    Debugger package tests%s: %d run\n", pass ? " under GC stress" : "", n);
        check("Smalltalk loadPackage: 'Regex'", "true");
        n = run_lib_tests("packages/Regex/tests/tests.txt");
        printf("ok    Regex package tests%s: %d run\n", pass ? " under GC stress" : "", n);
        check("Smalltalk loadPackage: 'Phylo'", "true");
        n = run_lib_tests("packages/Phylo/tests/tests.txt");
        printf("ok    Phylo package tests%s: %d run\n", pass ? " under GC stress" : "", n);
        check("Smalltalk loadPackage: 'Stats'", "true");
        n = run_lib_tests("packages/Stats/tests/tests.txt");
        printf("ok    Stats package tests%s: %d run\n", pass ? " under GC stress" : "", n);
        /* Greek: a few conjugations and declensions here, the rest in its tests.txt */
        check("Smalltalk loadPackage: 'Greek'", "true");
        check("'γράφω' asGreekVerb conjugate: #present", "#('γράφω' 'γράφεις' 'γράφει' 'γράφουμε' 'γράφετε' 'γράφουν')");
        check("'γράφω' asGreekVerb conjugate: #aorist", "#('έγραψα' 'έγραψες' 'έγραψε' 'γράψαμε' 'γράψατε' 'έγραψαν')");
        check("'αγαπάω' asGreekVerb passive: #aorist", "#('αγαπήθηκα' 'αγαπήθηκες' 'αγαπήθηκε' 'αγαπηθήκαμε' 'αγαπηθήκατε' 'αγαπήθηκαν')");
        check("'βλέπω' asGreekVerb futureSimple", "#('θα δω' 'θα δεις' 'θα δει' 'θα δούμε' 'θα δείτε' 'θα δουν')");
        check("GreekNoun plural: 'άνθρωπος'", "'άνθρωποι'");
        check("'άνθρωπος' asGreekNoun genitive", "'ανθρώπου'");
        check("'όνομα' asGreekNoun plurals", "#('ονόματα' 'ονομάτων' 'ονόματα' 'ονόματα')");
        check("('μεγάλος' asGreekAdjective with: 'θάλασσα' asGreekNoun) case: #accusative number: #singular", "'τη μεγάλη θάλασσα'");
        n = run_lib_tests("packages/Greek/tests/tests.txt");
        printf("ok    Greek package tests%s: %d run\n", pass ? " under GC stress" : "", n);
        gc_threshold = saved_threshold; gc_growth_pct = 100;
    }
    /* ---- background time slices: a busy forked process is preempted by the deadline and resumed where it stopped ---- */
    {
        check("BgN := 0. BgP := [[true] whileTrue: [BgN := BgN + 1]] fork. BgN", "0");
        interp_run_background(15);
        check("BgN > 1000", "true");
        check("BgSeen := BgN. BgSeen > 0", "true");
        interp_run_background(15);
        check("BgN > BgSeen", "true");
        /* the same, through sends rather than a bare loop (preemption at sends); a preempted process goes back to the front of its queue, so stop the first one */
        check("BgP terminate. 1", "1");
        check("BgM := 0. BgQ := [[true] whileTrue: [BgM := BgM + (BgM printString size)]] fork. BgM", "0");
        interp_run_background(15);
        check("BgM > 100", "true");
        check("BgQ terminate. 1", "1");
    }
    /* ---- the tutorials: once, not in both passes. They are read in from disk on demand, and keeping
       them all in the image would slow every later collection down for no gain. ---- */
    {
        int n = run_lib_tests("test_tutorials.txt");
        printf("ok    tutorials: %d run\n", n);
    }
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
    /* ---- images: save this system, start `st` from the file, and compare what it answers ---- */
    if (!test_image) {
        check("Object subclass: #ImgT instanceVariableNames: 'v' classVariableNames: '' category: 'T'. ImgT compile: 'v ^v ifNil: [7]'. ImgT new v", "7");
        check("Smalltalk at: #ImgSet put: (Set new add: ImgT new; add: 'str'; add: #sym; add: 42; add: 3.5; yourself). ImgSet size", "5");
        check("Smalltalk at: #ImgIds put: IdentityDictionary new. ImgIds at: ImgSet put: 99. ImgIds at: ImgSet", "99");
        check("Smalltalk at: #ImgBig put: 100 factorial. ImgBig printString size", "158");
        check("Smalltalk at: #ImgWide put: 'héllo' asWideString. ImgWide size", "5");
        check("Smalltalk snapshotAs: 'test_image.image'", "true");
        check("Smalltalk snapshotAs: '/nonexistent-dir/x.image'", "ERROR: cannot write /nonexistent-dir/x.image.tmp: No such file or directory");
        struct { const char *expr, *expect; } img[] = {
            { "ImgT new v", "7" }, { "ImgSet size", "5" }, { "ImgSet includes: 'str'", "true" }, { "ImgSet includes: #sym", "true" },
            { "ImgSet includes: 3.5", "true" }, { "ImgSet includes: 42", "true" }, { "ImgIds at: ImgSet", "99" },
            { "ImgBig printString size", "158" }, { "ImgWide utf8Encoded size", "6" }, { "#foo == #foo", "true" },
            { "'abc' asSymbol == #abc", "true" }, { "[1/0] on: ZeroDivide do: [:e | e return: 5]", "5" },
            { "| d | d := Dictionary new. d at: 'k' put: 1. d at: 'k'", "1" }, { "Date today class name", "#Date" },
            { "Object subclass: #ImgU instanceVariableNames: '' classVariableNames: '' category: 'T'. ImgU new printString", "'an ImgU'" },
            { "Smalltalk garbageCollect. ImgSet size", "5" }, { "(1 to: 2000) inject: 0 into: [:a :b | a + b]", "2001000" } };
        int nimg = (int)(sizeof img / sizeof img[0]);
        char cmd[16384] = "./st -i test_image.image"; 
        for (int i = 0; i < nimg; i++) {   /* single-quote each expression for the shell, escaping the quotes inside it */
            strcat(cmd, " -e '");
            for (const char *c = img[i].expr; *c; c++) { if (*c == '\'') strcat(cmd, "'\\''"); else strncat(cmd, c, 1); }
            strcat(cmd, "'");
        }
        strcat(cmd, " > test_image.out 2>&1");
        int rc = system(cmd);
        FILE *f = fopen("test_image.out", "r");
        for (int i = 0; i < nimg; i++) {
            char line[1024] = ""; if (!f || !fgets(line, sizeof line, f)) line[0] = 0;
            size_t n = strlen(line); while (n && (line[n - 1] == '\n')) line[--n] = 0;
            int ok = rc == 0 && strcmp(line, img[i].expect) == 0; if (!ok) failures++;
            printf("%s  [image] %-50s => %s%s%s\n", ok ? "ok  " : "FAIL", img[i].expr, line, ok ? "" : "   expected: ", ok ? "" : img[i].expect);
        }
        if (f) fclose(f);
        /* an image that is truncated, or not an image, is refused with a message */
        system("head -c 3000 test_image.image > test_trunc.image; echo 'not an image' > test_junk.image");
        system("./st -i test_trunc.image -e 1 > test_image.out 2>&1; ./st -i test_junk.image -e 1 >> test_image.out 2>&1");
        f = fopen("test_image.out", "r"); char all[2048] = ""; if (f) { size_t got = fread(all, 1, sizeof all - 1, f); all[got] = 0; fclose(f); }
        int ok = strstr(all, "truncated or damaged") && strstr(all, "not a Smalltalk image"); if (!ok) failures++;
        printf("%s  [image] damaged and non-image files are refused\n", ok ? "ok  " : "FAIL");
        remove("test_image.image"); remove("test_image.out"); remove("test_trunc.image"); remove("test_junk.image");
    }
    printf("\n%d failures\n", failures);
    printf("Transcript:\n%s", transcript_text ? transcript_text : "");
    return failures ? 1 : 0;
}
