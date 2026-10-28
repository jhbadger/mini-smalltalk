/* interp.c - bytecode interpreter with heap-allocated contexts and a cooperative process scheduler */
#include "st.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>

Interp interp;

/* ---------- method cache ---------- */
#define CACHE_SIZE 2048
static struct { oop cls, sel, method; } cache[CACHE_SIZE];
void interp_flush_cache(void) { memset(cache, 0, sizeof cache); }
static oop cached_lookup(oop cls, oop sel) {
    unsigned i = (((uintptr_t)cls >> 4) ^ ((uintptr_t)sel >> 3)) & (CACHE_SIZE - 1);
    if (cache[i].cls == cls && cache[i].sel == sel) return cache[i].method;
    oop m = lookup_method(cls, sel);
    if (m) { cache[i].cls = cls; cache[i].sel = sel; cache[i].method = m; }
    return m;
}

static oop new_context(oop method, oop receiver, oop sender, oop home, oop outer) {
    oop h = SLOT(method, M_HEADER);
    int ntemps = HDR_TEMPS(h), nstack = HDR_STACK(h);
    oop ctx = new_object(home != nilobj ? classBlockContext : classMethodContext, ntemps + nstack);
    SLOT(ctx, CTX_SENDER) = sender; SLOT(ctx, CTX_PC) = MK_INT(0); SLOT(ctx, CTX_SP) = MK_INT(CTX_FIXED + ntemps);
    SLOT(ctx, CTX_METHOD) = method; SLOT(ctx, CTX_RECEIVER) = receiver; SLOT(ctx, CTX_HOME) = home; SLOT(ctx, CTX_OUTER) = outer;
    return ctx;
}

static void describe_context(oop ctx, char *buf, int len) {
    oop method = SLOT(ctx, CTX_METHOD);
    oop home = SLOT(ctx, CTX_HOME);
    oop m = home != nilobj ? SLOT(home, CTX_METHOD) : method;
    oop sel = SLOT(m, M_SELECTOR);
    oop rc = CLASS_OF(SLOT(ctx, CTX_RECEIVER));
    char *rn = str_cstr(class_name_of(rc)); char *mn = str_cstr(class_name_of(SLOT(m, M_CLASS))); char *sn = str_cstr(sel == nilobj ? new_string("?") : sel);
    if (rc == SLOT(m, M_CLASS)) snprintf(buf, len, "%s%s>>%s", home != nilobj ? "[] in " : "", rn, sn);
    else snprintf(buf, len, "%s%s(%s)>>%s", home != nilobj ? "[] in " : "", rn, mn, sn);
    free(rn); free(mn); free(sn);
}

void interp_signal_error(const char *msg) {
    if (interp.failed) return;
    interp.failed = true;
    snprintf(interp.error, sizeof interp.error, "%s", msg);
    interp.walkback[0] = 0;
    int n = 0;
    for (oop c = interp.active; c && c != nilobj && n < 60; c = SLOT(c, CTX_SENDER), n++) {
        char line[512]; describe_context(c, line, sizeof line);
        if (strlen(interp.walkback) + strlen(line) + 2 < sizeof interp.walkback) { strcat(interp.walkback, line); strcat(interp.walkback, "\n"); }
    }
}

