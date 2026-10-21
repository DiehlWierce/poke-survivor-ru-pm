#!/usr/bin/env bash
# Soak-прогон 30–40 мин игрового времени: стоимость кадра и память не должны расти со временем.
# Баг приставки 3.1.0 проявился после ~29 мин (забег + меню + второй забег в одном процессе), а матрица шла ≤10 мин.
#   tools/soak.sh                                  # normal и rush × стартёры 1 4 7 × max-мета, 2400 игровых с (≈4–6 мин на прогон)
#   MODES="normal" DEXES="4" SECS=2400 tools/soak.sh
# Критерий (окно 600…1740 игровых с, до Приговора на 30-й минуте (там бот-бессмертный не может убить босса, и враги копятся сами)):
#   память в конце окна не больше 1.25× от начала. ms_avg (медиана 5 замеров) растёт > 1.6× — только предупреждение: в normal он следует за силой бота (лвл 40→117, сотни снарядов), а не за утечкой + пик памяти < 450 МБ. Итог: SOAK_OK / SOAK_FAIL.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${OUT:-${TMPDIR:-/tmp}/soak.$(date +%Y%m%d_%H%M%S)}"
export MODES="${MODES:-normal rush}" DEXES="${DEXES:-1 4 7}" SEEDS="${SEEDS:-1}" METAS="${METAS:-max}" SECS="${SECS:-2400}" JOBS="${JOBS:-3}" VERBOSE=1 OUT
"$ROOT/tools/mode_matrix.sh" >"$OUT.matrix.txt" 2>&1
tail -n 12 "$OUT.matrix.txt"
python3 -I - "$OUT" <<'PY'
import glob,re,sys
bad=0
for f in sorted(glob.glob(sys.argv[1]+"/*.log")):
    rows=[]
    for ln in open(f,errors="replace"):
        m=re.match(r"STAT t=(\d+) .*ms_avg=([\d.]+).* mem=(\d+)MB obj=(\d+) res=(\d+)",ln)
        if m: rows.append(tuple(float(x) for x in m.groups()))
    if not rows: print("SOAK_FAIL %s: нет STAT"%f); bad+=1; continue
    win=[r for r in rows if 600<=r[0]<=1740] or rows
    a,b=win[0],win[-1]
    med=lambda v:sorted(v)[len(v)//2]
    ma=med([r[1] for r in win[:5]]); mb=med([r[1] for r in win[-5:]])   # ms_avg шумный (снаряды игрока) — сравниваем медианы краёв
    peak=max(r[2] for r in rows if r[0]<=1740)
    ok = b[2]<=a[2]*1.25+10 and peak<450
    warn = " ПРЕДУПРЕЖДЕНИЕ: ms_avg вырос (проверь, не растёт ли сила бота: лвл/снаряды)" if mb>max(ma*1.6,3.0) else ""
    print("%s %s: t=%d..%d память %d→%d МБ (пик %d), ms_avg %.2f→%.2f, ресурсов %d→%d%s"%("SOAK_OK " if ok else "SOAK_FAIL",f.split("/")[-1],a[0],b[0],a[2],b[2],peak,ma,mb,a[4],b[4],warn))
    bad+=0 if ok else 1
print("SOAK_ALL_OK" if bad==0 else "SOAK_FAILED %d"%bad)
sys.exit(1 if bad else 0)
PY
