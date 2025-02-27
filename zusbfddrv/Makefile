#
# Copyright (c) 2024 Yuichi Nakamura (@yunkya2)
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

ifneq ($(DEBUG),)
CFLAGS += -DDEBUG
endif

all: zusbfddrv.sys zusbfdboot.hds zusbfdboot2.hds zusbfdformat.x

zusbfdboot.hds: zusbfdboot.bin bootloader.bin HUMAN.SYS
	./createhds.py $@ bootloader.bin HUMAN.SYS zusbfdboot.bin

zusbfdboot2.hds: zusbfdboot2.bin bootloader.bin HUMAN.SYS
	./createhds.py $@ bootloader.bin HUMAN.SYS zusbfdboot2.bin

zusbfdboot.bin: zusbfdboot.sys
	./fixupsys.py $< $@

zusbfdboot2.bin: zusbfdboot2.sys
	./fixupsys.py $< $@

bootloader.bin: bootloader.o
	$(OBJCOPY) -O binary $< $@

zusbfdboot.sys: head_boot.o zusbfddrv_boot.o
	$(LD) -o $@ $^ -nostartfiles -s

zusbfdboot2.sys: head_boot.o zusbfddrv_boot2.o
	$(LD) -o $@ $^ -nostartfiles -s

zusbfddrv.sys: head.o zusbfddrv.o
	$(LD) -o $@ $^ -nostartfiles -s

zusbfdformat.x: zusbfdformat.o
	$(LD) -o $@ $^ -s

head_boot.o: head.S
	$(AS) $(ASFLAGS) -o $@ -c $< -DCONFIG_BOOTDRIVER

zusbfddrv_boot.o: zusbfddrv.c
	$(CC) $(CFLAGS) -o $@ -c $< -DCONFIG_BOOTDRIVER

zusbfddrv_boot2.o: zusbfddrv.c
	$(CC) $(CFLAGS) -o $@ -c $< -DCONFIG_BOOTDRIVER -DCONFIG_DRIVES=2

zusbfddrv.o: zusbfddrv.h
zusbfddrv_boot.o: zusbfddrv.h
zusbfddrv_boot2.o: zusbfddrv.h

%.o: %.c
	$(CC) $(CFLAGS) -c $<

%.o: %.S
	$(AS) $(ASFLAGS) -c $<

clean:
	-rm -f *.o *.sys *.elf* *.x *.bin *.hds

.PHONY: all clean release
