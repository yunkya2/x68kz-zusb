*
*
*       SAVE.S
*
*
include  DOSCALL.MAC
include  JPEG.MAC
include	 work.inc
  .text
*
	.xref	Memory_error
	.xref	EOI,SOI,APP,COM,COM0,DQT,QtableL0,QtableC0,DHT,SOF,SOS,SOS_mono
	.xref	PutBlock,preENCODE,postENCODE
	.xref	make_DCT_table
	.xref	make_RGB_YUV_table
	.xref	make_ENCODE_table
	.xref	init_vwork
	.xref	getmem_1block_line
	.xref	getmem_file_buf
	.xref	OptHuffmanTable
	.xref	ClrRateTable

	.xref	Comment_not_found
	.xref	Qtable_not_found
	.xref	VS_not_found
	.xref	Read_error
	.xref	Write_error

	.xref	DHTDCL,DHTACL,DHTDCC,DHTACC

	.xref	clear_area
	.xref	PrintW
	.xref	PrintWI
	.xref	PrintHex
	.xref	PrintHex8
	.xref	DumpMem
	.xref	CRLF

VRAM   equ $C00000
*
	.xdef    Save
*
*
*
Save
	*圧縮用のﾜｰｸｴﾘｱ確保
	*----------------------------------
	move.l	free_adrs(a6),a2
	move.l	free_size(a6),d5
	move.l	#save_work_size,d1
	sub.l	d1,d5
	bcs	Memory_error
	adda.l	d1,a2
	move.l	a2,buff_adrs(a6)
	move.l	d5,buff_size(a6)

	*乗算ﾃｰﾌﾞﾙ作成
	*------------------------
	bsr	make_DCT_table
	bsr	make_RGB_YUV_table

	*画面関係のﾜｰｸｴﾘｱ初期化
	*------------------------
	move.w	HE(a6),d0
	sub.w	HS(a6),d0
	addq.w	#1,d0
	move.w	d0,Xline(a6)
	move.w  VE(a6),d0
	sub.w	VS(a6),d0
	addq.w	#1,d0
	move.w	d0,Yline(a6)
	bsr	init_vwork

	*画像取り込みﾊﾞｯﾌｧ確保
	*------------------------
	bsr	getmem_1block_line

	*画像保存バッファ確保（最大６４ＫＢ）
	*------------------------
	bsr	getmem_file_buf

	*画像保存
	*---------------------------
	bsr	ReadQtable
	bsr	SetQtable
	tst.w	EncodePath(a6)
	beq	@f			1ﾊﾟｽで圧縮
	bsr	ClrRateTable
	bsr	preENCODE
	bsr	PutImage
	bsr	OptHuffmanTable
	bsr	ClrRateTable
	clr.w	EncodePath(a6)
@@
	bsr	make_ENCODE_table
	bsr	Put_Header
	bsr	preENCODE
	bsr	PutImage
	bsr     postENCODE

	*画像終了ｺｰﾄﾞ書き込み
	*---------------------------
	move.l  #2,-(sp)
	pea.l	EOI(pc)
	move.w	Jhandle(a6),-(sp)
	dos	_WRITE
	tst.l	d0
	bmi	Write_error

	*ファイルを閉じる
	*---------------------------
	dos	_CLOSE
	lea.l	4+4(sp),sp

	clr.w	(sp)
	dos	_EXIT

***************************************
*
*	画像全体ｴﾝｺｰﾄﾞ
*
***************************************
PutImage
	*仮想画面ﾌｧｲﾙ指定の場合は、それをオープン
	*---------------------------
	btst.b	#5,Sys_flag2(a6)
	beq	@f

	clr.w	-(sp)
	pea.l	VSname(a6)
	dos	_OPEN
	addq.w	#4+2,sp
	tst.l	d0
	bmi	VS_not_found

	move.w	d0,VShandle(a6)
@@
	*スーパーバイザーモードに移行
	*-----------------------
	clr.l	-(sp)
	dos	_SUPER
	move.l	d0,(sp)

	*画像保存アドレス計算
	*-----------------------
	move.w	VS(a6),d0
	mulu.w	VSXsize(a6),d0
	add.l	d0,d0
	movea.l	VSadr(a6),a5
	adda.l	d0,a5
	move.w	HS(a6),d0
	add.w	d0,d0
	adda.w	d0,a5

  *画像保存開始
  *-----------------------
	move.w	VSXsize(a6),d5
	mulu.w	DeltaY(a6),d5
	add.l   d5,d5
	move.w	Yline(a6),d6
save20
	movem.l	d5-d6/a5,-(sp)
	bsr	PutBlock
	tst.w	d0
	bmi	Write_error
	movem.l	(sp)+,d5-d6/a5
	add.l	d5,a5
	sub.w	DeltaY(a6),d6
	bhi	save20

