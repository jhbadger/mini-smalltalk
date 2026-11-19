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
    fprintf(stderr, "usage: st [-e 'expression'] [-f file.st] [-c changes.st] [-k kerneldir] [-i file.image] [-n] [-l package]\n"
                    "  starts from an image when there is one: st.image in the current directory (your project's),\n"
                    "  else kernel.image next to the executable; otherwise the kernel sources are read from the\n"
                    "  executable's directory.  -i file starts from that image, -n and -k never use an image.\n"
                    "  -l package loads an optional system from the packages/ folder (e.g. -l Prolog).\n"
                    "  the changes file and -f files are relative to the current directory.\n"
                    "  with no -e, starts the interactive TUI environment\n");
    exit(1);
}

/* modification time of the newest kernelN.st in dir (0 if there are none) */
static time_t newest_kernel_source(const char *dir) {
    time_t newest = 0;
    for (int i = 1; i < 100; i++) {
        char path[PATH_MAX + 32]; snprintf(path, sizeof path, "%s/kernel%d.st", dir, i);
        time_t m = image_mtime(path); if (!m) break;
        if (m > newest) newest = m;
    }
    return newest;
}
static void show_background_error(void) {
    if (tools_open_debugger()) return;
    char *buf = malloc(strlen(interp.error) + strlen(interp.walkback) + 64);
    sprintf(buf, "%s\n\n%s", interp.error, interp.walkback);
    char title[200]; snprintf(title, sizeof title, "Error in background process: %.120s", interp.error);
    dialog_text(title, buf); free(buf); interp.failed = false;
}

