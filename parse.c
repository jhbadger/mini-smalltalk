/* parse.c - recursive descent parser for Smalltalk-80 methods and expressions */
#include "ast.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <setjmp.h>

typedef struct { TokList l; int i; Method *m; jmp_buf jb; Node **all; int nall, capall; } P;

static void fail(P *p, const char *msg) {
    Token *t = &p->l.toks[p->i];
    snprintf(p->m->err, sizeof p->m->err, "%s (near '%s')", msg, t->text);
    p->m->errpos = t->pos; longjmp(p->jb, 1);
}
static Token *cur(P *p) { return &p->l.toks[p->i]; }
static Token *peek(P *p, int k) { int j = p->i + k; if (j >= p->l.n) j = p->l.n - 1; return &p->l.toks[j]; }
static int at(P *p, enum TokType t) { return cur(p)->type == t; }
static Token *advance(P *p) { Token *t = cur(p); if (p->i < p->l.n - 1) p->i++; return t; }
static void expect(P *p, enum TokType t, const char *what) { if (!at(p, t)) { char b[128]; snprintf(b, sizeof b, "expected %s", what); fail(p, b); } advance(p); }

static Node *node(P *p, int kind) {
    Node *n = calloc(1, sizeof(Node)); n->kind = kind; n->pos = cur(p)->pos;
    if (p->nall == p->capall) { p->capall = p->capall ? p->capall * 2 : 64; p->all = realloc(p->all, p->capall * sizeof(Node *)); }
    p->all[p->nall++] = n; return n;
}
static void addarg(Node *n, Node *a) { n->args = realloc(n->args, (n->nargs + 1) * sizeof(Node *)); n->args[n->nargs++] = a; }
static void addstmt(Node *n, Node *s) { n->stmts = realloc(n->stmts, (n->nstmts + 1) * sizeof(Node *)); n->stmts[n->nstmts++] = s; }
static void addname(char ***arr, int *n, const char *s) { *arr = realloc(*arr, (*n + 1) * sizeof(char *)); (*arr)[(*n)++] = strdup(s); }

static Node *parse_expr(P *p);
static Node *parse_stmts_into(P *p, Node *blk, enum TokType end);

static oop parse_literal_array(P *p) {
    /* after #( ; collect elements until ) */
    oop items[1024]; int n = 0;
    while (!at(p, T_RPAREN)) {
        if (at(p, T_EOF)) fail(p, "unterminated literal array");
        Token *t = cur(p); oop v = NULL; int consumed = 0;
        switch (t->type) {
        case T_INT: v = t->big ? bn_from_string(t->text, t->radix) : MK_INT(t->ival); break;
        case T_FLOAT: v = new_float(t->fval); break;
        case T_STRING: v = new_string(t->text); break;
        case T_SYMBOL: v = new_symbol(t->text); break;
        case T_CHAR: v = charTable[t->ival & 255]; break;
        case T_IDENT:
            if (!strcmp(t->text, "true")) v = trueobj; else if (!strcmp(t->text, "false")) v = falseobj;
            else if (!strcmp(t->text, "nil")) v = nilobj; else v = new_symbol(t->text); break;
        case T_KEYWORD: {
            /* adjacent keywords form one symbol e.g. at:put: */
            char buf[256]; strcpy(buf, t->text);
            while (peek(p, 1)->type == T_KEYWORD && peek(p, 1)->pos == t->pos + (int)strlen(buf)) { advance(p); t = cur(p); strcat(buf, t->text); }
            v = new_symbol(buf); break; }
        case T_BINARY: case T_BAR: v = new_symbol(t->text); break;
        case T_LPAREN: case T_HASHPAREN: advance(p); v = parse_literal_array(p); consumed = 1; break;
        case T_HASHBRACK: case T_LBRACK: {
            advance(p); unsigned char b[1024]; int k = 0;
            while (at(p, T_INT)) { if (k < 1024) b[k++] = (unsigned char)cur(p)->ival; advance(p); }
            expect(p, T_RBRACK, "]"); v = new_bytes(classByteArray, k); memcpy(BYTES(v), b, k); consumed = 1; break; }
        default: fail(p, "bad literal array element");
        }
        if (t->type == T_BINARY && !strcmp(t->text, "-") && peek(p, 1)->type == T_INT) { advance(p); v = MK_INT(-cur(p)->ival); }
        else if (t->type == T_BINARY && !strcmp(t->text, "-") && peek(p, 1)->type == T_FLOAT) { advance(p); v = new_float(-cur(p)->fval); }
        if (!consumed) advance(p);
        if (n < 1024) items[n++] = v;
    }
    advance(p);
    oop a = new_array(n); for (int i = 0; i < n; i++) SLOT(a, i) = items[i]; return a;
}

