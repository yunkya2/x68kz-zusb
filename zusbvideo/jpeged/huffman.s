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
*	����ð��ق̺��ސ��擾
*
*	����
*		a1	����ð��ٱ��ڽ
*	�o��	
*		d4.l	���ސ�
*	�j��
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
*	����
*		d0.w	�eDECODE_TBL���N�_�Ƃ����̾��/4
*		d4.w	�t�̐�
*		a0.l	Tree
*		a1.l	Counter
*		a2.l	ID
*		a3.l	�eDECODE_TBL���ڽ
*	�o��
*		a2.l	����DHT���ڽ
*	�j��	d0-d4/d6-d7/a0-a1/a3
***********************************************
.xdef	MakeTree
MakeTree
	move.l	d5,-(sp)

	swap.w	d0
	move.w	#$8008,d0
	move.l	#$ffff_ffff,(a0)+	�װ����p����

*8�ޯĈ�x���޺���ð��ٍ쐬
*------------------------------
	moveq.l	#1,d6		���݂��޺����ޯĐ�
	moveq.l	#1,d3
	move.w	#256,d7
Mk8bitDecodeTbl
	move.l	d0,-(sp)

	lsr.w	d7
	add.w	d3,d3
	moveq.l	#0,d5
	move.b	(a1)+,d5
	sub.w	d5,d4

	*�t�̕����쐬
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

	*�@[���ݕ���]���������܂����ꍇ
	*
	*	offset + 0.b	$00
	*		 1.b	0�̌�
	*		 2.b	$00
	*		 3.b	����ð��قŉ�͏o�����ޯĐ�
	*		 4.w	$0000([AC/DC�l]�͎��܂�Ȃ���������)
	*		 6.w	AC/DC�l���ޯĐ�
	*-----------------------------------------------
		move.b	d6,d0
		moveq.l	#0,d1
		move.b	d2,d1
		bra	Mk8bitDecodeTblNoDCAC

	*�@[���ݕ���]��[AC/DC�l]�����܂����ꍇ
	*	offset + 0.b	$00
	*		 1.b	0�̌�	(EOB�̏ꍇ 64)
	*		 2.b	$00
	*		 3.b	����ð��قŉ�͏o�����ޯĐ�
	*		 4.w	AC/DC�l(0�ȉ��̒l�͂����-2����)
	*		 6.w	Reserved
	*-----------------------------------------------
Mk8bitDecodeTblACDC
		move.l	#$fffe_0000,d1
		lsl.l	d2,d1

		tst.b	d2
		bnz	Mk8bitDecodeTblSet

		*AC/DC�ޯĐ���0�ŁA0�̌���0�Ȃ�΁AEOB�ł���
		*----------------------------
		swap.w	d0
		tst.b	d0
		bnz	@f	0�̌���0�ł͂Ȃ�
		move.w	#64,d0
@@		swap.w	d0

Mk8bitDecodeTblNoDCAC
		move.w	d7,d6
		bra	Mk8bitDecodeTblSet2

	*�޺���ð��ُ�������
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

*�}�̕����̏���
*-------------------
		move.l	(sp)+,d0

	*�t�������̂Ɏ}���c���Ă���ꍇ�́A�װ����p���ނ�ݒ肵�I��
	*--------------------
		tst.w	d4
		bnz	Mk8bitDecodeTbl�t�L	�t�͂܂�����

		*�@���ݕ����װ
		*
		*	offset + 0.w	Tree��̈ʒu
		*		 2.b	$80
		*		 3.b	����ð��قŉ�͏o�����ޯĐ�(8�Œ�)
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

	*�t���c���Ă���̂Ɏ}�������Ȃ�����A�I��
	*--------------------
