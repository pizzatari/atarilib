; Objects
OBJ_P0          = 0     ; player 0
OBJ_P1          = 1     ; player 1
OBJ_M0          = 2     ; missile 0
OBJ_M1          = 3     ; missile 1
OBJ_BL          = 4     ; ball

; Console switches
SWITCH_DIFF1    = %10000000
SWITCH_DIFF0    = %01000000
SWITCH_BW       = %00001000
SWITCH_SELECT   = %00000010
SWITCH_RESET    = %00000001

; Controllers
JOY_FIRE        = %10000000

JOY1_RIGHT      = %10000000
JOY1_LEFT       = %01000000
JOY1_DOWN       = %00100000
JOY1_UP         = %00010000

JOY1_RIGHT      = JOY0_RIGHT >> 4
JOY1_LEFT       = JOY0_LEFT  >> 4
JOY1_DOWN       = JOY0_DOWN  >> 4
JOY1_UP         = JOY0_UP    >> 4
