*
*
*       掛け算テーブル
*
*
*
include  DOSCALL.MAC
include  IOCSCALL.MAC
include  JPEG.MAC
include	 work.inc

  .text
	.xref	Memory_error
	.xref	DHTDCL	*'MES.S'
	
*
*
* 　ＲＧＢテーブル作成
*
*	入力
*		なし
*	出力
*		なし
*
.xdef	make_RGB_table
make_RGB_table

	movea.l a6,a0
	adda.l  #RGB_TBL+2048*2*6,a0
	move.l	#$f801_07c0,d0
	move.l	#$003e_f801,d1
	move.l	#$07c0_003e,d2
	move.l	d0,d3
	move.l	d1,d4
	move.l	d2,d5

	rept	8
	movem.l	d0-d5,-(a0)
	endm

	moveq.l	#32-1,d7

@@

	rept	8
	movem.l	d0-d5,-(a0)
	endm

	sub.l	#$0001_0000,d0
	move.l	d0,d3
	rept	8
	movem.l	d0-d5,-(a0)
	endm

	subq.w	#1,d1
	move.l	d1,d4
	rept	8
	movem.l	d0-d5,-(a0)
	endm

	sub.l	#$07ff_0040,d0
	sub.l	#$0002_0000,d1
	move.l	d0,d3
	move.l	d1,d4
	rept	8
	movem.l	d0-d5,-(a0)
	endm

	sub.w	#$0000_07ff,d1
	sub.l	#$0040_0002,d2
	move.l	d1,d4
	move.l	d2,d5
	dbra	d7,@b

	movea.l a6,a0
	adda.l  #RGB_TBL_under+RGB_flow*2*6,a0

	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0,d4
	moveq.l	#0,d5

	move.w	#RGB_flow/2/4-1,d7
@@
	movem.l	d0-d5,-(a0)
	movem.l	d0-d5,-(a0)
	movem.l	d0-d5,-(a0)
	movem.l	d0-d5,-(a0)
	dbra.w	d7,@b

	movea.l a6,a0
	adda.l  #RGB_TBL_over+RGB_flow*2*6,a0

	move.l	#$f80107c0,d0
	move.l	#$003ef801,d1
	move.l	#$07c0003e,d2
	move.l	d0,d3
	move.l	d1,d4
	move.l	d2,d5

	move.w	#RGB_flow/2/4-1,d7
@@
	movem.l	d0-d5,-(a0)
	movem.l	d0-d5,-(a0)
	movem.l	d0-d5,-(a0)
	movem.l	d0-d5,-(a0)
	dbra.w	d7,@b
	rts
*
*
* 　ＩＤＣＴ乗算テーブル作成
*
*	入力
*		なし
*	出力
*		なし
*
.xdef	make_IDCT_table
make_IDCT_table

	movea.l a6,a2
	adda.l  #COS_TBL+2048*2*6,a2
	move.w	#4096/2+mul_flow-1,d7
	move.l	#2324419551,a4			cos(pi*6/16)*sqr(2)
	bsr	make_mul_tbl_sub2

	addq.w	#2,a2
	move.w	#4096/2+mul_flow-1,d7
	moveq.l	#1*6*2,d6			cos(pi*2/16)*sqr(2)
	move.l	#1316677908,a4
	bsr	make_mul_tbl_sub

	addq.w	#2,a2
	move.w	#4096/2+mul_flow-1,d7
	moveq.l	#1*6*2,d6			cos(pi/16)*sqr(2)
	move.l	#1662323478,a4
	bsr	make_mul_tbl_sub

	addq.w	#2,a2
	move.w	#4096/2+mul_flow-1,d7
	moveq.l	#1*6*2,d6			cos(pi*3/16)*sqr(2)
	move.l	#755379961,a4
	bsr	make_mul_tbl_sub

	addq.w	#2,a2
	move.w	#4096/2+mul_flow-1,d7
	move.l	#3374534151,a4			cos(pi*5/16)*sqr(2)
	bsr	make_mul_tbl_sub2

	addq.w	#2,a2
	move.w	#4096/2+mul_flow-1,d7
	move.l	#1184978811,a4			cos(pi*7/16)*sqr(2)
