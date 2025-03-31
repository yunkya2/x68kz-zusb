*
*
*       setqt.s
*       (�Z�[�u�ȊO�ɂ��g���邽��save.s���番��)
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
*  �ʎq���e�[�u���̐ݒ�
*
SetQtable

  *���x����(Y)�̗ʎq���e�[�u���쐬
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

  *�ʎq���e�[�u�����Q�p�ӂ���Ă��邩�H
  *�P�����p�ӂ���Ă���ꍇ�́A�F������(UV)�����x����(Y)�Ɠ����ʎq���e�[�u���𗘗p����B
  *�S���p�ӂ���Ă��Ȃ��ꍇ�́A�f�t�H���g�̗ʎq���e�[�u���𗘗p����
  *�i���ASAVE����̏ꍇ�́A�f�t�H���g��I�Ԃ悤��DQTadr(a6)�̒l��DQT+4�ɂȂ��Ă���)
  *---------------------------
  lea     DQT+4+1+64(pc),a1
  cmp.l   DQTadr(a6),a1
  bne     ll56
  lea     DQT+5(pc),a0
ll56

  *�F������(UV)�̗ʎq���e�[�u���쐬
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