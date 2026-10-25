# LEDGER 3.4.0 (diffs51: V5.1 -> V5.6)

Формат: `файл | функция/константа | суть | этап | статус`. Статусы: TODO, DONE, HAD, N/A. patchnotes.gd.diff пропущен.

## Сводка

Всего строк: 181 (176 hunk-ов без patchnotes; крупные hunk-и разбиты по смыслу или этапу)

По статусам: TODO 179, HAD 1, N/A 1

По этапам: 1A 23, 1B 22, 1C 6, 2A 19, 2B 12, 3 8, 4 29, 5A 12, 5B 11, 5C 2, 5D 8, 6A 22, 6B 3, 7 2, — 2

Допущения: билеты в main.gd (сундуки, боссы, дроп) отнесены к 1A (владелец main.gd); справка Normal в menu.gd к 1A; кнопка Kecleon `-128` в v56 (в PLAN `-12`) сверить на этапе 3; `updater.gd` N/A, версию синхронизировать на этапе 7.

## alpha.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| alpha.gd | MAX_ALLIES, BIG_RATE_BOSS, BIG_RATE_MINI | новые константы: до 2 союзников за забег, шанс поимки босса 0.6 / гиганта 0.75 | 4 | TODO |
| alpha.gd | allies_made | счётчик созданных союзников | 4 | TODO |
| alpha.gd | BallFx._process/_draw | анимация шара: падение после броска, красная вспышка, покачивания с красным свечением вместо поворота | 4 | TODO |
| alpha.gd | Down (absorb, base_pos) | поглощение побеждённого шаром: сжатие, подъём, покраснение | 4 | TODO |
| alpha.gd | _legend_free | свободно, пока allies_made < MAX_ALLIES (раньше: нет живого legend) | 4 | TODO |
| alpha.gd | on_down / on_big_down | on_down вызывает _begin_down; новый on_big_down для боссов и гигантов (enc open_boss/mini), нужен balls>0 и режим normal/type/daily/coop | 4 | TODO |
| alpha.gd | _begin_down | вынесен из on_down; сообщение «Альфа» только если не big; node.base_pos | 4 | TODO |
| alpha.gd | throw (rate, z_index) | шанс броска берётся из cur.rate (иначе RATE); fx2.z_index=20 | 4 | TODO |
| alpha.gd | _process state throw (absorb) | в момент попадания шара запускается absorb и красный burst | 4 | TODO |
| alpha.gd | _finish | для big-цели не сбрасывать t_next | 4 | TODO |
| alpha.gd | _resolve | при успехе золотые эффекты вместо _vanish, ball_pos; при провале сброс absorb | 4 | TODO |
| alpha.gd | _make_ally, _ally_tick | рост из шара (tween), второй союзник в allies_extra, баннер join_name/join_col вместо _say, лечение всех союзников | 4 | TODO |

## display.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| display.gd | WIN_RES, is_desktop, win_mode, win_res, apply_window, set_window | режим окна и разрешение для ПК | 6B | TODO |

## dynamax.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| dynamax.gd | MIN_LEVEL, MIN_TIME | MIN_LEVEL 20→1, новая MIN_TIME=180.0 | 1B | DONE |

## fusion_fx.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| fusion_fx.gd | lite, FRONT | новые поля: lite (=SV.perf()), FRONT=64 | 2B | TODO |
| fusion_fx.gd | cast | лимит acts 40/24/14 по lite | 2B | TODO |
| fusion_fx.gd | _org | новая функция: игрок + aim×FRONT | 2B | TODO |
| fusion_fx.gd | _px, _burst | пропуск частиц 0.45/0.75/0.95; burst ×0.5/0.25/0.1 по lite | 2B | TODO |
| fusion_fx.gd | waves (cast) | старт волн от _org()+dir×8 | 2B | TODO |
| fusion_fx.gd | seekers (cast) | старт искателей от _org() | 2B | TODO |
| fusion_fx.gd | beam wind-up _px | частицы подготовки луча от _org() | 2B | TODO |
| fusion_fx.gd | beam tick o | источник луча в уроне — _org() | 2B | TODO |
| fusion_fx.gd | beam _px | частицы вдоль луча от _org() | 2B | TODO |
| fusion_fx.gd | _d_beam o | отрисовка луча от _gp(_org()) | 2B | TODO |
| fusion_fx.gd | _d_beam (lite) | при lite>0 не рисовать внешние слои и круги луча | 2B | TODO |
| fusion_fx.gd | _draw_tint | при lite>=2 не рисовать тонировку | 2B | TODO |

