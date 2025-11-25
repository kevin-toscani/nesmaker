
    ;; Check if crossfading has been activated
    LDA crossFadeTimer
    BEQ +doneCrossFade

    ;; Check if we're on a crosfade frame
    DEC crossFadeTimer
    AND #CROSSFADE_SPEED_DEFAULT
    BNE +doneCrossFade

    ;; Fade the frame a step towards the new palette
    SwitchBank #$16
    JSR doCrossFade16
    JSR doCrossFadeSprites16
    ReturnBank

    ;; We're done for now
    +doneCrossFade
