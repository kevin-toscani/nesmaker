
# Crossfade

Crossfade is a NESMaker 4.5.x script that allows you to fade the background and/or sprites to any (sub)palette you wish.

## Implementation
1. Pull this repository into a location of choice, and then copy the `Crossfade` folder into the the `GameEngineData\Routines` folder of your NESMaker location.
2. Add a variable named `crossfadeTimer` to Overflow Ram (or ZP Ram if Overflow Ram is full).
3. Add the following line to the "Bank16" script your game is using:
```nasm
.include "Routines\Crossfade\Bank16.asm"
```
4. Add the following line to the "Handle Game Timers" script your game is using:
```nasm
.include "Routines\Crossfade\handleGameTimer.asm"
```
If you're not using an "handle game timer" script yet (i.e. it has `blank.asm` assigned in the script settings), you can also assign the `Routines\Crossfade\handleGameTimer.asm` to the Handle Game Timer script in your script settings.

## Test
If you want to quickly test the crossfade script, you can add `input_testCrossfade.asm` to your input scripts, and assign it to an input of choice (for example, Press Select on Main Game). This test script toggles the background palette between 0 and 1, and all sprite palettes between 0 and 3.

## Usage
To crossfade the background to the desired palette, insert the following code to where you want the fade to be initialized.
```nasm
    ;; Preload the ID of the palette you want to fade to.
    ;; Replace the #$01 with the palette ID of your choice.
    LDA #$01
    STA newPal

    ;; You can preload sprite subpalettes in a similar fashion:
    LDA #$A1
    STA spriteSubPal1
    LDA #$A2
    STA spriteSubPal2
    LDA #$A3
    STA spriteSubPal3
    LDA #$A4
    STA spriteSubPal4

    ;; Set the crossfade timer
    LDA #CROSSFADE_TIMER_DEFAULT
    STA crossFadeTimer
```

## Example

See some example footage here:

[![NESMaker crossfade test @ YouTube](https://img.youtube.com/vi/aUsmXhgVbo4/0.jpg)](https://www.youtube.com/watch?v=aUsmXhgVbo4)

## Customizations

### Fade speed
You can change the fade speed by changing two values in the script.
- Change`handleGameTimer.asm` line #5 to:
-- `AND #CROSSFADE_SPEED_SUPERFAST` = superfast fade
-- `AND #CROSSFADE_SPEED_FAST` = fast fade
-- `AND #CROSSFADE_SPEED_DEFAULT` = medium fade (default)
-- `AND #CROSSFADE_SPEED_SLOW` = slow fade
- Accordingly, change the value you store into `crossFadeTimer` (see `index_testCrossFade.asm` line #6 for an example):
-- `LDA #CROSSFADE_TIMER_SUPERFAST` = superfast fade
-- `LDA #CROSSFADE_TIMER_FAST` = fast fade
-- `LDA #CROSSFADE_TIMER_DEFAULT` = medium fade (default)
-- `LDA #CROSSFADE_TIMER_SLOW` = slow fade

## Questions
If anything is unclear, drop me a line at kevin81@nerdboard.nl or on one of my [socials](https://kevinvanderburg.nl).