## judgment.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| judgment.gd | SPD_SOFT, SPD_OVER | новые константы мягкого потолка скорости (130 / 0.25) | 1C | DONE |
| judgment.gd | A.max_hp | HP Арсеуса фиксированно 5000000.0 (раньше base×30) | 1C | DONE |
| judgment.gd | скорость Арсеуса | k растёт после 300 с (+0.0015/с), скорость через cap_spd | 1C | DONE |
| judgment.gd | cap_spd, touch_pct | новая static cap_spd(s) и touch_pct() — рост касания после 420 с | 1C | DONE |
| judgment.gd | touch | урон касания max_hp×touch_pct() | 1C | DONE |
| judgment.gd | легендарные спутники (def spd) | spd не ниже cap_spd(m._spd())×0.8 | 1C | DONE |

## main.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| main.gd | ORB_CAP | лимит орбов 420→300 | 2A | TODO |
| main.gd | join_t, join_name, join_col | переменные баннера «присоединился» | 4 | TODO |
| main.gd | NORMAL_MOVE_W, BALL_CAP | вес Normal-приёмов 0.15; BALL_CAP 9→6 | 1A | DONE |
| main.gd | DIR_MS, MINI_DEXES, late_warned | убрать ["eter",3600]; 12 гигантов вместо 4; флаг late_warned | 1A | DONE |
| main.gd | perf_lv | переменная perf-уровня | 2A | TODO |
| main.gd | gold_gcoins_run, gcoins_run | счётчики монет Gachapon в забеге | 5D | TODO |
| main.gd | _ready: _bind_move_devices(-1) | привязка устройств движения при старте | 6A | TODO |
| main.gd | setup: pfx.setup → apply_perf() | вместо прямого pfx.setup вызов apply_perf() | 2A | TODO |
| main.gd | pause_ui.perf_changed.connect | подписка на смену perf в паузе | 2A | TODO |
| main.gd | cards.lock_toggled/block_pressed.connect | подключение сигналов Lock/«Всегда сбрасывать» | 5A | TODO |
| main.gd | _add_input_actions, _bind_move_devices | device=-1 для кнопок/осей, новая _bind_move_devices(dev) | 6A | TODO |
| main.gd | _pad_slot | новая функция: слот 1–6 по кнопке геймпада | 6A | TODO |
| main.gd | _unhandled_input KEY_5/KEY_6 | клавиши 5 и 6 выбирают слоты 5–6 | 6A | TODO |
| main.gd | _unhandled_input (joypad slot) | кнопки геймпада slot1..6 | 6A | TODO |
| main.gd | _unhandled_input act_req | act_req не ставится, пока открыта лавка (shop_open) | 3 | TODO |
| main.gd | _end_run: mv_list, item_list | в итог забега добавлены desc приёма и список предметов | 5B | TODO |
| main.gd | _end_run: SV.finish_run | передаются gcoins, gold_gcoins, items | 5D | TODO |
| main.gd | apply_perf, _fx_cap | новая apply_perf (плотность ×1/0.6/0.3, ffx.lite); _fx_cap 60/24 при perf и 200/60/20 без | 2A | TODO |
| main.gd | _process: hud.join_* | передача join_* в HUD | 4 | TODO |
| main.gd | _process: z_btn, dyn_btn | готовность кнопок Z/MAX по run_time >= MIN_TIME | 1A | DONE |
| main.gd | _z_can | условие run_time >= ZM.MIN_TIME вместо level | 1A | DONE |
| main.gd | _dyn_can | условие run_time >= DYN.MIN_TIME вместо level | 1A | DONE |
| main.gd | _f (burnp, KNOCK_BASE) | burn с вероятностью burnp; база отдачи KNOCK_BASE на 1-м уровне | 1B | TODO (main.gd — не в моём списке; передать 1A: KNOCK_BASE/burnp/Min 3/say) |
| main.gd | _evo_infos | ready=true без требования навыка (и для ALT) | 1A | DONE |
| main.gd | _evo_infos (burnp текст) | в тексте эволюции добавляется «% шанс поджечь» из EVO_EXTRA.burnp | 1B | TODO (main.gd — не в моём списке; передать 1A: KNOCK_BASE/burnp/Min 3/say) |
| main.gd | player move spd | скорость игрока в бою с Судом — JDM.cap_spd(_spd()) при jd.phase=="fight" | 1A | DONE |
| main.gd | _setup_partner: _bind_move_devices | привязка устройств при старте напарника | 6A | TODO |
| main.gd | _update_partner | перепривязка устройств при смене pad напарника | 6A | TODO |
| main.gd | _fire_projectiles: _bullet_room, _make_bullet | лимит пуль [90,60,36] по perf_lv | 2A | TODO |
| main.gd | _scale_at | hp 1+t/150, dmg 1+t/650 | 1A | DONE |
| main.gd | _late_x | окно позднего этапа (t-1200)/600 | 1A | DONE |
| main.gd | _spawn_one | поздняя игра: HP ×(1+2lx), dmg ×(1+lx), spd ×(1+0.15lx), элиты 0.04+0.3lx | 1A | DONE |
| main.gd | _update_spawner: join_t | таймер баннера присоединения | 4 | TODO |
| main.gd | _update_spawner: late banner | «¡Minuto 20!…» (late_warned, shake 10, sfx boss) | 1A | DONE |
| main.gd | _update_spawner: rate | формула темпа спавна (×0.4, ×0.15, буст в начале, ×(1+1.5lx)) | 1A | DONE |
| main.gd | _spawn_thief | ротация воров 52/1000/1012 (thief_cycle) | 5D | TODO |
| main.gd | _spawn_thief (say) | сообщение «Gachapon Coin» для 1012 | 5D | TODO |
| main.gd | _hazard_hits_enemy, _ally_boss_attack, _ally_hz | атаки союзника-босса и попадание зон по врагам | 4 | TODO |
| main.gd | _update_hazards | ally_dmg: зоны союзника бьют врагов, а не игрока | 4 | TODO |
| main.gd | траву режет (grass cut) | число частиц травы [6,2,0] по perf_lv | 2A | TODO |
| main.gd | сундук/суперкоробка (tickets) | билеты 1 + 35% ещё одного, ticket10 0.08 (дроп с главных призов) | 1A | DONE |
| main.gd | try_ball | порог balls>=3, пауза 90 с | 1A | DONE |
| main.gd | монетный сундук (tickets) | ticket 0.07 / ticket10 0.08 | 1A | DONE |
| main.gd | allies_extra | список доп. союзников | 4 | TODO |
| main.gd | _upd_legend, _upd_ally | цикл по allies_extra; тело вынесено в _upd_ally | 4 | TODO |
| main.gd | _upd_ally: moving | гистерезис движения 28/52 | 4 | TODO |
| main.gd | _upd_ally: attack | союзник-альфа атакует _ally_boss_attack (atk_t 1.7) | 4 | TODO |
| main.gd | _legend_leave | уход союзника: учёт allies_extra | 4 | TODO |
| main.gd | bullets trail | трейлы только при perf=0, шаг 0.14 | 2A | TODO |
| main.gd | _xp_for | множитель early = lerp(0.85,1,(L-1)/19) | 1A | DONE |
| main.gd | _on_enemy_down: on_big_down | вызов alpha.on_big_down для open_boss/mini | 4 | TODO |
| main.gd | _on_enemy_down: wildleg | дикий легендарный даёт 2 билета вместо 3 | 1A | DONE |
| main.gd | loot thief (gimmi/ticket10) | Gimmighoul: gcoin/gcoin_gold; ticket10-вор: ticket10 + 1 билет без монет | 5D | TODO |
| main.gd | boss drop ticket10 | шанс 1/3 → 0.2 | 1A | DONE |
| main.gd | обычный дроп ticket | 1/400 → 1/600 | 1A | DONE |
| main.gd | _collect (gcoin kinds) | подбор gcoin и gcoin_gold | 5D | TODO |
| main.gd | _offer: выбор Normal | выборка карточек с весом NORMAL_MOVE_W (ключ u^(1/w)) | 1A | DONE |
| main.gd | pause_summary: all_stats | к каждой статистике добавлена иконка | 5B | TODO |
| main.gd | pause_summary: moves/items | icon у приёмов, desc у предметов, ab_name/ab_desc, hp_ratio | 5B | TODO |
| main.gd | _fuse_hint | причина отказа слияния после вязи | 7 | TODO |
| main.gd | _on_card_chosen: rarecandy | Редкая конфета сразу открывает следующие карточки | 5A | TODO |
| main.gd | _offer_item: блок и Lock | отфильтровать item_block, игнорировать при item_lock | 5A | TODO |
| main.gd | _offer_item: _item_ui (замена) | вызов _item_ui при выборе «оставить своё» | 5A | TODO |
| main.gd | _offer_item: rarecandy slots | для Редкой конфеты слот только 1 | 5A | TODO |
| main.gd | _item_ui, _on_lock_toggled, _on_block_pressed | кнопки Lock и «Всегда сбрасывать» | 5A | TODO |
| main.gd | _arena_bond_ready | связь доступна после победы без ожидания end<=2 | 5C | TODO |
| main.gd | _arena_tick (won) | связь: сброс, если нечего связывать; ожидание выбора связи | 5C | TODO |
| main.gd | босс-сундук (tickets) | ticket 3→2, ticket10 0.5→0.3 | 1A | DONE |
| main.gd | сундук (tickets 2) | ticket 2→1 | 1A | DONE |
| main.gd | Dynamax unlock say | текст «desde el minuto 3» без %d | 1B | TODO (main.gd — не в моём списке; передать 1A: KNOCK_BASE/burnp/Min 3/say) |
| main.gd | add_text | лимит Floater.alive [80,28,10] и plain | 2A | TODO |
| main.gd | Legend: boss_moves, moving | поля союзника | 4 | TODO |
| main.gd | Hazard.ally_dmg | поле урона союзника | 4 | TODO |
| main.gd | Orb draw: gcoin | иконка/свечение gcoin и gcoin_gold | 5D | TODO |
| main.gd | Cards: lock_toggled, block_pressed, item_mode, lock_on, block_name | сигналы и поля Lock/блока | 5A | TODO |
| main.gd | Cards: _toggle_lock, _do_block | обработчики | 5A | TODO |
| main.gd | Cards: touch (item_mode) | нажатия по кнопкам в item_mode | 5A | TODO |
| main.gd | Cards: KEY_R/KEY_B | R=Descartar siempre, B=Bloqueo в item_mode | 5A | TODO |
| main.gd | Cards: joypad reroll/ban | геймпад аналогично | 5A | TODO |
| main.gd | Cards._draw | кнопки «Descartar siempre»/«Bloqueo» | 5A | TODO |
| main.gd | Floater (alive, plain) | статический счётчик и режим без обводки | 2A | TODO |
| main.gd | Floater._draw | без L.t в отрисовке; plain пропускает обводку | 2A | TODO |
| main.gd | HUD vars join_* | поля баннера | 4 | TODO |
| main.gd | HUD act_sp | поле якоря кнопки действия | 3 | TODO |
| main.gd | HUD.draw_join | баннер «¡FELICIDADES!» + имя союзника | 4 | TODO |
| main.gd | HUD.act_rect | кнопка у цели (act_sp) и новая раскладка на коротких экранах | 3 | TODO |
| main.gd | HUD.draw_poi, _fit_size | подгонка шрифта текста кнопки действия | 3 | TODO |
| main.gd | HUD dyn «Min 3» | подпись вместо «Nv. N» | 1B | TODO (main.gd — не в моём списке; передать 1A: KNOCK_BASE/burnp/Min 3/say) |
| main.gd | HUD z «Min 3» | подпись вместо «Nv. N» | 1B | TODO (main.gd — не в моём списке; передать 1A: KNOCK_BASE/burnp/Min 3/say) |
| main.gd | HUD._draw: draw_join | вызов draw_join | 4 | TODO |

