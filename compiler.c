/* compiler.c - bytecode generation from the parse tree */
#include "ast.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <setjmp.h>

typedef struct Scope {
    struct Scope *parent; int inlined;
    char *names[128]; int idx[128]; int n;
    int *ntemps;            /* counter of the owning real scope */
    int own;                /* storage for the counter when real */
} Scope;

typedef struct Gen {
    unsigned char *code; int n, cap;
    oop lits[256]; int nlits;
    int depth, maxdepth;
    Scope *scope;
    oop cls; bool doit;
    jmp_buf *jb; char *err; int errlen;
    oop ivars;              /* Array of instance variable names */
} Gen;

static void gfail(Gen *g, const char *fmt, const char *a) { snprintf(g->err, g->errlen, fmt, a ? a : ""); longjmp(*g->jb, 1); }

static void emit(Gen *g, int b) {
    if (g->n == g->cap) { g->cap = g->cap ? g->cap * 2 : 128; g->code = realloc(g->code, g->cap); }
    g->code[g->n++] = (unsigned char)b;
}
static void adj(Gen *g, int d) { g->depth += d; if (g->depth > g->maxdepth) g->maxdepth = g->depth; }
static void emit1(Gen *g, int op, int a) { emit(g, op); emit(g, a); }
static int addlit(Gen *g, oop lit) {
    for (int i = 0; i < g->nlits; i++) if (g->lits[i] == lit) return i;
    if (g->nlits == 256) gfail(g, "too many literals", NULL);
    g->lits[g->nlits] = lit; return g->nlits++;
}
static int emit_jump(Gen *g, int op) { emit(g, op); emit(g, 0); emit(g, 0); return g->n; }  /* returns position after */
static void patch(Gen *g, int after, int target) { int off = target - after; g->code[after - 2] = (off >> 8) & 255; g->code[after - 1] = off & 255; }

static Scope *scope_new(Scope *parent, int inlined) {
    Scope *s = calloc(1, sizeof(Scope)); s->parent = parent; s->inlined = inlined;
    s->ntemps = inlined ? parent->ntemps : &s->own; return s;
}
static void scope_add(Gen *g, Scope *s, const char *name) {
    if (s->n == 128) gfail(g, "too many temporaries", NULL);
    s->names[s->n] = (char *)name; s->idx[s->n] = (*s->ntemps)++; s->n++;
}
/* returns 1 and sets depth/idx if found as temp */
static int lookup_temp(Scope *s, const char *name, int *depth, int *idx) {
    int d = 0;
    for (; s; s = s->parent) {
        for (int i = s->n - 1; i >= 0; i--) if (!strcmp(s->names[i], name)) { *depth = d; *idx = s->idx[i]; return 1; }
        if (!s->inlined) d++;
    }
    return 0;
}
static int lookup_ivar(Gen *g, const char *name) {
    if (g->ivars == nilobj) return -1;
    for (uint32_t i = 0; i < g->ivars->size; i++) if (str_eq_c(SLOT(g->ivars, i), name)) return (int)i;
    return -1;
}
static oop lookup_global_assoc(Gen *g, const char *name) {
    oop sym = new_symbol(name);
    oop c = g->cls;
    if (c->cls == classMetaclass) c = SLOT(c, MC_THISCLASS);
    for (; c != nilobj; c = SLOT(c, C_SUPER)) {
        oop pool = SLOT(c, C_CVARS);
        if (pool != nilobj) { oop a = dict_assoc_at(pool, sym); if (a) return a; }
    }
    oop a = dict_assoc_at(smalltalk, sym);
    if (a) return a;
    /* undeclared: capitalised names are auto-declared as globals (forward references to classes); do-its declare anything */
    if (g->doit || (name[0] >= 'A' && name[0] <= 'Z')) return dict_at_put(smalltalk, sym, nilobj);
    return NULL;
}

static void gen_expr(Gen *g, Node *n);
static void gen_stmts_value(Gen *g, Node **stmts, int n);

