*
*       LOAD.S
*
*
*
	include	DOSCALL.MAC
	include	IOCSCALL.MAC
	include	JPEG.MAC
	include	work.inc
	include	keycode.inc

	.text
*
*
	.xref	GetBlock		'GETBLOCK.S'
	.xref	write_nbytes		'GETBLOCK.S'
	.xref	Get_Header		'GETHEAD.S'
	.xref	Scroll			'SCROLL.S'
	.xref	clear_area		'JPEG.S'
	.xref	Memory_error		'ERROR.S'
	.xref	temp_name,temp_file	'MES.S'
	.xref	make_UQ_table		'MK_MUL_TBL.S'
	.xref	Write_error		'ERROR.S'
	.xref	int4c_bak		'MES.S'
	.xref	mouse_sub_bak		'MES.S'
	.xref	work_adrs		'MES.S'
	.xref	Disp_Pic_Info		'GETHEAD.S'
*
	.xdef	Load,inkey
	.xdef	init_vwork
	.xdef	getmem_1block_line
*
*
Load
*ヘッダ解析
*----------------------------------
	bsr	Get_Header

	cmp.b	#2,Action(a6)
	beq	load_exit		-Hｵﾌﾟｼｮﾝ指定(ヘッダのみ表示)

*逆量子化ﾃｰﾌﾞﾙ作成
*---------------------
	move.w	#1,Qlevel(a6)
	bsr	SetQtable

*展開用のﾜｰｸｴﾘｱ確保
*----------------------------------
	move.l	free_adrs(a6),a2
	move.l	free_size(a6),d5
	move.l	#load_work_size-em_free_adrs,d1
	adda.l	d1,a2
	sub.l	d1,d5
	bcs	Memory_error

	*展開命令ﾜｰｸｴﾘｱｻｲｽﾞ計算
	*--------------------
	move.l	a2,GETP_adrs(a6)
	move.w	HE(a6),d1
	sub.w	HS(a6),d1
	addq.w	#1,d1
	mulu.w	#4*2,d1
	add.l	#12*2,d1
	adda.l	d1,a2
	sub.l	d1,d5
	bcs	Memory_error
	move.l	d1,GETP_size(a6)

	*逆量子化乗算ﾃｰﾌﾞﾙ作成＆ﾒﾓﾘ確保
	*---------------------
	bsr	make_UQ_table
	move.l	a2,buff_adrs(a6)
	move.l	d5,buff_size(a6)

*  アスペクトの補正
*-----------------------
	btst.b	#5,Sys_flag(a6)
	bne	adjust_Aspect_end	アスペクトの自動補正抑制ｵﾌﾟｼｮﾝ指定

	move.w	DCC_bits(a6),d0
	swap.w	d0
	move.w	DCL_bits(a6),d0
	cmp.l	#17*65536+17,d0
	bne	adjust_Aspect_1
	cmp.l	#2*65536+3,Aspect(a6)
	beq	set_Aspect_3_2

adjust_Aspect_1

	cmp.l	#16*65536+16,d0
	bne	adjust_Aspect_end
	cmp.w	#512,Xline(a6)
	bne	adjust_Aspect_end
	cmp.w	#512,Yline(a6)
	bne	adjust_Aspect_end

set_Aspect_3_2

	move.l	#3*65536+2,Aspect(a6)
	bset.b	#7,Sys_flag(a6)	*JPEG.X,JPGS.Xで作られた画像はRGBの最大値が252にしかならない
				*のでそのための補正用フラグ（って実際は補正してない）
adjust_Aspect_end

*画面の各種ﾜｰｸｴﾘｱを初期化
*------------------------
	bsr	init_vwork

*ｽｸﾛｰﾙ可能なｵﾌﾟｼｮﾝか？
*--------------------
	btst.b	#2,Sys_flag2(a6)
	beq	load50	もとより、スクロールするオプション指定ではない

	btst.b	#0,Sys_flag(a6)
	bne	@f		ｷｰ待ち有りなのでｽｸﾛｰﾙ有り
	btst.b	#7,Sys_flag2(a6)
	beq	load50		ｷｰ待ちなしで、ｵｰﾄｽｸﾛｰﾙもなしなので、ｽｸﾛｰﾙなし
@@
*展開後スクロール表示出来るか？
*----------------------
	move.l	picture_size(a6),d2
	add.l	#1024,d2		ファイル読み込みバッファ予約
	cmp.l	buff_size(a6),d2
	bcc	load20			画像全体をメモリに展開出来ない

	*出来る
	*----------------------------
	sub.l	#1024,d2
	move.l	d2,Scroll_size(a6)
	bra	load11

*スクロール表示でテンポラリファイルに展開
*----------------------------------------
load20
	btst.b	#1,Sys_flag(a6)
	beq	load50			ﾃﾝﾎﾟﾗﾘに展開ｵﾌﾟｼｮﾝ無しなので展開後ｽｸﾛｰﾙなし

	*横１ブロックライン分のメモリを取る
	*---------------------------------
	bsr	getmem_1block_line

	*テンポラリファイルのパスを取得
	*--------------------------------
	lea.l	temp_path(a6),a0
	tst.b	(a0)
	bne	load21

	move.l	a0,-(sp)
	clr.l	-(sp)
	pea.l	temp_name(pc)
	dos	_GETENV
	lea.l	12(sp),sp
	tst.l	d0
	bpl	load21

	move.b	'.',(a0)		環境変数tempが設定されていない場合は
	clr.b	1(a0)			カレントディレクトリにテンポラリファイルを作る

	*ﾃﾝﾎﾟﾗﾘﾊﾟｽにファイル名を追加
	*------------------------------
load21
	tst.b	(a0)+
	bne	load21
	subq.w	#1,a0
	lea.l	temp_file(pc),a1
load22
	move.b	(a1)+,(a0)+
	bne	load22

	*テンポラリファイルをオープン
	*----------------------------
	move.w	#$20,-(sp)
	pea.l	temp_path(a6)
	dos	_MAKETMP
	addq.w	#6,sp
	tst.l	d0
	bmi	load50			オープン出来ないので展開後のスクロール表示はしない

	move.w  d0,temp_handle(a6)
	bset.b  #2,Sys_flag(a6)		テンポラリに展開するフラグ

