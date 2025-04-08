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


; Initialisation du clavier
InitKeyboard:
    ; Configure les lignes du clavier comme sorties et les colonnes comme entrées
		LDI r16,(1<<COL1)|(1<<COL2)|(1<<COL3)|(1<<COL4)
		LDI r17,(1<<ROW1)|(1<<ROW2)|(1<<ROW3)|(1<<ROW4)
		OUT KEYB_PORT,r16  ; Drive columns with HIGH values (or pull-ups if configured)
		OUT KEYB_DDR,r17   ; Set rows as outputs

		RET	

.MACRO Rowdetection
;STEP2 method
 ;the output configuration for rows generates the signal, while the input configuration for columns detects the signal when a button is pressed.
    ; Set the rows as input because use of KEYB_PORT
	LDI r16,(1<<ROW1)|(1<<ROW2)|(1<<ROW3)|(1<<ROW4)
	OUT KEYB_PORT,r16    ; Output the bit mask to the keyboard port to drive the rows
	
    ; Set the columns as output because use of KEYB_DDR
	LDI r16,(1<<COL1)|(1<<COL2)|(1<<COL3)|(1<<COL4)
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
    ; Vérifier chaque touche et affecter la direction correspondante
    SBIS PIND, COL2           ; Si le bouton 1 (haut) est appuyé
	RJMP Col2P
    SBIS PIND, COL2           ; Si le bouton 2 (bas) est appuyé
	RJMP Col2P
    SBIS PIND, COL1           ; Si le bouton 3 (gauche) est appuyé
	RJMP Col1P
    SBIS PIND, COL3           ; Si le bouton 4 (droite) est appuyé
	RJMP Col3P
	RET  

Col1P:
		Rowdetection DOnothing, SetDirectionLeft, DOnothing, DOnothing

Col2P:   
	    Rowdetection SetDirectionUp, DOnothing, SetDirectionDown, DOnothing
Col3P:
	    Rowdetection DOnothing, SetDirectionRIght, DOnothing, DOnothing


SetDirectionUp:
    LDI SnakeDirection, UP    ; Changer la direction en haut
    RET

SetDirectionDown:
    LDI SnakeDirection, DOWN  ; Changer la direction en bas
    RET

SetDirectionLeft:
    LDI SnakeDirection, LEFT  ; Changer la direction à gauche
    RET

SetDirectionRight:
    LDI SnakeDirection, RIGHT ; Changer la direction à droite
    RET

DOnothing:
	RET