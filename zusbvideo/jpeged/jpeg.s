*
*
*       JPEG.S
*
*
include   DOSCALL.MAC
include   JPEG.MAC
include   work.inc
*
	.xref   Save
	.xref   Load,DQT,running_size
	.xref   work_adrs
	.xref	Illegal_size_error
	.xref	Memory_error
	.xref	Switch_Error
*	.xref	no_sup_24_error
*
  .text
  .cpu 68000
*
start::
*�������m��
*--------------------------------------------
	*��۸���+����������؂��c���Č�͉��
	*-------------------------------
		lea.l	start(pc),a1
		sub.l	a0,a1
		move.l	a1,d1
	.if	0
		add.l	#4096+running_size-start-16,d1
	.else
		*	�O���Q�ƃV���{����p�����A�h���X���Z���ł��Ȃ��̂�
		*	���s���Ɍv�Z����
		add.l	#4096,d1
		lea.l	running_size(pc),a5
		add.l	a5,d1
		lea.l	start(pc),a5
		sub.l	a5,d1
		sub.l	#16,d1
	.endif

		move.l	8(a0),d0
		sub.l	a0,d0
		cmp.l	d0,d1
		bhi	Memory_error		��؂�����Ȃ�

		lea.l	(a0,d1.l),sp

		move.l	d1,-(sp)
		pea.l	16(a0)
		DOS	_SETBLOCK
		addq.l	#8,sp
		tst.l	d0
		bmi	Memory_error		��؂�����Ȃ�

	*�擾�o���邾����؂��擾
	*---------------------------------
		*�c����ػ��ނ��擾
		*-------------------------
		move.l	#-1,-(sp)
		DOS	_MALLOC
		addq.l	#4,sp
		rol.l	#8,d0
		cmp.b	#$81,d0
		bne	Memory_error		��؂�����Ȃ���ł��傤

		*�擾�o����ő����ػ��ނŎ擾
		*-------------------------
		lsr.l	#8,d0
		move.l	d0,d1
		move.l	d0,-(sp)
		DOS	_MALLOC
		addq.l	#4,sp
		tst.l	d0
		bmi	Memory_error		����H

		move.l	d0,a6
		lea.l	work_adrs(pc),a5
		move.l	d0,(a5)+		work start address set
		add.l	#COS_TBL+2048*2*6+COS1,d0
		move.l	d0,(a5)+		COS_TBL���ڽ
		lea.l	em_free_adrs(a6),a5	common work address

		move.l	a5,free_adrs(a6)
		move.l	d1,free_size(a6)

*���[�N������
*----------------------------------
		movea.l	a6,a5
		move.l	#clr_end,d5
		bsr	clear_area

		move.b  #3,uvmode(a6)
		move.l	#$00010001,Interval(a6)
		move.l	#$00010001,Interval+4(a6)
		move.w	#1,Qlevel(a6)
		lea.l	DQT+4(pc),a5
		move.l	a5,DQTadr(a6)
		move.l	#$c00000,VSadr(a6)
		move.w	#512,VSXsize(a6)
		move.w	#512,VSYsize(a6)
		move.w	#16,VScbit(a6)

		move.w	#-1,imsg_handle(a6)
*
		moveq.l	#1,d0
.cpu 68030
		move.b	(mpu_table-1,pc,d0.w*2),d0	MPU����
.cpu 68000
		move.b	d0,Sys_flag2(a6)
		bra	@f
mpu_table:	.dc.b	$04,$05
@@
		bset.b	#5,Sys_flag3(a6)

*�R�}���h���C�����
*------------------------------------
		addq.l	#1,a2
		bsr	Check_Parameter
		tst.b	fname(a6)
		beq	Switch_Error

		*�ʒu�w��ŁA�E���̍��W�w�肪�����ꍇ�́A�E���̍��W��������
		*------------------------------------

		btst.b	#6,Sys_flag2(a6)
		bne	main_pos_end

		move.w	VSXsize(a6),d0
		move.w	VSYsize(a6),d1
		subq.w	#1,d0
		subq.w	#1,d1
		move.w	d0,HE(a6)
		move.w	d1,VE(a6)

main_pos_end

		*�͈̓`�F�b�N(0,0)-(VSXsize,VSYsize)
		*---------------------------
		move.w	HE(a6),d1
		cmp.w	VSXsize(a6),d1
		bcc	Illegal_size_error
		cmp.w	HS(a6),d1
		bcs	Illegal_size_error
		move.w	VE(a6),d1
		cmp.w	VSYsize(a6),d1
		bcc	Illegal_size_error
		cmp.w	VS(a6),d1
		bcs	Illegal_size_error

*�e�����֕���
*--------------------------------------
*		cmp.b	#1,Action(a6)
*		beq	Save
		*cmp.w	#24,VScbit(a6)
		*beq	no_sup_24_error
		bra	Load

*  �R�}���h���C���E�p�����[�^�`�F�b�N
*-------------------------------------
Check_Parameter
CheckParam10
		move.b	(a2)+,d0
		beq	CheckParam99
		cmpi.b	#' ',d0
		bls	CheckParam10
		cmpi.b	#'-',d0
		beq	CheckParam20

		btst.b	#4,Sys_flag3(a6)
		bne	@f		'/'�͵�߼�݂Ƃ��Ďg�p�ł��Ȃ�

		cmpi.b	#'/',d0
		beq	CheckParam20
@@
	*̧�ٖ��擾
	*-------------------------------
		subq.l	#1,a2
		lea	fname(a6),a0
		bsr	CutFname
		bra	CheckParam10

	*   Option Check
	*----------------------------------
CheckParam20
		moveq.l	#0,d0
		move.b	(a2)+,d0
		cmp.b	#'A',d0
		bcs	@f
		cmp.b	#'Z',d0
		bhi	@f
		or.b	#$20,d0
@@
		lea.l	Option_tbl(pc),a1
@@
		move.w	(a1)+,d1
		beq	Switch_Error
		cmp.w	d0,d1
		beq	@f		��v
		addq.l	#2,a1
		bra	@b
@@
		move.w	(a1)+,d0
		jsr	CheckParam20(pc,d0.w)
		bra	CheckParam10

CheckParam99
		rts


		*�Z�[�u
		*------------------------
Option_S	tst.b	Action(a6)
		bne	Switch_Error
		move.b	#1,Action(a6)
		bsr	RangeRead
		rts
*
		*���[�h
		*------------------------
Option_L
		tst.b	Action(a6)
		bne	Switch_Error
		clr.b	Action(a6)
		bsr	RangeRead
		rts
*
		*�摜��̕\���ʒu
		*------------------------
Option_B
		bclr.b	#2,Sys_flag2(a6)	�\���J�n�ʒu�w��L��Ȃ̂Ž�۰قȂ�
		bsr	NUMCUT
		bcs	Switch_Error
		cmp.b	#',',(a2)+
		bne	Switch_Error
		move.w	d1,XS(a6)
		bsr	NUMCUT
		bcs	Switch_Error
		move.w	d1,YS(a6)
		rts

		*�摜�\���{��
		*-------------------------
Option_I
		bclr.b	#2,Sys_flag2(a6)	�{���w��L��Ȃ̂Ž�۰قȂ�
		bsr	NUMCUT
		bcs	Switch_Error
		move.w	d1,Interval+2(a6)
		move.w	d1,Interval+6(a6)
		move.b	(a2)+,d0
		cmp.b	#'/',d0
		bne	CheckParam36
		bsr	NUMCUT
		bcs	Switch_Error
		move.w	Interval+2(a6),d2
		move.w	d1,Interval+2(a6)
		move.w	d1,Interval+6(a6)
		move.w	d2,Interval(a6)
		move.w	d2,Interval+4(a6)
		move.b	(a2)+,d0
CheckParam36
		cmp.b	#',',d0
		bne	Option_I_dec
		bsr	NUMCUT
		bcs	Switch_Error
		move.w	d1,Interval+6(a6)
		cmp.b	#'/',(a2)+
		bne	Option_I_dec
		bsr	NUMCUT
		bcs	Switch_Error
		move.w	Interval+6(a6),d2
		move.w	d1,Interval+6(a6)
		move.w	d2,Interval+4(a6)
		rts
Option_I_dec
		subq.l	#1,a2
		rts
*
		*�ʎq�����x���̐ݒ�
		*-----------------------
Option_Q
		bsr	NUMCUT
		bcs	Option_Qtable
		move.w	d1,Qlevel(a6)
		rts
Option_Qtable
		****** �ʎq���e�[�u���̐ݒ�
		lea	Qname(a6),a0
		bsr	CutFname
		tst.b	d1
		beq	Switch_Error
		rts

		*���[�h�ݒ�
		*---------------------------
Option_M
		move.b	#1,colormode(a6)	*�ɸۉ摜�ł���
		move.b  #1,uvmode(a6)

		bsr	NUMCUT
		bcs	Switch_Error
		tst.w	d1
		beq	Option_M_end		*�ɸۉ摜�Ƃ��Ĉ���

		cmp.b	#3,d1
		bhi	Switch_Error
		clr.b	colormode(a6)		*�װ�摜�ł���
		move.b	d1,uvmode(a6)
Option_M_end
		rts

		*�w�b�_�[���
		*----------------------------
Option_H
		move.b	#2,Action(a6)
		rts

		*��ʏ������Ȃ�
		*-----------------------------
Option_N
		bset.b	#1,Sys_flag2(a6)
		rts

		*�R�����g
		*-----------------------------
Option_C
		move.b   (a2)+,d0
		beq      Switch_Error
		move.b   d0,Cflag(a6)
		lea      Comment(a6),a0
		cmpi.b   #'"',d0
		beq      CheckParam72
		subq.l   #1,a2
		bsr      CutFname
		tst.b    d1
		beq      Switch_Error
		rts
CheckParam72
			move.b   (a2)+,d0
			beq      Switch_Error
			bsr      SJIS
			bcs      CheckParam73
			move.b   d0,(a0)+
			move.b   (a2)+,d0
			beq      Switch_Error
			bra      CheckParam74
CheckParam73
			cmpi.b   #'"',d0
			beq      CheckParam76
			cmpi.b   #'\',d0
			bne      CheckParam74
			move.b   (a2)+,d0
			beq      Switch_Error
CheckParam74
		move.b   d0,(a0)+
		bra      CheckParam72
CheckParam76
		clr.b    (a0)
		rts


		*�A�X�y�N�g
		*---------------------
Option_A
		move.l   #$00010001,Aspect(a6)
		bsr      NUMCUT
		bcs      Option_A_end
		cmp.b    #',',(a2)+
		bne      Switch_Error
		move.w   d1,Aspect(a6)
		bsr      NUMCUT
		bcs      Switch_Error
		move.w   d1,Aspect+2(a6)
Option_A_end
		rts

		*�S��ʈ������΂�
		*----------------------
Option_F
		clr.b	DispMod(a6)
		bsr	NUMCUT
		bcs	Option_F_end
		cmp.w	#3,d1
		bhi	Switch_Error
		move.b	d1,DispMod(a6)
		beq	Option_F_end
		bclr.b	#2,Sys_flag2(a6)
Option_F_end
		rts

		*�L�[���͑҂�
		*-----------------------
Option_K
		bsr	NUMCUT
		bcc	@f
		moveq.l	#3,d1
@@
		cmp.w	#7,d1
		bhi	Switch_Error
		btst.l	#0,d1
		beq	@f
		bset.b	#0,Sys_flag(a6)
@@
		btst.l	#1,d1
		beq	@f
		bset.b	#7,Sys_flag2(a6)
@@
		btst.l	#2,d1
		beq	@f
		bset.b	#3,Sys_flag3(a6)
@@
		rts

		*�e���|�����ɓW�J����̂�����
		*------------------------------
Option_W
		bset.b	#1,Sys_flag(a6)
		lea	temp_path(a6),a0
		bsr	CutFname
		rts

		*���z��ʎw��
		*-------------------------------
Option_V
		move.b	(a2)+,d0
		ori.b	#$20,d0
		moveq.l	#16,d1
		cmpi.b	#'s',d0
		beq	CheckParamVS02
*		moveq.l	#24,d1
*		cmpi.b	#'f',d0
		bne	Switch_Error
CheckParamVS02
		move.w	d1,VScbit(a6)

		*���z��ʎw�肠��
		*-------------------------
		bclr.b	#2,Sys_flag2(a6)
		bset.b	#4,Sys_flag2(a6)
		bsr	NUMCUT
		bcs	Switch_Error
		cmp.b	#',',(a2)+
		bne	Switch_Error
		move.w  d1,VSXsize(a6)
		bsr	NUMCUT
		bcs	Switch_Error
		move.w	d1,VSYsize(a6)
		cmp.b	#',',(a2)+
		bne	Switch_Error

		cmp.b	#'$',(a2)
		bne	CheckParamVS05

			*��؏�̉��z��ʎw�肠��
			*----------------------
			addq.w	#1,a2
			bsr	HEXCUT
			bcs	Switch_Error
			move.l	d1,VSadr(a6)
			rts

			*̧�ُ�̉��z��ʎw�肠��
			*----------------------
CheckParamVS05
			bset.b	#5,Sys_flag2(a6)
			lea.l	VSname(a6),a0
			bsr	CutFname
			tst.b	d1
			beq	Switch_Error
			clr.l	VSadr(a6)
			rts

	*�摜�␳
	*-----------------------
Option_J
		bset.b	#5,Sys_flag(a6)
		bset.b	#5,Sys_flag3(a6)
		bsr	NUMCUT
		bcs	Option_J_end
		cmp.w	#3,d1
		bhi	Switch_Error
		*���߸ĕ␳
		*----------------------
		btst.l	#0,d1
		bne	@f
		bclr.b	#5,Sys_flag(a6)
@@
		*�I�����̉摜Home�ʒu�␳
		*----------------------
		btst.l	#1,d1
		bne	@f
		bclr.b	#5,Sys_flag3(a6)
@@
Option_J_end
		rts

		*�p�X�̋�؂�� "/"���g��Ȃ�
		*-----------------------------
Option_P
		bset.b	#4,Sys_flag3(a6)
		rts

		*�Q�p�X�ň��k
		*-----------------------------
Option_2
		move.w	#2-1,EncodePath(a6)
		rts
*
*  �t�@�C�����̃J�b�g
*
*  a2.l    Param Address
*  a0.l    Fname
*  d1.b:o  length(Fname)
*
CutFname
	moveq	#0,d1
cutf10
	move.b	(a2)+,d0
	beq	cutf20
	cmpi.b	#' ',d0
	bls	cutf20
	move.b	d0,(a0)+
	addq.b	#1,d1
	bra	cutf10
cutf20
	subq.l	#1,a2
	clr.b	(a0)
	rts
***********************************************
*
*	�����ײ݂��ʒu�w��ǂݍ���
*
*	����
*		a2.l.....Param Address
*	�o��
*		�ʒu�w��Ȃ��̏ꍇ
*			CY=1
*		�ʒu�w��L��̏ꍇ
*			CY=0
*			HS(a6)
*			HE(a6)
*			VS(a6)
*			VE(a6)
*	�j��	d0,d1
***********************************************
RangeRead
		bsr     NUMCUT
		bcs     rangeread80		�ʒu�w��Ȃ�

		bclr.b	#2,Sys_flag2(a6)	�ʒu�w��L��̏ꍇ�ͽ�۰قȂ�
		bset.b	#3,Sys_flag2(a6)	�ʒu�w��L��t���O�ݒ�
		cmp.b   #',',(a2)+
		bne     Switch_Error
		move.w  d1,HS(a6)
		bsr     NUMCUT
		bcs     Switch_Error
		move.w  d1,VS(a6)
		cmp.b   #',',(a2)
		bne     rangeread80
		addq.l	#1,a2

		bset.b	#6,Sys_flag2(a6)	�E���ʒu�w��L��t���O�ݒ�
		bsr     NUMCUT
		bcs     Switch_Error
		move.w  d1,HE(a6)
		cmp.b   #',',(a2)+
		bne     Switch_Error
		bsr     NUMCUT
		bcs     Switch_Error
		move.w  d1,VE(a6)
rangeread80
		rts
*
*
*  a2.l  Param Address
*  d0.b  �I�[����
*  d1.w  ����
*
*   �G���[���͂b�t���O�Z�b�g
*
NUMCUT
	moveq.l	#0,d0
	move.b	(a2)+,d0
	beq	numcut90
	bsr	chk_num
	bcs	numcut90
	moveq	#0,d1
	move.b	d0,d1
numcut10
	move.b	(a2)+,d0
	beq	numcut80
	bsr	chk_num
	bcs	numcut80
	mulu	#10,d1
	add.w	d0,d1
	bra	numcut10
numcut80
	subq.l	#1,a2
No_Carry_rts
	move.w	#0,ccr
	rts

numcut90
	subq.l	#1,a2
Carry_rts
	move.w	#1,ccr
	rts
*
*
*  a2.l  Param Address
*  d0.b  �I�[����
*  d1.w  ����
*
*   �G���[���͂b�t���O�Z�b�g
*
HEXCUT
  move.b  (a2)+,d0
  beq     numcut90
  bsr     chk_num
  bcc     hexcut05
  bsr     chk_hex
  bcs     numcut90

hexcut05
  moveq   #0,d1
  move.b  d0,d1
hexcut10
    move.b  (a2)+,d0
    bsr     chk_num
    bcc     hexcut20
    bsr     chk_hex
    bcs     numcut80
hexcut20
      lsl.l   #4,d1
      add.b   d0,d1
      bra     hexcut10


chk_num
  cmp.b   #'0',d0
  bcs     Carry_rts
  cmp.b   #'9',d0
  bhi     Carry_rts
  sub.b   #'0',d0
  bra     No_Carry_rts

chk_hex
  cmp.b   #'A',d0
  bcs     Carry_rts
  cmp.b   #'F',d0
  bls     chk_hex_upper
  cmp.b   #'a',d0
  bcs     Carry_rts
  cmp.b   #'f',d0
  bhi     Carry_rts
  sub.b   #'a'-'A',d0
chk_hex_upper
  sub.b   #'A'-10,d0
  bra     No_Carry_rts


******************************************************************************
*
*	�̈�N���A
*
*	����	d5.l	�N���A����o�C�g��
*		a5.l	�N���A����A�h���X
*
******************************************************************************
.xdef	clear_area
clear_area
	move.l	d5,-(sp)
	lsr.l	#2,d5
	bra	2f
1:
	clr.l	(a5)+
2:
	dbra	d5,1b
	sub.l	#$10000,d5
	bcc	1b

	moveq.l	#$03,d5
	and.l	(sp)+,d5
	bra	2f
1:
	clr.b	(a5)+
2:
	dbra	d5,1b
	rts
*
*
*
*  d0=�S�p Carry off
*
SJIS 
  cmpi.b #$80,d0
  bcs    sjis9
    cmpi.b  #$A0,d0
    bcs	   sjis5
      cmpi.b  #$E0,d0
      bra     sjis9
sjis5 
  eori #%0000_0001,ccr	* ccf
sjis9 
  rts
*
*

Option_tbl
		.dc.w	'a',Option_A-CheckParam20
		.dc.w	'b',Option_B-CheckParam20
		.dc.w	'c',Option_C-CheckParam20
		.dc.w	'f',Option_F-CheckParam20
		.dc.w	'h',Option_H-CheckParam20
		.dc.w	'i',Option_I-CheckParam20
		.dc.w	'j',Option_J-CheckParam20
		.dc.w	'k',Option_K-CheckParam20
		.dc.w	'l',Option_L-CheckParam20
		.dc.w	'm',Option_M-CheckParam20
		.dc.w	'n',Option_N-CheckParam20
		.dc.w	'p',Option_P-CheckParam20
		.dc.w	'q',Option_Q-CheckParam20
		.dc.w	's',Option_S-CheckParam20
		.dc.w	'v',Option_V-CheckParam20
		.dc.w	'w',Option_W-CheckParam20
		.dc.w	'2',Option_2-CheckParam20
		.dc.w	0

  .end	start
