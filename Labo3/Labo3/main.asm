;
; Labo3.asm
;
; Created: 06-03-25 14:30:23
; Author : alexb
;

; Replace with your application code

.include "m328pdef.inc"  

; BUZZER c
.equ BUZZER_P       = 1        
.equ BUZZER_DDR     = DDRB     
.equ BUZZER_PORT    = PORTB    
.equ BUZZER_PIN     = PINB    

; Timer1 reset value for overflow timing
.equ TCNT1_RESET_880   = 47354  ;440Hz

; KEYBOARD - MATRIX LIKE NUMERATION
.equ KEYB_PIN   = PIND    
.equ KEYB_DDR   = DDRD    
.equ KEYB_PORT  = PORTD   
;see SME_MicrocontrollerBoard_v2.1_Schematic
.equ ROW1       = 7       ; Row 1 assigned to bit 7
.equ ROW2       = 6       
.equ ROW3       = 5       
.equ ROW4       = 4       
.equ COL1       = 3       
.equ COL2       = 2      
.equ COL3       = 1       
.equ COL4       = 0       

; LED 
.equ LEDUP_P    = 2      
.equ LEDDOWN_P  = 3       
.equ LED_DDR    = DDRC    
.equ LED_PORT   = PORTC   
.equ LED_PIN    = PINC    



; Macro "keyboardStep2" performs the switching of port directions for rows and columns 
; to determine which specific row has a key pressed.
.MACRO keyboardStep2
 ;the output configuration for rows generates the signal, while the input configuration for columns detects the signal when a button is pressed.
    ; Set the rows as outputs because use of KEYB_PORT
	LDI r16,(1<<ROW1)|(1<<ROW2)|(1<<ROW3)|(1<<ROW4)
	OUT KEYB_PORT,r16    ; Output the bit mask to the keyboard port to drive the rows
	
    ; Set the columns as inputs because use of KEYB_DDR
	LDI r16,(1<<COL1)|(1<<COL2)|(1<<COL3)|(1<<COL4)
	OUT KEYB_DDR,r16     ; Configure keyboard port data direction for columns
	NOP                 
	
    ; Check which row is LOW indicating that a key is pressed on that row
	; SBIS Make Skip next instruction if bit ROW1 in the PIN register is set (HIGH)
	SBIS KEYB_PIN,ROW1   
	RJMP @0            
	SBIS KEYB_PIN,ROW2   
	RJMP @1            
	SBIS KEYB_PIN,ROW3   
	RJMP @2           
	SBIS KEYB_PIN,ROW4   
	RJMP @3            
	RJMP reset        
.ENDMACRO


;-------
; CODE 
;-------
.CSEG

.ORG 0x0000         ; Reset vector address
rjmp init           ; Jump to the initialization routine

.ORG 0X001A         ; Timer1 overflow vector address
rjmp timer1_ovf     ; Jump to the Timer1 overflow interrupt routine


init:
	; Initialize LEDs: Configure LED pins as outputs and set them HIGH (LEDs off)
	SBI LED_DDR,LEDUP_P    
	SBI LED_DDR,LEDDOWN_P  
	SBI LED_PORT,LEDUP_P  
	SBI LED_PORT,LEDDOWN_P 
	
	; Initialize buzzer: Configure buzzer pin as output and set it HIGH (buzzer off)
	SBI BUZZER_DDR,BUZZER_P 
	SBI BUZZER_PORT,BUZZER_P 
	
	; Configure Timer1 in normal mode 
	LDS r16,TCCR1A
	CBR r16,(1<<WGM10)|(1<<WGM11)
	STS TCCR1A,r16

	LDS r16,TCCR1B
	CBR r16,(1<<WGM12)|(1<<WGM13)|(1<<CS12)|(1<<CS11)
	SBR r16,(1<<CS10)
	STS TCCR1B,r16

	; Activate Timer1 overflow interrupt (set TOIE1 bit in TIMSK1)
	LDS r16,TIMSK1
	SBR r16,(1<<TOIE1)
	STS TIMSK1,r16
	
	rjmp main     ; Jump to the main loop


main:
	; Check if all columns (COL) are HIGH (no key pressed)
		; First, set all rows to LOW as outputs and configure columns as inputs
		LDI r16,(1<<COL1)|(1<<COL2)|(1<<COL3)|(1<<COL4)
		LDI r17,(1<<ROW1)|(1<<ROW2)|(1<<ROW3)|(1<<ROW4)
		OUT KEYB_PORT,r16  ; Drive columns with HIGH values (or pull-ups if configured)
		OUT KEYB_DDR,r17   ; Set rows as outputs
		NOP                ; Small delay to allow the port to stabilize (allow led to be on at same time while pressing on 8 and 4)
		
		; Check each column; if a column reads LOW, it means a key in that column is pressed
		SBIS KEYB_PIN,COL1   ; Skip next instruction if COL1 is HIGH
		RJMP C1Pressed       ; If COL1 is LOW, jump to label C1Pressed
		SBIS KEYB_PIN,COL2
		RJMP C2Pressed       
		SBIS KEYB_PIN,COL3
		RJMP C3Pressed       
		SBIS KEYB_PIN,COL4
		RJMP C4Pressed       
		RJMP reset           