*スクロールでのセンタリング表示の準備
*------------------------------------
load11

	clr.w	XS(a6)
	clr.w	YS(a6)

	move.w	Xline(a6),d0
	move.w	VSXsize(a6),d1
	move.w	d0,XE(a6)
	sub.w	d0,d1
	bls	load12

	addq.w	#1,d1
	lsr.w	d1
	subq.w	#1,d0
	add.w	d1,d0
	move.w	d0,HE(a6)
	move.w	d1,HS(a6)

load12

	move.w	Yline(a6),d0
	move.w	VSYsize(a6),d1
	move.w	d0,YE(a6)
	sub.w	d0,d1
	bls	load13

	addq.w	#1,d1
	lsr.w	d1
	subq.w	#1,d0
	add.w	d1,d0
	move.w	d0,VE(a6)
	move.w	d1,VS(a6)

load13
	bra	load70


*画像展開後スクロールしない場合
*------------------------------
load50
	*横１ブロックライン分のメモリを取る
	*-------------------------------
	bsr	getmem_1block_line

	bclr.b	#2,Sys_flag2(a6)		スクロールしない

	*-fｵﾌﾟｼｮﾝの処理
	*------------------------
	cmp.b	#1,DispMod(a6)
	bcs	load53				-f0または-fｵﾌﾟｼｮﾝなし
	bne	load51

	*全画面引き延ばし
	*----------------------
	move.w	HE(a6),d0
	sub.w	HS(a6),d0
	addq.w	#1,d0
	move.w	d0,Interval(a6)
	move.w	Xline(a6),Interval+2(a6)

	move.w	VE(a6),d0
	sub.w	VS(a6),d0
	addq.w	#1,d0
	move.w	d0,Interval+4(a6)
	move.w	Yline(a6),Interval+6(a6)
	bra	load53

	*縦横比を変えずに、出来るだけ大きく表示
	*--------------------------
load51
	move.w	Xline(a6),d0		d0...Xline
	move.w	Yline(a6),d1		d1...Yline

	move.w	HE(a6),d2
	sub.w	HS(a6),d2
	addq.w	#1,d2		DX

	move.w	VE(a6),d3
	sub.w	VS(a6),d3
	addq.w	#1,d3		DY

	move.w	d2,d4
	lsr.w	#1,d4
	add.w	d2,d4		DX*3/2

	*  Xline * DY/Yline
	*-------------------
load51_Y

	move.l	d0,d7
	mulu.w	d3,d7
	divu.w	d1,d7

	* DX >= Xline * DY/Yline
	*------------------------
	cmp.w	d7,d2
	bcs	load51_Y2

	move.w  d3,Interval(a6)
	bra	load51_Y_1

	* DX*3/2 >= Xline * DY/Yline
	*----------------------------
load51_Y2

	move.w	Aspect(a6),d6
	cmp.w	Aspect+2(a6),d6
	bne	load51_X
	cmp.b	#3,DispMod(a6)
	beq	load51_X		-f3オプション時はドット比の変更はしない

	cmp.w	d7,d4
	bcs	load51_X

	move.l	#3*65536+2,Aspect(a6)
	move.w	d3,d6
	add.w	d6,d6
	ext.l	d6
	divu.w	#3,d6
	move.w	d6,Interval(a6)
load51_Y_1
	move.w	d3,Interval+4(a6)
	move.w	d1,Interval+2(a6)
	move.w	d1,Interval+6(a6)
	bra	load53

	*  DY >= Yline * DX*3/2/Xline
	*----------------------------
load51_X

	move.w	Aspect(a6),d6
	cmp.w	Aspect+2(a6),d6
	bne	load51_X2
	cmp.b	#3,DispMod(a6)
	beq	load51_X2		-f3オプション時はドット比の変更はしない

	move.w	d4,d7
	mulu.w	d1,d7
	divu.w	d0,d7
	cmp.w	d7,d3
	bcs	load51_X2

	move.l	#3*65536+2,Aspect(a6)
	move.w	d2,Interval(a6)
	move.w	d4,Interval+4(a6)
	bra	load51_X_1
*
*  Yline * DX/Xline
*
load51_X2

	move.w	d2,Interval(a6)
	move.w	d2,Interval+4(a6)
load51_X_1
	move.w	d0,Interval+2(a6)
	move.w	d0,Interval+6(a6)

load53

*横方向の表示開始と終了位置を計算
*---------------------------------
	move.w	Xline(a6),d0
	sub.w	XS(a6),d0

	mulu	Interval(a6),d0
	divu	Interval+2(a6),d0	d0=画面上でのドット数

	btst.b	#3,Sys_flag2(a6)
	bne	load55		位置指定あり

	move.w	VSXsize(a6),d1		センタリングする
	sub.w	d0,d1
	bcs	load55
	addq.w	#1,d1
	lsr.w	d1
	move.w	d1,HS(a6)

	*横方向の表示終了位置が画面内に収まるようにする
	*---------------------------------------------
load55

	add.w	HS(a6),d0
	subq.w	#1,d0
	move.w	HE(a6),d1		d1=画面上での横方向表示終了位置(オプション指定で変更あり)
	cmp.w	d0,d1
	bhi	load63
	move.w	d1,d0
load63
	move.w	d0,HE(a6)

*縦方向の表示開始と終了位置を計算
*-----------------------------------
	move.w	Yline(a6),d0
	sub.w	YS(a6),d0
	mulu	Interval+4(a6),d0
	divu	Interval+6(a6),d0

	btst.b	#3,Sys_flag2(a6)
	bne	load64		位置指定あり

	move.w	VSYsize(a6),d1	センタリングする
	sub.w	d0,d1
	bcs	load64
	addq.w	#1,d1
	lsr.w	d1
	move.w	d1,VS(a6)

	*縦方向の表示終了位置が画面内に収まるようにする
	*---------------------------------------------
load64
	add.w	VS(a6),d0
	subq.w	#1,d0
	move.w	VE(a6),d1
	cmp.w	d0,d1
	bhi	load66
	move.w	d1,d0
load66
	move.w	d0,VE(a6)


