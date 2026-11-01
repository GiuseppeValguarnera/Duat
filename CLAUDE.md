# Duat — "Kheper: Reborn in the Duat" · note per Claude (passaggio di consegne)

Roguelike stile Hades nell'antico Egitto, Godot 4.7.2, GDScript. Nome interno del progetto: **Duat**.
Repo: GiuseppeValguarnera/Duat · versione web di sviluppo: https://giuseppevalguarnera.github.io/Duat/
Proprietario: Skizzo (Giuseppe), alle prime armi con il game dev.

## Regole di lavoro (fisse, chieste dal proprietario)
- Rispondi **sempre in italiano**, come un **game developer senior**.
- **Prima di ogni modifica** (sua o tua) discutine e dai considerazioni da esperto; **dalle di nuovo dopo**.
- È un **brainstorming**: non essere sempre d'accordo. Dì SEMPRE cosa ti convince e cosa no, e proponi alternative. "Sei tu l'esperto, io sono alle prime armi."
- Solo asset **gratuiti**. Deve funzionare su **PC e telefono** (touch + pad + tastiera).
- Bot e screenshot solo se il proprietario li chiede (test grandi, se richiesti, **solo di notte**).
- Sicurezza: la chiave API di itch.io **non va mai** scritta nel codice o nel progetto.
- Dopo ogni modifica: controllo che il progetto si avvii senza errori → commit → push → deploy. Niente screenshot né bot,
  salvo richiesta esplicita del proprietario: le prove le fa lui giocando. Poi resoconto in italiano con considerazioni.

## Ambiente (container nuovo)
```bash
bash tools/dev/setup.sh                       # scarica Godot 4.7.2 + modelli Web (in tools/dev/.godot_bin, ignorato da git)
G=tools/dev/.godot_bin/Godot_v4.7.2-stable_linux.x86_64
bash tools/dev/check.sh                       # controllo d'avvio dopo ogni modifica: "OK" o gli errori di script
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
- **Piuma di Ma'at** (modalità aiuto, nelle Opzioni): ondate -25%, nemici -10% velocità, -10% danni +2% a morte fino al 30%;
  Ka al 40%, lapis/cuori/serdab/Lacrime a metà, niente Lacrime "prima volta con l'arma", Peso del Cuore spento.
  Anubi la **offre** una volta dopo 3 sconfitte di fila col Serpente (`piuma1`) e una dopo 3 morti di fila entro la stanza 4
  (`piuma3`, `Meta.early_streak`); popup in hub.gd `_offer_feather`.

**Regione 2 – Sokar** (aperta dal 1/11/2026: `const SOKAR_READY := true` in `scripts/run.gd`; ci si arriva solo dopo Am-heh).
Dopo Am-heh la partita continua (porta "regione"). Fatti: passaggio con titolo e barca-serpente, pavimento di sabbia,
sabbie mobili (×0,6), tempeste di sabbia, giare; nemici: sciacallo (branco: esca + fianchi), avvoltoio di Nekhbet
(ombra a terra, picchiata), guardiano di Sokar (scudo frontale, carica), ba dannato (esplode, fragile). Gli scorpioni appartengono a Sokar.
Guardiana: **Serket** (`scripts/serket.gd`) nel **tempio** (`Arenas.paint_temple`): sabbia, piano di pietra al centro dove NON
scava (`DAIS_RADII`), 6 cumuli da cui escono gli scorpioni, statue della dea. Mosse: ventaglio di coda (spicchio rosso: si schiva
uscendone, non di lato); sotto la sabbia con **solco visibile**, scorpioni dai cumuli (max 4 vivi, 2-3 a scavo), a volte colpo di
coda in linea dalla sabbia, riemerge con un balzo in linea. Sotto metà vita: aura di veleno, ventaglio doppio, nube
(`Hazards.VenomCloud`) dove riemerge. Vita 560 × curva delle regioni (≈1260 alla stanza 5 di Sokar, tarata per chi arriva con 12-13 doni), niente sconto al primo incontro. Premio: dono +2, 5-6 lapis,
`Meta.serket_wins`. Il guardiano dipende dalla regione (`_start_guardian`, premio, testo di morte); serie della Piuma e sfida
"Due mani" restano solo del Serpente. `guardian_down`: caduto il guardiano, i rinforzi annunciati non escono più.
Prova: `DUAT_REGION2=1 tools/dev/shot.sh serketshot 1280 720 res://scenes/game.tscn [mobile]`. Bot: `DUAT_SKIP=guardian
DUAT_REGION2=1 DUAT_START_REGION=2` (entrano con 9 doni). Prima prova, 8 partite: veterani 6/6 in 26-60 s, casual 0/2.

Boss: **Aker** (`scripts/aker.gd`, disegno in `scripts/aker_art.gd`) alla **porta dell'orizzonte** (`Arenas.paint_horizon`):
il geroglifico akhet (due montagne, sole spento), la strada del sole da ovest (porta del tramonto, blu) a est (porta dell'alba,
rossa), rocce negli angoli (arena ovale), NIENTE colonne: il riparo sono le pietre del ruggito. Mito: due leoni schiena contro
schiena, Ieri (ovest, sabbia) e Domani (est, fuoco). Fase 1, leone doppio (vita 1700 in tutto, una barra sola): fianchi ×1,35,
teste ×0,8; soffio di sabbia (cono, spinge, sabbie mobili temporanee); **raggio dell'alba** (`Hazards.DawnRay`, ruota, un
colpo ogni 0,6 s); si gira (scambia le teste); ruggito → `Hazards.FallingStone` (ombra d'avviso, poi riparo solido 6 s che
**ferma il raggio**; se cade su di te si frantuma). A metà trema 1,8 s (invulnerabile, cadono pietre) e si divide:
`scripts/aker_lion.gd` Ieri (carica con scia di sabbie mobili, onda) e Domani (balzo, raggio), 425 ciascuno, **a turno**
(mai due mosse grandi insieme; l'altro gira e ruggisce). Caduto uno, l'altro prende la sua mossa. Peso del Cuore
`ira_aker`: se non finisci il secondo in 8 s, il primo rinasce con 210 (nascosto nell'hub finché Sokar è chiusa).
Vittoria: la telecamera sale (`Fx.look`) e il sole **tremola ma non sorge**. `Meta.aker_wins`, Lacrime come ogni boss,
10-12 lapis. Boss per regione: `_boss_kind()`; due boss insieme: `boss_group`, `_on_boss_split`, `_bosses_alive()`.
Prova: `DUAT_REGION2=1 tools/dev/shot.sh akershot 1280 720 res://scenes/game.tscn [mobile]`.
Bot: `DUAT_SKIP=ammit DUAT_REGION2=1 DUAT_START_REGION=2` (13 doni). Prima prova: veterani 1/6 vinte (5/6 alla seconda
fase); stesso test con Am-heh: 3/6. Danni più alti dal raggio → tick portato da 0,45 a 0,6 s. Da ritarare di notte.

