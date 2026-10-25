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
	"horus": {"name": "Horus", "color": Color(0.36, 0.55, 1.0)},
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
	"sobek_river": {"god": "sobek", "name": "Forza del Fiume", "desc": "I nemici storditi dal Morso di Sobek o rallentati dalla Marea del Nilo subiscono il %d%% di danni in più.", "values": [20, 30, 40]},
	# doni che esistono solo per un'arma: compaiono soltanto se la impugni
	"sobek_tail": {"god": "sobek", "weapon": "lancia", "name": "Colpo di Coda", "desc": "La spazzata della lancia fa il %d%% di danni in più e scaglia i nemici il doppio più lontano.", "values": [25, 35, 45]},
	"sekhmet_crescent": {"god": "sekhmet", "weapon": "khopesh", "name": "Zanna Ricurva", "desc": "I primi due fendenti del khopesh fanno il %d%% di danni in più.", "values": [20, 30, 40]},
	"bastet_point": {"god": "bastet", "weapon": "lancia", "name": "Punta Felina", "desc": "L'affondo della lancia dopo uno scatto ha il %d%% di probabilità di essere un colpo critico.", "values": [35, 50, 65]},
	"bastet_dance": {"god": "bastet", "weapon": "khopesh", "name": "Danza delle Lame", "desc": "Il khopesh colpisce il %d%% più rapidamente.", "values": [10, 15, 20]},
	"ra_edge": {"god": "ra", "weapon": "khopesh", "name": "Filo del Sole", "desc": "I fendenti del khopesh arrivano il %d%% più lontano e sono più ampi.", "values": [12, 18, 25]},
	# Iside: protezione, cure, magia
	"iside_wings": {"god": "iside", "name": "Ali di Iside", "desc": "All'inizio di ogni stanza hai uno scudo che assorbe %d danni.", "values": [10, 15, 20]},
	"iside_tears": {"god": "iside", "name": "Lacrime di Iside", "desc": "Tutte le cure ti curano il %d%% in più.", "values": [20, 30, 40]},
	"iside_knot": {"god": "iside", "name": "Nodo di Iside", "desc": "Sotto un terzo della vita subisci il %d%% di danni in meno.", "values": [25, 35, 45]},
	"iside_word": {"god": "iside", "name": "Nome Segreto di Ra", "desc": "Il Sekhem si carica il %d%% più in fretta.", "values": [25, 40, 55]},
	# Anubi pesa ogni cosa: i suoi doni sono bilance, un vantaggio un po' più grande del prezzo.
	"horus_return": {"god": "horus", "name": "Ritorno del Falco", "desc": "L'Occhio di Horus, finito il volo, torna da te e colpisce di nuovo chi incontra: %d%% dei danni.", "values": [60, 80, 100]},
	"horus_seek": {"god": "horus", "name": "Volo del Falco", "desc": "L'Occhio di Horus curva da solo verso il nemico più vicino e fa il %d%% di danni in più.", "values": [10, 20, 30]},
	"horus_twin": {"god": "horus", "name": "Il Sole e la Luna", "desc": "L'Occhio di Horus ha %d cariche: puoi lanciarlo più volte di fila.", "values": [2, 3, 4]},
	"horus_harpoon": {"god": "horus", "weapon": "lancia", "name": "Arpione di Horus", "desc": "Gli affondi della lancia fanno il %d%% di danni in più ai nemici lontani, sulla punta.", "values": [25, 40, 55]},
	"horus_mark": {"god": "horus", "name": "Sguardo del Falco", "desc": "I nemici colpiti dall'Occhio subiscono il %d%% di danni in più dal khopesh per 3 secondi.", "values": [20, 30, 40]},
	"anubi_light": {"god": "anubi", "balanced": true, "name": "Cuore Leggero", "desc": "Lo scatto si ricarica il %d%% più in fretta e ti muovi il 12%% più veloce.", "values": [20], "cost": "-5 vita massima."},
	"anubi_stone": {"god": "anubi", "balanced": true, "name": "Cuore di Pietra", "desc": "+%d vita massima.", "values": [12], "cost": "Ti muovi il 6% più lento."},
	"anubi_jackal": {"god": "anubi", "balanced": true, "name": "Fiuto dello Sciacallo", "desc": "+%d%% di danni ai nemici sotto metà vita.", "values": [30], "cost": "-10% di danni ai nemici sopra metà vita."},
	"anubi_scale": {"god": "anubi", "balanced": true, "name": "Bilancia Giusta", "desc": "Chi ti colpisce subisce il %d%% del danno che ti ha fatto.", "values": [150], "cost": "Subisci il 15% di danni in più."},
	"anubi_canopic": {"god": "anubi", "balanced": true, "name": "Vasi Canopi", "desc": "Ogni stanza ripulita ti cura di %d punti vita.", "values": [8], "cost": "-10 vita massima."},
	"anubi_mouth": {"god": "anubi", "balanced": true, "name": "Apertura della Bocca", "desc": "L'Occhio di Horus si ricarica il %d%% più in fretta.", "values": [35], "cost": "L'Occhio di Horus fa il 10% di danni in meno."},
	"anubi_linen": {"god": "anubi", "balanced": true, "name": "Bende di Lino", "desc": "Subisci il %d%% di danni in meno.", "values": [15], "cost": "Ti muovi il 5% più lento."},
	"anubi_guardian": {"god": "anubi", "balanced": true, "name": "Custode della Necropoli", "desc": "Il terzo colpo della combo fa il %d%% di danni in più.", "values": [50], "cost": "I primi due colpi della combo fanno il 10% di danni in meno."},
	"anubi_tribute": {"god": "anubi", "balanced": true, "name": "Offerte ai Defunti", "desc": "Ottieni il %d%% di Ka in più.", "values": [40], "cost": "-5 vita massima."},
	"anubi_guide": {"god": "anubi", "balanced": true, "name": "Guida delle Anime", "desc": "Ogni nemico abbattuto libera uno spirito che colpisce il nemico più vicino: %d danni.", "values": [22], "cost": "I nemici hanno il 5% di vita in più."},
	# Doni Doppi: compaiono quando hai già doni di entrambi gli dèi
	"duo_ra_thoth": {"god": "duo", "gods": ["ra", "thoth"], "name": "Occhio del Sole", "desc": "L'Occhio di Horus incendia sempre ed esplode quando si ferma (almeno 12 danni)."},
	"duo_ra_sekhmet": {"god": "duo", "gods": ["ra", "sekhmet"], "name": "Sole Furente", "desc": "I nemici in fiamme subiscono il 25% di danni in più dal khopesh."},
	"duo_sekhmet_bastet": {"god": "duo", "gods": ["sekhmet", "bastet"], "name": "Caccia delle Leonesse", "desc": "I colpi critici del khopesh liberano un ruggito che ferisce chi ti sta attorno (12 danni)."},
	"duo_thoth_bastet": {"god": "duo", "gods": ["thoth", "bastet"], "name": "Sguardo del Gatto Sapiente", "desc": "Un colpo critico dell'Occhio di Horus ne dimezza la ricarica."},
	"duo_sobek_iside": {"god": "duo", "gods": ["sobek", "iside"], "name": "Piena Sacra", "desc": "Finché hai lo scudo di Iside, il khopesh fa il 25% di danni in più."},
	# Thoth guarì l'Occhio di Horus strappato da Set: da allora l'Occhio è "sano" (wedjat)
	"duo_horus_thoth": {"god": "duo", "gods": ["horus", "thoth"], "name": "Occhio Risanato", "desc": "Quando l'Occhio di Horus abbatte un nemico, si ricarica all'istante."},
	# Iside, madre di Horus, curò il figlio nelle paludi del Delta
	"duo_iside_horus": {"god": "duo", "gods": ["iside", "horus"], "name": "Figlio di Iside", "desc": "Ogni lancio dell'Occhio di Horus che colpisce almeno un nemico ti cura di 2 punti vita."},
	"duo_anubi_sekhmet": {"god": "duo", "gods": ["anubi", "sekhmet"], "name": "Giudizio della Leonessa", "desc": "Il khopesh abbatte all'istante i nemici sotto il 15% della vita (non i guardiani e i boss)."},
	"duo_sobek_horus": {"god": "duo", "gods": ["sobek", "horus"], "weapon": "lancia", "name": "Arpione del Coccodrillo", "desc": "Gli affondi della lancia stordiscono per 0,6 secondi i nemici colpiti con la punta (meno i guardiani e i boss)."},
	"ra_heavy": {"god": "ra", "heavy": true, "name": "Ira del Sole", "desc": "Tutti i tuoi colpi incendiano, e le fiamme fanno il 60% di danni in più.", "cost": "L'Occhio di Horus si ricarica il 50% più lentamente."},
	"sekhmet_heavy": {"god": "sekhmet", "heavy": true, "name": "Sete Insaziabile", "desc": "+50% ai danni del khopesh.", "cost": "Finché ci sono nemici nella stanza perdi 1 punto vita ogni 2 secondi."},
	"bastet_heavy": {"god": "bastet", "heavy": true, "name": "Gioco del Gatto", "desc": "I colpi critici fanno il triplo dei danni invece del doppio, e hai sempre almeno il 10% di probabilità di critico.", "cost": "-15 vita massima."},
	"sobek_heavy": {"god": "sobek", "heavy": true, "name": "Fauci di Sobek", "desc": "+40% ai danni del khopesh e i nemici vengono scagliati il doppio più lontano.", "cost": "Ti muovi il 15% più lento."},
	"iside_heavy": {"god": "iside", "heavy": true, "name": "Abbraccio di Iside", "desc": "Ogni stanza ripulita ti cura del 15% della vita massima.", "cost": "Il khopesh fa il 25% di danni in meno."},
	"horus_heavy": {"god": "horus", "heavy": true, "name": "Occhio del Re", "desc": "L'Occhio di Horus fa il doppio dei danni e trapassa tutti i nemici.", "cost": "Il khopesh fa il 40% di danni in meno."},
	"thoth_heavy": {"god": "thoth", "heavy": true, "name": "Conoscenza Proibita", "desc": "L'Occhio di Horus si ricarica più del doppio più in fretta.", "cost": "Il khopesh fa il 35% di danni in meno."},
}

