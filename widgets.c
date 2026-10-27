/* widgets.c - window manager, list/text/button panes, popup menus and dialogs */
#include "ui.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <sys/time.h>

Window *windows[64]; int nwindows = 0;
static const char **desk_menu; static int ndesk; static void (*desk_cb)(int);
static char status_msg[256];
static char *clipboard = NULL;
static struct { Window *w; int mode; int dx, dy; } drag;   /* mode: 1 move, 2 resize */
static Pane *drag_pane = NULL;
static Window *modal = NULL;
static long last_click_ms = 0; static int last_click_pos = -1;

static long now_ms(void) { struct timeval tv; gettimeofday(&tv, NULL); return tv.tv_sec * 1000L + tv.tv_usec / 1000; }
static bool in_rect(Rect r, int x, int y) { return x >= r.x && y >= r.y && x < r.x + r.w && y < r.y + r.h; }
void ui_status(const char *fmt, ...) { va_list ap; va_start(ap, fmt); vsnprintf(status_msg, sizeof status_msg, fmt, ap); va_end(ap); }

/* ---------- windows ---------- */
Window *win_new(const char *title, int x, int y, int w, int h) {
    if (nwindows == 64) return NULL;
    Window *win = calloc(1, sizeof(Window));
    if (w > tui_cols) w = tui_cols; if (h > tui_rows - 1) h = tui_rows - 1;
    if (x + w > tui_cols) x = tui_cols - w; if (y + h > tui_rows - 1) y = tui_rows - 1 - h; if (x < 0) x = 0; if (y < 0) y = 0;
    win->r = (Rect){ x, y, w, h }; snprintf(win->title, sizeof win->title, "%s", title);
    windows[nwindows++] = win; return win;
}
static void pane_free(Pane *p) {
    for (int i = 0; i < p->nitems; i++) free(p->items[i]); free(p->items); free(p->text); free(p);
}
void win_close(Window *w) {
    int i; for (i = 0; i < nwindows && windows[i] != w; i++) {} if (i == nwindows) return;
    memmove(&windows[i], &windows[i + 1], (nwindows - i - 1) * sizeof(Window *)); nwindows--;
    if (w->on_close) w->on_close(w);
    for (int k = 0; k < w->npanes; k++) pane_free(w->panes[k]);
    if (drag.w == w) drag.w = NULL; if (drag_pane && drag_pane->win == w) drag_pane = NULL; if (modal == w) modal = NULL;
    free(w);
}
void win_raise(Window *w) {
    int i; for (i = 0; i < nwindows && windows[i] != w; i++) {} if (i == nwindows) return;
    memmove(&windows[i], &windows[i + 1], (nwindows - i - 1) * sizeof(Window *)); windows[nwindows - 1] = w;
}
Window *win_top(void) { return nwindows ? windows[nwindows - 1] : NULL; }
void win_set_title(Window *w, const char *t) { snprintf(w->title, sizeof w->title, "%s", t); }
void win_focus(Window *w, Pane *p) { w->focus = p; }
static Pane *pane_new(Window *w, int type) {
    Pane *p = calloc(1, sizeof(Pane)); p->type = type; p->win = w; p->sel = -1; p->anchor = -1;
    if (w->npanes < 16) w->panes[w->npanes++] = p; if (!w->focus) w->focus = p; return p;
}
Pane *win_add_list(Window *w, void (*on_select)(Pane *)) { Pane *p = pane_new(w, PANE_LIST); p->on_select = on_select; return p; }
Pane *win_add_text(Window *w, bool readonly) { Pane *p = pane_new(w, PANE_TEXT); p->readonly = readonly; p->text = calloc(1, 64); p->cap = 64; return p; }
Pane *win_add_button(Window *w, const char *label, void (*on_click)(Pane *)) { Pane *p = pane_new(w, PANE_BUTTON); snprintf(p->label, sizeof p->label, "%s", label); p->on_click = on_click; return p; }
void ui_set_desktop_menu(const char **items, int n, void (*on_menu)(int)) { desk_menu = items; ndesk = n; desk_cb = on_menu; }

/* ---------- lists ---------- */
void list_set_items(Pane *p, char **items, int n) {
    const char *keep = p->sel >= 0 && p->sel < p->nitems ? strdup(p->items[p->sel]) : NULL;
    for (int i = 0; i < p->nitems; i++) free(p->items[i]); free(p->items);
    p->items = items; p->nitems = n; p->sel = -1; p->top = 0;
    if (keep) { p->sel = list_find(p, keep); free((char *)keep); }
}
int list_find(Pane *p, const char *s) { for (int i = 0; i < p->nitems; i++) if (!strcmp(p->items[i], s)) return i; return -1; }
const char *list_selected(Pane *p) { return p->sel >= 0 && p->sel < p->nitems ? p->items[p->sel] : NULL; }
static void list_show_sel(Pane *p) {
    int h = p->r.h; if (h < 1) return;
    if (p->sel < p->top) p->top = p->sel; if (p->sel >= p->top + h) p->top = p->sel - h + 1; if (p->top < 0) p->top = 0;
}
void list_select(Pane *p, int idx, bool notify) {
    p->sel = (idx >= 0 && idx < p->nitems) ? idx : -1; list_show_sel(p);
    if (notify && p->on_select) p->on_select(p);
}

