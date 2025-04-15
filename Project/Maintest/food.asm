; food.asm

; D�finition de la nourriture
.DEF food_row = R19     ; Coordonn�e de la ligne de la nourriture
.DEF food_col = R25     ; Coordonn�e de la colonne de la nourriture
.DEF random =R18
.DEF score= R23
; Routine d'initialisation de la nourriture
FoodInit:
	PUSH R22
	LDI score, 0
	LDI food_row, 0x0C 
	LDI food_col, 0x27       ; Valeur maximale de la colonne (39)
	LDI random, 0x58
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
	INC score
    CALL GenerateFoodPos    
    RET
GenerateFoodPos:
    PUSH R16
    PUSH R17
    CALL Mixing

    ; G�n�ration de la ligne de la nourriture
    MOV R17, food_row      ; Pr�pare R17 pour RandomGenROW
GenFoodRow:
	LSR random
    CALL RandomGenROW      ; R17 contient une ligne al�atoire (valeur entre 0 et 12)
    CP R17, snake_row      ; Compare � la ligne du serpent (snake_row)
    BREQ GenFoodRow        ; Si �gal, on r�g�n�re une nouvelle ligne
    MOV food_row, R17      ; Sinon, on sauvegarde la ligne dans food_row

    ; G�n�ration de la colonne de la nourriture
    MOV R17, food_col      ; Pr�pare R17 pour RandomGenCOL
    CALL RandomGenCOL 
	;LSL random     ; R17 contient une colonne al�atoire (valeur entre 0 et 39)
    CPI R17, 0             ; V�rification pour �viter la colonne z�ro
    BRNE StoreFoodCol
Notzero:
	INC R17
	CALL RandomGenCOL 
	CPI R17,0
	BREQ Notzero
StoreFoodCol:
    MOV food_col, R17      ; On sauvegarde la colonne dans food_col

    CALL SetFoodBuffer     ; Met � jour le buffer d'affichage
    POP R16
    POP R17
    RET



; Routine pour g�n�rer un nombre al�atoire dans un registre donn�
RandomGenROW:
	LSR random
    EOR R17, random
	CPI R17, 13
	BRSH LetGoInROW
    RET
LetGoInROW:
	LSR random
	LSR R17
	CALL Mixing2
	EOR R17,random
	CPI R17, 13
	BRSH LetGoInROW
	RET
RandomGenCOL:
	MOV R16, random
	LSL random
	COM R16
	EOR random, R16
    EOR R17, random
	CPI R17, 40
	BRSH LetGoInCOL
    RET

LetGoInCOL:
	LSR random
	LSR R17
	EOR R17,random
	CPI R17, 40
	BRSH LetGoInCOL
    RET
Mixing:
	PUSH R17
	PUSH R16
    MOV R16, random                 ; Clone random to R16
    MOV R17, random                 ; Clone random to R19
    LSR random                      ; D�cale random � droite
    BST R16, 0                       ; Prend le premier bit (LSB) de R16
    BLD random, 6                    ; Place ce bit en 6�me position de random
    BLD R17, 6                       ; M�me pour R19
    EOR R17, R16                     ; R19 = R16 XOR R19
    BST R17, 6                       ; Prend le 7�me bit de R19
    BLD random, 5 
	EOR random, snake_col                   ; Place ce bit en 5�me position de random
	POP R16
	POP R17
    RET
Mixing2:
	PUSH R17
	PUSH R16
    MOV R16, random                 ; Clone random to R16
    MOV R17, random                 ; Clone random to R19
    LSR random                      ; D�cale random � droite
    BST R16, 0                       ; Prend le premier bit (LSB) de R16
    BLD random, 4                    ; Place ce bit en 6�me position de random
    BLD R17, 6                       ; M�me pour R19
    EOR R17, R16                     ; R19 = R16 XOR R19
    BST R17, 4                       ; Prend le 7�me bit de R19
    BLD random, 5 
	EOR random, snake_row                   ; Place ce bit en 5�me position de random
	POP R16
	POP R17
    RET
; Routine pour mettre � jour la position de la nourriture dans le buffer d'affichage
SetFoodBuffer:

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


