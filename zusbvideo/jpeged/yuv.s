*
*
*  YUV.S
*
*  ó£éUÉRÉTÉCÉìïœä∑ÉeÉXÉgÉvÉçÉOÉâÉÄ
*
*
.include	JPEG.MAC
.include	work.inc

DITH_UL	equ	0
DITH_UR equ     6
DITH_DL equ	6+10*12
DITH_DR equ	10*12
*DITH_UL	equ	0
*DITH_UR	equ	0
*DITH_DL	equ	0
*DITH_DR	equ	0
*

  xdef   YUV_to_RGB,YUV_to_RGB2,YUV_to_RGB4

	.text

*
*	ÇxÇtÇuÇ©ÇÁÇqÇfÇaïœä∑É}ÉNÉç
*
*
conv_y	macro Yin,RGBout
    move.l  Yin,d1 * Y			#12+n
    move.w  (a2,d1.w),d2	R	#14
    or.w    (a5,d1.w),d2	G,I	#14
    or.w    (a6,d1.w),d2	B	#14
    swap.w  d1				#4
    swap.w  d2				#4
    move.w  DITH_UR(a2,d1.w),d2		R	#14
    or.w    DITH_UR(a5,d1.w),d2	G,I	#14
    or.w    DITH_UR(a6,d1.w),d2		B	#14
    move.l  d2,RGBout			#12+n
	endm				116+2n
*
*	ÇxÇtÇuÇ©ÇÁÇqÇfÇaïœä∑É}ÉNÉçÇQ
*
*
conv_y2	macro Yin,RGBout
    move.l  Yin,d1 * Y			#12+n
    move.w  DITH_DL(a2,d1.w),d2		R	#14
    or.w    DITH_DL(a5,d1.w),d2	G,I	#14
    or.w    DITH_DL(a6,d1.w),d2		B	#14
    swap.w  d1				#4
    swap.w  d2				#4
    move.w  DITH_DR(a2,d1.w),d2		R	#14
    or.w    DITH_DR(a5,d1.w),d2	G,I	#14
    or.w    DITH_DR(a6,d1.w),d2		B	#14
    move.l  d2,RGBout			#12+n
	endm				116+2n

*
*	ÇxÇtÇuÇ©ÇÁÇqÇfÇaïœä∑É}ÉNÉç
*
*
conv_cy	macro RGBout
    move.w  (a2),d2	R	#14
    or.w    (a5),d2	G,I	#14
    or.w    (a6),d2	B	#14
    swap.w  d2				#4
    move.w  DITH_UR(a2),d2	R	#14
    or.w    DITH_UR(a5),d2	G,I	#14
    or.w    DITH_UR(a6),d2	B	#14
    move.l  d2,RGBout		#12+n
	endm
*
*	ÇxÇtÇuÇ©ÇÁÇqÇfÇaïœä∑É}ÉNÉçÇQ
*
*
conv_cy2	macro	RGBout
    move.w  DITH_DL(a2),d2	R	#14
    or.w    DITH_DL(a5),d2	G,I	#14
    or.w    DITH_DL(a6),d2	B	#14
    swap.w  d2				#4
    move.w  DITH_DR(a2),d2	R	#14
    or.w    DITH_DR(a5),d2	G,I	#14
    or.w    DITH_DR(a6),d2	B	#14
    move.l  d2,RGBout		#12+n
	endm


*
*	ÇxÇtÇuÇ©ÇÁÇqÇfÇaïœä∑É}ÉNÉçÇR
*
*
conv_cy3	macro	RGBout1,RGBout2
    move.w  (a2),RGBout1		R	#14
    or.w    (a5),RGBout1		G,I	#14
    or.w    (a6),RGBout1		B	#14
    swap.w  RGBout1				#4
    move.w  DITH_UR(a2),RGBout1		R	#14
    or.w    DITH_UR(a5),RGBout1	G,I	#14
    or.w    DITH_UR(a6),RGBout1		B	#14

    move.w  DITH_DL(a2),RGBout2		R	#14
    or.w    DITH_DL(a5),RGBout2	G,I	#14
    or.w    DITH_DL(a6),RGBout2		B	#14
    swap.w  RGBout2				#4
    move.w  DITH_DR(a2),RGBout2		R	#14
    or.w    DITH_DR(a5),RGBout2	G,I	#14
    or.w    DITH_DR(a6),RGBout2		B	#14
	endm
*
*	Çtê¨ï™ïœä∑É}ÉNÉç
*
*
conv_u	macro Uin

    move.w  Uin,a4 * U
    adda.l  d0,a4
    adda.w  -(a4),a6			d7 = 1.7718*U+0.0012*V
    adda.w  -(a4),a5			d6 = 0.3441*U+0.7139*V
	endm
