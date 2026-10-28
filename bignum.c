/* bignum.c - arbitrary precision integers for LargePositiveInteger / LargeNegativeInteger
   Representation: byte objects holding the magnitude little-endian (as in Smalltalk-80), sign by class.
   Arithmetic is done on uint32 limb arrays; results are normalised back to SmallInteger when they fit. */
#include "st.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

typedef struct { uint32_t *d; int n; int neg; } Big;   /* n limbs, most significant last; n == 0 means zero */

static void trim(Big *b) { while (b->n > 0 && b->d[b->n - 1] == 0) b->n--; if (b->n == 0) b->neg = 0; }
static Big big_alloc(int n) { Big b; b.d = calloc(n + 1, sizeof(uint32_t)); b.n = n; b.neg = 0; return b; }

bool bn_is_integer(oop o) { return IS_INT(o) || o->cls == classLargePositiveInteger || o->cls == classLargeNegativeInteger; }
oop bn_negate(oop a) { bool ok; return bn_arith('-', MK_INT(0), a, &ok); }

static Big from_oop(oop o) {
    Big b;
    if (IS_INT(o)) {
        intptr_t v = INT_VAL(o); uint64_t m = v < 0 ? (uint64_t)(-(v + 1)) + 1 : (uint64_t)v;
        b = big_alloc(2); b.d[0] = (uint32_t)m; b.d[1] = (uint32_t)(m >> 32); b.neg = v < 0; trim(&b); return b;
    }
    int nbytes = o->size; b = big_alloc((nbytes + 3) / 4);
    for (int i = 0; i < nbytes; i++) b.d[i / 4] |= (uint32_t)BYTES(o)[i] << (8 * (i % 4));
    b.neg = o->cls == classLargeNegativeInteger; trim(&b); return b;
}
static oop to_oop(Big b) {
    trim(&b);
    if (b.n <= 2) {
        uint64_t m = (b.n > 0 ? b.d[0] : 0) | (b.n > 1 ? (uint64_t)b.d[1] << 32 : 0);
        if (m < ((uint64_t)1 << 61)) { intptr_t v = (intptr_t)m; free(b.d); return MK_INT(b.neg ? -v : v); }
        if (b.neg && m == ((uint64_t)1 << 61)) { free(b.d); return MK_INT(-(intptr_t)m); }
    }
    int nbytes = b.n * 4; while (nbytes > 0 && ((b.d[(nbytes - 1) / 4] >> (8 * ((nbytes - 1) % 4))) & 0xff) == 0) nbytes--;
    oop o = new_bytes(b.neg ? classLargeNegativeInteger : classLargePositiveInteger, nbytes);
    for (int i = 0; i < nbytes; i++) BYTES(o)[i] = (b.d[i / 4] >> (8 * (i % 4))) & 0xff;
    free(b.d); return o;
}

