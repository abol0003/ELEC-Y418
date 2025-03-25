;---------------------------------------------------------
; Projet_corrige_mod_inverted.asm - Gestion de l'écran (80x7) avec buffer SRAM
; Version avec inversion verticale pour obtenir un pixel en haut à gauche
; et un délai prolongé.
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

    ; Initialisation : on souhaite que le pixel « logique » (row 0, col 0)
    ; s'affiche en haut à gauche. Pour cela, on calcule une "row effective" :
    ; effective_row = 7 – CurrentRow. Ici, CurrentRow = 0, donc effective_row = 7.
    LDI CurrentRow, 0        ; Indice logique = 0 (haut)
    LDI r26, 7               ; r26 = 7
    MOV r20, r26             ; r20 reçoit la row effective (7)
    LDI r21, 0              ; colonne 0
    RCALL SetScreenBit

    RCALL Display

    LDI Direction, 1         ; 1 = descente (logique)

    RJMP main

main:
    ; Effacer le pixel courant
    ; Calculer effective_row = 7 – CurrentRow
    MOV r26, CurrentRow
    LDI r27, 7
    SUB r27, r26           ; r27 = 7 – CurrentRow
    MOV r20, r27           ; utiliser cette valeur comme indice de ligne pour le buffer
    LDI r21, 0
    RCALL ClearScreenBit

    ; Mise à jour de CurrentRow (logique)
    CPI Direction, 1
    BREQ Down
    RJMP Up

Down:
    INC CurrentRow
    CPI CurrentRow, 7
    BRLO Continue
    LDI Direction, 0    ; inverser la direction (remonter)
    DEC CurrentRow
    RJMP Continue

Up:
    DEC CurrentRow
    BRMI ChangeDown
    RJMP Continue

ChangeDown:
    LDI Direction, 1    ; inverser la direction (redescendre)
    INC CurrentRow

Continue:
    ; Calculer la nouvelle row effective pour le pixel
    MOV r26, CurrentRow
    LDI r27, 7
    SUB r27, r26         ; effective_row = 7 – CurrentRow
    MOV r20, r27
    LDI r21, 0
    RCALL SetScreenBit

    RCALL Display

    RCALL LongDelay

    RJMP main

;---------------------------------------------------------
; Sous-programme LongDelay (délai prolongé)
LongDelay:
    PUSH r16
    PUSH r17
    PUSH r18
    LDI r16, 50       ; Ajustez ces valeurs pour obtenir le délai souhaité
LongDelay_Outer:
    LDI r17, 200
LongDelay_Middle:
    LDI r18, 250
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
; Envoi d'un octet au registre à décalage (MSB d'abord)
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

;---------------------------------------------------------
; Routine d'affichage
; Modification : calcul de la ligne active en partant de 0b10000000 et en décalant à droite.
Display:
    PUSH r16
    PUSH r17
    PUSH r18
    PUSH r19
    PUSH YL
    PUSH YH
    LDI r18, 0              ; index de ligne dans le buffer (0 = première ligne)
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
    ; Calcul du bit de ligne actif avec inversion : 
    ; Partir de 0b10000000 et décaler à droite pour correspondre à effective_row.
    LDI r16, 0b10000000
    MOV r19, r18
RowShift:
    CPI r19, 0
    BREQ RowDone
    LSR r16
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

;---------------------------------------------------------
; Allumer un pixel dans le buffer
; Entrées : r20 = effective_row, r21 = colonne
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

;---------------------------------------------------------
; Calculer l'adresse et le masque du bit dans le buffer
; Entrées : r20 = effective_row, r21 = colonne
; Sorties : r16 = octet actuel, r17 = masque
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

;---------------------------------------------------------
; Effacer un pixel dans le buffer
; Entrées : r20 = effective_row, r21 = colonne
ClearScreenBit:
    PUSH r16
    PUSH YL
    PUSH YH
    RCALL GetByteAndMask
    LDI r18, 0xFF
    EOR r17, r18         ; Inverser le masque
    AND r16, r17         ; Effacer le bit ciblé
    ST Y, r16
    POP YH
    POP YL
    POP r16
    RET
