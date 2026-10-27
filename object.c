/* object.c - object memory, GC, symbols, dictionaries, class bootstrap */
#include "st.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

oop nilobj, trueobj, falseobj;
oop classObject, classBehavior, classClass, classMetaclass, classUndefinedObject,
    classBoolean, classTrue, classFalse, classMagnitude, classNumber, classInteger,
    classSmallInteger, classFloat, classCharacter, classString, classSymbol, classArray,
    classByteArray, classDictionary, classAssociation, classCompiledMethod, classBlockClosure,
    classContext, classMessage, classCollection, classSequenceableCollection, classArrayedCollection,
    classOrderedCollection, classPoint;
oop smalltalk;
oop symDoesNotUnderstand, symDoIt, symValue, symPrintString, symError, symMustBeBoolean, symNew, symPrintOn;
oop charTable[256];

/* ---------- allocation & GC ---------- */
static struct Obj *all_objects = NULL;
static uint32_t next_hash = 1;
size_t gc_alloc_since = 0;
size_t gc_threshold = 8 * 1024 * 1024;

static oop *roots[4096];
static int nroots = 0;
void gc_add_root(oop *p) { if (nroots < 4096) roots[nroots++] = p; }
void gc_remove_root(oop *p) {
    for (int i = nroots - 1; i >= 0; i--) if (roots[i] == p) { roots[i] = roots[--nroots]; return; }
}

static oop alloc(oop cls, uint32_t size, int kind, size_t bytes) {
    struct Obj *o = calloc(1, sizeof(struct Obj) + bytes);
    if (!o) { fprintf(stderr, "out of memory\n"); exit(1); }
    o->cls = cls; o->size = size; o->kind = kind; o->hash = next_hash++ & 0xffffff;
    o->next = all_objects; all_objects = o;
    gc_alloc_since += sizeof(struct Obj) + bytes;
    return o;
}

oop new_bytes(oop cls, int n) { return alloc(cls, n, KIND_BYTES, n); }

oop new_object(oop cls, int indexed) {
    oop fmt = SLOT(cls, C_FORMAT);
    int fixed = FMT_SIZE(fmt), kind = FMT_KIND(fmt);
    if (kind == KIND_BYTES) return new_bytes(cls, indexed);
    int n = fixed + (kind == KIND_INDEXED ? indexed : 0);
    oop o = alloc(cls, n, kind, sizeof(oop) * n);
    for (int i = 0; i < n; i++) SLOT(o, i) = nilobj;
    return o;
}

oop new_array(int n) { return new_object(classArray, n); }
oop new_string_n(const char *s, int n) { oop o = new_bytes(classString, n); memcpy(BYTES(o), s, n); return o; }
oop new_string(const char *s) { return new_string_n(s, (int)strlen(s)); }
oop new_float(double d) { oop o = new_bytes(classFloat, 8); FLOATVAL(o) = d; return o; }
oop new_assoc(oop k, oop v) { oop a = new_object(classAssociation, 0); SLOT(a, A_KEY) = k; SLOT(a, A_VALUE) = v; return a; }

/* symbols: open addressing table of oops */
static oop *symtab = NULL; static int symcap = 0, symcount = 0;
static uint32_t str_hash(const unsigned char *s, int n) {
    uint32_t h = 2166136261u; for (int i = 0; i < n; i++) { h ^= s[i]; h *= 16777619u; } return h ? h : 1;
}
static void sym_insert(oop s);
static void sym_grow(void) {
    oop *old = symtab; int oldcap = symcap;
    symcap = symcap ? symcap * 2 : 1024; symtab = calloc(symcap, sizeof(oop)); symcount = 0;
    for (int i = 0; i < oldcap; i++) if (old[i]) sym_insert(old[i]);
    free(old);
}
static void sym_insert(oop s) {
    uint32_t i = str_hash(BYTES(s), s->size) & (symcap - 1);
    while (symtab[i]) i = (i + 1) & (symcap - 1);
    symtab[i] = s; symcount++;
}
oop new_symbol_n(const char *s, int n) {
    if (symcount * 2 >= symcap) sym_grow();
    uint32_t i = str_hash((const unsigned char *)s, n) & (symcap - 1);
    while (symtab[i]) {
        if ((int)symtab[i]->size == n && memcmp(BYTES(symtab[i]), s, n) == 0) return symtab[i];
        i = (i + 1) & (symcap - 1);
    }
    oop sym = new_bytes(classSymbol, n); memcpy(BYTES(sym), s, n);
    symtab[i] = sym; symcount++;
    return sym;
}
oop new_symbol(const char *s) { return new_symbol_n(s, (int)strlen(s)); }

