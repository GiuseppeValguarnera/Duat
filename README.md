# Duat

Roguelike action nell'oltretomba egizio, fatto con Godot 4.7.

**Stato:** fase 2. C'è la Sala del Giudizio (base tra una discesa e l'altra, con Anubi e il Libro dei Morti) e la Prima Ora completa: 10 stanze, un guardiano a metà, il Traghettatore, Am-heh alla fine, con nemici diversi, ricompense, doni degli dèi, patti di Set e Forma Divina. La grafica è provvisoria (forme semplici) di proposito: prima si rende divertente il gioco, poi arrivano gli sprite.

## La storia

Il protagonista crede di essere lo scriba del faraone Akhet, il cui nome è stato cancellato da ogni pietra d'Egitto, e scende nel Duat per ricomporlo. Nella Sala del Giudizio, sopra il cancello, il cartiglio di Akhet riprende un segno a ogni vittoria. Ogni vittoria sul boss della Prima Ora fa riaffiorare un **Ricordo dello scriba** (nei Papiri di Thoth, in cima; il leggio brilla d'oro finché non lo leggi), e il Traghettatore cambia voce e prezzi man mano che la storia avanza. La trama completa, i colpi di scena e le regole per scrivere le battute sono in [`docs/storia.md`](docs/storia.md): contiene spoiler.

## Come provarlo

1. Apri Godot 4.7, clicca **Import** e scegli il file `project.godot` di questa cartella.
2. Premi **F5** per avviare.

## Giocare dal telefono

La versione web è su **https://giuseppevalguarnera.github.io/Duat/**. Su iPhone: aprila con Safari, poi *Condividi → Aggiungi alla schermata Home* e aprila dall'icona: così va a schermo intero, senza barre del browser (dentro Safari iOS non permette lo schermo intero; se apri il gioco da Safari una schermata lo spiega). Gioca in orizzontale.

Sul telefono il gioco si avvicina un po' e testi, carte e menu sono più grandi (`Fx.ui` in `scripts/fx.gd`); il formato si allarga per riempire anche gli schermi più lunghi del 16:9. Per vedere la versione telefono sul computer: avvia Godot con `-- --mobile`.

**Salvataggio a metà discesa:** all'inizio di ogni stanza la discesa viene salvata. Se chiudi il gioco (o il telefono chiude la pagina), al prossimo avvio riparti dall'inizio di quella stanza. Morte, vittoria e abbandono cancellano il salvataggio.

Sul telefono: levetta virtuale a sinistra (appare dove appoggi il pollice), a destra l'arma (tieni premuto), scatto, Occhio di Horus e Forma Divina, in alto pausa e doni. Mentre ti muovi colpisci nella direzione in cui vai, con un aiuto alla mira se c'è un nemico più o meno davanti; da fermo la mira va da sola sul nemico più vicino (si può spegnere: Opzioni, *Mira automatica*). Nella Sala il pulsante grande diventa *Azione*; nei menu si tocca direttamente.

Per aggiornare la versione web dopo una modifica: `tools/deploy_web.sh /percorso/di/Godot` (serve il modello di esportazione *Web* di Godot 4.7.2).


**Aggiornamenti senza reinstallare:** quando esce una versione nuova, nella Sala, in basso a destra (sul telefono sopra il pulsante *Azione*), lampeggia piano la scritta *Nuova versione, aggiorna!*: toccarla apre le Opzioni sulla voce giusta. Solo nella Sala, non durante la discesa, perché aggiornare la farebbe perdere. *Aggiorna il gioco* scarica la versione nuova e riapre il gioco: i progressi restano, perché l'app non viene cancellata. (Su iPhone, cancellare l'app dalla schermata Home cancella anche il salvataggio.) Funziona così: `tools/deploy_web.sh` scrive un numero di versione nella pagina e in `version.txt`; la pagina (`web/shell.html`) li confronta all'avvio e ogni 5 minuti; `scripts/updater.gd` lo mostra nel gioco.
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
| Pausa (nella Sala: opzioni) | Esc o P | Start |
| Torna alla Sala (dopo morte o vittoria) | R | Start |

## La Sala del Giudizio

Il gioco parte qui, e qui torni dopo ogni discesa.

