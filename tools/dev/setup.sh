#!/bin/bash
# Prepara l'ambiente di sviluppo in un container nuovo: Godot 4.7.2 (Linux) e i modelli di
# esportazione Web (servono a tools/deploy_web.sh). Uso: bash tools/dev/setup.sh
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
B="$ROOT/tools/dev/.godot_bin"; mkdir -p "$B"; cd "$B"
REL=https://github.com/godotengine/godot/releases/download/4.7.2-stable
if [ ! -x Godot_v4.7.2-stable_linux.x86_64 ]; then
  curl -sSL -o g.zip "$REL/Godot_v4.7.2-stable_linux.x86_64.zip" && unzip -oq g.zip && rm g.zip
  chmod +x Godot_v4.7.2-stable_linux.x86_64
fi
T="$HOME/.local/share/godot/export_templates/4.7.2.stable"
if [ ! -f "$T/web_nothreads_release.zip" ]; then
  mkdir -p "$T"
  curl -sSL -o tpl.tpz "$REL/Godot_v4.7.2-stable_export_templates.tpz"
  unzip -oq tpl.tpz "templates/web_nothreads_*" "templates/version.txt" -d tpl
  cp tpl/templates/* "$T/" && rm -rf tpl tpl.tpz
fi
command -v xvfb-run >/dev/null || echo "ATTENZIONE: manca xvfb-run (apt-get install -y xvfb) per gli screenshot"
echo "Pronto: $B/Godot_v4.7.2-stable_linux.x86_64"