*****************************************************************
*
*  IDCT用乗算テーブル作成2
*
*	入力
*		a4.l...値の増分*65536*65536
*		d7.l...テーブルサイズ/2
*		a2...テーブルアドレス（０の値のところをさす）
*	出力
*		なし
*	破壊
*		d0,d1,d2,d3,a0,a1,a3
*****************************************************************
make_mul_tbl_sub2

	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#-6*2,d2
	moveq.l	#6*2,d5

	movea.l a2,a0
	movea.l	a2,a1

@@
	move.w	d1,(a0)
	adda.l	d5,a0

	add.l	a4,d0
	subx.w	d4,d4
	and.w	d5,d4
	add.w	d4,d1
	sub.w	d4,d2

	suba.l	d5,a1
	move.w	d2,(a1)

	dbra	d7,@b
	rts
*****************************************************************
*
*  IDCT用乗算テーブル作成
*
*	入力
*		d6.l*65536*65536+a4.l...値の増分*65536*65536
*		d7.l...テーブルサイズ/2
*		a2...テーブルアドレス（０の値のところをさす）
*	出力
*		なし
*	破壊
*		d0,d1,d2,d3,a0,a1,a3
*****************************************************************
make_mul_tbl_sub

	moveq.l	#0,d1

_make_mul_tbl_sub

	moveq.l	#6*2,d5
	moveq.l	#0,d0
	move.l	d1,d2
	sub.l	d5,d2

	movea.l a2,a0
	movea.l	a2,a1

@@
	move.w	d1,(a0)
	adda.l	d5,a0

	add.l	a4,d0
	subx.w	d4,d4
	and.w	d5,d4
	add.w	d6,d4
	add.w	d4,d1
	sub.w	d4,d2

	suba.l	d5,a1
	move.w	d2,(a1)

	dbra	d7,@b
	rts
*
*
*  ＹＵＶｔｏＲＧＢ変換乗算テーブル作成
*
*	入力
*		なし
*	出力
*		なし
*
.xdef	make_YUV_RGB_table
make_YUV_RGB_table

	movea.l a6,a2
	adda.l  #YUV_RGB_TBL+1024*2*6,a2
	move.w	#2048/2+mul_flow-1,d7
	moveq.l	#-1*6*2,d6				-0.3411*65536*65536
	move.l	#-1465013345,a4
	bsr	make_mul_tbl_sub

	addq.w	#2,a2
	move.w	#2048/2+mul_flow-1,d7
	moveq.l	#1*6*2,d6				1.7718*65536*65536
	move.l	#3314855759,a4
	bsr	make_mul_tbl_sub

	addq.w	#2,a2
	move.w	#2048/2+mul_flow-1,d7
	moveq.l	#1*6*2,d6				1.4020*65536*65536
	move.l	#1726576853,a4
	moveq.l	#R_TBL,d1
	bsr	_make_mul_tbl_sub

	addq.w	#2,a2
	move.w	#2048/2+mul_flow-1,d7
	moveq.l	#-1*6*2,d6				-0.7139*65536*65536
	move.l	#-3066177153,a4
	moveq.l	#G_TBL,d1
	bsr	_make_mul_tbl_sub

	addq.w	#2,a2
	move.w	#2048/2+mul_flow-1,d7
	moveq.l	#-1*6*2,d6				-0.0012*65536*65536
	move.l	#-5153961,a4
	moveq.l	#B_TBL,d1
	bra	_make_mul_tbl_sub
