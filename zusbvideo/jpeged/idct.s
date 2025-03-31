*
*  IDCT.S
*
*  離散コサイン逆変換
*
*  c0=1
*  c1=COS(pi*1/16)*sqr(2)
*  c2=COS(pi*2/16)*sqr(2)
*  c3=COS(pi*3/16)*sqr(2)
*  c4=1
*  c5=COS(pi*5/16)*sqr(2)
*  c6=COS(pi*6/16)*sqr(2)
*  c7=COS(pi*7/16)*sqr(2)
*
*     x=   0   1   2   3   4   5   6   7
*  u=0 :  c0  c0  c0  c0  c0  c0  c0  c0
*  u=1 :  c1  c3  c5  c7 -c7 -c5 -c3 -c1
*  u=2 :  c2  c6 -c6 -c2 -c2 -c6  c6  c2
*  u=3 :  c3 -c7 -c1 -c5  c5  c1  c7 -c3
*  u=4 :  c4 -c4 -c4  c4  c4 -c4 -c4  c4
*  u=5 :  c5 -c1  c7  c3 -c3 -c7  c1 -c5
*  u=6 :  c6 -c2  c2 -c6 -c6  c2 -c2  c6
*  u=7 :  c7 -c5  c3 -c1  c1 -c3  c5 -c7
*
.include	work.inc
	.text
	.xdef	IDCT
	.xdef	IDCT_SU1,IDCT_SU2,IDCT_SU3,IDCT_SU4,IDCT_SU5,IDCT_SU6,IDCT_SU7,IDCT_SU8
	.xdef   IDCT_3_2
*
*  Inverse Digital Cosine Transformation
*
*     suv(w),sxy(w)...a0-8*2
*     sxy 256階調 data
*
*  入力
*	d0...ジグザグスキャンで最後から連続している０の数
*  出力
*	a0...次のdata
*
IDCT

	move.w	IDCT_TBL(pc,d0.w),d0
	jmp	IDCT(pc,d0.w)

IDCT_TBL	dc.w	IDCT_64-IDCT
		dc.w	IDCT_63-IDCT
		dc.w	IDCT_62-IDCT
		dc.w	IDCT_61-IDCT
		dc.w	IDCT_60-IDCT
		dc.w	IDCT_59-IDCT
		dc.w	IDCT_58-IDCT
		dc.w	IDCT_57-IDCT
		dc.w	IDCT_56-IDCT
		dc.w	IDCT_55-IDCT
		dc.w	IDCT_54-IDCT
		dc.w	IDCT_53-IDCT
		dc.w	IDCT_52-IDCT
		dc.w	IDCT_51-IDCT
		dc.w	IDCT_50-IDCT
		dc.w	IDCT_49-IDCT
		dc.w	IDCT_48-IDCT
		dc.w	IDCT_47-IDCT
		dc.w	IDCT_46-IDCT
		dc.w	IDCT_45-IDCT
		dc.w	IDCT_44-IDCT
		dc.w	IDCT_43-IDCT
		dc.w	IDCT_42-IDCT
		dc.w	IDCT_41-IDCT
		dc.w	IDCT_40-IDCT
		dc.w	IDCT_39-IDCT
		dc.w	IDCT_38-IDCT
		dc.w	IDCT_37-IDCT
		dc.w	IDCT_36-IDCT
		dc.w	IDCT_35-IDCT
		dc.w	IDCT_34-IDCT
		dc.w	IDCT_33-IDCT
		dc.w	IDCT_32-IDCT
		dc.w	IDCT_31-IDCT
		dc.w	IDCT_30-IDCT
		dc.w	IDCT_29-IDCT
		dc.w	IDCT_28-IDCT
		dc.w	IDCT_27-IDCT
		dc.w	IDCT_26-IDCT
		dc.w	IDCT_25-IDCT
		dc.w	IDCT_24-IDCT
		dc.w	IDCT_23-IDCT
		dc.w	IDCT_22-IDCT
		dc.w	IDCT_21-IDCT
		dc.w	IDCT_20-IDCT
		dc.w	IDCT_19-IDCT
		dc.w	IDCT_18-IDCT
		dc.w	IDCT_17-IDCT
		dc.w	IDCT_16-IDCT
		dc.w	IDCT_15-IDCT
		dc.w	IDCT_14-IDCT
		dc.w	IDCT_13-IDCT
		dc.w	IDCT_12-IDCT
		dc.w	IDCT_11-IDCT
		dc.w	IDCT_10-IDCT
		dc.w	IDCT_9-IDCT
		dc.w	IDCT_8-IDCT
		dc.w	IDCT_7-IDCT
		dc.w	IDCT_6-IDCT
		dc.w	IDCT_5-IDCT
		dc.w	IDCT_4-IDCT
		dc.w	IDCT_3-IDCT
		dc.w	IDCT_2-IDCT
		dc.w	IDCT_1-IDCT
*
*  S'(y,u)
*
****************************
* x0000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
****************************
IDCT_1
      move.w  6*8*2+1*2(a0),d0
      move.w  d0,0*8*2(a0)
      move.w  d0,4*8*2(a0)
      rts

****************************
* xx000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
****************************
IDCT_2

      movea.w 5*8*2+1*2(a0),a1
      move.w  6*8*2+1*2(a0),d5

      movem.w  (a6,a1.w),d0-d3	COS1,COS3,COS5,COS7

      move.w  d5,d4
      move.w  d4,d7
      move.w  d5,d6

      sub.w   d1,d6        * S(6,y) = d5-d1
      add.w   d1,d1
      add.w   d6,d1        * S(1,y) = d5+d1 = d5-d1 + 2*d1 = S(6,y) + 2*d1

      sub.w   d2,d5        * S(5,y) = d5-d2
      add.w   d2,d2
      add.w   d5,d2        * S(2,y) = d5+d2 = d5-d2 + 2*d2 = S(5,y) +2*d2

      sub.w   d0,d7	   * S(7,y) = d5-d0
      add.w   d0,d0
      add.w   d7,d0        * S(0,y) = d5+d0 = d5-d0 + 2*d0 = S(7,y) + 2*d0

      sub.w   d3,d4        * S(4,y) = d5-d3
      add.w   d3,d3
      add.w   d4,d3        * S(3,y) = d5+d3 = d5-d3 + 2*d3 = S(4,y) +2*d3

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

****************************
* xx000000
* x0000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
****************************
IDCT_3

  tst.w   5*8*2+1*2(a0)
  beq     IDCT_3_1

	lea	-(64*2-2*2)(sp),sp
	lea.l	6*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)
	lea.l	@f(pc),a5
	bra	IDCT_SU2

****************************
* x0000000
* x0000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
****************************
IDCT_3_1

  movea.w 6*8*2+2*2(a0),a1
  move.w  6*8*2+1*2(a0),d5

