
.def	DelayTime = r20 
.equ	DelayCount1 = 128

; *** Provide millisecond delay (DelayTicks specifies number of ms)
DELAY:	push DelayTime
	push r25

	ldi	r25, DelayCount1

DELAY1:	dec r25
	brne DELAY1
	dec DelayTime
	brne DELAY1
	
	pop r25
	pop DelayTime
	ret
