*
*
*       SCROLL.S
*
*
*
include  DOSCALL.MAC
include  IOCSCALL.MAC
include  JPEG.MAC
include  work.inc
include	keycode.inc
  .text
*
*
	.xdef	Scroll
	.xref	inkey
	.xref	make_interval_work
	.xref	set_HOME_wait
	.xref	PrintW,PrintWI
	.xref	Disp_Pic_Zoom
	.xref	Disp_Pic_Position
	.xref	chk_key_fast
*
*	d6......Block X
*	d7......Block Y
*
*
*
Scroll

*画面の位置情報を初期化
*-------------------
		move.w	Maxline(a6),d0
		move.w	d0,MOUSE_Z(a6)
		move.w	d0,MOUSE_TZ(a6)
		move.w	d0,HZ(a6)

		move.w	d0,d1
		bsr	calc_XY_dots

		bsr	Disp_Pic_Position
		bsr	Disp_Pic_Zoom

		btst.b	#7,Sys_flag2(a6)
		beq	manual_scroll		ｵｰﾄｽｸﾛｰﾙ要求なし

		move.w	Xline(a6),d1
		cmp.w	VSXsize(a6),d1
		bhi	@f
		move.w	Yline(a6),d1
		cmp.w	VSYsize(a6),d1
		bls	manual_scroll		ｵｰﾄｽｸﾛｰﾙ必要無し
@@

*ｵｰﾄｽｸﾛｰﾙ
*---------------------
		move.w	#1,DirX(a6)
		clr.w	DirY(a6)
		clr.w	DirZ(a6)


		move.w	$9cc.w,TIME_BAK(a6)
		move.w	#20,TIME_WAIT(a6)	ｵｰﾄｽｸﾛｰﾙ開始まで待ち0.2秒

auto_scroll
		move.w	MOUSE_TZ(a6),-(sp)
		move.w	MOUSE_TY(a6),-(sp)
		move.w	MOUSE_TX(a6),-(sp)
		bsr	inkey
		move.w	(sp)+,d2
		move.w	(sp)+,d3
		move.w	(sp)+,d4

		tst.l	d0
		bmi	sc90

	*ｵｰﾄｽｸﾛｰﾙ処理
	*-------------------------------
		cmp.w	d5,d4
		bne	sc580			ｷｰ入力またはﾏｳｽから入力有り
		cmp.w	d6,d2
		bne	sc580			ｷｰ入力またはﾏｳｽから入力有り
		cmp.w	d7,d3
		bne	sc580			ｷｰ入力またはﾏｳｽから入力有り

	*経過時間計算
	*-------------------------------
		move.w	$9cc.w,d1
		move.w	TIME_BAK(a6),d0
		move.w	d1,TIME_BAK(a6)
		sub.w	d1,d0
		bcc	@f
		add.w	$9ca.w,d0
@@
	*時間待ち処理
	*-------------------------------
		move.w	TIME_WAIT(a6),d1
		beq	sc_auto
		sub.w	d0,d1
		bcc	@f
		clr.w	d1
@@
		move.w	d1,TIME_WAIT(a6)
		bra	sc590

	*ｽｸﾛｰﾙ方向計算
	*-------------------------------
sc_auto
		bsr	chk_key_fast

		move.w	Xline(a6),d2
		move.w	Yline(a6),d3
		sub.w	XL2(a6),d2
		bcc	@f
		clr.w	d2
@@
		sub.w	YL2(a6),d3
		bcc	@f
		clr.w	d3
@@
		moveq.l	#0,d4

		tst.w	DirY(a6)
		bmi	sc_xy_y_bak
		bnz	sc_xy_y_ff
		tst.w	DirX(a6)
		bmi	sc_xy_x_bak
		bnz	sc_xy_x_ff
		tst.w	DirZ(a6)
		bmi	sc_zoom_in
		bnz	sc_zoom_out
		bra	sc_auto_end

		*右へ移動
		*---------------------------
sc_xy_x_ff
		cmp.w	#512,Xline(a6)
		bls	@f

		add.w	d0,d6
		cmp.w	d6,d2
		bcc	sc590
		move.w	d2,d6
		moveq.l	#20,d4
