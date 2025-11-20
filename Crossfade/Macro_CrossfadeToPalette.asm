
MACRO CrossfadeToPalette arg0
    LDA arg0
    STA paletteDestination
    LDA #CROSSFADE_TIMER_DEFAULT
    STA crossFadeTimer
ENDM

