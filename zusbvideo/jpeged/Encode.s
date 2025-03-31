*
*
*  ENCODE.S
*
*  �n�t�}��������
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
*	DC�����ݺ��ޏ���ϸ�
*
*		�W�O�U�O�X�L����
*		�ʎq��
*		�O��̂c�b�l�Ƃ̍������
*	
******************************************************************************
ENCODE_DC	macro

*�W�O�U�O�X�L�����Ɨʎq��
*-----------------------
	move.w	(a5)+,d4	*Qtable�l�ǂݍ���
	move.w  d4,d3
	lsr.w	#1,d3
	move.w	(a0),d0	*�ʎq���O�̂c�b�l
	bmi	1f
	add.w	d3,d0	*���Ȃ珤��+0.5
	moveq.l	#0,d3
1:
	sub.w	d3,d0	*���Ȃ珤��-0.5
	ext.l	d0
	divs	d4,d0		* d0.w = ����̂c�b
 *�O��̂c�b�l�Ƃ̍������
 *------------------------
	move.w	(a1),d1  * �O��̂c�b
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
*	AC�����ݺ��ޏ���ϸ�
*
*		�W�O�U�O�X�L����
*		�ʎq��
*		�O�̌�����
*		EOB,ZRL����
******************************************************************************
ENCODE_AC	macro	SubAC,SubACZRL,SubACEOB
		local	ac10,ac20,ac50,ac90

	lea.l	ACLtable-DCLtable(a2),a2
	lea.l	ZigzagL(pc),a1
	moveq.l	#63-1,d2
ac10
	move.w	d2,d1  * RUN
ac20
*�W�O�U�O�X�L�����Ɨʎq��
*-----------------------
	move.w	(a5)+,d4		*Qtable�l�ǂݍ���
 	move.w	d4,d3
	lsr.w	#1,d3
	adda.w	(a1)+,a0		*Zigzagð��ٓǂݍ���
	move.w	(a0),d0
	*�����_�ȉ��l�̌ܓ�
	*---------------
	bmi	@f
	add.w	d3,d0
	moveq.l	#0,d3
@@
	sub.w	d3,d0

	ext.l	d0
	divs.w	d4,d0

	*�O�̌��J�E���g
	*-----------------------
	bne	ac50
	dbra	d2,ac20
	bsr	SubACEOB * EOB
	bra	ac90

	*�O�ȊO�̂`�b�l���o�Ă���
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
*�@�n�t�}�������œK���̂��߁A�e�l�̏o���䗦�v��
*
*	a0.l	�f�[�^�̈�
*	a1.l	�O��̂c�b�̈�i�g�p��́AZigzagð��كA�h���X)
*	a2.l	�c�b�R�[�h�\
*	a5.l	Qtable�A�h���X
.xdef ENCODE1
ENCODE1
	ENCODE_DC
	add.w	d2,d2
	addq.l	#1,(a2,d2.w)	 *�e�ޯĒ��̏o���������Z
	ENCODE_AC countAC,countACZRL,countACEOB
	moveq.l	#0,d0
	rts

******** ZRL
countACZRL
	addq.l	#1,15*16*8(a2)	 *�e�ޯĒ��̏o���������Z
	rts
******** EOB
countACEOB
	addq.l	#1,(a2)	 *�e�ޯĒ��̏o���������Z
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
*  �n�t�}�������o��
*
*
*	a0.l	�f�[�^�̈�
*	a1.l	�O��̂c�b�̈�i�g�p��́AZigzagð��كA�h���X)
*	a2.l	�c�b�R�[�h�\
*	a4.l	�o�b�t�@�[�A�h���X
*	a5.l	Qtable�A�h���X
*
*	d7.w	ndata	�o�b�t�@�[���f�[�^��
*	d6.w	rlen	�c��r�b�g��
*	d5.l	��ʃ��[�h rdata
*			�c��f�[�^
*
*
.xdef ENCODE
ENCODE
	tst.w	EncodePath(a6)
	bnz	ENCODE1

*���������ޯ̧����ڼ޽����A
*------------------------
	move.w	LastBufSize(a6),d7
	move.w	rlen(a6),d6
	move.w	rdata(a6),d5
	swap	d5
	move.l	bufadr(a6),a4
*  �c�b�����̏o��
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

*  �`�b�����̏o��
*------------------------
	ENCODE_AC PutAC,PutACZRL,PutACEOB

*���������ޯ̧����ڼ޽��ۑ�
*------------------------
	move.l	a4,bufadr(a6)
	swap	d5
	move.w	d5,rdata(a6)
	move.w	d6,rlen(a6)
	move.w	d7,LastBufSize(a6)
	move.l	errflg(a6),d0 
	rts
*
*  �`�b�o�͕⏕�o��
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
*  �R�[�h�o��
*    d5.w    code(w)
*    d4.w    lengh(w)
*
PutC
	cmp.w	d4,d6
	bls	putc50

	***** �o�͂Ȃ�
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
*  d5.l:l ���̓f�[�^�B��ʃ��[�h�o��
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