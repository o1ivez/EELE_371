;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Oliver Gough, EELE 371, 3/5/24
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
; init code here
;-------------------------------------------------------------------------------

init:

;setting up led 1
		bis.b		#BIT0, &P1DIR
		bic.b		#BIT0, &P1OUT
;setting up led 2
		bis.b		#BIT6, &P6DIR
		bic.b		#BIT6, &P6OUT
;set outputs
		bic.b		#LOCKLPM5, &PM5CTL0
;setting up timers

	;timer 1, .5 sec, led 2
	;.5 sec = (1/32768 sec)(1)(1)(16384)
		bis.w		#TBCLR, &TB0CTL
		bis.w		#TBSSEL__ACLK, &TB0CTL
		bis.w		#MC__UP, &TB0CTL

		bis.w		#16384, &TB0CCR0
		bis.w		#CCIE, &TB0CCTL0
		bic.w		#CCIFG, &TB0CCTL0

	;timer 2, 1 sec, led 1
	;1sec = (1/32768 sec)(1)(1)(32768)
		bis.w		#TBCLR, &TB1CTL
		bis.w		#TBSSEL__ACLK, &TB1CTL
		bis.w		#MC__UP, &TB1CTL

		bis.w		#32768, &TB1CCR0
		bis.w		#CCIE,  &TB1CCTL0
		bic.w		#CCIFG, &TB1CCTL0

		bis.w		#GIE, SR
;
;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
main:
		jmp 		main

;-------------------------------------------------------------------------------
; Interupt service routienes
;-------------------------------------------------------------------------------
ISR_2_Secs_Led_1_On_Off:
		xor.b		#BIT0, &P1OUT
		bic.w		#CCIFG, &TB1CCTL0
		reti

;---------------------ISR_2_Secs_Led_1_On_Off END-------------------------------
ISR_1_Sec_Led_2_On_Off:
		xor.b		#BIT6, &P6OUT
		bic.w		#CCIFG, &TB0CCTL0
		reti

;---------------------ISR_1_Sec_Led_2_On_Off END--------------------------------

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
            
            .sect	".int43"
            .short	ISR_1_Sec_Led_2_On_Off

            .sect	".int41"
			.short	ISR_2_Secs_Led_1_On_Off
