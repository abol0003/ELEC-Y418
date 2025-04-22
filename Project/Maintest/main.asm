; main.asm

.INCLUDE "m328pdef.inc"

.CSEG
.ORG 0x0000
    RJMP start
.ORG 0x001A
	;RJMP Timer1OverflowInterrupt
.ORG 0x0020
    RJMP Timer0OverflowInterrupt

.INCLUDE "ScreenShow.asm"
.INCLUDE "Snake.asm"
.INCLUDE "Board.asm"
.INCLUDE "Obstacles.asm"
.INCLUDE "food.asm"
.INCLUDE "TableDisplay.asm"


start:
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    LDI R16, LOW(RAMEND)
    OUT SPL, R16


	RCALL InitScreen
	RCALL InitKeyboard
    RCALL ClearScreen

    ; Configuration du Timer0 in normal mode
	LDI r16, 0         
	STS TCCR1A, r16     
    LDI R16, (1<<CS01)|(1<<CS00)
    OUT TCCR0B, R16
    LDI R16, 0x06
    OUT TCNT0, R16
    LDI R16, (1<<TOIE0)
    STS TIMSK0, R16

	LDI r16, 0          
	STS TCCR1A, r16     
    LDI R16, 4       
    STS TCCR1B, R16
	LDI R16, 0x0F             
    STS TCNT1H, R16
    LDI R16, 0xFF            
    STS TCNT1L, R16
    LDI R16, (1<<TOIE1)
    STS TIMSK1, R16

    SEI
	CALL LetsGo

init:
    ; Initialize the game by clearing the screen, setting up obstacles, 
    ; initializing the snake, and initializing the food.
    RCALL ClearScreen
	CALL InitObstacles
    CALL SnakeInit
	RCALL Delay
	CALL FoodInit


main_loop:
    ; Main game loop that handles input, snake movement
	RCALL ReadKeyboard
	RCALL DELAY
	RCALL SnakeMain 
	RCALL ReadKeyboard
    RJMP main_loop


Timer0OverflowInterrupt:
    ; Timer0 overflow interrupt handler
    ; Reload Timer0 and call the function to display 
	CBI PORTC,2
    LDI R18, 0x06
    OUT TCNT0, R23
    RCALL DisplayLine
    RETI

Timer1OverflowInterrupt:
    LDI R16, 0x00            
    STS TCNT1H, R16
    LDI R16, 0xAA          
    STS TCNT1L, R16
	RCALL ReadKeyboard
    RCALL SnakeMain        
    RETI

DELAY:
    ; Introduces a delay that adjusts based on the score
    ; The higher the score, the shorter the delay, thus making the game faster
    LDI R16,150
	SUB R16, score
	SUB R16, score
L1:
    LDI R17,255
	SUB R17, score
	SUB R17, score
	SUB R17, score
	SUB R17, score

L2:
	LDI R18,50
	SUB R18, score
L3:
    DEC R18
    BRNE L3
    DEC R17
	BRNE L2
	DEC R16
	BRNE L1
	RET