@@
		moveq.l	#0,d0
		moveq.l	#-1,d1
		moveq.l	#0,d2
		bra	sc_next_wait

		*上へ移動
		*---------------------------
sc_xy_y_bak
		cmp.w	#512,Yline(a6)
		bls	2f

		sub.w	d0,d7
		bcs	1f
		cmp.w	YL2(a6),d7
		bcc	sc590
1
		move.w	YL2(a6),d7
		moveq.l	#20,d4
2
		moveq.l	#-1,d0
		moveq.l	#0,d1
		moveq.l	#0,d2
		bra	sc_next_wait

		*左へ移動
		*---------------------------
sc_xy_x_bak
		cmp.w	#512,Xline(a6)
		bls	2f

		sub.w	d0,d6
		bcs	1f
		cmp.w	XL2(a6),d6
		bcc	sc590
1
		move.w	XL2(a6),d6
		moveq.l	#20,d4
2
		moveq.l	#0,d0
		moveq.l	#1,d1
		moveq.l	#0,d2
		bra	sc_next_wait


		*下へ移動
		*---------------------------
sc_xy_y_ff
		cmp.w	#512,Yline(a6)
		bls	@f

		add.w	d0,d7
		cmp.w	d7,d3
		bcc	sc590

		move.w	d3,d7
		moveq.l	#20,d4
@@
		moveq.l	#0,d0
		moveq.l	#0,d1
		moveq.l	#1,d2
		bra	sc_next_wait

	*ｵｰﾄ縮小
	*-----------------------------
sc_zoom_out
		moveq.l	#0,d4

		*倍率計算
		*-------------------
		sub.w	d0,d5
		bcs	1f
		cmp.w	#512,d5
		bhi	2f
1
		move.w	#512,d5
		moveq.l	#80,d4
2
		*Home位置計算
		*-------------------
			*X方向
			*--------------------
			move.w	VSXsize(a6),d2
			move.w	Xline(a6),d3
			cmp.w	d3,d2
			bcc	2f

			move.w	d2,d6
			mulu.w	Maxline(a6),d6
			divu.w	d5,d6
			cmp.w	d3,d6
			bls	1f
			move.w	d3,d6
1
			lsr.w	d6
2
			*Y方向
			*---------------------
			move.w	VSYsize(a6),d2
			move.w	Yline(a6),d3
			cmp.w	d3,d2
			bcc	2f

			move.w	d2,d7
			mulu.w	Maxline(a6),d7
			divu.w	d5,d7
			cmp.w	d3,d7
			bls	1f
			move.w	d3,d7
1
			lsr.w	d7
			sub.w	d7,d3
			move.w	d3,d7
2
		tst.w	d4
		beq	sc590
		moveq.l	#0,d0
		moveq.l	#0,d1
		moveq.l	#-1,d2
		bra	sc_next_wait

	*ｵｰﾄ拡大
	*-----------------------------
sc_zoom_in
		add.w	d0,d5
		bcs	@f
		cmp.w	Maxline(a6),d5
		bcs	sc590
@@
		move.w	Maxline(a6),d5
		moveq.l	#0,d0
		moveq.l	#0,d1
		moveq.l	#0,d2
		moveq.l	#20,d4
sc_next_wait
		move.w	d0,DirX(a6)
		move.w	d1,DirY(a6)
		move.w	d2,DirZ(a6)
		move.w	d4,TIME_WAIT(a6)
		bsr	move_pic
		move.w	$9cc.w,TIME_BAK(a6)
		bra	auto_scroll

	*ｽｸﾛｰﾙ座標設定
	*-----------------------------
sc590
		bsr	move_pic
		bra	auto_scroll

	*ｵｰﾄｽｸﾛｰﾙ&ｽﾞｰﾑ終了
	*-----------------------------
sc_auto_end
		bsr	move_pic
		btst.b	#0,Sys_flag(a6)
		beq	sc90			ｷｰ入力待ちなし

*　ｷｰ入力＆ｽｸﾛｰﾙ
*-------------------
manual_scroll

	btst.b	#0,Sys_flag(a6)
	beq	sc90				キー入力待ちｵﾌﾟｼｮﾝなし

