# Промт для сессии тестирования 3.4.0 (фаза II)

Открыть новую сессию Claude Code в `/Users/andrew/vscode_projects/poke-survivor` **без worktree**, ветка `upgrade/3.4.0`, режим auto. Вставить текст ниже.

---

Ты — тестировщик сборки Pokémon Survivors 3.4.0 (ветка `upgrade/3.4.0`, целевое устройство Anbernic RG34XX SP, 1 ГБ). Код не правь: только запускай проверки, читай логи и записывай дефекты. Вопросов не задавай. Push, тег, релиз и слияние в `portmaster` запрещены.

**Подготовка**
1. Прочитай `docs/upgrade-3.4.0/STATE.md` (раздел «Дефекты» и «Проблемы»), `PLAN.md` раздел «Фаза II», `notes/F_ru_coverage.md`. `main.gd` и `menu.gd` целиком не читай.
2. Dev-инструменты лежат в `tools/` (не в git, исключены через `.git/info/exclude`): `smoke.gd`, `savecheck.gd`, `mode_matrix.*`, `bench_frame.gd`, `bench_events.gd`, `soak.sh`, `menu_ux_check.gd`, `check_all.sh`, `fixtures/`. Запускай их с временным `HOME` (`HOME=$(mktemp -d)`), чтобы не трогать реальный сейв. `godot` = `/opt/homebrew/bin/godot` 4.7.2. Шум «N resources still in use at exit» безвреден.
3. Базовая линия 3.3.2 не снята. Создай чистый worktree ветки `portmaster` (`git worktree add ../poke-survivor-base portmaster`), восстанови туда `tools/` (`git archive f5421be7^ tools | tar -x -C ../poke-survivor-base`), выполни `godot --headless --path . --import` и снимай те же замеры там, для сравнения. После работы удали этот worktree.

**Проверки (каждая даёт результат в `STATE.md` → «Дефекты»: id, шаги воспроизведения, лог, подозреваемый файл и функция)**
1. `godot --headless --path . --import`, `tools/smoke.gd`, `tools/savecheck.gd` на `tools/fixtures/save_v3.0.0.json`, `save_v3.1.1.json` и `docs/upgrade-3.4.0/baseline/userdata_332/save.json`.
2. `mode_matrix` по всем режимам; новые FAIL против базовой линии — дефекты.
3. `bench_events`: поимка гиганта и босса (двое союзников, смерть союзника), Lock и «Descartar siempre», Редкая конфета, разлом с боссом и связь, воришки и монеты Gachapon, пауза LB/RB и выход, баннер 20-й минуты, Суд Арсеуса (победа), смена `perf` на лету. Если сценария нет в `bench_events.gd`, допиши его в отдельном файле `tools/` (в git не коммитить).
4. `soak`: 30 минут normal до Суда при `perf=1`. Сравни рост узлов и памяти с базовой линией.
5. `bench_frame` при `perf` 0/1/2 с fusion-приёмом против базовой линии: таблица FPS, `_draw` по классам, пиковая память. Цель: память на `perf=1` не выше 3.3.2. Отдельно измерь пик памяти при открытых видео-превью в меню (`perf=0`).
6. `menu_ux_check` с `--lang ru` и `--lang es`. Проверь полноту переводов: `python3 docs/upgrade-3.4.0/tools_cov.py --md notes/F_ru_coverage.md` (ждём missing=0, ru_same=0).
7. Скриншоты HUD при 640×480, 720×720, 1280×720 (built-in browser недоступен для Godot: используй `godot` с `--resolution` и `--write-movie`/скриншот через скрипт, как в `tools/vischeck*.gd`): кнопка действия у цели и без цели, MAX/Z, баннеры («¡Minuto 20!», «¡FELICIDADES!»), новая пауза, итог забега. Сохрани в `docs/upgrade-3.4.0/shots/`. Сверь, что кнопка действия не перекрывает Dynamax/Z, полосу приёмов и стик на 640×480.
8. Запуск с `-- --keys-only` (режим приставки): слоты 1–6 не привязаны по умолчанию, но назначаются на экране кнопок; окно/разрешение скрыты; по умолчанию `perf=1`.
9. `/code-review high` по диапазону `portmaster..upgrade/3.4.0`; находки — в «Дефекты».

**Итог:** в `STATE.md` заполни таблицу perf (FPS, `_draw`, память: 3.3.2 против 3.4.0 при perf 0/1/2), список дефектов с приоритетами (блокирующий / важный / косметика) и список непроверенного (что можно проверить только на приставке). Закоммить `docs/` на ветку `upgrade/3.4.0` («3.4.0 этап 8: результаты тестирования»). В конце напиши мне короткий отчёт: сколько дефектов, самые серьёзные, перспективы по памяти на приставке.