/* ---------- processes: linked lists, run queues, delays ---------- */
static long now_ms(void) { struct timeval tv; gettimeofday(&tv, NULL); return tv.tv_sec * 1000L + tv.tv_usec / 1000; }
static void ll_add_last(oop list, oop p) {
    SLOT(p, PR_LIST) = list; SLOT(p, PR_NEXT) = nilobj;
    if (SLOT(list, LL_FIRST) == nilobj) SLOT(list, LL_FIRST) = p; else SLOT(SLOT(list, LL_LAST), PR_NEXT) = p;
    SLOT(list, LL_LAST) = p;
}
static void ll_add_first(oop list, oop p) {
    SLOT(p, PR_LIST) = list; SLOT(p, PR_NEXT) = SLOT(list, LL_FIRST); SLOT(list, LL_FIRST) = p;
    if (SLOT(list, LL_LAST) == nilobj) SLOT(list, LL_LAST) = p;
}
static oop ll_remove_first(oop list) {
    oop p = SLOT(list, LL_FIRST); if (p == nilobj) return nilobj;
    SLOT(list, LL_FIRST) = SLOT(p, PR_NEXT); if (SLOT(list, LL_FIRST) == nilobj) SLOT(list, LL_LAST) = nilobj;
    SLOT(p, PR_NEXT) = nilobj; SLOT(p, PR_LIST) = nilobj; return p;
}
static void ll_remove(oop list, oop p) {
    oop prev = nilobj;
    for (oop q = SLOT(list, LL_FIRST); q != nilobj; prev = q, q = SLOT(q, PR_NEXT)) {
        if (q != p) continue;
        if (prev == nilobj) SLOT(list, LL_FIRST) = SLOT(q, PR_NEXT); else SLOT(prev, PR_NEXT) = SLOT(q, PR_NEXT);
        if (SLOT(list, LL_LAST) == q) SLOT(list, LL_LAST) = prev;
        SLOT(q, PR_NEXT) = nilobj; SLOT(q, PR_LIST) = nilobj; return;
    }
}
static int proc_prio(oop p) { oop v = SLOT(p, PR_PRIORITY); int pr = IS_INT(v) ? (int)INT_VAL(v) : 4; return pr < 1 ? 1 : pr > NUM_PRIORITIES ? NUM_PRIORITIES : pr; }
static oop run_queue(int prio) { return SLOT(SLOT(processor, PS_LISTS), prio - 1); }
static void make_runnable(oop p) { ll_add_last(run_queue(proc_prio(p)), p); }

#define MAX_DELAYS 128
static oop delay_procs = NULL; static long delay_wake[MAX_DELAYS];
static void delays_init(void) { if (!delay_procs) { delay_procs = new_array(MAX_DELAYS); gc_add_root(&delay_procs); } }
static bool add_delay(oop p, long wake) {
    delays_init();
    for (int i = 0; i < MAX_DELAYS; i++) if (SLOT(delay_procs, i) == nilobj) { SLOT(delay_procs, i) = p; delay_wake[i] = wake; return true; }
    return false;
}
static void remove_delay(oop p) { if (delay_procs) for (int i = 0; i < MAX_DELAYS; i++) if (SLOT(delay_procs, i) == p) SLOT(delay_procs, i) = nilobj; }
/* make due processes runnable; return the earliest pending wake time or -1 */
static long wake_delays(void) {
    if (!delay_procs) return -1;
    long now = now_ms(), earliest = -1;
    for (int i = 0; i < MAX_DELAYS; i++) {
        oop p = SLOT(delay_procs, i); if (p == nilobj) continue;
        if (delay_wake[i] <= now) { SLOT(delay_procs, i) = nilobj; make_runnable(p); }
        else if (earliest < 0 || delay_wake[i] < earliest) earliest = delay_wake[i];
    }
    return earliest;
}
static oop pick_runnable(void) {
    wake_delays();
    for (int prio = NUM_PRIORITIES; prio >= 1; prio--) { oop q = run_queue(prio); if (SLOT(q, LL_FIRST) != nilobj) return ll_remove_first(q); }
    return NULL;
}
bool interp_has_background(void) {
    for (int prio = 1; prio <= NUM_PRIORITIES; prio++) if (SLOT(run_queue(prio), LL_FIRST) != nilobj) return true;
    if (delay_procs) for (int i = 0; i < MAX_DELAYS; i++) if (SLOT(delay_procs, i) != nilobj) return true;
    return false;
}

