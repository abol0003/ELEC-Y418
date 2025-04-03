;------------------------------------------------------------
; Code complet corrigé pour l’affichage du pixel du serpent et
; pour la transmission du buffer d’affichage vers l’écran
;------------------------------------------------------------

.INCLUDE "M328PDEF.INC"

.CSEG
.ORG 0x0000
RJMP init

.ORG 0x001A
;RJMP TIMER1_OVF

.ORG 0x0020
RJMP TIMER0_OVF

;------------------------------------------------------------
; Initialisation
;------------------------------------------------------------
init:
    ; Initialisation de la pile
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    LDI R16, LOW(RAMEND)
    OUT SPL, R16

    ; Configuration des ports PB3, PB4 et PB5 en sortie
    LDI R17, (1<<3)|(1<<4)|(1<<5)  ; Create a mask for bits 3, 4, and 5 (binary: 0011 1000)
    OUT PORTB, r17           ; Initialize these pins (set output state)
    OUT DDRB, r17            ; Set PB3, PB4, and PB5 as outputs
	; Configure PC2 comme sortie et initialise à 0 (LED éteinte)
	SBI DDRC, 2          ; Puis configurer PC2 en sortie
	SBI PORTC, 2         ; D’abord mettre à 0

    LDI R18, 0           ; Initialiser le compteur de ligne (pour le rafraîchissement)

    ; Configuration du Timer1 (pour la logique du jeu – inactif pour l’instant)
    LDI R16, 0

    STS TCCR1A, R16
    LDI R16, (1<<CS11)|(1<<CS10)   ; Prescaler clk/64
    STS TCCR1B, R16
    LDI R16, (1<<TOIE1)
    STS TIMSK1, R16

    ; Configuration du Timer0 pour l’affichage
    LDI R16, (1<<CS01)|(1<<CS00)  
    OUT TCCR0B, R16
	LDI R16, (1<<CS01)|(1<<CS00)   
    LDI R16, 56                    ; Valeur initiale pour TCNT0
    OUT TCNT0, R16
    LDI R16, (1<<TOIE0)
    STS TIMSK0, R16

    SEI
	RCALL ClearScreen      ; Effacer l'écran
    RCALL SnakeInit        ; Initialiser le serpent (affichage du pixel)
    RJMP MAINLOOP

;------------------------------------------------------------
; SnakeInit : Initialisation du serpent
; Positionne le pixel du serpent sur la ligne 1 et la colonne 39
;------------------------------------------------------------
SnakeInit:
    LDI snake_row, 2     ; Ligne 1
    LDI snake_col, 39    ; Colonne 39
    RCALL SetScreenBit   ; Allume le pixel correspondant dans le buffer
    RET
;------------------------------------------------------------
; SetScreenBit : Allume le pixel à la position (R20, R21)
;------------------------------------------------------------
SetScreenBit:
    PUSH YL
    PUSH YH
    RCALL GetByteAndMask   ; R0 contient l’octet actuel, R1 le masque du pixel
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
    LDI R16, 0b10000000  ; Masque initial pour la colonne 0
GetByteAndMaskColMask:
    TST R3 ; ici le reste <8 determinera dans quelle colonne on est 
    BREQ GetByteAndMaskEnd
    LSR R16             ; Décalage vers la droite
    DEC R3
    RJMP GetByteAndMaskColMask
GetByteAndMaskEnd:
    LD R0, Y            ;  lit le contenu de la mémoire pointée par Y
    MOV R1, R16         ; Copier le masque dans R1 de la colonne
    POP R3
    POP R2
    POP R16
    RET

;------------------------------------------------------------
; DisplayLine : Affiche une ligne du buffer sur l’écran
;------------------------------------------------------------

ClearScreen:
    PUSH ZL
    PUSH ZH
    PUSH R16
    PUSH R17
    LDI ZL, low(0x0100)
    LDI ZH, high(0x0100)
    LDI R16, 0       ; Valeur zéro pour effacer
    LDI R17, 70      ; Nombre d’octets à effacer
clear_loop:
    ST Z+, R16      ; Écrire 0 dans le buffer et incrémenter le pointeur
    DEC R17
    BRNE clear_loop

	POP R16
    POP R17
    POP ZH
    POP ZL
    RET
DisplayLine:
	PUSH	R0
	PUSH	R1
	PUSH	R16
	PUSH	R17
	PUSH	R20
	PUSH	ZL
	PUSH	ZH
	IN		R16,	SREG
	PUSH	R16

	LDI		ZH,		high(0x0100)
	LDI		ZL,		low(0x0100)

	LDI		R16,	5
	MUL		R16,	R24
	ADD		ZL,		R0
nbByte_line:
	LDI R16, 10 ;number of byte to send at same time
DisplayLineLoop:
	LD		R20,	Z+
	CALL	pushByte

	CPI		R16,	6
	BRNE	HighScreen

	ADIW	Z,		6*5

	SBI		PINB,	4