/* ---------- text buffer helpers ---------- */
static void text_reserve(Pane *p, int n) { if (p->len + n + 1 > p->cap) { p->cap = (p->len + n + 1) * 2; p->text = realloc(p->text, p->cap); } }
static void text_delete_range(Pane *p, int a, int b) { if (a > b) { int t = a; a = b; b = t; } memmove(p->text + a, p->text + b, p->len - b + 1); p->len -= b - a; p->cursor = a; p->anchor = -1; p->dirty = true; }
static void text_insert_at(Pane *p, int at, const char *s, int n) { text_reserve(p, n); memmove(p->text + at + n, p->text + at, p->len - at + 1); memcpy(p->text + at, s, n); p->len += n; p->dirty = true; }
static bool has_sel(Pane *p) { return p->anchor >= 0 && p->anchor != p->cursor; }
static void sel_range(Pane *p, int *a, int *b) { *a = p->anchor < p->cursor ? p->anchor : p->cursor; *b = p->anchor < p->cursor ? p->cursor : p->anchor; }
static int line_start(Pane *p, int pos) { while (pos > 0 && p->text[pos - 1] != '\n') pos--; return pos; }
static int line_end(Pane *p, int pos) { while (pos < p->len && p->text[pos] != '\n') pos++; return pos; }
static int line_of(Pane *p, int pos) { int n = 0; for (int i = 0; i < pos && i < p->len; i++) if (p->text[i] == '\n') n++; return n; }
static int pos_of_line(Pane *p, int line) { int pos = 0; while (line > 0 && pos < p->len) { if (p->text[pos] == '\n') line--; pos++; } return pos; }
static int nlines(Pane *p) { return line_of(p, p->len) + 1; }
static int col_of(Pane *p, int pos) { int c = 0; for (int i = line_start(p, pos); i < pos; ) { uint32_t cp; int n = utf8_decode(p->text + i, &cp); if (cp == '\t') c += 4 - c % 4; else c += tui_cell_width(cp); i += n; } return c; }
static int pos_at_col(Pane *p, int ls, int col) {
    int c = 0, i = ls;
    while (i < p->len && p->text[i] != '\n') { uint32_t cp; int n = utf8_decode(p->text + i, &cp); int w = cp == '\t' ? 4 - c % 4 : tui_cell_width(cp); if (c + w > col) break; c += w; i += n; }
    return i;
}
static void text_show_cursor(Pane *p) {
    int line = line_of(p, p->cursor), col = col_of(p, p->cursor);
    if (line < p->tline) p->tline = line; if (line >= p->tline + p->r.h) p->tline = line - p->r.h + 1; if (p->tline < 0) p->tline = 0;
    if (col < p->hoff) p->hoff = col; if (col >= p->hoff + p->r.w - 1) p->hoff = col - p->r.w + 2; if (p->hoff < 0) p->hoff = 0;
}
void text_set(Pane *p, const char *s) { int n = (int)strlen(s); text_reserve(p, n); memcpy(p->text, s, n + 1); p->len = n; p->cursor = 0; p->anchor = -1; p->tline = 0; p->hoff = 0; p->dirty = false; }
char *text_get(Pane *p) { return strdup(p->text); }
char *text_selection(Pane *p) { if (!has_sel(p)) return NULL; int a, b; sel_range(p, &a, &b); char *s = malloc(b - a + 1); memcpy(s, p->text + a, b - a); s[b - a] = 0; return s; }
char *text_selection_or_line(Pane *p) {
    char *s = text_selection(p); if (s) return s;
    int a = line_start(p, p->cursor), b = line_end(p, p->cursor); s = malloc(b - a + 1); memcpy(s, p->text + a, b - a); s[b - a] = 0; return s;
}
void text_insert(Pane *p, const char *s) {
    if (has_sel(p)) { int a, b; sel_range(p, &a, &b); text_delete_range(p, a, b); }
    int n = (int)strlen(s); text_insert_at(p, p->cursor, s, n); p->cursor += n; p->anchor = -1; text_show_cursor(p);
}
void text_select_all(Pane *p) { p->anchor = 0; p->cursor = p->len; }
void text_select_range(Pane *p, int from, int to) { p->anchor = from; p->cursor = to; text_show_cursor(p); }
void text_copy(Pane *p) { char *s = text_selection(p); if (s) { free(clipboard); clipboard = s; } }
void text_cut(Pane *p) { if (p->readonly) return; text_copy(p); if (has_sel(p)) { int a, b; sel_range(p, &a, &b); text_delete_range(p, a, b); text_show_cursor(p); } }
void text_paste(Pane *p) { if (clipboard && !p->readonly) text_insert(p, clipboard); }
void text_append(Pane *p, const char *s) { int n = (int)strlen(s); text_insert_at(p, p->len, s, n); p->dirty = false; }
void text_scroll_to_end(Pane *p) { p->cursor = p->len; p->anchor = -1; int l = nlines(p); p->tline = l > p->r.h ? l - p->r.h : 0; p->hoff = 0; }

