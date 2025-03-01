;
; Task3.asm
;
; Created: 28-02-25 15:57:22
; Author : alexb
;


.INCLUDE "m328pdef.inc"
.ORG 0x000
RJMP init

init:
    CBI DDRB,0
    SBI PORTB,0
    SBI DDRC,3
    CBI PORTC,3

main:
    SBI PORTC,3
    RCALL DELAY
    CBI PORTC,3
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


;DELAY:
 ;   LDI R16,255
;L1:
 ;   LDI R17,255
;L2:
;	LDI R18,255
;L3:
 ;   DEC R18
  ;  BRNE L3
   ; DEC R17
    ;BRNE L2
;	DEC R16
;	BRNE L1


	;SBI PINC,2 permet de invert le bit
 ;   RET