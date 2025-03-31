*
*
*  DECODE.S
*
*  ハフマン復号化
*
include  DOSCALL.MAC
include  JPEG.MAC
include  work.inc

	.text
	.cpu	68000
	.xref	PrintWI
	.xref	PrintW
	.xref	IllegalJPEG,work_adrs
	.xref	Zigzag,Zigzag_Y

inGetC	macro
	local	inGetC1
*GetCｲﾝﾗｲﾝ展開 Start
	dbra	d7,inGetC1	#10
         bsr     GetBuf		#20
inGetC1
	move.b	(a5)+,d5	#8
	moveq.l	#8,d6		#4
*GetCｲﾝﾗｲﾝ展開 end
	endm

******************************************************************************
*
*  ハフマン復号入力（ＤＣ成分）＆逆量子化＆逆ジグザグ
*
*   a0.l  データ領域
*   a1.l  ＤＣハフマン木テーブル（８ビット分）
*   a2.l  前回のＤＣ領域
*   a4.l  逆量子化ﾃｰﾌﾞﾙ
*   a5.l  バッファーアドレス
*
*   d7.w	LastFFxxSize
*   d6.w	rlen	残りビット長
*   d5.l	buffer
******************************************************************************
.xdef	DecodeDCAC
DecodeDCAC

*ﾊﾌﾏﾝ符号とDC値を8bit分一気にデコード
*------------------------
		move.w	d5,d3
		clr.b	d3
		lsr.w	#8-3-2,d3
		move.l	(a1,d3.w),d2

	*ﾃﾞｺｰﾄﾞしたﾋﾞｯﾄ分だけ捨てる
	*--------------------
		cmp.b	d2,d6
		bhi	@f
		lsl.w	d6,d5
		sub.b	d6,d2
		inGetC
@@
		lsl.w	d2,d5
		sub.b	d2,d6

		swap.w	d2
		bpl	dc_lower_8bit	ﾃﾞｺｰﾄﾞは8bit以下である

*残りのﾊﾌﾏﾝ符号をﾃﾞｺｰﾄﾞ
*--------------------------
	rept	8
		add.w	d5,d5		#4
		addx.w	d2,d2		#4
		subq.w	#1,d6		#4
		bne	@f		#10
		inGetC
@@
		add.w	d2,d2		#4
		move.w	(a1,d2.w),d2	#14
		bmi	dc15		#10
	endm
		bra	IllegalJPEG
dc15
		tst.b	d2		#4
		bnz	dc40		#10,14	DC値読み込みへ

	*DC値は0である
	*-------------------------------
		move.w	(a2),d0
		bmi	dc90
		move.l	(a4)+,a2
		move.w	(a2,d0.w),(a0)
		bra	DECODE_AC

	*DC値も一緒にﾃﾞｺｰﾄﾞしたか？
	*---------------------------------
dc_lower_8bit
		move.w	4(a1,d3.w),d0
		bne	dc75		した

*DC値のﾃﾞｺｰﾄﾞ
*--------------------------------
		move.w	6(a1,d3.w),d2
	*DC値読み込み
	*----------------------------------------------
dc40
		not.w	d5
		ext.l	d5
		not.w	d5

		cmp.b	d2,d6
		bhi	@f
		lsl.l	d6,d5
		sub.b	d6,d2
		inGetC
		cmp.b	d2,d6
		bhi	@f
		lsl.l	d6,d5
		sub.b	d6,d2
		inGetC
@@
		lsl.l	d2,d5
		sub.b	d2,d6

		move.l	d5,d0
		swap	d0
		add.w	d0,d0
dc75
		bpl	@f
		addq.w	#2,d0
@@
		add.w	(a2),d0
		move.w	d0,(a2)
		bmi	dc90

	  *DC値の差分が正の場合
	  *-------------------
		move.l	(a4)+,a2
		move.w	(a2,d0.w),(a0)
		bra	DECODE_AC
dc90
	*DC値の差分が負の場合
	*-------------------
		move.l	(a4)+,a2
		move.w	-2(a2,d0.w),(a0)
******************************************************************************
*
*  ハフマン復号入力（ＡＣ成分）＆逆量子化＆逆ジグザグ
*
*   a0.l  データ領域
*   a1.l  ＡＣハフマン木テーブル（８ビット分）
*   a4.l  逆量子化ﾃｰﾌﾞﾙ
*   a5.l  バッファーアドレス
*   a3.l  ジグザグテーブル
*
*   d7.w  ndata  バッファー内データ数
*   d6.w  rlen   残りビット長
*   d5.l  buffer
*   d1.b  FFdxFlag
*
*    d2  ssss
*    d3  nnnn
*    d4  Zigzag destination
*
******************************************************************************
.xdef DECODE_AC
DECODE_AC
		moveq.l	#63*2,d4

