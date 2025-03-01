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
CBI DDRB,2
SBI PORTB,2

SBI DDRC,2
SBI PORTC,2

main:
IN R0,PINB
BST R0,2
; quand on appuie sur le bouton PB2 etat low

BRTC JoyPressed
JoyNotPressed:
SBI PORTC,2
RJMP main

JoyPressed:
CBI PORTC,2 ; on met à l'état low pour que le courant passe et que ca conduit 
RJMP main