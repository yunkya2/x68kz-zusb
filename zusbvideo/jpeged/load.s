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
*�w�b�_���
*----------------------------------
	bsr	Get_Header

	cmp.b	#2,Action(a6)
	beq	load_exit		-H��߼�ݎw��(�w�b�_�̂ݕ\��)

*�t�ʎq��ð��ٍ쐬
*---------------------
	move.w	#1,Qlevel(a6)
	bsr	SetQtable

*�W�J�p��ܰ��ر�m��
*----------------------------------
	move.l	free_adrs(a6),a2
	move.l	free_size(a6),d5
	move.l	#load_work_size-em_free_adrs,d1
	adda.l	d1,a2
	sub.l	d1,d5
	bcs	Memory_error

	*�W�J����ܰ��ر���ތv�Z
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

	*�t�ʎq����Zð��ٍ쐬����؊m��
	*---------------------
	bsr	make_UQ_table
	move.l	a2,buff_adrs(a6)
	move.l	d5,buff_size(a6)

*  �A�X�y�N�g�̕␳
*-----------------------
	btst.b	#5,Sys_flag(a6)
	bne	adjust_Aspect_end	�A�X�y�N�g�̎����␳�}����߼�ݎw��

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
	bset.b	#7,Sys_flag(a6)	*JPEG.X,JPGS.X�ō��ꂽ�摜��RGB�̍ő�l��252�ɂ����Ȃ�Ȃ�
				*�̂ł��̂��߂̕␳�p�t���O�i���Ď��ۂ͕␳���ĂȂ��j
adjust_Aspect_end

*��ʂ̊e��ܰ��ر��������
*------------------------
	bsr	init_vwork

