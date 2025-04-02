.INCLUDE "M328PDEF.INC"

.CSEG
.ORG 0X0000
RJMP init
.ORG 0x001A
RJMP TIMER1_OVF

; ------------------------------------------------
; Initialisation
; ------------------------------------------------
init:
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16
	LDI R16, LOW(RAMEND)
	OUT SPL, R16

	SBI DDRB, 3
	SBI DDRB, 4
	SBI DDRB, 5
	CBI PORTB, 3
	CBI PORTB, 4
	CBI PORTB, 5

	LDI ZL, low(0x0100)
	LDI ZH, high(0x0100)
	LDI R16, 0
	LDI R17, 70
	RCALL InitScreenBuffer

	LDI R16, 0
	STS TCCR1A, R16
	LDI R16, (1<<CS11)|(1<<CS10)
	STS TCCR1B, R16
	LDI R16, (1<<TOIE1)
	STS TIMSK1, R16
	SEI

	RJMP MAINLOOP

; ------------------------------------------------
; Interruption Timer1
; ------------------------------------------------
TIMER1_OVF:
	PUSH R0
	PUSH R1
	PUSH R16
	PUSH R17
	PUSH R18
	PUSH R19
	PUSH ZL
	PUSH ZH

	RCALL DisplayLine
	INC R18
	CPI R18, 7
	BRLO TimerDone
	LDI R18, 0
TimerDone:
	POP ZH
	POP ZL
	POP R19
	POP R18
	POP R17
	POP R16
	POP R1
	POP R0
	RETI

; ------------------------------------------------
; Initialiser le buffer
; ------------------------------------------------
InitScreenBuffer:
	ST Z+, R16
	DEC R17
	BRNE InitScreenBuffer
	RCALL SnakeInit
	LDI R18, 0
	RET

; ------------------------------------------------
; SnakeInit : Allume une ligne entière
; ------------------------------------------------
SnakeInit:
	LDI R16, 0       ; ligne 0
	LDI R17, 0       ; colonne de départ
	MOV R2, R16
	LDI R20, 40      ; 40 colonnes = 5 octets
SetLineLoop:
	MOV R3, R17
	RCALL SetScreenBit
	INC R17
	DEC R20
	BRNE SetLineLoop
	RET

; ------------------------------------------------
; Allumer un pixel à (R2, R3)
; ------------------------------------------------
SetScreenBit:
	PUSH YL
	PUSH YH
	RCALL GetByteAndMask
	OR R0, R1
	ST Y, R0
	POP YH
	POP YL
	RET

; ------------------------------------------------
; Éteindre un pixel à (R2, R3)
; ------------------------------------------------
ClearScreenBit:
	PUSH R16
	PUSH YL
	PUSH YH
	RCALL GetByteAndMask
	LDI R16, 0xFF
	EOR R1, R16
	AND R0, R1
	ST Y, R0
	POP YH
	POP YL
	POP R16
	RET

; ------------------------------------------------
; Calcule l'adresse et le mask pour un pixel
; Entrée : R2 = ligne, R3 = colonne
; Sortie : R0 = contenu actuel du byte, R1 = mask, Y = adresse du byte
; ------------------------------------------------
GetByteAndMask:
	PUSH R16
	PUSH R2
	PUSH R3

	LDI R16, 10
	MUL R2, R16
	LDI YL, low(0x0100)
	LDI YH, high(0x0100)
	ADD YL, R0
	ADC YH, R1

	LDI R16, 8
ColByteLoop:
	CP R3, R16
	BRLO GotColByte
	SUB R3, R16
	ADIW YL, 1
	RJMP ColByteLoop

GotColByte:
	LDI R16, 0b10000000
BitMaskLoop:
	TST R3
	BREQ MaskReady
	LSR R16
	DEC R3
	RJMP BitMaskLoop

MaskReady:
	LD R0, Y
	MOV R1, R16
	POP R3
	POP R2
	POP R16
	RET

; ------------------------------------------------
; Boucle principale
; ------------------------------------------------
MAINLOOP:
	RJMP MAINLOOP

; ------------------------------------------------
; Affiche UNE ligne du buffer
; Entrée : R18 = ligne
; ------------------------------------------------
DisplayLine:
	LDI ZL, low(0x0100)
	LDI ZH, high(0x0100)
	LDI R20, 10
	MUL R18, R20
	ADD ZL, R0
	ADC ZH, R1

	; --- Afficher les 40 colonnes du haut (octets 5 à 9) ---
	LDI R19, 5
	ADIW ZL, 5
DisplayUpper:
	LD R16, Z+
	LDI R17, 8
SendUpperBits:
	ROL R16
	BRCC SendZeroUpper
	SBI PORTB, 3
	RJMP ClockUpperBit
SendZeroUpper:
	CBI PORTB, 3
ClockUpperBit:
	SBI PORTB, 5
	CBI PORTB, 5
	DEC R17
	BRNE SendUpperBits
	DEC R19
	BRNE DisplayUpper

	; --- Afficher les 40 colonnes du bas (octets 0 à 4) ---
	LDI R19, 5
	SBIW ZL, 10
DisplayLower:
	LD R16, Z+
	LDI R17, 8
SendLowerBits:
	ROL R16
	BRCC SendZeroLower
	SBI PORTB, 3
	RJMP ClockLowerBit
SendZeroLower:
	CBI PORTB, 3
ClockLowerBit:
	SBI PORTB, 5
	CBI PORTB, 5
	DEC R17
	BRNE SendLowerBits
	DEC R19
	BRNE DisplayLower

	; --- Activer la ligne ---
	LDI R16, 0b10000000  ; bit de poids fort pour ligne 0
DisplayLineShift:
	CPI R18, 0
	BREQ SkipLineShift
LSRLine:
	LSR R16
	DEC R18
	BRNE LSRLine
SkipLineShift:
	LDI R17, 8
SendRowBits:
	LSR R16
	BRCC SendZeroRow
	SBI PORTB, 3
	RJMP ClockRowBit
SendZeroRow:
	CBI PORTB, 3
ClockRowBit:
	SBI PORTB, 5
	CBI PORTB, 5
	DEC R17
	BRNE SendRowBits

	SBI PORTB, 4
	NOP
	CBI PORTB, 4
	RET

