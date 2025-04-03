	.include	DOSCALL.MAC
	.include	JPEG.MAC
	.include	work.inc

	.xref	msgCR
	.xref	Restore_vector
	.xref	Comment_msg,Qtable_msg,file_msg,not_found_msg
	.xref	cant_PROC_msg
	.xref	ParamMsg
	.xref	illegal_size_msg
	.xref	out_of_memory_msg
	.xref	not_JPEG_msg
	.xref	no_picture_msg
	.xref	Write_error_msg
	.xref	Read_error_msg
*	.xref	no_sup_24_msg
	.xref	LoadForceContinue
	.text

*�����ײݴװ
*----------------------
.xdef	Switch_Error
Switch_Error
		pea	ParamMsg(pc)
		bra	Disp_error_end

*���l���͈͊O
*----------------------
.xdef	Illegal_size_error
Illegal_size_error
		pea.l	illegal_size_msg(pc)
		bra	Disp_error_end

*��؂�����Ȃ�
*----------------------
.xdef	Memory_error
Memory_error
		pea.l	out_of_memory_msg(pc)
		bra	Disp_error_end

*JPEĢ�قƉ��ߏo���Ȃ�
*----------------------
.xdef	Not_JPEG_error
Not_JPEG_error
		pea.l	not_JPEG_msg(pc)
		bra	Disp_error_end

*JPEĢ�قƉ��ߏo���Ȃ�
*----------------------
.xdef	No_Picture_error
No_Picture_error
		pea.l	no_picture_msg(pc)
		bra	Disp_error_end

*���ް�ޮ݂ł͑Ή��o���Ȃ�
*----------------------
.xdef	Cant_PROC_error
Cant_PROC_error
		pea.l	cant_PROC_msg(pc)
		bra	Disp_error_end

*�������߂Ȃ�
*----------------------
.xdef	Write_error
Write_error
		pea.l	Write_error_msg(pc)
		bra	Disp_error_end


*�ُ��JPEĢ�قł���
*----------------------
.xdef IllegalJPEG
IllegalJPEG
*		btst.b	#6,SysFlag3(a6)
*		beq	Read_error
		move.l	ErrorStackPoint(a6),d0
		bze	Read_error
		movea.l	d0,sp
		bra	LoadForceContinue

*�ǂݍ��߂Ȃ�
*----------------------
.xdef	Read_error
Read_error
		pea.l	Read_error_msg(pc)
		bra	Disp_error_end

*24bit�W�J�ͻ�߰Ă��Ă��Ȃ�
*----------------------
*.xdef	no_sup_24_error
*no_sup_24_error
*		pea.l	no_sup_24_msg(pc)
*		bra	Disp_error_end

*JPEĢ�ق�������Ȃ�
*----------------------
.xdef	JPEG_not_found
JPEG_not_found

		pea.l	fname(a6)
		bra	File_not_found

*���z���̧�ق�������Ȃ�
*----------------------
.xdef	VS_not_found
VS_not_found

		pea.l	VSname(a6)
		bra	File_not_found

*����̧�ق�������Ȃ�
*----------------------
.xdef	Comment_not_found
Comment_not_found

		pea.l	Comment(a6)
		pea.l	Comment_msg(pc)
		bra	_file_not_found

*�ʎq��ð���̧�ق�������Ȃ�
*----------------------
.xdef	Qtable_not_found
Qtable_not_found

		pea.l	Qname(a6)
		pea.l	Qtable_msg(pc)

_file_not_found

	.if	0
		DOS	_PRINT
	.endif

*̧�ق�������Ȃ�
*----------------------
File_not_found

	.if	0
		pea.l	file_msg(pc)
		DOS	_PRINT
		addq.l	#4,sp
		DOS	_PRINT
		addq.l	#4,sp
		pea.l	not_found_msg(pc)
	.endif

Disp_error_end
	.if	0
		DOS	_PRINT
		pea.l	msgCR(pc)
		DOS	_PRINT
	.endif

	.if	0

		bsr	Restore_vector

		move.w	#17,-(sp)
		dos	_CONCTRL	*���ٕ\��

		move.w	#9,(sp)
		dos	_EXIT2

	.else

		.xref	jpeg_abort_addr
		movea.l	jpeg_abort_addr,a0
		jmp	(a0)

	.endif

	.end