- **Anubi** parla con te: commenta com'è andata l'ultima discesa (chi ti ha ucciso, quale dio hai seguito, se hai stretto patti con Set) e, man mano che muori o vinci, racconta la storia del tuo nome scalpellato. Se gli parli ancora, ti spiega il giudizio dei morti: la pesatura del cuore, Ma'at, i 42 giudici, le parti dell'anima. Le battute sono in `scripts/dialogue.gd`.
- **I Papiri di Thoth** (lo scaffale in basso a destra): l'archivio di tutto quello che gli dèi ti hanno raccontato, diviso per dio, più le lezioni di Anubi e la storia dei capitoli che hai comprato. Le storie non ancora ascoltate restano sigillate.
- **Il Libro dei Morti** (il leggio a destra): spendi il Ka custodito per comprare capitoli, incantesimi passivi che valgono per sempre. Puoi tenerne attivi solo 2 alla volta (3 dopo aver sconfitto Am-heh, fino a 5 con i posti comprati), quindi prima di ogni discesa scegli quali portare.
- **La bilancia di Ma'at** al centro mostra i tuoi progressi.
- **Il cancello** a nord: camminaci dentro per iniziare una discesa.
- **Gli stendardi** sulla parete nord: uno per ogni dio, si colorano quando quel dio ti ha parlato per la prima volta.

| Capitolo | Effetto (livello 1 → 2 → 3) | Costo in Ka (livello 1 / 2 / 3) |
| --- | --- | --- |
| 17 · Uscire al giorno | Inizi ogni discesa con +15 → 25 → 35 vita massima. | 60 / 140 / 260 |
| 89 · Il ritorno del Ba | L'Occhio di Horus si ricarica il 15 → 22 → 30% più in fretta. | 60 / 140 / 260 |
| 56 · Il soffio d'aria | Lo scatto si ricarica il 10 → 18 → 25% più in fretta. | 60 / 140 / 260 |
| 154 · Il corpo incorrotto | L'Acqua del Nilo ti cura del 40 → 45 → 50% invece che del 30%. | 70 / 150 / 280 |
| 99 · La barca di Ra | I tesori di Ka valgono il 30 → 45 → 60% in più. | 80 / 170 / 300 |
| 110 · I Campi di Iaru | Inizi ogni discesa con 15 → 25 → 40 Ka da spendere dal Traghettatore. | 80 / 170 / 300 |
| 94 · Calamaio e tavolozza | Al Traghettatore tutto costa il 15 → 25 → 35% in meno. | 70 / 150 / 280 |
| 42 · Ogni membro è un dio | L'Occhio di Horus fa il 10 → 18 → 25% di danni in più. | 80 / 170 / 300 |
| 151 · La maschera | In ogni stanza il primo colpo che ricevi fa il 40 → 60 → 80% di danni in meno. | 90 / 190 / 320 |
| 125 · La confessione negativa | Finché hai più dell'80% della vita fai il 15 → 22 → 30% di danni in più. | 100 / 200 / 340 |
| 30 · Il cuore che non testimonia | Una volta per discesa sopravvivi a un colpo mortale con il 5 → 20 → 35% della vita. | 120 / 220 / 360 |
| 6 · Gli Ushabti | Una statuetta servitrice ti segue e colpisce il nemico più vicino ogni 2.0 → 1.6 → 1.3 secondi. | 140 / 240 / 380 |
| 72 · Le porte aperte | Dopo ogni stanza si aprono sempre tre porte. | 220 |

Ogni capitolo ha fino a 3 livelli: comprato il primo, sulla pagina compare *Potenzia*. Con il Ka si comprano anche **posti in più** nel Libro (400 e poi 800 Ka).

I numeri sono quelli dei veri capitoli del Libro dei Morti, e ognuno nel Libro mostra anche a cosa serviva davvero. Per aggiungerne uno: una riga in `ALL` in `scripts/chapters.gd`, poi l'effetto dove serve usando `Run.chap("id")`.

Dal menu di pausa, *Torna alla Sala (abbandona)* chiude la discesa: il Ka raccolto viene comunque custodito.

## Opzioni

Nella Sala, Esc o Start aprono le opzioni:
- **Piuma di Ma'at**: modalità aiuto facoltativa. Subisci il 10% di danni in meno, +2% a ogni morte, fino al 50%. In cambio custodisci solo il **40% del Ka** e il Peso del Cuore non conta (né i pesi né il record).
- Scuotimento dello schermo, pausa sui colpi, *Rifai l'addestramento* (la prossima discesa ricomincia dalla stanza di prova), volume generale e musica.

