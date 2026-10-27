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
    const char *files[] = { "kernel1.st", "kernel2.st", "kernel3.st" };
    for (int i = 0; i < 3; i++) if (!file_in(files[i], err, sizeof err)) { printf("%s: %s\n", files[i], err); }
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
    check("10 / 4", "2.5");
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
    check("1000000000 * 1000000000 * 1000000000", "1e+27");
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
    printf("\n%d failures\n", failures);
    printf("Transcript:\n%s", transcript_text ? transcript_text : "");
    return failures ? 1 : 0;
}
