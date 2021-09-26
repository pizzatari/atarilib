; -----------------------------------------------------------------------------
; Desc:     Adds a task to the front of the queue. Items shift down.
; Inputs:   X register (task id)
;           A register (argument)
;           TaskQueue
; Outputs:
; -----------------------------------------------------------------------------
QueueAdd SUBROUTINE
    ldy TaskQueue
    beq .Save
    ; shift right
    ldy TaskQueue
    sty TaskQueue+1
    ldy TaskArg
    sty TaskArg+1
.Save
    stx TaskQueue
    sta TaskArg
    rts

; -----------------------------------------------------------------------------
; Desc:     Replaces a task.
; Inputs:   X register (old task id)
;           Y register (new task id)
;           A register (argument)
; Outputs:  carry register (0 on success; 1 on fail)
; -----------------------------------------------------------------------------
QueueReplace SUBROUTINE
    sec

    ; search for task
    cpx TaskQueue
    bne .Next1

    sty TaskQueue
    sta TaskArg
    rts

.Next1
    cpx TaskQueue+1
    bne .NotFound

    sty TaskQueue+1
    sta TaskArg+1
    rts
     
.NotFound
    rts

; -----------------------------------------------------------------------------
; Desc:     Removes a task.
; Inputs:   X register (task id)
; Outputs:  carry register (0 on success; 1 on fail)
; -----------------------------------------------------------------------------
#if 0
QueueRemove SUBROUTINE
    ldy #0
    jsr QueueReplace
    rts
#endif

; -----------------------------------------------------------------------------
; Desc:     Clears the queue.
; Inputs:   TaskQueue
; Outputs:
; -----------------------------------------------------------------------------
QueueClear SUBROUTINE
    lda #0
    sta TaskArg
    sta TaskArg+1
    sta TaskQueue
    sta TaskQueue+1
    rts

; -----------------------------------------------------------------------------
; Desc:     Removes the trailing task.
; Inputs:   TaskQueue
; Outputs:  X register (task id removed or 0 on empty)
;           A register (task arg removed)
; Notes:
;   0,0 -> 0,0
;   1,0 -> 0,0
;   0,1 -> 0,0
;   1,1 -> 0,1
; -----------------------------------------------------------------------------
#if 0
QueueRemoveTail SUBROUTINE
    ; check if the tail is empty
    ldx TaskQueue+1
    beq .Clear

    ; shift right
    lda TaskArg+1
    ldy TaskArg
    sty TaskArg+1
    ldy TaskQueue
    sty TaskQueue+1
    rts

.Clear
    ldx TaskQueue
    lda TaskArg
    ldy #0
    sty TaskQueue
    sty TaskArg
    rts
#endif

; -----------------------------------------------------------------------------
; Desc:     Get the trailing task, which may be in the high or low byte.
;           TaskQueue is unmodified.
; Inputs:   TaskQueue
; Outputs:  X register (task id or 0 on empty)
;           A register (task arg)
; -----------------------------------------------------------------------------
QueueGetTail SUBROUTINE
    ldx TaskQueue+1
    beq .Next
    lda TaskArg+1
    rts
.Next
    ldx TaskQueue
    lda TaskArg
    rts

