*
*
*       GETHEAD.S
*
*
*
include  DOSCALL.MAC
include  JPEG.MAC
include  work.inc

	.xref	msgCR
	.xref	BaselineMsg
	.xref	ProgressiveMsg
	.xref	DCTMsg
	.xref	msg1,msg2,msg3,msg4,msg5,msg6
	.xref	jmsg1,jmsg2,jmsg3

	.xref	JPEG_not_found
	.xref	Not_JPEG_error
	.xref	No_Picture_error
	.xref	Cant_PROC_error
	.xref	Read_error
	.xref	Memory_error

	.xref	MakeTree
	.xref	CountCodeNumber

  .text
*
	.xref	PrintW,PrintWI
	.xref	Print2keta
	.xref	DQT,DHT
*
	.xdef	Get_Header
*
*
Get_Header
	lea	DHT+2(pc),a1
	move.w	(a1)+,d1
	subq.w	#2,d1
	bsr	getdht10
*
*とりあえず与えられたﾌｧｲﾙ名で開いてみる
*-------------------------------
*	move.w	#$020,-(sp)
	clr.w	-(sp)
	pea	fname(a6)
	dos	_OPEN
	addq.l	#6,sp
	move.w	d0,Jhandle(a6)
	bpl	OPEN_JPEG_END

	*開けない場合は、拡張子'.JPG'を付けて開いてみる
	*------------------------------------
		lea.l	fname(a6),a0
@@
		tst.b	(a0)+
		bnz	@b

		move.b	#'.',-1(a0)
		move.b	#'J',(a0)+
		move.b	#'P',(a0)+
		move.b	#'G',(a0)+
		clr.b	(a0)
OPEN_JPEG_1
	clr.w	-(sp)
	pea	fname(a6)
	dos	_OPEN
	addq.l	#6,sp
	move.w	d0,Jhandle(a6)
	bmi	JPEG_not_found

OPEN_JPEG_END

	*ﾌｧｲﾙの日付取得
	*----------------------
	clr.l	-(sp)
	move.w	d0,-(sp)
	DOS	_FILEDATE
	addq.l	#6,sp
	move.l	d0,fdate(a6)

	move.l	free_adrs(a6),a5
	move.l	free_size(a6),d5
	sub.l	#GetHeadWorkStart-em_free_adrs+1024,d5
	bcs	Memory_error
	adda.l	#GetHeadWorkStart-em_free_adrs,a5
	move.l	a5,GetHeadWorkAdrs(a6)
	lea.l	1024(a5),a5

	move.l	#1024,file_addr(a6)
	move.l	#0,file_point(a6)

*SOI

Search_SOI
	bsr	getc
Search_SOI_1
	cmp.b	#$FF,d0
	bne	Search_SOI

	bsr	getc
	cmp.b	#$D8,d0
	bne	Search_SOI_1
*
geth10
	bsr	getc
	cmp.b	#$FF,d0
	bne	Not_JPEG_error
*
geth15
	bsr	getc
geth16
	cmp.b	#$FF,d0
	beq	geth15
*
	tst.b	d0
	beq	Not_JPEG_error
	cmp.b	#$D8,d0 * SOI
	beq	Not_JPEG_error
	cmp.b	#$D9,d0 * EOI
	beq	No_Picture_error

	cmp.b	#$DA,d0
	beq	getSOS

	pea	geth10(pc)
*
	cmp.b	#$C4,d0
	beq	getDHT

	cmp.b	#$C0,d0
	bcs	geth40
	cmp.b	#$CF,d0
	bls	getSOFx
@@
	cmp.b	#$DB,d0 * DQT
	beq	getDQT
	cmp.b	#$E0,d0 * APP0(JFIF)
	beq	APP0
	cmp.b	#$FE,d0 * COM
	beq	getCOM
*
* geth_Other
*
  cmp.b   #$CF,d0
  bls     Cant_PROC_error
geth40
	addq.l	#4,sp
	bsr	getw
	cmp.w	#$ff00,d1
	bcc	geth50
	subq.w	#2,d1
	bcs	geth10
	bsr	skip_d1_bytes
	bra	geth10
geth50
	move.b	d1,d0
	bra	geth16

