TARGETS = zusb.x zusbhid.x zusbmsc.x zusbaudio.x zusbvideo.x zusbjoyc.x zusbcdplay.x
OBJS = $(TARGETS:.x=.o)
HEADERS = zusbmacro.h zusbtypes.h zusbregs.h
HEADERPATH = ../include

CC = m68k-xelf-gcc
CFLAGS = -Wall -O3 -I$(HEADERPATH)
LDFLAGS =
LIBS =

all: $(TARGETS)

%.x: %.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(TARGETS) $(OBJS) *.elf

.NOTINTERMEDIATE: $(OBJS)
.PHONY: all clean
