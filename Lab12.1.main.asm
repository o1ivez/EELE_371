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

		;timer for led2, TB0, 1 sec
		mov.w		#0000100111100010b, &TB0CTL

		;timer for led2, TB1, 2 sec
		bis.w		#TBCLR, &TB1CTL
		bis.w		#TBSSEL__ACLK, &TB1CTL
		bis.w		#MC__CONTINUOUS, &TB1CTL
		bis.w		#TBIE, &TB1CTL
		bic.w		#TBIFG, &TB1CTL
b
		bis.w		#GIE, SR

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
		bic.w		#TBIFG, &TB1CTL
		reti
;-------------------------------------------------------------------------------
ISR_1_Sec_Led_2_On_Off:
		xor.b		#BIT6, &P6OUT
		bic.w		#TBIFG, &TB0CTL
		reti
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
            
            .sect	".int42"
            .short	ISR_1_Sec_Led_2_On_Off


            .sect	".int41"
			.short	ISR_2_Secs_Led_1_On_Off