static void gen_var(Gen *g, const char *name) {
    int d, i;
    if (!strcmp(name, "self")) { emit(g, OP_PUSH_SELF); adj(g, 1); return; }
    if (!strcmp(name, "super")) { emit(g, OP_PUSH_SELF); adj(g, 1); return; }
    if (!strcmp(name, "nil")) { emit(g, OP_PUSH_NIL); adj(g, 1); return; }
    if (!strcmp(name, "true")) { emit(g, OP_PUSH_TRUE); adj(g, 1); return; }
    if (!strcmp(name, "false")) { emit(g, OP_PUSH_FALSE); adj(g, 1); return; }
    if (!strcmp(name, "thisContext")) { emit(g, OP_PUSH_CONTEXT); adj(g, 1); return; }
    if (lookup_temp(g->scope, name, &d, &i)) {
        if (d == 0) emit1(g, OP_PUSH_TEMP, i); else { emit(g, OP_PUSH_OUTER); emit(g, d); emit(g, i); }
        adj(g, 1); return;
    }
    if ((i = lookup_ivar(g, name)) >= 0) { emit1(g, OP_PUSH_INST, i); adj(g, 1); return; }
    oop a = lookup_global_assoc(g, name);
    if (!a) gfail(g, "undeclared variable '%s'", name);
    emit1(g, OP_PUSH_GLOBAL, addlit(g, a)); adj(g, 1);
}
static void gen_store(Gen *g, const char *name) {
    int d, i;
    if (lookup_temp(g->scope, name, &d, &i)) {
        if (d == 0) emit1(g, OP_STORE_TEMP, i); else { emit(g, OP_STORE_OUTER); emit(g, d); emit(g, i); }
        return;
    }
    if ((i = lookup_ivar(g, name)) >= 0) { emit1(g, OP_STORE_INST, i); return; }
    oop a = lookup_global_assoc(g, name);
    if (!a) gfail(g, "undeclared variable '%s'", name);
    emit1(g, OP_STORE_GLOBAL, addlit(g, a));
}

static oop gen_block_method(Gen *g, Node *b);

/* inline a zero-arg literal block's body in the current context; leaves value on stack */
static void gen_inline_block(Gen *g, Node *b) {
    Scope *s = scope_new(g->scope, 1); g->scope = s;
    for (int i = 0; i < b->ntemps; i++) scope_add(g, s, b->temps[i]);
    gen_stmts_value(g, b->stmts, b->nstmts);
    g->scope = s->parent; free(s);
}
static int is_literal_block(Node *n, int nparams) { return n && n->kind == N_BLOCK && n->nparams == nparams; }

static int try_inline(Gen *g, Node *recv, const char *sel, Node **args, int nargs) {
    if (nargs == 1 && (!strcmp(sel, "ifTrue:") || !strcmp(sel, "ifFalse:") || !strcmp(sel, "and:") || !strcmp(sel, "or:"))
        && is_literal_block(args[0], 0)) {
        gen_expr(g, recv);
        int neg = !strcmp(sel, "ifFalse:") || !strcmp(sel, "or:");
        int j1 = emit_jump(g, neg ? OP_JUMP_TRUE : OP_JUMP_FALSE); adj(g, -1);
        gen_inline_block(g, args[0]);
        int j2 = emit_jump(g, OP_JUMP); adj(g, -1);
        patch(g, j1, g->n);
        emit(g, !strcmp(sel, "and:") ? OP_PUSH_FALSE : !strcmp(sel, "or:") ? OP_PUSH_TRUE : OP_PUSH_NIL); adj(g, 1);
        patch(g, j2, g->n);
        return 1;
    }
    if (nargs == 2 && (!strcmp(sel, "ifTrue:ifFalse:") || !strcmp(sel, "ifFalse:ifTrue:"))
        && is_literal_block(args[0], 0) && is_literal_block(args[1], 0)) {
        gen_expr(g, recv);
        int j1 = emit_jump(g, !strcmp(sel, "ifTrue:ifFalse:") ? OP_JUMP_FALSE : OP_JUMP_TRUE); adj(g, -1);
        gen_inline_block(g, args[0]);
        int j2 = emit_jump(g, OP_JUMP); adj(g, -1);
        patch(g, j1, g->n);
        gen_inline_block(g, args[1]);
        patch(g, j2, g->n);
        return 1;
    }
    if ((nargs == 1 && (!strcmp(sel, "whileTrue:") || !strcmp(sel, "whileFalse:")) && is_literal_block(args[0], 0) && is_literal_block(recv, 0))
        || (nargs == 0 && (!strcmp(sel, "whileTrue") || !strcmp(sel, "whileFalse")) && is_literal_block(recv, 0))) {
        int neg = !strncmp(sel, "whileFalse", 10);
        int top = g->n;
        gen_inline_block(g, recv);
        int jend = emit_jump(g, neg ? OP_JUMP_TRUE : OP_JUMP_FALSE); adj(g, -1);
        if (nargs == 1) { gen_inline_block(g, args[0]); emit(g, OP_POP); adj(g, -1); }
        int jb = emit_jump(g, OP_JUMP); patch(g, jb, top);
        patch(g, jend, g->n);
        emit(g, OP_PUSH_NIL); adj(g, 1);
        return 1;
    }
    return 0;
}

