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
coda in linea dalla sabbia, riemerge con un balzo in linea (blocco 11: max 4 scorpioni vivi, tuffi ed evocazioni +15% più radi, `SUMMON_SLOW`). Sotto metà vita: aura di veleno, ventaglio doppio, nube
(`Hazards.VenomCloud`) dove riemerge. Vita 560 × curva delle regioni (≈1260 alla stanza 5 di Sokar, tarata per chi arriva con 12-13 doni), niente sconto al primo incontro. Premio: dono +2, 5-6 lapis,
`Meta.serket_wins`. Il guardiano dipende dalla regione (`_start_guardian`, premio, testo di morte); serie della Piuma e sfida
"Due mani" restano solo del Serpente. `guardian_down`: caduto il guardiano, i rinforzi annunciati non escono più.
Prova: `DUAT_REGION2=1 tools/dev/shot.sh serketshot 1280 720 res://scenes/game.tscn [mobile]`. Bot: `DUAT_SKIP=guardian
DUAT_REGION2=1 DUAT_START_REGION=2` (entrano con 9 doni). Prima prova, 8 partite: veterani 6/6 in 26-60 s, casual 0/2.

Boss: **Aker** (riscritto nel blocco 9; `scripts/aker.gd`, `scripts/aker_lion.gd`, disegno `scripts/aker_art.gd`; tutte le
costanti in cima ai file) alla **porta dell'orizzonte** (`Arenas.paint_horizon`: akhet, strada del sole ovest→est, rocce
negli angoli, NIENTE colonne). Mito: Ieri (ovest, sabbia) e Domani (est, fuoco). **Fase 1**, un corpo e due teste, vita
1500 (`HP`; barra unica che include i due leoni: `bar_extra`, totale 2500): ti **caccia** a 78 px/s (60% del giocatore) e ruota
lento (`TURN_RATE` 70°/s) per tenerti davanti a una testa (`fire_dir` = asse, fuoco +, sabbia −); fianchi ×1,35, teste ×0,8
(cono 35°). Mosse con avviso 0,45-0,65 s: **morso** (3 colpi da 11 che ti seguono), **carica** (340 px/s, 22, scia di sabbie
mobili, rimbalza sul muro e ricarica verso di te), **soffio doppio** (il corpo ruota di 80°: sabbia 8 e fuoco 16, spinta 220),
**balzo** (ombra, 24 nel raggio 46, anello d'urto 10), **ruggito → raggio dell'alba** (`Hazards.DawnRay` 1,8 s, 110°, 10 a
colpo ogni 0,6 s, cammina a metà velocità; ricarica 8 s; max 2 `FallingStone` che si sgretolano al 3° passaggio del raggio,
`ray_pass`). Dopo una mossa grande 1,2 s fermo (`PUNISH`); sotto metà vita le mosse si legano a due (`_chain_next`, pausa
0,5 s). A 0 trema 1,8 s (invulnerabile, `die()` sovrascritto) e si divide (`_split`, musica "elite", battute
«Io sono Ieri…» «Io sono Domani…»): **Ieri** (carica 430 px/s da 20 con scia, onda a cono 12 con spinta) e **Domani**
(balzo 20, raggio), 500 ciascuno, **insieme** (aspettano solo 0,35 s se l'altro ha appena iniziato un avviso; avviso mai sotto
0,45 s). **Tenaglia** (ogni 11 s, decide Ieri): si piazzano ai lati opposti di te e caricano insieme (scritta TENAGLIA).
Caduto uno, l'altro prende la sua mossa e si infuria (+25% velocità e danni, `fury`; battute proprie). Peso del Cuore
`ira_aker` (la rinascita a 8 s è stata tolta): leoni già a +10% alla divisione, furia del sopravvissuto +50%.
Vittoria: la telecamera sale (`Fx.look`) e il sole **tremola ma non sorge**. `Meta.aker_wins`, Lacrime come ogni boss,
10-12 lapis. Boss per regione: `_boss_kind()`; due boss insieme: `boss_group`, `_on_boss_split`, `_bosses_alive()`.
Bot: `bot_escape(pos)` su Aker e leoni. Test: `tools/dev/akersmoke.gd` (nel controllo d'avvio, `--fixed-fps 60`,
`DUAT_REGION2=1`): tutte le mosse, divisione, tenaglia, furia, vittoria. Prova: `DUAT_REGION2=1 tools/dev/shot.sh akershot
1280 720 res://scenes/game.tscn [mobile]`. Bot: `DUAT_SKIP=ammit DUAT_REGION2=1 DUAT_START_REGION=2` (13 doni).
**Blocco 11 – servitori e arena** (`scripts/aker_arena.gd`, class_name `AkerArena`, costanti in cima; `Arenas.horizon_*`):
metà ovest sabbia con 2 sabbie mobili fisse (`Hazards.Quicksand`, ora rallentano anche i nemici normali), metà est
terreno spaccato con 2 **crepe di fuoco** (`AkerArena.FireCrack`: ogni 6 s, avviso 1 s rosso, fiammata 0,4 s da 12,
`aker_crepa`); rocce degli angoli rimpicciolite e 4 **stele** (`AkerArena.Stele`, strato 1, gruppo `aker_stones`: fermano
raggio, colpi e frecce; si spezzano al 3° passaggio del raggio o a una carica di Ieri, gruppo `horizon_stele`).
**Servitori** (`AkerArena.Gates` evoca con `game._on_boss_summon`, cerchio d'avviso e bagliore della porta): Ombra di
Sabbia `aker_shade` (porta del tramonto, ovest: lenta 42, vita 24 con la curva, contatto 8, scia di sabbie mobili) e
Scintilla dell'Alba `aker_spark` (porta dell'alba, est: veloce 118, vita 8, a 18 px si accende 0,3 s ed esplode 10 nel
raggio 26, macchia di fuoco r15 per 4 s, al massimo 2 macchie insieme; abbattuta prima non esplode). Fase 1 ogni porta
ogni 10 s, max 2 vivi; fase 2 ogni 7 s, max 3, Ieri = ovest, Domani = est; caduto un leone la sua porta crolla.
`Enemy.no_reward` (niente Ka né cuori); caduto Aker i servitori annunciati non escono.
**Difficoltà NON ancora verificata** coi bot (obiettivo: 10-15% al primo tentativo con 12-13 doni, ~3 minuti).

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
`_spawn_arrow`; frecce in `scripts/arrow.gd`, disegno in `scripts/arrow_art.gd`): freccia ogni 0,4 s da 8 di danno base
(`BOW_ARROW` 8/12 di un fendente, blocco 13; +20% oltre 120 px, `arrow.gd` `FAR_DIST`/`FAR_BONUS`), gittata 235 px, si ferma al primo nemico, muri e colonne la fermano (raggio sullo
strato 1); tiro carico ×3,5 una freccia, gittata 306, che trapassa tutto, carica 1 s, movimento ×0,65, ricarica **4 s** (eccezione alla regola delle armi); mentre tiri
×0,9 (`BOW_FIRE_SLOW`); ventaglio di 3 frecce corte (±18°, 120 px, 38%) alla fine dello scatto; mira: **quasi nessuna assistenza**
(blocco 11; blocco 12: ±6° `BOW_ASSIST` solo con la levetta del telefono e col pad): la freccia parte dove punti (mouse, levetta destra; sul telefono il tasto dell'arco è una levetta di mira,
`touch_controls.gd` `aim_touch`/`_set_aim`, `player.gd` `_touch_bow_input`: trascinare = frecce, dito fermo 0,25 s =
carica, rilascio a carica piena = tiro carico, tocco rapido = una freccia; `last_stick` tiene la direzione 0,2 s). Effetti dei doni al massimo una volta ogni 0,5 s per nemico (`arrow.gd` `FX_GAP`, meta
`arrow_fx`); lo scudo del guardiano di Sokar para le frecce (`blocks(dir)`, "PARATO"). Unico aspetto: Satet (+5/10/15%).
Doni `arco_*` (campo `weapon`): Ra fuoco (sostituisce `ra_burn`), Sekhmet tiro carico +30/45/60%, Thoth trapassa 1 (dietro
60/80/100%), Bastet critico del tiro carico 35/50/65%, Sobek rallenta 20/28/36% per 2 s (`Enemy.slow_t`, conta per
la Forza del Fiume), Iside scudo 5/7/9 a carica piena (non si somma), Horus **Ricochet del Falco** (`arco_ricochet`, `RICOCHET` in player.gd:
1 rimbalzo al 60% / 1 all'80% / 2 all'80%, sul più vicino non colpito entro ¼ dello schermo con visuale libera; con la
Freccia Sapiente parte quando la freccia si ferma; niente sul tiro carico), Anubi
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
×0,80, cd 0,32 (blocco 13); terza a ventaglio 55°/86 px ×1,4, cd 0,46; colpisce **tutti** i nemici sulla linea; danni ×0,5 addosso al
corpo che salgono fino a ×1 al 70% della portata (`FLAIL_BODY`). Dopo lo scatto (`FLAIL_DASH`): 118 px ×1,3, slancio 110,
spinta 300 nella direzione del colpo (i nemici vengono trascinati con te). Attacco caricato = **pastorale** (`_hook`,
`HOOK`): cono 28° (×1,4 sul telefono) fino a 150 px (blocco 13, la mira usa il raggio vero), ×1,6 danni; i nemici normali vengono lanciati verso di te (o 150 px
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
e 35%→65%). Al banco dell'orafo: **Collana a due amuleti** 40 (`collana`; `Meta.amulet2`, `Run.amulet2`,
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

