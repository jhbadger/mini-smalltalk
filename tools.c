/* tools.c - System Browser, Workspace, Transcript, Inspector, error notifier, system menu */
#include "ui.h"
#include "tools.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <strings.h>

extern oop pending_inspect;
bool ui_quit = false;
enum { W_BROWSER = 1, W_WORKSPACE, W_TRANSCRIPT, W_INSPECTOR, W_LESSON, W_LISTTOOL, W_NOTEBOOK };
static void browsers_refresh(void);

/* ---------- helpers ---------- */
static int cmp_str(const void *a, const void *b) { return strcmp(*(const char **)a, *(const char **)b); }
static bool is_class(oop v) { return !IS_INT(v) && v != nilobj && v->cls && !IS_INT(v->cls) && v->cls->cls == classMetaclass; }
typedef struct { char **v; int n, cap; } StrList;
static void sl_add(StrList *l, const char *s) {
    for (int i = 0; i < l->n; i++) if (!strcmp(l->v[i], s)) return;
    if (l->n == l->cap) { l->cap = l->cap ? l->cap * 2 : 32; l->v = realloc(l->v, l->cap * sizeof(char *)); }
    l->v[l->n++] = strdup(s);
}
static void sl_sort(StrList *l) { qsort(l->v, l->n, sizeof(char *), cmp_str); }
static char *oop_str(oop s) { return s == nilobj || IS_INT(s) ? strdup("") : str_cstr(s); }
static oop class_named(const char *name) { oop c = global_lookup(name); return is_class(c) ? c : NULL; }

/* An unhandled error. When the Debugger package is loaded it is given the context the error came from;
   otherwise (and if the debugger itself fails) the walkback window is shown as before. */
bool tools_open_debugger(void) {
    oop dbg = class_named("Debugger");
    if (!dbg || !interp.errorContext || interp.errorContext == nilobj) return false;
    oop args[2] = { interp.errorContext, new_string(interp.error) };
    interp.failed = false;
    interp_send(dbg, new_symbol("openOn:message:"), args, 2);
    interp.errorContext = NULL;
    if (interp.failed) { interp.failed = false; return false; }
    return true;
}
static void show_error(void) {
    if (tools_open_debugger()) { tools_after_eval(); return; }
    char *buf = malloc(strlen(interp.error) + strlen(interp.walkback) + 64);
    sprintf(buf, "%s\n\n%s", interp.error, interp.walkback);
    char title[200]; snprintf(title, sizeof title, "Error: %.150s", interp.error);
    dialog_text(title, buf); free(buf); interp.failed = false;
}
/* evaluate src with receiver; shows an error window on failure; returns NULL on failure */
static oop evaluate(const char *src, oop receiver, bool *ok) {
    char err[512]; oop r = interp_eval(receiver, src, err, sizeof err);
    if (interp.failed) { show_error(); *ok = false; return nilobj; }
    *ok = true; return r;
}

/* ---------- code pane actions (shared by workspace, browser, inspector) ---------- */
typedef struct { oop receiver; bool rooted; char *tool; } EvalCtx;   /* tool: a Smalltalk class whose #evaluate: handles the text (a language workspace) */
static oop pane_receiver(Pane *p) { EvalCtx *c = p->user; return c && c->receiver ? c->receiver : nilobj; }
/* evaluate src for a pane: Smalltalk by default, or through the pane's tool class (#evaluate: answering a String) */
static oop pane_eval(Pane *p, const char *src, bool *ok, bool *is_text) {
    EvalCtx *c = p->user; *is_text = false;
    if (c && c->tool) {
        oop cls = class_named(c->tool);
        if (!cls) { ui_status("no class named %s", c->tool); *ok = false; return nilobj; }
        oop arg = new_string(src);
        oop r = interp_send(cls, new_symbol("evaluate:"), &arg, 1);
        if (interp.failed) { show_error(); *ok = false; return nilobj; }
        *ok = true; *is_text = true; return r;
    }
    return evaluate(src, pane_receiver(p), ok);
}
static void do_it(Pane *p) { char *src = text_selection_or_line(p); bool ok, txt; pane_eval(p, src, &ok, &txt); free(src); if (ok) ui_status("done"); tools_after_eval(); }
static void print_it(Pane *p) {
    char *src = text_selection_or_line(p); bool ok, txt; oop r = pane_eval(p, src, &ok, &txt); free(src);
    if (!ok) return;
    char *s = txt ? str_cstr(r) : str_cstr(interp_print_string(r));
    int end = p->anchor >= 0 && p->anchor > p->cursor ? p->anchor : p->cursor;
    if (p->anchor < 0 || p->anchor == p->cursor) { while (end < p->len && p->text[end] != '\n') end++; }
    char *ins = malloc(strlen(s) + 3); sprintf(ins, txt ? "\n%s" : " %s", s);
    p->anchor = -1; p->cursor = end; text_insert(p, ins); text_select_range(p, end, end + (int)strlen(ins));
    free(ins); free(s); tools_after_eval();
}
static void inspect_it(Pane *p) { char *src = text_selection_or_line(p); bool ok, txt; oop r = pane_eval(p, src, &ok, &txt); free(src); if (ok) open_inspector(r); tools_after_eval(); }
static bool code_key(Pane *p, Event *ev) {
    if (!(ev->mods & MOD_CTRL)) return false;
    switch (ev->key) { case 'd': do_it(p); return true; case 'p': print_it(p); return true; case 't': inspect_it(p); return true; }
    return false;
}
static const char *ws_menu[] = { "do it", "print it", "inspect it", "-", "copy", "cut", "paste", "select all" };
static void ws_menu_cb(Pane *p, int i) {
    switch (i) { case 0: do_it(p); break; case 1: print_it(p); break; case 2: inspect_it(p); break;
    case 4: text_copy(p); break; case 5: text_cut(p); break; case 6: text_paste(p); break; case 7: text_select_all(p); break; }
}

/* ---------- Workspace ---------- */
static void single_layout(Window *w) { w->panes[0]->r = (Rect){ w->r.x + 1, w->r.y + 1, w->r.w - 2, w->r.h - 2 }; }
static int cascade = 0;
void open_workspace(void) {
    Window *w = win_new("Workspace", 4 + cascade * 3, 2 + cascade, tui_cols * 3 / 5, tui_rows / 2 - 1); cascade = (cascade + 1) % 5;
    w->kind = W_WORKSPACE; w->layout = single_layout;
    Pane *t = win_add_text(w, false); t->menu = ws_menu; t->nmenu = 8; t->on_menu = ws_menu_cb; t->on_key = code_key;
    text_set(t, "\"Workspace: select an expression (or leave the cursor on its line) and use the right-button menu,\n"
                " or ctrl-D (do it), ctrl-P (print it), ctrl-T (inspect it). ctrl-Q quits.\"\n\n"
                "3 + 4 * 2.\n(1 to: 10) inject: 0 into: [:a :b | a + b].\n#(3 1 2) asSortedCollection.\n"
                "Transcript show: 'Hello from Smalltalk-80'; cr.\n"
                "Smalltalk allClasses size.\n");
}

/* a workspace for another language: do it / print it send  toolClass evaluate: text  (see Prolog) */
static void open_tool_workspace(const char *title, const char *tool, const char *text) {
    Window *w = win_new(title, 4 + cascade * 3, 2 + cascade, tui_cols * 3 / 5, tui_rows / 2 - 1); cascade = (cascade + 1) % 5;
    w->kind = W_WORKSPACE; w->layout = single_layout;
    Pane *t = win_add_text(w, false); t->menu = ws_menu; t->nmenu = 8; t->on_menu = ws_menu_cb; t->on_key = code_key;
    EvalCtx *c = calloc(1, sizeof *c); c->tool = strdup(tool); t->user = c;
    text_set(t, text);
}

/* ---------- Notebook ----------
   A text file of prose with Smalltalk in it, written the Markdown way: code goes between fence lines of three
   backquotes (``` alone, or ```smalltalk or ```st), and printing a cell puts its value in a ```result block under it,
   which the next run of the cell replaces. Fences with any other word after them are shown as code but not run. */