IDCT_3_2

      movem.w (a6,a1.w),d0-d3	COS1

      move.w  d5,d4
      move.w  d4,d7
      move.w  d5,d6

      sub.w   d0,d7	* S'(u,7) = d5-d0
      add.w   d0,d0
      add.w   d7,d0	* S'(u,0) = d5+d0 = d5-d0 +2*d0 = S'(u,7) + 2*d0

      sub.w   d1,d6	* S'(u,6) = d5-d4
      add.w   d1,d1
      add.w   d6,d1	* S'(u,1) = d5+d4 = d5-d4 + 2*d4 = S'(u,6) + 2*d4

      sub.w   d2,d5	* S'(u,5) = d5-d4
      add.w   d2,d2
      add.w   d5,d2	* S'(u,2) = d5+d4 = d5-d4 + 2*d4 = S'(u,5) + 2*d4

      sub.w   d3,d4	* S'(u,4) = d5-d3
      add.w   d3,d3
      add.w   d4,d3	* S'(u,3) = d5+d3 = d5-d3 + 2*d3 = S'(u,4) + 2*d3

      move.w  d0,a2
      swap.w  d0
      move.w  a2,d0
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+

      move.w  d1,d0
      swap.w  d0
      move.w  d1,d0
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+

      move.w  d2,d0
      swap.w  d0
      move.w  d2,d0
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+

      move.w  d3,d0
      swap.w  d0
      move.w  d3,d0
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+

      move.w  d4,d0
      swap.w  d0
      move.w  d4,d0
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+

      move.w  d5,d0
      swap.w  d0
      move.w  d5,d0
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+

      move.w  d6,d0
      swap.w  d0
      move.w  d6,d0
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+

      move.w  d7,d0
      swap.w  d0
      move.w  d7,d0
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+
      move.l  d0,(a0)+
	lea	-8*8*2(a0),a0
      rts


****************************
* xx000000
* x0000000
* x0000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
****************************
IDCT_4
	lea	-(64*2-2*2)(sp),sp
	lea	6*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)
	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@
dehehe
	dc.w	IDCT_clr6_SU1-*-2


****************************
* xx000000
* xx000000
* x0000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
****************************
IDCT_5

	lea	-(64*2-2*2)(sp),sp
	lea.l	5*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_clr6-*-2

****************************
* xxx00000
* xx000000
* x0000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
****************************
IDCT_6

	lea	-(64*2-3*2)(sp),sp
	lea	5*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_clr5_SU1-*-2

****************************
* xxxx0000
* xx000000
* x0000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
****************************
IDCT_7

	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU1

****************************
* xxxx0000
* xxx00000
* x0000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
****************************
IDCT_8

	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_clr4_SU1-*-2
****************************
* xxxx0000
* xxx00000
* xx000000
* 00000000
* 00000000
* 00000000
* 00000000
* 00000000
****************************
IDCT_9

	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_clr4_SU1-*-2

****************************
* xxxx0000
* xxx00000
* xx000000
* x0000000
* 00000000
* 00000000
* 00000000
* 00000000
****************************
IDCT_10

	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_clr4_SU1-*-2



IDCT_11
	lea	-(64*2-4*2)(sp),sp
	lea.l	4*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
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
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_clr4_SU1-*-2


IDCT_14
	lea	-(64*2-4*2)(sp),sp
	lea.l	3*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_clr4-*-2


IDCT_15
	lea	-(64*2-5*2)(sp),sp
	lea.l	3*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU1-*-2
	dc.w	IDCT_clr3-*-2


IDCT_16
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU1-*-2
	dc.w	IDCT_clr2_SU1-*-2



IDCT_17
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU2

IDCT_18
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_19
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_20
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_clr2_SU1-*-2


IDCT_21
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_clr2_SU1-*-2


IDCT_22
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_23
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_clr2_SU1-*-2

IDCT_24
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU3

IDCT_25
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU4
@@	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_clr2_SU1-*-2


IDCT_26
	lea	-(64*2-6*2)(sp),sp
	lea.l	3*16(a0),a0
	move.w	-1*16+1*2(a0),-(sp)

	lea.l	@f(pc),a5
	bra	IDCT_SU4
@@	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_clr2_SU1-*-2


IDCT_27
	lea	-(64*2-6*2)(sp),sp
	lea.l	2*16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU3-*-2
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
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_clr1-*-2

IDCT_29
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU1

IDCT_30
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU2-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_31
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_32
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_33
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_34
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_35
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_36
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_37
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_38
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_39
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_40
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU3-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_41
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU2
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_normal_SU1-*-2

IDCT_42
	lea	-(64*2-8*2)(sp),sp
	move.w	1*2(a0),-(sp)
	lea.l	16(a0),a0

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU4-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
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
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
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
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
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
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU5-*-2
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
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU6-*-2
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
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU6-*-2
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
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU6-*-2
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
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU6-*-2
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
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
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
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_normal-*-2

IDCT_53
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU3
@@	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_normal-*-2

IDCT_54
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU4
@@	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_normal-*-2

IDCT_55
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU5
@@	dc.w	IDCT_SU5-*-2
	dc.w	IDCT_SU6-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
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
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
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
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU7-*-2
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
@@	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

IDCT_61
	lea	-(64*2-8*2)(sp),sp

	lea.l	@f(pc),a5
	bra	IDCT_SU6
@@	dc.w	IDCT_SU7-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

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
@@	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_SU8-*-2
	dc.w	IDCT_normal-*-2

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

**********************************
*   xxxxxxxx
*   xxxxxxxx
*   xxxxxxxx
*   xxxxxxxx
*   xxxxxxxx
*   xxxxxxxx
*   xxxxxxxx
*   xxxxxxxx
**********************************
IDCT_normal
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00
    move.w  d7,a5
    movem.w (sp)+,d4-d7/a1-a4

    adda.l a6,a1
    adda.l a6,a2
    adda.l a6,a3
    adda.l a6,a4
*
    movem.w (a6,d6.w),d0-d3

    sub.w   (a1)+,d2
    add.w   (a1)+,d0
    sub.w   (a1)+,d3
    sub.w   (a1),d1

    sub.w   (a2)+,d1
    add.w   (a2)+,d3
    add.w   (a2)+,d0
    add.w   (a2),d2

    sub.w   (a4)+,d3  * d3 = S1*cos7+S3*cos5+S5*cos3+S7*cos1
    add.w   (a4)+,d2  * d2 = S1*cos5-S3*cos1+S5*cos7+S7*cos3
    sub.w   (a4)+,d1  * d1 = S1*cos3-S3*cos7-S5*cos1-S7*cos5
    add.w   (a4),d0  * d0 = S1*cos1+S3*cos3+S5*cos5+S7*cos7