/* run bytecodes. base: the context whose return ends this run (NULL = background slice for forked processes).
   deadline: wall-clock ms after which a background slice is preempted (0 = never). */
static oop run(oop base, long deadline) {
    static int trace = -1; if (trace < 0) trace = getenv("ST_TRACE") != NULL;
    oop saved = interp.active; gc_add_root(&saved);
    oop owner = SLOT(processor, PS_ACTIVE); gc_add_root(&owner);
    interp.failed = false;
    oop ctx = NULL, method = NULL, rcvr = NULL, lits = NULL; unsigned char *code = NULL; int pc = 0, sp = 0; oop *slots = NULL; oop result = nilobj;
    bool need_switch = base == NULL; unsigned icount = 0;
#define LOAD() do { ctx = interp.active; method = SLOT(ctx, CTX_METHOD); rcvr = SLOT(ctx, CTX_RECEIVER); lits = SLOT(method, M_LITERALS); \
        code = BYTES(SLOT(method, M_BYTECODES)); pc = (int)INT_VAL(SLOT(ctx, CTX_PC)); sp = (int)INT_VAL(SLOT(ctx, CTX_SP)); slots = ctx->slots; } while (0)
#define SAVE() do { SLOT(ctx, CTX_PC) = MK_INT(pc); SLOT(ctx, CTX_SP) = MK_INT(sp); } while (0)
#define PUSH(v) (slots[sp++] = (v))
#define POP() (slots[--sp])
#define CUR() SLOT(processor, PS_ACTIVE)
#define PARK_CURRENT() do { SAVE(); SLOT(CUR(), PR_CONTEXT) = ctx; } while (0)   /* save the running process so it can be resumed */
    if (base) { interp.active = base; LOAD(); }
    oop sel = nilobj; int n = 0, super = 0;
    for (;;) {
        if (need_switch) { need_switch = false; goto switch_process; }
        if (gc_alloc_since > gc_threshold) { SAVE(); gc_collect(); LOAD(); }
        if (deadline && (++icount & 1023) == 0 && now_ms() > deadline) {   /* preempt the background slice */
            PARK_CURRENT(); ll_add_first(run_queue(proc_prio(CUR())), CUR()); CUR() = main_process; result = nilobj; goto done;
        }
        int op = code[pc++];
        switch (op) {
        case OP_PUSH_INST: PUSH(SLOT(rcvr, code[pc++])); break;
        case OP_PUSH_TEMP: PUSH(slots[CTX_FIXED + code[pc++]]); break;
        case OP_PUSH_OUTER: { int d = code[pc++], i = code[pc++]; oop c = ctx; while (d--) c = SLOT(c, CTX_OUTER); PUSH(SLOT(c, CTX_FIXED + i)); break; }
        case OP_PUSH_LIT: PUSH(SLOT(lits, code[pc++])); break;
        case OP_PUSH_GLOBAL: PUSH(SLOT(SLOT(lits, code[pc++]), A_VALUE)); break;
        case OP_PUSH_SELF: PUSH(rcvr); break;
        case OP_PUSH_NIL: PUSH(nilobj); break;
        case OP_PUSH_TRUE: PUSH(trueobj); break;
        case OP_PUSH_FALSE: PUSH(falseobj); break;
        case OP_PUSH_INT: PUSH(MK_INT((signed char)code[pc++])); break;
        case OP_PUSH_CONTEXT: SAVE(); PUSH(ctx); break;
        case OP_STORE_INST: SLOT(rcvr, code[pc++]) = slots[sp - 1]; break;
        case OP_STORE_TEMP: slots[CTX_FIXED + code[pc++]] = slots[sp - 1]; break;
        case OP_STORE_OUTER: { int d = code[pc++], i = code[pc++]; oop c = ctx; while (d--) c = SLOT(c, CTX_OUTER); SLOT(c, CTX_FIXED + i) = slots[sp - 1]; break; }
        case OP_STORE_GLOBAL: SLOT(SLOT(lits, code[pc++]), A_VALUE) = slots[sp - 1]; break;
        case OP_POP: sp--; break;
        case OP_DUP: { oop t = slots[sp - 1]; PUSH(t); break; }
        case OP_JUMP: { int off = (int16_t)((code[pc] << 8) | code[pc + 1]); pc += 2 + off; break; }
        case OP_JUMP_FALSE: case OP_JUMP_TRUE: {
            int off = (int16_t)((code[pc] << 8) | code[pc + 1]); pc += 2; oop v = POP();
            if (v == (op == OP_JUMP_FALSE ? falseobj : trueobj)) pc += off;
            else if (v != trueobj && v != falseobj) { SAVE(); interp_signal_error("NonBoolean receiver"); goto abort; }
            break; }
        case OP_PUSH_BLOCK: {
            oop bm = SLOT(lits, code[pc++]);
            oop b = new_object(classBlockClosure, 0);
            SLOT(b, B_OUTER) = ctx; SLOT(b, B_METHOD) = bm; SLOT(b, B_RECEIVER) = rcvr; SLOT(b, B_NUMARGS) = MK_INT(HDR_ARGS(SLOT(bm, M_HEADER)));
            PUSH(b); break; }
        case OP_RETURN: {
            oop v = POP(); oop target; oop origin = ctx;
            if (SLOT(ctx, CTX_HOME) == nilobj) { target = SLOT(ctx, CTX_SENDER); SLOT(ctx, CTX_PC) = MK_INT(-1); }
            else {
                oop home = SLOT(ctx, CTX_HOME); origin = home;
                if (INT_VAL(SLOT(home, CTX_PC)) < 0) { SAVE(); interp_signal_error("Block cannot return: home context has already returned"); goto abort; }
                target = SLOT(home, CTX_SENDER); SLOT(home, CTX_PC) = MK_INT(-1);
            }
            if (base && origin == base) { result = v; goto done; }
            if (target == nilobj) { SLOT(CUR(), PR_CONTEXT) = nilobj; goto switch_process; }   /* a forked process finished */
            interp.active = target; LOAD(); PUSH(v); break; }
        case OP_BLOCK_RETURN: {
            oop v = POP(); oop target = SLOT(ctx, CTX_SENDER);
            if (base && ctx == base) { result = v; goto done; }
            if (target == nilobj) { SLOT(CUR(), PR_CONTEXT) = nilobj; goto switch_process; }
            interp.active = target; LOAD(); PUSH(v); break; }
        case OP_SEND: sel = SLOT(lits, code[pc++]); n = code[pc++]; super = 0; goto send;
        case OP_SUPER_SEND: sel = SLOT(lits, code[pc++]); n = code[pc++]; super = 1; goto send;
        default: SAVE(); interp_signal_error("bad bytecode"); goto abort;
        }
        continue;
    send: {
            oop recv = slots[sp - n - 1];
            oop cls = super ? SLOT(SLOT(method, M_CLASS), C_SUPER) : CLASS_OF(recv);
            if (trace) { char *cn = str_cstr(class_name_of(cls)); char *sn = str_cstr(sel); fprintf(stderr, "send %s>>%s\n", cn, sn); free(cn); free(sn); }
            oop m = cached_lookup(cls, sel);
            if (!m) {
                oop args = new_array(n); for (int i = 0; i < n; i++) SLOT(args, i) = slots[sp - n + i];
                oop msg = new_object(classMessage, 0); SLOT(msg, MSG_SELECTOR) = sel; SLOT(msg, MSG_ARGS) = args;
                sp -= n; PUSH(msg); n = 1; sel = symDoesNotUnderstand;
                m = cached_lookup(cls, sel);
                if (!m) {
                    char buf[300]; char *s = str_cstr(SLOT(msg, MSG_SELECTOR)); char *cn = str_cstr(class_name_of(cls));
                    snprintf(buf, sizeof buf, "%s does not understand #%s", cn, s); free(s); free(cn);
                    SAVE(); interp_signal_error(buf); goto abort;
                }
            }
            int prim = (int)INT_VAL(SLOT(m, M_PRIM));
            if (prim) {
                if (prim == 80) {            /* block value family */
                    if (CLASS_OF(recv) == classBlockClosure && INT_VAL(SLOT(recv, B_NUMARGS)) == n) {
                        SAVE();
                        oop outer = SLOT(recv, B_OUTER);
                        oop home = SLOT(outer, CTX_HOME) != nilobj ? SLOT(outer, CTX_HOME) : outer;
                        oop nctx = new_context(SLOT(recv, B_METHOD), SLOT(recv, B_RECEIVER), ctx, home, outer);
                        for (int i = 0; i < n; i++) SLOT(nctx, CTX_FIXED + i) = slots[sp - n + i];
                        sp -= n + 1; SAVE(); interp.active = nctx; LOAD(); continue;
                    }
                } else if (prim == 81) {     /* valueWithArguments: */
                    oop arr = slots[sp - 1];
                    if (CLASS_OF(recv) == classBlockClosure && !IS_INT(arr) && arr->cls == classArray && (int)arr->size == INT_VAL(SLOT(recv, B_NUMARGS))) {
                        SAVE();
                        oop outer = SLOT(recv, B_OUTER);
                        oop home = SLOT(outer, CTX_HOME) != nilobj ? SLOT(outer, CTX_HOME) : outer;
                        oop nctx = new_context(SLOT(recv, B_METHOD), SLOT(recv, B_RECEIVER), ctx, home, outer);
                        for (uint32_t i = 0; i < arr->size; i++) SLOT(nctx, CTX_FIXED + i) = SLOT(arr, i);
                        sp -= 2; SAVE(); interp.active = nctx; LOAD(); continue;
                    }
                } else if (prim == 82) {     /* perform: family: receiver selector args... */
                    oop s = slots[sp - n];
                    if (!IS_INT(s) && s->cls == classSymbol) {
                        for (int i = 0; i < n - 1; i++) slots[sp - n + i] = slots[sp - n + 1 + i];
                        sp--; n--; sel = s; super = 0; goto send;
                    }
                } else if (prim == 83) {     /* perform:withArguments: */
                    oop s = slots[sp - 2], arr = slots[sp - 1];
                    if (!IS_INT(s) && s->cls == classSymbol && !IS_INT(arr) && arr->cls == classArray) {
                        sp -= 2; for (uint32_t i = 0; i < arr->size; i++) PUSH(SLOT(arr, i));
                        n = arr->size; sel = s; super = 0; goto send;
                    }
                } else if (prim >= 140 && prim <= 148) {   /* processes and semaphores */
                    oop cur = CUR();
                    switch (prim) {
                    case 140:   /* BlockClosure>>newProcess */
                        if (CLASS_OF(recv) == classBlockClosure && INT_VAL(SLOT(recv, B_NUMARGS)) == 0) {
                            SAVE();
                            oop outer = SLOT(recv, B_OUTER);
                            oop home = SLOT(outer, CTX_HOME) != nilobj ? SLOT(outer, CTX_HOME) : outer;
                            oop nctx = new_context(SLOT(recv, B_METHOD), SLOT(recv, B_RECEIVER), nilobj, home, outer);
                            oop proc = new_object(classProcess, 0); SLOT(proc, PR_CONTEXT) = nctx; SLOT(proc, PR_PRIORITY) = SLOT(cur, PR_PRIORITY);
                            sp -= n + 1; PUSH(proc); continue;
                        }
                        break;
                    case 141:   /* Process>>resume */
                        if (CLASS_OF(recv) == classProcess && SLOT(recv, PR_CONTEXT) != nilobj && SLOT(recv, PR_LIST) == nilobj && recv != cur) {
                            sp -= n + 1; PUSH(recv);
                            if (proc_prio(recv) > proc_prio(cur)) { PARK_CURRENT(); ll_add_first(run_queue(proc_prio(cur)), cur); CUR() = recv; interp.active = SLOT(recv, PR_CONTEXT); LOAD(); }
                            else make_runnable(recv);
                            continue;
                        }
                        break;
                    case 142: case 143:   /* suspend / terminate */
                        if (CLASS_OF(recv) == classProcess) {
                            if (recv == cur) {
                                sp -= n + 1; PUSH(recv); PARK_CURRENT();
                                if (prim == 143) { SLOT(cur, PR_CONTEXT) = nilobj; if (cur == owner) { result = nilobj; goto done; } }
                                goto switch_process;
                            }
                            if (SLOT(recv, PR_LIST) != nilobj) ll_remove(SLOT(recv, PR_LIST), recv);
                            remove_delay(recv);
                            if (prim == 143) SLOT(recv, PR_CONTEXT) = nilobj;
                            sp -= n + 1; PUSH(recv); continue;
                        }
                        break;
                    case 144: {   /* ProcessorScheduler>>yield */
                        sp -= n + 1; PUSH(recv);
                        oop q = run_queue(proc_prio(cur));
                        if (SLOT(q, LL_FIRST) != nilobj) { PARK_CURRENT(); ll_add_last(q, cur); goto switch_process; }
                        continue; }
                    case 145: {   /* Semaphore>>wait */
                        if (CLASS_OF(recv) != classSemaphore && !(!IS_INT(recv) && recv->size >= SEMAPHORE_SIZE)) break;
                        oop ex = SLOT(recv, SEM_EXCESS); intptr_t excess = IS_INT(ex) ? INT_VAL(ex) : 0;
                        sp -= n + 1; PUSH(recv);
                        if (excess > 0) { SLOT(recv, SEM_EXCESS) = MK_INT(excess - 1); continue; }
                        PARK_CURRENT(); ll_add_last(recv, cur); goto switch_process; }
                    case 146: {   /* Semaphore>>signal */
                        if (IS_INT(recv) || recv->size < SEMAPHORE_SIZE) break;
                        sp -= n + 1; PUSH(recv);
                        if (SLOT(recv, LL_FIRST) == nilobj) { oop ex = SLOT(recv, SEM_EXCESS); SLOT(recv, SEM_EXCESS) = MK_INT((IS_INT(ex) ? INT_VAL(ex) : 0) + 1); continue; }
                        oop proc = ll_remove_first(recv);
                        if (proc_prio(proc) > proc_prio(cur)) { PARK_CURRENT(); ll_add_first(run_queue(proc_prio(cur)), cur); CUR() = proc; interp.active = SLOT(proc, PR_CONTEXT); LOAD(); }
                        else make_runnable(proc);
                        continue; }
                    case 148: {   /* Delay>>primWait: milliseconds */
                        oop msArg = slots[sp - 1]; if (!IS_INT(msArg)) break;
                        sp -= n + 1; PUSH(recv); PARK_CURRENT();
                        if (!add_delay(cur, now_ms() + INT_VAL(msArg))) { make_runnable(cur); }
                        goto switch_process; }
                    }
                } else {
                    bool ok = false; SAVE();
                    oop r = call_primitive(prim, &slots[sp - n - 1], n, &ok);
                    if (interp.failed) goto abort;
                    if (ok) { sp -= n + 1; PUSH(r); continue; }
                }
            }
            SAVE();
            oop nctx = new_context(m, recv, ctx, nilobj, nilobj);
            for (int i = 0; i < n; i++) SLOT(nctx, CTX_FIXED + i) = slots[sp - n + i];
            sp -= n + 1; SAVE();
            interp.active = nctx; LOAD();
            continue;
        }
    switch_process: {
            oop next;
            for (;;) {
                next = pick_runnable();
                if (next) break;
                long w = wake_delays();
                if (!base) { CUR() = main_process; result = nilobj; goto done; }
                if (w < 0) { interp_signal_error("deadlock: every process is waiting"); goto abort; }
                long d = w - now_ms(); if (d > 50) d = 50; if (d > 0) usleep((useconds_t)d * 1000);
            }
            CUR() = next; interp.active = SLOT(next, PR_CONTEXT); LOAD();
            continue;
        }
    }