enum { NB_PROSE, NB_CODE, NB_RESULT, NB_OTHER };
typedef struct { int open, body, body_end, end, kind; bool closed; } Cell;   /* positions in the text; body..body_end is the code */
typedef struct { char *path; } Notebook;
#define NB_CODE_BG 254
#define NB_FENCE_FG C_DIM_FG
#define NB_RESULT_FG 24

/* a fence line: up to three spaces, then ``` and an optional word; *kind says what the fence opens */
static bool nb_fence(const char *s, const char *e, int *kind) {
    int sp = 0; while (s < e && *s == ' ' && sp < 3) { s++; sp++; }
    if (e - s < 3 || strncmp(s, "```", 3)) return false;
    s += 3; while (s < e && *s == '`') s++;
    while (s < e && (*s == ' ' || *s == '\t')) s++;
    const char *w = s; while (s < e && *s != ' ' && *s != '\t' && *s != '\r') s++;
    int n = (int)(s - w);
    if (n == 0 || (n == 9 && !strncasecmp(w, "smalltalk", 9)) || (n == 2 && !strncasecmp(w, "st", 2))) *kind = NB_CODE;
    else if (n == 6 && !strncasecmp(w, "result", 6)) *kind = NB_RESULT;
    else *kind = NB_OTHER;
    return true;
}
static bool nb_bare_fence(const char *s, const char *e) {   /* a closing fence: ``` and nothing after it */
    int k; if (!nb_fence(s, e, &k)) return false;
    while (s < e && *s == ' ') s++; while (s < e && *s == '`') s++;
    while (s < e && (*s == ' ' || *s == '\t' || *s == '\r')) s++;
    return s == e;
}
/* the fenced cells of the text, up to (and including) the one that contains pos; pass len to get them all */
static Cell *nb_cells(const char *t, int len, int upto, int *count) {
    int n = 0, cap = 16; Cell *cs = malloc(cap * sizeof *cs);
    int pos = 0; bool in = false;
    while (pos < len) {
        const char *nl = memchr(t + pos, '\n', len - pos);
        int eol = nl ? (int)(nl - t) : len, next = nl ? eol + 1 : len;
        int kind;
        if (!in) {
            if (pos > upto) break;
            if (nb_fence(t + pos, t + eol, &kind)) {
                if (n == cap) cs = realloc(cs, (cap *= 2) * sizeof *cs);
                cs[n++] = (Cell){ pos, next, len, len, kind, false }; in = true;
            }
        } else {
            if (nb_bare_fence(t + pos, t + eol)) {
                cs[n - 1].body_end = pos; cs[n - 1].end = next; cs[n - 1].closed = true; in = false;
            }
        }
        pos = next;
    }
    *count = n; return cs;
}
/* the cell that the cursor is in (on its fence lines counts), or -1 */
static int nb_cell_at(Cell *cs, int n, int pos, int len) {
    for (int i = 0; i < n; i++) if (pos >= cs[i].open && (pos < cs[i].end || (pos == len && cs[i].end == len))) return i;
    return -1;
}
static void nb_line_style(Pane *p, int pos, int *fg, int *bg) {
    int n; Cell *cs = nb_cells(p->text, p->len, pos, &n);
    int i = nb_cell_at(cs, n, pos, p->len);
    if (i >= 0) {
        Cell c = cs[i]; bool fence = pos == c.open || (c.closed && pos >= c.body_end);
        if (c.kind == NB_RESULT) *fg = fence ? NB_FENCE_FG : NB_RESULT_FG;
        else { *bg = NB_CODE_BG; if (fence) *fg = NB_FENCE_FG; }
    }
    free(cs);
}
static char *nb_copy(Pane *p, int a, int b) { char *s = malloc(b - a + 1); memcpy(s, p->text + a, b - a); s[b - a] = 0; return s; }