/* ---------- drawing ---------- */
static void draw_list(Pane *p, bool active) {
    for (int row = 0; row < p->r.h; row++) {
        int i = p->top + row; bool sel = i == p->sel;
        int fg = sel ? C_LIST_SEL_FG : C_WIN_FG, bg = sel ? (active ? C_LIST_SEL_BG : C_DIM_FG) : C_WIN_BG;
        tui_fill(p->r.x, p->r.y + row, p->r.w, 1, ' ', fg, bg, 0);
        if (i < p->nitems) tui_text(p->r.x, p->r.y + row, p->items[i], p->r.w - (p->nitems > p->r.h ? 1 : 0), fg, bg, 0);
    }
    if (p->nitems > p->r.h && p->r.h > 0) {
        int th = p->r.h * p->r.h / p->nitems; if (th < 1) th = 1; int ty = p->top * (p->r.h - th) / (p->nitems - p->r.h > 0 ? p->nitems - p->r.h : 1);
        for (int row = 0; row < p->r.h; row++) tui_put(p->r.x + p->r.w - 1, p->r.y + row, (row >= ty && row < ty + th) ? 0x2588 : 0x2591, C_FRAME, C_WIN_BG, 0);
    }
}
static void draw_text(Pane *p, bool active) {
    int a = -1, b = -1; if (has_sel(p)) sel_range(p, &a, &b);
    int pos = pos_of_line(p, p->tline);
    for (int row = 0; row < p->r.h; row++) {
        tui_fill(p->r.x, p->r.y + row, p->r.w, 1, ' ', C_WIN_FG, C_WIN_BG, 0);
        if (pos > p->len || (pos == p->len && row > 0 && p->tline + row > line_of(p, p->len))) continue;
        int col = 0;
        while (pos < p->len && p->text[pos] != '\n') {
            uint32_t cp; int n = utf8_decode(p->text + pos, &cp);
            int w = cp == '\t' ? 4 - col % 4 : tui_cell_width(cp);
            bool insel = pos >= a && pos < b;
            for (int k = 0; k < w; k++) {
                int sx = col + k - p->hoff;
                if (sx >= 0 && sx < p->r.w) tui_put(p->r.x + sx, p->r.y + row, (cp == '\t' || k > 0) ? ' ' : (cp < 32 ? '?' : cp), C_WIN_FG, insel ? C_SEL_BG : C_WIN_BG, 0);
            }
            col += w; pos += n;
        }
        if (pos < p->len && pos >= a && pos < b && col - p->hoff >= 0 && col - p->hoff < p->r.w) tui_put(p->r.x + col - p->hoff, p->r.y + row, ' ', C_WIN_FG, C_SEL_BG, 0);
        pos++;
    }
    if (active && !p->readonly && p->win == win_top()) {
        int line = line_of(p, p->cursor), col = col_of(p, p->cursor);
        if (line >= p->tline && line < p->tline + p->r.h && col - p->hoff >= 0 && col - p->hoff < p->r.w) {
            int cx = p->r.x + col - p->hoff, cy = p->r.y + line - p->tline;
            uint32_t cp = ' ';
            if (p->cursor < p->len && p->text[p->cursor] != '\n' && p->text[p->cursor] != '\t') utf8_decode(p->text + p->cursor, &cp);
            if (cp < 32) cp = ' ';
            tui_put(cx, cy, cp, C_WIN_BG, C_WIN_FG, ATTR_BOLD);     /* visible block cursor */
            tui_set_cursor(cx, cy);                                   /* and the terminal's own cursor */
        }
    }
}
static void draw_button(Pane *p) {
    tui_fill(p->r.x, p->r.y, p->r.w, 1, ' ', C_WIN_FG, C_MENU_BG, 0);
    tui_text(p->r.x + 1, p->r.y, p->label, p->r.w - 2, C_WIN_FG, C_MENU_BG, ATTR_BOLD);
}
static void draw_window(Window *w, bool top) {
    if (w->layout) w->layout(w);
    tui_fill(w->r.x, w->r.y, w->r.w, w->r.h, ' ', C_WIN_FG, C_WIN_BG, 0);
    tui_box(w->r.x, w->r.y, w->r.w, w->r.h, C_FRAME, C_WIN_BG, 0);
    int tbg = top ? C_TITLE_BG : C_TITLE_INACTIVE_BG, tfg = top ? C_TITLE_FG : C_WIN_FG;
    tui_fill(w->r.x, w->r.y, w->r.w, 1, ' ', tfg, tbg, 0);
    tui_text(w->r.x + 1, w->r.y, "[x]", 3, tfg, tbg, ATTR_BOLD);
    char t[160]; snprintf(t, sizeof t, " %s ", w->title);
    int tw = (int)strlen(t); int tx = w->r.x + (w->r.w - tw) / 2; if (tx < w->r.x + 5) tx = w->r.x + 5;
    tui_text(tx, w->r.y, t, w->r.w - (tx - w->r.x) - 1, tfg, tbg, ATTR_BOLD);
    tui_put(w->r.x + w->r.w - 1, w->r.y + w->r.h - 1, 0x256f, C_FRAME, C_WIN_BG, ATTR_BOLD);
    for (int i = 0; i < w->npanes; i++) {
        Pane *p = w->panes[i]; if (p->r.w <= 0 || p->r.h <= 0) continue;
        bool active = (w->focus == p);
        if (p->type == PANE_LIST) draw_list(p, active); else if (p->type == PANE_TEXT) draw_text(p, active); else draw_button(p);
    }
}
void ui_draw(void) {
    tui_set_cursor(-1, -1);
    tui_clear(C_FRAME, C_DESKTOP_BG);
    for (int y = 0; y < tui_rows - 1; y += 2) for (int x = (y / 2) % 2; x < tui_cols; x += 4) tui_put(x, y, 0xb7, 240, C_DESKTOP_BG, 0);
    for (int i = 0; i < nwindows; i++) draw_window(windows[i], i == nwindows - 1);
    tui_fill(0, tui_rows - 1, tui_cols, 1, ' ', C_WIN_FG, C_TITLE_INACTIVE_BG, 0);
    tui_text(1, tui_rows - 1, status_msg[0] ? status_msg : "Mini Smalltalk-80  |  right-click desktop for the System menu  |  ctrl-Q quits", tui_cols - 2, C_WIN_FG, C_TITLE_INACTIVE_BG, 0);
}

