;
; Task5.asm
;
; Created: 04-03-25 19:18:35
; Author : alexb
;


.include "m328pdef.inc"

; Buzzer
.equ BUZZER_P       = 1
.equ BUZZER_DDR     = DDRB
.equ BUZZER_PORT    = PORTB
.equ BUZZER_PIN     = PINB

; Timer 1: Reload value for overflow at 440Hz
; clock of 16MHz then number of cycles equal 16MHz x(1/880)= 18182 cycles 
; we are on 16 bit timer then we want to precharge 2^16-18182= 47354 cycles to reach the overflow after 18182 cycles
; the interrupt toggle 
.equ TCNT1_RESET_440 = 47354 ; 56445 is the value for sound at 880MHz
.equ JOYSTICK_BTN   = 2      ; PB2
.equ JOYSTICK_DDR   = DDRB
.equ JOYSTICK_PORT  = PORTB
.equ JOYSTICK_PIN   = PINB

.CSEG
.ORG 0x0000
    rjmp init


.ORG 0x001A
    rjmp timer1_ovf  ; Jump  when the Timer1 overflow interrupt occurs

init:
    ; Configures the buzzer as an output and switches it off initially
    SBI BUZZER_DDR, BUZZER_P
    CBI BUZZER_PORT, BUZZER_P

    ; Configures joystick button as input 
    CBI JOYSTICK_DDR, JOYSTICK_BTN    
    SBI JOYSTICK_PORT, JOYSTICK_BTN  

    ; Configure Timer1 in Normal mode 
LDI r16, 0          ; Load 0 into r16
STS TCCR1A, r16     ; Store 0 in TCCR1A to set Timer1 to Normal mode

; Configure Timer1 with prescaler = 1 ensure no division of the clock (CS11 and CS12 set to 0)
LDI r16, (1<<CS10)  ; Load the value with CS10 set to 1 into r16
STS TCCR1B, r16     ; Store the value in TCCR1B to set prescaler to 1

; Load the reload value into Timer1 as it is 16 bit it is split into 2 bytes (2x8 bits) then just load in two separate bytes
LDI r16, HIGH(TCNT1_RESET_440)   
LDI r17, LOW(TCNT1_RESET_440)    
STS TCNT1H, r16     ; Store high byte into TCNT1H
STS TCNT1L, r17     ; Store low byte into TCNT1L

; Enable Timer1 Overflow Interrupt (TOIE1)
LDI r16, (1<<TOIE1) ; Load the value with TOIE1 set into r16
STS TIMSK1, r16     ; Store the value in TIMSK1 to enable Timer1 overflow interrupt

CLI                 ; Disable global interrupts


main_loop:
    ; Checks joystick button status ( it is at 1 when not pressed)
    SBIC JOYSTICK_PIN, JOYSTICK_BTN   ; If the bit is 0 (button pressed), the instruction is skipped.
        RJMP JoyNotPressed
    ; If we arrive here, the button is pressed: activate the interrupts to activate the buzzer.
    SEI ;Active Interruption (><CLI)
    RJMP main_loop

JoyNotPressed:
    ; Button released: deactivates interrupts and stops the buzzer
    CLI
    CBI BUZZER_PORT, BUZZER_P
    RJMP main_loop

timer1_ovf:
    LDI r16, HIGH(TCNT1_RESET_440)
    LDI r17, LOW(TCNT1_RESET_440)
    STS TCNT1H, r16
    STS TCNT1L, r17

    ;buzzer toggle: writing 1 to BUZZER_PIN changes its state
    SBI BUZZER_PIN, BUZZER_P

    RETI
