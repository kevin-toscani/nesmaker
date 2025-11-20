;; Here's a first stub/draft to implement Zapper functionality in NESmaker
;; games. The basic gist of it, is this:
;;
;;
;; 1) If the trigger was not pulled, go to step 8.
;;
;; 2) Black out the entire screen for the next frame.
;;
;; 3) At the next frame, check if the zapper senses light. If so, the player
;;    probably is cheating (i.e. not pointing at the screen, but rather at a
;;    different light source); go to step 7.
;;
;; 4) Highlight a shootable object on the next frame (i.e. show a white box
;;    or area where the shootable object is positioned).
;;
;; 5) At the next frame, check if the zapper senses light. If so, the object
;;    has been shot; update the object accordingly and go to step 7.
;;
;; 6) If the zapper did not sense light, check the next object (go to step 4).
;;    If all objects have been checked, we're done handling the zapper.
;;
;; 7) Restore the palettes.
;;
;; 8) Continue game handling as usual.
;;
;;
;; NOTE: before you apply this script, please make sure you have at least
;; 17 bytes of RAM reserved for palette backups. To do this, add a variable
;; to your Overflow RAM in the NESmaker UI. Its name should be "palBackup"
;; and its size should be 17 bytes.
;; Also, you need an additional zero page variable "zapped."
;; Finally, you need to set an additional constant for which tile to use to
;; draw a white box on screen. This constant should be named "ZAP_WHITE_TILE"
;; and in this example we're using tile id 126 (#$7E).
;;



;;
;; Step 0: define constants for easier reading/understanding the code.
;;

ZAPPER             = $4017 ; This is the NES address for controller port 2.
ZAP_TRIGGER        = $10   ; Bit-4 is set when the zapper is half-triggered.
ZAP_LIGHT          = $08   ; Bit-3 is set when the zapper senses a light source.
COLOR_BLACK        = $0F   ; $0F is the palette value for black.
COLOR_WHITE        = $30   ; $30 is the palette value for white.
OBJECT_IS_ZAPPABLE = $80   ; Use object flag Bit-7 for zappability.



;;
;; Step 1: check trigger pull
;;

    LDA ZAPPER             ; Read controller port 2
    AND #ZAP_TRIGGER       ; Check the zapper half-trigger bit
    BNE +                  ; If half-triggered, go to step 2
        LDA #$00           ; Reset the "zapped" variable
        STA zapped         ;
        JMP +zap_done      ; If not half-triggered, go to step 8
    +

    LDA zapped             ; Check if the zapper is still in trigger mode from
    BEQ +                  ; the last time. If so, don't "re-trigger" this
        JMP +zap_done      ; code, but rather go to step 8
    +

    INC zapped             ; Set the zapped variable so the script is not being
                           ; re-triggered as long as the zapper is in half-
                           ; trigger state



;;
;; Step 2: Black out the entire screen
;;

    ;; 2a. Hide all objects
    LDA #$00               ; By resetting the sprite RAM pointer, and then
    STA spriteRamPointer   ; cleaning up sprite RAM altogether, the NMI won't
    JSR doCleanUpSpriteRam ; be drawing any sprites (hopefully).

    ;; 2b. Overwrite background palettes
    LDX #$00               ; Setup the x-register to loop through the palettes
    -
        LDA bckPal,x       ; Backup the current background palette color
        STA palBackup,x    ;
        LDA #COLOR_BLACK   ; Set the new palette color to black
        STA bckPal,x       ;
        INX                ; Do this for all colors
        CPX #$10           ; (16 in total)
    BNE -

    LDA sprPal+3           ; Backup the last color of the first sprite palette
    STA palBackup+16       ;
    LDA #COLOR_WHITE       ; Set the new color to white
    STA sprPal+3           ;

    LDA #$03               ; Tell NESmaker to update the background palettes
    STA updateScreenData   ; (ideally, this would also update the sprite
                           ; palettes, but that requires line 137 of NMI.asm
                           ; to be removed)
    JSR doWaitFrame        ; Wait for NMI to update the screen



;;
;; Step 3: Check if zapper senses light
;;

    LDA ZAPPER             ; Read controller port 2
    AND #ZAP_LIGHT         ; Check the zapper light sensor bit
    BNE +                  ; If zapper senses no light, go to step 4
        JMP +zap_restore   ; If zapper senses light, go to step 7
    +



;;
;; Step 4: Highlight a shootable object
;;

    ;; 4a. Loop through objects
    LDX #$00