load70
*仮想画面ファイルバッファ確保
*--------------------------------
	btst.b	#5,Sys_flag2(a6)
	beq	load_get_VSF_buf_end	ｵﾌﾟｼｮﾝは仮想画面ファイル指定ではない

	bsr	getmem_1line
	move.w	#1,-(sp)
	pea.l	VSname(a6)
	dos	_OPEN
	addq.w	#4+2,sp
	tst.l	d0
	bpl	load_get_VSF_buf_ok	ファイルがすでに存在している

	move.w	#$20,-(sp)
	pea.l	VSname(a6)
	dos	_CREATE
	addq.w	#4+2,sp
	tst.l	d0
	bmi	Write_error		ファイルが作成出来ない

load_get_VSF_buf_ok

	move.w	d0,VShandle(a6)

load_get_VSF_buf_end

*読み込みバッファの確保
*--------------------------------
	bsr	getmem_file_buf

*スーパバイザーモードへ以降
*--------------------------------
	clr.l	-(sp)
	dos	_SUPER
	move.l	d0,(sp)

	bsr	Get_vector

*スクリーンモード設定
*--------------------------------
	btst.b	#4,Sys_flag2(a6)
	bne	load83			仮想画面に展開なので画面初期化はしない

	btst.b	#1,Sys_flag2(a6)
	bne	load80			-nｵﾌﾟｼｮﾝ指定有り（設定しない）

	*現在のｽｸﾘｰﾝﾓｰﾄﾞ判定
	*-----------------------------
	moveq.l	#-1,d1
	iocs	_CRTMOD
	cmp.w	#$0c,d0
	beq	Load76

	*違うｽｸﾘｰﾝﾓｰﾄﾞだった
	*-----------------------------
	move.w	#$0c,d1
	iocs	_CRTMOD
	iocs	_G_CLR_ON
	bra	load77

	*同じｽｸﾘｰﾝﾓｰﾄﾞだった
	*-----------------------------
Load76
	move.w	#$10c,d1
	iocs	_CRTMOD
	moveq.l	#2,d1				text clrar
	moveq.l	#$2a,d0
	trap	#15
	moveq.l	#3,d1
	iocs	$91
	ori.w	#%0000_0000_0000_1111,$e8002a	Graphic Fast Clear
	move.w	#2,$e80480
@@	btst.b	#1,$e80480+1
	bnz	@b

	move.w	#%0000_0000_0010_1111,d1
	iocs	$93
load77
	moveq.l	#0,d2
	moveq.l	#0,d3
	bsr	set_HOME

	*ドット比が１：１の場合正方形モードにする
	*-------------------------
load80
	cmp.b	#1,DispMod(a6)
	beq	load82		全画面に引き延ばしの場合は正方形モードにしない

	move.w	Aspect(a6),d0
	cmp.w	Aspect+2(a6),d0
	bne	load82		正方形ではない
	bsr	Square
load82
	*マウスの初期化
	*---------------------------
	iocs	_MS_INIT
	moveq.l	#0,d1
	iocs	_SKEY_MOD
	iocs	_MS_CUROF

	moveq.l	#$0000_0000,d1
	move.l	#$01ff_01ff,d2
	iocs	_MS_LIMIT
	move.l	#$0100_0100,d1
	iocs	_MS_CURST

	*　カーソルを消す
	*-------------------
	move.w	#18,-(sp)
	dos	_CONCTRL
	addq.w	#2,sp

*展開表示
*---------------------------
load83
	move.l	sp,ErrorStackPoint(a6)
	bsr	GetBlock		画像展開
	tst.l	d0
	bmi	load_end		強制終了

		move.b	#1,DecodeStatus(a6)
		bra	Load84

.xdef LoadForceContinue
LoadForceContinue			*画像に異常が有っても、強制終了しない場合、
					*GetBlockの中からここに飛んでくる
		move.b	#-1,DecodeStatus(a6)
Load84
		clr.l	ErrorStackPoint(a6)

		*画像情報表示要求がある場合は表示する（状態項目更新の為)
		*-------------------------
		btst.b	#0,Sys_flag3(a6)
		beq	@f
		bsr	Disp_Pic_Info	
@@

*仮想画面ファイルを閉じる
*----------------------------
	btst.b	#5,Sys_flag2(a6)
	beq	close_VSfile_end

	*仮想画面ファイルサイズ計算
	*-----------------------------
	move.w	VSXsize(a6),d5
	mulu.w	VSYsize(a6),d5
	add.l	d5,d5

	*現在の仮想画面ファイルサイズを取得
	*-----------------------------
	move.w	#2,-(sp)
	clr.l	-(sp)
	move.w	VShandle(a6),-(sp)
	dos	_SEEK
	addq.w	#2+4+2,sp
	tst.l	d0
	bmi	Write_error

	sub.l	d0,d5
	bls	close_VSfile

	move.l	d5,d0
	move.l	buff_size(a6),d5
	cmp.l	d0,d5
	bls	clear_VSfile
	move.l	d0,d5
clear_VSfile
	move.l	Scroll_Area(a6),a5
	movem.l	d0/d5/a5,-(sp)		d5=clear memory size
	bsr	clear_area		d0=clear file size
	movem.l	(sp)+,d0/d5/a5
	exg.l	d0,d5			d5=write file size
	bsr	write_nbytes		d0=write memory size

close_VSfile

	move.w	VShandle(a6),-(sp)
	dos	_CLOSE
	addq.w	#2,sp
	tst.l	d0
	bmi	Write_error

close_VSfile_end

*スクロール表示可能か
*----------------------------
	btst.b	#2,Sys_flag2(a6)
	beq	load90			スクロール表示はしない

	btst.b	#2,Sys_flag(a6)
	beq	load87			ﾃﾝﾎﾟﾗﾘに展開はしていない

	btst.b	#3,Sys_flag(a6)
	bne	load90			ディスクフル

	*展開後不用になったﾜｰｸｴﾘｱを解放して、ﾃﾝﾎﾟﾗﾘに展開した画像が読み込めるか？
	*------------------------------
	movea.l	free_adrs(a6),a0
	move.l	a0,GETP_adrs(a6)
	adda.l	GETP_size(a6),a0
	move.l	a0,Scroll_Area(a6)

	move.l	free_size(a6),d0
	sub.l	GETP_size(a6),d0
	sub.l	picture_size(a6),d0
	bcs	load87			読み込めない

	*ﾒｯｾｰｼﾞ読み込みﾊﾞｯﾌｧﾜｰｸ更新
	*------------------------------
	cmp.l	#1024,d0
	bcs	load87
	move.l	#65535,d1
	cmp.l	d1,d0
	bls	@f
	move.l	d1,d0
