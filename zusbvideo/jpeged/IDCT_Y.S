*
*  IDCT_Y.S
*
*  離散コサイン逆変換（Ｙ成分）
*
*
*
.include	work.inc
	.text
	.xdef	IDCT_Y
	.xref	IDCT_SU1,IDCT_SU2,IDCT_SU3,IDCT_SU4,IDCT_SU5,IDCT_SU6,IDCT_SU7,IDCT_SU8
	.xref   IDCT_3_2
	.xref	IDCT_SU3_16,IDCT_SU4_16,IDCT_SU5_16
	.xref	COS_TBL_adrs
*
*  Inverse Digital Cosine Transformation
*
*     suv(w),sxy(w)...a0
*     sxy 256階調 data
*
*  入力
*	d0...ジグザグスキャンで最後から連続している０の数
*  出力
*	a0...次のdata
*
IDCT_Y

	move.w	IDCT_TBL(pc,d0.w),d0
	jmp	IDCT_Y(pc,d0.w)

IDCT_TBL	dc.w	IDCT_64-IDCT_Y
		dc.w	IDCT_63-IDCT_Y
		dc.w	IDCT_62-IDCT_Y
		dc.w	IDCT_61-IDCT_Y
		dc.w	IDCT_60-IDCT_Y
		dc.w	IDCT_59-IDCT_Y
		dc.w	IDCT_58-IDCT_Y
		dc.w	IDCT_57-IDCT_Y
		dc.w	IDCT_56-IDCT_Y
		dc.w	IDCT_55-IDCT_Y
		dc.w	IDCT_54-IDCT_Y
		dc.w	IDCT_53-IDCT_Y
		dc.w	IDCT_52-IDCT_Y
		dc.w	IDCT_51-IDCT_Y
		dc.w	IDCT_50-IDCT_Y
		dc.w	IDCT_49-IDCT_Y
		dc.w	IDCT_48-IDCT_Y
		dc.w	IDCT_47-IDCT_Y
		dc.w	IDCT_46-IDCT_Y
		dc.w	IDCT_45-IDCT_Y
		dc.w	IDCT_44-IDCT_Y
		dc.w	IDCT_43-IDCT_Y
		dc.w	IDCT_42-IDCT_Y
		dc.w	IDCT_41-IDCT_Y
		dc.w	IDCT_40-IDCT_Y
		dc.w	IDCT_39-IDCT_Y
		dc.w	IDCT_38-IDCT_Y
		dc.w	IDCT_37-IDCT_Y
		dc.w	IDCT_36-IDCT_Y
		dc.w	IDCT_35-IDCT_Y
		dc.w	IDCT_34-IDCT_Y
		dc.w	IDCT_33-IDCT_Y
		dc.w	IDCT_32-IDCT_Y
		dc.w	IDCT_31-IDCT_Y
		dc.w	IDCT_30-IDCT_Y
		dc.w	IDCT_29-IDCT_Y
		dc.w	IDCT_28-IDCT_Y
		dc.w	IDCT_27-IDCT_Y
		dc.w	IDCT_26-IDCT_Y
		dc.w	IDCT_25-IDCT_Y
		dc.w	IDCT_24-IDCT_Y
		dc.w	IDCT_23-IDCT_Y
		dc.w	IDCT_22-IDCT_Y
		dc.w	IDCT_21-IDCT_Y
		dc.w	IDCT_20-IDCT_Y
		dc.w	IDCT_19-IDCT_Y
		dc.w	IDCT_18-IDCT_Y
		dc.w	IDCT_17-IDCT_Y
		dc.w	IDCT_16-IDCT_Y
		dc.w	IDCT_15-IDCT_Y
		dc.w	IDCT_14-IDCT_Y
		dc.w	IDCT_13-IDCT_Y
		dc.w	IDCT_12-IDCT_Y
		dc.w	IDCT_11-IDCT_Y
		dc.w	IDCT_10-IDCT_Y
		dc.w	IDCT_9-IDCT_Y
		dc.w	IDCT_8-IDCT_Y
		dc.w	IDCT_7-IDCT_Y
		dc.w	IDCT_6-IDCT_Y
		dc.w	IDCT_5-IDCT_Y
		dc.w	IDCT_4-IDCT_Y
		dc.w	IDCT_3-IDCT_Y
		dc.w	IDCT_2-IDCT_Y
		dc.w	IDCT_1-IDCT_Y
