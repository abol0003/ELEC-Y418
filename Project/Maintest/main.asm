.INCLUDE "M328PDEF.INC"

.CSEG
.ORG 0x0000
RJMP init

.ORG 0x001A
RJMP TIMER1_OVF

.ORG 0x0020
RJMP TIMER0_OVF

; ------------------------------------------------------------
; Initialization
; ------------------------------------------------------------
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
ClearBuffer:
	ST Z+, R16	 ; incremente R30 de 1 et met valeur de R16
	DEC R17	;decremente R17 de 1 initialement à 0x46
	BRNE ClearBuffer

	RCALL SnakeInit

	LDI R18, 0 ; Compteur de ligne

	; Timer1 (pour logique du jeu, non utilisé ici)
	LDI R16, 0
	STS TCCR1A, R16
	LDI R16, (1<<CS11)|(1<<CS10) ; met R16 à 0x03
	STS TCCR1B, R16
	LDI R16, (1<<TOIE1) ; met R16 à 0x01
	STS TIMSK1, R16

	; Timer0 (affichage à 312 Hz)
	LDI R16, (1<<CS01)|(1<<CS00)   ; Prescaler clk/64 ; met R16 à 0x03
	OUT TCCR0B, R16
	LDI R16, 56                    ; Pour 312 Hz 0x38
	OUT TCNT0, R16
	LDI R16, (1<<TOIE0)
	STS TIMSK0, R16

	SEI
	RJMP MAINLOOP

; ------------------------------------------------------------
; SnakeInit : Allume pixel (0,39)
; ------------------------------------------------------------
SnakeInit:
	LDI R20, 2     ; ligne
	LDI R21, 39    ; Load R21
	RCALL SetScreenBit
	RET ; renvoie à la ligne juste après le call de snake init

; ------------------------------------------------------------
; Set bit at row R20, column R21
; ------------------------------------------------------------
SetScreenBit:
	PUSH YL ; push direct to stak
	PUSH YH
	RCALL GetByteAndMask
	OR R0, R1 ; effectue or entre R0 et R1 ce qui met R0 à 0x01
	ST Y, R0 ; store indirect ; R28 is at 0x18
	POP YH ; remet R29 à 0
	POP YL ; remet R28 à 0
	RET; envoie au ret de snakeinit

; ------------------------------------------------------------
; GetByteAndMask: calcul adresse + masque
; ------------------------------------------------------------
GetByteAndMask:
	PUSH R16
	PUSH R20
	PUSH R21
	PUSH R22

	MOV R22, R21 ; load the coloumn into R22

	LDI R16, 10 ; load R16 to 0x0A
	MUL R20, R16 ; multiply the ligne value with R16 ( stay 0 for column 0); for R20=0x02 it put R0 to 0x14
	LDI YL, low(0x0100)	; put R28 to 0x00
	LDI YH, high(0x0100) ; put R29 to 0x01
	ADD YL, R0 ;add but R0 is 0; for R20=0x02 put R28 to 0x14
	ADC YH, R1 ; add but R1 is 0

	LDI R16, 8
ByteOffset:
	CP R21, R16 ; compare value R21 is the column value and R16 =0x08
	BRLO DoneByteOffset ; branch if lower; when lower R21=0x07 for initial value of 0x27
	SUB R21, R16 ;	soustrait 0x08 à la valeur de la colonne
	ADIW YL, 1 ; ajoute 1 à R28
	RJMP ByteOffset

DoneByteOffset:
; une fois arriver ici tu as YL qui contient le nombre de fois que l'on a du enlever 8 au num de colonne + la valeur de MUL R20, R16 donc ici Yl vaut 0x18!!!  
	LDI R16, 0b10000000 ; R16 est loader à 0x80
BitMask:
	;R21 contains de value of the rest under 8 due to the substrction in byteoffset
	TST R21		;Test for Zero or Minus met à jour les flag ; when R21=0x00 goes to Done Mask
	BREQ DoneMask ; branch if equal
	LSR R16 ; shift right the value goes from 0x80 to 0x40
	DEC R21 ;enlever 1 à R21
	RJMP BitMask

DoneMask:
	LD R0, Y ; la valeur de R29=0x01 est copier dans R1 ; R0 put back at 0x00 alors que R28 ne change pas
	MOV R1, R16
	POP R22 ; reload la value de la ligne
	POP R21 ; reload les values de la colonne
	POP R20
	POP R16
	RET ; fait retourner dans setscreenbit

; ------------------------------------------------------------
; MAIN
; ------------------------------------------------------------
MAINLOOP:
	RJMP MAINLOOP

; ------------------------------------------------------------
; Affichage d'une ligne (R18)
; ------------------------------------------------------------
DisplayLine:
	LDI ZL, low(0x0100)
	LDI ZH, high(0x0100) ; put R31 à 0x01
	LDI R20, 10 ; load R20 à 10 0x0A
	MUL R18, R20
	ADD ZL, R0
	ADC ZH, R1

	; Partie haute (bytes 5 à 9)
	LDI R19, 5 ; load R19 to 0x05
	ADIW ZL, 5 ; load R19 to 0x05
DisplayUpper:
	LD R16, Z+ ; add 1 to R30
	LDI R17, 8 ;load 0x08 to R17
SendUpperBits:
	ROL R16 ; rotate left true carry
	BRCC ZeroU
	SBI PORTB, 3
	RJMP ClockU
ZeroU:
	CBI PORTB, 3
ClockU:
	SBI PORTB, 5
	CBI PORTB, 5
	DEC R17
	BRNE SendUpperBits
	DEC R19
	BRNE DisplayUpper

	; Partie basse (bytes 0 à 4)
	LDI R19, 5
	SBIW ZL, 10 ; sub by ten so put it to 0x00
DisplayLower:
	LD R16, Z+
	LDI R17, 8
SendLowerBits:
	ROL R16
	BRCC ZeroL
	SBI PORTB, 3
	RJMP ClockL
ZeroL:
	CBI PORTB, 3
ClockL:
	SBI PORTB, 5
	CBI PORTB, 5
	DEC R17
	BRNE SendLowerBits
	DEC R19
	BRNE DisplayLower

	; Génération dynamique de la ligne active depuis R18
	LDI R16, 0b00001000 ; load r16 at 0x80

	MOV R19, R18
ShiftLine:
	CPI R19, 0 ; compare
	BREQ DoneShift
	LSR R16
	DEC R19
	RJMP ShiftLine
DoneShift:

	LDI R17, 8
SendRowBits:
	LSR R16  ; shift to right
	BRCC RowZero
	SBI PORTB, 3
	RJMP ClockRow
RowZero:
	CBI PORTB, 3
ClockRow:
	SBI PORTB, 5
	CBI PORTB, 5
	DEC R17
	BRNE SendRowBits

	SBI PORTB, 4
	NOP
	CBI PORTB, 4
	RET

; ------------------------------------------------------------
; TIMER0_OVF ? Affichage ligne par ligne
; ------------------------------------------------------------
TIMER0_OVF:
	PUSH R0
	PUSH R16
	PUSH R17
	PUSH R18
	PUSH R19
	PUSH ZL
	PUSH ZH

	RCALL DisplayLine

	INC R18
	CPI R18, 8
	BRLO skipReset
	LDI R18, 0
skipReset:

	LDI R16, 56
	OUT TCNT0, R16

	POP ZH
	POP ZL
	POP R19
	POP R18
	POP R17
	POP R16
	POP R0
	RETI

; ------------------------------------------------------------
; TIMER1_OVF ? inactif pour l’instant
; ------------------------------------------------------------
TIMER1_OVF:
	RETI