/* ---------- events ---------- */
static Window *window_at(int x, int y) { for (int i = nwindows - 1; i >= 0; i--) if (in_rect(windows[i]->r, x, y)) return windows[i]; return NULL; }
static Pane *pane_at(Window *w, int x, int y) { if (w->layout) w->layout(w); for (int i = 0; i < w->npanes; i++) if (in_rect(w->panes[i]->r, x, y)) return w->panes[i]; return NULL; }

static void text_mouse_pos(Pane *p, int x, int y, int *pos) {
    int line = p->tline + (y - p->r.y); int nl = nlines(p); if (line >= nl) line = nl - 1;
    int ls = pos_of_line(p, line); *pos = pos_at_col(p, ls, x - p->r.x + p->hoff);
}
static void select_word(Pane *p) {
    int a = p->cursor, b = p->cursor;
    #define WORDCH(c) (((c) >= 'a' && (c) <= 'z') || ((c) >= 'A' && (c) <= 'Z') || ((c) >= '0' && (c) <= '9') || (c) == '_' || (c) == ':')
    while (a > 0 && WORDCH(p->text[a - 1])) a--; while (b < p->len && WORDCH(p->text[b])) b++;
    if (a == b && b < p->len) b++;
    p->anchor = a; p->cursor = b;
}
static void pane_mouse(Pane *p, Event *ev) {
    Window *w = p->win; w->focus = p;
    if (ev->type == EV_MOUSE_DOWN && ev->button == BTN_RIGHT) {
        if (p->menu && p->nmenu) { int i = menu_popup(ev->x, ev->y, p->menu, p->nmenu); if (i >= 0 && p->on_menu) p->on_menu(p, i); }
        return;
    }
    if (p->type == PANE_LIST) {
        if (ev->type == EV_MOUSE_DOWN && ev->button == BTN_LEFT) { int i = p->top + ev->y - p->r.y; if (i < p->nitems) list_select(p, i, true); }
    } else if (p->type == PANE_TEXT) {
        int pos; text_mouse_pos(p, ev->x, ev->y, &pos);
        if (ev->type == EV_MOUSE_DOWN && ev->button == BTN_LEFT) {
            long t = now_ms();
            if (t - last_click_ms < 400 && pos == last_click_pos) { p->cursor = pos; select_word(p); last_click_ms = 0; }
            else { p->cursor = pos; p->anchor = pos; drag_pane = p; last_click_ms = t; last_click_pos = pos; }
            p->prefcol = col_of(p, p->cursor);
        } else if (ev->type == EV_MOUSE_DRAG && drag_pane == p) { p->cursor = pos; text_show_cursor(p); }
        else if (ev->type == EV_MOUSE_UP && drag_pane == p) { if (p->anchor == p->cursor) p->anchor = -1; drag_pane = NULL; }
    } else if (p->type == PANE_BUTTON) {
        if (ev->type == EV_MOUSE_DOWN && ev->button == BTN_LEFT && p->on_click) p->on_click(p);
    }
}
static void pane_wheel(Pane *p, int dir) {
    if (p->type == PANE_LIST) { p->top += dir * 3; int mx = p->nitems - p->r.h; if (p->top > mx) p->top = mx; if (p->top < 0) p->top = 0; }
    else if (p->type == PANE_TEXT) { p->tline += dir * 3; int mx = nlines(p) - 1; if (p->tline > mx) p->tline = mx; if (p->tline < 0) p->tline = 0; }
}
static void move_cursor(Pane *p, Event *ev, int newpos, bool vertical) {
    if (ev->mods & MOD_SHIFT) { if (p->anchor < 0) p->anchor = p->cursor; } else p->anchor = -1;
    p->cursor = newpos; if (!vertical) p->prefcol = col_of(p, p->cursor); text_show_cursor(p);
}
static void text_key(Pane *p, Event *ev) {
    if (p->on_key && p->on_key(p, ev)) return;
    int k = ev->key;
    if (ev->mods & MOD_CTRL) {
        switch (k) { case 'a': text_select_all(p); return; case 'c': text_copy(p); return; case 'x': text_cut(p); return; case 'v': text_paste(p); return;
        case 'e': move_cursor(p, ev, line_end(p, p->cursor), false); return; case 'k': if (!p->readonly) { int e = line_end(p, p->cursor); if (e == p->cursor && e < p->len) e++; text_delete_range(p, p->cursor, e); } return; }
        return;
    }
    switch (k) {
    case KEY_LEFT: if (p->cursor > 0) { int c = p->cursor - 1; while (c > 0 && (p->text[c] & 0xc0) == 0x80) c--; move_cursor(p, ev, c, false); } return;
    case KEY_RIGHT: if (p->cursor < p->len) { int c = p->cursor + 1; while (c < p->len && (p->text[c] & 0xc0) == 0x80) c++; move_cursor(p, ev, c, false); } return;
    case KEY_UP: case KEY_DOWN: case KEY_PGUP: case KEY_PGDN: {
        int line = line_of(p, p->cursor); int d = k == KEY_UP ? -1 : k == KEY_DOWN ? 1 : k == KEY_PGUP ? -p->r.h : p->r.h;
        line += d; if (line < 0) line = 0; if (line >= nlines(p)) line = nlines(p) - 1;
        move_cursor(p, ev, pos_at_col(p, pos_of_line(p, line), p->prefcol), true); return; }
    case KEY_HOME: move_cursor(p, ev, line_start(p, p->cursor), false); return;
    case KEY_END: move_cursor(p, ev, line_end(p, p->cursor), false); return;
    }
    if (p->readonly) return;
    if (k == 127 || k == 8) { if (has_sel(p)) { int a, b; sel_range(p, &a, &b); text_delete_range(p, a, b); } else if (p->cursor > 0) { int c = p->cursor - 1; while (c > 0 && (p->text[c] & 0xc0) == 0x80) c--; text_delete_range(p, c, p->cursor); } text_show_cursor(p); return; }
    if (k == KEY_DEL) { if (has_sel(p)) { int a, b; sel_range(p, &a, &b); text_delete_range(p, a, b); } else if (p->cursor < p->len) { int c = p->cursor + 1; while (c < p->len && (p->text[c] & 0xc0) == 0x80) c++; text_delete_range(p, p->cursor, c); } return; }
    if (k == 13) {
        char buf[128] = "\n"; int ls = line_start(p, p->cursor), n = 1;
        for (int i = ls; i < p->cursor && n < 120 && (p->text[i] == '\t' || p->text[i] == ' '); i++) buf[n++] = p->text[i];
        buf[n] = 0; text_insert(p, buf); return;
    }
    if (k == 9) { text_insert(p, "\t"); return; }
    if (k >= 32 && k < 1000) {
        char u[5]; int n; uint32_t cp = (uint32_t)k;
        if (cp < 0x80) { u[0] = (char)cp; n = 1; } else if (cp < 0x800) { u[0] = 0xc0 | (cp >> 6); u[1] = 0x80 | (cp & 0x3f); n = 2; }
        else if (cp < 0x10000) { u[0] = 0xe0 | (cp >> 12); u[1] = 0x80 | ((cp >> 6) & 0x3f); u[2] = 0x80 | (cp & 0x3f); n = 3; }
        else { u[0] = 0xf0 | (cp >> 18); u[1] = 0x80 | ((cp >> 12) & 0x3f); u[2] = 0x80 | ((cp >> 6) & 0x3f); u[3] = 0x80 | (cp & 0x3f); n = 4; }
        u[n] = 0; text_insert(p, u);
    }
}
static void list_key(Pane *p, Event *ev) {
    int k = ev->key, n = p->nitems; if (!n) return;
    int s = p->sel < 0 ? -1 : p->sel;
    switch (k) {
    case KEY_UP: if (s > 0) list_select(p, s - 1, true); return;
    case KEY_DOWN: if (s < n - 1) list_select(p, s + 1, true); return;
    case KEY_PGUP: list_select(p, s - p->r.h < 0 ? 0 : s - p->r.h, true); return;
    case KEY_PGDN: list_select(p, s + p->r.h >= n ? n - 1 : s + p->r.h, true); return;
    case KEY_HOME: list_select(p, 0, true); return;
    case KEY_END: list_select(p, n - 1, true); return;
    }
    if (k >= 32 && k < 127 && !(ev->mods & MOD_CTRL)) {   /* jump to first item starting with the letter */
        for (int i = 1; i <= n; i++) { int j = (s + i) % n; if (p->items[j][0] == k || (p->items[j][0] | 32) == (k | 32)) { list_select(p, j, true); return; } }
    }
}

