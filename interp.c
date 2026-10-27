/* interp.c - bytecode interpreter with heap-allocated contexts */
#include "st.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

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
    oop ctx = new_object(classContext, ntemps + nstack);
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

static oop run(oop base) {
    static int trace = -1; if (trace < 0) trace = getenv("ST_TRACE") != NULL;
    oop saved = interp.active; gc_add_root(&saved);
    interp.active = base; interp.failed = false;
    oop ctx, method, rcvr, lits; unsigned char *code; int pc, sp; oop *slots; oop result = nilobj;
#define LOAD() do { ctx = interp.active; method = SLOT(ctx, CTX_METHOD); rcvr = SLOT(ctx, CTX_RECEIVER); lits = SLOT(method, M_LITERALS); \
        code = BYTES(SLOT(method, M_BYTECODES)); pc = (int)INT_VAL(SLOT(ctx, CTX_PC)); sp = (int)INT_VAL(SLOT(ctx, CTX_SP)); slots = ctx->slots; } while (0)
#define SAVE() do { SLOT(ctx, CTX_PC) = MK_INT(pc); SLOT(ctx, CTX_SP) = MK_INT(sp); } while (0)
#define PUSH(v) (slots[sp++] = (v))
#define POP() (slots[--sp])
    LOAD();
    oop sel = nilobj; int n = 0, super = 0;
    for (;;) {
        if (gc_alloc_since > gc_threshold) { SAVE(); gc_collect(); LOAD(); }
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
            oop v = POP(); oop target;
            if (SLOT(ctx, CTX_HOME) == nilobj) { target = SLOT(ctx, CTX_SENDER); SLOT(ctx, CTX_PC) = MK_INT(-1); }
            else {
                oop home = SLOT(ctx, CTX_HOME);
                if (INT_VAL(SLOT(home, CTX_PC)) < 0) { SAVE(); interp_signal_error("Block cannot return: home context has already returned"); goto abort; }
                target = SLOT(home, CTX_SENDER); SLOT(home, CTX_PC) = MK_INT(-1);
            }
            if (target == nilobj || ctx == base) { result = v; goto done; }
            interp.active = target; LOAD(); PUSH(v); break; }
        case OP_BLOCK_RETURN: {
            oop v = POP(); oop target = SLOT(ctx, CTX_SENDER);
            if (target == nilobj || ctx == base) { result = v; goto done; }
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
        }
    }
abort:
    result = nilobj;
done:
    interp.active = saved; gc_remove_root(&saved);
    return result;
#undef LOAD
#undef SAVE
#undef PUSH
#undef POP
}

oop interp_run_method(oop method, oop receiver, oop *args, int nargs) {
    oop ctx = new_context(method, receiver, nilobj, nilobj, nilobj);
    for (int i = 0; i < nargs; i++) SLOT(ctx, CTX_FIXED + i) = args[i];
    return run(ctx);
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
