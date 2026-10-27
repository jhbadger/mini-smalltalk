/* lex.h - Smalltalk tokenizer */
#ifndef LEX_H
#define LEX_H
#include <stdint.h>
enum TokType { T_EOF, T_IDENT, T_KEYWORD, T_BINARY, T_INT, T_FLOAT, T_STRING, T_SYMBOL, T_CHAR,
    T_LPAREN, T_RPAREN, T_LBRACK, T_RBRACK, T_LBRACE, T_RBRACE, T_HASHPAREN, T_HASHBRACK,
    T_PERIOD, T_SEMI, T_CARET, T_ASSIGN, T_COLON, T_BAR, T_ERROR };
typedef struct { enum TokType type; char *text; int pos; intptr_t ival; double fval; } Token;
typedef struct { Token *toks; int n, cap; } TokList;
TokList lex_all(const char *src);
void lex_free(TokList *l);
const char *lex_name(enum TokType t);
#endif
