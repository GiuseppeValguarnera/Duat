#!/bin/bash
# Partite dei bot (tools/playtest/bot.gd) in parallelo, su una copia del progetto.
# Uso: printf "nome persona seed [VAR=val ...]\n..." | tools/dev/bots.sh OUT.jsonl [PROCESSI]
# I risultati (una riga JSON per partita) in $DUAT_BOTS/OUT.jsonl, i log in $DUAT_BOTS/logs/.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export G="${DUAT_GODOT:-$ROOT/tools/dev/.godot_bin/Godot_v4.7.2-stable_linux.x86_64}"
export T="${DUAT_BOTS:-/tmp/duat_bots}"; export OUT="$1"; P="${2:-2}"
export DUAT_LANG="${DUAT_LANG:-it}"
mkdir -p "$T/logs" "$T/homes"
rm -rf "$T/work" && cp -r "$ROOT" "$T/work" && rm -rf "$T/work/.git" "$T/work/override.cfg" "$T/work/tools" "$T/work/i18n" "$T/work/build"
cp "$ROOT/tools/playtest/bot.gd" "$T/work/bot.gd"
sed -i 's#^Touch="\*res://scripts/touch_controls.gd"#&\nAutoTest="*res://bot.gd"#' "$T/work/project.godot"
(cd "$T/work" && HOME="$T/homes/imp" timeout 120 "$G" --headless --path . --import > "$T/import.txt" 2>&1)
grep "SCRIPT ERROR" "$T/import.txt" | head -3
rm -f "$T/$OUT"
one() {
  name=$1; persona=$2; sd=$3; shift 3
  H="$T/homes/${name}_${persona}_$sd"; rm -rf "$H"; mkdir -p "$H/.local/share/godot/app_userdata/Duat"
  [ -n "$SAVE" ] && cp "$SAVE" "$H/.local/share/godot/app_userdata/Duat/duat_save.cfg"
  (cd "$T/work" && env HOME="$H" DUAT_EXP=$name DUAT_PERSONA=$persona DUAT_SEED=$sd DUAT_OUT="$T/$OUT" "$@" timeout 600 "$G" --headless --fixed-fps 60 --path . res://scenes/game.tscn > "$T/logs/${name}_${persona}_$sd.txt" 2>&1)
  rm -rf "$H"
}
export -f one
xargs -P "$P" -L 1 bash -c 'one "$@"' _
