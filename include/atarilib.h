; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     January 2021
; Desc:     Common definition files used for Blackjack Theta VIII and Battle
;           for Proton Atari 2600 games.
; Notes:    atarilib directory should be placed in the parent directory
;           containing the game project files.
; -----------------------------------------------------------------------------

    include "bankswitch.h"
    include "bits.h"
    include "debug.h"
    include "draw.h"
    include "io.h"
    include "math.h"
    include "position.h"
    include "task.h"
    include "time.h"
    include "util.h"
    include "video.h"

    ; TODO: move these dasm files elsewhere
    include "macro.h"
    include "vcs.h"
