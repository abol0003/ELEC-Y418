;
; Task4.asm
;
; Created: 28-02-25 14:24:30
; Author : alexb
;

.INCLUDE "m328pdef.inc"
.ORG 0x000
RJMP init

init:
    SBI DDRB,1 ; set buzzer as an output
    CBI PORTB,1
    SBI DDRC,3
    CBI PORTC,3

main:
    SBI PORTC,3
	SBI PINB,1
    RCALL DELAY
    CBI PORTC,3
	CBI PINB,1
    RCALL DELAY
    RJMP main

DELAY:
    LDI R16,255
L1:
    LDI R17,255
L2:
    DEC R17
    BRNE L2
    DEC R16
    BRNE L1

	;SBI PINC,2 permet de invert le bit
    RET


