#
# Copyright (c) 2025 Yuichi Nakamura (@yunkya2)
#
# The MIT License (MIT)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

CROSS = m68k-xelf-
CC = $(CROSS)gcc
AS = $(CROSS)gcc
LD = $(CROSS)gcc
OBJCOPY = $(CROSS)objcopy

GIT_REPO_VERSION=$(shell git describe --tags --always)

CFLAGS = -g -m68000 -I. -Os -DGIT_REPO_VERSION=\"$(GIT_REPO_VERSION)\"
CFLAGS += -I../include
ASFLAGS = -m68000 -I.

TARGET = zusbvideo.x
OBJS = $(TARGET:.x=.o)
HEADERS = zusbfunc.h zusbtypes.h zusbregs.h
LDFLAGS = -s
LIBS = jpeged.a

all: $(TARGET)
	-cp $(TARGET) /mnt/c/X68000Z/HFS/

%.x: %.o $(LIBS)
	$(LD) $(LDFLAGS) -o $@ $< $(LIBS)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $<

jpeged.a:
	$(MAKE) makelib
	cp jpeged/$@ .

makelib:
	$(MAKE) -C jpeged

install: ../build
	cp -p $(TARGET) ../build/bin
	cp -p README.md ../build/doc/zusbvideo.md

clean:
	rm -f $(TARGET) $(OBJS) *.elf

cleanlib: clean
	rm -f jpeged.a
	$(MAKE) -C jpeged clean

.NOTINTERMEDIATE: $(OBJS)
.PHONY: all clean install makelib
