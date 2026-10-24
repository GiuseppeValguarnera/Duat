# Duat

Roguelike action nell'oltretomba egizio, fatto con Godot 4.7.

**Stato:** fase 2. C'è la Sala del Giudizio (base tra una discesa e l'altra, con Anubi e il Libro dei Morti) e una run di 6 stanze più il boss, con nemici diversi, ricompense, doni degli dèi, patti di Set e Forma Divina. La grafica è provvisoria (forme semplici) di proposito: prima si rende divertente il gioco, poi arrivano gli sprite.

## Come provarlo

1. Apri Godot 4.7, clicca **Import** e scegli il file `project.godot` di questa cartella.
2. Premi **F5** per avviare.

## Comandi

| Azione | Tastiera e mouse | Controller |
| --- | --- | --- |
| Muoverti | WASD o frecce | Levetta sinistra |
| Mirare | Mouse | Levetta destra |
| Khopesh (tieni premuto per la combo) | Clic sinistro o J | RB (o X) |
| Scatto (invulnerabile) | Spazio, Shift o K | LB o A |
| Occhio di Horus | Clic destro o L | RT (o Y) |
| Forma Divina (quando il Sekhem è pieno) | Q | LT |
| Vedi i tuoi doni (mette in pausa) | Tab | Select |
| Mostra/nascondi hitbox | F1 | |
| Parla / apri il Libro (nella Sala) | E | Y |
| Pausa | Esc o P | Start |
| Torna alla Sala (dopo morte o vittoria) | R | Start |

## La Sala del Giudizio

Il gioco parte qui, e qui torni dopo ogni discesa.

- **Anubi** parla con te: commenta com'è andata l'ultima discesa (chi ti ha ucciso, quale dio hai seguito, se hai stretto patti con Set) e, man mano che muori o vinci, racconta la storia del tuo nome scalpellato. Se gli parli ancora, ti spiega il giudizio dei morti: la pesatura del cuore, Ma'at, i 42 giudici, le parti dell'anima. Le battute sono in `scripts/dialogue.gd`.
- **I Papiri di Thoth** (lo scaffale in basso a destra): l'archivio di tutto quello che gli dèi ti hanno raccontato, diviso per dio, più le lezioni di Anubi e la storia dei capitoli che hai comprato. Le storie non ancora ascoltate restano sigillate.
- **Il Libro dei Morti** (il leggio a destra): spendi il Ka custodito per comprare capitoli, incantesimi passivi che valgono per sempre. Puoi tenerne attivi solo 2 alla volta (3 dopo aver sconfitto Ammit), quindi prima di ogni discesa scegli quali portare.
- **La bilancia di Ma'at** al centro mostra i tuoi progressi.
- **Il cancello** a nord: camminaci dentro per iniziare una discesa.
- **Gli stendardi** sulla parete nord: uno per ogni dio, si colorano quando quel dio ti ha parlato per la prima volta.

| Capitolo | Effetto | Costo |
| --- | --- | --- |
| 17 · Uscire al giorno | +15 vita massima | 60 Ka |
| 89 · Il ritorno del Ba | Occhio di Horus 15% più rapido | 60 Ka |
| 154 · Il corpo incorrotto | L'Acqua del Nilo cura il 40% invece del 30% | 70 Ka |
| 99 · La barca di Ra | Tesori di Ka +30% | 80 Ka |
| 125 · La confessione negativa | +15% danni sopra l'80% di vita | 100 Ka |
| 30 · Il cuore che non testimonia | Una volta per discesa sopravvivi a un colpo mortale | 120 Ka |
| 6 · Gli Ushabti | Una statuetta ti segue e colpisce il nemico più vicino ogni 2 s | 140 Ka |

I numeri sono quelli dei veri capitoli del Libro dei Morti, e ognuno nel Libro mostra anche a cosa serviva davvero. Per aggiungerne uno: una riga in `ALL` in `scripts/chapters.gd`, poi l'effetto dove serve usando `Run.chap("id")`.

Dal menu di pausa, *Torna alla Sala (abbandona)* chiude la discesa: il Ka raccolto viene comunque custodito.

## Come funziona una run

1. All'inizio Anubi pesa il tuo cuore: scegli uno dei suoi doni, ognuno con un vantaggio e un prezzo più piccolo.
2. Ogni stanza ha due ondate di nemici. La prima stanza non ha ricompensa: i doni degli dèi arrivano dalle stanze che scegli tu.
3. Quando la ripulisci compare la ricompensa: camminaci sopra per prenderla. Il Ka arriva soprattutto dai tesori: scarabei 0, mummie 1, sacerdoti 2.
4. Si aprono 2 o 3 porte, e sopra ognuna vedi cosa c'è dietro: il dono di un dio, un tesoro di Ka o una cura.
5. Prima dell'ultima stanza una delle porte è sempre l'**Acqua del Nilo**, per curarti prima del boss. Dopo la sesta stanza si apre il cancello di **Ammit**, il boss della Prima Ora. I nemici hanno il 6% di vita in più a ogni stanza.