-zap_objLoop:

    LDA Object_status,x     ; Get the current object's status
    AND #%10000000          ; Check if it is active (i.e. Bit 7 = 1)
    BNE +                   ;
        JMP +zap_next       ; If it is inactive, go to step 6
    +

    ;; 4b. Check if "object x" is zappable
    LDY Object_type,x       ; Get the current object's type id
    LDA MonsterBits,y       ; Check if the current object is zappable
    AND #OBJECT_IS_ZAPPABLE ;
    BNE +                   ;
        JMP +zap_next       ; If it is not zappable, go to step 6
    +

    ;; 4c. Draw white sprite tiles where the object would be
    
    LDA Object_x_hi,x      ; Get the object's x-position on screen
    STA tempA              ; and store it in a temp variable
    LDA Object_y_hi,x      ; Get the object's y-position on screen
    STA tempB              ; and store it in a temp variable

    SwitchBank #$1C        ; Static object data should be read from bank $1C
        LDA ObjectSize,y   ; Get the object's height in tiles
        AND #%00000111     ;
        STA tempC          ; and store it in a temp variable
        STA tempy          ; store it twice; we need to reuse this later
        LDA ObjectSize,y   ; Get the object's width in tiles
        LSR                ;
        LSR                ;
        LSR                ;
        AND #%00000111     ;
        STA tempD          ; and store it in a temp variable
    ReturnBank             ; We're done with bank $1C, so return the last one

    LDY #$00               ; Reset the sprite RAM pointer to make sure no other
                           ; sprites are being drawn during this frame loop.

    -spriteLoop:               ; Set up a loop for drawing sprites
        LDA tempB              ; Write Y-position to scroll RAM
        STA SpriteRam,y        ;
        INY                    ;

        LDA #ZAP_WHITE_TILE    ; Write sprite tile id to scroll RAM
        STA SpriteRam,y        ;
        INY                    ;

        LDA #$00               ; Write attributes to scroll RAM
        STA SpriteRam,y        ;
        INY                    ;

        LDA tempA              ; Write X-position to scroll RAM
        STA SpriteRam,y        ;
        INY                    ;

        DEC tempC              ; Check the next vertical sprite
        BEQ +nextRow           ; If none are left, draw the next column
            LDA tempB          ; Add 8 pixels vertically to draw the next
            CLC                ; sprite
            ADC #$08           ;
            STA tempB          ;
            JMP -spriteLoop    ; Draw the next sprite
        +nextRow:

        DEC tempD              ; Check the next horizontal sprite
        BEQ +doneDrawing       ; If none are left, we're done drawing
            LDA Object_y_hi,x  ; Reset the y-position for the next sprite
            STA tempB          ;
            LDA tempy          ; Also reset the number of sprites per column
            STA tempC          ;
            LDA tempA          ; Add 8 pixels horizontally to draw the next
            CLC                ; column of sprites
            ADC #$08           ;
            STA tempA          ;
            JMP -spriteLoop    ; Draw the next sprite
        +doneDrawing:
    ;; This is the end of the spriteLoop

    STY spriteRamPointer   ; Update the sprite RAM pointer
    JSR doCleanUpSpriteRam ; Clean up any sprites left

    JSR doWaitFrame        ; Wait for NMI to update the screen



;;
;; Step 5: Keep checking this frame until the zapper senses light
;;

    INC waiting            ; Keep checking until zapper hit OR nmi
    -keepChecking:         ;
    
    LDA ZAPPER             ; Read controller port 2
    AND #ZAP_LIGHT         ; Check the zapper light sensor bit
    BEQ +                  ; If zapper senses light, handle zapping
        LDA waiting        ; Keep zapping until NMI has happened
        BNE -keepChecking  ;
        JMP +zap_next      ; Zapper has not sensed light: go to step 6
    +

    LDA #$00               ; Zapper sensed light: reset waiting variable
    STA waiting            ;
    JSR doHandleZap        ; Go to the subroutine that handles a zapper hit

    ;; NOTE: This script assumes that you cannot "kill two birds with one
    ;; stone," so to speak. If it IS possible in your game to hit multiple
    ;; objects with a single shot, you can remove / comment out the following
    ;; line to keep checking objects.
    JMP +zap_restore       ; Skip checking the other objects



;;
;; Step 6: Check the next shootable object
;;

+zap_next:
    INX
    CPX #TOTAL_MAX_OBJECTS
    BEQ +zap_restore
        JMP -zap_objLoop



;;
;; Step 7: Restore the palettes
;;

+zap_restore:
    LDX #$00
    -
        LDA palBackup,x    ; Restore the original background color
        STA bckPal,x       ;
        INX                ; Do this for all colors
        CPX #$10           ; (16 in total)
    BNE -

    LDA palBackup+16       ; Also restore the original not-white sprite color
    STA sprPal+3           ;

    LDA #$03               ; Tell NESmaker to update the background palettes
    STA updateScreenData   ; (ideally, this would also update the sprite
                           ; palettes, but that requires line 137 of NMI.asm
                           ; to be removed).
    JSR doWaitFrame        ; Wait for NMI to update the screen



;;
;; Step 8: Continue game handling as usual
;;

+zap_done:                 ; We're done zapping now