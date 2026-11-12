#!/bin/bash
# GUARDARE una partita del bot: come bots.sh ma con la grafica (xvfb) e uno screenshot ogni pochi secondi.
# Uso: tools/dev/watch.sh NOME persona seed [VAR=val ...]   → immagini in /tmp/duat_watch/NOME/, risultato in NOME.jsonl
# Poi: python3 tools/dev/sheet.py /tmp/duat_watch/NOME  (fogli di contatto 3x3 da guardare)
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
G="${DUAT_GODOT:-$ROOT/tools/dev/.godot_bin/Godot_v4.7.2-stable_linux.x86_64}"
T=/tmp/duat_watch; NAME=$1; PERSONA=$2; SD=$3; shift 3
W="${DUAT_W:-1280}"; HH="${DUAT_H:-720}"
mkdir -p "$T/$NAME" "$T/homes"; rm -f "$T/$NAME"/*.png "$T/$NAME.jsonl"
WK="$T/work_$NAME"
rm -rf "$WK" && cp -r "$ROOT" "$WK" && rm -rf "$WK/.git" "$WK/override.cfg" "$WK/tools" "$WK/i18n" "$WK/build"
cp "$ROOT/tools/playtest/bot.gd" "$WK/bot.gd"; cp "$ROOT/tools/playtest/snap.gd" "$WK/snap.gd"
sed -i 's#^Touch="\*res://scripts/touch_controls.gd"#&\nAutoTest="*res://bot.gd"\nSnap="*res://snap.gd"#' "$WK/project.godot"
H="$T/homes/$NAME"; rm -rf "$H"; mkdir -p "$H/.local/share/godot/app_userdata/Duat"
[ -n "$SAVE" ] && cp "$SAVE" "$H/.local/share/godot/app_userdata/Duat/duat_save.cfg"
(cd "$WK" && HOME="$H" timeout 120 "$G" --headless --path . --import > "$T/$NAME.import.txt" 2>&1)
(cd "$WK" && env HOME="$H" DUAT_LANG="${DUAT_LANG:-it}" DUAT_NOTUT=1 DUAT_EXP=$NAME DUAT_PERSONA=$PERSONA DUAT_SEED=$SD DUAT_OUT="$T/$NAME.jsonl" DUAT_SNAP_DIR="$T/$NAME" "$@" timeout "${DUAT_TIMEOUT:-420}" xvfb-run -a -s "-screen 0 $((W+50))x$((HH+50))x24" "$G" --path . --rendering-driver opengl3 --resolution ${W}x${HH} --fixed-fps 60 res://scenes/game.tscn > "$T/$NAME.txt" 2>&1)
rm -rf "$WK" "$H"
ls "$T/$NAME" | wc -l; cat "$T/$NAME.jsonl" 2>/dev/null | head -c 600
