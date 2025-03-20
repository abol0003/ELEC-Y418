;---------------------------------------------------------
; Task10_Task9Style.asm
; Created: 19-03-25 14:45:14 (adapted)
; Author : alexb
; Description: This version of Task10 has been restructured to follow Task9's architecture.
;              It displays a character (CharacterBite) by shifting out 80 column bits and 8 row bits,
;              then performs a latch sequence.
;---------------------------------------------------------

.include "m328pdef.inc"          ; Include the microcontroller definitions

;------------ 
; CONSTANTS 
;------------
; SCREEN configuration constants
.equ SCREEN_DDR      = DDRB         ; Define Data Direction Register for Port B
.equ SCREEN_PORT     = PORTB        ; Define Output Register for Port B
.equ SCREEN_PIN      = PINB         ; Define Input Register for Port B
.equ SCREEN_DATA     = 3            ; Define Data line (SDI) on Pin PB3
.equ SCREEN_CLK      = 5            ; Define Clock line on Pin PB5
; Note: Pin PB4 is used for the latch sequence (accessed via SCREEN_PIN)

; (The TCNT values are not used anymore because we no longer rely on interrupts)

;-------- 
; MACROS
;-------- 
.MACRO shiftReg
    SBI SCREEN_PORT, SCREEN_DATA   ; Set the data line HIGH
    SBRS @0, @1                    ; Test bit @1 in register @0; skip next instruction if set
    CBI SCREEN_PORT, SCREEN_DATA   ; Otherwise, set the data line LOW
    SBI SCREEN_PIN, SCREEN_CLK     ; Generate a rising edge: set the clock line HIGH
    SBI SCREEN_PIN, SCREEN_CLK     ; (Keep the clock line high to ensure proper timing)
.ENDMACRO

;------- 
; CODE
;-------
.CSEG
.ORG 0x0000
    RJMP init                      ; Jump to initialization routine

init:
    ; Configure PB3, PB4, and PB5 as outputs and initialize their state
    LDI r17, (1<<3)|(1<<4)|(1<<5)    ; Load mask to set bits 3, 4, and 5 (for PB3, PB4, PB5)
    OUT SCREEN_DDR, r17              ; Set PB3, PB4, and PB5 as output
    OUT SCREEN_PORT, r17             ; Set initial state: set PB3, PB4, and PB5 HIGH (may be modified later)
    
    ; Initialize registers used for shifting
    LDI r22, 7           ; r22 is used as an offset for the character table
    LDI r21, 0b1000000   ; r21 holds the row control bits (7 bits; MSB set)

    ; Enable interrupts if needed (not used in this main loop version)
    SEI

    RJMP main            ; Jump to the main loop

main:
    rcall DisplaySymbol  ; Call the subroutine to display the symbol (shift out bits and latch)
    rcall Delay          ; Call the delay subroutine to adjust refresh rate
    RJMP main            ; Infinite loop: repeat display and delay

;---------------------------------------------------------
; Subroutine: DisplaySymbol
; This subroutine performs:
;  - Shifting out 80 column bits (16 iterations, each shifting 5 bits)
;  - Shifting out 8 row bits for row selection
;  - The latch sequence (activating PB4) to transfer data to the output registers.
;---------------------------------------------------------
DisplaySymbol:
    ; --- Process the character columns ---
    LDI ZL, low(CharacterA<<1)  ; Load low byte of the address 
    LDI ZH, high(CharacterA<<1) ; Load high byte of the address
    DEC r22                        ; Decrement offset register r22
    BRPL notreset                  ; If result is positive, branch to notreset
    LDI r22, 6                     ; Otherwise, reload r22 with 6
notreset:
    ADD ZL, r22                    ; Add offset in r22 to the low pointer (adjust character line selection)
    LPM r1, Z                      ; Load a byte from program memory into r1 (this byte represents one row of the character)

    ; Shift out the column bits:
    ; We perform 16 iterations, each shifting out 5 bits (16 * 5 = 80 bits in total)
    LDI r18, 16                    ; Load counter with 16 (number of iterations)