static int cmp_mag(const Big *a, const Big *b) {
    if (a->n != b->n) return a->n < b->n ? -1 : 1;
    for (int i = a->n - 1; i >= 0; i--) if (a->d[i] != b->d[i]) return a->d[i] < b->d[i] ? -1 : 1;
    return 0;
}
static Big add_mag(const Big *a, const Big *b) {
    int n = (a->n > b->n ? a->n : b->n) + 1; Big r = big_alloc(n); uint64_t c = 0;
    for (int i = 0; i < n; i++) { c += (i < a->n ? a->d[i] : 0) + (uint64_t)(i < b->n ? b->d[i] : 0); r.d[i] = (uint32_t)c; c >>= 32; }
    trim(&r); return r;
}
static Big sub_mag(const Big *a, const Big *b) {   /* |a| >= |b| */
    Big r = big_alloc(a->n); int64_t c = 0;
    for (int i = 0; i < a->n; i++) { c += (int64_t)a->d[i] - (i < b->n ? b->d[i] : 0); r.d[i] = (uint32_t)(c & 0xffffffff); c = c < 0 ? -1 : 0; }
    trim(&r); return r;
}
static Big mul_mag(const Big *a, const Big *b) {
    Big r = big_alloc(a->n + b->n + 1);
    for (int i = 0; i < a->n; i++) {
        uint64_t c = 0;
        for (int j = 0; j < b->n; j++) { c += (uint64_t)a->d[i] * b->d[j] + r.d[i + j]; r.d[i + j] = (uint32_t)c; c >>= 32; }
        int k = i + b->n; while (c) { c += r.d[k]; r.d[k++] = (uint32_t)c; c >>= 32; }
    }
    trim(&r); return r;
}
/* divide magnitude by small value in place; returns remainder */
static uint32_t divmod_small(Big *a, uint32_t v) {
    uint64_t rem = 0;
    for (int i = a->n - 1; i >= 0; i--) { uint64_t cur = (rem << 32) | a->d[i]; a->d[i] = (uint32_t)(cur / v); rem = cur % v; }
    trim(a); return (uint32_t)rem;
}
/* binary long division of magnitudes: q = a / b, r = a % b */
static void divmod_mag(const Big *a, const Big *b, Big *q, Big *r) {
    *q = big_alloc(a->n); *r = big_alloc(b->n + 1 > a->n ? b->n + 1 : a->n + 1);
    if (cmp_mag(a, b) < 0) { memcpy(r->d, a->d, a->n * 4); r->n = a->n; trim(q); trim(r); return; }
    if (b->n == 1) { memcpy(q->d, a->d, a->n * 4); q->n = a->n; uint32_t rem = divmod_small(q, b->d[0]); r->d[0] = rem; r->n = 1; trim(r); return; }
    r->n = 0;
    for (int bit = a->n * 32 - 1; bit >= 0; bit--) {
        /* r = r << 1 | bit */
        uint32_t carry = (a->d[bit / 32] >> (bit % 32)) & 1;
        for (int i = 0; i < r->n; i++) { uint32_t nc = r->d[i] >> 31; r->d[i] = (r->d[i] << 1) | carry; carry = nc; }
        if (carry) r->d[r->n++] = carry;
        if (cmp_mag(r, b) >= 0) {
            int64_t c = 0;
            for (int i = 0; i < r->n; i++) { c += (int64_t)r->d[i] - (i < b->n ? b->d[i] : 0); r->d[i] = (uint32_t)(c & 0xffffffff); c = c < 0 ? -1 : 0; }
            trim(r);
            q->d[bit / 32] |= 1u << (bit % 32);
        }
    }
    trim(q); trim(r);
}
static Big shift_left(const Big *a, int s) {
    int limbs = s / 32, bits = s % 32; Big r = big_alloc(a->n + limbs + 1);
    for (int i = 0; i < a->n; i++) {
        uint64_t v = (uint64_t)a->d[i] << bits;
        r.d[i + limbs] |= (uint32_t)v; r.d[i + limbs + 1] |= (uint32_t)(v >> 32);
    }
    r.neg = a->neg; trim(&r); return r;
}

oop bn_arith(int op, oop ao, oop bo, bool *ok) {
    *ok = true;
    if (!bn_is_integer(ao) || !bn_is_integer(bo)) { *ok = false; return nilobj; }
    Big a = from_oop(ao), b = from_oop(bo), r = { 0, 0, 0 }; oop result = nilobj;
    switch (op) {
    case '+': case '-': {
        int bneg = op == '-' ? !b.neg : b.neg;
        if (a.neg == bneg) { r = add_mag(&a, &b); r.neg = a.neg; }
        else if (cmp_mag(&a, &b) >= 0) { r = sub_mag(&a, &b); r.neg = a.neg; }
        else { r = sub_mag(&b, &a); r.neg = bneg; }
        result = to_oop(r); break; }
    case '*': r = mul_mag(&a, &b); r.neg = a.neg != b.neg; result = to_oop(r); break;
    case '/': case '%': case 'q': case 'r': {
        if (b.n == 0) { *ok = false; break; }
        Big q, rem; divmod_mag(&a, &b, &q, &rem);
        q.neg = a.neg != b.neg; rem.neg = a.neg; trim(&q); trim(&rem);
        if ((op == '/' || op == '%') && rem.n != 0 && a.neg != b.neg) {   /* floor semantics */
            Big one = big_alloc(1); one.d[0] = 1; one.n = 1;
            Big q2 = add_mag(&q, &one); q2.neg = 1; free(q.d); q = q2;
            Big r2 = (cmp_mag(&b, &rem) >= 0) ? sub_mag(&b, &rem) : sub_mag(&rem, &b); r2.neg = b.neg; free(rem.d); rem = r2; free(one.d);
        }
        if (op == '/' || op == 'q') { result = to_oop(q); free(rem.d); } else { result = to_oop(rem); free(q.d); }
        break; }
    case 'c': {
        int c; if (a.neg != b.neg) c = a.neg ? -1 : 1; else { c = cmp_mag(&a, &b); if (a.neg) c = -c; }
        result = MK_INT(c); break; }
    case '&': case '|': case '^': {
        if (a.neg || b.neg) { *ok = false; break; }
        int n = a.n > b.n ? a.n : b.n; r = big_alloc(n);
        for (int i = 0; i < n; i++) { uint32_t x = i < a.n ? a.d[i] : 0, y = i < b.n ? b.d[i] : 0; r.d[i] = op == '&' ? x & y : op == '|' ? x | y : x ^ y; }
        result = to_oop(r); break; }
    case 's': {
        if (!IS_INT(bo)) { *ok = false; break; }
        intptr_t s = INT_VAL(bo);
        if (s >= 0) { if (s > 100000) { *ok = false; break; } r = shift_left(&a, (int)s); result = to_oop(r); }
        else {
            s = -s; Big pw = big_alloc(1); pw.d[0] = 1; pw.n = 1; Big p = shift_left(&pw, (int)s); free(pw.d);
            Big q, rem; divmod_mag(&a, &p, &q, &rem); q.neg = a.neg;
            if (a.neg && rem.n != 0) { Big one = big_alloc(1); one.d[0] = 1; one.n = 1; Big q2 = add_mag(&q, &one); q2.neg = 1; free(q.d); q = q2; free(one.d); }
            result = to_oop(q); free(rem.d); free(p.d);
        }
        break; }
    default: *ok = false;
    }
    free(a.d); free(b.d);
    return result;
}