abort:
    result = nilobj;
    if (CUR() != owner) {                 /* a forked process died: drop it, and unblock the owner if it was waiting */
        SLOT(CUR(), PR_CONTEXT) = nilobj;
        if (base) { if (SLOT(owner, PR_LIST) != nilobj) ll_remove(SLOT(owner, PR_LIST), owner); remove_delay(owner); }
        CUR() = base ? owner : main_process;
    }
done:
    interp.active = saved; gc_remove_root(&saved); gc_remove_root(&owner);
    return result;
#undef LOAD
#undef SAVE
#undef PUSH
#undef POP
#undef CUR
#undef PARK_CURRENT
}

bool interp_run_background(int max_ms) {
    if (!interp_has_background()) return false;
    if (wake_delays() >= 0) { /* delays pending; something may be runnable now */ }
    bool any = false;
    for (int prio = 1; prio <= NUM_PRIORITIES; prio++) if (SLOT(run_queue(prio), LL_FIRST) != nilobj) any = true;
    if (!any) return false;
    run(NULL, now_ms() + max_ms);
    return true;
}

oop interp_run_method(oop method, oop receiver, oop *args, int nargs) {
    oop ctx = new_context(method, receiver, nilobj, nilobj, nilobj);
    for (int i = 0; i < nargs; i++) SLOT(ctx, CTX_FIXED + i) = args[i];
    return run(ctx, 0);
}

