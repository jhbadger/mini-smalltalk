/* tui.c - raw terminal handling, double-buffered cell screen, keyboard and SGR mouse input */
#include "tui.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <termios.h>
#include <signal.h>
#include <poll.h>
#include <sys/ioctl.h>

typedef struct { uint32_t ch; int16_t fg, bg; uint8_t attr; } Cell;
int tui_cols = 80, tui_rows = 24;
static Cell *front = NULL, *back = NULL;
static struct termios orig_tio;
static volatile sig_atomic_t resized = 0;
static int cur_x = -1, cur_y = -1;
static int initialized = 0;
static int headless = 0, at_eof = 0;
static int utf8_encode(uint32_t cp, char *out);

static void on_winch(int sig) { (void)sig; resized = 1; }

static void query_size(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0) { tui_cols = ws.ws_col; tui_rows = ws.ws_row; }
    size_t n = (size_t)tui_cols * tui_rows;
    free(front); free(back);
    front = calloc(n, sizeof(Cell)); back = calloc(n, sizeof(Cell));
    for (size_t i = 0; i < n; i++) { front[i].ch = 0xffffffff; back[i].ch = ' '; back[i].fg = -1; back[i].bg = -1; }
    write(STDOUT_FILENO, "\x1b[2J", 4);
}

int tui_eof(void) { return at_eof; }
void tui_dump(FILE *f) {
    for (int y = 0; y < tui_rows; y++) {
        char line[4096]; int n = 0;
        for (int x = 0; x < tui_cols && n < 4000; x++) { uint32_t ch = back[y * tui_cols + x].ch; if (!ch) ch = ' '; n += utf8_encode(ch, line + n); }
        while (n > 0 && line[n - 1] == ' ') n--;
        line[n] = 0; fprintf(f, "%s\n", line);
    }
}

void tui_init(void) {
    if (getenv("ST_HEADLESS")) {
        headless = 1; tui_cols = getenv("ST_COLS") ? atoi(getenv("ST_COLS")) : 120; tui_rows = getenv("ST_ROWS") ? atoi(getenv("ST_ROWS")) : 40;
        size_t n = (size_t)tui_cols * tui_rows; front = calloc(n, sizeof(Cell)); back = calloc(n, sizeof(Cell));
        for (size_t i = 0; i < n; i++) { front[i].ch = 0xffffffff; back[i].ch = ' '; }
        initialized = 1; return;
    }
    tcgetattr(STDIN_FILENO, &orig_tio);
    struct termios t = orig_tio;
    t.c_lflag &= ~(ECHO | ICANON | ISIG | IEXTEN);
    t.c_iflag &= ~(IXON | ICRNL | BRKINT | INPCK | ISTRIP);
    t.c_oflag &= ~OPOST; t.c_cflag |= CS8;
    t.c_cc[VMIN] = 0; t.c_cc[VTIME] = 0;
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &t);
    const char *s = "\x1b[?1049h\x1b[?25l\x1b[?1000h\x1b[?1002h\x1b[?1006h";
    write(STDOUT_FILENO, s, strlen(s));
    signal(SIGWINCH, on_winch);
    query_size(); initialized = 1;
}
void tui_shutdown(void) {
    if (!initialized || headless) return;
    const char *s = "\x1b[?1006l\x1b[?1002l\x1b[?1000l\x1b[?25h\x1b[0m\x1b[?1049l";
    write(STDOUT_FILENO, s, strlen(s));
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_tio); initialized = 0;
}

