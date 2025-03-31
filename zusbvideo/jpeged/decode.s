*
*
*  DECODE.S
*
*  �n�t�}��������
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
*GetC��ײݓW�J Start
	dbra	d7,inGetC1	#10
         bsr     GetBuf		#20
inGetC1
	move.b	(a5)+,d5	#8
	moveq.l	#8,d6		#4
*GetC��ײݓW�J end
	endm

******************************************************************************
*
*  �n�t�}���������́i�c�b�����j���t�ʎq�����t�W�O�U�O
*
*   a0.l  �f�[�^�̈�
*   a1.l  �c�b�n�t�}���؃e�[�u���i�W�r�b�g���j
*   a2.l  �O��̂c�b�̈�
*   a4.l  �t�ʎq��ð���
*   a5.l  �o�b�t�@�[�A�h���X
*
*   d7.w	LastFFxxSize
*   d6.w	rlen	�c��r�b�g��
*   d5.l	buffer
******************************************************************************
.xdef	DecodeDCAC
DecodeDCAC

*���ݕ�����DC�l��8bit����C�Ƀf�R�[�h
*------------------------
		move.w	d5,d3
		clr.b	d3
		lsr.w	#8-3-2,d3
		move.l	(a1,d3.w),d2

	*�޺��ނ����ޯĕ������̂Ă�
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
		bpl	dc_lower_8bit	�޺��ނ�8bit�ȉ��ł���

*�c������ݕ������޺���
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
		bnz	dc40		#10,14	DC�l�ǂݍ��݂�

	*DC�l��0�ł���
	*-------------------------------
		move.w	(a2),d0
		bmi	dc90
		move.l	(a4)+,a2
		move.w	(a2,d0.w),(a0)
		bra	DECODE_AC

	*DC�l���ꏏ���޺��ނ������H
	*---------------------------------
dc_lower_8bit
		move.w	4(a1,d3.w),d0
		bne	dc75		����

*DC�l���޺���
*--------------------------------
		move.w	6(a1,d3.w),d2
	*DC�l�ǂݍ���
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

	  *DC�l�̍��������̏ꍇ
	  *-------------------
		move.l	(a4)+,a2
		move.w	(a2,d0.w),(a0)
		bra	DECODE_AC
dc90
	*DC�l�̍��������̏ꍇ
	*-------------------
		move.l	(a4)+,a2
		move.w	-2(a2,d0.w),(a0)
******************************************************************************
*
*  �n�t�}���������́i�`�b�����j���t�ʎq�����t�W�O�U�O
*
*   a0.l  �f�[�^�̈�
*   a1.l  �`�b�n�t�}���؃e�[�u���i�W�r�b�g���j
*   a4.l  �t�ʎq��ð���
*   a5.l  �o�b�t�@�[�A�h���X
*   a3.l  �W�O�U�O�e�[�u��
*
*   d7.w  ndata  �o�b�t�@�[���f�[�^��
*   d6.w  rlen   �c��r�b�g��
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

*���ݕ�����AC�l��8bit����C�Ƀf�R�[�h
*------------------------
ac10
		move.w	d5,d3		#4
		clr.b	d3		#4
		lsr.w   #8-3-2,d3	#10
		lea.l	8(a1,d3.w),a2	#12
		move.l	(a2)+,d2	#12

	*�޺��ނ����ޯĕ������̂Ă�
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
		bmi	ac_normal	8bit�޺��ނ��ᑫ��Ȃ�

	*AC�l���ꏏ���޺��ނ������H
	*---------------------------------
		move.w	(a2)+,d0
		bnz	ac_decoded	����
		move.w	(a2),d3		#8	d3=AC�l���ޯĐ�

*AC�l���޺���
*--------------------------------
ACValueRead
	*AC�l�ǂݍ���
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

	*AC�l��������
	*-----------------------
		move.l	d5,d0
		swap.w	d0
		add.w	d0,d0
ac_decoded

	*0�̌�������0����������
	*------------------------------
		add.w	d2,d2		d2.w=�O�̌�*2
		beq	ac17		#10

		sub.b	d2,d4
		bls	ac_EOB		�O�̌����c��̂`�b�̈�𒴂���
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
*EOB�ł���
*-----------------------
ac_EOB
		add.b	d2,d4		d4.w = 0�̌�
ac_EOB2
		rts


*�c������ݕ������޺���
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
		bze	ac_EOB2		EOB�ł���

		moveq.l	#$000f,d3			#4
		and.w	d2,d3		AC		#4
		lsr.b	#4,d2		Run		#16
		bra	ACValueRead

******************************************************************************
*
*	�t�@�C���ǂݍ���($FFxx�̏����������ōs��)
*
*	����	a5.l	�ǂݍ��ݱ��ڽ
*		d1.w	0)$FF��ǂݍ��� -1)�ǂݍ���ł��Ȃ�
*		d7.l	high)�ޯ̧�c���޲Đ�
*	�o��	d7.l	high)�ޯ̧�c���޲Đ�
*			low)����$FF�܂ŁA���́A�ޯ̧�Ō�܂ł��޲Đ�
*		d1.w	0)$FF��ǂݍ��� -1)�ǂݍ���ł��Ȃ�
*		a5.l	�ǂݍ��ݱ��ڽ
*	�j��	d0.l,d6.l
******************************************************************************
.xdef GetBuf
GetBuf
*�c����ޯ̧�޲Đ��擾
*-----------------------
	swap.w	d7			#4
*�ЂƂO���޲Ă�$FF�̏ꍇ�A�����޲Ă�$00,$FF,$Dx����������
*-----------------------
	
	tst.w	d1			#4
	bnz	GetBufSearchFF	�ЂƂO���޲Ă�$FF�ł͂Ȃ�	#10
1:
	dbra.w	d7,2f			#10
	bsr	GetBufAllSub
2:
	move.b	(a5)+,d0		#8
	beq	GetBufSearchFF	$00�̏ꍇ($FF00)	#10
	cmp.b	#$d0,d0					#8
	bcs	GetBufFFxxErr	$D0�ȉ��̺��ނʹװ	#10
	cmp.b	#$df,d0					#8
	bls.b	GetBufFFDx	$Dx�̏ꍇ		#10
	cmp.b	#$ff,d0
	beq	1b		$FF�̏ꍇ
	bra	GetBufFFxxErr	�װ

GetBufFFDx
		*$FFDx�̏ꍇ�A�ǂݍ��ݓr�����ޯĂ�j������
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
		bne	GetBufSearchFF	�����޲Ď�荞��
GetBufFFDxChkFFxx
		dbra	d7,@f
		bsr	GetBufAllSub
@@
		move.b	(a5)+,d0
		beq	GetBufSearchFF	�����޲Ď�荞��
		cmp.b	#$ff,d0
		beq	GetBufFFDxChkFFxx	$FFFF�Ȃ疳��
		and.b	#$f0,d0
		cmp.b	#$d0,d0
		beq	GetBufFFDxLoop		�܂�$FFDx������
GetBufFFxxErr
		subq.l	#1,a5
		addq.w	#1,d7
*$FF����
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
	ext.w	d1		#4	d1=$0000)������ -1)��������
	sub.w	d1,d7		#4	�������� d7=d7+1
	swap.w	d7		#4
	move.w	a5,d7		#4
	move.l	d6,a5		#4
	sub.w	d6,d7		#4
	subq.w	#1,d7		#4
	rts			#16

**************
*	����	�Ȃ�
*	�o��	d7	�ǂݍ����޲Đ�
*		a5	�ǂݍ��݊J�n���ڽ
*	�j��	d0.l
**************
GetBufAllSub
	move.l	buf_size(a6),-(sp)
	movea.l	buf_adrs(a6),a5
	move.l	a5,-(sp)
	move.w	Jhandle(a6),-(sp)
	DOS	_READ
	lea.l	10(sp),sp
	move.l  d0,d7
	bmi	IllegalJPEG	�ǂݍ��߂Ȃ�
	bnz	@f

	*����ȏ�̧�قȂ��Ȃ̂ŁADummy Data�ݒ�
	*---------------------
	tst.l	errflg(a6)
	bnz	IllegalJPEG	�ǂݍ��߂Ȃ�
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
*	����	����
*	�o��	d1	FFxxFlag(a6)�ݒ�l
*		d5	rdata(a6)�ݒ�l
*		d6	rlen(a6)�ݒ�l
*		d7	LastBufSize(a6),LastFFxxSize(a6)�ݒ�l
*		a5	NextFFxxAdrs(a6)�ݒ�l
*	�j��	d0.l
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