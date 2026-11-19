/* image.c - binary images: save the object memory to a file, and start from one instead of the kernel sources.

   File layout (all integers in the machine's byte order; the header records the word size and an
   endianness probe, so an image only loads on a machine like the one that wrote it):

     header   magic, format version, word size, endian probe, layout fingerprint, object count,
              global count, next identity hash, size of everything after the header
     objects  per object: class, size, identity hash, kind, interned-Symbol flag, then the slots
              (pointer objects) or the bytes (byte objects)
     globals  the C-level well-known objects (nil, true, the classes, Smalltalk ...) and the 256 Characters

   A reference to an object is written as (index + 1) << 1, a SmallInteger as itself (low bit set), and a
   null pointer as 0. Only objects reachable from the system roots are written, so saving also collects garbage.
   Processes are not resumed after loading; the scheduler is reset and the user interface starts afresh. */
#include "st.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <sys/stat.h>
#include <unistd.h>

const char *image_path = "st.image";

#define IMAGE_MAGIC "MSTIMG\r\n"
#define IMAGE_VERSION 1
#define ENDIAN_PROBE 0x0102030405060708ULL

typedef struct {
    char magic[8];
    uint32_t version, wordsize;
    uint64_t endian;
    uint64_t layout;          /* fingerprint of the VM's object layouts and bytecodes */
    uint64_t nobjects, nglobals;
    uint32_t next_hash, reserved;
    uint64_t body_bytes;      /* file size minus the header */
} Header;
typedef struct { uint64_t cls; uint32_t size, hash; uint8_t kind, interned, pad[6]; } Record;

/* anything that changes how objects or bytecodes are laid out must change this */
static uint64_t layout_fingerprint(void) {
    uint64_t v[] = { sizeof(struct Obj), CLASS_SIZE, METACLASS_SIZE, METHOD_SIZE, CTX_FIXED, BLOCK_SIZE, DICT_SIZE, ASSOC_SIZE,
                     MSG_SIZE, CHAR_SIZE, LINK_SIZE, PROCESS_SIZE, LINKEDLIST_SIZE, SEMAPHORE_SIZE, PS_SIZE, NUM_PRIORITIES, OP_RETURN_RETRY };
    uint64_t h = 1469598103934665603ULL;
    for (size_t i = 0; i < sizeof v / sizeof v[0]; i++) { h ^= v[i]; h *= 1099511628211ULL; }
    return h;
}

time_t image_mtime(const char *path) { struct stat st; return stat(path, &st) == 0 ? st.st_mtime : 0; }

/* ---- saving ---- */
typedef struct { oop *keys; uint32_t *ids; size_t cap; } PtrMap;
static void map_init(PtrMap *m, size_t n) {
    m->cap = 1024; while (m->cap < n * 2 + 16) m->cap *= 2;
    m->keys = calloc(m->cap, sizeof(oop)); m->ids = calloc(m->cap, sizeof(uint32_t));
}
static size_t map_slot(PtrMap *m, oop o) { size_t i = (size_t)(((uintptr_t)o >> 4) * 2654435761u) & (m->cap - 1); while (m->keys[i] && m->keys[i] != o) i = (i + 1) & (m->cap - 1); return i; }
static void map_put(PtrMap *m, oop o, uint32_t id) { size_t i = map_slot(m, o); m->keys[i] = o; m->ids[i] = id; }
static uint32_t map_get(PtrMap *m, oop o) { size_t i = map_slot(m, o); return m->keys[i] == o ? m->ids[i] : 0; }

static uint64_t encode(PtrMap *m, oop o) {
    if (!o) return 0;
    if (IS_INT(o)) return (uint64_t)(uintptr_t)o;
    return (uint64_t)map_get(m, o) << 1;           /* ids start at 1; every reachable object has one */
}

