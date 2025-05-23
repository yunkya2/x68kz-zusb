#
# Makefile for jpegedx.x (jpeged.r cross-compile version)
#

CROSS = m68k-xelf-
HAS = run68 HAS.X
HASFLAGS = -w1
CC = $(CROSS)gcc
AS = $(CROSS)gcc
LD = $(CROSS)gcc
AR = $(CROSS)ar
RANLIB = $(CROSS)ranlib

GIT_REPO_VERSION=$(shell git describe --tags --always)

CFLAGS = -g -m68000 -I. -Os -DGIT_REPO_VERSION=\"$(GIT_REPO_VERSION)\"
ASFLAGS = -m68000 -I.
LDFLAGS =
ARFLAGS = rcs

TARGET = jpegedx.x
TARGETLIB = jpeged.a

COBJS += main.o

OBJS += jpeged.o
OBJS += jpeg.o
OBJS += error.o
OBJS += setqt.o
OBJS += load.o
OBJS += disp.o
OBJS += gethead.o
OBJS += getblock.o
OBJS += decode.o
OBJS += idct.o
OBJS += idct_y.o
OBJS += yuv.o
OBJS += scroll.o
OBJS += mk_mul_tbl.o
OBJS += huffman.o
OBJS += mes.o

# save.oをELF objにできないためビルド対象から外す
# セーブ処理を削除	
#OBJS += save.o
#OBJS += putblock.o encode.o dct.o vtoyuv.o

all: $(TARGET) $(TARGETLIB)

# リンクはELF形式で行う
$(TARGET): $(COBJS) $(TARGETLIB) 
	$(LD) $(LDFLAGS) -o $@ $^

$(TARGETLIB): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^
	$(RANLIB) $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# アセンブルはrun68を使ってHAS.Xで実行し、できた*.oをELF形式に変換する
%.o: %.s
	$(HAS) $(HASFLAGS) -o tmp.o $< && x68k2elf.py tmp.o $@ && rm tmp.o

clean:
	rm -f $(TARGET) $(TARGETLIB) $(OBJS) $(COBJS) *.elf

.NOTINTERMEDIATE: $(OBJS) $(COBJS)
.PHONY: all clean