Prime prove della Sokar più dura (bot, pochi): Serket 650 veterani 8/8 casual 0/4; Aker 1550 veterani 3/8 casual 0/4;
da Am-heh a Sokar (8 veterani con 13 doni): 4 battono Am-heh, poi 1 vince Sokar e 3 muoiono nelle stanze 6-7 (prima 15/18).
Bot: il campo `result` vale "win"/"cleared"/"death" (attenzione: non esiste "won").

**Blocco 1 (1/11/2026)**: guardiani con la musica del boss (siti di musica gratuita bloccati dal container: per un brano
nuovo serve che il proprietario lo alleghi); stanze con élite senza cambio di musica ("Frozen Desert" era calmo come la
Sala); colonne a `z_index` 1 e `_pillar_depth()` (chi passa dietro è coperto, avvoltoi z 3), ba dannato bloccato da muri e
colonne; coccodrillo immerso fuori dall'acqua esce a terra (`_inside_home`, `_relocate` lo rimette in acqua); mira
automatica sul telefono anche camminando (raggio 180, fermo 260); tasto d'azione del telefono con etichetta del contesto
(`_interact_label`); sul web "Esci" torna alla Sala (`Run.hold_descent`, la discesa riprende dal cancello) e l'opzione
"Esci dal gioco" non c'è; occhi dell'Ushabti senza doni doppi dell'Occhio (`eye.from_player`); Scettro Was: contatore
nell'HUD; Guida delle Anime 15; scarabei 90,25. Prove: `crocfloor`, `pillardepth`, `autoaimshot`, `shopbtn`, `blocco1shot`
(con `DUAT_WEBQUIT=1`). Bot: `music_odd` (stanze con nemici senza musica da battaglia), `spirit` (catene di Anubi),
`DUAT_ANUBI=Guida_delle_Anime`, `DUAT_GUIDE22=1` (valore vecchio, per confronto).
Guida delle Anime, 24 partite per versione (stessi semi): a 15 la catena chiude da sola il 10,6% delle stanze (10/94,
tutte con scarabei) e gli spiriti fanno il 43% delle uccisioni; a 22 l'11,0% e il 44%. Il danno conta poco: gli scarabei
(12 vita) muoiono comunque e la catena continua. Musica: 0 stanze con nemici senza musica da battaglia in 24 partite.

