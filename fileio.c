/* fileio.c - chunk ("bang") format file-in / file-out and the changes log */
#include "st.h"
#include "lex.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

const char *changes_path = "changes.st";

/* read next chunk from *pp; returns malloc'd text (with !! unescaped) or NULL at end */
static char *next_chunk(const char **pp) {
    const char *p = *pp; if (!*p) return NULL;
    char *out = malloc(strlen(p) + 1); int n = 0;
    while (*p) {
        if (*p == '!') { if (p[1] == '!') { out[n++] = '!'; p += 2; continue; } p++; break; }
        out[n++] = *p++;
    }
    out[n] = 0; *pp = p; return out;
}
static bool blank(const char *s) { while (*s) { if (*s != ' ' && *s != '\t' && *s != '\n' && *s != '\r') return false; s++; } return true; }

/* recognise "Foo methodsFor: 'cat'" or "Foo class methodsFor: 'cat'" */
static bool parse_methods_for(const char *chunk, char *cls, int clen, bool *meta, char *cat, int catlen) {
    TokList l = lex_all(chunk); int i = 0; bool r = false; *meta = false;
    if (l.n > i && l.toks[i].type == T_IDENT) {
        snprintf(cls, clen, "%s", l.toks[i].text); i++;
        if (l.n > i && l.toks[i].type == T_IDENT && !strcmp(l.toks[i].text, "class")) { *meta = true; i++; }
        if (l.n > i + 2 && l.toks[i].type == T_KEYWORD && !strcmp(l.toks[i].text, "methodsFor:") && l.toks[i + 1].type == T_STRING && l.toks[i + 2].type == T_EOF) {
            snprintf(cat, catlen, "%s", l.toks[i + 1].text); r = true;
        }
    }
    lex_free(&l); return r;
}

bool file_in_string(const char *src, char *err, int errlen) {
    const char *p = src; char *chunk; bool ok = true; err[0] = 0; int lineno = 1; const char *last = src;
    while ((chunk = next_chunk(&p))) {
        for (const char *q = last; q < p; q++) if (*q == '\n') lineno++;
        int startline = lineno; for (const char *q = chunk; *q; q++) if (*q == '\n') startline--;
        last = p;
        if (blank(chunk)) { free(chunk); continue; }
        if (getenv("ST_DEBUG")) { fprintf(stderr, "chunk line %d: %.60s\n", startline, chunk); }
        char cls[128], cat[128]; bool meta;
        if (parse_methods_for(chunk, cls, sizeof cls, &meta, cat, sizeof cat)) {
            oop c = global_lookup(cls);
            if (c == nilobj || IS_INT(c)) { if (!err[0]) snprintf(err, errlen, "line %d: unknown class %s", startline, cls); ok = false; }
            else if (meta) c = c->cls;
            char *m;
            while ((m = next_chunk(&p))) {
                for (const char *q = last; q < p; q++) if (*q == '\n') lineno++;
                last = p;
                if (blank(m)) { free(m); break; }
                if (c != nilobj && !IS_INT(c)) {
                    char e[512]; oop cm = compile_method(c, m, cat, e, sizeof e);
                    if (!cm) { if (!err[0]) snprintf(err, errlen, "line %d: %s", lineno, e); ok = false; }
                    else dict_at_put(SLOT(c, C_METHODS), SLOT(cm, M_SELECTOR), cm);
                }
                free(m);
            }
        } else {
            char e[512]; interp_eval(nilobj, chunk, e, sizeof e);
            if (interp.failed) { if (!err[0]) snprintf(err, errlen, "line %d: %s", startline, interp.error); ok = false; interp.failed = false; }
        }
        free(chunk);
    }
    extern void interp_flush_cache(void); interp_flush_cache();
    return ok;
}

bool file_in(const char *path, char *err, int errlen) {
    FILE *f = fopen(path, "rb"); if (!f) { snprintf(err, errlen, "cannot open %s", path); return false; }
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    char *buf = malloc(n + 1); size_t got = fread(buf, 1, n, f); buf[got] = 0; fclose(f);
    bool r = file_in_string(buf, err, errlen); free(buf); return r;
}

/* ---- file out ---- */
typedef struct { char *s; size_t n, cap; } Buf;
static void badd(Buf *b, const char *s) { size_t l = strlen(s); if (b->n + l + 1 > b->cap) { b->cap = (b->n + l + 1) * 2 + 1024; b->s = realloc(b->s, b->cap); } memcpy(b->s + b->n, s, l + 1); b->n += l; }
static void badd_escaped(Buf *b, const char *s) { for (; *s; s++) { char t[3] = { *s, 0, 0 }; if (*s == '!') t[1] = '!'; badd(b, t); } }
static void badd_oop(Buf *b, oop s) { char *c = str_cstr(s); badd(b, c); free(c); }

