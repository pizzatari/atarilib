; -----------------------------------------------------------------------------
; Macros and subroutines for calling a procedure in another bank.
;
;   Routines must reside in the same page and the same address offset
;   within each bank.
;
;   Routines must also be relocated to their own address spaces for bank
;   detection to work:
;       RORG: ... $9000, $b000, $d000, $f000
;
;   INCLUDE_BANKSWITCH_SUBS (bank#)
;
;   CALL_BANK Procedure         ; 57 cycle overhead
;   JUMP_BANK Label             ; 24 cycle overhead
;
; -----------------------------------------------------------------------------

BS_SIZEOF = 35  ; bytes

; -----------------------------------------------------------------------------
; Desc:     Call a procedure in another bank.
; Params:   procedure to call
; Outputs:
; -----------------------------------------------------------------------------
    MAC CALL_BANK
.PROC       SET {1}
.DEST_BANK  SET (((.PROC & $f000) - BANK0_RORG) >> 13)
.CALL_SUB   SET (Bank0_CallBank & $0fff) | (. & $f000)

        ldx #.DEST_BANK         ; 2 (2)
        lda #<.PROC             ; 2 (4)
        ldy #>.PROC             ; 2 (6)
        jsr .CALL_SUB           ; 51 (57)
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Jump to a label in another bank. Subroutine does not return.
; Params:   label to jump to
; Outputs:
; -----------------------------------------------------------------------------
    MAC JUMP_BANK
.LABEL      SET {1}
.DEST_BANK  SET (((.LABEL & $f000) - BANK0_RORG) >> 13)
.JUMP_SUB   SET (Bank0_JumpBank & $0fff) | (. & $f000)

        ldx #.DEST_BANK         ; 2 (2)
        lda #<.LABEL            ; 2 (4)
        ldy #>.LABEL            ; 2 (6)
        jmp .JUMP_SUB           ; 18 (24)
    ENDM

    MAC INCLUDE_BANKSWITCH_SUBS
    ; -------------------------------------------------------------------------
    ; Desc:     Call a procedure in another bank.
    ; Inputs:   X register (destination bank #)
    ;           A register (destination subroutine LSB)
    ;           Y register (destination subroutine MSB)
    ; Outputs:
    ; -------------------------------------------------------------------------
Bank{1}_CallBank SUBROUTINE     ; 6 (6)

    sta TempPtr                 ; 3 (9)     save subroutine
    sty TempPtr+1               ; 3 (12)

    ; save source bank number
    lda #{1}                    ; 2 (14)
    pha                         ; 3 (17)

    lda BANK0_HOTSPOT,x         ; 4 (21)    do the bankswitch

    lda #>(.Return-1)           ; 2 (23)    push the return address
    pha                         ; 3 (26)
    lda #<(.Return-1)           ; 2 (28)
    pha                         ; 3 (31)

    jmp (TempPtr)               ; 5 (36)    do the subroutine call

.Return
    pla                         ; 3 (39)    retrieve source bank number
    tax                         ; 2 (41)
    lda BANK0_HOTSPOT,x         ; 4 (45)    do the return bank switch
    rts                         ; 6 (51)

    ; -------------------------------------------------------------------------
    ; Desc:     Jump to a label in another bank.
    ; Inputs:   X register (destination bank #)
    ;           A register (destination subroutine LSB)
    ;           Y register (destination subroutine MSB)
    ; Outputs:
    ; -------------------------------------------------------------------------
Bank{1}_JumpBank SUBROUTINE     ; 3 (3)
    ; push destination address
    sta TempPtr                 ; 3 (6)     save subroutine
    sty TempPtr+1               ; 3 (9)

    lda BANK0_HOTSPOT,x         ; 4 (13)    do the bankswitch
    jmp (TempPtr)               ; 5 (18)    call the subroutine
    ENDM