void ui_handle(Event *ev) {
    if (ev->type == EV_RESIZE) { for (int i = 0; i < nwindows; i++) { Window *w = windows[i]; if (w->r.x + w->r.w > tui_cols) w->r.x = tui_cols - w->r.w; if (w->r.y + w->r.h > tui_rows - 1) w->r.y = tui_rows - 1 - w->r.h; if (w->r.x < 0) w->r.x = 0; if (w->r.y < 0) w->r.y = 0; } return; }
    if (ev->type == EV_KEY) {
        Window *w = modal ? modal : win_top();
        if (!w) { if (ev->key == 27 && desk_cb) { int i = menu_popup(2, 1, desk_menu, ndesk); if (i >= 0) desk_cb(i); } return; }
        if (w->on_key && w->on_key(w, ev)) return;
        if (ev->key == 9 && !(ev->mods & MOD_CTRL) && (w->focus == NULL || w->focus->type != PANE_TEXT || (ev->mods & MOD_SHIFT))) {   /* cycle focus */
            int i = 0; for (; i < w->npanes && w->panes[i] != w->focus; i++) {} w->focus = w->panes[(i + 1) % w->npanes]; return;
        }
        if (ev->key == 27 && !modal && desk_cb) { int i = menu_popup(2, 1, desk_menu, ndesk); if (i >= 0) desk_cb(i); return; }
        Pane *p = w->focus; if (!p) return;
        if (p->type == PANE_TEXT) text_key(p, ev); else if (p->type == PANE_LIST) list_key(p, ev);
        else if (p->type == PANE_BUTTON && (ev->key == 13 || ev->key == ' ') && p->on_click) p->on_click(p);
        return;
    }
    /* mouse */
    if (ev->type == EV_MOUSE_DRAG || ev->type == EV_MOUSE_UP) {
        if (drag.w) {
            Window *w = drag.w;
            if (drag.mode == 1) { w->r.x = ev->x - drag.dx; w->r.y = ev->y - drag.dy; if (w->r.y < 0) w->r.y = 0; if (w->r.y > tui_rows - 2) w->r.y = tui_rows - 2; if (w->r.x < -w->r.w + 4) w->r.x = -w->r.w + 4; if (w->r.x > tui_cols - 4) w->r.x = tui_cols - 4; }
            else { int nw = ev->x - w->r.x + 1, nh = ev->y - w->r.y + 1; if (nw >= 12) w->r.w = nw; if (nh >= 4) w->r.h = nh; }
            if (ev->type == EV_MOUSE_UP) drag.w = NULL;
            return;
        }
        if (drag_pane) { pane_mouse(drag_pane, ev); return; }
        return;
    }
    Window *w = window_at(ev->x, ev->y);
    if (modal && w != modal) return;
    if (ev->type == EV_WHEEL_UP || ev->type == EV_WHEEL_DOWN) { if (w) { Pane *p = pane_at(w, ev->x, ev->y); if (p) pane_wheel(p, ev->type == EV_WHEEL_UP ? -1 : 1); } return; }
    if (ev->type != EV_MOUSE_DOWN) return;
    if (!w) { if (ev->button == BTN_RIGHT && desk_cb) { int i = menu_popup(ev->x, ev->y, desk_menu, ndesk); if (i >= 0) desk_cb(i); } return; }
    win_raise(w);
    if (ev->y == w->r.y) {   /* title bar */
        if (ev->x >= w->r.x + 1 && ev->x <= w->r.x + 3 && ev->button == BTN_LEFT) { win_close(w); return; }
        if (ev->button == BTN_LEFT) { drag.w = w; drag.mode = 1; drag.dx = ev->x - w->r.x; drag.dy = ev->y - w->r.y; }
        return;
    }
    if (ev->x == w->r.x + w->r.w - 1 && ev->y == w->r.y + w->r.h - 1 && ev->button == BTN_LEFT) { drag.w = w; drag.mode = 2; return; }
    Pane *p = pane_at(w, ev->x, ev->y);
    if (p) pane_mouse(p, ev);
}

