## Notes

Pokémon Survivors is a free, non-commercial fan game. Original game design and content: JPTER78
([PokéSurvivor](https://github.com/JPTER78/pokesurvivor)). Android port: JayElDragon
([poke-survivor](https://github.com/JayElDragon/poke-survivor)). PortMaster build: DiehlWierce.

The game is exported for Linux arm64 with the stock Godot 4.7.2 template and runs through the
PortMaster Weston wrapper (`weston_pkg_0.2`) with OpenGL ES (the Compatibility renderer).
The game reads the gamepad itself; the update check (it downloads an Android APK) is off here.
The game language is chosen in the in-game settings; Russian is included.

Saves and settings live in `pokesurvivors/conf/`. The log is `pokesurvivors/log.txt`.

This build has not been tested on real hardware by the upstream authors. If the buttons feel
wrong, remap them in the game's own settings (Settings > Controls) and pick the Nintendo layout
if A/B are swapped.

## Controls

| Button | Action |
|--|--|
| D-pad / left stick | Move / menu cursor |
| A (or B on Nintendo layout) | Confirm |
| B (or A on Nintendo layout) | Back |
| L1 / R1 | Previous / next move |
| X | Ban a card |
| Y | Reroll cards |
| Start | Pause |
| L3 / R3 / Select | Z-move / swap Pokémon / Dynamax (default mapping) |
| Select + Start | Quit the game |

## Compile

`zsh tools/portmaster/build.sh` in the project (Godot 4.7.2 with the Linux arm64 export templates).
