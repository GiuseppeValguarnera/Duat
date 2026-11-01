#!/bin/bash
# Prova "severa" con screenshot: avvia il gioco con uno script di prova (tools/dev/shots/*.gd) come
# autoload e con gli avvisi di GDScript trattati come errori (override.cfg).
# Uso: tools/dev/shot.sh NOME_SCRIPT [LARGHEZZA ALTEZZA] [scena] [mobile]
#   es.  tools/dev/shot.sh piumashot
#        tools/dev/shot.sh rebshot 1280 720 res://scenes/game.tscn
#        DUAT_REGION2=1 tools/dev/shot.sh sokshot 1280 720 res://scenes/game.tscn
# Le immagini finiscono in $DUAT_SHOTS (default /tmp/duat_shots), il log in $DUAT_SHOTS/NOME.txt.
# Stampa le righe "SCRIPT ERROR" (nessuna riga = tutto ok).
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEV="$ROOT/tools/dev"
G="${DUAT_GODOT:-$DEV/.godot_bin/Godot_v4.7.2-stable_linux.x86_64}"
export DUAT_SHOTS="${DUAT_SHOTS:-/tmp/duat_shots}"
export DUAT_LANG="${DUAT_LANG:-it}"
NAME="$1"; W="${2:-1280}"; H="${3:-720}"; SCENE="${4:-}"; MOB="${5:-}"
mkdir -p "$DUAT_SHOTS"
HOMEDIR="$DUAT_SHOTS/home"; rm -rf "$HOMEDIR"; mkdir -p "$HOMEDIR"
cd "$ROOT"
sed -i '/^AutoTest=/d' project.godot          # resti di una prova interrotta: mai nella copia
cp project.godot "$DUAT_SHOTS/project.bak"
# la pulizia avviene anche se la prova viene interrotta (timeout, Ctrl+C): prima la riga AutoTest
# restava in project.godot e finiva nei commit
cleanup() {
  cp "$DUAT_SHOTS/project.bak" project.godot 2>/dev/null
  sed -i '/^AutoTest=/d' project.godot
  rm -f autotest.gd autotest.gd.uid override.cfg
}
trap cleanup EXIT
trap 'exit 143' TERM INT
cp "$DEV/shots/$NAME.gd" autotest.gd
cp "$DEV/override.cfg" .
sed -i 's#^Run="\*res://scripts/run.gd"#&\nAutoTest="*res://autotest.gd"#' project.godot
HOME="$HOMEDIR" timeout 90 "$G" --headless --path . --import > /dev/null 2>&1
EXTRA=""; [ "$MOB" = mobile ] && EXTRA="-- --mobile"
DUAT_NOTUT=1 HOME="$HOMEDIR" timeout 150 xvfb-run -a -s "-screen 0 $((W+50))x$((H+50))x24" "$G" --path . --rendering-driver opengl3 --resolution ${W}x${H} $SCENE $EXTRA > "$DUAT_SHOTS/$NAME.txt" 2>&1
grep -E "SCRIPT ERROR|Parse Error" "$DUAT_SHOTS/$NAME.txt" | sort | uniq -c | head -5
