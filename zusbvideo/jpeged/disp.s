******************************************************************************
*
*	画面表示関係ｻﾌﾞﾙｰﾁﾝ
*
******************************************************************************
	include	DOSCALL.MAC
	include	IOCSCALL.MAC
	include  work.inc

	.xref	msgCR,msgBar
	.xref	Info_msg,spc8_msg
	.xref	color_msg,mono_msg
	.xref	DecodeNowMsg
	.xref	DecodeNormalMsg
	.xref	DecodeErrorMsg

	.text

******************************************************************************
*
*  画像情報を表示
*
******************************************************************************
.xdef Disp_Pic_Info
Disp_Pic_Info
		movem.l	d0-d7/a0,-(sp)

*固定ﾒｯｾｰｼﾞ表示
*----------------------------
	*画像情報固定ﾒｯｾｰｼﾞ表示
	*---------------------
		*カーソル位置(0,0)設定
		*---------------------
		clr.l	-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL
		addq.l	#6,sp

		*固定ﾒｯｾｰｼﾞ表示
		*-----------------------
		pea.l	Info_msg(pc)
		DOS	_PRINT
		addq.l	#4,sp

	*バー表示
	*----------------------------
		*カーソル位置(0,6)設定
		*---------------------
		move.l	#$0000_0006,-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL

		*バー表示
		*----------------------------
		moveq.l	#32-1,d7
		pea.l	msgBar(pc)
@@
		DOS	_PRINT
		dbra	d7,@b

		lea.l	10(sp),sp

*画像情報表示
*----------------------------
	*ﾌｧｲﾙ名(9,0)に表示
	*--------------------------
		move.l	#$0009_0000,-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL
		addq.l	#6,sp

		pea.l	fname(a6)
		DOS	_PRINT
		pea.l	msgCR(pc)
		DOS	_PRINT
		addq.l	#8,sp

	*画像ｻｲｽﾞ(9,1)に表示
	*-------------------------
		move.l	#$0009_0001,-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL
		addq.l	#6,sp

		move.w	Xline(a6),d0
		bsr	PrintW
		move.w	#'x',-(sp)
		DOS	_PUTCHAR
		addq.l	#2,sp
		move.w	Yline(a6),d0
		bsr	PrintW

	*画像密度(9,2)
	*---------------------
		move.l	#$0009_0002,-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL
		addq.l	#6,sp

		move.w	Aspect(a6),d0
		bsr	PrintW
		move.w	#':',-(sp)
		DOS	_PUTCHAR
		addq.l	#2,sp
		move.w	Aspect+2(a6),d0
		bsr	PrintW

	*画像精度(9,3)
	*---------------------
		move.l	#$0009_0003,-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL
		addq.l	#6,sp

		moveq.l	#0,d0
		move.b	Qlevel_source(a6),d0
		bsr	PrintW

	*色成分間引き率(9,4)
	*---------------------
		move.l	#$0009_0004,-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL

		move.w	#'1',(sp)
		DOS	_PUTCHAR
		move.w	#'/',(sp)
		DOS	_PUTCHAR

		addq.l	#6,sp

		moveq.l	#$0f,d1
		and.b	uvmode_source(a6),d1
		moveq.l	#0,d0
		move.b	uvmode_source(a6),d0
		lsr.b	#4,d0
		mulu.w	d1,d0
		bsr	PrintW

	*作成日付(41,1)
	*---------------------
		move.l	#$0029_0001,-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp

		*年
		*----------------
		move.w	#$00fe,d0
		and.b	fdate(a6),d0
		lsr.b	d0
		add.w	#1980,d0
		bsr	PrintW
		move.w	#'-',(sp)
		DOS	_PUTCHAR

		*月
		*----------------
		move.w	#$01e0,d0
		and.w	fdate(a6),d0
		lsr.w	#5,d0
		bsr	Print2keta
		DOS	_PUTCHAR

		*日
		*----------------
		moveq.l	#$001f,d0
		and.b	fdate+1(a6),d0
		bsr	Print2keta
		move.w	#' ',(sp)
		DOS	_PUTCHAR

		*時
		*----------------
		move.w	#$f8,d0
		and.b	fdate+2(a6),d0
		lsr.b	#3,d0
		bsr	Print2keta
		move.w	#':',(sp)
		DOS	_PUTCHAR

		*分
		*----------------
		move.w	#$07e0,d0
		and.w	fdate+2(a6),d0
		lsr.w	#5,d0
		bsr	Print2keta
		move.w	#':',(sp)
		DOS	_PUTCHAR
		addq.l	#2,sp

		*秒
		*----------------
		moveq.l	#$01f,d0
		and.b	fdate+3(a6),d0
		bsr	Print2keta


	*色(41,2)
	*---------------------
		move.l	#$0029_0002,-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL
		addq.l	#6,sp

		lea.l	color_msg(pc),a0

		tst.b	colormode(a6)
		beq	@f
		lea.l	mono_msg(pc),a0
