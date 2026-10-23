class_name Boons
## Elenco degli dèi e dei loro doni. Per aggiungere un dono: una riga in ALL,
## poi il suo effetto in run.gd (o dove serve, cercando il suo id).

const GODS := {
	"ra": {"name": "Ra", "color": Color(0.96, 0.65, 0.14)},
	"sekhmet": {"name": "Sekhmet", "color": Color(0.94, 0.37, 0.24)},
	"thoth": {"name": "Thoth", "color": Color(0.31, 0.76, 0.78)},
}

const ALL := {
	"ra_burn": {"god": "ra", "name": "Colpo Solare", "desc": "I fendenti del khopesh incendiano i nemici per 2 secondi."},
	"ra_disc": {"god": "ra", "name": "Disco di Ra", "desc": "L'Occhio di Horus esplode quando colpisce e ferisce chi sta vicino."},
	"sekhmet_fury": {"god": "sekhmet", "name": "Furia della Leonessa", "desc": "+35% ai danni del khopesh."},
	"sekhmet_blood": {"god": "sekhmet", "name": "Sete di Sangue", "desc": "Ogni nemico abbattuto ti cura di 3 punti vita."},
	"thoth_pierce": {"god": "thoth", "name": "Sguardo di Thoth", "desc": "L'Occhio di Horus trapassa fino a 2 nemici."},
	"thoth_calc": {"god": "thoth", "name": "Calcolo di Thoth", "desc": "L'Occhio di Horus si ricarica il 40% più in fretta."},
}


static func god_name(god: String) -> String:
	return GODS[god]["name"]


static func god_color(god: String) -> Color:
	return GODS[god]["color"]


## Doni non ancora presi di un dio.
static func available(god: String, taken: Array) -> Array:
	var out := []
	for id in ALL:
		if ALL[id]["god"] == god and not taken.has(id):
			out.append(id)
	return out


## Dèi che hanno ancora almeno un dono da offrire.
static func gods_with_boons(taken: Array) -> Array:
	var out := []
	for g in GODS:
		if not available(g, taken).is_empty():
			out.append(g)
	return out
