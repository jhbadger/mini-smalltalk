CC ?= cc
CFLAGS ?= -O2 -Wall -Wno-unused-result -Wno-unused-function
LDFLAGS ?= -lm

VM_SRCS = object.c lex.c parse.c compiler.c interp.c prims.c fileio.c bignum.c
UI_SRCS = tui.c widgets.c tools.c
VM_OBJS = $(VM_SRCS:.c=.o)
UI_OBJS = $(UI_SRCS:.c=.o)

all: st

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

check: test_vm
	./test_vm

clean:
	rm -f *.o st test_vm

.PHONY: all clean check