*��۰ى\�ȵ�߼�݂��H
*--------------------
	btst.b	#2,Sys_flag2(a6)
	beq	load50	���Ƃ��A�X�N���[������I�v�V�����w��ł͂Ȃ�

	btst.b	#0,Sys_flag(a6)
	bne	@f		���҂��L��Ȃ̂Ž�۰ٗL��
	btst.b	#7,Sys_flag2(a6)
	beq	load50		���҂��Ȃ��ŁA��Ľ�۰ق��Ȃ��Ȃ̂ŁA��۰قȂ�
@@
*�W�J��X�N���[���\���o���邩�H
*----------------------
	move.l	picture_size(a6),d2
	add.l	#1024,d2		�t�@�C���ǂݍ��݃o�b�t�@�\��
	cmp.l	buff_size(a6),d2
	bcc	load20			�摜�S�̂��������ɓW�J�o���Ȃ�

	*�o����
	*----------------------------
	sub.l	#1024,d2
	move.l	d2,Scroll_size(a6)
	bra	load11

*�X�N���[���\���Ńe���|�����t�@�C���ɓW�J
*----------------------------------------
load20
	btst.b	#1,Sys_flag(a6)
	beq	load50			�����؂ɓW�J��߼�ݖ����Ȃ̂œW�J�㽸۰قȂ�

	*���P�u���b�N���C�����̃����������
	*---------------------------------
	bsr	getmem_1block_line

	*�e���|�����t�@�C���̃p�X���擾
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

	move.b	'.',(a0)		���ϐ�temp���ݒ肳��Ă��Ȃ��ꍇ��
	clr.b	1(a0)			�J�����g�f�B���N�g���Ƀe���|�����t�@�C�������

	*�������߽�Ƀt�@�C������ǉ�
	*------------------------------
load21
	tst.b	(a0)+
	bne	load21
	subq.w	#1,a0
	lea.l	temp_file(pc),a1
load22
	move.b	(a1)+,(a0)+
	bne	load22

	*�e���|�����t�@�C�����I�[�v��
	*----------------------------
	move.w	#$20,-(sp)
	pea.l	temp_path(a6)
	dos	_MAKETMP
	addq.w	#6,sp
	tst.l	d0
	bmi	load50			�I�[�v���o���Ȃ��̂œW�J��̃X�N���[���\���͂��Ȃ�

	move.w  d0,temp_handle(a6)
	bset.b  #2,Sys_flag(a6)		�e���|�����ɓW�J����t���O

*�X�N���[���ł̃Z���^�����O�\���̏���
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


*�摜�W�J��X�N���[�����Ȃ��ꍇ
*------------------------------
load50
	*���P�u���b�N���C�����̃����������
	*-------------------------------
	bsr	getmem_1block_line

	bclr.b	#2,Sys_flag2(a6)		�X�N���[�����Ȃ�

	*-f��߼�݂̏���
	*------------------------
	cmp.b	#1,DispMod(a6)
	bcs	load53				-f0�܂���-f��߼�݂Ȃ�
	bne	load51

	*�S��ʈ������΂�
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

	*�c�����ς����ɁA�o���邾���傫���\��
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
	beq	load51_X		-f3�I�v�V�������̓h�b�g��̕ύX�͂��Ȃ�

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
	beq	load51_X2		-f3�I�v�V�������̓h�b�g��̕ύX�͂��Ȃ�

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

*�������̕\���J�n�ƏI���ʒu���v�Z
*---------------------------------
	move.w	Xline(a6),d0
	sub.w	XS(a6),d0

	mulu	Interval(a6),d0
	divu	Interval+2(a6),d0	d0=��ʏ�ł̃h�b�g��

	btst.b	#3,Sys_flag2(a6)
	bne	load55		�ʒu�w�肠��

	move.w	VSXsize(a6),d1		�Z���^�����O����
	sub.w	d0,d1
	bcs	load55
	addq.w	#1,d1
	lsr.w	d1
	move.w	d1,HS(a6)

	*�������̕\���I���ʒu����ʓ��Ɏ��܂�悤�ɂ���
	*---------------------------------------------
load55

	add.w	HS(a6),d0
	subq.w	#1,d0
	move.w	HE(a6),d1		d1=��ʏ�ł̉������\���I���ʒu(�I�v�V�����w��ŕύX����)
	cmp.w	d0,d1
	bhi	load63
	move.w	d1,d0
load63
	move.w	d0,HE(a6)

*�c�����̕\���J�n�ƏI���ʒu���v�Z
*-----------------------------------
	move.w	Yline(a6),d0
	sub.w	YS(a6),d0
	mulu	Interval+4(a6),d0
	divu	Interval+6(a6),d0

	btst.b	#3,Sys_flag2(a6)
	bne	load64		�ʒu�w�肠��

	move.w	VSYsize(a6),d1	�Z���^�����O����
	sub.w	d0,d1
	bcs	load64
	addq.w	#1,d1
	lsr.w	d1
	move.w	d1,VS(a6)

	*�c�����̕\���I���ʒu����ʓ��Ɏ��܂�悤�ɂ���
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
*���z��ʃt�@�C���o�b�t�@�m��
*--------------------------------
	btst.b	#5,Sys_flag2(a6)
	beq	load_get_VSF_buf_end	��߼�݂͉��z��ʃt�@�C���w��ł͂Ȃ�

	bsr	getmem_1line
	move.w	#1,-(sp)
	pea.l	VSname(a6)
	dos	_OPEN
	addq.w	#4+2,sp
	tst.l	d0
	bpl	load_get_VSF_buf_ok	�t�@�C�������łɑ��݂��Ă���

	move.w	#$20,-(sp)
	pea.l	VSname(a6)
	dos	_CREATE
	addq.w	#4+2,sp
	tst.l	d0
	bmi	Write_error		�t�@�C�����쐬�o���Ȃ�

load_get_VSF_buf_ok

	move.w	d0,VShandle(a6)

load_get_VSF_buf_end

*�ǂݍ��݃o�b�t�@�̊m��
*--------------------------------
	bsr	getmem_file_buf

*�X�[�p�o�C�U�[���[�h�ֈȍ~
*--------------------------------
	clr.l	-(sp)
	dos	_SUPER
	move.l	d0,(sp)

	bsr	Get_vector

*�X�N���[�����[�h�ݒ�
*--------------------------------
	btst.b	#4,Sys_flag2(a6)
	bne	load83			���z��ʂɓW�J�Ȃ̂ŉ�ʏ������͂��Ȃ�

	btst.b	#1,Sys_flag2(a6)
	bne	load80			-n��߼�ݎw��L��i�ݒ肵�Ȃ��j

	*���݂̽�ذ�Ӱ�ޔ���
	*-----------------------------
	moveq.l	#-1,d1
	iocs	_CRTMOD
	cmp.w	#$0c,d0
	beq	Load76

	*�Ⴄ��ذ�Ӱ�ނ�����
	*-----------------------------
	move.w	#$0c,d1
	iocs	_CRTMOD
	iocs	_G_CLR_ON
	bra	load77

	*������ذ�Ӱ�ނ�����
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

	*�h�b�g�䂪�P�F�P�̏ꍇ�����`���[�h�ɂ���
	*-------------------------
load80
	cmp.b	#1,DispMod(a6)
	beq	load82		�S��ʂɈ������΂��̏ꍇ�͐����`���[�h�ɂ��Ȃ�

	move.w	Aspect(a6),d0
	cmp.w	Aspect+2(a6),d0
	bne	load82		�����`�ł͂Ȃ�
	bsr	Square
load82
	*�}�E�X�̏�����
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

	*�@�J�[�\��������
	*-------------------
	move.w	#18,-(sp)
	dos	_CONCTRL
	addq.w	#2,sp

*�W�J�\��
*---------------------------
load83
	move.l	sp,ErrorStackPoint(a6)
	bsr	GetBlock		�摜�W�J
	tst.l	d0
	bmi	load_end		�����I��

		move.b	#1,DecodeStatus(a6)
		bra	Load84

.xdef LoadForceContinue
LoadForceContinue			*�摜�Ɉُ킪�L���Ă��A�����I�����Ȃ��ꍇ�A
					*GetBlock�̒����炱���ɔ��ł���
		move.b	#-1,DecodeStatus(a6)
Load84
		clr.l	ErrorStackPoint(a6)

		*�摜���\���v��������ꍇ�͕\������i��ԍ��ڍX�V�̈�)
		*-------------------------
		btst.b	#0,Sys_flag3(a6)
		beq	@f
		bsr	Disp_Pic_Info	
@@

*���z��ʃt�@�C�������
*----------------------------
	btst.b	#5,Sys_flag2(a6)
	beq	close_VSfile_end

	*���z��ʃt�@�C���T�C�Y�v�Z
	*-----------------------------
	move.w	VSXsize(a6),d5
	mulu.w	VSYsize(a6),d5
	add.l	d5,d5

	*���݂̉��z��ʃt�@�C���T�C�Y���擾
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

*�X�N���[���\���\��
*----------------------------
	btst.b	#2,Sys_flag2(a6)
	beq	load90			�X�N���[���\���͂��Ȃ�

	btst.b	#2,Sys_flag(a6)
	beq	load87			�����؂ɓW�J�͂��Ă��Ȃ�

	btst.b	#3,Sys_flag(a6)
	bne	load90			�f�B�X�N�t��

	*�W�J��s�p�ɂȂ���ܰ��ر��������āA�����؂ɓW�J�����摜���ǂݍ��߂邩�H
	*------------------------------
	movea.l	free_adrs(a6),a0
	move.l	a0,GETP_adrs(a6)
	adda.l	GETP_size(a6),a0
	move.l	a0,Scroll_Area(a6)

	move.l	free_size(a6),d0
	sub.l	GETP_size(a6),d0
	sub.l	picture_size(a6),d0
	bcs	load87			�ǂݍ��߂Ȃ�

	*ү���ޓǂݍ����ޯ̧ܰ��X�V
	*------------------------------
	cmp.l	#1024,d0
	bcs	load87
	move.l	#65535,d1
	cmp.l	d1,d0
	bls	@f
	move.l	d1,d0
@@
	move.l	d0,buf_size(a6)

	*�摜�S�̂�ǂݍ���
	*------------------------------
	clr.w	-(sp)
	clr.l	-(sp)
	move.w	temp_handle(a6),-(sp)
	dos	_SEEK			�t�@�C���̐擪��

	move.l	picture_size(a6),-(sp)
	move.l	Scroll_Area(a6),-(sp)
	move.w	temp_handle(a6),-(sp)
	dos	_READ
	lea.l	8+10(sp),sp		�摜��S���ǂݍ���

	bsr	close_temp		������̧�ق��폜


*�X�N���[���\��
*------------------------------
load87
	bsr	Scroll
	bra	load_end_adjust_home

*�W�J�\����̃L�[���͑҂�
*------------------------------
load90
	btst.b	#0,Sys_flag(a6)
	beq	load_end_adjust_home	�L�[���͑҂���߼�݂Ȃ�
@@
	dc.w	$ffff

	bsr	inkey
	tst.l	d0
	beq	@b

load_end_adjust_home

	bsr	pic_home_adjust

*�\���I��
*-------------------------------
load_end
	*������(G_VIEW)�p�ɉ�ʂ�Home�ʒu��ݒ�
	*-----------------------------
	bsr	set_HOME_for_apli

	*������̧�ٍ폜
	*-------------------------------
	bsr	close_temp

	*����ү���ނ�\�����Ă�����������ďI��
	*-------------------------------
@@
	btst.b	#0,Sys_flag3(a6)
	beq	@f
	bsr	inkey_undo
	bra	@b
@@
	*�}�E�X������
	*-------------------------------
	btst.b	#5,Sys_flag2(a6)
	bne	load_end_VS		���z��ʂɓW�J�����ꍇ�́A�������Ȃ��ŏI��

	iocs	_MS_INIT
	moveq.l	#-1,d1
	iocs	_SKEY_MOD

	*�J�[�\���\��
	*--------------------------------
	move.w	#17,-(sp)
	dos	_CONCTRL
	addq.w	#2,sp

	*���[�U�[���[�h�֕��A
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
*	��ʃT�C�Y���A�eܰ���������
*
*******************************************************************
init_vwork

	*  �摜�̏c,������ۯ���, ��ۯ��̏c�����ޯĐ����v�Z
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
	move.w	d1,BlkX(a6)		�������̃u���b�N��
	move.w	d2,BlkY(a6)		�c�����̃u���b�N��
	move.w	d3,DeltaX(a6)		1��ۯ��ӂ�̉����ޯĐ�
	move.w	d4,DeltaY(a6)		1��ۯ��ӂ�̏c���ޯĐ�

	*  �摜�̎g�p��ؗe�ʂ��v�Z
	*--------------------------------
	lsl.w	#3,d1
	lsl.w	#3,d2
	mulu.w	d1,d2
	add.l	d2,d2			d2=�g�p�������e��
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
*	���P�u���b�N���C�����̃����������
*
*******************************************************************
getmem_1block_line

	move.w	BlkX(a6),d0
	mulu.w	DeltaY(a6),d0
	lsl.l	#3+1,d0
	cmp.l	buff_size(a6),d0
	bcc	Memory_error			�m�ۏo���Ȃ��̂ŃG���[
	move.l	d0,Scroll_size(a6)
	bset.b	#4,Sys_flag(a6)
	rts

*******************************************************************
*
*	��ʉ��P���C�����̃����������
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
	bcc	Memory_error			�m�ۏo���Ȃ��̂ŃG���[
	move.l	d0,VSFile_buf_size(a6)
	rts

*******************************************************************
*
*	̧�ٱ����ޯ̧�̊m��
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
*	����	�Ȃ�
*	�o��	d6,d7.....x,y�ړ���
*		d5........z(�g��k����)
*	�j��	d0-d5,a0-a2
*
******************************************************************************
inkey
*�}�E�X�f�[�^�ǂݍ���
*-------------------------
	*�I����
	*-------------------
	iocs	_MS_GETDT
	cmp.w	#$ff_ff,d0
	beq	inkey_end_key2		�I���ł���

	move.w	MOUSE_TZ(a6),d5

	*�J�[�\���ʒu�ǂݍ���
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


*�L�[����
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
*�\���ʒu�A�\���{������̫�Ă�
*-----------------------------
inkey_home
		bclr.b	#2,Sys_flag3(a6)
		bnz	inkey_home_first

		move.b	Home_key_time(a6),d0
		tst.b	d0
		bne	inkey_home_next

	*�ŏ���Home���������ꂽ�ꍇ�̏���
	*-------------------------
inkey_home_first
		move.w	Maxline(a6),d5
		move.w	Xline(a6),d6
		move.w	Yline(a6),d7
		lsr.w	d6
		lsr.w	d7
		bra	inkey_home_end

	*���ڂ�Home���������ꂽ�ꍇ�̏���
	*�@�摜����ʂ̻��ނɍ��킹��
	*-------------------------
inkey_home_next
		*�\���{����ܰ��Ɠ����`���ɕϊ�
		*----------------------
		move.w	Maxline(a6),d5
		move.w	#512,d0
		cmp.w	d0,d5
		bcs	1f		�g�������

			*�k��
			*---------------------
			move.w	d0,d5
			bra	2f
			*�g��
			*----------------------
1
			move.w	d0,d5
2
		*�摜��ΰшʒu���v�Z
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
*�摜����\��
*----------------------
inkey_undo
		btst.b	#4,Sys_flag2(a6)
		bnz	inkey_undo_end

		btst.b	#0,Sys_flag3(a6)
		beq	inkey_undo_disp1

		bchg.b	#1,Sys_flag3(a6)
		bne	inkey_undo_disp2

	*�\�����ŁA���K���ɐݒ�
	*----------------------------
		move.w	#$1b3f,$e82600
		rts

	*�\��
	*----------------------------
inkey_undo_disp1
		bset.b	#0,Sys_flag3(a6)
		bsr	cls_text
		bra	Disp_Pic_Info


	*�\������
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
		bcc	@f		���ް�۰���Ă��Ȃ�
		add.w	$9ca.w,d0
@@
		add.w	d0,d0
		cmp.w	#$fffe,2(a1)
		bhi	get_key_time_1	��߰Ē�
		beq	@f		��߰ĊJ�n�҂���

		move.w	#$fffe,2(a1)	�ŏ���key on�̏������������Ƃ��}�[�N
		moveq.l	#1,d0
		bra	get_key_time_2
@@
		sub.w	#20*2,d0
		bls	get_key_time_end	�܂���߰ĊJ�n�ł͂Ȃ�
		move.w	#$ffff,2(a1)	��߰Ē��ł��鎖���}�[�N
get_key_time_1
		move.w	d2,(a1)

	*�ړ�������������
	*------------------------------
get_key_time_2
		bsr	chk_key_fast
		add.w	d0,d1
get_key_time_end
		rts


Key_jmp_tbl
	*�ʏ�̷�����
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

	*������Ɠ��ʂȷ�����
	*-------------------------
		.dc.w	K_Home*6,inkey_home-inkey_loop

		.dc.w	0

***********************
*
*	�ړ��������L�[�`�F�b�N
*
*	����	d0	�ړ���
*	�o��	d0	�ړ���
*	�j��	����
***********************
.xdef chk_key_fast
chk_key_fast
		cmp.w	#$ffff,Key_work+K_Ctrl*6(a6)
		bne	3f			Ctrl��������
		cmp.w	#$ffff,Key_work+K_Opt1*6(a6)
		bne	3f			Opt.1��������

		btst.b	#3,Sys_flag3(a6)
		bne	1f			TV ctrl�����ړ����������Ƃ��ċ����g�p

		btst.b	#0,$ed0027
		beq	4f			Opt.2��TV ctrl
		bra	2f			Opt.2��normal
1:
		cmp.w	#$ffff,Key_work+K_Shift*6(a6)
		bne	3f			Shift��������
2:
		cmp.w	#$ffff,Key_work+K_Opt2*6(a6)
		bne	3f			Opt.2��������
		bra	4f
3:
		lsl.w	#2,d0
4:
		rts
******************************************************************************
*
*   �x�N�^�擾
*
******************************************************************************
Get_vector
*Ctrl-C�ƃv���Z�X�̃A�{�[�g�x�N�^��ύX����
*--------------------------------------------
		pea.l	abort_process(pc)
		move.w	#_CTRLVC,-(sp)
		DOS	_INTVCS
		addq.w	#6,sp

		pea.l	abort_process(pc)
		move.w	#_ERRJVC,-(sp)
		DOS	_INTVCS
		addq.w	#6,sp

*KEY BUFFER FULL���荞�݂̃x�N�^��������
*--------------------------------------------
	*Key_work��������
	*--------------------------------
		lea.l	Key_work(a6),a0
		move.l	#$ffff0000,d0
		move.w	#128+2-1,d1
@@
		move.l	d0,(a0)+
		move.w	d0,(a0)+
		dbra	d1,@b

	*�޸���������
	*-------------------------------
		*���޸����擾
		*---------------------
		move.w	#$4c,-(sp)
		DOS	_INTVCG
		addq.l	#2,sp
		lea.l	int4c_bak(pc),a0
		move.l	d0,(a0)
		*�޸��������ւ�
		*---------------------
		pea	int4c(pc)
		move.w	#$4c,-(sp)
		DOS	_INTVCS
		addq.l	#2+4,sp

*ϳ���M��׸��L�����荞�ݏ��������纰ق�����޸��̈��������
*--------------------------------------------
		lea.l	mouse_sub_bak(pc),a0
		move.l	$934.w,(a0)
		lea.l	mouse_int(pc),a0
		move.l	a0,$934.w
		rts
******************************************************************************
*
*   �x�N�^���A
*
******************************************************************************
.xdef	Restore_vector
Restore_vector
		move.l	int4c_bak(pc),d0
		beq	Restore_vector_4c_end	�޸�̯����Ă��Ȃ�
		move.l	d0,-(sp)
		move.w	#$4c,-(sp)
		DOS	_INTVCS
		addq.l	#2+4,sp
Restore_vector_4c_end

		move.l	mouse_sub_bak(pc),d0
		beq	Restore_vector_mouse_end	�޸�̯����Ă��Ȃ�
		move.l	d0,$934.w
Restore_vector_mouse_end

		rts
*******************************************************
*
*	Ctrl-C�܂��͏����𒆒f���ꂽ�ꍇ�̏���
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
*	Key Buffer Full ���荞�ݏ���
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
		bcc	keyon_sub	���ݏ���
		bra	keyoff_sub
int4c_end
		movem.l	(sp)+,d0/a0/a6
		move.l	int4c_bak(pc),-(sp)
		rts

*----------------------------
*���ݏ���
*	d0.w	�����ݺ���*2
*----------------------------
keyon_sub
		add.l	d0,a0
		add.w	d0,d0
		add.l	d0,a0
		cmp.w	#$ffff,(a0)
		bne	@f			���ݒ�

	*TV ctrl�������������̷��݂́A����
	*----------------------
		btst.b	#3,Sys_flag3(a6)
		bne	keyon_sub_set_time	TV ctrl�����ړ����������Ƃ��ċ����g�p

		cmp.w	#$ffff,Key_work+K_Shift*6(a6)
		bne	@f			Shift��������Ă���

		btst.b	#0,$ed0027
		bne	keyon_sub_set_time	Opt.2��TVctrl���ł͂Ȃ�
		cmp.w	#$ffff,Key_work+K_Opt2*6(a6)
		bne	@f			Opt2��������Ă���

	*���݊J�n���Ԃ�ݒ�
	*------------------------
keyon_sub_set_time
		move.w	$9cc.w,(a0)
		clr.w	2(a0)
@@
		rts
*----------------------------
*���̏���
*	d0.w	�����ݺ���*2
*----------------------------
keyoff_sub
		add.l	d0,a0
		add.w	d0,d0
		add.l	d0,a0
		move.w	(a0),d0
		cmp.w	#$ffff,d0
		beq	keyoff_sub_end	���łɷ��̂ɂȂ��Ă���

		*���̎��Ԃ��v�Z
		*----------------------
		sub.w	$9cc.w,d0
		bcc	@f		���ް�۰���Ă��Ȃ�
		add.w	$9ca.w,d0
@@
		add.w	d0,d0

	*��߰Ē��̏ꍇ�A���̂܂ł̎��Ԃ𷰵ݎ��Ԃɉ��Z
	*----------------------
		cmp.w	#$fffe,2(a0)
		beq	keyoff_sub_1	��߰ĊJ�n�҂�������
		bhi	@f		��߰Ē�

		*���݂��緰�̂܂ŁA���ݎ��Ԃ�ǂ܂�Ȃ������ꍇ�̏���
		*--------------------
		sub.w	#20*2,d0
		bhi	@f
		moveq.l	#1,d0
@@
		add.w	d0,4(a0)	����߰ĊJ�n���緰�̂܂ł̎��Ԃ����Z
keyoff_sub_1
		move.w	#$ffff,(a0)	���̒��׸ސݒ�
keyoff_sub_end
		rts
*******************************************************
*
*	Mouse��M��׸����荞�ݏ��������纰ق�����޸��̓���
*	��̏���
*
*	input	a1.l	ϳ��ް��̱��ڽ
*	output	none
*	break	none
*******************************************************
mouse_int
		movem.l	d0/a0/a6,-(sp)
		move.l	work_adrs(pc),a6

*�����݂̏���
*----------------------------
		lea.l	Mouse_work(a6),a0
		moveq.l	#0*2,d0

		pea.l	mouse_int_left_end(pc)	�߂���ڽ
		btst.b	#1,(a1)
		bnz	keyon_sub	���ݏ���
		bra	keyoff_sub
mouse_int_left_end

*�E���݂̏���
*----------------------------
		lea.l	Mouse_work(a6),a0
		moveq.l	#1*2,d0
		pea.l	mouse_int_right_end(pc)	�߂���ڽ
		btst.b	#0,(a1)
		bnz	keyon_sub	���ݏ���
		bra	keyoff_sub
mouse_int_right_end

		movem.l	(sp)+,d0/a0/a6
		move.l	mouse_sub_bak(pc),a0
		jmp	(a0)

******************************************************************************
*
*   home�ʒu����ʃA�v���p�ɐݒ�
*
*	����	d2.w	X
*		d3.w	Y
*
******************************************************************************
.xdef	set_HOME_wait
set_HOME_wait

	*�A�����ԑ҂�
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
*   �摜��home�ʒu��(0,0)�ɕύX
*
*	����	Home_X(a6)
*		Home_Y(a6)
*	�o��	����
*	�j��
******************************************************************************
.xdef pic_home_adjust
pic_home_adjust

		btst.b	#5,Sys_flag3(a6)
		beq	pic_home_adjust_end	�␳�v������

		move	Home_Y(a6),d1
		move	Home_X(a6),d0
		move.w	d0,d2
		or.w	d1,d2
		beq	pic_home_adjust_end	���ł�Home�ʒu��(0,0)�ł���

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
*VRAM�ǂݍ���
*
*	����	d0	X��Home�ʒu
*		a0	��荞���ޯ̧���ڽ
*		a1	VRAM���ڽ
*	�o��	�Ȃ�
*	�j��	d2,a0,a2
*******************************
get_VRAM_adjust_X
	*�E����荞��
	*------------------------
		movea.l	a1,a2
		add.w	d0,a2
		add.w	d0,a2

		move.w	#512,d2
		sub.w	d0,d2

		*�ݸ�ܰ�ނœ]�������]��
		*-------------------
		lsr.w	d2
		bcc	@f			�]���ޯĐ��͋���
		move.w	(a2)+,(a0)+
@@
		*�ݸ�ܰ��*2�œ]�������]��
		*-------------------
		lsr.w	d2
		bcc	@f			�]���ޯĐ��͂S�̔{��
		move.l	(a2)+,(a0)+
@@
		*�ݸ�ܰ��*2�œ]��
		*-----------------
		subq.w	#1,d2
		bcs	1f
@@		move.l	(a2)+,(a0)+
		move.l	(a2)+,(a0)+
		dbra.w	d2,@b
1
	*������荞��
	*------------------------
		movea.l	a1,a2
		move.w	d0,d2
		beq	get_VRAM_adjust_X_end

		*�ݸ�ܰ�ނœ]�������]��
		*-------------------
		lsr.w	d2
		bcc	@f			�]���ޯĐ��͋���
		move.w	(a2)+,(a0)+
@@
		*�ݸ�ܰ��*2�œ]�������]��
		*-------------------
		lsr.w	d2
		bcc	@f			�]���ޯĐ���4�̔{��
		move.l	(a2)+,(a0)+
@@
		*�ݸ�ܰ��*2�œ]��
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
*	�e�L�X�g��ʂ��N���A����
******************************************************************************
cls_text
		move.w	#2,-(sp)
		move.w	#10,-(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
		rts
******************************************************************************
*
*  �e���|�����t�@�C������č폜����
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