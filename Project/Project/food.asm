; food.asm

; D�finition de la nourriture
.DEF food_row = R19     ; Coordonn�e de la ligne de la nourriture
.DEF food_col = R25     ; Coordonn�e de la colonne de la nourriture

; Routine d'initialisation de la nourriture
FoodInit:
	PUSH R22
	LDI food_row, 0x0A 
	LDI food_col, 0x3F       ; Valeur maximale de la colonne (39)
    CALL GenerateFoodPos
	POP R22
    RET

CheckPlace:
	PUSH R16
	PUSH R17
	MOV R16, R4 ; 
	MOV R17, R5 ;
	AND R16, R17
	TST R16
	BRNE GenerateFoodPos
	OR R4, R5            ; Effectue un OR pour ajouter la nourriture au buffer
    ST X, R4           ; �crit la valeur mise � jour dans le buffer
	POP R16
	POP R17
	RET
EatFood:
    CALL GenerateFoodPos    
    RET
GenerateFoodPos:
	PUSH R16
	PUSH R17
	MOV R17, food_row
    CALL RandomGenROW 
	MOV food_row, R17
	MOV R17, food_col
    CALL RandomGenCOL
	MOV food_col, R17
	POP R16 
	POP R17
	CALL SetFoodBuffer
    RET

; Routine pour g�n�rer un nombre al�atoire dans un registre donn�
RandomGenROW:
	;MOV R16, snake_row
	LDI R16, 0x0B
    EOR R17, R16
	;ANDI R17, 12
	CPI R17, 13
	BRSH LetGoInROW
    RET
LetGoInROW:
	AND R17,snake_col
	CPI R17, 13
	BRSH LetGoInROW
	RET
RandomGenCOL:
	MOV R16, snake_col
	LSR R16
	COM R16
    EOR R17, R16
	;ANDI R17, 39
	CPI R17, 40
	BRSH LetGoInCOL
    RET
LetGoInCOL:
	AND R17,snake_row
	CPI R17, 40
	BRSH LetGoInCOL
    RET

; Routine pour mettre � jour la position de la nourriture dans le buffer d'affichage
SetFoodBuffer:
	;PUSH R0
	;PUSH R1
	PUSH R2
	PUSH R3
	PUSH XL
	PUSH XH
    MOV R2, food_row
    MOV R3, food_col
    ; Initialiser le pointeur Y vers le d�but du buffer (0x0100)
    LDI XL, low(0x0100)
    LDI XH, high(0x0100)
    ; Pour chaque ligne, avancer de 5 octets (chaque ligne = 40 colonnes = 5 octets)
SetFoodBufferRow:
    TST R2
    BREQ SetFoodBufferP2 ; Branch if R2 == 0
    ADIW X, 5            ; Avance de 5 octets pour atteindre la ligne correcte
    DEC R2
    RJMP SetFoodBufferRow
SetFoodBufferP2:
    LDI R16, 8           ; Chaque octet repr�sente 8 colonnes
SetFoodBufferCol:
    CP R3, R16           ; V�rifie o� se trouve la colonne
    BRLO SetFoodBufferP3  ; Si c'est inf�rieur, on reste dans l'octet actuel
    SUB R3, R16
    ADIW X, 1            ; Avance d'un octet dans la ligne
    RJMP SetFoodBufferCol
SetFoodBufferP3:
    LDI R16, 0b00000001  ; Masque initial pour la colonne 0
SetFoodBufferColMask:
    TST R3
    BREQ SetFoodBufferEnd
    LSL R16              ; D�cale � gauche pour avancer dans les colonnes
    DEC R3
    RJMP SetFoodBufferColMask
SetFoodBufferEnd:
    LD R4, X             ; Lit le contenu de la m�moire point�e par Y
    MOV R5, R16          ; Place le masque dans R1
	CALL CheckPlace
	POP XH
    POP XL
    POP R3
    POP R2
    RET

; Routine de gestion de la collision entre le serpent et la nourriture
CheckFoodCollision:
    PUSH R16
	PUSH R17
    MOV R16, food_row    ; R�cup�re la position de la nourriture
    MOV R17, food_col    ; R�cup�re la position de la nourriture
    ; V�rifie si la position du serpent est la m�me que celle de la nourriture
    CP snake_row, R16
    BRNE NoCollision
    CP snake_col, R17
    BRNE NoCollision
    ; Si on est sur la m�me position, c'est une collision (manger la nourriture)
    LDI R18, 1 
	POP R16
	POP R17
	RET        
NoCollision:
	LDI R18,0
    POP R16
	POP R17
    RET