*
*
*  ＤＣＴ変換乗算テーブル作成
*
*	入力
*		なし
*	出力
*		なし
*
.xdef	make_DCT_table
make_DCT_table

	movea.l a6,a2
	adda.l  #DCT_TBL+4096/2*8*4,a2
	move.w	#4*4,a3
	move.w	#8192/2-1,d7
	move.l	#3924782306,d5
	move.l	#17733,d6			cos6*65536^3
	bsr	make_DCT_tbl_sub

	addq.w	#4,a2
	move.w	#8192/2-1,d7
	move.l	#1955211143,d5
	move.l	#42813,d6			cos2
	bsr	make_DCT_tbl_sub

	addq.w	#4,a2
	move.w	#8*4,a3
	move.w	#4096/2-1,d7
	move.l	#2240476201,d5
	move.l	#45450,d6			cos1
	bsr	make_DCT_tbl_sub

	addq.w	#4,a2
	move.w	#4096/2-1,d7
	move.l	#394020632,d5
	move.l	#38531,d6			cos3
	bsr	make_DCT_tbl_sub

	addq.w	#4*2,a2				cos2h,cos6h

	addq.w	#4,a2
	move.w	#4096/2-1,d7
	move.l	#2802021324,d5
	move.l	#25745,d6			cos5
	bsr	make_DCT_tbl_sub

	addq.w	#4,a2
	move.w	#4096/2-1,d7
	move.l	#2881323235,d5
	move.l	#9040,d6			cos7
*
*  DCT用乗算テーブル作成
*
*	入力
*		d6.l*65536*65536*65536+d5.l*65535*65535....値の増分*65536*65536*65535
*		d7.l...テーブルサイズ/2
*		a2...０の値のテーブルアドレス
*		a3...アドレス増加分
*	出力
*		なし
*	破壊
*		d0,d1,d2,d3,a0,a1,a3
*
make_DCT_tbl_sub

	move.l	#$8000_0000,d0		+0.5(四捨五入のため)
	moveq.l	#0,d1
	move.l	d0,d2
	moveq.l	#0,d3
	movea.l a2,a0
	movea.l a2,a1

@@

	move.l	d1,(a0)
	adda.l	a3,a0
	add.l	d5,d0
	addx.l	d6,d1

	sub.l	d5,d2
	subx.l	d6,d3
	suba.l	a3,a1
	move.l	d3,(a1)

	dbra	d7,@b
	rts

*
*
*  ＲＧＢｔｏＹＵＶ変換乗算テーブル作成
*
*	入力
*		なし
*	出力
*		なし
*
.xdef	make_RGB_YUV_table
make_RGB_YUV_table

	movea.l a6,a2
	adda.l  #RGB_YUV_TBL,a2
	move.w	#64/2*8*4,d0
	cmp.w	#16,VScbit(a6)
	beq	@f		16bitｶﾗｰﾓｰﾄﾞである
	move.w	#256/2*8*4,d0
@@
	lea.l	(a2,d0.w),a2
	move.l	#153878,d6		 0.5870*4*65536*65536*65536
	move.l	#2267742732,d5
	bsr	make_RGB_YUV_tbl_sub

	addq.w	#4,a2
	move.l	#(-1-86926),d6		-0.3316
	move.l	#-4081936918,d5
	bsr	make_RGB_YUV_tbl_sub

	addq.w	#4,a2
	move.l	#(-1-109759),d6		-0.4187
	move.l	#-2975553343,d5
	bsr	make_RGB_YUV_tbl_sub

	addq.w	#4,a2
	move.l	#78381,d6		0.2990
	move.l	#240518169,d5
	bsr	make_RGB_YUV_tbl_sub

	addq.w	#4,a2
	move.l	#(-1-44145),d6		-0.1684
	move.l	#-213030378,d5
	bsr	make_RGB_YUV_tbl_sub

	addq.w	#4,a2
	move.l	#131072,d6			 0.5000
	moveq.l	#0,d5
	bsr	make_RGB_YUV_tbl_sub

	addq.w	#4,a2
	move.l	#29884,d6			 0.1140
	move.l	#1786706395,d5
	bsr	make_RGB_YUV_tbl_sub

	addq.w	#4,a2
	move.l	#(-1-21312),d6		-0.0813
	move.l	#-1319413953,d5
