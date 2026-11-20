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
    bool inblock;           /* generating a real (non-inlined) block: ^ is a non-local return */
    const char *tempnames[256]; int ntempnames;      /* the name of each temporary, by its index */
    int map[512][2]; int nmap;                       /* pc -> source offset, one entry per statement */
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
    { int i = s->idx[s->n - 1];      /* remember the name so the debugger can show it */
      if (i >= 0 && i < 256) { g->tempnames[i] = name; if (i + 1 > g->ntempnames) g->ntempnames = i + 1; } }
}
/* note that the statement starting at this source offset begins at the current bytecode */
static void mark_source(Gen *g, int pos) {
    if (g->nmap > 0 && g->map[g->nmap - 1][0] == g->n) { g->map[g->nmap - 1][1] = pos; return; }
    if (g->nmap >= 512) return;
    g->map[g->nmap][0] = g->n; g->map[g->nmap][1] = pos; g->nmap++;
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

/* ---------- special sends: arithmetic, comparison and indexing get their own opcodes (see st.h) ---------- */
static const struct { const char *sel; int nargs; int op; } special_sends[] = {
    {"+", 1, OP_ADD}, {"-", 1, OP_SUB}, {"*", 1, OP_MUL}, {"<", 1, OP_LT}, {">", 1, OP_GT}, {"<=", 1, OP_LE}, {">=", 1, OP_GE},
    {"=", 1, OP_EQ}, {"~=", 1, OP_NE}, {"==", 1, OP_IDENT}, {"\\\\", 1, OP_MOD}, {"//", 1, OP_DIV},
    {"at:", 1, OP_AT}, {"at:put:", 2, OP_ATPUT},
};
static int send_opcode(const char *sel, int nargs) {
    for (size_t i = 0; i < sizeof special_sends / sizeof special_sends[0]; i++)
        if (nargs == special_sends[i].nargs && !strcmp(sel, special_sends[i].sel)) return special_sends[i].op;
    return OP_SEND;
}
/* the arguments are already on the stack */
static void emit_send(Gen *g, const char *sel, int nargs) {
    emit(g, send_opcode(sel, nargs)); emit(g, addlit(g, new_symbol(sel))); emit(g, nargs);
    adj(g, -nargs);
}

/* ---------- which sends the compiler inlines ---------- */
enum { IL_NONE, IL_COND1, IL_COND2, IL_WHILE, IL_TODO, IL_TOBYDO, IL_TIMES };
static int inline_kind(Node *recv, const char *sel, Node **args, int nargs);

/* Does `n` mention one of names[0..nn) from inside a real (not inlined) block, or assign to the loop variable names[0]?
   The inlined loops keep their variable in the enclosing context, so a block that captured it would see the
   later iterations instead of its own; such loops are not inlined. Over-approximate: shadowing is ignored. */
static int touches(Node *n, const char **names, int nn, int inreal) {
    if (!n) return 0;
    switch (n->kind) {
    case N_LIT: return 0;
    case N_VAR: if (inreal) for (int i = 0; i < nn; i++) if (!strcmp(n->name, names[i])) return 1; return 0;
    case N_ASSIGN:
        for (int i = 0; i < nn; i++) if (!strcmp(n->name, names[i]) && (inreal || i == 0)) return 1;
        return touches(n->recv, names, nn, inreal);
    case N_RETURN: return touches(n->recv, names, nn, inreal);
    case N_BLOCK:
        for (int i = 0; i < n->nstmts; i++) if (touches(n->stmts[i], names, nn, 1)) return 1;
        return 0;
    case N_BRACE: for (int i = 0; i < n->nargs; i++) if (touches(n->args[i], names, nn, inreal)) return 1; return 0;
    case N_CASCADE:
        if (touches(n->recv, names, nn, inreal)) return 1;
        for (int i = 0; i < n->nargs; i++) for (int j = 0; j < n->args[i]->nargs; j++) if (touches(n->args[i]->args[j], names, nn, inreal)) return 1;
        return 0;
    case N_SEND: {
        int kind = n->recv ? inline_kind(n->recv, n->sel, n->args, n->nargs) : IL_NONE;
        Node *inl[3] = {NULL, NULL, NULL};     /* the blocks that will be inlined: their bodies run in the enclosing context */
        switch (kind) {
        case IL_COND1: case IL_TIMES: inl[0] = n->args[0]; break;
        case IL_COND2: inl[0] = n->args[0]; inl[1] = n->args[1]; break;
        case IL_WHILE: inl[0] = n->recv; if (n->nargs) inl[1] = n->args[0]; break;
        case IL_TODO: inl[0] = n->args[1]; break;
        case IL_TOBYDO: inl[0] = n->args[2]; break;
        }
        Node *kids[4]; int nk = 0; kids[nk++] = n->recv; for (int i = 0; i < n->nargs && nk < 4; i++) kids[nk++] = n->args[i];
        int more = n->nargs > 3;
        for (int k = 0; k < nk; k++) {
            Node *c = kids[k]; int isinl = c && (c == inl[0] || c == inl[1] || c == inl[2]);
            if (isinl) { for (int i = 0; i < c->nstmts; i++) if (touches(c->stmts[i], names, nn, inreal)) return 1; }
            else if (touches(c, names, nn, inreal)) return 1;
        }
        if (more) for (int i = 3; i < n->nargs; i++) if (touches(n->args[i], names, nn, inreal)) return 1;
        return 0; }
    }
    return 0;
}
/* a one-parameter literal block whose parameter and temporaries can live in the enclosing context */
static int loop_block_ok(Node *blk) {
    const char *names[64]; int nn = 0;
    names[nn++] = blk->params[0];
    for (int i = 0; i < blk->ntemps && nn < 64; i++) names[nn++] = blk->temps[i];
    if (blk->ntemps >= 63) return 0;
    for (int i = 0; i < blk->nstmts; i++) if (touches(blk->stmts[i], names, nn, 0)) return 0;
    return 1;
}
static int timesrepeat_block_ok(Node *blk) {      /* no parameter; its temporaries must not be captured either */
    if (blk->ntemps == 0) return 1;
    if (blk->ntemps >= 64) return 0;
    const char *names[64]; int nn = 0;
    for (int i = 0; i < blk->ntemps; i++) names[nn++] = blk->temps[i];
    for (int i = 0; i < blk->nstmts; i++) if (touches(blk->stmts[i], names, nn, 0)) return 0;
    return 1;
}

static int inline_kind(Node *recv, const char *sel, Node **args, int nargs) {
    if (nargs == 1 && (!strcmp(sel, "ifTrue:") || !strcmp(sel, "ifFalse:") || !strcmp(sel, "and:") || !strcmp(sel, "or:"))
        && is_literal_block(args[0], 0)) return IL_COND1;
    if (nargs == 2 && (!strcmp(sel, "ifTrue:ifFalse:") || !strcmp(sel, "ifFalse:ifTrue:"))
        && is_literal_block(args[0], 0) && is_literal_block(args[1], 0)) return IL_COND2;
    if ((nargs == 1 && (!strcmp(sel, "whileTrue:") || !strcmp(sel, "whileFalse:")) && is_literal_block(args[0], 0) && is_literal_block(recv, 0))
        || (nargs == 0 && (!strcmp(sel, "whileTrue") || !strcmp(sel, "whileFalse")) && is_literal_block(recv, 0))) return IL_WHILE;
    if (nargs == 2 && !strcmp(sel, "to:do:") && is_literal_block(args[1], 1) && loop_block_ok(args[1])) return IL_TODO;
    if (nargs == 3 && !strcmp(sel, "to:by:do:") && args[1]->kind == N_LIT && IS_INT(args[1]->lit) && INT_VAL(args[1]->lit) != 0
        && is_literal_block(args[2], 1) && loop_block_ok(args[2])) return IL_TOBYDO;
    if (nargs == 1 && !strcmp(sel, "timesRepeat:") && is_literal_block(args[0], 0) && timesrepeat_block_ok(args[0])) return IL_TIMES;
    return IL_NONE;
}

/* a counting loop: start to: stop [by: step] do: [:i | body], or n timesRepeat: [body] (var == NULL).
   Locals: a hidden limit (unless stop is a literal), the loop variable, the body's temporaries - all in this context.
   Like the methods in Number, the expression's value is the receiver. */
static void gen_counted_loop(Gen *g, Node *recv, Node *stop, Node *step, Node *blk, int times) {
    Scope *s = scope_new(g->scope, 1);
    int stop_lit = !times && stop->kind == N_LIT;
    int need_limit = times || !stop_lit;
    int limit_idx = -1, var_idx;
    if (need_limit) { scope_add(g, s, "(limit)"); limit_idx = s->idx[s->n - 1]; }
    scope_add(g, s, times ? "(count)" : blk->params[0]); var_idx = s->idx[s->n - 1];
    int first_temp = s->n;
    for (int i = 0; i < blk->ntemps; i++) scope_add(g, s, blk->temps[i]);
    /* initial values, evaluated in the enclosing scope; the receiver stays on the stack as the expression's value */
    gen_expr(g, recv);
    if (times) {
        emit1(g, OP_STORE_TEMP, limit_idx);
        emit1(g, OP_PUSH_INT, 1); adj(g, 1); emit1(g, OP_STORE_TEMP, var_idx); emit(g, OP_POP); adj(g, -1);
    } else {
        emit1(g, OP_STORE_TEMP, var_idx);
        if (need_limit) { gen_expr(g, stop); emit1(g, OP_STORE_TEMP, limit_idx); emit(g, OP_POP); adj(g, -1); }
    }
    int descending = step && INT_VAL(step->lit) < 0;
    int top = g->n;
    emit1(g, OP_PUSH_TEMP, var_idx); adj(g, 1);
    if (need_limit) { emit1(g, OP_PUSH_TEMP, limit_idx); adj(g, 1); } else gen_expr(g, stop);
    emit_send(g, descending ? ">=" : "<=", 1);
    int jend = emit_jump(g, OP_JUMP_FALSE); adj(g, -1);
    g->scope = s;
    for (int i = 0; i < blk->ntemps; i++) { emit(g, OP_PUSH_NIL); adj(g, 1); emit1(g, OP_STORE_TEMP, s->idx[first_temp + i]); emit(g, OP_POP); adj(g, -1); }
    gen_stmts_value(g, blk->stmts, blk->nstmts); emit(g, OP_POP); adj(g, -1);
    g->scope = s->parent;
    emit1(g, OP_PUSH_TEMP, var_idx); adj(g, 1);
    if (step) gen_expr(g, step); else { emit1(g, OP_PUSH_INT, 1); adj(g, 1); }
    emit_send(g, "+", 1);
    emit1(g, OP_STORE_TEMP, var_idx); emit(g, OP_POP); adj(g, -1);
    int jb = emit_jump(g, OP_JUMP); patch(g, jb, top);
    patch(g, jend, g->n);
    free(s);
}

static int try_inline(Gen *g, Node *recv, const char *sel, Node **args, int nargs) {
    switch (inline_kind(recv, sel, args, nargs)) {
    case IL_COND1: {
        gen_expr(g, recv);
        int neg = !strcmp(sel, "ifFalse:") || !strcmp(sel, "or:");
        int j1 = emit_jump(g, neg ? OP_JUMP_TRUE : OP_JUMP_FALSE); adj(g, -1);
        gen_inline_block(g, args[0]);
        int j2 = emit_jump(g, OP_JUMP); adj(g, -1);
        patch(g, j1, g->n);
        emit(g, !strcmp(sel, "and:") ? OP_PUSH_FALSE : !strcmp(sel, "or:") ? OP_PUSH_TRUE : OP_PUSH_NIL); adj(g, 1);
        patch(g, j2, g->n);
        return 1; }
    case IL_COND2: {
        gen_expr(g, recv);
        int j1 = emit_jump(g, !strcmp(sel, "ifTrue:ifFalse:") ? OP_JUMP_FALSE : OP_JUMP_TRUE); adj(g, -1);
        gen_inline_block(g, args[0]);
        int j2 = emit_jump(g, OP_JUMP); adj(g, -1);
        patch(g, j1, g->n);
        gen_inline_block(g, args[1]);
        patch(g, j2, g->n);
        return 1; }
    case IL_WHILE: {
        int neg = !strncmp(sel, "whileFalse", 10);
        int top = g->n;
        gen_inline_block(g, recv);
        int jend = emit_jump(g, neg ? OP_JUMP_TRUE : OP_JUMP_FALSE); adj(g, -1);
        if (nargs == 1) { gen_inline_block(g, args[0]); emit(g, OP_POP); adj(g, -1); }
        int jb = emit_jump(g, OP_JUMP); patch(g, jb, top);
        patch(g, jend, g->n);
        emit(g, OP_PUSH_NIL); adj(g, 1);
        return 1; }
    case IL_TODO: gen_counted_loop(g, recv, args[0], NULL, args[1], 0); return 1;
    case IL_TOBYDO: gen_counted_loop(g, recv, args[0], args[1], args[2], 0); return 1;
    case IL_TIMES: gen_counted_loop(g, recv, NULL, NULL, args[0], 1); return 1;
    }
    return 0;
}

static void gen_send_tail(Gen *g, const char *sel, Node **args, int nargs, int super) {
    for (int i = 0; i < nargs; i++) gen_expr(g, args[i]);
    if (super) { emit(g, OP_SUPER_SEND); emit(g, addlit(g, new_symbol(sel))); emit(g, nargs); adj(g, -nargs); }
    else emit_send(g, sel, nargs);
}

static void gen_expr(Gen *g, Node *n) {
    switch (n->kind) {
    case N_LIT:
        if (IS_INT(n->lit) && INT_VAL(n->lit) >= -128 && INT_VAL(n->lit) <= 127) emit1(g, OP_PUSH_INT, (int)INT_VAL(n->lit) & 255);
        else emit1(g, OP_PUSH_LIT, addlit(g, n->lit));
        adj(g, 1); break;
    case N_VAR: gen_var(g, n->name); break;
    case N_ASSIGN: gen_expr(g, n->recv); gen_store(g, n->name); break;
    case N_RETURN: gen_expr(g, n->recv); emit(g, OP_RETURN); if (g->inblock) emit(g, OP_RETURN_RETRY); break;
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
        mark_source(g, stmts[i]->pos);
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
    { oop names = new_array(ntemps);        /* the debugger shows temporaries by name */
      for (int i = 0; i < ntemps; i++) SLOT(names, i) = new_string(i < g->ntempnames && g->tempnames[i] ? g->tempnames[i] : "?");
      SLOT(m, M_TEMPNAMES) = names;
      oop map = new_array(g->nmap * 2);
      for (int i = 0; i < g->nmap; i++) { SLOT(map, i * 2) = MK_INT(g->map[i][0]); SLOT(map, i * 2 + 1) = MK_INT(g->map[i][1]); }
      SLOT(m, M_SOURCEMAP) = map; }
    free(g->code); g->code = NULL;
    return m;
}

static oop gen_block_method(Gen *g, Node *b) {
    Gen bg; memset(&bg, 0, sizeof bg);
    bg.cls = g->cls; bg.doit = g->doit; bg.jb = g->jb; bg.err = g->err; bg.errlen = g->errlen; bg.ivars = g->ivars; bg.inblock = true;
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
            mark_source(&g, m->stmts[i]->pos);
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
