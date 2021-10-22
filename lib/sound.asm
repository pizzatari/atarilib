; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     Feb 2019
; Version:  1.0
; Project:  Simple Sound 2600
; Desc:     Simple sound driver for Atari 2600. This plays basic sound clips
;           or short tunes.
; -----------------------------------------------------------------------------

; SoundCtrl
SOUND_LOOPS_MASK        = %11110000
SOUND_CURR_NOTE_MASK    = %00001111
SOUND_LOOPS_POS         = 4

; -----------------------------------------------------------------------------
; Desc:     Stops all sounds and clears the queue.
; Inputs:    
; Ouputs:
; -----------------------------------------------------------------------------
SoundClear SUBROUTINE
    lda #0
    sta AUDC0
    sta AUDC1
    sta AUDV0
    sta AUDV1
    sta AUDF0
    sta AUDF1

    sta SoundQueue
    sta SoundQueue+1
    sta SoundCtrl
    sta SoundCtrl+1
    rts

#if 1
; -----------------------------------------------------------------------------
; Desc:     Play a sound in an empty channel. If there's no empty channel, the
;           trailing channel gets overwritten.
; Inputs:   Arg1 (sound id)
; Ouputs:
; -----------------------------------------------------------------------------
SoundPlay SUBROUTINE            ; 6 (6)
    ldx Arg1                    ; 3 (9)
    beq .Return                 ; 2 (11)    if id == SOUND_ID_NONE

    ; assemble SoundCtrl element: [loops,starting note #]
    lda SoundLoops,x            ; 4 (15)
    ora SoundNumNotes,x         ; 4 (19) 

    ; check trailing channel
    ldy SoundQueue+1            ; 3 (22)
    bne .Next                   ; 3 (25)

.Trailing                       ;        [31]
    sta SoundCtrl+1             ; 3 (27) [34]
    stx SoundQueue+1            ; 3 (30) [37]
    rts                         ; 6 (36) [43]

.Next
    ; check leading channel
    ldy SoundQueue              ; 3 (28)
    bne .Trailing               ; 2 (30)

    sta SoundCtrl               ; 3 (33)
    stx SoundQueue              ; 3 (36)

.Return
    rts                         ; 6 (42)

; -----------------------------------------------------------------------------
; Desc:     Play two sounds (if two are supplied). Existing channels are
;           overwritten.
; Inputs:   Arg1 (sound id)
;           Arg2 (sound id)
; Ouputs:
; -----------------------------------------------------------------------------
SoundPlay2 SUBROUTINE           ; 6 (6)
    ldx Arg2                    ; 3 (9)
    beq .Next                   ; 2 (11)    if id == SOUND_ID_NONE

    ; assemble SoundCtrl element: [loops,starting note #]
    lda SoundLoops,x            ; 4 (15)
    ora SoundNumNotes,x         ; 4 (19) 
    sta SoundCtrl+1             ; 3 (22)
    stx SoundQueue+1            ; 3 (25)

.Next
    ldx Arg1                    ; 3 (28)
    beq .Return                 ; 2 (30)

    ; assemble SoundCtrl element: [loops,starting note #]
    lda SoundLoops,x            ; 4 (34)
    ora SoundNumNotes,x         ; 4 (38) 
    sta SoundCtrl               ; 3 (41)
    stx SoundQueue              ; 3 (44)

.Return
    rts                         ; 6 (50)


#else
SoundPlay SUBROUTINE
    lda Arg1                    ; 3 (3)
    beq .Return                 ; 2 (5)     SOUND_ID_NONE

    tax                         ; 2 (7)     save A
    tay                         ; 2 (9)

    ; initialize pointer to sound data
    lda SoundTableLo,y          ; 4 (13)
    sta TempPtr                 ; 3 (16)
    lda SoundTableHi,y          ; 4 (20)
    sta TempPtr+1               ; 3 (23)     TempPtr = SoundTable[id]

    ; loops must be > 0
    ldy #1                      ; 2 (25)     select first byte
    lda (TempPtr),y             ; 5 (30)
    beq .Return                 ; 2 (32)

    ; search for an empty spot
    txa                         ; 2 (34)     restore A
    ldx #SOUND_QUEUE_LEN-1      ; 2 (36)
.Loop
    ldy SoundQueue,x            ; 4 (4)
    bmi .FoundEmptyChannel      ; 2 (6)
    cmp SoundQueue,x            ; 4 (10)
    beq .FoundEmptyChannel      ; 2 (12)     reuse channel playing the same sound
    dex                         ; 2 (14)
    bpl .Loop                   ; 3 (17)

    ; init; 36 (36)
    ; loop; 33 (69)

    ; queue is full, replace last element
    ldx #SOUND_QUEUE_LEN-1      ; 2 (71)
.FoundEmptyChannel

    ; add id to the queue
    sta SoundQueue,x            ; 4 (75)

    ; initialize current note
    lda #0                      ; 2 (77)
    SET_BITS_X SOUND_CURR_NOTE_MASK, SoundCtrl  ; 26 (103)

    ; initialize loops
    ldy #1                      ; 2 (105)      select second byte
    lda (TempPtr),y             ; 5 (110)
    ;sta SoundLoops,x
    SET_BITS_X SOUND_LOOPS_MASK, SoundCtrl  ; 18 (128)

.Return
    rts                         ; 6 (134)

SoundPlay2 SUBROUTINE
    jsr SoundPlay
    lda Arg2
    sta Arg1
    jsr SoundPlay
    rts
#endif

; -----------------------------------------------------------------------------
; Desc:     Play the next sound sample.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
#if 1
SoundTick SUBROUTINE            ; 6 (6)
    ldx SoundQueue+1            ; 3 (9)
    beq .NextElem               ; 2 (11)

    lda SoundTempo,x            ; 4 (15)
    and FrameCtr                ; 3 (18)
    bne .NextElem               ; 2 (20)    if play tick != 0

    lda SoundCtrl+1             ; 3 (23)    [loops, note #]
    bne .PlayNote1              ; 3 (26)    if [loops, note #] != [0, 0]

    sta SoundQueue+1            ; 3 (28)    end of clip: remove element
    sta AUDV1                   ; 3 (31)
    sta AUDC1                   ; 3 (34)
    sta AUDF1                   ; 3 (37)
    jmp .NextElem               ; 3 (40)

.PlayNote1
    ; test for end of loop
    and #SOUND_CURR_NOTE_MASK   ; 2 (28)
    bne .Continue1              ; 2 (30)    if curr note != 0

    ; beginning of next loop: reload starting note number
    ;   example: when note = -6 & $0f
    ;       0000 1010 num notes
    ;   eor 1111 0000 remaining loops
    ;       1111 1010 ctrl
    lda SoundNumNotes,x         ; 4 (34)
    eor SoundCtrl+1             ; 3 (37)
    sta SoundCtrl+1             ; 3 (40)

.Continue1
    ; get a pointer to the sound data
    lda SoundTableLo,x          ; 5 (45)
    sta TempPtr                 ; 3 (48)
    lda SoundTableHi,x          ; 5 (53)
    sta TempPtr+1               ; 3 (56)

    ; get an index to the next note
    lda SoundCtrl+1             ; 3 (59)
    ora #$f0                    ; 2 (61)
    asl                         ; 2 (63)
    tay                         ; 2 (65)

    lda (TempPtr),y             ; 5 (70)
    sta AUDC1                   ; 3 (73)

    lsr                         ; 2 (75)
    lsr                         ; 2 (77)
    lsr                         ; 2 (79)
    lsr                         ; 2 (81)
    sta AUDV1                   ; 3 (84)

    iny                         ; 2 (86)
    lda (TempPtr),y             ; 5 (91)
    sta AUDF1                   ; 3 (94)

    inc SoundCtrl+1             ; 5 (99)

.NextElem
    ldx SoundQueue              ; 3 (102)
    beq .Return                 ; 2 (104)

    lda SoundTempo,x            ; 4 (108)
    and FrameCtr                ; 3 (111)
    bne .Return                 ; 2 (113)   if play tick != 0

    lda SoundCtrl               ; 3 (116)   [loops, note #]
    bne .PlayNote2              ; 3 (119)   if [loops, note #] != [0, 0]

    sta SoundQueue              ; 3 (121)   end of clip: remove element
    sta AUDV0                   ; 3 (124)
    sta AUDC0                   ; 3 (127)
    sta AUDF0                   ; 3 (130)
    jmp .Return                 ; 3 (133)

.PlayNote2
    ; test for end of loop
    and #SOUND_CURR_NOTE_MASK   ; 2 (121)
    bne .Continue2              ; 2 (123)   if curr note != 0

    ; beginning of next loop: reload starting note number
    lda SoundNumNotes,x         ; 4 (127)
    eor SoundCtrl               ; 3 (130)
    sta SoundCtrl               ; 3 (133)

.Continue2
    ; get a pointer to the sound data
    lda SoundTableLo,x          ; 5 (138)
    sta TempPtr                 ; 3 (141)
    lda SoundTableHi,x          ; 5 (146)
    sta TempPtr+1               ; 3 (149)

    ; get an index to the next note
    lda SoundCtrl               ; 3 (152)
    ora #$f0                    ; 2 (154)
    asl                         ; 2 (156)
    tay                         ; 2 (158)

    lda (TempPtr),y             ; 5 (163)
    sta AUDC0                   ; 3 (166)

    lsr                         ; 2 (168)
    lsr                         ; 2 (170)
    lsr                         ; 2 (172)
    lsr                         ; 2 (174)
    sta AUDV0                   ; 3 (177)

    iny                         ; 2 (179)
    lda (TempPtr),y             ; 5 (184)
    sta AUDF0                   ; 3 (187)

    inc SoundCtrl               ; 5 (192)

.Return
    rts                         ; 6 (198)

#else
SoundTick SUBROUTINE
    ldx #SOUND_QUEUE_LEN-1      ; 2 (2)     X = current queue index
.Loop
    ; check if there's a sound effect in the queue
    lda SoundQueue,x            ; 4 (4)
    beq .Mute                   ; 2 (6)     SOUND_ID_NONE

    tay                         ; 2 (8)

    ; get a pointer to the sound data
    lda SoundTableLo,y          ; 4 (12)
    sta TempPtr                 ; 3 (15)
    lda SoundTableHi,y          ; 4 (19)
    sta TempPtr+1               ; 3 (22)     TempPtr = &SoundTable[id]

    ; 1st byte is the playback tempo
    ldy #0                      ; 2 (24)     Y -> start of sound data
    lda (TempPtr),y             ; 5 (29)
    ; skip if this is not a play tick
    and FrameCtr                ; 3 (32)
    bne .NextNote               ; 2 (34)

    ; seek to next note: 1 + ticks
    ;lda SoundCurrNote,x
    GET_BITS_X SOUND_CURR_NOTE_MASK, SoundCtrl  ; 14 (48)

    asl                         ; 2 (50)     A = A * 2
    tay                         ; 2 (52)
    iny                         ; 2 (54)
    iny                         ; 2 (56)     skip 2 byte header

    ; check for the end of the clip
    lda (TempPtr),y             ; 5 (61)
    beq .EndOfClip              ; 2 (63)

    ; next byte is volume and control
    sta AUDC0,x                 ; 4 (67)     write to channel
    ; get the volume
    lsr                         ; 2 (69)
    lsr                         ; 2 (71)
    lsr                         ; 2 (73)
    lsr                         ; 2 (75)
    sta AUDV0,x                 ; 4 (79)     write to channel

    ; next byte is the audio frequency
    iny                         ; 2 (81)
    lda (TempPtr),y             ; 5 (86)
    sta AUDF0,x                 ; 5 (91)     write to channel
    
    ; advance the current note
    ;inc SoundCurrNote,x
    INC_BITS_X SOUND_CURR_NOTE_MASK, SoundCtrl  ; 12 (103)
    jmp .NextNote               ; 3 (106)

.EndOfClip
    ; rewind
    lda #0
    ;sta SoundCurrNote,x
    SET_BITS_X SOUND_CURR_NOTE_MASK, SoundCtrl
    ; check for remaining loops
    ;dec SoundLoops,x
    DEC_BITS_X SOUND_LOOPS_MASK, SoundCtrl
    lda SoundCtrl,x
    and #SOUND_LOOPS_MASK
    bne .NextNote

.RemoveElement
    ; end of the sound clip: erase the queue entry
    lda #SOUND_ID_NONE
    sta SoundQueue,x

.Mute
    lda #0
    ; mute any current playing notes
    sta AUDV0,x                 
    sta AUDC0,x
    sta AUDF0,x

.NextNote
    dex
    bpl .Loop

    rts
#endif
