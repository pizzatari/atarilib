; -----------------------------------------------------------------------------
; Macros and subroutines for calling a procedure in another bank.
;
; Call and Jump subroutines must be positioned at the same offset within a
; single page for every bank with callable subroutines or labels.
;
; Routines must be RORG'ed beginning at $1000 and follow every odd block.
;   RORG: $1000, $3000, $5000....
;
; Faster version: the calling footprint is larger and the Y register is used.
;   FAST_CALL = 1   ; 0 to disable
;
; Example:
;   INCLUDE_BANKSWITCH_SUBS
;   CALL_BANK Procedure
;   JUMP_BANK Label
; -----------------------------------------------------------------------------

    IFNCONST BS_FAST_CALLS
BS_FAST_CALLS SET 0
    ENDIF

    IF BS_FAST_CALLS == 1
BS_SIZEOF   = 35
    ELSE
BS_SIZEOF   = 49
    ENDIF

; -----------------------------------------------------------------------------
; Desc:     Call a procedure in another bank.
; Params:   procedure to call
; Outputs:
; -----------------------------------------------------------------------------
    MAC CALL_BANK
.PROC       SET {1}
.DEST_BANK  SET {1} / $2000
.CALL_SUB   SET (Bank0_CallBank & $0fff) | (. & $f000)

        ; check for a call within the same bank
        IF (. & $f000) == (.PROC & $f000)
            jsr .PROC
        ELSE
            IF BS_FAST_CALLS == 1
            ldy #.DEST_BANK         ; 2 [2]
            ENDIF

            lda #>.PROC             ; 2 (2) [4]
            ldx #<.PROC             ; 2 (4) [6]
            jsr .CALL_SUB           ; 63 (67) 51 [57]
        ENDIF
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Jump to a label in another bank. Subroutine does not return.
; Params:   label to jump to
; Outputs:
; -----------------------------------------------------------------------------
    MAC JUMP_BANK
.LABEL      SET {1}
.DEST_BANK  SET {1} / $2000
.JUMP_SUB   SET (Bank0_JumpBank & $0fff) | (. & $f000)

        ; check for a jump within the same bank
        IF (. & $f000) == (.LABEL & $f000)
            jmp .LABEL
        ELSE
            IF BS_FAST_CALLS == 1
            ldy #.DEST_BANK         ; 2 [2]
            ENDIF

            lda #>.LABEL            ; 2 (2) [4]
            ldx #<.LABEL            ; 2 (4) [6]
            jmp .JUMP_SUB           ; 34 (38) 18 [24]
        ENDIF
    ENDM

    ; -------------------------------------------------------------------------
    ; Desc:     Defines bankswitching subroutines.
    ; Param:    source bank #
    ; Outputs:
    ; -------------------------------------------------------------------------
    MAC INCLUDE_BANKSWITCH_SUBS

    ; -------------------------------------------------------------------------
    ; Desc:     Call a procedure in another bank.
    ; Inputs:   A register (destination subroutine MSB)
    ;           X register (destination subroutine LSB)
    ;           [Y register (destination bank)]
    ; Outputs:
    ; Example;  lda #>Subroutine
    ;           ldx #<Subroutine
    ;           ;ldy #1
    ;           jsr Bank0_CallBank
    ; -------------------------------------------------------------------------
Bank,CURR_BANK,"_CallBank" SUBROUTINE; 6 (6) [6]
.HOTSPOT = (. & $f000) + (CURR_BANK * $2000) + HOTSPOT_OFFSET

    stx TempPtr                 ; 3 (9) [9]    save subroutine
    sta TempPtr+1               ; 3 (12) [12]

    IF BS_FAST_CALLS == 1
        ; save source bank number
        lda #CURR_BANK          ; 2 [14]
        pha                     ; 3 [17]

        lda .HOTSPOT,y          ; 4 [21]
    ELSE
        ; destination bank number
        and #$70                ; 2 (14)
        asl                     ; 2 (16)
        rol                     ; 2 (18)
        rol                     ; 2 (20)
        rol                     ; 2 (22)
        tax                     ; 2 (24)

        ; save source bank number
        lda #CURR_BANK          ; 2 (26)
        pha                     ; 3 (29)

        lda .HOTSPOT,x          ; 4 (33)
    ENDIF

    lda #>(.Return-1)           ; 2 (35) [23]    push the return address
    pha                         ; 3 (38) [26]
    lda #<(.Return-1)           ; 2 (40) [28]
    pha                         ; 3 (43) [31]

    jmp (TempPtr)               ; 5 (48) [36]    do the subroutine call

.Return
    pla                         ; 3 (51) [39]    retrieve source bank number
    tax                         ; 2 (53) [41]
    lda .HOTSPOT,x              ; 4 (57) [45]    do the return bank switch
    rts                         ; 6 (63) [51]

    ; -------------------------------------------------------------------------
    ; Desc:     Jump to a label in another bank.
    ; Inputs:   A register (destination subroutine MSB)
    ;           X register (destination subroutine LSB)
    ;           [Y register (destination bank)]
    ; Outputs:
    ; Example;  lda #>Label
    ;           ldx #<Label
    ;           ;ldy #1
    ;           jmp Bank0_JumpBank
    ; -------------------------------------------------------------------------
Bank,CURR_BANK,"_JumpBank" SUBROUTINE; 3 (3) [3]
.HOTSPOT = (. & $f000) + (CURR_BANK * $2000) + HOTSPOT_OFFSET

    ; push destination address
    stx TempPtr                 ; 3 (6) [6]     save subroutine
    sta TempPtr+1               ; 3 (9) [9]

    IF BS_FAST_CALLS == 1
        lda .HOTSPOT,y          ; 4 [13]        do the bankswitch
    ELSE
        ; destination bank number
        and #$70                ; 2 (11)
        asl                     ; 2 (13)
        rol                     ; 2 (15)
        rol                     ; 2 (17)
        rol                     ; 2 (19)
        tax                     ; 2 (21)
        lda .HOTSPOT,x          ; 4 (25)        do the bankswitch
    ENDIF

    jmp (TempPtr)               ; 5 (30) [18]   call the subroutine

    ENDM