@@
	move.l	d0,buf_size(a6)

	*画像全体を読み込む
	*------------------------------
	clr.w	-(sp)
	clr.l	-(sp)
	move.w	temp_handle(a6),-(sp)
	dos	_SEEK			ファイルの先頭へ

	move.l	picture_size(a6),-(sp)
	move.l	Scroll_Area(a6),-(sp)
	move.w	temp_handle(a6),-(sp)
	dos	_READ
	lea.l	8+10(sp),sp		画像を全部読み込む

	bsr	close_temp		ﾃﾝﾎﾟﾗﾘﾌｧｲﾙを削除


*スクロール表示
*------------------------------
load87
	bsr	Scroll
	bra	load_end_adjust_home

*展開表示後のキー入力待ち
*------------------------------
load90
	btst.b	#0,Sys_flag(a6)
	beq	load_end_adjust_home	キー入力待ちｵﾌﾟｼｮﾝなし
@@
	dc.w	$ffff

	bsr	inkey
	tst.l	d0
	beq	@b

load_end_adjust_home

	bsr	pic_home_adjust

*表示終了
*-------------------------------
load_end
	*他ｱﾌﾟﾘ(G_VIEW)用に画面のHome位置を設定
	*-----------------------------
	bsr	set_HOME_for_apli

	*ﾃﾝﾎﾟﾗﾘﾌｧｲﾙ削除
	*-------------------------------
	bsr	close_temp

	*もしﾒｯｾｰｼﾞを表示していたら消去して終了
	*-------------------------------
@@
	btst.b	#0,Sys_flag3(a6)
	beq	@f
	bsr	inkey_undo
	bra	@b
@@
	*マウス初期化
	*-------------------------------
	btst.b	#5,Sys_flag2(a6)
	bne	load_end_VS		仮想画面に展開した場合は、何もしないで終了

	iocs	_MS_INIT
	moveq.l	#-1,d1
	iocs	_SKEY_MOD

	*カーソル表示
	*--------------------------------
	move.w	#17,-(sp)
	dos	_CONCTRL
	addq.w	#2,sp

	*ユーザーモードへ復帰
	*-------------------------------
load_end_VS

	bsr	Restore_vector
	clr.w	-(sp)
	DOS	_KFLUSH
	addq.l	#2,sp
	dos	_SUPER
	addq.w	#4,sp

load_exit

*	dos	_EXIT
	rts

*******************************************************************
*
*	画面サイズより、各ﾜｰｸを初期化
*
*******************************************************************
init_vwork

	*  画像の縦,横のﾌﾞﾛｯｸ数, ﾌﾞﾛｯｸの縦横のﾄﾞｯﾄ数を計算
	*--------------------------------
	move.w	Xline(a6),d1
	move.w	Yline(a6),d2
	moveq.l	#8,d3
	moveq.l	#8,d4

	addq.w	#7,d1
	addq.w	#7,d2
	lsr.w	#3,d1
	lsr.w	#3,d2

	move.b	uvmode(a6),d0
	subq.b	#1,d0
	beq	@f

	add.w	d3,d3
	addq.w	#1,d1
	bclr.l	#0,d1

	subq.b	#1,d0
	beq	@f

	add.w	d4,d4
	addq.w	#1,d2
	bclr.l	#0,d2
@@
	move.w	d1,BlkX(a6)		横方向のブロック数
	move.w	d2,BlkY(a6)		縦方向のブロック数
	move.w	d3,DeltaX(a6)		1ﾌﾞﾛｯｸ辺りの横のﾄﾞｯﾄ数
	move.w	d4,DeltaY(a6)		1ﾌﾞﾛｯｸ辺りの縦のﾄﾞｯﾄ数

	*  画像の使用ﾒﾓﾘ容量を計算
	*--------------------------------
	lsl.w	#3,d1
	lsl.w	#3,d2
	mulu.w	d1,d2
	add.l	d2,d2			d2=使用メモリ容量
	move.l	d2,picture_size(a6)

	moveq.l	#0,d1
	move.w	BlkX(a6),d1
	lsl.l	#3+1,d1
	move.l	d1,HScroll_size(a6)
	lsl.l	#3,d1
	move.l	d1,lx(a6)
	move.l	buff_adrs(a6),Scroll_Area(a6)

	moveq.l	#0,d0
	move.w	VSXsize(a6),d0
	add.l	d0,d0
	move.l	d0,VSXbyte(a6)
	rts


*******************************************************************
*
*	横１ブロックライン分のメモリを取る
*
*******************************************************************
getmem_1block_line

	move.w	BlkX(a6),d0
	mulu.w	DeltaY(a6),d0
	lsl.l	#3+1,d0
	cmp.l	buff_size(a6),d0
	bcc	Memory_error			確保出来ないのでエラー
	move.l	d0,Scroll_size(a6)
	bset.b	#4,Sys_flag(a6)
	rts

*******************************************************************
*
*	画面横１ライン分のメモリを取る
*
*******************************************************************
.xdef getmem_1line
getmem_1line
	movea.l	Scroll_Area(a6),a0
	adda.l	Scroll_size(a6),a0
	move.l	a0,VSFile_buf_adrs(a6)
	moveq.l	#0,d0
	move.w	HE(a6),d0
	sub.w	HS(a6),d0
	addq.w	#1,d0
	add.l	d0,d0
	cmp.l	buff_size(a6),d0
	bcc	Memory_error			確保出来ないのでエラー
	move.l	d0,VSFile_buf_size(a6)
	rts

*******************************************************************
*
*	ﾌｧｲﾙｱｸｾｽﾊﾞｯﾌｧの確保
*
*******************************************************************
	.xdef	getmem_file_buf
