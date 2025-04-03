*
*  DCT.S
*
*  ó£éUÉRÉTÉCÉìïœä∑
*
*  S(v,u)= Sum(y)Sum(x) C(v)*C(u)*Syx*cos((2x+1)u*pi/16)*cos((2y+1)*v*pi/16)/4
*	 C(u),C(v) =1/sqrt(2)  (u,v=0ÇÃéû)
*	           =1		ÇªÇÃëº
*
*  c(x,u)=cos(pi*(2x+1)*u/16)*C(u)
*   C(0)=1/sqr(2)
*   C(1Å`7)=1
*  Ç»ÇÒÇæÇØÇ«ÅAëSëÃÇ…1/sqr(2)ÇÇ©ÇØÇƒ
*   C(0)=1/2
*   C(1Å`7)=1/sqr(2)
*	c0=cos(pi*0/16)/sqr(2)/sqr(2)=1/2
*	c1=cos(pi*1/16)/sqr(2)
*	c2=cos(pi*2/16)/sqr(2)
*	c3=cos(pi*2/16)/sqr(2)
*	c4=cos(pi*4/16)/sqr(2)=1/2
*	c5=cos(pi*5/16)/sqr(2)
*	c6=cos(pi*6/16)/sqr(2)
*	c7=cos(pi*7/16)/sqr(2)
*
*  Ç∆ÇµÇƒÅAs(u,v)ÇåvéZÇµÇΩÇÁÇQî{Ç∑ÇÈ
*
*     x=   0   1   2   3   4   5   6   7
*  u=0 :  c0  c0  c0  c0  c0  c0  c0  c0
*  u=1 :  c1  c3  c5  c7 -c7 -c5 -c3 -c1
*  u=2 :  c2  c6 -c6 -c2 -c2 -c6  c6  c2
*  u=3 :  c3 -c7 -c1 -c5  c5  c1  c7 -c3
*  u=4 :  c4 -c4 -c4  c4  c4 -c4 -c4  c4
*  u=5 :  c5 -c1  c7  c3 -c3  c7  c1 -c5
*  u=6 :  c6 -c2  c2 -c6 -c6  c2 -c2  c6
*  u=7 :  c7 -c5  c3 -c1  c1 -c3  c5 -c7
*
   .include	work.inc
   .text
   xref	PrintWI
   xdef    DCT
*
*  Digital Cosine Transformation
*
*     a4.l sxy(w)
*     sxy 256äKí≤ data
*
*
DCT
  lea     -8*8*4+8*4(sp),sp
  add.l   #DCT_TBL+4096/2*4*8,a6
  move.l  #$00008000,a5
  moveq   #8-1,d7
sy00
*
*  S'(y,0),S'(y,4)
*
    lea.l   -4*8(a4),a4
    movem.l (a4),d0-d3/a0-a3
    add.l   a3,d0		d0=S0+S7
    add.l   a2,d1		d1=S1+S6
    add.l   a1,d2               d2=S2+S5
    add.l   a0,d3		d3=S3+S4

    move.l  d0,d4
    move.l  d1,d5
    add.l   d3,d4		d4=S0+S3+S4+S7
    add.l   d2,d5		d5=S1+S2+S5+S6

	add.l	d4,d5	d5=d4+d5	
	add.l	d4,d4
	sub.l	d5,d4	d4=d4-d5
	addq.l	#1,d5
	addq.l	#1,d4
	asr.l	d5
	asr.l	d4
    move.l  d5,-(sp)      * S'(y,0)=S0+S1+S2+S3+S4+S5+S6+S7
    move.l  d4,4*4*8(sp)  * S'(y,4)=S0-S1-S2+S3+S4-S5-S6+S7
*
*  S'(y,2),S'(y,6)
*
    move.l  d0,d4
    move.l  d1,d5
    sub.l   d3,d4		d4=S0-S3-S4+S7
    sub.l   d2,d5		d5=S1-S2-S5+S6
	add.l	a5,d4
	add.l	a5,d5
	swap.w	d4
	swap.w	d5
	lsl.w	#4,d4
	lsl.w	#4,d5
	movem.l	DCOS6(a6,d4.w),d4/d6
	add.l	DCOS6(a6,d5.w),d6
	sub.l	DCOS2(a6,d5.w),d4

	move.l	d6,2*4*8(sp)   * S'(y,2)=cos2(s0-s3-s4+s7)+cos6(s1-s2-s5+s6)
	move.l	d4,6*4*8(sp)   * S'(y,6)=cos6(s0-s3-s4+s7)-cos2(s1-s2-s5+s6)
*
*  S'(y,1),S'(y,3),S'(y,5),S'(y,7)
*
    sub.l   a3,d0
    sub.l   a2,d1
    sub.l   a1,d2
    sub.l   a0,d3

    sub.l   a3,d0		d0=S0-S7
    sub.l   a2,d1		d1=S1-S6
    sub.l   a1,d2               d2=S2-S5
    sub.l   a0,d3		d3=S3-S4

	add.l	a5,d0
	add.l	a5,d1
	add.l	a5,d2
	add.l	a5,d3
	swap.w	d0
	swap.w	d1
	swap.w	d2
	swap.w	d3
	lsl.w	#5,d0
	lsl.w	#5,d1
	lsl.w	#5,d2
	lsl.w	#5,d3
*
*  S'(y,1)  S'(y,3)  S'(y,5)  S'(y,7)
*
    movem.l DCOS5(a6,d0.w),d5-d6
    movem.l DCOS1(a6,d0.w),d0/d4
    add.l   DCOS3(a6,d1.w),d0
    sub.l   DCOS7(a6,d1.w),d4
    sub.l   DCOS1(a6,d1.w),d5
    sub.l   DCOS5(a6,d1.w),d6

    add.l   DCOS5(a6,d2.w),d0
    sub.l   DCOS1(a6,d2.w),d4
    add.l   DCOS7(a6,d2.w),d5
    add.l   DCOS3(a6,d2.w),d6

    add.l   DCOS7(a6,d3.w),d0
    sub.l   DCOS5(a6,d3.w),d4
    add.l   DCOS3(a6,d3.w),d5
    sub.l   DCOS1(a6,d3.w),d6

    move.l  d0,1*4*8(sp)    * S'(y,1)=cos1(s0-s7)+cos3(s1-s6)+cos5(s2-s5)+cos7(s3-s4)
    move.l  d4,3*4*8(sp)    * S'(y,3)=cos3(s0-s7)-cos7(s1-s6)-cos1(s2-s5)-cos5(s3-s4)
    move.l  d5,5*4*8(sp)    * S'(y,5)=cos5(s0-s7)-cos1(s1-s6)+cos7(s2-s5)+cos3(s3-s4)
    move.l  d6,7*4*8(sp)    * S'(y,7)=cos7(s0-s7)-cos5(s1-s6)+cos3(s2-s5)-cos1(s3-s4)
*
    dbra    d7,sy00
*
*  S(u,v)
*
  moveq   #8-1,d7
su00
*
*  S(u,0),S(u,4)
*
    movem.l (sp)+,d0-d3/a0-a3

    add.l   a3,d0		d0=s0+s7
    add.l   a2,d1		d1=s1+s6
    add.l   a1,d2		d2=s2+s5
    add.l   a0,d3		d3=s3+s4

    move.l  d0,d4
    move.l  d1,d5
    add.l   d3,d4	d4=d0+d3=s0+s7+s3+s4
    add.l   d2,d5	d5=d1+d2=s1+s6+s2+s5

	add.l	d4,d5	d5=d4+d5	
	add.l	d4,d4
	sub.l	d5,d4	d4=d4-d5
	swap	d5
	swap	d4
	addq.w	#2,d5
	addq.w	#2,d4
	asr.w	#2,d5
	asr.w	#2,d4
    move.w  d5,(a4)+		* S(u,0)=s0+s1+s2+s3+s4+s5+s6+s7
    move.w  d4,16*4-2(a4)	* S(u,4)=s0-s1-s2+s3+s4-s5-s6+s7
*
*  S(u,2),S(u,6)
*
    move.l  d0,d4
    move.l  d1,d5
    sub.l   d3,d4	d4=d0-d3=s0+s7-s3-s4
    sub.l   d2,d5	d5=d1-d2=s1+s6-s2-s5
	add.l	a5,d4
	add.l	a5,d5
	swap.w	d4
	swap.w	d5
	lsl.w	#4,d4
	lsl.w	#4,d5

    movem.l DCOS6(a6,d4.w),d4/d6
    add.l   DCOS6(a6,d5.w),d6
    sub.l   DCOS2(a6,d5.w),d4
	swap	d6
	swap	d4
	addq.w	#1,d6
	addq.w	#1,d4
	asr.w	#1,d6
	asr.w	#1,d4
    move.w  d6,16*2-2(a4)	* S(u,2)=cos2(s0+s7-s3-s4)+cos6(s1+s6-s2-s5)
    move.w  d4,16*6-2(a4)	* S(u,6)=cos6(s0+s7-s3-s4)-cos2(s1+s6-s2-s5)
*
*  S(u,1),S(u,3),S(u,5),S(u,7)
*
    sub.l   a3,d0
    sub.l   a2,d1
    sub.l   a1,d2
    sub.l   a0,d3
    sub.l   a3,d0		d0=s0-s7
    sub.l   a2,d1		d1=s1-s6
    sub.l   a1,d2		d2=s2-s5
    sub.l   a0,d3		d3=s3-s4

	add.l	a5,d0
	add.l	a5,d1
	add.l	a5,d2
	add.l	a5,d3

    swap.w  d0
    swap.w  d1
    swap.w  d2
    swap.w  d3
    lsl.w   #5,d0
    lsl.w   #5,d1
    lsl.w   #5,d2
    lsl.w   #5,d3

*
*  S(u,1)  S(u,7)  S(u,3)  S(u,5)
*
    movem.l DCOS5(a6,d0.w),d5-d6
    movem.l DCOS1(a6,d0.w),d0/d4
    add.l   DCOS3(a6,d1.w),d0
    sub.l   DCOS7(a6,d1.w),d4
    sub.l   DCOS1(a6,d1.w),d5
    sub.l   DCOS5(a6,d1.w),d6

    add.l   DCOS5(a6,d2.w),d0
    sub.l   DCOS1(a6,d2.w),d4
    add.l   DCOS7(a6,d2.w),d5
    add.l   DCOS3(a6,d2.w),d6

    add.l   DCOS7(a6,d3.w),d0
    sub.l   DCOS5(a6,d3.w),d4
    add.l   DCOS3(a6,d3.w),d5
    sub.l   DCOS1(a6,d3.w),d6
	swap	d0
	swap	d4
	swap	d5
	swap	d6
	addq.w	#1,d0
	addq.w	#1,d4
	addq.w	#1,d5
	addq.w	#1,d6
	asr.w	#1,d0
	asr.w	#1,d4
	asr.w	#1,d5
	asr.w	#1,d6
	move.w	d0,16*1-2(a4) * S(u,1)=cos1(s0-s7)+cos3(s1-s6)+cos5(s2-s5)+cos7(s3-s4)
	move.w	d4,16*3-2(a4) * S(u,3)=cos3(s0-s7)-cos7(s1-s6)-cos1(s2-s5)-cos5(s3-s4)
	move.w	d5,16*5-2(a4) * S(u,5)=cos5(s0-s7)-cos1(s1-s6)+cos7(s2-s5)+cos3(s3-s4)
	move.w	d6,16*7-2(a4) * S(u,7)=cos7(s0-s7)-cos5(s1-s6)+cos3(s2-s5)-cos1(s3-s4)

	dbra	d7,su00
	sub.l	#DCT_TBL+4096/2*4*8,a6
	rts

 .end
