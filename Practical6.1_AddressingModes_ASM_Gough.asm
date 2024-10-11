;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Oliver Gough, EELE 371, 2/5/24
;
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
; Main loop here
;-------------------------------------------------------------------------------

;this code is made to move stuff
init:

		mov.w	#02000h, R4 ;move 2000h into r4
		mov.w	R4, R5		;r4 into r5
		mov.w	#Var1, R6	;move var1 into r6

main:

		mov.w	&02000h, R7 ;move mem addrs 2000 into r7
		mov.w	Con2, R8	;move cont 2 into r8
		mov.w	@R4, R9		;move val in r4 to r9

		mov.w	@R5+, R10	;move info from meme location 2002 into r10
		mov.w	@R5+, R11	;move info from mem loc 2004 to r11

		mov.w	2(R4), 2(R6)	;move 2nd bir of r4 inro 2nd bit r6

		jmp		main


;-------------------------------------------------------------------------------
; Memory Allocation
;-------------------------------------------------------------------------------
			.data
			.retain
Con1:		.short	0ACEDh		;defieing costants
Con2:		.short	0BEEFh		;defining constants again
Var1:		.space 	28			;makeing space for 28 bits

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
            
