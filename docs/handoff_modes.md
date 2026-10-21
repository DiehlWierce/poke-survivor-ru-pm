# Матрица режимов (бот) — заметки для продолжения

## Инструменты
- `tools/mode_matrix.gd` — один забег с ботом (ходит/бегает/возвращается, выбирает карточки, переключает слоты,
  собирает орбы, заходит в разломы, держится у босса). Сторожа: TIME_STALL, CARDS_STUCK, CHOOSING_NO_CARDS,
  NO_ENEMIES, NO_KILLS, BOSS_NO_DAMAGE, RUSH_NO_BOSS, ARENA_STUCK, TOWER_STUCK, BIOME_STUCK, BLANK_CHUNKS,
  PLAYER_DEAD_GOD, рывки >100 мс. Сохранение только в памяти (save_blocked), профили `--meta zero|mid|max`.
- `tools/mode_matrix.sh` — матрица (параллельно, временный HOME). Переменные MODES/DEXES/SEEDS/METAS/SECS/JOBS/OUT/PROJECT.
  `ONE="rush 4 1 zero" EXTRA=--probe tools/mode_matrix.sh` — один прогон с подробностями.
- `tools/mode_matrix_report.py OUT...` — сводная таблица по режим×мета.
- Ветка main для сравнения: `git archive main | tar -x -C <dir>`, `godot --headless --path <dir> --import`,
  затем `PROJECT=<dir> tools/mode_matrix.sh` (скрипт сам копирует бота в tools/ того каталога).
- Свежий worktree: сначала `godot --headless --path . --import` (иначе нет кэша class_name → Parse Error «Prof»).

## Состояние
- Режимы: normal daily rush party type team coop rifts tower.
- rush 8 покемонов × 3 сида × zero/max: порт и main ведут себя одинаково (в среднем 5 боссов zero / 7 max за 480 с).
  Буквального зависания на 4-м боссе ботом пока не воспроизведено; см. ниже.