**Blocco 2 (1/11/2026)**:
- *Piuma di Ma'at*: ondate ×0,75, nemici normali −10% velocità, sconto danni 10% +2%/morte fino al 30%, Ka 40%,
  `Run.feather_half()` dimezza per difetto lapis (`Restorations.gain`), cuori, serdab, Lacrime delle sfide; `claim_boss`
  non dà Lacrime con la Piuma. Offerte di Anubi: `piuma1` (3 sconfitte col Serpente), `piuma3` (`Meta.early_streak`,
  3 morti di fila entro la stanza 4); tolta `piuma2`. Prova `feathershot`.
- *Opzioni*: `scripts/ui/options_menu.gd` (OptionsMenu), dalla pausa della partita, da Esc nella Sala (con voci extra),
  dalla pausa di Casa e Armeria. Volume musica / effetti (`Sfx` ha il cursore "effetti" per tutto tranne la musica),
  mira automatica (telefono e pad, mai col mouse), vibrazione (`Fx.vibrate`), grandezza del testo (`Fx.apply_text_scale`,
  `Fx.base_ui`), lingua, tutorial, Piuma, scossa, pausa d'impatto. Prova `optionsshot`.
- *Porte*: `_seal_doors()` mette 3 porte chiuse in ogni stanza di combattimento; `_add_door` apre quella del lato (o ne
  crea una) con `open_door()` (battenti animati, `open_k`); si entra solo con interagisci (`door.enter()`,
  `DOOR_REACH` 46, pulsante ENTRA sul telefono). Prova `doorpush`.
- *Tutorial*: pergamena a sinistra sotto la barra della vita, 72% di opacità, 5% dello schermo (9% sul telefono). `tutshot`.
- *Attacchi*: `_attack_input()` in player.gd: tocco = combo (con buffer), tenere premuto oltre 0,25 s carica 1 s
  (velocità ×0,5, cerchio sopra la testa), rilascio a pieno = attacco caricato, poi 2 s di ricarica. Khopesh: giro
  (58, ×3); lancia: `scripts/thrown_spear.gd` (×2,4 andata, ×1,2 ritorno, disarmato finché non torna). Attacco in scatto
  (`after_dash_t`, `swing_index` 3, direzione dello scatto senza levetta/mouse): khopesh 210°/50/×1,5, lancia affondo
  in corsa. Wepwawet e Balzo della Leonessa potenziano l'attacco in scatto. Bot: combo a colpetti (`atk_flip`), carica
  con `charge_hold`; risultati `charged`, `dash_atk`. Prova `chargeshot`.
- `shot.sh` pulisce con un trap anche se interrotto. Nelle prove dei bot dare nomi diversi a righe con stessa persona
  e seme (condividono cartella e log).

Dialoghi (Anubi, Imhotep, Neith): `UiStyle.next_talk_page` divide le battute lunghe in pagine a fine frase (≈3 righe sul
telefono), il riquadro cresce verso l'alto, e un triangolo che pulsa (`UiStyle.ContinueMark`) dice "tocca per continuare".
Prova: `tools/dev/shot.sh talkshot 1300 600 "" mobile`.

