#!/usr/bin/env python3
"""Controlla che ogni carattere usato nei testi del gioco esista nei caratteri del gioco.
Sul PC un simbolo mancante viene preso da un font di sistema; nel browser del telefono no,
e compare un quadratino. Uso: python3 tools/check_glyphs.py (esce con 1 se manca qualcosa)."""
import collections, glob, re, sys
from fontTools.ttLib import TTFont

FONTS = ["aref-ruqaa", "aref-ruqaa-bold"]
cmaps = {f: set(TTFont(f"assets/fonts/{f}.woff2").getBestCmap()) for f in FONTS}
where = collections.defaultdict(set)
for p in glob.glob("scripts/*.gd"):
    for i, line in enumerate(open(p, encoding="utf-8"), 1):
        code = line.split("#", 1)[0] if line.lstrip().startswith("#") is False else ""
        for m in re.finditer(r'"(?:[^"\\]|\\.)*"', code):
            for ch in m.group(0):
                if ord(ch) > 127:
                    where[ch].add(f"{p.split('/')[-1]}:{i}")
bad = 0
for ch, w in sorted(where.items()):
    missing = [f for f in FONTS if ord(ch) not in cmaps[f]]
    if missing:
        bad += 1
        print(f"{ch!r} U+{ord(ch):04X} manca in {', '.join(missing)}: {', '.join(sorted(w)[:5])}")
print("tutto a posto" if not bad else f"{bad} caratteri mancanti")
sys.exit(1 if bad else 0)