getmem_file_buf
	movea.l	Scroll_Area(a6),a0
	adda.l	Scroll_size(a6),a0
	adda.l	VSFile_buf_size(a6),a0
	move.l	a0,buf_adrs(a6)
	move.l	buff_size(a6),d0
	sub.l	Scroll_size(a6),d0
	bls	Memory_error
	sub.l	VSFile_buf_size(a6),d0
	bls	Memory_error
	cmp.l	#65535,d0
	bls	getmem_file_buf72
	move.l	#65535,d0
getmem_file_buf72
	move.l	d0,buf_size(a6)
	rts










******************************************************************************
*
*   INKEY
*
*	入力	なし
*	出力	d6,d7.....x,y移動量
*		d5........z(拡大縮小量)
*	破壊	d0-d5,a0-a2
*
******************************************************************************
inkey
*マウスデータ読み込み
*-------------------------
	*終了か
	*-------------------
	iocs	_MS_GETDT
	cmp.w	#$ff_ff,d0
	beq	inkey_end_key2		終了である

	move.w	MOUSE_TZ(a6),d5

	*カーソル位置読み込み
	*-------------------
	iocs	_MS_CURGT
	move.w	d0,d7
	swap.w	d0
	move.w	d0,d6
	sub.w	#$100,d6
	bcs	inkey_ms_posx_sub
	add.w	MOUSE_TX(a6),d6
	bcc	inkey_ms_posy
	move.w	#$ffff,d6
	bra	inkey_ms_posy
inkey_ms_posx_sub
	add.w	MOUSE_TX(a6),d6
	bcs	inkey_ms_posy
	moveq.l	#0,d6

inkey_ms_posy

	sub.w	#$100,d7
	bcs	inkey_ms_posy_sub
	add.w	MOUSE_TY(a6),d7
	bcc	inkey_keyboard
	move.w	#$ffff,d7
	bra	inkey_keyboard
inkey_ms_posy_sub
	add.w	MOUSE_TY(a6),d7
	bcs	inkey_keyboard
	moveq.l	#0,d7

inkey_keyboard

	move.l	#$0100_0100,d1
	iocs	_MS_CURST


*キー入力
*-------------------
inkey_loop
		lea.l	Key_jmp_tbl(pc),a2

inkey_loop1
		move.w	(a2)+,d0
		beq	inkey_special

		lea.l	Key_work(a6),a1
		add.w	d0,a1
		bsr	get_key_time
		move.w	(a2)+,d0
		tst.w	d1
		beq	inkey_loop1
		bset.b	#2,Sys_flag3(a6)
		jsr	inkey_loop(pc,d0.w)
		bra	inkey_loop1
inkey_special
		move.w	(a2)+,d0
		beq	inkey_end

		lea.l	Key_work(a6),a1
		add.w	d0,a1
		bsr	get_key_time
		move.w	(a2)+,d0
		tst.w	d1
		beq	inkey_special
		jsr	inkey_loop(pc,d0.w)
		bra	inkey_special

inkey_end_key
		addq.l	#4,sp
inkey_end_key2
		moveq.l	#-1,d0
		rts

inkey_end
	move.w	Xline(a6),d0
	cmp.w	d0,d6
	bls	@f
	move.w	d0,d6
	subq.w	#1,d6
@@

	move.w	Yline(a6),d0
	cmp.w	d0,d7
	bcs	@f
	move.w	d0,d7
	subq.w	#1,d7
@@
	move.w	d6,MOUSE_TX(a6)
	move.w	d7,MOUSE_TY(a6)
	moveq.l	#0,d0
	rts

inkey_up
	sub.w	d1,d7
	bcc	@f
	moveq.l	#0,d7
@@:	rts

inkey_down
	add.w	d1,d7
	bcc	@f
	moveq.l	#-1,d7
@@:	rts

inkey_left
		sub.w	d1,d6
		bcc	@f
		moveq.l	#0,d6
@@:		rts

inkey_right
		add.w	d1,d6
		bcc	@f
		moveq.l	#-1,d6
@@:		rts

inkey_zoomin
		add.w	d1,d5
		bcs	1f

		move.w	Maxline(a6),d0
*		add.w	#512-1,d0
		add.w	d0,d0
		subq.w	#1,d0
*

		cmp.w	d0,d5
		bls	2f
1		move.w	d0,d5
2		rts

inkey_zoomout
		sub.w	d1,d5
		bls	1f

		cmp.w	#1,d5
		bhi	2f
1
		moveq.l	#1,d5
2
		moveq.l	#0,d0
		move.w	Maxline(a6),d0
		cmp.w	d0,d5
		bhi	inkey_zoomout_end

		lsr.l	#16-9,d0
		addq.w	#1,d0
		cmp.w	d0,d5
		bcc	inkey_zoomout_end

		move.w	d0,d5

inkey_zoomout_end
		rts

*-----------------------------
*表示位置、表示倍率をﾃﾞﾌｫﾙﾄへ
*-----------------------------
inkey_home
		bclr.b	#2,Sys_flag3(a6)
		bnz	inkey_home_first

		move.b	Home_key_time(a6),d0
		tst.b	d0
		bne	inkey_home_next

	*最初のHomeｷｰが押された場合の処理
	*-------------------------
inkey_home_first
		move.w	Maxline(a6),d5
		move.w	Xline(a6),d6
		move.w	Yline(a6),d7
		lsr.w	d6
		lsr.w	d7
		bra	inkey_home_end

	*二回目のHomeｷｰが押された場合の処理
	*　画像を画面のｻｲｽﾞに合わせる
	*-------------------------
inkey_home_next
		*表示倍率をｷｰﾜｰｸと同じ形式に変換
		*----------------------
		move.w	Maxline(a6),d5
		move.w	#512,d0
		cmp.w	d0,d5
		bcs	1f		拡大方向へ

			*縮小
			*---------------------
			move.w	d0,d5
			bra	2f
			*拡大
			*----------------------
1
			move.w	d0,d5
2
		*画像のﾎｰﾑ位置を計算
		*----------------------
		move.w	Xline(a6),d6
		move.w	Yline(a6),d7
		lsr.w	d6
		lsr.w	d7
inkey_home_end

		move.b	Home_key_time(a6),d0
		addq.b	#1,d0
		cmp.b	#2,d0
		bcs	@f
		moveq.l	#0,d0
