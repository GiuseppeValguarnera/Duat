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
for room in 1 4 8; do
  DUAT_NOTUT=1 DUAT_REGION2=1 DUAT_START_REGION=2 DUAT_START_ROOM=$room HOME="$HOMEDIR" timeout 60 "$G" --headless --path . --quit-after 900 res://scenes/game.tscn >> "$OUT/run.txt" 2>&1
done
ERR=$(cat "$OUT/import.txt" "$OUT/run.txt" | grep -E "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script" -A1 | grep -v "^--$" | sort | uniq -c)
if [ -n "$ERR" ]; then
  echo "$ERR" | head -20
  exit 1
fi
echo "OK"