*ﾊﾌﾏﾝ符号とAC値を8bit分一気にデコード
*------------------------
ac10
		move.w	d5,d3		#4
		clr.b	d3		#4
		lsr.w   #8-3-2,d3	#10
		lea.l	8(a1,d3.w),a2	#12
		move.l	(a2)+,d2	#12

	*ﾃﾞｺｰﾄﾞしたﾋﾞｯﾄ分だけ捨てる
	*--------------------
		cmp.b	d2,d6		#4
		bhi	@f		#10
		lsl.w	d6,d5
		sub.b	d6,d2
		inGetC
@@
		lsl.w	d2,d5		#6+2n
		sub.b   d2,d6		#4

		swap.w	d2
		bmi	ac_normal	8bitﾃﾞｺｰﾄﾞじゃ足りない

	*AC値も一緒にﾃﾞｺｰﾄﾞしたか？
	*---------------------------------
		move.w	(a2)+,d0
		bnz	ac_decoded	した
		move.w	(a2),d3		#8	d3=AC値のﾋﾞｯﾄ数

*AC値のﾃﾞｺｰﾄﾞ
*--------------------------------
ACValueRead
	*AC値読み込み
	*---------------------------
		not.w	d5		#4
		ext.l	d5		#4
		not.w	d5		#4
		cmp.b	d3,d6		#4
		bhi	@f		#10
		lsl.l	d6,d5
		sub.b	d6,d3
		inGetC
		cmp.b	d3,d6
		bhi	@f
		lsl.l	d6,d5
		sub.b	d6,d3
		inGetC
@@
		lsl.l	d3,d5		#8+2n
		sub.b	d3,d6		#4

	*AC値書き込み
	*-----------------------
		move.l	d5,d0
		swap.w	d0
		add.w	d0,d0
ac_decoded

	*0の個数分だけ0を書き込む
	*------------------------------
		add.w	d2,d2		d2.w=０の個数*2
		beq	ac17		#10

		sub.b	d2,d4
		bls	ac_EOB		０の個数が残りのＡＣ領域を超えた
		clr.w	d3
		add.w	d2,d2
		add.w	d2,a4
		neg.w	d2
		jmp	ac17(pc,d2.w)
		rept 16
		adda.w	(a3)+,a0
		move.w	d3,(a0)
		endm
ac17
		adda.w	(a3)+,a0	#14
		move.l	(a4)+,a2	#12
		move.w	(a2,d0.w),(a0)	#18    *AC
		subq.w	#2,d4
		bnz	ac10
		rts
*EOBである
*-----------------------
ac_EOB
		add.b	d2,d4		d4.w = 0の個数
ac_EOB2
		rts


*残りのﾊﾌﾏﾝ符号をﾃﾞｺｰﾄﾞ
*--------------------------
ac_normal
	rept	8
		add.w	d5,d5
		addx.w	d2,d2
		subq.w	#1,d6
		bne	@f
		inGetC
@@
		add.w	d2,d2
		move.w	8(a1,d2.w),d2
		bmi	ac15
	endm
		bra	IllegalJPEG
ac15
		tst.b	d2
		bze	ac_EOB2		EOBである

		moveq.l	#$000f,d3			#4
		and.w	d2,d3		AC		#4
		lsr.b	#4,d2		Run		#16
		bra	ACValueRead

******************************************************************************
*
*	ファイル読み込み($FFxxの処理もここで行う)
*
*	入力	a5.l	読み込みｱﾄﾞﾚｽ
*		d1.w	0)$FFを読み込んだ -1)読み込んでいない
*		d7.l	high)ﾊﾞｯﾌｧ残りﾊﾞｲﾄ数
*	出力	d7.l	high)ﾊﾞｯﾌｧ残りﾊﾞｲﾄ数
*			low)次の$FFまで、又は、ﾊﾞｯﾌｧ最後までのﾊﾞｲﾄ数
*		d1.w	0)$FFを読み込んだ -1)読み込んでいない
*		a5.l	読み込みｱﾄﾞﾚｽ
*	破壊	d0.l,d6.l
******************************************************************************
.xdef GetBuf
GetBuf
*残りのﾊﾞｯﾌｧﾊﾞｲﾄ数取得
*-----------------------
	swap.w	d7			#4