@@
		move.l	a0,-(sp)
		DOS	_PRINT
		addq.l	#4,sp

		bsr	Disp_Pic_Zoom
		bsr	Disp_Pic_Position

	*展開状態表示(9,5)
	*-----------------------
		move.l	#$0009_0005,-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL
		addq.l	#4+2,sp

		move.b	DecodeStatus(a6),d0
		lea.l	DecodeNowMsg(pc),a0
		cmp.b	#1,d0
		bcs	@f
		lea.l	DecodeNormalMsg(pc),a0
		beq	@f
		lea.l	DecodeErrorMsg(pc),a0
@@
		move.l	a0,-(sp)
		DOS	_PRINT
		addq.l	#4,sp

*ﾒｯｾｰｼﾞ表示(0,7)
*---------------------
		moveq.l	#31-7,d3	d2=表示行数

		move.w	d3,-(sp)
		move.w	#7,-(sp)
		move.w	#15,-(sp)
		DOS	_CONCTRL
		addq.l	#6,sp

		move.w	imsg_handle(a6),d1
		bmi	imsg_disp_end

		move.w	#1,-(sp)
		clr.l	-(sp)
		move.w	d1,-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		move.l	d0,-(sp)

		clr.w	-(sp)
		move.l	imsg_start_point(a6),-(sp)
		move.w	d1,-(sp)
		DOS	_SEEK

		move.l	imsg_size(a6),d2
		beq	4f
1
		move.w	d1,(sp)
		DOS	_FGETC

		cmp.b	#$0d,d0
		beq	3f
		cmp.b	#$0a,d0
		bne	2f

		pea	msgCR(pc)
		dos	_PRINT
		addq.l	#4,sp
		subq.l	#1,d3
		bne	3f
		bra	4f
2
		move.w	d0,(sp)
		DOS	_PUTCHAR
3
		subq.l	#1,d2
		bnz	1b
4
		addq.l	#8,sp

		move.l	(sp)+,d0
		clr.w	-(sp)
		move.l	d0,-(sp)
		move.w	d1,-(sp)
		DOS	_SEEK
		addq.l	#8,sp

imsg_disp_end
		move.w	#31,-(sp)
		move.w	#0,-(sp)
		move.w	#15,-(sp)
		DOS	_CONCTRL
		addq.l	#6,sp

		movem.l	(sp)+,d0-d7/a0
		rts

******************************************************************************
*
*  画像倍率を表示
*
******************************************************************************
.xdef Disp_Pic_Zoom
Disp_Pic_Zoom

		btst.b	#0,Sys_flag3(a6)
		beq	Disp_Pic_Zoom_end

		movem.l	d0-d7,-(sp)

	*倍率(41,4)
	*---------------------
		move.l	#$0029_0004,-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL
		addq.l	#6,sp

		move.w	Interval(a6),d0
		bsr	PrintW
		move.w	#'/',-(sp)
		DOS	_PUTCHAR

		move.w	Interval+2(a6),d0
		bsr	PrintW

		pea.l	spc8_msg(pc)
		DOS	_PRINT

		addq.l	#4+2,sp

		movem.l	(sp)+,d0-d7

Disp_Pic_Zoom_end
		rts
******************************************************************************
*
*  画像位置を表示
*
******************************************************************************
.xdef Disp_Pic_Position
Disp_Pic_Position

		btst.b	#0,Sys_flag3(a6)
		beq	Disp_Pic_Position_end

		movem.l	d0-d7,-(sp)

	*位置(41,3)
	*---------------------
		move.l	#$0029_0003,-(sp)
		move.w	#3,-(sp)
		DOS	_CONCTRL
		addq.l	#6,sp

		move.w	#'(',-(sp)
		DOS	_PUTCHAR

		move.w	MOUSE_TX(a6),d0
		sub.w	XL2(a6),d0
		bsr	PrintWI
		move.w	#',',(sp)
		DOS	_PUTCHAR

		move.w	MOUSE_TY(a6),d0
		sub.w	YL2(a6),d0
		bsr	PrintWI

		move.w	#')',(sp)
		DOS	_PUTCHAR

		pea.l	spc8_msg(pc)
		DOS	_PRINT

		addq.l	#4+2,sp

		movem.l	(sp)+,d0-d7

