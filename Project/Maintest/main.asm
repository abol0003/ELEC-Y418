; main.asm

.INCLUDE "m328pdef.inc"

.CSEG
.ORG 0x0000
    RJMP start
.ORG 0x001A
	;RJMP Timer1OverflowInterrupt
; Vecteur d'interruption pour le d�bordement du Timer0 (adresse 0x0020)
.ORG 0x0020
    RJMP Timer0OverflowInterrupt

.INCLUDE "ScreenShow.asm"
.INCLUDE "Snake.asm"
.INCLUDE "Board.asm"
.INCLUDE "Obstacles.asm"
.INCLUDE "food.asm"
.INCLUDE "TableDisplay.asm"


start:
    ; Initialisation de la pile
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
	SBI DDRC,3
    CBI PORTC,3
	SBI DDRC,2
    CBI PORTC,2

	RCALL InitScreen
	RCALL InitKeyboard

    ; Effacer le buffer d'affichage
    RCALL ClearScreen
    ;-------------------------------------
    ; Configuration du Timer0 en mode normal
	LDI r16, 0         ; Load 0 into r16
	STS TCCR1A, r16     ; Store 0 in TCCR1A to set Timer1 to Normal mode
    ; Choix d'un prescaler de 64 : CS01 et CS00 � 1
    LDI R16, (1<<CS01)|(1<<CS00)
    OUT TCCR0B, R16
    ; Charger TCNT0 avec la valeur de d�part (ici 0x06)
    ; La valeur d�termine la p�riode d'interruption (P�riode = (256 � TCNT0)*(prescaler/clok))
    LDI R16, 0x06
    OUT TCNT0, R16
    ; Activer l'interruption de d�bordement du Timer0 (bit TOIE0 dans TIMSK0)
    LDI R16, (1<<TOIE0)
    STS TIMSK0, R16

		 ;-------------------------------------
    ; Configuration du Timer1 pour le mouvement du snake
; Timer 1: Reload value for overflow at 440Hz
; clock of 16MHz then number of cycles equal 16MHz x(1/880)= 18182 cycles 
; we are on 16 bit timer then we want to precharge 2^16-18182= 47354 cycles to reach the overflow after 18182 cycles
; the interrupt toggle 
    ; On utilise ici un prescaler de 64 
	LDI r16, 0          ; Load 0 into r16
	STS TCCR1A, r16     ; Store 0 in TCCR1A to set Timer1 to Normal mode
    LDI R16, 4       ; Prescaler 64
    STS TCCR1B, R16
    ; Charger Timer1 pour obtenir environ 8 Hz (valeurs obtenues par calcul)
	LDI R16, 0x0F             ; Valeur haute initiale
    STS TCNT1H, R16
    LDI R16, 0xFF            ; Valeur basse initiale
    STS TCNT1L, R16
    ; Activer l'interruption de d�bordement du Timer1 (TOIE1)
    LDI R16, (1<<TOIE1)
    STS TIMSK1, R16

    ; Activer les interruptions globales
    SEI
	CALL LetsGo
;------------------------------------------------------------
; INIT
;------------------------------------------------------------
init:

    RCALL ClearScreen
	CALL InitObstacles
    CALL SnakeInit
	RCALL Delay
	CALL FoodInit


main_loop:
	RCALL ReadKeyboard
	RCALL DELAY
	RCALL SnakeMain 
	RCALL ReadKeyboard
    RJMP main_loop

fill_buffer:
    ; Remplissage du buffer � 0x0100 avec motif 0xAA
    LDI R16, 0xAA         
    LDI ZL, low(0x0100+34)  
    LDI ZH, high(0x0100)    
    LDI R17, 1
    ST Z+, R16
    DEC R17
    BRNE fill_buffer
	LDI R16,0
	RET


Timer0OverflowInterrupt:
	CBI PORTC,2
    LDI R18, 0x06
    OUT TCNT0, R23
    RCALL DisplayLine
    RETI

;------------------------------------------------------------
; Timer1Interrupt : Mise � jour du mouvement du snake
;------------------------------------------------------------
Timer1OverflowInterrupt:
    ;CBI PORTC,3
    LDI R16, 0x00             ; Recharge de la partie haute
    STS TCNT1H, R16
    LDI R16, 0xAA           ; Recharge de la partie basse
    STS TCNT1L, R16
	;RCALL ReadKeyboard

    ; Appeler la routine qui met � jour le mouvement du snake
    ;RCALL SnakeMain          ; Cette routine est d�finie dans Snake.asm
    RETI
DELAY:
	;PUSH R16
	;PUSH R17
	;PUSH R18

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
	;POP R16
	;POP R17
	;POP R18
	RET

