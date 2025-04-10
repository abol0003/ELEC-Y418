; food.asm

; Définition de la nourriture
.equ FOOD = 0x80  ; Chaque octet rempli (0x80) représente un pixel de nourriture (un bloc complet)

.DEF food_row = R19     ; Coordonnée de la ligne de la nourriture
.DEF food_col = R25     ; Coordonnée de la colonne de la nourriture

; Routine d'initialisation de la nourriture
FoodInit:
	PUSH R22
	LDI food_row, 0x0A 
	LDI food_col, 0x3F       ; Valeur maximale de la colonne (39)
    CALL GenerateFoodPos
	POP R22
    RET

; Routine pour générer une position aléatoire pour la nourriture
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

; Routine pour générer un nombre aléatoire dans un registre donné
RandomGenROW:
	;MOV R16, snake_row
	LDI R16, 0x0B
    EOR R17, R16
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
	CPI R17, 40
	BRSH LetGoInCOL
    RET
LetGoInCOL:
	AND R17,snake_row
	CPI R17, 40
	BRSH LetGoInCOL
    RET

; Routine pour mettre à jour la position de la nourriture dans le buffer d'affichage
SetFoodBuffer:
	PUSH R2
	PUSH R3
    MOV R2, food_row
    MOV R3, food_col
    ; Initialiser le pointeur Y vers le début du buffer (0x0100)
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
    LDI R16, 8           ; Chaque octet représente 8 colonnes
SetFoodBufferCol:
    CP R3, R16           ; Vérifie où se trouve la colonne
    BRLO SetFoodBufferP3  ; Si c'est inférieur, on reste dans l'octet actuel
    SUB R3, R16
    ADIW X, 1            ; Avance d'un octet dans la ligne
    RJMP SetFoodBufferCol
SetFoodBufferP3:
    LDI R16, 0b00000001  ; Masque initial pour la colonne 0
SetFoodBufferColMask:
    TST R3
    BREQ SetFoodBufferEnd
    LSL R16              ; Décale à gauche pour avancer dans les colonnes
    DEC R3
    RJMP SetFoodBufferColMask
SetFoodBufferEnd:
    LD R0, X             ; Lit le contenu de la mémoire pointée par Y
    MOV R1, R16          ; Place le masque dans R1
	CALL CheckPlace
    RET

CheckPlace:
	PUSH R16
	PUSH R17
	MOV R16, R0 ; 
	MOV R17, R1 ;
	AND R16, R17
	TST R16
	BRNE NoPlace
	OR R0, R1            ; Effectue un OR pour ajouter la nourriture au buffer
    ST X, R0 
	POP R2
	POP R3            ; Écrit la valeur mise à jour dans le buffer
	POP R16
	POP R17
	RET
NoPlace:
	POP R2
	POP R3
	RJMP GenerateFoodPos


; Routine de gestion de la collision entre le serpent et la nourriture
CheckFoodCollision:
    PUSH R16
	PUSH R17
    MOV R16, food_row    ; Récupère la position de la nourriture
    MOV R17, food_col    ; Récupère la position de la nourriture
    ; Vérifie si la position du serpent est la même que celle de la nourriture
    CP snake_row, R16
    BRNE NoCollision
    CP snake_col, R17
    BRNE NoCollision
    ; Si on est sur la même position, c'est une collision (manger la nourriture)
    CALL EatFood         ; Appeler la routine pour manger la nourriture
NoCollision:
    POP R16
	POP R17
    RET

EatFood:
    CALL GenerateFoodPos    
    RET
