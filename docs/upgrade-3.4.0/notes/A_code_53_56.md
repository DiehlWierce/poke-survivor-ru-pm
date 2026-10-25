# Код 5.3 -> 5.6: поведенческие изменения по диффам

Номера строк: v56. Метки: [5.6] = есть в патчноуте 5.6; [5.5] = есть в патчноуте 5.5 (в APK 5.3 этого ещё не было); [НЕДОК.] = в патчноутах нет.
Patchnotes.gd пропущен. Файлы: `scripts/*.gd`.

## 1. Опция «Rendimiento» (Normal / Ahorro / Mínimo) [5.6]
- Ключ настроек `settings.perf` (0..2, по умолчанию 0), save_data.gd:91 (в дефолтном словаре рядом с `quality`).
- Меню настроек: menu.gd:6992 `_srow("Rendimiento", ...)`, сегмент ["Normal","Ahorro","Mínimo"].
- Пауза > Опции: pause_ui.gd:21 новый сигнал `perf_changed(lv)`; pause_ui.gd:139 `_perf_row()` (определена :741), кнопки 130x48; main.gd:684 подключает `perf_changed -> apply_perf()`.
- main.gd:454 `var perf_lv`; main.gd:1122 `apply_perf()`: `perf_lv=clampi(settings.perf,0,2)`; плотность `pfx.setup([1,1,0.65,0.35][quality] * [1.0,0.6,0.3][perf_lv])`; `ffx.lite = perf_lv`. Вызывается на старте (main.gd:589, раньше `pfx.setup([1,1,.65,.35][quality])`).
- `_fx_cap()` main.gd:1131: при perf_lv>0 возвращает 60 (Ahorro) / 24 (Mínimo), иначе прежний match по quality.
- Трейлы снарядов (`b.trail`) только при perf_lv==0: main.gd:7353.
- Срезанная трава: число burst-Fx `min(cut.size(), [6,2,0][perf_lv])` (было 6): main.gd:6575.
- Урон/сложность не меняются (по описанию опции).

## 2. pfx: общее урезание частиц (для всех режимов) [5.5 «-50% más» / 5.6 общий]
- pfx.gd:18 `BASE_CUT` 0.6 -> 0.3.
- pfx.gd:22 `dens = clampf(q*BASE_CUT, 0.1, 1.0)` (мин было 0.2).
- `skip = clampf(1.0 - q*0.35, 0.5, 0.85)` (было `1-q*0.7`, 0.2..0.75).
- `cap_parts = int(450*clampf(q,.35,1))` (было 900); `cap_sprites = int(100*...)` (было 200).
- pfx.gd:73 `sp()`: порог пропуска `skip*0.9` (было `skip*0.6`).
- [НЕДОК. по конкретным числам; в 5.5 лишь «Menos partículas… -50% más»].

## 3. Лимит снарядов игрока [5.6]
- main.gd:2628 `_bullet_room()`, вызывается первой строкой `_make_bullet`.
- Кап `[90, 60, 36][perf_lv]` (Normal/Ahorro/Mínimo): при достижении капа удаляется первый не-orb снаряд (`ob.orb == false`), orb-ы не трогаются.

## 4. Лимит цифр урона [5.6]
- main.gd:8935 `add_text`: `cap=[80,28,10][perf_lv]`; если `Floater.alive >= cap and size < 24` — текст не создаётся (крупные >=24 проходят всегда).
- main.gd:10653 `Floater`: `static var alive`, `_enter_tree/_exit_tree` инкремент/декремент; поле `plain` (=perf_lv>0) — без обводки `draw_string_outline`; рисует `text` без повторного `L.t()` (перевод теперь только в `add_text`, `f.text = L.t(text)`).

