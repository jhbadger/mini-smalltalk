/* ui.h - windows, panes and dialogs for the TUI */
#ifndef UI_H
#define UI_H
#include "tui.h"
#include <stdbool.h>

typedef struct { int x, y, w, h; } Rect;
typedef struct Window Window;
typedef struct Pane Pane;

enum { PANE_LIST, PANE_TEXT, PANE_BUTTON };

struct Pane {
    int type; Rect r; Window *win; void *user; int tag;
    /* list */
    char **items; int nitems; int sel; int top;
    void (*on_select)(Pane *);
    /* text */
    char *text; int len, cap; int cursor, anchor; int tline; int hoff; int prefcol; bool readonly; bool dirty; bool wrap;
    bool (*on_key)(Pane *, Event *);          /* return true if handled */
    /* button */
    char label[64]; void (*on_click)(Pane *);
    /* popup menu (right button) */
    const char **menu; int nmenu; void (*on_menu)(Pane *, int);
};

struct Window {
    Rect r; char title[128]; Pane *panes[16]; int npanes; Pane *focus; void *user; int kind;
    void (*layout)(Window *); void (*on_close)(Window *); bool (*on_key)(Window *, Event *);
    bool closed;
};

/* colours */
enum { C_DESKTOP_BG = 237, C_WIN_BG = 255, C_WIN_FG = 16, C_TITLE_BG = 24, C_TITLE_FG = 231, C_TITLE_INACTIVE_BG = 250,
    C_FRAME = 240, C_SEL_BG = 153, C_MENU_BG = 230, C_MENU_HI_BG = 24, C_LIST_SEL_BG = 16, C_LIST_SEL_FG = 255, C_DIM_FG = 244 };

/* window manager */
extern Window *windows[64]; extern int nwindows;
Window *win_new(const char *title, int x, int y, int w, int h);
void win_close(Window *w);
void win_raise(Window *w);
Pane *win_add_list(Window *w, void (*on_select)(Pane *));
Pane *win_add_text(Window *w, bool readonly);
Pane *win_add_button(Window *w, const char *label, void (*on_click)(Pane *));
void win_set_title(Window *w, const char *title);
void win_focus(Window *w, Pane *p);
Window *win_top(void);
void ui_draw(void);
void ui_handle(Event *ev);
void ui_set_desktop_menu(const char **items, int n, void (*on_menu)(int));
void ui_status(const char *fmt, ...);

/* list panes */
void list_set_items(Pane *p, char **items, int n);     /* takes ownership of strings and array */
void list_select(Pane *p, int idx, bool notify);
const char *list_selected(Pane *p);
int list_find(Pane *p, const char *s);

/* text panes */
void text_set(Pane *p, const char *s);
char *text_get(Pane *p);                                /* malloc'd copy */
char *text_selection_or_line(Pane *p);                  /* malloc'd; selection, else current line */
char *text_selection(Pane *p);                          /* malloc'd or NULL */
void text_insert(Pane *p, const char *s);               /* replace selection with s, cursor after */
void text_select_all(Pane *p);
void text_select_range(Pane *p, int from, int to);
void text_copy(Pane *p); void text_cut(Pane *p); void text_paste(Pane *p);
void text_append(Pane *p, const char *s);
void text_scroll_to_end(Pane *p);

/* modal helpers */
int menu_popup(int x, int y, const char **items, int n);     /* -1 if cancelled */
char *dialog_prompt(const char *title, const char *initial); /* malloc'd or NULL */
bool dialog_confirm(const char *title, const char *msg);
void dialog_text(const char *title, const char *text);       /* non-modal read-only window */

#endif
