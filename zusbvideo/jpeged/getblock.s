*
*
*       GETBLOCK.S
*
*
*
	include	DOSCALL.MAC
	include IOCSCALL.MAC
	include	JPEG.MAC
	include	work.inc

	.text

	.xref	IDCT			'IDCT.S'
	.xref	IDCT_Y			'IDCT_Y.S'
	.xref	YUV_to_RGB		'YUV.S'
	.xref	YUV_to_RGB2		'YUV.S'
	.xref	YUV_to_RGB4		'YUV.S
	.xref	DecodeDCAC		'DECODE.S'
	.xref	preDECODE		'DECODE.S'
	.xref	Zigzag,Zigzag_Y		'MES.S'
	.xref	inkey			'LOAD.S'
	.xref	close_temp		'LOAD.S'
	.xref	work_adrs		'JPEG.S'
	.xref	clear_area		'JPEG.S'
	.xref   make_YUV_RGB_table	'MK_MUL_TBL.S'
	.xref	make_IDCT_table		'MK_MUL_TBL.S'
	.xref	make_RGB_table		'MK_MUL_TBL.S'
	.xref	make_interval_work	'MK_MUL_TBL.S'
	.xref	Write_error		'ERROR.S'
	.xref	set_HOME		'LOAD.S'
	.xref	calc_XY_dots		'SCROLL.S'
	.xref	COS_TBL_adrs
	.xref	Disp_Pic_Position	'GETHEAD.S'
	.xref	GetBuf			'Decode.s'

	.xdef	GetBlock

******************************************************************************
*
*	�F���M���̓��̓}�N��
*
******************************************************************************
DecodeUV	macro	label,stack_depth
		local	DecodeUV1,DecodeUV2

  lea     udata1+6*16+1*2(a6),a0

	lea.l	DCC_DECODE_TBL(a6),a1
	lea	preDC+2(a6),a2
	lea.l	Zigzag(pc),a3
	lea	UQC_tbl(a6),a4
	bsr	DecodeDCAC

	move.w	d4,-(sp)
*
  lea     vdata1+6*16+1*2(a6),a0

*	lea.l	DCC_DECODE_TBL(a6),a1
	lea	preDC+4(a6),a2
	lea.l	Zigzag(pc),a3
	lea	UQC_tbl(a6),a4
	bsr	DecodeDCAC

	move.w	d4,-(sp)

	movem.w	d1/d5-d6,FFxxFlag(a6)	d1=FFxxFlag d5=rdata d6=rlen
	movem.l	d7/a5,LastBufSize(a6)	d7=LastBufSize,LastFFxxSize a5=bufadr

	move.w	y1(a6),d0		2(sp),d0
	add.w	DeltaY(a6),d0
	cmp.w	YS(a6),d0
	bcs	DecodeUV1

	move.w	x1(a6),d0		(sp),d0
	add.w	DeltaX(a6),d0
	cmp.w	XS(a6),d0
	bcc	DecodeUV2
DecodeUV1:
	lea.l	stack_depth(sp),sp
	bra	label
DecodeUV2:
	endm