**Blocco 9 (2/11/2026) – Aker, arco, mira assistita, Anubi**. Aker: vedi sopra (Regione 2). Arco: vedi blocco 5.
*Mira assistita* (rivista nel blocco 10, vedi sotto): arco e Occhio `_assisted` (cono `ASSIST_BOW` 12°, entro il 70%
dello schermo, visibile, senza muri/colonne in mezzo, mai dietro, bersaglio appiccicoso); mischia `_melee_aim`.
*Anubi*: profondità `Run.depth(regione, stanza)` = (regione−1)×10 + stanza, usata nelle battute, nel record della Sala
("Il piano più profondo", `Meta.best_room` ora è la profondità, `Meta.last_region`) e nel riepilogo ("piano %d").
Battute di morte in tabella: `dialogue.gd` `death_table()` per regione e fascia (Sokar 1-3, 4-6, 7-9, guardiano, boss,
consiglio del boss, pericoli `HAZARD_KILLERS` fiume/buca/falco, vittoria), almeno 3 varianti; `death_line(reg, rm,
killer, boss)`. Per una regione nuova basta aggiungere righe alla tabella.

**Blocco 10 (2/11/2026) – danni in Sokar, mira, arco, Occhio, Thoth, pesanti di Nefti e Shu**.
- *Registro dei danni* (player.gd `log_damage`, `top_damage`, `LOG_WINDOW` 10 s su `log_clock`): ogni danno con la sua
  fonte (`Run.last_hit`, veleno con `poison_key`: `scorpion_veleno`, `serket_aura`, `serket_nube`, `serpent_veleno`);
  alla morte le prime tre fonti (`game.gd` `_damage_sources`, nomi da `KILLER_NAMES`). Anello di fuoco di Am-heh ora
  `amheh_anello`. *Danno da terreno* (`TERRAIN_KINDS`: fiume, fuoco di Am-heh, olio; e i tick del veleno):
  `terrain_signal` → bordi colorati e icona al posto dell'ankh (hud_bars.gd `_terrain_edges`, `_terrain_icon`), suono
  "hurt" basso; niente scossa né pausa d'impatto. Fiume: bordo chiaro che pulsa (`RIM`), contro corrente il
  trascinamento cala fino al 60% (`RIVER_AGAINST`), all'arrivo di uno scatto niente tick immediato. Valori di danno
  invariati: fiume 2 ogni 0,5 s (×1,25 = 5/s). Veleno (blocco 11): 2 ogni 0,9 s (`POISON_TICK`), 3 s a puntura, massimo
  5 s (`POISON_MAX`), un tempo per fonte (`poisons`), niente veleno se lo scudo ha preso tutto il colpo (`absorbed_frame`).
  Scorpione: puntura ±45° (`STING_CONE`), 10 px sempre (`STING_CLOSE`), cono rosso d'avviso, velocità 72.
