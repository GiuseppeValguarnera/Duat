class_name Boons
## Dèi, doni, doni pesanti e patti di Set.
## Per aggiungere un dono: una riga in ALL, poi il suo effetto in run.gd.

const MAX_LEVEL := 3
## Probabilità che tra le tre scelte compaia il dono pesante del dio.
const HEAVY_CHANCE := 0.35

const GODS := {
	"ra": {"name": "Ra", "color": Color(0.96, 0.65, 0.14)},
	"sekhmet": {"name": "Sekhmet", "color": Color(0.94, 0.37, 0.24)},
	"thoth": {"name": "Thoth", "color": Color(0.31, 0.76, 0.78)},
	"bastet": {"name": "Bastet", "color": Color(0.4, 0.85, 0.5)},
	"sobek": {"name": "Sobek", "color": Color(0.62, 0.66, 0.28)},
	"iside": {"name": "Iside", "color": Color(0.95, 0.56, 0.76)},
	"set": {"name": "Set", "color": Color(0.78, 0.25, 0.2)},
	"anubi": {"name": "Anubi", "color": Color(0.62, 0.56, 0.92)},
}

## `values` = il numero del dono ai livelli 1, 2 e 3 (entra nel %d della descrizione).
## I doni pesanti hanno un solo livello e un prezzo (`cost`).
const ALL := {
	"ra_burn": {"god": "ra", "name": "Colpo Solare", "desc": "Il khopesh incendia i nemici: %d danni ogni mezzo secondo per 2 secondi.", "values": [5, 7, 9]},
	"ra_disc": {"god": "ra", "name": "Disco di Ra", "desc": "L'Occhio di Horus esplode quando si ferma: %d danni a chi sta vicino.", "values": [14, 20, 26]},
	"ra_dawn": {"god": "ra", "name": "Corsa dell'Alba", "desc": "Lo scatto ferisce i nemici che attraversi (%d danni) e li incendia per 1 secondo.", "values": [4, 6, 8], "cost": "Lo scatto si ricarica il 40% più lentamente."},
	"ra_eye": {"god": "ra", "name": "Occhio Ardente", "desc": "L'Occhio di Horus incendia i nemici e fa il %d%% di danni in più.", "values": [15, 30, 45]},
	"sekhmet_fury": {"god": "sekhmet", "name": "Furia della Leonessa", "desc": "+%d%% ai danni del khopesh.", "values": [35, 50, 65]},
	"sekhmet_blood": {"god": "sekhmet", "name": "Sete di Sangue", "desc": "Ogni nemico abbattuto ti cura di %d punti vita.", "values": [3, 5, 7]},
	"sekhmet_roar": {"god": "sekhmet", "name": "Ruggito", "desc": "Il terzo colpo della combo libera un'onda d'urto attorno a te: %d danni.", "values": [10, 16, 22]},
	"sekhmet_leap": {"god": "sekhmet", "name": "Balzo della Leonessa", "desc": "Il primo colpo dopo uno scatto fa il %d%% di danni in più.", "values": [60, 90, 120]},
	"thoth_pierce": {"god": "thoth", "name": "Sguardo di Thoth", "desc": "L'Occhio di Horus trapassa fino a %d nemici.", "values": [2, 3, 4]},
	"thoth_calc": {"god": "thoth", "name": "Calcolo di Thoth", "desc": "L'Occhio di Horus si ricarica il %d%% più in fretta.", "values": [40, 50, 60]},
	"thoth_tri": {"god": "thoth", "name": "Occhio Moltiplicato", "desc": "L'Occhio di Horus scaglia %d raggi a ventaglio.", "values": [3, 5, 7]},
	"thoth_scribe": {"god": "thoth", "name": "Parola dello Scriba", "desc": "+%d%% ai danni dell'Occhio di Horus.", "values": [60, 90, 120]},
	# Bastet: colpi critici e agilità
	"bastet_claws": {"god": "bastet", "name": "Artigli Affilati", "desc": "Il khopesh ha il %d%% di probabilità di fare un colpo critico (danni doppi).", "values": [12, 18, 24]},
	"bastet_eyes": {"god": "bastet", "name": "Occhi di Gatto", "desc": "L'Occhio di Horus ha il %d%% di probabilità di fare un colpo critico (danni doppi).", "values": [15, 25, 35]},
	"bastet_step": {"god": "bastet", "name": "Passo Felino", "desc": "Lo scatto si ricarica il %d%% più in fretta.", "values": [20, 30, 40]},
	"bastet_lives": {"god": "bastet", "name": "Nove Vite", "desc": "La prima volta che muori in questa run ti rialzi con il %d%% della vita.", "values": [30, 40, 50]},
	# Sobek: resistenza, controllo, acqua
	"sobek_skin": {"god": "sobek", "name": "Pelle di Coccodrillo", "desc": "Subisci il %d%% di danni in meno.", "values": [10, 15, 20]},
	"sobek_bite": {"god": "sobek", "name": "Morso di Sobek", "desc": "Il terzo colpo della combo stordisce i nemici per %.1f secondi.", "values": [1.0, 1.5, 2.0]},
	"sobek_tide": {"god": "sobek", "name": "Marea del Nilo", "desc": "Alla fine dello scatto lasci una pozza che rallenta i nemici del %d%% per 3 secondi.", "values": [30, 40, 50]},
	"sobek_river": {"god": "sobek", "name": "Forza del Fiume", "desc": "Ogni stanza ripulita ti dà +%d vita massima.", "values": [4, 6, 8]},
	# Iside: protezione, cure, magia
	"iside_wings": {"god": "iside", "name": "Ali di Iside", "desc": "All'inizio di ogni stanza hai uno scudo che assorbe %d danni.", "values": [8, 12, 16]},
	"iside_tears": {"god": "iside", "name": "Lacrime di Iside", "desc": "Tutte le cure ti curano il %d%% in più.", "values": [30, 45, 60]},
	"iside_knot": {"god": "iside", "name": "Nodo di Iside", "desc": "Sotto un terzo della vita fai il %d%% di danni in più.", "values": [30, 45, 60]},
	"iside_word": {"god": "iside", "name": "Parola Magica", "desc": "Il Sekhem si carica il %d%% più in fretta.", "values": [25, 40, 55]},
	# Anubi pesa ogni cosa: i suoi doni sono bilance, un vantaggio un po' più grande del prezzo.
	"anubi_light": {"god": "anubi", "balanced": true, "name": "Cuore Leggero", "desc": "Lo scatto si ricarica il %d%% più in fretta e ti muovi il 15%% più veloce.", "values": [30], "cost": "-10 vita massima."},
	"anubi_stone": {"god": "anubi", "balanced": true, "name": "Cuore di Pietra", "desc": "+%d vita massima.", "values": [30], "cost": "Ti muovi l'8% più lento."},
	"anubi_jackal": {"god": "anubi", "balanced": true, "name": "Fiuto dello Sciacallo", "desc": "+%d%% di danni ai nemici sotto metà vita.", "values": [50], "cost": "-10% di danni ai nemici sopra metà vita."},
	"anubi_scale": {"god": "anubi", "balanced": true, "name": "Bilancia Giusta", "desc": "Chi ti colpisce subisce il %d%% del danno che ti ha fatto.", "values": [200], "cost": "Subisci il 10% di danni in più."},
	"anubi_guide": {"god": "anubi", "balanced": true, "name": "Guida delle Anime", "desc": "Ogni nemico abbattuto libera uno spirito che colpisce il nemico più vicino: %d danni.", "values": [15], "cost": "I nemici hanno il 5% di vita in più."},
	"ra_heavy": {"god": "ra", "heavy": true, "name": "Ira del Sole", "desc": "Tutti i tuoi colpi incendiano, e le fiamme fanno il 60% di danni in più.", "cost": "L'Occhio di Horus si ricarica il 50% più lentamente."},
	"sekhmet_heavy": {"god": "sekhmet", "heavy": true, "name": "Sete Insaziabile", "desc": "+60% ai danni del khopesh.", "cost": "Finché ci sono nemici nella stanza perdi 1 punto vita ogni 3 secondi."},
	"bastet_heavy": {"god": "bastet", "heavy": true, "name": "Gioco del Gatto", "desc": "I colpi critici fanno il triplo dei danni invece del doppio, e hai sempre almeno il 10% di probabilità di critico.", "cost": "-15 vita massima."},
	"sobek_heavy": {"god": "sobek", "heavy": true, "name": "Fauci di Sobek", "desc": "+50% ai danni del khopesh e i nemici vengono scagliati il doppio più lontano.", "cost": "Ti muovi il 15% più lento."},
	"iside_heavy": {"god": "iside", "heavy": true, "name": "Abbraccio di Iside", "desc": "Ogni stanza ripulita ti cura del 25% della vita massima.", "cost": "Il khopesh fa il 20% di danni in meno."},
	"thoth_heavy": {"god": "thoth", "heavy": true, "name": "Conoscenza Proibita", "desc": "L'Occhio di Horus si ricarica più del doppio più in fretta.", "cost": "Il khopesh fa il 35% di danni in meno."},
}