## menu.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| menu.gd | _ready: DSP.apply_window | применение режима окна при старте меню | 6B | TODO |
| menu.gd | ver_lbl | подпись версии + «Hotfix y mejoras QoL» | 7 | TODO |
| menu.gd | _show, _modes_to_top | при открытии «Режимов» прокрутка вверх | 6A | TODO |
| menu.gd | _input | Escape снимает фокус с LineEdit/TextEdit; PAD.vertical_only для плиток режимов | 6A | TODO |
| menu.gd | _grid_nav | Dex: влево к панели деталей; Modes: вверх/вниз по плиткам | 6A | TODO |
| menu.gd | нажатие «Играть» | modes_sel = первый режим | 6A | TODO |
| menu.gd | _build_modes: focus_neighbor | вертикальные соседи плиток режимов | 6A | TODO |
| menu.gd | _modes_select, _restore_opts_focus, _modes_select_impl | сохранение фокуса в опциях режима | 6A | TODO |
| menu.gd | итог забега (info) | блоки «Objetos» и «Qué hace cada movimiento» | 5B | TODO |
| menu.gd | справка: Normal | «Partida Normal: Sentencia de Arceus» (30 мин) | 1A | DONE |
| menu.gd | справка: капча | новая запись «Capturar jefes y gigantes» | 4 | TODO |
| menu.gd | лексикон Dynamax | текст «desde el minuto 3» (без DYN.MIN_LEVEL) | 1B | DONE |
| menu.gd | _refresh_settings: Rendimiento | ряд «Rendimiento» Normal/Ahorro/Mínimo | 2A | TODO |
| menu.gd | _refresh_settings: окно | «Modo de ventana» и «Resolución de la ventana» (только PC) | 6B | TODO |