- *Mira della mischia* (`_melee_aim`, `_melee_pick`, `_attack_base`; rivista nel blocco 11): SEMPRE il nemico più vicino
  a 360° entro portata ×1,5 (`MELEE_ASSIST_REACH`), a pari distanza (±15%) quello verso cui guardi; visuale libera;
  bersaglio stabile; nessuno a portata → dove ti muovi/guardi. L'arco escluso; l'Occhio a 12° solo al lancio. Vale per fendenti, frustate, attacco caricato e
  pastorale (`_hook_target`). Col mouse spenta; opzione "Mira assistita" attiva di base.
- *Origine dei colpi* (`Boons.ORIGINS`, `Boons.acts_on(id, origine)`, `Run.hit_has`): origini khopesh, lancia, flagello,
  occhio, freccia; i doni con `weapon` valgono per la loro arma; le frecce (`arrow.gd`, `O := "freccia"`) ricevono solo i
  doni dell'arco e quelli generali. Occhio Moltiplicato `horus_multi` e Occhio Penetrante `horus_pierce` sono di Horus;
  tolti Calcolo di Thoth e Parola dello Scriba; doppi `duo_ra_horus`, `duo_horus_bastet`. Id vecchi: `Run.BOON_ALIASES`
  e `Run.clean_boons` (gli sconosciuti cadono senza errori).
