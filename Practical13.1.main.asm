;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Oliver Gough, EELE 371, 3/20/24
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
;Init code
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

;need to add timers depending on practical instructions.

		;timer for led1, TB0, .25 sec
		;.250 sec = (1/1 000 000 sec)(1)(1)(250000)
		bis.w		#TBCLR, &TB0CTL			;clear timers and dividers
		bis.w		#TBSSEL__SMCLK, &TB0CTL	;1 megahz clock
		bis.w		#MC__UP, &TB0CTL		;chose up mode
		bis.w		#ID__2,	&TB0CTL			;devide by 4

		bis.w		#0FFFFh, &TB0CCR0		;set long count length value
		bis.w		#CCIE, &TB0CCTL0		;chose to devide by
		bic.w		#CCIFG, &TB0CCTL0		;set long

		;timer for led2, TB1, 2 sec
		bis.w		#TBCLR, &TB1CTL			;clear timers and dividers
		bis.w		#TBSSEL__ACLK, &TB1CTL	;32khz clock lentth
		bis.w		#MC__CONTINUOUS, &TB1CTL;contuinus clock
		bis.w		#TBIE, &TB1CTL			;clear flag
		bic.w		#TBIFG, &TB1CTL			;enaable inte

;setting global interupt enable
		bis.b		#GIE, 	SR

;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
main:
		jmp		main

;-------------------------------------------------------------------------------
; Interupt service routienes
;-------------------------------------------------------------------------------

;turns led 2 on and clears flags
TimerB1_2s:
		xor.b		#BIT6, &P6OUT
		bic.w		#TBIFG, &TB1CTL
		reti
;----------------------ISR_1_Sec_Led_2_On_Off END---------------------------------
;turns led 1 off and clears flags
TimerB0_250ms:
		xor.b		#BIT0, &P1OUT
		bic.w		#TBIFG, &TB0CTL
		reti
;------------------------ISR_2_Secs_Led_1_On_Off END----------------------------
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
            .short	TimerB0_250ms			;timer b0, led 1, .25 secs


            .sect	".int40"				;timer B1, led 2, 2 secs
			.short	TimerB1_2s