/* the code cell under the cursor when nothing is selected: its index among all cells, or -1 */
static int nb_current_cell(Pane *p, Cell **cs, int *n) {
    *cs = nb_cells(p->text, p->len, p->len, n);
    if (p->anchor >= 0 && p->anchor != p->cursor) return -1;
    int i = nb_cell_at(*cs, *n, p->cursor, p->len);
    return i >= 0 && (*cs)[i].kind == NB_CODE ? i : -1;
}
/* write a cell's value into the result block under it (replacing the one already there) */
static void nb_put_result(Pane *p, Cell *cs, int n, int i, const char *value) {
    Cell c = cs[i]; int to = c.end;
    if (c.closed && i + 1 < n && cs[i + 1].kind == NB_RESULT && cs[i + 1].open == c.end) to = cs[i + 1].end;
    size_t vl = strlen(value); char *ins = malloc(vl + 32); ins[0] = 0;
    if (c.end > 0 && p->text[c.end - 1] != '\n') strcat(ins, "\n");
    if (!c.closed) strcat(ins, "```\n");
    strcat(ins, "```result\n"); strcat(ins, value);
    if (vl == 0 || value[vl - 1] != '\n') strcat(ins, "\n");
    strcat(ins, "```");
    if (to < p->len || (to > 0 && p->text[to - 1] == '\n')) strcat(ins, "\n");
    int cur = p->cursor, line = p->tline;
    text_select_range(p, c.end, to); text_insert(p, ins); free(ins);
    p->cursor = cur; p->anchor = -1; p->tline = line; text_show_cursor(p);
}
/* run cell i; print: also show its value under it. False if it failed (the error is shown). */
static bool nb_run_cell(Pane *p, Cell *cs, int n, int i, bool print, oop *result) {
    char *src = nb_copy(p, cs[i].body, cs[i].body_end); bool ok;
    oop r = evaluate(src, nilobj, &ok); free(src);
    if (!ok) { p->cursor = cs[i].body; p->anchor = -1; text_show_cursor(p); return false; }
    if (result) *result = r;
    if (print) { char *s = str_cstr(interp_print_string(r)); nb_put_result(p, cs, n, i, s); free(s); }
    return true;
}
static void nb_do(Pane *p, int what) {   /* 0 do it, 1 print it, 2 inspect it: the cell under the cursor, else as a workspace does */
    Cell *cs; int n; int i = nb_current_cell(p, &cs, &n);
    if (i < 0) { free(cs); if (what == 0) do_it(p); else if (what == 1) print_it(p); else inspect_it(p); return; }
    oop r = nilobj;
    if (nb_run_cell(p, cs, n, i, what == 1, &r)) { if (what == 2) open_inspector(r); else ui_status("done"); }
    free(cs); tools_after_eval();
}
static void nb_run_all(Pane *p) {
    int ran = 0;
    for (int k = 0;; k++) {   /* the cells are found again after each run, since printing a value moves the ones below */
        int n, i, seen = -1; Cell *cs = nb_cells(p->text, p->len, p->len, &n);
        for (i = 0; i < n; i++) if (cs[i].kind == NB_CODE && ++seen == k) break;
        if (i == n) { free(cs); break; }
        bool ok = nb_run_cell(p, cs, n, i, true, NULL); free(cs); tools_after_eval();
        if (!ok) { ui_status("stopped at cell %d: it failed", k + 1); return; }
        ran++;
    }
    ui_status("ran %d cell%s", ran, ran == 1 ? "" : "s");
}
static void nb_clear_results(Pane *p) {
    int n, removed = 0; Cell *cs = nb_cells(p->text, p->len, p->len, &n);
    int cur = p->cursor;
    for (int i = n - 1; i >= 0; i--) if (cs[i].kind == NB_RESULT) {
        text_select_range(p, cs[i].open, cs[i].end); text_insert(p, ""); removed++;
        if (cur >= cs[i].end) cur -= cs[i].end - cs[i].open; else if (cur > cs[i].open) cur = cs[i].open;
    }
    free(cs); p->cursor = cur; p->anchor = -1; text_show_cursor(p);
    ui_status("removed %d result%s", removed, removed == 1 ? "" : "s");
}
static char *nb_read_file(const char *path) {
    FILE *f = fopen(path, "rb"); if (!f) return NULL;
    size_t cap = 4096, len = 0; char *s = malloc(cap); size_t k;
    while ((k = fread(s + len, 1, cap - len - 1, f)) > 0) { len += k; if (cap - len < 2) s = realloc(s, cap *= 2); }
    fclose(f); s[len] = 0; return s;
}
static const char *nb_base(const char *path) { const char *b = strrchr(path, '/'); return b ? b + 1 : path; }
static void nb_title(Window *w) {
    Notebook *nb = w->user; char t[128];
    snprintf(t, sizeof t, "Notebook: %s%s", nb_base(nb->path), w->panes[0]->dirty ? " *" : "");
    if (strcmp(t, w->title)) win_set_title(w, t);
}
static bool nb_save(Window *w) {
    Notebook *nb = w->user; Pane *p = w->panes[0];
    FILE *f = fopen(nb->path, "wb");
    bool ok = f && fwrite(p->text, 1, p->len, f) == (size_t)p->len;
    if (f && fclose(f) != 0) ok = false;
    if (!ok) { char msg[1400]; snprintf(msg, sizeof msg, "Cannot write the notebook to\n  %s", nb->path); ui_status("could not save %s", nb->path); dialog_text("Notebook not saved", msg); return false; }
    p->dirty = false; nb_title(w); ui_status("saved %s", nb->path); return true;
}
static void nb_save_as(Window *w) {
    Notebook *nb = w->user; char *f = dialog_prompt("Save notebook as", nb->path);
    if (f && f[0]) { char *old = nb->path; nb->path = f; if (nb_save(w)) free(old); else { nb->path = old; free(f); } }
    else free(f);
}
static void nb_revert(Window *w) {
    Notebook *nb = w->user; Pane *p = w->panes[0];
    if (p->dirty && !dialog_confirm("Revert", "Throw away the changes made since the notebook was last saved?")) return;
    char *s = nb_read_file(nb->path);
    if (!s) { ui_status("cannot read %s", nb->path); return; }
    text_set(p, s); free(s); nb_title(w); ui_status("read %s again", nb->path);
}
static bool nb_may_close(Window *w) {
    Notebook *nb = w->user; if (!w->panes[0]->dirty) return true;
    char *items[] = { "save, then close", "close without saving", "do not close" };
    char prompt[300]; snprintf(prompt, sizeof prompt, "%s has changes that are not saved", nb_base(nb->path));
    int c = dialog_choose("Close notebook", prompt, items, 3);
    return c == 0 ? nb_save(w) : c == 1;
}
static void nb_close(Window *w) { Notebook *nb = w->user; free(nb->path); free(nb); }
static const char *nb_menu[] = { "do it", "print it", "inspect it", "run all cells", "clear results", "-", "save", "save as...", "revert", "-", "copy", "cut", "paste", "select all" };
static void nb_menu_cb(Pane *p, int i) {
    switch (i) { case 0: case 1: case 2: nb_do(p, i); break; case 3: nb_run_all(p); break; case 4: nb_clear_results(p); break;
    case 6: nb_save(p->win); break; case 7: nb_save_as(p->win); break; case 8: nb_revert(p->win); break;
    case 10: text_copy(p); break; case 11: text_cut(p); break; case 12: text_paste(p); break; case 13: text_select_all(p); break; }
}
static bool nb_key(Pane *p, Event *ev) {
    if (!(ev->mods & MOD_CTRL)) return false;
    switch (ev->key) { case 'd': nb_do(p, 0); return true; case 'p': nb_do(p, 1); return true; case 't': nb_do(p, 2); return true;
    case 'r': nb_run_all(p); return true; case 's': nb_save(p->win); return true; }
    return false;
}
static const char *nb_new_text =
    "# Notes\n\n"
    "A notebook is a text file of prose with Smalltalk in it. The code goes between\n"
    "fence lines of three backquotes, as in Markdown:\n\n"
    "```smalltalk\n"
    "squares := (1 to: 10) collect: [:i | i * i].\n"
    "squares inject: 0 into: [:a :b | a + b]\n"
    "```\n\n"
    "Put the cursor anywhere in a cell and print it (ctrl-P) to run the whole cell:\n"
    "its value appears in a result block under it, replaced each time the cell runs.\n"
    "ctrl-D runs it without showing the value, ctrl-R runs every cell from the top,\n"
    "and ctrl-S saves the file. Select some text to run just that, as in a workspace.\n"
    "A variable assigned without being declared is kept from one cell to the next:\n\n"
    "```smalltalk\n"
    "squares last\n"
    "```\n";
int tools_unsaved_notebooks(void) {
    int n = 0; for (int i = 0; i < nwindows; i++) if (windows[i]->kind == W_NOTEBOOK && windows[i]->panes[0]->dirty) n++;
    return n;
}
static void notebooks_refresh(void) { for (int i = 0; i < nwindows; i++) if (windows[i]->kind == W_NOTEBOOK) nb_title(windows[i]); }
void open_notebook(const char *path) {
    for (int i = 0; i < nwindows; i++)   /* already open: bring it forward */
        if (windows[i]->kind == W_NOTEBOOK && !strcmp(((Notebook *)windows[i]->user)->path, path)) { win_raise(windows[i]); return; }
    char *s = nb_read_file(path); bool fresh = !s;
    int ww = tui_cols - 4 < 90 ? tui_cols - 4 : 90, wh = tui_rows - 4;
    Window *w = win_new("Notebook", (tui_cols - ww) / 2 + cascade, 1 + cascade, ww, wh); cascade = (cascade + 1) % 5;
    w->kind = W_NOTEBOOK; w->layout = single_layout; w->on_close = nb_close; w->may_close = nb_may_close;
    Notebook *nb = calloc(1, sizeof *nb); nb->path = strdup(path); w->user = nb;
    Pane *t = win_add_text(w, false); t->menu = nb_menu; t->nmenu = 14; t->on_menu = nb_menu_cb; t->on_key = nb_key; t->line_style = nb_line_style;
    text_set(t, fresh ? nb_new_text : s); free(s);
    if (fresh) t->dirty = true;   /* not on disk until it is saved */
    nb_title(w); win_focus(w, t);
    ui_status(fresh ? "new notebook %s (not saved yet: ctrl-S saves it)" : "opened %s", path);
}

/* ---------- Transcript ---------- */
static const char *tr_menu[] = { "clear", "copy", "select all" };
static void tr_menu_cb(Pane *p, int i) { if (i == 0) { transcript_len = 0; if (transcript_text) transcript_text[0] = 0; text_set(p, ""); } else if (i == 1) text_copy(p); else text_select_all(p); }
void open_transcript(void) {
    int h = tui_rows / 3; Window *w = win_new("System Transcript", tui_cols - tui_cols * 2 / 5 - 2, 1, tui_cols * 2 / 5, h);
    w->kind = W_TRANSCRIPT; w->layout = single_layout;
    Pane *t = win_add_text(w, true); t->menu = tr_menu; t->nmenu = 3; t->on_menu = tr_menu_cb;
    text_set(t, transcript_text ? transcript_text : ""); text_scroll_to_end(t);
}
static void transcripts_refresh(void) {
    for (int i = 0; i < nwindows; i++) if (windows[i]->kind == W_TRANSCRIPT) {
        Pane *t = windows[i]->panes[0];
        if ((size_t)t->len != transcript_len || (transcript_text && memcmp(t->text, transcript_text, transcript_len))) { text_set(t, transcript_text ? transcript_text : ""); text_scroll_to_end(t); }
    }
}