- *Thoth* (turchese): Prima Parola `thoth_first` 40/60/80% (`Run.first_word`, meta `fw`, boss `fw0`/`fw1` per fase),
  Clessidra `thoth_hourglass` 1,2/1,6/2 s di -60% (`Run.on_player_hurt`, `hourglass_t`; anche se lo scudo para),
  Geroglifo Scritto `thoth_glyph` ogni 8 colpi 12/18/24 ai tre più vicini, Lezione dello Scriba `thoth_lesson`
  (`Run.scribe_lesson`, `lesson_regions` salvato nella discesa; stanza 1 di una regione ≥2 e dopo Am-heh/Aker), raro
  Giudizio `thoth_judgment` (<12%), pesante Tempo Rubato `thoth_stolen` (-20% nemici e proiettili, -20% danni). Doppi
  Registro dei Morti `duo_thoth_anubi` (`REQUIRES_ALL`) e Nome Vero `duo_thoth_iside` (scudo 4 fino a 12).
  `Run.thoth_time()` rallenta `enemy_bolt.gd` e la sfera di Khepri; in enemy.gd tutti i rallentamenti insieme non
  scendono sotto `MIN_ENEMY_SPEED` 0,35. Colpi del giocatore: `Run.player_hit(e, fx)` (moltiplicatore) e
  `Run.after_player_hit(e, dir, fx)` in tutti i punti di colpo (fendenti, giro, frustate, pastorale, lancia lanciata,
  frecce, Occhio).
- *Pesanti*: Nefti **Fame dei Defunti** `nefti_heavy` (+1 vita a colpo, per le frecce col tetto di 0,5 s; tetto di Nefti
  20; -20 vita massima), Shu **Il Cielo Cade** `shu_heavy` (ogni colpo spinge a 260, schianti ×2; costo semplice -20% a
  tutti i danni). Raro e pesante di un dio condividono un posto (`Boons.offers`, `specials` a caso; col Sigillo il raro).

**Blocco 11 (3/11/2026)**: veleno e scorpioni, arco senza mira assistita e levetta sul telefono, mira della mischia
sempre sul più vicino, **Tempo Giusto** (Thoth `thoth_timing`: ricarica del caricato -15/22/30%, mai sotto 1,8 s,
`CHARGE_CD_MIN`; con khopesh, lancia e flagello arriva al massimo a -10% per il minimo), testi degli acquisti
(`favors.gd`, campo `sub` mostrato nella cassa; tasto "Altre scelte (N rimaste)"), Collana a due amuleti, Aker con
servitori e arena nuova (vedi Regione 2).

**Blocco 12 (3/11/2026) – leggibilità dei danni in Sokar** (valori di danno dei nemici invariati).
- *Diagnosi*: `Run.hit_log` (15 voci: fonte, danno, distanza dal centro della fonte, stato dell'attacco, secondi di volo
  dei proiettili via `player.hit_age`; `player._note_hit`) → Opzioni "Ultimi colpi" (`options_menu.gd` `_show_hits`,
  `STATE_NAMES`). Opzione "Mostra aree di danno" (`Meta.options.zones`, `Run.show_zones()`): `Enemy._draw_zones` (corpo
  azzurro, contatto rosso) + `_zones()` dei nemici (salto, carica, cono, esplosioni), sagoma del giocatore, proiettili.
- *Regola unica* (`Enemy.PLAYER_R` 6, `TOUCH_PAD` 2, `touch_dist()`, `touches(p, r, at)`): i colpi di corpo vanno a segno
  solo se le sagome si toccano; le zone (coni, strisce, cerchi) usano esattamente le misure dell'avviso. Avvisi con
  `Enemy.warn_strip` / `Enemy.warn_circle` (rosso `Enemy.WARN` che si riempie). Ogni attacco sopra il 10% della vita ha
  almeno 0,45 s di avviso: scorpione 0,45, Serket secondo ventaglio `SECOND_FAN` 0,63 (0,45 s), Scintille 0,45, Miraggio
  non lancia da meno di 72 px (`MIN_THROW`). Serket: ventaglio senza margine, coda in linea `LINE_HALF` 12 e balzo
  `BREACH_HALF` 16 larghi quanto l'avviso. Aker: morso su un punto fisso (`bite_at`, `_bite_center`) che smette di seguirti
  a metà preparazione, carica `CHARGE_HALF` 32, onda con la fascia vera. Leoni: carica = contatto, balzo senza margine.