## Maledizioni di Set: durano un certo numero di ondate.
const SET_CURSES := {
	"fast_enemies": {"desc": "I nemici sono più veloci del 30%", "waves": 2},
	"fragile": {"desc": "Subisci il 50% di danni in più", "waves": 2},
	"no_eye": {"desc": "Non puoi usare l'Occhio di Horus", "waves": 2},
	"slow_dash": {"desc": "Lo scatto si ricarica in un tempo doppio", "waves": 2},
}

## Benedizioni di Set: arrivano quando la maledizione finisce e durano tutta la run.
const SET_BLESSINGS := {
	"set_might": {"name": "Forza di Set", "desc": "+25% a tutti i danni"},
	"set_vigor": {"name": "Vigore del Deserto", "desc": "+20 vita massima"},
	"set_sekhem": {"name": "Tempesta Interiore", "desc": "Il Sekhem si carica il 50% più in fretta"},
	"set_swift": {"name": "Vento Rosso", "desc": "+15% velocità di movimento"},
	"set_greed": {"name": "Tributo", "desc": "+50% Ka dai nemici"},
}


static func god_name(god: String) -> String:
	return GODS[god]["name"]


static func god_color(god: String) -> Color:
	return GODS[god]["color"]


static func is_heavy(id: String) -> bool:
	return ALL[id].get("heavy", false)


