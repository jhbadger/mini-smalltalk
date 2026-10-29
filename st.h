/* st.h - shared declarations for the mini Smalltalk-80 system */
#ifndef ST_H
#define ST_H
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* ---------- objects ---------- */
typedef struct Obj *oop;
struct Obj {
    oop cls;
    uint32_t size;      /* slot count (pointers) or byte count (bytes) */
    uint8_t kind;       /* KIND_* */
    uint8_t mark;
    uint16_t pad;
    uint32_t hash;      /* identity hash */
    struct Obj *next;   /* allocation list for GC sweep */
    oop slots[];
};
enum { KIND_POINTERS = 0, KIND_INDEXED = 1, KIND_BYTES = 2 };

#define IS_INT(o)   (((intptr_t)(o)) & 1)
#define INT_VAL(o)  (((intptr_t)(o)) >> 1)
#define MK_INT(i)   ((oop)((((intptr_t)(i)) * 2) | 1))
#define INT_MAX_VAL ((intptr_t)1 << 61)
#define SLOT(o,i)   ((o)->slots[i])
#define BYTES(o)    ((unsigned char *)(o)->slots)
#define CLASS_OF(o) (IS_INT(o) ? classSmallInteger : (o)->cls)
#define FLOATVAL(o) (*(double *)BYTES(o))

/* Behavior / Class / Metaclass layout (shared prefix) */
enum { C_SUPER = 0, C_METHODS, C_FORMAT, C_NAME, C_IVARS, C_CVARS, C_CATEGORY, C_COMMENT, CLASS_SIZE };
enum { MC_THISCLASS = 3, METACLASS_SIZE };
#define FMT_SIZE(f) (INT_VAL(f) & 0xffff)
#define FMT_KIND(f) (INT_VAL(f) >> 16)
#define MK_FMT(size,kind) MK_INT((size) | ((kind) << 16))

/* CompiledMethod */
enum { M_HEADER = 0, M_LITERALS, M_BYTECODES, M_SELECTOR, M_CLASS, M_SOURCE, M_PRIM, M_CATEGORY, METHOD_SIZE };
#define HDR_ARGS(h)   (INT_VAL(h) & 0xff)
#define HDR_TEMPS(h)  ((INT_VAL(h) >> 8) & 0xff)
#define HDR_STACK(h)  ((INT_VAL(h) >> 16) & 0xff)
#define MK_HDR(a,t,s) MK_INT((a) | ((t) << 8) | ((s) << 16))

/* Context: fixed slots then temps and stack */
enum { CTX_SENDER = 0, CTX_PC, CTX_SP, CTX_METHOD, CTX_RECEIVER, CTX_HOME, CTX_OUTER, CTX_CLOSURE, CTX_FIXED };
/* BlockClosure */
enum { B_OUTER = 0, B_METHOD, B_RECEIVER, B_NUMARGS, BLOCK_SIZE };
/* Association, Dictionary, Message, Character */
enum { A_KEY = 0, A_VALUE, ASSOC_SIZE };
enum { D_TALLY = 0, D_KEYS, D_VALUES, DICT_SIZE };
enum { MSG_SELECTOR = 0, MSG_ARGS, MSG_SIZE };
enum { CH_VALUE = 0, CHAR_SIZE };
/* processes: Link, Process, LinkedList, Semaphore, ProcessorScheduler */
enum { LINK_NEXT = 0, LINK_SIZE };
enum { PR_NEXT = 0, PR_CONTEXT, PR_PRIORITY, PR_LIST, PR_NAME, PROCESS_SIZE };
enum { LL_FIRST = 0, LL_LAST, LINKEDLIST_SIZE };
enum { SEM_EXCESS = 2, SEMAPHORE_SIZE };
enum { PS_LISTS = 0, PS_ACTIVE, PS_SIZE };
#define NUM_PRIORITIES 8

/* bytecodes */
enum {
    OP_PUSH_INST = 1, OP_PUSH_TEMP, OP_PUSH_OUTER, OP_PUSH_LIT, OP_PUSH_GLOBAL,
    OP_PUSH_SELF, OP_PUSH_NIL, OP_PUSH_TRUE, OP_PUSH_FALSE, OP_PUSH_INT, OP_PUSH_CONTEXT,
    OP_STORE_INST, OP_STORE_TEMP, OP_STORE_OUTER, OP_STORE_GLOBAL,
    OP_POP, OP_DUP, OP_SEND, OP_SUPER_SEND, OP_RETURN, OP_BLOCK_RETURN,
    OP_PUSH_BLOCK, OP_JUMP, OP_JUMP_FALSE, OP_JUMP_TRUE
};