- *Sciacallo*: salto 260 × 0,23 s = 60 px, pericolo ~75 (`LEAP_DANGER`, parte solo da lì), preparazione 0,45 s, direzione
  bloccata a metà, striscia vera. *Guardiano*: carica 230 × 0,435 = 100 px, parte entro 110 (`CHARGE_FROM`), preparazione
  0,9 s con direzione bloccata a metà; **scudo con resistenza** (`SHIELD_FRAC` 0,4 della vita; danno pieno dei colpi parati,
  ×2 se `Run.heavy_strike` – attacco caricato, lancia lanciata, tiro carico –; spinta di Shu = 2 × schianto; contro colonna
  o nemico −1/3): crepato sotto metà, rotto → barcolla 0,8 s e resta scoperto 6 s (`SHIELD_DOWN`), poi torna intero.
- *Proiettili*: giavellotto 1,1 s (`BOLT_LIFE`, ~300 px) con striscia vera (`BOLT_HALF` 9); sfera di Khepri R 12, alone,
  frecce rosse sulla traiettoria, ferisce a R + 6; statue-falco esattamente la striscia (niente +4).
- *Avvoltoi*: a terra 1,9 s, in volo 1,6-2,6 s (`SOAR_TIME`), atterraggio con polvere e suono, picchiata = contatto; le
  frecce li colpiscono in volo al 60% (`ARROW_AIR`, `Run.arrow_hit`). La mira della mischia ignora chi è in volo.
- *Ba dannati*: miccia in secondi reali (`fuse_left`), niente spinte/Shu/stordimento/anti-incastro durante la miccia.
- *Mira*: corpo del giocatore girato verso il colpo durante l'attacco; prova `tools/dev/aimsmoke.gd` nel controllo
  d'avvio (davanti, dietro camminando all'indietro, due nemici, nessuno).

**Blocco 13 (4/11/2026)**:
- *Strato a terra*: `Hazards.ground(n)` (gruppo `ground_hazards`, z 0, subito dopo il nodo con `rebake`) per sabbie mobili,
  pozze di veleno, fuoco a terra, crepe di fuoco, fiume di sabbia nera e lastre: sopra il pavimento, sotto le creature.
- *Armi*: pastorale 150 px; frustate ×0,80 / 0,32 s; arco 8, 0,4 s, ×0,9 tirando, gittata 235, tiro carico 3,5 frecce con
  ricarica 4 s, +20% oltre 120 px (vale anche per i rimbalzi del Ricochet).
- *Ba dannati*: l'esplosione ferisce anche i nemici (`ENEMY_BLAST` 24, spinta 220; boss e guardiani immuni) e accende gli
  altri Ba nel raggio (`chain_ignite`, `CHAIN_DELAY` 0,3 s: reazione a catena).
- *Schermo intero*: `Fx.fs_supported/fs_on/fs_request/fs_hint`; Opzioni (riga `fullscreen`, `button_down`) e pausa; sul web
  il gioco arma `window.duatWantFS` e `web/shell.html` esegue la richiesta al rilascio (pointerup/touchend/keyup/click);
  tasto F gestito dalla pagina (sul PC scaricato da `Fx._unhandled_key_input`); niente su iPhone/iPad; suggerimento
  "Premi F" una volta (`Meta.options.fs_hint`). La pagina non scorre (rotella, frecce, Spazio, PagSu/Giù, Inizio/Fine),
  il canvas prende il focus al primo clic, `refit()` con debounce e solo se la misura cambia.
- *Seconda Barca*: scheda del dono a destra (`_boon_card`), tocco = evidenzia, secondo tocco = conferma; nelle carte il
  confronto "Prima (…)". *Altare di Imhotep*: lista completa degli amuleti forgiati con descrizione, che scorre.
- *Prima di boss e mini boss* (corretto nel blocco 14): vedi sotto. *Cura del Traghettatore*: `Run.ferry_heal()` = 60%
  di `nile_heal()` (18% di base).

**Blocco 14 (7/11/2026)**: Occhio di Horus 18 di danno base (`eye_damage`, default di `eye.gd` allineato) e 3,2 s di
ricarica (`eye_cooldown`); l'Occhio dell'Ushabti ha il suo danno (6). **Prima di boss e mini boss** (stanza G-2 e 9,
`_open_doors`): 2-3 porte, TUTTE verso stanze senza nemici: Traghettatore, sala con la cura e sala con un dono
(`{"calm": true}` nella ricompensa → `start_room` con `quiet`, `_start_quiet_room`: niente ondate, trappole né colonne,
musica della Sala, ricompensa già a terra, non conta come stanza ripulita); dopo, una porta sola verso la prova. Porte con
" · sala tranquilla, senza nemici". Prova `tools/dev/quietsmoke.gd` nel controllo d'avvio.