*
*  RGB to YUV用乗算テーブル作成
*
*	入力
*		d6.l*65536*65536+d5.l...値の増分*65536*65536
*		d7.l...テーブルサイズ
*		a2...テーブルアドレス
*	出力
*		なし
*	破壊
*		d0,d1,d2,d3,a0,a1,a3
*
make_RGB_YUV_tbl_sub

	move.w	#8*4,a3
	moveq.l	#64/2-1,d7

	cmp.w	#16,VScbit(a6)
	beq	make_DCT_tbl_sub	16bitｶﾗｰﾓｰﾄﾞである

*24bitｶﾗｰ用
*-----------------------
make_RGB_YUV_tbl_sub_24bit

	move.w	#256/2-1,d7
	asr.l	d6
	roxr.l	d5
	asr.l	d6
	roxr.l	d5
	bra	make_DCT_tbl_sub

*
*  逆量子化乗算テーブル作成
*
*	入力
*		a2.l...乗算ﾃｰﾌﾞﾙ格納ｱﾄﾞﾚｽ
*		d5.l...空きﾒﾓﾘ
*	出力
*		a2.l...乗算ﾃｰﾌﾞﾙの次のｱﾄﾞﾚｽ
*		d5.l...空きﾒﾓﾘ
*
.xdef	make_UQ_table
make_UQ_table

	lea.l	UQL_tbl(a6),a0
	lea.l	QtableL(a6),a1

	moveq.l	#64*2-1,d7	Qtableの個数
	moveq.l	#0-1,d6		処理済みテーブル数

	move.w	(a1)+,d1

make_UQ_table_loop

	move.l	#2048,d0
	divs.w	d1,d0

	moveq.l	#0,d2
	move.w	d0,d2
	lsl.w	#1+1,d2
	addq.w	#2+2,d2
	sub.l	d2,d5		d2=この値のﾃｰﾌﾞﾙで消費するﾒﾓﾘ量
	bcs	Memory_error		ﾒﾓﾘが足りない

	swap.w	d0
	sub.w	#2048,d0

	add.w	d0,d0	*ﾜｰﾄﾞ単位に
	add.w	d0,d0
	move.w	d0,d2
	add.w	d0,d0
	add.w	d2,d0	*６倍

	add.w	d1,d1	*ﾜｰﾄﾞ単位に
	add.w	d1,d1
	move.w	d1,d2
	add.w	d1,d1
	add.w	d2,d1	*６倍

@@

	move.w	d0,(a2)+
	add.w	d1,d0
	bne	@b

	move.w	d0,(a2)+	DECODEルーチン用調整（ハフマン復号した値そのままだと負の値が全部－１されているためそれの調整用）
	move.l	a2,a3		０の値のアドレス

@@

	move.w	d0,(a2)+
	add.w	d1,d0

	cmp.w	#2047*2*6,d0
	ble	@b

make_UQ_table_3

	move.l	a3,(a0)+	０の値のアドレス

	addq.w	#1,d6
	move.w	(a1)+,d1

	lea.l	-2(a1),a4
	movea.l	a0,a3
	move.w	d6,d0

@@

	subq.w	#4,a3
	cmp.w	-(a4),d1
	dbeq.w	d0,@b			同じ値がでるまで検索

	dbeq.w	d7,make_UQ_table_loop	同じ値がなかった
	move.l	(a3),a3			０の値のアドレス
	dbne.w	d7,make_UQ_table_3	同じ値があった
	rts

**********************************************************
*
* X方向の間引き・引き延ばし命令作成
*
*	入力
*		d7...画面上の表示ﾄﾞｯﾄ数
*	出力
*		なし
**********************************************************
.xdef	make_interval_work
make_interval_work