/* ---------- well known objects (object.c) ---------- */
extern oop nilobj, trueobj, falseobj;
extern oop classObject, classBehavior, classClass, classMetaclass, classUndefinedObject,
    classBoolean, classTrue, classFalse, classMagnitude, classNumber, classInteger,
    classSmallInteger, classFloat, classCharacter, classString, classSymbol, classArray,
    classByteArray, classDictionary, classAssociation, classCompiledMethod, classBlockClosure,
    classContext, classMessage, classCollection, classSequenceableCollection, classArrayedCollection,
    classOrderedCollection, classPoint, classSet, classIdentitySet, classIdentityDictionary,
    classLargePositiveInteger, classLargeNegativeInteger, classMethodContext, classBlockContext,
    classProcess, classSemaphore, classProcessorScheduler, classLinkedList, classLink;
extern oop smalltalk;            /* the global Dictionary */
extern oop processor, main_process;
extern oop symDoesNotUnderstand, symDoIt, symValue, symPrintString, symError, symMustBeBoolean, symNew, symPrintOn, symHash, symEquals;
extern oop charTable[256];

/* object.c */
void st_init(void);
oop new_object(oop cls, int indexed);      /* pointers, size from class format + indexed */
oop new_bytes(oop cls, int nbytes);
oop new_string(const char *s);
oop new_string_n(const char *s, int n);
oop new_symbol(const char *s);
oop new_symbol_n(const char *s, int n);
oop new_float(double d);
oop new_array(int n);
oop new_assoc(oop key, oop value);
oop new_dict(void);
oop make_class(const char *name, oop super, int instsize, int kind);
oop define_class(oop super, oop nameSym, oop ivarNames, oop cvarNames, oop category, int kind);
char *str_cstr(oop s);                  /* malloc'd C string copy */
bool str_eq_c(oop s, const char *c);
oop lookup_method(oop cls, oop selector);
oop class_name_of(oop cls);             /* String naming class or metaclass */
oop class_ivar_names(oop cls);          /* Array of Strings, including inherited */
oop global_lookup(const char *name);
/* dictionary */
oop dict_at(oop d, oop key);            /* value or NULL */
oop dict_assoc_at(oop d, oop key);      /* association or NULL */
oop dict_at_put(oop d, oop key, oop value); /* returns association */
bool dict_remove(oop d, oop key);
oop dict_keys(oop d);                   /* Array of keys */
uint32_t obj_hash(oop o);
bool obj_equal(oop a, oop b);
oop all_instances(oop cls);             /* Array of all instances of a class */
/* gc */
void gc_add_root(oop *p);
void gc_remove_root(oop *p);
void gc_collect(void);
extern size_t gc_alloc_since;
extern size_t gc_threshold;

/* compiler.c */
oop compile_method(oop cls, const char *src, const char *category, char *err, int errlen);
oop compile_doit(oop cls, const char *src, char *err, int errlen);
void method_selector_of_source(const char *src, char *out, int outlen);

/* interp.c */
typedef struct {
    oop active;             /* active context */
    char error[1024];       /* set when an error aborted the run */
    char walkback[8192];
    bool failed;
} Interp;
extern Interp interp;
oop interp_send(oop receiver, oop selector, oop *args, int nargs);
oop interp_eval(oop receiver, const char *src, char *err, int errlen); /* compile and run a do-it */
oop interp_run_method(oop method, oop receiver, oop *args, int nargs);
oop interp_print_string(oop o);                    /* printString as C-accessible String oop */
void interp_signal_error(const char *msg);
bool interp_run_background(int max_ms);            /* give forked processes a time slice; true if any ran */
bool interp_has_background(void);
/* bignum.c: arbitrary precision integers (LargePositiveInteger / LargeNegativeInteger) */
oop bn_arith(int op, oop a, oop b, bool *ok);      /* op: + - * / % q r c & | ^ s(hift) */
oop bn_print(oop a, int base);
oop bn_to_float(oop a, bool *ok);
oop bn_from_double(double d);
oop bn_from_string(const char *digits, int radix);
oop bn_negate(oop a);
bool bn_is_integer(oop o);
uint32_t bn_hash(oop o);
/* prims.c */
oop call_primitive(int n, oop *args, int nargs, bool *ok); /* args[0] is receiver */
/* transcript buffer */
void transcript_append(const char *s, int n);
extern char *transcript_text;
extern size_t transcript_len;
extern char *pending_window_title, *pending_window_text;   /* a window requested by primitive 180 (tutorial lessons) */

/* fileio.c */
bool file_in(const char *path, char *err, int errlen);
bool file_in_string(const char *src, char *err, int errlen);
bool load_kernel(const char *dir, char *err, int errlen);   /* files kernel1.st, kernel2.st, ... in order */
char *file_out_class(oop cls);          /* malloc'd chunk-format text */
/* the changes file: all code changes are appended here while changes_logging is on (interactive use) */
extern bool changes_logging;
extern int changes_count, changes_failures;    /* chunks written / write attempts that failed */
extern const char *changes_path;
const char *changes_abs_path(void);
bool changes_log(const char *text);
void changes_log_method(oop cls, const char *category, const char *src);
void changes_log_class(oop super, const char *name, const char *ivars, const char *cvars, const char *category, int kind);
void changes_log_remove_method(oop cls, oop selector);
void changes_log_comment(oop cls, const char *text);

#endif
