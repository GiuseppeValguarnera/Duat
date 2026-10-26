# Duat — "Kheper: Reborn in the Duat" · note per Claude (passaggio di consegne)

Roguelike stile Hades nell'antico Egitto, Godot 4.7.2, GDScript. Nome interno del progetto: **Duat**.
Repo: GiuseppeValguarnera/Duat · versione web di sviluppo: https://giuseppevalguarnera.github.io/Duat/
Proprietario: Skizzo (Giuseppe), alle prime armi con il game dev.

## Regole di lavoro (fisse, chieste dal proprietario)
- Rispondi **sempre in italiano**, come un **game developer senior**.
- **Prima di ogni modifica** (sua o tua) discutine e dai considerazioni da esperto; **dalle di nuovo dopo**.
- È un **brainstorming**: non essere sempre d'accordo. Dì SEMPRE cosa ti convince e cosa no, e proponi alternative. "Sei tu l'esperto, io sono alle prime armi."
- Solo asset **gratuiti**. Deve funzionare su **PC e telefono** (touch + pad + tastiera).
- Fix piccoli → piccoli test con i bot. Test grandi (centinaia di partite) **solo di notte**.
- Sicurezza: la chiave API di itch.io **non va mai** scritta nel codice o nel progetto.
- Dopo ogni modifica: test severo → commit → push → deploy web → resoconto in italiano con considerazioni.

## Ambiente (container nuovo)
```bash
bash tools/dev/setup.sh                       # scarica Godot 4.7.2 + modelli Web (in tools/dev/.godot_bin, ignorato da git)
G=tools/dev/.godot_bin/Godot_v4.7.2-stable_linux.x86_64
bash tools/deploy_web.sh $G                   # pubblica la versione web (ramo gh-pages)
```
- Commit con le righe di attribuzione richieste dalla sessione. Push su `main`.
- **Prove severe con screenshot**: `tools/dev/shot.sh NOME [L A] [scena] [mobile]` (script in `tools/dev/shots/`,
  `override.cfg` rende errori gli avvisi: shadowing, inferenza da Variant, ternari isolati, divisione intera…).
  Immagini in `/tmp/duat_shots`. Hub di default; `res://scenes/game.tscn` per una partita.
  Variabili utili: `DUAT_REGION2=1` (attiva Sokar), `DUAT_START_REGION=2`, `DUAT_AMULET=<id>` (amuleto al liv. 3),
  `DUAT_SERDAB=always`, `DUAT_NOTUT=1` (già messo), `DUAT_LANG=en`.
  Le coordinate del canvas sono in unità 640x360: ×2 per lo screenshot 1280x720.
- **Bot**: `printf "nome persona seed [VAR=val]\n" | tools/dev/bots.sh out.jsonl [processi]` → `/tmp/duat_bots/`.
  Persone: casual, abituale, veterano… (vedi `tools/playtest/bot.gd`).
  **Learners** (giocatori che imparano, salvataggi persistenti, acquisti nell'hub):
  `python3 tools/playtest/learners.py $G OUTDIR testers runs procs` → `OUTDIR/runs/*.jsonl`, `OUTDIR/quit`;
  analisi con `tools/playtest/analyze_learners.py`. Processi in background con `run_in_background`, non nohup.
- **Traduzioni**: `python3 i18n/extract.py` poi `--check` (elenca le stringhe senza inglese);
  `python3 tools/dev/fill_i18n.py it.txt en.txt` (una frase per riga, stesso ordine).
  I valori dei dizionari (es. KILLER_NAMES) non vengono estratti: aggiungerli a mano al CSV.
- Non usare `pkill/pgrep -f` con un pattern che compare nel tuo stesso comando (uccide la shell): usa ps+awk.

## Trappole di GDScript già incontrate
- Le classi interne non possono chiamare funzioni statiche della classe esterna: dare un `class_name` (es. `Courtyard._leaf`, `Hazards.VenomPuddle`).
- Impostare `position` **prima** di `add_child` se `_ready` la controlla.
- Prima di cambiare scena: `get_viewport().set_input_as_handled()`.
- I nodi con z_index -1 finiscono sotto il pavimento: aggiungerli dopo il decoro.
- I poligoni sottili (foglie) falliscono la triangolazione: disegnarli con linee.

## Stato del gioco (ottobre 2026)
**Regione 1 – Acque di Wernes** (coerenza: acqua, coccodrilli, Lago di Fuoco, Porta allagata).
Guardiano: **Serpente della Porta** (combatte in acqua: scia a V sott'acqua, stati seek_deep/rain, pozze di veleno che l'acqua profonda scioglie, -25% vita finché non lo batti la prima volta).
Boss: **Am-heh** sull'isola del Lago di Fuoco (prosciuga la vasca più vicina al giocatore con 1,5 s di avviso; babbuini che versano acqua; ira con doppio balzo e anello di fuoco).
Acqua profonda rallenta (×0,75). Colonne di papiro nell'acqua. Elite = patina e bordo d'oro, più grandi (niente aura gialla).
Coccodrillo: imboscata dall'acqua, riemerge spazientito dopo 6 s (2 s se è l'ultimo).

