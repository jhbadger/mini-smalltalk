/* main.c - Mini Smalltalk-80 TUI entry point */
#include "st.h"
#include "ui.h"
#include "tools.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern oop pending_inspect;
extern bool quit_requested;

static void usage(void) {
    fprintf(stderr, "usage: st [-e 'expression'] [-f file.st] [-c changes.st] [-k kerneldir]\n"
                    "  with no -e, starts the interactive TUI environment\n");
    exit(1);
}

int main(int argc, char **argv) {
    const char *kdir = "."; const char **evals = NULL; int nevals = 0; const char **files = NULL; int nfiles = 0;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-e") && i + 1 < argc) { evals = realloc(evals, (nevals + 1) * sizeof(char *)); evals[nevals++] = argv[++i]; }
        else if (!strcmp(argv[i], "-f") && i + 1 < argc) { files = realloc(files, (nfiles + 1) * sizeof(char *)); files[nfiles++] = argv[++i]; }
        else if (!strcmp(argv[i], "-c") && i + 1 < argc) changes_path = argv[++i];
        else if (!strcmp(argv[i], "-k") && i + 1 < argc) kdir = argv[++i];
        else usage();
    }
    st_init();
    gc_add_root(&pending_inspect);
    char err[512]; char path[1024];
    const char *kernels[] = { "kernel1.st", "kernel2.st", "kernel3.st" };
    for (int i = 0; i < 3; i++) {
        snprintf(path, sizeof path, "%s/%s", kdir, kernels[i]);
        if (!file_in(path, err, sizeof err)) { fprintf(stderr, "%s: %s\n", path, err); if (access(path, R_OK)) { fprintf(stderr, "kernel sources not found; use -k to point at the source directory\n"); return 1; } }
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
        if (!tui_read_event(&ev, 250)) continue;
        if (ev.type == EV_KEY && (ev.mods & MOD_CTRL) && ev.key == 'q') {
            if (dialog_confirm("Quit", "Quit Smalltalk? (changes are already logged to the changes file)")) break; else continue;
        }
        ui_handle(&ev);
        tools_after_eval();
    }
    tui_shutdown();
    return 0;
}