*SOFxの処理
*--------------------------
getSOFx
	and.b	#$0f,d0
	move.b	d0,SOFx(a6)
	bsr	getw
	sub.w	#2,d1
	bcs	Cant_PROC_error

	lea.l	1(a5),a1
	cmp.l	d1,d5
	bls	Cant_PROC_error
	bsr	get_d1_bytes

	move.l	1+1(a5),d0
	move.l  d0,Yline(a6)
	subq.w	#1,d0
	move.w	d0,XE(a6)
	swap.w	d0
	subq.w	#1,d0
	move.w	d0,YE(a6)

	move.w	Xline(a6),d0
	cmp.w	Yline(a6),d0
	bhi	@f
	move.w	Yline(a6),d0
@@
	move.w	d0,Maxline(a6)


	move.b	1(a5),Qlevel_source(a6)

	move.b	1+1+2+2+1+1(a5),d0
	move.b	d0,uvmode_source(a6)
	moveq	#3,d1
	cmp.b	#$22,d0
	beq	sof20		色差成分を1/4に間引く
	moveq	#2,d1
	cmp.b	#$21,d0		色差成分を1/2に間引く
	beq	sof20
	moveq	#1,d1		間引かない
sof20
	move.b	d1,uvmode(a6)

	*SOF内容表示
	*---------------
	cmp.b #2,Action(a6)
	bne   SOF_DISP_END

	pea     msgCR(pc)
	dos     _PRINT

	move.b	SOFx(a6),d0
	lea.l	BaselineMsg(pc),a0
	tst.b	d0
	beq	@f
	lea.l	ProgressiveMsg(pc),a0
	cmp.b	#2,d0
	bne	Cant_PROC_error
@@:
	move.l	a0,-(sp)
	dos	_PRINT
	pea.l	DCTMsg(pc)
	dos	_PRINT

	pea.l	msg1(pc)
	dos	_PRINT
	moveq.l	#0,d0
	move.b	Qlevel_source(a6),d0
	bsr	PrintW

	pea.l	msg2(pc)
	dos	_PRINT
	move.b	1+1+2+2(a5),d0
	bsr	PrintW

    pea.l   msg3(pc)
    dos     _PRINT
    move.w  Xline(a6),d0
    bsr     PrintW

    pea.l   msg4(pc)
    dos     _PRINT
    move.w  Yline(a6),d0
    bsr     PrintW

    pea.l   msg5(pc)
    dos     _PRINT
	move.b	uvmode_source(a6),d0
	and.w	#$0F,d0
	bsr	PrintW

    pea.l   msg6(pc)
    dos     _PRINT
	move.b	uvmode_source(a6),d0
	lsr.b	#4,d0
	bsr	PrintW

	lea.l	9*4(sp),sp

SOF_DISP_END

    cmp.b   #8,1(a5)
    bne     Cant_PROC_error
	*ｶﾗｰ画像かﾓﾉｸﾛ画像か判定
	*----------------------
	clr.b	colormode(a6)
	cmp.b	#3,1+1+2+2(a5)
	beq	getSOF_END		*ｶﾗｰ画像である
	cmp.b	#1,1+1+2+2(a5)
	bne	Cant_PROC_error			*対処できない
	move.b	#1,colormode(a6)	*ﾓﾉｸﾛ画像である

getSOF_END
	rts
*
.xdef getSOS
getSOS
****** SOS
	bsr	getw
	tst.b	colormode(a6)
	bnz	getSOS_mono
getSOS_color
	sub.w	#7+2,d1
	bcs	Cant_PROC_error
	move.w	d1,-(sp)

	bsr	getc
	cmp.b	#3,d0
	bne	Cant_PROC_error
	*Y
	*-------------------
	bsr	getw
	tst.b	d1
	bne	Cant_PROC_error

	*U
	*-------------------
	bsr	getw
	cmp.b	#$11,d1
	bne	Cant_PROC_error
	bsr	getw
	*V
	*-------------------
	cmp.b	#$11,d1
	bne	Cant_PROC_error
	bra	getSOS_1

getSOS_mono
	subq.w	#3+2,d1
	bcs	Cant_PROC_error
	move.w	d1,-(sp)

	bsr	getc
	cmp.b	#1,d0
	bne	Cant_PROC_error
	bsr	getw
	tst.b	d1
	bne	Cant_PROC_error
