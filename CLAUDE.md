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
- Mai `git add -A` mentre girano le prove severe: `shot.sh` mette `autotest.gd`, `override.cfg` e la riga
  `AutoTest=` in `project.godot` (i primi due ora sono in .gitignore). Prima del commit: `grep -c AutoTest project.godot` deve dare 0.
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
(`Hazards.VenomCloud`) dove riemerge. Vita 650 × moltiplicatore di regione (≈920 in Sokar, prima ≈570), niente sconto al primo incontro. Premio: dono +2, 5-6 lapis,
`Meta.serket_wins`. Il guardiano dipende dalla regione (`_start_guardian`, premio, testo di morte); serie della Piuma e sfida
"Due mani" restano solo del Serpente. `guardian_down`: caduto il guardiano, i rinforzi annunciati non escono più.
Prova: `DUAT_REGION2=1 tools/dev/shot.sh serketshot 1280 720 res://scenes/game.tscn [mobile]`. Bot: `DUAT_SKIP=guardian
DUAT_REGION2=1 DUAT_START_REGION=2` (entrano con 9 doni). Prima prova, 8 partite: veterani 6/6 in 26-60 s, casual 0/2.

Boss: **Aker** (`scripts/aker.gd`, disegno in `scripts/aker_art.gd`) alla **porta dell'orizzonte** (`Arenas.paint_horizon`):
il geroglifico akhet (due montagne, sole spento), la strada del sole da ovest (porta del tramonto, blu) a est (porta dell'alba,
rossa), rocce negli angoli (arena ovale), NIENTE colonne: il riparo sono le pietre del ruggito. Mito: due leoni schiena contro
schiena, Ieri (ovest, sabbia) e Domani (est, fuoco). Fase 1, leone doppio (vita 1550 in tutto, una barra sola): fianchi ×1,35,
teste ×0,8; soffio di sabbia (cono, spinge, sabbie mobili temporanee); **raggio dell'alba** (`Hazards.DawnRay`, ruota, un
colpo ogni 0,6 s); si gira (scambia le teste); ruggito → `Hazards.FallingStone` (ombra d'avviso, poi riparo solido 6 s che
**ferma il raggio**; se cade su di te si frantuma). A metà trema 1,8 s (invulnerabile, cadono pietre) e si divide:
`scripts/aker_lion.gd` Ieri (carica con scia di sabbie mobili, onda) e Domani (balzo, raggio), 385 ciascuno, **a turno**
(mai due mosse grandi insieme; l'altro gira e ruggisce). Caduto uno, l'altro prende la sua mossa. Peso del Cuore
`ira_aker`: se non finisci il secondo in 8 s, il primo rinasce con 190 (nascosto nell'hub finché Sokar è chiusa).
Vittoria: la telecamera sale (`Fx.look`) e il sole **tremola ma non sorge**. `Meta.aker_wins`, Lacrime come ogni boss,
10-12 lapis. Boss per regione: `_boss_kind()`; due boss insieme: `boss_group`, `_on_boss_split`, `_bosses_alive()`.
Prova: `DUAT_REGION2=1 tools/dev/shot.sh akershot 1280 720 res://scenes/game.tscn [mobile]`.
Bot: `DUAT_SKIP=ammit DUAT_REGION2=1 DUAT_START_REGION=2` (13 doni). Prima prova: veterani 1/6 vinte (5/6 alla seconda
fase); stesso test con Am-heh: 3/6. Danni più alti dal raggio → tick portato da 0,45 a 0,6 s. Da ritarare di notte.

Prime prove della Sokar più dura (bot, pochi): Serket 650 veterani 8/8 casual 0/4; Aker 1550 veterani 3/8 casual 0/4;
da Am-heh a Sokar (8 veterani con 13 doni): 4 battono Am-heh, poi 1 vince Sokar e 3 muoiono nelle stanze 6-7 (prima 15/18).
Bot: il campo `result` vale "win"/"cleared"/"death" (attenzione: non esiste "won").

Dialoghi (Anubi, Imhotep, Neith): `UiStyle.next_talk_page` divide le battute lunghe in pagine a fine frase (≈3 righe sul
telefono), il riquadro cresce verso l'alto, e un triangolo che pulsa (`UiStyle.ContinueMark`) dice "tocca per continuare".
Prova: `tools/dev/shot.sh talkshot 1300 600 "" mobile`.

## Prossimi passi (in ordine)
1. ~~Serket~~ e ~~Aker~~ fatti; ~~storia di Sokar~~ fatta (ottobre 2026).
2. **Seconda regione più dura (concordato col proprietario, in corso)**:
   - ~~Base~~: `Run.SOKAR_DEPTH` (vita dei nemici come dalla 4ª stanza di Wernes), `SOKAR_DAMAGE` ×1,12,
     `SOKAR_KA` ×1,25 (lapis invariati: "non esageriamo"), ondate ×1,3 (più nemici, NON una terza ondata),
     élite anche per guardiano di Sokar e avvoltoio, trappole come due stanze più avanti (`Run.trap_depth`).
     Boss: Serket 650 (≈920 con la regione; 5 scorpioni vivi), Aker 1550 (leoni 385, rinascita 190). Am-heh invariato.
   - ~~Oasi della quarta ora~~ (`scripts/oasis.gd`, stanza "oasis" tra Wernes e Sokar, non conta come stanza):
     fonte (+25% vita, una volta), altare di Imhotep (cambia amuleto tra i forgiati, solo per la discesa),
     statua di Sokar che parla, Mahaf con il negozio, porta "desert". Prova: `oasisshot`.
   - **Fiumi di sabbia nera** (approvati): fasce che trascinano e feriscono poco alla volta, si attraversano con
     lo scatto o sulle lastre; più due trappole (sabbie che crollano, statue-falco di Sokar che soffiano in linea).
   - **Nemici nuovi** (approvati): lanciatore di giavellotti (distanza, linea d'avviso), sacerdote di Sokar
     (scudi di sabbia agli altri), scarabeo di Khepri (sfera che rimbalza), **miraggio** in forma di donna
     (copie false, la vera ha l'ombra). NIENTE mummia sepolta (troppo simile al coccodrillo). Lo scorpione è Serket.
     Coerenza con la storia e la regione obbligatoria.
   - **Dèi nuovi** (approvati): **Nefti** (ombra: scatto, colpi alle spalle) e **Shu** (vento: spinte, deviare i
     colpi, tempeste a favore). NIENTE patti di Sokar: i patti restano di Set.
   - Dialoghi più aulici già dall'inizio (Anubi, dèi, Mahaf; Imhotep resta vanitoso).
   - Poi: confronto con Hades ("cosa ha in più") e mega test di notte; infine `SOKAR_READY = true`.
3. Dopo: abbellimenti del Cortile (armeria); pagina itch.io e modulo feedback (il proprietario fornisce `FEEDBACK_URL`);
   se segnalato, lo stesso fix dello scorrimento col pad (`_settle_entries` in casa.gd) in altre finestre.

## Dati dei test (per confronto)
Learners 40×25 (629 partite): il Serpente era il muro (30/40 abbandoni, 13 mai battuto), coccodrillo 2° killer.
Dopo i fix (40×12, prime 12 partite): mai battuto il Serpente 13→10, morti da coccodrillo 102→63, abbandoni 13→14 (non migliorati → Piuma offerta da Anubi).

Mega test (27/10/2026, Sokar aperta, versione con ponte e nemici alleggeriti), learners 40×20 = 584 discese:
battono il Serpente 80%, Am-heh 12% dei tester (18 vittorie su 34 scontri), abbandonano 70% (mediana dopo 13 discese).
Killer: Serpente 201, coccodrillo 108, mummia 82, scarabeo 59. Sokar: 18 discese, 15 vittorie complete (campione
piccolo: 12 di due tester "prudenti"). Boss mirati (30 partite, forza giusta): Serpente 21/30, Serket 17/30, Am-heh 7/30,
Aker 8/30; per i bravi il raggio dell'alba è la prima fonte di danni.
Difficoltà massima (tutti i Pesi, peso 14): 40 partite intere e prova di carico (`stressshot`), zero crash.
Prestazioni (logica+fisica, server): stanza normale ~5 ms, boss 2-3 ms; ~0,1 ms per corpo nel motore; disegno su
telefono non misurabile qui (stanza piena ~800 chiamate di disegno). Caccia agli stalli (`DUAT_STALL=150`): 0 da nemici.

Documenti: `README.md` (panoramica e sistemi), `docs/storia.md` (storia e personaggi), `CHANGELOG.md`.
