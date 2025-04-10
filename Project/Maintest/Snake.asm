; Snake.asm

.DEF snake_row = R20     ; Coordonnée de la ligne du serpent
.DEF snake_col = R21     ; Coordonnée de la colonne du serpent
.equ UP    = 1
.equ DOWN  = 2
.equ LEFT  = 3
.equ RIGHT = 4
.DEF SnakeDirection = R22

SnakeInit:
    LDI snake_row, 1   ; Ligne 1
    LDI snake_col, 6   ; Colonne 39
	LDI SnakeDirection, 0
    RCALL SetPosBuffer   ; Allume le pixel correspondant dans le buffer
    RET

SnakeMain:
    PUSH R16
    PUSH R17
    MOV R16, snake_row     ; R16 = ligne actuelle
    MOV R17, snake_col     ; R17 = colonne actuelle
	CPI SnakeDirection, RIGHT
    BRNE check_left
    DEC R17
	BRMI backleft                ; Déplacement vers la droite
    RJMP update_head
backleft:
	LDI R17, 39
    RJMP update_head
check_left:
    CPI SnakeDirection, LEFT
    BRNE check_up
    INC R17                ; Déplacement vers la gauche
	CPI R17, 40
	BREQ backright
    RJMP update_head
backright:
	LDI R17, 0
    RJMP update_head
check_up:
    CPI SnakeDirection, UP
    BRNE check_down
    DEC R16  
	BRMI gohighscreen              ; Déplacement vers le haut
    RJMP update_head
gohighscreen:
	LDI R16, 13
    RJMP update_head
check_down:
    CPI SnakeDirection, DOWN
    BRNE update_head       ; Si aucune des directions n'est détectée, on ne change pas la position
    INC R16 
	CPI R16, 14
	BREQ godownscreen
	RJMP update_head
godownscreen:
	LDI R16, 0
	RJMP update_head
update_head:
	CALL ClearOldPos
    MOV snake_row, R16
    MOV snake_col, R17
    RCALL SetPosBuffer
    POP R17
    POP R16
    RET

ClearOldPos:
	CBI PORTC,3
	PUSH YL
	PUSH YH
    RCALL GetByteAndMask ; R0 contient l’octet actuel du buffer, R1 le masque du pixel
	COM R1  ; allow to keep the obstacles on when snake goes in same byte of an pixel of obstacle
	AND R0,R1
	ST Y, R0
	POP YL
	POP YH
	RET



;------------------------------------------------------------
; Find column ( trame of bits ) and position in buffer (line)
;------------------------------------------------------------
SetPosBuffer:
    PUSH YL
    PUSH YH
    RCALL GetByteAndMask 
	RCALL CheckObstacles  ; R0 contient l’octet actuel, R1 le masque du pixel
    OR R0, R1            ; do or to keep previous led on on ( for example obstacle etc)
    ST Y, R0             ; Écrit l’octet mis à jour dans le buffer
    POP YH
    POP YL
    RET
;------------------------------------------------------------
; 
;	Is used to find the position of the snake
;
;------------------------------------------------------------
GetByteAndMask:
    PUSH R16
    PUSH R2
    PUSH R3
    ; Sauvegarder les coordonnées dans R2 (ligne) et R3 (colonne)
    MOV R2, R20
    MOV R3, R21
    ; Initialiser le pointeur Y vers le début du buffer (0x0100)
    LDI YL, low(0x0100)
    LDI YH, high(0x0100)
    ; Pour chaque ligne, avancer de 5 octets (chaque ligne = 40 colonnes = 5 octets)
GetByteAndMaskRow:
    TST R2
    BREQ GetByteAndMaskP2 ; branch if R2=0
    ADIW Y, 5 ; enable to select the good row
    DEC R2
    RJMP GetByteAndMaskRow
GetByteAndMaskP2:
    LDI R16, 8    ; Chaque octet représente 8 colonnes
GetByteAndMaskCol:
    CP R3, R16 ; is doing colnum/8
    BRLO GetByteAndMaskP3	;branch if lower
    SUB R3, R16
    ADIW Y, 1 ; max 5 times as only 5 octet in a row
    RJMP GetByteAndMaskCol
GetByteAndMaskP3:; ici on est dans la bonne adress de la ram
    LDI R16, 0b00000001  ; Masque initial pour la colonne 0
GetByteAndMaskColMask:
    TST R3 ; ici le reste <8 determinera dans quelle colonne on est 
    BREQ GetByteAndMaskEnd
    LSL R16             ; Décalage vers la gauche car le a colonne 0 est tout à droite
    DEC R3
    RJMP GetByteAndMaskColMask
GetByteAndMaskEnd:
    LD R0, Y            ;  lit le contenu de la mémoire pointée par Y
    MOV R1, R16         ; Copier le masque dans R1 de la colonne
    POP R3
    POP R2
    POP R16
    RET