/* ---------- lesson window (opened by Smalltalk code through primitive 180, e.g. the Tutorial) ---------- */
static void show_lesson_window(const char *title, const char *text) {
    Window *w = NULL;
    for (int i = 0; i < nwindows; i++) if (windows[i]->kind == W_LESSON) w = windows[i];
    if (!w) {
        int ww = tui_cols - 2 < 84 ? tui_cols - 2 : 84, wh = tui_rows - 3;   /* lesson lines are at most 80 columns */
        w = win_new(title, (tui_cols - ww) / 2, 1, ww, wh); w->kind = W_LESSON; w->layout = single_layout;
        Pane *t = win_add_text(w, false); t->menu = ws_menu; t->nmenu = 8; t->on_menu = ws_menu_cb; t->on_key = code_key;
    }
    win_set_title(w, title); text_set(w->panes[0], text); win_raise(w); w->focus = w->panes[0];
}
/* Copy an Array of Strings out into C strings. The copy has to happen before the next message is sent:
   an oop held only in a C local is not a root, so a collection during that send would free it. */
static int strings_from_array(oop a, char **out, int max) {
    if (interp.failed || !a || IS_INT(a) || a->cls != classArray) { interp.failed = false; return 0; }
    int n = (int)a->size; if (n > max) n = max;
    for (int i = 0; i < n; i++) out[i] = oop_str(SLOT(a, i));
    return n;
}

/* The tutorials: the one for the language, and one from every loaded package that ships one. They are
   read in from disk the first time they are asked for, so an image that never opens one carries none.
   With only one there is nothing to choose, so it just opens. */
static void open_tutorial(void) {
    char *raw[64], *items[64];
    int n = strings_from_array(interp_send(smalltalk, new_symbol("tutorialNames"), NULL, 0), raw, 64);
    if (n == 0) { ui_status("there are no tutorials to open"); return; }
    int m = strings_from_array(interp_send(smalltalk, new_symbol("tutorialListing"), NULL, 0), items, 64);
    if (m != n) { for (int k = 0; k < m; k++) free(items[k]); for (int k = 0; k < n; k++) items[k] = strdup(raw[k]); }
    int pick = n == 1 ? 0 : dialog_choose("Tutorials", "every tutorial this image can open", items, n);
    for (int k = 0; k < n; k++) free(items[k]);
    if (pick >= 0) {
        oop arg = new_string(raw[pick]);
        bool saved = changes_logging; changes_logging = false;   /* a tutorial is part of the system, not the user's changes */
        interp_send(smalltalk, new_symbol("startTutorial:"), &arg, 1);
        changes_logging = saved;
        if (interp.failed) show_error();
        browsers_refresh(); tools_after_eval();
    }
    for (int k = 0; k < n; k++) free(raw[k]);
}

/* ---------- Inspector ---------- */
typedef struct { oop obj; Pane *fields, *value, *code; EvalCtx ctx; } Inspector;
static void insp_layout(Window *w) {
    Inspector *in = w->user; int lw = w->r.w / 3; int ih = w->r.h - 2; int vh = ih * 2 / 3;
    in->fields->r = (Rect){ w->r.x + 1, w->r.y + 1, lw, ih };
    in->value->r = (Rect){ w->r.x + 1 + lw + 1, w->r.y + 1, w->r.w - lw - 3, vh };
    in->code->r = (Rect){ w->r.x + 1 + lw + 1, w->r.y + 1 + vh + 1, w->r.w - lw - 3, ih - vh - 1 };
    for (int y = 0; y < ih; y++) tui_put(w->r.x + 1 + lw, w->r.y + 1 + y, 0x2502, C_FRAME, C_WIN_BG, 0);
    for (int x = lw + 1; x < w->r.w - 1; x++) tui_put(w->r.x + 1 + x, w->r.y + 1 + vh, 0x2500, C_FRAME, C_WIN_BG, 0);
}
static oop insp_field_value(Inspector *in, int i) {
    oop o = in->obj; if (i == 0) return o;
    if (IS_INT(o)) return nilobj;
    int fixed = o->kind == KIND_BYTES ? 0 : FMT_SIZE(SLOT(o->cls, C_FORMAT));
    if (i <= fixed) return SLOT(o, i - 1);
    int k = i - fixed - 1;
    if (o->kind == KIND_BYTES) return k < (int)o->size ? ((o->cls == classString || o->cls == classSymbol) ? charTable[BYTES(o)[k]] : MK_INT(BYTES(o)[k])) : nilobj;
    return (fixed + k) < (int)o->size ? SLOT(o, fixed + k) : nilobj;
}
static void insp_select(Pane *p) {
    Inspector *in = p->win->user; if (p->sel < 0) return;
    char *s = str_cstr(interp_print_string(insp_field_value(in, p->sel))); text_set(in->value, s); free(s);
}
static void insp_fill(Inspector *in) {
    StrList l = { 0 }; char buf[64];
    l.v = malloc(sizeof(char *) * 4); l.cap = 4; l.v[l.n++] = strdup("self");
    oop o = in->obj;
    if (!IS_INT(o)) {
        oop names = o->kind == KIND_BYTES ? new_array(0) : class_ivar_names(o->cls);
        for (uint32_t i = 0; i < names->size; i++) { if (l.n == l.cap) { l.cap *= 2; l.v = realloc(l.v, l.cap * sizeof(char *)); } l.v[l.n++] = str_cstr(SLOT(names, i)); }
        int fixed = o->kind == KIND_BYTES ? 0 : FMT_SIZE(SLOT(o->cls, C_FORMAT)); int n = (int)o->size - fixed; if (o->kind == KIND_BYTES) n = o->size;
        if (n > 200) n = 200;
        for (int i = 1; i <= n; i++) { snprintf(buf, sizeof buf, "%d", i); if (l.n == l.cap) { l.cap *= 2; l.v = realloc(l.v, l.cap * sizeof(char *)); } l.v[l.n++] = strdup(buf); }
    }
    list_set_items(in->fields, l.v, l.n);
}
static const char *insp_menu[] = { "inspect", "update" };
static void insp_menu_cb(Pane *p, int i) { Inspector *in = p->win->user; if (i == 0 && p->sel >= 0) open_inspector(insp_field_value(in, p->sel)); else if (i == 1) insp_fill(in); }
static void insp_close(Window *w) { Inspector *in = w->user; gc_remove_root(&in->obj); gc_remove_root(&in->ctx.receiver); free(in); }
void open_inspector(oop obj) {
    Inspector *in = calloc(1, sizeof(Inspector)); in->obj = obj; in->ctx.receiver = obj; gc_add_root(&in->obj); gc_add_root(&in->ctx.receiver);
    char *cn = str_cstr(class_name_of(CLASS_OF(obj))); char title[160]; snprintf(title, sizeof title, "Inspector: %s", cn);
    int w = tui_cols / 2, h = tui_rows / 2;
    Window *win = win_new(title, tui_cols / 4 + cascade * 2, tui_rows / 4 + cascade, w, h); cascade = (cascade + 1) % 5;
    win->kind = W_INSPECTOR; win->user = in; win->layout = insp_layout; win->on_close = insp_close;
    in->fields = win_add_list(win, insp_select); in->fields->menu = insp_menu; in->fields->nmenu = 2; in->fields->on_menu = insp_menu_cb;
    in->value = win_add_text(win, true); in->value->menu = ws_menu; in->value->nmenu = 8; in->value->on_menu = ws_menu_cb; in->value->user = &in->ctx; in->value->on_key = code_key;
    in->code = win_add_text(win, false); in->code->menu = ws_menu; in->code->nmenu = 8; in->code->on_menu = ws_menu_cb; in->code->user = &in->ctx; in->code->on_key = code_key;
    text_set(in->code, "\"evaluate expressions here with self bound to the inspected object\"\n");
    insp_fill(in); list_select(in->fields, 0, true); free(cn);
}

/* ---------- System Browser ---------- */
typedef struct {
    Pane *cats, *classes, *protos, *sels, *code, *side; bool meta;
    char cat[128], cls[128], proto[128], sel[256]; int mode;   /* 0 class template, 1 class definition, 2 method, 3 comment */
} Browser;
#define ALL_PROTO "-- all --"