static Node *parse_block(P *p) {
    Node *b = node(p, N_BLOCK); expect(p, T_LBRACK, "[");
    while (at(p, T_COLON)) { advance(p); if (!at(p, T_IDENT)) fail(p, "expected block parameter name"); addname(&b->params, &b->nparams, advance(p)->text); }
    if (b->nparams) { if (at(p, T_BAR)) advance(p); else if (!at(p, T_RBRACK)) fail(p, "expected | after block parameters"); }
    if (at(p, T_BAR)) { advance(p); while (at(p, T_IDENT)) addname(&b->temps, &b->ntemps, advance(p)->text); expect(p, T_BAR, "|"); }
    parse_stmts_into(p, b, T_RBRACK);
    expect(p, T_RBRACK, "]");
    return b;
}

static Node *parse_primary(P *p) {
    Token *t = cur(p); Node *n;
    switch (t->type) {
    case T_IDENT: n = node(p, N_VAR); n->name = strdup(t->text); advance(p); return n;
    case T_INT: n = node(p, N_LIT); n->lit = t->big ? bn_from_string(t->text, t->radix) : MK_INT(t->ival); advance(p); return n;
    case T_FLOAT: n = node(p, N_LIT); n->lit = new_float(t->fval); advance(p); return n;
    case T_STRING: n = node(p, N_LIT); n->lit = new_string(t->text); advance(p); return n;
    case T_SYMBOL: n = node(p, N_LIT); n->lit = new_symbol(t->text); advance(p); return n;
    case T_CHAR: n = node(p, N_LIT); n->lit = charTable[t->ival & 255]; advance(p); return n;
    case T_HASHPAREN: advance(p); n = node(p, N_LIT); n->lit = parse_literal_array(p); return n;
    case T_HASHBRACK: {
        advance(p); unsigned char b[4096]; int k = 0;
        while (at(p, T_INT)) { if (k < 4096) b[k++] = (unsigned char)cur(p)->ival; advance(p); }
        expect(p, T_RBRACK, "]"); n = node(p, N_LIT); n->lit = new_bytes(classByteArray, k); memcpy(BYTES(n->lit), b, k); return n; }
    case T_LBRACK: return parse_block(p);
    case T_LPAREN: advance(p); n = parse_expr(p); expect(p, T_RPAREN, ")"); return n;
    case T_LBRACE: {
        advance(p); n = node(p, N_BRACE);
        while (!at(p, T_RBRACE)) { addarg(n, parse_expr(p)); if (at(p, T_PERIOD)) advance(p); else break; }
        expect(p, T_RBRACE, "}"); return n; }
    case T_BINARY:
        if (!strcmp(t->text, "-") && (peek(p, 1)->type == T_INT || peek(p, 1)->type == T_FLOAT)) {
            advance(p); t = cur(p); n = node(p, N_LIT);
            n->lit = t->type == T_INT ? (t->big ? bn_negate(bn_from_string(t->text, t->radix)) : MK_INT(-t->ival)) : new_float(-t->fval); advance(p); return n;
        }
        fail(p, "unexpected binary selector");
    default: { char b[128]; snprintf(b, sizeof b, "unexpected %s", lex_name(t->type)); fail(p, b); }
    }
    return NULL;
}

static Node *mksend(P *p, Node *recv, const char *sel) { Node *n = node(p, N_SEND); n->recv = recv; n->sel = strdup(sel); return n; }

static Node *parse_unary_tail(P *p, Node *recv) {
    while (at(p, T_IDENT)) { recv = mksend(p, recv, cur(p)->text); advance(p); }
    return recv;
}
static Node *parse_binary_tail(P *p, Node *recv) {
    while (at(p, T_BINARY) || at(p, T_BAR)) {
        Node *s = mksend(p, recv, cur(p)->text); advance(p);
        addarg(s, parse_unary_tail(p, parse_primary(p))); recv = s;
    }
    return recv;
}
static Node *parse_keyword_tail(P *p, Node *recv) {
    if (!at(p, T_KEYWORD)) return recv;
    char sel[512] = ""; Node *s = node(p, N_SEND); s->recv = recv;
    while (at(p, T_KEYWORD)) {
        strcat(sel, cur(p)->text); advance(p);
        addarg(s, parse_binary_tail(p, parse_unary_tail(p, parse_primary(p))));
    }
    s->sel = strdup(sel); return s;
}
/* parse one cascaded message (no receiver) */
static Node *parse_cascade_msg(P *p) {
    if (at(p, T_IDENT)) { Node *s = mksend(p, NULL, cur(p)->text); advance(p); return s; }
    if (at(p, T_BINARY) || at(p, T_BAR)) {
        Node *s = mksend(p, NULL, cur(p)->text); advance(p);
        addarg(s, parse_unary_tail(p, parse_primary(p))); return s;
    }
    if (at(p, T_KEYWORD)) return parse_keyword_tail(p, NULL);
    fail(p, "expected message after ;"); return NULL;
}