*
*	Çuê¨ï™ïœä∑É}ÉNÉç
*
*
conv_v	macro Vin
    move.w  Vin,a4 * V
    adda.l  d0,a4
    adda.w  (a4)+,a2			1.4020
    adda.w  (a4)+,a5			0.7319
    adda.w  (a4),a6			0.0012
	endm
*
*	Çuê¨ï™ïœä∑É}ÉNÉç
*
*
convm_v	macro Vin
    move.w  Vin,a4 * V
    movem.w (a4,d0.l),a2/a5-a6		1.4020,0.7319,0.0012
	endm

*
*	Çtê¨ï™ïœä∑É}ÉNÉç
*
*
conv1_u	macro Uin
    move.w  Uin,a4 * U
    adda.l  d0,a4
    add.w   -(a4),d3			1.7718	B
    add.w   -(a4),d2			0.3441	G
	endm
*
*	Çtê¨ï™ïœä∑É}ÉNÉçÇQ
*
*
conv1_cu	macro Uin
    move.w  Uin,a4 * U
    movem.w  -4(a4,d0.l),d2-d3		0.3441,1.7718
	endm
*
*	Çuê¨ï™ïœä∑É}ÉNÉç
*
*
conv1_v	macro Vin
    move.w  Vin,a4 * V
    adda.l  d0,a4
    add.w   (a4)+,d1			1.4020	R
    add.w   (a4)+,d2			0.7319	G
    add.w   (a4),d3			0.0012	B
	endm
*
*	Çuê¨ï™ïœä∑É}ÉNÉçÇQ
*
*
conv1_cv	macro Vin
    move.w  Vin,a4 * V
    adda.l  d0,a4
    move.w  (a4)+,d1		1.4020	R
    move.w  (a4)+,d2		0.7319	G
    move.w  (a4),d3		0.0012	B
	endm
*
*	Çuê¨ï™ïœä∑É}ÉNÉçÇQ
*
*
conv1m_cv	macro Vin
    move.w  Vin,a4 * V
    movem.w  (a4,d0.l),d1-d3		1.4020,0.7319,0.0012	RGB
	endm
*
*	Çuê¨ï™ïœä∑É}ÉNÉçÇR
*
*
conv1_cv2	macro Vin
    move.w  Vin,a4 * V
    adda.l   d0,a4
    move.w   (a4)+,d1			1.4020	R
    add.w    (a4)+,d2			0.7139	G
    add.w    (a4)+,d3			0.0012	B
	endm
*
*  RGB assemble
*
conv1_y	macro DITH_OFF,DITH_OFF2
    move.w  DITH_OFF(a2,d1.w),d1	R
    or.w    DITH_OFF2(a5,d2.w),d1	G,I
    or.w    DITH_OFF(a6,d3.w),d1	B
	endm
*
*
*
*  YUV to RGB
*    a0     VRAM(w)
*    a1     Ydata(w)
*    a2     Udata(w)
*    a3     Vdata(w)
*
*
YUV_to_RGB
  move.l  a6,d0
  add.l   #YUV_RGB_TBL+V14020+1024*2*6,d0
  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6

  jmp     yuv1_tbl(pc,d2.w)

  align 4
yuv1_tbl

  bra.w    yr10_yuv
  bra.w    yr10_yu_
  bra.w    yr10_y_v
  bra.w    yr10_y__
  bra.w    yr10__uv
  bra.w    yr10__u_
  bra.w    yr10___v
*  bra.w    yr10_normal


yr10_normal
  moveq.l #4-1,d4
yr15
  moveq.l #4-1,d5
yr20
    move.l  (a1)+,d1 * Y
    move.w  d1,d2
    move.w  d1,d3

    conv1_u  udata1-vdata1(a3)
    conv1_v  (a3)+
    conv1_y

    swap.w  d1
    move.w  d1,d2
    move.w  d1,d3

    conv1_u  udata1-vdata1(a3)
    conv1_v  (a3)+
    conv1_y  DITH_UR,DITH_UR

    move.l  d1,(a0)+
    dbra    d5,yr20
  moveq.l  #4-1,d5
yr25
    move.l  (a1)+,d1 * Y
    move.w  d1,d2
    move.w  d1,d3

    conv1_u  udata1-vdata1(a3)
    conv1_v  (a3)+
    conv1_y  DITH_DL,DITH_DL

    swap.w  d1
    move.w  d1,d2
    move.w  d1,d3

    conv1_u  udata1-vdata1(a3)
    conv1_v  (a3)+
    conv1_y  DITH_DR,DITH_DR

    move.l  d1,(a0)+
    dbra    d5,yr25
   dbra    d4,yr15
  rts
