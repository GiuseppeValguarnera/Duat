class_name Weapons
## Le armi del Cortile di Neith. Ogni arma ha tre aspetti: il primo è libero, gli altri si
## risvegliano all'altare con le Lacrime di Iside, e ogni aspetto ha 3 livelli.
## "values" = il valore dell'aspetto a ogni livello (sostituisce {v} nella descrizione),
## "cost" = Lacrime per sbloccarlo (indice 0) e per i livelli 2 e 3.
## Le armi ancora da forgiare restano coperte da un telo nel cortile.

const ALL_IT := {
	"khopesh": {
		"name": "Khopesh", "short": "KHOPESH", "the": "il khopesh",
		"desc": "La spada ricurva dei faraoni. Fendenti ampi a distanza ravvicinata: il terzo colpo della combinazione è il più forte. Attaccando durante lo scatto il fendente è più largo e più lungo; tenendo premuto, un colpo a giro attorno a te.",
		"lore": "Il khopesh nasce da un'ascia da battaglia e prende il nome dalla zampa anteriore di un animale, a cui somiglia. Nelle pitture dei templi il faraone lo riceve dalle mani degli dèi prima della battaglia.",
		"aspects": {
			"faraone": {"name": "Aspetto del Faraone", "desc": "La lama dei re, equilibrata in ogni colpo. +{v}% di danni.", "values": [5, 10, 15], "cost": [0, 1, 2],
				"lore": "Ramses II la impugna nei rilievi della battaglia di Qadesh, scolpiti sulle pareti di mezzo Egitto."},
			"montu": {"name": "Aspetto di Montu", "desc": "Il terzo colpo affonda più lontano e fa il {v}% di danni in più.", "values": [35, 50, 70], "cost": [1, 1, 2],
				"lore": "Montu, il dio falco della guerra di Tebe. I faraoni guerrieri del Medio Regno portavano il suo nome: Mentuhotep, 'Montu è soddisfatto'."},
			"wepwawet": {"name": "Aspetto di Wepwawet", "desc": "L'attacco in scatto diventa un fendente circolare e fa il {v}% di danni in più.", "values": [40, 60, 85], "cost": [2, 1, 2],
				"lore": "Wepwawet, lo sciacallo 'che apre le vie'. Il suo stendardo apriva le processioni del re e la strada dei morti verso l'Occidente."},
		},
	},
	"lancia": {
		"name": "Lancia di Neith", "short": "LANCIA", "the": "la lancia",
		"desc": "Affondi lunghi e stretti per colpire da lontano; il terzo colpo è un'ampia spazzata. Attaccando durante lo scatto affondi in corsa e trapassi la fila; tenendo premuto la lanci: trapassa tutti e torna, ma finché non torna sei disarmato.",
		"lore": "Neith di Sais è tra le dee più antiche: il suo segno, uno scudo con due frecce incrociate, compare già prima dei faraoni. I Greci la confusero con Atena.",
		"aspects": {
			"neith": {"name": "Aspetto di Neith", "desc": "La lancia della dea guerriera, come la forgiò. +{v}% di danni.", "values": [5, 10, 15], "cost": [0, 1, 2],
				"lore": "A Sais si diceva che Neith avesse tessuto il mondo come una tela, e che continuasse a tesserlo ogni giorno."},
			"onuris": {"name": "Aspetto di Onuris", "desc": "Gli affondi arrivano il {v}% più lontano.", "values": [20, 30, 40], "cost": [1, 1, 2],
				"lore": "Onuris, il cacciatore, andò fino ai confini del mondo a riprendere la dea lontana, l'Occhio di Ra fuggito nel deserto. Il suo nome vuol dire 'colui che riporta la lontana'."},
			"khonsu": {"name": "Aspetto di Khonsu", "desc": "La spazzata stordisce i nemici per {v} secondi.", "values": [0.6, 0.9, 1.2], "cost": [2, 1, 2],
				"lore": "Khonsu, la luna, 'colui che viaggia' attraverso la notte. Una sua statua, si raccontava, fu mandata fino in Asia a guarire una principessa posseduta."},
		},
	},
	"arco": {
		"name": "Arco di Satet", "short": "ARCO", "the": "l'arco",
		"desc": "Frecce rapide da lontano, che si fermano sul primo nemico. Tenendo premuto tendi l'arco (ti muovi più piano): il tiro carico trapassa tutta la fila. Alla fine dello scatto scocca un ventaglio di tre frecce. La mira punta da sola il nemico più vicino.",
		"lore": "Satet, la dea arciera di Elefantina, scagliava le sue frecce sulla prima cataratta: ogni anno, si diceva, era la sua freccia ad aprire la piena del Nilo. Neith, la più antica delle arciere, ne custodisce l'arco.",
		"aspects": {
			"satet": {"name": "Aspetto di Satet", "desc": "L'arco della signora della cataratta. +{v}% di danni.", "values": [5, 10, 15], "cost": [0, 1, 2],
				"lore": "Il nome di Satet viene forse da 'scagliare': la sua corona bianca è ornata da corna di antilope, e nei templi di Elefantina era la padrona dell'acqua fresca che scende dal sud."},
		},
	},
	"flagello": {
		"name": "Flagello di Osiride", "short": "FLAGELLO", "the": "il flagello",
		"desc": "Le insegne del faraone. Tre frustate a media distanza che colpiscono tutti i nemici in linea (la terza è più ampia): i danni pieni arrivano alla punta, chi ti sta addosso ne subisce meno. Tenendo premuto, il pastorale aggancia un nemico lontano e lo lancia verso di te o dove ti muovi; élite e boss invece tirano te verso di loro. Attaccando dopo lo scatto, una frustata lunga trascina con te i nemici colpiti.",
		"lore": "Il flagello (nekhakha) e il pastorale (heka) erano le insegne di Osiride, il re dei morti, e di ogni faraone dopo di lui: il pastorale del pastore che guida il gregge, il flagello di chi lo difende. Tutankhamon li stringe incrociati sul petto, nel suo sarcofago d'oro.",
		"aspects": {
			"osiride": {"name": "Aspetto di Osiride", "desc": "Le insegne del re dei morti. +{v}% di danni.", "values": [5, 10, 15], "cost": [0, 1, 2],
				"lore": "Osiride regnò sull'Egitto prima degli uomini; ucciso da Set e ricomposto da Iside, scese a regnare nel Duat. Lo si dipinge verde o nero, il colore della terra fertile e della vita che rinasce."},
		},
	},
}