static void gen_send_tail(Gen *g, const char *sel, Node **args, int nargs, int super) {
    for (int i = 0; i < nargs; i++) gen_expr(g, args[i]);
    emit(g, super ? OP_SUPER_SEND : OP_SEND); emit(g, addlit(g, new_symbol(sel))); emit(g, nargs);
    adj(g, -nargs);
}

static void gen_expr(Gen *g, Node *n) {
    switch (n->kind) {
    case N_LIT:
        if (IS_INT(n->lit) && INT_VAL(n->lit) >= -128 && INT_VAL(n->lit) <= 127) emit1(g, OP_PUSH_INT, (int)INT_VAL(n->lit) & 255);
        else emit1(g, OP_PUSH_LIT, addlit(g, n->lit));
        adj(g, 1); break;
    case N_VAR: gen_var(g, n->name); break;
    case N_ASSIGN: gen_expr(g, n->recv); gen_store(g, n->name); break;
    case N_RETURN: gen_expr(g, n->recv); emit(g, OP_RETURN); break;
    case N_BLOCK: { oop m = gen_block_method(g, n); emit1(g, OP_PUSH_BLOCK, addlit(g, m)); adj(g, 1); break; }
    case N_BRACE: {
        oop a = dict_assoc_at(smalltalk, new_symbol("Array"));
        emit1(g, OP_PUSH_GLOBAL, addlit(g, a)); adj(g, 1);
        emit1(g, OP_PUSH_INT, n->nargs & 255); adj(g, 1);
        emit(g, OP_SEND); emit(g, addlit(g, new_symbol("new:"))); emit(g, 1); adj(g, -1);
        for (int i = 0; i < n->nargs; i++) {
            emit(g, OP_DUP); adj(g, 1); emit1(g, OP_PUSH_INT, (i + 1) & 255); adj(g, 1);
            gen_expr(g, n->args[i]);
            emit(g, OP_SEND); emit(g, addlit(g, new_symbol("at:put:"))); emit(g, 2); adj(g, -2);
            emit(g, OP_POP); adj(g, -1);
        }
        break; }
    case N_SEND: {
        int super = n->recv->kind == N_VAR && !strcmp(n->recv->name, "super");
        if (!super && try_inline(g, n->recv, n->sel, n->args, n->nargs)) break;
        gen_expr(g, n->recv);
        gen_send_tail(g, n->sel, n->args, n->nargs, super);
        break; }
    case N_CASCADE: {
        int super = n->recv->kind == N_VAR && !strcmp(n->recv->name, "super");
        gen_expr(g, n->recv);
        for (int i = 0; i < n->nargs; i++) {
            Node *m = n->args[i];
            if (i < n->nargs - 1) { emit(g, OP_DUP); adj(g, 1); }
            gen_send_tail(g, m->sel, m->args, m->nargs, super);
            if (i < n->nargs - 1) { emit(g, OP_POP); adj(g, -1); }
        }
        break; }
    }
}

/* statements; leaves value of last on the stack (nil if none) */
static void gen_stmts_value(Gen *g, Node **stmts, int n) {
    if (n == 0) { emit(g, OP_PUSH_NIL); adj(g, 1); return; }
    for (int i = 0; i < n; i++) {
        gen_expr(g, stmts[i]);
        if (stmts[i]->kind == N_RETURN) { if (i == n - 1) { emit(g, OP_PUSH_NIL); adj(g, 1); } continue; }
        if (i < n - 1) { emit(g, OP_POP); adj(g, -1); }
    }
}