*
*
*
yr10___v
  conv_v  (a3)
  lea.l   udata1-vdata1(a3),a3
  moveq.l #4-1,d4
yr15___v
  moveq.l #4-1,d5
yr20___v
    move.l  (a1)+,d1 * Y
    move.w  d1,d2
    move.w  d1,d3

    conv1_u (a3)+
    conv1_y

    swap.w  d1
    move.w  d1,d2
    move.w  d1,d3

    conv1_u (a3)+
    conv1_y DITH_UR,DITH_UR

    move.l  d1,(a0)+
    dbra    d5,yr20___v
  moveq.l #4-1,d5
yr25___v
    move.l  (a1)+,d1 * Y
    move.w  d1,d2
    move.w  d1,d3

    conv1_u (a3)+
    conv1_y DITH_DL,DITH_DL

    swap.w  d1
    move.w  d1,d2
    move.w  d1,d3

    conv1_u (a3)+
    conv1_y DITH_DR,DITH_DR

    move.l  d1,(a0)+
    dbra    d5,yr25___v
   dbra    d4,yr15___v
  rts
*
*
*
yr10__u_
  conv_u  udata1-vdata1(a3)
  moveq.l #4-1,d4
yr15__u_
  moveq.l #4-1,d5
yr20__u_
    move.l  (a1)+,d1 * Y
    move.w  d1,d2
    move.w  d1,d3

    conv1_v (a3)+
    conv1_y

    swap.w  d1
    move.w  d1,d2
    move.w  d1,d3

    conv1_v (a3)+
    conv1_y DITH_UR,DITH_UR

    move.l  d1,(a0)+
    dbra    d5,yr20__u_
  moveq.l #4-1,d5
yr25__u_
    move.l  (a1)+,d1 * Y
    move.w  d1,d2
    move.w  d1,d3

    conv1_v (a3)+
    conv1_y DITH_DL,DITH_DL

    swap.w  d1
    move.w  d1,d2
    move.w  d1,d3

    conv1_v (a3)+
    conv1_y DITH_DR,DITH_DR

    move.l  d1,(a0)+
    dbra    d5,yr25__u_
   dbra    d4,yr15__u_
  rts
*
*
*
yr10__uv

    conv_u  udata1-vdata1(a3)
    conv_v  (a3)

  moveq.l #4-1,d4

yr10__uv_1

    rept    4
    conv_y  (a1)+,(a0)+
    endm
    rept    4
    conv_y2  (a1)+,(a0)+
    endm

    dbra    d4,yr10__uv_1
  rts
*
*
*
yr10_y__
  move.w  (a1),d1 * Y
  ext.l   d1
  adda.l  d1,a2
  adda.l  d1,a5
  adda.l  d1,a6
  moveq.l #4-1,d4
yr15_y__
  moveq.l  #4-1,d5
yr20_y__

    conv1_cu   udata1-vdata1(a3)
    conv1_cv2  (a3)+
    conv1_y

    swap.w  d1

    conv1_cu   udata1-vdata1(a3)
    conv1_cv2  (a3)+
    conv1_y    DITH_UR,DITH_UR

    move.l  d1,(a0)+
    dbra    d5,yr20_y__
  moveq.l  #4-1,d5
yr25_y__

    conv1_cu   udata1-vdata1(a3)
    conv1_cv2  (a3)+
    conv1_y    DITH_DL,DITH_DL

    swap.w  d1

    conv1_cu   udata1-vdata1(a3)
    conv1_cv2  (a3)+
    conv1_y    DITH_DR,DITH_DR

    move.l  d1,(a0)+
    dbra    d5,yr25_y__
   dbra    d4,yr15_y__
  rts
*
*
*
yr10_y_v
  move.w  (a1),d1 * Y
  ext.l   d1
  adda.l  d1,a2
  adda.l  d1,a5
  adda.l  d1,a6
  conv_v  (a3)
  lea.l   udata1-vdata1(a3),a3
  moveq.l #4-1,d4
yr15_y_v
  moveq.l #4-1,d5
yr20_y_v
    conv1_cu (a3)+
    move.w  (a2),d1		R
    or.w    (a5,d2.w),d1	G,I
    or.w    (a6,d3.w),d1	B

    swap.w  d1

    conv1_cu (a3)+
    move.w  DITH_UR(a2),d1		R
    or.w    DITH_UR(a5,d2.w),d1	G,I
    or.w    DITH_UR(a6,d3.w),d1		B

    move.l  d1,(a0)+
    dbra    d5,yr20_y_v
  moveq.l #4-1,d5
