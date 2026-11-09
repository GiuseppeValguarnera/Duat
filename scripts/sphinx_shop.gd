class_name SphinxShop
extends RefCounted
## La Sfinge come luogo (blocco 17): modificatori della prova, sigilli e Tesoro della Sfinge.
## Tutto è salvato in Meta.sphinx (compatibile coi salvataggi di prima: chiavi nuove con default).
##
## SIGILLI: solo nella prova. 1 a ondata superata, +2 per ogni guardiano abbattuto, +1 per ogni ondata
## senza colpi (+1 con la Moneta della Sfinge). Una prova media (ondata 8-12) ne dà circa 15-20: i
## piccoli oggetti costano 20-80 (2-5 prove), il Favore 450 (25-30 prove).

const SEALS_WAVE := 1
const SEALS_GUARD := 2
const SEALS_CLEAN := 1
const MAX_MODS := 3

## Modificatori: si scelgono PRIMA della prova e valgono per tutta la prova. `bonus` si somma al
## moltiplicatore del punteggio (1 + somma). Riusano gli effetti degli enigmi. I premi della
## settimana restano legati all'ondata: i modificatori non li cambiano.
const MODS_IT := {
	"tough": {"name": "Pietra Dura", "desc": "I nemici hanno il 30% di vita in più.", "bonus": 0.3},
	"fast": {"name": "Vento del Deserto", "desc": "I nemici sono più veloci del 15%.", "bonus": 0.25},
	"noheal": {"name": "Digiuno", "desc": "Nessuna cura, di nessun tipo: né quella ogni 5 ondate, né quella degli enigmi, né quella dei doni.", "bonus": 0.35},
	"fragile": {"name": "Pelle Sottile", "desc": "Dopo un colpo resti invulnerabile la metà del tempo.", "bonus": 0.3},
	"horde": {"name": "Sciame", "desc": "Ogni ondata ha 3 nemici in più.", "bonus": 0.3, "shop": 40},
	"first": {"name": "Primo Sangue", "desc": "Il primo colpo che subisci in ogni ondata fa il 50% di danni in più (i colpi restano quelli di sempre, con il loro avviso).", "bonus": 0.25, "shop": 40},
	"elite": {"name": "Corte d'Oro", "desc": "In ogni ondata un nemico in più è élite, fin dalla prima.", "bonus": 0.35, "shop": 60},
	"sting": {"name": "Morso del Deserto", "desc": "I nemici fanno il 20% di danni in più.", "bonus": 0.3, "shop": 60},
}
const MOD_ORDER := ["tough", "fast", "noheal", "fragile", "horde", "first", "elite", "sting"]