char *str_cstr(oop s) {
    if (IS_INT(s) || s->kind != KIND_BYTES) return strdup("");
    char *c = malloc(s->size + 1); memcpy(c, BYTES(s), s->size); c[s->size] = 0; return c;
}
bool str_eq_c(oop s, const char *c) {
    return !IS_INT(s) && s->kind == KIND_BYTES && strlen(c) == s->size && memcmp(BYTES(s), c, s->size) == 0;
}

/* ---------- mark & sweep ---------- */
static oop *mstack = NULL; static size_t mcap = 0, msp = 0;
static void mark_push(oop o) {
    if (!o || IS_INT(o) || o->mark) return;
    o->mark = 1;
    if (msp == mcap) { mcap = mcap ? mcap * 2 : 65536; mstack = realloc(mstack, mcap * sizeof(oop)); }
    mstack[msp++] = o;
}
static void mark_drain(void) {
    while (msp) {
        oop o = mstack[--msp];
        mark_push(o->cls);
        if (o->kind != KIND_BYTES) for (uint32_t i = 0; i < o->size; i++) mark_push(SLOT(o, i));
    }
}
void gc_collect(void) {
    mark_push(nilobj); mark_push(trueobj); mark_push(falseobj); mark_push(smalltalk);
    for (int i = 0; i < 256; i++) mark_push(charTable[i]);
    for (int i = 0; i < symcap; i++) if (symtab[i]) mark_push(symtab[i]);
    for (int i = 0; i < nroots; i++) mark_push(*roots[i]);
    mark_push(interp.active);
    mark_drain();
    struct Obj **pp = &all_objects;
    while (*pp) {
        struct Obj *o = *pp;
        if (o->mark) { o->mark = 0; pp = &o->next; }
        else { *pp = o->next; free(o); }
    }
    gc_alloc_since = 0;
}