**Blocco 4 (1/11/2026) – Shu**, dio dell'aria (bianco perla e oro; `Meta.shu_met`: la prima volta in Sokar, poi ovunque;
presentazione in `Lore.GODS["shu"]`, ritratto `_shu` in god_portrait.gd). Meccanica: `Enemy.shu_push(dir, forza)` (boss,
guardiani ed élite ×0,2 e niente schianto); per 0,5 s il nemico "vola" (`shu_t`): se sbatte (muro, colonna, nemico) subisce lo
**schianto** `Run.shu_slam_damage()` (6, o 8/12/16 con il Soffio); spinto nella sabbia nera o in una buca ci cade dentro.
Un colpo normale azzera `shu_t`: la combo non spinge. Doni: Soffio (colpo finale), Colonna d'Aria (`scripts/shu_vortex.gd`
sull'attacco caricato), Vento del Nord (eye.gd), Ali del Cielo (scatto +20/30/40% e spinge di lato), Muro di Vento
(enemy_bolt.gd `_deflect`, `player.wind_wall_cd`), Separatore del Cielo (`shu_pushed_t`), Signore delle Tempeste
(`Run.shu_gust`, sempre attiva se c'è una `Hazards.Sandstorm`, gruppo "sandstorm"), raro Sopra la Terra (`Boons.is_rare`,
compare come i pesanti); doppi: Vento Ardente (Ra), Ali del Falco (Horus, l'Occhio torna).

**Blocco 5 (1/11/2026) – armi e Arco di Satet**. Sblocco: khopesh subito; lancia gratis da Neith alla prima visita
del Cortile (come prima, i salvataggi la tengono); **arco** dopo `Meta.serpent_wins >= 3` per **20 lapis**
(`Weapons.UNLOCK_COST`, `requirement_met`, `buy`): si compra al piedistallo (gemma che pulsa) o da **Neith nella Sala**
(`hub.gd` `_neith_here`, `_start_neith`, `_offer_bow`; disegno condiviso in `scripts/neith_art.gd`, `talk_who`).
Arco (`player.gd` `_bow_shot`, `_bow_aim`,
`_spawn_arrow`; frecce in `scripts/arrow.gd`, disegno in `scripts/arrow_art.gd`): freccia ogni 0,33 s al 60% di un
fendente (12×0,6), si ferma al primo nemico, muri e colonne la fermano (raggio sullo strato 1); tiro carico ×2,4 (=4
frecce) che trapassa tutto, carica 1 s, movimento ×0,65 e ricarica 2 s come ogni arma (`_charge_cd_max`, prima 3 s); ventaglio di 3 frecce corte
(±18°, 120 px) alla fine dello scatto; mira: il nemico più vicino entro 320 (levetta destra decide lei; col mouse vale
il nemico puntato, se no il più vicino), sempre, anche con la mira automatica spenta. Unico aspetto: Satet (+5/10/15%).
Doni `arco_*` (campo `weapon`): Ra fuoco (sostituisce `ra_burn`), Sekhmet tiro carico +30/45/60%, Thoth trapassa 1 (dietro
60/80/100%), Bastet critico del tiro carico 35/50/65%, Sobek rallenta 20/28/36% per 2 s (`Enemy.slow_t`, conta per
la Forza del Fiume), Iside scudo 5/7/9 a carica piena (non si somma), Horus frecce che curvano +10/15/20%, Anubi
(bilancia) 2 frecce a ventaglio −35% ciascuna, Nefti il tiro carico marchia col Lutto (cura 2/3/4), Shu il tiro carico
spinge (schianto 8/12/16). `Boons.NOT_FOR["arco"]`: niente doni della combo (Ruggito, Morso di Sobek, Custode, Soffio di
Shu) né Colpo Solare. Battute: ogni dio commenta l'arco la prima volta (`Lore.bow_line`, id `arco_<dio>`), Anubi
`arco1`, Neith `arco_preso` e `arco_amheh`. Lacrime della prima vittoria con l'arco: automatiche (`claim_boss`).
Prove: `DUAT_WEAPON=arco` (o `flagello`) forza l'arma; `tools/dev/weaponsmoke.gd` (nel controllo d'avvio, per arco e
flagello) colpisce con tutti i doni dell'arma, un nemico è élite.

**Regola comune dell'attacco caricato** (tutte le armi): carica 1 s, movimento ×0,65 (`CHARGE_SLOW`, prima ×0,5 per
khopesh e lancia), ricarica 2 s (`_charge_cd_max`) col cerchio sopra la testa.

