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
TSRGEN = ../libtsr/bin/$(CROSS)tsrgen

GIT_REPO_VERSION=$(shell git describe --tags --always)

CFLAGS = -g -m68000 -I. -Os -DGIT_REPO_VERSION=\"$(GIT_REPO_VERSION)\"
CFLAGS += -I../include
CFLAGS += -I../libtsr/include -D__DOS_INLINE__ -D__IOCS_INLINE__
ASFLAGS = -m68000 -I.

TARGETS = zusbscsi.x
HEADERS = zusbscsi.h zusbscsi_internal.h zusbmodrv.h
HEADERS += ../libtsr/include/x68k/tsr.h ../libtsr/include/x68k/dos_internal.h
LDFLAGS = -s -specs=nano.specs
LIBS =

ifneq ($(DEBUG),)
CFLAGS += -DDEBUG
endif

all: $(TARGETS)

zusbscsi.x: zusbscsi_main.o zusbscsi_resident.o ../libtsr/lib/libx68ktsr.a
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

zusbscsi_resident.o: zusbscsi.o scsiiocs.o ../libtsr/lib/libx68ktsr.a
	$(TSRGEN) -u zusbscsi_initialize -o $@ $< scsiiocs.o

../libtsr/lib/libx68ktsr.a:
	$(MAKE) -C ../libtsr all

zusbmodrv.x: zusbmodrv_main.o zusbmodrv_resident.o ../libtsr/lib/libx68ktsr.a
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

zusbmodrv_resident.o: zusbmodrv.o ../libtsr/lib/libx68ktsr.a
	$(TSRGEN) -u interrupt -o $@ $<

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $<

%.o: %.S
	$(AS) $(ASFLAGS) -c $<

install: ../build
	cp -p $(TARGETS) ../build/sys
	cp -p README.md ../build/doc/zusbscsi.md

clean:
	-rm -f $(TARGETS) *.o *.elf

.PHONY: all clean install