*ユーザーモードに移行
*-----------------------
	dos	_SUPER

	btst.b	#5,Sys_flag2(a6)
	beq	@f

	move.w	VShandle(a6),(sp)
	dos	_CLOSE
	tst.l	d0
	bmi	Read_error
@@
	addq.l	#4,sp
	rts
***************************************
*
*	ｺﾒﾝﾄ情報出力
*
***************************************
.xdef Put_Comment
Put_Comment
  tst.b   Cflag(a6)
  bne     putcom20
*
  moveq.l #0,d0
  move.w  COM+2(pc),d0
  addq.l  #2,d0
  move.l  d0,-(sp)
  pea     COM(pc)
  move.w  d5,-(sp)
  dos     _WRITE
  lea     10(sp),sp
  tst.l   d0
  bmi     Write_error
  rts
*
*
*  Count Comment
*
putcom20
  moveq   #0,d3
  cmp.b   #'"',Cflag(a6)
  bne     putcom40
*
  move.l  a0,-(sp)
  lea     Comment(a6),a0
  bsr     CountCOM
  move.l  (sp)+,a0
  pushl   d3
  addq.w  #2,d3
  move.w  d3,-(sp)
  move.w  COM(pc),-(sp)
*
  pushl   #4
  pea     4(sp)
  move.w  d5,-(sp)
  dos     _WRITE
  tst.l   d0
  bmi     Write_error
  lea     10+2+2(sp),sp
*
  popl    d3
  pushl   d3
  pea     Comment(a6)
  move.w  d5,-(sp)
  dos     _WRITE
  tst.l   d0
  bmi     Write_error
  lea     10(sp),sp
  rts
*
*  コメントファイルの出力
*
putcom40
  clr.w   -(sp)
  pea     Comment(a6)
  dos     _OPEN
  move.l  d0,d4
  bmi     Comment_not_found
  addq.l  #6,sp
putcom50
    pushw   d4
    dos     _FGETC
    addq.l  #2,sp
    tst.l   d0
    bmi     putcom60
    cmp.b   #$1A,d0
    beq     putcom60
      addq.w    #1,d3
      bra       putcom50
putcom60
    pushw   d4
    dos     _CLOSE
    addq.l  #2,sp
*
  addq.w  #2,d3
  move.w  d3,-(sp)
  move.w  COM(pc),-(sp)
  pushl   #4
  pea     4(sp)
  move.w  d5,-(sp)
  dos     _WRITE
  tst.l   d0
  bmi     Write_error
  lea     10+2+2(sp),sp
*
  clr.w   -(sp)
  pea     Comment(a6)
  dos     _OPEN
  move.l  d0,d4
  addq.l  #6,sp
*
putcom70
    pushw   d4
    dos     _FGETC
    addq.l  #2,sp
    tst.l   d0
    bmi     putcom80
    cmp.b   #$1A,d0
    beq     putcom80
      pushw   d5
      pushw   d0
      dos     _FPUTC
      addq.l  #4,sp
      tst.l   d0
      beq     Write_error
      bra     putcom70
putcom80
    pushw   d4
    dos     _CLOSE
    addq.l  #2,sp
  rts
*
*
CountCOM
  move.b  (a0)+,d0
  beq     countcom90
    addq.w  #1,d3
    bra     CountCOM
countcom90
  rts
*
PutCOM
  move.b  (a0)+,d0
  beq     putcom90
    pushw   d5
    pushw   d0
    dos     _FPUTC
    tst.l   d0
    beq     Write_error
    addq.l  #4,sp
    bra     PutCOM
putcom90
  rts
*
*
*
.xdef Put_Header
Put_Header
*
  lea.l   SOI(pc),a0

  move.w  #$20,-(sp)
  pea     fname(a6)
  dos     _CREATE
  addq.l  #6,sp
  move.w  d0,Jhandle(a6)
  bmi     Write_error
  move.w  d0,d5
*
  move.w  Aspect(a6),d0
  beq     puthead10
    move.w  d0,APP+12-SOI(a0)
    move.w  Aspect+2(a6),d0
    move.w  d0,APP+14-SOI(a0)
puthead10
  move.l  #20,-(sp)
  pea     SOI(pc)
  move.w  d5,-(sp)
  dos     _WRITE
  tst.l   d0
  bmi     Write_error
  lea     10(sp),sp
*
  bsr     Put_Comment
*
  move.w  Xline(a6),d0
  move.b  d0,SOF+8-SOI(a0)
  lsr.w   #8,d0
  move.b  d0,SOF+7-SOI(a0)
  move.w  Yline(a6),d0
  move.b  d0,SOF+6-SOI(a0)
  lsr.w   #8,d0
  move.b  d0,SOF+5-SOI(a0)