static oop finish_method(Gen *g, int nargs, oop selector, int prim) {
    oop m = new_object(classCompiledMethod, 0);
    int ntemps = *g->scope->ntemps;
    SLOT(m, M_HEADER) = MK_HDR(nargs, ntemps, g->maxdepth + 2);
    oop lits = new_array(g->nlits); for (int i = 0; i < g->nlits; i++) SLOT(lits, i) = g->lits[i];
    SLOT(m, M_LITERALS) = lits;
    oop bc = new_bytes(classByteArray, g->n); memcpy(BYTES(bc), g->code, g->n);
    SLOT(m, M_BYTECODES) = bc; SLOT(m, M_SELECTOR) = selector; SLOT(m, M_CLASS) = g->cls;
    SLOT(m, M_PRIM) = MK_INT(prim); SLOT(m, M_SOURCE) = nilobj; SLOT(m, M_CATEGORY) = nilobj;
    free(g->code); g->code = NULL;
    return m;
}

static oop gen_block_method(Gen *g, Node *b) {
    Gen bg; memset(&bg, 0, sizeof bg);
    bg.cls = g->cls; bg.doit = g->doit; bg.jb = g->jb; bg.err = g->err; bg.errlen = g->errlen; bg.ivars = g->ivars;
    Scope *s = scope_new(g->scope, 0); bg.scope = s;
    for (int i = 0; i < b->nparams; i++) scope_add(&bg, s, b->params[i]);
    for (int i = 0; i < b->ntemps; i++) scope_add(&bg, s, b->temps[i]);
    gen_stmts_value(&bg, b->stmts, b->nstmts);
    emit(&bg, OP_BLOCK_RETURN);
    oop m = finish_method(&bg, b->nparams, nilobj, 0);
    free(s);
    return m;
}

static void free_scopes(Scope *s) { while (s) { Scope *p = s->parent; free(s); s = p; } }

static oop compile(oop cls, const char *src, const char *category, bool doit, char *err, int errlen) {
    err[0] = 0;
    Method *m = parse_method(src, doit);
    if (m->err[0]) { snprintf(err, errlen, "%s", m->err); method_free(m); return NULL; }
    Gen g; memset(&g, 0, sizeof g); jmp_buf jb; g.jb = &jb; g.err = err; g.errlen = errlen; g.cls = cls; g.doit = doit;
    g.ivars = (cls->cls == classMetaclass) ? new_array(0) : class_ivar_names(cls);
    Scope *s = scope_new(NULL, 0); g.scope = s;
    if (setjmp(jb)) { free(g.code); free_scopes(g.scope); method_free(m); return NULL; }
    for (int i = 0; i < m->nparams; i++) scope_add(&g, s, m->params[i]);
    for (int i = 0; i < m->ntemps; i++) scope_add(&g, s, m->temps[i]);
    if (doit) {
        gen_stmts_value(&g, m->stmts, m->nstmts); emit(&g, OP_RETURN);
    } else {
        for (int i = 0; i < m->nstmts; i++) {
            gen_expr(&g, m->stmts[i]);
            if (m->stmts[i]->kind != N_RETURN) { emit(&g, OP_POP); adj(&g, -1); }
        }
        if (m->nstmts == 0 || m->stmts[m->nstmts - 1]->kind != N_RETURN) { emit(&g, OP_PUSH_SELF); emit(&g, OP_RETURN); }
    }
    oop sel = new_symbol(m->selector);
    oop cm = finish_method(&g, m->nparams, sel, m->primitive);
    SLOT(cm, M_SOURCE) = new_string(src);
    if (category) SLOT(cm, M_CATEGORY) = new_string(category);
    free(s); method_free(m);
    return cm;
}

oop compile_method(oop cls, const char *src, const char *category, char *err, int errlen) { return compile(cls, src, category, false, err, errlen); }
oop compile_doit(oop cls, const char *src, char *err, int errlen) { return compile(cls, src, NULL, true, err, errlen); }

void method_selector_of_source(const char *src, char *out, int outlen) {
    TokList l = lex_all(src); int i = 0; out[0] = 0;
    if (l.n && l.toks[0].type == T_IDENT) snprintf(out, outlen, "%s", l.toks[0].text);
    else if (l.n && (l.toks[0].type == T_BINARY || l.toks[0].type == T_BAR)) snprintf(out, outlen, "%s", l.toks[0].text);
    else while (i + 1 < l.n && l.toks[i].type == T_KEYWORD) { strncat(out, l.toks[i].text, outlen - strlen(out) - 1); i += 2; }
    lex_free(&l);
}
