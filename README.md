# Duat

Roguelike action nell'oltretomba egizio, fatto con Godot 4.7.

**Stato:** fase 1, le fondamenta del combattimento. La grafica è provvisoria (forme semplici) di proposito: prima si rende divertente il combattimento, poi arrivano gli sprite.

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
| Ricomincia | R | Start |

## Cosa c'è

- Combo di 3 colpi col khopesh. Il terzo è più ampio e spinge lontano.
- Aiuto alla mira: se un nemico è entro 25° dalla direzione del colpo, il fendente si orienta su di lui.
- Scatto con invulnerabilità per tutta la durata: puoi attraversare i nemici.
- Occhio di Horus: un raggio che attraversa i nemici e si ferma sui muri.
- Mummie che inseguono e, da vicino, preparano un affondo. Prima dell'affondo diventano rosse e mostrano una linea: è il segnale per schivare. Un colpo pesante durante l'avviso le interrompe.
- Ondate sempre più grandi, hitstop e tremolio della telecamera sui colpi.

## Regolare la sensazione di gioco

Apri `scenes/player.tscn` (o `scenes/mummy.tscn`), seleziona il nodo principale e cambia i valori nell'**Ispettore**: velocità, durata dello scatto, danno, tempi di ricarica. Le tre mosse della combo sono nella tabella `COMBO` in `scripts/player.gd`.

## Struttura

```
scenes/   main.tscn (stanza di prova), player.tscn, mummy.tscn
scripts/  main.gd, player.gd, mummy.gd, eye.gd, reticle.gd
          fx.gd (effetti globali), input_setup.gd (comandi)
```