@@
		bsr	inkey
		tst.l	d0
		bmi	sc90
sc580
		bsr	move_pic
		bra	@b
sc90
		rts

******************************************************************************
*
*	画像移動
*
*	入力
*		d5.w	画像の倍率
*		d6.w	画像の中心位置x
*		d7.w	画像の中心位置y
******************************************************************************
move_pic
		move.w	d6,MOUSE_TX(a6)
		move.w	d7,MOUSE_TY(a6)
		move.w	d5,MOUSE_TZ(a6)
		movem.w	d5-d7,-(sp)

*------------------------------
*倍率が変更された場合
*------------------------------
	cmp.w	MOUSE_Z(a6),d5
	beq	move_pic_home	変更されてない

*倍率変更前の画像表示開始終了位置を保存
*---------------------
		move.w	MOUSE_X(a6),d6
		move.w	MOUSE_Y(a6),d7
		bsr	calc_disp_XYdots
		sub.w	d0,d1
		sub.w	d2,d3
		add.w	Home_FX(a6),d0
		add.w	Home_FY(a6),d2
		sub.w	Home_X(a6),d0
		sub.w	Home_Y(a6),d2
		and.w	#$1ff,d0
		and.w	#$1ff,d2
		add.w	d0,d1
		add.w	d2,d3
		movem.w	d0-d3,-(sp)

*倍率計算
*----------------------
		move.w	MOUSE_TX(a6),d6
		move.w	MOUSE_TY(a6),d7
		move.w	MOUSE_TZ(a6),d5

		move.w	Maxline(a6),d1
		cmp.w	d1,d5
		bls	1f

		*拡大の場合
		*----------------------
		move.w	d1,d0
		add.w	d1,d1
		sub.w	d5,d1

		bra	2f
1
		*縮小の場合
		*----------------------
		move.w	d5,d0
2
		bsr	calc_XY_dots

		clr.w	Home_FX(a6)
		clr.w	Home_FY(a6)
		bsr	calc_HOME
		sub.w	Home_X(a6),d2
		sub.w	Home_Y(a6),d3

		sub.w	d2,Home_FX(a6)
		sub.w	d3,Home_FY(a6)

*メッセージ表示
*---------------------
		bsr	Disp_Pic_Zoom
		bsr	Disp_Pic_Position

*今の画像表示範囲を計算
*-------------------------
		move.w	MOUSE_TX(a6),d6
		move.w	MOUSE_TY(a6),d7
		bsr	calc_disp_XYdots
		movem.w	(sp)+,d4-d7

*以前表示した範囲と、今の範囲の両方とも含む範囲を計算
*(d4,d5)-(d6,d7)
*-------------------------
		sub.w	d0,d1
		sub.w	d2,d3
		add.w	Home_FX(a6),d0
		add.w	Home_FY(a6),d2
		sub.w	Home_X(a6),d0
		sub.w	Home_Y(a6),d2
		and.w	#$1ff,d0
		and.w	#$1ff,d2
		add.w	d0,d1
		add.w	d2,d3

		cmp.w	d0,d4
		bls	@f
		move.w	d0,d4
@@
		cmp.w	d1,d5
		bcc	@f
		move.w	d1,d5
@@
		cmp.w	d2,d6
		bls	@f
		move.w	d2,d6
@@
		cmp.w	d3,d7
		bcc	@f
		move.w	d3,d7