******************************************************************************
*  �J���[����
*
*      (sp) = �W�J�ް��i�[���ڽ
*     4(sp) = �������ۯ��̓W�J�ް��i�[���ڽ
******************************************************************************
GetBlock

*��Z�e�[�u���E�n�t�}�������e�[�u���쐬
*---------------------------------
GetBlock_make_table

		bsr	make_IDCT_table
		bsr	make_YUV_RGB_table
		bsr	make_RGB_table

*�摜�ʒu��񏉊���
*---------------------------------
		clr.w	HX(a6)
		clr.w	HY(a6)

		movem.w	Interval(a6),d0-d1
		bsr	calc_XY_dots

	*X�ʒu��񏉊���
	*------------------------
		move.w	XL2(a6),d7
		cmp.w	#512,Xline(a6)
		bcc	@f
		move.w	Xline(a6),d7
		lsr.w	d7
@@
		clr.w	Home_X(a6)
		move.w	HS(a6),Home_FX(a6)
		move.w	d7,MOUSE_X(a6)
		move.w	d7,MOUSE_TX(a6)

	*Y�ʒu��񏉊���
	*------------------------
		move.w	YL2(a6),d7
		cmp.w	#512,Yline(a6)
		bcc	@f
		move.w	Yline(a6),d7
		lsr.w	d7
@@
		clr.w	Home_Y(a6)
		move.w	VS(a6),Home_FY(a6)
		move.w	d7,MOUSE_Y(a6)
		move.w	d7,MOUSE_TY(a6)

		move.w	HE(a6),d7
		sub.w	HS(a6),d7
		addq.w	#1,d7
		bsr     make_interval_work

*���[�N�G���A�쐬
*--------------------------------
	move.l	Scroll_Area(a6),d0
	move.l	lx(a6),d1
	add.l	d0,d1
	move.l	d1,-(sp)		4(sp)
	move.l	d0,-(sp)		 (sp)

	move.w	Interval+4(a6),d0
	move.w	Interval+6(a6),d1
	lsr.w	#1,d1
	add.w	d1,d0
	move.w	d0,yi(a6)		-(sp) *  yi	 6(sp)
	move.w	VS(a6),v(a6)		-(sp)		 4(sp)
	clr.w	y1(a6)			-(sp)			 2(sp),0(sp)
	clr.w	x1(a6)			-(sp)			 2(sp),0(sp)

	bsr	preDECODE	�f�[�^�ǂݍ��ݏ����i�n�t�}�������j
	bra	Getb1stBlock

*�W�J�\��
*--------------------------------
getb10

	bsr	inkey
	tst.l	d0
	bmi	exit

   btst.b   #4,Sys_flag(a6)
   beq      getb11			�摜�W�J�ޯ̧��1ײݕ��̂�

	move.l	Scroll_Area(a6),d0
	move.l	d0,(sp)
	add.l	lx(a6),d0
	move.l	d0,4(sp)

getb11

	clr.w	x1(a6)

getb20
	movem.w	FFxxFlag(a6),d1/d5-d6	d1=FFxxFlag d5=rdata d6=rlen
	movem.l	LastBufSize(a6),d7/a5	d7=LastBufSize,LastFFxxSize a5=bufadr
	tst.w	d7
	bnz	Getb1stBlock		�܂�$FF�܂œǂݍ���ł��Ȃ�

	bsr	GetBuf
	addq.w	#1,d7
	move.w	rlen(a6),d6
	bnz	Getb1stBlock		$FFDx�ł͂Ȃ�����
	
	subq.w	#1,d7
	move.b	(a5)+,d5
	moveq.l	#8,d6

	*��P�u���b�N�̓���
	*--------------------------
Getb1stBlock

      lea     ydata1+7*16+1*2(a6),a0
      lea     DCL_DECODE_TBL(a6),a1
      lea     preDC(a6),a2
	lea.l	Zigzag_Y(pc),a3
      lea     UQL_tbl(a6),a4
      bsr     DecodeDCAC
      move.w  d4,-(sp)

      cmp.b   #1,uvmode(a6)
      beq     getb60

	*��Q�u���b�N�̓���
	*-----------------------------
      lea     ydata2+7*16+1*2(a6),a0
*	lea.l	DCL_DECODE_TBL(a6),a1
      lea     preDC(a6),a2
	lea.l	Zigzag_Y(pc),a3
      lea     UQL_tbl(a6),a4
      bsr     DecodeDCAC

	move.w	d4,-(sp)
*
      cmp.b   #2,uvmode(a6)
      beq     getb50

	*��R�u���b�N�̓���
	*----------------------------------
      lea     ydata3+7*16+1*2(a6),a0
*	lea.l	DCL_DECODE_TBL(a6),a1
      lea     preDC(a6),a2
	lea.l	Zigzag_Y(pc),a3
      lea     UQL_tbl(a6),a4
      bsr     DecodeDCAC

	move.w	d4,-(sp)

	*��S�u���b�N�̓���
	*-----------------------------------
      lea     ydata4+7*16+1*2(a6),a0
*	lea.l	DCL_DECODE_TBL(a6),a1
      lea     preDC(a6),a2
	lea.l	Zigzag_Y(pc),a3
      lea     UQL_tbl(a6),a4
      bsr     DecodeDCAC

	move.w	d4,-(sp)
*
*
*  �P�^�S�ɊԈ����ꂽ�f�[�^
*----------------------------------------
	DecodeUV	getb45,2*6


	move.w	2+2+2+2+2(sp),d0
	lea	ydata1(a6),a0
	move.l	COS_TBL_adrs(pc),a6
      bsr     IDCT_Y

      move.w  2+2+2+2(sp),d0
      lea     ydata2-ydata1(a0),a0
      bsr     IDCT_Y

      move.w  2+2+2(sp),d0
      lea     ydata3-ydata2(a0),a0
      bsr     IDCT_Y

      move.w  2+2(sp),d0
      lea     ydata4-ydata3(a0),a0
      bsr     IDCT_Y

      move.w  2(sp),d0
      lea     udata1-ydata4(a0),a0
      bsr     IDCT

      move.w  (sp),d0
      lea     vdata1-udata1(a0),a0
      bsr     IDCT

      movem.w  (sp)+,d0-d5

	moveq.l	#63*2,d6
	sub.w	d6,d0
	clr.w	d0
	addx.w	d0,d0
	sub.w	d6,d1
	addx.w	d0,d0
	move.w	d0,d1

	sub.w	d6,d2
	addx.w	d0,d0
	sub.w	d6,d3
	roxl.w	#3,d0

	sub.w	d6,d4
	addx.w	d1,d1
	sub.w	d6,d5
	roxl.w	#3,d1

      movea.l (sp),a0

      move.l   work_adrs(pc),a6
      move.w  d0,-(sp)
      lea     ydata1(a6),a1
      lea     vdata1(a6),a3
	bsr	YUV_to_RGB4

      move.w  (sp)+,d1

      movea.l  4(sp),a0
      move.l  work_adrs(pc),a6
      lea     ydata3(a6),a1
      lea     vdata1+32*2(a6),a3
	bsr     YUV_to_RGB4

getb45
      add.l   #128*2,(sp)
      add.l   #128*2,4(sp)

      bra     getb80
*
*  �P�^�Q�ɊԈ����ꂽ�f�[�^
*------------------------------------
getb50
	DecodeUV	getb55,2*4
*
	move.w	2+2+2(sp),d0
	lea	ydata1(a6),a0
	move.l	COS_TBL_adrs(pc),a6
      bsr     IDCT_Y

      move.w  2+2(sp),d0
      lea     ydata2-ydata1(a0),a0
      bsr     IDCT_Y

      move.w  2(sp),d0
      lea     udata1-ydata2(a0),a0
      bsr     IDCT

      move.w  (sp),d0
      lea     vdata1-udata1(a0),a0
      bsr     IDCT

      movem.w  (sp)+,d0-d3

	moveq.l	#63*2,d6
	sub.w	d6,d2
	clr.w	d2
	addx.w	d2,d2
	sub.w	d6,d3
	addx.w	d2,d2

	sub.w	d6,d1
	addx.w	d2,d2
	sub.w	d6,d0
	roxl.w	#3,d2

      move.l  (sp),a0
      move.l  work_adrs(pc),a6
      lea     ydata1(a6),a1
      lea     vdata1(a6),a3
      bsr     YUV_to_RGB2

getb55
      add.l   #128*2,(sp)
      bra     getb80
*
*  �Ԉ�����Ă��Ȃ��f�[�^
*
getb60

	tst.b	colormode(a6)
	beq	getb60_color	*color�摜�ł���

	*�ɸۉ摜�p�W�J
	*------------------------------
		movem.w	d1/d5-d6,FFxxFlag(a6)	d1=FFxxFlag d5=rdata d6=rlen
		movem.l	d7/a5,LastBufSize(a6)	d7=LastBufSize,LastFFxxSize a5=bufadr


		clr.w	udata1+0*8*2(a6)
		clr.w	udata1+4*8*2(a6)
		clr.w	vdata1+0*8*2(a6)
		clr.w	vdata1+4*8*2(a6)

		move.w	(sp),d0
		lea	ydata1(a6),a0
		move.l	COS_TBL_adrs(pc),a6
		bsr	IDCT_Y

		move.w	(sp)+,d2
		moveq.l	#63*2,d6
		sub.w	d6,d2
		clr.w	d2
		roxl.w	#2+3,d2

		move.l	(sp),a0
		move.l	work_adrs(pc),a6
		lea	ydata1(a6),a1
		lea	vdata1(a6),a3
		bsr	YUV_to_RGB
		add.l	#128,(sp)
		*�ɸۉ摜��p ���̉������̈ʒu
		*------------------------------
		movea.l	work_adrs(pc),a6
		move.w	x1(a6),d0		(sp),d0
		add.w	DeltaX(a6),d0
		move.w	d0,x1(a6)		(sp)
		cmp.w	Xline(a6),d0
		bcc	getb90			�������̓W�J�I��

		movem.w	FFxxFlag(a6),d1/d5-d6	d1=FFxxFlag d5=rdata d6=rlen
		movem.l	LastBufSize(a6),d7/a5	d7=LastBufSize,LastFFxxSize a5=bufadr
		bra	Getb1stBlock

	*�װ�Ԉ����Ȃ��摜�p�W�J
	*------------------------------
getb60_color

	DecodeUV	getb65,2*3

	move.w	2+2(sp),d0
	lea	ydata1(a6),a0
	move.l	COS_TBL_adrs(pc),a6
      bsr     IDCT_Y

      move.w  2(sp),d0
      lea     udata1-ydata1(a0),a0
      bsr     IDCT

      move.w  (sp),d0
      lea     vdata1-udata1(a0),a0
      bsr     IDCT

      movem.w  (sp)+,d0-d2
	moveq.l	#63*2,d6
	sub.w	d6,d2
	clr.w	d2
	addx.w	d2,d2

	sub.w	d6,d1
	addx.w	d2,d2
	sub.w	d6,d0
	roxl.w	#3,d2

      move.l  (sp),a0
      move.l  work_adrs(pc),a6
      lea     ydata1(a6),a1
      lea     vdata1(a6),a3
      bsr     YUV_to_RGB

getb65
      add.l   #128,(sp)



*���̉������̈ʒu
*------------------------------
getb80
      movea.l work_adrs(pc),a6
      move.w  x1(a6),d0			(sp),d0
      add.w   DeltaX(a6),d0
      move.w  d0,x1(a6)			(sp)
      cmp.w   Xline(a6),d0
      bcs     getb20			�܂��������̓W�J�͏I����Ă��Ȃ�

*�����؂ɓW�J�ް�����������
*------------------------------
getb90
      btst.b  #2,Sys_flag(a6)
      beq     getb90_next_ScrollArea	�����؂ɓW�J���Ȃ�

      move.w  BlkX(a6),d1
      mulu.w  DeltaY(a6),d1
      lsl.l   #3+1,d1
      move.l  d1,-(sp)
      move.l  Scroll_Area(a6),-(sp)
      move.w  temp_handle(a6),-(sp)
      dos     _WRITE
      lea.l   10(sp),sp
      cmp.l   d0,d1
      beq     getb90_next_ScrollArea	�S���������߂�

	bsr	close_temp		�������߂Ȃ��̂������؂��폜

*�摜�\��
*------------------------------
getb90_next_ScrollArea

      move.w  y1(a6),d2		2(sp),d2
      move.w  v(a6),d3		4(sp),d3
      move.w  yi(a6),d4		6(sp),d4
      move.l  (sp),a0
      sub.l   lx(a6),a0
      move.w  HS(a6),a3
      bsr     GetPart

    cmp.b   #3,uvmode(a6)
    bne     getb92

      move.l  4(sp),a0
      move.l  lx(a6),d0
      sub.l   d0,a0
      add.l   d0,(sp)
      add.l   d0,4(sp)
      bsr     GetPart

getb92
      move.w  d4,yi(a6)		6(sp)
      move.w  d2,y1(a6)		2(sp)
      move.w  d3,v(a6)		4(sp)

*��ʂ�ΰшʒu��ݒ�
*----------------------------
      btst    #4,Sys_flag2(a6)
      bne     getb93			���z��ʂɑ΂��ēW�J
      btst.b  #3,Sys_flag2(a6)
      bne     getb93			�ʒu�w�肠��

      cmp.w   VSYsize(a6),d3
      blt     getb93

	and.w	#$1ff,d3
	moveq.l	#0,d2
	bsr	set_HOME

	move.w	y1(a6),d0
	sub.w	YL(a6),d0
	add.w	YL2(a6),d0
	move.w	d0,MOUSE_TY(a6)
	move.w	d0,MOUSE_Y(a6)
	bsr	Disp_Pic_Position

getb93

*���̏c�����̈ʒu
*-------------------------------
	move.w	y1(a6),d2		2(sp),d2
	cmp.w	Yline(a6),d2
	blt	getb10

*����I��
*--------------------------------
	moveq.l	#0,d0

Getblock_end

	addq.l	#8,sp
	rts

*�����I��
*--------------------------------
exit
	moveq.l	#-1,d0
	bra	Getblock_end


******************************************************************************
*
*  �����\��
*
*    d2.w:i  y
*    d3.w:i  vy
*    d4.w:i  yi
*    a0.l:i  vwork
*    a2.l:i  vram address
******************************************************************************
.xdef GetPart
GetPart

  cmp.w   Yline(a6),d2
  bcc     GetPart100

* a2.l = VRAM���ڽ
*-------------------------
   movea.l VSadr(a6),a2
   adda.l  a3,a2
   adda.l  a3,a2

   moveq.l #0,d0
   move.w  d3,d0
   divu.w  VSYsize(a6),d0
   swap.w  d0
   mulu.w  VSXsize(a6),d0
   add.l   d0,d0
   adda.l  d0,a2

   move.w  XS(a6),d0
   moveq.l #$07,d1
   and.w   d0,d1
   and.w   #$fff8,d0
   add.w   d1,d1
   lsl.w   #6+1-3,d0
   adda.w  d1,a0
   adda.w  d0,a0
*
*-------------------------
  moveq.l #8-1,d7
  move.w  VE(a6),d1
  move.b  Sys_flag2(a6),d6
  move.l  VSXbyte(a6),d5
  move.l  GETP_adrs(a6),a1
getp40
    cmp.w   YS(a6),d2
    bcs     getp95
*
getp45
    cmp.w   Interval+6(a6),d4
    bcs     getp90
 
      btst    #4,d6
      bne     getp80			���z��ʂɑ΂��ēW�J
      btst    #3,d6
      bne     getp80			�ʒu�w�肠��
 
*--- �ʒu�w�薳���A�X�N���[���Ή� ---

      movea.l a2,a5
      movea.l a0,a4
      jsr     (a1)
      adda.l  d5,a2			1line��
      sub.w   Interval+6(a6),d4
      addq.w  #1,d3
      cmp.l   #$c00000+512*512*2,a2
      bcs     getp45
      sub.l   #512*512*2,a2
     bra     getp45

*���z��ʁA�ʒu�w��L��A�X�N���[�����Ȃ�
*--------------------------------
getp80
	btst	#5,d6
	bne	getp81			���z��ʃt�@�C���ɑ΂��ēW�J
	cmp.w	d3,d1
	bcs	getp85
	movea.l	a2,a5
	movea.l	a0,a4
	jsr	(a1)
	bra	getp85

*���z��ʃt�@�C���ɑ΂��ēW�J
*--------------------------------
getp81
      cmp.w   d3,d1
      bcs     getp85

	*�w��ʒu�܂ŃV�[�N
	*-----------------------------
	clr.w	-(sp)
	pea.l	(a2)
	move.w	VShandle(a6),-(sp)
	dos	_SEEK
	addq.w	#2+4+2,sp
	tst.l	d0
	bpl	getp_VSF50	�V�[�N�o����
	cmp.w	#-25,d0
	bne	Write_error

	*�w��ʒu�܂ŃV�[�N�o���Ȃ��̂ŁA�o���鏊�܂ŃV�[�N
	*-----------------------------
	move.w	#2,-(sp)
	clr.l	-(sp)
	move.w	VShandle(a6),-(sp)
	dos	_SEEK
	addq.w	#2+4+2,sp
	tst.l	d0
	bmi	Write_error

	*�w��ʒu�܂łO���������ނ��߂�ܰ��ر�쐬
	*-----------------------------
	movea.l	VSFile_buf_adrs(a6),a5
	move.l	VSFile_buf_size(a6),d5
	bsr	clear_area

	*�w��ʒu�܂łO����������
	*-----------------------------
	move.l	a2,d5
	sub.l	d0,d5				d5=�������ރo�C�g��
	move.l	VSFile_buf_size(a6),d0
	movea.l	VSFile_buf_adrs(a6),a5
	bsr	write_nbytes

	*�摜�ް��W�J
	*--------------------------------
getp_VSF50
	move.l	VSXbyte(a6),d5
	movea.l	VSFile_buf_adrs(a6),a5
	movea.l	a0,a4
	jsr	(a1)

	*�摜�ް����t�@�C���ɏo��
	*--------------------------------
	move.l	VSFile_buf_size(a6),d5
	movea.l	VSFile_buf_adrs(a6),a5
	bsr	GetPart_VSF_sub
	move.l	VSXbyte(a6),d5

*����ײ݂̏�����
*--------------------------------
getp85
	adda.l	d5,a2			1line��
	sub.w	Interval+6(a6),d4
	addq.w	#1,d3
	bra	getp45

getp90
    add.w   Interval+4(a6),d4
getp95
    lea     16(a0),a0
    addq.w  #1,d2
    cmp.w   Yline(a6),d2
    dbcc    d7,getp40
GetPart100
  rts




.xdef	write_nbytes
write_nbytes
	sub.l	d0,d5
	bls	write_nbytes_10

	movem.l	d0/d5,-(sp)
	move.l	d0,d5
	bsr	GetPart_VSF_sub
	movem.l	(sp)+,d0/d5
	bra	write_nbytes

write_nbytes_10
	add.l	d0,d5

GetPart_VSF_sub

	*�摜�ް����t�@�C���ɏo��
	*--------------------------------
	move.l	d5,-(sp)
	move.l	a5,-(sp)
	move.w	VShandle(a6),-(sp)
	dos	_WRITE
	lea.l	4+4+2(sp),sp
	tst.l	d0
	bmi	Write_error
	cmp.l	d5,d0
	bne	Write_error
	rts


  .end
