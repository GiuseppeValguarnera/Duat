class_name Chapters
## Il Libro dei Morti: capitoli (incantesimi passivi) che si comprano con il Ka nella
## Sala del Giudizio e restano per sempre. Se ne possono tenere attivi pochi alla volta:
## sono più dei posti disponibili, quindi ogni discesa è una scelta.
## I numeri dei capitoli sono quelli veri del Libro dei Morti egizio.

const ALL := {
	"c17": {"num": 17, "name": "Uscire al giorno", "desc": "Inizi ogni discesa con +15 vita massima.", "cost": 30, "lore": "Gli Egizi chiamavano il Libro dei Morti 'Formule per uscire al giorno'. Il capitolo 17 è uno dei più antichi e lunghi: spiega chi sono gli dèi che il morto incontrerà nel viaggio."},
	"c89": {"num": 89, "name": "Il ritorno del Ba", "desc": "L'Occhio di Horus si ricarica il 15% più in fretta.", "cost": 30, "lore": "Il Ba, la parte dell'anima con corpo d'uccello e testa umana, di giorno vola fuori dalla tomba. Il capitolo 89 serve a farlo tornare ogni notte nel suo corpo."},
	"c154": {"num": 154, "name": "Il corpo incorrotto", "desc": "L'Acqua del Nilo ti cura del 40% invece che del 30%.", "cost": 35, "lore": "Una formula contro la decomposizione: 'non marcirò, non diventerò vermi'. Il corpo intatto era la casa del Ka, la forza vitale."},
	"c99": {"num": 99, "name": "La barca di Ra", "desc": "I tesori di Ka valgono il 30% in più.", "cost": 40, "lore": "Per raggiungere i campi dell'aldilà il morto doveva salire sulla barca di un traghettatore, che gli chiedeva il nome di ogni parte della barca. Il capitolo 99 contiene le risposte."},
	"c30": {"num": 30, "name": "Il cuore che non testimonia", "desc": "Una volta per discesa sopravvivi a un colpo mortale con 1 punto vita.", "cost": 60, "lore": "Era inciso sullo scarabeo del cuore, un amuleto messo sul petto della mummia: 'O mio cuore, non alzarti a testimoniare contro di me'. Così il cuore non confessava le colpe sulla bilancia."},
	"c125": {"num": 125, "name": "La confessione negativa", "desc": "Finché hai più dell'80% della vita fai il 15% di danni in più.", "cost": 50, "lore": "La Confessione negativa: davanti a quarantadue giudici il morto elenca le colpe che non ha commesso. È il capitolo più famoso del Libro dei Morti."},
	"c6": {"num": 6, "name": "Gli Ushabti", "desc": "Una statuetta servitrice ti segue e colpisce il nemico più vicino ogni 2 secondi.", "cost": 70, "lore": "Gli ushabti, 'quelli che rispondono', erano statuine sepolte anche a centinaia. Quando gli dèi chiamavano il morto a lavorare i campi dell'aldilà, rispondevano al posto suo: 'Eccomi!'."},
}


## Quanti capitoli si possono tenere attivi: 2, più 1 la prima volta che sconfiggi Ammit.
static func slots() -> int:
	return 2 + (1 if Meta.ammit_wins > 0 else 0)


static func is_unlocked(id: String) -> bool:
	return Meta.chapters_unlocked.has(id)


static func is_equipped(id: String) -> bool:
	return Meta.chapters_equipped.has(id)


## Compra un capitolo se c'è abbastanza Ka. Restituisce true se è andato a buon fine.
static func buy(id: String) -> bool:
	var cost: int = ALL[id]["cost"]
	if is_unlocked(id) or Meta.ka_bank < cost:
		return false
	Meta.ka_bank -= cost
	Meta.chapters_unlocked.append(id)
	if Meta.chapters_equipped.size() < slots():
		Meta.chapters_equipped.append(id)
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
