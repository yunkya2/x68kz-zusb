*
*
*  VTOYUV.S
*
*  離散コサイン変換テストプログラム
*
*
.include	work.inc

  .text

  xdef   VRAM_to_YUV,VRAM_to_YUV2,VRAM_to_YUV4

*
*	VRAMデータからRGB成分を分離するマクロ
*
VtoRGB	macro  Vin
      move.w  Vin,d2
      move.w  d2,d1
      lsl.w   #5,d1
      moveq.l #$0020,d0
      and.w   d1,d0 * I
      and.w   #$07e0,d1 * B
      move.w  d2,d3
      and.w   #$07c0,d3
      or.w    d0,d3     * R
      lsr.w   #5,d2
      and.w   #$07c0,d2
      or.w    d0,d2     * G
	endm

*
*	Y成分計算マクロ
*
conv_y	macro	out
      move.l  R02990(a4,d3.w),out
      add.l   G05870(a4,d2.w),out
      add.l   B01140(a4,d1.w),out
	endm
*
*	U成分計算マクロ
*
conv_u	macro	out
      move.l  R01684(a4,d3.w),out
      add.l   G03316(a4,d2.w),out
      add.l   R05000(a4,d1.w),out
	endm
*
*	U成分計算マクロ2
*
conv_ua	macro	out
      add.l   R01684(a4,d3.w),out
      add.l   G03316(a4,d2.w),out
      add.l   R05000(a4,d1.w),out
	endm
*
*	V成分計算マクロ
*
conv_v	macro	out
      move.l  R05000(a4,d3.w),out
      add.l   G04187(a4,d2.w),out
      add.l   B00813(a4,d1.w),out
	endm
*
*	V成分計算マクロ2
*
conv_va	macro	out
      add.l   R05000(a4,d3.w),out
      add.l   G04187(a4,d2.w),out
      add.l   B00813(a4,d1.w),out
	endm
*
*  VRAM to YUV
*	a0	VRAM(w)
*	a1	Ydata(w)
*	a2	Udata(w)
*	a3	Vdata(w)
*
*
VRAM_to_YUV
  movea.l  a6,a4
  adda.l   #RGB_YUV_TBL,a4
  movea.l  HScroll_size(a6),a5
  moveq.l  #8-1,d6
ry10
    moveq.l  #8-1,d7
ry20
      VtoRGB  (a0)+
      conv_y  d0
      move.l  d0,(a1)+  * Y

      conv_u  d0
      move.l  d0,(a2)+  * U

      conv_v  d0
      move.l  d0,(a3)+  * V
*
    dbra.w    d7,ry20
  lea     -8*2(a0,a5.l),a0
  dbra.w    d6,ry10
  rts
*





VRAM_to_YUV2
  movea.l  a6,a4
  adda.l   #RGB_YUV_TBL,a4
  movea.l  HScroll_size(a6),a5
  moveq.l  #8-1,d6
ry210
    moveq.l  #4-1,d7
ry220
      VtoRGB  (a0)+
      conv_y  d0
      move.l  d0,(a1)+  * Y
      conv_u  d4
      conv_v  d5

      VtoRGB  (a0)+
      conv_y  d0
      move.l  d0,(a1)+  * Y
      conv_ua d4
      conv_va d5

      asr.l   #1,d4
      asr.l   #1,d5
      move.l  d4,(a2)+  * U
      move.l  d5,(a3)+  * V
*
    dbra.w    d7,ry220

    lea.l    (-8+8*8)*4(a1),a1
    moveq.l  #4-1,d7
ry230
      VtoRGB  (a0)+
      conv_y  d0
      move.l  d0,(a1)+  * Y
      conv_u  d4
      conv_v  d5

      VtoRGB  (a0)+
      conv_y  d0
      move.l  d0,(a1)+  * Y
      conv_ua d4
      conv_va d5

      asr.l   #1,d4
      asr.l   #1,d5
      move.l  d4,(a2)+  * U
      move.l  d5,(a3)+  * V
*
    dbra.w    d7,ry230

  lea.l   (-8-8*8+8)*4(a1),a1
  lea     -8*2*2(a0,a5.l),a0
  dbra.w    d6,ry210
  rts






VRAM_to_YUV4
  movea.l  a6,a4
  adda.l   #RGB_YUV_TBL,a4
  movea.l  HScroll_size(a6),a5
  moveq.l  #4-1,d6
ry410
    moveq.l  #4-1,d7
ry420
      VtoRGB  (a0)+
      conv_y  d0
      move.l  d0,(a1)+  * Y
      conv_u  d4
      conv_v  d5

      VtoRGB  (a0)+
      conv_y  d0
      move.l  d0,(a1)+  * Y
      conv_ua  d4
      conv_va  d5

      VtoRGB  -4(a0,a5.l)
      conv_y  d0
      move.l  d0,(-2+1*8)*4(a1)  * Y
      conv_ua  d4
      conv_va  d5

      VtoRGB  -2(a0,a5.l)
      conv_y  d0
      move.l  d0,(-1+1*8)*4(a1)  * Y
      conv_ua  d4
      conv_va  d5

      asr.l   #2,d4
      asr.l   #2,d5
      move.l  d4,(a2)+  * U
      move.l  d5,(a3)+  * V
*
    dbra.w    d7,ry420

    lea.l    (-8+8*8)*4(a1),a1
    moveq.l  #4-1,d7
ry430
      VtoRGB  (a0)+
      conv_y  d0
      move.l  d0,(a1)+  * Y
      conv_u  d4
      conv_v  d5

      VtoRGB  (a0)+
      conv_y  d0
      move.l  d0,(a1)+  * Y
      conv_ua  d4
      conv_va  d5

      VtoRGB  -4(a0,a5.l)
      conv_y  d0
      move.l  d0,(-2+1*8)*4(a1)  * Y
      conv_ua  d4
      conv_va  d5

      VtoRGB  -2(a0,a5.l)
      conv_y  d0
      move.l  d0,(-1+1*8)*4(a1)  * Y
      conv_ua  d4
      conv_va  d5

      asr.l   #2,d4
      asr.l   #2,d5
      move.l  d4,(a2)+  * U
      move.l  d5,(a3)+  * V
*
    dbra.w    d7,ry430

  lea.l   (-8-8*8+8*2)*4(a1),a1
  lea.l   -8*2*2(a0,a5.l),a0
  adda.l  a5,a0
  dbra.w    d6,ry410
  rts
  .end
