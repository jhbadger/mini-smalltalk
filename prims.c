/* prims.c - primitive operations */
#include "st.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <sys/time.h>

char *transcript_text = NULL; size_t transcript_len = 0; static size_t transcript_cap = 0;
oop pending_inspect = NULL; bool quit_requested = false;
void interp_flush_cache(void);

void transcript_append(const char *s, int n) {
    if (transcript_len + n + 1 > transcript_cap) { transcript_cap = (transcript_len + n + 1) * 2 + 4096; transcript_text = realloc(transcript_text, transcript_cap); }
    memcpy(transcript_text + transcript_len, s, n); transcript_len += n; transcript_text[transcript_len] = 0;
    if (transcript_len > 200000) { size_t cut = transcript_len - 150000; memmove(transcript_text, transcript_text + cut, transcript_len - cut + 1); transcript_len -= cut; }
}

static bool is_bytes(oop o) { return !IS_INT(o) && o->kind == KIND_BYTES; }
static bool is_num(oop o) { return IS_INT(o) || (!IS_INT(o) && o->cls == classFloat); }
static double num_val(oop o) { return IS_INT(o) ? (double)INT_VAL(o) : FLOATVAL(o); }
static bool fits(intptr_t v) { return v >= -INT_MAX_VAL && v < INT_MAX_VAL; }
static oop fmt_float(double d) {
    char buf[64]; snprintf(buf, sizeof buf, "%.15g", d);
    if (strtod(buf, NULL) != d) snprintf(buf, sizeof buf, "%.17g", d);
    if (!strpbrk(buf, ".einA")) strcat(buf, ".0");
    return new_string(buf);
}
static int indexable_size(oop o) {
    if (IS_INT(o)) return 0;
    if (o->kind == KIND_BYTES) return o->size;
    if (o->kind == KIND_INDEXED) return o->size - FMT_SIZE(SLOT(o->cls, C_FORMAT));
    return 0;
}

#define FAIL do { *ok = false; return nilobj; } while (0)
#define A(i) args[i]