yr25_y_v
    conv1_cu (a3)+
    move.w  DITH_DL(a2),d1		R
    or.w    DITH_DL(a5,d2.w),d1	G,I
    or.w    DITH_DL(a6,d3.w),d1		B

    swap.w  d1

    conv1_cu (a3)+
    move.w  DITH_DR(a2),d1		R
    or.w    DITH_DR(a5,d2.w),d1	G,I
    or.w    DITH_DR(a6,d3.w),d1		B

    move.l  d1,(a0)+
    dbra    d5,yr25_y_v
   dbra    d4,yr15_y_v
  rts
*
*
*
yr10_yu_
  move.w  (a1),d1 * Y
  ext.l   d1
  adda.l  d1,a2
  adda.l  d1,a5
  adda.l  d1,a6
  conv_u  udata1-vdata1(a3)
  moveq.l #4-1,d4
yr15_yu_
  moveq.l #4-1,d5
yr20_yu_

    conv1m_cv (a3)+
    conv1_y

    swap.w  d1

    conv1_cv (a3)+
    conv1_y DITH_UR,DITH_UR

    move.l  d1,(a0)+
    dbra    d5,yr20_yu_

  moveq.l #4-1,d5
yr25_yu_

    conv1m_cv (a3)+
    conv1_y DITH_DL,DITH_DL

    swap.w  d1

    conv1_cv (a3)+
    conv1_y DITH_DR,DITH_DR

    move.l  d1,(a0)+
    dbra    d5,yr25_yu_
   dbra    d4,yr15_yu_
  rts
*
*
*
yr10_yuv

    move.w  (a1),d1 * Y
    move.w  d1,d2
    move.w  d1,d3

    conv1_u  udata1-vdata1(a3)
    conv1_v  (a3)

    adda.w  d1,a2
    adda.w  d2,a5
    adda.w  d3,a6

*
*  RGB assemble
*
    conv_cy3 d0,d4

    move.l  d0,d1
    move.l  d0,d2
    move.l  d0,d3
    move.l  d4,d5
    move.l  d4,d6
    move.l  d4,d7
    lea.l   64*2(a0),a0
    rept    4
    movem.l d0-d7,-(a0)
    endm
    rts

*
*	ÇPÅ^ÇQÇ…ä‘à¯Ç©ÇÍÇΩéûÇÃÇxÇtÇuÇ©ÇÁÇqÇfÇaïœä∑
*
*  YUV to RGB 2
*    a0     VRAM(w)
*    a1     Ydata(w)
*    a2     Udata(w)
*    a3     Vdata(w)
*
*
YUV_to_RGB2

  move.l  a6,d0
  add.l   #YUV_RGB_TBL+V14020+1024*2*6,d0
  jmp     yuv2_tbl(pc,d2.w)

  align 4
yuv2_tbl

  bra.w    yr400_yyuv
  bra.w    yr200_yyu_
  bra.w    yr200_yy_v
  bra.w    yr200_yy__
  bra.w    yr400_y_uv
  bra.w    yr200_y_u_
  bra.w    yr200_y__v
  bra.w    yr200_y___
  bra.w    yr400__yuv
  bra.w    yr200__yu_
  bra.w    yr200__y_v
  bra.w    yr200__y__
  bra.w    yr400___uv
  bra.w    yr200___u_
  bra.w    yr200____v
*  bra.w    yr200_normal

yr200_normal

  move.l a6,d3
  add.l  #RGB_TBL+1024*2*6,d3
  bsr     yr201
  lea     -64*2+4*2(a3),a3
yr201
  moveq.l #4-1,d7
yr205
  moveq.l #4-1,d6
yr210

    convm_v  (a3)+
    adda.l  d3,a2			#4
    adda.l  d3,a5			#4
    adda.l  d3,a6			#4
    conv_u  udata1-vdata1-2(a3)
    conv_y  (a1)+,(a0)+

    dbra    d6,yr210

  addq.w  #4*2,a3
  moveq.l #4-1,d6
yr215

    convm_v   (a3)+
    adda.l  d3,a2			#4
    adda.l  d3,a5			#4
    adda.l  d3,a6			#4
    conv_u   udata1-vdata1-2(a3)
    conv_y2  (a1)+,(a0)+

    dbra    d6,yr215
  addq.w  #4*2,a3
  dbra     d7,yr205
  rts
*
*
*
yr200____v

  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6
  conv_v  (a3)
  move.l  a5,d6
  move.l  a6,d7
  lea.l   udata1-vdata1(a3),a3

  bsr     yr201____v
  lea     -64*2+4*2(a3),a3

yr201____v
  moveq.l #4-1,d4
yr205____v
  moveq.l #4-1,d5
yr210____v

    move.l  d6,a5			#4
    move.l  d7,a6			#4

    conv_u  (a3)+
    conv_y  (a1)+,(a0)+
    dbra    d5,yr210____v

  addq.w  #4*2,a3
  moveq.l #4-1,d5
