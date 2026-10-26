#!/bin/bash
# Esporta la versione web (giocabile da telefono) e la pubblica sul ramo gh-pages.
# Uso: tools/deploy_web.sh /percorso/di/Godot_v4.7.2
# Serve il pacchetto "Web" dei modelli di esportazione di Godot 4.7.2 (Editor > Gestisci modelli di esportazione).
# Il gioco poi è su https://giuseppevalguarnera.github.io/Duat/
set -e
GODOT="${1:?indica il percorso di Godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/web"
rm -rf "$OUT" && mkdir -p "$OUT"
"$GODOT" --headless --path "$ROOT" --import > /dev/null 2>&1 || true
"$GODOT" --headless --path "$ROOT" --export-release "Web" "$OUT/index.html"
touch "$OUT/.nojekyll"
# numero di versione: nella pagina del gioco e in version.txt (il pulsante "Aggiorna il gioco" li confronta)
BUILD="$(git -C "$ROOT" rev-parse --short HEAD)-$(date +%Y%m%d%H%M%S)"
sed -i "s/__DUAT_BUILD__/$BUILD/" "$OUT/index.html"
sed -i "s/__DUAT_VERSION__/$(cat "$ROOT/VERSION")/; s/__DUAT_CHANNEL__/dev/; s#__DUAT_VERSION_URL__#version.txt#" "$OUT/index.html"
echo "$BUILD" > "$OUT/version.txt"
# l'ultima versione stabile (quella su itch.io): la legge la versione stabile per sapere se c'è un aggiornamento
mkdir -p "$OUT/stable"
cp "$ROOT/web/stable_version.txt" "$OUT/stable/version.txt"
TMP="$(mktemp -d)"
cp -r "$OUT/." "$TMP/"
cd "$TMP"
git init -q -b gh-pages
git add -A
git commit -qm "Versione web $(date +%Y-%m-%d\ %H:%M)"
git push -qf "$(git -C "$ROOT" remote get-url origin)" gh-pages
rm -rf "$TMP"
echo "Pubblicato la versione $BUILD. Tra un minuto è su https://giuseppevalguarnera.github.io/Duat/"
