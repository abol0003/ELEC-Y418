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
    ; Configure les lignes du clavier comme sorties et les colonnes comme entr�es
		LDI r16,(1<<COL1)|(1<<COL2)|(1<<COL3)|(1<<COL4)
		LDI r17,(1<<ROW1)|(1<<ROW2)|(1<<ROW3)|(1<<ROW4)
		OUT KEYB_PORT,r16  ; Drive columns with HIGH values (or pull-ups if configured)
		OUT KEYB_DDR,r17   ; Set rows as outputs

    RET

; Fonction pour lire les entr�es du clavier
ReadKeyboard:
    ; V�rifier chaque touche et affecter la direction correspondante
    SBIS PIND, COL2           ; Si le bouton 1 (haut) est appuy�
    RJMP SetDirectionUp

    SBIS PIND, COL2           ; Si le bouton 2 (bas) est appuy�
    RJMP SetDirectionDown

    SBIS PIND, COL3           ; Si le bouton 3 (gauche) est appuy�
    RJMP SetDirectionLeft

    SBIS PIND, COL4           ; Si le bouton 4 (droite) est appuy�
    RJMP SetDirectionRight

    RET         

SetDirectionUp:
    LDI SnakeDirection, UP    ; Changer la direction en haut
    RET

SetDirectionDown:
    LDI SnakeDirection, DOWN  ; Changer la direction en bas
    RET

SetDirectionLeft:
    LDI SnakeDirection, LEFT  ; Changer la direction � gauche
    RET

SetDirectionRight:
    LDI SnakeDirection, RIGHT ; Changer la direction � droite
    RET

