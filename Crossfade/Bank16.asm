
;;
;; Helper constant declarations
;;

CROSSFADE_SPEED_SUPERFAST = %0001
CROSSFADE_SPEED_FAST      = %0011
CROSSFADE_SPEED_DEFAULT   = %0111
CROSSFADE_SPEED_SLOW      = %1111
CROSSFADE_TIMER_SUPERFAST = %00010001
CROSSFADE_TIMER_FAST      = %00100001
CROSSFADE_TIMER_DEFAULT   = %01000001
CROSSFADE_TIMER_SLOW      = %10000001


doCrossFadeSprites16:
    LDX #$00
    -loadSubpalettesLoop:
        ;; Load desired subpalette
        LDY spriteSubPal1,x
        LDA ObjectPaletteDataLo,y
        STA temp16
        LDA ObjectPaletteDataHi,y
        STA temp16+1

        ;; Multiply x-register by 4 to get the subpalette offset
        TXA
        PHA
        ASL
        ASL
        TAX

        ;; Loop through the colors
        LDY #$00
        -fadeColorLoop:
            LDA sprPal,x
            STA tempA
            LDA (temp16),y
            STA tempB

            ;; Update sprite color
            TXA
            PHA
            TYA
            PHA
            JSR doFadeColorArbitrarily
            PLA
            TAY
            PLA
            TAX
            
            LDA tempA
            STA sprPal,x

            ;; Next color
            INX
            INY
            CPY #4
        BNE -fadeColorLoop

        ;; Next subpalette
        PLA
        TAX
        INX
        CPX #$04
    BNE -loadSubpalettesLoop

    ;; Tell NMI to update sprite colors in the PPU
    LDA updateScreenData
    ORA #%00000010
    STA updateScreenData

    RTS


;;
;; Subroutine: doCrossFade16
;; Loads the desired palette and "moves" all current palette colors
;; one step towards the new colors.
;;
;; Uses doFadeColorArbitrarily
;; Clobbers X, Y, tempA, tempB, temp16
;;


doCrossFade16:
    ;; Load the desired destination palette address
    LDY newPal
    LDA GameBckPalLo,y
    STA temp16
    LDA GameBckPalHi,y
    STA temp16+1

    ;; Loop through the colors
    LDY #$0F
    -fadeColorLoop:
    
        ;; Store colors in temporary variables
        LDA bckPal,y
        STA tempA
        LDA (temp16),y
        STA tempB
        
        ;; Update background color
        TYA
        PHA
        JSR doFadeColorArbitrarily
        PLA
        TAY
        
        ;; Store new color in palette
        LDA tempA
        STA bckPal,y
        
        ;; Next color
        DEY
    BPL -fadeColorLoop

    ;; Tell NMI to update background colors in the PPU
    LDA updateScreenData
    ORA #%00000001
    STA updateScreenData

    ;; We're done
    RTS


;;
;; Subroutine: doFadeColorArbitrarily
;; Move one color from the current palette one step into the desired
;; color from the new palete.
;;
;; Clobbers X, Y, temp, temp1, tempA,
;;

doFadeColorArbitrarily:
    LDX tempA
    CPX tempB
    BNE +
        RTS
    +

    LDY tempB
    LDA tblColorExceptionIndex,x
    BEQ +defaultToWhat

    +exceptionToWhat:
        LDA tblColorExceptionIndex,y
        BNE +exceptionToException
        JMP +exceptionToDefault

    +defaultToWhat:
        LDA tblColorExceptionIndex,y
        BNE +defaultToException

    +defaultToDefault:
        +hue:
            ;; Check if hue moves up or down
            TXA
            AND #$0F
            STA temp
            TYA
            AND #$0F
            CMP temp
            BEQ +saturation
            BCC +hueMaybeDown
        
        +hueMaybeUp:
            SEC
            SBC temp
            CMP #7
            BCC +hueUp
            JMP +hueDown

        +hueMaybeDown:
            STA temp1
            LDA temp
            SEC
            SBC temp1
            CMP #7
            BCC +hueDown

        +hueUp:
            INX
            CPX #13
            BNE +
                TXA
                AND #$F0
                ORA #$01
                TAX
            +
            STX tempA
            JMP +saturation
            
        +hueDown:
            DEX
            BNE +
                TXA
                AND #$F0
                ORA #$0D
                TAX
            +
            STX tempA
            
        +saturation:
            ;; Check if saturation moves up or down
            TXA
            AND #$F0
            STA temp
            TYA
            AND #$F0
            CMP temp
            BEQ +nextColor
            BCC +saturationDown
            
        +saturationUp:
            TXA
            CLC
            ADC #$10
            STA tempA
            RTS

        +saturationDown:
            TXA
            SEC
            SBC #$10
            STA tempA
            RTS

    +exceptionToException:
        STY temp
        CPX temp
        BEQ +noChange
            BCC +lighter
                +darker
                DEX
                DEX
            +lighter
            INX
        +noChange:
        LDA tblGrayscale,x
        STA tempA
        RTS

    +defaultToException:
        LDA tblColorExceptionIndex,y
        ASL
        ASL
        ASL
        ASL
        SEC
        SBC #$10
        STA temp
        
        LDA tempA
        AND #$F0
        CMP temp
        BEQ +setAasB
        BCS +darkenA
        
        +lightenA:
            LDA tempA
            CLC
            ADC #$10
            STA tempA
            RTS
        
        +darkenA:
            LDA tempA
            SEC
            SBC #$10
            STA tempA
            RTS

        +setAasB:
            LDA tempB
            STA tempA
            RTS

    +exceptionToDefault:
        LDA tempB
        AND #$0F
        ORA tblExceptionCorrection,x
        STA tempA

    +nextColor:
        RTS


;;
;; Helper tables to handle exception (grayscale) colors
;;

tblColorExceptionIndex:
    .db 2,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1
    .db 3,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1
    .db 4,0,0,0,0,0,0,0,0,0,0,0,0,2,1,1
    .db 4,0,0,0,0,0,0,0,0,0,0,0,0,3,1,1

tblGrayscale:
    .db $0F, $0F, $00, $10, $20, $20

tblExceptionCorrection:
    .db $00, $00, $00, $10, $20