yr215____v

    move.l  d6,a5			#4
    move.l  d7,a6			#4

    conv_u   (a3)+
    conv_y2  (a1)+,(a0)+
    dbra    d5,yr215____v
  addq.w  #4*2,a3
  dbra    d4,yr205____v
  rts

*
*
*
yr200___u_

  movea.l a6,a5
  adda.l  #RGB_TBL+1024*2*6,a5
  move.l  a5,d3
  movea.l a5,a6
  conv_u  udata1-vdata1(a3)
  move.l  a5,d6
  move.l  a6,d7

  bsr     yr201___u_
  lea     -64*2+4*2(a3),a3

yr201___u_
  moveq.l #4-1,d4
yr205___u_
  moveq.l #4-1,d5
yr210___u_

    convm_v  (a3)+
    adda.l  d3,a2			#4
    adda.l  d6,a5			#4
    adda.l  d7,a6			#4
    conv_y  (a1)+,(a0)+
    dbra    d5,yr210___u_

  addq.w  #4*2,a3
  moveq.l #4-1,d5
yr215___u_

    convm_v   (a3)+
    adda.l  d3,a2			#4
    adda.l  d6,a5			#4
    adda.l  d7,a6			#4
    conv_y2  (a1)+,(a0)+
    dbra    d5,yr215___u_
  addq.w  #4*2,a3
  dbra    d4,yr205___u_
  rts
*
*
*
yr200__y__

  move.l a6,d3
  add.l  #RGB_TBL+1024*2*6,d3
  bsr     yr201__y__
  lea     -64*2+4*2(a3),a3
  bra     yr201
*
*
*
yr200__y_v

  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6
  conv_v  (a3)
  move.l  a5,d6
  move.l  a6,d7
  lea.l   udata1-vdata1(a3),a3

  bsr     yr201__y_v
  lea     -64*2+4*2(a3),a3
  bra     yr201____v

*
*
*
yr200__yu_

  movea.l a6,a5
  adda.l  #RGB_TBL+1024*2*6,a5
  move.l  a5,d3
  movea.l a5,a6
  conv_u  udata1-vdata1(a3)
  move.l  a5,d6
  move.l  a6,d7

  bsr     yr201__yu_
  lea     -64*2+4*2(a3),a3
  bra     yr201___u_
*
*
*
yr200_y___

  move.l a6,d3
  add.l  #RGB_TBL+1024*2*6,d3
  bsr     yr201
  lea     -64*2+4*2(a3),a3

yr201__y__
  move.w  (a1),d1
  ext.l   d1
  add.l  d1,d3
  moveq.l #4-1,d4
yr205__y__
  moveq.l  #4-1,d5
yr210__y__

    convm_v  (a3)+
    adda.l  d3,a2			#4
    adda.l  d3,a5			#4
    adda.l  d3,a6			#4
    conv_u  udata1-vdata1-2(a3)
    conv_cy (a0)+
    dbra    d5,yr210__y__
  addq.w  #4*2,a3
  moveq.l  #4-1,d5
yr215__y__

    convm_v   (a3)+
    adda.l  d3,a2			#4
    adda.l  d3,a5			#4
    adda.l  d3,a6			#4
    conv_u   udata1-vdata1-2(a3)
    conv_cy2 (a0)+
    dbra    d5,yr215__y__
  addq.w  #4*2,a3
  dbra    d4,yr205__y__
  sub.l  d1,d3
  lea     64*2(a1),a1
  rts
*
*
*
yr200_y__v

  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6
  conv_v  (a3)
  move.l  a5,d6
  move.l  a6,d7
  lea.l   udata1-vdata1(a3),a3
  bsr     yr201____v
  lea     -64*2+4*2(a3),a3
yr201__y_v
  move.w  (a1),d1
  ext.l   d1
  add.l  d1,a2
  add.l  d1,d6
  add.l  d1,d7
  moveq.l #4-1,d4
yr205__y_v
  moveq.l  #4-1,d5
yr210__y_v

    move.l  d6,a5			#4
    move.l  d7,a6			#4

    conv_u  (a3)+
    conv_cy (a0)+
    dbra    d5,yr210__y_v
  addq.w  #4*2,a3
  moveq.l  #4-1,d5
yr215__y_v

    move.l  d6,a5			#4
    move.l  d7,a6			#4

    conv_u   (a3)+
    conv_cy2 (a0)+
    dbra    d5,yr215__y_v

  addq.w  #4*2,a3
  dbra    d4,yr205__y_v
  sub.l  d1,a2
  sub.l  d1,d6
  sub.l  d1,d7
  lea     64*2(a1),a1
  rts
