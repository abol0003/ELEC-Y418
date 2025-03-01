;
; Lab1.asm
;
; Created: 28-02-25 14:24:30
; Author : alexb
;


.INCLUDE "m328pdef.inc"
.ORG 0x000
RJMP init

init:
CBI DDRB,0
SBI PORTB,0

SBI DDRC,3
SBI PORTC,3

main:
IN R0,PINB
BST R0,0 ;met dans un autre registre tflag


BRTS switchhigh

switchnothigh:
SBI PORTC,3
RJMP main

switchhigh:
CBI PORTC,3
RJMP main