**Blocco 15 (8/11/2026)**:
- *Sfinge, «La scala dell'enigma»* (`scripts/sphinx.gd` class_name `Sphinx`: regole, dati, enigmi; `scripts/sphinx_trial.gd`
  class_name `SphinxTrial`: la partita). Porta nella parete nord della Sala a x 616 (`hub.gd` `SPHINX_X`), 28 lapislazzuli
  (`Sphinx.COST`; lucchetto e prezzo sulla lastra), E = classifica e premi (`_show_sphinx_board`), ci si entra camminando.
  `Run.trial` → game.gd riusa tutto: `start_room({"kind": "sphinx"})` (arena grande, due colonne `TRIAL_PILLARS`, statua
  della Sfinge), `_room_cleared` → `trial.on_wave_cleared`, `_on_player_died` → `trial.finish`, pausa con
  "Ritirati". Spenti nella prova: capitoli (`Run.chap`, `Chapters.is_equipped`), Pesi, Piuma, amuleti, Sekhem, Ka dei
  nemici, sfide, salvataggio della discesa (`Run.save_descent`). Arma del giorno e ondate dal seme del giorno UTC
  (`Sphinx.day()`, `DUAT_SPHINX_DAY` per le prove; `DUAT_WEAPON` forza l'arma). Ondate: `Sphinx.wave_list` (nemici di
  Wernes, quelli di Sokar dalla 11ª; élite con "@e"), vita/danni/velocità con `Run.trial_hp/trial_dmg/trial_speed`
  (`hp_mult` come Wernes fino alla 25, danni fino a ×1,25, dopo la 25 solo numero e velocità +2%/ondata fino a +30%).
  Guardiani ogni 5 (`GUARDS`: guardiano di Sokar élite, Ombra di Ieri `aker_lion@ieri` 260, grande scarabeo di Khepri
  `khepri@g` ×3 élite (blocco 16, al posto di Serket: nell'arena di pietra le sue regole di sabbia non si leggevano),
  Ombra di Domani 420; +30% a giro). Sabbie mobili dalla 11ª, crepe di fuoco dalla 16ª. **Pausa della Sfinge** ogni 3
  ondate (blocco 16, `_sphinx_pause`): enigma (`riddles()`, 17, ordine del giorno, nessuna ripetizione nella prova
  finché ce ne sono) poi tre doni (`boon_offers`: dèi diversi, solo nuovi, niente pesanti/rari/doppi/Set/Anubi); se cade
  insieme alla cura (ondata 15) prima la cura, poi la pausa. Risposta prudente (short −2, gift, heal, slow, shield) o
  audace (tough +30%, fast, noheal, fragile, horde +3, elite, sting): l'effetto dura 3 ondate (`active`,
  `active_left`, `Sphinx.EFFECT_WAVES`), nell'HUD accanto all'ondata (`effect_short`). Cura 15% ogni 5. Punti: 10 a
  ondata, +3 senza colpi, +1 sotto 25 s, +4 (`PTS_HARD`) per ogni ondata superata con un effetto audace attivo.
  *Schermata dei comandi* (`show_controls`, `WeaponIcon`, `_keys` per dispositivo, `_moves` per arma, `_fit_panel`
  rimpicciolisce sul telefono): prima dell'ondata 1 una volta per arma (`Meta.sphinx.intro`), poi da «Comandi
  dell'arma» nella pausa. *Protezione della data* (`Sphinx.touch_clock` a ogni avvio in `Meta._ready`, a ogni prova e
  a ogni premio; `clock_ok` con 10 minuti di tolleranza; `last_seen`): orologio indietro → niente premi settimanali,
  riga neutra nella bacheca e nel riepilogo; le soglie riscosse si azzerano solo quando la settimana va avanti. `Meta.sphinx`: open, scores (10, con giorno/seme/arma/regole per una classifica online futura), week/claimed
  (premi `WEEKLY` 5/10/15/20 → 15+1, 25+2, 35+3, 50+4; settimana dal lunedì 00:00 UTC). Prova `tools/dev/sphinxsmoke.gd`
  (nel controllo d'avvio).
- *Frecce e nomi* (`hub.gd` `HubDoorArrows`, `_draw_door_names`): chevron a terra verso cancello (due tratti, più
  evidenti), Sfinge, Cortile, Casa; di pietra con lucchetto e prezzo se chiuse. Spariscono dopo `Meta.use_door(id)`
  (`Meta.doors_used`), opzione "Mostra le frecce" (`Meta.options.arrows`). Sul telefono ×1,45 e contorno chiaro.
- *Grafica della Sala*: `HubCat` nero lucido senza pelo (`_head`), `_draw_scale` (base a gradini, geroglifi,
  `_scale_balance()` dai guardiani/boss battuti e dai restauri, Pesi che riappesantiscono, `scale_glow`), vasca del Nilo
  `HubArt._pool` in `spots["vasca"]` (solida, bordo scolpito, onde, luna, pesce ogni 9 s, papiri, lampade; secca senza
  restauro). *Racconti dell'acqua* (`scripts/tales.gd` class_name `Tales`, 12 miti con condizione; `Meta.tales_read`,
  punto esclamativo sulla vasca; `hub.gd` `_open_tales`, una pagina per racconto con ◀ ▶ e tastiera).