## Doni con un prezzo da mostrare (pesanti e doni di Anubi).
static func has_cost(id: String) -> bool:
	return ALL[id].has("cost")


## Testo del dono a un certo livello (1, 2 o 3).
static func text(id: String, level: int) -> String:
	var b: Dictionary = ALL[id]
	if is_heavy(id):
		return b["desc"]
	return b["desc"] % b["values"][clampi(level, 1, MAX_LEVEL) - 1]


## Le tre scelte offerte da un dio. `owned` = {id: livello} dei doni già presi.
## Prima i doni nuovi, poi i potenziamenti; a volte il dono pesante prende il terzo posto.
static func offers(god: String, owned: Dictionary) -> Array:
	var fresh := []
	var ups := []
	var heavy := ""
	for id in ALL:
		if ALL[id]["god"] != god:
			continue
		if is_heavy(id):
			if not owned.has(id):
				heavy = id
		elif not owned.has(id):
			fresh.append(id)
		elif owned[id] < MAX_LEVEL:
			ups.append(id)
	fresh.shuffle()
	ups.shuffle()
	var out := fresh + ups
	out = out.slice(0, 3)
	if heavy != "" and randf() < HEAVY_CHANCE:
		if out.size() >= 3:
			out[2] = heavy
		else:
			out.append(heavy)
	return out


## Dèi (tranne Set) che hanno ancora qualcosa da offrire.
static func gods_with_boons(owned: Dictionary) -> Array:
	var out := []
	for g in GODS:
		if g != "set" and g != "anubi" and not offers(g, owned).is_empty():
			out.append(g)
	return out


## Tre patti di Set: ognuno è una maledizione più una benedizione, scelte a caso.
static func set_offers(taken_blessings: Array) -> Array:
	var blessings := []
	for b in SET_BLESSINGS:
		if not taken_blessings.has(b):
			blessings.append(b)
	blessings.shuffle()
	var curses: Array = SET_CURSES.keys()
	curses.shuffle()
	var out := []
	for i in range(mini(3, blessings.size())):
		out.append({"curse": curses[i % curses.size()], "blessing": blessings[i]})
	return out