*
*  S'(y,u)
*

IDCT_1
        move.w  7*8*2+1*2(a0),0*8*2(a0)
	rts

IDCT_2

      movea.w 5*8*2+1*2(a0),a1
      adda.l  a6,a1
      move.w  7*8*2+1*2(a0),d5

      move.w  (a1)+,d1		COS1
      move.w  (a1)+,d0		COS3
      move.w  (a1)+,d3		COS5
      move.w  (a1),d2		COS7

      move.w  d5,d4
      move.w  d4,d7
      move.w  d5,d6

      sub.w   d1,d6	   * S(7,y) = d4-d1
      add.w   d1,d1
      add.w   d6,d1        * S(0,y) = d4+d1 = d4-d1 + 2*d1 = S(7,y) + 2*d1

      sub.w   d2,d5        * S(4,y) = d4-d2
      add.w   d2,d2
      add.w   d5,d2        * S(3,y) = d4+d2 = d4-d2 + 2*d2 = S(4,y) +2*d2

      sub.w   d0,d7        * S(6,y) = d4-d0
      add.w   d0,d0
      add.w   d7,d0        * S(1,y) = d4+d0 = d4-d0 + 2*d0 = S(6,y) + 2*d0

      sub.w   d3,d4        * S(5,y) = d4-d3
      add.w   d3,d3
      add.w   d4,d3        * S(2,y) = d4+d3 = d4-d3 + 2*d3 = S(5,y) +2*d3

      lea.l    8*8*2(a0),a0
      movem.w  d0-d7,-(a0)
      movem.w  d0-d7,-(a0)
      movem.w  d0-d7,-(a0)
      movem.w  d0-d7,-(a0)

      movem.w  d0-d7,-(a0)
      movem.w  d0-d7,-(a0)
      movem.w  d0-d7,-(a0)
      movem.w  d0-d7,-(a0)
      rts

IDCT_3

  tst.w   5*8*2+1*2(a0)
  beq     IDCT_3_1

	lea	-(64*2-2*2)(sp),sp
	lea.l	7*16(a0),a0
	move.w	-2*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2

IDCT_3_1
	movea.w	7*8*2+2*2(a0),a1
	move.w	7*8*2+1*2(a0),d5
	bra	IDCT_3_2

IDCT_4
	lea	-(64*2-2*2)(sp),sp
	lea.l	7*16(a0),a0
	move.w	-2*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_clr6_SU1-*-2

IDCT_5
	lea	-(64*2-2*2)(sp),sp
	lea.l	5*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3_16-*-2
	dc.w	IDCT_clr6-*-2


IDCT_6
	lea	-(64*2-3*2)(sp),sp
	lea.l	4*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU1
@@	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU3_16-*-2
	dc.w	IDCT_clr5-*-2


IDCT_7
	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU1

IDCT_8
	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU3_16-*-2
	dc.w	IDCT_clr4_SU1-*-2

IDCT_9
	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU3_16-*-2
	dc.w	IDCT_clr4_SU1-*-2

IDCT_10
	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4_16-*-2
	dc.w	IDCT_clr4_SU1-*-2

IDCT_11
	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5_16-*-2
	dc.w	IDCT_clr4_SU1-*-2

IDCT_12
	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2

IDCT_13
	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5_16-*-2
	dc.w	IDCT_clr4_SU1-*-2

IDCT_14
	lea	-(64*2-4*2)(sp),sp
	lea.l	3*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5_16-*-2
	dc.w	IDCT_clr4-*-2

IDCT_15
	lea	-(64*2-5*2)(sp),sp
	lea.l	3*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU1-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_clr3-*-2

