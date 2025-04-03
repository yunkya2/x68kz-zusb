*
*
*       GETHEAD.S
*
*
*
include  DOSCALL.MAC
include  JPEG.MAC
include  work.inc

	.xref	DHTDCL,DHT
	.xref	clear_area

  .text
************************************
*
*	ﾊﾌﾏﾝﾃｰﾌﾞﾙのｺｰﾄﾞ数取得
*
*	入力
*		a1	ﾊﾌﾏﾝﾃｰﾌﾞﾙｱﾄﾞﾚｽ
*	出力	
*		d4.l	ｺｰﾄﾞ数
*	破壊
*		d0,d6
************************************
.xdef CountCodeNumber
CountCodeNumber

	moveq.l	#0,d4
	moveq.l	#0,d0
	moveq.l	#16-1,d6

@@	move.b	(a1)+,d0
	add.w	d0,d4
	dbra	d6,@b

	lea.l	-16(a1),a1
	rts
***********************************************
*       MAKETREE
*
*	入力
*		d0.w	各DECODE_TBLを起点としたｵﾌｾｯﾄ/4
*		d4.w	葉の数
*		a0.l	Tree
*		a1.l	Counter
*		a2.l	ID
*		a3.l	各DECODE_TBLｱﾄﾞﾚｽ
*	出力
*		a2.l	次のDHTｱﾄﾞﾚｽ
*	破壊	d0-d4/d6-d7/a0-a1/a3
***********************************************
.xdef	MakeTree
MakeTree
	move.l	d5,-(sp)

	swap.w	d0
	move.w	#$8008,d0
	move.l	#$ffff_ffff,(a0)+	ｴﾗｰ判定用ｺｰﾄﾞ

*8ﾋﾞｯﾄ一度にﾃﾞｺｰﾄﾞﾃｰﾌﾞﾙ作成
*------------------------------
	moveq.l	#1,d6		現在のﾃﾞｺｰﾄﾞﾋﾞｯﾄ数
	moveq.l	#1,d3
	move.w	#256,d7
Mk8bitDecodeTbl
	move.l	d0,-(sp)

	lsr.w	d7
	add.w	d3,d3
	moveq.l	#0,d5
	move.b	(a1)+,d5
	sub.w	d5,d4

	*葉の部分作成
	*--------------------
	sub.w	d5,d3
	bcc	Mk8bitDecodeTblNextCode
	add.w	d5,d4
	sub.w	d3,d4
	add.w	d3,d5
	moveq.l	#0,d3
	bra	Mk8bitDecodeTblNextCode

Mk8bitDecodeTblSetCode

	movem.w	d6-d7,-(sp)

		moveq.l	#0,d0
		move.b	(a2)+,d0

		moveq.l	#$0f,d2
		and.b	d0,d2
		lsr.b	#4,d0

		swap.w	d0
		move.b	d2,d0
		add.b	d6,d0
		cmp.b	#8,d0
		bls	Mk8bitDecodeTblACDC

	*　[ﾊﾌﾏﾝ符号]だけが収まった場合
	*
	*	offset + 0.b	$00
	*		 1.b	0の個数
	*		 2.b	$00
	*		 3.b	復号ﾃｰﾌﾞﾙで解析出来たﾋﾞｯﾄ数
	*		 4.w	$0000([AC/DC値]は収まらなかった符号)
	*		 6.w	AC/DC値のﾋﾞｯﾄ数
	*-----------------------------------------------
		move.b	d6,d0
		moveq.l	#0,d1
		move.b	d2,d1
		bra	Mk8bitDecodeTblNoDCAC

	*　[ﾊﾌﾏﾝ符号]と[AC/DC値]が収まった場合
	*	offset + 0.b	$00
	*		 1.b	0の個数	(EOBの場合 64)
	*		 2.b	$00
	*		 3.b	復号ﾃｰﾌﾞﾙで解析出来たﾋﾞｯﾄ数
	*		 4.w	AC/DC値(0以下の値はさらに-2する)
	*		 6.w	Reserved
	*-----------------------------------------------