## 5. Fusion FX: выстрел перед игроком + lite-режимы [5.6]
- fusion_fx.gd:13 `var lite` (0/1/2, ставится из `apply_perf`), :14 `const FRONT = 64.0`.
- fusion_fx.gd:~165 `_org()` = `player.position + _aim_dir()*FRONT` (точка запуска впереди игрока на 64 px).
- Заменено `pp`/`_pp()` на `_org()`: `waves` (стартовая позиция теперь `_org() + dir*8` вместо `pp + dir*24`), `seekers` (`pos:_org()`), beam (частицы замаха, origin `o` в логике и в `_d_beam` через `_gp(_org())`, частицы вдоль луча).
- Кап одновременных актов в `cast()`: `acts.size() > (40 if lite==0 else 24 if lite==1 else 14)` -> return (раньше без лимита).
- `_px`: вероятность пропуска `0.45 / 0.75 / 0.95` (lite 0/1/2).
- `_burst`: число частиц `n * 0.5 / 0.25 / 0.1`, минимум 2.
- `_d_beam`: при lite>0 не рисуются два внешних слоя луча (w*1.25, w*0.85) и два круга на концах.
- `_draw_tint()`: при lite>=2 пропускается.

## 6. Мини-босс/гиганты и ловля Poké Ball (alpha.gd, main.gd, poi.gd) [5.5]
- alpha.gd:7-10 новые константы `MAX_ALLIES=2`, `BIG_RATE_BOSS=0.6`, `BIG_RATE_MINI=0.75`; поле `allies_made`. `_legend_free()` теперь `allies_made < MAX_ALLIES` (раньше `legend` не занят) :111.
- `on_big_down(e, kind)` alpha.gd:169: ловля обычного босса (`enc=="open_boss"`, шанс 0.6) и гиганта (`enc=="mini"`, 0.75); условия: нет `cur`, `allies_made<2`, `balls>0`, режим normal/type/daily/coop, есть `_smeta[dex]`. Вызывается из main.gd:7460. Сообщение «¡%s debilitado! Lanza una Poké Ball (8 s).»
- `_begin_down()` выделен из `on_down()`; сообщение «Alfa derrotado» только для не-big. `_finish`: для big не пересчитывается `t_next`.
- Бросок: шанс `cur.rate` вместо константы `RATE`; `BallFx.z_index=20`.
- Анимация: падение шара (0.3 с, 22 px) + красная вспышка, покачивание по `fmod(tt-0.3,0.45)` амплитуда 0.55 (было 0.5); поглощение Pokémon в шар (`Down.absorb`, 0.35 с, масштаб->0.02, подъём 22 px); при успехе — золотое кольцо/burst, ally появляется масштабом 0.08->1 за 0.45 с (Tween TRANS_BACK) с белой вспышкой modulate 2.2; при провале — спрайт возвращается.
- Ally: `m.legend` либо `m.allies_extra` (main.gd:7128); `_ally_tick` лечит 0.6%/с обоих; `lg.atk_t=1.0` на старте.
- main.gd:7176-7230 `_upd_legend` -> цикл по `allies_extra` + `_upd_ally(lg)`; гистерезис движения `lg.moving`: стоп при dist<28, старт при dist>52 (было просто `>40`) [НЕДОК.].
- Для `lg.alpha`: интервал атак 1.7 с и `_ally_boss_attack` (main.gd:6138) вместо `_legend_strike` (1.25 с). Атаки: slam (zone r=96+radius, x1.8 dmg), dash/leap (beam 330+radius / zone r=82, x1.6/x1.7), rain (4 зоны r=50, x1.1), beam (3 луча веером ±0.5, x1.3), nova (r=250, x1.2), volley (5 лучей, шаг 0.27, x0.9); набор `boss_moves` строится по типу, стабильно по `_hash(dex,...)`. Поле `boss_moves`, `moving` в классе Legend (main.gd:9249).
- Новый `Hazard.ally_dmg` (main.gd:985), `_hazard_hits_enemy` (main.gd:6125), `_ally_hz`; в `_update_hazards` (main.gd:6241): если `ally_dmg>0` — бьёт врагов (кроме `scripted`) с knock 140, а не игрока.
- Уход союзника: `legend=null` только если это `legend`, иначе `allies_extra.erase`.
- main.gd:216-218, 4751, 11101, 11334, 11833: баннер вступления `join_t/join_name/join_col`, длится 3.2 с, `draw_join()` («¡FELICIDADES!» + «%s se ha unido a ti»); заменил сообщение «¡Atrapado!» [5.5 «cartel de celebración»].
- main.gd:388 `MINI_DEXES`: `[248,321,95,208]` -> `+[143,130,464,306,376,76,131,149]` (Snorlax, Gyarados, Rhyperior, Aggron, Metagross, Golem, Lapras, Dragonite) [5.5].
- Дроп/лимиты шаров: main.gd:342 `BALL_CAP 9->6`; main.gd:7086 `try_ball`: `balls>=4 -> >=3`, интервал `60 -> 90` с [5.5 «menos abundantes, máximo 6»; значения 3/90 — НЕДОК.].
- poi.gd:316 пакет: шанс шара `0.15/0.1 -> 0.1/0.06` (rare/обычный); poi.gd:345 ящик rare: `0.35 -> 0.25`; poi.gd:410 копилка: `give_up` `0.55 -> 0.7`, при tier>=3 вероятность «обе» `0.5 -> 0.3` [НЕДОК. по числам].
- poi.gd:506 кнопка «Lanzar Poké Ball»: `hud.act_sp` ставится над упавшим Pokémon (`cur.pos + (0,-34)` в экранных координатах) [5.5 «botón dentro del Pokémon caído»].
- menu.gd:4991 новая справочная запись «Capturar jefes y gigantes» (60%/75%, максимум 2).

