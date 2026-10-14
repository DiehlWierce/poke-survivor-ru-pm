# 🎮 Pokémon Survivors v1.0.0 — the first Android release

**Pokémon Survivors** is a free, fan-made, Pokémon-themed *survivor-like* for Android. Pick a starter, survive as long as you can against endless waves of Pokémon, level up, evolve your moves, open rifts to fight legendaries, and face the Judgment of Arceus.

This is a **native Android port** of the web game **PokéSurvivor by JPTER78** — rebuilt from scratch in Godot with the goal of giving you *the same experience as the original*, plus everything a phone needs: touch controls, gamepad support, notch-safe UI, a minimap, a field-of-view slider and 11 languages.

> **No ads. No purchases. No online features. Your progress stays on your device.**

---

## ✨ Highlights

- 🕹️ **Three ways to play:** touch, and gamepad with **three layouts — Xbox, PlayStation and Nintendo**
- 🌍 **11 languages**, every menu, move, item, achievement and Pokémon name translated
- 📱 **Built for phones and tablets:** notch / cut-out safe areas, landscape play, adjustable field of view, minimap
- ⚡ **Over 960 Pokémon** to collect, each with its own permanent upgrades
- 🌀 **Rifts, legendary arenas and the Judgment of Arceus**
- 🏆 **130 achievements, 23 unlockable titles, daily & weekly missions, trainer profile card**

---

## 🕹️ Controls

### Touch (phones & tablets)
- **Floating joystick** — put your thumb anywhere and drag; the stick appears where you touch.
- **Fixed joystick (optional)** — keeps the stick pinned to the bottom-left corner.
- **Joystick size** — Small / Medium / Large.
- Tap a move icon at the bottom to switch to it; tap the pause button in the top-right corner.
- Tap the cards on the level-up screen to pick an upgrade.

### Gamepad — three layouts
Plug in or pair any controller and pick the layout that matches it in **Settings → Controls → Gamepad type**. Button names, icons and hints change with the layout:

| Layout | Confirm | Cancel | Pause |
|---|---|---|---|
| **Xbox** | A | B | Menu |
| **PlayStation** | Cross | Circle | Options |
| **Nintendo** | A (right) | B (bottom) | + |

- **Left stick or D-pad** to move and to navigate every menu.
- **Fully remappable:** tap an action in the list, press the controller button you want, done. One tap resets the mapping.
- Remappable actions: previous move, next move, pause, confirm, cancel, reroll cards, ban a card.
- Menus, the level-up cards, the pause screen, the gacha and the settings are all navigable with the pad.
- Hints on screen always show the right button names for the layout you chose.

### Keyboard
Also supported (1–4 to choose moves, 1–3 on the level-up cards, R to reroll, B to ban).

---

## 📱 Android-specific features (not in the web original)

- **Field-of-view slider** — zoom the camera in or out to taste (great for small phones).
- **Minimap** — circular radar showing the map, nearby Pokémon, rifts and pickups, with a north marker.
- **Notch / camera cut-out support** — the HUD, buttons and cards respect safe areas on every side.
- **Screen-size option** in settings, and landscape-locked play.
- **Quality setting** — Auto / High / Medium / Low for effects and particles (Auto lowers them by itself if the game starts to stutter).
- **FPS counter** (optional).
- **Reduce screen shake & flashes**, **damage numbers on/off**, **vibration on/off**, volume sliders and a one-tap **mute**.
- **Local save + backup code** — copy a save code and paste it on another device to move your progress (there is no online account in this port).
- Smooth **back-button** handling and gamepad-friendly focus in every menu.

---

## 🌍 Languages (11)

English · Español (España) · Español (Latinoamérica) · Français · Italiano · Português (Brasil) · Português (Portugal) · Русский · 日本語 · 中文（普通话）· 廣東話（粵語）

- **Everything** is translated: menus, settings, tutorials, level-up cards, moves and their descriptions, items, weather, missions, achievements, titles, gacha, toasts and in-game banners.
- **Pokémon, move, type and item names use the official names** in French, Italian, Japanese, Mandarin and Cantonese (Cantonese uses the official Traditional-Chinese names).
- Fonts: the original pixel font for Latin and Cyrillic text, with Noto Sans CJK for Japanese and Chinese.
- Change it any time in **Settings → Graphics → Language**.

---

## ⚔️ Gameplay (faithful to the original)

