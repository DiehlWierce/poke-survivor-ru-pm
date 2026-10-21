#!/usr/bin/env python3
"""Сводка по логам tools/mode_matrix.sh: python3 tools/mode_matrix_report.py OUT_DIR [OUT_DIR2 ...]
По каждой паре режим×мета: прогонов, OK, средние боссов/уровень/убийства/время, рывки >100 мс, виды проблем."""
import json, sys, os, re, collections

for out in sys.argv[1:]:
    agg = collections.defaultdict(lambda: collections.Counter())
    kinds = collections.defaultdict(collections.Counter)
    for fn in sorted(os.listdir(out)):
        if not fn.endswith('.log'):
            continue
        txt = open(os.path.join(out, fn), errors='replace').read()
        m = re.search(r'^MATRIX_RESULT (.*)$', txt, re.M)
        mode, dex, seed, meta = re.match(r'(\w+?)_(\d+)_s(\d+)_(\w+)\.log', fn).groups()
        a = agg[(mode, meta)]
        a['runs'] += 1
        errs = [l for l in txt.splitlines() if re.search(r'SCRIPT ERROR|^ERROR:|USER ERROR', l)
                and not re.search(r'resources still in use|ret != noErr|get_system_ca|RID allocations', l)]
        if errs:
            kinds[(mode, meta)]['script_error'] += 1
        if not m:
            kinds[(mode, meta)]['no_result'] += 1
            continue
        r = json.loads(m.group(1))
        if r['ok'] and not errs:
            a['ok'] += 1
        for k in ('bosses_seen', 'level', 'kills', 'run_time', 'hitches', 'cards', 'rift_entered', 'tw_floor', 'blank_frames'):
            a[k] += r.get(k, 0)
        a['worst'] = max(a['worst'], r.get('worst_ms', 0))
        a['biomes'] += len(r.get('biomes', []))
        for k, v in r.get('issue_kinds', {}).items():
            kinds[(mode, meta)][k] += 1
    print(f'== {out}')
    print(f'{"mode":7} {"meta":5} {"ok":>6} {"boss":>5} {"lvl":>5} {"kills":>6} {"time":>5} {"biom":>4} {"rift":>4} {"floor":>5} {"hitch":>5} {"worst":>6} {"blank":>5}  issues')
    for (mode, meta), a in sorted(agg.items()):
        n = max(1, a['runs'])
        print(f'{mode:7} {meta:5} {a["ok"]:>2}/{a["runs"]:<3} {a["bosses_seen"]/n:5.1f} {a["level"]/n:5.1f} {a["kills"]/n:6.0f} {a["run_time"]/n:5.0f} {a["biomes"]/n:4.1f} {a["rift_entered"]/n:4.1f} {a["tw_floor"]/n:5.1f} {a["hitches"]:>5} {a["worst"]:6.0f} {a["blank_frames"]:>5}  {dict(kinds[(mode, meta)])}')
