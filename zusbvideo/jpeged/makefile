
CC      = lc
AS      = as -z -m68000
ASFLAGS = 
LD      = link
HDRS    = mnp.h prot.h

.SUFFIXES:   .s

.s.o:
	${AS} ${ASFLAGS} $< -plst\\$<

all: jpeged.r 

jpeged.r: jpeg.o save.o putblock.o encode.o load.o disp.o gethead.o getblock.o \
          decode.o dct.o idct.o idct_y.o yuv.o vtoyuv.o  \
          scroll.o mk_mul_tbl.o Huffman.o mes.o error.o \
          jpeged.lnk
	hlk  -i jpeged.lnk
	cv jpeged.x

jpeg.o		: jpeg.s	jpeg.mac	work.inc	makefile
save.o  	: save.s	jpeg.mac	work.inc	makefile
putblock.o	: putblock.s	jpeg.mac	work.inc	makefile
encode.o	: encode.s	jpeg.mac	work.inc	makefile
load.o		: load.s	jpeg.mac	work.inc	makefile	keycode.inc
disp.o		: disp.s	jpeg.mac	work.inc	makefile
scroll.o	: scroll.s	jpeg.mac	work.inc	makefile	keycode.inc
gethead.o	: gethead.s	jpeg.mac	work.inc	makefile
getblock.o	: getblock.s	jpeg.mac	work.inc	makefile
decode.o	: decode.s	jpeg.mac	work.inc	makefile
Huffman.o	: Huffman.s	jpeg.mac	work.inc	makefile
vtoyuv.o	: vtoyuv.s			work.inc	makefile
dct.o		: dct.s				work.inc	makefile
idct.o		: idct.s			work.inc	makefile
idct_y.o	: idct_y.s			work.inc	makefile
yuv.o		: yuv.s	jpeg.mac		work.inc	makefile
mk_mul_tbl.o	: mk_mul_tbl.s	jpeg.mac	work.inc	makefile
mes.o		: mes.s
error.o		: error.s