Disp_Pic_Position_end
		rts

******************************************************************************
*
*	ﾒﾓﾘﾀﾞﾝﾌﾟ
*
*	a1	開始アドレス
*	d1.l	表示バイト数
*
******************************************************************************
.xdef	DumpMem
DumpMem
	movem.l	d0-d7/a0-a5,-(sp)
	bsr	CRLF
	movea.l	a3,a0
	moveq.l	#16-1,d2

1:
	cmp.w	#16-1,d2
	bne	2f

	move.l	a1,d0
	bsr	PrintHex
	
2:
	move.b	(a1)+,d0
	bsr	PrintHex8
	dbra.w	d2,3f
	bsr	CRLF
	moveq.l	#16-1,d2
3:	
	subq.l	#1,d1
	bhi	1b
	bsr	CRLF
	movem.l	(sp)+,d0-d7/a0-a5
	rts

******************************************************************************
*
*	改行表示
*
******************************************************************************
.xdef CRLF
CRLF
	move.l	d0,-(sp)
	move.w	#$0d,-(sp)
	DOS	_PUTCHAR
	move.w	#$0a,(sp)
	DOS	_PUTCHAR
	addq.l	#2,sp
	move.l	(sp)+,d0
	rts

******************************************************************************
*
*	数字表示	d0:w
*
******************************************************************************
.xdef PrintWI
PrintWI
	tst.w	d0
	bpl	PrintW
	beq	PrintW
	move.l	d0,-(sp)
	move.w	#'-',-(sp)
	DOS	_PUTCHAR
	addq.w	#2,sp
	move.l	(sp)+,d0
	neg.w	d0
	bsr	PrintW
	neg.w	d0
	rts

.xdef	PrintW
PrintW
	movem.l d0-d1/a5,-(sp)
	and.l	#$0000FFFF,d0
	moveq.l	#10,d1
	move.l	sp,a5
	subq.l	#8,sp
	clr.b	-(a5)
prtw10
	divu	d1,d0
	swap	d0
	add.b	#'0',d0
	move.b	d0,-(a5)
	clr.w	d0
	swap	d0
	bne	prtw10
	move.l	a5,-(sp)
	dos       _PRINT
	lea.l	8+4(sp),sp
	movem.l	(sp)+,d0-d1/a5
	rts


.xdef	Print2keta
Print2keta
	movem.l	d0/a5,-(sp)
	move.l	sp,a5
	subq.l	#4,sp
	clr.b	-(a5)
@@
	divu.w	#10,d0
	swap	d0
	add.l	#'0'*$10000+'0',d0
	move.b	d0,-(a5)
	swap.w	d0
	move.b	d0,-(a5)
	move.l	a5,-(sp)
	DOS	_PRINT
	addq.l	#8,sp
	movem.l	(sp)+,d0/a5
 	rts




.xdef	PrintHex8
PrintHex8
	movem.l	d0-d1/a5,-(sp)
	move.l	sp,a5
	subq.l	#4,sp
	move.w	#' '*256,-(a5)
	bsr	_printhex2
	move.l	a5,-(sp)
	DOS	_PRINT
	addq.l	#8,sp
	movem.l	(sp)+,d0-d1/a5
	rts

.xdef	PrintHex
PrintHex
	movem.l	d0-d1/a5,-(sp)
	move.l	sp,a5
	lea.l	-12(sp),sp
	move.w	#' '*256,-(a5)
	bsr	_printhex4
	bsr	_printhex4
	move.l	a5,-(sp)
	DOS	_PRINT
	lea.l	4+12(sp),sp
	movem.l	(sp)+,d0-d1/a5
	rts

	*４桁分表示
	*-------------------
_printhex4
	bsr	_printhex2

	*２桁分表示
	*-------------------
_printhex2
	bsr	@f
@@
	moveq.l	#$0f,d1
	and.b	d0,d1
	cmp.b	#$0a,d1
	bcs	@f
	add.b	#'A'-'0'-$0a,d1
@@
	add.b	#'0',d1
	move.b	d1,-(a5)
	lsr.l	#4,d0
	rts

	.end