Se il gioco perde il focus (una chiamata, un'altra finestra) va in pausa da solo. *Esci* dal menu di pausa lascia la discesa salvata.

## Il Cortile di Neith e le armi

Dalla Sala del Giudizio, una porta nella parete ovest (con lo scudo e le frecce incrociate di Neith) porta al **Cortile di Neith**. Si apre dopo la prima vittoria sul Serpente della Porta: la prima volta Neith, la dea guerriera di Sais, ti consegna la **Lancia di Neith** (`scripts/armory.gd`, `scenes/armory.tscn`).

- **Piedistalli**: le armi come offerte votive. Avvicinati e premi Azione per impugnarla: con quella scendi nel Duat. Le quattro ancora da forgiare (Arco di Satet, Flagello di Osiride, Scettro was, Artigli di Bastet) restano coperte da un telo.
- **Altare degli aspetti**: ogni arma ha 3 aspetti (il primo è libero), ognuno con 3 livelli. Si risvegliano e si potenziano con le **Lacrime di Iside**.
- **Ushabti**: statuine d'argilla da colpire, che si ricompongono da sole ("Eccomi!"). La **stele** accanto misura l'ultimo colpo, la combinazione e i danni al secondo.
- **Porta delle prove**: fa uscire scarabei, mummie, un sacerdote, scorpioni, un cobra o tutti insieme. Nel cortile non si muore.

| Arma | Come si gioca | Aspetti |
| --- | --- | --- |
| Khopesh | Fendenti ampi da vicino, il terzo colpo è il più forte | del Faraone (+danni) · di Montu (terzo colpo più lungo e più forte) · di Wepwawet (dopo uno scatto, fendente circolare) |
| Lancia di Neith | Due affondi lunghi e stretti, poi un'ampia spazzata; subito dopo uno scatto, un affondo lunghissimo | di Neith (+danni) · di Onuris (affondi più lunghi) · di Khonsu (la spazzata stordisce) |

**Lacrime di Iside**: arrivano solo dai boss delle regioni (oggi Am-heh, 2 Lacrime), la **prima volta** che li batti **con ogni arma** e di nuovo con il Peso del Cuore a 4 e a 8. Il Serpente della Porta, guardiano di mezzo, non ne dà. Rivincere con la stessa arma non dà altre Lacrime: per crescere bisogna cambiare arma. Il Libro dei Morti ora si paga solo in Ka; il capitolo 26, *Il cuore restituito*, dà una piccola probabilità (3/5/7%) che i nemici lascino un cuore che cura 5/6/7 punti vita (livelli e posti in più compresi). Dati in `scripts/weapons.gd`; i testi dei doni scritti per il khopesh si adattano da soli all'arma impugnata.

## Come funziona una run

0. **La prima volta: l'addestramento.** Una stanza vera con fantocci al posto dei nemici, un passo alla volta, con il testo in un riquadro di papiro fisso in alto (mai sopra i nemici): muoversi, il khopesh, lo scatto attraverso una mummia d'allenamento che diventa rossa e carica, l'Occhio di Horus su fantocci che si rompono solo con l'Occhio, il Ka (cos'è e a cosa serve) e le porte. Non si può morire e si può saltare. Poi comincia la discesa vera (`scripts/tutorial.gd`, fantocci in `scripts/dummy.gd`).
1. All'inizio Anubi pesa il tuo cuore: scegli uno dei suoi doni, ognuno con un vantaggio e un prezzo più piccolo.
2. Ogni stanza ha due ondate di nemici (nelle prime due un po' più piccole; sacerdoti e trappole dalla terza). La prima stanza non ha ricompensa: i doni degli dèi arrivano dalle stanze che scegli tu.
3. Quando la ripulisci compare la ricompensa: camminaci sopra per prenderla. Il Ka arriva soprattutto dai tesori: scarabei 0, mummie 1, sacerdoti 2.
4. Si aprono 2 o 3 porte, e sopra ognuna vedi cosa c'è dietro: il dono di un dio, un tesoro di Ka o una cura. Le porte fuori dallo schermo hanno una **freccia sul bordo** con il colore e il nome della ricompensa.
5. **Stanza 5: il Serpente della Porta.** Nel Libro delle Porte ogni porta del Duat è custodita da un serpente. È il guardiano a metà discesa: morde in affondo, sputa ventagli di veleno e si inabissa nella sabbia per riemergere sotto di te (un cerchio rosso avvisa dove). Sotto metà vita si infuria: più rapido, ventaglio più largo e **affondi doppi**. Combatte da solo (340 vita: più del vecchio 260, perché chi gioca davvero lo batteva al primo tentativo). Batterlo dà un dono che sale **di due livelli** invece di uno.
6. **Il Traghettatore** (Mahaf, dal capitolo 99 del Libro dei Morti): è una delle porte, ma solo nella stanza **subito prima del Serpente** (stanza 4) e **subito prima di Am-heh** (stanza 10). Vende Acqua del Nilo (20 Ka), un'offerta agli dèi (40 Ka) e l'Inchiostro di Thoth, che alza di livello un tuo dono (30 Ka). Si spende il Ka raccolto in questa discesa, e quello speso non torna a casa: più forti ora o capitoli dopo.
7. Dalla stanza 6 arrivano due nemici nuovi: lo **scorpione di Serket** e il **cobra**.
8. Prima dell'ultima stanza una delle porte è sempre l'**Acqua del Nilo**. Dopo la decima stanza si apre il cancello di **Am-heh**, il boss della Prima Ora. I nemici hanno il 6% di vita in più a ogni stanza.

## Il serdab: la stanza segreta

Nelle tombe egizie il *serdab* era una stanzetta murata, senza porta, che custodiva la statua del Ka del defunto: gli dèi la guardavano da una fessura. Nella discesa, ogni tanto (al massimo una volta a discesa, dalla seconda stanza, mai nelle stanze del Serpente, del Traghettatore, di Set e del boss; in circa 2 discese su 3), quando ripulisci una stanza un tratto del muro in alto ha una **crepa** con un geroglifico storto, e se ti avvicini cade un filo di polvere. Tre colpi d'arma e il muro crolla. Dentro: buio, pareti piene di geroglifici, la statua del Ka con le braccia alzate e un'iscrizione (formule d'offerta e maledizioni come quelle delle tombe vere, sul re in generale), un po' di Ka (30-45) e una volta su due un cuore che cura 10. Niente nemici e niente trappole. Si esce dallo stesso buco e si prosegue (`scripts/serdab.gd`; per le prove `DUAT_SERDAB=always`).

## Nemici

| Nemico | Comportamento | Come affrontarlo |
| --- | --- | --- |
| Mummia | Lenta e resistente. Da vicino diventa rossa e prepara un affondo | Schiva al momento giusto, o interrompila col terzo colpo della combo |
| Scarabei | Arrivano a gruppi di tre, veloci e fragili, a zig-zag | Colpi ampi e Occhio di Horus |
| Sacerdote di Set | Resta lontano e lancia sfere. Prima di lanciare si ferma e la sfera cresce | Spostati negli ultimi istanti, o colpiscilo per interromperlo |

Dalla terza stanza alcune mummie e alcuni sacerdoti sono **élite**: alone dorato, più grossi, +80% di vita, lasciano più Ka.

### Nemici della seconda metà

- **Scorpione di Serket**: veloce, ti gira intorno e punge con la coda. Avviso: la coda si alza e si illumina di verde. La puntura **avvelena**: perdi 2 vita ogni 0,6 secondi per 3 secondi (il veleno non può ucciderti).
- **Cobra**: resta a distanza, alza il cappuccio (avviso con la linea verde) e sputa tre gocce in fila. Poi si nasconde sotto la sabbia e riemerge altrove: va colpito quando è fuori.

## Trappole (dalla terza stanza)

- **Spuntoni:** lastre nel pavimento. I fori si illuminano, poi escono le punte: feriscono te (10) e anche i nemici (14).
- **Feritoie (dalla terza stanza):** teste di cobra nelle pareti laterali. Gli occhi si accendono, poi sparano un dardo che attraversa la stanza.

Lo scatto le supera entrambe. A stanza ripulita si fermano.

## Acqua e fuoco: le acque di Wernes

La Prima Ora ha i suoi pericoli, gli stessi che si ritrovano contro Am-heh (`scripts/hazards.gd`, disposizione in `place_elements` di `scripts/room_builder.gd`):

- **Pozze e canali d'acqua:** rallentano te e i nemici del 30% e spengono le fiamme; il fuoco non vi entra.
- **Grate di fuoco:** file di tre grate che si arroventano per quasi un secondo e poi sputano fiamme (9 danni). Bruciano anche i nemici.
- **Giare d'olio:** si rompono colpendole con l'arma o con l'Occhio. L'olio prende fuoco dopo 0,6 secondi (il tempo per allontanarsi) e brucia per 4 secondi; il fuoco accende le giare vicine, a catena. Sono uno strumento: rompile quando i nemici ci sono attorno.
- Le **mummie**, fasciate di lino, prendono il 50% di danni in più dal fuoco.

| Stanze | Cosa compare |
| --- | --- |
| 1-2 | al massimo una pozza |
| 3-5 | acqua e giare d'olio, spuntoni come prima |
| 6-8 | anche una grata di fuoco, uno spuntone in meno |
| 9-10 | due grate di fuoco, due spuntoni in meno; a volte due specchi d'acqua |

Gli spuntoni tornano protagonisti nel deserto di Sokar, la seconda regione. Da fare: un capitolo del Libro dei Morti che faccia lasciare Ka alle giare, come in Hades.

## Boss della Prima Ora: Am-heh, il Divoratore di Milioni

Nel mito è un dio dalla testa di cane che vive in un lago di fuoco del Duat e divora le anime dei dannati (`scripts/amheh.gd`). Ha 1000 punti vita. L'arena ha **quattro pozze d'acqua**: rallentano (anche i nemici) e spengono le fiamme, e il fuoco non vi entra (`scripts/hazards.gd`).

- **Morso:** da vicino, un ventaglio rosso davanti alle fauci, poi azzanna (20 danni).
- **Balzo:** un cerchio rosso segna dove atterrerà (20 danni); all'atterraggio accende un anello di fuoco.
- **Fiato di fuoco:** un cono arancione mostra la direzione, poi soffia per un secondo, girando lentamente verso di te; le fiamme restano a terra qualche secondo e bruciano anche gli altri nemici.
- **Marea di fuoco:** ogni 3 attacchi (ogni 2 sotto il 60%) ulula, le piastrelle si accendono di rosso a ondata, poi divampa tutto il pavimento tranne l'acqua (22 danni). Si sopravvive in una pozza o scattando nell'istante della vampata. Dopo resta **esausto** 2 secondi e subisce il 50% di danni in più.
- **Al 60% e al 30% della vita** fa evaporare la pozza più vicina (ne restano sempre due) e chiama scarabei (poi scarabei e un sacerdote).

## Ammit, la Divoratrice (in attesa del finale)

Ammit non è più il boss della Prima Ora: tornerà come boss finale nella Sala delle Due Verità, con una bilancia e una risposta diversa per ogni arma (vedi `docs/storia.md`). Il combattimento attuale resta nel codice (`BOSS_KIND` in `scripts/game.gd`) come base.

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
| Horus (l'Occhio) | Ritorno del Falco (l'Occhio torna e colpisce ancora), Volo del Falco (insegue il nemico più vicino), Il Sole e la Luna (2-4 cariche), Sguardo del Falco (chi è colpito dall'Occhio prende più danni dal khopesh) · pesante: Occhio del Re (Occhio ×2 e trapassa tutto, khopesh −40%) |
| Thoth (Occhio di Horus) | Sguardo di Thoth, Calcolo di Thoth, Occhio Moltiplicato, Parola dello Scriba · pesante: Conoscenza Proibita |
| Bastet (critici e agilità) | Artigli Affilati, Occhi di Gatto, Passo Felino, Protezione di Bastet · pesante: Gioco del Gatto |
| Sobek (resistenza e controllo) | Pelle di Coccodrillo, Morso di Sobek, Marea del Nilo, Forza del Fiume · pesante: Fauci di Sobek |
| Iside (protezione e cure) | Ali di Iside, Lacrime di Iside, Nodo di Iside, Nome Segreto di Ra (solo dopo aver sbloccato il Sekhem) · pesante: Abbraccio di Iside |
| Anubi (solo a inizio run, doni-bilancia con un piccolo prezzo) | Cuore Leggero, Cuore di Pietra, Fiuto dello Sciacallo, Bilancia Giusta, Guida delle Anime, Vasi Canopi, Apertura della Bocca, Bende di Lino, Custode della Necropoli, Offerte ai Defunti |

**Doni delle armi:** alcuni doni compaiono solo con un'arma in mano e ne esaltano lo stile (sulla carta: "solo Lancia di Neith" o "solo Khopesh").

| Arma | Dono | Dio | Effetto |
| --- | --- | --- | --- |
| Lancia | Arpione di Horus | Horus | Affondi più forti sui nemici lontani, sulla punta |
| Lancia | Punta Felina | Bastet | L'affondo dopo lo scatto può essere critico |
| Lancia | Colpo di Coda | Sobek | Spazzata più forte, scaglia il doppio |
| Khopesh | Zanna Ricurva | Sekhmet | Primi due fendenti più forti |
| Khopesh | Danza delle Lame | Bastet | Colpi più rapidi |
| Khopesh | Filo del Sole | Ra | Fendenti più lunghi e più ampi |

Forza del Fiume e cinque Doni Doppi compaiono solo se hai già i doni con cui si combinano (`Boons.REQUIRES`).

**Doni Doppi:** quando hai già doni di due dèi, a volte (45%) uno dei due ti offre un dono che li unisce (carta dorata). Sono 9, almeno uno per ogni dio; l'Arpione del Coccodrillo esiste solo con la lancia. Misurato con 2000 partite simulate: in una discesa con 9 doni ne compare almeno uno circa 2 volte su 3 (7 su 10 con la lancia), con 6 doni 1 volta su 3. Con il Peso del Cuore *silenzio* le scelte sono due e il doppio prende la seconda.

| Dono Doppio | Dèi | Effetto |
| --- | --- | --- |
| Occhio del Sole | Ra + Thoth | L'Occhio incendia sempre ed esplode quando si ferma |
| Sole Furente | Ra + Sekhmet | I nemici in fiamme subiscono +25% dal khopesh |
| Caccia delle Leonesse | Sekhmet + Bastet | I critici del khopesh liberano un ruggito |
| Sguardo del Gatto Sapiente | Thoth + Bastet | Un critico dell'Occhio ne dimezza la ricarica |
| Piena Sacra | Sobek + Iside | Con lo scudo di Iside il khopesh fa +25% |
| Occhio Risanato | Horus + Thoth | Se l'Occhio abbatte un nemico si ricarica subito (Thoth guarì l'Occhio di Horus) |
| Figlio di Iside | Iside + Horus | Ogni lancio dell'Occhio che va a segno cura 2 punti vita |
| Giudizio della Leonessa | Anubi + Sekhmet | L'arma abbatte all'istante i nemici sotto il 15% della vita (non guardiani e boss) |
| Arpione del Coccodrillo | Sobek + Horus | Solo lancia: la punta dell'affondo stordisce per 0,6 secondi |

Senza doni l'Occhio di Horus si ferma sul primo nemico che colpisce.

I nemici colpiti barcollano per un terzo di secondo: non si muovono e non fanno danno da contatto. Le mummie durante l'affondo non barcollano.

## Le divinità parlano

**La scelta dei doni.** In alto c'è il ritratto del dio, dipinto alla maniera egizia (profilo, occhio con il kohl, collare usekh, corone e simboli di ognuno: la doppia corona di Horus, il disco di Ra, la luna di Thoth, il trono di Iside...). I ritratti sono disegnati in SVG da `tools/portraits/make_portraits.py` e trasformati in PNG da `tools/portraits/render.js`; il busto esce dal medaglione e si anima mentre parla, e le sue parole compaiono man mano. Sotto, le carte sono **papiri**: nomi in Cinzel, testi in Macondo (tratto da pennello, ma leggibile), titoli grandi in Cinzel Decorative con un riflesso d'oro che scorre (tutti font OFL): etichetta, nome, descrizione, prezzo e in fondo il **riassunto** (▲ cosa guadagni, ▼ cosa paghi), così dopo la prima lettura si sceglie a colpo d'occhio. Quando prendi il dono: lampo del colore del dio, anello di luce attorno a te, scintille e il nome del dono al centro.

Ogni volta che un dio ti offre un dono, ti parla. La prima volta si presenta; poi, a ogni incontro, racconta un pezzo del suo mito (Ra e il serpente Apophis, Iside che ricompone Osiride, Thoth che vince cinque giorni alla Luna, i gatti sacri di Bastet...), una volta sola. Quando ha raccontato tutto, risponde con frasi brevi. Le storie sono in `scripts/lore.gd`: sono fatti della mitologia e della storia egizia, semplificati ma non inventati. Ogni dio ha la sua voce (Ra solenne e cosmico, Sekhmet feroce, Thoth misurato, Bastet regale, Sobek lento, Iside materna, Set sprezzante) e parla sempre in prima persona: i fatti moderni, come le statue di Sekhmet nei musei, li racconta come profezie.

**I tuoi doni durante la scelta:** mentre scegli un dono, Tab / Select o il pulsante *I tuoi doni* in alto a destra mostrano quelli che hai già, per costruire le combinazioni.

## Patti di Set

A volte, oltre alle porte normali, Set apre un **varco in più nella parete sud**: è una deviazione, come le porte del Caos in Hades. Arriva di rado: mai nella prima stanza né davanti al Serpente o al boss, almeno 3 stanze tra un varco e l'altro e al massimo 2 a discesa. La probabilità parte dal 20% e cresce un poco a ogni stanza senza Set: in 7 discese su 10 lo incontri una volta, in 2 due volte, in 1 mai (`SET_DOOR_*` in `scripts/game.gd`). Entrare costa 8 punti vita; dentro c'è l'altare di Set, senza nemici, e la stanza non conta nella discesa. Scegli un patto, poi si riaprono le stesse porte che avevi lasciato: non perdi nessun dono. Il patto è una **maledizione** per le 2 stanze successive e poi una **benedizione** per tutta la discesa. Tempesta Interiore (Sekhem) compare solo dopo aver sbloccato il Sekhem.

Davanti ai guardiani, ai boss e al Traghettatore Set tace: la maledizione non agisce e non conta la stanza. Le maledizioni colpiscono qualunque stile di gioco, così non si possono aggirare: nemici più veloci del 20%, +30% di danni subiti, nemici con il 25% di vita in più, cure ridotte del 40%, oppure 1 vita persa ogni 3 secondi mentre combatti. Le benedizioni: +25% a tutti i danni, +15 vita massima, Sekhem +50%, +15% velocità, +50% Ka, attacchi più rapidi del 20%.

Bilanciato con i bot (patto forzato nella stanza 2 contro nessun patto, stesse partite): quando Set prendeva il posto di una porta, il patto costava anche un dono e chi lo prendeva superava il Serpente 1 volta su 10 contro 7.

## Il Peso del Cuore

Dopo la prima vittoria su Am-heh, la **bilancia di Ma'at** al centro della Sala diventa interattiva: prima di scendere puoi posarvi dei pesi. Ogni livello di peso rende la discesa più dura e ti fa custodire il **10% di Ka in più**. Il gioco ricorda il peso più alto con cui hai battuto Ammit. È la sfida per chi ha già vinto, sul modello del Patto di Punizione di Hades.

| Peso | Effetto | Livelli |
| --- | --- | --- |
| Piume di piombo | Nemici +20% vita per livello | 2 |
| Zanne affilate | +20% danni subiti per livello | 2 |
| Le orde del Duat | +25% nemici per ondata per livello | 2 |
| Il sangue dei campioni | Élite il doppio delle volte, dalla stanza 2 | 1 |
| Sabbie traditrici | Trappole dalla prima stanza, e di più | 1 |
| Il Nilo in secca | L'Acqua del Nilo cura la metà | 1 |
| Il silenzio degli dèi | Due doni tra cui scegliere invece di tre | 1 |
| La fame di Am-heh | Am-heh +30% vita, la marea di fuoco arriva più spesso | 1 |

I pesi sono in `scripts/weights.gd`.

## Sekhem e Forma Divina

Il Sekhem è il dono di **Am-heh**: si sblocca per sempre la prima volta che lo sconfiggi (salvato in `user://duat_save.cfg`). Dalla run successiva si carica facendo e subendo danni. Quando è pieno attivi la **Forma Divina** per 6 secondi: onda d'urto iniziale, +50% ai danni del khopesh e solo il 30% dei danni subiti.

## Suoni

Spuntoni, mummie, scorpioni, cobra e Serpente hanno suoni costruiti apposta (`tools/synth_sfx.py`): lastra che scatta e lame che escono, bende che sfregano e rantolo, zampette di chitina, sibili, sabbia che si apre. Am-heh ringhia prima del morso e del balzo, azzanna con un latrato secco, atterra con un tonfo, ulula prima della marea (la voce sale e ridiscende) e ansima quando è esausto. Il fuoco soffia (fiato di Am-heh, grate), si accende (olio, fuoco a terra) e divampa (marea). I colpi a segno hanno il tintinnio della scintilla (più pieno sui colpi forti), le giare si rompono come coccio, l'acqua fa uno schizzo quando ci entri, l'anima dei nemici sale con un sussurro. Si rigenerano con `python3 tools/synth_sfx.py <pacchetti Kenney> assets/sfx nome1,nome2`.

I suoni vengono dai pacchetti CC0 di [Kenney](https://kenney.nl/assets/category:Audio) (*Impact Sounds*, *Interface Sounds*, *RPG Audio*): uso libero anche commerciale. Crediti in `assets/sfx/CREDITS.md`.

Anche i nemici hanno i loro suoni: lo zampettio degli scarabei, i passi trascinati e lo scricchiolio delle mummie prima dell'affondo, l'incantesimo dei sacerdoti e le loro sfere magiche. Più un nemico è lontano, più è piano; fuori dallo schermo non si sente (`Sfx.play_at`).

Ogni suono può avere più varianti (`hit.ogg`, `hit_2.ogg`, ...): il gioco ne sceglie una a caso, così i colpi ripetuti non suonano tutti uguali. Per cambiare un suono basta sostituire il file con lo stesso nome; `tools/convert_sfx.py` rifà la conversione dai pacchetti originali e porta tutti i file allo stesso volume.

## Musica

Quattro brani, con dissolvenza incrociata da uno all'altro (`scripts/music.gd`):

| Momento | Brano |
| --- | --- |
| Sala del Giudizio | Desert Mystic, PolygonDan (CC0) |
| Stanze | Desert Loop, iamoneabe (CC0) |
| Serpente della Porta, e stanze con nemici élite (dalla comparsa del primo) | Frozen Desert, Dizzy Crow (CC0) |
| Traghettatore | Desert Mystic (come la Sala) |
| Ammit | Arabesque, brainiac256 (**CC-BY 3.0**, va citato nei crediti) |

Alla morte suona un breve tema funebre (`death.ogg`, ricavato dai suoni CC0 del gioco: campana rallentata con eco e un bordone basso), alla vittoria torna il tema della Sala. Crediti completi in `assets/music/CREDITS.md`.

**Volume:** nel menu di pausa, voce *Volume*, c'è un cursore per il volume generale, uno per la musica e uno per ogni categoria di suoni (attacchi, scatto, danni subiti, nemici e boss, trappole, ricompense e menu). Le impostazioni vengono salvate.

## Fine della run

Alla morte tutto rallenta, un lampo rosso, lo schermo si scurisce e compare la bilancia di Ma'at: il cuore scende, più pesante della piuma. Poi il papiro con chi ti ha ucciso e il riepilogo. Alla vittoria compare un riepilogo (tempo, nemici, danni, doni, Ka). Il Ka raccolto viene **custodito** tra una run e l'altra nel salvataggio e si spende nel Libro dei Morti. Premi R o Start per tornare alla Sala del Giudizio.

## Playtest automatico

`tools/playtest/` contiene un bot che gioca davvero (senza invulnerabilità) con sette stili di giocatore: novizio, casual, veterano, speedrunner, min-maxer, prudente, cecchino. Registra vittorie, stanze raggiunte, danni subiti per fonte, tempi e doni scelti.

```
python3 tools/playtest/run_playtest.py --godot /percorso/di/Godot --seeds 16
python3 tools/playtest/run_playtest.py --godot ... --personas veterano --env "DUAT_ANUBI=Cuore di Pietra"
```

Prima di pubblicare: `python3 tools/check_glyphs.py` controlla che ogni simbolo dei testi esista nei caratteri del gioco (nel browser del telefono un simbolo mancante diventa un quadratino).

Il bot gioca peggio di una persona, quindi serve per i **confronti** (stesse partite, cambia una sola scelta), non per misurare la difficoltà assoluta. Con lui sono stati bilanciati i patti di Set, i doni di Anubi e il Peso del Cuore: per esempio Cuore di Pietra a +30 vita portava il bot da 1 a 7 vittorie su 16, ora è a +12. Con la Prima Ora a 10 stanze, il bot "veterano" arriva da Ammit circa 9 volte su 16, con circa 8 doni, e il Serpente della Porta ne ferma circa un quarto.

## Regolare la sensazione di gioco

Apri una scena in `scenes/`, seleziona il nodo principale e cambia i valori nell'**Ispettore**: velocità, vita, danno, tempi di ricarica. Le tre mosse della combo sono nella tabella `COMBO` in `scripts/player.gd`.

## HUD

In alto a sinistra, in un riquadro scuro con il bordo d'oro: l'ankh accanto alla vita (la barra lascia una scia chiara quando subisci danno, l'ankh lampeggia sotto un terzo), il Sekhem, il geroglifico del Ka con il suo numero (che "salta" quando sale), la stanza, e l'Occhio di Horus che si riempie di blu mentre si ricarica, con un pallino per ogni carica.

## Struttura

```
scenes/   hub.tscn (la Sala del Giudizio), game.tscn (la run), serpent.tscn, scorpion.tscn, cobra.tscn, player.tscn, mummy.tscn, scarab.tscn, priest.tscn
tools/    convert_sfx.py  prepara i suoni dai pacchetti di Kenney
          playtest/    bot di playtest automatico
scripts/  hub.gd       la Sala del Giudizio      dialogue.gd   battute di Anubi
          lore.gd      storie degli dèi e Papiri di Thoth
          weights.gd   il Peso del Cuore
          music.gd     musica di sottofondo
          chapters.gd  Libro dei Morti           ushabti.gd    la statuetta del capitolo 6
          meta.gd      salvataggio permanente     sfx.gd        suoni e volumi
          game.gd      stanze, ondate, ricompense, porte, menu dei doni
          room_builder.gd  costruzione delle stanze: acqua, grate, giare, spuntoni, muri
          tutorial.gd  l'addestramento della prima volta
          hazards.gd   acqua, fuoco, grate, giare d'olio      amheh.gd   il boss della Prima Ora
          updater.gd   «Aggiorna all'ultima versione» (solo web)
          ui/          pezzi di interfaccia: barre dell'HUD, carte di scelta, frecce delle porte,
                       anello dei doni, bilancia della morte, icone
          room_decor.gd  arredamento delle stanze     traps.gd   trappole
          run.gd       stato della run (vita, Ka, doni) ed effetti dei doni
          boons.gd     elenco di dèi e doni
          enemy.gd     base comune a tutti i nemici
          mummy.gd, scarab.gd, priest.gd, scorpion.gd, cobra.gd   comportamento dei singoli nemici
          serpent.gd   il Serpente della Porta    ferryman.gd   il Traghettatore e il negozio
          player.gd, eye.gd, enemy_bolt.gd, pickup.gd, door.gd, reticle.gd
          fx.gd        effetti globali     input_setup.gd   comandi
          ui_style.gd  stile egizio: papiro, Cinzel     god_portrait.gd   ritratti degli dèi
          dummy.gd     fantocci dell'addestramento
```

### Aggiungere un nemico

Crea uno script che inizia con `extends Enemy` e scrivi due funzioni: `_behave()` (come si muove) e `_draw_body()` (come si disegna). Vita, colpi subiti, bruciatura e morte li gestisce già `enemy.gd`.

### Aggiungere un dono

Aggiungi una riga in `ALL` dentro `scripts/boons.gd`, poi scrivi il suo effetto dove serve, cercando il suo id con `Run.has("id_del_dono")`.
