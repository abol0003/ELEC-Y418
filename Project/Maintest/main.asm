.INCLUDE "M328PDEF.INC"

.CSEG
.ORG 0x0000
RJMP init              ; Jump to initialization on reset

.ORG 0x001A
RJMP TIMER1_OVF        ; Timer1 overflow interrupt vector

; ------------------------------------------------------------
; Initialization Routine
; ------------------------------------------------------------
init:
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16
	LDI R16, LOW(RAMEND)
	OUT SPL, R16

	; Set PB3 (SDI), PB4 (LE), PB5 (CLK) as output
	SBI DDRB, 3
	SBI DDRB, 4
	SBI DDRB, 5
	CBI PORTB, 3
	CBI PORTB, 4
	CBI PORTB, 5

	; Clear video buffer
	LDI ZL, low(0x0100)
	LDI ZH, high(0x0100)
	LDI R16, 0
	LDI R17, 70
ClearScreen:
	ST Z+, R16
	DEC R17
	BRNE ClearScreen

	; Set pixel at (row 0, column 0)
	LDI R20, 0      ; Row index
	LDI R21, 0      ; Column index
	RCALL SetScreenBit

	; Timer1 setup (overflow every short interval)
	LDI R16, 0
	STS TCCR1A, R16
	LDI R16, (1<<CS11)|(1<<CS10)
	STS TCCR1B, R16
	LDI R16, (1<<TOIE1)
	STS TIMSK1, R16
	SEI

	LDI R18, 0      ; Current row to display
	RJMP MAINLOOP

; ------------------------------------------------------------
; Timer1 Overflow ISR: Refresh screen line-by-line
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

; ------------------------------------------------------------
; Set pixel ON at (R20=row, R21=col)
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
; Compute address + bit mask for pixel (R20, R21)
; Result: Y points to byte, R1 = bit mask
; ------------------------------------------------------------
GetByteAndMask:
	PUSH R16
	PUSH R20
	PUSH R21

	LDI R16, 10
	MUL R20, R16        ; R1:R0 = row × 10
	LDI YL, low(0x0100)
	LDI YH, high(0x0100)
	ADD YL, R0
	ADC YH, R1

	LDI R16, 8
ColByteLoop:
	CP R21, R16
	BRLO GotColByte
	SUB R21, R16
	ADIW YL, 1
	RJMP ColByteLoop

GotColByte:
	LDI R16, 0b10000000    ; Start from MSB (bit 7 = left)
BitMaskLoop:
	TST R21
	BREQ MaskReady
	LSR R16
	DEC R21
	RJMP BitMaskLoop

MaskReady:
	LD R0, Y
	MOV R1, R16
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
; Display current line (R18)
; ------------------------------------------------------------
DisplayLine:
	LDI ZL, low(0x0100)
	LDI ZH, high(0x0100)
	LDI R20, 10
	MUL R18, R20
	ADD ZL, R0
	ADC ZH, R1

	; Display upper (bytes 5 to 9)
	LDI R19, 5
	ADIW ZL, 5
DisplayUpper:
	LD R16, Z+
	LDI R17, 8
SendUpperBits:
	ROL R16
	BRCC SendZeroU
	SBI PORTB, 3
	RJMP ClockU
SendZeroU:
	CBI PORTB, 3
ClockU:
	SBI PORTB, 5
	CBI PORTB, 5
	DEC R17
	BRNE SendUpperBits
	DEC R19
	BRNE DisplayUpper

	; Display lower (bytes 0 to 4)
	LDI R19, 5
	SBIW ZL, 10
DisplayLower:
	LD R16, Z+
	LDI R17, 8
SendLowerBits:
	ROL R16
	BRCC SendZeroL
	SBI PORTB, 3
	RJMP ClockL
SendZeroL:
	CBI PORTB, 3
ClockL:
	SBI PORTB, 5
	CBI PORTB, 5
	DEC R17
	BRNE SendLowerBits
	DEC R19
	BRNE DisplayLower

	; Select correct row
	LDI R16, 0b10000000
	CPI R18, 0
	BREQ SkipRowShift
RowShift:
	LSR R16
	DEC R18
	BRNE RowShift
SkipRowShift:
	LDI R17, 8
SendRowBits:
	LSR R16
	BRCC SendZeroRow
	SBI PORTB, 3
	RJMP ClockRow
SendZeroRow:
	CBI PORTB, 3
ClockRow:
	SBI PORTB, 5
	CBI PORTB, 5
	DEC R17
	BRNE SendRowBits

	; Latch to LED driver
	SBI PORTB, 4
	NOP
	CBI PORTB, 4
	RET