HighScreen:
	DEC		R16
	BRNE	DisplayLineLoop
	LDI		R20,	0x80
	; the goal is to transform the column number into binaire
	SBRC	R24,	2 ; if bit 2 is 0 then Swap is skipped
	SWAP	R20

	SBRC	R24,	0
	LSR		R20

	SBRS	R24,	1
	RJMP	EnableLine
	
	LSR		R20
	LSR		R20

EnableLine:
	CALL	pushByte
	SBI		PINB,	4
	DEC		R24
	BRGE	endScreen
	LDI		R24,	6

endScreen:
	POP		R16
	OUT		SREG,	R16
	POP 	ZH
	POP 	ZL
	POP 	R20
	POP		R17
	POP 	R16
	POP		R1
	POP		R0
	RETI

pushByte:
	LDI		R17,	8
pushByteLoop:
	CBI		PORTB,	3
	BST		R20,	0 ; prend le bit numero b de R20 et le met dans le bit T
	BRTC	send			;Branch if T Flag Cleared
	SBI		PORTB,	3
send:
	SBI		PINB,	5
	SBI		PINB,	5
	LSR		R20 ; decal vers la droite le bit 0 est mis dans le carry
	DEC		R17
	BRNE	pushByteLoop
	RET
;------------------------------------------------------------
; TIMER0_OVF : Routine d'interruption du Timer0 pour actualiser l’affichage
;
; Appelle DisplayLine pour afficher la ligne courante, puis
; incrémente le compteur de ligne (R18) et réinitialise TCNT0.
;------------------------------------------------------------
TIMER0_OVF:
    CBI PORTC, 2           ;  Toggle PB2 here to verify interrupt is firing   
    PUSH R0
    PUSH R16
    PUSH R17
    PUSH R18
    PUSH R19
    PUSH ZL
    PUSH ZH

    RCALL DisplayLine   ; Affiche la ligne actuelle du buffer

    INC R18
    CPI R18, 8
    BRLO skipReset
    LDI R18, 0
skipReset:
    LDI R16, 56
    OUT TCNT0, R16

    POP ZH
    POP ZL
    POP R19
    POP R18
    POP R17
    POP R16
    POP R0
    RETI

;------------------------------------------------------------
; TIMER1_OVF : Routine d'interruption du Timer1 (logique du jeu active)
; Cette routine vérifie la variable "direction" et appelle la routine
; de déplacement correspondante.
;------------------------------------------------------------
TIMER1_OVF:
    PUSH R16
    PUSH R17
    PUSH R18
    PUSH R19
    PUSH YL
    PUSH YH

    ; Vérification de la direction (les valeurs sont arbitraires et doivent
    ; correspondre à la logique de votre jeu)
    LDI R16, 6            ; Valeur pour la direction "droite"
    CP direction, R16
    BRNE notRight
    RCALL moveRight
    RJMP timer1_end

notRight:
    LDI R16, 4            ; Valeur pour la direction "gauche"
    CP direction, R16
    BRNE notLeft
    RCALL moveLeft
    RJMP timer1_end

notLeft:
    LDI R16, 8            ; Valeur pour la direction "haut"
    CP direction, R16
    BRNE notUp
    RCALL moveUp
    RJMP timer1_end

notUp:
    LDI R16, 2            ; Valeur pour la direction "bas"
    CP direction, R16
    BRNE timer1_end
    RCALL moveDown

timer1_end:
    POP YH
    POP YL
    POP R19
    POP R18
    POP R17
    POP R16
    RETI

;------------------------------------------------------------
; Définitions pour les variables de déplacement du serpent
;------------------------------------------------------------
.DEF direction = R25     ; Direction : 6 = droite, 4 = gauche, 8 = haut, 2 = bas
.DEF snake_row = R20     ; Coordonnée de la ligne du serpent
.DEF snake_col = R21     ; Coordonnée de la colonne du serpent

;------------------------------------------------------------
; Routines de déplacement du serpent
;------------------------------------------------------------
moveRight:
    INC snake_col           ; Augmenter la colonne (déplacement à droite)
    RCALL SetScreenBit      ; Allumer le pixel à la nouvelle position
    RET

moveLeft:
    DEC snake_col           ; Diminuer la colonne (déplacement à gauche)
    RCALL SetScreenBit
    RET

moveUp:
    DEC snake_row           ; Diminuer la ligne (déplacement vers le haut)
    RCALL SetScreenBit
    RET

moveDown:
    INC snake_row           ; Augmenter la ligne (déplacement vers le bas)
    RCALL SetScreenBit
    RET

;------------------------------------------------------------
; MAINLOOP : Boucle principale
; La gestion du jeu et de l’affichage est assurée par les interruptions.
;------------------------------------------------------------
MAINLOOP:
    RJMP MAINLOOP