## Le armi che si comprano nel Cortile con i lapislazzuli, quando la condizione è soddisfatta.
## Il khopesh è tuo da subito, la lancia te la regala Neith alla prima visita.
const UNLOCK_COST := {"arco": 20, "flagello": 35}

## Armi ancora da forgiare: solo il nome, coperte nel cortile.
const FUTURE_IT := [
	{"name": "Scettro was", "glyph": "was"},
	{"name": "Artigli di Bastet", "glyph": "artigli"},
]

const MAX_LEVEL := 3


static func is_unlocked(w: String) -> bool:
	if w == "khopesh":
		return true
	return Meta.weapons_unlocked.has(w)


## La condizione per comprare l'arma è soddisfatta? (lancia e khopesh non si comprano)
static func requirement_met(w: String) -> bool:
	match w:
		"arco":
			return Meta.serpent_wins >= 3
		"flagello":
			return Meta.ammit_wins >= 1 or Meta.runs >= 15
	return true


## Il testo della condizione (per il piedistallo coperto e per Neith nella Sala).
static func requirement_text(w: String) -> String:
	match w:
		"arco":
			return Lang.t("Batti il Serpente della Porta tre volte (%d/3)") % mini(Meta.serpent_wins, 3)
		"flagello":
			return Lang.t("Batti Am-heh, oppure compi 15 discese (%d/15)") % mini(Meta.runs, 15)
	return ""


static func unlock_cost(w: String) -> int:
	return int(UNLOCK_COST.get(w, 0))


static func can_buy(w: String) -> bool:
	return UNLOCK_COST.has(w) and not is_unlocked(w) and requirement_met(w) and Meta.lapis >= unlock_cost(w)


## Compra l'arma con i lapislazzuli: da quel momento è tua per sempre.
static func buy(w: String) -> bool:
	if not can_buy(w):
		return false
	Meta.lapis -= unlock_cost(w)
	Meta.weapons_unlocked.append(w)
	Meta.save()
	return true


