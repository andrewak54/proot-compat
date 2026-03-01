CC      = gcc
CFLAGS  = -shared -fPIC -O2 -Wall
LDFLAGS = -ldl

all: libfakechown.so

libfakechown.so: fakechown.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

install: libfakechown.so
	install -m 755 libfakechown.so /home/akulov/libfakechown.so
	install -m 755 tmux-wrapper.sh /usr/local/bin/tmux

clean:
	rm -f libfakechown.so

.PHONY: all install clean