ColLoop:
    shiftReg r1, 0                ; Call macro to shift out the MSB of r1 (column bit)
    shiftReg r1, 1                ; Shift out next bit (macro uses different bit position as parameter)
    shiftReg r1, 2                ; Shift out third bit
    shiftReg r1, 3                ; Shift out fourth bit
    shiftReg r1, 4                ; Shift out fifth bit
    DEC r18                       ; Decrement loop counter
    BRNE ColLoop                  ; Repeat if counter is not zero

    ; After shifting column bits, generate two clock pulses on the data line:
    CBI SCREEN_PORT, SCREEN_DATA   ; Clear the data line (set to LOW)
    SBI SCREEN_PIN, SCREEN_CLK     ; Set the clock line HIGH (first pulse)
    SBI SCREEN_PIN, SCREEN_CLK     ; Set the clock line HIGH again (second pulse)

    ; --- Process the row selection ---
    ; Shift out 8 bits for row selection 
    shiftReg r21, 6                ; Shift out bit corresponding to position 6 of r21
    shiftReg r21, 5                ; Shift out bit at position 5
    shiftReg r21, 4                ; Shift out bit at position 4
    shiftReg r21, 3                ; Shift out bit at position 3
    shiftReg r21, 2                ; Shift out bit at position 2
    shiftReg r21, 1                ; Shift out bit at position 1
    shiftReg r21, 0                ; Shift out bit at position 0

    ; Update the row register: shift it right; if result is zero, reload initial value
    LSR r21                      ; Logical shift right on r21
    BRNE endDisplay              ; If result is nonzero, skip reload
    LDI r21, 0b1000000           ; Otherwise, reload r21 with initial row pattern (MSB set)

endDisplay:
    ; --- Latch sequence ---
    ; Generate a rising edge on PB4 to transfer shifted data into the output registers
    SBI SCREEN_PIN, 4            ; Set PB4 HIGH (latch active)
    ; (A small delay can be added here if necessary)
    CBI SCREEN_PORT, 4           ; Set PB4 LOW to complete the latch sequence (OE active low)

    RET                          ; Return from subroutine

;---------------------------------------------------------
; Subroutine: Delay
; Simple delay loop to adjust the refresh rate.
;---------------------------------------------------------
Delay:
    LDI r16, 50                  ; Outer loop counter set to 50
DelayOuter:
    LDI r17, 250                 ; Inner loop counter set to 250
DelayInner:
    DEC r17                      ; Decrement inner loop counter
    BRNE DelayInner              ; Continue inner loop until r17 reaches 0
    DEC r16                      ; Decrement outer loop counter
    BRNE DelayOuter              ; Continue outer loop until r16 reaches 0
    RET                          ; Return from Delay subroutine

;---------------------------------------------------------
; Character Definitions for "ALEXIS"
; Each character is defined by 8 bytes (7 bits used plus a terminating 0).
;---------------------------------------------------------
CharacterA:
    .db 0b00110, 0b01001, 0b01001, 0b01001, 0b01111, 0b01001, 0b01001, 0

CharacterBite:
    .db 0b11011, 0b11011, 0b01010, 0b01010, 0b01010, 0b01010, 0b01110, 0

CharacterL:
    .db 0b01000, 0b01000, 0b01000, 0b01000, 0b01000, 0b01000, 0b01111, 0

CharacterE:
    .db 0b01111, 0b01000, 0b01000, 0b01110, 0b01000, 0b01000, 0b01111, 0

CharacterX:
    .db 0b01001, 0b01001, 0b00110, 0b00110, 0b01001, 0b01001, 0b01001, 0

CharacterI:
    .db 0b01110, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110, 0

CharacterS:
    .db 0b01111, 0b01000, 0b01000, 0b01111, 0b00001, 0b00001, 0b01111, 0
