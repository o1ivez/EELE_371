;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Oliver Gough, EELE 371, 2/23/24
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
;Data initalization
;-------------------------------------------------------------------------------
init:

;setting up regeisters
		mov.w		#00000h, R6
		mov.w		#00001h, R7
		mov.w		#00002h, R8
		mov.w		#00000h, R9

;configure led 1
		mov.b	#000h, &P1SEL0
		mov.b	#000h, &P1SEL1

		bis.b	#00000001b, &P1DIR	;set as output
		bic.b	#00000001b, &P1OUT	;set inital value to zero

;confiugure output pins p6

		mov.b	#0000h, &P6SEL0
		mov.b	#0000h, &P6SEL1

		bis.b	#01111b,		&P6DIR	;set p6 as an output
		bis.b	#00001111b, 	&P6REN	;enable resistor on  p4.1
		bic.b	#00001111b, 	&P6OUT	;set as down resistor


;configure switch 1
		bic.b	#BIT1,	&P4DIR	;set p4.1 as an input 	p4.1 = s1
		bis.b	#BIT1,	&P4REN	;enble pull down resisotrs on p4.1
		bis.b	#BIT1,	&P4OUT	;make the resistor a pull up


;confiugure Input pins p5

		mov.b	#0000h, &P5SEL0 			;setting bits of s3 (FIND A PORT)
		mov.b	#0000h, &P5SEL1

		bic.b	#01111b,		&P5DIR	;set p2.3 as an input
		bis.b	#00001111b, 	&P5REN	;enable resistor on  p4.1
		bis.b	#00001111b, 	&P5OUT	;set as pull up resistor

;Disable digital I/O low power default
		bic.b	#LOCKLPM5, &PM5CTL0


;-------------------------------------------------------------------------------
; Main loop
;-------------------------------------------------------------------------------
main:


		mov.b	#0000b, &P6OUT		;all leds off
		mov.b	#1111b, &P6OUT		;all leds on
		mov.b	#0010b, 	R4		;set up r4
		mov.b	#0000b, 	R5		;set up r5
		mov.b	#0000b, &P6OUT		;turn leds off

		jmp 	start

endTest:

		jmp 		test

;-------------------------------------------------------------------------------
; Start code here
;-------------------------------------------------------------------------------
start:

while:
		mov.w		&P4IN, 	R4
		mov.b 		#00000001b,	&P1OUT	;Red led on
		cmp			#0C00h, 		R4	;sw
		jnz			while				;jump back to while if not zero
		mov.b		#00000000b, &P1OUT	;else turn off and step to test

test:

		mov.b		&P5IN, R5			;move the vlaues of the switches to R5

if_0000:								;test case 0000
		cmp			#0000b, R5
		jz			led1111				;jump to turn on all leds

if_0001:								;test case 0001
		cmp 		#0001b, R5
		jz			ledEqR7				;jump to turn on leds equaling R7

if_0010:
		cmp			#0010b, R5			;test case 0010
		jz			rolR9				;set leds equal to value in r9
		jmp 		test				;return to test


led1111:
		mov.b	 #01111b, &P6OUT		;turn on leds
		jmp 	test					;jump back to test

ledEqR7:
		mov.b	R7,		&P6OUT			;turn on leds
		jmp 	test					;back to test

rolR9:
		rla.b	R9						;rotate r9 left by 1
		mov.b	R9, &P6OUT				;move the binary code of r9 into leds
		jmp 	endTest					;jumps to end test to complete loop


;-------------------------------------------------------------------------------
; Memory Allocation
;-------------------------------------------------------------------------------
			.data
			.retain
word1:		.short 	0ACEDh
word2:		.short	0BEEFh
word34:		.space	8

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
            