static Node *parse_expr(P *p) {
    if (at(p, T_IDENT) && peek(p, 1)->type == T_ASSIGN) {
        Node *a = node(p, N_ASSIGN); a->name = strdup(cur(p)->text); advance(p); advance(p);
        a->recv = parse_expr(p); return a;
    }
    Node *e = parse_keyword_tail(p, parse_binary_tail(p, parse_unary_tail(p, parse_primary(p))));
    if (at(p, T_SEMI)) {
        if (e->kind != N_SEND) fail(p, "cascade without a message");
        Node *c = node(p, N_CASCADE); c->recv = e->recv;
        Node *first = e; first->recv = NULL; addarg(c, first);
        while (at(p, T_SEMI)) { advance(p); addarg(c, parse_cascade_msg(p)); }
        return c;
    }
    return e;
}

static Node *parse_statement(P *p) {
    if (at(p, T_CARET)) { Node *r = node(p, N_RETURN); advance(p); r->recv = parse_expr(p); return r; }
    return parse_expr(p);
}
static Node *parse_stmts_into(P *p, Node *blk, enum TokType end) {
    while (!at(p, end) && !at(p, T_EOF)) {
        addstmt(blk, parse_statement(p));
        if (at(p, T_PERIOD)) advance(p); else break;
    }
    return blk;
}

Method *parse_method(const char *src, bool doit) {
    Method *m = calloc(1, sizeof(Method));
    P p; memset(&p, 0, sizeof p); p.m = m; p.l = lex_all(src);
    if (setjmp(p.jb)) {
        lex_free(&p.l);
        for (int i = 0; i < p.nall; i++) {   /* free nodes non-recursively: every node is in the arena */
            Node *n = p.all[i]; free(n->name); free(n->sel); free(n->args); free(n->stmts);
            for (int j = 0; j < n->nparams; j++) free(n->params[j]); free(n->params);
            for (int j = 0; j < n->ntemps; j++) free(n->temps[j]); free(n->temps);
            free(n);
        }
        free(p.all); m->stmts = NULL; m->nstmts = 0;
        return m;
    }
    if (doit) m->selector = strdup("DoIt");
    else {
        char sel[512] = "";
        if (at(&p, T_IDENT)) { strcpy(sel, cur(&p)->text); advance(&p); }
        else if (at(&p, T_BINARY) || at(&p, T_BAR)) {
            strcpy(sel, cur(&p)->text); advance(&p);
            if (!at(&p, T_IDENT)) fail(&p, "expected argument name"); addname(&m->params, &m->nparams, advance(&p)->text);
        } else if (at(&p, T_KEYWORD)) {
            while (at(&p, T_KEYWORD)) {
                strcat(sel, cur(&p)->text); advance(&p);
                if (!at(&p, T_IDENT)) fail(&p, "expected argument name"); addname(&m->params, &m->nparams, advance(&p)->text);
            }
        } else fail(&p, "expected method pattern");
        m->selector = strdup(sel);
    }
    if (at(&p, T_BAR)) { advance(&p); while (at(&p, T_IDENT)) addname(&m->temps, &m->ntemps, advance(&p)->text); expect(&p, T_BAR, "|"); }
    if (at(&p, T_BINARY) && !strcmp(cur(&p)->text, "<") && peek(&p, 1)->type == T_KEYWORD && !strcmp(peek(&p, 1)->text, "primitive:")) {
        advance(&p); advance(&p); if (!at(&p, T_INT)) fail(&p, "expected primitive number"); m->primitive = (int)advance(&p)->ival;
        if (!(at(&p, T_BINARY) && !strcmp(cur(&p)->text, ">"))) fail(&p, "expected >"); advance(&p);
    }
    if (at(&p, T_BAR)) { advance(&p); while (at(&p, T_IDENT)) addname(&m->temps, &m->ntemps, advance(&p)->text); expect(&p, T_BAR, "|"); }
    Node tmp; memset(&tmp, 0, sizeof tmp);
    parse_stmts_into(&p, &tmp, T_EOF);
    if (!at(&p, T_EOF)) fail(&p, "unexpected token");
    m->stmts = tmp.stmts; m->nstmts = tmp.nstmts;
    lex_free(&p.l);
    m->errpos = -1;
    free(p.all);   /* nodes are freed by method_free walking the tree */
    return m;
}

static void node_free(Node *n) {
    if (!n) return;
    free(n->name); free(n->sel);
    node_free(n->recv);
    for (int i = 0; i < n->nargs; i++) node_free(n->args[i]); free(n->args);
    for (int i = 0; i < n->nstmts; i++) node_free(n->stmts[i]); free(n->stmts);
    for (int i = 0; i < n->nparams; i++) free(n->params[i]); free(n->params);
    for (int i = 0; i < n->ntemps; i++) free(n->temps[i]); free(n->temps);
    free(n);
}
void method_free(Method *m) {
    if (!m) return;
    free(m->selector);
    for (int i = 0; i < m->nparams; i++) free(m->params[i]); free(m->params);
    for (int i = 0; i < m->ntemps; i++) free(m->temps[i]); free(m->temps);
    for (int i = 0; i < m->nstmts; i++) node_free(m->stmts[i]); free(m->stmts);
    free(m);
}