/* ---------- dictionaries (keys Array, values Array of Associations) ---------- */
uint32_t obj_hash(oop o) {
    if (IS_INT(o)) return (uint32_t)INT_VAL(o) * 2654435761u;
    if (o->cls == classString) return str_hash(BYTES(o), o->size);
    if (o->cls == classFloat) { double d = FLOATVAL(o); if (d == (double)(long)d) return (uint32_t)(long)d * 2654435761u; uint64_t b; memcpy(&b, &d, 8); return (uint32_t)(b ^ (b >> 32)); }
    return o->hash * 2654435761u;
}
bool obj_equal(oop a, oop b) {
    if (a == b) return true;
    if (IS_INT(a) || IS_INT(b)) {
        if (IS_INT(a) && !IS_INT(b) && b->cls == classFloat) return (double)INT_VAL(a) == FLOATVAL(b);
        if (IS_INT(b) && !IS_INT(a) && a->cls == classFloat) return (double)INT_VAL(b) == FLOATVAL(a);
        return false;
    }
    if (a->cls == classString && b->cls == classString)
        return a->size == b->size && memcmp(BYTES(a), BYTES(b), a->size) == 0;
    if (a->cls == classFloat && b->cls == classFloat) return FLOATVAL(a) == FLOATVAL(b);
    return false;
}
oop new_dict(void) {
    oop d = new_object(classDictionary, 0);
    SLOT(d, D_TALLY) = MK_INT(0); SLOT(d, D_KEYS) = new_array(16); SLOT(d, D_VALUES) = new_array(16);
    return d;
}
static int dict_find(oop d, oop key) {
    oop keys = SLOT(d, D_KEYS); int cap = keys->size;
    uint32_t i = obj_hash(key) & (cap - 1);
    for (;;) {
        oop k = SLOT(keys, i);
        if (k == nilobj) return -(int)i - 1;
        if (obj_equal(k, key)) return (int)i;
        i = (i + 1) & (cap - 1);
    }
}
oop dict_assoc_at(oop d, oop key) { int i = dict_find(d, key); return i >= 0 ? SLOT(SLOT(d, D_VALUES), i) : NULL; }
oop dict_at(oop d, oop key) { oop a = dict_assoc_at(d, key); return a ? SLOT(a, A_VALUE) : NULL; }
static void dict_grow(oop d) {
    oop okeys = SLOT(d, D_KEYS), ovals = SLOT(d, D_VALUES); int cap = okeys->size;
    oop nkeys = new_array(cap * 2), nvals = new_array(cap * 2);
    SLOT(d, D_KEYS) = nkeys; SLOT(d, D_VALUES) = nvals;
    for (int i = 0; i < cap; i++) if (SLOT(okeys, i) != nilobj) {
        int j = dict_find(d, SLOT(okeys, i)); j = -j - 1;
        SLOT(nkeys, j) = SLOT(okeys, i); SLOT(nvals, j) = SLOT(ovals, i);
    }
}
oop dict_at_put(oop d, oop key, oop value) {
    int i = dict_find(d, key);
    if (i >= 0) { oop a = SLOT(SLOT(d, D_VALUES), i); SLOT(a, A_VALUE) = value; return a; }
    int tally = INT_VAL(SLOT(d, D_TALLY));
    if ((tally + 1) * 2 > (int)SLOT(d, D_KEYS)->size) { dict_grow(d); i = dict_find(d, key); }
    i = -i - 1;
    oop a = new_assoc(key, value);
    SLOT(SLOT(d, D_KEYS), i) = key; SLOT(SLOT(d, D_VALUES), i) = a;
    SLOT(d, D_TALLY) = MK_INT(tally + 1);
    return a;
}
bool dict_remove(oop d, oop key) {
    int i = dict_find(d, key); if (i < 0) return false;
    oop keys = SLOT(d, D_KEYS), vals = SLOT(d, D_VALUES); int cap = keys->size;
    SLOT(keys, i) = nilobj; SLOT(vals, i) = nilobj;
    SLOT(d, D_TALLY) = MK_INT(INT_VAL(SLOT(d, D_TALLY)) - 1);
    /* re-insert the following cluster */
    for (uint32_t j = (i + 1) & (cap - 1); SLOT(keys, j) != nilobj; j = (j + 1) & (cap - 1)) {
        oop k = SLOT(keys, j), v = SLOT(vals, j);
        SLOT(keys, j) = nilobj; SLOT(vals, j) = nilobj;
        int n = dict_find(d, k); n = -n - 1; SLOT(keys, n) = k; SLOT(vals, n) = v;
    }
    return true;
}
oop dict_keys(oop d) {
    int tally = INT_VAL(SLOT(d, D_TALLY)); oop r = new_array(tally); oop keys = SLOT(d, D_KEYS); int n = 0;
    for (uint32_t i = 0; i < keys->size; i++) if (SLOT(keys, i) != nilobj) SLOT(r, n++) = SLOT(keys, i);
    return r;
}

/* ---------- classes ---------- */
oop global_lookup(const char *name) { oop v = dict_at(smalltalk, new_symbol(name)); return v ? v : nilobj; }