IDCT_16
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU1-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_17
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_18
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_19
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_20
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_21
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_22
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_23
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_24
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_25
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU4
@@	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_26
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU4
@@	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_27
	lea	-(64*2-6*2)(sp),sp
	lea.l	2*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_clr2-*-2

IDCT_28
	lea	-(64*2-7*2)(sp),sp
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU1
@@	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_clr1-*-2

IDCT_29
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU1

IDCT_30
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_31
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_32
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_33
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_34
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_35
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_36
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_37
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_38
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_39
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_40
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_41
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_42
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	1*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_43
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU2

IDCT_44
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_45
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_46
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_47
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_48
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_49
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_50
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_51
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_52
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_53
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU3

IDCT_54
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU4

IDCT_55
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU5
@@	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_56
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU5
@@	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_57
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU5
@@	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_58
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU5
@@	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_59
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU5
@@	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_60
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU5

IDCT_61
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU6

IDCT_62
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU7
@@	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2


IDCT_63
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU7

IDCT_64
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU8
@@	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_normal
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00
    swap.w  d7

    movem.w (sp)+,d4-d6/a1-a5

    adda.l a6,a1
    adda.l a6,a2
    adda.l a6,a3
    adda.l a6,a4
    adda.l a6,a5

    movem.w (a6,d6.w),d0-d3
    exg.l   d0,d1	d1=COS1,d0=COS3
    exg.l   d2,d3	d3=COS5,d2=COS7

    sub.w   (a2)+,d3
    add.w   (a2)+,d1
    sub.w   (a2)+,d2
    sub.w   (a2),d0

    sub.w   (a3)+,d0
    add.w   (a3)+,d2
    add.w   (a3)+,d1
    add.w   (a3),d3

    sub.w   (a5)+,d2  * d2 = S1*cos7+S3*cos5+S5*cos3+S7*cos1
    add.w   (a5)+,d3  * d3 = S1*cos5-S3*cos1+S5*cos7+S7*cos3
    sub.w   (a5)+,d0  * d0 = S1*cos3-S3*cos7-S5*cos1-S7*cos5
    add.w   (a5),d1  * d1 = S1*cos1+S3*cos3+S5*cos5+S7*cos7

    move.w  -(a1),d6	COS2
    move.w  -(a1),d7	COS6
    sub.w   -(a4),d7	* d7 =S2*cos6+S6*cos2
    add.w   -(a4),d6	* d6 =S2*cos2+S6*cos6

    sub.w   d5,d4  * d4=s0-s4
    add.w   d5,d5
    add.w   d4,d5  * d5=s0+s4
*
    sub.w   d7,d4	* d4=d4-d7
    add.w   d7,d7
    add.w   d4,d7	* d7=d4+d7
*
    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(1,y),S(6,y)
*
    sub.w   d0,d7	S(6,y)
    add.w   d0,d0
    add.w   d7,d0	S(1,y)