## Il Tesoro: niente potenza per le discese, tranne il Favore. kind: mod, riddles, title, frame,
## ornament, talk, tale, favor.
const ITEMS_IT := {
	"m_horde": {"kind": "mod", "mod": "horde", "cost": 40, "name": "Modificatore: Sciame", "desc": "Sblocca il modificatore Sciame: ogni ondata ha 3 nemici in più (+0,30 al moltiplicatore)."},
	"m_first": {"kind": "mod", "mod": "first", "cost": 40, "name": "Modificatore: Primo Sangue", "desc": "Sblocca il modificatore Primo Sangue: il primo colpo subito in ogni ondata fa il 50% di danni in più (+0,25)."},
	"m_elite": {"kind": "mod", "mod": "elite", "cost": 60, "name": "Modificatore: Corte d'Oro", "desc": "Sblocca il modificatore Corte d'Oro: un'élite in più in ogni ondata (+0,35)."},
	"m_sting": {"kind": "mod", "mod": "sting", "cost": 60, "name": "Modificatore: Morso del Deserto", "desc": "Sblocca il modificatore Morso del Deserto: i nemici fanno il 20% di danni in più (+0,30)."},
	"r_nilo": {"kind": "riddles", "cost": 50, "name": "Enigmi del fiume", "desc": "Quattro enigmi nuovi sul Nilo e i suoi dèi, che la Sfinge mescola agli altri nelle pause."},
	"r_stelle": {"kind": "riddles", "cost": 50, "name": "Enigmi del cielo", "desc": "Quattro enigmi nuovi sulle stelle, il cielo di Nut e i viaggi del sole."},
	"t_viandante": {"kind": "title", "cost": 20, "name": "Titolo: Viandante", "desc": "Un titolo accanto al tuo nome nella classifica della Sfinge."},
	"t_solutore": {"kind": "title", "cost": 40, "name": "Titolo: Solutore di enigmi", "desc": "Un titolo accanto al tuo nome nella classifica della Sfinge."},
	"t_amico": {"kind": "title", "cost": 60, "name": "Titolo: Amico della Sfinge", "desc": "Un titolo accanto al tuo nome nella classifica. Lei dirà che non è vero."},
	"t_custode": {"kind": "title", "cost": 80, "name": "Titolo: Custode della scala", "desc": "Il titolo più alto nella classifica della Sfinge."},
	"f_lapis": {"kind": "frame", "cost": 50, "name": "Cornice di lapislazzuli", "desc": "Una cornice blu e oro intorno alla tua classifica."},
	"f_oro": {"kind": "frame", "cost": 80, "name": "Cornice d'oro", "desc": "Una cornice d'oro intorno alla tua classifica, con le gemme agli angoli."},
	"o_collare": {"kind": "ornament", "cost": 40, "name": "Collare usekh", "desc": "Un largo collare d'oro e lapislazzuli sul petto della Sfinge."},
	"o_gioielli": {"kind": "ornament", "cost": 30, "name": "Orecchini e ureo", "desc": "Orecchini d'oro e un ureo di lapislazzuli sulla fronte della Sfinge."},
	"o_loti": {"kind": "ornament", "cost": 30, "name": "Fiori di loto", "desc": "Mazzi di loti bianchi e blu ai piedi della Sfinge."},
	"o_bracieri": {"kind": "ornament", "cost": 60, "name": "Bracieri accesi", "desc": "Due bracieri di bronzo accesi ai lati della Sfinge, nell'arena."},
	"o_stendardi": {"kind": "ornament", "cost": 50, "name": "Stendardi", "desc": "Due stendardi blu e oro appesi alla parete, dietro la Sfinge."},
	"d_ricordi": {"kind": "talk", "cost": 40, "name": "Ricordi della Sfinge", "desc": "Nel menu compare «Ascolta»: la Sfinge racconta qualcosa di sé, a modo suo."},
	"s_harmachis": {"kind": "tale", "cost": 30, "name": "Racconto: Horemakhet", "desc": "Un racconto nuovo per la vasca della Sala: la Sfinge come Horus nell'orizzonte."},
	"s_thutmose": {"kind": "tale", "cost": 30, "name": "Racconto: il sogno di Thutmose", "desc": "Un racconto nuovo per la vasca della Sala: la stele del sogno, tra le zampe della Sfinge."},
	"favore": {"kind": "favor", "cost": 450, "name": "Il Favore della Sfinge", "desc": "Nelle discese normali, a volte uno dei doni della Sfinge prende l'ultimo posto tra le scelte degli dèi (circa una scelta su otto). Mai garantito, al massimo uno per discesa, mai insieme a un dono doppio, pesante o raro. È l'unica cosa del Tesoro che conta nelle discese."},
}
const ITEM_ORDER := ["m_horde", "m_first", "m_elite", "m_sting", "r_nilo", "r_stelle", "o_collare", "o_gioielli", "o_loti",
	"o_bracieri", "o_stendardi", "t_viandante", "t_solutore", "t_amico", "t_custode", "f_lapis", "f_oro", "d_ricordi",
	"s_harmachis", "s_thutmose", "favore"]

static var MODS: Dictionary = {}
static var ITEMS: Dictionary = {}


static func refresh_lang() -> void:
	MODS = Lang.deep(MODS_IT)
	ITEMS = Lang.deep(ITEMS_IT)


static func mods() -> Dictionary:
	if MODS.is_empty():
		refresh_lang()
	return MODS


static func items() -> Dictionary:
	if ITEMS.is_empty():
		refresh_lang()
	return ITEMS


# --- sigilli e acquisti ---------------------------------------------------------------------