*
    movem.w -4(a6,d7.w),d6-d7	d6=COS6,d7=COS2
    sub.w   -(a3),d6		COS2  d6 =S2*cos6+S6*cos2
    add.w   -(a3),d7		COS6  d7 =S2*cos2+S6*cos6
*
    sub.w   d4,d5  * d5=s0-s4
    add.w   d4,d4
    add.w   d5,d4  * d4=s0+s4

    sub.w   d7,d4	* d4=d4-d7
    add.w   d7,d7
    add.w   d4,d7	* d7=d4+d7

    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(0,y),S(7,y)
*
    sub.w   d0,d7	* S(7,y)
    add.w   d0,d0
    add.w   d7,d0	* S(0,y)
*
*  S(1,y),S(6,y)
*
    sub.w   d1,d6	* S(6,y)
    add.w   d1,d1
    add.w   d6,d1	* S(1,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d2,d5	* S(5,y)
    add.w   d2,d2
    add.w   d5,d2	* S(2,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d3,d4	* S(4,y)
    add.w   d3,d3
    add.w   d4,d3	* S(3,y)
    movem.w d0-d7,-(a0)		store S(0,y),S(1,y),S(2,y),S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    move.w  a5,d7
    dbra    d7,sy00
*
  rts


**********************************
*   xxxxxxxx
*   xxxxxxx0
*   xxxxxxx0
*   xxxxxxx0
*   xxxxxxx0
*   xxxxxxx0
*   xxxxxxx0
*   xxxxxxx0
**********************************
IDCT_normal_SU1
*
*  S(x,y)
*
  move.w  7*2(sp),d0
  beq     IDCT_clr1

  movea.w  d0,a4
  adda.l   a6,a4

  moveq   #8-1,d7
sy00_SU1
    move.w  d7,a5

    movem.w (sp)+,d4-d7/a1-a3
    addq.l  #1*2,sp

    adda.l a6,a1
    adda.l a6,a2
    adda.l a6,a3
*
    movem.w (a6,d6.w),d0-d3

    sub.w   (a1)+,d2
    add.w   (a1)+,d0
    sub.w   (a1)+,d3
    sub.w   (a1),d1

    sub.w   (a2)+,d1
    add.w   (a2)+,d3
    add.w   (a2)+,d0
    add.w   (a2),d2

    sub.w   (a4)+,d3  * d3 = S1*cos7+S3*cos5+S5*cos3+S7*cos1
    add.w   (a4)+,d2  * d2 = S1*cos5-S3*cos1+S5*cos7+S7*cos3
    sub.w   (a4)+,d1  * d1 = S1*cos3-S3*cos7-S5*cos1-S7*cos5
    add.w   (a4),d0   * d0 = S1*cos1+S3*cos3+S5*cos5+S7*cos7
    subq.l  #3*2,a4
*
    movem.w -4(a6,d7.w),d6-d7	d6=COS6,d7=COS2
    sub.w   -(a3),d6		COS2  d6 =S2*cos6+S6*cos2
    add.w   -(a3),d7		COS6  d7 =S2*cos2+S6*cos6
*
    sub.w   d4,d5  * d5=s0-s4
    add.w   d4,d4
    add.w   d5,d4  * d4=s0+s4

    sub.w   d7,d4	* d4=d4-d7
    add.w   d7,d7
    add.w   d4,d7	* d7=d4+d7

    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(0,y),S(7,y)
*
    sub.w   d0,d7	* S(7,y)
    add.w   d0,d0
    add.w   d7,d0	* S(0,y)
*
*  S(1,y),S(6,y)
*
    sub.w   d1,d6	* S(6,y)
    add.w   d1,d1
    add.w   d6,d1	* S(1,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d2,d5	* S(5,y)
    add.w   d2,d2
    add.w   d5,d2	* S(2,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d3,d4	* S(4,y)
    add.w   d3,d3
    add.w   d4,d3	* S(3,y)
    movem.w d0-d7,-(a0)		store S(0,y),S(1,y),S(2,y),S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    move.w  a5,d7
    dbra    d7,sy00_SU1
*
  rts


**********************************
*   xxxxxxx0
*   xxxxxxx0
*   xxxxxxx0
*   xxxxxxx0
*   xxxxxxx0
*   xxxxxxx0
*   xxxxxxx0
*   xxxxxxx0
**********************************
IDCT_clr1
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr1
    move.w  d7,a5

    movem.w (sp)+,d4-d7/a1-a4

    adda.l  a6,a1
    adda.l  a6,a2
    adda.l  a6,a3
*
    movem.w (a6,d6.w),d0-d3

    sub.w   (a1)+,d2
    add.w   (a1)+,d0
    sub.w   (a1)+,d3
    sub.w   (a1),d1

    sub.w   (a2)+,d1
    add.w   (a2)+,d3
    add.w   (a2)+,d0
    add.w   (a2),d2

    movem.w -4(a6,d7.w),d6-d7	d6=COS6,d7=COS2
    sub.w   -(a3),d6		COS2  d6 =S2*cos6+S6*cos2
    add.w   -(a3),d7		COS6  d7 =S2*cos2+S6*cos6
*
    sub.w   d4,d5  * d5=s0-s4
    add.w   d4,d4
    add.w   d5,d4  * d4=s0+s4

    sub.w   d7,d4	* d4=d4-d7
    add.w   d7,d7
    add.w   d4,d7	* d7=d4+d7

    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(0,y),S(7,y)
*
    sub.w   d0,d7	* S(7,y)
    add.w   d0,d0
    add.w   d7,d0	* S(0,y)
*
*  S(1,y),S(6,y)
*
    sub.w   d1,d6	* S(6,y)
    add.w   d1,d1
    add.w   d6,d1	* S(1,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d2,d5	* S(5,y)
    add.w   d2,d2
    add.w   d5,d2	* S(2,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d3,d4	* S(4,y)
    add.w   d3,d3
    add.w   d4,d3	* S(3,y)
    movem.w d0-d7,-(a0)		store S(0,y),S(1,y),S(2,y),S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    move.w  a5,d7
    dbra    d7,sy00_clr1
*
  rts



**********************************
*   xxxxxx00
*   xxxxxx00
*   xxxxxx00
*   xxxxxx00
*   xxxxxx00
*   xxxxxx00
*   xxxxxx00
*   xxxxxx00
**********************************
IDCT_clr2
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr2

    movem.w (sp)+,d4-d6/a1-a3
    addq.l  #2*2,sp

    adda.l  a6,a2
    adda.l  a6,a3
*
    movem.w (a6,d6.w),d0-d3

    sub.w   (a2)+,d2
    add.w   (a2)+,d0
    sub.w   (a2)+,d3
    sub.w   (a2),d1

    sub.w   (a3)+,d1
    add.w   (a3)+,d3
    add.w   (a3)+,d0
    add.w   (a3),d2

    movem.w -4(a6,a1.w),d6/a1	d6=COS6,a1=COS2
*
    sub.w   d4,d5  * d5=s0-s4
    add.w   d4,d4
    add.w   d5,d4  * d4=s0+s4

    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1

    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(0,y),S(7,y)
*
    sub.l   d0,a1	* S(7,y)
    add.w   d0,d0
    add.w   a1,d0	* S(0,y)
*
*  S(1,y),S(6,y)
*
    sub.w   d1,d6	* S(6,y)
    add.w   d1,d1
    add.w   d6,d1	* S(1,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d2,d5	* S(5,y)
    add.w   d2,d2
    add.w   d5,d2	* S(2,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d3,d4	* S(4,y)
    add.w   d3,d3
    add.w   d4,d3	* S(3,y)
    movem.w d0-d6/a1,-(a0)		store S(0,y),S(1,y),S(2,y),S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    dbra    d7,sy00_clr2
*
  rts


**********************************
*   xxxxxx00
*   xxxxx000
*   xxxxx000
*   xxxxx000
*   xxxxx000
*   xxxxx000
*   xxxxx000
*   xxxxx000
**********************************
IDCT_clr2_SU1
*
*  S(x,y)
*
  move.w  5*2(sp),d0
  beq	  IDCT_clr3

  movea.w d0,a3
  adda.l  a6,a3
  moveq   #8-1,d7
sy00_clr2_SU1

    movem.w (sp)+,d4-d6/a1-a2
    addq.l  #3*2,sp

    adda.l  a6,a2
*
    movem.w (a6,d6.w),d0-d3

    sub.w   (a2)+,d2
    add.w   (a2)+,d0
    sub.w   (a2)+,d3
    sub.w   (a2),d1

    sub.w   (a3)+,d1
    add.w   (a3)+,d3
    add.w   (a3)+,d0
    add.w   (a3),d2
    subq.l  #3*2,a3

    movem.w -4(a6,a1.w),d6/a1	d6=COS6,a1=COS2
*
    sub.w   d4,d5  * d5=s0-s4
    add.w   d4,d4
    add.w   d5,d4  * d4=s0+s4

    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1

    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(0,y),S(7,y)
*
    sub.l   d0,a1	* S(7,y)
    add.w   d0,d0
    add.w   a1,d0	* S(0,y)
*
*  S(1,y),S(6,y)
*
    sub.w   d1,d6	* S(6,y)
    add.w   d1,d1
    add.w   d6,d1	* S(1,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d2,d5	* S(5,y)
    add.w   d2,d2
    add.w   d5,d2	* S(2,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d3,d4	* S(4,y)
    add.w   d3,d3
    add.w   d4,d3	* S(3,y)
    movem.w d0-d6/a1,-(a0)		store S(0,y),S(1,y),S(2,y),S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    dbra    d7,sy00_clr2_SU1
*
  rts

**********************************
*   xxxxx000
*   xxxxx000
*   xxxxx000
*   xxxxx000
*   xxxxx000
*   xxxxx000
*   xxxxx000
*   xxxxx000
**********************************
IDCT_clr3
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr3

    movem.w (sp)+,d4-d6/a1-a2
    addq.l  #3*2,sp

    adda.l  a6,a2
*
    movem.w (a6,d6.w),d0-d3

    sub.w   (a2)+,d2
    add.w   (a2)+,d0
    sub.w   (a2)+,d3
    sub.w   (a2),d1

    movem.w -4(a6,a1.w),d6/a1	d6=COS6,a1=COS2
*
    sub.w   d4,d5  * d5=s0-s4
    add.w   d4,d4
    add.w   d5,d4  * d4=s0+s4

    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1

    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(0,y),S(7,y)
*
    sub.l   d0,a1	* S(7,y)
    add.w   d0,d0
    add.w   a1,d0	* S(0,y)
*
*  S(1,y),S(6,y)
*
    sub.w   d1,d6	* S(6,y)
    add.w   d1,d1
    add.w   d6,d1	* S(1,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d2,d5	* S(5,y)
    add.w   d2,d2
    add.w   d5,d2	* S(2,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d3,d4	* S(4,y)
    add.w   d3,d3
    add.w   d4,d3	* S(3,y)
    movem.w d0-d6/a1,-(a0)		store S(0,y),S(1,y),S(2,y),S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    dbra    d7,sy00_clr3
*
  rts



**********************************
*   xxxx0000
*   xxxx0000
*   xxxx0000
*   xxxx0000
*   xxxx0000
*   xxxx0000
*   xxxx0000
*   xxxx0000
**********************************
IDCT_clr4
*
  lea.l 1*16(a0),a0
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr4

    movem.w (sp)+,d5-d6/a1-a2
    addq.l  #4*2,sp

    adda.l  a6,a2
*
    movem.w (a6,d6.w),d0-d3

    sub.w   (a2)+,d2
    add.w   (a2)+,d0
    sub.w   (a2)+,d3
    sub.w   (a2),d1

    movem.w -4(a6,a1.w),d6/a1	d6=COS6,a1=COS2
*
    move.w  d5,d4

    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1

    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(0,y),S(7,y)
*
    sub.l   d0,a1	* S(7,y)
    add.w   d0,d0
    add.w   a1,d0	* S(0,y)
*
*  S(1,y),S(6,y)
*
    sub.w   d1,d6	* S(6,y)
    add.w   d1,d1
    add.w   d6,d1	* S(1,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d2,d5	* S(5,y)
    add.w   d2,d2
    add.w   d5,d2	* S(2,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d3,d4	* S(4,y)
    add.w   d3,d3
    add.w   d4,d3	* S(3,y)
    movem.w d0-d6/a1,-(a0)		store S(0,y),S(1,y),S(2,y),S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    dbra    d7,sy00_clr4
*
  rts


**********************************
*   xxxx0000
*   xxx00000
*   xxx00000
*   xxx00000
*   xxx00000
*   xxx00000
*   xxx00000
*   xxx00000
**********************************
IDCT_clr4_SU1
*
*  S(x,y)
*
  move.w  3*2(sp),d0
  beq     IDCT_clr5

  lea.l 1*16(a0),a0

  movea.w d0,a2
  adda.l  a6,a2
  moveq   #8-1,d7
sy00_clr4_SU1

    movem.w (sp)+,d5-d6/a1
    lea.l   5*2(sp),sp
*
    movem.w  (a6,d6.w),d0-d3

    sub.w   (a2)+,d2
    add.w   (a2)+,d0
    sub.w   (a2)+,d3
    sub.w   (a2),d1
    subq.l  #3*2,a2

    movem.w -4(a6,a1.w),d6/a1	d6=COS6,a1=COS2
*
    move.w  d5,d4

    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1

    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(0,y),S(7,y)
*
    sub.l   d0,a1	* S(7,y)
    add.w   d0,d0
    add.w   a1,d0	* S(0,y)
*
*  S(1,y),S(6,y)
*
    sub.w   d1,d6	* S(6,y)
    add.w   d1,d1
    add.w   d6,d1	* S(1,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d2,d5	* S(5,y)
    add.w   d2,d2
    add.w   d5,d2	* S(2,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d3,d4	* S(4,y)
    add.w   d3,d3
    add.w   d4,d3	* S(3,y)
    movem.w d0-d6/a1,-(a0)		store S(0,y),S(1,y),S(2,y),S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    dbra    d7,sy00_clr4_SU1
*
  rts



**********************************
*   xxx00000
*   xxx00000
*   xxx00000
*   xxx00000
*   xxx00000
*   xxx00000
*   xxx00000
*   xxx00000
**********************************
IDCT_clr5
*
  lea.l 1*16(a0),a0
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr5

    movem.w (sp)+,d5-d6/a1
    lea.l   5*2(sp),sp

*
    movem.w (a6,d6.w),d0-d3
    movem.w -4(a6,a1.w),d6/a1	d6=COS6,a1=COS2
*
    move.w  d5,d4

    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1

    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(0,y),S(7,y)
*
    sub.l   d0,a1	* S(7,y)
    add.w   d0,d0
    add.w   a1,d0	* S(0,y)
*
*  S(1,y),S(6,y)
*
    sub.w   d1,d6	* S(6,y)
    add.w   d1,d1
    add.w   d6,d1	* S(1,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d2,d5	* S(5,y)
    add.w   d2,d2
    add.w   d5,d2	* S(2,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d3,d4	* S(4,y)
    add.w   d3,d3
    add.w   d4,d3	* S(3,y)
    movem.w d0-d6/a1,-(a0)	store S(0,y),S(1,y),S(2,y),S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    dbra    d7,sy00_clr5
*
  rts
**********************************
*   xxx00000
*   xx000000
*   xx000000
*   xx000000
*   xx000000
*   xx000000
*   xx000000
*   xx000000
**********************************
IDCT_clr5_SU1
*
  lea.l 1*16(a0),a0
*
*  S(x,y)
*
    move.w  4(sp),a2
    movem.w -4(a6,a2.w),a3/a4	a3=COS6,a4=COS2

  moveq   #8-1,d7
sy00_clr5_SU1

    move.l  (sp)+,d5
    lea.l   6*2(sp),sp
*
    movem.w (a6,d5.w),d0-d3
    swap.w  d5

    move.w  a4,a1		COS2
    move.w  a3,d6		COS6
*
    move.w  d5,d4

    sub.w   a1,d4	* d4=d4-a1
    add.l   a1,a1
    add.l   d4,a1	* a1=d4+a1

    sub.w   d6,d5	* d5=d5-d6
    add.w   d6,d6
    add.w   d5,d6	* d6=d5+d6
*
*  S(0,y),S(7,y)
*
    sub.l   d0,a1	* S(7,y)
    add.w   d0,d0
    add.w   a1,d0	* S(0,y)
*
*  S(1,y),S(6,y)
*
    sub.w   d1,d6	* S(6,y)
    add.w   d1,d1
    add.w   d6,d1	* S(1,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d2,d5	* S(5,y)
    add.w   d2,d2
    add.w   d5,d2	* S(2,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d3,d4	* S(4,y)
    add.w   d3,d3
    add.w   d4,d3	* S(3,y)
    movem.w d0-d6/a1,-(a0)	store S(0,y),S(1,y),S(2,y),S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    dbra    d7,sy00_clr5_SU1
*
  rts



**********************************
*   xx000000
*   xx000000
*   xx000000
*   xx000000
*   xx000000
*   xx000000
*   xx000000
*   xx000000
**********************************
IDCT_clr6
*
  lea.l 1*16(a0),a0
*
*  S(x,y)
*
  moveq   #8-1,d7
sy00_clr6

    move.l  (sp)+,d5
    lea.l   6*2(sp),sp
*
    movem.w (a6,d5.w),d0-d3
    swap.w  d5
*
    move.w  d5,d4
    move.w  d4,a4
    move.w  d5,d6
*
*  S(0,y),S(7,y)
*
    sub.l   d0,a4	* S(7,y)
    add.w   d0,d0
    add.w   a4,d0	* S(0,y)
*
*  S(1,y),S(6,y)
*
    sub.w   d1,d6	* S(6,y)
    add.w   d1,d1
    add.w   d6,d1	* S(1,y)
*
*  S(2,y),S(5,y)
*
    sub.w   d2,d5	* S(5,y)
    add.w   d2,d2
    add.w   d5,d2	* S(2,y)
*
*  S(3,y),S(4,y)
*
    sub.w   d3,d4	* S(4,y)
    add.w   d3,d3
    add.w   d4,d3	* S(3,y)
    movem.w d0-d6/a4,-(a0)	store S(0,y),S(1,y),S(2,y),S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    dbra    d7,sy00_clr6
*
  rts


**********************************
*   xx000000
*   x0000000
*   x0000000
*   x0000000
*   x0000000
*   x0000000
*   x0000000
*   x0000000
**********************************
IDCT_clr6_SU1
*
    lea.l 1*16(a0),a0
*
*  S(x,y)
*
  movea.w 2(sp),a4
  movem.w  (a6,a4.w),a1-a4

  moveq   #8-1,d7
sy00_clr6_SU1

    move.w  (sp)+,d0
    lea.l   7*2(sp),sp

    move.w  d0,d1
    move.w  d0,d2
    move.w  d0,d3
    move.w  d0,d4
    move.w  d0,d5
    move.w  d0,d6
    move.w  d0,a5
*
    sub.l   a1,a5	   * S(7,y)
    add.w   a1,d0	   * S(0,y)
*
    sub.w   a2,d6	   * S(6,y)
    add.w   a2,d1	   * S(1,y)
*
    sub.w   a3,d5	   * S(5,y)
    add.w   a3,d2	   * S(2,y)
*
    sub.w   a4,d4	   * S(4,y)
    add.w   a4,d3	   * S(3,y)

    movem.w d0-d6/a5,-(a0)	store S(0,y),S(1,y),S(2,y) S(3,y),S(4,y),S(5,y),S(6,y),S(7,y)
*
    dbra    d7,sy00_clr6_SU1
*
  rts

**********************************
*   x0000000
**********************************
IDCT_SU1

	move.w	1*2(a0),d5
	lea.l	2*8(a0),a0

_IDCT_SU1

	move.w	d5,-(sp)
	move.w	d5,1*16(sp)
	move.w	d5,2*16(sp)
	move.w	d5,3*16(sp)
	move.w	d5,4*16(sp)
	move.w	d5,5*16(sp)
	move.w	d5,6*16(sp)
	move.w	d5,7*16(sp)

	move.w	(a5)+,d5
	jmp	(a5,d5.w)

**********************************
*   xx000000
**********************************
IDCT_SU2

    movem.w 1*2(a0),d5-d6
    lea.l   2*8(a0),a0

_IDCT_SU2

    move.w  d6,d0
    beq     _IDCT_SU1

    movem.w (a6,d6.w),d0-d3

    move.w  d5,d4
    beq     IDCT_SU2_01

    move.w  d5,d7
*
*  S'(u,0),S'(u,7)
*
    sub.w   d0,d7
    add.w   d0,d0
    add.w   d7,d0
*
*  S'(u,3),S'(u,4)
*
    sub.w   d3,d4
    add.w   d3,d3
    add.w   d4,d3

    move.w  d7,-(sp)        * S'(u,7) = d2+d3-d4
    move.w  d4,3*16(sp)   * S'(u,4) = d2-d3-d4
    move.w  d3,4*16(sp)   * S'(u,3) = d2-d3+d4 = d2-d3-d4 + 2*d4 = S'(u,4) + 2*d4
    move.w  d0,7*16(sp)   * S'(u,0) = d2+d3+d4 = d2+d3-d4 +2*d4 = S'(u,7) + 2*d4
*
    move.w  d5,d7
*
*  S'(u,1),S'(u,6)
*
    sub.w   d1,d7
    add.w   d1,d1
    add.w   d7,d1
*
*  S'(u,2),S'(u,5)
*
    sub.w   d2,d5
    add.w   d2,d2
    add.w   d5,d2

    move.w  d1,6*16(sp)   * S'(u,1) = d1+d3+d4 = d1+d3-d4 + 2*d4 = S'(u,6) + 2*d4
    move.w  d2,5*16(sp)   * S'(u,2) = d1-d3+d4 = d1-d3-d4 + 2*d4 = S'(u,5) + 2*d4
    move.w  d5,2*16(sp)   * S'(u,5) = d1-d3-d4
    move.w  d7,1*16(sp)   * S'(u,6) = d1+d3-d4

	move.w	(a5)+,d5
	jmp	(a5,d5.w)

**********************************
*   0x000000
**********************************
IDCT_SU2_01
	move.w	d0,7*16-2(sp)	* S'(u,0)
	neg.w	d0
	move.w	d0,-(sp)	* S'(u,7)
	move.w	d3,4*16(sp)	* S'(u,3)
	neg.w	d3
	move.w	d3,3*16(sp)	* S'(u,4)

	move.w	d1,6*16(sp)	* S'(u,1) = d1+d3+d4 = d1+d3-d4 + 2*d4 = S'(u,6) + 2*d4
	move.w	d2,5*16(sp)	* S'(u,2) = d1-d3+d4 = d1-d3-d4 + 2*d4 = S'(u,5) + 2*d4
	neg.w	d1
	neg.w	d2
	move.w	d2,2*16(sp)	* S'(u,5) = d1-d3-d4
	move.w  d1,1*16(sp)	* S'(u,6) = d1+d3-d4

	move.w	(a5)+,d5
	jmp	(a5,d5.w)

**********************************
*   xxx00000
**********************************
.xdef	IDCT_SU3_16
IDCT_SU3_16
	lea.l	1*16(a0),a0
IDCT_SU3

    movem.w     (a0)+,d4-d7
    addq.w      #4*2,a0

_IDCT_SU3

    move.w  d7,d0
    beq     _IDCT_SU2

*
    movem.w (a6,d6.w),d0-d3

    move.w  d5,d4
*
    move.l  -4(a6,d7.w),d7
    sub.w   d7,d4	* d4=d4-d7
    add.w   d7,d7
    add.w   d4,d7	* d7=d4+d7
*
*  S'(u,0),S'(u,7)
*
    sub.w   d0,d7
    add.w   d0,d0
    add.w   d7,d0
*
*  S'(u,3),S'(u,4)
*
    sub.w   d3,d4
    add.w   d3,d3
    add.w   d4,d3

    move.w  d7,-(sp)        * S'(u,7) = d2+d3-d4
    move.w  d4,3*16(sp)   * S'(u,4) = d2-d3-d4
    move.w  d3,4*16(sp)   * S'(u,3) = d2-d3+d4 = d2-d3-d4 + 2*d4 = S'(u,4) + 2*d4
    move.w  d0,7*16(sp)   * S'(u,0) = d2+d3+d4 = d2+d3-d4 +2*d4 = S'(u,7) + 2*d4
*
    swap.w  d7
    sub.w   d7,d5	* d5=d5-d6
    add.w   d7,d7
    add.w   d5,d7	* d6=d5+d6
*
*  S'(u,1),S'(u,6)
*
    sub.w   d1,d7
    add.w   d1,d1
    add.w   d7,d1
*
*  S'(u,2),S'(u,5)
*
    sub.w   d2,d5
    add.w   d2,d2
    add.w   d5,d2

    move.w  d1,6*16(sp)   * S'(u,1) = d1+d3+d4 = d1+d3-d4 + 2*d4 = S'(u,6) + 2*d4
    move.w  d2,5*16(sp)   * S'(u,2) = d1-d3+d4 = d1-d3-d4 + 2*d4 = S'(u,5) + 2*d4
    move.w  d5,2*16(sp)   * S'(u,5) = d1-d3-d4
    move.w  d7,1*16(sp)   * S'(u,6) = d1+d3-d4

	move.w	(a5)+,d5
	jmp	(a5,d5.w)


**********************************
*   xxxx0000
**********************************
.xdef	IDCT_SU4_16
IDCT_SU4_16
	lea.l	1*16(a0),a0
IDCT_SU4

    movem.w     (a0)+,d4-d7/a1
    addq.l      #3*2,a0

_IDCT_SU4

    move.w  a1,d0
    beq     _IDCT_SU3

    adda.l a6,a1
*
    movem.w (a6,d6.w),d0-d3

    sub.w   (a1)+,d2
    add.w   (a1)+,d0
    sub.w   (a1)+,d3
    sub.w   (a1),d1

    move.w  d5,d4
*
    move.l  -4(a6,d7.w),d7
    sub.w   d7,d4	* d4=d4-d7
    add.w   d7,d7
    add.w   d4,d7	* d7=d4+d7
*
*  S'(u,0),S'(u,7)
*
    sub.w   d0,d7
    add.w   d0,d0
    add.w   d7,d0
*
*  S'(u,3),S'(u,4)
*
    sub.w   d3,d4
    add.w   d3,d3
    add.w   d4,d3

    move.w  d7,-(sp)        * S'(u,7) = d2+d3-d4
    move.w  d4,3*16(sp)   * S'(u,4) = d2-d3-d4
    move.w  d3,4*16(sp)   * S'(u,3) = d2-d3+d4 = d2-d3-d4 + 2*d4 = S'(u,4) + 2*d4
    move.w  d0,7*16(sp)   * S'(u,0) = d2+d3+d4 = d2+d3-d4 +2*d4 = S'(u,7) + 2*d4
*
    swap.w  d7
    sub.w   d7,d5	* d5=d5-d6
    add.w   d7,d7
    add.w   d5,d7	* d6=d5+d6
*
*  S'(u,1),S'(u,6)
*
    sub.w   d1,d7
    add.w   d1,d1
    add.w   d7,d1
*
*  S'(u,2),S'(u,5)
*
    sub.w   d2,d5
    add.w   d2,d2
    add.w   d5,d2

    move.w  d1,6*16(sp)   * S'(u,1) = d1+d3+d4 = d1+d3-d4 + 2*d4 = S'(u,6) + 2*d4
    move.w  d2,5*16(sp)   * S'(u,2) = d1-d3+d4 = d1-d3-d4 + 2*d4 = S'(u,5) + 2*d4
    move.w  d5,2*16(sp)   * S'(u,5) = d1-d3-d4
    move.w  d7,1*16(sp)   * S'(u,6) = d1+d3-d4

	move.w	(a5)+,d5
	jmp	(a5,d5.w)


**********************************
*   xxxxx000
**********************************
.xdef	IDCT_SU5_16
IDCT_SU5_16
	lea.l	1*16(a0),a0
IDCT_SU5

    movem.w     (a0)+,d4-d7/a1
    addq.l      #3*2,a0

_IDCT_SU5

    move.w  d4,d0
    beq     _IDCT_SU4

    adda.l a6,a1
*
    movem.w (a6,d6.w),d0-d3

    sub.w   (a1)+,d2
    add.w   (a1)+,d0
    sub.w   (a1)+,d3
    sub.w   (a1),d1

    sub.w   d4,d5  * d1=s0-s4
    add.w   d4,d4
    add.w   d5,d4  * d3=s0+s4 = s0-s4 + 2*s4
*
    move.l  -4(a6,d7.w),d7
    sub.w   d7,d4	* d4=d4-d7
    add.w   d7,d7
    add.w   d4,d7	* d7=d4+d7
*
*  S'(u,0),S'(u,7)
*
    sub.w   d0,d7
    add.w   d0,d0
    add.w   d7,d0
*
*  S'(u,3),S'(u,4)
*
    sub.w   d3,d4
    add.w   d3,d3
    add.w   d4,d3

    move.w  d7,-(sp)        * S'(u,7) = d2+d3-d4
    move.w  d4,3*16(sp)   * S'(u,4) = d2-d3-d4
    move.w  d3,4*16(sp)   * S'(u,3) = d2-d3+d4 = d2-d3-d4 + 2*d4 = S'(u,4) + 2*d4
    move.w  d0,7*16(sp)   * S'(u,0) = d2+d3+d4 = d2+d3-d4 +2*d4 = S'(u,7) + 2*d4
*
    swap.w  d7
    sub.w   d7,d5	* d5=d5-d6
    add.w   d7,d7
    add.w   d5,d7	* d6=d5+d6
*
*  S'(u,1),S'(u,6)
*
    sub.w   d1,d7
    add.w   d1,d1
    add.w   d7,d1
*
*  S'(u,2),S'(u,5)
*
    sub.w   d2,d5
    add.w   d2,d2
    add.w   d5,d2

    move.w  d1,6*16(sp)   * S'(u,1) = d1+d3+d4 = d1+d3-d4 + 2*d4 = S'(u,6) + 2*d4
    move.w  d2,5*16(sp)   * S'(u,2) = d1-d3+d4 = d1-d3-d4 + 2*d4 = S'(u,5) + 2*d4
    move.w  d5,2*16(sp)   * S'(u,5) = d1-d3-d4
    move.w  d7,1*16(sp)   * S'(u,6) = d1+d3-d4

	move.w	(a5)+,d5
	jmp	(a5,d5.w)



**********************************
*   xxxxxx00
**********************************
IDCT_SU6

    movem.w     (a0)+,d4-d7/a1-a2
    addq.l      #2*2,a0

_IDCT_SU6

    move.w  a2,d0
    beq     _IDCT_SU5

    adda.l a6,a1
    adda.l a6,a2
*
    movem.w  (a6,d6.w),d0-d3

    sub.w   (a1)+,d2
    add.w   (a1)+,d0
    sub.w   (a1)+,d3
    sub.w   (a1),d1

    sub.w   (a2)+,d1
    add.w   (a2)+,d3
    add.w   (a2)+,d0
    add.w   (a2),d2

    sub.w   d4,d5  * d1=s0-s4
    add.w   d4,d4
    add.w   d5,d4  * d3=s0+s4 = s0-s4 + 2*s4
*
    move.l  -4(a6,d7.w),d7
    sub.w   d7,d4	* d4=d4-d7
    add.w   d7,d7
    add.w   d4,d7	* d7=d4+d7
*
*  S'(u,0),S'(u,7)
*
    sub.w   d0,d7
    add.w   d0,d0
    add.w   d7,d0
*
*  S'(u,3),S'(u,4)
*
    sub.w   d3,d4
    add.w   d3,d3
    add.w   d4,d3

    move.w  d7,-(sp)        * S'(u,7) = d2+d3-d4
    move.w  d4,3*16(sp)   * S'(u,4) = d2-d3-d4
    move.w  d3,4*16(sp)   * S'(u,3) = d2-d3+d4 = d2-d3-d4 + 2*d4 = S'(u,4) + 2*d4
    move.w  d0,7*16(sp)   * S'(u,0) = d2+d3+d4 = d2+d3-d4 +2*d4 = S'(u,7) + 2*d4
*
    swap.w  d7
    sub.w   d7,d5	* d5=d5-d6
    add.w   d7,d7
    add.w   d5,d7	* d6=d5+d6
*
*  S'(u,1),S'(u,6)
*
    sub.w   d1,d7
    add.w   d1,d1
    add.w   d7,d1
*
*  S'(u,2),S'(u,5)
*
    sub.w   d2,d5
    add.w   d2,d2
    add.w   d5,d2

    move.w  d1,6*16(sp)   * S'(u,1) = d1+d3+d4 = d1+d3-d4 + 2*d4 = S'(u,6) + 2*d4
    move.w  d2,5*16(sp)   * S'(u,2) = d1-d3+d4 = d1-d3-d4 + 2*d4 = S'(u,5) + 2*d4
    move.w  d5,2*16(sp)   * S'(u,5) = d1-d3-d4
    move.w  d7,1*16(sp)   * S'(u,6) = d1+d3-d4

	move.w	(a5)+,d5
	jmp	(a5,d5.w)



**********************************
*   xxxxxxx0
**********************************
IDCT_SU7

    movem.w     (a0)+,d4-d7/a1-a4

_IDCT_SU7

    move.w  a3,d0
    beq     _IDCT_SU6

IDCT_SU7_2

    adda.l a6,a1
    adda.l a6,a2
    adda.l a6,a3
*
    movem.w (a6,d6.w),d0-d3

    sub.w   (a1)+,d2
    add.w   (a1)+,d0
    sub.w   (a1)+,d3
    sub.w   (a1),d1

    sub.w   (a2)+,d1
    add.w   (a2)+,d3
    add.w   (a2)+,d0
    add.w   (a2),d2

    sub.w   d4,d5  * d1=s0-s4
    add.w   d4,d4
    add.w   d5,d4  * d3=s0+s4 = s0-s4 + 2*s4
*
    move.l  -4(a6,d7.w),d7
    add.w   -4(a3),d7  * d7 =S2*cos2+S6*cos6

    sub.w   d7,d4	* d4=d4-d7
    add.w   d7,d7
    add.w   d4,d7	* d7=d4+d7
*
*  S'(u,0),S'(u,7)
*
    sub.w   d0,d7
    add.w   d0,d0
    add.w   d7,d0
*
*  S'(u,3),S'(u,4)
*
    sub.w   d3,d4
    add.w   d3,d3
    add.w   d4,d3

    move.w  d7,-(sp)        * S'(u,7) = d2+d3-d4
    move.w  d4,3*16(sp)     * S'(u,4) = d2-d3-d4
    move.w  d3,4*16(sp)     * S'(u,3) = d2-d3+d4 = d2-d3-d4 + 2*d4 = S'(u,4) + 2*d4
    move.w  d0,7*16(sp)     * S'(u,0) = d2+d3+d4 = d2+d3-d4 +2*d4 = S'(u,7) + 2*d4
*
    swap.w  d7
    sub.w   -(a3),d7  * d7 =S2*cos6+S6*cos2

    sub.w   d7,d5	* d5=d5-d6
    add.w   d7,d7
    add.w   d5,d7	* d6=d5+d6
*
*  S'(u,1),S'(u,6)
*
    sub.w   d1,d7
    add.w   d1,d1
    add.w   d7,d1
*
*  S'(u,2),S'(u,5)
*
    sub.w   d2,d5
    add.w   d2,d2
    add.w   d5,d2

    move.w  d1,6*16(sp)   * S'(u,1) = d1+d3+d4 = d1+d3-d4 + 2*d4 = S'(u,6) + 2*d4
    move.w  d2,5*16(sp)   * S'(u,2) = d1-d3+d4 = d1-d3-d4 + 2*d4 = S'(u,5) + 2*d4
    move.w  d5,2*16(sp)   * S'(u,5) = d1-d3-d4
    move.w  d7,1*16(sp)   * S'(u,6) = d1+d3-d4

	move.w	(a5)+,d5
	jmp	(a5,d5.w)


**********************************
*   xxxxxxxx
**********************************
IDCT_SU8

    movem.w     (a0)+,d4-d7/a1-a4	*S0,S1,S2,S3,S4,S5,S6,S7
    move.w  a4,d0
    beq     _IDCT_SU7

    adda.l a6,a1
    adda.l a6,a2
    adda.l a6,a3
    adda.l a6,a4
*
    movem.w (a6,d6.w),d0-d3

    sub.w   (a1)+,d2
    add.w   (a1)+,d0
    sub.w   (a1)+,d3
    sub.w   (a1),d1

    sub.w   (a2)+,d1
    add.w   (a2)+,d3
    add.w   (a2)+,d0
    add.w   (a2),d2

    sub.w   (a4)+,d3  * d3 = S1*cos7+S3*cos5+S5*cos3+S7*cos1
    add.w   (a4)+,d2  * d2 = S1*cos5-S3*cos1+S5*cos7+S7*cos3
    sub.w   (a4)+,d1  * d1 = S1*cos3-S3*cos7-S5*cos1-S7*cos5
    add.w   (a4),d0   * d0 = S1*cos1+S3*cos3+S5*cos5+S7*cos7

    sub.w   d4,d5  * d5=s0-s4
    add.w   d4,d4
    add.w   d5,d4  * d4=s0+s4
*
    move.l  -4(a6,d7.w),d7
    add.w   -4(a3),d7	* d7 =S2*cos2+S6*cos6

    sub.w   d7,d4	* d4=s0+s4-S2*cos2-S6*cos6
    add.w   d7,d7
    add.w   d4,d7	* d7=s0+s4+S2*cos2+S6*cos6
*
*  S'(u,0),S'(u,7)
*
    sub.w   d0,d7	* d7=S0-S1*cos1+S2*cos2-S3*cos3+S4-S5*cos5+S6*cos6-S7*cos7
    add.w   d0,d0
    add.w   d7,d0	* d0=
*
*  S'(u,3),S'(u,4)
*
    sub.w   d3,d4
    add.w   d3,d3
    add.w   d4,d3

    move.w  d7,-(sp)      * S'(u,7) = d2+d3-d4
    move.w  d4,3*16(sp)   * S'(u,4) = d2-d3-d4
    move.w  d3,4*16(sp)   * S'(u,3) = d2-d3+d4 = d2-d3-d4 + 2*d4 = S'(u,4) + 2*d4
    move.w  d0,7*16(sp)   * S'(u,0) = d2+d3+d4 = d2+d3-d4 +2*d4 = S'(u,7) + 2*d4
*
    swap.w  d7
    sub.w   -(a3),d7    * d7 =S2*cos6+S6*cos2
    sub.w   d7,d5	* d5=d5-d6
    add.w   d7,d7
    add.w   d5,d7	* d6=d5+d6
*
*  S'(u,1),S'(u,6)
*
    sub.w   d1,d7
    add.w   d1,d1
    add.w   d7,d1
*
*  S'(u,2),S'(u,5)
*
    sub.w   d2,d5
    add.w   d2,d2
    add.w   d5,d2

    move.w  d1,6*16(sp)   * S'(u,1) = S2*cos6+S6*cos2
    move.w  d2,5*16(sp)   * S'(u,2) = 
    move.w  d5,2*16(sp)   * S'(u,5) = 
    move.w  d7,1*16(sp)   * S'(u,6) = S2*cos6+S6*cos2

	move.w	(a5)+,d5
	jmp	(a5,d5.w)

.end
