*
*
*  ENCODE.S
*
*  ハフマン符号化
*
include	DOSCALL.MAC
include	JPEG.MAC
include	work.inc
*
	.text
	.xref	ZigzagL	'MES.S'
	.xref	PrintWI	'Load.s'
	.xref	PrintHex
	.xref	CRLF


******************************************************************************
*
*	DC成分ｴﾝｺｰﾄﾞ処理ﾏｸﾛ
*
*		ジグザグスキャン
*		量子化
*		前回のＤＣ値との差を取る
*	
******************************************************************************
ENCODE_DC	macro

*ジグザグスキャンと量子化
*-----------------------
	move.w	(a5)+,d4	*Qtable値読み込み
	move.w  d4,d3
	lsr.w	#1,d3
	move.w	(a0),d0	*量子化前のＤＣ値
	bmi	1f
	add.w	d3,d0	*正なら商に+0.5
	moveq.l	#0,d3
1:
	sub.w	d3,d0	*負なら商に-0.5
	ext.l	d0
	divs	d4,d0		* d0.w = 今回のＤＣ
 *前回のＤＣ値との差を取る
 *------------------------
	move.w	(a1),d1  * 前回のＤＣ
	move.w	d0,(a1)
	moveq.l	#0,d2
	sub.w	d1,d0
	beq	3f
	move.w	d0,d1
	bpl	2f
	neg.w	d1
	subq.w	#1,d0
2:
	addq.w	#4,d2
	lsr.w	#1,d1
	bne	2b
3:
	endm

******************************************************************************
*
*	AC成分ｴﾝｺｰﾄﾞ処理ﾏｸﾛ
*
*		ジグザグスキャン
*		量子化
*		０の個数ｶｳﾝﾄ
*		EOB,ZRLﾁｪｯｸ
******************************************************************************
ENCODE_AC	macro	SubAC,SubACZRL,SubACEOB
		local	ac10,ac20,ac50,ac90

	lea.l	ACLtable-DCLtable(a2),a2
	lea.l	ZigzagL(pc),a1
	moveq.l	#63-1,d2
ac10
	move.w	d2,d1  * RUN
ac20
*ジグザグスキャンと量子化
*-----------------------
	move.w	(a5)+,d4		*Qtable値読み込み
 	move.w	d4,d3
	lsr.w	#1,d3
	adda.w	(a1)+,a0		*Zigzagﾃｰﾌﾞﾙ読み込み
	move.w	(a0),d0
	*小数点以下四捨五入
	*---------------
	bmi	@f
	add.w	d3,d0
	moveq.l	#0,d3
@@
	sub.w	d3,d0

	ext.l	d0
	divs.w	d4,d0

	*０の個数カウント
	*-----------------------
	bne	ac50
	dbra	d2,ac20
	bsr	SubACEOB * EOB
	bra	ac90

	*０以外のＡＣ値が出てきた
	*-------------------
ac50
	move.w	d0,-(sp) * AC
	sub.w	d2,d1
@@
	cmp.w	#15,d1
	bls	@f
	bsr	SubACZRL * ZRL
        sub.w   #16,d1
        bra     @b
@@
	move.w	d1,-(sp) * Run
	bsr	SubAC
	addq.l	#4,sp
	dbra	d2,ac10
*
ac90
	endm
*
*
*　ハフマン符号最適化のため、各値の出現比率計測
*
*	a0.l	データ領域
*	a1.l	前回のＤＣ領域（使用後は、Zigzagﾃｰﾌﾞﾙアドレス)
*	a2.l	ＤＣコード表
*	a5.l	Qtableアドレス
.xdef ENCODE1
ENCODE1
	ENCODE_DC
	add.w	d2,d2
	addq.l	#1,(a2,d2.w)	 *各ﾋﾞｯﾄ長の出現率を加算
	ENCODE_AC countAC,countACZRL,countACEOB
	moveq.l	#0,d0
	rts

******** ZRL
countACZRL
	addq.l	#1,15*16*8(a2)	 *各ﾋﾞｯﾄ長の出現率を加算
	rts
******** EOB
countACEOB
	addq.l	#1,(a2)	 *各ﾋﾞｯﾄ長の出現率を加算
	rts

*    pushw  AC(w)
*    pushw  RUN(w)
countAC
	move.w	4(sp),d0
	lsl.w	#7,d0
	move.w	6(sp),d1 * AC
	bpl	@f
	neg.w	d1
@@
	addq.w	#8,d0
	lsr.w	#1,d1
	bne	@b
	addq.l  #1,0(a2,d0.w)
	rts
*
*
*
*  ハフマン符号出力
*
*
*	a0.l	データ領域
*	a1.l	前回のＤＣ領域（使用後は、Zigzagﾃｰﾌﾞﾙアドレス)
*	a2.l	ＤＣコード表
*	a4.l	バッファーアドレス
*	a5.l	Qtableアドレス
*
*	d7.w	ndata	バッファー内データ数
*	d6.w	rlen	残りビット長
*	d5.l	上位ワード rdata
*			残りデータ
*
*
.xdef ENCODE
ENCODE
	tst.w	EncodePath(a6)
	bnz	ENCODE1

*書き込みﾊﾞｯﾌｧ制御ﾚｼﾞｽﾀ復帰
*------------------------
	move.w	LastBufSize(a6),d7
	move.w	rlen(a6),d6
	move.w	rdata(a6),d5
	swap	d5
	move.l	bufadr(a6),a4