oop bn_print(oop ao, int base) {
    Big a = from_oop(ao); char *buf = malloc(a.n * 32 + 8); int k = 0; int neg = a.neg;
    if (a.n == 0) buf[k++] = '0';
    while (a.n > 0) { uint32_t d = divmod_small(&a, (uint32_t)base); buf[k++] = d < 10 ? '0' + d : 'A' + d - 10; }
    if (neg) buf[k++] = '-';
    for (int i = 0; i < k / 2; i++) { char t = buf[i]; buf[i] = buf[k - 1 - i]; buf[k - 1 - i] = t; }
    buf[k] = 0; oop s = new_string(buf); free(buf); free(a.d); return s;
}

oop bn_to_float(oop ao, bool *ok) {
    *ok = true; if (!bn_is_integer(ao)) { *ok = false; return nilobj; }
    Big a = from_oop(ao); double d = 0;
    for (int i = a.n - 1; i >= 0; i--) d = d * 4294967296.0 + a.d[i];
    if (a.neg) d = -d; free(a.d); return new_float(d);
}

oop bn_from_double(double d) {
    int neg = d < 0; if (neg) d = -d;
    int e; double m = frexp(d, &e);              /* d = m * 2^e, 0.5 <= m < 1 */
    uint64_t mant = (uint64_t)ldexp(m, 53); e -= 53;
    Big b = big_alloc(2); b.d[0] = (uint32_t)mant; b.d[1] = (uint32_t)(mant >> 32); b.neg = neg; trim(&b);
    if (e > 0) { Big s = shift_left(&b, e); free(b.d); b = s; }
    else if (e < 0) { for (int i = 0; i < -e; i++) divmod_small(&b, 2); }
    b.neg = neg; return to_oop(b);
}

uint32_t bn_hash(oop o) {
    uint32_t h = 2166136261u; for (uint32_t i = 0; i < o->size; i++) { h ^= BYTES(o)[i]; h *= 16777619u; } return h;
}

oop bn_from_string(const char *digits, int radix) {
    Big b = big_alloc(strlen(digits) / 2 + 2); b.n = 0;
    for (const char *p = digits; *p; p++) {
        int d = (*p >= '0' && *p <= '9') ? *p - '0' : (*p >= 'A' && *p <= 'Z') ? *p - 'A' + 10 : (*p >= 'a' && *p <= 'z') ? *p - 'a' + 10 : -1;
        if (d < 0 || d >= radix) break;
        uint64_t c = d;
        for (int i = 0; i < b.n; i++) { c += (uint64_t)b.d[i] * radix; b.d[i] = (uint32_t)c; c >>= 32; }
        if (c) b.d[b.n++] = (uint32_t)c;
    }
    return to_oop(b);
}