static func aspect_level(w: String, a: String) -> int:
	var lvl := int(Meta.aspect_levels.get("%s:%s" % [w, a], 0))
	# il primo aspetto di ogni arma è sempre disponibile
	if lvl == 0 and a == first_aspect(w) and is_unlocked(w):
		return 1
	return lvl


static func first_aspect(w: String) -> String:
	return (ALL[w]["aspects"] as Dictionary).keys()[0]


static func chosen_aspect(w: String) -> String:
	var a: String = Meta.weapon_aspect.get(w, first_aspect(w))
	return a if aspect_level(w, a) > 0 else first_aspect(w)


static func text(w: String, a: String, lvl: int) -> String:
	var d: Dictionary = ALL[w]["aspects"][a]
	var v = d["values"][clampi(lvl, 1, MAX_LEVEL) - 1]
	var vs := str(v) if v is int else ("%.1f" % v).replace(".", "." if Lang.is_en() else ",")   # in inglese il punto
	return String(d["desc"]).replace("{v}", vs)


## Lacrime per il prossimo passo dell'aspetto (sbloccarlo o salire di livello); -1 se è al massimo.
static func next_cost(w: String, a: String) -> int:
	var lvl := aspect_level(w, a)
	if lvl >= MAX_LEVEL:
		return -1
	return int(ALL[w]["aspects"][a]["cost"][lvl])


## Con le Lacrime che hai puoi risvegliare o potenziare qualcosa? (il punto esclamativo sull'altare)
static func something_to_spend() -> bool:
	for w in ALL:
		if not is_unlocked(w):
			continue
		for a in ALL[w]["aspects"]:
			var c := next_cost(w, a)
			if c > 0 and Meta.tears >= c:
				return true
	return false


static func upgrade(w: String, a: String) -> bool:
	var c := next_cost(w, a)
	if c < 0 or Meta.tears < c or not is_unlocked(w):
		return false
	Meta.tears -= c
	Meta.aspect_levels["%s:%s" % [w, a]] = aspect_level(w, a) + 1
	Meta.save()
	return true


static func choose(w: String, a: String = "") -> void:
	if not is_unlocked(w):
		return
	Meta.weapon = w
	if a != "" and aspect_level(w, a) > 0:
		Meta.weapon_aspect[w] = a
	Meta.save()


## Il nome dell'arma per i testi dei doni scritti per il khopesh. Va chiamata sul testo già
## tradotto: in italiano cambia anche l'articolo (il khopesh, la lancia), in inglese basta il nome.
static func adapt(s: String) -> String:
	if Run.weapon == "khopesh" or Run.weapon == "":
		return s
	if Run.weapon == "flagello":
		if Lang.is_en():
			return s.replace("Khopesh", "Flail").replace("khopesh", "flail")
		return s.replace("Khopesh", "Flagello").replace("khopesh", "flagello")
	if Run.weapon == "arco":
		if Lang.is_en():
			return s.replace("Khopesh", "Bow").replace("khopesh", "bow")
		return s.replace("Il khopesh", "L'arco").replace("il khopesh", "l'arco").replace("del khopesh", "dell'arco") \
			.replace("dal khopesh", "dall'arco").replace("al khopesh", "all'arco").replace("Khopesh", "Arco").replace("khopesh", "arco")
	if Lang.is_en():
		return s.replace("Khopesh", "Spear").replace("khopesh", "spear")
	return s.replace("Il khopesh", "La lancia").replace("il khopesh", "la lancia").replace("del khopesh", "della lancia") \
		.replace("dal khopesh", "dalla lancia").replace("al khopesh", "alla lancia").replace("Khopesh", "Lancia").replace("khopesh", "lancia")


## I testi qui sopra sono in italiano (le costanti *_IT); il gioco legge le copie tradotte
## nella lingua scelta, rifatte da Lang.refresh_data() quando cambia la lingua.
static var ALL: Dictionary = Lang.deep(ALL_IT)
static var FUTURE: Array = Lang.deep(FUTURE_IT)


static func refresh_lang() -> void:
	ALL = Lang.deep(ALL_IT)
	FUTURE = Lang.deep(FUTURE_IT)
