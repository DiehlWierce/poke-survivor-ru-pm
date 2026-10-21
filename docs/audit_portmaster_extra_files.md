# Аудит лишних файлов в ветке `portmaster` (3.1.2)

Только чтение (`git ls-tree -r -l portmaster`, grep `res://` по scripts/data/project.godot/export_presets.cfg). Удаление — только после одобрения владельца. Размеры — байты в git (без сжатия).

Всего в ветке: 27 385 файлов, 98,4 МБ. Из них `assets/pokemon` — 89,3 МБ (26 936 файлов, 966 покемонов × 7 анимаций × обычный/`s/` + `.import`), audio 2,1 МБ, data 2,3 МБ, fonts 2,0 МБ, scripts 1,0 МБ, docs 0,94 МБ.

## Что нужно порту
- `tools/portmaster/build.sh` (3 354), `portmaster/` (Pokemon Survivors.sh, `pokesurvivors/`: port.json, gameinfo.xml, gptk, README, cover.png, screenshot.png, licenses/ — 175 764 всего), `LICENSE`, `CREDITS.md`, `export_presets.cfg` (пресет PortMaster исключает `portmaster/*, tools/*, README.md, RELEASE_NOTES_v1.0.0.md, main_etapa*.txt, scripts/*.gd.txt`), `project.godot`, `scenes/`, `scripts/`, `audio/` (все 75 ogg используются: sfx_shot_*, burst%d, reveal%d — динамические имена), `fonts/` (кроме пункта ниже), `data/*.json` (кроме пункта ниже), `icon.png` (config/icon), `assets/pokemon` (все 966 папок есть в pokedex.json; анимации Idle/Walk/Attack/Charge/Hurt/Faint/Shoot и `s/` используются в коде) и `assets/world` (102 файла, 399 471).
- Тяжёлое место порта — спрайты покемонов (91 % веса), но они нужны игре; сокращать можно только пересжатием/атласом, не удалением.

## Точно лишнее (1 048 186 Б ≈ 1,0 МБ)

| Путь | Размер | Причина |
|---|---|---|
| `main_etapa6.gd.txt` | 79 129 | Старый слепок main.gd, не используется, исключён из экспорта |
| `main_etapa7.gd.txt` | 116 351 | То же |
| `docs/device_logs/` (6 dmesg + log.txt + perf_log.txt) | 513 465 | Логи приставки 3.1.0, разобраны в handoff_v5 |
| `docs/img/` (rift_veil_k02.png, k15.png) | 253 719 | Скриншоты для отчётов |
| `docs/agent_prompts.md`, `agent_prompts_round2.md`, `code_review_prompt_and_plan.md`, `codex_prompt_v5.md` | 85 522 | Выполненные промты агентов |

## Вероятно лишнее (проверить), 438 822 Б

| Путь | Размер | Причина / что проверить |
|---|---|---|
| `docs/handoff_claude.md`, `handoff_codex.md`, `handoff_merge.md`, `handoff_modes.md`, `handoff_playtest.md`, `handoff_v5.md`, `handoff_vfx.md`, `playtest_report.md` | 84 909 | История работ; ценное свести в 1–2 файла (см. audit_docs_summary.md) |
| `tools/` кроме `portmaster/build.sh` (bench_*, check_all.sh, mode_matrix.*, pgcheck, savecheck, savenotice, smoke, soak.sh, vis_probe_pfx, vischeck*, menu_ux_check + `.uid`) | 140 118 | Не нужны сборке порта, но это тест-инфраструктура разработки (check_all.sh). Решить: держать в репозитории (рекомендую) или вынести |
| `RELEASE_NOTES_v1.0.0.md` | 9 828 | Заметки Android v1.0.0, не относятся к порту |
| `icon/` (adaptive_*, main_192 и `.import`) | 116 468 | Нужны только пресету Android (adaptive foreground/background); порту не нужны. Если Android-сборки не ведутся — удалить вместе с пресетом Android |
| `icon.svg` + `.import` | 2 007 | Нигде не упоминается (иконка проекта — icon.png) |
| `fonts/PixelifySans.ttf` + `.import` | 79 926 | В коде грузится только `PixelifySansFix.ttf`; проверить, что CREDITS/OFL не ссылаются на него |
| `data/menu_sprites.json` | 5 566 | Ни одной ссылки в scripts (проверить динамическую загрузку по имени) |

## Нужное порту/игре, но стоит знать
- `portmaster/pokesurvivors/cover.png` и `screenshot.png` (по 82 039) побайтно равны `icon.png` по размеру — похоже на заглушки; для PortMaster нужны настоящие обложка/скриншот (не удаление, а замена).
- `data/lang_*.json` 2 МБ — все 10 языков используются; `lang_es_419.json` (4 838) — частичный, наследует от es.
- Все `*.import` в `assets/` (≈13 тыс. файлов, ≈12 МБ) в git нужны, т.к. `.godot/` в gitignore не коммитится; удалять нельзя без смены схемы сборки.
- `docs/upstream_v51/` (337 МБ) — неотслеживаемый, в `portmaster` отсутствует; чтобы не попал в коммит случайно, добавить в `.gitignore` (сейчас защита только через `.gdignore` для Godot, не для git).
- Не проверено: что `docs/*.md` не попадают в `.pck` (в режиме all_resources не-ресурсы без include_filter не экспортируются). Проверка: `godot --headless --export-pack` и просмотр списка — не запускалась по условию задания.

## Итог
Кандидаты на удаление: «точно» ≈ 1,05 МБ, «вероятно» ≈ 0,44 МБ, всего ≈ 1,49 МБ из 98,4 МБ (1,5 %). Выигрыш для размера порта нулевой (эти файлы не в .pck), это чистка репозитория. Реальный вес — спрайты покемонов (89 МБ), все используются.