int main(int argc, char **argv) {
    const char *kdir = NULL; const char **evals = NULL; int nevals = 0; const char **files = NULL; int nfiles = 0;
    const char *image_arg = NULL; bool no_image = false; const char **packages = NULL; int npackages = 0; char notice[2048] = "";
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-e") && i + 1 < argc) { evals = realloc(evals, (nevals + 1) * sizeof(char *)); evals[nevals++] = argv[++i]; }
        else if (!strcmp(argv[i], "-f") && i + 1 < argc) { files = realloc(files, (nfiles + 1) * sizeof(char *)); files[nfiles++] = argv[++i]; }
        else if (!strcmp(argv[i], "-c") && i + 1 < argc) changes_path = argv[++i];
        else if (!strcmp(argv[i], "-k") && i + 1 < argc) kdir = argv[++i];
        else if (!strcmp(argv[i], "-i") && i + 1 < argc) image_arg = argv[++i];
        else if (!strcmp(argv[i], "-n")) no_image = true;
        else if (!strcmp(argv[i], "-l") && i + 1 < argc) { packages = realloc(packages, (npackages + 1) * sizeof(char *)); packages[npackages++] = argv[++i]; }
        else usage();
    }
    char exedir[PATH_MAX]; executable_dir(argv[0], exedir, sizeof exedir);
    char err[512];
    bool kdir_given = kdir != NULL;
    if (!kdir) {   /* default: next to the executable, else the current directory */
        char probe[PATH_MAX + 32]; snprintf(probe, sizeof probe, "%s/kernel1.st", exedir);
        kdir = access(probe, R_OK) == 0 ? exedir : ".";
    }
    kernel_dir = kdir;
    /* an image replaces st_init() and the kernel sources */
    bool loaded = false;
    if (image_arg) {
        if (!image_load(image_arg, err, sizeof err)) { fprintf(stderr, "st: %s\n", err); return 1; }
        loaded = true; image_path = image_arg;
    } else if (!no_image && !kdir_given) {
        char base[PATH_MAX + 32]; snprintf(base, sizeof base, "%s/kernel.image", exedir);
        const char *candidates[2] = { "st.image", base };
        time_t sources = newest_kernel_source(kdir);
        for (int i = 0; i < 2 && !loaded; i++) {
            time_t m = image_mtime(candidates[i]);
            if (!m) continue;
            if (sources && m < sources) {
                char msg[1024]; snprintf(msg, sizeof msg, "The image %s is older than the kernel sources in %s, so it was NOT used and the kernel was loaded from source.\n%s",
                    candidates[i], kdir, i == 0 ? "It still holds the work you saved: start with  st -i st.image  to load it anyway." : "Rebuild it with  make image.");
                fprintf(stderr, "st: %s\n", msg); if (!notice[0]) snprintf(notice, sizeof notice, "%s", msg);
                continue;
            }
            if (image_load(candidates[i], err, sizeof err)) { loaded = true; if (i == 0) image_path = candidates[0]; }
            else {
                char msg[1024]; snprintf(msg, sizeof msg, "Cannot use the image %s: %s.\nThe kernel was loaded from source instead.", candidates[i], err);
                fprintf(stderr, "st: %s\n", msg); if (!notice[0]) snprintf(notice, sizeof notice, "%s", msg);
                if (heap_head()) break;   /* a damaged image may have left objects behind: do not try another */
            }
        }
    }
    if (!loaded) {
        st_init();
        if (!load_kernel(kdir, err, sizeof err)) {
            fprintf(stderr, "%s\n", err);
            if (!strncmp(err, "cannot open", 11)) { fprintf(stderr, "kernel sources (kernel1.st ...) not found in %s; use -k to point at the source directory\n", kdir); return 1; }
        }
    }
    gc_add_root(&pending_inspect);
    for (int i = 0; i < npackages; i++) {
        oop name = new_string(packages[i]);
        interp_send(smalltalk, new_symbol("loadPackage:"), &name, 1);
        if (interp.failed) { fprintf(stderr, "st: cannot load package %s: %s\n", packages[i], interp.error); interp.failed = false; }
    }
    if (access(changes_path, R_OK) == 0 && !file_in(changes_path, err, sizeof err)) fprintf(stderr, "%s: %s\n", changes_path, err);
    for (int i = 0; i < nfiles; i++) if (!file_in(files[i], err, sizeof err)) fprintf(stderr, "%s: %s\n", files[i], err);
    if (nevals) {
        for (int i = 0; i < nevals; i++) {
            oop r = interp_eval(nilobj, evals[i], err, sizeof err);
            if (interp.failed) { printf("Error: %s\n%s", interp.error, interp.walkback); interp.failed = false; }
            else { char *s = str_cstr(interp_print_string(r)); printf("%s\n", s); free(s); }
            if (pending_window_text) { printf("---- %s ----\n%s\n", pending_window_title, pending_window_text); free(pending_window_title); free(pending_window_text); pending_window_title = pending_window_text = NULL; }
        }
        if (transcript_len) fputs(transcript_text, stdout);
        return 0;
    }
    bool headless = getenv("ST_HEADLESS") != NULL;
    if (!headless && !isatty(STDIN_FILENO)) { fprintf(stderr, "st: stdin is not a terminal; use -e to evaluate expressions\n"); return 1; }
    changes_logging = true;   /* from here on every class, method and removal is appended to the changes file */
    tui_init();
    tools_system_menu_install();
    /* initial desk: browser across the top, workspace bottom-left, transcript bottom-right */
    int bh = (tui_rows - 1) * 3 / 5; if (bh < 12) bh = 12;
    open_transcript(); win_top()->r = (Rect){ tui_cols / 2 + 1, bh + 1, tui_cols - tui_cols / 2 - 2, tui_rows - bh - 3 };
    open_workspace(); win_top()->r = (Rect){ 1, bh + 1, tui_cols / 2 - 1, tui_rows - bh - 3 };
    open_browser(); win_top()->r = (Rect){ 1, 0, tui_cols - 2, bh };
    win_raise(windows[1]);   /* workspace in front, ready for typing */
    if (notice[0]) dialog_text("Image not used", notice);
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
            char qmsg[1200]; snprintf(qmsg, sizeof qmsg, "Quit Smalltalk?  Code changes are saved in %s", changes_abs_path());
            if (dialog_confirm("Quit", qmsg)) break; else continue;
        }
        ui_handle(&ev);
        tools_after_eval();
    }
    tui_shutdown();
    return 0;
}
