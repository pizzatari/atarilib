; -----------------------------------------------------------------------------
; Macros and subroutines for calling a procedure in another bank.
;
;   CALL_BANK #, #, #           ; 70 cycle overhead
;   JUMP_BANK #, #, #           ; 30 cycle overhead
;   INCLUDE_BANKSWITCH_SUBS #
; -----------------------------------------------------------------------------

BS_SIZEOF = $2d
BS_VERSION = 2

; -----------------------------------------------------------------------------
; Desc:     Call a procedure in another bank.
; Params:   dest proc index, dest bank num, source bank #
; Outputs:
; Notes:    Wrapper for compatibility.
; -----------------------------------------------------------------------------
    MAC CALL_BANK
.DSTPROC    SET {1}
.DSTBANK    SET {2}
.SRCBANK    SET {3}

        ldx #.DSTPROC           ; 2 (2)
        ldy #.DSTBANK           ; 2 (4)
        lda #.SRCBANK           ; 2 (6)
        jsr Bank{3}_CallBank    ; 6 (12)
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Jump to a label in another bank. Subroutine does not return.
; Params:   dest proc index, dest bank num, source bank #
; Outputs:
; Notes:    Wrapper for compatibility.
; -----------------------------------------------------------------------------
    MAC JUMP_BANK
.DSTPROC    SET {1}
.DSTBANK    SET {2}
.SRCBANK    SET {3}

    ldx #.DSTPROC               ; 2 (2)
    ldy #.DSTBANK               ; 2 (4)
    jmp Bank{3}_JumpBank        ; 3 (7)
    ENDM

    MAC INCLUDE_BANKSWITCH_SUBS
    ; -------------------------------------------------------------------------
    ; Desc:     Call a procedure in another bank.
    ; Params:   source bank #
    ; Inputs:   X register (destination proc idx)
    ;           Y register (destination bank #)
    ;           A register (source bank #)
    ; Outputs:
    ; -------------------------------------------------------------------------
Bank{1}_CallBank SUBROUTINE
    ; map procedure idx to procedure
    pha                         ; 3 (3)     save source bank #
    lda Bank{1}_ProcTableLo,x   ; 4 (7)
    sta TempPtr                 ; 3 (10)
    lda Bank{1}_ProcTableHi,x   ; 4 (14)
    sta TempPtr+1               ; 3 (17)

    ; do the bank switch
    lda BANK0_HOTSPOT,y         ; 4 (21)

    ; do the subroutine call
    lda #>(.Return-1)           ; 2 (23)    push the return address
    pha                         ; 3 (26)
    lda #<(.Return-1)           ; 2 (28)
    pha                         ; 3 (31)
    jmp (TempPtr)               ; 5 (36)

.Return
    pla                         ; 4 (46)    fetch source bank # 
    tay                         ; 2 (48)
    lda BANK0_HOTSPOT,y         ; 4 (52)    do the return bank switch
    rts                         ; 6 (58)

    ; -------------------------------------------------------------------------
    ; Desc:     Jump to a label in another bank.
    ; Params:   source bank #
    ; Inputs:   X register (destination proc idx)
    ;           Y register (destination bank #)
    ; Outputs:
    ; -------------------------------------------------------------------------
Bank{1}_JumpBank SUBROUTINE
    ; map procedure idx to procedure
    lda Bank{1}_ProcTableLo,x   ; 4 (4)
    sta TempPtr                 ; 3 (7)
    lda Bank{1}_ProcTableHi,x   ; 4 (11)
    sta TempPtr+1               ; 3 (14)

    ; do the bank switch
    lda BANK0_HOTSPOT,y         ; 4 (18)
    jmp (TempPtr)               ; 5 (23)

    ENDM
