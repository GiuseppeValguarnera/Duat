#!/usr/bin/env python3
"""Estrae le stringhe visibili al giocatore (italiano) da scripts/*.gd e scenes/*.tscn
e aggiorna i18n/duat_translations.csv (formato CSV di Godot: keys,it,en).

Uso:  python3 i18n/extract.py            aggiorna il CSV (le traduzioni esistenti restano)
      python3 i18n/extract.py --check    elenca solo le chiavi senza traduzione inglese
Le chiavi sono la stringa italiana esatta, così nel codice basta scrivere tr("...").
"""
import csv, glob, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CSV_PATH = os.path.join(ROOT, "i18n", "duat_translations.csv")

# stringhe GDScript tra doppi apici (con escape)
STR_RE = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
# chiavi di dizionario che contengono testo visibile
VISIBLE_KEYS = {"name", "desc", "cost", "title", "text", "lore", "lines", "short", "the"}
# parole che indicano un identificatore e non un testo
SKIP_EXACT = set()
# parole singole minuscole che però si vedono a schermo (non riconoscibili in automatico)
EXTRA_VISIBLE = {"pronto", "nessuno", "comprato", "pesante", "doppio", "bilancia", "sì", "no", "spenta", "colpo", "combo"}
ITALIAN_HINT = re.compile(r"[àèéìòùÀÈÉÌÒÙ]|\b(il|lo|la|i|gli|le|di|del|della|dei|un|una|che|non|per|con|sei|ti|tu|io|è|ogni|sono|più|nel|nella|alla|dal|anche|ma|se|come|al|ai|da|in)\b", re.I)


def looks_visible(s: str) -> bool:
    if s in EXTRA_VISIBLE:
        return True
    if s in ("Label", "Button", "HSlider") or s.startswith(("window.", "(window")):   # nomi tecnici, codice della pagina web
        return False
    if not s.strip():
        return False
    if s.startswith(("res://", "user://", "#")):
        return False
    if re.fullmatch(r"[a-z0-9_./:%-]+", s):          # id, azioni, percorsi, stati
        return False
    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", s) and not s[0].isupper():
        return False
    if re.fullmatch(r"[%0-9.dsf ·+\-x×:/()\[\]]+", s):   # solo segnaposto/numeri
        return False
    if re.fullmatch(r"[A-Z][a-zA-Z]+(Area|Shape|Body|Box|Label)?", s) and " " not in s and s in NODE_NAMES:
        return False
    # deve contenere almeno una lettera e (spazio o lettera maiuscola iniziale)
    if not re.search(r"[A-Za-zÀ-ÿ]", s):
        return False
    if " " not in s and not s[0].isupper():
        return False
    return True


NODE_NAMES = {"World", "UI", "Hud", "Prompt", "Help", "Talk", "Box", "Name", "Text", "Message", "Banner",
              "Reticle", "Camera", "Body", "Hurtbox", "Shape", "ContactArea", "Player", "Game", "Hub",
              "Audio", "Mummy", "Scarab", "Priest", "Ammit", "Serpent", "Scorpion", "Cobra"}

# righe di codice da ignorare (stringhe non visibili)
SKIP_LINE = re.compile(r"(preload\(|load\(|get_node|\$|is_action|action_press|action_release|_keys\(|_button\(|"
                       r"Sfx\.play|play_at\(|Music\.play|add_to_group|is_in_group|get_nodes_in_group|"
                       r"get_first_node_in_group|has_method|has_signal|connect\(|emit\(|change_scene|"
                       r"set_value\(|get_value\(|theme_override|add_theme_|get_environment|"
                       r"@export_group|\.has\(\"|Weights\.rank\(|Run\.has\(|Run\.val\(|Run\.chap\(|Run\.cursed\(|"
                       r"Meta\.dialogue_seen|match |state ==|state = |kind ==|== \"|!= \"|in \[\")")


def unescape(s: str) -> str:
    """La stringa come la vede il gioco: \\n diventa un vero a capo, \\" diventa ", ecc.
    Le chiavi del CSV sono in questa forma, perché tr() riceve la stringa già interpretata."""
    out, i = [], 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            n = s[i + 1]
            out.append({"n": "\n", "t": "\t", '"': '"', "\\": "\\", "'": "'"}.get(n, "\\" + n))
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def scan():
    found = []          # (stringa, file:riga) in ordine di apparizione
    seen = set()
    files = sorted(glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True)) + sorted(glob.glob(os.path.join(ROOT, "scenes", "*.tscn")))
    for path in files:
        rel = os.path.relpath(path, ROOT)
        is_scene = path.endswith(".tscn")
        for n, line in enumerate(open(path, encoding="utf-8"), 1):
            stripped = line.strip()
            if stripped.startswith("#") or stripped.startswith("##"):
                continue
            if is_scene:
                m = re.match(r'\s*text = "((?:[^"\\]|\\.)*)"', line)
                cands = [m.group(1)] if m else []
            else:
                code = line.split(" ## ")[0]
                cands = []
                for m in STR_RE.finditer(code):
                    s = m.group(1)
                    before = code[:m.start()]
                    # avvolta in Lang.t(): è testo visibile per definizione
                    if before.endswith("Lang.t("):
                        cands.append(s)
                        continue
                    # chiave di dizionario visibile: "name": "..."
                    km = re.search(r'"(\w+)":\s*$', before)
                    if km and km.group(1) in VISIBLE_KEYS:
                        cands.append(s)
                        continue
                    if km:            # altre chiavi (es. "god": "ra") non sono testo
                        continue
                    # la stringa stessa usata come chiave di dizionario: salta
                    after = code[m.end():m.end() + 2]
                    if after.startswith(":") and not re.search(r"\w$", before.rstrip()):
                        continue
                    if s == "bilancia" and "lvl" not in code:
                        continue
                    if SKIP_LINE.search(code) and not ITALIAN_HINT.search(s) and s not in EXTRA_VISIBLE:
                        continue
                    cands.append(s)
            for s in cands:
                if not looks_visible(s):
                    continue
                if s not in EXTRA_VISIBLE and not (ITALIAN_HINT.search(s) or " " in s or s[:1].isupper()):
                    continue
                s = unescape(s)
                if s in seen:
                    continue
                seen.add(s)
                found.append((s, f"{rel}:{n}"))
    return found


def load_csv():
    rows = {}
    if os.path.exists(CSV_PATH):
        with open(CSV_PATH, encoding="utf-8", newline="") as f:
            for r in csv.DictReader(f):
                rows[r["keys"]] = r
    return rows


def main():
    found = scan()
    old = load_csv()
    if "--check" in sys.argv:
        missing = [s for s, _ in found if not old.get(s, {}).get("en")]
        for s in missing:
            print(s)
        print(f"\n{len(missing)} stringhe senza inglese su {len(found)}")
        return
    keys = [s for s, _ in found]
    gone = [k for k in old if k not in set(keys)]
    with open(CSV_PATH, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
        w.writerow(["keys", "it", "en"])
        for s in keys:
            w.writerow([s, s, old.get(s, {}).get("en", "")])
        # le chiavi sparite dal codice restano in fondo (potrebbero essere state solo spostate)
        for k in gone:
            w.writerow([k, k, old[k].get("en", "")])
    missing = [s for s in keys if not old.get(s, {}).get("en")]
    print(f"{len(keys)} stringhe nel codice, {len(missing)} senza traduzione inglese, {len(gone)} non più trovate (tenute in fondo)")
    for s in missing[:50]:
        print("  manca:", s)


if __name__ == "__main__":
    main()
