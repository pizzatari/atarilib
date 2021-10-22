; -----------------------------------------------------------------------------
; Desc:     Includes math subroutines.
; Params:   bank #
; Outputs:
; -----------------------------------------------------------------------------

    MAC INCLUDE_MATH_FUNCS

; -----------------------------------------------------------------------------
; Desc:     Computes log2 of the value given.
; Inputs:   A register (value)
; Ouputs:   X register (result)
;           1-8 when A>0, 0 otherwise.
; Notes:
;   Max cycles: 71 = 15 + (7 * 7 - 1) + 8
; ----------------------------------------------------------------------------
Bank{1}_Log2 SUBROUTINE ; 6 (6)
    ldx #0              ; 3 (9)
    tay                 ; 2 (11)    save a copy
    cmp #0              ; 2 (13)
    beq .Return         ; 2 (15)

.Loop
    inx                 ; 2 (2)
    lsr                 ; 2 (4)
    bne .Loop           ; 3 (7)

    tya                 ; 2 (2)     restore original value
.Return
    rts                 ; 6 (8)

; -----------------------------------------------------------------------------
; Desc:     For the value given, computes the highest powers of two that are
;           below and above the value
; Inputs:   A register (power of 2 greater than value)
; Ouputs:   X register (power of 2 less than value)
; -----------------------------------------------------------------------------
#if 0
Bank{1}_Pow2Max SUBROUTINE  ; 6 (6)
    pha                     ; 3 (9)
    tsx                     ; 2 (11)

    lsr                     ; 2 (13)
    ora $1,x                ; 4 (17)
    sta $1,x                ; 4 (21)
    lsr                     ; 2 (23)
    lsr                     ; 2 (25)
    ora $1,x                ; 4 (29)
    sta $1,x                ; 4 (33)
    lsr                     ; 2 (35)
    lsr                     ; 2 (37)
    lsr                     ; 2 (39)
    lsr                     ; 2 (41)
    ora $1,x                ; 4 (45)
    sta $1,x                ; 4 (49)

    clc                     ; 2 (51)
    adc #1                  ; 2 (53)
    lsr                     ; 2 (55)
    tax                     ; 2 (57)
    pla                     ; 4 (61)

    clc                     ; 2 (63)
    adc #1                  ; 2 (65)

    rts                     ; 6 (71)
#endif
    ENDM

    MAC INCLUDE_MATH_SUBS
; -----------------------------------------------------------------------------
; Desc:     Add two 3-byte integers.
; Inputs:   TempPtr (addend)
;           TempPtr2 (addend)
; Outputs:  TempPtr (result)
; Notes:    Integers are MSB order and the carry flag indicates wraparound.
; -----------------------------------------------------------------------------
Bank{1}_AddInt3Ptr SUBROUTINE
    clc

    ldy #2
    lda (TempPtr),y
    adc (TempPtr2),y
    sta (TempPtr),y

    dey
    lda (TempPtr),y
    adc (TempPtr2),y
    sta (TempPtr),y

    dey
    lda (TempPtr),y
    adc (TempPtr2),y
    sta (TempPtr),y

    rts

; -----------------------------------------------------------------------------
; Desc:     Subtract two 3-byte integers.
; Inputs:   TempPtr (minuend)
;           TempPtr2 (subtrahend)
; Outputs:  TempPtr (result)
; Notes:    Integers are MSB order.
; -----------------------------------------------------------------------------
Bank{1}_SubInt3Ptr SUBROUTINE
    sec

    ldy #2
    lda (TempPtr),y
    sbc (TempPtr2),y
    sta (TempPtr),y

    dey
    lda (TempPtr),y
    sbc (TempPtr2),y
    sta (TempPtr),y

    dey
    lda (TempPtr),y
    sbc (TempPtr2),y
    sta (TempPtr),y

    rts

; -----------------------------------------------------------------------------
; Desc:     Divide a 3-byte BCD integer by 2.
; Inputs:   TempPtr2 (dividend)
; Outputs:  TempPtr2 (result)
; Notes:    BCD must be turned on. Integers are MSB order.
; -----------------------------------------------------------------------------
Bank{1}_Div2BCD3Ptr SUBROUTINE
    ldy #2
.Divide
    lda (TempPtr2),y
    tax
    and #%11101111              ; force 10s place to be even
    lsr                         ; divide by 2
    sta (TempPtr2),y
    php                         ; save the carry flag
    ; check if 10s place was odd
    txa
    and #%00010000
    beq .IsEven10
    clc
    lda #$05
    adc (TempPtr2),y            ; 10s place is odd, add 10/2
    sta (TempPtr2),y
.IsEven10
    dey                         ; next byte
    bpl .Divide

    ; corrections for 1s place being odd
    ldy #1
.Correction
    plp
    bcc .Skip
    clc
    lda #$50
    adc (TempPtr2),y            ; 10s place is odd, +10/2 to next digit
    sta (TempPtr2),y
.Skip
    iny
    cpy #3
    bne .Correction

    plp                         ; throw away the last one
    rts

; -----------------------------------------------------------------------------
; Desc:     Compare two unsigned 3-byte BCD integers in MSB order.
; Inputs:   TempPtr
;           TempPtr2
; Outputs:  A register
;           1 if *TempPtr > *TempPtr2
;           0 if *TempPtr = *TempPtr2
;          -1 if *TempPtr < *TempPtr2
; -----------------------------------------------------------------------------
Bank{1}_CompareBCD3Ptr SUBROUTINE
    ldy #0
    lda (TempPtr),y
    cmp (TempPtr2),y
    bcc .ReturnLt
    bne .ReturnGtr

    iny
    lda (TempPtr),y
    cmp (TempPtr2),y
    bcc .ReturnLt
    bne .ReturnGtr

    iny
    lda (TempPtr),y
    cmp (TempPtr2),y
    bcc .ReturnLt
    bne .ReturnGtr

    ; return equal
    lda #0
    rts

.ReturnLt
    lda #-1
    rts

.ReturnGtr
    lda #1
    rts

    ENDM
