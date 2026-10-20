#!/usr/bin/env bash
# Сравнивает изменённые scripts/ текущей рабочей копии с их версией в BASE_REF,
# чередуя порядок прогонов. Все замеры идут в одном worktree и через общий lock.
set -euo pipefail
if (( $# < 1 || $# > 2 )); then
  echo "Использование: $0 <base-ref> [пары=3]" >&2
  exit 2
fi
BASE_REF="$1"
PAIRS="${2:-3}"
if ! [[ "$PAIRS" =~ ^[0-9]+$ ]] || (( PAIRS < 1 )); then
  echo "Число пар должно быть положительным целым" >&2
  exit 2
fi
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
GODOT_BIN="${GODOT_BIN:-godot}"
LOCK=/private/tmp/poke-bench-lock.sh
if [[ ! -x "$LOCK" ]]; then
  echo "ОШИБКА: нет общего замка $LOCK; бенч не запущен" >&2
  exit 2
fi
if ! git rev-parse --verify "$BASE_REF^{commit}" >/dev/null 2>&1; then
  echo "ОШИБКА: base-ref не является коммитом: $BASE_REF" >&2
  exit 2
fi
FILES=()
while IFS= read -r file; do FILES+=("$file"); done < <({ git diff --name-only "$BASE_REF" -- scripts; git ls-files --others --exclude-standard -- scripts; } | sort -u)
if (( ${#FILES[@]} == 0 )); then
  echo "Нет изменённых или новых scripts/ файлов относительно $BASE_REF" >&2
  exit 2
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/poke-bench-ab.XXXXXX")" || exit 2
HOME_TMP="$TMP/home"
mkdir -p "$HOME_TMP/Library/Application Support/Godot/app_userdata/Pokémon Survivors/logs" "$TMP/after"
export HOME="$HOME_TMP"
for f in "${FILES[@]}"; do
  mkdir -p "$TMP/after/$(dirname "$f")"
  if [[ -f "$f" ]]; then cp -p "$f" "$TMP/after/$f"; else touch "$TMP/after/.absent-${f//\//_}"; fi
done
restore_after() {
  for f in "${FILES[@]}"; do
    if [[ -f "$TMP/after/.absent-${f//\//_}" ]]; then
      rm -f "$f"
    else
      mkdir -p "$(dirname "$f")"
      cp -p "$TMP/after/$f" "$f"
    fi
  done
}
restore_base() {
  for f in "${FILES[@]}"; do
    if git cat-file -e "$BASE_REF:$f" 2>/dev/null; then
      mkdir -p "$(dirname "$f")"
      git show "$BASE_REF:$f" > "$f" || return 1
    else
      rm -f "$f"
    fi
  done
}
cleanup() {
  restore_after
  rm -rf "$TMP"
}
trap cleanup EXIT INT TERM
run_bench() {
  local label="$1" log="$2"
  echo "Запуск: $label"
  "$LOCK" codex "$GODOT_BIN" --headless --path "$ROOT" --fixed-fps 30 --script res://tools/bench_frame.gd -- --keys-only --scenario run --prof >"$log" 2>&1
  local rc=$?
  cat "$log"
  if (( rc != 0 )); then echo "Бенч завершился с кодом $rc" >&2; return 1; fi
  python3 - "$log" <<'PY' | tee -a "$log"
import json, sys
rows = [line[7:] for line in open(sys.argv[1], encoding="utf-8", errors="replace") if line.startswith("RESULT ")]
if not rows:
    raise SystemExit("Не найден RESULT JSON")
r = json.loads(rows[-1])
c = r.get("chunks", {})
vals = (r.get("avg_ms"), r.get("p99_ms"), c.get("bench_blank_frames"), c.get("vis_missing"))
if any(v is None for v in vals):
    raise SystemExit(f"В RESULT отсутствует метрика: {vals}")
print("METRICS %.6f %.6f %d %d" % vals)
if vals[2] != 0 or vals[3] != 0:
    raise SystemExit("Нарушено требование blank=0 и vis_missing=0")
PY
}
AFTER_AVG=(); AFTER_P99=(); BASE_AVG=(); BASE_P99=()
for (( pair=1; pair<=PAIRS; pair++ )); do
  a_log="$TMP/pair-${pair}-after.log"; b_log="$TMP/pair-${pair}-base.log"
  if (( pair % 2 == 1 )); then
    restore_after || exit 1
    run_bench "после, пара $pair" "$a_log" || exit 1
    restore_base || exit 1
    run_bench "до, пара $pair" "$b_log" || exit 1
  else
    restore_base || exit 1
    run_bench "до, пара $pair" "$b_log" || exit 1
    restore_after || exit 1
    run_bench "после, пара $pair" "$a_log" || exit 1
  fi
  read -r _ aa ap ab av < <(grep '^METRICS ' "$a_log" | tail -1)
  read -r _ ba bp bb bv < <(grep '^METRICS ' "$b_log" | tail -1)
  AFTER_AVG+=("$aa"); AFTER_P99+=("$ap"); BASE_AVG+=("$ba"); BASE_P99+=("$bp")
  echo "Пара $pair: avg после/до=$aa/$ba ms; p99 после/до=$ap/$bp ms; blank после/до=$ab/$bb; vis_missing после/до=$av/$bv"
done
python3 - "$PAIRS" "${AFTER_AVG[*]}" "${AFTER_P99[*]}" "${BASE_AVG[*]}" "${BASE_P99[*]}" <<'PY'
import sys
n = int(sys.argv[1])
def vals(s): return [float(x) for x in s.split()]
aa, ap, ba, bp = map(vals, sys.argv[2:6])
ma, mb = sum(aa)/n, sum(ba)/n
mp, mq = sum(ap)/n, sum(bp)/n
print(f"СРЕДНИЕ ({n} пар): avg после/до={ma:.3f}/{mb:.3f} мс; p99 после/до={mp:.3f}/{mq:.3f} мс; blank=0; vis_missing=0")
if ma > mb * 1.03 or mp > mq * 1.05:
    print("BENCH_AB_FAIL: avg > +3% или p99 > +5%")
    raise SystemExit(1)
print("BENCH_AB_OK")
PY