reset:
	; Reset state: Turn both LEDs off by setting them HIGH, disable interrupts, and return to main loop
	SBI LED_PORT,LEDUP_P
	SBI LED_PORT,LEDDOWN_P
	CLI                 ; Disable interrupts
	RJMP main           ;


;---------------------------------------------------
; Handling key press detection using the keyboardStep2 macro
;---------------------------------------------------
C1Pressed:
	keyboardStep2 C1R1Pressed,C1R2Pressed,C1R3Pressed,C1R4Pressed

C2Pressed:
	keyboardStep2 C2R1Pressed,C2R2Pressed,C2R3Pressed,C2R4Pressed

C3Pressed:
	keyboardStep2 C3R1Pressed,C3R2Pressed,C3R3Pressed,C3R4Pressed

C4Pressed:
	keyboardStep2 C4R1Pressed,C4R2Pressed,C4R3Pressed,C4R4Pressed


;---------------------------------------------------
; Actions corresponding to specific key presses
;---------------------------------------------------

C1R1Pressed:
	; Key corresponding to "7" pressed: Turn both LEDs on (active low) 
	CBI LED_PORT,LEDUP_P   ; Clear LED_UP (turn it on if active low)
	CBI LED_PORT,LEDDOWN_P ; Clear LED_DOWN (turn it on)
	CLI                  
	RJMP main             

C1R2Pressed:
	; Key corresponding to "4" pressed: LED UP off (set high), LED DOWN on (set low)
	SBI LED_PORT,LEDUP_P   ; Set LED_UP (off)
	CBI LED_PORT,LEDDOWN_P ; Clear LED_DOWN (on)
	CLI                    
	RJMP main              

C1R3Pressed:
	; Key corresponding to "1" pressed: Enable buzzer 
	SEI                    
	RJMP main              

C1R4Pressed:
	; Key corresponding to "A" pressed: Enable buzzer 
	SEI                    
	RJMP main              

C2R1Pressed:
	; Key corresponding to "8" pressed: LED UP on (clear, active low), 
	CBI LED_PORT,LEDUP_P   ; Clear LED_UP (on)
	SBI LED_PORT,LEDDOWN_P ; Set LED_DOWN (off)
	CLI                    
	RJMP main             

C2R2Pressed:
	; Key corresponding to "5" pressed: Enable buzzer
	SEI                    
	RJMP main              

C2R3Pressed:
	; Key corresponding to "2" pressed: Enable buzzer
	SEI                   
	RJMP main             

C2R4Pressed:
	; Key corresponding to "0" pressed: Enable buzzer
	SEI                    
	RJMP main              

C3R1Pressed:
	; Key corresponding to "9" pressed: Enable buzzer
	SEI                    
	RJMP main              

C3R2Pressed:
	; Key corresponding to "6" pressed: Enable buzzer
	SEI                    
	RJMP main              

C3R3Pressed:
	; Key corresponding to "3" pressed: Enable buzzer
	SEI                    
	RJMP main              

C3R4Pressed:
	; Key corresponding to "B" pressed: Enable buzzer
	SEI                    
	RJMP main              

C4R1Pressed:
	; Key corresponding to "F" pressed: Enable buzzer
	SEI                    
	RJMP main             

C4R2Pressed:
	; Key corresponding to "E" pressed: Enable buzzer
	SEI                    
	RJMP main              

C4R3Pressed:
	; Key corresponding to "D" pressed: Enable buzzer
	SEI                    
	RJMP main              

C4R4Pressed:
	; Key corresponding to "C" pressed: Enable buzzer
	SEI                    
	RJMP main              



timer1_ovf: 
	; This interrupt routine is called when Timer1 overflows
	; Reload Timer1 with the preset reset value to create a periodic interrupt
	LDI r16,HIGH(TCNT1_RESET_880)  ; Load high byte of the reset value into r16
	LDI r17,LOW(TCNT1_RESET_880)   ; Load low byte of the reset value into r17
	STS TCNT1H,r16                 ; Store high byte to Timer1 high register
	STS TCNT1L,r17                 ; Store low byte to Timer1 low register
	
	; Activate the buzzer by setting its output pin high (toggle it)
	SBI BUZZER_PIN,BUZZER_P
	RETI                         