**Meta-progressione**
- Lapislazzuli: porta lapis 4-5, Serpente 4-5, Am-heh 10-12. Serdab: UN premio a caso (cuore, 2-3 lapis o 10-15 Ka).
- Restauri della Sala/Armeria: 6–18 lapis.
- **Casa della Vita** (porta est della Sala): costa **30 lapis**. Dentro: **Imhotep** (PNG, storia e consigli),
  banco dell'orafo (amuleti), muro di Thoth con 10 **sfide**; il secondo muro si apre dopo **7 sfide**.
  Le sfide contano solo dopo aver aperto la Casa.
- **8 amuleti**, solo bonus (niente maledizioni), uno alla volta, forgiati con i lapis, livelli a 0/20/50 stanze:
  iside, ankh, djed (statua esca), was, shen, hathor (sconto 10/25/40%), udjat, kheper. Vedi `scripts/amulets.gd`.
- **Pesi del Cuore**: due nuovi pesi danno 2 attacchi extra a Serpente e Am-heh.
- **Rinascita** (`scripts/rebirth.gd`): ba che sale, scarabeo che spinge il sole (saltabile dopo la prima volta), emersione nella Sala.
- **Piuma di Ma'at** (modalità aiuto, nelle Opzioni): -10% danni +2% a morte fino a 50%, ma solo 40% del Ka e Peso del Cuore spento.
  Anubi la **offre** dopo 3 sconfitte di fila contro il Serpente (di nuovo a 6) — `Meta.serpent_streak`, beat `piuma1/piuma2`, popup in hub.gd `_offer_feather`.

**Regione 2 – Sokar** (in costruzione, nascosta: `const SOKAR_READY := false` in `scripts/run.gd`).
Dopo Am-heh la partita continua (porta "regione"). Fatti: passaggio con titolo e barca-serpente, pavimento di sabbia,
sabbie mobili (×0,6), tempeste di sabbia, giare; nemici: sciacallo (branco: esca + fianchi), avvoltoio di Nekhbet
(ombra a terra, picchiata), guardiano di Sokar (scudo frontale, carica), ba dannato (esplode, fragile). Gli scorpioni appartengono a Sokar.
Guardiana: **Serket** (`scripts/serket.gd`) nel **tempio** (`Arenas.paint_temple`): sabbia, piano di pietra al centro dove NON
scava (`DAIS_RADII`), 6 cumuli da cui escono gli scorpioni, statue della dea. Mosse: ventaglio di coda (spicchio rosso: si schiva
uscendone, non di lato); sotto la sabbia con **solco visibile**, scorpioni dai cumuli (max 4 vivi, 2-3 a scavo), a volte colpo di
coda in linea dalla sabbia, riemerge con un balzo in linea. Sotto metà vita: aura di veleno, ventaglio doppio, nube
(`Hazards.VenomCloud`) dove riemerge. Vita 460 (×1,24 in Sokar), niente sconto al primo incontro. Premio: dono +2, 5-6 lapis,
`Meta.serket_wins`. Il guardiano dipende dalla regione (`_start_guardian`, premio, testo di morte); serie della Piuma e sfida
"Due mani" restano solo del Serpente. `guardian_down`: caduto il guardiano, i rinforzi annunciati non escono più.
Prova: `DUAT_REGION2=1 tools/dev/shot.sh serketshot 1280 720 res://scenes/game.tscn [mobile]`. Bot: `DUAT_SKIP=guardian
DUAT_REGION2=1 DUAT_START_REGION=2` (entrano con 9 doni). Prima prova, 8 partite: veterani 6/6 in 26-60 s, casual 0/2.

Dialoghi (Anubi, Imhotep, Neith): `UiStyle.next_talk_page` divide le battute lunghe in pagine a fine frase (≈3 righe sul
telefono) e il riquadro cresce verso l'alto. Prova: `tools/dev/shot.sh talkshot 1300 600 "" mobile`.

## Prossimi passi (in ordine)
1. ~~Serket~~ fatta (ottobre 2026). Ritocco proposto: un segno "tocca per continuare" nei dialoghi, ora che vanno a pagine.
2. **Aker**, boss di Sokar: due teste (sabbia e fuoco), ruggito con pietre che cadono; a metà vita **trema (invulnerabile) e si divide in due**; arena = porta dell'orizzonte con il sole spento.
3. Storia di Sokar: Ricordo IV, secondo segno del cartiglio, "il sole che non sorge"; battute di Anubi, Mahaf, Imhotep.
4. `SOKAR_READY = true` e bilanciamento con i bot (test grande di notte).
5. Dopo: abbellimenti del Cortile (armeria); pagina itch.io e modulo feedback (il proprietario fornisce `FEEDBACK_URL`);
   se segnalato, lo stesso fix dello scorrimento col pad (`_settle_entries` in casa.gd) in altre finestre.

## Dati dei test (per confronto)
Learners 40×25 (629 partite): il Serpente era il muro (30/40 abbandoni, 13 mai battuto), coccodrillo 2° killer.
Dopo i fix (40×12, prime 12 partite): mai battuto il Serpente 13→10, morti da coccodrillo 102→63, abbandoni 13→14 (non migliorati → Piuma offerta da Anubi).

Documenti: `README.md` (panoramica e sistemi), `docs/storia.md` (storia e personaggi), `CHANGELOG.md`.
