"""Riempie le traduzioni inglesi mancanti. Uso (dalla radice del progetto):
  python3 i18n/extract.py && python3 i18n/extract.py --check   # elenca le stringhe senza inglese
  python3 tools/dev/fill_i18n.py it.txt en.txt                 # una frase per riga, stesso ordine
"""
import csv, sys
it = [x for x in open(sys.argv[1], encoding='utf-8').read().split('\n') if x]
en = [x for x in open(sys.argv[2], encoding='utf-8').read().split('\n') if x]
assert len(it) == len(en), (len(it), len(en))
P = 'i18n/duat_translations.csv'
rows = list(csv.reader(open(P, encoding='utf-8')))
m = dict(zip(it, en)); n = 0
for r in rows[1:]:
    if r[0] in m and not r[2]:
        r[2] = m[r[0]]; n += 1
csv.writer(open(P, 'w', encoding='utf-8', newline=''), lineterminator='\n').writerows(rows)
print(n, "tradotte")