## 7. Режим Normal: Eternatus убран, хард после 20-й минуты [5.5]
- main.gd:386 `DIR_MS`: убран `["eter", 3600.0]`.
- main.gd:393 `late_warned`; main.gd:4772: при `t>=1200` один раз баннер «¡Minuto 20! …», shake=10, sfx "boss".
- `_late_x(t)` main.gd:4678: `(t-1200)/2400 -> (t-1200)/600` (насыщение за 10 мин вместо 40).
- Спавн scaling main.gd:4700: hp `1+1.0*lx -> 1+2.0*lx`; dmg `1+0.45*lx -> 1+1.0*lx`; spd `1+0.08*lx -> 1+0.15*lx`; шанс элиты `0.04+0.12*lx -> 0.04+0.3*lx` (x2.2 hp/x1.3 dmg без изменений).
- main.gd:4577 `_scale_at`: hp `1+t/95 -> 1+t/150`; dmg `1+t/420 -> 1+t/650`; spd без изменений (`min(0.35, t/1400)`).
- Скорость спавна main.gd:4777: `pow(t/60,1.6)*0.5 -> *0.4`; множитель `0.17 -> 0.15`; новый множитель раннего буста `(1 + 0.7*clamp(1 - t/240, 0, 1))`; late-фактор `(1 - 0.25*lx) -> (1 + 1.5*lx)`.
- menu.gd:4983 текст справки «Partida Normal: Sentencia de Arceus» (вместо Eternatus).
- Числа дают пункты 5.5 «dificultad más suave», «más enemigos al inicio», «a partir del minuto 20…», «sin Eternatus»; конкретные формулы не раскрыты.
- XP: `_xp_for` main.gd:7411 добавлен множитель `early = lerp(0.85, 1.0, clamp((lvl-1)/19, 0, 1))` (уровни 1..20 дешевле до -15%) [5.5 «primeros niveles piden menos experiencia»].

