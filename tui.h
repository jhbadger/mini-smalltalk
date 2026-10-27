/* tui.h - terminal screen buffer and input events */
#ifndef TUI_H
#define TUI_H
#include <stdint.h>
#include <stdio.h>

enum { ATTR_BOLD = 1, ATTR_REVERSE = 2, ATTR_UNDERLINE = 4, ATTR_DIM = 8 };
#define COLOR_DEFAULT (-1)

enum { EV_NONE, EV_KEY, EV_MOUSE_DOWN, EV_MOUSE_UP, EV_MOUSE_DRAG, EV_MOUSE_MOVE, EV_WHEEL_UP, EV_WHEEL_DOWN, EV_RESIZE };
enum { KEY_UP = 1000, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_HOME, KEY_END, KEY_PGUP, KEY_PGDN, KEY_DEL, KEY_INS, KEY_F1 };
enum { MOD_SHIFT = 1, MOD_ALT = 2, MOD_CTRL = 4 };
enum { BTN_LEFT = 0, BTN_MIDDLE = 1, BTN_RIGHT = 2 };
typedef struct { int type; int key; int x, y; int button; int mods; } Event;

extern int tui_cols, tui_rows;
void tui_init(void);
void tui_shutdown(void);
void tui_clear(int fg, int bg);
void tui_put(int x, int y, uint32_t ch, int fg, int bg, int attr);
int tui_text(int x, int y, const char *s, int maxw, int fg, int bg, int attr);   /* returns cells used */
void tui_fill(int x, int y, int w, int h, uint32_t ch, int fg, int bg, int attr);
void tui_box(int x, int y, int w, int h, int fg, int bg, int attr);
void tui_set_cursor(int x, int y);  /* -1,-1 hides */
void tui_flush(void);
int tui_read_event(Event *ev, int timeout_ms);
int utf8_decode(const char *s, uint32_t *cp);  /* returns bytes consumed */
int tui_cell_width(uint32_t cp);
int tui_eof(void);                 /* scripted (ST_HEADLESS) input exhausted */
void tui_dump(FILE *f);            /* write the current screen as plain text */
#endif
