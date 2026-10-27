/* lex.c - Smalltalk-80 tokenizer */
#include "lex.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

static void push(TokList *l, Token t) {
    if (l->n == l->cap) { l->cap = l->cap ? l->cap * 2 : 64; l->toks = realloc(l->toks, l->cap * sizeof(Token)); }
    l->toks[l->n++] = t;
}
static Token mk(enum TokType ty, const char *s, int n, int pos) {
    Token t = { ty, NULL, pos, 0, 0 }; t.text = malloc(n + 1); memcpy(t.text, s, n); t.text[n] = 0; return t;
}
static int isbin(int c) { return c && strchr("+-*/\\<>=~@%&?,|", c) != NULL; }

const char *lex_name(enum TokType t) {
    static const char *n[] = { "end of input", "identifier", "keyword", "binary selector", "integer", "float", "string",
        "symbol", "character", "(", ")", "[", "]", "{", "}", "#(", "#[", ".", ";", "^", ":=", ":", "|", "error" };
    return n[t];
}

/* parse number starting at s; returns chars consumed, fills t */
static int lex_number(const char *s, Token *t, int pos) {
    const char *p = s; int radix = 10;
    while (isdigit(*p)) p++;
    if (*p == 'r' && isalnum(p[1])) { radix = atoi(s); p++; } else p = s;
    intptr_t v = 0; int isfloat = 0; double fv = 0;
    for (;;) {
        int c = *p, d;
        if (isdigit(c)) d = c - '0'; else if (isupper(c)) d = c - 'A' + 10; else break;
        if (d >= radix) break;
        v = v * radix + d; p++;
    }
    if (radix == 10 && *p == '.' && isdigit(p[1])) {
        isfloat = 1; fv = (double)v; double scale = 0.1; p++;
        while (isdigit(*p)) { fv += (*p - '0') * scale; scale /= 10; p++; }
    }
    if (radix == 10 && *p == 'e' && (isdigit(p[1]) || (p[1] == '-' && isdigit(p[2])))) {
        p++; int neg = 0; if (*p == '-') { neg = 1; p++; }
        int e = 0; while (isdigit(*p)) e = e * 10 + (*p++ - '0');
        if (neg) { isfloat = 1; if (!fv) fv = (double)v; fv *= pow(10, -e); }
        else {
            double r = (isfloat ? fv : (double)v) * pow(10, e);
            if (isfloat || r > 1e17) { isfloat = 1; fv = r; } else v = (intptr_t)r;
        }
    }
    *t = mk(isfloat ? T_FLOAT : T_INT, s, (int)(p - s), pos);
    t->ival = v; t->fval = fv;
    return (int)(p - s);
}

TokList lex_all(const char *src) {
    TokList l = { 0, 0, 0 };
    const char *p = src;
    while (*p) {
        int pos = (int)(p - src);
        if (isspace((unsigned char)*p)) { p++; continue; }
        if (*p == '"') { p++; while (*p && *p != '"') p++; if (*p) p++; continue; }
        if (isalpha((unsigned char)*p) || *p == '_') {
            const char *s = p; while (isalnum((unsigned char)*p) || *p == '_') p++;
            if (*p == ':' && p[1] != '=') { p++; push(&l, mk(T_KEYWORD, s, (int)(p - s), pos)); }
            else push(&l, mk(T_IDENT, s, (int)(p - s), pos));
            continue;
        }
        if (isdigit((unsigned char)*p)) { Token t; p += lex_number(p, &t, pos); push(&l, t); continue; }
        if (*p == '\'') {
            p++; char *buf = malloc(strlen(p) + 1); int n = 0;
            for (;;) {
                if (!*p) break;
                if (*p == '\'') { if (p[1] == '\'') { buf[n++] = '\''; p += 2; continue; } p++; break; }
                buf[n++] = *p++;
            }
            Token t = mk(T_STRING, buf, n, pos); free(buf); push(&l, t); continue;
        }
        if (*p == '$' && p[1]) { Token t = mk(T_CHAR, p + 1, 1, pos); t.ival = (unsigned char)p[1]; push(&l, t); p += 2; continue; }
        if (*p == '#') {
            if (p[1] == '(') { push(&l, mk(T_HASHPAREN, "#(", 2, pos)); p += 2; continue; }
            if (p[1] == '[') { push(&l, mk(T_HASHBRACK, "#[", 2, pos)); p += 2; continue; }
            if (p[1] == '\'') {
                p += 2; char *buf = malloc(strlen(p) + 1); int n = 0;
                while (*p) { if (*p == '\'') { if (p[1] == '\'') { buf[n++] = '\''; p += 2; continue; } p++; break; } buf[n++] = *p++; }
                Token t = mk(T_SYMBOL, buf, n, pos); free(buf); push(&l, t); continue;
            }
            if (isalpha((unsigned char)p[1]) || p[1] == '_') {
                const char *s = ++p;
                while (isalnum((unsigned char)*p) || *p == '_' || (*p == ':' && p[1] != '=')) p++;
                push(&l, mk(T_SYMBOL, s, (int)(p - s), pos)); continue;
            }
            if (isbin(p[1])) { const char *s = ++p; while (isbin(*p)) p++; push(&l, mk(T_SYMBOL, s, (int)(p - s), pos)); continue; }
            push(&l, mk(T_ERROR, p, 1, pos)); p++; continue;
        }
        if (*p == ':' && p[1] == '=') { push(&l, mk(T_ASSIGN, ":=", 2, pos)); p += 2; continue; }
        if (*p == '_' ) { push(&l, mk(T_ASSIGN, "_", 1, pos)); p++; continue; }
        switch (*p) {
        case '(': push(&l, mk(T_LPAREN, p, 1, pos)); p++; continue;
        case ')': push(&l, mk(T_RPAREN, p, 1, pos)); p++; continue;
        case '[': push(&l, mk(T_LBRACK, p, 1, pos)); p++; continue;
        case ']': push(&l, mk(T_RBRACK, p, 1, pos)); p++; continue;
        case '{': push(&l, mk(T_LBRACE, p, 1, pos)); p++; continue;
        case '}': push(&l, mk(T_RBRACE, p, 1, pos)); p++; continue;
        case '.': push(&l, mk(T_PERIOD, p, 1, pos)); p++; continue;
        case ';': push(&l, mk(T_SEMI, p, 1, pos)); p++; continue;
        case '^': push(&l, mk(T_CARET, p, 1, pos)); p++; continue;
        case ':': push(&l, mk(T_COLON, p, 1, pos)); p++; continue;
        case '!': push(&l, mk(T_ERROR, p, 1, pos)); p++; continue;
        }
        if (*p == '|' && !isbin(p[1])) { push(&l, mk(T_BAR, p, 1, pos)); p++; continue; }
        if (isbin(*p)) {
            const char *s = p; p++;
            while (isbin(*p) && !(*p == '-' && isdigit((unsigned char)p[1]))) p++;
            push(&l, mk(T_BINARY, s, (int)(p - s), pos)); continue;
        }
        push(&l, mk(T_ERROR, p, 1, pos)); p++;
    }
    push(&l, mk(T_EOF, "", 0, (int)(p - src)));
    return l;
}

void lex_free(TokList *l) { for (int i = 0; i < l->n; i++) free(l->toks[i].text); free(l->toks); l->toks = NULL; l->n = l->cap = 0; }
