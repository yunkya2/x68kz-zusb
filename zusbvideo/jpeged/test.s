

	rept 4
		add.w	d5,d5		#4
		addx.w	d2,d2		#4
		subq.w	#1,d6		#4
		bne	@f		#10
		inGetC
@@
		move.b	(a1)+,d0	#8
		sub.w	d0,d2		#4
		bcs	Decode1		#10
		adda.l	d0,a1		#6
	endm
		bra	ReadError
decode1
		add.w	d0,d2		#4
		move.b	(a1,d2.w),d0	#14

	1bit“–‚½‚è	12+10 +12+16=50
			12+10 +4+14+10=50

	—t		4+14	=18
			4+14+4	=22