static int cmp_str(const void *a, const void *b) { return strcmp(*(char **)a, *(char **)b); }

static void file_out_side(Buf *b, oop cls, const char *clsname, bool meta) {
    oop sels = dict_keys(SLOT(cls, C_METHODS)); int n = sels->size;
    /* collect categories */
    char **cats = calloc(n + 1, sizeof(char *)); int nc = 0;
    for (int i = 0; i < n; i++) {
        oop m = dict_at(SLOT(cls, C_METHODS), SLOT(sels, i)); oop c = SLOT(m, M_CATEGORY);
        char *cs = c == nilobj ? strdup("as yet unclassified") : str_cstr(c); bool found = false;
        for (int j = 0; j < nc; j++) if (!strcmp(cats[j], cs)) found = true;
        if (found) free(cs); else cats[nc++] = cs;
    }
    qsort(cats, nc, sizeof(char *), cmp_str);
    char **names = calloc(n + 1, sizeof(char *));
    for (int i = 0; i < n; i++) names[i] = str_cstr(SLOT(sels, i));
    qsort(names, n, sizeof(char *), cmp_str);
    for (int j = 0; j < nc; j++) {
        char hdr[512]; snprintf(hdr, sizeof hdr, "!%s%s methodsFor: '%s'!\n", clsname, meta ? " class" : "", cats[j]); badd(b, hdr);
        for (int i = 0; i < n; i++) {
            oop m = dict_at(SLOT(cls, C_METHODS), new_symbol(names[i])); oop c = SLOT(m, M_CATEGORY);
            char *cs = c == nilobj ? strdup("as yet unclassified") : str_cstr(c);
            if (!strcmp(cs, cats[j])) {
                oop src = SLOT(m, M_SOURCE); char *s = src == nilobj ? strdup(names[i]) : str_cstr(src);
                badd_escaped(b, s); badd(b, "! "); free(s);
            }
            free(cs);
        }
        badd(b, "!\n\n");
    }
    for (int i = 0; i < n; i++) free(names[i]); free(names);
    for (int j = 0; j < nc; j++) free(cats[j]); free(cats);
}

char *file_out_class(oop cls) {
    Buf b = { 0, 0, 0 };
    if (cls->cls == classMetaclass) cls = SLOT(cls, MC_THISCLASS);
    char *name = str_cstr(SLOT(cls, C_NAME));
    oop super = SLOT(cls, C_SUPER);
    int kind = FMT_KIND(SLOT(cls, C_FORMAT));
    int superKind = super == nilobj ? KIND_POINTERS : FMT_KIND(SLOT(super, C_FORMAT));
    const char *sel = (kind == KIND_POINTERS || kind == superKind) ? "subclass:" : kind == KIND_INDEXED ? "variableSubclass:" : "variableByteSubclass:";
    if (super == nilobj) badd(&b, "nil "); else badd_oop(&b, SLOT(super, C_NAME));
    badd(&b, " "); badd(&b, sel); badd(&b, " #"); badd(&b, name);
    badd(&b, "\n\tinstanceVariableNames: '");
    oop iv = SLOT(cls, C_IVARS); for (uint32_t i = 0; iv != nilobj && i < iv->size; i++) { if (i) badd(&b, " "); badd_oop(&b, SLOT(iv, i)); }
    badd(&b, "'\n\tclassVariableNames: '");
    oop cv = dict_keys(SLOT(cls, C_CVARS)); for (uint32_t i = 0; i < cv->size; i++) { if (i) badd(&b, " "); badd_oop(&b, SLOT(cv, i)); }
    badd(&b, "'\n\tcategory: '"); badd_oop(&b, SLOT(cls, C_CATEGORY)); badd(&b, "'!\n\n");
    oop cm = SLOT(cls, C_COMMENT);
    if (cm != nilobj && cm->size > 0) { badd(&b, name); badd(&b, " comment: '"); char *c = str_cstr(cm);
        for (char *q = c; *q; q++) { char t[3] = { *q, 0, 0 }; if (*q == '\'') t[1] = '\''; if (*q == '!') t[1] = '!'; badd(&b, t); } free(c); badd(&b, "'!\n\n"); }
    file_out_side(&b, cls, name, false);
    file_out_side(&b, cls->cls, name, true);
    free(name);
    return b.s ? b.s : strdup("");
}

void changes_log(const char *text) {
    FILE *f = fopen(changes_path, "ab"); if (!f) return;
    fputs(text, f); fputs("\n", f); fclose(f);
}