Mk8bitDecodeTblACDC
		move.l	#$fffe_0000,d1
		lsl.l	d2,d1

		tst.b	d2
		bnz	Mk8bitDecodeTblSet

		*AC/DCﾋﾞｯﾄ数が0で、0の個数が0ならば、EOBである
		*----------------------------
		swap.w	d0
		tst.b	d0
		bnz	@f	0の個数が0ではない
		move.w	#64,d0
@@		swap.w	d0

Mk8bitDecodeTblNoDCAC
		move.w	d7,d6
		bra	Mk8bitDecodeTblSet2

	*ﾃﾞｺｰﾄﾞﾃｰﾌﾞﾙ書き込み
	*----------------------------
Mk8bitDecodeTblSet
		lsr.w	d7
		move.w	d7,d6
		subq.w	#1,d2
		lsr.w	d2,d6

		move.w	d7,-(sp)
		bsr	Mk8bitDecodeTblSetSub
		move.w	(sp)+,d7
		swap.w	d1
		neg.w	d1
		swap.w	d1
Mk8bitDecodeTblSet2
		bsr	Mk8bitDecodeTblSetSub

	movem.w	(sp)+,d6-d7

Mk8bitDecodeTblNextCode

	dbra	d5,Mk8bitDecodeTblSetCode

*枝の部分の処理
*-------------------
		move.l	(sp)+,d0

	*葉が無いのに枝が残っている場合は、ｴﾗｰ判定用ｺｰﾄﾞを設定し終了
	*--------------------
		tst.w	d4
		bnz	Mk8bitDecodeTbl葉有	葉はまだある

		*　ﾊﾌﾏﾝ復号ｴﾗｰ
		*
		*	offset + 0.w	Tree上の位置
		*		 2.b	$80
		*		 3.b	復号ﾃｰﾌﾞﾙで解析出来たﾋﾞｯﾄ数(8固定)
		*		 4.w	Reserved
		*		 6.w	Reserved
		*------------------------------------------
		mulu.w	d3,d7
		bra	2f
1		move.l	d0,(a3)+
		clr.l	(a3)+
		lea.l	3*8(a3),a3
2		dbra.w	d7,1b
		bra	maketreeEnd

	*葉が残っているのに枝が無くなったら、終了
	*--------------------
Mk8bitDecodeTbl葉有
		tst.w	d3
		bze	maketreeEnd		枝無し

	*次のﾋﾞｯﾄﾁｪｯｸ
	*-------------------------
		addq.w	#1,d6
		cmp.w	#8,d6
		bls	Mk8bitDecodeTbl		まだ8bit分のﾃﾞｺｰﾄﾞﾃｰﾌﾞﾙを作成していない

	*　8bitを超える[ﾊﾌﾏﾝ符号]の場合
	*
	*	offset + 0.w	Tree上の位置
	*		 2.b	$80
	*		 3.b	復号ﾃｰﾌﾞﾙで解析出来たﾋﾞｯﾄ数(8固定)
	*		 4.w	Reserved
	*		 6.w	Reserved
	*-----------------------------------	
		*枝が余らないかチェック
		*------------------------
		moveq.l	#0,d6
		move.w	d3,d1
		add.w	d1,d1
		cmp.w	d4,d1
		bls	@f		余らない

		move.w	d3,d6
		move.w	d4,d3
		addq.w	#1,d3
		lsr.w	d3
		sub.w	d3,d6
		move.l	d0,d1
@@
		*余らないであろう枝の行き先を設定する
		*-----------------------
		move.w	d3,d7
		swap.w	d0
		addq.w	#1,d0
		bra	2f
1		swap.w	d0
		move.l	d0,(a3)+
		clr.l	(a3)+
		swap.w	d0
		addq.w	#1,d0
		lea.l	3*8(a3),a3
2		dbra.w	d7,1b

		*余るのが確実な枝を行き止まりにする
		*-----------------------
		bra	2f
1		move.l	d1,(a3)+
		clr.l	(a3)+
		lea.l	3*8(a3),a3
2		dbra.w	d6,1b

*8ﾋﾞｯﾄを超えるﾊﾌﾏﾝ符号用ﾃｰﾌﾞﾙ作成
*------------------------------
		moveq.l	#16-8-1,d6	考えられる最大の残りﾋﾞｯﾄ数-1
		move.w	#$8000,d1	bit 15=1)葉の印
