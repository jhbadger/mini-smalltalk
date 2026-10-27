/* ast.h - parse tree for the compiler */
#ifndef AST_H
#define AST_H
#include "st.h"
#include "lex.h"
enum { N_LIT, N_VAR, N_ASSIGN, N_SEND, N_CASCADE, N_BLOCK, N_RETURN, N_BRACE };
typedef struct Node Node;
struct Node {
    int kind, pos;
    oop lit;                 /* N_LIT */
    char *name;              /* N_VAR, N_ASSIGN target */
    Node *recv;              /* N_SEND receiver (NULL inside cascade list), N_ASSIGN value, N_RETURN value, N_CASCADE receiver */
    char *sel;               /* N_SEND selector */
    Node **args; int nargs;  /* N_SEND args, N_CASCADE messages, N_BRACE elements */
    Node **stmts; int nstmts;/* N_BLOCK body */
    char **params; int nparams; /* N_BLOCK params */
    char **temps; int ntemps;   /* N_BLOCK temps */
};
typedef struct {
    char *selector; char **params; int nparams; char **temps; int ntemps;
    Node **stmts; int nstmts; int primitive; char err[256]; int errpos;
} Method;
Method *parse_method(const char *src, bool doit);
void method_free(Method *m);
#endif
