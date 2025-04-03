*
*
*       PutBlock.S
*
include  DOSCALL.MAC
include  JPEG.MAC
include  work.inc
*
	.text
*
	.xref	DCT
	.xref	ENCODE,VRAM_to_YUV,VRAM_to_YUV2,VRAM_to_YUV4
	.xref	Read_error
*
*
*
*
*  �J���[�o��
*
*    d6.w:i  �c���ײݐ�
*    a5.l:i  VRAM
*
.xdef	PutBlock
PutBlock
	*ܰ��ر������
	*--------------------------
	clr.w	-(sp)
	move.l	Scroll_Area(a6),a0
	adda.l	lx(a6),a0
	pea.l	(a0)
	move.l	Scroll_Area(a6),a0
	pea.l	(a0)

	*VRAM�ް���荞��
	*--------------------------
	btst.b	#5,Sys_flag2(a6)
	beq	GetVRAM

	*̧�ق�VRAM�ް���荞��
	*--------------------------
	move.w	DeltaY(a6),d4
	subq.w	#1,d4
GetF10
	clr.w	-(sp)
	move.l	a5,-(sp)
	move.w	VShandle(a6),-(sp)
	dos	_SEEK
	addq.w	#2+4+2,sp

	moveq.l	#0,d7
	move.w	Xline(a6),d7
	add.l	d7,d7
	move.l	d7,-(sp)
	move.l	a0,-(sp)
	move.w	VShandle(a6),-(sp)
	dos	_READ
	lea.l	4+4+2(sp),sp
	tst.l	d0
	bmi	Read_error
	cmp.l	d0,d7
	bne	Read_error

	adda.l	VSXbyte(a6),a5
	moveq.l	#0,d7
	move.w	Xline(a6),d7
	adda.w	d7,a0
	adda.w	d7,a0
	move.w	DeltaX(a6),d0
	divu.w	d0,d7
	swap.w	d7
	tst.w	d7
	beq	GetF40
	movea.l	a0,a1
	sub.w   d7,d0
	sub.w	d7,a1
	sub.w	d7,a1

	subq.w	#1,d0
GetF30
	move.w	(a1)+,(a0)+
	dbra	d0,GetF30
GetF40
	subq.w	#1,d6
	dbeq	d4,GetF10
	bne	GetV70
	subq.w	#1,d4
	bcs	GetV70
	bra	GetV45

	*��؂�VRAM�ް���荞��
	*--------------------------
GetVRAM
	move.w	DeltaY(a6),d4
	subq.w	#1,d4
GetV10
	move.l	a5,a4
	move.w	Xline(a6),d7
	subq.w	#1,d7
GetV20
	move.w	(a4)+,(a0)+
	dbra	d7,GetV20
	adda.l	VSXbyte(a6),a5
	moveq.l	#0,d7
	move.w	Xline(a6),d7
	move.w	DeltaX(a6),d0
	divu.w	d0,d7
	swap.w	d7
	tst.w	d7
	beq	GetV40
	movea.l	a0,a1
	sub.w   d7,d0
	sub.w	d7,a1
	sub.w	d7,a1

	subq.w	#1,d0
GetV30
	move.w	(a1)+,(a0)+
	dbra	d0,GetV30
GetV40

	subq.w	#1,d6
	dbeq	d4,GetV10
	bne	GetV70
	subq.w	#1,d4
	bcs	GetV70

GetV45
	move.l	Scroll_Area(a6),a1

GetV50
	move.w	BlkX(a6),d0
	subq.w	#1,d0
GetV60
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	dbra	d0,GetV60
	dbra	d4,GetV50
GetV70

	*�ۑ�
	*--------------------------
putb20

  cmp.b   #1,uvmode(a6)
  beq     putb1
  cmp.b   #2,uvmode(a6)
  beq     putb2

*
* �F�������P�^�S�̏ꍇ
*
*  ��P�E�Q�u���b�N�̓Ǎ�
*-------------------
	move.l	(sp),a0
	lea.l	Eydata1(a6),a1
	lea.l	Eudata1(a6),a2
	lea.l	Evdata1(a6),a3
	bsr	VRAM_to_YUV4
	add.l	#16*2,(sp)
*
*  ��R�E�S�u���b�N�̓Ǎ�
*--------------------
	move.l	4(sp),a0
	lea.l	Eydata3(a6),a1
	lea.l	Eudata1+8*4*4(a6),a2
	lea.l	Evdata1+8*4*4(a6),a3
	bsr	VRAM_to_YUV4
	add.l	#16*2,4(sp)
*
	lea.l	Eydata1+8*8*4(a6),a4
	bsr	DCT
	lea.l	Eydata2+8*8*4(a6),a4
	bsr	DCT
	lea.l	Eydata3+8*8*4(a6),a4
	bsr	DCT
	lea.l	Eydata4+8*8*4(a6),a4
	bsr	DCT
*
	lea.l	Eydata1(a6),a0
	lea.l	preDC(a6),a1
	lea.l	DCLtable(a6),a2
	lea.l	QtableL(a6),a5
	bsr	ENCODE
	tst.l	d0
	bmi	putb90
*
	lea.l	Eydata2(a6),a0
	lea.l	preDC(a6),a1
	lea.l	DCLtable(a6),a2
	lea.l	QtableL(a6),a5
	bsr	ENCODE
	tst.l	d0
	bmi	putb90
*
	lea.l	Eydata3(a6),a0
	lea.l	preDC(a6),a1
	lea.l	DCLtable(a6),a2
	lea.l	QtableL(a6),a5
	bsr	ENCODE
	tst.l	d0
	bmi	putb90
*
	lea.l	Eydata4(a6),a0
	lea.l	preDC(a6),a1
	lea.l	DCLtable(a6),a2
	lea.l	QtableL(a6),a5
	bsr	ENCODE
	tst.l	d0
	bpl	putb60
	bra	putb90
*
* �F�������P�^�Q�̏ꍇ
*
putb2
*  ��P�E�Q�u���b�N�̓Ǎ�
*-------------------
	move.l	(sp),a0
	lea.l	Eydata1(a6),a1
	lea.l	Eudata1(a6),a2
	lea.l	Evdata1(a6),a3
	bsr	VRAM_to_YUV2
	add.l	#16*2,(sp)
*
	lea.l	Eydata1+8*8*4(a6),a4
	bsr	DCT
	lea.l	Eydata2+8*8*4(a6),a4
	bsr	DCT
*
	lea.l	Eydata1(a6),a0
	lea.l	preDC(a6),a1
	lea.l	DCLtable(a6),a2
	lea.l	QtableL(a6),a5
	bsr	ENCODE
	tst.l	d0
	bmi	putb90
*
	lea.l	Eydata2(a6),a0
	lea.l	preDC(a6),a1
	lea.l	DCLtable(a6),a2
	lea.l	QtableL(a6),a5
	bsr	ENCODE
	tst.l	d0
	bpl	putb60
	bra	putb90
*
* �F�������P�^�P�̏ꍇ
*
putb1
*  ��P�u���b�N�̓Ǎ�
*-------------------
	move.l	(sp),a0
	lea.l	Eydata1(a6),a1
	lea.l	Eudata1(a6),a2
	lea.l	Evdata1(a6),a3
	bsr	VRAM_to_YUV
	add.l	#8*2,(sp)
*
	lea.l	Eydata1+8*8*4(a6),a4
	bsr	DCT
*
	lea.l	Eydata1(a6),a0
	lea.l	preDC(a6),a1
	lea.l	DCLtable(a6),a2
	lea.l	QtableL(a6),a5
	bsr	ENCODE
	tst.l	d0
	bmi	putb90

	tst.b	colormode(a6)
	bnz	putb80		*�ɸۉ摜�ł���̂ŐF���M���͏������Ȃ�
*
*  �F���M���̏���
*
putb60

	lea.l	Eudata1+8*8*4(a6),a4
	bsr	DCT
*
	lea.l	Evdata1+8*8*4(a6),a4
	bsr	DCT
*
	lea.l	Eudata1(a6),a0
	lea.l	preDC+2(a6),a1
	lea.l	DCCtable(a6),a2
	lea.l	QtableC(a6),a5
	bsr	ENCODE
	tst.l	d0
	bmi	putb90
*
	lea.l	Evdata1(a6),a0
	lea.l	preDC+4(a6),a1
	lea.l	DCCtable(a6),a2
	lea.l	QtableC(a6),a5
	bsr	ENCODE
	tst.l	d0
	bmi	putb90
*
putb80
	move.w	8(sp),d0
	add.w	DeltaX(a6),d0
	move.w	d0,8(sp)
	cmp.w	Xline(a6),d0
	bcs	putb20
	moveq.l	#0,d0
putb85
	lea.l	4+4+2(sp),sp
	rts
putb90
	moveq.l	#-1,d0
	bra	putb85