static oop browser_class(Browser *b) { oop c = class_named(b->cls); if (!c) return NULL; return b->meta ? c->cls : c; }
static void br_layout(Window *w) {
    Browser *b = w->user; int iw = w->r.w - 2, ih = w->r.h - 2; int lh = ih * 2 / 5; if (lh < 4) lh = 4; if (lh > ih - 3) lh = ih - 3;
    int cw = iw / 4; int x = w->r.x + 1, y = w->r.y + 1;
    b->cats->r = (Rect){ x, y, cw - 1, lh };
    b->classes->r = (Rect){ x + cw, y, cw - 1, lh - 1 };
    b->side->r = (Rect){ x + cw, y + lh - 1, cw - 1, 1 };
    b->protos->r = (Rect){ x + 2 * cw, y, cw - 1, lh };
    b->sels->r = (Rect){ x + 3 * cw, y, iw - 3 * cw, lh };
    b->code->r = (Rect){ x, y + lh + 1, iw, ih - lh - 1 };
    for (int k = 1; k < 4; k++) for (int j = 0; j < lh; j++) tui_put(x + k * cw - 1, y + j, 0x2502, C_FRAME, C_WIN_BG, 0);
    for (int i = 0; i < iw; i++) tui_put(x + i, y + lh, 0x2500, C_FRAME, C_WIN_BG, 0);
}
static void br_fill_cats(Browser *b) {
    StrList l = { 0 }; oop keys = dict_keys(smalltalk);
    for (uint32_t i = 0; i < keys->size; i++) { oop c = dict_at(smalltalk, SLOT(keys, i)); if (is_class(c) && c->cls != classMetaclass) { char *s = oop_str(SLOT(c, C_CATEGORY)); sl_add(&l, s[0] ? s : "Unclassified"); free(s); } }
    sl_sort(&l); list_set_items(b->cats, l.v, l.n);
}
static void br_fill_classes(Browser *b) {
    StrList l = { 0 }; oop keys = dict_keys(smalltalk);
    for (uint32_t i = 0; i < keys->size; i++) {
        oop c = dict_at(smalltalk, SLOT(keys, i)); if (!is_class(c)) continue;
        char *s = oop_str(SLOT(c, C_CATEGORY)); if (!strcmp(s[0] ? s : "Unclassified", b->cat)) { char *n = oop_str(SLOT(c, C_NAME)); sl_add(&l, n); free(n); } free(s);
    }
    sl_sort(&l); list_set_items(b->classes, l.v, l.n);
}
static void br_fill_protos(Browser *b) {
    StrList l = { 0 }; oop c = browser_class(b);
    if (c) {
        oop sels = dict_keys(SLOT(c, C_METHODS));
        for (uint32_t i = 0; i < sels->size; i++) { oop m = dict_at(SLOT(c, C_METHODS), SLOT(sels, i)); char *s = oop_str(SLOT(m, M_CATEGORY)); sl_add(&l, s[0] ? s : "as yet unclassified"); free(s); }
        sl_sort(&l);
        if (l.n) { if (l.n == l.cap) { l.cap++; l.v = realloc(l.v, l.cap * sizeof(char *)); } memmove(l.v + 1, l.v, l.n * sizeof(char *)); l.v[0] = strdup(ALL_PROTO); l.n++; }
    }
    list_set_items(b->protos, l.v, l.n);
}
static void br_fill_sels(Browser *b) {
    StrList l = { 0 }; oop c = browser_class(b);
    if (c && b->proto[0]) {
        oop sels = dict_keys(SLOT(c, C_METHODS)); bool all = !strcmp(b->proto, ALL_PROTO);
        for (uint32_t i = 0; i < sels->size; i++) {
            oop m = dict_at(SLOT(c, C_METHODS), SLOT(sels, i)); char *s = oop_str(SLOT(m, M_CATEGORY));
            if (all || !strcmp(s[0] ? s : "as yet unclassified", b->proto)) { char *n = str_cstr(SLOT(sels, i)); sl_add(&l, n); free(n); }
            free(s);
        }
        sl_sort(&l);
    }
    list_set_items(b->sels, l.v, l.n);
}
static void br_show_code(Browser *b) {
    oop c = browser_class(b); char buf[1024];
    if (b->mode == 2 && c && b->sel[0]) {
        oop m = dict_at(SLOT(c, C_METHODS), new_symbol(b->sel));
        if (m) { char *s = oop_str(SLOT(m, M_SOURCE)); text_set(b->code, s); free(s); return; }
    }
    if (b->mode == 3 && c) { char *s = oop_str(SLOT(c->cls == classMetaclass ? SLOT(c, MC_THISCLASS) : c, C_COMMENT)); text_set(b->code, s); free(s); return; }
    if (c && (b->mode == 1 || b->mode == 3)) {
        oop r = interp_send(c->cls == classMetaclass ? SLOT(c, MC_THISCLASS) : c, new_symbol("definition"), NULL, 0);
        char *s = interp.failed ? strdup("") : str_cstr(r); interp.failed = false; text_set(b->code, s); free(s); return;
    }
    if (c && b->mode == 2) {
        snprintf(buf, sizeof buf, "message selector and argument names\n\t\"comment stating purpose of message\"\n\n\t| temporary variable names |\n\tstatements");
        text_set(b->code, buf); return;
    }
    snprintf(buf, sizeof buf, "Object subclass: #NameOfClass\n\tinstanceVariableNames: 'instVarName1 instVarName2'\n\tclassVariableNames: 'ClassVarName1'\n\tcategory: '%s'", b->cat[0] ? b->cat : "Unclassified");
    text_set(b->code, buf);
}
static void br_set_title(Browser *b, Window *w) {
    char t[300]; if (b->cls[0]) snprintf(t, sizeof t, "System Browser: %s%s%s%s", b->cls, b->meta ? " class" : "", b->sel[0] ? ">>" : "", b->sel);
    else snprintf(t, sizeof t, "System Browser"); win_set_title(w, t);
}
static void cat_select(Pane *p) {
    Browser *b = p->win->user; const char *s = list_selected(p); snprintf(b->cat, sizeof b->cat, "%s", s ? s : "");
    b->cls[0] = b->proto[0] = b->sel[0] = 0; b->mode = 0; br_fill_classes(b); br_fill_protos(b); br_fill_sels(b); br_show_code(b); br_set_title(b, p->win);
}
static void class_select(Pane *p) {
    Browser *b = p->win->user; const char *s = list_selected(p); snprintf(b->cls, sizeof b->cls, "%s", s ? s : "");
    b->proto[0] = b->sel[0] = 0; b->mode = 1; br_fill_protos(b); br_fill_sels(b); br_show_code(b); br_set_title(b, p->win);
}
static void proto_select(Pane *p) {
    Browser *b = p->win->user; const char *s = list_selected(p); snprintf(b->proto, sizeof b->proto, "%s", s ? s : "");
    b->sel[0] = 0; b->mode = 2; br_fill_sels(b); br_show_code(b); br_set_title(b, p->win);
}
static void sel_select(Pane *p) {
    Browser *b = p->win->user; const char *s = list_selected(p); snprintf(b->sel, sizeof b->sel, "%s", s ? s : "");
    b->mode = 2; br_show_code(b); br_set_title(b, p->win);
}
static void side_click(Pane *p) {
    Browser *b = p->win->user; b->meta = !b->meta; snprintf(p->label, sizeof p->label, "%s", b->meta ? "[class]" : "[instance]");
    b->proto[0] = b->sel[0] = 0; if (b->cls[0]) b->mode = 1; br_fill_protos(b); br_fill_sels(b); br_show_code(b); br_set_title(b, p->win);
}
static void br_accept(Browser *b, Window *w) {
    char *src = text_get(b->code); oop c = browser_class(b); char err[512];
    if (b->mode == 2 && c) {
        const char *proto = (!b->proto[0] || !strcmp(b->proto, ALL_PROTO)) ? "as yet unclassified" : b->proto;
        oop m = compile_method(c, src, proto, err, sizeof err);
        if (!m) { ui_status("Compile error: %s", err); dialog_text("Compile error", err); free(src); return; }
        dict_at_put(SLOT(c, C_METHODS), SLOT(m, M_SELECTOR), m); extern void interp_flush_cache(void); interp_flush_cache();
        char *sel = str_cstr(SLOT(m, M_SELECTOR)); snprintf(b->sel, sizeof b->sel, "%s", sel); free(sel);
        changes_log_method(c, proto, src); b->code->dirty = false;
        br_fill_protos(b); list_select(b->protos, list_find(b->protos, b->proto[0] ? b->proto : proto), false); if (!b->proto[0]) snprintf(b->proto, sizeof b->proto, "%s", proto);
        br_fill_sels(b); list_select(b->sels, list_find(b->sels, b->sel), false); br_set_title(b, w); ui_status("accepted %s", b->sel);
    } else if (b->mode == 3 && c) {
        oop real = c->cls == classMetaclass ? SLOT(c, MC_THISCLASS) : c; SLOT(real, C_COMMENT) = new_string(src);
        changes_log_comment(real, src);
        b->code->dirty = false; ui_status("comment accepted");
    } else {   /* class definition: evaluating it goes through the class-creation primitive, which logs it */
        bool ok; evaluate(src, nilobj, &ok);
        if (ok) {
            /* find the class name from the source: token after '#' */
            const char *h = strchr(src, '#'); char name[128] = ""; if (h) { int k = 0; h++; while (*h && k < 127 && ((*h >= 'a' && *h <= 'z') || (*h >= 'A' && *h <= 'Z') || (*h >= '0' && *h <= '9') || *h == '_')) name[k++] = *h++; name[k] = 0; }
            oop nc = class_named(name);
            if (nc) { char *cat = oop_str(SLOT(nc, C_CATEGORY)); snprintf(b->cat, sizeof b->cat, "%s", cat[0] ? cat : "Unclassified"); free(cat); snprintf(b->cls, sizeof b->cls, "%s", name); }
            b->code->dirty = false; browsers_refresh(); b->mode = 1; br_show_code(b); br_set_title(b, w); ui_status("class %s defined", name);
        }
    }
    free(src);
}
static void br_cancel(Browser *b) { br_show_code(b); }
static const char *code_menu[] = { "do it", "print it", "inspect it", "-", "accept", "cancel", "-", "copy", "cut", "paste", "select all" };
static void code_menu_cb(Pane *p, int i) {
    Browser *b = p->win->user;
    switch (i) { case 0: do_it(p); break; case 1: print_it(p); break; case 2: inspect_it(p); break; case 4: br_accept(b, p->win); break; case 5: br_cancel(b); break;
    case 7: text_copy(p); break; case 8: text_cut(p); break; case 9: text_paste(p); break; case 10: text_select_all(p); break; }
}
static bool br_code_key(Pane *p, Event *ev) {
    if ((ev->mods & MOD_CTRL) && ev->key == 's') { br_accept(p->win->user, p->win); return true; }
    if ((ev->mods & MOD_CTRL) && ev->key == 'l') { br_cancel(p->win->user); return true; }
    return code_key(p, ev);
}
static void browsers_refresh(void) {
    for (int i = 0; i < nwindows; i++) if (windows[i]->kind == W_BROWSER) {
        Browser *b = windows[i]->user;
        br_fill_cats(b); list_select(b->cats, list_find(b->cats, b->cat), false);
        br_fill_classes(b); list_select(b->classes, list_find(b->classes, b->cls), false);
        br_fill_protos(b); list_select(b->protos, list_find(b->protos, b->proto), false);
        br_fill_sels(b); list_select(b->sels, list_find(b->sels, b->sel), false);
    }
}
/* senders / implementors */
static bool method_sends(oop m, oop sym) {
    oop lits = SLOT(m, M_LITERALS);
    for (uint32_t i = 0; i < lits->size; i++) { oop l = SLOT(lits, i); if (l == sym) return true; if (!IS_INT(l) && l->cls == classCompiledMethod && method_sends(l, sym)) return true; }
    return false;
}
static void find_methods(const char *selector, bool senders) {
    StrList l = { 0 }; oop sym = new_symbol(selector); oop keys = dict_keys(smalltalk);
    for (uint32_t i = 0; i < keys->size; i++) {
        oop c = dict_at(smalltalk, SLOT(keys, i)); if (!is_class(c)) continue;
        for (int side = 0; side < 2; side++) {
            oop cc = side ? c->cls : c; oop sels = dict_keys(SLOT(cc, C_METHODS));
            for (uint32_t k = 0; k < sels->size; k++) {
                oop m = dict_at(SLOT(cc, C_METHODS), SLOT(sels, k));
                if (senders ? method_sends(m, sym) : SLOT(sels, k) == sym) { char *cn = str_cstr(class_name_of(cc)); char *sn = str_cstr(SLOT(sels, k)); char buf[512]; snprintf(buf, sizeof buf, "%s>>%s", cn, sn); sl_add(&l, buf); free(cn); free(sn); }
            }
        }
    }
    sl_sort(&l); size_t total = 1; for (int i = 0; i < l.n; i++) total += strlen(l.v[i]) + 1;
    char *txt = malloc(total + 32); txt[0] = 0; for (int i = 0; i < l.n; i++) { strcat(txt, l.v[i]); strcat(txt, "\n"); free(l.v[i]); } free(l.v);
    if (!txt[0]) strcpy(txt, "(none)");
    char title[300]; snprintf(title, sizeof title, "%s of %s", senders ? "Senders" : "Implementors", selector); dialog_text(title, txt); free(txt);
}
static const char *cat_menu[] = { "add category", "file out category", "update" };
static void cat_menu_cb(Pane *p, int i) {
    Browser *b = p->win->user;
    if (i == 0) { char *n = dialog_prompt("New class category", ""); if (n && n[0]) { snprintf(b->cat, sizeof b->cat, "%s", n); b->cls[0] = b->proto[0] = b->sel[0] = 0; b->mode = 0; br_fill_classes(b); br_fill_protos(b); br_fill_sels(b); br_show_code(b); } free(n); }
    else if (i == 1 && b->cat[0]) {
        char fname[256]; snprintf(fname, sizeof fname, "%s.st", b->cat); for (char *q = fname; *q; q++) if (*q == ' ' || *q == '/') *q = '_';
        FILE *f = fopen(fname, "wb"); if (!f) { ui_status("cannot write %s", fname); return; }
        for (int k = 0; k < b->classes->nitems; k++) { oop c = class_named(b->classes->items[k]); if (c) { char *t = file_out_class(c); fputs(t, f); free(t); } }
        fclose(f); ui_status("filed out category to %s", fname);
    } else browsers_refresh();
}
static const char *class_menu[] = { "definition", "comment", "-", "file out", "remove class" };
static void class_menu_cb(Pane *p, int i) {
    Browser *b = p->win->user; oop c = class_named(b->cls); if (!c) return;
    if (i == 0) { b->mode = 1; b->sel[0] = 0; br_show_code(b); }
    else if (i == 1) { b->mode = 3; b->sel[0] = 0; br_show_code(b); }
    else if (i == 3) { char fname[256]; snprintf(fname, sizeof fname, "%s.st", b->cls); FILE *f = fopen(fname, "wb"); if (f) { char *t = file_out_class(c); fputs(t, f); free(t); fclose(f); ui_status("filed out to %s", fname); } else ui_status("cannot write %s", fname); }
    else if (i == 4) { char msg[200]; snprintf(msg, sizeof msg, "Remove class %s from the system?", b->cls);
        if (dialog_confirm("Remove class", msg)) { dict_remove(smalltalk, new_symbol(b->cls)); if (changes_logging) { char buf[256]; snprintf(buf, sizeof buf, "Smalltalk removeKey: #%s!\n", b->cls); changes_log(buf); } b->cls[0] = b->proto[0] = b->sel[0] = 0; b->mode = 0; browsers_refresh(); br_show_code(b); br_set_title(b, p->win); } }
}
static const char *proto_menu[] = { "add protocol", "remove protocol" };
static void proto_menu_cb(Pane *p, int i) {
    Browser *b = p->win->user; if (!b->cls[0]) return;
    if (i == 0) { char *n = dialog_prompt("New message protocol", ""); if (n && n[0]) { snprintf(b->proto, sizeof b->proto, "%s", n); b->sel[0] = 0; b->mode = 2; br_fill_sels(b); br_show_code(b); } free(n); }
    else if (b->proto[0] && strcmp(b->proto, ALL_PROTO)) { if (b->sels->nitems) ui_status("protocol is not empty"); else { b->proto[0] = 0; br_fill_protos(b); br_fill_sels(b); } }
}
static const char *sel_menu[] = { "senders", "implementors", "-", "remove method" };
static void sel_menu_cb(Pane *p, int i) {
    Browser *b = p->win->user; if (!b->sel[0]) return;
    if (i == 0) find_methods(b->sel, true); else if (i == 1) find_methods(b->sel, false);
    else if (i == 3) { char msg[300]; snprintf(msg, sizeof msg, "Remove %s>>%s?", b->cls, b->sel);
        if (dialog_confirm("Remove method", msg)) { oop c = browser_class(b); if (c) { dict_remove(SLOT(c, C_METHODS), new_symbol(b->sel)); extern void interp_flush_cache(void); interp_flush_cache();
            changes_log_remove_method(c, new_symbol(b->sel)); }
            b->sel[0] = 0; br_fill_protos(b); br_fill_sels(b); br_show_code(b); br_set_title(b, p->win); } }
}
static void br_close(Window *w) { free(w->user); }
void open_browser(void) { open_browser_on(NULL); }
void open_browser_on(const char *className) {
    Browser *b = calloc(1, sizeof(Browser));
    Window *w = win_new("System Browser", 1 + cascade * 2, 2 + cascade, tui_cols - 4, tui_rows * 2 / 3); cascade = (cascade + 1) % 5;
    w->kind = W_BROWSER; w->user = b; w->layout = br_layout; w->on_close = br_close;
    b->cats = win_add_list(w, cat_select); b->cats->menu = cat_menu; b->cats->nmenu = 3; b->cats->on_menu = cat_menu_cb;
    b->classes = win_add_list(w, class_select); b->classes->menu = class_menu; b->classes->nmenu = 5; b->classes->on_menu = class_menu_cb;
    b->side = win_add_button(w, "[instance]", side_click);
    b->protos = win_add_list(w, proto_select); b->protos->menu = proto_menu; b->protos->nmenu = 2; b->protos->on_menu = proto_menu_cb;
    b->sels = win_add_list(w, sel_select); b->sels->menu = sel_menu; b->sels->nmenu = 4; b->sels->on_menu = sel_menu_cb;
    b->code = win_add_text(w, false); b->code->menu = code_menu; b->code->nmenu = 11; b->code->on_menu = code_menu_cb; b->code->on_key = br_code_key;
    br_fill_cats(b);
    if (className) { oop c = class_named(className); if (c) { char *cat = oop_str(SLOT(c, C_CATEGORY)); list_select(b->cats, list_find(b->cats, cat[0] ? cat : "Unclassified"), true); free(cat); list_select(b->classes, list_find(b->classes, className), true); } }
    else br_show_code(b);
    w->focus = b->cats;
}

