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
		mov.w		#00006h, R7
		mov.w		#00004h, R8
		mov.w		#00000h, R9

;configure led 2
		mov.b	#00000000b, &P6SEL0
		mov.b	#00000000b, &P6SEL1

		bis.b	#01000000b, &P6DIR	;set as output
		bic.b	#01000000b, &P6OUT	;set inital value to zero

;confiugure output pins p6

		mov.b	#0000h, &P6SEL0
		mov.b	#0000h, &P6SEL1

		bis.b	#01111b,		&P6DIR	;set p6 as an output
		bis.b	#00001111b, 	&P6REN	;enable resistor on  p4.1
		bic.b	#00001111b, 	&P6OUT	;set as down resistor


;configure switch 2
		bic.b	#BIT3,	&P2DIR	;set p4.1 as an input 	p4.1 = s1
		bis.b	#BIT3,	&P2REN	;enble pull down resisotrs on p4.1
		bis.b	#BIT3,	&P2OUT	;make the resistor a pull up

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
;setting all outputs to high

		mov.b	#00000000b, &P6OUT		;all leds off
		mov.b	#01001111b, &P6OUT		;all leds on
		mov.w	&P2IN, 	R4		;set up r4
		mov.b	&P5IN, 	R5		;set up r5
		mov.b	#00000000b, &P6OUT		;turn leds off

		jmp 	start

endTest:

		jmp 		test

;-------------------------------------------------------------------------------
; Start code here
;-------------------------------------------------------------------------------
start:

while:
		mov.w		&P2IN, 			R4
		cmp			#0800h, 		R4	;sw
		jz			while				;jump back to while if not zero
		mov.b		#01000000b,	&P6OUT	;else turn off and step to test

test:

		mov.b		&P5IN, R5			;move the vlaues of the switches to R5

if_1111:								;test case 0000
		cmp			#1111b, R5
		jz			led1010				;jump to turn on all leds

if_1101:								;test case 0001
		cmp 		#1101b, R5
		jz			ledEqR7				;jump to turn on leds equaling R7

if_0010:
		cmp			#0010b, R5			;test case 0010
		jz			rolR9				;set leds equal to value in r9
		jmp 		test				;return to test


led1010:
		mov.b	 #00001010b, &P6OUT		;turn on leds
		jmp 	test					;jump back to test

ledEqR7:
		mov.b	R7,		&P6OUT			;turn on leds
		jmp 	test					;back to test

rolR9:
		rla.b	R8						;rotate r9 left by 1
		mov.b	R8, &P6OUT				;move the binary code of r9 into leds
		jmp 	endTest					;jumps to end test to complete loop


;-------------------------------------------------------------------------------
; Memory Allocation
;-------------------------------------------------------------------------------
			.data
			.retain
word1:		.short 	01010h
word2:		.short	00101h
word34:		.space	4

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
            