*ひとつ前のﾊﾞｲﾄが$FFの場合、次のﾊﾞｲﾄが$00,$FF,$Dxかﾁｪｯｸする
*-----------------------
	
	tst.w	d1			#4
	bnz	GetBufSearchFF	ひとつ前のﾊﾞｲﾄは$FFではない	#10
1:
	dbra.w	d7,2f			#10
	bsr	GetBufAllSub
2:
	move.b	(a5)+,d0		#8
	beq	GetBufSearchFF	$00の場合($FF00)	#10
	cmp.b	#$d0,d0					#8
	bcs	GetBufFFxxErr	$D0以下のｺｰﾄﾞはｴﾗｰ	#10
	cmp.b	#$df,d0					#8
	bls.b	GetBufFFDx	$Dxの場合		#10
	cmp.b	#$ff,d0
	beq	1b		$FFの場合
	bra	GetBufFFxxErr	ｴﾗｰ

GetBufFFDx
		*$FFDxの場合、読み込み途中のﾋﾞｯﾄを破棄する
		*------------------
		moveq.l	#0,d0
		move.w	d0,preDC(a6)
		move.l	d0,preDC+2(a6)
		move.w	d0,rlen(a6)
GetBufFFDxLoop
		dbra	d7,@f
		bsr	GetBufAllSub
@@
		move.b	(a5)+,d5
		lsl.w	#8,d5
		cmp.w	#$ff00,d5
		bne	GetBufSearchFF	次のﾊﾞｲﾄ取り込み
GetBufFFDxChkFFxx
		dbra	d7,@f
		bsr	GetBufAllSub
@@
		move.b	(a5)+,d0
		beq	GetBufSearchFF	次のﾊﾞｲﾄ取り込み
		cmp.b	#$ff,d0
		beq	GetBufFFDxChkFFxx	$FFFFなら無視
		and.b	#$f0,d0
		cmp.b	#$d0,d0
		beq	GetBufFFDxLoop		また$FFDxが来た
GetBufFFxxErr
		subq.l	#1,a5
		addq.w	#1,d7
*$FF検索
*--------------------
GetBufSearchFF
	dbra.w	d7,@f		#10
	bsr	GetBufAllSub
@@
	move.l	a5,d6		#4
	moveq.l	#-1,d0		#4
@@	cmp.b	(a5)+,d0	#8
	dbeq	d7,@b		#10
	sne.b	d1		#6
	ext.w	d1		#4	d1=$0000)発見時 -1)未発見時
	sub.w	d1,d7		#4	未発見時 d7=d7+1
	swap.w	d7		#4
	move.w	a5,d7		#4
	move.l	d6,a5		#4
	sub.w	d6,d7		#4
	subq.w	#1,d7		#4
	rts			#16

**************
*	入力	なし
*	出力	d7	読み込んだﾊﾞｲﾄ数
*		a5	読み込み開始ｱﾄﾞﾚｽ
*	破壊	d0.l
**************
GetBufAllSub
	move.l	buf_size(a6),-(sp)
	movea.l	buf_adrs(a6),a5
	move.l	a5,-(sp)
	move.w	Jhandle(a6),-(sp)
	DOS	_READ
	lea.l	10(sp),sp
	move.l  d0,d7
	bmi	IllegalJPEG	読み込めない
	bnz	@f

	*これ以上ﾌｧｲﾙなしなので、Dummy Data設定
	*---------------------
	tst.l	errflg(a6)
	bnz	IllegalJPEG	読み込めない
	move.l	#-1,errflg(a6)
	move.l	#$ff00ff00,(a5)
	addq.w	#4,d7
@@
	subq.w	#1,d7
	rts
******************************************************************************
*
*	pre DECODE
*
*	入力	無し
*	出力	d1	FFxxFlag(a6)設定値
*		d5	rdata(a6)設定値
*		d6	rlen(a6)設定値
*		d7	LastBufSize(a6),LastFFxxSize(a6)設定値
*		a5	NextFFxxAdrs(a6)設定値
*	破壊	d0.l
******************************************************************************
.xdef preDECODE
preDECODE
	clr.w	-(sp)
	move.l	file_point(a6),-(sp)
	move.w	Jhandle(a6),-(sp)
	DOS	_SEEK
	addq.l	#8,sp

	moveq.l	#0,d1
	move.w	d1,preDC(a6)
	move.l	d1,preDC+2(a6)
	move.l	d1,errflg(a6)
	moveq.l	#0,d7
	moveq.l	#-1,d1
	bsr	GetBuf
	move.b	(a5)+,d5
	lsl.w	#8,d5
	inGetC
	rts

  .end
