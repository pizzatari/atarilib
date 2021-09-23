; -----------------------------------------------------------------------------
; Desc:     Generates a multiplication table.
; Params:   bank #, factor, length of table
; Outputs:
; -----------------------------------------------------------------------------
    MAC INCLUDE_MULTIPLY_TABLE
.factor SET {2}
.length SET {3}
.cnt SET 0

Bank{1}_Mult{2}
    LIST OFF

    REPEAT .length
        dc.b .factor * .cnt
.cnt SET .cnt + 1
    REPEND

    LIST ON

    ENDM

; -----------------------------------------------------------------------------
; Desc:     Generates a power table.
; Params:   bank #, factor, length of table
; Outputs:
; -----------------------------------------------------------------------------
    MAC INCLUDE_POWER_TABLE 
.factor SET {2}
.length SET {3}
.sum SET .factor

Bank{1}_Pow{2}
    dc.b 1

    LIST OFF

    REPEAT .length-1
        dc.b .sum
.sum SET .sum * .factor
    REPEND

    LIST ON

    ENDM

