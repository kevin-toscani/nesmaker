
# Crossfade

Crossfade is a NESMaker 4.5.x script that allows you to fade the background to any[^1] palette you wish.

## Implementation

1. Pull this repository into the `GameEngineData\Routines` folder of your NESMaker location. Alternatively, you can also download the ZIP file and only copy the `Crossfade` folder into place.
2. Add two variables to Overflow Ram (or ZP Ram if Overflow Ram is full) in your project settings: `crossfadeTimer` and `paletteDestination`.
3. Add the following line to the "Bank16" script your game is using:
```nasm
.include "Routines\Crossfade\Bank16.asm"
```
4. Add the following line to the "Extra Game Timers" script your game is using:
```nasm
.include "Routines\Crossfade\handleGameTimer.asm"
```
5. Optionally, you can copy the file `Macro_CrossfadeToPalette.asm` into the `GameEngineData\Routines\BASE_4_5\System\Macros` folder of your NESMaker location. This is not required though.

## Test
If you want to quickly test the crossfade script, you can add `input_testCrossfade.asm` to your input scripts, and assign it to an input of choice (for example, Press Select on Main Game). This test script cycles the background palette through the first four background palettes of your project.

## Usage

To crossfade the background to the desired palette, insert the following code to where you want the fade to be initialized.
```nasm
    ;; Preload the ID of the palette you want to fade to.
    ;; Replace the #1 with the palette ID of your choice.
    LDA #1
    STA paletteDestination

    ;; Set the crossfade timer
    LDA #CROSSFADE_TIMER_DEFAULT
    STA crossFadeTimer
```

The provided macro does this as well. Call as follows:
```nasm
    CrossfadeToPalette #1 ; change #1 to the desired palette ID
```

## Example

See some example footage here:

[![NESMaker crossfade test @ YouTube](https://img.youtube.com/vi/aUsmXhgVbo4/0.jpg)](https://www.youtube.com/watch?v=aUsmXhgVbo4)

## Customizations

### Fade speed
You can change the fade speed by changing two values in the script.
- Change`handleGameTimer.asm` line #5 to:
  - `AND #CROSSFADE_SPEED_SUPERFAST` = superfast fade
  - `AND #CROSSFADE_SPEED_FAST` = fast fade
  - `AND #CROSSFADE_SPEED_DEFAULT` = medium fade (default)
  - `AND #CROSSFADE_SPEED_SLOW` = slow fade
- Accordingly, change the value you store into `crossFadeTimer` (see `input_testCrossFade.asm` line #6 for an example, or change the provided macro if you're using that):
  - `LDA #CROSSFADE_TIMER_SUPERFAST` = superfast fade
  - `LDA #CROSSFADE_TIMER_FAST` = fast fade
  - `LDA #CROSSFADE_TIMER_DEFAULT` = medium fade (default)
  - `LDA #CROSSFADE_TIMER_SLOW` = slow fade

## Questions
If anything is unclear, drop me a line at kevin81@nerdboard.nl or on one of my [socials](https://kevinvanderburg.nl).

[^1]: Caveat: this script only fades to untriggered day-time background palettes.
