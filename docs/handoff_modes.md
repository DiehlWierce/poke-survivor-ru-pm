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

## Прогоны (Mac, 9 параллельно, --fixed-fps 30)
- full1 (normal+daily, 10 покемонов × 2 сида × zero/mid/max, 117 прогонов): жёстких проблем нет (ни TIME_STALL,
  CARDS_STUCK, NO_ENEMIES, BIOME_STUCK, BLANK_CHUNKS). Мягкие: BOSS_NO_DAMAGE/NO_KILLS — слабый бот/баланс
  (Leafeon-босс с регенерацией против травяных атак Бульбазавра и т.п.), такие же на main.
- Рывки >400 мс на Mac только в момент входа в разлом (arena=true, 450-1250 мс; под параллельной нагрузкой) —
  область другого агента (переход в разлом); сравнить с main одиночным прогоном.
- Ошибка движка «Parameter "t" is null» (texture_2d_initialize, dummy-рендер headless) есть и на main — шум, игнорируется.
- Бот: Z/C через настоящий _input (Input.parse_input_event), переключение слотов (только активная группа стреляет;
  слот из одних buff = 0 урона — так «застревали» первые прогоны), сбор орбов, держится у босса. `--lvl N` — сильный игрок.
- rush с `--lvl 25 --meta max` (Z+Динамакс): 12 боссов за 480 с, без зависаний.