getSOS_1
*ﾒｯｾｰｼﾞ表示
*------------------
	cmp.b #2,Action(a6)
	bne   SOS_DISP_END

	pea     msgCR(pc)
	dos     _PRINT
	addq.l  #4,sp

SOS_DISP_END

	move.w	(sp)+,d1
	bra	skip_d1_bytes
*
*
***** COM
getCOM
	moveq.l	#0,d1
	bsr	getw
	subq.w	#2,d1
	bcs	Not_JPEG_error

	move.l	d1,imsg_size(a6)
	move.w	Jhandle(a6),imsg_handle(a6)
	move.l	file_point(a6),imsg_start_point(a6)

	cmp.b	#2,Action(a6)
	bne	skip_d1_bytes

COM_DISP
	pea	msgCR(pc)
	dos	_PRINT
	dos	_PRINT
	addq.l	#4-2,sp
	moveq.l	#0,d2
	bra	com60
com10
	bsr	getc
	cmp.b	#$0d,d0
	beq	com60
	cmp.b	#$0a,d0
	bne	com50

	pea	msgCR(pc)
	dos	_PRINT
	addq.l	#4,sp
	bra	com60

com50
	move.w	d0,(sp)
	DOS	_PUTCHAR
com60
	dbra	d1,com10
	addq.l	#2,sp
com90
    rts

*
***** APP0
APP0
	bsr	getw
	sub.w	#14,d1
	bcs	Cant_PROC_error
	move.w	d1,-(sp)
*
	bsr	getw
	swap.w	d1
	bsr	getw
	move.l	d1,d2
	bsr	getc
	bsr	getw	バージョン
	bsr	getc	密度単位
	bsr	getw	水平密度
	swap.w	d1
	bsr	getw	垂直密度
	move.l	d1,d3

	move.w	(sp)+,d1
	bsr	skip_d1_bytes

	cmp.l	#'JFIF',d2
	bne	app090

	tst.w	Aspect(a6)
	bne	app010
	move.l	d3,Aspect(a6)
app010
	cmp.b	#2,Action(a6)
	bne	app090

	pea	jmsg1(pc)
	dos	_PRINT
	pea.l	jmsg2(pc)
	dos	_PRINT
	move.w	Aspect(a6),d0
	bsr	PrintW
	pea.l	jmsg3(pc)
	dos	_PRINT
	lea.l	4*3(sp),sp

	move.w	Aspect+2(a6),d0
	bsr	PrintW
app090
	rts
*
*
getDQT
***** DQT
	bsr	getw
	subq.w	#2,d1
	bcs	Not_JPEG_error
	cmp.w	#$84-2,d1
	blt	getDQT030

	lea	DQT+4(pc),a1
	bra	get_d1_bytes

getDQT030
	move.l  DQTadr(a6),a1
	add.l	d1,DQTadr(a6)
	bra	get_d1_bytes
*
*
*
.xdef getDHT
getDHT
	moveq.l	#0,d1
	bsr	getw
	subq.w	#2,d1
	bcs	Not_JPEG_error
	cmp.l	d1,d5
	bcs	Cant_PROC_error

	move.l	a5,a1
	bsr	get_d1_bytes

	move.l	a5,a1
getdht10
	move.b	#$FF,(a1,d1.l)
*
*
getdht20
	move.b	(a1)+,d0
	bne	@f

	bsr	CountCodeNumber
	move.w	d4,DCL_bits(a6)
	lea.l	RootDCL(a6),a0
	lea.l	DCL_DECODE_TBL(a6),a3
	move.w	#(RootDCL-DCL_DECODE_TBL)/4,d0
	bra	getdht50

@@
	cmp.b	#$01,d0
	bne	@f

	bsr	CountCodeNumber
	move.w	d4,DCC_bits(a6)
	lea.l	RootDCC(a6),a0
	lea.l	DCC_DECODE_TBL(a6),a3
	move.w	#(RootDCC-DCC_DECODE_TBL)/4,d0
	bra	getdht50