## Nemici

| Nemico | Comportamento | Come affrontarlo |
| --- | --- | --- |
| Mummia | Lenta e resistente. Da vicino diventa rossa e prepara un affondo | Schiva al momento giusto, o interrompila col terzo colpo della combo |
| Scarabei | Arrivano a gruppi di tre, veloci e fragili, a zig-zag | Colpi ampi e Occhio di Horus |
| Sacerdote di Set | Resta lontano e lancia sfere. Prima di lanciare si ferma e la sfera cresce | Spostati negli ultimi istanti, o colpiscilo per interromperlo |

Dalla terza stanza alcune mummie e alcuni sacerdoti sono **élite**: alone dorato, più grossi, +80% di vita, lasciano più Ka.

## Trappole (dalla seconda stanza)

- **Spuntoni:** lastre nel pavimento. I fori si illuminano, poi escono le punte: feriscono te (10) e anche i nemici (14).
- **Feritoie (dalla terza stanza):** teste di cobra nelle pareti laterali. Gli occhi si accendono, poi sparano un dardo che attraversa la stanza.

Lo scatto le supera entrambe. A stanza ripulita si fermano.

## Boss: Ammit, la Divoratrice

Testa di coccodrillo, corpo di leone, zampe di ippopotamo: nel mito divora i cuori che non superano il giudizio. Ha 1100 punti vita.

- **Carica:** si ferma e una striscia rossa mostra la traiettoria, poi scatta in linea retta. Se sbatte contro una colonna resta **stordita** per 2 secondi e subisce il 50% di danni in più, ma la colonna **crolla**: nell'arena ce ne sono solo 6. Durante la carica travolge anche gli altri nemici sulla sua strada (30 danni).
- **Sputo:** un anello viola si stringe attorno a lei, poi lancia sfere in tutte le direzioni.
- **Morso:** quando sei vicino, un ventaglio rosso si accende davanti alle fauci, poi azzanna (24 danni).
- **Ruggito del Giudizio:** si impenna, poi un'onda d'urto si allarga per tutta l'arena. Si supera scattandoci attraverso.
- **Furia (sotto metà vita):** è più veloce, lancia più sfere, fa due onde di fila e chiama 4 scarabei e un Sacerdote di Set, una volta sola.

## Doni

