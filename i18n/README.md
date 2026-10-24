# Traduzioni

Questa cartella contiene le traduzioni del gioco. Per ora c'è l'**inglese**; le altre lingue arriveranno quando il gioco sarà completo e vicino all'uscita.

## I file

- `duat_translations.csv`: il file che Godot legge. È nel formato CSV di Godot: la prima colonna (`keys`) è la frase italiana esatta come la vede il gioco, poi una colonna per lingua (`it`, `en`). Gli "a capo" sono veri a capo dentro la cella (non `\n`), perché `tr()` riceve la stringa già interpretata.
- `extract.py`: legge `scripts/*.gd` e `scenes/*.tscn`, trova tutte le frasi che il giocatore vede (menu, doni, maledizioni, capitoli, dialoghi di Anubi e degli dèi, Papiri di Thoth, porte, HUD, messaggi di fine discesa) e aggiorna il CSV.

## Come si aggiorna

```
python3 i18n/extract.py           # aggiunge le frasi nuove, tiene le traduzioni già fatte
python3 i18n/extract.py --check   # elenca solo le frasi ancora senza inglese
```

- Le frasi nuove vengono aggiunte con la colonna `en` vuota: vanno tradotte a mano (o con l'aiuto di Claude).
- Le frasi che non si trovano più nel codice (per esempio perché sono state riscritte) restano in fondo al file, così una traduzione non si perde se la frase è stata solo spostata. Si possono cancellare quando si è sicuri.
- I segnaposto (`%d`, `%s`, `%.1f`, `%02d`, `%%`) devono restare uguali e nello stesso ordine nella traduzione. I tag colore (`[color=...]`, `[b]`, `[center]`) idem.
- Le parole singole minuscole che compaiono a schermo (`pronto`, `nessuno`, `comprato`, ...) non si riconoscono in automatico: se ne aggiungi una nel codice, mettila in `EXTRA_VISIBLE` dentro `extract.py`.

## Scelte di traduzione (inglese)

- Nomi mitologici nella forma inglese standard: Anubis, Isis, Osiris, Nephthys, Horus, Apophis, Ma'at, Ammit, Duat, Book of the Dead, Field of Reeds (Aaru), Hall of Two Truths.
- Termini di gioco: Sala del Giudizio → Hall of Judgement · Scriba → Scribe · dono → boon · dono pesante → heavy boon · Dono Doppio → Duo Boon · patto → pact · maledizione → curse · benedizione → blessing · Forma Divina → Divine Form · Occhio di Horus → Eye of Horus · khopesh resta khopesh · Peso del Cuore → Weight of the Heart · Papiri di Thoth → Scrolls of Thoth · Serpente della Porta → Serpent of the Gate · Traghettatore → Ferryman · Acqua del Nilo → Water of the Nile · Ka custodito → Stored Ka · discesa → descent · stanza → chamber.
- Ogni dio conserva la sua voce: Ra cosmico, Sekhmet feroce, Thoth misurato, Bastet regale, Sobek lento, Iside materna, Set sprezzante, Anubi grave e asciutto.

## Cosa manca per usarle nel gioco

1. Registrare il file in `project.godot` (Godot crea da solo i file `.translation` quando importa il CSV):
   ```
   [internationalization]
   locale/translations=PackedStringArray("res://i18n/duat_translations.en.translation", "res://i18n/duat_translations.it.translation")
   ```
2. Le etichette con testo fisso (impostato nelle scene o con `label.text = "Frase"`) vengono tradotte da sole, perché i nodi Control di Godot traducono il loro testo automaticamente.
3. Le frasi con segnaposto vanno avvolte in `tr()` **prima** del `%`: `tr("Stanza %d/%d") % [a, b]`, non `tr("Stanza %d/%d" % [a, b])`. Lo stesso per i testi presi dai dizionari (`tr(Boons.ALL[id]["name"])`, `tr(c["desc"])`, i testi di `Lore` e `Dialogue`), e per i testi disegnati con `draw_string`, che non passano dai nodi Control.
4. Scelta della lingua: all'avvio `TranslationServer.set_locale(OS.get_locale_language())`, più una voce nel menu opzioni salvata in `Meta`.

## Altre lingue (più avanti)

Per aggiungere una lingua basta una nuova colonna nel CSV (per esempio `es`, `fr`, `de`, `pt_BR`, `zh_CN`, `ja`, `ru`) e un nuovo file `.translation` nella lista di `project.godot`. Per cinese, giapponese e russo servirà anche un font che contenga quei caratteri.
