## Notes

Pokémon Survivors is a free, non-commercial fan game and a heavily reworked project by DiehlWierce
(PortMaster build, localisation, new content). It is based on PokéSurvivor by JPTER78
([pokesurvivor](https://github.com/JPTER78/pokesurvivor)) and its Godot/Android port by JayElDragon
([poke-survivor](https://github.com/JayElDragon/poke-survivor)).

The game is exported for Linux arm64 with the stock Godot 4.7.2 template and runs through the
PortMaster Weston wrapper (`weston_pkg_0.2`) with OpenGL ES (the Compatibility renderer).
Buttons are translated to keys by gptokeyb and the game's native joystick input is off; the update check (it downloads an Android APK) is off here.
The game language is chosen in the in-game settings; Russian is included.

Saves and settings live in `pokesurvivors/conf/`. The log is `pokesurvivors/log.txt`; frame-time stats and hitches are in `pokesurvivors/perf_log.txt`.

Tips for smoother play:
- The game is locked to 30 fps on handhelds (steadier than 40-55 fps with dips). To change it, create `pokesurvivors/maxfps.txt` containing e.g. `60`.
- On muOS the CPU can stay at a low clock after waking from sleep (some users see lag in all ports until a full reboot). If a port lags, reboot once or set the CPU governor to performance in muOS settings.
- Pick Settings > Effects > Low in the game.

Handheld tweaks: fewer enemies on screen (44), lighter effects, 30 fps cap, minimap fog updated in slices. For the lightest picture pick Settings > Effects > Low.

This build has not been tested on real hardware by the upstream authors. If the buttons feel
wrong, edit `pokesurvivors.gptk`.

## Controls

The pad is translated to keyboard keys by gptokeyb (`pokesurvivors.gptk`); the game's own joystick
input is switched off in this build (it fired twice per press on muOS). Names below are the
RG34XX-SP labels (Nintendo layout); swap `a` and `b` in the .gptk file if yours differ.

| Button | Action |
|--|--|
| D-pad / left stick | Move / menu cursor |
| B (bottom) | Confirm / pick a card |
| A (right) | Back / pause |
| Y (left) | Reroll cards |
| X (top) | Ban a card |
| L1 / R1 | Previous / next move, previous / next card |
| L2 / R2 | Z-move / Dynamax |
| Select | Swap Pokémon (team mode) |
| Start | Pause |
| Select + Start | Quit the game |

## Compile

`zsh tools/portmaster/build.sh` in the project (Godot 4.7.2 with the Linux arm64 export templates).

## По-русски

Бесплатная фанатская игра в духе Vampire Survivors (оригинал — JPTER78, порт на Android — JayElDragon, сборка для PortMaster — DiehlWierce). Кнопки превращаются в клавиши через gptokeyb (раскладка в `pokesurvivors.gptk`), выход — Select+Start. Русский язык включается в настройках игры. Сохранения лежат в `pokesurvivors/conf/`, лог — `pokesurvivors/log.txt`, замеры кадров и рывки — `pokesurvivors/perf_log.txt`. На реальном железе порт пока не проверен; если подтверждение и отмена перепутаны, поменяй местами `a` и `b` в `pokesurvivors.gptk`.
