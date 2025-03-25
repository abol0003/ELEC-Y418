;---------------------------------------------------------
; Projet_corrige_mod.asm - Gestion de l'écran (80x7) avec buffer SRAM
; Version avec un délai beaucoup plus long pour ralentir le déplacement
;---------------------------------------------------------
.include "m328pdef.inc"

; CONSTANTES
.equ SCREEN_DDR      = DDRB
.equ SCREEN_PORT     = PORTB
.equ ScreenL         = 0x00
.equ ScreenH         = 0x01
.equ ScreenLength    = 70      ; 7 lignes x 10 octets
.equ ColsPerLine     = 10

.def CurrentRow = r22
.def Direction   = r23

;---------------------------------------------------------
.CSEG
.ORG 0x0000
rjmp init

init:
    ; Configurer PB3, PB4, PB5 comme sorties et les mettre à 0
    LDI r16, (1<<3)|(1<<4)|(1<<5)
    OUT SCREEN_DDR, r16
    CLR r16
    OUT SCREEN_PORT, r16

    RCALL ScreenInit

    ; Allumer le pixel initial (ligne 0, colonne 0)
    LDI r20, 0        ; ligne 0
    LDI r21, 0        ; colonne 0
    RCALL SetScreenBit

    ; Afficher le buffer pour vérifier
    RCALL Display

    ; Initialisation de la position et de la direction
    LDI CurrentRow, 0
    LDI Direction, 1       ; 1 = descente

    RJMP main

;---------------------------------------------------------
; Boucle principale modifiée :
; - Effacer l'ancien pixel
; - Mettre à jour la position
; - Allumer le nouveau pixel
; - Actualiser l'affichage et attendre un long délai
main:
    ; Effacer le pixel courant
    MOV r20, CurrentRow
    LDI r21, 0
    RCALL ClearScreenBit

    ; Mise à jour de la position verticale
    CPI Direction, 1
    BREQ Down
    RJMP Up

Down:
    INC CurrentRow
    CPI CurrentRow, 7
    BRLO Continue
    LDI Direction, 0    ; Inverser la direction (remonter)
    DEC CurrentRow
    RJMP Continue

Up:
    DEC CurrentRow
    BRMI ChangeDown
    RJMP Continue

ChangeDown:
    LDI Direction, 1    ; Inverser la direction (redescendre)
    INC CurrentRow

Continue:
    ; Allumer le pixel à la nouvelle position dans le buffer
    MOV r20, CurrentRow
    LDI r21, 0
    RCALL SetScreenBit

    ; Actualiser l'affichage
    RCALL Display

    ; Appel d'un délai prolongé pour ralentir le mouvement
    RCALL LongDelay

    RJMP main

;---------------------------------------------------------
; Sous-programme LongDelay : triple boucle imbriquée pour un délai très long
LongDelay:
    PUSH r16
    PUSH r17
    PUSH r18
    ; Ces valeurs peuvent être ajustées pour obtenir le délai désiré
    LDI r16, 50       ; boucle extérieure
LongDelay_Outer:
    LDI r17, 200      ; boucle intermédiaire
LongDelay_Middle:
    LDI r18, 250      ; boucle intérieure
LongDelay_Inner:
    DEC r18
    BRNE LongDelay_Inner
    DEC r17
    BRNE LongDelay_Middle
    DEC r16
    BRNE LongDelay_Outer
    POP r18
    POP r17
    POP r16
    RET

;---------------------------------------------------------
; Sous-routines inchangées (shift_out_byte, ScreenInit, Display, SetScreenBit, 
; GetByteAndMask, ClearScreenBit)

shift_out_byte:
    PUSH r16
    PUSH r17
    MOV r17, r16          ; sauvegarder r16 dans r17
    LDI r16, 8
shift_loop:
    ROL r17
    BRCC zero_bit
    SBI SCREEN_PORT, 3
    RJMP clock_pulse
zero_bit:
    CBI SCREEN_PORT, 3
clock_pulse:
    SBI SCREEN_PORT, 5
    CBI SCREEN_PORT, 5
    DEC r16
    BRNE shift_loop
    POP r17
    POP r16
    RET

ScreenInit:
    PUSH r16
    PUSH r17
    PUSH YL
    PUSH YH
    LDI r17, ScreenLength
    LDI YL, ScreenL
    LDI YH, ScreenH
    CLR r16
ClearLoop:
    ST Y+, r16
    DEC r17
    BRNE ClearLoop
    POP YH
    POP YL
    POP r17
    POP r16
    RET

Display:
    PUSH r16
    PUSH r17
    PUSH r18
    PUSH r19
    PUSH YL
    PUSH YH
    LDI r18, 0              ; index de ligne
DisplayLoop:
    LDI r19, ColsPerLine    ; nombre d'octets par ligne
    LDI YL, ScreenL
    LDI YH, ScreenH
    MUL r18, r19
    ADD YL, r0
    ADC YH, r1
ColLoop:
    LD r16, Y+
    RCALL shift_out_byte
    DEC r19
    BRNE ColLoop
    ; Calcul du bit de ligne active
    LDI r16, 0b00000001
    MOV r19, r18
RowShift:
    CPI r19, 0
    BREQ RowDone
    LSL r16
    DEC r19
    RJMP RowShift
RowDone:
    RCALL shift_out_byte
    SBI SCREEN_PORT, 4
    CBI SCREEN_PORT, 4
    INC r18
    CPI r18, 7
    BRLO DisplayLoop
    POP YH
    POP YL
    POP r19
    POP r18
    POP r17
    POP r16
    RET

SetScreenBit:
    PUSH r16
    PUSH r17
    PUSH r18
    PUSH YL
    PUSH YH
    RCALL GetByteAndMask
    OR r16, r17
    ST Y, r16
    POP YH
    POP YL
    POP r18
    POP r17
    POP r16
    RET

GetByteAndMask:
    PUSH r16
    PUSH r17
    PUSH r18
    LDI YL, ScreenL
    LDI YH, ScreenH
    LDI r16, ColsPerLine
    MUL r20, r16
    ADD YL, r0
    ADC YH, r1
    LDI r17, 8
ColLoop_GBM:
    CP r21, r17
    BRLO FoundByte
    SUB r21, r17
    ADIW YL, 1
    RJMP ColLoop_GBM
FoundByte:
    LDI r18, 0b10000000
ShiftMask:
    TST r21
    BREQ DoneMask
    LSR r18
    DEC r21
    RJMP ShiftMask
DoneMask:
    LD r16, Y
    MOV r17, r18
    POP r18
    POP r17
    POP r16
    RET

ClearScreenBit:
    PUSH r16
    PUSH YL
    PUSH YH
    RCALL GetByteAndMask
    LDI r18, 0xFF
    EOR r17, r18
    AND r16, r17
    ST Y, r16
    POP YH
    POP YL
    POP r16
    RET
