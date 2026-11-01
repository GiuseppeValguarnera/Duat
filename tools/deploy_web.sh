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
# File con la versione nel nome: il browser (e la cache di GitHub Pages, 10 minuti) non può più
# dare il gioco vecchio dentro la pagina nuova. Prima "Aggiorna il gioco" riapriva la versione
# vecchia: il service worker di Godot serviva index.js, index.wasm e index.pck dalla sua cache.
for f in index.js index.wasm index.pck index.audio.worklet.js index.audio.position.worklet.js; do
  if [ -f "$OUT/$f" ]; then mv "$OUT/$f" "$OUT/index-$BUILD.${f#index.}"; fi
done
sed -i "s/index\.\(js\|wasm\|pck\|audio\)/index-$BUILD.\1/g; s/\"executable\":\"index\"/\"executable\":\"index-$BUILD\"/" "$OUT/index.html"
# niente service worker: Godot non lo registra più, e quello vecchio (rimasto sui telefoni) viene
# sostituito da uno che svuota le cache, si cancella e ricarica la pagina
sed -i 's/"serviceWorker":"[^"]*"/"serviceWorker":""/' "$OUT/index.html"
cp "$ROOT/web/service_worker_reset.js" "$OUT/index.service.worker.js"
grep -q "index-$BUILD.wasm" "$OUT/index.html" || { echo "ERRORE: i nomi dei file con la versione non sono nella pagina"; exit 1; }
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