int utf8_decode(const char *s, uint32_t *cp) {
    unsigned char c = (unsigned char)s[0];
    if (c < 0x80) { *cp = c; return 1; }
    if ((c & 0xe0) == 0xc0 && s[1]) { *cp = ((c & 0x1f) << 6) | (s[1] & 0x3f); return 2; }
    if ((c & 0xf0) == 0xe0 && s[1] && s[2]) { *cp = ((c & 0x0f) << 12) | ((s[1] & 0x3f) << 6) | (s[2] & 0x3f); return 3; }
    if ((c & 0xf8) == 0xf0 && s[1] && s[2] && s[3]) { *cp = ((c & 0x07) << 18) | ((s[1] & 0x3f) << 12) | ((s[2] & 0x3f) << 6) | (s[3] & 0x3f); return 4; }
    *cp = '?'; return 1;
}
static int utf8_encode(uint32_t cp, char *out) {
    if (cp < 0x80) { out[0] = (char)cp; return 1; }
    if (cp < 0x800) { out[0] = 0xc0 | (cp >> 6); out[1] = 0x80 | (cp & 0x3f); return 2; }
    if (cp < 0x10000) { out[0] = 0xe0 | (cp >> 12); out[1] = 0x80 | ((cp >> 6) & 0x3f); out[2] = 0x80 | (cp & 0x3f); return 3; }
    out[0] = 0xf0 | (cp >> 18); out[1] = 0x80 | ((cp >> 12) & 0x3f); out[2] = 0x80 | ((cp >> 6) & 0x3f); out[3] = 0x80 | (cp & 0x3f); return 4;
}
int tui_cell_width(uint32_t cp) { return (cp >= 0x1100 && (cp <= 0x115f || (cp >= 0x2e80 && cp <= 0xa4cf) || (cp >= 0xac00 && cp <= 0xd7a3) || (cp >= 0xf900 && cp <= 0xfaff) || (cp >= 0xfe30 && cp <= 0xfe4f) || (cp >= 0xff00 && cp <= 0xff60) || (cp >= 0x1f300 && cp <= 0x1faff))) ? 2 : 1; }

void tui_put(int x, int y, uint32_t ch, int fg, int bg, int attr) {
    if (x < 0 || y < 0 || x >= tui_cols || y >= tui_rows) return;
    Cell *c = &back[y * tui_cols + x]; c->ch = ch; c->fg = fg; c->bg = bg; c->attr = attr;
}
void tui_clear(int fg, int bg) { tui_fill(0, 0, tui_cols, tui_rows, ' ', fg, bg, 0); }
void tui_fill(int x, int y, int w, int h, uint32_t ch, int fg, int bg, int attr) {
    for (int j = y; j < y + h; j++) for (int i = x; i < x + w; i++) tui_put(i, j, ch, fg, bg, attr);
}
int tui_text(int x, int y, const char *s, int maxw, int fg, int bg, int attr) {
    int used = 0;
    while (*s && used < maxw) {
        uint32_t cp; int n = utf8_decode(s, &cp); s += n;
        if (cp == '\t') { int k = 4 - (used % 4); while (k-- && used < maxw) tui_put(x + used++, y, ' ', fg, bg, attr); continue; }
        if (cp < 32) cp = '?';
        tui_put(x + used, y, cp, fg, bg, attr); used += tui_cell_width(cp);
    }
    return used;
}
void tui_box(int x, int y, int w, int h, int fg, int bg, int attr) {
    if (w < 2 || h < 2) return;
    tui_put(x, y, 0x250c, fg, bg, attr); tui_put(x + w - 1, y, 0x2510, fg, bg, attr);
    tui_put(x, y + h - 1, 0x2514, fg, bg, attr); tui_put(x + w - 1, y + h - 1, 0x2518, fg, bg, attr);
    for (int i = 1; i < w - 1; i++) { tui_put(x + i, y, 0x2500, fg, bg, attr); tui_put(x + i, y + h - 1, 0x2500, fg, bg, attr); }
    for (int j = 1; j < h - 1; j++) { tui_put(x, y + j, 0x2502, fg, bg, attr); tui_put(x + w - 1, y + j, 0x2502, fg, bg, attr); }
}
void tui_set_cursor(int x, int y) { cur_x = x; cur_y = y; }

