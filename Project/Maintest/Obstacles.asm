; obstacles.asm

; D�finition des obstacles
.equ OBSTACLE = 0xFF   ; Chaque octet rempli (0xFF) repr�sente un obstacle (un bloc complet)

InitObstacles:
    PUSH ZL
    PUSH ZH
    PUSH R16
    PUSH R17

    LDI ZL, low(0x0100)    ; Commence � partir de l'adresse 0x0100
    LDI ZH, high(0x0100)
    
    ; Placer des obstacles horizontaux dans la premi�re ligne
    LDI R17, 5             ; Nombre d'obstacles � placer dans la premi�re ligne
    LDI R16, OBSTACLE      ; R16 contient la valeur de l'obstacle (0xFF)

WriteObstaclesLine0:
    ST Z+, R16             ; �crire l'obstacle dans le buffer � la position Z, puis incr�menter Z
    DEC R17
    BRNE WriteObstaclesLine0
	RET
    ; Passer � la ligne suivante (ajouter 5 octets pour la ligne suivante)
    LDI ZL, low(0x0100)    ; Revenir au d�but de la m�moire
    LDI ZH, high(0x0100)
    ADIW Z, 5*10           ; Avancer de 5*10 octets pour se positionner sur la deuxi�me ligne (ligne 10)

    LDI R17, 2             ; Nombre d'obstacles � placer dans la deuxi�me ligne (ici 2)
WriteObstaclesLine10:
    ST Z+, R16             ; �crire l'obstacle dans le buffer � la position Z, puis incr�menter Z
    DEC R17
    BRNE WriteObstaclesLine10
	RET
	LDI R18,0x01
	LDI R17,12
WriteOblique:
	ST Z+,R18
	ADIW Z, 4
	LSL R18
	CPI R18, 0x80
	BREQ reloadreg
	DEC R17
	BRNE WriteOblique	
    ; Restaurer les registres
    POP R17
    POP R16
    POP ZH
    POP ZL
    RET
reloadreg:
	LDI R18, 0x01
	RET

CheckObstacles:
	PUSH R16
	PUSH R17
	MOV R16, R0 ; contient la ligne de buffer
	MOV R17, R1 ; contient la position du serpent
	AND R16, R17
	TST R16
	BRNE Collision
	POP R16
	POP R17
	RET
Collision:
	POP R16
	POP R17
	RCALL CheckFoodCollision
	CPI R18, 1
	BRNE IsWall
	CPI R18,0
	BRNE EatFood
	RET
IsWall:
	RJMP restart
