#!/bin/bash
# Pubblica una versione STABILE (la prova pubblica su itch.io). Diversa da deploy_web.sh, che
# pubblica a ogni modifica la versione di SVILUPPO sul sito GitHub (per te e gli amici fidati).
#
# Uso: tools/release.sh /percorso/di/Godot 0.2.0 "Novità in una riga; altra novità"
#
# Cosa fa:
#  1. scrive il numero nel file VERSION e aggiunge le novità in cima a CHANGELOG.md;
#  2. esporta il gioco web con il canale "stable" in build/stable e lo comprime in
#     build/duat-web-VERSIONE.zip (è lo zip da caricare su itch.io come gioco HTML);
#  3. se c'è butler (lo strumento di itch) e la variabile BUTLER_API_KEY, lo carica da solo su
#     ITCH_TARGET (per esempio "giuseppevalguarnera/duat:html5"); altrimenti lo carichi tu a mano;
#  4. aggiorna web/stable_version.txt (la versione stabile controlla lì se ce n'è una nuova),
#     fa il commit, mette l'etichetta git vVERSIONE e ripubblica il sito di sviluppo.
set -e
GODOT="${1:?indica il percorso di Godot}"
VER="${2:?indica il numero di versione, per esempio 0.2.0}"
NOTES="${3:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/stable"
cd "$ROOT"
echo "$VER" > VERSION
# il registro delle novità (le righe separate da ";")
{
	echo "## $VER · $(date +%d/%m/%Y)"
	echo
	IFS=';' read -ra items <<< "$NOTES"
	for it in "${items[@]}"; do
		it="$(echo "$it" | sed 's/^ *//; s/ *$//')"
		[ -n "$it" ] && echo "- $it"
	done
	echo
	[ -f CHANGELOG.md ] && cat CHANGELOG.md
} > CHANGELOG.new && mv CHANGELOG.new CHANGELOG.md
rm -rf "$OUT" && mkdir -p "$OUT"
"$GODOT" --headless --path "$ROOT" --import > /dev/null 2>&1 || true
"$GODOT" --headless --path "$ROOT" --export-release "Web" "$OUT/index.html"
BUILD="$(git rev-parse --short HEAD)-$(date +%Y%m%d%H%M%S)"
sed -i "s/__DUAT_BUILD__/$BUILD/; s/__DUAT_VERSION__/$VER/; s/__DUAT_CHANNEL__/stable/; s#__DUAT_VERSION_URL__#https://giuseppevalguarnera.github.io/Duat/stable/version.txt#" "$OUT/index.html"
ZIP="$ROOT/build/duat-web-$VER.zip"
rm -f "$ZIP"
(cd "$OUT" && zip -qr "$ZIP" .)
echo "$BUILD" > web/stable_version.txt
if command -v butler > /dev/null && [ -n "$BUTLER_API_KEY" ] && [ -n "$ITCH_TARGET" ]; then
	butler push "$OUT" "$ITCH_TARGET" --userversion "$VER"
	echo "Caricata su itch.io: $ITCH_TARGET"
else
	echo "Zip pronto da caricare su itch.io (tipo HTML, «This file will be played in the browser»): $ZIP"
fi
git add VERSION CHANGELOG.md web/stable_version.txt
git commit -qm "Versione stabile $VER"
git tag -f "v$VER"
git push -q origin HEAD:main
git push -qf origin "v$VER"
# il sito di sviluppo porta anche stable/version.txt: così chi gioca su itch.io vede «Nuova versione»
bash "$ROOT/tools/deploy_web.sh" "$GODOT"
echo "Versione stabile $VER pronta (build $BUILD)."