oop call_primitive(int n, oop *args, int nargs, bool *ok) {
    *ok = true;
    oop self = args[0];
    switch (n) {
    /* ---- Object ---- */
    case 1: return self == A(1) ? trueobj : falseobj;
    case 2: return CLASS_OF(self);
    case 3: return MK_INT(indexable_size(self));
    case 4: { if (!IS_INT(A(1)) || IS_INT(self)) FAIL; int i = (int)INT_VAL(A(1)); if (i < 1 || i > indexable_size(self)) FAIL;
        if (self->kind == KIND_BYTES) return (self->cls == classString || self->cls == classSymbol) ? charTable[BYTES(self)[i - 1]] : MK_INT(BYTES(self)[i - 1]);
        return SLOT(self, FMT_SIZE(SLOT(self->cls, C_FORMAT)) + i - 1); }
    case 5: { if (!IS_INT(A(1)) || IS_INT(self)) FAIL; int i = (int)INT_VAL(A(1)); if (i < 1 || i > indexable_size(self)) FAIL;
        if (self->kind == KIND_BYTES) {
            if (self->cls == classString || self->cls == classSymbol) { if (IS_INT(A(2)) || A(2)->cls != classCharacter) FAIL; BYTES(self)[i - 1] = (unsigned char)INT_VAL(SLOT(A(2), CH_VALUE)); }
            else { if (!IS_INT(A(2)) || INT_VAL(A(2)) < 0 || INT_VAL(A(2)) > 255) FAIL; BYTES(self)[i - 1] = (unsigned char)INT_VAL(A(2)); }
            return A(2); }
        SLOT(self, FMT_SIZE(SLOT(self->cls, C_FORMAT)) + i - 1) = A(2); return A(2); }
    case 6: if (IS_INT(self) || FMT_KIND(SLOT(self, C_FORMAT)) != KIND_POINTERS) FAIL; return new_object(self, 0);
    case 7: { if (IS_INT(self) || !IS_INT(A(1)) || INT_VAL(A(1)) < 0) FAIL; int k = FMT_KIND(SLOT(self, C_FORMAT)); if (k == KIND_POINTERS) FAIL;
        oop o = new_object(self, (int)INT_VAL(A(1)));
        if (k == KIND_BYTES) { oop c = self; bool str = false; while (c != nilobj) { if (c == classString) str = true; c = SLOT(c, C_SUPER); } if (str) memset(BYTES(o), ' ', o->size); }
        return o; }
    case 8: return MK_INT(IS_INT(self) ? INT_VAL(self) : self->hash);
    case 9: { if (IS_INT(self) || !IS_INT(A(1))) FAIL; int i = (int)INT_VAL(A(1)); if (self->kind == KIND_BYTES || i < 1 || i > (int)self->size) FAIL; return SLOT(self, i - 1); }
    case 10: { if (IS_INT(self) || !IS_INT(A(1))) FAIL; int i = (int)INT_VAL(A(1)); if (self->kind == KIND_BYTES || i < 1 || i > (int)self->size) FAIL; SLOT(self, i - 1) = A(2); return A(2); }
    case 11: { char *m = is_bytes(A(1)) ? str_cstr(A(1)) : strdup("error"); interp_signal_error(m); free(m); return nilobj; }
    case 12: { if (IS_INT(self)) return self;
        if (self->kind == KIND_BYTES) { oop o = new_bytes(self->cls, self->size); memcpy(BYTES(o), BYTES(self), self->size); return o; }
        oop o = new_object(self->cls, indexable_size(self)); for (uint32_t i = 0; i < self->size && i < o->size; i++) SLOT(o, i) = SLOT(self, i); return o; }
    case 15: return lookup_method(CLASS_OF(self), A(1)) ? trueobj : falseobj;
    case 16: if (IS_INT(self)) FAIL; return dict_at(SLOT(self, C_METHODS), A(1)) ? trueobj : falseobj;
    /* ---- SmallInteger ---- */
    case 20: case 21: case 22: case 23: case 24: case 25: case 38: case 39: {
        if (!IS_INT(self) || !IS_INT(A(1))) FAIL; intptr_t a = INT_VAL(self), b = INT_VAL(A(1)), r;
        switch (n) {
        case 20: r = a + b; break; case 21: r = a - b; break;
        case 22: if (__builtin_mul_overflow(a, b, &r)) FAIL; break;
        case 23: if (b == 0) FAIL; r = a / b; if ((a % b != 0) && ((a < 0) != (b < 0))) r--; break;
        case 24: if (b == 0) FAIL; r = a % b; if (r != 0 && ((r < 0) != (b < 0))) r += b; break;
        case 25: if (b == 0 || a % b != 0) FAIL; r = a / b; break;
        case 38: if (b == 0) FAIL; r = a / b; break;
        default: if (b == 0) FAIL; r = a % b; break; }
        if (!fits(r)) FAIL; return MK_INT(r); }
    case 26: case 27: case 28: case 29: case 30: case 31: {
        if (!IS_INT(self) || !IS_INT(A(1))) FAIL; intptr_t a = INT_VAL(self), b = INT_VAL(A(1)); bool r;
        switch (n) { case 26: r = a < b; break; case 27: r = a > b; break; case 28: r = a <= b; break; case 29: r = a >= b; break; case 30: r = a == b; break; default: r = a != b; }
        return r ? trueobj : falseobj; }
    case 32: if (!IS_INT(self) || !IS_INT(A(1))) FAIL; return MK_INT(INT_VAL(self) & INT_VAL(A(1)));
    case 33: if (!IS_INT(self) || !IS_INT(A(1))) FAIL; return MK_INT(INT_VAL(self) | INT_VAL(A(1)));
    case 34: if (!IS_INT(self) || !IS_INT(A(1))) FAIL; return MK_INT(INT_VAL(self) ^ INT_VAL(A(1)));
    case 35: { if (!IS_INT(self) || !IS_INT(A(1))) FAIL; intptr_t a = INT_VAL(self), s = INT_VAL(A(1));
        if (s >= 0) { if (s > 60) FAIL; intptr_t r = a << s; if ((r >> s) != a || !fits(r)) FAIL; return MK_INT(r); }
        return MK_INT(s < -62 ? (a < 0 ? -1 : 0) : a >> -s); }
    case 36: if (!IS_INT(self)) FAIL; return new_float((double)INT_VAL(self));
    case 37: { if (!IS_INT(self) || !IS_INT(A(1))) FAIL; int base = (int)INT_VAL(A(1)); if (base < 2 || base > 36) FAIL;
        char buf[80]; int k = 79; buf[k] = 0; intptr_t v = INT_VAL(self); bool neg = v < 0; if (neg) v = -v;
        do { int d = (int)(v % base); buf[--k] = d < 10 ? '0' + d : 'A' + d - 10; v /= base; } while (v);
        if (neg) buf[--k] = '-'; return new_string(buf + k); }
    /* ---- Float (accept any number argument) ---- */
    case 40: case 41: case 42: case 43: {
        if (!is_num(self) || !is_num(A(1))) FAIL; double a = num_val(self), b = num_val(A(1));
        switch (n) { case 40: return new_float(a + b); case 41: return new_float(a - b); case 42: return new_float(a * b);
        default: if (b == 0) FAIL; return new_float(a / b); } }
    case 44: case 45: case 46: case 47: case 48: {
        if (!is_num(self) || !is_num(A(1))) FAIL; double a = num_val(self), b = num_val(A(1)); bool r;
        switch (n) { case 44: r = a < b; break; case 45: r = a > b; break; case 46: r = a <= b; break; case 47: r = a >= b; break; default: r = a == b; }
        return r ? trueobj : falseobj; }
    case 49: { if (!is_num(self)) FAIL; double d = trunc(num_val(self)); if (!fits((intptr_t)d) || isnan(d)) FAIL; return MK_INT((intptr_t)d); }
    case 50: if (!is_num(self)) FAIL; return fmt_float(num_val(self));
    case 51: if (!is_num(self)) FAIL; return new_float(sqrt(num_val(self)));
    case 52: if (!is_num(self)) FAIL; return new_float(log(num_val(self)));
    case 53: if (!is_num(self)) FAIL; return new_float(exp(num_val(self)));
    case 54: if (!is_num(self)) FAIL; return new_float(sin(num_val(self)));
    case 55: if (!is_num(self)) FAIL; return new_float(cos(num_val(self)));
    case 56: if (!is_num(self)) FAIL; return new_float(atan(num_val(self)));
    case 57: if (!is_num(self) || !is_num(A(1))) FAIL; return new_float(pow(num_val(self), num_val(A(1))));
    case 58: if (!is_num(self)) FAIL; return new_float(num_val(self) - trunc(num_val(self)));
    /* ---- Strings, Symbols, byte and pointer collections ---- */
    case 63: if (!is_bytes(self) || !is_bytes(A(1))) FAIL;
        return (self->size == A(1)->size && memcmp(BYTES(self), BYTES(A(1)), self->size) == 0) ? trueobj : falseobj;
    case 64: return MK_INT(obj_hash(self) & 0x3fffffff);
    case 65: if (!is_bytes(self)) FAIL; return new_symbol_n((char *)BYTES(self), self->size);
    case 66: if (!is_bytes(self)) FAIL; return new_string_n((char *)BYTES(self), self->size);
    case 67: { /* replaceFrom: start to: stop with: coll startingAt: repStart */
        if (IS_INT(self) || !IS_INT(A(1)) || !IS_INT(A(2)) || !IS_INT(A(4)) || IS_INT(A(3))) FAIL;
        oop src = A(3); int start = (int)INT_VAL(A(1)), stop = (int)INT_VAL(A(2)), rs = (int)INT_VAL(A(4)); int len = stop - start + 1;
        if (len < 0) return self; if (start < 1 || stop > indexable_size(self) || rs < 1 || rs + len - 1 > indexable_size(src)) FAIL;
        if (self->kind == KIND_BYTES && src->kind == KIND_BYTES) { memmove(BYTES(self) + start - 1, BYTES(src) + rs - 1, len); return self; }
        if (self->kind == KIND_INDEXED && src->kind == KIND_INDEXED) {
            int df = FMT_SIZE(SLOT(self->cls, C_FORMAT)), sf = FMT_SIZE(SLOT(src->cls, C_FORMAT));
            memmove(&SLOT(self, df + start - 1), &SLOT(src, sf + rs - 1), len * sizeof(oop)); return self; }
        FAIL; }
    case 68: { if (!is_bytes(self) || !is_bytes(A(1))) FAIL; uint32_t m = self->size < A(1)->size ? self->size : A(1)->size;
        int c = memcmp(BYTES(self), BYTES(A(1)), m); if (c == 0) c = (int)self->size - (int)A(1)->size; return MK_INT(c < 0 ? -1 : c > 0 ? 1 : 0); }
    case 69: { if (!is_bytes(self)) FAIL; char *s = str_cstr(self); char *end; double d = strtod(s, &end);
        bool isf = strpbrk(s, ".eE") != NULL; oop r = (end == s) ? nilobj : (isf || !fits((intptr_t)d)) ? new_float(d) : MK_INT((intptr_t)d); free(s); return r; }
    case 70: if (!IS_INT(A(1)) || INT_VAL(A(1)) < 0 || INT_VAL(A(1)) > 255) FAIL; return charTable[INT_VAL(A(1))];
    /* ---- Dictionary ---- */
    case 90: { oop v = dict_at(self, A(1)); if (!v) FAIL; return v; }
    case 91: dict_at_put(self, A(1), A(2)); return A(2);
    case 92: if (!dict_remove(self, A(1))) FAIL; return A(1);
    case 93: return dict_keys(self);
    case 94: return dict_at(self, A(1)) ? trueobj : falseobj;
    case 95: { oop a = dict_assoc_at(self, A(1)); if (!a) FAIL; return a; }
    /* ---- classes and system ---- */
    case 100: { if (IS_INT(A(1)) || A(1)->cls != classSymbol || !is_bytes(A(2)) || !is_bytes(A(3)) || !IS_INT(A(5))) FAIL;
        oop c = define_class(self, A(1), A(2), A(3), A(4), (int)INT_VAL(A(5))); interp_flush_cache(); return c; }
    case 101: { if (IS_INT(self) || !is_bytes(A(1))) FAIL; char err[512]; char *src = str_cstr(A(1)); char *cat = is_bytes(A(2)) ? str_cstr(A(2)) : strdup("as yet unclassified");
        oop m = compile_method(self, src, cat, err, sizeof err); free(src); free(cat);
        if (!m) { interp_signal_error(err); return nilobj; }
        dict_at_put(SLOT(self, C_METHODS), SLOT(m, M_SELECTOR), m); interp_flush_cache(); return SLOT(m, M_SELECTOR); }
    case 102: if (IS_INT(self)) FAIL; if (!dict_remove(SLOT(self, C_METHODS), A(1))) FAIL; interp_flush_cache(); return A(1);
    case 103: if (IS_INT(self)) FAIL; return dict_keys(SLOT(self, C_METHODS));
    case 104: { if (IS_INT(self)) FAIL; oop m = dict_at(SLOT(self, C_METHODS), A(1)); if (!m) FAIL; return m; }
    case 105: if (IS_INT(self)) FAIL; return class_ivar_names(self);
    case 106: { if (IS_INT(self)) FAIL; oop f = SLOT(self, C_FORMAT); return MK_INT(FMT_KIND(f)); }
    case 110: { if (!is_bytes(A(1))) FAIL; transcript_append((char *)BYTES(A(1)), A(1)->size); return self; }
    case 111: transcript_append("\n", 1); return self;
    case 112: quit_requested = true; return self;
    case 113: interp_flush_cache(); return self;
    case 114: { if (!is_bytes(A(1))) FAIL; char err[512]; char *p = str_cstr(A(1)); bool r = file_in(p, err, sizeof err); free(p);
        if (!r) { interp_signal_error(err); return nilobj; } return self; }
    case 115: { if (IS_INT(A(1))) FAIL; char *t = file_out_class(A(1)); oop s = new_string(t); free(t); return s; }
    case 116: { struct timeval tv; gettimeofday(&tv, NULL); return MK_INT((tv.tv_sec % 1000000) * 1000 + tv.tv_usec / 1000); }
    case 117: gc_collect(); return self;
    case 119: pending_inspect = self; return self;
    case 120: { if (!is_bytes(A(1))) FAIL; char err[512]; char *src = str_cstr(A(1)); oop r = interp_eval(self, src, err, sizeof err); free(src); return r; }
    case 121: { if (!is_bytes(A(1))) FAIL; char err[512]; char *src = str_cstr(A(1)); bool r = file_in_string(src, err, sizeof err); free(src);
        if (!r) { interp_signal_error(err); return nilobj; } return self; }
    }
    FAIL;
}