## moves_data.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| moves_data.gd | flamethrower | desc, arc 0.9→1.45, count 7→8 (у нас arc 1.1, knock 70 — привести к цели) | 1B | DONE |
| moves_data.gd | aura-sphere, fairy-wind, dazzling-gleam | aura: dmg 24, pierce 1; fairy-wind 13/0.4; gleam 11/0.4 | 1B | DONE |
| moves_data.gd | fleur-cannon, play-rough | fleur 57/ccp 0.4; play-rough 31/ccp 0.4 | 1B | DONE |
| moves_data.gd | KNOCK_BASE | новая константа {"flamethrower": 45} | 1B | DONE |
| moves_data.gd | EVO_EXTRA["water-gun"] | burn:1, burnp:0.3 для эволюции Water Gun | 1B | DONE |

## navgrid.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| navgrid.gd | move (край строки) | на краю строки — прыжок в соседнюю строку | 6A | TODO |
| navgrid.gd | _side_jump | новая функция | 6A | TODO |

## pad.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| pad.gd | ACTIONS | добавлены slot1..slot6 | 6A | TODO |
| pad.gd | LABELS | подписи «Elegir movimiento N» | 6A | TODO |
| pad.gd | defaults | кнопки по умолчанию для слотов | 6A | TODO |
| pad.gd | is_cancel | Backspace больше не отмена | 6A | TODO |
| pad.gd | apply (event.device) | e.device = -1 | 6A | TODO |
| pad.gd | STICK_DELAY, STICK_REPEAT, vertical_only | задержка 0.5, повтор 0.24, флаг vertical_only | 6A | TODO |
| pad.gd | stick_event | X-ось игнорируется при vertical_only | 6A | TODO |