oop lookup_method(oop cls, oop selector) {
    while (cls != nilobj && cls) {
        oop m = dict_at(SLOT(cls, C_METHODS), selector);
        if (m) return m;
        cls = SLOT(cls, C_SUPER);
    }
    return NULL;
}
oop class_name_of(oop cls) {
    if (IS_INT(cls) || cls == nilobj) return new_string("nil");
    if (cls->cls == classMetaclass) {
        oop n = class_name_of(SLOT(cls, MC_THISCLASS)); char *c = str_cstr(n);
        char buf[256]; snprintf(buf, sizeof buf, "%s class", c); free(c); return new_string(buf);
    }
    oop n = SLOT(cls, C_NAME); if (n == nilobj) return new_string("?");
    return new_string_n((char *)BYTES(n), n->size);
}
oop class_ivar_names(oop cls) {
    oop chain[64]; int n = 0;
    for (oop c = cls; c != nilobj && n < 64; c = SLOT(c, C_SUPER)) chain[n++] = c;
    int total = 0;
    for (int i = n - 1; i >= 0; i--) {
        if (chain[i]->cls == classMetaclass) continue;
        oop iv = SLOT(chain[i], C_IVARS); if (iv != nilobj) total += iv->size;
    }
    oop r = new_array(total); int k = 0;
    for (int i = n - 1; i >= 0; i--) {
        if (chain[i]->cls == classMetaclass) continue;
        oop iv = SLOT(chain[i], C_IVARS); if (iv != nilobj) for (uint32_t j = 0; j < iv->size; j++) SLOT(r, k++) = SLOT(iv, j);
    }
    return r;
}

static oop raw_class(int size) { oop c = alloc(NULL, size, KIND_POINTERS, sizeof(oop) * size); for (int i = 0; i < size; i++) SLOT(c, i) = nilobj; return c; }

oop make_class(const char *name, oop super, int instsize, int kind) {
    oop meta = raw_class(METACLASS_SIZE); meta->cls = classMetaclass;
    oop cls = raw_class(CLASS_SIZE); cls->cls = meta;
    SLOT(meta, MC_THISCLASS) = cls;
    SLOT(meta, C_SUPER) = (super && super != nilobj) ? super->cls : classClass;
    SLOT(meta, C_METHODS) = new_dict(); SLOT(meta, C_FORMAT) = MK_FMT(CLASS_SIZE, KIND_POINTERS);
    SLOT(cls, C_SUPER) = super ? super : nilobj;
    SLOT(cls, C_METHODS) = new_dict(); SLOT(cls, C_FORMAT) = MK_FMT(instsize, kind);
    SLOT(cls, C_NAME) = new_symbol(name); SLOT(cls, C_IVARS) = new_array(0); SLOT(cls, C_CVARS) = new_dict();
    SLOT(cls, C_CATEGORY) = new_string("Kernel"); SLOT(cls, C_COMMENT) = new_string("");
    dict_at_put(smalltalk, SLOT(cls, C_NAME), cls);
    return cls;
}

/* split 'a b c' into Array of Strings */
static oop split_names(oop s) {
    char *c = str_cstr(s); int n = 0; char *copy = strdup(c);
    for (char *t = strtok(copy, " \t\r\n"); t; t = strtok(NULL, " \t\r\n")) n++;
    oop r = new_array(n); strcpy(copy, c); n = 0;
    for (char *t = strtok(copy, " \t\r\n"); t; t = strtok(NULL, " \t\r\n")) SLOT(r, n++) = new_string(t);
    free(copy); free(c); return r;
}

oop define_class(oop super, oop nameSym, oop ivarNames, oop cvarNames, oop category, int kind) {
    oop ivars = split_names(ivarNames), cvars = split_names(cvarNames);
    int superSize = super == nilobj ? 0 : FMT_SIZE(SLOT(super, C_FORMAT));
    int superKind = super == nilobj ? KIND_POINTERS : FMT_KIND(SLOT(super, C_FORMAT));
    if (kind == KIND_POINTERS && superKind != KIND_POINTERS) kind = superKind;
    oop cls = dict_at(smalltalk, nameSym);
    if (!cls || IS_INT(cls) || cls == nilobj || cls->cls == nilobj || cls->cls->cls != classMetaclass) {
        char *n = str_cstr(nameSym); cls = make_class(n, super, superSize + ivars->size, kind); free(n);
    } else {
        SLOT(cls, C_SUPER) = super; SLOT(cls->cls, C_SUPER) = super == nilobj ? classClass : super->cls;
        SLOT(cls, C_FORMAT) = MK_FMT(superSize + ivars->size, kind);
    }
    SLOT(cls, C_IVARS) = ivars;
    if (category != nilobj) SLOT(cls, C_CATEGORY) = category;
    oop pool = SLOT(cls, C_CVARS);
    for (uint32_t i = 0; i < cvars->size; i++) {
        oop k = new_symbol_n((char *)BYTES(SLOT(cvars, i)), SLOT(cvars, i)->size);
        if (!dict_at(pool, k)) dict_at_put(pool, k, nilobj);
    }
    return cls;
}