**Blocco 6 (1/11/2026) – Flagello di Osiride** (id `flagello`, aspetto unico `osiride` +5/10/15%; disegno
`scripts/flail_art.gd`: flagello a strisce oro/blu con tre code di perline, pastorale col ricciolo). Sblocco: prima vittoria
su Am-heh **o** 15 discese, **35 lapis**, al piedistallo del Cortile (`Weapons.requirement_met/UNLOCK_COST`); Anubi lo
annuncia (`flagello0`). Frustate (`player.gd` `_flail_swing`, `_in_lash`, `FLAIL`): 80 px in linea (mezza larghezza 9)
×0,85, cd 0,3; terza a ventaglio 55°/86 px ×1,4, cd 0,46; colpisce **tutti** i nemici sulla linea; danni ×0,5 addosso al
corpo che salgono fino a ×1 al 70% della portata (`FLAIL_BODY`). Dopo lo scatto (`FLAIL_DASH`): 118 px ×1,3, slancio 110,
spinta 300 nella direzione del colpo (i nemici vengono trascinati con te). Attacco caricato = **pastorale** (`_hook`,
`HOOK`): cono 28° (×1,4 sul telefono) fino a 240 px, ×1,6 danni; i nemici normali vengono lanciati verso di te (o 150 px
dove ti muovi) con `Enemy.shu_push(dir, forza, true)` → volano, si schiantano, cadono in sabbia nera e trappole;
élite/guardiani/boss: **voli tu** da loro (560 px/s, max 0,6 s, invulnerabile, `_hook_pulling`). Mentre carichi una linea
tratteggiata e un cerchio indicano il bersaglio: **oro** = lo tiri, **rosso** = voli tu (`_draw_hook`).
Doni `flagello_*`: Ra la 3ª frustata incendia (4/5/6), Sekhmet punta +25/35/45%, Thoth +15/22/30% di portata, Bastet
aggancio critico sicuro +20/35/50%, Sobek rallenta 15/22/30% (`Enemy.slow_t`, rinominato da `arrow_slow_t`), Iside scudo
6/9/12 all'aggancio, Horus l'aggancio ricarica l'Occhio, Anubi (bilancia) frustate +30% rapide e −20% di portata, Nefti
l'agganciato è marchiato (cura 2/3/4), Shu schianto del lanciato 12/18/24 (`Enemy.hook_slam`). Battute: ogni dio la prima
volta (`Lore.flail_line`, id `flagello_<dio>`), Anubi `flagello1`, Imhotep `imh_flagello`, Neith `flagello_preso`.

