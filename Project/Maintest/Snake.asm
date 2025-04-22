; Snake.asm

.DEF snake_row = R20    
.DEF snake_col = R21     
.equ UP    = 1
.equ DOWN  = 2
.equ LEFT  = 3
.equ RIGHT = 4
.DEF SnakeDirection = R22

SnakeInit:
    ; Initializes the snake's starting position and calls SetPosBuffer to set the pixel in the buffer.
    LDI snake_row, 6
    LDI snake_col, 10 
	LDI SnakeDirection, 3
    RCALL SetPosBuffer   
    RET

SnakeMain:
    ; Main snake movement logic: checks the snake's direction (RIGHT, LEFT, UP, DOWN) and updates its position accordingly.
    PUSH R16
    PUSH R17
    MOV R16, snake_row     
    MOV R17, snake_col    
	CPI SnakeDirection, RIGHT
    BRNE check_left
    DEC R17       ;move right
	BRMI backleft               
    RJMP update_head
backleft:
	LDI R17, 39
    RJMP update_head
check_left:
    CPI SnakeDirection, LEFT
    BRNE check_up
    INC R17                ;move left
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
	BRMI gohighscreen              ; move up
    RJMP update_head
gohighscreen:
	LDI R16, 13
    RJMP update_head
check_down:
    CPI SnakeDirection, DOWN
    BRNE update_head       ; if nothing change we keep going in same direction
    INC R16					; move down
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
    ; Clears the previous position of the snake by resetting the corresponding pixel in the buffer while keeping obstacles intact.
	PUSH YL
	PUSH YH
    RCALL GetByteAndMask ;R0 contains the current buffer byte, R1 the pixel mask
	COM R1  ; allow to keep the obstacles on when snake goes in same byte of an pixel of obstacle
	AND R0,R1
	ST Y, R0
	POP YL
	POP YH
	RET

SetPosBuffer:
    ; Sets the position of the snake by updating the corresponding pixel in the display buffer, accounting for obstacles.
    PUSH YL
    PUSH YH
	PUSH R0
	PUSH R1
    RCALL GetByteAndMask 
	RCALL CheckObstacles  
	RCALL GetByteAndMask ; we have to call it 2 times because if new food is in same byte, the food will not be showed as Checkobstacle also change buffer
    OR R0, R1            ; do or to keep previous led on on ( for example obstacle etc)
    ST Y, R0 
	POP R0
	POP R1            
    POP YH
    POP YL
    RET
GetByteAndMask:
    ; Retrieves the current byte and calculates the mask for the snake's position based on its row and column, returning the value from the buffer.
    PUSH R16
    PUSH R2
    PUSH R3
    MOV R2, R20
    MOV R3, R21
    LDI YL, low(0x0100)
    LDI YH, high(0x0100)
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
GetByteAndMaskP3:; here we are in the right address of the ram
    LDI R16, 0b00000001  ; Initial mask for column 0
GetByteAndMaskColMask:
    TST R3 ; here the remainder <8 will determine which column you are in 
    BREQ GetByteAndMaskEnd
    LSL R16             ; Shift to the left because a column 0 is on the far right
    DEC R3
    RJMP GetByteAndMaskColMask
GetByteAndMaskEnd:
    LD R0, Y            ;  reads the contents of the memory pointed to by Y
    MOV R1, R16         
    POP R3
    POP R2
    POP R16
    RET


