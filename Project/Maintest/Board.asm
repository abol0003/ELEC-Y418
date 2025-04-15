; Board.asm

.equ KEYB_PIN   = PIND
.equ KEYB_DDR   = DDRD
.equ KEYB_PORT  = PORTD
.equ ROW1       = 7
.equ ROW2       = 6
.equ ROW3       = 5
.equ ROW4       = 4
.equ COL1       = 3
.equ COL2       = 2
.equ COL3       = 1
.equ COL4       = 0


InitKeyboard:
		PUSH R16
		PUSH R17
		LDI r16,(1<<COL1)|(1<<COL2)|(1<<COL3)|(1<<COL4)
		LDI r17,(1<<ROW1)|(1<<ROW2)|(1<<ROW3)|(1<<ROW4)
		NOP
		OUT KEYB_PORT,r16  ; Drive columns with HIGH values 
		NOP
		OUT KEYB_DDR,r17   ; Set rows as outputs
		POP R16 
		POP R17
		RET	

.MACRO Rowdetection
;STEP2 method
 ;the output configuration for rows generates the signal, while the input configuration for columns detects the signal when a button is pressed.
    ; Set the rows as input because use of KEYB_PORT
	LDI r17,(1<<ROW1)|(1<<ROW2)|(1<<ROW3)|(1<<ROW4)
	LDI r16,(1<<COL1)|(1<<COL2)|(1<<COL3)|(1<<COL4)
	NOP
	OUT KEYB_PORT,r17
	NOP
	OUT KEYB_DDR,r16     ; Configure keyboard port data direction for columns
	NOP                 
	
    ; Check which row is LOW indicating that a key is pressed on that row
	; SBIS Make Skip next instruction if bit ROW1 in the PIN register is set (HIGH)
	SBIS KEYB_PIN,ROW1   
	RJMP @0            
	SBIS KEYB_PIN,ROW2   
	RJMP @1            
	SBIS KEYB_PIN,ROW3   
	RJMP @2           
	SBIS KEYB_PIN,ROW4   
	RJMP @3 
	RET           
.ENDMACRO

; Fonction pour lire les entrées du clavier
ReadKeyboard:
	NOP
    SBIS PIND, COL2           ; UP and DOWN
	RJMP Col2P
    SBIS PIND, COL1           ; LEFT
	RJMP Col1P
    SBIS PIND, COL3           ; RIGHT
	RJMP Col3P
	SBIS PIND, COL4
	RJMP Col4P
	RET 

Col1P:
	Rowdetection DOnothing, DOnothing, DOnothing, replay
Col2P:   
	Rowdetection DOnothing, SetDirectionLeft, DOnothing, DOnothing
Col3P:
	Rowdetection SetDirectionUp, DOnothing, SetDirectionDown, restart
Col4P:
	Rowdetection DOnothing,SetDirectionRight, DOnothing, Pause


SetDirectionUp:
    LDI SnakeDirection, UP  
	RCALL InitKeyBoard  ;As we use 2 step method we need to reswitch row as output
    RET

SetDirectionDown:
    LDI SnakeDirection, DOWN 
	RCALL InitKeyBoard  
    RET

SetDirectionLeft:
    LDI SnakeDirection, LEFT 
	RCALL InitKeyBoard  
    RET

SetDirectionRight:
    LDI SnakeDirection, RIGHT
	RCALL InitKeyBoard  
    RET
Pause:
	LDI SnakeDirection, 0
	RCALL InitKeyBoard
	RET
replay:
	RJMP init

DOnothing:
	RCALL InitKeyBoard  
	RET
restart:
	RJMP start