static char *obuf = NULL; static size_t olen = 0, ocap = 0;
static void out(const char *s, size_t n) { if (olen + n > ocap) { ocap = (olen + n) * 2 + 4096; obuf = realloc(obuf, ocap); } memcpy(obuf + olen, s, n); olen += n; }
static void outs(const char *s) { out(s, strlen(s)); }

void tui_flush(void) {
    olen = 0; outs("\x1b[?25l");
    int lfg = -2, lbg = -2, lattr = -1; int ly = -1, lx = -1;
    for (int y = 0; y < tui_rows; y++) for (int x = 0; x < tui_cols; x++) {
        Cell *b = &back[y * tui_cols + x], *f = &front[y * tui_cols + x];
        if (b->ch == f->ch && b->fg == f->fg && b->bg == f->bg && b->attr == f->attr) continue;
        if (ly != y || lx != x) { char m[32]; snprintf(m, sizeof m, "\x1b[%d;%dH", y + 1, x + 1); outs(m); }
        if (b->fg != lfg || b->bg != lbg || b->attr != lattr) {
            char m[64]; outs("\x1b[0");
            if (b->attr & ATTR_BOLD) outs(";1"); if (b->attr & ATTR_DIM) outs(";2"); if (b->attr & ATTR_UNDERLINE) outs(";4"); if (b->attr & ATTR_REVERSE) outs(";7");
            if (b->fg >= 0) { snprintf(m, sizeof m, ";38;5;%d", b->fg); outs(m); }
            if (b->bg >= 0) { snprintf(m, sizeof m, ";48;5;%d", b->bg); outs(m); }
            outs("m"); lfg = b->fg; lbg = b->bg; lattr = b->attr;
        }
        char u[4]; int n = utf8_encode(b->ch ? b->ch : ' ', u); out(u, n);
        *f = *b; lx = x + tui_cell_width(b->ch); ly = y;
        if (tui_cell_width(b->ch) == 2 && x + 1 < tui_cols) { front[y * tui_cols + x + 1] = back[y * tui_cols + x + 1]; x++; }
    }
    if (cur_x >= 0 && cur_y >= 0) { char m[32]; snprintf(m, sizeof m, "\x1b[%d;%dH\x1b[?25h", cur_y + 1, cur_x + 1); outs(m); }
    if (!headless) write(STDOUT_FILENO, obuf, olen);
}

/* ---------- input ---------- */
static unsigned char ibuf[256]; static int ilen = 0, ipos = 0;
static int fill(int timeout_ms) {
    if (ipos < ilen) return 1;
    if (at_eof) return 0;
    struct pollfd p = { STDIN_FILENO, POLLIN, 0 };
    if (poll(&p, 1, timeout_ms) <= 0) return 0;
    int n = read(STDIN_FILENO, ibuf, sizeof ibuf); if (n <= 0) { if (n == 0) at_eof = 1; return 0; }
    ilen = n; ipos = 0; return 1;
}
static int peekc(int timeout_ms) { return fill(timeout_ms) ? ibuf[ipos] : -1; }
static int getc_(int timeout_ms) { return fill(timeout_ms) ? ibuf[ipos++] : -1; }

