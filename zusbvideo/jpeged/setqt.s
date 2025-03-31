*
*
*       setqt.s
*       (セーブ以外にも使われるためsave.sから分離)
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