*  ＤＣ成分の出力
*-------------------------
	ENCODE_DC
	move.w	0(a2,d2.w),d5  * code
	move.w	2(a2,d2.w),d4  * length
	bsr	PutC
	lsr.w	#2,d2
	beq	dc_end
	moveq.l	#16,d1
	sub.w	d2,d1
	lsl.w	d1,d0
	move.w	d0,d5
	move.w	d2,d4
	bsr	PutC
dc_end

*  ＡＣ成分の出力
*------------------------
	ENCODE_AC PutAC,PutACZRL,PutACEOB

*書き込みﾊﾞｯﾌｧ制御ﾚｼﾞｽﾀ保存
*------------------------
	move.l	a4,bufadr(a6)
	swap	d5
	move.w	d5,rdata(a6)
	move.w	d6,rlen(a6)
	move.w	d7,LastBufSize(a6)
	move.l	errflg(a6),d0 
	rts
*
*  ＡＣ出力補助出力
*
*    a3.l Huffman Table
*
******** ZRL
PutACZRL
	move.w	15*16*4(a2),d5
	move.w	15*16*4+2(a2),d4
	bra	PutC
******** EOB
PutACEOB
	move.w	(a2),d5
	move.w	2(a2),d4
	bra	PutC

********
*    pushw  AC(w)
*    pushw  RUN(w)
PutAC
  move.l  d2,-(sp)
  moveq.l #0,d2
  move.w  10(sp),d0 * AC
  move.w  d0,d1
  bpl     @f
    subq.w  #1,d0
    neg.w   d1
@@
      addq.w  #4,d2
    lsr.w   #1,d1
    bne     @b

  move.w  8(sp),d3
  lsl.w   #6,d3
  add.w   d2,d3
  move.w  0(a2,d3.w),d5 * code
  move.w  2(a2,d3.w),d4 * length
  bsr     PutC
  lsr.w   #2,d2
  moveq.l #16,d3
  sub.w   d2,d3
  lsl.w   d3,d0
  move.w  d0,d5
  move.w  d2,d4
  move.l (sp)+,d2
*
*  コード出力
*    d5.w    code(w)
*    d4.w    lengh(w)
*
PutC
	cmp.w	d4,d6
	bls	putc50

	***** 出力なし
	lsl.l	d4,d5
	sub.w	d4,d6
	rts

putc50
	lsl.l	d6,d5
	sub.w	d6,d4
	moveq.l	#8,d6
	bsr	PutB
*
putc60
	cmp.w	d6,d4
	bcs	putc70
	lsl.l	d6,d5
	sub.w	d6,d4
	bsr	PutB
	bra	putc60
putc70
	lsl.l   d4,d5
	sub.w	d4,d6
	rts
*
*  d5.l:l 入力データ。上位ワード出力
*
PutB

  swap    d5
  cmp.b   #$FF,d5
  bne     putb20
    move.b  d5,(a4)+
    clr.w   d5
    dbra    d7,putb20
    move.l  d0,-(sp)
    move.l  buf_size(a6),d7
    move.l  d7,-(sp)
    subq.l  #1,d7
    move.l  buf_adrs(a6),a4
    move.l  a4,-(sp)
    move.w  Jhandle(a6),-(sp)
    dos     _WRITE
    move.l  d0,errflg(a6) * I/O error
    lea     10(sp),sp
    move.l  (sp)+,d0

putb20
  move.b  d5,(a4)+
  dbra    d7,putb80
    move.l  d0,-(sp)
    move.l  buf_size(a6),d7
    move.l  d7,-(sp)
    subq.l  #1,d7
    move.l  buf_adrs(a6),a4
    move.l  a4,-(sp)
    move.w  Jhandle(a6),-(sp)
    dos     _WRITE
    move.l  d0,errflg(a6) * I/O error
    lea     10(sp),sp
    move.l  (sp)+,d0
putb80
  swap    d5
  rts
*
*  d0.w  Handle
*
*
.xdef   preENCODE
preENCODE
  clr.l   errflg(a6) * I/O error flag
  clr.w   preDC(a6)
  clr.l   preDC+2(a6)

  clr.w   rdata(a6)
  move.w  #8,rlen(a6)
  move.l  buf_size(a6),d0
  subq.l  #1,d0
  move.w  d0,LastBufSize(a6)
  move.l  buf_adrs(a6),bufadr(a6)

  rts
*
.xdef	postENCODE
postENCODE
  movem.l d1/a0,-(sp)
  move.l  bufadr(a6),a4
  moveq.l #0,d7
  move.w  LastBufSize(a6),d7
  move.w  rlen(a6),d1
  cmp.w   #8,d1 
  beq     postEncode50
    moveq.l #-1,d0
    move.w  rdata(a6),d0
    rol.l   d1,d0
    move.b  d0,(a4)+
    subq.w  #1,d7
postEncode50
    move.l  buf_size(a6),d0
    subq.l  #1,d0
    sub.l   d7,d0
  beq     postEncode90
    move.l  d0,-(sp)
    move.l  buf_adrs(a6),-(sp)
    move.w  Jhandle(a6),-(sp)
    dos     _WRITE
    move.l  d0,errflg(a6) * I/O error
    lea     10(sp),sp
postEncode90
  movem.l (sp)+,d1/a0
  move.l  errflg(a6),d0
  rts
*
  .end
