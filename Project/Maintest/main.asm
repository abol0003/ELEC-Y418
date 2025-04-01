.INCLUDE "M328PDEF.INC"

.CSEG
.ORG 0x0000
RJMP init

.ORG 0x001A
RJMP TIMER1_OVF

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
	ST Z+, R16
	DEC R17
	BRNE ClearBuffer

	RCALL SnakeInit

	LDI R18, 0 ; Line counter for display

	LDI R16, 0
	STS TCCR1A, R16
	LDI R16, (1<<CS11)|(1<<CS10)
	STS TCCR1B, R16
	LDI R16, (1<<TOIE1)
	STS TIMSK1, R16
	SEI
	RJMP MAINLOOP

; ------------------------------------------------------------
; Display one row each frame (interrupt-driven)
; ------------------------------------------------------------
TIMER1_OVF:
	PUSH R0
	PUSH R1
	PUSH R16
	PUSH R17
	PUSH R18
	PUSH R19
	PUSH ZL
	PUSH ZH

	CPI R18, 7
	RCALL DisplayLine
	INC R18
	BRLO done
	LDI R18, 0
done:
	POP ZH
	POP ZL
	POP R19
	POP R18
	POP R17
	POP R16
	POP R1
	POP R0
	RETI

; ------------------------------------------------------------
; SnakeInit : Turn on pixel (0,0)
; ------------------------------------------------------------
SnakeInit:
	LDI R20, 0     ; row
	LDI R21, 39     ; col going from right to left and up to down then col 0 is top right 
	RCALL SetScreenBit
	RET

; ------------------------------------------------------------
; Set bit at row R20, column R21
; ------------------------------------------------------------
SetScreenBit:
	PUSH YL
	PUSH YH
	RCALL GetByteAndMask
	OR R0, R1
	ST Y, R0
	POP YH
	POP YL
	RET

; ------------------------------------------------------------
; Calculate byte address and bitmask for pixel (R20 = row, R21 = col)
; Returns:
;   Y -> pointer to byte in RAM
;   R0 = current byte value
;   R1 = bitmask
; ------------------------------------------------------------
GetByteAndMask:
	PUSH R16
	PUSH R20
	PUSH R21
	PUSH R22

	MOV R22, R21       ; Save original column for mask

	LDI R16, 10
	MUL R20, R16
	LDI YL, low(0x0100)
	LDI YH, high(0x0100)
	ADD YL, R0
	ADC YH, R1

	LDI R16, 8
ByteOffset:
	CP R21, R16
	BRLO DoneByteOffset
	SUB R21, R16
	ADIW YL, 1
	RJMP ByteOffset

DoneByteOffset:
	LDI R16, 0b10000000
BitMask:
	TST R21
	BREQ DoneMask
	LSR R16
	DEC R21
	RJMP BitMask

DoneMask:
	LD R0, Y
	MOV R1, R16
	POP R22
	POP R21
	POP R20
	POP R16
	RET

; ------------------------------------------------------------
; Main loop
; ------------------------------------------------------------
MAINLOOP:
	RJMP MAINLOOP

; ------------------------------------------------------------
; DisplayLine: render current line (R18)
; ------------------------------------------------------------
DisplayLine:
	LDI ZL, low(0x0100)
	LDI ZH, high(0x0100)
	LDI R20, 10
	MUL R18, R20
	ADD ZL, R0
	ADC ZH, R1

	; Send upper part (bytes 5–9)
	LDI R19, 5
	ADIW ZL, 5
DisplayUpper:
	LD R16, Z+
	LDI R17, 8
SendUpperBits:
	ROL R16
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

	; Send lower part (bytes 0–4)
	LDI R19, 5
	SBIW ZL, 10
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

	; Activate line
	LDI R16, 0b10000000
LineShift:
	CPI R18, 0
	BREQ SkipShift
ShiftLoop:
	LSR R16
	DEC R18
	BRNE ShiftLoop
SkipShift:
	LDI R17, 8
SendRowBits:
	LSR R16
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