static oop def(const char *name, oop super, int size, int kind) { return make_class(name, super, size, kind); }

void st_init(void) {
    /* bootstrap: nil must exist before class slots are filled */
    struct Obj *nilraw = alloc(NULL, 0, KIND_POINTERS, 0); nilobj = nilraw;
    classMetaclass = NULL; classClass = NULL;
    smalltalk = NULL;
    /* temporary dictionary needs classes: create Symbol/String/Array/Dictionary/Association first with NULL meta */
    classSymbol = raw_class(CLASS_SIZE); classString = raw_class(CLASS_SIZE); classArray = raw_class(CLASS_SIZE);
    classDictionary = raw_class(CLASS_SIZE); classAssociation = raw_class(CLASS_SIZE);
    SLOT(classSymbol, C_FORMAT) = MK_FMT(0, KIND_BYTES); SLOT(classString, C_FORMAT) = MK_FMT(0, KIND_BYTES);
    SLOT(classArray, C_FORMAT) = MK_FMT(0, KIND_INDEXED); SLOT(classDictionary, C_FORMAT) = MK_FMT(DICT_SIZE, KIND_POINTERS);
    SLOT(classAssociation, C_FORMAT) = MK_FMT(ASSOC_SIZE, KIND_POINTERS);
    smalltalk = new_dict();
    classMetaclass = raw_class(CLASS_SIZE);
    classClass = raw_class(CLASS_SIZE);
    /* now proper classes */
    classObject = def("Object", nilobj, 0, KIND_POINTERS);
    classBehavior = def("Behavior", classObject, 3, KIND_POINTERS);
    oop classDesc = def("ClassDescription", classBehavior, 3, KIND_POINTERS);
    /* fix Class and Metaclass which were allocated raw */
    oop fix[2] = { classClass, classMetaclass }; const char *fixn[2] = { "Class", "Metaclass" };
    int fixs[2] = { CLASS_SIZE, METACLASS_SIZE };
    for (int i = 0; i < 2; i++) {
        oop c = fix[i]; oop meta = raw_class(METACLASS_SIZE); meta->cls = classMetaclass; c->cls = meta;
        SLOT(meta, MC_THISCLASS) = c; SLOT(meta, C_SUPER) = classDesc->cls; SLOT(meta, C_METHODS) = new_dict();
        SLOT(meta, C_FORMAT) = MK_FMT(CLASS_SIZE, KIND_POINTERS);
        SLOT(c, C_SUPER) = classDesc; SLOT(c, C_METHODS) = new_dict(); SLOT(c, C_FORMAT) = MK_FMT(fixs[i], KIND_POINTERS);
        SLOT(c, C_NAME) = new_symbol(fixn[i]); SLOT(c, C_IVARS) = new_array(0); SLOT(c, C_CVARS) = new_dict();
        SLOT(c, C_CATEGORY) = new_string("Kernel"); SLOT(c, C_COMMENT) = new_string("");
        dict_at_put(smalltalk, SLOT(c, C_NAME), c);
    }
    /* the metaclasses created so far have cls == NULL (Metaclass didn't exist): fix them */
    classObject->cls->cls = classMetaclass; classBehavior->cls->cls = classMetaclass; classDesc->cls->cls = classMetaclass;
    /* Object class superclass is Class */
    SLOT(classObject->cls, C_SUPER) = classClass;
    classUndefinedObject = def("UndefinedObject", classObject, 0, KIND_POINTERS);
    nilobj->cls = classUndefinedObject;
    classBoolean = def("Boolean", classObject, 0, KIND_POINTERS);
    classTrue = def("True", classBoolean, 0, KIND_POINTERS); classFalse = def("False", classBoolean, 0, KIND_POINTERS);
    trueobj = new_object(classTrue, 0); falseobj = new_object(classFalse, 0);
    classMagnitude = def("Magnitude", classObject, 0, KIND_POINTERS);
    classNumber = def("Number", classMagnitude, 0, KIND_POINTERS);
    classInteger = def("Integer", classNumber, 0, KIND_POINTERS);
    classSmallInteger = def("SmallInteger", classInteger, 0, KIND_POINTERS);
    classFloat = def("Float", classNumber, 0, KIND_BYTES);
    classCharacter = def("Character", classMagnitude, CHAR_SIZE, KIND_POINTERS);
    classCollection = def("Collection", classObject, 0, KIND_POINTERS);
    classSequenceableCollection = def("SequenceableCollection", classCollection, 0, KIND_POINTERS);
    classArrayedCollection = def("ArrayedCollection", classSequenceableCollection, 0, KIND_POINTERS);
    /* fix the raw early classes: give them metaclasses and names by re-making over the same objects */
    struct { oop *c; const char *n; oop super; int size; int kind; } early[] = {
        { &classArray, "Array", classArrayedCollection, 0, KIND_INDEXED },
        { &classString, "String", classArrayedCollection, 0, KIND_BYTES },
        { &classSymbol, "Symbol", NULL, 0, KIND_BYTES },
        { &classAssociation, "Association", classMagnitude, ASSOC_SIZE, KIND_POINTERS },
        { &classDictionary, "Dictionary", classCollection, DICT_SIZE, KIND_POINTERS } };
    for (int i = 0; i < 5; i++) {
        oop c = *early[i].c; oop super = early[i].super ? early[i].super : classString;
        oop meta = raw_class(METACLASS_SIZE); meta->cls = classMetaclass; c->cls = meta;
        SLOT(meta, MC_THISCLASS) = c; SLOT(meta, C_SUPER) = super->cls; SLOT(meta, C_METHODS) = new_dict();
        SLOT(meta, C_FORMAT) = MK_FMT(CLASS_SIZE, KIND_POINTERS);
        SLOT(c, C_SUPER) = super; SLOT(c, C_METHODS) = new_dict(); SLOT(c, C_FORMAT) = MK_FMT(early[i].size, early[i].kind);
        SLOT(c, C_NAME) = new_symbol(early[i].n); SLOT(c, C_IVARS) = new_array(0); SLOT(c, C_CVARS) = new_dict();
        SLOT(c, C_CATEGORY) = new_string("Kernel"); SLOT(c, C_COMMENT) = new_string("");
        dict_at_put(smalltalk, SLOT(c, C_NAME), c);
    }
    classByteArray = def("ByteArray", classArrayedCollection, 0, KIND_BYTES);
    classOrderedCollection = def("OrderedCollection", classSequenceableCollection, 3, KIND_POINTERS);
    classCompiledMethod = def("CompiledMethod", classObject, METHOD_SIZE, KIND_POINTERS);
    classBlockClosure = def("BlockClosure", classObject, BLOCK_SIZE, KIND_POINTERS);
    classContext = def("Context", classObject, CTX_FIXED, KIND_INDEXED);
    classMessage = def("Message", classObject, MSG_SIZE, KIND_POINTERS);
    classPoint = def("Point", classObject, 2, KIND_POINTERS);
    oop sysdict = def("SystemDictionary", classDictionary, DICT_SIZE, KIND_POINTERS);
    smalltalk->cls = sysdict;
    for (int i = 0; i < 256; i++) { charTable[i] = new_object(classCharacter, 0); SLOT(charTable[i], CH_VALUE) = MK_INT(i); }
    dict_at_put(smalltalk, new_symbol("Smalltalk"), smalltalk);
    dict_at_put(smalltalk, new_symbol("Transcript"), nilobj);
    symDoesNotUnderstand = new_symbol("doesNotUnderstand:"); symDoIt = new_symbol("DoIt");
    symValue = new_symbol("value"); symPrintString = new_symbol("printString"); symError = new_symbol("error:");
    symMustBeBoolean = new_symbol("mustBeBoolean"); symNew = new_symbol("new"); symPrintOn = new_symbol("printOn:");
}
