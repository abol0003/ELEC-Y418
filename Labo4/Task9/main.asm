;---------------------------------------------------------
; Task9.asm
; Created: 13-03-25 14:18:24
; Author : alexb

.include "m328pdef.inc"        


; CONSTANTS 
;----------------------------
.equ SCREEN_DDR      = DDRB       ; Data Direction Register for Port B
.equ SCREEN_PORT     = PORTB      ; Output register for Port B
.equ SCREEN_PIN      = PINB       ; Input register for Port B 

; CODE 
;---------------------------
.CSEG
.ORG 0x0000             
rjmp init               

init:
    ; Configure PB3, PB4, and PB5 as outputs and initialize them.
    LDI r17, (1<<3)|(1<<4)|(1<<5)  ; Create a mask for bits 3, 4, and 5 (binary: 0011 1000)
    OUT SCREEN_PORT, r17           ; Initialize these pins (set output state)
    OUT SCREEN_DDR, r17            ; Set PB3, PB4, and PB5 as outputs
    RJMP main                      ; Continue to main routine

main:
    
    ; Column Processing Loop (80 iterations)
    ;----------------------------
    ; Activate the column signal by setting PB3 high.
    SBI SCREEN_PIN, 3              ; Set PB3 HIGH
    LDI r18, 80                    ; Load the column counter with 80 (0x50 in hex)
    rcall ColLoop                ; Call subroutine for column loop

    
    ; Row Processing Loop (8 iterations)
    ;----------------------------
    ; Each row is delayed by pulsing PB5.
    LDI r18, 8                     ; Load the row counter with 8
    rcall RowLoop                ; Call subroutine for row loop

    ;----------------------------
    ; Control Signal and Delay
    ;----------------------------
    ; Set PB4 high to activate a control signal (e.g., a latch signal)
    SBI SCREEN_PIN, 4              ; Set PB4 HIGH

    ; Create a delay.
    rcall Delay

    ; Mandatory to put to maintain its state after the delay.
    SBI SCREEN_PIN, 4             ; Set PB4 HIGH again

    RJMP main                     ; Repeat the entire process indefinitely

;---------------------------------------------------------
; Loop: ColLoop
;---------------------------------------------------------
ColLoop:
    SBI SCREEN_PIN, 5              ; Toggle PB5 to generate a pulse for a column
    DEC r18                      ; Decrement the column counter
    BRNE ColLoop				; Repeat loop until 80 pulses are generated

;---------------------------------------------------------
; Loop: RowLoop
;---------------------------------------------------------
RowLoop:
; We have to make the change in row because the led is on when row is high see slides 
; The diode is passante when current goes from row to col then col has to be low 
	SBI SCREEN_PIN, 3              ; added from task8
	SBI SCREEN_PIN, 5              ; Pulse PB5 for the row delay
	SBI SCREEN_PIN, 5              ; added from task8  
	;sending two time PB5 ensure that we take the entire period ( front montant et descendant )
	DEC r18                      ; Decrement the row counter
	BRNE RowLoop				 ; Continue until all 8 rows are processed

; Loop: Delay
;---------------------------------------------------------
Delay:
    LDI r16, 50                  
DelayOuter:
    LDI r17, 250                 
DelayInner:
    DEC r17                      ; Decrement inner counter 
    BRNE DelayInner              ; Loop back if r17 not zero 
    DEC r16                      ; Decrement outer counter
    BRNE DelayOuter              ; Loop back if r16 not zero
    RET
