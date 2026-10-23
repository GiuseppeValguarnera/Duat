# Duat

Roguelike action nell'oltretomba egizio, fatto con Godot 4.7.

**Stato:** fase 2, una run di prova di 3 stanze con nemici diversi, ricompense e doni degli dèi. La grafica è provvisoria (forme semplici) di proposito: prima si rende divertente il gioco, poi arrivano gli sprite.

## Come provarlo

1. Apri Godot 4.7, clicca **Import** e scegli il file `project.godot` di questa cartella.
2. Premi **F5** per avviare.

## Comandi

| Azione | Tastiera e mouse | Controller |
| --- | --- | --- |
| Muoverti | WASD o frecce | Levetta sinistra |
| Mirare | Mouse | Levetta destra |
| Khopesh (tieni premuto per la combo) | Clic sinistro o J | X |
| Scatto (invulnerabile) | Spazio, Shift o K | A |
| Occhio di Horus | Clic destro o L | Y |
| Mostra/nascondi hitbox | F1 | |
| Ricomincia (dopo morte o vittoria) | R | Start |

## Come funziona una run

1. Ogni stanza ha due ondate di nemici.
2. Quando la ripulisci compare la ricompensa: camminaci sopra per prenderla.
3. Si aprono 2 o 3 porte, e sopra ognuna vedi cosa c'è dietro: il dono di un dio, un tesoro di Ka o una cura.
4. Dopo la terza stanza si apre l'uscita.

## Nemici

| Nemico | Comportamento | Come affrontarlo |
| --- | --- | --- |
| Mummia | Lenta e resistente. Da vicino diventa rossa e prepara un affondo | Schiva al momento giusto, o interrompila col terzo colpo della combo |
| Scarabei | Arrivano a gruppi di tre, veloci e fragili, a zig-zag | Colpi ampi e Occhio di Horus |
| Sacerdote di Set | Resta lontano e lancia sfere. Prima di lanciare si ferma e la sfera cresce | Spostati negli ultimi istanti, o colpiscilo per interromperlo |

## Doni

| Dio | Dono | Effetto |
| --- | --- | --- |
| Ra | Colpo Solare | Il khopesh incendia i nemici per 2 secondi |
| Ra | Disco di Ra | L'Occhio di Horus esplode quando colpisce |
| Sekhmet | Furia della Leonessa | +35% ai danni del khopesh |
| Sekhmet | Sete di Sangue | Ogni nemico abbattuto ti cura di 3 |
| Thoth | Sguardo di Thoth | L'Occhio di Horus trapassa fino a 2 nemici |
| Thoth | Calcolo di Thoth | L'Occhio di Horus si ricarica il 40% più in fretta |

Senza doni l'Occhio di Horus si ferma sul primo nemico che colpisce.

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