/* ---------- popup menu ---------- */
int menu_popup(int x, int y, const char **items, int n) {
    int w = 4; for (int i = 0; i < n; i++) { int l = (int)strlen(items[i]) + 4; if (l > w) w = l; }
    int h = n + 2; if (x + w > tui_cols) x = tui_cols - w; if (y + h > tui_rows) y = tui_rows - h; if (x < 0) x = 0; if (y < 0) y = 0;
    int hi = -1; Event ev;
    for (;;) {
        ui_draw();
        tui_fill(x, y, w, h, ' ', C_WIN_FG, C_MENU_BG, 0); tui_box(x, y, w, h, C_WIN_FG, C_MENU_BG, 0);
        for (int i = 0; i < n; i++) {
            bool sel = i == hi; if (!strcmp(items[i], "-")) { for (int k = 1; k < w - 1; k++) tui_put(x + k, y + 1 + i, 0x2500, C_WIN_FG, C_MENU_BG, 0); continue; }
            tui_fill(x + 1, y + 1 + i, w - 2, 1, ' ', sel ? C_TITLE_FG : C_WIN_FG, sel ? C_MENU_HI_BG : C_MENU_BG, 0);
            tui_text(x + 2, y + 1 + i, items[i], w - 4, sel ? C_TITLE_FG : C_WIN_FG, sel ? C_MENU_HI_BG : C_MENU_BG, 0);
        }
        tui_set_cursor(-1, -1); tui_flush();
        if (!tui_read_event(&ev, 500)) continue;
        if (ev.type == EV_KEY) {
            if (ev.key == 27) return -1;
            if (ev.key == KEY_UP) { do { hi = (hi + n - 1) % n; } while (!strcmp(items[hi], "-")); continue; }
            if (ev.key == KEY_DOWN) { do { hi = (hi + 1) % n; } while (!strcmp(items[hi], "-")); continue; }
            if (ev.key == 13 && hi >= 0) return hi;
            continue;
        }
        if (ev.type == EV_MOUSE_MOVE || ev.type == EV_MOUSE_DRAG) { if (ev.x > x && ev.x < x + w - 1 && ev.y > y && ev.y < y + h - 1) hi = ev.y - y - 1; continue; }
        if (ev.type == EV_MOUSE_DOWN || ev.type == EV_MOUSE_UP) {
            bool inside = ev.x > x && ev.x < x + w - 1 && ev.y > y && ev.y < y + h - 1;
            if (inside) { int i = ev.y - y - 1; if (strcmp(items[i], "-")) return i; continue; }
            if (ev.type == EV_MOUSE_DOWN) return -1;
        }
    }
}

