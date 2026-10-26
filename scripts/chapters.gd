class_name Chapters
## Il Libro dei Morti: capitoli (incantesimi passivi) che si comprano con il Ka nella
## Sala del Giudizio e restano per sempre. Se ne possono tenere attivi pochi alla volta:
## sono più dei posti disponibili, quindi ogni discesa è una scelta.
## I numeri dei capitoli sono quelli veri del Libro dei Morti egizio.
##
## Ogni capitolo ha fino a 3 livelli: "values" è il valore a ogni livello (sostituisce {v} nella
## descrizione) e "cost" il prezzo in Ka di ogni livello. Le Lacrime di Iside servono alle armi.

const ALL_IT := {
	"c17": {"num": 17, "name": "Uscire al giorno", "desc": "Inizi ogni discesa con +{v} vita massima.", "values": [15, 25, 35], "cost": [60, 140, 260], "lore": "Gli Egizi chiamavano il Libro dei Morti 'Formule per uscire al giorno'. Il capitolo 17 è uno dei più antichi e lunghi: spiega chi sono gli dèi che il morto incontrerà nel viaggio."},
	"c89": {"num": 89, "name": "Il ritorno del Ba", "desc": "L'Occhio di Horus si ricarica il {v}% più in fretta.", "values": [15, 22, 30], "cost": [60, 140, 260], "lore": "Il Ba, la parte dell'anima con corpo d'uccello e testa umana, di giorno vola fuori dalla tomba. Il capitolo 89 serve a farlo tornare ogni notte nel suo corpo."},
	"c56": {"num": 56, "name": "Il soffio d'aria", "desc": "Lo scatto si ricarica il {v}% più in fretta.", "values": [10, 18, 25], "cost": [60, 140, 260], "lore": "I capitoli dal 54 al 59 danno al morto il respiro nell'aldilà: 'Io sono l'uovo del Grande Starnazzatore, respiro l'aria che è in lui'. Senza aria, nel Duat non si va da nessuna parte."},
	"c154": {"num": 154, "name": "Il corpo incorrotto", "desc": "L'Acqua del Nilo ti cura del {v}% invece che del 30%.", "values": [40, 45, 50], "cost": [70, 150, 280], "lore": "Una formula contro la decomposizione: 'non marcirò, non diventerò vermi'. Il corpo intatto era la casa del Ka, la forza vitale."},
	"c99": {"num": 99, "name": "La barca di Ra", "desc": "I tesori di Ka valgono il {v}% in più.", "values": [30, 45, 60], "cost": [80, 170, 300], "lore": "Per raggiungere i campi dell'aldilà il morto doveva salire sulla barca di un traghettatore, che gli chiedeva il nome di ogni parte della barca. Il capitolo 99 contiene le risposte."},
	"c110": {"num": 110, "name": "I Campi di Iaru", "desc": "Inizi ogni discesa con {v} Ka da spendere dal Traghettatore.", "values": [15, 25, 40], "cost": [80, 170, 300], "lore": "Il Campo dei Giunchi era il paradiso egizio: un Egitto perfetto, con canali, grano alto e raccolti senza fine. Il capitolo 110 ne è la mappa, dipinta sui papiri con i suoi campi e i suoi canali."},
	"c94": {"num": 94, "name": "Calamaio e tavolozza", "desc": "Al Traghettatore tutto costa il {v}% in meno.", "values": [15, 25, 35], "cost": [70, 150, 280], "lore": "Con il capitolo 94 il morto chiede la tavolozza e il calamaio di Thoth, per essere uno scriba anche nell'aldilà. Saper scrivere era un potere: chi scrive i nomi, li fa esistere."},
	"c42": {"num": 42, "name": "Ogni membro è un dio", "desc": "L'Occhio di Horus fa il {v}% di danni in più.", "values": [10, 18, 25], "cost": [80, 170, 300], "lore": "Nel capitolo 42 il morto dà un dio a ogni parte del corpo: 'i miei capelli sono di Nun, il mio volto è di Ra, i miei occhi di Hathor'. Così nessuna parte di lui è più mortale."},
	"c151": {"num": 151, "name": "La maschera", "desc": "In ogni stanza il primo colpo che ricevi fa il {v}% di danni in meno.", "values": [40, 60, 80], "cost": [90, 190, 320], "lore": "Il capitolo 151 era inciso sulle maschere funebri. Quella d'oro di Tutankhamon lo porta sul retro: protegge la testa del re 'contro i suoi nemici' e gli dà gli occhi per vedere nel buio."},
	"c125": {"num": 125, "name": "La confessione negativa", "desc": "Finché hai più dell'80% della vita fai il {v}% di danni in più.", "values": [15, 22, 30], "cost": [100, 200, 340], "lore": "La Confessione negativa: davanti a quarantadue giudici il morto elenca le colpe che non ha commesso. È il capitolo più famoso del Libro dei Morti."},
	"c30": {"num": 30, "name": "Il cuore che non testimonia", "desc": "Una volta per discesa sopravvivi a un colpo mortale con il {v}% della vita.", "values": [5, 20, 35], "cost": [120, 220, 360], "lore": "Era inciso sullo scarabeo del cuore, un amuleto messo sul petto della mummia: 'O mio cuore, non alzarti a testimoniare contro di me'. Così il cuore non confessava le colpe sulla bilancia."},
	"c6": {"num": 6, "name": "Gli Ushabti", "desc": "Una statuetta servitrice ti segue e colpisce il nemico più vicino ogni {v} secondi.", "values": [2.0, 1.6, 1.3], "cost": [140, 240, 380], "lore": "Gli ushabti, 'quelli che rispondono', erano statuine sepolte anche a centinaia. Quando gli dèi chiamavano il morto a lavorare i campi dell'aldilà, rispondevano al posto suo: 'Eccomi!'."},
	"c26": {"num": 26, "name": "Il cuore restituito", "desc": "I nemici abbattuti hanno il {v}% di probabilità di lasciare un cuore che ti cura di {h} punti vita.", "values": [3, 5, 7], "heal": [5, 6, 7], "cost": [90, 190, 320], "lore": "Con il capitolo 26 il morto riceve di nuovo il suo cuore, l'ib: 'Il mio cuore è con me, e non mi sarà tolto'. Per gli Egizi si pensava con il cuore, non con il cervello, che i mummificatori buttavano via."},
	"c72": {"num": 72, "name": "Le porte aperte", "desc": "Dopo ogni stanza si aprono sempre tre porte.", "values": [1], "cost": [220], "lore": "'Uscire al giorno e aprire la tomba': con il capitolo 72 il morto conosce i nomi dei guardiani delle porte, e chi conosce il nome di un guardiano può passare."},
}