@@
		move.b	d0,Home_key_time(a6)
		rts

*----------------------
*画像情報を表示
*----------------------
inkey_undo
		btst.b	#4,Sys_flag2(a6)
		bnz	inkey_undo_end

		btst.b	#0,Sys_flag3(a6)
		beq	inkey_undo_disp1

		bchg.b	#1,Sys_flag3(a6)
		bne	inkey_undo_disp2

	*表示中で、半階調に設定
	*----------------------------
		move.w	#$1b3f,$e82600
		rts

	*表示
	*----------------------------
inkey_undo_disp1
		bset.b	#0,Sys_flag3(a6)
		bsr	cls_text
		bra	Disp_Pic_Info


	*表示解除
	*----------------------------
inkey_undo_disp2
		bclr.b	#0,Sys_flag3(a6)
		bclr.b	#1,Sys_flag3(a6)
		bsr	cls_text
		move.w	#$003f,$e82600
inkey_undo_end
		rts


get_key_time
		move.w	4(a1),d1
		clr.w	4(a1)
		move.w	(a1),d0
		cmp.w	#$ffff,d0
		beq	get_key_time_end

		move.w	$9cc.w,d2
		sub.w	d2,d0
		bcc	@f		ｵｰﾊﾞｰﾌﾛｰしていない
		add.w	$9ca.w,d0
@@
		add.w	d0,d0
		cmp.w	#$fffe,2(a1)
		bhi	get_key_time_1	ﾘﾋﾟｰﾄ中
		beq	@f		ﾘﾋﾟｰﾄ開始待ち中

		move.w	#$fffe,2(a1)	最初のkey onの処理をしたことをマーク
		moveq.l	#1,d0
		bra	get_key_time_2
@@
		sub.w	#20*2,d0
		bls	get_key_time_end	まだﾘﾋﾟｰﾄ開始ではない
		move.w	#$ffff,2(a1)	ﾘﾋﾟｰﾄ中である事をマーク
get_key_time_1
		move.w	d2,(a1)

	*移動高速化ｷｰﾁｪｯｸ
	*------------------------------
get_key_time_2
		bsr	chk_key_fast
		add.w	d0,d1
get_key_time_end
		rts


Key_jmp_tbl
	*通常のｷｰ処理
	*-------------------------
		.dc.w	K_Up*6,inkey_up-inkey_loop
		.dc.w	K_T2*6,inkey_up-inkey_loop

		.dc.w	K_Down*6,inkey_down-inkey_loop
		.dc.w	K_T8*6,inkey_down-inkey_loop

		.dc.w	K_Right*6,inkey_right-inkey_loop
		.dc.w	K_T4*6,inkey_right-inkey_loop

		.dc.w	K_Left*6,inkey_left-inkey_loop
		.dc.w	K_T6*6,inkey_left-inkey_loop

		.dc.w	K_PgUp*6,inkey_zoomout-inkey_loop
		.dc.w	K_PgDn*6,inkey_zoomin-inkey_loop

		.dc.w	K_Esc*6,inkey_end_key-inkey_loop
		.dc.w	K_BkSp*6,inkey_end_key-inkey_loop
		.dc.w	K_Enter*6,inkey_end_key-inkey_loop
		.dc.w	K_Space*6,inkey_end_key-inkey_loop

		.dc.w	K_Undo*6,inkey_undo-inkey_loop

		.dc.w	$80*6,inkey_zoomout-inkey_loop
		.dc.w	$81*6,inkey_zoomin-inkey_loop

		.dc.w	0

	*ちょっと特別なｷｰ処理
	*-------------------------
		.dc.w	K_Home*6,inkey_home-inkey_loop

		.dc.w	0

***********************
*
*	移動高速化キーチェック
*
*	入力	d0	移動量
*	出力	d0	移動量
*	破壊	無し
***********************
.xdef chk_key_fast
chk_key_fast
		cmp.w	#$ffff,Key_work+K_Ctrl*6(a6)
		bne	3f			Ctrl同時押し
		cmp.w	#$ffff,Key_work+K_Opt1*6(a6)
		bne	3f			Opt.1同時押し

		btst.b	#3,Sys_flag3(a6)
		bne	1f			TV ctrlｷｰも移動高速化ｷｰとして強制使用

		btst.b	#0,$ed0027
		beq	4f			Opt.2はTV ctrl
		bra	2f			Opt.2はnormal
1:
		cmp.w	#$ffff,Key_work+K_Shift*6(a6)
		bne	3f			Shift同時押し
2:
		cmp.w	#$ffff,Key_work+K_Opt2*6(a6)
		bne	3f			Opt.2同時押し
		bra	4f
3:
		lsl.w	#2,d0
4:
		rts
******************************************************************************
*
*   ベクタ取得
*
******************************************************************************
Get_vector
*Ctrl-Cとプロセスのアボートベクタを変更する
*--------------------------------------------
		pea.l	abort_process(pc)
		move.w	#_CTRLVC,-(sp)
		DOS	_INTVCS
		addq.w	#6,sp

		pea.l	abort_process(pc)
		move.w	#_ERRJVC,-(sp)
		DOS	_INTVCS
		addq.w	#6,sp

*KEY BUFFER FULL割り込みのベクタを乗っ取る
*--------------------------------------------
	*Key_workを初期化
	*--------------------------------
		lea.l	Key_work(a6),a0
		move.l	#$ffff0000,d0
		move.w	#128+2-1,d1
@@
		move.l	d0,(a0)+
		move.w	d0,(a0)+
		dbra	d1,@b

	*ﾍﾞｸﾀを初期化
	*-------------------------------
		*元ﾍﾞｸﾀを取得
		*---------------------
		move.w	#$4c,-(sp)
		DOS	_INTVCG
		addq.l	#2,sp
		lea.l	int4c_bak(pc),a0
		move.l	d0,(a0)
		*ﾍﾞｸﾀを書き替え
		*---------------------
		pea	int4c(pc)
		move.w	#$4c,-(sp)
		DOS	_INTVCS
		addq.l	#2+4,sp

