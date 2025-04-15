.equ OBSTACLE = 0xFF

InitObstacles:
    PUSH ZL
    PUSH ZH
    PUSH R16
    PUSH R17
    LDI ZL, low(0x0100)
    LDI ZH, high(0x0100)
    LDI R17, 5
    LDI R16, OBSTACLE

WriteObstaclesLine0:
    ST Z+, R16
    DEC R17
    BRNE WriteObstaclesLine0

    LDI ZL, low(0x0100)
    LDI ZH, high(0x0100)
    ADIW Z, 5*10
    LDI R17, 2

WriteObstaclesLine10:
    ST Z+, R16
    DEC R17
    BRNE WriteObstaclesLine10
    LDI R18,0x01
    LDI R17,12

WriteOblique:
    ST Z+,R18
    ADIW Z, 4
    LSL R18
    CPI R18, 0x80
    DEC R17
    BRNE WriteOblique    
    POP R17
    POP R16
    POP ZH
    POP ZL
    RET

CheckObstacles:
    PUSH R16
    PUSH R17
    MOV R16, R0
    MOV R17, R1
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
    RJMP GameOver
	;RJMP restart