**Blocco 17 (9/11/2026) – la Sfinge personaggio**:
- *Luogo e dialogo*: entrando dalla porta della Sala si arriva nell'arena e la prova NON parte. `scripts/sphinx_statue.gd`
  (class_name `SphinxStatue`, vista di fronte, `process_mode` sempre attivo): occhi che seguono piano il giocatore entro
  `ZONE` 240, palpebre, polvere e occhi accesi quando parla (`speak`), rumore sordo (`amheh_land` basso), fumetto `say()`
  che non ferma il gioco, ornamenti dal Tesoro (collare, gioielli, loti, bracieri, stendardi). Solida: 164×116 dalla
  parete. `SphinxTrial.near_statue()` → prompt e tasto PARLA (touch_controls) → `open_menu()`: dialogo
  `SphinxUI.TalkBox` (macchina da scrivere 80 caratteri/s, tocco o tasto completa) con menu Accetta la prova /
  Modificatori / Il Tesoro della Sfinge / Comandi / Ascolta (con «Ricordi») / Vai via. Prima visita: discorso lungo
  (`first`); poi 1-2 righe per situazione (assenza > 3 giorni, premi già presi, record, ritorno) + arma del giorno.
  Reazioni senza dialogo: fermo davanti 7 s → `idle`, te ne vai senza menu → `walk_off` (45%, attesa 10-14 s).
- *Battute* (`scripts/sphinx_lines.gd`, `SphinxLines.table()`/`pick()`: a caso senza ripetere l'ultima, salvata in
  `Meta.sphinx.last_line`): first, enter_back/long/claimed/record, weapon, accept, shop, mods, leave, idle, walk_off,
  record, near, early, normal, retired, cause_* (da `Run.last_hit`, mappa `CAUSES`; altrimenti `cause_generic`), memories.
- *Sconfitta*: `_outcome` (record se supera il migliore, vicino ≥ 85%, precoce se < metà della media delle ondate dopo 3
  prove), `_death_talk` (esito + causa) poi riepilogo con modificatori, sigilli, premi; «Riprova» = `Run.sphinx_reopen` e
  ricarica la scena col menu già aperto; il pausa prima della prova dice «Torna alla Sala».
