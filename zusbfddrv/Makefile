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

TARGETS = zusbfddrv.sys zusbfdboot1.hds zusbfdboot2.hds zusbfdformat.x
HEADERS = zusbfddrv.h
LDFLAGS = -nostartfiles -s
LIBS =

ifneq ($(DEBUG),)
CFLAGS += -DDEBUG
endif

all: $(TARGETS)

zusbfdboot1.hds: zusbfdboot1.bin bootloader.bin HUMAN.SYS
	./createhds.py $@ bootloader.bin HUMAN.SYS zusbfdboot1.bin

zusbfdboot2.hds: zusbfdboot2.bin bootloader.bin HUMAN.SYS
	./createhds.py $@ bootloader.bin HUMAN.SYS zusbfdboot2.bin

zusbfdboot1.bin: zusbfdboot1.sys
	./fixupsys.py $< $@

zusbfdboot2.bin: zusbfdboot2.sys
	./fixupsys.py $< $@

bootloader.bin: bootloader.o
	$(OBJCOPY) -O binary $< $@

zusbfdboot1.sys: head_boot.o zusbfddrv_boot1.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

zusbfdboot2.sys: head_boot.o zusbfddrv_boot2.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

zusbfddrv.sys: head.o zusbfddrv.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

zusbfdformat.x: zusbfdformat.o
	$(LD) -s -o $@ $^ $(LIBS)

head_boot.o: head.S
	$(AS) $(ASFLAGS) -o $@ -c $< -DCONFIG_BOOTDRIVER

zusbfddrv_boot1.o: zusbfddrv.c $(HEADERS)
	$(CC) $(CFLAGS) -o $@ -c $< -DCONFIG_BOOTDRIVER

zusbfddrv_boot2.o: zusbfddrv.c $(HEADERS)
	$(CC) $(CFLAGS) -o $@ -c $< -DCONFIG_BOOTDRIVER -DCONFIG_DRIVES=2

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $<

%.o: %.S
	$(AS) $(ASFLAGS) -c $<

install: ../build
	cp -p $(filter %.x,$(TARGETS)) ../build/bin
	cp -p $(filter %.sys,$(TARGETS)) ../build/sys
	cp -p $(filter %.hds,$(TARGETS)) ../build
	cp -p README.md ../build/doc/zusbfddrv.md

clean:
	-rm -f $(TARGETS) *.o *.sys *.elf *.x *.bin

.PHONY: all clean install
