
MACRO CrossfadeToPalette _palette
    LDA _palette
    STA paletteDestination
    LDA #CROSSFADE_TIMER_DEFAULT
    STA crossFadeTimer
ENDM