- **Starter test:** answer a few questions, Mystery-Dungeon style, and get your personality-matched partner — or choose any starter yourself.
- **Survive & level up:** pick one of three upgrade cards each level — new moves, move upgrades, passives. **Reroll** or **ban** cards (upgradable).
- **Move evolutions:** every move can evolve into its stronger form.
- **Bond:** link several moves so they fire together (up to 4 at once).
- **Held items:** Leftovers, Choice Band/Scarf, Life Orb, Focus Sash, Shell Bell, Amulet Coin, Lucky Egg, Quick Claw, Rocky Helmet, Assault Vest — find a new one and choose whether to **swap or keep the one you have**.
- **Weather:** sun, rain, sandstorm, snow and fog change how each type performs.
- **Altars, chests and traps** across a procedurally varied world.
- **Rifts:** from about 1:15 into the run a rift can open every 30 seconds; step in to fight a legendary in a type-themed arena (18 arenas, one per type). Dying inside a rift only throws you out of the rift — **your run continues**.
- **The Judgment of Arceus** at minute 30 — an invincible Arceus hunts you while legendary guests drop in.
- **Bosses, shinies, "thief" Pokémon carrying tickets and coins, and frenzied enemies.**

### Meta progression
- **Gacha** with ×1 and ×10 tickets, rarity tiers, shiny chance and at least one *Very Rare* Pokémon guaranteed on every ×10 pull; duplicates convert to coins.
- **Permanent upgrades per Pokémon** (Vitality, Strength, Stride, Reflexes, Shell, Synthesis, Magnet, Wisdom, Fortune, Repertoire, Crit, Reroll, Ban).
- **Daily and weekly missions** (reset at 00:00 Puerto Rico time; you may swap one daily mission per day).
- **130 achievements** across Collection, Survival, Combat, Rifts, Legendaries and Missions, plus **23 titles**.
- **Trainer profile:** name, favourite 3 Pokémon, equipped title, a trainer card, and a Records tab with your best runs.
- **Pokédex** for all regions, with shiny toggle.

---

## 🔧 Changes & balance in this release

### Melee moves buffed
Melee moves were the weakest way to play, because you have to stand next to what you fight. All nine melee moves now deal more damage, reach slightly farther and grant a short burst of invincibility every time they swing (always less than the move's cooldown, so you are never permanently invulnerable):

| Move | Damage | Range | Invincibility per swing |
|---|---|---|---|
| Tackle | 16 → **21** | 60 → **68** | 0.35 s → **0.40 s** |
| Vine Whip | 19 → **25** | 85 → **90** | — → **0.22 s** |
| Wing Attack | 17 → **22** | 73 → **78** | — → **0.24 s** |
| Body Slam | 36 → **42** | 58 → **66** | — → **0.30 s** |
| Bug Bite | 13 → **17** | 55 → **62** | — → **0.18 s** |
| Karate Chop | 22 → **28** | 63 → **70** | — → **0.22 s** |
| Lick | 14 → **18** | 60 → **66** | — → **0.20 s** |
| Metal Claw | 18 → **24** | 63 → **70** | — → **0.22 s** |
| Bite | 17 → **22** | 58 → **64** | — → **0.20 s** |

Melee users still take 25 % less damage from enemies, as in the original. Evolved melee moves inherit the new numbers.

### Late-run readability
- Enemy **shields** last 7 s, can't be re-applied for 14 s and are capped, so crowds don't turn into unkillable walls.
- **Summoners** spawn 4 minions per cast, with a per-summoner and a global minion cap.
- **Healing stacking** is dampened when many healers are on screen.

### Fixes & polish
- Gamepad focus and back-button handling fixed across all menus.
- Pixel-font glyph fixes, new app icon, safe-area handling on all screens.
- Rift/arena loading fixed.
- Hundreds of text strings reviewed so nothing is left in the wrong language.

---

## 📦 Install

1. Download **`Poke-Survivors.apk`** from the assets below.
2. Open it on your Android device and allow *"Install from this source"* if asked.
3. Launch **Pokémon Survivors** and take the starter test.

Play in **landscape**. A controller is optional but fully supported.

---

## ⚠️ Known limitations

- **Offline only** — the original's online/group features and PC-account linking are not part of this port. Use the backup code to move your save.
- Cantonese uses the official **Traditional-Chinese (Taiwan) Pokémon names**; Russian and Portuguese move names are community-style translations, not official ones.
- Tested on a limited set of devices and controllers — if something looks off on yours, please open an issue with your device model and Android version.

---

## 🙏 Credits

- **Original game — PokéSurvivor by [JPTER78](https://github.com/JPTER78/pokesurvivor).** All game design, systems, balance and content come from his work; this port exists because of it. Go play and support the original: <https://github.com/JPTER78/pokesurvivor> · Wiki: <https://pokesurvivor.wiki>
- **Android port — JayElDragon.**
- **Sprites** — [PMD SpriteCollab](https://github.com/PMDCollab/SpriteCollab) and its many artists (CC BY-NC 4.0).
- **Pokémon, move, item and type data & official names** — [PokéAPI](https://pokeapi.co).
- **Fonts** — Pixelify Sans and Noto Sans CJK (both SIL Open Font License).
- Made with the **Godot Engine**.

*Pokémon and its characters are trademarks of Nintendo, Creatures Inc. and GAME FREAK inc. This is a free, non-profit fan project with no affiliation to them.*