@@
	*画面上の表示位置を画像上の表示位置に変換
	*(d4,d6)-(d4+d5,d6+d7)
	*--------------------------
		sub.w	d0,d5
		sub.w	d2,d7
		sub.w	d0,d4
		sub.w	d2,d6
		neg.w	d4
		neg.w	d6

		addq.w	#1,d5
		addq.w	#1,d7

		moveq.l	#0,d1
		move.w	Interval(a6),d1
		move.w	Interval+2(a6),d0

		mulu.w	d0,d5
		add.l	d1,d5
		subq.l	#1,d5
		move.w	d5,d2
		clr.w	d5
		swap.w	d5
		divu.w	d1,d5
		move.w	d2,d5
		divu.w	d1,d5
		add.w	XL4(a6),d5

		mulu.w	d0,d7
		add.l	d1,d7
		subq.l	#1,d7
		move.w	d7,d2
		clr.w	d7
		swap.w	d7
		divu.w	d1,d7
		move.w	d2,d7
		divu.w	d1,d7
		add.w	YL4(a6),d7

		mulu.w	d0,d4
		add.l	d1,d4
		subq.l	#1,d4
		move.w	d4,d2
		clr.w	d4
		swap.w	d4
		divu.w	d1,d4
		move.w	d2,d4
		divu.w	d1,d4
		add.w	XL4(a6),d4

		mulu.w	d0,d6
		add.l	d1,d6
		subq.l	#1,d6
		move.w	d6,d2
		clr.w	d6
		swap.w	d6
		divu.w	d1,d6
		move.w	d2,d6
		divu.w	d1,d6
		add.w	YL4(a6),d6

		add.w	d4,d5
		add.w	d6,d7

	*表示開始位置のはみ出しﾁｪｯｸ
	*-----------------------------
		move.w	MOUSE_TX(a6),d0
		sub.w	XL2(a6),d0
		move.w	d0,d1
		bpl	@f
		clr.w	d1
@@
		sub.w	d4,d1
		cmp.w	d0,d1
		bge	@f
		move.w	d0,d1
@@
		move.w	d1,d4

		move.w	MOUSE_TY(a6),d0
		sub.w	YL2(a6),d0
		move.w	d0,d1
		bpl	@f
		clr.w	d1
@@
		sub.w	d6,d1
		cmp.w	d0,d1
		bge	@f
		move.w	d0,d1
@@
		move.w	d1,d6

	*画像上の表示位置から、GetPartの入力ﾚｼﾞｽﾀ形式に変換
	*(d4,d6)-(d4+d5,d6+d7)　→  (d2,d3) Xsize=d6 Ysize=d1
	*--------------------------
		move.w	d4,d2
		move.w	d6,d3
		move.w	d5,d6
		move.w	d7,d1

		bsr	GetPart
		bra	move_pic_x_end

*------------------------------
*画像を新たに書き込む位置を計算
*------------------------------
move_pic_home
	*Ｘ方向の計算(d0.w:移動量 d2.w:表示開始位置)
	*---------------------
	move.w	d6,d0
	move.w	d6,d2
	sub.w	XL2(a6),d2
	sub.w	MOUSE_X(a6),d0
	bcs	calc_vposx20		左に移動

		*右に移動の場合
		*-----------------------------
		cmp.w	XL(a6),d0
		bcs	@f
		move.w	XL(a6),d0
@@
		add.w	XL(a6),d2
		sub.w	d0,d2
		sub.w	XL4(a6),d2
		bra	calc_vposx_end

		*左に移動の場合
		*------------------------------
calc_vposx20
		neg.w	d0
		cmp.w	XL(a6),d0
		bcs	calc_vposx_end
		move.w	XL(a6),d0
calc_vposx_end

	*Ｙ方向の計算(d1.w:移動量 d3.w:表示開始位置)
	*---------------------
	move.w	d7,d1
	move.w	d7,d3
	sub.w	YL2(a6),d3
	sub.w	MOUSE_Y(a6),d1
	bcs	calc_vposy20

		*下に移動の場合
		*-----------------------------
		cmp.w	YL(a6),d1
		bcs	@f
		move.w	YL(a6),d1
@@
		add.w	YL(a6),d3
		sub.w	d1,d3
		sub.w	YL4(a6),d3
		bra	calc_vposy_end

		*上に移動の場合
		*-----------------------------
calc_vposy20
		neg.w	d1
		cmp.w	YL(a6),d1
		bcs	calc_vposy_end
		move.w	YL(a6),d1
calc_vposy_end

*移動量が０の場合はバックグランドプロセスを動かす
*-----------------------
		tst.w	d0
		bne	@f
		tst.w	d1
		bne	@f

		move.w	d0,-(sp)
		DOS	$ffff
		move.w	(sp)+,d0
		bra	move_pic_y_move