## Maledizioni di Set: durano le prossime stanze (contate quando le ripulisci), poi arriva la benedizione.
const SET_CURSES := {
	"fast_enemies": {"desc": "I nemici sono più veloci del 20%", "rooms": 2},
	"fragile": {"desc": "Subisci il 30% di danni in più", "rooms": 2},
	"tough": {"desc": "I nemici hanno il 25% di vita in più", "rooms": 2},
	"thirst": {"desc": "Le cure ti curano il 40% in meno", "rooms": 2},
	"bleed": {"desc": "Finché ci sono nemici perdi 1 vita ogni 3 secondi", "rooms": 2},
}

## Benedizioni di Set: arrivano quando la maledizione finisce e durano tutta la run.
const SET_BLESSINGS := {
	"set_might": {"name": "Forza di Set", "desc": "+25% a tutti i danni"},
	"set_vigor": {"name": "Vigore del Deserto", "desc": "+15 vita massima"},
	"set_sekhem": {"name": "Tempesta Interiore", "desc": "Il Sekhem si carica il 50% più in fretta"},
	"set_swift": {"name": "Vento Rosso", "desc": "+15% velocità di movimento"},
	"set_greed": {"name": "Tributo", "desc": "+50% di Ka"},
	"set_rage": {"name": "Ira del Deserto", "desc": "Attacchi con il khopesh il 20% più rapidamente"},
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
		return Weapons.adapt(b["desc"])
	return Weapons.adapt(b["desc"] % b["values"][clampi(level, 1, MAX_LEVEL) - 1])


## Le tre scelte offerte da un dio. `owned` = {id: livello} dei doni già presi.
## Prima i doni nuovi, poi i potenziamenti; a volte il dono pesante prende il terzo posto.
## Doni che riguardano il Sekhem: compaiono solo dopo averlo sbloccato sconfiggendo Am-heh.
const NEEDS_SEKHEM := ["iside_word", "set_sekhem"]


static func available_now(id: String) -> bool:
	return not NEEDS_SEKHEM.has(id) or Meta.sekhem_unlocked


## Doni che funzionano solo insieme ad altri: compaiono soltanto se ne possiedi almeno uno.
const REQUIRES := {
	"sobek_river": ["sobek_bite", "sobek_tide"],
	"duo_ra_sekhmet": ["ra_burn", "ra_dawn", "ra_eye", "ra_heavy"],
	"duo_sekhmet_bastet": ["bastet_claws", "bastet_heavy", "bastet_point"],
	"duo_thoth_bastet": ["bastet_eyes", "bastet_heavy"],
	"duo_sobek_iside": ["iside_wings"],
	# il dono di Anubi c'è quasi sempre (lo dà all'inizio): serve uno di quelli che riguardano i colpi
	"duo_anubi_sekhmet": ["anubi_jackal", "anubi_guardian", "anubi_scale", "anubi_guide"],
}


static func requirements_met(id: String, owned: Dictionary) -> bool:
	if not REQUIRES.has(id):
		return true
	for r in REQUIRES[id]:
		if owned.has(r):
			return true
	return false


static func offers(god: String, owned: Dictionary) -> Array:
	var fresh := []
	var ups := []
	var heavy := ""
	for id in ALL:
		if ALL[id]["god"] != god or not available_now(id):
			continue
		if not owned.has(id) and not requirements_met(id, owned):
			continue
		if ALL[id].has("weapon") and ALL[id]["weapon"] != Run.weapon:
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
		if not is_duo(id) or owned.has(id) or not requirements_met(id, owned):
			continue
		if ALL[id].has("weapon") and ALL[id]["weapon"] != Run.weapon:
			continue
		var gods: Array = ALL[id]["gods"]
		if not gods.has(god):
			continue
		var other: String = gods[1] if gods[0] == god else gods[0]
		if has_god(owned, other) and has_god(owned, god):
			out.append(id)
	return out




## Riassunto breve di ogni dono, mostrato in fondo alla carta: [vantaggio, prezzo].
## Il %d prende il valore del livello, come nella descrizione.
const SHORT := {
	"ra_burn": ["Arma: fuoco %d ogni 0,5 s", ""],
	"ra_disc": ["Occhio esplode: %d danni", ""],
	"ra_dawn": ["Scatto ferisce: %d danni", "Scatto -40% più lento"],
	"ra_eye": ["Occhio +%d%% danni e incendia", ""],
	"sekhmet_fury": ["Khopesh +%d%% danni", ""],
	"sekhmet_blood": ["+%d vita ogni 5 uccisioni", ""],
	"sekhmet_roar": ["3° colpo: onda di %d danni", ""],
	"sekhmet_leap": ["Dopo lo scatto +%d%% danni", ""],
	"thoth_pierce": ["Occhio trapassa %d nemici", ""],
	"thoth_calc": ["Occhio ricarica -%d%%", ""],
	"thoth_tri": ["Occhio: %d raggi a ventaglio", ""],
	"thoth_scribe": ["Occhio +%d%% danni", ""],
	"bastet_claws": ["Khopesh %d%% critico", ""],
	"bastet_eyes": ["Occhio %d%% critico", ""],
	"bastet_step": ["Scatto ricarica -%d%%", ""],
	"bastet_lives": ["Ti rialzi con il %d%%", ""],
	"sobek_skin": ["-%d%% danni subiti", ""],
	"sobek_bite": ["3° colpo stordisce", ""],
	"sobek_tide": ["Pozza: nemici -%d%% veloci", ""],
	"sobek_river": ["+%d%% su storditi e lenti", ""],
	"sobek_tail": ["Spazzata +%d%%, spinta ×2", ""],
	"sekhmet_crescent": ["1° e 2° fendente +%d%% danni", ""],
	"bastet_point": ["Affondo: %d%% critico", ""],
	"bastet_dance": ["Khopesh +%d%% più rapido", ""],
	"ra_edge": ["Fendenti +%d%% più lunghi", ""],
	"horus_harpoon": ["Punta: affondi +%d%%", ""],
	"iside_wings": ["Scudo di %d a ogni stanza", ""],
	"iside_tears": ["Cure +%d%%", ""],
	"iside_knot": ["Sotto 1/3 vita: -%d%% danni", ""],
	"iside_word": ["Sekhem +%d%% più rapido", ""],
	"horus_return": ["Occhio torna: %d%% danni", ""],
	"horus_seek": ["Occhio insegue · +%d%% danni", ""],
	"horus_twin": ["Occhio: %d cariche", ""],
	"horus_mark": ["Colpiti dall'Occhio: +%d%%", ""],
	"anubi_light": ["Scatto -%d%% · +12%% velocità", "-5 vita massima"],
	"anubi_stone": ["+%d vita massima", "-6% velocità"],
	"anubi_jackal": ["+%d%% danni sotto metà vita", "-10% danni sopra metà"],
	"anubi_scale": ["Rifletti il %d%% dei danni", "+15% danni subiti"],
	"anubi_canopic": ["+%d vita a ogni stanza", "-10 vita massima"],
	"anubi_mouth": ["Occhio ricarica -%d%%", "Occhio -10% danni"],
	"anubi_linen": ["-%d%% danni subiti", "-5% velocità"],
	"anubi_guardian": ["3° colpo +%d%%", "1° e 2° colpo -10%"],
	"anubi_tribute": ["+%d%% Ka", "-5 vita massima"],
	"anubi_guide": ["Spiriti da %d danni", "Nemici +5% vita"],
	"duo_ra_thoth": ["Occhio incendia, esplode", ""],
	"duo_ra_sekhmet": ["+25% sui nemici in fiamme", ""],
	"duo_sekhmet_bastet": ["Critici: ruggito di 12 danni", ""],
	"duo_thoth_bastet": ["Critico: ricarica Occhio -50%", ""],
	"duo_sobek_iside": ["Con lo scudo: khopesh +25%", ""],
	"duo_horus_thoth": ["Occhio uccide: ricarica subito", ""],
	"duo_iside_horus": ["Occhio a segno: +2 vita", ""],
	"duo_anubi_sekhmet": ["Sotto il 15%: abbattuto", ""],
	"duo_sobek_horus": ["Punta: stordisce 0,6 s", ""],
	"ra_heavy": ["Tutto incendia · fiamme +60%", "Occhio ricarica +50%"],
	"sekhmet_heavy": ["Khopesh +50%", "In lotta: -1 vita ogni 2 s"],
	"bastet_heavy": ["Critici ×3 · almeno 10%", "-15 vita massima"],
	"sobek_heavy": ["Khopesh +40% · spinta doppia", "-15% velocità"],
	"iside_heavy": ["+15% vita a ogni stanza", "Khopesh -25%"],
	"thoth_heavy": ["Occhio: ricarica ×2", "Khopesh -35%"],
	"horus_heavy": ["Occhio ×2, trapassa tutti", "Khopesh -40%"],
}


static func short(id: String, level: int) -> Array:
	if not SHORT.has(id):
		return ["", ""]
	var gain: String = SHORT[id][0]
	var b: Dictionary = ALL[id]
	if gain.find("%d") >= 0 and b.has("values"):
		gain = gain % int(round(b["values"][clampi(level, 1, b["values"].size()) - 1]))
	return [Weapons.adapt(gain), Weapons.adapt(SHORT[id][1])]
