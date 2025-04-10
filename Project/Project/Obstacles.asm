; obstacles.asm

; D�finition des obstacles
.equ OBSTACLE = 0xFF   ; Chaque octet rempli (0xFF) repr�sente un obstacle (un bloc complet)

InitObstacles:
    PUSH ZL
    PUSH ZH
    PUSH R16
    PUSH R17
    LDI ZL, low(0x0100)    ; Commence � partir de l'adresse 0x0200 (par exemple pour une zone r�serv�e aux obstacles)
    LDI ZH, high(0x0100)
    
    ; Placer des obstacles horizontaux
    LDI R17, 5             ; Nombre d'obstacles horizontaux � placer
    LDI R16, OBSTACLE      ; R16 contient la valeur de l'obstacle (0xFF)

WriteObstaclesHorizontal:
    ST Z+, R16             ; �crire l'obstacle dans le buffer � la position Z, puis incr�menter Z
    DEC R17
    BRNE WriteObstaclesHorizontal   ; R�p�ter jusqu'� placer tous les obstacles horizontaux
    
    ; Placer des obstacles verticaux
    LDI R17, 6             ; Nombre d'obstacles verticaux (en lignes)
    LDI R18, 5             ; Colonne de d�part (colonne 5 dans cet exemple)
    POP R17
    POP R16
    POP ZH
    POP ZL
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
	RJMP restart
