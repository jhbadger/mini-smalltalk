/* tools.h - the Smalltalk-80 programming tools built on the window system */
#ifndef TOOLS_H
#define TOOLS_H
#include "st.h"
void open_browser(void);
void open_browser_on(const char *className);
void open_workspace(void);
void open_transcript(void);
void open_inspector(oop obj);
void tools_after_eval(void);          /* refresh transcript windows, open pending inspectors, update browsers */
void tools_system_menu_install(void);
extern bool ui_quit;
extern const char *kernel_dir;        /* where kernel*.st and tutorial.st live */
#endif
