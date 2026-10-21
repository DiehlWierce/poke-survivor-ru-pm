#!/usr/bin/env bash
# Набор прогонов tools/vischeck.gd (окно, lite как на приставке, временный HOME на каждый прогон — реальный сейв не трогается).
# Использование: tools/vischeck_suite.sh [OUT_DIR] [quick]
#   quick — только normal (полный) + один короткий; без него: режимы normal/daily/rush, стартеры всех типов,
#   свежий и полностью прокачанный сейв, Z-ходы всех 18 типов (по zoff).
# Печатает по строке на прогон (VIS JSON + VIS_OK/VIS_FAIL) и в конце SUITE_OK / SUITE_FAIL.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
GODOT_BIN="${GODOT_BIN:-godot}"
OUT="${1:-$(mktemp -d "${TMPDIR:-/tmp}/vischeck.XXXXXX")}"
QUICK="${2:-}"
mkdir -p "$OUT"
fail=0
run() {
  local tag="$1"; shift
  local home; home="$(mktemp -d "${TMPDIR:-/tmp}/vischeck-home.XXXXXX")"
  mkdir -p "$home/Library/Application Support/Godot/app_userdata" "$OUT/shots_$tag"
  HOME="$home" "$GODOT_BIN" --path "$ROOT" --script res://tools/vischeck.gd -- --keys-only --seed 7 --shots "$OUT/shots_$tag" "$@" > "$OUT/$tag.log" 2>&1
  rm -rf "$home"
  local res; res="$(grep -E '^VIS_(OK|FAIL)' "$OUT/$tag.log" | tail -1)"
  echo "$tag: $(grep -E '^VIS ' "$OUT/$tag.log" | tail -1 | cut -c5-) ${res:-NO_RESULT}"
  [[ "$res" == "VIS_OK" ]] || fail=$((fail + 1))
  if grep -qE 'SCRIPT ERROR|Parse Error' "$OUT/$tag.log"; then echo "  $tag: SCRIPT ERROR в логе $OUT/$tag.log"; fail=$((fail + 1)); fi
}
run normal25 --mode normal --dex 25 --zoff 0
if [[ "$QUICK" != "quick" ]]; then
  run daily --mode daily --zoff 6
  run rush --mode rush --dex 4 --zoff 12
  run normal25_max --mode normal --dex 25 --zoff 3 --meta max
  run s1 --mode normal --dex 1 --frames 1200 --zoff 3
  run s4_max --mode normal --dex 4 --frames 1200 --zoff 9 --meta max
  run s7 --mode normal --dex 7 --frames 1200 --zoff 15
  run s79 --mode normal --dex 79 --frames 1200 --zoff 1
else
  run s4 --mode normal --dex 4 --frames 1200 --zoff 9
fi
echo "логи и скриншоты: $OUT"
if (( fail > 0 )); then echo "SUITE_FAIL: $fail"; exit 1; fi
echo "SUITE_OK"