bool image_save(const char *path, char *err, int errlen) {
    char tmp[4096]; snprintf(tmp, sizeof tmp, "%s.tmp", path);
    FILE *f = fopen(tmp, "wb");
    if (!f) { snprintf(err, errlen, "cannot write %s: %s", tmp, strerror(errno)); return false; }
    heap_flag_interned(true);
    heap_mark_image_roots();
    uint64_t n = 0;
    for (struct Obj *o = heap_head(); o; o = o->next) if (o->mark) n++;
    PtrMap map; map_init(&map, n);
    uint32_t id = 0;
    for (struct Obj *o = heap_head(); o; o = o->next) if (o->mark) map_put(&map, o, ++id);
    int ng; oop **g = image_globals(&ng);
    Header h; memset(&h, 0, sizeof h);
    memcpy(h.magic, IMAGE_MAGIC, 8); h.version = IMAGE_VERSION; h.wordsize = sizeof(oop); h.endian = ENDIAN_PROBE;
    h.layout = layout_fingerprint(); h.nobjects = n; h.nglobals = (uint64_t)ng + 256; h.next_hash = heap_next_hash();
    uint64_t body = 0;
    for (struct Obj *o = heap_head(); o; o = o->next) if (o->mark) body += sizeof(Record) + (o->kind == KIND_BYTES ? o->size : (uint64_t)o->size * sizeof(oop));
    body += h.nglobals * sizeof(uint64_t);
    h.body_bytes = body;
    bool ok = fwrite(&h, sizeof h, 1, f) == 1;
    for (struct Obj *o = heap_head(); o && ok; o = o->next) {
        if (!o->mark) continue;
        Record r; memset(&r, 0, sizeof r);
        r.cls = encode(&map, o->cls); r.size = o->size; r.hash = o->hash; r.kind = o->kind; r.interned = o->pad == 1;
        ok = fwrite(&r, sizeof r, 1, f) == 1;
        if (!ok) break;
        if (o->kind == KIND_BYTES) { if (o->size) ok = fwrite(BYTES(o), 1, o->size, f) == o->size; }
        else for (uint32_t i = 0; i < o->size && ok; i++) { uint64_t w = encode(&map, SLOT(o, i)); ok = fwrite(&w, sizeof w, 1, f) == 1; }
    }
    for (int i = 0; i < ng && ok; i++) { uint64_t w = encode(&map, *g[i]); ok = fwrite(&w, sizeof w, 1, f) == 1; }
    for (int i = 0; i < 256 && ok; i++) { uint64_t w = encode(&map, charTable[i]); ok = fwrite(&w, sizeof w, 1, f) == 1; }
    heap_clear_marks(); heap_flag_interned(false);
    free(map.keys); free(map.ids);
    if (fclose(f) != 0) ok = false;
    if (!ok) { snprintf(err, errlen, "error writing %s: %s", tmp, strerror(errno)); remove(tmp); return false; }
    if (rename(tmp, path) != 0) { snprintf(err, errlen, "cannot replace %s: %s", path, strerror(errno)); remove(tmp); return false; }
    return true;
}

/* ---- loading ---- */
static oop decode(oop *objs, uint64_t n, uint64_t w, bool *bad) {
    if (w & 1) return (oop)(uintptr_t)w;
    if (w == 0) return NULL;
    uint64_t id = w >> 1;
    if (id > n) { *bad = true; return NULL; }
    return objs[id - 1];
}

