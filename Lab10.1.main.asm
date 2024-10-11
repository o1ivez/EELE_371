;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Oliver Gough, EELE 371, 2/26/24
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
; Init code
;-------------------------------------------------------------------------------
init:
;configure led 1
		mov.b	#000h, &P1SEL0 ;setting bits of led2
		mov.b	#000h, &P1SEL1

		bis.b	#00000001b, &P1DIR	;set as output
		bic.b	#00000001b, &P1OUT	;set inital value to zero

;configure led 2
		mov.b	#000h, &P6SEL0 ;setting bits of led2
		mov.b	#000h, &P6SEL1

		bis.b	#01000000b, &P6DIR	;set as output
		bic.b	#01000000b, &P6OUT	;set inital value to zero

;clearing registers

		mov.w	#00000h, R4
		mov.w	#02000h, R5
		mov.w	#00000h, R6

;Disable digital I/O low power default
		bic.b	#LOCKLPM5, &PM5CTL0

;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
main:
;re clearing regeistoers for when code loops
		mov.w	#00000h, R4
		mov.w	#02000h, R5
		mov.w	#00000h, R6
;setting up counting variable
		mov.w 	#016d, 	R6

while1:
;while count != 0, R6 == count
		dec R6


pushLoop:
;pushes data 16 times and jumps when count != 0, code will run secquantualy when count == 0
		push	@R5+
		cmp		#000d, R6
		jnz		while1

endPushLoop:
;resetting regisiters for pop loop
		mov.w	#02000h, R4

while2:
;while count != 0, R6 == count
		mov.w	#016d, R6

popLoop:
;pushes data 16 times and jumps when count == 0
		dec 	R6
		pop		R5

;calling add 3 to add 3 to the regiseters values, comment out when doing demo 1
		call	#add3

;moves data to proper location in memory
		mov.w	R5, 0(R4)
		add.w	#02d, R4

;compares with the value of r6 to know when to jump
		cmp		#0000d, R6
		jnz		popLoop

endPopLoop:
;repeat the code
		jmp 	main


;-------------------------------------------------------------------------------
; Add3 subroutiene
;-------------------------------------------------------------------------------
add3:

		add.w 	#03h,	R5
		ret


;-------------------------------------------------------------------------------
; Memeor allocation
;-------------------------------------------------------------------------------
			.data
			.retain
init0:		.short 	00000h
init1:		.short 	01111h
init2:		.short 	02222h
init3:		.short 	03333h
init4:		.short 	04444h
init5:		.short 	05555h
init6:		.short  06666h
init7:		.short 	07777h
init8:		.short 	08888h
init9:		.short 	09999h
initA:		.short 	0AAAAh
initB:		.short 	0BBBBh
initC:		.short 	0CCCCh
initD:		.short 	0DDDDh
initE:		.short 	0EEEEh
initF:		.short 	0FFFFh
zeros: 		.space	32

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
            