@@
		bsr	Disp_Pic_Position
move_pic_y_move

*画面のホーム位置(d2.w,d3.w)を変更
*----------------------
	movem.w	d0-d3,-(sp)

	bsr	calc_HOME
	bsr	set_HOME_wait
*	move.w	#$003f,$e82200
*	or.w	#$4000,$e82600

	movem.w	(sp)+,d0-d3

*Ｙ方向の移動
*-----------------------
	movem.w	d0-d3/d6-d7,-(sp)
	tst.w	d1
	beq	move_pic_y_end

	move.w	d6,d2
	sub.w	XL2(a6),d2
	move.w	XL(a6),d6
	bsr	GetPart

move_pic_y_end
	movem.w	(sp)+,d0-d3/d6-d7

*Ｘ方向の移動
*-----------------------
move_pic_x_move
	move.w	d0,d6
	beq	move_pic_x_end		X方向の移動量=0

	move.w	d7,d0
	sub.w	YL2(a6),d0

	cmp.w	d0,d3
	bne	move_pic_x_10
	add.w	d1,d3
	bra	move_pic_x_20
move_pic_x_10
	move.w	d0,d3
move_pic_x_20

	*表示するﾗｲﾝ数を計算
	*----------------------------
	move.w	YL(a6),d7
	sub.w	d1,d7
	bls	move_pic_x_end		表示するﾗｲﾝ数は0

	move.w	d7,d1
	bsr	GetPart

move_pic_x_end

	movem.w	(sp)+,d5-d7

move_pic_end
*画像位置を設定
*---------------------
	move.w	d5,MOUSE_Z(a6)
	move.w	d6,MOUSE_X(a6)
	move.w	d7,MOUSE_Y(a6)

*	move.w	#$0000,$E82200

	rts

***********************************
*
*	画像を表示する縦横ﾄﾞｯﾄ数を計算
*
*	入力	d6		画像表示中心X
*		d7		画像表示中心Y
*	出力	d0		画像の表示開始Xﾄﾞｯﾄ
*		d1		画像の表示終了Xﾄﾞｯﾄ
*		d2		画像の表示開始Yﾄﾞｯﾄ
*		d3		画像の表示終了Yﾄﾞｯﾄ
*	破壊	d4
***********************************
calc_disp_XYdots

		move.w	Interval(a6),d0
		move.w	Interval+2(a6),d1

	*X方向の表示開始と終了ﾄﾞｯﾄを計算し保存
	*--------------------
		move.w	d6,d2

		sub.w	XL2(a6),d2
		move.w	XL(a6),d3
		add.w	d2,d3

		tst.w	d2
		bpl	@f
		clr.w	d2
		sub.w	XL4(a6),d2
@@
		cmp.w	Xline(a6),d3
		bcs	@f
		move.w	Xline(a6),d3
@@
		bsr	calc_disp_dots
		movem.w	d2-d3,-(sp)

	*Y方向の表示開始と終了ﾄﾞｯﾄを計算し保存
	*--------------------
		move.w	d7,d2

		sub.w	YL2(a6),d2
		move.w	YL(a6),d3
		add.w	d2,d3

		tst.w	d2
		bpl	@f
		clr.w	d2
		sub.w	YL4(a6),d2
@@
		cmp.w	Yline(a6),d3
		bcs	@f
		move.w	Yline(a6),d3
@@
		bsr	calc_disp_dots

		movem.w	(sp)+,d0-d1

		rts
***********************************
*
*	画像を表示するﾄﾞｯﾄ数を計算
*
*	入力	d0.w/d1.w	倍率
*		d2		表示開始位置
*		d3		表示終了位置
*	出力	d2		画像の表示開始ﾄﾞｯﾄ
*		d3		画像の表示終了ﾄﾞｯﾄ
*	破壊	d4
***********************************
calc_disp_dots

		add.w	#$8000,d2
		mulu.w	d0,d2
		move.w	d2,d4
		clr.w	d2
		swap.w	d2
		divu.w	d1,d2
		move.w	d4,d2
		divu.w	d1,d2

		add.w	#$8000,d3
		mulu.w	d0,d3
		move.w	d3,d4
		clr.w	d3
		swap.w	d3
		divu.w	d1,d3
		move.w	d4,d3
		divu.w	d1,d3

		rts

