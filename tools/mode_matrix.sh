#!/usr/bin/env bash
# Матрица режимов × покемонов × сидов × мета-прогресса с ботом (tools/mode_matrix.gd).
#   tools/mode_matrix.sh                       # полная матрица (см. MODES/DEXES/SEEDS/METAS ниже)
#   MODES="rush" DEXES="4 25" SEEDS="1 2" METAS="zero max" SECS=600 JOBS=8 tools/mode_matrix.sh
#   ONE="rush 4 1 zero" tools/mode_matrix.sh   # один прогон с выводом в терминал
#   KEYS= tools/mode_matrix.sh   # без --keys-only: путь ПК (не приставки)
#   PROJECT=/path/to/other/checkout tools/mode_matrix.sh   # прогнать тот же бот на другой ветке (например main)
# Каждый прогон — отдельный процесс Godot с временным HOME (сохранение и логи игрока не трогаются;
# сам бот ещё и держит сохранение только в памяти с save_blocked). Ошибки скриптов ищутся в stderr.
# Известный шум (есть и на main, гонка фоновой загрузки текстур в headless dummy-рендере): ERROR Parameter "t" is null
# в texture_2d_initialize — не считается провалом.
# Итог: таблица и $OUT/summary.txt; провал = SCRIPT ERROR/push_error/ISSUE/нет MATRIX_RESULT.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$ROOT/tools/mode_matrix.gd"
PROJECT="${PROJECT:-$ROOT}"
GODOT_BIN="${GODOT_BIN:-godot}"
# Покемоны: стартёры огня/воды/травы + по одному на каждый первичный тип + разные способности
# (25 электро/static, 92 призрак/levitate, 66 боевой/guts, 74 камень/sturdy, 147 дракон, 123 жук/swarm, 35 фея/cutecharm,
#  81 сталь/magnetpull, 52 нормальный/pickup, 96 психо/insomnia, 27 земля/sandveil, 16 летающий/keeneye, 41 яд, 215 тьма, 220 лёд,
#  129 вода/swiftswim, 113 нормальный/naturalcure, 448 боевой/innerfocus)
DEXES="${DEXES:-1 4 7 25 92 66 74 147 123 35 81 52 96 27 16 41 215 220 129 113}"
MODES="${MODES:-normal daily rush party type team coop rifts tower}"
SEEDS="${SEEDS:-1 2}"
METAS="${METAS:-zero mid max}"
SECS="${SECS:-}"
JOBS="${JOBS:-8}"
OUT="${OUT:-${TMPDIR:-/tmp}/mode_matrix.$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT"
TMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/poke-matrix-home.XXXXXX")" || exit 1
trap 'rm -rf "$TMP_HOME"' EXIT

secs_for() {   # игровых секунд по режиму: хватает на 2 смены биома / 6+ боссов / разломы / несколько этажей
	if [[ -n "$SECS" ]]; then echo "$SECS"; return; fi
	case "$1" in
		rush) echo 480 ;;
		rifts) echo 500 ;;
		tower) echo 420 ;;
		*) echo 540 ;;
	esac
}

run_one() {
	local mode="$1" dex="$2" seed="$3" meta="$4"
	local tag="${mode}_${dex}_s${seed}_${meta}"
	local log="$OUT/$tag.log"
	local h="$TMP_HOME/$tag"
	mkdir -p "$h"
	cp "$TOOL" "$PROJECT/tools/mode_matrix.gd" 2>/dev/null || true
	HOME="$h" "$GODOT_BIN" --headless --path "$PROJECT" --fixed-fps 30 --script res://tools/mode_matrix.gd -- ${KEYS---keys-only} \
		--mode "$mode" --dex "$dex" --seed "$seed" --meta "$meta" --secs "$(secs_for "$mode")" >"$log" 2>&1
	rm -rf "$h"
	local res errs st
	res="$(grep -m1 '^MATRIX_RESULT ' "$log" | cut -d' ' -f2-)"
	errs="$(grep -E 'SCRIPT ERROR|Parse Error|^ERROR:|USER ERROR' "$log" | grep -vE 'resources still in use at exit|ret != noErr|get_system_ca_certificates|RID allocations|Parameter "t" is null' | sort | uniq -c | sort -rn | head -5)"
	if [[ -z "$res" ]]; then st="FAIL(no result)"
	elif [[ -n "$errs" ]]; then st="FAIL(script error)"
	elif echo "$res" | grep -q '"ok":false'; then st="FAIL(issue)"
	else st="OK"; fi
	local hit
	hit="$(echo "$res" | sed -nE 's/.*"hitches":([0-9]+).*"worst_ms":([0-9.]+).*/hitch=\1 worst=\2ms/p')"
	echo "$st $tag $hit $(echo "$res" | sed -nE 's/.*"issue_kinds":(\{[^}]*\}).*/\1/p')" >>"$OUT/summary.txt"
	if [[ "$st" != OK ]]; then
		{ echo "== $tag: $st"; [[ -n "$errs" ]] && echo "$errs"; grep -E '^ISSUE ' "$log" | head -5; } >>"$OUT/failures.txt"
	fi
	echo "$st $tag $hit"
}
export -f run_one secs_for
export OUT TMP_HOME GODOT_BIN PROJECT TOOL SECS

if [[ -n "${ONE:-}" ]]; then
	read -r m d s me <<<"$ONE"
	HOME="$TMP_HOME" "$GODOT_BIN" --headless --path "$PROJECT" --fixed-fps 30 --script res://tools/mode_matrix.gd -- ${KEYS---keys-only} \
		--mode "$m" --dex "$d" --seed "$s" --meta "${me:-zero}" --secs "$(secs_for "$m")" --verbose ${EXTRA:-}
	exit $?
fi

: >"$OUT/summary.txt"
: >"$OUT/failures.txt"
for mode in $MODES; do for dex in $DEXES; do for seed in $SEEDS; do for meta in $METAS; do
	echo "$mode $dex $seed $meta"
done; done; done; done | xargs -P "$JOBS" -L 1 bash -c 'run_one "$0" "$1" "$2" "$3"'

total=$(wc -l <"$OUT/summary.txt" | tr -d ' ')
ok=$(grep -c '^OK ' "$OUT/summary.txt")
hitchy=$(grep -cE 'hitch=[1-9]' "$OUT/summary.txt")
echo "== матрица: $ok/$total OK (с рывками >100 мс: $hitchy); логи: $OUT"
[[ -s "$OUT/failures.txt" ]] && cat "$OUT/failures.txt"
(( ok == total ))