/* ---------- dialogs ---------- */
static int dialog_result;
static bool prompt_key(Pane *p, Event *ev) { if (ev->key == 13) { dialog_result = 1; return true; } if (ev->key == 27) { dialog_result = 0; return true; } return false; }
char *dialog_prompt(const char *title, const char *initial) {
    int w = 50; Window *win = win_new(title, (tui_cols - w) / 2, tui_rows / 2 - 2, w, 4);
    Pane *t = win_add_text(win, false); t->on_key = prompt_key; text_set(t, initial ? initial : ""); text_select_all(t);
    t->r = (Rect){ win->r.x + 2, win->r.y + 1, w - 4, 1 };
    Pane *b1 = win_add_button(win, "[ OK ]", NULL), *b2 = win_add_button(win, "[ Cancel ]", NULL);
    b1->r = (Rect){ win->r.x + 2, win->r.y + 2, 8, 1 }; b2->r = (Rect){ win->r.x + 12, win->r.y + 2, 12, 1 };
    win->focus = t;
    Event ev; modal = win; dialog_result = -1;
    while (dialog_result < 0) {
        t->r = (Rect){ win->r.x + 2, win->r.y + 1, win->r.w - 4, 1 }; b1->r = (Rect){ win->r.x + 2, win->r.y + 2, 8, 1 }; b2->r = (Rect){ win->r.x + 12, win->r.y + 2, 12, 1 };
        ui_draw(); tui_flush();
        if (!tui_read_event(&ev, 500)) continue;
        if (ev.type == EV_MOUSE_DOWN && in_rect(b1->r, ev.x, ev.y)) { dialog_result = 1; break; }
        if (ev.type == EV_MOUSE_DOWN && in_rect(b2->r, ev.x, ev.y)) { dialog_result = 0; break; }
        if (ev.type == EV_MOUSE_DOWN && ev.y == win->r.y && ev.x >= win->r.x + 1 && ev.x <= win->r.x + 3) { dialog_result = 0; break; }
        ui_handle(&ev);
    }
    modal = NULL;
    char *r = dialog_result == 1 ? text_get(t) : NULL;
    win_close(win); return r;
}
static bool confirm_key(Window *w, Event *ev) {
    if (ev->key == 'y' || ev->key == 'Y' || ev->key == 13) { dialog_result = 1; return true; }
    if (ev->key == 'n' || ev->key == 'N' || ev->key == 27) { dialog_result = 0; return true; }
    return false;
}
static void yes_click(Pane *p) { dialog_result = 1; }
static void no_click(Pane *p) { dialog_result = 0; }
bool dialog_confirm(const char *title, const char *msg) {
    int w = (int)strlen(msg) + 6; if (w < 30) w = 30; if (w > tui_cols - 4) w = tui_cols - 4;
    Window *win = win_new(title, (tui_cols - w) / 2, tui_rows / 2 - 2, w, 5); win->on_key = confirm_key;
    Pane *t = win_add_text(win, true); text_set(t, msg); t->r = (Rect){ win->r.x + 2, win->r.y + 1, w - 4, 1 };
    Pane *b1 = win_add_button(win, "[ Yes ]", yes_click), *b2 = win_add_button(win, "[ No ]", no_click);
    b1->r = (Rect){ win->r.x + 2, win->r.y + 3, 9, 1 }; b2->r = (Rect){ win->r.x + 13, win->r.y + 3, 8, 1 };
    win->focus = b1;
    Event ev; modal = win; dialog_result = -1;
    while (dialog_result < 0) {
        t->r = (Rect){ win->r.x + 2, win->r.y + 1, win->r.w - 4, 1 }; b1->r = (Rect){ win->r.x + 2, win->r.y + 3, 9, 1 }; b2->r = (Rect){ win->r.x + 13, win->r.y + 3, 8, 1 };
        ui_draw(); tui_flush(); if (!tui_read_event(&ev, 500)) continue;
        if (ev.type == EV_MOUSE_DOWN && ev.y == win->r.y && ev.x >= win->r.x + 1 && ev.x <= win->r.x + 3) { dialog_result = 0; break; }
        ui_handle(&ev);
    }
    modal = NULL; bool r = dialog_result == 1; win_close(win); return r;
}
static void text_window_layout(Window *w) { w->panes[0]->r = (Rect){ w->r.x + 1, w->r.y + 1, w->r.w - 2, w->r.h - 2 }; }
static const char *ro_menu[] = { "copy", "select all" };
static void ro_menu_cb(Pane *p, int i) { if (i == 0) text_copy(p); else text_select_all(p); }
void dialog_text(const char *title, const char *text) {
    int lines = 1, maxw = 20; int cur = 0;
    for (const char *s = text; *s; s++) { if (*s == '\n') { lines++; cur = 0; } else if (++cur > maxw) maxw = cur; }
    int w = maxw + 4; if (w > tui_cols - 4) w = tui_cols - 4; if (w < (int)strlen(title) + 8) w = (int)strlen(title) + 8;
    int h = lines + 2; if (h > tui_rows - 6) h = tui_rows - 6; if (h < 4) h = 4;
    static int cascade = 0; cascade = (cascade + 1) % 6;
    Window *win = win_new(title, 6 + cascade * 2, 3 + cascade, w, h); win->layout = text_window_layout;
    Pane *t = win_add_text(win, true); text_set(t, text); t->menu = ro_menu; t->nmenu = 2; t->on_menu = ro_menu_cb;
}