/* ---------- system menu ---------- */
/* ---------- list tool: a two-pane browser a package drives from Smalltalk (primitive 203) ----------
   The class answers:  listItems (Array of Strings), detailAt: index (String), commandLabels (Array of Strings),
   command: labelIndex at: itemIndex (does the work; a String answer replaces the detail pane). */
#define LT_MAXCMD 24
typedef struct {
    char cls[128]; Pane *list, *text;
    const char *menu[LT_MAXCMD + 1]; int nmenu; char *labels[LT_MAXCMD];
} ListTool;

static void lt_layout(Window *w) {
    ListTool *lt = w->user; int lw = w->r.w / 3; if (lw < 12) lw = 12; if (lw > w->r.w - 10) lw = w->r.w - 10;
    lt->list->r = (Rect){ w->r.x + 1, w->r.y + 1, lw, w->r.h - 2 };
    lt->text->r = (Rect){ w->r.x + 1 + lw + 1, w->r.y + 1, w->r.w - lw - 3, w->r.h - 2 };
    for (int y = 0; y < w->r.h - 2; y++) tui_put(w->r.x + 1 + lw, w->r.y + 1 + y, 0x2502, C_FRAME, C_WIN_BG, 0);
}
static void lt_close(Window *w) { ListTool *lt = w->user; for (int i = 0; i < lt->nmenu; i++) free(lt->labels[i]); free(lt); }
/* send a message to the tool's class; answers NULL (and reports) when it fails */
static oop lt_send(ListTool *lt, const char *sel, oop *args, int nargs) {
    oop cls = class_named(lt->cls);
    if (!cls) { ui_status("no class named %s", lt->cls); return NULL; }
    oop r = interp_send(cls, new_symbol(sel), args, nargs);
    if (interp.failed) { show_error(); return NULL; }
    return r;
}
static void lt_show_detail(Window *w) {
    ListTool *lt = w->user;
    int sel = lt->list->sel;
    oop arg = MK_INT(sel + 1);
    oop r = lt_send(lt, "detailAt:", &arg, 1);
    if (!r) return;
    char *s = oop_str(r); text_set(lt->text, s); free(s);
}
static void lt_fill(Window *w) {
    ListTool *lt = w->user;
    int keep = lt->list->sel;
    oop items = lt_send(lt, "listItems", NULL, 0);
    if (!items || IS_INT(items) || items->cls != classArray) return;
    StrList l = { 0 };
    for (uint32_t i = 0; i < items->size; i++) { char *s = oop_str(SLOT(items, i)); sl_add(&l, s); free(s); }
    list_set_items(lt->list, l.v, l.n);
    if (keep >= (int)items->size) keep = (int)items->size - 1;
    if (keep < 0 && items->size) keep = 0;
    if (keep >= 0) list_select(lt->list, keep, false);
    lt_show_detail(w);
}
static const char *lt_text_menu[] = { "copy", "select all" };
static void lt_text_menu_cb(Pane *p, int i) { if (i == 0) text_copy(p); else text_select_all(p); }
static Window *lt_window_of(Pane *p) { return p->win; }
static void lt_select(Pane *p) { lt_show_detail(lt_window_of(p)); }
static void lt_menu_cb(Pane *p, int i) {
    Window *w = lt_window_of(p); ListTool *lt = w->user;
    oop args[2] = { MK_INT(i + 1), MK_INT(p->sel + 1) };
    oop r = lt_send(lt, "command:at:", args, 2);
    if (!r) return;
    lt_fill(w);
    if (!IS_INT(r) && r->kind == KIND_BYTES) { char *s = oop_str(r); text_set(lt->text, s); free(s); }
    tools_after_eval();
}
static void open_list_tool(const char *clsName, const char *title) {
    ListTool *lt = calloc(1, sizeof *lt);
    snprintf(lt->cls, sizeof lt->cls, "%s", clsName);
    int ww = tui_cols - 6 < 100 ? tui_cols - 6 : 100, wh = tui_rows - 6 < 26 ? tui_rows - 6 : 26;
    if (ww < 30) ww = 30; if (wh < 10) wh = 10;
    Window *w = win_new(title, 2 + cascade * 2, 1 + cascade, ww, wh); cascade = (cascade + 1) % 5;
    w->kind = W_LISTTOOL; w->user = lt; w->layout = lt_layout; w->on_close = lt_close;
    lt->list = win_add_list(w, lt_select);
    lt->text = win_add_text(w, true);
    lt->text->menu = lt_text_menu; lt->text->nmenu = 2; lt->text->on_menu = lt_text_menu_cb;
    oop labels = lt_send(lt, "commandLabels", NULL, 0);
    if (labels && !IS_INT(labels) && labels->cls == classArray) {
        for (uint32_t i = 0; i < labels->size && lt->nmenu < LT_MAXCMD; i++) {
            lt->labels[lt->nmenu] = oop_str(SLOT(labels, i));
            lt->menu[lt->nmenu] = lt->labels[lt->nmenu];
            lt->nmenu++;
        }
    }
    if (lt->nmenu) { lt->list->menu = lt->menu; lt->list->nmenu = lt->nmenu; lt->list->on_menu = lt_menu_cb; }
    lt_fill(w);
    win_focus(w, lt->list);
}
/* a package asked for a prompt (primitive 204) */
static char *tools_prompt(const char *title, const char *initial) { return dialog_prompt(title, initial); }