*
*  S(0,y),S(7,y)
*
    sub.w   d1,d6	S(7,y)
    add.w   d1,d1
    add.w   d6,d1	S(0,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d2,d5	   S(4,y)
    add.w   d2,d2
    add.w   d5,d2	   S(3,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d3,d4	S(5,y)
    add.w   d3,d3
    add.w   d4,d3	S(2,y)
    movem.w d0-d7,-(a0)		store S(1,y),S(0,y),S(3,y),S(2,y),S(5,y),S(4,y),S(7,y),S(6,y)
*
    swap.w  d7
    dbra    d7,sy00
*
  rts


IDCT_normal_SU1
*
*  S(x,y)
*
  move.w  7*2(sp),d0
  beq     IDCT_clr1

  move.w  d0,a5
  adda.l  a6,a5
  moveq   #8-1,d7
sy00_SU1
    swap.w  d7

    movem.w (sp)+,d4-d6/a1-a4
    addq.l  #2,sp

    adda.l a6,a1
    adda.l a6,a2
    adda.l a6,a3
    adda.l a6,a4

    movem.w (a6,d6.w),d0-d3
    exg.l   d0,d1	d1=COS1,d0=COS3
    exg.l   d2,d3	d3=COS5,d2=COS7

    sub.w   (a2)+,d3
    add.w   (a2)+,d1
    sub.w   (a2)+,d2
    sub.w   (a2),d0

    sub.w   (a3)+,d0
    add.w   (a3)+,d2
    add.w   (a3)+,d1
    add.w   (a3),d3

    sub.w   (a5)+,d2  * d2 = S1*cos7+S3*cos5+S5*cos3+S7*cos1
    add.w   (a5)+,d3  * d3 = S1*cos5-S3*cos1+S5*cos7+S7*cos3
    sub.w   (a5)+,d0  * d0 = S1*cos3-S3*cos7-S5*cos1-S7*cos5
    add.w   (a5),d1  * d1 = S1*cos1+S3*cos3+S5*cos5+S7*cos7
    subq.w  #3*2,a5

    move.w  -(a1),d6	COS2
    move.w  -(a1),d7	COS6
    sub.w   -(a4),d7	* d7 =S2*cos6+S6*cos2
    add.w   -(a4),d6	* d6 =S2*cos2+S6*cos6

    sub.w   d5,d4  * d4=s0-s4
    add.w   d5,d5
    add.w   d4,d5  * d5=s0+s4
*
    sub.w   d7,d4	* d4=d4-d7
    add.w   d7,d7
    add.w   d4,d7	* d7=d4+d7
*
    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(1,y),S(6,y)
*
    sub.w   d0,d7	S(6,y)
    add.w   d0,d0
    add.w   d7,d0	S(1,y)
*
*  S(0,y),S(7,y)
*
    sub.w   d1,d6	S(7,y)
    add.w   d1,d1
    add.w   d6,d1	S(0,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d2,d5	   S(4,y)
    add.w   d2,d2
    add.w   d5,d2	   S(3,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d3,d4	S(5,y)
    add.w   d3,d3
    add.w   d4,d3	S(2,y)
    movem.w d0-d7,-(a0)		store S(1,y),S(0,y),S(3,y),S(2,y),S(5,y),S(4,y),S(7,y),S(6,y)
*
    swap.w  d7
    dbra    d7,sy00_SU1
*
  rts

IDCT_clr1
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr1
    swap.w  d7

    movem.w (sp)+,d4-d5/a1-a5
    addq.w  #1*2,sp

    adda.l  a6,a1
    adda.l  a6,a2
    adda.l  a6,a3
    adda.l  a6,a4
    adda.l  a6,a5

    move.w  (a1)+,d1	COS1
    move.w  (a1)+,d0	COS3
    move.w  (a1)+,d3	COS5
    move.w  (a1),d2	COS7

    sub.w   (a3)+,d3
    add.w   (a3)+,d1
    sub.w   (a3)+,d2
    sub.w   (a3),d0

    sub.w   (a4)+,d0
    add.w   (a4)+,d2
    add.w   (a4)+,d1
    add.w   (a4),d3

    move.w  -(a2),d6	COS2
    move.w  -(a2),d7	COS6
    sub.w   -(a5),d7	* d7 =S2*cos6+S6*cos2
    add.w   -(a5),d6	* d6 =S2*cos2+S6*cos6

    sub.w   d5,d4  * d4=s0-s4
    add.w   d5,d5
    add.w   d4,d5  * d5=s0+s4
*
    sub.w   d7,d4	* d4=d4-d7
    add.w   d7,d7
    add.w   d4,d7	* d7=d4+d7
*
    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(1,y),S(6,y)
*
    sub.w   d0,d7	S(6,y)
    add.w   d0,d0
    add.w   d7,d0	S(1,y)
*
*  S(0,y),S(7,y)
*
    sub.w   d1,d6	S(7,y)
    add.w   d1,d1
    add.w   d6,d1	S(0,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d2,d5	   S(4,y)
    add.w   d2,d2
    add.w   d5,d2	   S(3,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d3,d4	S(5,y)
    add.w   d3,d3
    add.w   d4,d3	S(2,y)
    movem.w d0-d7,-(a0)		store S(1,y),S(0,y),S(3,y),S(2,y),S(5,y),S(4,y),S(7,y),S(6,y)
*
    swap.w  d7
    dbra    d7,sy00_clr1
*
  rts




IDCT_clr2
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr2

    movem.w (sp)+,d4-d5/a1-a4
    addq.l  #2*2,sp

    adda.l  a6,a1
    adda.l  a6,a2
    adda.l  a6,a3
    adda.l  a6,a4

    move.w  (a1)+,d1	COS1
    move.w  (a1)+,d0	COS3
    move.w  (a1)+,d3	COS5
    move.w  (a1),d2	COS7

    sub.w   (a3)+,d3
    add.w   (a3)+,d1
    sub.w   (a3)+,d2
    sub.w   (a3),d0

    sub.w   (a4)+,d0
    add.w   (a4)+,d2
    add.w   (a4)+,d1
    add.w   (a4),d3

    move.w  -(a2),d6	COS2
    move.w  -(a2),a1	COS6

    sub.w   d5,d4  * d4=s0-s4
    add.w   d5,d5
    add.w   d4,d5  * d5=s0+s4
*
    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1
*
    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(1,y),S(6,y)
*
    sub.l   d0,a1	S(6,y)
    add.w   d0,d0
    add.w   a1,d0	S(1,y)
*
*  S(0,y),S(7,y)
*
    sub.w   d1,d6	S(7,y)
    add.w   d1,d1
    add.w   d6,d1	S(0,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d2,d5	   S(4,y)
    add.w   d2,d2
    add.w   d5,d2	   S(3,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d3,d4	S(5,y)
    add.w   d3,d3
    add.w   d4,d3	S(2,y)
    movem.w d0-d6/a1,-(a0)		store S(1,y),S(0,y),S(3,y),S(2,y),S(5,y),S(4,y),S(7,y),S(6,y)
*
    dbra    d7,sy00_clr2
*
  rts



IDCT_clr2_SU1
*
*  S(x,y)
*
  move.w  5*2(sp),d0
  beq	  IDCT_clr3

  movea.w d0,a4
  adda.l  a6,a4
  moveq   #8-1,d7
sy00_clr2_SU1

    movem.w (sp)+,d4-d5/a1-a3
    addq.w  #3*2,sp

    adda.l  a6,a1
    adda.l  a6,a2
    adda.l  a6,a3

    move.w  (a1)+,d1	COS1
    move.w  (a1)+,d0	COS3
    move.w  (a1)+,d3	COS5
    move.w  (a1),d2	COS7

    sub.w   (a3)+,d3
    add.w   (a3)+,d1
    sub.w   (a3)+,d2
    sub.w   (a3),d0

    sub.w   (a4)+,d0
    add.w   (a4)+,d2
    add.w   (a4)+,d1
    add.w   (a4),d3
    subq.w  #3*2,a4

    move.w  -(a2),d6	COS2
    move.w  -(a2),a1	COS6

    sub.w   d5,d4  * d4=s0-s4
    add.w   d5,d5
    add.w   d4,d5  * d5=s0+s4
*
    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1
*
    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(1,y),S(6,y)
*
    sub.l   d0,a1	S(6,y)
    add.w   d0,d0
    add.w   a1,d0	S(1,y)
*
*  S(0,y),S(7,y)
*
    sub.w   d1,d6	S(7,y)
    add.w   d1,d1
    add.w   d6,d1	S(0,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d2,d5	   S(4,y)
    add.w   d2,d2
    add.w   d5,d2	   S(3,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d3,d4	S(5,y)
    add.w   d3,d3
    add.w   d4,d3	S(2,y)
    movem.w d0-d6/a1,-(a0)		store S(1,y),S(0,y),S(3,y),S(2,y),S(5,y),S(4,y),S(7,y),S(6,y)
*
    dbra    d7,sy00_clr2_SU1
*
  rts


IDCT_clr3
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr3

    movem.w (sp)+,d4-d5/a1-a3
    addq.l  #3*2,sp

    adda.l  a6,a1
    adda.l  a6,a2
    adda.l  a6,a3

    move.w  (a1)+,d1	COS1
    move.w  (a1)+,d0	COS3
    move.w  (a1)+,d3	COS5
    move.w  (a1),d2	COS7

    sub.w   (a3)+,d3
    add.w   (a3)+,d1
    sub.w   (a3)+,d2
    sub.w   (a3),d0

    move.w  -(a2),d6	COS2
    move.w  -(a2),a1	COS6

    sub.w   d5,d4  * d4=s0-s4
    add.w   d5,d5
    add.w   d4,d5  * d5=s0+s4
*
    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1
*
    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(1,y),S(6,y)
*
    sub.l   d0,a1	S(6,y)
    add.w   d0,d0
    add.w   a1,d0	S(1,y)
*
*  S(0,y),S(7,y)
*
    sub.w   d1,d6	S(7,y)
    add.w   d1,d1
    add.w   d6,d1	S(0,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d2,d5	   S(4,y)
    add.w   d2,d2
    add.w   d5,d2	   S(3,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d3,d4	S(5,y)
    add.w   d3,d3
    add.w   d4,d3	S(2,y)
    movem.w d0-d6/a1,-(a0)		store S(1,y),S(0,y),S(3,y),S(2,y),S(5,y),S(4,y),S(7,y),S(6,y)
*
    dbra    d7,sy00_clr3
*
  rts


IDCT_clr4
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr4

    movem.w (sp)+,d4/a1-a3
    addq.w  #4*2,sp

    adda.l  a6,a1
    adda.l  a6,a2
    adda.l  a6,a3

    move.w  (a1)+,d1	COS1
    move.w  (a1)+,d0	COS3
    move.w  (a1)+,d3	COS5
    move.w  (a1),d2	COS7

    sub.w   (a3)+,d3
    add.w   (a3)+,d1
    sub.w   (a3)+,d2
    sub.w   (a3),d0

    move.w  -(a2),d6	COS2
    move.w  -(a2),a1	COS6

    move.w  d4,d5
*
    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1
*
    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(1,y),S(6,y)
*
    sub.l   d0,a1	S(6,y)
    add.w   d0,d0
    add.w   a1,d0	S(1,y)
*
*  S(0,y),S(7,y)
*
    sub.w   d1,d6	S(7,y)
    add.w   d1,d1
    add.w   d6,d1	S(0,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d2,d5	   S(4,y)
    add.w   d2,d2
    add.w   d5,d2	   S(3,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d3,d4	S(5,y)
    add.w   d3,d3
    add.w   d4,d3	S(2,y)
    movem.w d0-d6/a1,-(a0)		store S(1,y),S(0,y),S(3,y),S(2,y),S(5,y),S(4,y),S(7,y),S(6,y)
*
    dbra    d7,sy00_clr4
*
  rts


IDCT_clr4_SU1
*
*  S(x,y)
*
  move.w  2*3(sp),d0
  beq     IDCT_clr5

  movea.w d0,a3
  adda.l  a6,a3
  moveq   #8-1,d7
sy00_clr4_SU1

    movem.w (sp)+,d5/a1-a2
    lea.l   5*2(sp),sp

    adda.l  a6,a1
    adda.l  a6,a2

    move.w  (a1)+,d1	COS1
    move.w  (a1)+,d0	COS3
    move.w  (a1)+,d3	COS5
    move.w  (a1),d2	COS7

    sub.w   (a3)+,d3
    add.w   (a3)+,d1
    sub.w   (a3)+,d2
    sub.w   (a3),d0
    subq.w  #3*2,a3

    move.w  -(a2),d6	COS2
    move.w  -(a2),a1	COS6

    move.w  d5,d4
*
    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1
*
    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(1,y),S(6,y)
*
    sub.l   d0,a1	S(6,y)
    add.w   d0,d0
    add.w   a1,d0	S(1,y)
*
*  S(0,y),S(7,y)
*
    sub.w   d1,d6	S(7,y)
    add.w   d1,d1
    add.w   d6,d1	S(0,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d2,d5	   S(4,y)
    add.w   d2,d2
    add.w   d5,d2	   S(3,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d3,d4	S(5,y)
    add.w   d3,d3
    add.w   d4,d3	S(2,y)
    movem.w d0-d6/a1,-(a0)		store S(1,y),S(0,y),S(3,y),S(2,y),S(5,y),S(4,y),S(7,y),S(6,y)
*
    dbra    d7,sy00_clr4_SU1
*
  rts


IDCT_clr5
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr5

    movem.w (sp)+,d4/a1-a2
    lea.l   5*2(sp),sp

    adda.l  a6,a1
    adda.l  a6,a2

    move.w  (a1)+,d1	COS1
    move.w  (a1)+,d0	COS3
    move.w  (a1)+,d3	COS5
    move.w  (a1),d2	COS7

    move.w  -(a2),d6	COS2
    move.w  -(a2),a1	COS6

    move.w  d4,d5
*
    sub.w   a1,d4	* d4=d4-a2
    add.l   a1,a1
    add.l   d4,a1	* a2=d4+a2
*
    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(1,y),S(6,y)
*
    sub.l   d0,a1	S(6,y)
    add.w   d0,d0
    add.w   a1,d0	S(1,y)
*
*  S(0,y),S(7,y)
*
    sub.w   d1,d6	S(7,y)
    add.w   d1,d1
    add.w   d6,d1	S(0,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d2,d5	   S(4,y)
    add.w   d2,d2
    add.w   d5,d2	   S(3,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d3,d4	S(5,y)
    add.w   d3,d3
    add.w   d4,d3	S(2,y)
    movem.w d0-d6/a1,-(a0)		store S(1,y),S(0,y),S(3,y),S(2,y),S(5,y),S(4,y),S(7,y),S(6,y)
*
    dbra    d7,sy00_clr5
*
  rts


IDCT_clr6
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr6

    move.w  (sp)+,d4
    movea.w (sp)+,a1
    lea.l   6*2(sp),sp

    adda.l  a6,a1

    move.w  (a1)+,d1	COS1
    move.w  (a1)+,d0	COS3
    move.w  (a1)+,d3	COS5
    move.w  (a1),d2	COS7

    move.w  d4,d5
    move.w  d4,a4
    move.w  d5,d6
*
*  S(1,y),S(6,y)
*
    sub.l   d0,a4	S(6,y)
    add.w   d0,d0
    add.w   a4,d0	S(1,y)
*
*  S(0,y),S(7,y)
*
    sub.w   d1,d6	S(7,y)
    add.w   d1,d1
    add.w   d6,d1	S(0,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d2,d5	   S(4,y)
    add.w   d2,d2
    add.w   d5,d2	   S(3,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d3,d4	S(5,y)
    add.w   d3,d3
    add.w   d4,d3	S(2,y)
    movem.w d0-d6/a4,-(a0)		store S(1,y),S(0,y),S(3,y),S(2,y),S(5,y),S(4,y),S(7,y),S(6,y)
*
    dbra    d7,sy00_clr6
*
  rts



IDCT_clr6_SU1
*
*  S(x,y)
*
  movea.w 2(sp),a3
  movem.w (a6,a3.w),a1-a4

  moveq   #8-1,d7
sy00_clr6_SU1

    move.w  (sp)+,d0
    lea.l   2*7(sp),sp

    move.w  d0,d1
    move.w  d0,d2
    move.w  d0,d3
    move.w  d0,d4
    move.w  d0,d5
    move.w  d0,d6
    move.w  d0,a5
*
    sub.l   a2,a5	S(6,y)
    add.w   a2,d0	S(1,y)
*
    sub.w   a1,d6	S(7,y)
    add.w   a1,d1	S(0,y)
*
    sub.w   a4,d5	S(4,y)
    add.w   a4,d2	S(3,y)
*
    sub.w   a3,d4	S(5,y)
    add.w   a3,d3	S(2,y)

    movem.w d0-d6/a5,-(a0)	store S(1,y),S(0,y),S(3,y),S(2,y),S(5,y),S(4,y),S(7,y),S(6,y)
*
    dbra    d7,sy00_clr6_SU1
*
  rts

 .end