*
*
*
yr200_y_u_

  movea.l a6,a5
  adda.l  #RGB_TBL+1024*2*6,a5
  move.l  a5,d3
  movea.l a5,a6
  conv_u  udata1-vdata1(a3)
  move.l  a5,d6
  move.l  a6,d7
  bsr     yr201___u_
  lea     -64*2+4*2(a3),a3
yr201__yu_
  move.w  (a1),d1
  ext.l   d1
  add.l  d1,d3
  add.l  d1,d6
  add.l  d1,d7
  moveq.l #4-1,d4
yr205__yu_
  moveq.l  #4-1,d5
yr210__yu_

    convm_v  (a3)+
    adda.l  d3,a2			#4
    adda.l  d6,a5			#4
    adda.l  d7,a6			#4
    conv_cy (a0)+
    dbra    d5,yr210__yu_

  addq.w  #4*2,a3
  moveq.l  #4-1,d5
yr215__yu_

    convm_v   (a3)+
    adda.l  d3,a2			#4
    adda.l  d6,a5			#4
    adda.l  d7,a6			#4
    conv_cy2 (a0)+
    dbra    d5,yr215__yu_
  addq.w  #4*2,a3
  dbra    d4,yr205__yu_

  sub.l  d1,d3
  sub.l  d1,d6
  sub.l  d1,d7
  lea     64*2(a1),a1
  rts
*
*
*
yr200_yy__

  move.l a6,d3
  add.l  #RGB_TBL+1024*2*6,d3
  bsr     yr201__y__
  lea     -64*2+4*2(a3),a3
  bra     yr201__y__
*
*
*
yr200_yy_v

  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6
  conv_v  (a3)
  move.l  a5,d6
  move.l  a6,d7
  lea.l   udata1-vdata1(a3),a3
  bsr     yr201__y_v
  lea     -64*2+4*2(a3),a3
  bra     yr201__y_v
*
*
*
yr200_yyu_

  movea.l a6,a5
  adda.l  #RGB_TBL+1024*2*6,a5
  move.l  a5,d3
  movea.l a5,a6
  conv_u  udata1-vdata1(a3)
  move.l  a5,d6
  move.l  a6,d7
  bsr     yr201__yu_
  lea     -64*2+4*2(a3),a3
  bra     yr201__yu_
*
*	ÇPÅ^ÇSÇ…ä‘à¯Ç©ÇÍÇΩéûÇÃÇxÇtÇuÇ©ÇÁÇqÇfÇaïœä∑
*
*  YUV to RGB 4
*	ì¸óÕ
*		a0     VRAM(w)
*		a1     Ydata(w)
*		a2     Udata(w)
*		a3     Vdata(w)
*	èoóÕ
*		a2     Udata(w)+(8*4)*2
*		a3     Vdata(w)+(8*4)*2
*
YUV_to_RGB4

  move.l  a6,d0
  add.l   #YUV_RGB_TBL+V14020+1024*2*6,d0
  jmp     yuv4_tbl(pc,d1.w)

  align 4
yuv4_tbl

  bra.w    yr400_yyuv
  bra.w    yr400_y_uv
  bra.w    yr400__yuv
  bra.w    yr400___uv

  bra.w    yr400_yy_v
  bra.w    yr400_y__v
  bra.w    yr400__y_v
  bra.w    yr400____v

  bra.w    yr400_yyu_
  bra.w    yr400_y_u_
  bra.w    yr400__yu_
  bra.w    yr400___u_

  bra.w    yr400_yy__
  bra.w    yr400_y___
  bra.w    yr400__y__
*  bra.w    yr400_normal

yr400_normal

  move.l a6,d3
  add.l  #RGB_TBL+1024*2*6,d3
  bsr     yr401
  lea     -32*2+4*2(a3),a3

yr401
  moveq.l  #8*2,d4
  moveq.l  #4-1,d7
yr405
  moveq.l  #4-1,d6
yr410

    convm_v  (a3)+			#8+18+4*3=38
    conv_u   udata1-vdata1-2(a3)	#48
    adda.l  d3,a2			#8
    adda.l  d3,a5			#8
    adda.l  d3,a6			#8
    conv_y   (a1)+,(a0)+		#116
    conv_y2  8*2-4(a1),8*2-4(a0)	#124

    dbra    d6,yr410			#10
  addq.w  #4*2,a3
  add.l   d4,a1
  add.l   d4,a0
  dbra    d7,yr405
  rts
*
*
*
yr400____v

  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5			#4
  movea.l a2,a6			#4
  conv_V  (a3)			#40
  move.l  a5,d6			#4
  move.l  a6,d7			#4
  lea.l   udata1-vdata1(a3),a3

  bsr     yr401____v
  lea     -32*2+4*2(a3),a3