MakeOverTree
		add.w	d3,d3
		moveq.l	#0,d5
		move.b	(a1)+,d5
		sub.w	d5,d4

	*葉の部分作成
	*--------------------
		sub.w	d5,d3
		bcc	2f
		*枝の数より葉が多い場合、枝の数に合わせる
		*-----------------------
		add.w	d5,d4
		sub.w	d3,d4
		add.w	d3,d5		d5=枝の数 (d3=d3-d5+d5)
		moveq.l	#0,d3
		bra	2f
1		move.b	(a2)+,d1
		move.w	d1,(a0)+
2		dbra	d5,1b

	*枝の部分作成
	*-------------------
		*余りの枝の場合は、ｴﾗｰ判定用ｺｰﾄﾞを埋め込む
		*--------------------
		move.w	d3,d5
		bze	maketreeEnd	枝は無い

	*余りすぎの枝を刈る
	*-------------------
		tst.w	d4
		bnz	2f		まだ葉があるので余りではない

		*葉が無いので、残りの枝は全部余り
		*----------------
		moveq.l	#-1,d0
@@		move.w	d0,(a0)+
		dbra	d5,@b
		bra	maketreeEnd

1		move.w	d0,(a0)+
		addq.w	#1,d0
2		dbra	d5,1b

		dbra	d6,MakeOverTree

maketreeEnd
		add.w	d4,d4
		adda.w	d4,a2		次のﾊﾌﾏﾝ符号ﾃｰﾌﾞﾙ取得ｱﾄﾞﾚｽ計算
		move.l	(sp)+,d5
		rts

******************
*	入力	d0.l
*		d1.l
*		d6.w
*		d7.w
*		a3.l
*	出力	d1.l
*	破壊	d2.w
******************
Mk8bitDecodeTblSetSub
		move.w	d6,d2
		subq.w	#1,d2
@@		move.l	d0,(a3)+
		move.l	d1,(a3)+
		lea.l	3*8(a3),a3
		dbra.w	d2,@b
		swap.w	d1
		addq.w	#2,d1
		swap.w	d1
		sub.w	d6,d7
		bhi	Mk8bitDecodeTblSetSub
		rts
******************************************
*
*  ハフマン符号化テーブル作成
*
*	入力
*		なし
*	出力
*		なし
******************************************
.xdef	make_ENCODE_table
make_ENCODE_table

	lea.l	DHTDCL(pc),a0
	lea.l	DCLtable(a6),a1
	bsr	make_ENCODE_table_sub

	lea.l	ACLtable(a6),a1
	bsr	make_ENCODE_table_sub

	lea.l	DCCtable(a6),a1
	bsr	make_ENCODE_table_sub

	lea.l	ACCtable(a6),a1

make_ENCODE_table_sub

	addq.l	#1,a0		*それぞれのﾊﾌﾏﾝ符号ﾋﾞｯﾄ長毎の取り得る値の数
	lea.l	16(a0),a2	*それぞれのﾊﾌﾏﾝ符号に対応する値のﾃｰﾌﾞﾙ
	moveq.l	#$0000,d0	*ﾊﾌﾏﾝ符号
	moveq.l	#$0001,d1	*ﾊﾌﾏﾝ符号ﾋﾞｯﾄ長
	move.w	#$8000,d2	*ﾊﾌﾏﾝ符号加算値
1:
	move.b	(a0)+,d3
	beq	3f		*このﾋﾞｯﾄ長には値は存在しない
2:
	moveq.l	#0,d4
	move.b	(a2)+,d4
	lsl.w	#2,d4
	movem.w	d0-d1,(a1,d4.w)	
	add.w	d2,d0
	subq.b	#1,d3
	bnz	2b
3:
	lsr.w	#1,d2
	addq.w	#1,d1		*ﾋﾞｯﾄ長増加
	cmp.w	#16,d1
	bls	1b

	movea.l	a2,a0
	rts

***************************************
*
*	値の出現確率ﾃｰﾌﾞﾙ初期化
*
***************************************
.xdef ClrRateTable
ClrRateTable
		lea.l	RateTableStart(a6),a5
		move.l	#RateTableEnd-RateTableStart,d5
		bra	clear_area