@@
	cmp.b	#$10,d0
	bne	@f

	bsr	CountCodeNumber
	lea.l	RootACL(a6),a0
	lea.l	ACL_DECODE_TBL(a6),a3
	move.w	#(RootACL-ACL_DECODE_TBL)/4,d0
	bra	getdht50

@@
	cmp.b	#$11,d0
	bne	@f

	bsr	CountCodeNumber
	lea.l	RootACC(a6),a0
	lea.l	ACC_DECODE_TBL(a6),a3
	move.w	#(RootACC-ACC_DECODE_TBL)/4,d0
getdht50
	lea	16(a1),a2
	bsr	MakeTree
	move.l	a2,a1
	bra	getdht20
@@
	cmp.b	#$FF,d0
	bne	Cant_PROC_error
	rts
*
*********************************************************************
*
*　１文字読み込み
*
*	input	none
*	output	d0.b
*	break	none
*
*********************************************************************
.xdef	getc
getc
		move.l	a5,-(sp)

		move.l	GetHeadWorkAdrs(a6),a5
		move.l	file_addr(a6),d0
		cmp.l	#1024,d0
		bcs	getc_1			*まだバッファが残っている

*バッファに読み込む
*-------------------------
	*読み込む所までＳＥＥＫ
	*------------------------
		move.w	#0,-(sp)
		move.l	file_point(a6),-(sp)
		move.w	Jhandle(a6),-(sp)
		DOS	_SEEK
		addq.l	#8,sp
		tst.l	d0
		bmi	Read_error
	*読み込む
	*------------------------
		move.l	#1024,-(sp)
		move.l	a5,-(sp)
		move.w	Jhandle(a6),-(sp)
		dc.w	_READ
		lea	10(sp),sp
		tst.l	d0
		bmi	Read_error
		clr.l	d0

*バッファから１バイト読み込む
*-------------------------
getc_1
		addq.l	#1,d0
		move.l	d0,file_addr(a6)
		move.b	-1(a5,d0.l),d0
		addq.l	#1,file_point(a6)

		move.l	(sp)+,a5
		rts
*********************************************************************
*
*	１ワード読む
*
*	input	none
*	output	d1.w
*	break	d0.l
*
*********************************************************************
getw
		bsr	getc
		lsl.w	#8,d0
		move.w	d0,d1
		bsr	getc
		move.b	d0,d1
		rts
*********************************************************************
*
*	指定バイト数スキップ
*
*	input	d1.w....スキップするバイト数
*	output	none
*	break	high word of d1.l
*
*********************************************************************
skip_d1_bytes
		and.l	#$0000ffff,d1
		add.l	d1,file_addr(a6)
		add.l	d1,file_point(a6)
		rts
*********************************************************************
*
*	指定バイト数メモリに読み込む
*
*	input	d1.w	読み込むバイト数
*		a1	読み込むアドレス
*	output	none
*	break	d0.l,a1.l
*
*********************************************************************
get_d1_bytes
		movem.l	d1-d2/a0,-(sp)

		and.l	#$0000ffff,d1
		beq	get_d1_bytes_end
		move.l	file_addr(a6),d0
		move.l	#1024,d2
		sub.l	d0,d2
		bhi	get_d1_bytes_1

get_d1_bytes_0
		bsr	getc
		move.b	d0,(a1)+
		subq.w	#1,d1
		beq	get_d1_bytes_end

		moveq.l	#1,d0
		move.l	#1024-1,d2

get_d1_bytes_1
		move.l	GetHeadWorkAdrs(a6),a0
		adda.l	d0,a0

		cmp.l	d1,d2
		bcs	get_d1_bytes_3

		add.l	d1,file_point(a6)
		add.l	d1,file_addr(a6)
		subq.w	#1,d1
get_d1_bytes_2
		move.b	(a0)+,(a1)+
		dbra	d1,get_d1_bytes_2
get_d1_bytes_end
		movem.l	(sp)+,d1-d2/a0
		rts

get_d1_bytes_3
		add.l	d2,file_point(a6)
		add.l	d2,file_addr(a6)
		sub.l	d2,d1
		subq.w	#1,d2
get_d1_bytes_4
		move.b	(a0)+,(a1)+
		dbra	d2,get_d1_bytes_4
		bra	get_d1_bytes_0

  .end
