; -----------------------------------------------------------------------------
; Macros and subroutines for calling a procedure in another bank.
;
;   Routines must reside at the same address offset within each bank.
;
;   INCLUDE_BANKSWITCH_SUBS (bank#)
;
;   CALL_BANK Procedure         ; 57 cycle overhead
;   JUMP_BANK Label             ; 24 cycle overhead
;
; -----------------------------------------------------------------------------

BS_SIZEOF = $2d
BS_VERSION = 2

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
        jsr .CALL_SUB           ; 6 (12)
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
        jmp .JUMP_SUB           ; 3 (9)
    ENDM

    MAC INCLUDE_BANKSWITCH_SUBS
    ; -------------------------------------------------------------------------
    ; Desc:     Call a procedure in another bank.
    ; Inputs:   X register (destination bank #)
    ;           A register (destination subroutine LSB)
    ;           Y register (destination subroutine MSB)
    ; Outputs:
    ; -------------------------------------------------------------------------
Bank{1}_CallBank SUBROUTINE 

    sta TempPtr                 ; 3 (3)     save subroutine
    sty TempPtr+1               ; 3 (6)

    ; save source bank number
    lda #{1}                    ; 2 (8)
    pha                         ; 3 (11)

    lda BANK0_HOTSPOT,x         ; 4 (15)    do the bankswitch

    lda #>(.Return-1)           ; 2 (17)    push the return address
    pha                         ; 3 (20)
    lda #<(.Return-1)           ; 2 (22)
    pha                         ; 3 (25)

    jmp (TempPtr)               ; 5 (30)    do the subroutine call

.Return
    pla                         ; 3 (33)    retrieve source bank number
    tax                         ; 2 (35)
    lda BANK0_HOTSPOT,x         ; 4 (39)    do the return bank switch
    rts                         ; 6 (45)

    ; -------------------------------------------------------------------------
    ; Desc:     Jump to a label in another bank.
    ; Inputs:   X register (destination bank #)
    ;           A register (destination subroutine LSB)
    ;           Y register (destination subroutine MSB)
    ; Outputs:
    ; -------------------------------------------------------------------------
Bank{1}_JumpBank SUBROUTINE
    ; push destination address
    sta TempPtr                 ; 3 (3)     save subroutine
    sty TempPtr+1               ; 3 (6)

    lda BANK0_HOTSPOT,x         ; 4 (10)    do the bankswitch
    jmp (TempPtr)               ; 5 (15)    call the subroutine
    ENDM