***********************************
*
*	画像を表示する縦横ﾄﾞｯﾄ数を計算
*
*	入力
*		d0.w/d1.w....倍率
*
*	破壊	d2,d3,d4
***********************************
.xdef	calc_XY_dots
calc_XY_dots
	movem.w	d0-d1,Interval(a6)

	moveq.l	#0,d3
	move.w	d0,d3
	subq.w	#1,d3

	move.w	VSXsize(a6),d2
	mulu.w	d1,d2
	add.l	d3,d2
	divu.w	d0,d2
	move.w	d2,XL(a6)
	move.l	d2,d3
	swap.w	d3
	lsr.w	d2
	bcc	@f
	add.w	d0,d3
@@
	moveq.l	#0,d4
	lsr.w	d3
	beq	@f
	moveq.l	#1,d4
@@
	add.w	d1,d3
	move.w	d2,XL2(a6)
	move.w	d3,XL3(a6)
	move.w	d4,XL4(a6)

	moveq.l	#0,d3
	move.w	d0,d3
	subq.w	#1,d3

	move.w	VSYsize(a6),d2
	mulu.w	d1,d2
	add.l	d3,d2
	divu.w	d0,d2
	move.w	d2,YL(a6)
	move.l	d2,d3
	swap.w	d3
	lsr.w	d2
	bcc	@f
	add.w	d0,d3
@@
	moveq.l	#0,d4
	lsr.w	d3
	beq	@f
	moveq.l	#1,d4
@@
	add.w	d1,d3
	move.w	d2,YL2(a6)
	move.w	d3,YL3(a6)
	move.w	d4,YL4(a6)
	rts

***********************************
*
*	画面のHome位置を計算
*
*	入力
*		d6.w
*		d7.w
*	出力
*		d2.w
*		d3.w
***********************************
calc_HOME
	move.w	Interval(a6),d0
	move.w	Interval+2(a6),d1

	move.w	d6,d2
	sub.w	XL2(a6),d2
	add.w	#$8000,d2
	mulu.w	d0,d2
	move.w	d2,d4
	clr.w	d2
	swap.w	d2
	divu.w	d1,d2
	move.w	d4,d2
	divu.w	d1,d2
	add.w	Home_FX(a6),d2
	and.w   #$1ff,d2

	move.w	d7,d3
	sub.w	YL2(a6),d3
	add.w	#$8000,d3
	mulu.w	d0,d3
	move.w	d3,d4
	clr.w	d3
	swap.w	d3
	divu.w	d1,d3
	move.w	d4,d3
	divu.w	d1,d3
	add.w	Home_FY(a6),d3
	and.w   #$1ff,d3
	rts
******************************************************************************
*
*	部分表示
*
*	入力
*		d1.w...表示する縦方向のﾄﾞｯﾄ数
*		d2.w...画像上の位置x
*		d3.w...画像上の位置y
*		d6.w...表示する横方向のﾄﾞｯﾄ数
******************************************************************************
GetPart

*画面の表示縦や横のﾄﾞｯﾄ数が偶数の場合、１足す
*-------------------------
	add.w	XL4(a6),d6
	add.w	YL4(a6),d1

	movem.w	d0/d2/d5-d7,-(sp)

* a2.l = VRAMｱﾄﾞﾚｽ
*-------------------------
	movea.l	VSadr(a6),a2
	move.w	Interval+2(a6),d4
	move.w	d2,d0
	add.w	#$8000,d0
	mulu.w	Interval(a6),d0
	move.w	d0,d7
	clr.w	d0
	swap.w	d0
	divu.w	d4,d0
	move.w	d7,d0
	divu.w	d4,d0
	add.w	Home_FX(a6),d0
	and.w	#$1ff,d0
	move.w	d0,d5

	add.w	d0,d0
	adda.w	d0,a2

	move.w	d3,d0
	add.w	#$8000,d0
	mulu.w	Interval(a6),d0
	move.w	d0,d7
	clr.w	d0
	swap.w	d0
	divu.w	d4,d0
	move.w	d7,d0
	divu.w	d4,d0
	add.w	Home_FY(a6),d0
	move.l	d0,d4

	and.l	#$1ff,d0
	lsl.l	#8,d0
	lsl.l	#2,d0
	adda.l	d0,a2