yr401____v
  moveq.l  #4-1,d4
yr405____v
  moveq.l  #4-1,d5
yr410____v

    move.l  d6,a5			#4
    move.l  d7,a6			#4

    conv_U   (a3)+
    conv_y   (a1)+,(a0)+		#116
    conv_y2  8*2-4(a1),8*2-4(a0)	#124

    dbra    d5,yr410____v
  addq.w  #4*2,a3
  lea.l   8*2(a1),a1
  lea.l   8*2(a0),a0
  dbra    d4,yr405____v
  rts
*
*
*
yr400___u_

  movea.l a6,a5
  adda.l  #RGB_TBL+1024*2*6,a5
  move.l  a5,d3
  movea.l a5,a6

    conv_U  udata1-vdata1(a3)

  move.l  a5,d6
  move.l  a6,d7

  bsr     yr401___u_
  lea     -32*2+4*2(a3),a3

yr401___u_
  moveq.l  #4-1,d4
yr405___u_
  moveq.l  #4-1,d5
yr410___u_

    convm_v   (a3)+			#38
    adda.l  d3,a2			#8
    adda.l  d6,a5			#8
    adda.l  d7,a6			#8
    conv_y   (a1)+,(a0)+		#116
    conv_y2  8*2-4(a1),8*2-4(a0)	#124

    dbra    d5,yr410___u_
  addq.w  #4*2,a3
  lea.l   8*2(a1),a1
  lea.l   8*2(a0),a0
  dbra    d4,yr405___u_
  rts
*
*
*
yr400___uv

  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6
  conv_u  udata1-vdata1(a3)
  conv_v  (a3)
  moveq.l #8-1,d4

yr405___uv
  moveq.l  #4-1,d5
yr410___uv
    conv_y  (a1)+,(a0)+			#116
    conv_y2 8*2-4(a1),8*2-4(a0)		#116
    dbra    d5,yr410___uv
  lea.l    8*2(a1),a1
  lea.l    8*2(a0),a0
  dbra    d4,yr405___uv
  rts
*
*
*
yr400__y__

  move.l a6,d3
  add.l  #RGB_TBL+1024*2*6,d3
  bsr     yr401__y__
  lea     -32*2+4*2(a3),a3
  bra     yr401
*
*
*
yr400__y_v

  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6
  conv_v  (a3)
  move.l  a5,d6
  move.l  a6,d7
  lea.l   udata1-vdata1(a3),a3

  bsr     yr401__y_v
  lea     -32*2+4*2(a3),a3
  bra     yr401____v
*
*
*
yr400__yu_

  movea.l a6,a5
  adda.l  #RGB_TBL+1024*2*6,a5
  move.l  a5,d3
  movea.l a5,a6

  conv_u  udata1-vdata1(a3)

  move.l  a5,d6
  move.l  a6,d7

  bsr     yr401__yu_
  lea     -32*2+4*2(a3),a3
  bra     yr401___u_
*
*
*
yr400__yuv

  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6

  conv_u  udata1-vdata1(a3)
  conv_v  (a3)
  bsr     yr401__yuv
  moveq.l #4-1,d4
  bra     yr405___uv

*
*
*
yr400_y___
  move.l a6,d3
  add.l  #RGB_TBL+1024*2*6,d3
  bsr     yr401
  lea     -32*2+4*2(a3),a3
yr401__y__
  move.w  (a1),d1
  ext.l   d1
  add.l  d1,d3
  moveq.l  #4-1,d7
yr405__y__
  moveq.l  #4-1,d6
yr410__y__

    convm_v   (a3)+			#38
    adda.l  d3,a2			#8
    adda.l  d3,a5			#8
    adda.l  d3,a6			#8
    conv_u   udata1-vdata1-2(a3)
    conv_cy  (a0)+
    conv_cy2 8*2-4(a0)
    dbra    d6,yr410__y__
  addq.w  #4*2,a3
  lea.l   8*2(a0),a0
  dbra    d7,yr405__y__
  lea.l   64*2(a1),a1
  sub.l  d1,d3
  rts
*
*
*
yr400_y__v
  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6
  conv_v  (a3)
  move.l  a2,d3
  move.l  a5,d6
  move.l  a6,d7
  lea.l   udata1-vdata1(a3),a3
  bsr     yr401____v
  lea     -32*2+4*2(a3),a3
yr401__y_v
  move.w  (a1),d1
  ext.l   d1
  add.l  d1,a2
  add.l  d1,d6
  add.l  d1,d7
  moveq.l  #4-1,d4
yr405__y_v
  moveq.l  #4-1,d5
