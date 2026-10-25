# Правила для исполнителей (вставляются в каждый промпт)
Репозиторий: /Users/andrew/vscode_projects/poke-survivor (Godot 4.7, godot = /opt/homebrew/bin/godot). Ты работаешь в своём worktree (текущая папка), ветка от upgrade/3.4.0.
Справка: план docs/upgrade-3.4.0/PLAN.md (в твоём worktree она есть), LEDGER.md (твои строки — по метке этапа), notes/*.md. Апстрим: диффы V5.1→V5.6 в /Users/andrew/vscode_projects/poke-survivor-ref/diffs51/*.diff, декомпилят V5.6 в /Users/andrew/vscode_projects/poke-survivor-ref/v56 (только читать, в репозиторий не копировать).
1. Переносим ПОВЕДЕНИЕ и ЧИСЛА оригинала V5.6. Код пишем в стиле нашего дерева (имена, комментарии, раскладка scripts/ui|game|util). Ищем аналоги по смыслу (grep), номера строк апстрима к нам не относятся. Наши собственные фичи (натуры, капсулы, TM, лавка, второй приём, слияния без лимита, perf_log/run_log, DMG_TXT_MAX, keys_only) сохраняй.
2. Ключи строк = испанская строка дословно из v56. Новые строки, которых нет в v56, пиши в docs/upgrade-3.4.0/keys/<этап>.txt как «ключ | контекст». Строки оборачивай так же, как в окружающем коде (L.t / tr).
3. НЕ трогать data/lang_*.json, scripts/patchnotes.gd, README.md, project.godot (кроме input map на этапе 6) и файлы вне своего списка. Не читай main.gd/menu.gd целиком: grep -n и sed -n диапазоны.
4. Новые ключи сейва — с дефолтом в схеме SV.d; старые сейвы обязаны грузиться.
5. Память/производительность: не создавать ресурсы в _process; кэшировать и освобождать; декоративное уважает SV.perf() (когда появится).
6. В конце: `godot --headless --path . --quit` без SCRIPT ERROR/Parse Error ("resources still in use at exit" — безвредный шум), затем git commit на свою ветку по-русски, без Co-Authored. Не пушить.
7. Отчёт ≤20 строк: изменённые функции, ключи сейва, новые строки, результат headless, что НЕ удалось. Без кода. Отметь в LEDGER.md (в своём worktree) свои строки как DONE (или HAD/N/A с причиной).