static int parse_csi(Event *ev) {
    /* after ESC [ ; collect params until final byte */
    int params[8] = { 0 }; int np = 0; int lt = 0; int c; char final = 0; int have = 0;
    if (peekc(20) == '<') { lt = 1; getc_(20); }
    for (;;) {
        c = getc_(20); if (c < 0) return 0;
        if (c >= '0' && c <= '9') { if (np < 8) params[np] = params[np] * 10 + (c - '0'); have = 1; }
        else if (c == ';') { if (np < 7) np++; have = 0; }
        else { final = (char)c; break; }
    }
    if (have || np) np++;
    if (lt) {
        int b = params[0], x = params[1] - 1, y = params[2] - 1;
        ev->x = x; ev->y = y; ev->mods = ((b & 4) ? MOD_SHIFT : 0) | ((b & 8) ? MOD_ALT : 0) | ((b & 16) ? MOD_CTRL : 0);
        if (b & 64) { ev->type = (b & 1) ? EV_WHEEL_DOWN : EV_WHEEL_UP; ev->button = -1; return 1; }
        ev->button = b & 3;
        if (b & 32) ev->type = ev->button == 3 ? EV_MOUSE_MOVE : EV_MOUSE_DRAG;
        else ev->type = final == 'M' ? EV_MOUSE_DOWN : EV_MOUSE_UP;
        return 1;
    }
    ev->type = EV_KEY; int mod = np >= 2 ? params[1] - 1 : 0;
    ev->mods = ((mod & 1) ? MOD_SHIFT : 0) | ((mod & 2) ? MOD_ALT : 0) | ((mod & 4) ? MOD_CTRL : 0);
    switch (final) {
    case 'A': ev->key = KEY_UP; return 1; case 'B': ev->key = KEY_DOWN; return 1;
    case 'C': ev->key = KEY_RIGHT; return 1; case 'D': ev->key = KEY_LEFT; return 1;
    case 'H': ev->key = KEY_HOME; return 1; case 'F': ev->key = KEY_END; return 1;
    case 'Z': ev->key = 9; ev->mods |= MOD_SHIFT; return 1;
    case '~':
        switch (params[0]) { case 1: case 7: ev->key = KEY_HOME; return 1; case 4: case 8: ev->key = KEY_END; return 1;
        case 2: ev->key = KEY_INS; return 1; case 3: ev->key = KEY_DEL; return 1; case 5: ev->key = KEY_PGUP; return 1; case 6: ev->key = KEY_PGDN; return 1; }
        return 0;
    }
    return 0;
}

int tui_read_event(Event *ev, int timeout_ms) {
    memset(ev, 0, sizeof *ev);
    if (resized) { resized = 0; query_size(); ev->type = EV_RESIZE; return 1; }
    int c = getc_(timeout_ms);
    if (c < 0) {
        if (resized) { resized = 0; query_size(); ev->type = EV_RESIZE; return 1; }
        if (at_eof) { ev->type = EV_KEY; ev->key = 27; return 1; }   /* at end of scripted input every read is Escape */
        return 0;
    }
    if (c == 27) {
        int n = peekc(30);
        if (n < 0) { ev->type = EV_KEY; ev->key = 27; return 1; }
        if (n == '[') { getc_(0); if (parse_csi(ev)) return 1; return tui_read_event(ev, timeout_ms); }
        if (n == 'O') { getc_(0); int k = getc_(20); ev->type = EV_KEY;
            switch (k) { case 'A': ev->key = KEY_UP; break; case 'B': ev->key = KEY_DOWN; break; case 'C': ev->key = KEY_RIGHT; break; case 'D': ev->key = KEY_LEFT; break;
            case 'H': ev->key = KEY_HOME; break; case 'F': ev->key = KEY_END; break; default: ev->key = 27; } return 1; }
        /* alt + key */
        getc_(0); ev->type = EV_KEY; ev->key = n; ev->mods = MOD_ALT; return 1;
    }
    ev->type = EV_KEY;
    if (c >= 0x80) {
        char s[5] = { (char)c, 0, 0, 0, 0 }; int need = (c & 0xe0) == 0xc0 ? 1 : (c & 0xf0) == 0xe0 ? 2 : 3;
        for (int i = 0; i < need; i++) { int d = getc_(20); if (d < 0) break; s[i + 1] = (char)d; }
        uint32_t cp; utf8_decode(s, &cp); ev->key = (int)cp; return 1;
    }
    if (c < 32 && c != 9 && c != 13 && c != 10) { ev->key = c + 96; ev->mods = MOD_CTRL; if (c == 0) { ev->key = ' '; } return 1; }
    if (c == 10) c = 13;
    ev->key = c; return 1;
}
