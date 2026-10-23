# Duat

Roguelike action nell'oltretomba egizio, fatto con Godot 4.7.

**Stato:** fase 2, una run di prova di 3 stanze con nemici diversi, ricompense, doni degli dèi, patti di Set e Forma Divina. La grafica è provvisoria (forme semplici) di proposito: prima si rende divertente il gioco, poi arrivano gli sprite.

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
| Ricomincia (dopo morte o vittoria) | R | Start |

## Come funziona una run

1. All'inizio Anubi ti offre uno dei suoi doni.
2. Ogni stanza ha due ondate di nemici.
3. Quando la ripulisci compare la ricompensa: camminaci sopra per prenderla.
4. Si aprono 2 o 3 porte, e sopra ognuna vedi cosa c'è dietro: il dono di un dio, un tesoro di Ka o una cura.
5. Dopo la terza stanza si apre l'uscita.

## Nemici

| Nemico | Comportamento | Come affrontarlo |
| --- | --- | --- |
| Mummia | Lenta e resistente. Da vicino diventa rossa e prepara un affondo | Schiva al momento giusto, o interrompila col terzo colpo della combo |
| Scarabei | Arrivano a gruppi di tre, veloci e fragili, a zig-zag | Colpi ampi e Occhio di Horus |
| Sacerdote di Set | Resta lontano e lancia sfere. Prima di lanciare si ferma e la sfera cresce | Spostati negli ultimi istanti, o colpiscilo per interromperlo |

## Doni

Ogni dio offre sempre tre scelte. Ogni dono ha 3 livelli: quando un dio ha finito i doni nuovi, ti propone di potenziare quelli che hai. In circa una scelta su tre compare il **dono pesante** del dio: più forte, ma con un prezzo (`HEAVY_CHANCE` in `scripts/boons.gd`).

| Dio | Doni |
| --- | --- |
| Ra (fuoco) | Colpo Solare, Disco di Ra, Corsa dell'Alba, Occhio Ardente · pesante: Ira del Sole |
| Sekhmet (furia) | Furia della Leonessa, Sete di Sangue, Ruggito, Balzo della Leonessa · pesante: Sete Insaziabile |
| Thoth (Occhio di Horus) | Sguardo di Thoth, Calcolo di Thoth, Occhio Moltiplicato, Parola dello Scriba · pesante: Conoscenza Proibita |
| Anubi (solo a inizio run) | Bende dell'Imbalsamatore, Guida delle Anime, Bilancia Giusta, Fiuto dello Sciacallo |

Senza doni l'Occhio di Horus si ferma sul primo nemico che colpisce.

I nemici colpiti barcollano per un terzo di secondo: non si muovono e non fanno danno da contatto. Le mummie durante l'affondo non barcollano.

## Patti di Set

A volte compare una porta di **Set**: entrare costa 10 punti vita. A fine stanza scegli un patto: una **maledizione** che dura 2 ondate (nemici più veloci, più danni subiti, niente Occhio, scatto più lento) e poi una **benedizione** permanente per tutta la run.

## Sekhem e Forma Divina

Il Sekhem si carica facendo e subendo danni, più o meno ogni due stanze. Quando è pieno attivi la **Forma Divina** per 6 secondi: onda d'urto iniziale, +50% ai danni del khopesh e solo il 30% dei danni subiti.

## Regolare la sensazione di gioco

Apri una scena in `scenes/`, seleziona il nodo principale e cambia i valori nell'**Ispettore**: velocità, vita, danno, tempi di ricarica. Le tre mosse della combo sono nella tabella `COMBO` in `scripts/player.gd`.

## Struttura

```
scenes/   game.tscn (la run), player.tscn, mummy.tscn, scarab.tscn, priest.tscn
scripts/  game.gd      stanze, ondate, ricompense, porte, menu dei doni
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