*Ｘ方向の展開ルーチン作成
*-------------------------
	*前準備
	*-------------------------
	movea.l	GETP_adrs(a6),a5
	move.w	Interval+2(a6),d6
	move.w	Interval(a6),d0
	move.w  d6,a4
	add.w	d0,d6
	move.w	XS(a6),d2	d2=画像の表示開始位置

	move.w	d2,d3
	add.w	#$8000,d3
	mulu.w	d0,d3
	move.w	d3,d1
	clr.w	d3
	swap.w	d3
	divu.w	Interval+2(a6),d3
	move.w	d1,d3
	divu.w	Interval+2(a6),d3
	swap.w	d3
	add.w	XL3(a6),d3

	move.w	HX(a6),d1	d1=表示開始位置X
	move.w	d1,d0
	sub.w	Home_X(a6),d0
	and.w	#$1ff,d0	d0=画面のHome位置から表示開始位置までのﾄﾞｯﾄ数

	sub.w	d0,d7		d7=残りﾄﾞｯﾄ数-1
	subq.w	#1,d7

*表示開始位置が負の場合の作成
*-------------------------
		tst.w	d2
		bpl	mk_int_wk_minus_end
		move.w	#$7000,(a5)+		'moveq.l #0,d0
mk_int_wk_minus
		sub.w	a4,d3
		bcs	mk_int_wk_minus_1

		move.w	#$3ac0,(a5)+		'move.w	d0,(a5)+
		addq.w	#1,d1
		cmp.w	VSXsize(a6),d1
		bne	@f
		clr.w	d1
		move.w	#$9bc5,(a5)+		'sub.l d5,a5'
@@
		dbra	d7,mk_int_wk_minus
		bra	mk_int_wk50

mk_int_wk_minus_1
		add.w	d6,d3
		cmp.w	XE(a6),d2
		beq	mk_int_wk50
		addq.w	#1,d2
		bmi	mk_int_wk_minus
mk_int_wk_minus_end

	cmp.w	Xline(a6),d2
	bcc	mk_int_wk_over

*作成
*-------------------------
		moveq.l	#0,d5
		moveq.l	#0,d0
mk_int_wk_mid
		sub.w	a4,d3
		bcs	mk_int_wk_skip

		cmp.w	#-2,d5
		beq	mk_int_wk_cont

	*次の画像のﾄﾞｯﾄに移動した場合
	*-------------------------
		tst.w	d5
		beq	mk_int_wk_next1

		*移動量が2ﾊﾞｲﾄ以上の場合
		*-------------------------
		moveq.l	#0,d0

		cmp.w	#8,d5
		bhi	mk_int_wk_lea	8ﾊﾞｲﾄ以上の移動なのでlea命令を使う

		and.w	#$0007,d5
		add.w   d5,d5
		lsl.w	#8,d5
		or.w	#$504c,d5
		move.w	d5,(a5)+	'addq.w	#n,a4
		bra	mk_int_wk_next

mk_int_wk_lea
		move.w  #$49ec,(a5)+	'lea.l n(a4),a4'
	        move.w  d5,(a5)+
mk_int_wk_next
		move.w  #$3adc,(a5)+	'move.w (a4)+,(a5)+
		moveq.l	#1,d0
		bra	mk_int_wk_move

		*前のﾄﾞｯﾄに続いた場合
		*------------------------
mk_int_wk_next1
		bclr.l	#1,d0
		bnz	mk_int_wk_next	VRAMの右端から左端に移動したので
		tst.w	d0
		beq	mk_int_wk_next	前には'move.l (a4)+,(a5)+'がある
		bmi	mk_int_wk_next	前のﾄﾞｯﾄは引き延ばされている

		move.w  #$2adc,-2(a5)	'move.l (a4)+,(a5)+
		moveq.l	#0,d0
		bra	mk_int_wk_move

	*前のﾄﾞｯﾄと同じ場合
	*-------------------------
