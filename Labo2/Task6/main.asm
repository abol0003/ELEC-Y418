;
; Task6.asm
;
; Created: 04-03-25 19:19:35
; Author : alexb
;

.include "m328pdef.inc"

; Buzzer 
.equ BUZZER_P       = 1
.equ BUZZER_DDR     = DDRB
.equ BUZZER_PORT    = PORTB
.equ BUZZER_PIN     = PINB

; Timer reload values for desired sound frequencies:
.equ TCNT1_RESET_440 = 47354  ; explanation on task5
.equ TCNT1_RESET_880 = 56445  ; 

; Joystick button 
.equ JOYSTICK_BTN   = 2
.equ JOYSTICK_DDR   = DDRB
.equ JOYSTICK_PORT  = PORTB
.equ JOYSTICK_PIN   = PINB

; Switch
.equ FREQ_SWITCH_BIT = 0
.equ FREQ_SWITCH_DDR = DDRB
.equ FREQ_SWITCH_PORT = PORTB
.equ FREQ_SWITCH_PIN = PINB

.CSEG
.ORG 0x0000
    rjmp init

; Interrupt vector assignment for Timer1 Overflow 
.ORG 0x001A
    rjmp timer1_ovf  ; Jump  when the Timer1 overflow interrupt occurs

init:
	 ;This sets the port pin as an output.
    SBI BUZZER_DDR, BUZZER_P ;BUZZER_P is a constant indicating the bit number to be modified in BUZZER_DDR
	;This sets the output value to low, turning off the buzzer
    CBI BUZZER_PORT, BUZZER_P

    ; Configure joystick button as input 
    CBI JOYSTICK_DDR, JOYSTICK_BTN
    SBI JOYSTICK_PORT, JOYSTICK_BTN

    ; Configure frequency switch
    CBI FREQ_SWITCH_DDR, FREQ_SWITCH_BIT
    SBI FREQ_SWITCH_PORT, FREQ_SWITCH_BIT

    ; Configure Timer1 in Normal mode 
LDI r16, 0          ; Load 0 into r16
STS TCCR1A, r16     ; Store 0 in TCCR1A to set Timer1 to Normal mode

; Configure Timer1 with prescaler = 1 ensure no division of the clock (CS11 and CS12 set to 0)
LDI r16, (1<<CS10)  ; Load the value with CS10 set to 1 into r16
STS TCCR1B, r16     ; Store the value in TCCR1B to set prescaler to 1

; Load the reload value into Timer1 as it is 16 bit it is split into 2 bytes (2x8 bits) then just load in two separate bytes
LDI r16, HIGH(TCNT1_RESET_880)   
LDI r17, LOW(TCNT1_RESET_880)    
STS TCNT1H, r16     ; Store high byte into TCNT1H
STS TCNT1L, r17     ; Store low byte into TCNT1L

; Enable Timer1 Overflow Interrupt (TOIE1)
LDI r16, (1<<TOIE1) ; Load the value with TOIE1 set into r16
STS TIMSK1, r16     ; Store the value in TIMSK1 to enable Timer1 overflow interrupt

CLI                 ; Disable global interrupts

main_loop:
    ; Checks joystick button status ( it is at 1 when not pressed)
    SBIC JOYSTICK_PIN, JOYSTICK_BTN ;SBIC check if bit is clear ( set to 0) or set to 1
        RJMP JoyNotPressed
    SEI
    RJMP main_loop

JoyNotPressed:
    ; Disable sound if joystick button released
    CLI ;clear interrupt
    CBI BUZZER_PORT, BUZZER_P
    RJMP main_loop

timer1_ovf:
    ; Select reload value based on frequency switch state:
    SBIS FREQ_SWITCH_PIN, FREQ_SWITCH_BIT  ; If switch is high skip RJMP Load440
        RJMP Load440
	RJMP Load880

Load880:
    LDI r16, HIGH(TCNT1_RESET_880)
    LDI r17, LOW(TCNT1_RESET_880)
    RJMP LoadReload

Load440:
    LDI r16, HIGH(TCNT1_RESET_440)
    LDI r17, LOW(TCNT1_RESET_440)

LoadReload:
    ; Preload Timer1 with the selected reload value
    STS TCNT1H, r16
    STS TCNT1L, r17

    ;buzzer toggle: writing 1 to BUZZER_PIN changes its state
    SBI BUZZER_PIN, BUZZER_P

    RETI ;end interupt