**Blocco 7 (1/11/2026) – grazie degli dèi e Mahaf**. `scripts/favors.gd` (`Meta.favors`, sezione "grazie"): acquisti coi
lapis che **non danno potenza**. Alla cassa dello scalpellino, sezione "Grazie degli dèi" sotto i restauri (tolta la
parola "Comodità"): **Voce degli Dèi** 15 (`voce`; pulsante nel menu dei doni, `_open_choice(..., reroll)`,
`Run.voices_left`, salvato nella discesa), seconda eco 30 (`voce2`, due volte), **Seconda Barca** 25 (`barca`;
`Oasis.Barque` sull'acqua dell'Oasi, `_open_swap` → `_swap_choices` → `_do_swap`: un dono di un dio normale, non pesante né
raro né di Anubi, scambiato con un altro dello stesso dio allo stesso livello; non si scambia un dono da cui dipende un
altro, `_needed_by_other`), **Sigillo di Thoth** 22 (`sigillo`; `Boons.duo_chance()` 0,45→0,7, raro al posto del pesante
e 35%→65%). Al banco dell'orafo: **Collana a due sigilli** 40 (`collana`; `Meta.amulet2`, `Run.amulet2`,
`Run.wears(id)`, `Run.amulet_lvl(id)`, `Amulets.val_of(id)`, `equip/unequip/worn`; due icone nell'HUD; l'altare
dell'Oasi riempie il secondo sigillo se è libero, altrimenti sostituisce il primo). Battute all'acquisto (`lines`,
`speaker`): Anubi (Voce, Barca), Thoth (Sigillo, `talk_who` "thoth" nella Sala), Imhotep (Collana).
**Mahaf nell'Oasi** non vende più: parla (`Oasis.MAHAF_LINES`, id `mahaf_oasi_N`) e, dopo, "Sali sulla barca di Mahaf"
(`_board_mahaf`: l'eroe sale, la barca scivola a nord, prima stanza di Sokar; niente più porta "desert"). In Sokar il
Traghettatore col negozio c'era già nelle stanze prima di Serket e di Aker (`_open_doors`, stessa regola di Wernes); le
porte di Sokar ora nominano Serket e Aker. Prova: `tools/dev/favorsmoke.gd` (nel controllo d'avvio).

**Blocco 8 (2/11/2026) – telefono: crash, prestazioni, schermate, aggiornamento**.
- *Memoria (crash su iPhone)*: `tools/dev/memsoak.gd` (Sala → Casa → Cortile → 10 stanze di Wernes + Am-heh → 10 di
  Sokar + Aker → Sala, 6 giri): memoria statica 76 MB piatta, oggetti +1 a giro, nodi orfani 0 prima di ogni cambio
  stanza (i ~100 "orfani" subito dopo `start_room` sono la stanza vecchia in `queue_free`). I bot (ogni stanza registra
  mem/obj/nodes/orphans/res in `rooms`) danno lo stesso: 72→75 MB in 16 stanze. **Nessuna perdita trovata nella logica.**
  Asset leggeri (8 MB, musiche in streaming, suoni in pool). **Ancora sospetto** (non misurabile qui): memoria della
  scheda grafica su iPhone (texture cotte di stanza e colonne, SubViewport) e la risoluzione di disegno: ora il
  `devicePixelRatio` è limitato a 2 in `web/shell.html` (prima ~2500×1200 sugli iPhone a 3×).
  *Registro*: `scripts/diag.gd` (`Diag.record` a ogni stanza, boss, guardiano, Sala, Casa, Cortile) scrive
  `localStorage.duat_diag_live`; `web/shell.html` segna `duat_alive` (visibile/aperta), errori JS e `webglcontextlost`;
  se all'avvio la pagina risultava ancora aperta → `duat_diag_last` → Opzioni "Ultimo problema" (si cancella premendo).
- *Prestazioni* (xvfb + opengl3, `tools/dev/perfprobe.gd`, `tools/dev/perfsplit.gd` che nasconde un gruppo di nodi alla
  volta): chiamate di disegno Sokar stanza 8 721 → 422, Wernes 638 → 472 (con più nemici). Le colonne costavano ~117
  chiamate: ora `Pillars.bake()` le disegna una volta in una texture (anche dopo un crollo); le porte ~44 l'una: ora
  rettangoli e `draw_primitive` (≈3 l'una) e si ridisegnano solo da aperte. `Fx.burst`: tetto di 28 esplosioni, niente
  fuori schermo, 60% delle particelle sul telefono. Logica (senza grafica): ~4 ms + fisica ~5 ms nella stanza piena.
  Restano care: i nemici disegnati a mano (20-40 chiamate l'uno: cerchi e poligoni), Am-heh e i suoi babbuini.
- *Schermate a carte* (`_open_choice`, `scripts/ui/choice_card.gd`): frase del dio a pagine con il triangolo, le carte
  dopo l'ultima pagina (`choice_advance`, anche per il bot); carte adattate a larghezza e altezza (testo fino a 7, titolo
  fino a 10, poi la parte centrale scorre con ▲ ▼); sul telefono primo tocco = selezione, secondo o "Scegli" = conferma;
  pad/tastiera: sinistra/destra selezione, azione conferma, su/giù scorrono (`ChoiceCard.Keys` → `_choice_input`).
  Dietro la finestra niente banner né HUD. Prova `tools/dev/choicesmoke.gd`.
- *Trascinamento col dito*: autoload `DragScroll` (`scripts/ui/drag_scroll.gd`) per tutti gli ScrollContainer: soglia
  7 px, il rilascio dopo un trascinamento non preme il pulsante.
- *Aggiorna gioco*: la causa era il service worker della PWA di Godot (cache-first di index.js/wasm/pck). Ora
  `tools/deploy_web.sh` mette la versione nei nomi dei file (`index-<build>.wasm/.pck/.js`), toglie il service worker
  dalla configurazione e pubblica `web/service_worker_reset.js` al posto del vecchio (svuota le cache, si cancella,
  ricarica). La pagina all'avvio cancella service worker e cache rimasti.
- Neith nella Sala tra la porta del Cortile e Anubi (`spots["neith"]` x 148, y 236, rivolta al centro). Descrizioni dei
  doni nuovi accorciate. Bot: `DUAT_SKIP=sokar` (12 doni e +10 vita, discesa intera di Sokar), arco e flagello a distanza,
  nell'Oasi salgono sulla barca di Mahaf.
- *Test armi × regioni* (bot, 64 + 32 partite, nessun valore cambiato): vedi "Dati dei test".

## Regola delle regioni (vale per ogni regione futura)
La vita dei nemici segue `Run.region_hp_curve(regione, stanza)`: Wernes parte da 1,00 e sale di 0,06 a stanza (1,54 alla
decima); **ogni regione parte dall'ultima stanza della precedente +15% e sale con un passo doppio** di quella prima
(Sokar 1,77 → 2,85, passo 0,12; una terza regione partirebbe da ≈3,28 con passo 0,24). Ogni regione ha anche il suo
moltiplicatore dei danni subiti (Sokar ×1,25), ondate più piene ed élite più frequenti. I mini boss prendono la curva
(tarare la loro vita di base); i boss no (vita fissa nella scena, tarata sui doni con cui si arriva).

## Prossimi passi (in ordine)
1. ~~Serket~~ e ~~Aker~~ fatti; ~~storia di Sokar~~ fatta (ottobre 2026).
2. **Seconda regione più dura (concordato col proprietario, in corso)**:
   - ~~Base~~ (rivista nel blocco 3 F): curva della vita `Run.region_hp_curve`, `SOKAR_DAMAGE` ×1,25,
     `SOKAR_KA` ×1,25 (lapis invariati: "non esageriamo"), ondate ×1,3 (più nemici, NON una terza ondata),
     élite dalla prima stanza (14% +2%/stanza, fino al 32%; mummia, guardiano, avvoltoio, sciacallo, lanciatore),
     trappole come due stanze più avanti (`Run.trap_depth`). Boss: Serket 560 (≈1260 con la curva; 5 scorpioni vivi),
     Aker 1700 (leoni 425, rinascita 210). Am-heh invariato. `SOKAR_READY = true`.
   - ~~Oasi della quarta ora~~ (`scripts/oasis.gd`, stanza "oasis" tra Wernes e Sokar, non conta come stanza):
     fonte (+25% vita, una volta), altare di Imhotep (cambia amuleto tra i forgiati, solo per la discesa),
     statua di Sokar che parla, Mahaf con il negozio, porta "desert". Prova: `oasisshot`.
   - ~~Fiumi di sabbia nera, lastre che crollano, statue-falco~~ (blocco 3 A), ~~4 nemici nuovi~~ (lanciatore, sacerdote di
     Sokar, scarabeo di Khepri, Miraggio: blocco 3 B), ~~ondate con limiti~~ (C), ~~Nefti~~ (dea del lifesteal, D),
     ~~dialoghi aulici~~ (E), ~~apertura e curva di difficoltà~~ (F).
   - ~~Shu~~ (blocco 4): il dio dell'aria, spinte e schianti.
   - Le prove le fa il proprietario giocando: raccogliere le sue impressioni su Sokar (durezza della curva, Serket,
     Aker, nemici nuovi) e ritarare. Mega test con i bot solo se lo chiede, di notte.
3. Raccogliere le impressioni su arco e flagello (danni, tiro carico, aggancio del pastorale, mira automatica col mouse)
   e ritarare; aspetti in più per arco e flagello.
4. Dopo: abbellimenti del Cortile (armeria); pagina itch.io e modulo feedback (il proprietario fornisce `FEEDBACK_URL`);
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

Armi × regioni (2/11/2026, bot senza meta-progressione, salvataggio vuoto): Wernes veterani (12 a testa) oltre il
Serpente: khopesh 6, lancia 2, arco 12, flagello 9; Am-heh battuto: arco 2, flagello 2, gli altri 0. Danni/s: arco 22,9,
gli altri ~17. Sokar con 12 doni (8 a testa): nessuno arriva ad Aker; stanza media khopesh 3,4, lancia 3,6, arco 6,6,
flagello 4,4. Attacco caricato del khopesh quasi mai usato dai bot (2-4 a partita). I bot giocano meglio a distanza:
parte del vantaggio dell'arco è dei bot.

Documenti: `README.md` (panoramica e sistemi), `docs/storia.md` (storia e personaggi), `CHANGELOG.md`.
