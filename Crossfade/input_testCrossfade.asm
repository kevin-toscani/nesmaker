
    ;; Cycle through the first four palettes
    INC paletteDestination
    LDA paletteDestination
    AND #%00000011
    STA paletteDestination

    ;; Initialize crossfading by setting the timer
    LDA #CROSSFADE_TIMER_DEFAULT
    STA crossFadeTimer

    ;; Return
    RTS