const MAX_LEVEL := 3
const SLOT_KA := [400, 800]                ## Ka per il 1° e il 2° posto in più nel Libro


## Quanti capitoli si possono tenere attivi: 2, +1 la prima volta che sconfiggi il boss della Prima Ora,
## +1 per ogni posto comprato con il Ka.
static func slots() -> int:
	return 2 + (1 if Meta.ammit_wins > 0 else 0) + Meta.extra_slots


static func level(id: String) -> int:
	return int(Meta.chapter_levels.get(id, 0))


static func max_level(id: String) -> int:
	return (ALL[id]["values"] as Array).size()


static func is_unlocked(id: String) -> bool:
	return level(id) > 0


static func is_equipped(id: String) -> bool:
	return Meta.chapters_equipped.has(id)


## Valore del capitolo al livello comprato (0 se non è attivo).
static func value(id: String) -> float:
	var l := level(id)
	if l == 0 or not is_equipped(id):
		return 0.0
	return float(ALL[id]["values"][l - 1])


static func text(id: String, lvl: int) -> String:
	var c: Dictionary = ALL[id]
	var v = c["values"][clampi(lvl, 1, max_level(id)) - 1]
	var vs := str(v) if v is int else ("%.1f" % v).replace(".", "." if Lang.is_en() else ",")   # in inglese il punto
	var out := String(c["desc"]).replace("{v}", vs)
	if c.has("heal"):
		out = out.replace("{h}", str(c["heal"][clampi(lvl, 1, max_level(id)) - 1]))
	return out


## Cura del cuore del capitolo 26 al livello comprato.
static func heart_heal() -> float:
	var l := level("c26")
	return 0.0 if l == 0 else float(ALL["c26"]["heal"][l - 1])


## Prezzo del prossimo livello: [Ka, Lacrime]. [-1, 0] se è già al massimo.
## C'è un capitolo nuovo (o un posto nel Libro) che puoi già comprare? Il leggio lo segnala.
static func something_affordable() -> bool:
	for id in ALL:
		if level(id) == 0 and int(ALL[id]["cost"][0]) <= Meta.ka_bank:
			return true
	var sc := slot_cost()
	return sc > 0 and Meta.ka_bank >= sc


static func next_cost(id: String) -> Array:
	var l := level(id)
	if l >= max_level(id):
		return [-1, 0]
	return [int(ALL[id]["cost"][l]), 0]


## Compra il capitolo o il suo livello successivo. Restituisce true se è andato a buon fine.
static func buy(id: String) -> bool:
	var c := next_cost(id)
	if c[0] < 0 or Meta.ka_bank < c[0] or Meta.tears < c[1]:
		return false
	Meta.ka_bank -= c[0]
	Meta.tears -= c[1]
	var first := level(id) == 0
	Meta.chapter_levels[id] = level(id) + 1
	if first and Meta.chapters_equipped.size() < slots():
		Meta.chapters_equipped.append(id)
	Meta.save()
	return true


## Prezzo in Ka del prossimo posto nel Libro (-1 se sono già tutti comprati).
static func slot_cost() -> int:
	return SLOT_KA[Meta.extra_slots] if Meta.extra_slots < SLOT_KA.size() else -1


static func buy_slot() -> bool:
	var c := slot_cost()
	if c < 0 or Meta.ka_bank < c:
		return false
	Meta.ka_bank -= c
	Meta.extra_slots += 1
	Meta.save()
	return true


## Attiva o disattiva un capitolo già comprato.
static func toggle(id: String) -> bool:
	if not is_unlocked(id):
		return false
	if is_equipped(id):
		Meta.chapters_equipped.erase(id)
	elif Meta.chapters_equipped.size() < slots():
		Meta.chapters_equipped.append(id)
	else:
		return false
	Meta.save()
	return true


## I testi qui sopra sono in italiano (le costanti *_IT); il gioco legge le copie tradotte
## nella lingua scelta, rifatte da Lang.refresh_data() quando cambia la lingua.
static var ALL: Dictionary = Lang.deep(ALL_IT)


static func refresh_lang() -> void:
	ALL = Lang.deep(ALL_IT)
