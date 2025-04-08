;------------------------------------------------------------
; DisplayLine : Affiche une ligne du buffer sur l��cran
;------------------------------------------------------------
InitScreen:
    LDI R16, (1<<3)|(1<<4)|(1<<5)
    OUT DDRB, R16
    CBI PORTB, 3
    CBI PORTB, 4
    CBI PORTB, 5

ClearScreen:
    PUSH ZL
    PUSH ZH
    PUSH R16
    PUSH R17
    LDI ZL, low(0x0100)
    LDI ZH, high(0x0100)
    LDI R16, 0       ; Valeur z�ro pour effacer
    LDI R17, 70      ; Nombre d�octets � effacer
clear_loop:
    ST Z+, R16      ; �crire 0 dans le buffer et incr�menter le pointeur
    DEC R17
    BRNE clear_loop

	POP R16
    POP R17
    POP ZH
    POP ZL
    RET
DisplayLine:
	PUSH	R0
	PUSH	R1
	PUSH	R16
	PUSH	R17
	PUSH	R20
	PUSH	ZL
	PUSH	ZH
	IN		R16,	SREG
	PUSH	R16

	LDI		ZH,		high(0x0100)
	LDI		ZL,		low(0x0100)

	LDI		R16,	5
	MUL		R16,	R24
	ADD		ZL,		R0
nbByte_line:
	LDI R16, 10 ;number of byte to send at same time
DisplayLineLoop:
	LD		R20,	Z+
	CALL	pushByte

	CPI		R16,	6
	BRNE	HighScreen

	ADIW	Z,		6*5

	SBI		PINB,	4

HighScreen:
	DEC		R16
	BRNE	DisplayLineLoop
	LDI		R20,	0x80
	; the goal is to transform the column number into binaire
	SBRC	R24,	2 ; if bit 2 is 0 then Swap is skipped
	SWAP	R20

	SBRC	R24,	0
	LSR		R20

	SBRS	R24,	1
	RJMP	EnableLine
	
	LSR		R20
	LSR		R20

EnableLine:
	CALL	pushByte
	SBI		PINB,	4
	DEC		R24
	BRGE	endScreen
	LDI		R24,	6

endScreen:
	POP		R16
	OUT		SREG,	R16
	POP 	ZH
	POP 	ZL
	POP 	R20
	POP		R17
	POP 	R16
	POP		R1
	POP		R0
	RETI

pushByte:
	LDI		R17,	8
pushByteLoop:
	CBI		PORTB,	3
	BST		R20,	0 ; prend le bit numero b de R20 et le met dans le bit T
	BRTC	send			;Branch if T Flag Cleared
	SBI		PORTB,	3
send:
	SBI		PINB,	5
	SBI		PINB,	5
	LSR		R20 ; decal vers la droite le bit 0 est mis dans le carry
	DEC		R17
	BRNE	pushByteLoop
	RET