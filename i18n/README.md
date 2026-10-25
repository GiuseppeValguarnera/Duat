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

## Come le usa il gioco

- Il CSV è registrato in `project.godot` (`[internationalization]`): Godot crea da solo i file `.translation` quando importa.
- **La lingua** si sceglie in Opzioni, voce *Lingua · Language*. All'inizio segue quella del telefono o del computer (italiano per chi ce l'ha in italiano, inglese per tutti gli altri). È salvata in `Meta.options["lang"]`. Per le prove automatiche `DUAT_LANG=it` (o `en`) la impone: il bot di playtest legge le carte in italiano.
- `scripts/lang.gd` ha tutto: `Lang.t("frase")` traduce, `Lang.apply()` cambia lingua, `Lang.deep()` fa la copia tradotta di un dato costante.
- **Frasi nel codice:** `Lang.t("...")`. Con un segnaposto la traduzione va fatta **prima** di riempirlo: `Lang.t("Stanza %d/%d") % [a, b]`, non `Lang.t("Stanza %d/%d" % [a, b])`.
- **Dati costanti grandi** (doni, capitoli, storie degli dèi, armi, pesi): la costante in italiano si chiama `ALL_IT` (o `GODS_IT`, ...), il gioco legge `ALL`, una copia tradotta rifatta a ogni cambio di lingua (`refresh_lang()` in ogni file, chiamata da `Lang.refresh_data()`).
- **Liste costanti piccole** (frasi del Traghettatore, iscrizioni del serdab, testi delle Opzioni, nomi di chi ti ha ucciso, presentazione dei boss): si traducono con `Lang.t()` dove si leggono.
- **Etichette con testo fisso** (nelle scene o `label.text = "Frase"`): si traducono da sole, i nodi Control di Godot lo fanno in automatico.
- **khopesh e lancia:** `Weapons.adapt()` va chiamata sul testo già tradotto; in inglese cambia solo il nome (khopesh → spear).
- **Decimali:** in inglese con il punto (0.6), in italiano con la virgola (0,6).

## Altre lingue (più avanti)

Per aggiungere una lingua basta una nuova colonna nel CSV (per esempio `es`, `fr`, `de`, `pt_BR`, `zh_CN`, `ja`, `ru`) e un nuovo file `.translation` nella lista di `project.godot`. Per cinese, giapponese e russo servirà anche un font che contenga quei caratteri.