*ﾏｳｽ受信ｷｬﾗｸﾀ有効割り込み処理内からｺｰﾙされるﾍﾞｸﾀの一つを乗っ取る
*--------------------------------------------
		lea.l	mouse_sub_bak(pc),a0
		move.l	$934.w,(a0)
		lea.l	mouse_int(pc),a0
		move.l	a0,$934.w
		rts
******************************************************************************
*
*   ベクタ復帰
*
******************************************************************************
.xdef	Restore_vector
Restore_vector
		move.l	int4c_bak(pc),d0
		beq	Restore_vector_4c_end	ﾍﾞｸﾀﾌｯｸしていない
		move.l	d0,-(sp)
		move.w	#$4c,-(sp)
		DOS	_INTVCS
		addq.l	#2+4,sp
Restore_vector_4c_end

		move.l	mouse_sub_bak(pc),d0
		beq	Restore_vector_mouse_end	ﾍﾞｸﾀﾌｯｸしていない
		move.l	d0,$934.w
Restore_vector_mouse_end

		rts
*******************************************************
*
*	Ctrl-Cまたは処理を中断された場合の処理
*
*	input	none
*	output	none
*	break	d0.l,d1.l
*******************************************************
abort_process
		move.l	work_adrs(pc),a6
		bsr	Restore_vector
		bsr	set_HOME_for_apli
		clr.w	-(sp)
		DOS	_KFLUSH
		move.w	#-1,(sp)
		DOS	_EXIT2
*******************************************************
*
*	Key Buffer Full 割り込み処理
*
*	input	none
*	output	none
*	break	none
*******************************************************
int4c
		movem.l	d0/a0/a6,-(sp)
		move.l	work_adrs(pc),a6
		lea.l	Key_work(a6),a0

		moveq.l	#0,d0
		move.b	$e8802f,d0
		pea.l	int4c_end(pc)
		add.b	d0,d0
		bcc	keyon_sub	ｷｰｵﾝ処理
		bra	keyoff_sub
int4c_end
		movem.l	(sp)+,d0/a0/a6
		move.l	int4c_bak(pc),-(sp)
		rts

*----------------------------
*ｷｰｵﾝ処理
*	d0.w	ｷｰｽｷｬﾝｺｰﾄﾞ*2
*----------------------------
keyon_sub
		add.l	d0,a0
		add.w	d0,d0
		add.l	d0,a0
		cmp.w	#$ffff,(a0)
		bne	@f			ｷｰｵﾝ中

	*TV ctrlｷｰが同時押しのｷｰｵﾝは、無視
	*----------------------
		btst.b	#3,Sys_flag3(a6)
		bne	keyon_sub_set_time	TV ctrlｷｰも移動高速化ｷｰとして強制使用

		cmp.w	#$ffff,Key_work+K_Shift*6(a6)
		bne	@f			Shiftが押されている

		btst.b	#0,$ed0027
		bne	keyon_sub_set_time	Opt.2はTVctrlｷｰではない
		cmp.w	#$ffff,Key_work+K_Opt2*6(a6)
		bne	@f			Opt2が押されている

	*ｷｰｵﾝ開始時間を設定
	*------------------------
keyon_sub_set_time
		move.w	$9cc.w,(a0)
		clr.w	2(a0)
@@
		rts
*----------------------------
*ｷｰｵﾌ処理
*	d0.w	ｷｰｽｷｬﾝｺｰﾄﾞ*2
*----------------------------
keyoff_sub
		add.l	d0,a0
		add.w	d0,d0
		add.l	d0,a0
		move.w	(a0),d0
		cmp.w	#$ffff,d0
		beq	keyoff_sub_end	すでにｷｰｵﾌになっている

		*ｷｰｵﾌ時間を計算
		*----------------------
		sub.w	$9cc.w,d0
		bcc	@f		ｵｰﾊﾞｰﾌﾛｰしていない
		add.w	$9ca.w,d0
@@
		add.w	d0,d0

	*ﾘﾋﾟｰﾄ中の場合、ｷｰｵﾌまでの時間をｷｰｵﾝ時間に加算
	*----------------------
		cmp.w	#$fffe,2(a0)
		beq	keyoff_sub_1	ﾘﾋﾟｰﾄ開始待ちだった
		bhi	@f		ﾘﾋﾟｰﾄ中

		*ｷｰｵﾝからｷｰｵﾌまで、ｷｰｵﾝ時間を読まれなかった場合の処理
		*--------------------
		sub.w	#20*2,d0
		bhi	@f
		moveq.l	#1,d0
@@
		add.w	d0,4(a0)	ｷｰﾘﾋﾟｰﾄ開始からｷｰｵﾌまでの時間を加算
keyoff_sub_1
		move.w	#$ffff,(a0)	ｷｰｵﾌ中ﾌﾗｸﾞ設定
keyoff_sub_end
		rts
*******************************************************
*
*	Mouse受信ｷｬﾗｸﾀ割り込み処理内からｺｰﾙされるﾍﾞｸﾀの内の
*	一つの処理
*
*	input	a1.l	ﾏｳｽﾃﾞｰﾀのｱﾄﾞﾚｽ
*	output	none
*	break	none
*******************************************************
mouse_int
		movem.l	d0/a0/a6,-(sp)
		move.l	work_adrs(pc),a6

*左ﾎﾞﾀﾝの処理
*----------------------------
		lea.l	Mouse_work(a6),a0
		moveq.l	#0*2,d0

		pea.l	mouse_int_left_end(pc)	戻りｱﾄﾞﾚｽ
		btst.b	#1,(a1)
		bnz	keyon_sub	ｷｰｵﾝ処理
		bra	keyoff_sub
mouse_int_left_end

*右ﾎﾞﾀﾝの処理
*----------------------------
		lea.l	Mouse_work(a6),a0
		moveq.l	#1*2,d0
		pea.l	mouse_int_right_end(pc)	戻りｱﾄﾞﾚｽ
		btst.b	#0,(a1)
		bnz	keyon_sub	ｷｰｵﾝ処理
		bra	keyoff_sub
mouse_int_right_end

		movem.l	(sp)+,d0/a0/a6
		move.l	mouse_sub_bak(pc),a0
		jmp	(a0)

