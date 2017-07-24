;**** A P P L I C A T I O N   N O T E   A V R 3 0 5 ************************
;*
;* Title		: Half Duplex Interrupt Driven Software UART
;* Version		: 1.1
;* Last updated		: 97.08.27
;* Target		: AT90Sxxxx (All AVR Device)
;*
;* Support email	: avr@atmel.com
;*
;* Code Size		: 32 Words
;* Low Register Usage	: 0
;* High Register Usage	: 4
;* Interrupt Usage	: None
;*
;* DESCRIPTION
;* This Application note contains a very code efficient software UART.
;* The example program receives one character and echoes it back.
;***************************************************************************


;***** Pin definitions

.def	TxBuf		= r19
.def	RxBuf		= r21


; *** RECIEVE CHARACTER:
;     Routine to poll status register and write UART data to RxBuf
RXchar:	sbis	USR,	7	; Bit 7 = Got data
	rjmp	RXchar
	in	RxBuf,	UDR
	ret

; *** TRANSMIT CHARACTER:
;     Routine to poll status register and write TxBuf to UART
TXchar:	;sbis	USR,	5	; Bit 5 = Tx Ready
	;rjmp	TXchar
	;out	UDR, 	TxBuf
	ret