Mk8bitDecodeTbl�t�L
		tst.w	d3
		bze	maketreeEnd		�}����

	*�����ޯ�����
	*-------------------------
		addq.w	#1,d6
		cmp.w	#8,d6
		bls	Mk8bitDecodeTbl		�܂�8bit�����޺���ð��ق��쐬���Ă��Ȃ�

	*�@8bit�𒴂���[���ݕ���]�̏ꍇ
	*
	*	offset + 0.w	Tree��̈ʒu
	*		 2.b	$80
	*		 3.b	����ð��قŉ�͏o�����ޯĐ�(8�Œ�)
	*		 4.w	Reserved
	*		 6.w	Reserved
	*-----------------------------------	
		*�}���]��Ȃ����`�F�b�N
		*------------------------
		moveq.l	#0,d6
		move.w	d3,d1
		add.w	d1,d1
		cmp.w	d4,d1
		bls	@f		�]��Ȃ�

		move.w	d3,d6
		move.w	d4,d3
		addq.w	#1,d3
		lsr.w	d3
		sub.w	d3,d6
		move.l	d0,d1
@@
		*�]��Ȃ��ł��낤�}�̍s�����ݒ肷��
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

		*�]��̂��m���Ȏ}���s���~�܂�ɂ���
		*-----------------------
		bra	2f
1		move.l	d1,(a3)+
		clr.l	(a3)+
		lea.l	3*8(a3),a3
2		dbra.w	d6,1b

*8�ޯĂ𒴂������ݕ����pð��ٍ쐬
*------------------------------
		moveq.l	#16-8-1,d6	�l������ő�̎c���ޯĐ�-1
		move.w	#$8000,d1	bit 15=1)�t�̈�
MakeOverTree
		add.w	d3,d3
		moveq.l	#0,d5
		move.b	(a1)+,d5
		sub.w	d5,d4

	*�t�̕����쐬
	*--------------------
		sub.w	d5,d3
		bcc	2f
		*�}�̐����t�������ꍇ�A�}�̐��ɍ��킹��
		*-----------------------
		add.w	d5,d4
		sub.w	d3,d4
		add.w	d3,d5		d5=�}�̐� (d3=d3-d5+d5)
		moveq.l	#0,d3
		bra	2f
1		move.b	(a2)+,d1
		move.w	d1,(a0)+
2		dbra	d5,1b

	*�}�̕����쐬
	*-------------------
		*�]��̎}�̏ꍇ�́A�װ����p���ނ𖄂ߍ���
		*--------------------
		move.w	d3,d5
		bze	maketreeEnd	�}�͖���

	*�]�肷���̎}������
	*-------------------
		tst.w	d4
		bnz	2f		�܂��t������̂ŗ]��ł͂Ȃ�

		*�t�������̂ŁA�c��̎}�͑S���]��
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
		adda.w	d4,a2		�������ݕ���ð��َ擾���ڽ�v�Z
		move.l	(sp)+,d5
		rts

******************
*	����	d0.l
*		d1.l
*		d6.w
*		d7.w
*		a3.l
*	�o��	d1.l
*	�j��	d2.w
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
*  �n�t�}���������e�[�u���쐬
*
*	����
*		�Ȃ�
*	�o��
*		�Ȃ�
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

	addq.l	#1,a0		*���ꂼ������ݕ����ޯĒ����̎�蓾��l�̐�
	lea.l	16(a0),a2	*���ꂼ������ݕ����ɑΉ�����l��ð���
	moveq.l	#$0000,d0	*���ݕ���
	moveq.l	#$0001,d1	*���ݕ����ޯĒ�
	move.w	#$8000,d2	*���ݕ������Z�l
1:
	move.b	(a0)+,d3
	beq	3f		*�����ޯĒ��ɂ͒l�͑��݂��Ȃ�
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
	addq.w	#1,d1		*�ޯĒ�����
	cmp.w	#16,d1
	bls	1b

	movea.l	a2,a0
	rts

***************************************
*
*	�l�̏o���m��ð��ُ�����
*
***************************************
.xdef ClrRateTable
ClrRateTable
		lea.l	RateTableStart(a6),a5
		move.l	#RateTableEnd-RateTableStart,d5
		bra	clear_area
***************************************
*
*	���ݕ���ð��ٍœK��
*
***************************************
.xdef OptHuffmanTable
OptHuffmanTable
		moveq.l	#2,d6		DHT����
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
		bne	OptHuffmanTableEnd	*�ɸۉ摜�ł���
		
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
*	�����ذ�쐬
*
*******************************************************
.xdef OptHuffmanTableMake
OptHuffmanTableMake
*�����ذ�쐬
*--------------------
		move.b	d0,(a2)+
		addq.w	#1,d6		DHT���ލX�V

		lea.l	HuffTree(a6),a0
		moveq.l	#16,d3		

MakeTreeLoop
	*��ԖڂƓ�Ԗڂɏ������l��ð��ٱ��ڽ�擾
	*-----------------------
		moveq.l	#-1,d0		�ŏ��l
		moveq.l	#-1,d1		�Q�Ԗڂɏ������l
		lea.l	$0000.w,a4	�ŏ��l��ð��ٱ��ڽ
		movea.l	a4,a5		��Ԗڂɏ������l��ð��ٱ��ڽ

		*�t�̕�������
		*---------------------
		move.w	d7,d4
		movea.l	a3,a1
		bsr	OptHuffmanTableSub

		*�}�ɂȂ��Ă��镔������
		*---------------------
		lea.l	HuffTree(a6),a1
		move.l	a0,d4
		sub.l	a1,d4
		lsr.w	#3,d4
		beq	@f		�}�͂܂��Ȃ�
		subq.w	#1,d4
		bsr	OptHuffmanTableSub
@@
	*�}��ð��قɓo�^
	*--------------------
		*�e�ւ��߲���ݒ�
		*--------------------
		clr.l	(a4)
		move.l	a0,4(a4)

		*�t�̍ŏ��l��ð��ٲ��ޯ���l�����ݕ���ð��قɐݒ�
		*---------------------
		move.l	a4,d4
		lea.l	HuffTree(a6),a4
		cmp.l	a4,d4
		bcs	1f		�t�ł���
		cmp.l	a0,d4
		bcs	2f		�t�ł͂Ȃ�
1:
		sub.l	a3,d4
		lsr.w	#3,d4
		move.b	d4,(a2,d3.w)
		addq.w	#1,d3
2:	
		tst.l	d1
		bmi	MakeTreeFormat	���ɍs��������

		clr.l	(a5)
		move.l	a0,4(a5)

		*�t�̓�Ԗڂɏ������l��ð��ٲ��ޯ���l�����ݕ���ð��قɐݒ�
		*---------------------
		move.l	a5,d4
		cmp.l	a4,d4
		bcs	1f		�t�ł���
		cmp.l	a0,d4
		bcs	2f		�t�ł͂Ȃ�
1:
		sub.l	a3,d4
		lsr.w	#3,d4
		move.b	d4,(a2,d3.w)
		addq.w	#1,d3
2:	
		*���v�̎g�p����o�^
		*-------------------
		add.l	d1,d0
		move.l	d0,(a0)
		addq.l	#8,a0
		bra	MakeTreeLoop
MakeTreeFormat

*���ݕ���ð��قɐݒ肵���A���ޯ���l����������������A�傫�����ɕ��ѕς���
*---------------------
		lea.l	16(a2),a4
		lea.l	(a2,d3.w),a5
		add.w	d3,d6		DHT���ލX�V

		move.l	a5,-(sp)	����DHT���ڽ�ۑ�

		sub.w	#16-1,d3
		lsr.w	#1,d3
		subq.w	#1,d3
@@
		move.b	(a4),d0
		move.b	-(a5),(a4)+
		move.b	d0,(a5)
		dbra	d3,@b

*�e�t�̕����ޯĒ����v�Z����
*--------------------------
	*�e�����ޯĒ����̒l�̐�����ܰ�������
	*----------------------
		lea.l	HuffCount(a6),a5
		move.l	#16*16-4,d5
		bsr	clear_area

	*�����ޯĒ��v�Z
	*---------------------
		lea.l	HuffCount(a6),a5
		move.w	d7,d4
		movea.l	a3,a1
1:
		move.l	4(a1),d0
		beq	4f		�t�͑��݂��Ȃ�
		movea.l	d0,a4

		*���܂ł��ǂ�
		*-------------------
		moveq.l	#0,d1
		bra	3f
2:
		addq.l	#1,d1
		move.l	4(a4),a4
3:
		cmp.l	a4,a0
		bne	2b		�܂�������Ȃ�

		addq.b	#1,-1(a5,d1.w)	�ޯĒ����̒l�̐�����

		*����ð���
		*------------------
4:
		addq.l	#8,a1
		dbra	d4,1b

*�����ޯĒ���16bit�ɐ�������
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

*���ݕ���ð��قɕ������Ɋ��蓖�Ă��l����������
*--------------------------
		moveq.l	#16-1,d4
		lea.l	HuffCount(a6),a1
@@
		move.b	(a1)+,(a2)+
		dbra.w	d4,@b

		movea.l	(sp)+,a2	����DHT���ڽ���A
		rts
******************
*
*	����	a1	�e�l�̏o���䗦ð���
*		d0	��ԏ������l
*		d1	��Ԗڂɏ������l
*		a4	��ԏ������l��ð��ٱ��ڽ
*		a5	��Ԗڂɏ������l��ð��ٱ��ڽ
*		d2	���̒l�ȉ��́A���łɑ��̗t�ƌ����ς�
*		d4	ð��ِ�-1
*	�o��
*		d0	��ԏ������l
*		d1	��Ԗڂɏ������l
*		a4	��ԏ������l��ð��ٱ��ڽ
*		a5	��Ԗڂɏ������l��ð��ٱ��ڽ
*	�j��	a1,d4,d5
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