## pause_ui.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| pause_ui.gd | perf_changed | новый сигнал | 2A | TODO |
| pause_ui.gd | vars opt_root, tab, tab_btns, stat_grid и др. | поля вкладок/сводки | 5B | TODO |
| pause_ui.gd | build: cc.offset_top, opt_root | сдвиг панели опций под вкладки | 5B | TODO |
| pause_ui.gd | build: _perf_row | ряд Rendimiento в опциях | 2A | TODO |
| pause_ui.gd | build, _build_tabs, set_tab, _build_summary, hide_summary, _pokeball | вкладки Resumen/Opciones, убрана кнопка Resumen, панорамный фон, Abandonar | 5B | TODO |
| pause_ui.gd | _proj_art, _icon_box, _stat_tile, show_summary | новые плитки статистики, иконки, шапка с портретом | 5B | TODO |
| pause_ui.gd | _perf_row | функция выбора Normal/Ahorro/Mínimo | 2A | TODO |
| pause_ui.gd | _input | LB/RB (PAD prev/next) и Q/E/PageUp/PageDown переключают вкладки | 5B | TODO |
| pause_ui.gd | open | show summary и set_tab(0) при открытии | 5B | TODO |

## pfx.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| pfx.gd | BASE_CUT, skip, setup | dens×0.3, skip, cap_parts 450, cap_sprites 100 (у нас 1400/320 с LITE-лимитами) | 2A | TODO |
| pfx.gd | px | отбрасывание частиц по skip | 2A | TODO |
| pfx.gd | sp | отбрасывание спрайтов по skip×0.9 | 2A | TODO |