* Y方向の残りﾄﾞｯﾄ数を計算(d4)
*---------------------------------
	sub.w	Home_Y(a6),d4
	and.w	#$1ff,d4
	sub.w	VSXsize(a6),d4
	neg.w	d4
	move.w	d4,Y_last(a6)

* Y方向の倍率計算ワーク作成(d4)
*---------------------------------
	swap.w	d4
	add.w	YL3(a6),d4

*Y位置が負の場合の処理
*---------------------------------
	tst.w	d3
	bpl	@f
	move.w	d5,-(sp)
	bsr	GetPartYOver
	move.w	(sp)+,d5
	tst.w	d1
	beq	GetPart_allend
@@
	cmp.w	Yline(a6),d3
	bcc	GetPart110

	cmp.w	Xline(a6),d2
	bge	GetPart110

	move.w	d2,d0
	add.w	d6,d0
	bmi	GetPart110

*画像横展開命令作成
*-------------------------
	move.w	d6,-(sp)

	subq.w	#1,d6
	add.w	d2,d6

	move.w	MOUSE_TZ(a6),d0
	cmp.w	HZ(a6),d0
	bne	GetPart_mkwk_10		倍率が変更された
	cmp.w	HX(a6),d5
	bne	GetPart_mkwk_10		Home位置が変化した
	cmp.w	XS(a6),d2
	bne	GetPart_mkwk_10		表示開始位置が変わった

	cmp.w	XE(a6),d6
	beq	GetPart_mkwk_end
GetPart_mkwk_10
	movem.l	d0-d4,-(sp)
	move.w	d5,HX(a6)
	move.w	d0,HZ(a6)
	move.w	d2,XS(a6)
	move.w	d6,XE(a6)
	move.w	VSXsize(a6),d7
	bsr	make_interval_work
	movem.l	(sp)+,d0-d4
GetPart_mkwk_end

	move.w	(sp)+,d6

* a0.l = 画像アドレス
*-------------------------
		tst.w	d2
		bpl	@f
		moveq.l	#0,d2
@@
		move.w	d2,d0
		and.l	#$0000fff8,d0
		lsl.l	#7-3,d0
		move.l	d0,a0

		move.w	d3,d0
		and.w	#$fff8,d0
		mulu.w	BlkX(a6),d0
		lsl.l	#7-3,d0
		adda.l	d0,a0

	*1ﾌﾞﾛｯｸ(8x8)中残り何ﾗｲﾝ目から表示するか計算
	* d7=残りﾗｲﾝ数
	*---------------------------
		moveq.l	#8,d7
		moveq.l	#7,d0
		and.w	d3,d0
		sub.w	d0,d7

		lsl.w	#4,d0
		adda.w	d0,a0

	*1ﾌﾞﾛｯｸ(8x8)中残り何ﾄﾞｯﾄ目から表示するか計算
	*---------------------------
		moveq.l	#$07,d0
		and.w	d2,d0
		add.w	d0,d0
		adda.w	d0,a0

		move.l	a0,TEMP_FP(a6)

	*画像ﾊﾞｯﾌｧから、何ﾗｲﾝ分表示するか計算(d1.h=画像外の表示ﾗｲﾝ数,d1.l=画像内の表示ﾗｲﾝ数)
	*-----------------------------
		move.w	Yline(a6),d0
		sub.w	d3,d0

		cmp.w	d1,d0
		bls	@f
		move.w	d1,d0
@@
		sub.w	d0,d1
		swap.w	d1
		move.w	d0,d1

	move.l	VSXbyte(a6),d5
	move.l	GETP_adrs(a6),a1

