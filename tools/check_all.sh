#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
GODOT_BIN="${GODOT_BIN:-godot}"
EXPECTED_PG_HASH=3914984115
EXPECTED_TOAST_HASH=2461697248
TMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/poke-check-home.XXXXXX")" || exit 1
LOG_DIR="$TMP_HOME/Library/Application Support/Godot/app_userdata/Pokémon Survivors/logs"
mkdir -p "$LOG_DIR"
export HOME="$TMP_HOME"
trap 'rm -rf "$TMP_HOME"' EXIT
errors=0
known_resource_errors=0
known_ca_errors=0
run_check() {
  local label="$1"; shift
  local log
  log="$(mktemp "${TMPDIR:-/tmp}/poke-check-log.XXXXXX")" || return 1
  "$@" >"$log" 2>&1
  local rc=$?
  cat "$log"
  if (( rc != 0 )); then
    echo "FAIL: $label (exit $rc)"
    errors=$((errors + 1))
  fi
  if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "$log" | grep -vE 'ERROR: [0-9]+ resources still in use at exit|ERROR: Condition \"ret != noErr\" is true. Returning: \"\"' >/dev/null; then
    echo "FAIL: $label emitted an error"
    errors=$((errors + 1))
  fi
  local known
  known="$(grep -Ec 'ERROR: [0-9]+ resources still in use at exit' "$log" || true)"
  known_resource_errors=$((known_resource_errors + known))
  local ca
  ca="$(grep -Ec 'get_system_ca_certificates \(platform/macos/os_macos.mm:1035\)' "$log" || true)"
  known_ca_errors=$((known_ca_errors + ca))
  rm -f "$log"
  return 0
}
echo "== GDScript parse checks =="
while IFS= read -r script; do
  case "$script" in
    # Мёртвые, удаляются в A3/A4: старые переводы menu, исключены до удаления.
    scripts/menu_e14.gd|scripts/menu_e15.gd) echo "SKIP $script — мёртвые, удаляются в A3/A4"; continue ;;
  esac
  run_check "parse $script" "$GODOT_BIN" --headless --path "$ROOT" --check-only --script "res://$script" || true
done < <(find scripts -type f -name '*.gd' | sort)
echo "== Scene and language smoke =="
run_check "smoke" "$GODOT_BIN" --headless --path "$ROOT" --script res://tools/smoke.gd || true
echo "== quit-after 600 =="
run_check "quit-after" "$GODOT_BIN" --headless --path "$ROOT" --quit-after 600 -- --keys-only || true
echo "== pgcheck =="
PG_LOG="$(mktemp "${TMPDIR:-/tmp}/poke-pgcheck.XXXXXX")"
"$GODOT_BIN" --headless --path "$ROOT" --script res://tools/pgcheck.gd >"$PG_LOG" 2>&1
pg_rc=$?
cat "$PG_LOG"
if (( pg_rc != 0 )); then
  echo "FAIL: pgcheck (exit $pg_rc)"
  errors=$((errors + 1))
fi
if ! grep -Eq "check ids: .*hash=${EXPECTED_PG_HASH} toasts hash=${EXPECTED_TOAST_HASH}" "$PG_LOG"; then
  echo "FAIL: pgcheck hash differs from expected ${EXPECTED_PG_HASH}/${EXPECTED_TOAST_HASH}"
  errors=$((errors + 1))
fi
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "$PG_LOG" | grep -vE 'ERROR: [0-9]+ resources still in use at exit|ERROR: Condition \"ret != noErr\" is true. Returning: \"\"' >/dev/null; then
  echo "FAIL: pgcheck emitted an error"
  errors=$((errors + 1))
fi
known="$(grep -Ec 'ERROR: [0-9]+ resources still in use at exit' "$PG_LOG" || true)"
known_resource_errors=$((known_resource_errors + known))
ca="$(grep -Ec 'get_system_ca_certificates \(platform/macos/os_macos.mm:1035\)' "$PG_LOG" || true)"
known_ca_errors=$((known_ca_errors + ca))
rm -f "$PG_LOG"
echo "== summary =="
echo "known resources still in use at exit: $known_resource_errors"
echo "known macOS CA lookup diagnostics (present at baseline): $known_ca_errors"
if (( errors > 0 )); then
  echo "CHECK_ALL_FAIL: $errors"
  exit 1
fi
echo "CHECK_ALL_OK"