/* The System menu: the built-in items, then whatever packages registered with SystemMenu (Smalltalk), then quit. */
static const char *sys_base[] = { "system browser", "workspace", "notebook...", "system transcript", "tutorial...", "-", "file in...", "load package...", "browse class...", "save image", "collect garbage" };
#define NBASE 11
static const char *sys_items[NBASE + 40]; static int sys_n = 0, sys_extra = 0;   /* sys_extra: how many package items follow the base */
static char *sys_extra_labels[32];
static void sys_menu_cb(int i);
static void sys_menu_rebuild(void) {
    for (int i = 0; i < sys_extra; i++) { free(sys_extra_labels[i]); sys_extra_labels[i] = NULL; }
    sys_extra = 0;
    oop sm = class_named("SystemMenu");
    if (sm) {
        oop labels = interp_send(sm, new_symbol("labels"), NULL, 0);
        if (!interp.failed && !IS_INT(labels) && labels->cls == classArray)
            for (uint32_t i = 0; i < labels->size && sys_extra < 32; i++) sys_extra_labels[sys_extra++] = oop_str(SLOT(labels, i));
        interp.failed = false;
    }
    sys_n = 0;
    for (int i = 0; i < NBASE; i++) sys_items[sys_n++] = sys_base[i];
    if (sys_extra) { sys_items[sys_n++] = "-"; for (int i = 0; i < sys_extra; i++) sys_items[sys_n++] = sys_extra_labels[i]; }
    sys_items[sys_n++] = "-"; sys_items[sys_n++] = "quit";
    ui_set_desktop_menu(sys_items, sys_n, sys_menu_cb);
}
static void sys_menu_cb(int i) {
    int extra_first = NBASE + 1, quit = sys_extra ? NBASE + 1 + sys_extra + 1 : NBASE + 1;
    if (sys_extra && i >= extra_first && i < extra_first + sys_extra) {
        oop sm = class_named("SystemMenu"); if (!sm) return;
        oop arg = MK_INT(i - extra_first + 1);
        interp_send(sm, new_symbol("run:"), &arg, 1);
        if (interp.failed) show_error();
        tools_after_eval(); return;
    }
    if (i == quit) { if (dialog_confirm("Quit", tools_quit_message())) ui_quit = true; return; }
    switch (i) {
    case 0: open_browser(); break; case 1: open_workspace(); break;
    case 2: { char *f = dialog_prompt("Notebook (path to a text file, new or existing)", "notes.md"); if (f && f[0]) open_notebook(f); free(f); break; }
    case 3: open_transcript(); break; case 4: open_tutorial(); break;
    case 6: { char *f = dialog_prompt("File in (path to .st file)", ""); if (f && f[0]) { char err[512]; if (file_in(f, err, sizeof err)) ui_status("filed in %s", f); else { ui_status("file in failed: %s", err); dialog_text("File in failed", err); } browsers_refresh(); } free(f); break; }
    case 7: { /* load package: pick one from the list rather than typing its name */
        char *raw[64], *items[64];
        int n = strings_from_array(interp_send(smalltalk, new_symbol("availablePackages"), NULL, 0), raw, 64);
        if (n == 0) { ui_status("there are no packages to load"); break; }
        int m = strings_from_array(interp_send(smalltalk, new_symbol("packageListing"), NULL, 0), items, 64);
        if (m != n) { for (int k = 0; k < m; k++) free(items[k]); for (int k = 0; k < n; k++) items[k] = strdup(raw[k]); }
        int pick = dialog_choose("Load package", "a * marks the packages already loaded", items, n);
        for (int k = 0; k < n; k++) free(items[k]);
        if (pick >= 0) {
            oop arg = new_string(raw[pick]);
            interp_send(smalltalk, new_symbol("loadPackage:"), &arg, 1);
            if (interp.failed) show_error(); else ui_status("loaded package %s", raw[pick]);
            browsers_refresh(); tools_after_eval();
        }
        for (int k = 0; k < n; k++) free(raw[k]);
        break; }
    case 8: { char *n = dialog_prompt("Browse class", ""); if (n && n[0]) { if (class_named(n)) open_browser_on(n); else ui_status("no class named %s", n); } free(n); break; }
    case 9: { char err[512], msg[1200];
        snprintf(msg, sizeof msg, "Save the whole system to %s?\n\nEverything is saved except open windows and processes. The changes file %s is set aside, since the image now contains it.", image_path, changes_abs_path());
        if (!dialog_confirm("Save image", msg)) break;
        if (image_snapshot(image_path, err, sizeof err)) ui_status("saved image %s", image_path);
        else { ui_status("could not save the image: %s", err); dialog_text("Save image failed", err); }
        break; }
    case 10: gc_collect(); ui_status("garbage collected"); break;
    }
}
const char *tools_quit_message(void) {
    static char msg[1400]; int n = tools_unsaved_notebooks();
    if (n) snprintf(msg, sizeof msg, "Quit Smalltalk?  Code changes are saved in %s\n\n%d notebook%s %s changes that are NOT saved.", changes_abs_path(), n, n == 1 ? "" : "s", n == 1 ? "has" : "have");
    else snprintf(msg, sizeof msg, "Quit Smalltalk?  Code changes are saved in %s", changes_abs_path());
    return msg;
}
void tools_system_menu_install(void) { ui_prompt_hook = tools_prompt; sys_menu_rebuild(); }