**Regola di bilanciamento:** un dono di livello 1 vale circa **+20% su un aspetto del gioco** (danno del khopesh, ricarica dell'Occhio, danni subiti, velocità...). I livelli 2 e 3 aggiungono circa metà ciascuno. Un dono pesante vale circa +50%, ma con un prezzo vero. I doni di Anubi danno un vantaggio un po' più grande del prezzo che chiedono. I numeri sono tutti in `ALL` in `scripts/boons.gd`.

Ogni dio offre sempre tre scelte. Ogni dono ha 3 livelli: quando un dio ha finito i doni nuovi, ti propone di potenziare quelli che hai. In circa una scelta su tre compare il **dono pesante** del dio: più forte, ma con un prezzo (`HEAVY_CHANCE` in `scripts/boons.gd`).

| Dio | Doni |
| --- | --- |
| Ra (fuoco) | Colpo Solare, Disco di Ra, Corsa dell'Alba (con prezzo: scatto più lento), Occhio Ardente · pesante: Ira del Sole |
| Sekhmet (furia) | Furia della Leonessa, Sete di Sangue, Ruggito, Balzo della Leonessa · pesante: Sete Insaziabile |
| Thoth (Occhio di Horus) | Sguardo di Thoth, Calcolo di Thoth, Occhio Moltiplicato, Parola dello Scriba · pesante: Conoscenza Proibita |
| Bastet (critici e agilità) | Artigli Affilati, Occhi di Gatto, Passo Felino, Protezione di Bastet · pesante: Gioco del Gatto |
| Sobek (resistenza e controllo) | Pelle di Coccodrillo, Morso di Sobek, Marea del Nilo, Forza del Fiume · pesante: Fauci di Sobek |
| Iside (protezione e cure) | Ali di Iside, Lacrime di Iside, Nodo di Iside, Nome Segreto di Ra (solo dopo aver sbloccato il Sekhem) · pesante: Abbraccio di Iside |
| Anubi (solo a inizio run, doni-bilancia con un piccolo prezzo) | Cuore Leggero, Cuore di Pietra, Fiuto dello Sciacallo, Bilancia Giusta, Guida delle Anime, Vasi Canopi, Apertura della Bocca, Bende di Lino, Custode della Necropoli, Offerte ai Defunti |

**Doni Doppi:** quando hai già doni di due dèi, a volte uno dei due ti offre un dono che li unisce (carta dorata).

| Dono Doppio | Dèi | Effetto |
| --- | --- | --- |
| Occhio del Sole | Ra + Thoth | L'Occhio incendia sempre ed esplode quando si ferma |
| Sole Furente | Ra + Sekhmet | I nemici in fiamme subiscono +25% dal khopesh |
| Caccia delle Leonesse | Sekhmet + Bastet | I critici del khopesh liberano un ruggito |
| Sguardo del Gatto Sapiente | Thoth + Bastet | Un critico dell'Occhio ne dimezza la ricarica |
| Piena Sacra | Sobek + Iside | Con lo scudo di Iside il khopesh fa +25% |

Senza doni l'Occhio di Horus si ferma sul primo nemico che colpisce.

I nemici colpiti barcollano per un terzo di secondo: non si muovono e non fanno danno da contatto. Le mummie durante l'affondo non barcollano.

## Le divinità parlano

Ogni volta che un dio ti offre un dono, ti parla. La prima volta si presenta; poi, a ogni incontro, racconta un pezzo del suo mito (Ra e il serpente Apophis, Iside che ricompone Osiride, Thoth che vince cinque giorni alla Luna, i gatti sacri di Bastet...), una volta sola. Quando ha raccontato tutto, risponde con frasi brevi. Le storie sono in `scripts/lore.gd`: sono fatti della mitologia e della storia egizia, semplificati ma non inventati. Ogni dio ha la sua voce (Ra solenne e cosmico, Sekhmet feroce, Thoth misurato, Bastet regale, Sobek lento, Iside materna, Set sprezzante) e parla sempre in prima persona: i fatti moderni, come le statue di Sekhmet nei musei, li racconta come profezie.

## Patti di Set

A volte compare una porta di **Set**: entrare costa 10 punti vita. A fine stanza scegli un patto: una **maledizione** che dura le 2 stanze successive e poi una **benedizione** permanente per tutta la run. Tempesta Interiore (Sekhem) compare solo dopo aver sbloccato il Sekhem.

Le maledizioni colpiscono qualunque stile di gioco, così non si possono aggirare: nemici più veloci del 30%, +50% di danni subiti, nemici con il 40% di vita in più, cure dimezzate, oppure 1 vita persa ogni 2 secondi mentre combatti. Se il patto arriva dopo la stanza 4, la maledizione dura anche contro Ammit (la carta lo dice).

## Il Peso del Cuore

Dopo la prima vittoria su Ammit, la **bilancia di Ma'at** al centro della Sala diventa interattiva: prima di scendere puoi posarvi dei pesi. Ogni livello di peso rende la discesa più dura e ti fa custodire il **10% di Ka in più**. Il gioco ricorda il peso più alto con cui hai battuto Ammit. È la sfida per chi ha già vinto, sul modello del Patto di Punizione di Hades.

| Peso | Effetto | Livelli |
| --- | --- | --- |
| Piume di piombo | Nemici +20% vita per livello | 2 |
| Zanne affilate | +20% danni subiti per livello | 2 |
| Le orde del Duat | +25% nemici per ondata per livello | 2 |
| Il sangue dei campioni | Élite il doppio delle volte, dalla stanza 2 | 1 |
| Sabbie traditrici | Trappole dalla prima stanza, e di più | 1 |
| Il Nilo in secca | L'Acqua del Nilo cura la metà | 1 |
| Il silenzio degli dèi | Due doni tra cui scegliere invece di tre | 1 |
| La fame di Ammit | Ammit +30% vita, ogni Ruggito libera due onde | 1 |

I pesi sono in `scripts/weights.gd`.

## Sekhem e Forma Divina

Il Sekhem è il dono di **Ammit**: si sblocca per sempre la prima volta che la sconfiggi (salvato in `user://duat_save.cfg`). Dalla run successiva si carica facendo e subendo danni. Quando è pieno attivi la **Forma Divina** per 6 secondi: onda d'urto iniziale, +50% ai danni del khopesh e solo il 30% dei danni subiti.

## Suoni

I suoni vengono dai pacchetti CC0 di [Kenney](https://kenney.nl/assets/category:Audio) (*Impact Sounds*, *Interface Sounds*, *RPG Audio*): uso libero anche commerciale. Crediti in `assets/sfx/CREDITS.md`.

Anche i nemici hanno i loro suoni: lo zampettio degli scarabei, i passi trascinati e lo scricchiolio delle mummie prima dell'affondo, l'incantesimo dei sacerdoti e le loro sfere magiche. Più un nemico è lontano, più è piano; fuori dallo schermo non si sente (`Sfx.play_at`).

Ogni suono può avere più varianti (`hit.ogg`, `hit_2.ogg`, ...): il gioco ne sceglie una a caso, così i colpi ripetuti non suonano tutti uguali. Per cambiare un suono basta sostituire il file con lo stesso nome; `tools/convert_sfx.py` rifà la conversione dai pacchetti originali e porta tutti i file allo stesso volume.

## Musica

Quattro brani, con dissolvenza incrociata da uno all'altro (`scripts/music.gd`):

| Momento | Brano |
| --- | --- |
| Sala del Giudizio | Desert Mystic, PolygonDan (CC0) |
| Stanze | Desert Loop, iamoneabe (CC0) |
| Stanza con nemici élite (dalla comparsa del primo élite) | Frozen Desert, Dizzy Crow (CC0) |
| Ammit | Arabesque, brainiac256 (**CC-BY 3.0**, va citato nei crediti) |

Alla morte la musica si abbassa, alla vittoria torna il tema della Sala. Crediti completi in `assets/music/CREDITS.md`.

**Volume:** nel menu di pausa, voce *Volume*, c'è un cursore per il volume generale, uno per la musica e uno per ogni categoria di suoni (attacchi, scatto, danni subiti, nemici e boss, trappole, ricompense e menu). Le impostazioni vengono salvate.

## Fine della run

Alla morte o alla vittoria compare un riepilogo (tempo, nemici, danni, doni, Ka). Il Ka raccolto viene **custodito** tra una run e l'altra nel salvataggio e si spende nel Libro dei Morti. Premi R o Start per tornare alla Sala del Giudizio.

## Playtest automatico

`tools/playtest/` contiene un bot che gioca davvero (senza invulnerabilità) con sette stili di giocatore: novizio, casual, veterano, speedrunner, min-maxer, prudente, cecchino. Registra vittorie, stanze raggiunte, danni subiti per fonte, tempi e doni scelti.

```
python3 tools/playtest/run_playtest.py --godot /percorso/di/Godot --seeds 16
python3 tools/playtest/run_playtest.py --godot ... --personas veterano --env "DUAT_ANUBI=Cuore di Pietra"
```

Il bot gioca peggio di una persona, quindi serve per i **confronti** (stesse partite, cambia una sola scelta), non per misurare la difficoltà assoluta. Con lui sono stati bilanciati i patti di Set, i doni di Anubi e il Peso del Cuore: per esempio Cuore di Pietra a +30 vita portava il bot da 1 a 7 vittorie su 16, ora è a +12.

## Regolare la sensazione di gioco

Apri una scena in `scenes/`, seleziona il nodo principale e cambia i valori nell'**Ispettore**: velocità, vita, danno, tempi di ricarica. Le tre mosse della combo sono nella tabella `COMBO` in `scripts/player.gd`.

## Struttura

```
scenes/   hub.tscn (la Sala del Giudizio), game.tscn (la run), player.tscn, mummy.tscn, scarab.tscn, priest.tscn
tools/    convert_sfx.py  prepara i suoni dai pacchetti di Kenney
          playtest/    bot di playtest automatico
scripts/  hub.gd       la Sala del Giudizio      dialogue.gd   battute di Anubi
          lore.gd      storie degli dèi e Papiri di Thoth
          weights.gd   il Peso del Cuore
          music.gd     musica di sottofondo
          chapters.gd  Libro dei Morti           ushabti.gd    la statuetta del capitolo 6
          meta.gd      salvataggio permanente     sfx.gd        suoni e volumi
          game.gd      stanze, ondate, ricompense, porte, menu dei doni
          room_decor.gd  arredamento delle stanze     traps.gd   trappole
          run.gd       stato della run (vita, Ka, doni) ed effetti dei doni
          boons.gd     elenco di dèi e doni
          enemy.gd     base comune a tutti i nemici
          mummy.gd, scarab.gd, priest.gd   comportamento dei singoli nemici
          player.gd, eye.gd, enemy_bolt.gd, pickup.gd, door.gd, reticle.gd
          fx.gd        effetti globali     input_setup.gd   comandi
```

### Aggiungere un nemico

Crea uno script che inizia con `extends Enemy` e scrivi due funzioni: `_behave()` (come si muove) e `_draw_body()` (come si disegna). Vita, colpi subiti, bruciatura e morte li gestisce già `enemy.gd`.

### Aggiungere un dono

Aggiungi una riga in `ALL` dentro `scripts/boons.gd`, poi scrivi il suo effetto dove serve, cercando il suo id con `Run.has("id_del_dono")`.