- *Modificatori* (`scripts/sphinx_shop.gd` `MODS_IT`, massimo 3, `mods_on`, salvati): Pietra Dura, Vento del Deserto,
  Digiuno (`Run.trial_noheal`: `player.heal` non cura), Pelle Sottile (gratis); Sciame, Primo Sangue (`Run.trial_first`:
  primo colpo dell'ondata ×1,5 in `take_damage`), Corte d'Oro, Morso del Deserto (dal Tesoro). Punteggio ×(1 + somma
  dei bonus) (`total_score`); la classifica salva mods, mult, raw, titolo. Premi settimanali invariati (ondata).
- *Doni della Sfinge* (boons.gd, dio "sfinge", un livello, campo `color`, `Boons.is_sphinx/color_of/sphinx_pool`): nella
  prova sostituiscono gli dèi (`Sphinx.boon_offers`); effetti in run.gd/player.gd (`sf_*`); `sf_coin` solo nella prova.
  Esclusi da `gods_with_boons`, Lezione dello Scriba, Kheper, Seconda Barca, Inchiostro di Thoth, `_max_level` 1.
- *Sigilli e Tesoro* (`SphinxShop.seals/add_seals/buy`, `ITEMS_IT`, `SphinxUI.open_shop` con anteprima `Preview` e doppio
  tocco): 1 a ondata, +2 guardiano, +1 senza colpi (+1 Moneta); oggetti 20-80, Favore 450. Enigmi extra
  `_riddles_river/_riddles_sky`, racconti `harmachis` e `thutmose` in tales.gd, titolo e cornice nella bacheca della Sala.
- *Favore della Sfinge* (`favore_sfinge` in favors.gd con `seals`, visibile alla cassa ma si prende nel Tesoro):
  `Sphinx.favor_roll` (12,5% per scelta, al massimo un dono della Sfinge per discesa, mai con doppio/pesante/raro) in
  `game._show_boon_menu`, carta «Dono della Sfinge · raro».

**Revisione del 12/11/2026** (carta bianca del proprietario: controllo generale con screenshot e bot, niente contenuti nuovi).
- *Sala*: `HubFront` (classe interna di hub.gd, aggiunta prima di frecce e giocatore) disegna porta della Sfinge, nomi
  delle porte e bilancia SOPRA il decoro (fregio e rosone le coprivano): `_draw_sphinx_door(ci, pulse)`,
  `_draw_door_names(ci)`, `_draw_scale(ci, p)` prendono il CanvasItem. Porta della Sfinge larga 40 con cornice d'oro,
  bagliore e cono di luce; frecce più chiare con sotto-tratto scuro.
- *Sokar si vede deserto*: pavimento ridipinto in game.gd (`sokar := Run.region == 2 and not set_altar and not Run.trial`:
  sabbia chiara, lastre solo a "isole", onde del vento, fregio ocra); `decor.SHADE` 0,34 in Sokar, 0,46 altrove (era 0,52),
  0,18 nelle arene; luce `Color(1.0, 0.94, 0.82)`. Sciacalli **neri** con collare d'oro (sulla sabbia non si vedevano);
  ombra a terra dei nemici alfa 0,5 dalla regione 2.
- *HUD*: sotto il 30% di vita bordi rosso scuro che pulsano (hud_bars.gd). Prova della Sfinge: `hud_line()` "Ondata N ·
  P punti", seconda riga `hud_extra()` (moltiplicatore, effetto dell'enigma, sigilli).
- *Bilanciamento*: lancia affondi ×1,15 e cono 40° (erano ×1,0 / 34°). Ombre dei leoni nella Sfinge: `aker_lion.gd`
  `shadow` (`SHADOW_DMG` 0,65, `SHADOW_SPEED` 0,8), vita Ieri 220, Domani 380 (14 prove su 24 finivano all'ondata 10).
  **Sokar NON alleggerita**: lo 0/12 dei veterani era ignoranza del bot.
- *Strumenti*: `tools/dev/watch.sh NOME persona seme [VAR=val]` (bot con grafica sotto xvfb + `tools/playtest/snap.gd`:
  uno screenshot ogni `DUAT_SNAP_EVERY` s in `/tmp/duat_watch/NOME/`, `DUAT_TIMEOUT`), `tools/dev/sheet.py DIR [col righe]`
  (provini), prove `hubtour` (`DUAT_FRESH=1`), `sphinxtour` (`DUAT_ORN=1`), `touchshot`; `DUAT_SHOTS` sceglie la cartella
  (i comandi a tocco NON compaiono negli screenshot senza schermo). Bot: schiva sfera di Khepri, carica del guardiano,
  salto dello sciacallo, picchiata, miccia dei Ba; porta scelta una volta (`door_pick`: l'indecisione tra porte uguali
  sembrava uno stallo); `DUAT_TRIAL=1` (+ `DUAT_MODS=a,b`) gioca la prova della Sfinge, campo `trial` nel risultato.
- *Dati*: Sokar con bot corretto (12 veterani, 12 doni): 1 vittoria, 5 arrivano ad Aker (gli resta 37-77%): vicino
  all'obiettivo. Sfinge (24 prove): ondate 5-23, mediana ≈10, sigilli mediana ≈15 (Favore 450 ≈ 28 prove). Wernes
  (24 partite senza meta, veterani e abituali): 1 vittoria (arco), quasi tutti cadono tra Serpente e stanza 8; fonti di danno:
  veleno del Serpente, scarabei, coccodrilli, mummie. **Lancia ancora ultima** (5 su 6 morti con gli scarabei prima
  fonte): prossimo ritocco da valutare (cono degli affondi o spinta), dopo le impressioni del proprietario.
- *Terza regione*: rimandata di proposito (Sokar ha ancora poche vittorie e nessuna impressione dal proprietario).

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
4. Raccogliere le impressioni sulla Sfinge (durezza delle ondate e dei guardiani, enigmi, premi) e ritarare.
5. Dopo: abbellimenti del Cortile (armeria); pagina itch.io e modulo feedback (il proprietario fornisce `FEEDBACK_URL`);
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
