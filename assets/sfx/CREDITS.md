# Suoni

Tutti i suoni vengono dai pacchetti di **Kenney** (https://kenney.nl), con licenza
**CC0 1.0** (pubblico dominio: uso libero anche commerciale, nessun obbligo di citazione).

- Impact Sounds
- Interface Sounds
- RPG Audio

Sono stati scelti, rinominati, in parte modificati (velocità, eco, filtri) e normalizzati
con `tools/convert_sfx.py`.

## Suoni creati per Duat (`tools/synth_sfx.py`)

Spuntoni, mummie (passi e carica), scorpioni, cobra e Serpente della Porta sono costruiti
mescolando suoni Kenney CC0 (rallentati, filtrati, sovrapposti) con rumore sintetico generato
da ffmpeg (sibili, rantoli, sabbia). Stessa licenza: CC0.

Ritocco per gli altoparlanti dei telefoni: charge, orb, hurt, kill, roar e death hanno meno bassi e più
medi (filtro e volume con ffmpeg), perché sul telefono erano quasi muti.