void tools_after_eval(void) {
    transcripts_refresh();
    static int seen_count = 0, seen_failures = 0;
    if (changes_failures > seen_failures) {
        seen_failures = changes_failures;
        char msg[1200]; snprintf(msg, sizeof msg, "WARNING: your changes could NOT be saved.\n\nCannot write the changes file:\n  %s\n\nThey exist only in this session and will be lost when you quit.\nQuit, change to a directory you can write to (or start with -c file), and redo them.", changes_abs_path());
        ui_status("WARNING: cannot write %s -- changes will be lost on quit", changes_abs_path());
        dialog_text("Changes not saved", msg);
    } else if (changes_count > seen_count) {
        seen_count = changes_count;
        ui_status("saved to %s  (%d change%s this session)", changes_abs_path(), changes_count, changes_count == 1 ? "" : "s");
    }
    if (pending_notebook_path) { char *f = pending_notebook_path; pending_notebook_path = NULL; open_notebook(f); free(f); }
    notebooks_refresh();
    if (pending_inspect) { oop o = pending_inspect; pending_inspect = NULL; open_inspector(o); }
    if (pending_tool_class) { open_tool_workspace(pending_tool_title, pending_tool_class, pending_tool_text); free(pending_tool_class); free(pending_tool_title); free(pending_tool_text); pending_tool_class = pending_tool_title = pending_tool_text = NULL; }
    if (menu_items_changed) { menu_items_changed = false; sys_menu_rebuild(); }
    if (pending_list_tool_class) { open_list_tool(pending_list_tool_class, pending_list_tool_title); free(pending_list_tool_class); free(pending_list_tool_title); pending_list_tool_class = pending_list_tool_title = NULL; }
    if (pending_window_text) { show_lesson_window(pending_window_title, pending_window_text); free(pending_window_title); free(pending_window_text); pending_window_title = pending_window_text = NULL; }
    static size_t last_classes = 0; size_t n = INT_VAL(SLOT(smalltalk, D_TALLY));
    if (n != last_classes) { last_classes = n; browsers_refresh(); }
}