## poi.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| poi.gd | _pack_reward (opts) | вес ticket 5→3 и 15→10 | 1B | DONE |
| poi.gd | _pack_reward (try_ball) | try_ball 0.15/0.1 → 0.1/0.06 | 1B | DONE |
| poi.gd | supply claim | ticket 1, golden ticket 1, rare ball 0.25 | 1B | DONE |
| poi.gd | Kecleon trade | give_up 0.55→0.7, tier≥3 0.5→0.3 | 3 | TODO |
| poi.gd | _update: act_sp reset | сброс act_sp в начале | 3 | TODO |
| poi.gd | _update: ball/open/chest act_sp | привязка кнопки к цели (-34 / -14 / -10) | 3 | TODO |
| poi.gd | _update: Kecleon act_sp | привязка кнопки к Kecleon | 3 | TODO |

## save_data.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| save_data.gd | PITY_5 | гарантия 90 | — | HAD |
| save_data.gd | UP_COST_MUL | новая константа 0.6 | 1B | DONE |
| save_data.gd | UPGRADES ban | Veto: max 6 у нас есть; grow 1.7 (у нас 1.6) | 1B | DONE |
| save_data.gd | default settings.perf | ключ perf в настройках по умолчанию | 2A | TODO |
| save_data.gd | up_cost | множитель UP_COST_MUL в стоимости | 1B | DONE |
| save_data.gd | PURPLE_LEGEND_P | 0.3→0.12 (у нас 0.2) | 1B | DONE |
| save_data.gd | finish_run | учёт gcoins/gold_coins и gcoins в last_run | 5D | TODO |

## touch_scroll.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| touch_scroll.gd | BAR_W, _on_node_added | широкие полосы прокрутки для всех ScrollContainer | 5B | TODO |

## types_data.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| types_data.gd | ITEMS (choiceband, shellbell, lifeorb, rockyhelmet) | новые описания и механика | 1B | DONE (описания; механика в main.gd — 1A) |
| types_data.gd | ITEMS (safetygoggles, pureincense) | новые описания и механика | 1B | DONE (описания; механика в main.gd — 1A) |

## updater.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| updater.gd | FALLBACK_VERSION | 5.1→5.6; обновлятор в порте отключён, версию сохраняем 3.x (синхронизация версии — этап 7) | — | N/A |

## zmove.gd

| файл | функция/константа | суть | этап | статус |
|---|---|---|---|---|
| zmove.gd | MIN_LEVEL, MIN_TIME | MIN_LEVEL 15→1, MIN_TIME=180.0 | 1B | DONE |