***************************************
*
*	ﾊﾌﾏﾝ符号ﾃｰﾌﾞﾙ最適化
*
***************************************
.xdef OptHuffmanTable
OptHuffmanTable
		moveq.l	#2,d6		DHTｻｲｽﾞ
		lea.l	DHTDCL(pc),a2

		moveq.l	#$00,d0
		moveq.l	#16-4-1,d7
		lea.l	DCLtable(a6),a3
		bsr	OptHuffmanTableMake

		moveq.l	#$10,d0
		move.w	#16*16-4-1,d7
		lea.l	ACLtable(a6),a3
		bsr	OptHuffmanTableMake

		tst.b	colormode(a6)
		bne	OptHuffmanTableEnd	*ﾓﾉｸﾛ画像である
		
		moveq.l	#$01,d0
		moveq.l	#16-4-1,d7
		lea.l	DCCtable(a6),a3
		bsr	OptHuffmanTableMake

		moveq.l	#$11,d0
		move.w	#16*16-4-1,d7
		lea.l	ACCtable(a6),a3
		bsr	OptHuffmanTableMake

OptHuffmanTableEnd

		lea.l	DHT+2(pc),a1
		move.w	d6,(a1)
		rts
*******************************************************
*
*	ﾊﾌﾏﾝﾂﾘｰ作成
*
*******************************************************
.xdef OptHuffmanTableMake
OptHuffmanTableMake
*ﾊﾌﾏﾝﾂﾘｰ作成
*--------------------
		move.b	d0,(a2)+
		addq.w	#1,d6		DHTｻｲｽﾞ更新

		lea.l	HuffTree(a6),a0
		moveq.l	#16,d3		

MakeTreeLoop
	*一番目と二番目に小さい値のﾃｰﾌﾞﾙｱﾄﾞﾚｽ取得
	*-----------------------
		moveq.l	#-1,d0		最小値
		moveq.l	#-1,d1		２番目に小さい値
		lea.l	$0000.w,a4	最小値のﾃｰﾌﾞﾙｱﾄﾞﾚｽ
		movea.l	a4,a5		二番目に小さい値のﾃｰﾌﾞﾙｱﾄﾞﾚｽ

		*葉の部分検索
		*---------------------
		move.w	d7,d4
		movea.l	a3,a1
		bsr	OptHuffmanTableSub

		*枝になっている部分検索
		*---------------------
		lea.l	HuffTree(a6),a1
		move.l	a0,d4
		sub.l	a1,d4
		lsr.w	#3,d4
		beq	@f		枝はまだない
		subq.w	#1,d4
		bsr	OptHuffmanTableSub
@@
	*枝をﾃｰﾌﾞﾙに登録
	*--------------------
		*親へのﾎﾟｲﾝﾀ設定
		*--------------------
		clr.l	(a4)
		move.l	a0,4(a4)

		*葉の最小値のﾃｰﾌﾞﾙｲﾝﾃﾞｯｸｽ値をﾊﾌﾏﾝ符号ﾃｰﾌﾞﾙに設定
		*---------------------
		move.l	a4,d4
		lea.l	HuffTree(a6),a4
		cmp.l	a4,d4
		bcs	1f		葉である
		cmp.l	a0,d4
		bcs	2f		葉ではない
1:
		sub.l	a3,d4
		lsr.w	#3,d4
		move.b	d4,(a2,d3.w)
		addq.w	#1,d3
2:	
		tst.l	d1
		bmi	MakeTreeFormat	根に行き着いた

		clr.l	(a5)
		move.l	a0,4(a5)

		*葉の二番目に小さい値のﾃｰﾌﾞﾙｲﾝﾃﾞｯｸｽ値をﾊﾌﾏﾝ符号ﾃｰﾌﾞﾙに設定
		*---------------------
		move.l	a5,d4
		cmp.l	a4,d4
		bcs	1f		葉である
		cmp.l	a0,d4
		bcs	2f		葉ではない
1:
		sub.l	a3,d4
		lsr.w	#3,d4
		move.b	d4,(a2,d3.w)
		addq.w	#1,d3
2:	
		*合計の使用率を登録
		*-------------------
		add.l	d1,d0
		move.l	d0,(a0)
		addq.l	#8,a0
		bra	MakeTreeLoop
