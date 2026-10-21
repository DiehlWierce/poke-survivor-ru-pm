# Карта переноса V5.1 → port/v5 (этап 0)

Трёхсторонний индекс символов верхнего уровня (база V4 `4f964fee`, эталон V5.1 `docs/upstream_v51`, наше `portmaster` 3.1.2). Генератор: `python3 tools/v5_index.py <scratchpad>` (нужен `<scratchpad>/v4src` из `git archive 4f964fee scripts`). Сводка по символам: чистая дельта = V5≠V4, наш==V4; конфликт = V5≠V4 и наш≠V4; новые = только в V5.

## Файлы, которых нет ни в V4, ни у нас (26) — переносятся целиком, оценка стоимости на A53 до включения

| Файл | Строк V5.1 | Символов | Этап |
|---|---|---|---|
| ach.gd |      108 | 15 | 1 |
| alpha.gd |      322 | 38 | 3 |
| cave.gd |      325 | 43 | 3 |
| cave_int.gd |      334 | 40 | 3 |
| challenges.gd |      323 | 34 | 1 |
| challenges_data.gd |      106 | 2 | 1 |
| daynight.gd |       90 | 18 | 3 |
| evo_abil.gd |      716 | 59 | 1 |
| evo_fx.gd |      354 | 27 | 2 |
| fusion_fx.gd |     1522 | 65 | 2 |
| fusions.gd |       65 | 3 | 1 |
| gachapon.gd |      615 | 14 | 4/6 |
| gachapon_data.gd |       63 | 3 | 1 |
| hazard.gd |      143 | 18 | 3 |
| invasion.gd |      232 | 30 | 3 |
| kec_spr.gd |        4 | 2 | 1 |
| kecleon.gd |      811 | 99 | 4/6 |
| lab_int.gd |      262 | 33 | 3 |
| meteor.gd |      562 | 64 | 3 |
| mewtwo.gd |      633 | 62 | 3 |
| poi.gd |      540 | 47 | 3 |
| rescue.gd |      268 | 31 | 3 |
| secret.gd |      278 | 26 | 3 |
| textscale.gd |       49 | 10 | 1 |
| touch_scroll.gd |       70 | 9 | 1 |
| vfx2.gd |      413 | 6 | 2 |

## Файлы, существующие в V4 и изменённые V5.1

| Файл | чистая дельта | КОНФЛИКТ | новые | убрано в V5 |
|---|---|---|---|---|
| abilities.gd | 2 | 0 | 0 | 0 |
| arena.gd | 0 | 1 | 0 | 0 |
| display.gd | 1 | 0 | 1 | 0 |
| dynamax.gd | 3 | 0 | 0 | 0 |
| icons.gd | 4 | 0 | 4 | 0 |
| judgment.gd | 5 | 0 | 5 | 0 |
| lang.gd | 1 | 0 | 0 | 0 |
| main.gd | 54 | 41 | 187 | 0 |
| main_e14.gd | 7 | 0 | 0 | 0 |
| main_e15.gd | 7 | 0 | 0 | 0 |
| main_e16.gd | 7 | 0 | 0 | 0 |
| menu.gd | 10 | 36 | 141 | 5 |
| menu_e14.gd | 9 | 0 | 0 | 0 |
| menu_e15.gd | 9 | 0 | 0 | 0 |
| moves_data.gd | 5 | 0 | 0 | 0 |
| pad.gd | 0 | 0 | 10 | 0 |
| patchnotes.gd | 1 | 1 | 0 | 0 |
| pause_ui.gd | 0 | 3 | 19 | 0 |
| pfx.gd | 0 | 1 | 0 | 0 |
| progress.gd | 6 | 0 | 1 | 0 |
| pxfont.gd | 1 | 0 | 0 | 0 |
| save_data.gd | 7 | 3 | 3 | 0 |
| slots.gd | 2 | 0 | 0 | 0 |
| tileworld.gd | 0 | 1 | 0 | 0 |
| types_data.gd | 1 | 0 | 0 | 0 |
| updater.gd | 0 | 2 | 0 | 0 |
| vfx.gd | 4 | 1 | 1 | 0 |
| zmove.gd | 1 | 0 | 0 | 0 |

Списки символов по файлам: `python3` из `/private/tmp/claude-501/-Users-andrew-vscode-projects-poke-survivor/f187a135-ac08-449f-823f-f37b30b2ddaa/scratchpad/detail.json` (пересоздаётся скриптом). Порядок: данные/мелкие → слияния → мир → меню → исправления → дельта 5.1; `main.gd` (54/41/187) и `menu.gd` (10/36/141) — функция за функцией.

## Блокеры
- `docs/v5_compare_report.md` отсутствует (сессия-анализ не закончила). Карта выше посчитана скриптом независимо.
- Недельный лимит на старте: 84 %, потолок 98 % → хватает на этап 0 и, возможно, малую часть этапа 1. Перенос 26 новых файлов + ~400 символов main/menu за остаток не уместить.
