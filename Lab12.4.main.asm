;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Oliver Gough, EELE 371, 3/6/24
;
;led 1 10% duty, timer 0
;TB0CCR0 = (1/32768 sec)(1)(1)(32768) =  1 milisec
;TB0CCR1 = (1/32768 sec)(1)(1)(29491) = .9 milisec
;
;R4 == delay once counter
;R6 == PMW Time period
;R7 == PMW Duty cycle
;R8 == minimum duty cycle allowed
;R9 == max duty cycle allowed
;R10 == duty cycle step size
;R11 == enable
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
;setting up registers
		mov.w 		#0000h, R4
		mov.w 		#01050d, R6
		mov.w 		#00250d, R7
		mov.w 		#0000h, R8
		mov.w 		#0000h, R9
		mov.w 		#0025d, R10
		mov.w		#0000h, R11
;setting up led 1
		bis.b		#BIT0, &P1DIR
		bic.b		#BIT0, &P1OUT
;setting up led 2
		bis.b		#BIT6, &P6DIR
		bic.b		#BIT6, &P6OUT
;setting up s1 as port intetupt
		bic.b		#BIT1,	&P4DIR
		bis.b		#BIT1,	&P4REN
		bis.b		#BIT1,	&P4OUT
		bic.b		#BIT1,	&P4IES		;low to high
;setting up s2 as port intetupt
		bic.b		#BIT3,	&P2DIR
		bis.b		#BIT3,	&P2REN
		bis.b		#BIT3,	&P2OUT
		bic.b		#BIT3,	&P2IES		;low to high
;set outputs
		bic.b		#LOCKLPM5, &PM5CTL0
;setting up timers
		;led 1 10% duty, timer 0
		;TB0CCR0 = (1/32768 sec)(1)(1)(32768) =  1 sec
		;TB0CCR1 = (1/32768 sec)(1)(1)(29491) = .9 sec
		bis.w		#TBCLR, &TB0CTL
		bis.w		#TBSSEL__SMCLK, &TB0CTL
		bis.w		#MC__UP, &TB0CTL

		mov.w		R6, &TB0CCR0
		mov.w		R7,  &TB0CCR1

		bis.w		#CCIE, &TB0CCTL0
		bic.w		#CCIFG, &TB0CCTL0

		bis.w		#CCIE, &TB0CCTL1
		bic.w		#CCIFG, &TB0CCTL1

;clearing the interupt flags
		bic.b		#BIT1,	&P4IFG
		bis.b		#BIT1,	&P4IE
		bic.b		#BIT3,	&P2IFG
		bis.b		#BIT3,	&P2IE
;setting global interupt enable
		bis.b		#GIE, 	SR

;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
main:
		cmp			#0001b, R11
		jnz 		main
		call		#flashGreenLed
		mov.w		#0000b, R11
		jmp 		main

;-------------------------------------------------------------------------------
; Subroutienes
;-------------------------------------------------------------------------------
;delays the counter one time by counting down from #FFFFh and resurns
delayOnce:
		mov.w		#0FFFFh, R4
midDelay:
		dec			R4
		cmp			#000h, 	R4
		jnz			midDelay
		ret
;-------------------------------------------------------------------------------
;turns leds on, calls delay once,  turns leds off and returns
flashGreenLed:
		xor.b		#BIT6, 	&P6OUT
		call 		#delayOnce
		xor.b		#BIT6, 	&P6OUT
		ret
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; Interupt service routienes
;-------------------------------------------------------------------------------
;turns led 1 on and clears flags, tied to orignail times
LED_1_ON:
		bis.b		#BIT0, &P1OUT
		bic.w		#CCIFG,  &TB0CCTL0
		reti
;---------------------------------------------------------------------------------
;turns led 1 off and clears flags, tied to compare timer
LED_1_OFF:
		bic.b		#BIT0, &P1OUT;look into fixing this as it may change how pmw is handeled by system
		bic.w		#CCIFG,  &TB0CCTL1
		reti
;---------------------------------------------------------------------------------
;compares to max value, if == mov 01 to r11 to enavle flash code and skip to end of isr,
;elese incrase the pmw (need to learn how to chnage the timer from the isr)
increasePMW:
		cmp			#00500d, R7
		jz			setEnable1InISR
		jmp			moveOnInIsr1
setEnable1InISR:
		mov.w		#00001b, R11; enables code in main loop
		jmp			moveOnInIsr1
moveOnInIsr1:
		cmp			#00500d, R7
		jz			increasePMWfinal
		add.w		R10, R7
		mov.w		R7,  &TB0CCR1

		;bis.w		R7,  &TB0CCR1	(set the timer to new time)
increasePMWfinal:
		bic.b		#BIT1, &P4IFG
		reti
;---------------------------------------------------------------------------------
;compares to min value, if == mov 01 to r11 to enavle flash code and skip to end of isr,
;elese decrase the pmw (need to learn how to chnage the timer from the isr)
decreasePMW:
		cmp			#0025d, R7
		jz			setEnable2InISR
		jmp			moveOnInIsr2
setEnable2InISR:
		mov.w		#00001b, R11; enables code in main loop
		jmp			moveOnInIsr2
moveOnInIsr2:
		cmp			#0025d, R7
		jz			decreasePMWfinal
		sub.w		R10, R7
		mov.w		R7,  &TB0CCR1
decreasePMWfinal:
		bic.b		#BIT3, &P2IFG
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
            
            .sect	".int22"
            .short	increasePMW				;swtich 1 interupt service rountiene

            .sect	".int24"
            .short	decreasePMW				;switch 2 interupt service routinene

            .sect	".int43"
            .short 	LED_1_ON

            .sect 	".int42"
            .short	LED_1_OFF
