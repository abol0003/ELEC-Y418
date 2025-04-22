;TableDisplay.asm

GameOver :
    ; Displays the "GAME OVER" message and the score on the screen, then jumps to WaitRestart for a restart.
	CALL CLearScreen 
	LDI YL, low(0x0200)                
	LDI YH, high(0x0200)                
	LDI R16, 13                ; G
	ST Y+, R16
	LDI R16, 11                ; A
	ST Y+, R16
	LDI R16, 15                 ; M
	ST Y+, R16
	LDI R16, 12
	ST Y+, R16                 ; E
	LDI R16, 10                 ; espace 
	ST Y+, R16
	LDI R16, 16                 ; O
	ST Y+, R16
	LDI R16, 21                 ; V
	ST Y+, R16
	LDI R16, 12                 ; E
	ST Y+, R16
	LDI R16, 18                 ; R
	ST Y+, R16
	MOV R16, score              ; score
	ST Y+, R16
	RJMP WaitRestart
LetsGO:
    ; Displays the "LET'S GO BRO" message on the screen and waits for a key press to start the game.
	CALL CLearScreen 
	LDI YL, low(0x0200)                
	LDI YH, high(0x0200)                
	LDI R16, 14                ; L
	ST Y+, R16
	LDI R16, 12                ; E
	ST Y+, R16
	LDI R16, 20                 ; T
	ST Y+, R16
	LDI R16, 22
	ST Y+, R16                 ; '
	LDI R16, 19                 ; S 
	ST Y+, R16
	LDI R16, 13                 ; G
	ST Y+, R16
	LDI R16, 16                 ; 0
	ST Y+, R16
	LDI R16, 23                 
	ST Y+, R16
	LDI R16, 18                  
	ST Y+, R16
	LDI R16,  16             
	ST Y+, R16
	RJMP WaitRestart
WaitRestart:
    ; Waits for the user to press a key to start/restart the game, checking input
	CALL ReadKeyboard
	LDI R22,0

	; The lines above take the good character in character Table and write it on the screen buffer 
	LDI YL, low(0x020A)                
	LDI YH, high(0x0200) 
intermediate :
	LDI XL, low(0x0100)	
	LDI XH, high(0x0100)	
	ADD XL, R22
	CPI R22,5
	BRSH gohigh
EnableHigh:
	LDI R16,0								
	LDI R18,7						
	LDI R17,8
	LD R19,-Y ; load value in buffer
blocksloopGame:
	LDI ZL,low(CharTable << 1)
	LDI ZH,high(CharTable << 1)
	MOV R21, R19
	MUL R21,R17 ; multiply to get the right line of the table					
	MOV R21,R0								
	ADD R21,R16	; add offset to go trought all row each byte in table is for one row						
	ADC ZL, R21 ; add it to Z 
	BRCC NoCarry
	LDI R21, 1
	ADD ZH,R21
	NoCarry:
		LPM R21,Z	; load the good byte in table
blockGame :
	ST X, R21			
	ADIW X, 5 ; go to next row ( a line is 5 byte)
	INC R16				
	DEC R18		; 7 to zero to make all r0w 
	BRNE blocksloopGame
	INC R22
	CPI R22, 10
	BREQ WaitRestart
	RJMP intermediate					
gohigh:
	ADIW X, 30 
	RJMP EnableHigh
	
CharTable:
.db 0b00011111,0b00010001,0b00010001,0b00010001,0b00010001,0b00010001,0b00011111,0b00000000 ; 0
.db 0b00000100,0b00001100,0b00010100,0b00000100,0b00000100,0b00000100,0b00011111,0b00000000 ; 1
.db 0b00011111,0b00010001,0b00000001,0b00000010,0b00000100,0b00001000,0b00011111,0b00000000 ; 2
.db 0b00011111,0b00000001,0b00000001,0b00011111,0b00000001,0b00000001,0b00011111,0b00000000 ; 3
.db 0b00010001,0b00010001,0b00010001,0b00011111,0b00000001,0b00000001,0b00000001,0b00000000 ; 4
.db 0b00011111,0b00010000,0b00010000,0b00011111,0b00000001,0b00000001,0b00011111,0b00000000 ; 5
.db 0b00011111,0b00010000,0b00010000,0b00011111,0b00010001,0b00010001,0b00011111,0b00000000 ; 6
.db 0b00011111,0b00010001,0b00000001,0b00000010,0b00000100,0b00001000,0b00010000,0b00000000 ; 7 
.db 0b00011111,0b00010001,0b00010001,0b00011111,0b00010001,0b00010001,0b00011111,0b00000000 ; 8
.db 0b00011111,0b00010001,0b00010001,0b00011111,0b00000001,0b00000001,0b00011111,0b00000000 ; 9
.db 0b00000000,0b00000000,0b00000000,0b00000000,0b00000000,0b00000000,0b00000000,0b00000000 ; nothing 10
.db 0b00000100,0b00001010,0b00010001,0b00010001,0b00011111,0b00010001,0b00010001,0b00000000 ;A => 11
.db 0b00011111,0b00010000,0b00010000,0b00011111,0b00010000,0b00010000,0b00011111,0b00000000 ;E => 12
.db 0b00011111,0b00010000,0b00010000,0b00010111,0b00010001,0b00010001,0b00011111,0b00000000 ;G => 13
.db 0b00100000,0b00100000,0b00100000,0b00100000,0b00100000,0b00100000,0b00111111,0b00000000	;L=>14
.db 0b00010001,0b00011011,0b00010101,0b00010001,0b00010001,0b00010001,0b00010001,0b00000000 ;M => 15
.db 0b00011111,0b00010001,0b00010001,0b00010001,0b00010001,0b00010001,0b00011111,0b00000000 ;O => 16
.db 0b00011111,0b00010001,0b00010001,0b00011111,0b00010000,0b00010000,0b00010000,0b00000000 ;P => 17
.db 0b00011111,0b00010001,0b00010001,0b00011111,0b00010100,0b00010010,0b00010001,0b00000000 ;R => 18
.db 0b11111000,0b10000000,0b10000000,0b11111000,0b00001000,0b00001000,0b11111000,0b00000000 ;S => 19
.db 0b00011111,0b00000100,0b00000100,0b00000100,0b00000100,0b00000100,0b00000100,0b00000000 ;T => 20
.db 0b00010001,0b00010001,0b00010001,0b00010001,0b00010001,0b00001010,0b00000100,0b00000000 ;V => 21
.db 0b00100000,0b00100000,0b00100000,0b01000000,0b00000000,0b00000000,0b00000000,0b00000000 ; '=> 22
.db 0b00011110,0b00010001,0b00010001,0b0011110,0b00010001,0b00010001,0b00011110,0b00000000 ; B=> 23 because added after