mk_int_wk_cont
		tst.w	d0
		bmi	mk_int_wk_cont_cont	前のﾄﾞｯﾄは、その前のﾄﾞｯﾄと同じ
		bclr.l	#1,d0
		bnz	mk_int_wk_cont_round	VRAMの右端から左端に移動した

		*前のﾄﾞｯﾄとそのままつながっている場合
		*--------------------------
		tst.w	d0
		bnz	@f

		move.w  #$201c,-2(a5)	'move.l (a4)+,d0
		move.w  #$2ac0,(a5)+	'move.l d0,(a5)+
		bra	mk_int_wk_cont_cont
@@
		move.w  #$301c,-2(a5)	'move.w (a4)+,d0
		move.w  #$3ac0,(a5)+	'move.w d0,(a5)+
		bra	mk_int_wk_cont_cont

		*前のﾄﾞｯﾄはVRAMの右端の場合
		*--------------------------
mk_int_wk_cont_round
		tst.w	d0
		bnz	@f

		move.l  #$201c2ac0,-4(a5)	'move.l (a4)+,d0
						*'move.l d0,(a5)+
		bra	1f
@@
		move.l  #$301c3ac0,-4(a5)	'move.w (a4)+,d0
						*'move.w d0,(a5)+
1:		move.w	#$9bc5,(a5)+		'sub.l d5,a5'

		*前のﾄﾞｯﾄは、その前のﾄﾞｯﾄと同じな場合
		*--------------------------
mk_int_wk_cont_cont

		move.w  #$3ac0,(a5)+	'move.w d0,(a5)+
		moveq.l	#-1,d0

mk_int_wk_move

		moveq.l	#-2,d5
		addq.w	#1,d1
		cmp.w	VSXsize(a6),d1
		bne	@f
		clr.w	d1
		move.w	#$9bc5,(a5)+		'sub.l d5,a5'
		bset.l	#1,d0			VRAMの右端から左端にまたいだ事をマーク
@@
		dbra	d7,mk_int_wk_mid
		bra	mk_int_wk50

	*次の画像のﾄﾞｯﾄへ移動
	*-----------------------------
mk_int_wk_skip
		add.w	d6,d3
		addq.w  #2,d5
		addq.w	#1,d2
		moveq.l	#$7,d4
		and.w	d2,d4
		bne	@f
		add.w	#(64-8)*2,d5
@@
		cmp.w	Xline(a6),d2
		bcc	mk_int_wk_over

		cmp.w	XE(a6),d2
		bls	mk_int_wk_mid
		bra	mk_int_wk50

*表示終了位置が画像より大きい場合の作成
*-------------------------
mk_int_wk_over
		move.w	#$7000,(a5)+		'moveq.l #0,d0
mk_int_wk_over_1
		sub.w	a4,d3
		bcs	mk_int_wk_over_2

		move.w	#$3ac0,(a5)+		'move.w	d0,(a5)+
		addq.w	#1,d1
		cmp.w	VSXsize(a6),d1
		bne	@f
		clr.w	d1
		move.w	#$9bc5,(a5)+		'sub.l d5,a5'
@@
		dbra	d7,mk_int_wk_over_1
		bra	mk_int_wk50

mk_int_wk_over_2
		add.w	d6,d3
		addq.w	#1,d2
		cmp.w	XE(a6),d2
		bls	mk_int_wk_over_1
mk_int_wk50

	move.w	#$4e75,(a5)+	'rts


*キャッシュのフラッシュ
*--------------------------
	btst	#0,Sys_flag2(a6)
	beq	mk_int_wk_rts

	*キャッシュフラッシュ
	*--------------------
	moveq.l	#$3 ,d1		*0)？
				*1)現在のキャッシュ状態の読みだし
				*2)？
				*3)キャッシュのフラッシュ
				*4)キャッシュの状態を設定する
	moveq.l	#$ac,d0
	trap	#$0f

mk_int_wk_rts

	rts

  .end
