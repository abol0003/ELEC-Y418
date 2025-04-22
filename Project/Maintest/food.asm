; food.asm

.DEF food_row = R19     
.DEF food_col = R25     
.DEF random =R18
.DEF score= R23
FoodInit:
    ; Initializes food by setting the row and column values, setting the score to 0, and calling GenerateFoodPos to place the food.
	PUSH R22
	LDI score, 0
	LDI food_row, 0x0C 
	LDI food_col, 0x27       
	LDI random, 0x68
    CALL GenerateFoodPos
	POP R22
    RET

CheckPlace:
    ; Checks if the food's position collides with any other element (like obstacles or snake); if not, updates the buffer with the food position.
	PUSH R16
	PUSH R17
	MOV R16, R4  
	MOV R17, R5 
	AND R16, R17
	TST R16
	BRNE GenerateFoodPos
	OR R4, R5            ; Performs an OR to add food to the buffer
    ST X, R4           
	POP R16
	POP R17
	RET
EatFood:
    ; Increments the score and calls GenerateFoodPos to place new food on the screen.
	INC score
    CALL GenerateFoodPos    
    RET
GenerateFoodPos:
    ; Generates random food position by calling RandomGenROW and RandomGenCOL for row and column generation; ensures the food doesn't overlap with the snake's position.
    PUSH R16
    PUSH R17
    CALL Mixing

    MOV R17, food_row      
GenFoodRow:
	LSR random
    CALL RandomGenROW      
    CP R17, snake_row     
    BREQ GenFoodRow        
    MOV food_row, R17      

    MOV R17, food_col      
    CALL RandomGenCOL 
    CPI R17, 0             ; Checking to avoid the zero column because kill all the random generation by mutliplying by 0 stay 0
    BRNE StoreFoodCol
Notzero:
	INC R17
	CALL RandomGenCOL 
	CPI R17,0
	BREQ Notzero
StoreFoodCol:
    MOV food_col, R17      

    CALL SetFoodBuffer    
    POP R16
    POP R17
    RET

RandomGenROW:
    ; Generates a random row for the food using bit shifting and XOR operations on the random value, ensuring it's within the valid row range (0 to 13).
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
    ; Generates a random column for the food by performing bit shifts and XOR operations on the random value, ensuring the column is between 0 and 39.
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
    ; Performs a randomization operation on the 'random' value by shifting bits and XOR-ing it with the snake's column value to introduce variability.
	PUSH R17
	PUSH R16
    MOV R16, random                
    MOV R17, random               
    LSR random                      
    BST R16, 0                       ; Take the LSB from R16
    BLD random, 6                    ; Place this bit in the 6th position of 'random'
    BLD R17, 6                       ; Do the same for R17
    EOR R17, R16                     ; XOR R16 with R17 and store result in R17
    BST R17, 6                       ; Take the 7th bit from R17
    BLD random, 5                    ; Place this bit back into random
    EOR random, snake_col            ; XOR random with the snake's column value                  
	POP R16
	POP R17
    RET
Mixing2:
    ; Similar to Mixing, but modifies the random value using the snake's row value instead of the column value.
	PUSH R17
	PUSH R16
    MOV R16, random                 ; Clone random to R16
    MOV R17, random                 ; Clone random to R19
    LSR random                      ; Décale random à droite
   BST R16, 0                       ; Take the LSB from R16
    BLD random, 4                    ; Place this bit in the 4th position of 'random'
    BLD R17, 6                       ; Do the same for R17
    EOR R17, R16                     ; XOR R16 with R17 and store result in R17
    BST R17, 4                       ; Take the 7th bit from R17
    BLD random, 5                    ; Place this bit back into 'random'
    EOR random, snake_row            ; XOR random with the snake's row value to introduce further variability
    POP R16
	POP R17
    RET

SetFoodBuffer: ; SImilar to GetByteAndMask
    ; Updates the screen buffer with the food's position by using the food's row and column to calculate the correct memory address and set the corresponding pixel.
	PUSH R2
	PUSH R3
	PUSH XL
	PUSH XH
    MOV R2, food_row
    MOV R3, food_col
    LDI XL, low(0x0100)
    LDI XH, high(0x0100)
SetFoodBufferRow:
    TST R2
    BREQ SetFoodBufferP2
    ADIW X, 5          
    DEC R2
    RJMP SetFoodBufferRow
SetFoodBufferP2:
    LDI R16, 8          
SetFoodBufferCol:
    CP R3, R16          
    BRLO SetFoodBufferP3  
    SUB R3, R16
    ADIW X, 1            
    RJMP SetFoodBufferCol
SetFoodBufferP3:
    LDI R16, 0b00000001  
SetFoodBufferColMask:
    TST R3
    BREQ SetFoodBufferEnd
    LSL R16            
    DEC R3
    RJMP SetFoodBufferColMask
SetFoodBufferEnd:
    LD R4, X            
    MOV R5, R16         
	CALL CheckPlace
	POP XH
    POP XL
    POP R3
    POP R2
    RET

CheckFoodCollision:
    ; Checks if the snake's current position overlaps with the food's position
    PUSH R16
	PUSH R17
    MOV R16, food_row    ;  Recovers food position
    MOV R17, food_col  
	; Check whether the snake's position is the same as the food's position
    CP snake_row, R16
    BRNE NoCollision
    CP snake_col, R17
    BRNE NoCollision
    LDI R18, 1 ; if 1 is food collision and not wall colission it is used to differentiate
	POP R16
	POP R17
	RET        
NoCollision:
	LDI R18,0
    POP R16
	POP R17
    RET


