.include "8515def.inc"

; Scratch registers
.def 	Temp      = r16
.def 	Temp2 	  = r17
.def	Temp3	  = r18
.def	Temp4	  = r28

; Modem Port Definitions
.equ	MDM_PORT   	=   PORTA
.equ	MDM_PIN		=   PINA
.equ    MDM_DDR		=   DDRA

.def	Time		= r10

; Modem Pin Definitions
.equ    mdm_RXD   =   0  ; Input
.equ	mdm_TXD   =   1  ; Output
.equ	mdm_M0    =   2  ; O
.equ	mdm_M1    =   3  ; O
.equ	mdm_DET   =   4  ; I
.equ	mdm_RDY   =   5  ; I
.equ	mdm_CLK   =   6  ; O
.equ	mdm_PTT	  =   7  ; O

.equ	TXDelay   =   50 ; Number of flags to send before packet.
.equ	TXHang    =   50 ;   "                  "  after     "  .

; Modem Control Register (not a physical register, but a software one.
.def	mdm_Control	= r25
.equ	mdm_BSEnable	= 0	; Bit Stuffing Enable
.equ	mdm_CRCEnable	= 1

; Modem Scratch Registers
.def	mdm_CRCh	= r22	; CRC Hi Byte
.def	mdm_CRCl	= r23	; CRC Lo Byte
.def	mdm_StuffCount	= r24	; History of last few bits (for stuffing)


		; *** Interrupt vector table

		rjmp	RESET	; External reset, Power-on reset, Watchdog reset
		reti		; External interrupt 0
		reti		; External interrupt 1
		reti		; Timer/Counter 1 Capture Event
		reti		; T/C 1 Compare Match A
		reti		; T/C 1 Compare Match B
		reti		; T/C 1 Overflow
		reti		; T/C 0 Overflow
		reti		; Serial Xfer complete
		reti		; UART RX complete
		reti		; UART Data Register Empty
		reti		; UART TX complete
		reti		; Analog Comparator

RESET:		ldi	Temp, low(RAMEND)
    		out   	SPL, Temp
    		ldi   	Temp, high(RAMEND)
    		out   	SPH, temp		; Initialize Stackpointer

		ldi	DelayTime, 255		; Set the default delay length

		ldi	Temp, 95
		out	UBRR, Temp		; 2400 bps @ 3.68 MHz
		
		ldi	Temp, (1<<RXEN)|(1<<TXEN)
		out	UCR, Temp		; Enable reciever

		ldi	Temp, 0x00
		out	LCD_PORT, Temp   	; Clear the outputs

		ldi	Temp, 0xFF
		out 	LCD_DDR, Temp 		; Set the direction to output

		; *** PRINT SPLASH MESSAGE *****************************
		
		rcall	LCD_Init
		
		ldi	zl, low(strInit1*2)	; Display First Line
		ldi	zh, high(strInit1*2)
		rcall	LCD_PrintPM

		ldi	Temp,	0b11000000	; Move LCD to the next line.
		rcall	LCD_SendCmd

		ldi	zl, low(strInit2*2)	; Display Second Line
		ldi	zh, high(strInit2*2)
		rcall	LCD_PrintPM
		
		;********************************************************		
		
		rcall	mdm_Init		; Initialize the modem


		; *** READ FROM THE GPS *********************************
		
		; Sample RMC sentence:
		; $GPRMC,230943,A,3024.580,N,09110.844,W,000.0,360.0,010401,001.3,E*61
		;       0123456789012345678901234567890123456789012345678901234567890123456789

		
		; *** Wait for $GPRMC to arrive.
WAIT_DOLLAR:	rcall 	RXchar
		cpi	RxBuf, '$'
		brne	WAIT_DOLLAR
		
		rcall	RXchar
		cpi	RxBuf, 'G'
		brne	WAIT_DOLLAR

		rcall	RXchar
		cpi	RxBuf, 'P'
		brne	WAIT_DOLLAR

		rcall	RXchar
		cpi	RxBuf, 'R'
		brne	WAIT_DOLLAR		
		
		rcall	RXchar
		cpi	RxBuf, 'M'
		brne	WAIT_DOLLAR
		
		rcall	RXchar
		cpi	RxBuf, 'C'
		brne	WAIT_DOLLAR
		
		; If we've made it this far, we need to store the text for processing.

		ldi	r26, low(buffer)
		ldi	r27, high(buffer)

STOREMEM:	rcall	RXchar
		st	X+, RxBuf
		cpi	RxBuf, 13	; store until we hit the carriage return.
		brne 	STOREMEM
		
		; Line has been stored, now send it to the LCD
		; $GPRMC,230943,A,3024.580,N,09110.844,W,000.0,360.0,010401,001.3,E*61
		;       0123456789012345678901234567890123456789012345678901234567890123456789
		;                 1         2         3         4         5         6

		; *** Parse the longitude
		
		rcall	LCD_Clear		; Clear the LCD
				
		ldi	r30, low(buffer)	; Put the memory address in Z.
		ldi	r31, high(buffer)
		
		adiw	r30, 10			; Skip to 10th character.

		ldi	Temp, ' '		; Display a " "
		rcall	LCD_SendChar
		
		ldi	Temp2, 	2		; Print the degrees
		rcall	LCD_PrintMem
		
		ldi	Temp, 0b11011111	; Print the degrees symbol
		rcall	LCD_SendChar
		
		ldi	Temp2,	6		; Print the minutes
		rcall	LCD_PrintMem

		adiw	r30, 1			; Print 'N' or 'S'.
		ldi	Temp2,	1
		rcall	LCD_PrintMem

		ldi	Temp, ' '		; Print a space.
		rcall	LCD_SendChar
		
		; Move back to start of buffer and print the hours and minutes (4 char)
		ldi	r30, low(buffer)	; Put the memory address in Z.
		ldi	r31, high(buffer)
		adiw	r30, 1
		ldi	Temp2, 4
		rcall	LCD_PrintMem
				

		; *** Move to the next line and send latitude
		
		ldi	r30, low(buffer)	; Put the memory address in Z.
		ldi	r31, high(buffer)
		adiw	r30, 20
			
		ldi	Temp,	0b11000000	; Move to the next line.
		rcall	LCD_SendCmd
	
		adiw	r30, 1
		
		ldi	Temp2, 	3		; Degrees
		rcall	LCD_PrintMem
		
		ldi	Temp, 0b11011111	; Degrees Symbol
		rcall	LCD_SendChar
		
		ldi	Temp2,	6		; Minutes
		rcall	LCD_PrintMem

		adiw	r30, 1			; 'E'/'W'
		ldi	Temp2,	1
		rcall	LCD_PrintMem

		ldi	Temp, ' '		; Spaces
		rcall	LCD_SendChar
		ldi	Temp, ' '
		rcall	LCD_SendChar
		ldi	Temp, ' '
		rcall	LCD_SendChar
						
		; Move back to start of buffer and send the seconds.
		ldi	r30, low(buffer)	; Put the memory address in Z.
		ldi	r31, high(buffer)
		adiw	r30, 5
		ldi	Temp2, 2
		rcall	LCD_PrintMem		
		rcall 	TXPacket		; Transmit.
		rjmp	WAIT_DOLLAR		; Repeat the whole process.

;***********************************

		; Set the direction of the IOs
mdm_Init:	push	Temp
		ldi	Temp, (0 << mdm_RXD) | (1 << mdm_TXD) | (1 << mdm_M0) | (1 << mdm_M1) | (0 << mdm_DET) | (0 << mdm_RDY) | (1 << mdm_CLK) | (1 << mdm_PTT)
		out	MDM_DDR, Temp
		rcall	TXDisable
		pop	Temp
		ret
		
		; Put the transmitter in recieve mode.
TXDisable:	push 	Temp
		ldi	Temp, (1 << mdm_M0) | (1 << mdm_M1) | (0 << mdm_CLK) | (1 << mdm_PTT)
		out	MDM_PORT, Temp
		pop	Temp
		ret
		
		; Put the transmitter in transmit mode.
TXEnable:	push	Temp
		ldi	Temp, (1 << mdm_M0) | (0 << mdm_M1) | (0 << mdm_CLK) | (0 << mdm_PTT)
		out	MDM_PORT, Temp
		rcall 	DELAY
		pop	Temp
		ret

; *******

TXPacket:	push 	Temp
		push 	Temp2
		push	Temp3
		
		rcall	TXEnable	; Enable the modem.

		clr	mdm_StuffCount	; Set the ones count to 0.
		ser	mdm_CRCh	; Initialize the CRC to 0xFF
		ser	mdm_CRCl	; Initialize the CRC to 0xFF
		
		; Disable bitstuffing and CRC for flags.
		ldi	mdm_Control, (0<<mdm_BSEnable)|(0<<mdm_CRCEnable)
			
		; Transmit leading flags.
		ldi	Temp,	TXDelay
		ldi	Temp3,	0x7E 	; Flag byte = 01111110b = 7Eh
     StartFlag:	rcall   TXByte
    		dec	Temp
    		brne	StartFlag
    		
		; Enable bitstuffing and CRC for the actual packet.
		ldi	mdm_Control, (1<<mdm_BSEnable)|(1<<mdm_CRCEnable)
    		
    		; Send destination address.
		ldi	r30, low(Dest*2)	; Z lower
		ldi	r31, high(Dest*2)	; Z upper
		lpm			; r0 <-- (Z)
		mov	Temp3, r0	; Make a copy
      SendDest:	rcall	TXByte		; Transmit it.
      		adiw	r30, 1		; Increment address
      		lpm			; r0 <-- (Z)
      		mov	Temp3, r0	; Make a copy
      		cpi	Temp3, 0 	; Null character?
      		brne	SendDest	; Repeat
      	
      		; Send source address
		ldi	r30, low(Source*2)	; Load the memory address (low byte)
		ldi	r31, high(Source*2)	; Load the memory address (high byte)
		lpm				; r0 <-- (Z)
		mov	Temp3, r0		; Make a copy
       SendSrc:	rcall	TXByte			; Transmit it.
      		adiw	r30, 1			; Increment address
      		lpm				; r0 <-- (Z)
      		mov	Temp3, r0		; Make a copy
      		cpi	Temp3, 0 		; Null character?
      		brne	SendSrc			; Repeat      		
    		
    		; *** Transmit Control
    		ldi	Temp3, 0x03		; 0x03 = control byte (UI packet)
    		rcall	TXByte
    		
    		; *** Transmit PID
    		ldi	Temp3, 0xF0		; 0xF0 = PID flag (Pure AX.25)
    		rcall	TXByte
    		
		ldi	r30, low(buffer)	; Put the memory address in Z.
		ldi	r31, high(buffer)
		
		ldi	Temp3, '/'		; Send a '/'		
		rcall	TXByte
		
		adiw	r30, 1

	
		ldi	Temp, 6			; Send the time
      TimeLoop:	ld	Temp3, Z+
      		rcall	TXByte
      		dec	Temp
      		brne	TimeLoop
				
		ldi	Temp3, 'z'		; Send z for Zulu
    		rcall	TXByte	
    		
   		adiw	r30, 3


		ldi	Temp, 7			; Send the longitude
      LongLoop:	ld	Temp3, Z+
      		rcall	TXByte
      		dec	Temp
      		brne	LongLoop
      		
      		adiw	r30, 2
      		ld	Temp3, Z+
      		rcall	TXByte

		ldi	Temp3, '/'
    		rcall	TXByte	
		
		adiw	r30, 1		

		ldi	Temp, 8			; Send the latitude.
      LatLoop:	ld	Temp3, Z+
      		rcall	TXByte
      		dec	Temp
      		brne	LatLoop
      		
      		adiw	r30, 2
      		ld	Temp3, Z+
      		rcall	TXByte

		; Send a message
		ldi	r30, low(Message*2)	; Z lower
		ldi	r31, high(Message*2)	; Z upper
		lpm				; r0 <-- (Z)
      		mov	Temp3, r0		; Make a copy
     SendInfo:	rcall	TXByte			; Transmit it.
      		adiw	r30, 1			; Increment address
      		lpm				; r0 <-- (Z)
      		mov	Temp3, r0		; Make a copy
      		cpi	Temp3, 0 		; Null character?
      		brne	SendInfo		; Repeat 	

    		; Disable CRC calculation and send the CRC		
		ldi	mdm_Control, (1<<mdm_BSEnable)|(0<<mdm_CRCEnable)

	    	com	mdm_CRCl
	    	com	mdm_CRCh
	    	mov	Temp3, mdm_CRCl
    		rcall	TXByte
    		mov	Temp3, mdm_CRCh
    		rcall	TXByte
    		
    		; Disable bit stuffing.
    		ldi	mdm_Control, (0<<mdm_BSEnable)
    		
    		
    		; *** Transmit trailing flags.
	Loop2:	ldi	Temp,	TXHang
		ldi	Temp3,	0x7E ; Flag byte = 01111110b = 7Eh
       EndFlag:	rcall   TXByte
    		dec	Temp
    		brne	EndFlag
    		
		rcall	TXDisable
    	 	
   		pop	Temp3
		pop	Temp2
		pop 	Temp
		ret

TXByte:		push 	Temp
		push 	Temp2
		push	Temp3

		ldi	Temp, 8 ; 8 bits to send.
		
     SendBit:	ror	Temp3	; Move bit-to-send into Carry.
		brcs	TX1

	   TX0:	ldi	Temp2, 0	; Bit to send is a 0.
	   	
	   	sbrc	mdm_Control, mdm_CRCEnable	; Skip if CRC is disabled.
	   	rcall	CalcCRC

	   	rcall	mdm_TX0

	   	; Clear the bits stuffing count
	   	clr	mdm_StuffCount

	   	rjmp	Done
	
	   TX1: ldi	Temp2, 1	; Bit to send is a 1
	   	
	   	sbrc	mdm_Control, mdm_CRCEnable	; Skip if CRC is disabled.
	   	rcall	CalcCRC
	   	
	   	sbrs	mdm_Control, mdm_BSEnable	; Skip if Bit stuffing is disabled.
	   	rjmp 	NoStuff
	   	
		cpi	mdm_StuffCount, 5	; See if we've transmitted 5 ones.
	   	brne	NoStuff			; If not, don't TX 0.
	   	
	   	clr	mdm_StuffCount		; Reset the count.
	   	rcall	mdm_TX0			; This is the stuff bit.

       NoStuff: rcall	mdm_TX1
	  	inc	mdm_StuffCount
	  Done:	dec	Temp
	  	brne	SendBit
		
		pop	Temp3
		pop	Temp2
		pop 	Temp
		ret

		; Check sum routine from Carl Ott.
CalcCRC:	eor   	mdm_CRCl,temp2		; xor lsb
    		lsr     mdm_CRCh		; zero hi bit, rotate 
        	ror     mdm_CRCl		; rotate all, lsb goes into carry
        	brcs	pc+2			; skip on carry set
        	ret
        	ldi	temp2,0x08		; if carry is one, xor in poly
        	eor   	mdm_CRCl,temp2
        	ldi	temp2,0x84
        	eor   	mdm_CRCh,temp2
        	ret

		; *** Waits for ready to go low (it's active low)
mdm_WaitForRdy:	sbic	MDM_PIN, mdm_RDY	; Skip if ready is low
		rjmp	MDM_WaitForRdy		; Repeat
		ret

		; *** Routine to transmit a 0 (Signal transition in NRZI)
mdm_TX0:	rcall	MDM_WaitForRdy		; Wait for Ready
		
		in	Temp2,	mdm_PORT	; Load the current port value
		ldi	Temp4, (1<<mdm_TXD)	; Mask off everything but TXD
		eor	Temp2,	Temp4		; Toggle TXd
		out	mdm_PORT, Temp2		; Send it back to the port

		nop
		sbi	MDM_PORT, mdm_CLK	; Clock the chip
		nop
		cbi	MDM_PORT, mdm_CLK
		ldi	TXBuf, '0'
		rcall	TXChar		
		ret

		; *** Routine to transmit a 1 (No change in NRZI)
mdm_TX1:	rcall	MDM_WaitForRdy		; Wait for Ready
		nop				; Clock the chip
		sbi	MDM_PORT, mdm_CLK
		nop
		cbi	MDM_PORT, mdm_CLK
		ldi	TXBuf, '1'
		rcall	TXChar
		ret

strInit1:	.db	" APRS-On-A-Chip ", 0
strInit2:	.db	"  v0.1  KC5FRP  ", 0
strWait1:	.db	" Sync with GPS: ", 0

Message:	.db	"-PHG2230/Hello from an AVR!", 0

Source:		.db	('K'<<1), ('C'<<1), ('5'<<1), ('F'<<1), ('R'<<1), ('P' << 1), 0x61, 0
Dest:		.db	('W'<<1), ('I'<<1), ('D'<<1), ('E'<<1), (' '<<1), (' ' << 1), 0x60, 0


.include "LCD.asm"
.include "serial.asm"

.dseg
buffer:	.byte 80	; GPS Data Buffer
.eseg