## 8. Sentencia de Arceus (judgment.gd) [5.5]
- :487 HP Arceus `roundf(base*30)` -> `5000000.0`.
- :11-12 `SPD_SOFT=130.0`, `SPD_OVER=0.25`; :642 `static cap_spd(s)`: `s` до 130, дальше `130 + (s-130)*0.25` (мягкий кап скорости игрока).
- :572 скорость Arceus: `k = min(1.22, 0.74 + arena_t*0.013) + max(0, arena_t-300)*0.0015`; `spd = max(70, cap_spd(m._spd())*k)` (раньше от некапнутой скорости).
- :647 `touch_pct()` = `min(1, 0.4 + max(0, arena_t-420)/180*(1-0.4))`; урон касания `max_hp*touch_pct()` вместо `max_hp*0.4` (растёт с 7-й минуты до 100% к 10-й).
- Скорость легендарных: `max(clamp(48+(spd-78)*0.6, 48, 105), cap_spd(m._spd())*0.8)` (≥80% скорости игрока) :702.
- main.gd:1981: скорость игрока в фазе `jd.phase=="fight"` проходит через `JDM.cap_spd` [5.5].

## 9. Z-move и Dynamax: по времени, а не по уровню [5.5]
- zmove.gd:9 и dynamax.gd:9: `MIN_LEVEL 15/20 -> 1`, новый `MIN_TIME = 180.0` (3:00 run_time).
- main.gd:1323, 1329, 1577 (`_z_can`), 1601 (`_dyn_can`): условие `player.level >= MIN_LEVEL` -> `run_time >= MIN_TIME`.
- HUD подпись «Nv. %d» -> «Min 3» (main.gd:11655 и аналог для Dynamax); сообщение разблокировки «(desde el minuto 3)»; menu.gd:5245 лексикон Dynamax «desde el minuto 3».
- Остальные константы (COOLDOWN 240, DUR 60, GROW 1.6, ...) не менялись.

## 10. Геймпад: выбор движения напрямую и ремап [5.5]
- pad.gd:8 `ACTIONS` +`slot1..slot6`; :20 `LABELS` «Elegir movimiento 1..6».
- Дефолтные кнопки (pad.gd:~46): slot1 DPAD_UP, slot2 DPAD_RIGHT, slot3 DPAD_DOWN, slot4 DPAD_LEFT, slot5 MISC1, slot6 TOUCHPAD.
- main.gd:814 `_pad_slot(bi)`; main.gd:884 в обработке JoypadButton `slot = _pad_slot(bi)`; main.gd:844-847 клавиши `KEY_5`/`KEY_6` -> слоты 4 и 5.

## 11. Геймпад: меню и стик [5.6]
- pad.gd:146-147 `STICK_DELAY 0.42 -> 0.5`, `STICK_REPEAT 0.16 -> 0.24` (стик в меню медленнее при удержании).
- navgrid.gd:78-90: при горизонтальном движении на краю ряда (`row.size()<2` или первый/последний элемент) вызывается новый `_side_jump(f, items, row, dx)` (navgrid.gd:104): ищет элемент не в этом ряду, сбоку не менее 24 px, метрика `|dy|*3 + side*0.2`; если не нашёл — прежний wrap по ряду.
- menu.gd:1813: во вкладке `cur=="dex"` при `ui_left` из сетки Pokémon (focus x>500) и если слева в том же ряду (±10 px по y) никого нет — фокус на первый focusable `dex_foot`, затем `dex_detail` (кнопка «Elegir»/компаньон) [5.6].
- menu.gd:2503-2528 `_modes_select(id)` теперь обёртка: запоминает индекс кнопки в `mp_opts`, вызывает `_modes_select_impl`, затем `_restore_opts_focus` (call_deferred) — фокус остаётся на той же кнопке при смене типа и пр. [5.6]. Правка в `_side_jump` не упомянута отдельно [НЕДОК. — общая навигация rows/side, возможно часть пункта про «Elegir»].

