# Duat

Roguelike action nell'oltretomba egizio, fatto con Godot 4.7.

**Stato:** fase 2, una run di prova di 6 stanze più il boss con nemici diversi, ricompense, doni degli dèi, patti di Set e Forma Divina. La grafica è provvisoria (forme semplici) di proposito: prima si rende divertente il gioco, poi arrivano gli sprite.

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
| Pausa | Esc o P | Start |
| Ricomincia (dopo morte o vittoria) | R | Start |

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

## Patti di Set

A volte compare una porta di **Set**: entrare costa 10 punti vita. A fine stanza scegli un patto: una **maledizione** che dura 2 ondate (nemici più veloci, più danni subiti, niente Occhio, scatto più lento) e poi una **benedizione** permanente per tutta la run. Tempesta Interiore (Sekhem) compare solo dopo aver sbloccato il Sekhem.

## Sekhem e Forma Divina

Il Sekhem è il dono di **Ammit**: si sblocca per sempre la prima volta che la sconfiggi (salvato in `user://duat_save.cfg`). Dalla run successiva si carica facendo e subendo danni. Quando è pieno attivi la **Forma Divina** per 6 secondi: onda d'urto iniziale, +50% ai danni del khopesh e solo il 30% dei danni subiti.

## Suoni

I suoni sono provvisori e generati da `tools/make_sfx.py` (nessuna licenza da rispettare).

**Per usare suoni veri:** metti in `assets/sfx/` un file `.ogg` con lo stesso nome di quello da sostituire (per esempio `hit.ogg`): ha la precedenza sul `.wav` generato. Fonti con licenza CC0 (uso libero anche commerciale, senza obbligo di citare): i pacchetti di [Kenney](https://kenney.nl/assets/category:Audio) (*Impact Sounds*, *RPG Audio*, *Interface Sounds*) e [OpenGameArt](https://opengameart.org) filtrando per CC0.

**Volume:** nel menu di pausa, voce *Volume*, c'è un cursore per il volume generale e uno per ogni categoria (attacchi, scatto, danni subiti, nemici e boss, trappole, ricompense e menu). Le impostazioni vengono salvate.

## Fine della run

Alla morte o alla vittoria compare un riepilogo (tempo, nemici, danni, doni, Ka). Il Ka raccolto viene **custodito** tra una run e l'altra nel salvataggio: servirà nella Sala del Giudizio.

## Regolare la sensazione di gioco

Apri una scena in `scenes/`, seleziona il nodo principale e cambia i valori nell'**Ispettore**: velocità, vita, danno, tempi di ricarica. Le tre mosse della combo sono nella tabella `COMBO` in `scripts/player.gd`.

## Struttura

```
scenes/   game.tscn (la run), player.tscn, mummy.tscn, scarab.tscn, priest.tscn
scripts/  game.gd      stanze, ondate, ricompense, porte, menu dei doni
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
