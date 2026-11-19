CC ?= cc
CFLAGS ?= -O2 -Wall -Wno-unused-result -Wno-unused-function
LDFLAGS ?= -lm

VM_SRCS = object.c lex.c parse.c compiler.c interp.c prims.c fileio.c bignum.c image.c
UI_SRCS = tui.c widgets.c tools.c
VM_OBJS = $(VM_SRCS:.c=.o)
UI_OBJS = $(UI_SRCS:.c=.o)

all: st kernel.image

st: $(VM_OBJS) $(UI_OBJS) main.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

test_vm: $(VM_OBJS) test_vm.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.c st.h
	$(CC) $(CFLAGS) -c $< -o $@

widgets.o tools.o main.o: ui.h tui.h
tui.o: tui.h
lex.o parse.o compiler.o fileio.o: lex.h
parse.o compiler.o: ast.h

# the base image: the kernel loaded from source and saved, so that st starts instantly (st uses it when it is
# newer than the kernel sources; a project image, st.image in the current directory, takes precedence).
kernel.image: st $(wildcard kernel*.st)
	./st -n -c /dev/null -e "Smalltalk snapshotAs: 'kernel.image'" > /dev/null

image: kernel.image

check: test_vm st kernel.image
	./test_vm
	ST_TEST_IMAGE=kernel.image ./test_vm

clean:
	rm -f *.o st test_vm kernel.image

.PHONY: all clean check image