## 12. Пауза > Resumen (pause_ui.gd) [5.5]
- Кнопка «Abandonar partida» на вкладке Resumen (pause_ui.gd:325, 250x56, шрифт 24, нижний правый угол, `quit_run.emit()`).
- Блок «Pokémon» в начале списка движений: имя (`d["pname"]`), пилюли типов, рамка с «Habilidad: %s» (`ab_name`) и описанием (`ab_desc`) (pause_ui.gd:522-556) — требует новых полей в `pause_summary()` main.gd (не в диффе; поля из v56 main). Отдельного заголовка «Movimientos» сверху больше нет (:298 удалён, добавлен ниже :555) [5.5 «nueva pantalla… Resumen»; блок способности — НЕДОК. как отдельная деталь].
- Предметы: вместо HFlow пилюль — карточки 48 px с иконкой, именем (20) и описанием (15) [5.5 «El resumen muestra los objetos y lo que hace cada movimiento»].
- Правый отступ 20 px у `stat_grid` и `moves_box` (MarginContainer) под более толстый скролл [5.5].

## 13. Баланс движений (moves_data.gd) [5.5]
- :49 aura-sphere: dmg 17->24, pierce 0->1.
- Fairy charm (cc "charm"): `ccp` 0.07/0.12 -> **0.4**: fairy-wind (:53, также dmg 11->13), dazzling-gleam (:54, dmg 9->11), fleur-cannon (:82, ccp 0.12->0.4, dmg 50->57), play-rough (:83, ccp 0.12->0.4, dmg 27->31).
- Все остальные записи не менялись (Scald/Flamethrower в 5.5 notes — вне этих диффов, у них, вероятно, другие данные, см. evo-таблицы; в диффах moves_data их нет).

## 14. Предметы: описания (types_data.gd) [5.5]
- Только текст описаний, числа в самих формулах в этом diff не меняются: choiceband («solo puedes usar el movimiento que tengas activo»), shellbell («4% del daño, hasta 4 vida/с»), lifeorb («1% max_hp за атаку»), rockyhelmet («15 + 4 за уровень»), safetygoggles, pureincense («+30% hp, +50% exp, +25% монет»). Эти значения должны совпадать с кодом в main.gd (в diff main.gd кода предметов нет — только текст).
- Статус-эффектов в types_data diff нет.

## 15. Экономика (save_data.gd) [5.5]
- save_data.gd:36 `UP_COST_MUL = 0.6`; `up_cost` умножает на него: цена пермаапгрейдов -40%.
- `max_hp`, `base`, `grow` апгрейдов без изменений.
- Дефолт `settings.perf: 0` (см. п.1).

## 16. Эволюция движений [5.5]
- main.gd:1914 и :1918 (evo-инфо для UI): поле `ready` теперь всегда `true` (раньше зависело от `_lv(needs) > 0` / `_has_item(bigorb)`) — эволюция только по максимальному уровню, без требований [5.5 «evolucionan solo con subirlos al nivel máximo»]. Сами условия эволюции в других местах main.gd в этом diff не менялись (только UI-флаг).

## 17. Карты выбора движений
- main.gd:7647: при формировании кандидатов вес Normal-типа `NORMAL_MOVE_W=0.15` (const main.gd:341) — взвешенный shuffle через ключ `rand^(1/w)`; остальные типы вес 1.0 [5.5].

## 18. Прочее
- updater.gd:13 `FALLBACK_VERSION "5.3" -> "5.6"` [служебное, НЕДОК. очевидно].
- menu.gd:5245 лексикон Dynamax: текст «desde el minuto 3» [5.5].

## Недокументированное (сводка)
- Конкретные числовые константы шаров: `try_ball` порог 3 / интервал 90 с; poi.gd шансы (0.1/0.06, 0.25, 0.7/0.3).
- Гистерезис движения союзника (`lg.moving`, 28/52 px) в main.gd:7218.
- pfx: `skip` формула, `cap_parts 450`, `cap_sprites 100`, `sp() skip*0.9`.
- fusion_fx кап `acts` 40/24/14 и lite-пороги (упомянуто лишь «simplifica efectos»).
- Блок «Pokémon + Habilidad» в Resumen.
- navgrid `_side_jump` как общая механика межрядного перехода по X (в 5.6 упомянуты только 3 частных случая).
- Рост касания Arceus после 7 мин документирован; но формула `touch_pct` (100% к 10 мин) и бонус скорости после 300 с — детали не документированы.