******************************************************************************
*
*   home位置を上位アプリ用に設定
*
*	入力	d2.w	X
*		d3.w	Y
*
******************************************************************************
.xdef	set_HOME_wait
set_HOME_wait

	*帰線期間待ち
	*---------------------
@@
	btst.b	#4,$e88001
	beq	@b
@@
	btst.b	#4,$e88001
	bnz	@b

.xdef	set_HOME
set_HOME
	move.w	d2,Home_X(a6)
	move.w	d3,Home_Y(a6)

	moveq.l	#$00,d1
	IOCS	_HOME
	rts

.xdef	set_HOME_for_apli
set_HOME_for_apli
	move.w	Home_X(a6),d2
	move.w	Home_Y(a6),d3

	moveq.l	#$00,d1
	IOCS	_SCROLL
	moveq.l	#$01,d1
	IOCS	_SCROLL
	moveq.l	#$02,d1
	IOCS	_SCROLL
	moveq.l	#$03,d1
	IOCS	_SCROLL
	rts

******************************************************************************
*
*   画像のhome位置を(0,0)に変更
*
*	入力	Home_X(a6)
*		Home_Y(a6)
*	出力	無し
*	破壊
******************************************************************************
.xdef pic_home_adjust
pic_home_adjust

		btst.b	#5,Sys_flag3(a6)
		beq	pic_home_adjust_end	補正要求無し

		move	Home_Y(a6),d1
		move	Home_X(a6),d0
		move.w	d0,d2
		or.w	d1,d2
		beq	pic_home_adjust_end	すでにHome位置は(0,0)である

		movem.w	d0/d1,-(sp)

		moveq.l	#0,d2
		moveq.l	#0,d3
		bsr	set_HOME

		movem.w	(sp)+,d0/d1

		move.w	#512,d7
		moveq.l	#0,d4
		bra	pic_home_adjust_start

pic_home_adjust_loop

		cmp.w	d3,d4
		bne	1f

		lea.l	em_free_adrs(a6),a0
		move.l	#512/8-1,d2
@@
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		dbra.w	d2,@b

		addq.w	#1,d4
		and.w	#$1ff,d4

pic_home_adjust_start

		move.w	d4,d3
		lea.l	em_free_adrs(a6),a0
1
		lea.l	$c00000,a1
		moveq.l	#0,d2
		move.w	d3,d2
		lsl.l	#8,d2
		lsl.l	#2,d2
		add.l	d2,a1
		bsr	get_VRAM_adjust_X

pic_home_adjust_next

		add.w	d1,d3
		and.w	#$1ff,d3

		move.l	a1,a0
		dbra.w	d7,pic_home_adjust_loop

pic_home_adjust_end

		rts

*******************************
*VRAM読み込み
*
*	入力	d0	XのHome位置
*		a0	取り込みﾊﾞｯﾌｧｱﾄﾞﾚｽ
*		a1	VRAMｱﾄﾞﾚｽ
*	出力	なし
*	破壊	d2,a0,a2
*******************************
get_VRAM_adjust_X
	*右側取り込み
	*------------------------
		movea.l	a1,a2
		add.w	d0,a2
		add.w	d0,a2

		move.w	#512,d2
		sub.w	d0,d2

		*ﾛﾝｸﾞﾜｰﾄﾞで転送した余り
		*-------------------
		lsr.w	d2
		bcc	@f			転送ﾄﾞｯﾄ数は偶数
		move.w	(a2)+,(a0)+
@@
		*ﾛﾝｸﾞﾜｰﾄﾞ*2で転送した余り
		*-------------------
		lsr.w	d2
		bcc	@f			転送ﾄﾞｯﾄ数は４の倍数
		move.l	(a2)+,(a0)+
@@
		*ﾛﾝｸﾞﾜｰﾄﾞ*2で転送
		*-----------------
		subq.w	#1,d2
		bcs	1f
@@		move.l	(a2)+,(a0)+
		move.l	(a2)+,(a0)+
		dbra.w	d2,@b
1
	*左側取り込み
	*------------------------
		movea.l	a1,a2
		move.w	d0,d2
		beq	get_VRAM_adjust_X_end

		*ﾛﾝｸﾞﾜｰﾄﾞで転送した余り
		*-------------------
		lsr.w	d2
		bcc	@f			転送ﾄﾞｯﾄ数は偶数
		move.w	(a2)+,(a0)+
@@
		*ﾛﾝｸﾞﾜｰﾄﾞ*2で転送した余り
		*-------------------
		lsr.w	d2
		bcc	@f			転送ﾄﾞｯﾄ数は4の倍数
		move.l	(a2)+,(a0)+
@@
		*ﾛﾝｸﾞﾜｰﾄﾞ*2で転送
		*-----------------
		subq.w	#1,d2
		bcs	get_VRAM_adjust_X_end
@@		move.l	(a2)+,(a0)+
		move.l	(a2)+,(a0)+
		dbra.w	d2,@b
get_VRAM_adjust_X_end
		rts
******************************************************************************
*
*   square.s
*
******************************************************************************
Square
	moveq.l  #$16,d1
	move.l  #$E80029,a1
	iocs    _B_BPOKE

	moveq.l  #$0e,d1
	lea.l   $e80003-$e80029-1(a1),a1
	iocs    _B_BPOKE

	moveq.l  #$2c,d1
	addq.l   #$E80005-$e80003-1,a1
	iocs    _B_BPOKE

	moveq.l  #$6c,d1
	addq.l   #$E80007-$e80005-1,a1
	iocs    _B_BPOKE

	move.w   #$0089,d1
	subq.l   #$e80007+1-$E80000,a1
	iocs    _B_WPOKE
	rts

******************************************************************************
*	テキスト画面をクリアする
******************************************************************************
cls_text
		move.w	#2,-(sp)
		move.w	#10,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		rts
******************************************************************************
*
*  テンポラリファイルを閉じて削除する
*
******************************************************************************
	.xdef	close_temp
close_temp

	bclr.b	#2,Sys_flag(a6)
	beq	@f

	move.w	temp_handle(a6),-(sp)
	dos	_CLOSE

	pea.l	temp_path(a6)
	dos	_DELETE
	addq.l	#4+2,sp

@@
	rts


*
  .end

