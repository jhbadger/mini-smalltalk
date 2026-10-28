/* main.c - Mini Smalltalk-80 TUI entry point */
#include "st.h"
#include "ui.h"
#include "tools.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif

extern oop pending_inspect;
extern bool quit_requested;

/* directory containing the running executable (symlinks resolved); falls back to argv[0]'s directory, then "." */
static void executable_dir(const char *argv0, char *out, size_t outlen) {
    char path[PATH_MAX] = "";
#ifdef __APPLE__
    uint32_t n = sizeof path;
    if (_NSGetExecutablePath(path, &n) != 0) path[0] = 0;
#else
    ssize_t n = readlink("/proc/self/exe", path, sizeof path - 1);
    if (n > 0) path[n] = 0; else path[0] = 0;
#endif
    if (!path[0]) snprintf(path, sizeof path, "%s", argv0);
    char real[PATH_MAX];
    if (realpath(path, real)) snprintf(path, sizeof path, "%s", real);
    char *slash = strrchr(path, '/');
    if (slash) { *slash = 0; snprintf(out, outlen, "%s", path[0] ? path : "/"); }
    else snprintf(out, outlen, ".");
}

static void usage(void) {
    fprintf(stderr, "usage: st [-e 'expression'] [-f file.st] [-c changes.st] [-k kerneldir]\n"
                    "  kernel sources are read from the executable's directory unless -k is given;\n"
                    "  the changes file and -f files are relative to the current directory.\n"
                    "  with no -e, starts the interactive TUI environment\n");
    exit(1);
}
static void show_background_error(void) {
    char *buf = malloc(strlen(interp.error) + strlen(interp.walkback) + 64);
    sprintf(buf, "%s\n\n%s", interp.error, interp.walkback);
    char title[200]; snprintf(title, sizeof title, "Error in background process: %.120s", interp.error);
    dialog_text(title, buf); free(buf); interp.failed = false;
}

int main(int argc, char **argv) {
    const char *kdir = NULL; const char **evals = NULL; int nevals = 0; const char **files = NULL; int nfiles = 0;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-e") && i + 1 < argc) { evals = realloc(evals, (nevals + 1) * sizeof(char *)); evals[nevals++] = argv[++i]; }
        else if (!strcmp(argv[i], "-f") && i + 1 < argc) { files = realloc(files, (nfiles + 1) * sizeof(char *)); files[nfiles++] = argv[++i]; }
        else if (!strcmp(argv[i], "-c") && i + 1 < argc) changes_path = argv[++i];
        else if (!strcmp(argv[i], "-k") && i + 1 < argc) kdir = argv[++i];
        else usage();
    }
    char exedir[PATH_MAX]; executable_dir(argv[0], exedir, sizeof exedir);
    st_init();
    gc_add_root(&pending_inspect);
    char err[512];
    if (!kdir) {   /* default: next to the executable, else the current directory */
        char probe[PATH_MAX + 32]; snprintf(probe, sizeof probe, "%s/kernel1.st", exedir);
        kdir = access(probe, R_OK) == 0 ? exedir : ".";
    }
    if (!load_kernel(kdir, err, sizeof err)) {
        fprintf(stderr, "%s\n", err);
        if (!strncmp(err, "cannot open", 11)) { fprintf(stderr, "kernel sources (kernel1.st ...) not found in %s; use -k to point at the source directory\n", kdir); return 1; }
    }
    if (access(changes_path, R_OK) == 0 && !file_in(changes_path, err, sizeof err)) fprintf(stderr, "%s: %s\n", changes_path, err);
    for (int i = 0; i < nfiles; i++) if (!file_in(files[i], err, sizeof err)) fprintf(stderr, "%s: %s\n", files[i], err);
    if (nevals) {
        for (int i = 0; i < nevals; i++) {
            oop r = interp_eval(nilobj, evals[i], err, sizeof err);
            if (interp.failed) { printf("Error: %s\n%s", interp.error, interp.walkback); interp.failed = false; }
            else { char *s = str_cstr(interp_print_string(r)); printf("%s\n", s); free(s); }
        }
        if (transcript_len) fputs(transcript_text, stdout);
        return 0;
    }
    bool headless = getenv("ST_HEADLESS") != NULL;
    if (!headless && !isatty(STDIN_FILENO)) { fprintf(stderr, "st: stdin is not a terminal; use -e to evaluate expressions\n"); return 1; }
    tui_init();
    tools_system_menu_install();
    /* initial desk: browser across the top, workspace bottom-left, transcript bottom-right */
    int bh = (tui_rows - 1) * 3 / 5; if (bh < 12) bh = 12;
    open_transcript(); win_top()->r = (Rect){ tui_cols / 2 + 1, bh + 1, tui_cols - tui_cols / 2 - 2, tui_rows - bh - 3 };
    open_workspace(); win_top()->r = (Rect){ 1, bh + 1, tui_cols / 2 - 1, tui_rows - bh - 3 };
    open_browser(); win_top()->r = (Rect){ 1, 0, tui_cols - 2, bh };
    win_raise(windows[1]);   /* workspace in front, ready for typing */
    Event ev;
    while (!ui_quit && !quit_requested) {
        ui_draw(); tui_flush();
        if (headless && tui_eof()) { tui_dump(stdout); break; }
        bool busy = interp_has_background();
        if (!tui_read_event(&ev, busy ? 10 : 250)) {
            if (busy && interp_run_background(30)) { if (interp.failed) { show_background_error(); } tools_after_eval(); }
            continue;
        }
        if (ev.type == EV_KEY && (ev.mods & MOD_CTRL) && ev.key == 'q') {
            if (dialog_confirm("Quit", "Quit Smalltalk? (changes are already logged to the changes file)")) break; else continue;
        }
        ui_handle(&ev);
        tools_after_eval();
    }
    tui_shutdown();
    return 0;
}
