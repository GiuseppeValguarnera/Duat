#!/bin/bash
# Controllo d'avvio (la verifica dopo ogni modifica, vedi CLAUDE.md): importa il progetto e avvia
# la Sala e una partita senza grafica per qualche secondo, con gli avvisi di GDScript trattati come
# errori (override.cfg). Niente screenshot, niente bot.
# Uso: bash tools/dev/check.sh        → stampa "OK" oppure gli errori, ed esce con 1 se ce ne sono
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEV="$ROOT/tools/dev"
G="${DUAT_GODOT:-$DEV/.godot_bin/Godot_v4.7.2-stable_linux.x86_64}"
OUT="${TMPDIR:-/tmp}/duat_check"; mkdir -p "$OUT"
HOMEDIR="$OUT/home"; rm -rf "$HOMEDIR"; mkdir -p "$HOMEDIR"
cd "$ROOT"
cleanup() { rm -f override.cfg; }
trap cleanup EXIT
trap 'exit 143' TERM INT
cp "$DEV/override.cfg" .
HOME="$HOMEDIR" timeout 120 "$G" --headless --path . --import > "$OUT/import.txt" 2>&1
: > "$OUT/run.txt"
for scene in res://scenes/hub.tscn res://scenes/armory.tscn res://scenes/game.tscn; do
  DUAT_NOTUT=1 HOME="$HOMEDIR" timeout 60 "$G" --headless --path . --quit-after 600 "$scene" >> "$OUT/run.txt" 2>&1
done
# Sokar: stanze 1, 4 e 8 (terreno, trappole, nemici del deserto)
for room in 1 4 8; do   # (sotto: anche il Banco di Apopi)
  DUAT_NOTUT=1 DUAT_REGION2=1 DUAT_START_REGION=2 DUAT_START_ROOM=$room HOME="$HOMEDIR" timeout 60 "$G" --headless --path . --quit-after 900 res://scenes/game.tscn >> "$OUT/run.txt" 2>&1
done
# il Banco di Apopi (terza regione): stanze 1, 4, 8, guardiano (5) e boss (11)
for room in 1 4 8 5 11; do
  DUAT_NOTUT=1 DUAT_START_REGION=3 DUAT_START_ROOM=$room HOME="$HOMEDIR" timeout 60 "$G" --headless --path . --quit-after 900 res://scenes/game.tscn >> "$OUT/run.txt" 2>&1
done
# arco e flagello: colpi, attacco caricato e in scatto con tutti i loro doni (tools/dev/weaponsmoke.gd)
for w in arco flagello khopesh; do
  DUAT_NOTUT=1 DUAT_START_ROOM=2 DUAT_WEAPON=$w HOME="$HOMEDIR" timeout 90 "$G" --headless --path . --script res://tools/dev/weaponsmoke.gd >> "$OUT/run.txt" 2>&1
done
# grazie degli dèi e Oasi: Voce degli Dèi, Collana, Seconda Barca, la barca di Mahaf (tools/dev/favorsmoke.gd)
DUAT_NOTUT=1 DUAT_START_ROOM=2 HOME="$HOMEDIR" timeout 90 "$G" --headless --path . --script res://tools/dev/favorsmoke.gd >> "$OUT/run.txt" 2>&1
# finestra a carte: frase a pagine, carte nello schermo, doppio tocco (tools/dev/choicesmoke.gd)
DUAT_NOTUT=1 HOME="$HOMEDIR" timeout 60 "$G" --headless --path . --script res://tools/dev/choicesmoke.gd -- --mobile >> "$OUT/run.txt" 2>&1
# prima di boss e mini boss: porte solo verso stanze senza nemici (tools/dev/quietsmoke.gd)
DUAT_NOTUT=1 HOME="$HOMEDIR" timeout 60 "$G" --headless --fixed-fps 60 --path . --script res://tools/dev/quietsmoke.gd >> "$OUT/run.txt" 2>&1
# mira assistita della mischia: quattro scenari sulla funzione di bersaglio (tools/dev/aimsmoke.gd)
DUAT_NOTUT=1 HOME="$HOMEDIR" timeout 60 "$G" --headless --fixed-fps 60 --path . --script res://tools/dev/aimsmoke.gd >> "$OUT/run.txt" 2>&1
# la prova della Sfinge: ondate, guardiani, enigmi, doni, premi, classifica (tools/dev/sphinxsmoke.gd)
DUAT_NOTUT=1 DUAT_SPHINX_DAY=20400 HOME="$HOMEDIR" timeout 150 "$G" --headless --fixed-fps 60 --path . --script res://tools/dev/sphinxsmoke.gd >> "$OUT/run.txt" 2>&1
# Aker: tutte le mosse, la divisione, la tenaglia, la furia, la vittoria (tools/dev/akersmoke.gd)
DUAT_NOTUT=1 DUAT_REGION2=1 HOME="$HOMEDIR" timeout 120 "$G" --headless --fixed-fps 60 --path . --script res://tools/dev/akersmoke.gd >> "$OUT/run.txt" 2>&1
ERR=$(cat "$OUT/import.txt" "$OUT/run.txt" | grep -E "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script" -A1 | grep -v "^--$" | sort | uniq -c)
if [ -n "$ERR" ]; then
  echo "$ERR" | head -20
  exit 1
fi
echo "OK"
