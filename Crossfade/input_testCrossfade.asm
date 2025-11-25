
    ;; Cycle through the first four palettes
    INC paletteDestination
    LDA paletteDestination
    AND #%00000011
    STA paletteDestination

    ;; Load a new sprite subpalette (e.g. a grayscale one)
    LDA #$04
    STA spriteSubPal1
    STA spriteSubPal2
    STA spriteSubPal3
    STA spriteSubPal4

    ;; Initialize crossfading by setting the timer
    LDA #CROSSFADE_TIMER_DEFAULT
    STA crossFadeTimer

    ;; Return
    RTS
