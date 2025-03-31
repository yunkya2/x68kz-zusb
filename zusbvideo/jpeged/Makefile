#
# Makefile for jpegedx.x (jpeged.r cross-compile version)
#

CROSS = m68k-xelf-
HAS = run68 HAS.X
HASFLAGS = -w1
LD = $(CROSS)gcc
LDFLAGS = -nostdlib -e start

TARGET = jpegedx.x

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

all: $(TARGET)

# リンクはELF形式で行う
$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

# アセンブルはrun68を使ってHAS.Xで実行し、できた*.oをELF形式に変換する
%.o: %.s
	$(HAS) $(HASFLAGS) -o tmp.o $< && x68k2elf.py tmp.o $@

clean:
	rm -f $(TARGET) $(OBJS) *.elf

.NOTINTERMEDIATE: $(OBJS)
.PHONY: all clean