*
  move.b  #$11,d1
  move.b  uvmode(a6),d0
  subq.b  #1,d0
  beq     puthead200
  move.b  #$21,d1
  subq.b  #1,d0
  beq     puthead200
  move.b  #$22,d1
*
puthead200
  move.b  d1,SOF+11-SOI(a0)

	moveq.l	#3,d1
	tst.b	colormode(a6)
	beq	puthead300
	moveq.l	#1,d1
puthead300
	move.b	d1,SOF+9-SOI(a0)

*DQT書き込み
*----------------------
	move.l	#2+(1+64)*2,d1
	move.l	#2+(1+64)*1,d0
	lea.l   DQT(pc),a0
	bsr	PutHead_sub

*DHT書き込み
*----------------------
	moveq.l	#0,d1
	move.w	DHT+2(pc),d1
	lea.l   DHT(pc),a0
	bsr	puthead_sub10

*SOF書き込み
*----------------------
	move.l	#2+15,d1
	move.l	#2+9,d0
	lea.l   SOF(pc),a0
	bsr	PutHead_sub

*SOS書き込み
*----------------------
	lea.l   SOS(pc),a0
	move.l	#2+10+2,d1

	tst.b	colormode(a6)
	beq	puthead_SOS	*ｶﾗｰ画像である

	lea.l   SOS_mono(pc),a0
	move.l	#2+6+2,d1

puthead_SOS

	move.l	d1,-(sp)
	move.l	a0,-(sp)
	move.w	d5,-(sp)
	dos	_WRITE
	lea.l	10(sp),sp
	cmp.l	d0,d1
	bne	Write_error		*書き込みに失敗
	rts





PutHead_sub
	tst.b	colormode(a6)
	beq	puthead_sub10	*ｶﾗｰ画像である
	move.l	d0,d1
puthead_sub10

	ror.w	#8,d1
	move.b	d1,2(a0)
	ror.w	#8,d1
	move.b	d1,2+1(a0)
	addq.l	#2,d1
	move.l	d1,-(sp)
	move.l	a0,-(sp)
	move.w	d5,-(sp)
	dos	_WRITE
	lea.l	10(sp),sp
	cmp.l	d0,d1
	bne	Write_error		*書き込みに失敗
	rts
*
*
*  量子化テーブルの読込
*
ReadQtable
  tst.b   Qname(a6)
  beq     readq90
*
  clr.w   -(sp)
  pea     Qname(a6)
  dos     _OPEN
  move.w  d0,d5
  bmi     Qtable_not_found
  addq.l  #6,sp
  pushl   #64
  pea     DQT+5(pc)
  pushw   d5
  dos     _READ
  cmp.l   #64,d0
  bne     Qtable_not_found
  lea     10(sp),sp

	tst.b	colormode(a6)
	bnz	readq80			*ﾓﾉｸﾛ画像である

  pushl   #64
  pea     DQT+70(pc)
  pushw   d5
  dos     _READ
  cmp.l   #64,d0
  bne     Qtable_not_found
  lea     10(sp),sp
readq80
  pushw   d5
  dos     _CLOSE
  addq.l  #2,sp
readq90
  rts
*
*  量子化テーブルの設定
*
SetQtable

  *明度成分(Y)の量子化テーブル作成
  *------------------------
  move.w  Qlevel(a6),d1
  lea     DQT+5(pc),a0
  lea     QtableL(a6),a1
  move.w  #63,d2
ll50
    moveq   #0,d0
    move.b  (a0),d0
    divu    d1,d0
    bne     ll55
      moveq   #1,d0
ll55
    move.b  d0,(a0)+
    move.w  d0,(a1)+
    dbra    d2,ll50
*
  lea     DQT+70(pc),a0

  *量子化テーブルが２個用意されているか？
  *１個だけ用意されている場合は、色相成分(UV)も明度成分(Y)と同じ量子化テーブルを利用する。
  *全く用意されていない場合は、デフォルトの量子化テーブルを利用する
  *（尚、SAVE動作の場合は、デフォルトを選ぶようにDQTadr(a6)の値がDQT+4になっている)
  *---------------------------
  lea     DQT+4+1+64(pc),a1
  cmp.l   DQTadr(a6),a1
  bne     ll56
  lea     DQT+5(pc),a0
ll56

  *色相成分(UV)の量子化テーブル作成
  *------------------------
  lea     QtableC(a6),a1
  move.w  #63,d2
ll60
    moveq   #0,d0
    move.b  (a0),d0
    divu    d1,d0
    bne     ll65
      moveq   #1,d0
ll65
    move.b  d0,(a0)+
    move.w  d0,(a1)+
    dbra    d2,ll60
  rts


.end