yr410__y_v

    move.l  d6,a5			#4
    move.l  d7,a6			#4

    conv_u   (a3)+
    conv_cy  (a0)+
    conv_cy2 8*2-4(a0)

    dbra    d5,yr410__y_v
  addq.w  #4*2,a3
  lea.l   8*2(a0),a0
  dbra    d4,yr405__y_v
  lea.l   64*2(a1),a1
  sub.l  d1,a2
  sub.l  d1,d6
  sub.l  d1,d7
  rts
*
*
*
yr400_y_u_
  movea.l a6,a5
  adda.l  #RGB_TBL+1024*2*6,a5
  move.l  a5,d3
  movea.l a5,a6
  conv_u  udata1-vdata1(a3)
  move.l  a5,d6
  move.l  a6,d7
  bsr     yr401___u_
  lea     -32*2+4*2(a3),a3
yr401__yu_
  move.w  (a1),d1
  ext.l   d1
  add.l  d1,d3
  add.l  d1,d6
  add.l  d1,d7
  moveq.l  #4-1,d4
yr405__yu_
  moveq.l  #4-1,d5
yr410__yu_

    convm_v   (a3)+			#38
    adda.l  d3,a2			#8
    adda.l  d6,a5			#8
    adda.l  d7,a6			#8
    conv_cy  (a0)+
    conv_cy2 8*2-4(a0)

    dbra    d5,yr410__yu_
  addq.w  #4*2,a3
  lea.l   8*2(a0),a0
  dbra    d4,yr405__yu_
  lea.l   64*2(a1),a1
  sub.l  d1,d3
  sub.l  d1,d6
  sub.l  d1,d7
  rts
*
*
*
yr400_y_uv
  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6
  conv_u  udata1-vdata1(a3)
  conv_v  (a3)
  moveq.l #4-1,d4
  bsr     yr405___uv
yr401__yuv
  move.w  (a1),a4
  adda.l  a4,a2
  adda.l  a4,a5
  adda.l  a4,a6

  conv_cy3 d0,d4
  move.l  d0,d1
  move.l  d0,d2
  move.l  d0,d3
  move.l  d4,d5
  move.l  d4,d6
  move.l  d4,d7
  lea.l   64*2(a0),a0
  rept    4
  movem.l d0-d7,-(a0)
  endm
  lea.l   64*2(a0),a0
  lea.l   64*2(a1),a1
  suba.l  a4,a2
  suba.l  a4,a5
  suba.l  a4,a6
  rts
*
*
*
yr400_yy__
  move.l a6,d3
  add.l  #RGB_TBL+1024*2*6,d3
  bsr     yr401__y__
  lea     -32*2+4*2(a3),a3
  bra     yr401__y__
*
*
*
yr400_yy_v
  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6
  conv_v  (a3)
  move.l  a5,d6
  move.l  a6,d7
  lea.l   udata1-vdata1(a3),a3
  bsr     yr401__y_v
  lea     -32*2+4*2(a3),a3
  bra     yr401__y_v
*
*
*
yr400_yyu_
  movea.l a6,a5
  adda.l  #RGB_TBL+1024*2*6,a5
  move.l  a5,d3
  movea.l a5,a6
  conv_u  udata1-vdata1(a3)
  move.l  a5,d6
  move.l  a6,d7
  bsr     yr401__yu_
  lea     -32*2+4*2(a3),a3
  bra     yr401__yu_
*
*
*
yr400_yyuv
  movea.l a6,a2
  adda.l  #RGB_TBL+1024*2*6,a2
  movea.l a2,a5
  movea.l a2,a6
  conv_u  udata1-vdata1(a3)
  conv_v  (a3)

  lea.l   64*2*2(a0),a0

  move.w  64*2(a1),a4
  adda.l  a4,a2
  adda.l  a4,a5
  adda.l  a4,a6

  conv_cy3 d0,d4
  move.l  d0,d1
  move.l  d0,d2
  move.l  d0,d3
  move.l  d4,d5
  move.l  d4,d6
  move.l  d4,d7
  rept    4
  movem.l d0-d7,-(a0)
  endm
  suba.l  a4,a2
  suba.l  a4,a5
  suba.l  a4,a6

  move.w  (a1),a4
  adda.l  a4,a2
  adda.l  a4,a5
  adda.l  a4,a6

  conv_cy3 d0,d4
  move.l  d0,d1
  move.l  d0,d2
  move.l  d0,d3
  move.l  d4,d5
  move.l  d4,d6
  move.l  d4,d7
  rept    4
  movem.l d0-d7,-(a0)
  endm

  lea.l   64*2*2(a0),a0
*  lea.l   64*2*2(a1),a1
  rts
*
 
  .end
