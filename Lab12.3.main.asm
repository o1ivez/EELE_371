;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Oliver Gough, EELE 371, 3/6/24
;
;led 1 10% duty, timer 0
;TB0CCR0 = (1/32768 sec)(1)(1)(32768) =  1 sec
;TB0CCR1 = (1/32768 sec)(1)(1)(29491) = .9 sec


;led 2 90% duty, timer 1
;TB1CCR0 = (1/32768 sec)(1)(1)(32768) =  1 sec
;TB1CCR1 = (1/32768 sec)(1)(1)(3277) = .1 sec
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

		;led 1 10% duty, timer 0
		;TB0CCR0 = (1/32768 sec)(1)(1)(32768) =  1 sec
		;TB0CCR1 = (1/32768 sec)(1)(1)(29491) = .9 sec

		bis.w		#TBCLR, &TB0CTL
		bis.w		#TBSSEL__ACLK, &TB0CTL
		bis.w		#MC__UP, &TB0CTL

		bis.w		#32768, &TB0CCR0
		bis.w		#29491,  &TB0CCR1

		bis.w		#CCIE, &TB0CCTL0
		bic.w		#CCIFG, &TB0CCTL0

		bis.w		#CCIE, &TB0CCTL1
		bic.w		#CCIFG, &TB0CCTL1

		;led 2 90% duty, timer 1
		;TB1CCR0 = (1/32768 sec)(1)(1)(32768) =  1 sec
		;TB1CCR1 = (1/32768 sec)(1)(1)(3277) = .1 sec

		bis.w		#TBCLR, &TB1CTL
		bis.w		#TBSSEL__ACLK, &TB1CTL
		bis.w		#MC__UP, &TB1CTL

		bis.w		#32768, &TB1CCR0
		bis.w		#3277,  &TB1CCR1

		bis.w		#CCIE, &TB1CCTL0
		bic.w		#CCIFG, &TB1CCTL0

		bis.w		#CCIE, &TB1CCTL1
		bic.w		#CCIFG, &TB1CCTL1

		bis.w		#GIE, SR

;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

main:
		jmp 		main
                                            
;-------------------------------------------------------------------------------
; Interupt service routienes
;-------------------------------------------------------------------------------

LED_1_ON:
		bic.b		#BIT0, &P1OUT
		bic.w		#CCIFG,  &TB0CCTL0
		reti
;---------------------------------------------------------------------------------
LED_1_OFF:
		bis.b		#BIT0, &P1OUT
		bic.w		#CCIFG,  &TB0CCTL1
		reti
;---------------------------------------------------------------------------------
LED_2_On:
		bic.b		#BIT6,   &P6OUT
		bic.w		#CCIFG,  &TB1CCTL0
		reti
;---------------------------------------------------------------------------------
LED_2_OFF:
		bis.b		#BIT6,   &P6OUT
		bic.w		#CCIFG,  &TB1CCTL1
		reti
;---------------------------------------------------------------------------------

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
            .short 	LED_1_ON

            .sect 	".int42"
            .short	LED_1_OFF

             .sect	".int41"
            .short 	LED_2_On

            .sect 	".int40"
            .short	LED_2_OFF