MakeTreeFormat

*ﾊﾌﾏﾝ符号ﾃｰﾌﾞﾙに設定した、ｲﾝﾃﾞｯｸｽ値順を小さい順から、大きい順に並び変える
*---------------------
		lea.l	16(a2),a4
		lea.l	(a2,d3.w),a5
		add.w	d3,d6		DHTｻｲｽﾞ更新

		move.l	a5,-(sp)	次のDHTｱﾄﾞﾚｽ保存

		sub.w	#16-1,d3
		lsr.w	#1,d3
		subq.w	#1,d3
@@
		move.b	(a4),d0
		move.b	-(a5),(a4)+
		move.b	d0,(a5)
		dbra	d3,@b

*各葉の符号ﾋﾞｯﾄ長を計算する
*--------------------------
	*各符号ﾋﾞｯﾄ長毎の値の数ｶｳﾝﾄﾜｰｸ初期化
	*----------------------
		lea.l	HuffCount(a6),a5
		move.l	#16*16-4,d5
		bsr	clear_area

	*符号ﾋﾞｯﾄ長計算
	*---------------------
		lea.l	HuffCount(a6),a5
		move.w	d7,d4
		movea.l	a3,a1
1:
		move.l	4(a1),d0
		beq	4f		葉は存在しない
		movea.l	d0,a4

		*根までたどる
		*-------------------
		moveq.l	#0,d1
		bra	3f
2:
		addq.l	#1,d1
		move.l	4(a4),a4
3:
		cmp.l	a4,a0
		bne	2b		まだ根じゃない

		addq.b	#1,-1(a5,d1.w)	ﾋﾞｯﾄ長毎の値の数ｶｳﾝﾄ

		*次のﾃｰﾌﾞﾙ
		*------------------
4:
		addq.l	#8,a1
		dbra	d4,1b

*符号ﾋﾞｯﾄ長を16bitに制限する
*--------------------------
		lea.l	HuffCount+16*16-4-1(a6),a1
		move.w	#16*16-4-16-1,d4
1:
		tst.b	(a1)
		beq	4f

		lea.l	-2(a1),a0
2:
		tst.b	(a0)
		beq	3f
		subq.b	#1,(a0)
		addq.b	#2,1(a0)
		addq.b	#1,-1(a1)
		subq.b	#2,(a1)
		bra	1b
3:
		subq.l	#1,a0
		bra	2b
4:
		subq.l	#1,a1
		dbra	d4,1b

*ﾊﾌﾏﾝ符号ﾃｰﾌﾞﾙに符号毎に割り当てた値を書き込む
*--------------------------
		moveq.l	#16-1,d4
		lea.l	HuffCount(a6),a1
@@
		move.b	(a1)+,(a2)+
		dbra.w	d4,@b

		movea.l	(sp)+,a2	次のDHTｱﾄﾞﾚｽ復帰
		rts
******************
*
*	入力	a1	各値の出現比率ﾃｰﾌﾞﾙ
*		d0	一番小さい値
*		d1	二番目に小さい値
*		a4	一番小さい値のﾃｰﾌﾞﾙｱﾄﾞﾚｽ
*		a5	二番目に小さい値のﾃｰﾌﾞﾙｱﾄﾞﾚｽ
*		d2	この値以下は、すでに他の葉と結合済み
*		d4	ﾃｰﾌﾞﾙ数-1
*	出力
*		d0	一番小さい値
*		d1	二番目に小さい値
*		a4	一番小さい値のﾃｰﾌﾞﾙｱﾄﾞﾚｽ
*		a5	二番目に小さい値のﾃｰﾌﾞﾙｱﾄﾞﾚｽ
*	破壊	a1,d4,d5
******************
OptHuffmanTableSub
1:
		move.l	(a1),d5
		beq	3f

		cmp.l	d5,d0
		bcs	2f

		move.l	d0,d1
		movea.l	a4,a5
		move.l	d5,d0
		movea.l	a1,a4
		bra	3f
2:
		cmp.l	d5,d1
		bcs	3f
		move.l	d5,d1
		movea.l	a1,a5
3:
		addq.l	#8,a1
		dbra.w	d4,1b
		rts

  .end