static func seals() -> int:
	return int(Meta.sphinx.get("seals", 0))


static func add_seals(n: int) -> void:
	if n <= 0:
		return
	Meta.sphinx["seals"] = seals() + n
	Meta.sphinx["seals_total"] = int(Meta.sphinx.get("seals_total", 0)) + n
	Meta.save()


static func owns(id: String) -> bool:
	if id == "favore":
		return Favors.has("favore_sfinge")
	return (Meta.sphinx.get("owned", []) as Array).has(id)


static func buy(id: String) -> bool:
	var it: Dictionary = ITEMS_IT[id]
	if owns(id) or seals() < int(it["cost"]):
		return false
	Meta.sphinx["seals"] = seals() - int(it["cost"])
	if id == "favore":
		Favors.grant("favore_sfinge")
	else:
		var o: Array = Meta.sphinx.get("owned", [])
		o.append(id)
		Meta.sphinx["owned"] = o
		# un ornamento comprato si indossa subito; titolo e cornice si usano subito
		match String(it["kind"]):
			"ornament":
				var on: Array = Meta.sphinx.get("orn_on", [])
				on.append(id)
				Meta.sphinx["orn_on"] = on
			"title":
				Meta.sphinx["title"] = id
			"frame":
				Meta.sphinx["frame"] = id
	Meta.save()
	return true


# --- modificatori ----------------------------------------------------------------------------

static func mod_unlocked(m: String) -> bool:
	return not MODS_IT[m].has("shop") or owns("m_" + m)


static func mods_on() -> Array:
	var out := []
	for m in Meta.sphinx.get("mods_on", []):
		if MODS_IT.has(m) and mod_unlocked(String(m)):
			out.append(String(m))
	return out


static func has_mod(m: String) -> bool:
	return mods_on().has(m)


## Accende o spegne un modificatore; false se sono già MAX_MODS (o è bloccato).
static func toggle_mod(m: String) -> bool:
	var on := mods_on()
	if on.has(m):
		on.erase(m)
	elif on.size() >= MAX_MODS or not mod_unlocked(m):
		return false
	else:
		on.append(m)
	Meta.sphinx["mods_on"] = on
	Meta.save()
	return true


static func mult(list: Array) -> float:
	var k := 1.0
	for m in list:
		if MODS_IT.has(m):
			k += float(MODS_IT[m]["bonus"])
	return k


static func mult_text(k: float) -> String:
	return ("×%.2f" % k).replace(".", ",") if Lang.code() == "it" else "×%.2f" % k


static func mod_names(list: Array) -> String:
	var parts := []
	for m in list:
		if mods().has(m):
			parts.append(String(mods()[m]["name"]))
	return ", ".join(parts)


# --- ornamenti, titolo, cornice --------------------------------------------------------------

static func ornament_on(id: String) -> bool:
	return owns(id) and (Meta.sphinx.get("orn_on", []) as Array).has(id)


static func toggle_ornament(id: String) -> void:
	var on: Array = Meta.sphinx.get("orn_on", [])
	if on.has(id):
		on.erase(id)
	elif owns(id):
		on.append(id)
	Meta.sphinx["orn_on"] = on
	Meta.save()


static func title_text() -> String:
	var t := String(Meta.sphinx.get("title", ""))
	if t == "" or not owns(t):
		return ""
	return String(items()[t]["name"]).get_slice(": ", 1)


static func frame() -> String:
	var f := String(Meta.sphinx.get("frame", ""))
	return f if f != "" and owns(f) else ""


## Usa (o smette di usare) un titolo o una cornice comprati.
static func select(id: String) -> void:
	var key := "title" if String(ITEMS_IT[id]["kind"]) == "title" else "frame"
	Meta.sphinx[key] = "" if String(Meta.sphinx.get(key, "")) == id else id
	Meta.save()


static func in_use(id: String) -> bool:
	match String(ITEMS_IT[id]["kind"]):
		"ornament":
			return ornament_on(id)
		"title":
			return String(Meta.sphinx.get("title", "")) == id
		"frame":
			return String(Meta.sphinx.get("frame", "")) == id
	return false
