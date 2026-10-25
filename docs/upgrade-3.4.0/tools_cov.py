#!/usr/bin/env python3
"""Cobertura de traducciones (3.4.0, 7L).
Uso: python3 docs/upgrade-3.4.0/tools_cov.py [--md notes/F_ru_coverage.md] [--cand]
1) Extrae literales de L.t("..")/TL.t/tr("..") en scripts/**/*.gd y comprueba que la clave
   exista en los 10 idiomas (+ lang_features / lang_second_move) y que conserve los %s/%d.
2) Comprueba que el valor ru no coincida con la clave (salvo numeros / simbolos).
3) --cand: literales "tipo texto" de archivos que usan L.t que no estan en ningun idioma
   (candidatos a cadenas que pasan por L.t(String(x)) en tablas de datos / listas)."""
import json, re, sys, glob, os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
LANGS = ["en", "fr", "it", "ja", "pt_BR", "pt_PT", "ru", "vi", "zh_CN", "zh_HK"]
STR = r'"((?:[^"\\\n]|\\.)*)"'
RX1 = re.compile(r'\b(?:\w+\.)*(?:L|TL|LG)\.t\(\s*' + STR)
RX2 = re.compile(r'(?<![A-Za-z0-9_.])tr\(\s*' + STR)
ESC = {"n": "\n", "t": "\t", '"': '"', "\\": "\\", "'": "'"}


def unesc(s):
    return re.sub(r'\\(.)', lambda m: ESC.get(m.group(1), m.group(0)), s)


def load(code):
    d = json.load(open(f"{ROOT}/data/lang_{code}.json", encoding="utf-8"))
    for fp in ("lang_features", "lang_second_move"):
        r = json.load(open(f"{ROOT}/data/{fp}.json", encoding="utf-8"))
        d.update(r.get(code, {}))
    return d


def gd_files():
    return sorted(glob.glob(f"{ROOT}/scripts/**/*.gd", recursive=True))


def extract():
    keys = {}
    for p in gd_files():
        rel = os.path.relpath(p, ROOT)
        for i, line in enumerate(open(p, encoding="utf-8"), 1):
            if line.lstrip().startswith("#"):
                continue
            for rx in (RX1, RX2):
                for m in rx.finditer(line):
                    keys.setdefault(unesc(m.group(1)), []).append(f"{rel}:{i}")
    return keys


def same_ok(k):
    if re.match(r'^[\W\d_]*$', k):
        return True
    rest = re.sub(r'%[-+0-9.]*[sdfx%]', '', k)
    return not re.search(r'[A-Za-zÀ-ÿ]{3,}', rest)


def fmt(s):
    return sorted(re.findall(r'%[-+0-9.]*[sdfx%]', s))


def main():
    md = sys.argv[sys.argv.index("--md") + 1] if "--md" in sys.argv else None
    keys = extract()
    langs = {c: load(c) for c in LANGS}
    ru = langs["ru"]
    missing = {c: [k for k in keys if k not in langs[c]] for c in LANGS}
    same = [k for k in keys if k in ru and ru[k] == k and not same_ok(k)]
    badfmt = {c: [k for k in keys if k in langs[c] and fmt(k) != fmt(langs[c][k])] for c in LANGS}
    out = ["# F_ru_coverage (generado por docs/upgrade-3.4.0/tools_cov.py)\n", f"Claves L.t/tr literales: {len(keys)}\n"]
    for c in LANGS:
        out.append(f"- {c}: faltan {len(missing[c])}, formato distinto {len(badfmt[c])}")
    out.append(f"\n## ru sin traducir (valor == clave): {len(same)}")
    for k in same:
        out.append(f"- `{k}` ({keys[k][0]})")
    for c in LANGS:
        if missing[c]:
            out.append(f"\n## faltan en {c} ({len(missing[c])})")
            for k in missing[c][:80]:
                out.append(f"- `{k}` ({keys[k][0]})")
        if badfmt[c]:
            out.append(f"\n## formato distinto en {c}")
            for k in badfmt[c]:
                out.append(f"- `{k}`")
    ncand = 0
    if "--cand" in sys.argv:
        known = set()
        for c in LANGS:
            known |= set(langs[c])
        known |= set(json.load(open(f"{ROOT}/data/lang_es_419.json", encoding="utf-8")))
        cand = {}
        lit = re.compile(STR)
        for p in gd_files():
            src = open(p, encoding="utf-8").read()
            for i, line in enumerate(src.split("\n"), 1):
                if line.lstrip().startswith("#"):
                    continue
                for m in lit.finditer(line):
                    s = unesc(m.group(1))
                    if s in known or s in keys or len(s) < 4:
                        continue
                    if re.search(r'res://|user://|\.(png|json|gd|tscn|ogg|txt)\b|^[a-z_0-9:/.\-\[\]]+$', s):
                        continue
                    if not re.search(r'[ ¡¿áéíóúñÁÉÍÓÚÑ]', s):
                        continue
                    cand.setdefault(s, f"{os.path.relpath(p, ROOT)}:{i}")
        ncand = len(cand)
        out.append(f"\n## candidatos sin clave en ningun idioma ({ncand})")
        for s, w in cand.items():
            out.append(f"- `{s}` ({w})")
    text = "\n".join(out) + "\n"
    if md:
        path = md if os.path.isabs(md) else os.path.join(ROOT, "docs/upgrade-3.4.0", md)
        open(path, "w", encoding="utf-8").write(text)
    else:
        print(text)
    mt = sum(len(v) for v in missing.values())
    print(f"keys={len(keys)} missing_total={mt} ru_same={len(same)} badfmt={sum(len(v) for v in badfmt.values())} cand={ncand}")


main()
