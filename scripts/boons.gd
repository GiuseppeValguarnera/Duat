class_name Boons
## REGOLA DI BILANCIAMENTO
## Un dono normale di livello 1 vale circa +20% su un solo aspetto del gioco
## (danni del khopesh, danni dell'Occhio, difesa, mobilità...). I livelli 2 e 3 aggiungono
## circa metà di quel valore ciascuno. Un dono pesante vale circa +50%, con un prezzo.
## Un dono di Anubi ha un vantaggio di poco più grande del prezzo.
## Prima di aggiungere un dono, confrontalo con questa misura.
## Dèi, doni, doni pesanti e patti di Set.
## Per aggiungere un dono: una riga in ALL, poi il suo effetto in run.gd.

const MAX_LEVEL := 3
## Da quale stanza in poi un dio può comparire (1 = da subito). Es.: {"sekhmet": 3}
const MIN_ROOM := {}
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
	"duo": {"name": "Doppio", "color": Color(1.0, 0.86, 0.45)},
}

## `values` = il numero del dono ai livelli 1, 2 e 3 (entra nel %d della descrizione).
## I doni pesanti hanno un solo livello e un prezzo (`cost`).
const ALL := {
	"ra_burn": {"god": "ra", "name": "Colpo Solare", "desc": "Il khopesh incendia i nemici: %d danni ogni mezzo secondo per 2 secondi.", "values": [4, 5, 6]},
	"ra_disc": {"god": "ra", "name": "Disco di Ra", "desc": "L'Occhio di Horus esplode quando si ferma: %d danni a chi sta vicino.", "values": [14, 20, 26]},
	"ra_dawn": {"god": "ra", "name": "Corsa dell'Alba", "desc": "Lo scatto ferisce i nemici che attraversi (%d danni) e li incendia per 1 secondo.", "values": [4, 6, 8], "cost": "Lo scatto si ricarica il 40% più lentamente."},
	"ra_eye": {"god": "ra", "name": "Occhio Ardente", "desc": "L'Occhio di Horus incendia i nemici e fa il %d%% di danni in più.", "values": [15, 30, 45]},
	"sekhmet_fury": {"god": "sekhmet", "name": "Furia della Leonessa", "desc": "+%d%% ai danni del khopesh.", "values": [20, 30, 40]},
	"sekhmet_blood": {"god": "sekhmet", "name": "Sete di Sangue", "desc": "Ogni 5 nemici abbattuti ti curi di %d punti vita.", "values": [3, 4, 5]},
	"sekhmet_roar": {"god": "sekhmet", "name": "Ruggito", "desc": "Il terzo colpo della combo libera un'onda d'urto attorno a te: %d danni.", "values": [10, 14, 18]},
	"sekhmet_leap": {"god": "sekhmet", "name": "Balzo della Leonessa", "desc": "Il primo colpo dopo uno scatto fa il %d%% di danni in più.", "values": [50, 75, 100]},
	"thoth_pierce": {"god": "thoth", "name": "Sguardo di Thoth", "desc": "L'Occhio di Horus trapassa fino a %d nemici.", "values": [2, 3, 4]},
	"thoth_calc": {"god": "thoth", "name": "Calcolo di Thoth", "desc": "L'Occhio di Horus si ricarica il %d%% più in fretta.", "values": [25, 35, 45]},
	"thoth_tri": {"god": "thoth", "name": "Occhio Moltiplicato", "desc": "L'Occhio di Horus scaglia %d raggi a ventaglio, ognuno con il 60%% dei danni.", "values": [3, 4, 5]},
	"thoth_scribe": {"god": "thoth", "name": "Parola dello Scriba", "desc": "+%d%% ai danni dell'Occhio di Horus.", "values": [35, 50, 65]},
	# Bastet: colpi critici e agilità
	"bastet_claws": {"god": "bastet", "name": "Artigli Affilati", "desc": "Il khopesh ha il %d%% di probabilità di fare un colpo critico (danni doppi).", "values": [15, 22, 30]},
	"bastet_eyes": {"god": "bastet", "name": "Occhi di Gatto", "desc": "L'Occhio di Horus ha il %d%% di probabilità di fare un colpo critico (danni doppi).", "values": [15, 25, 35]},
	"bastet_step": {"god": "bastet", "name": "Passo Felino", "desc": "Lo scatto si ricarica il %d%% più in fretta.", "values": [20, 30, 40]},
	"bastet_lives": {"god": "bastet", "name": "Protezione di Bastet", "desc": "La prima volta che muori in questa run ti rialzi con il %d%% della vita.", "values": [30, 40, 50]},
	# Sobek: resistenza, controllo, acqua
	"sobek_skin": {"god": "sobek", "name": "Pelle di Coccodrillo", "desc": "Subisci il %d%% di danni in meno.", "values": [12, 18, 24]},
	"sobek_bite": {"god": "sobek", "name": "Morso di Sobek", "desc": "Il terzo colpo della combo stordisce i nemici per %.1f secondi.", "values": [0.6, 0.9, 1.2]},
	"sobek_tide": {"god": "sobek", "name": "Marea del Nilo", "desc": "Alla fine dello scatto lasci una pozza che rallenta i nemici del %d%% per 3 secondi.", "values": [30, 40, 50]},
	"sobek_river": {"god": "sobek", "name": "Forza del Fiume", "desc": "I nemici storditi dal Morso o rallentati dalla Marea subiscono il %d%% di danni in più.", "values": [20, 30, 40]},
	# Iside: protezione, cure, magia
	"iside_wings": {"god": "iside", "name": "Ali di Iside", "desc": "All'inizio di ogni stanza hai uno scudo che assorbe %d danni.", "values": [10, 15, 20]},
	"iside_tears": {"god": "iside", "name": "Lacrime di Iside", "desc": "Tutte le cure ti curano il %d%% in più.", "values": [20, 30, 40]},
	"iside_knot": {"god": "iside", "name": "Nodo di Iside", "desc": "Sotto un terzo della vita subisci il %d%% di danni in meno.", "values": [25, 35, 45]},
	"iside_word": {"god": "iside", "name": "Nome Segreto di Ra", "desc": "Il Sekhem si carica il %d%% più in fretta.", "values": [25, 40, 55]},
	# Anubi pesa ogni cosa: i suoi doni sono bilance, un vantaggio un po' più grande del prezzo.
	"anubi_light": {"god": "anubi", "balanced": true, "name": "Cuore Leggero", "desc": "Lo scatto si ricarica il %d%% più in fretta e ti muovi il 10%% più veloce.", "values": [15], "cost": "-10 vita massima."},
	"anubi_stone": {"god": "anubi", "balanced": true, "name": "Cuore di Pietra", "desc": "+%d vita massima.", "values": [30], "cost": "Ti muovi l'8% più lento."},
	"anubi_jackal": {"god": "anubi", "balanced": true, "name": "Fiuto dello Sciacallo", "desc": "+%d%% di danni ai nemici sotto metà vita.", "values": [30], "cost": "-10% di danni ai nemici sopra metà vita."},
	"anubi_scale": {"god": "anubi", "balanced": true, "name": "Bilancia Giusta", "desc": "Chi ti colpisce subisce il %d%% del danno che ti ha fatto.", "values": [150], "cost": "Subisci il 15% di danni in più."},
	"anubi_canopic": {"god": "anubi", "balanced": true, "name": "Vasi Canopi", "desc": "Ogni stanza ripulita ti cura di %d punti vita.", "values": [8], "cost": "-10 vita massima."},
	"anubi_mouth": {"god": "anubi", "balanced": true, "name": "Apertura della Bocca", "desc": "L'Occhio di Horus si ricarica il %d%% più in fretta.", "values": [35], "cost": "L'Occhio di Horus fa il 10% di danni in meno."},
	"anubi_linen": {"god": "anubi", "balanced": true, "name": "Bende di Lino", "desc": "Subisci il %d%% di danni in meno.", "values": [15], "cost": "Ti muovi il 5% più lento."},
	"anubi_guardian": {"god": "anubi", "balanced": true, "name": "Custode della Necropoli", "desc": "Il terzo colpo della combo fa il %d%% di danni in più.", "values": [50], "cost": "I primi due colpi della combo fanno il 10% di danni in meno."},
	"anubi_tribute": {"god": "anubi", "balanced": true, "name": "Offerte ai Defunti", "desc": "Ottieni il %d%% di Ka in più.", "values": [40], "cost": "-5 vita massima."},
	"anubi_guide": {"god": "anubi", "balanced": true, "name": "Guida delle Anime", "desc": "Ogni nemico abbattuto libera uno spirito che colpisce il nemico più vicino: %d danni.", "values": [15], "cost": "I nemici hanno il 5% di vita in più."},
	# Doni Doppi: compaiono quando hai già doni di entrambi gli dèi
	"duo_ra_thoth": {"god": "duo", "gods": ["ra", "thoth"], "name": "Occhio del Sole", "desc": "L'Occhio di Horus incendia sempre ed esplode quando si ferma (almeno 12 danni)."},
	"duo_ra_sekhmet": {"god": "duo", "gods": ["ra", "sekhmet"], "name": "Sole Furente", "desc": "I nemici in fiamme subiscono il 25% di danni in più dal khopesh."},
	"duo_sekhmet_bastet": {"god": "duo", "gods": ["sekhmet", "bastet"], "name": "Caccia delle Leonesse", "desc": "I colpi critici del khopesh liberano un ruggito che ferisce chi ti sta attorno (12 danni)."},
	"duo_thoth_bastet": {"god": "duo", "gods": ["thoth", "bastet"], "name": "Sguardo del Gatto Sapiente", "desc": "Un colpo critico dell'Occhio di Horus ne dimezza la ricarica."},
	"duo_sobek_iside": {"god": "duo", "gods": ["sobek", "iside"], "name": "Piena Sacra", "desc": "Finché hai lo scudo di Iside, il khopesh fa il 25% di danni in più."},
	"ra_heavy": {"god": "ra", "heavy": true, "name": "Ira del Sole", "desc": "Tutti i tuoi colpi incendiano, e le fiamme fanno il 60% di danni in più.", "cost": "L'Occhio di Horus si ricarica il 50% più lentamente."},
	"sekhmet_heavy": {"god": "sekhmet", "heavy": true, "name": "Sete Insaziabile", "desc": "+50% ai danni del khopesh.", "cost": "Finché ci sono nemici nella stanza perdi 1 punto vita ogni 3 secondi."},
	"bastet_heavy": {"god": "bastet", "heavy": true, "name": "Gioco del Gatto", "desc": "I colpi critici fanno il triplo dei danni invece del doppio, e hai sempre almeno il 10% di probabilità di critico.", "cost": "-15 vita massima."},
	"sobek_heavy": {"god": "sobek", "heavy": true, "name": "Fauci di Sobek", "desc": "+40% ai danni del khopesh e i nemici vengono scagliati il doppio più lontano.", "cost": "Ti muovi il 15% più lento."},
	"iside_heavy": {"god": "iside", "heavy": true, "name": "Abbraccio di Iside", "desc": "Ogni stanza ripulita ti cura del 15% della vita massima.", "cost": "Il khopesh fa il 20% di danni in meno."},
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
	"set_might": {"name": "Forza di Set", "desc": "+20% a tutti i danni"},
	"set_vigor": {"name": "Vigore del Deserto", "desc": "+15 vita massima"},
	"set_sekhem": {"name": "Tempesta Interiore", "desc": "Il Sekhem si carica il 50% più in fretta"},
	"set_swift": {"name": "Vento Rosso", "desc": "+15% velocità di movimento"},
	"set_greed": {"name": "Tributo", "desc": "+50% di Ka"},
	"set_rage": {"name": "Ira del Deserto", "desc": "Attacchi con il khopesh il 15% più rapidamente"},
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
	if is_heavy(id) or not b.has("values"):
		return b["desc"]
	return b["desc"] % b["values"][clampi(level, 1, MAX_LEVEL) - 1]


## Le tre scelte offerte da un dio. `owned` = {id: livello} dei doni già presi.
## Prima i doni nuovi, poi i potenziamenti; a volte il dono pesante prende il terzo posto.
## Doni che riguardano il Sekhem: compaiono solo dopo averlo sbloccato sconfiggendo Ammit.
const NEEDS_SEKHEM := ["iside_word", "set_sekhem"]


static func available_now(id: String) -> bool:
	return not NEEDS_SEKHEM.has(id) or Meta.sekhem_unlocked


static func offers(god: String, owned: Dictionary) -> Array:
	var fresh := []
	var ups := []
	var heavy := ""
	for id in ALL:
		if ALL[id]["god"] != god or not available_now(id):
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
	# se non resta altro, il dono pesante compare sempre (altrimenti il menu sarebbe vuoto)
	if heavy != "" and (out.is_empty() or randf() < HEAVY_CHANCE):
		if out.size() >= 3:
			out[2] = heavy
		else:
			out.append(heavy)
	return out


## Dèi (tranne Set) che hanno ancora qualcosa da offrire.
static func gods_with_boons(owned: Dictionary, for_room: int = 99) -> Array:
	var out := []
	for g in GODS:
		if MIN_ROOM.get(g, 1) > for_room:
			continue
		if g != "set" and g != "anubi" and g != "duo" and not offers(g, owned).is_empty():
			out.append(g)
	return out


## Tre patti di Set: ognuno è una maledizione più una benedizione, scelte a caso.
static func set_offers(taken_blessings: Array) -> Array:
	var blessings := []
	for b in SET_BLESSINGS:
		if not taken_blessings.has(b) and available_now(b):
			blessings.append(b)
	blessings.shuffle()
	var curses: Array = SET_CURSES.keys()
	curses.shuffle()
	var out := []
	for i in range(mini(3, blessings.size())):
		out.append({"curse": curses[i % curses.size()], "blessing": blessings[i]})
	return out


## Probabilità che un Dono Doppio prenda il posto di una delle tre scelte, quando è disponibile.
const DUO_CHANCE := 0.45


static func is_duo(id: String) -> bool:
	return ALL[id]["god"] == "duo"


static func has_god(owned: Dictionary, god: String) -> bool:
	for id in owned:
		if ALL[id]["god"] == god:
			return true
	return false


## Doni Doppi che il dio `god` può offrire: serve già un dono dell'altro dio.
static func duos_for(god: String, owned: Dictionary) -> Array:
	var out := []
	for id in ALL:
		if not is_duo(id) or owned.has(id):
			continue
		var gods: Array = ALL[id]["gods"]
		if not gods.has(god):
			continue
		var other: String = gods[1] if gods[0] == god else gods[0]
		if has_god(owned, other) and has_god(owned, god):
			out.append(id)
	return out