bool image_load(const char *path, char *err, int errlen) {
    if (heap_head()) { snprintf(err, errlen, "an image can only be loaded into an empty system"); return false; }
    FILE *f = fopen(path, "rb");
    if (!f) { snprintf(err, errlen, "cannot open %s: %s", path, strerror(errno)); return false; }
    Header h;
    if (fread(&h, sizeof h, 1, f) != 1 || memcmp(h.magic, IMAGE_MAGIC, 8) != 0) { fclose(f); snprintf(err, errlen, "%s is not a Smalltalk image", path); return false; }
    if (h.version != IMAGE_VERSION) { fclose(f); snprintf(err, errlen, "%s has image format %u; this system reads format %d", path, h.version, IMAGE_VERSION); return false; }
    if (h.wordsize != sizeof(oop) || h.endian != ENDIAN_PROBE) { fclose(f); snprintf(err, errlen, "%s was saved on a machine with a different word size or byte order", path); return false; }
    int ng; oop **g = image_globals(&ng);
    if (h.layout != layout_fingerprint() || h.nglobals != (uint64_t)ng + 256) { fclose(f); snprintf(err, errlen, "%s was saved by a different version of the virtual machine; rebuild it from the kernel sources", path); return false; }
    struct stat st;
    if (fstat(fileno(f), &st) != 0 || (uint64_t)st.st_size != sizeof h + h.body_bytes) { fclose(f); snprintf(err, errlen, "%s is truncated or damaged", path); return false; }
    unsigned char *buf = malloc(h.body_bytes ? h.body_bytes : 1);
    if (!buf || fread(buf, 1, h.body_bytes, f) != h.body_bytes) { fclose(f); free(buf); snprintf(err, errlen, "cannot read %s", path); return false; }
    fclose(f);
    oop *objs = malloc((h.nobjects ? h.nobjects : 1) * sizeof(oop));
    bool bad = false; uint64_t pos = 0, n = h.nobjects;
    /* pass 1: allocate every object */
    for (uint64_t i = 0; i < n && !bad; i++) {
        Record r;
        if (pos + sizeof r > h.body_bytes) { bad = true; break; }
        memcpy(&r, buf + pos, sizeof r);
        uint64_t payload = r.kind == KIND_BYTES ? r.size : (uint64_t)r.size * sizeof(oop);
        if (r.kind > KIND_BYTES || pos + sizeof r + payload > h.body_bytes) { bad = true; break; }
        objs[i] = heap_new_raw(r.size, r.kind, r.hash); objs[i]->pad = r.interned ? 1 : 0;
        pos += sizeof r + payload;
    }
    uint64_t globals_pos = pos;
    /* pass 2: fill in classes, slots and bytes */
    pos = 0;
    for (uint64_t i = 0; i < n && !bad; i++) {
        Record r; memcpy(&r, buf + pos, sizeof r); pos += sizeof r; oop o = objs[i];
        o->cls = decode(objs, n, r.cls, &bad);
        if (r.kind == KIND_BYTES) { if (r.size) memcpy(BYTES(o), buf + pos, r.size); pos += r.size; }
        else for (uint32_t k = 0; k < r.size; k++) { uint64_t w; memcpy(&w, buf + pos, sizeof w); pos += sizeof w; SLOT(o, k) = decode(objs, n, w, &bad); }
    }
    if (!bad && globals_pos + h.nglobals * sizeof(uint64_t) != h.body_bytes) bad = true;
    if (!bad) {
        for (int i = 0; i < ng; i++) { uint64_t w; memcpy(&w, buf + globals_pos + (uint64_t)i * 8, 8); *g[i] = decode(objs, n, w, &bad); }
        for (int i = 0; i < 256; i++) { uint64_t w; memcpy(&w, buf + globals_pos + ((uint64_t)ng + i) * 8, 8); charTable[i] = decode(objs, n, w, &bad); }
    }
    free(buf); free(objs);
    if (bad) { snprintf(err, errlen, "%s is damaged", path); return false; }
    heap_set_next_hash(h.next_hash);
    heap_rebuild_symbols();
    /* processes are not resumed: the running one is the user interface, and nothing else is runnable */
    oop lists = SLOT(processor, PS_LISTS);
    for (int i = 0; i < NUM_PRIORITIES; i++) { oop l = SLOT(lists, i); SLOT(l, LL_FIRST) = nilobj; SLOT(l, LL_LAST) = nilobj; }
    SLOT(processor, PS_ACTIVE) = main_process;
    SLOT(main_process, PR_CONTEXT) = nilobj; SLOT(main_process, PR_LIST) = nilobj; SLOT(main_process, PR_NEXT) = nilobj;
    heap_reset_alloc_counter();
    return true;
}

/* save, and when the file is the image this session started from (or will restart from), set the changes file aside:
   everything in it is now in the image, and replaying it again at the next start would be pointless */
bool image_snapshot(const char *path, char *err, int errlen) {
    if (!image_save(path, err, errlen)) return false;
    struct stat a, b;
    bool current = stat(path, &a) == 0 && stat(image_path, &b) == 0 && a.st_dev == b.st_dev && a.st_ino == b.st_ino;
    if (current && stat(changes_path, &b) == 0 && S_ISREG(b.st_mode)) {
        char bak[4096]; snprintf(bak, sizeof bak, "%s.bak", changes_path);
        if (rename(changes_path, bak) == 0) changes_count = 0;
    }
    return true;
}
