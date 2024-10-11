;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Oliver Gough, EELE 371, 3/1/24
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
; Init code here
;-------------------------------------------------------------------------------

init:
;setting up registers
			mov.w 	#00000h, R4
			mov.w 	#00000h, R5
			mov.w 	#00000h, R6
			mov.w 	#00000h, R7

;configure led 1
			bis.b	#BIT0, 	&P1DIR
			bic.b	#BIT0, 	&P1OUT

;configure led 2
			bis.b	#BIT6, 	&P6DIR
			bic.b	#BIT6, 	&P6OUT

;setting up s1 as port intetupt
			bic.b	#BIT1,	&P4DIR
			bis.b	#BIT1,	&P4REN
			bis.b	#BIT1,	&P4OUT
			bis.b	#BIT1,	&P4IES		;high to low

;setting up s2 as port intetupt
			bic.b	#BIT3,	&P2DIR
			bis.b	#BIT3,	&P2REN
			bis.b	#BIT3,	&P2OUT
			bic.b	#BIT3,	&P2IES		;low to high

			bic.b	#LOCKLPM5, &PM5CTL0

;clearing the interupt flags
			bic.b	#BIT1,	&P4IFG
			bis.b	#BIT1,	&P4IE

			bic.b	#BIT3,	&P2IFG
			bis.b	#BIT3,	&P2IE
;setting global interupt enable
			bis.b	#GIE, 	SR



;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

main:
			mov.w	#05d, 	R5			;this makes it so it delays 5 times
			jmp 	blinkRed

blinkRed:
			xor		#01h, &P1OUT		;toggle led 1
			jmp 	longDelay

longDelay:
			mov.w	#0FFFFh, R4
			call 	#delayOnce			;call delay once
			jmp 	main



;-------------------------------End BlinkRed-----------------------------------

			jmp 	main


;--------------------END MAIN---------------------------------------------------

;-------------------------------------------------------------------------------
; Subroutienes
;-------------------------------------------------------------------------------
;delay the dec r4 by r5 amount of times
delayOnce:
			dec		R4
			cmp		#000h, 	R4
			jnz		delayOnce
			dec 	R5
			cmp		#000h, 	R5
			jnz		delayOnce
			ret


;-------------------------------------------------------------------------------
; Interupt service routienes
;-------------------------------------------------------------------------------

;service switch one
;toggle led 1
switch1Triggered:
			xor.b		#BIT6, P6OUT
			bic.b		#BIT1, &P4IFG
			reti

;---------------------------END SWITCH1TRIGGERED--------------------------------

;service switch two turn led 2 on and delay and turn off
switch2Triggered:
			mov.w		R5, R7
			mov.w		#03h, R5

			xor.b		#BIT6, P6OUT
			call 		#delayOnce
			xor.b		#BIT6, P6OUT

			mov.w		R7, R5
			bic.b		#BIT3, &P2IFG
			reti

endISR2:

;-----------------------------------END ISR2------------------------------------

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
            .sect	".int22"
            .short	switch1Triggered		;swtich 1 interupt service rountiene

            .sect	".int24"
            .short	switch2Triggered

