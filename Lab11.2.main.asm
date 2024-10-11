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

;configure p3.0 - p3.3 as outputs

			mov.b	#0000h, &P3SEL0
			mov.b	#0000h, &P3SEL1

			bis.b	#01111b,		&P3DIR	;set p6 as an output
			bis.b	#00001111b, 	&P3REN	;enable resistor on  p4.1
			bic.b	#00001111b, 	&P3OUT	;set as down resistor

;setting up s1 as port intetupt
			bic.b	#BIT1,	&P4DIR
			bis.b	#BIT1,	&P4REN
			bis.b	#BIT1,	&P4OUT
			bic.b	#BIT1,	&P4IES		;low to high
;setting up s2 as port intetupt
			bic.b	#BIT3,	&P2DIR
			bis.b	#BIT3,	&P2REN
			bis.b	#BIT3,	&P2OUT
			bic.b	#BIT3,	&P2IES		;low to high
;clear high z
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
			jmp 	blinkGreen

blinkGreen:
			xor.b	#BIT6, P6OUT		;toggle led 1
			jmp 	longDelay

longDelay:
			mov.w	#0FFFFh, R4
			call 	#delayOnce			;call delay once
			jmp 	main

;-------------------------------End BlinkGreen-----------------------------------


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

flashLeds:
			mov.w	R6,	&P3OUT
			call	#delayOnce
			mov.w	#0000b,	&P3OUT
			ret


;-------------------------------------------------------------------------------
; Interupt service routienes
;-------------------------------------------------------------------------------

;counts up by 1, cannot go above 15d if it trys flash output led
countUp1:
			cmp			#01111b, R6
			jz			flashLeds
			inc			R6
			mov.w		R6, &P3OUT
			bic.b		#BIT1, &P4IFG
			reti
;----------------------------------END COUNTUP1---------------------------------

;counts down by 2, cannot go below 2d if it trys flash output led
countDown2:
			cmp			#00b, R6
			jz			flashLedsIn
			cmp			#01,  R6
			jz			flashLedsIn
			cmp			#02d, R6
			jz			flashLedsIn
			jmp			countDown2Fin

flashLedsIn:
			mov.w		R6,	&P3OUT
			call		#delayOnce
			mov.w		#0000b,	&P3OUT
			jmp 		retiFin


countDown2Fin:
			sub.w 		#02d, R6
			call		#flashLeds
retiFin:
			bic.b		#BIT3, &P2IFG
			reti
;----------------------------------END COUNTDOWN2-------------------------------

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
            .short	countUp1		;swtich 1 interupt service rountiene

            .sect	".int24"
            .short	countDown2		;switch 2 interupt service routinene