GetPart_Cont
* ﾃﾝﾎﾟﾗﾘﾌｧｲﾙから画像ﾃﾞｰﾀを読み込む
*---------------------------------
	move.l	TEMP_FP(a6),a0

	btst.b	#2,Sys_flag(a6)
	beq	getp10

	clr.w	-(sp)
	move.l	a0,-(sp)
	move.w	temp_handle(a6),-(sp)
	dos	_SEEK

	moveq.l	#7,d0
	and.w	d2,d0
	add.w	d6,d0
	addq.w	#7,d0
	and.w	#$fff8,d0
	lsl.l	#7-3,d0
	move.l	d0,-(sp)
	move.l  Scroll_Area(a6),-(sp)
	move.w	temp_handle(a6),-(sp)

	dos	_READ
	lea.l	8+10(sp),sp
	lea.l	$0000.w,a0
getp10
	adda.l	Scroll_Area(a6),a0

	moveq.l	#-8,d0
	add.w	d7,d0
	lsl.w	#4,d0
	ext.l	d0
	add.l	lx(a6),d0
	add.l	d0,TEMP_FP(a6)

*画像表示
*-------------------------
	sub.w	d7,d1
	bcc	@f
	add.w	d1,d7
	clr.w	d1
@@
	subq.w	#1,d7
getp40
	move.w	Interval+2(a6),d0
	sub.w	d0,d4
	bcs	getp41

	movea.l	a2,a5
	movea.l	a0,a4
	jsr	(a1)
	lea.l	1024(a2),a2	1line下
	move.l	a2,d0
	bclr.l	#19,d0
	movea.l	d0,a2

	subq.w	#1,Y_last(a6)
	bnz	getp40
	bra	GetPart_allend
getp41
	add.w	d0,d4
	add.w	Interval(a6),d4
	lea	16(a0),a0
	dbra	d7,getp40
getp42
	moveq.l	#8,d7
	tst.w	d1
	bnz	GetPart_Cont

	swap.w	d1
	move.w	HX(a6),d5
GetPart110
	tst.w	d1
	beq	GetPart_allend
	move.w	d1,d3
	neg.w	d3
	bsr	GetPartYOver
GetPart_allend
	movem.w	(sp)+,d0/d2/d5-d7
	rts



GetPartYOver
	move.w	d6,d7
	moveq.l	#0,d0
	move.w	XL3(a6),d0
	mulu.w	Interval(a6),d7
	add.l	d0,d7
	divu.w	Interval+2(a6),d7

	move.w	d5,d0
	sub.w	Home_X(a6),d0
	and.w	#$1ff,d0	d0=画面のHome位置から表示開始位置までのﾄﾞｯﾄ数
	sub.w	VSXsize(a6),d0
	neg.w	d0		d0=表示開始位置から、画面の右端までのﾄﾞｯﾄ数

	cmp.w	d7,d0
	bhi	@f
	move.w	d0,d7
@@
	add.w	d7,d5
	sub.w	#512,d5
	bhi	@f		VRAMの右端をまたぐ
	clr.w	d5		またがない
@@
	sub.w	d5,d7

	move.w	d5,-(sp)
	move.w	d7,-(sp)

getpYO100
	sub.w	Interval+2(a6),d4
	bcs	getpYO200

	movea.l	a2,a5

	moveq.l	#0,d0
	move.w	(sp),d7
	bra	2f
1	move.w	d0,(a5)+
2	dbra.w	d7,1b

	lea.l	-1024(a5),a5

	move.w	2(sp),d7
	bra	2f
1	move.w	d0,(a5)+
2	dbra.w	d7,1b

	lea.l	1024(a2),a2		1line下
	move.l	a2,d0
	and.l	#$c7ffff,d0
	movea.l	d0,a2

	subq.w	#1,Y_last(a6)
	bnz	getpYO100
	bra	getpYO_over_end

getpYO200
	add.w	Interval(a6),d4
	add.w	Interval+2(a6),d4
	subq.w	#1,d1
	beq	getpYOend
	addq.w	#1,d3
	bmi	getpYO100
getpYOend
	addq.l	#4,sp
	rts

getpYO_over_end
	moveq.l	#0,d1
	bra	getpYOend

  .end