oop interp_send(oop receiver, oop selector, oop *args, int nargs) {
    /* trampoline method: push temps, send, return */
    oop m = new_object(classCompiledMethod, 0);
    SLOT(m, M_HEADER) = MK_HDR(nargs, nargs, nargs + 4);
    oop lits = new_array(1); SLOT(lits, 0) = selector; SLOT(m, M_LITERALS) = lits;
    unsigned char code[64]; int k = 0;
    code[k++] = OP_PUSH_SELF;
    for (int i = 0; i < nargs; i++) { code[k++] = OP_PUSH_TEMP; code[k++] = i; }
    code[k++] = OP_SEND; code[k++] = 0; code[k++] = nargs; code[k++] = OP_RETURN;
    oop bc = new_bytes(classByteArray, k); memcpy(BYTES(bc), code, k);
    SLOT(m, M_BYTECODES) = bc; SLOT(m, M_SELECTOR) = symDoIt; SLOT(m, M_CLASS) = CLASS_OF(receiver);
    SLOT(m, M_PRIM) = MK_INT(0);
    return interp_run_method(m, receiver, args, nargs);
}

oop interp_eval(oop receiver, const char *src, char *err, int errlen) {
    oop m = compile_doit(CLASS_OF(receiver), src, err, errlen);
    if (!m) { interp.failed = true; snprintf(interp.error, sizeof interp.error, "%s", err); interp.walkback[0] = 0; return nilobj; }
    return interp_run_method(m, receiver, NULL, 0);
}

oop interp_print_string(oop o) {
    bool wasFailed = interp.failed; char savedErr[1024]; strcpy(savedErr, interp.error);
    oop r = interp_send(o, symPrintString, NULL, 0);
    if (interp.failed) { r = new_string("<error in printString>"); }
    interp.failed = wasFailed; strcpy(interp.error, savedErr);
    if (IS_INT(r) || r->kind != KIND_BYTES) r = new_string("<not a string>");
    return r;
}
