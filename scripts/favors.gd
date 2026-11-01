class_name Favors
extends RefCounted
## Le grazie degli dèi: acquisti con i lapislazzuli che NON danno potenza (quella è del Libro dei
## Morti), ma più scelta durante la discesa. La Voce degli Dèi, la Seconda Barca e il Sigillo di
## Thoth si comprano alla cassa dello scalpellino, in una sezione separata dai restauri; la Collana
## a due sigilli al banco dell'orafo, nella Casa della Vita. Ogni acquisto ha la battuta di chi lo
## consegna (`speaker` e `lines`): Anubi, Thoth dai Papiri, Imhotep.

const ALL_IT := {
	"voce": {"name": "Voce degli Dèi", "cost": 15, "speaker": "anubi",
		"desc": "Una volta per discesa puoi chiedere a un dio altre tre scelte per il suo dono.",
		"lore": "Gli Egizi parlavano agli dèi attraverso le statue dei templi: il sacerdote poneva la domanda, e il dio rispondeva muovendo la barca sacra in avanti o indietro.",
		"lines": ["Ora la tua voce arriva fino agli dèi, Scriba. Non tutti amano essere interrogati due volte: chiedi con rispetto, e chiedi una volta sola."]},
	"voce2": {"name": "Voce degli Dèi · seconda eco", "cost": 30, "speaker": "anubi", "needs": "voce",
		"desc": "La Voce degli Dèi si può usare due volte per discesa.",
		"lore": "Nelle grandi feste di Tebe la statua di Amon usciva dal tempio e rispondeva a chiunque le parlasse lungo la strada: la sua voce arrivava due volte, all'andata e al ritorno.",
		"lines": ["La tua voce ha trovato un'eco. Gli dèi ti ascolteranno due volte. Ricorda però che anche il silenzio è una risposta."]},
	"barca": {"name": "La Seconda Barca", "cost": 25, "speaker": "anubi",
		"desc": "Nell'Oasi della quarta ora una seconda barca ti aspetta sull'acqua: puoi scambiare un dono già preso con un altro dello stesso dio, allo stesso livello.",
		"lore": "Ra attraversava il cielo su due barche: la Mandjet del giorno e la Mesektet della notte. Al tramonto passava dall'una all'altra, e il carico restava lo stesso.",
		"lines": ["Ra cambia barca al tramonto, Scriba, e nessuno lo chiama incostante. Nell'Oasi troverai la tua seconda barca: lascia sulla riva un dono, e un altro dello stesso dio salirà con te."]},
	"sigillo": {"name": "Il Sigillo di Thoth", "cost": 22, "speaker": "thoth",
		"desc": "I doni rari e i doni doppi compaiono più spesso.",
		"lore": "Thoth teneva il registro degli dèi e conosceva le parole che legano. Gli scribi gli dedicavano una goccia d'inchiostro prima di ogni lavoro.",
		"lines": ["Ho posato il mio sigillo sul tuo nome. Ora i patti tra gli dèi ti trovano più facilmente, e le cose rare ti vengono incontro. Non sprecarle: le ho contate."]},
	"collana": {"name": "La Collana a due sigilli", "cost": 40, "speaker": "imhotep",
		"desc": "Porti due amuleti al collo invece di uno.",
		"lore": "Le mummie dei re erano coperte di amuleti, a decine, tra una benda e l'altra: ognuno con il suo capitolo del Libro dei Morti e il suo posto sul corpo.",
		"lines": ["Due sigilli d'oro sulla stessa catena. Ai miei tempi solo il faraone ne portava più d'uno, e lo pesavano ogni mattina perché non si stancasse.", "Ma tu non sei un faraone, giovane scriba. O forse sì. Portali bene: un amuleto è un pensiero, e due pensieri insieme sono già un dialogo."]},
}
## Quelle della cassa dello scalpellino, in ordine (la collana è dell'orafo).
const SHOP := ["voce", "voce2", "barca", "sigillo"]
static var ALL := {}


static func refresh_lang() -> void:
	ALL = Lang.deep(ALL_IT)


static func data() -> Dictionary:
	if ALL.is_empty():
		refresh_lang()
	return ALL


static func has(id: String) -> bool:
	return Meta.favors.has(id)


## Si vede nell'elenco: la seconda eco solo dopo la prima Voce.
static func visible(id: String) -> bool:
	var need: String = ALL_IT[id].get("needs", "")
	return need == "" or has(need)


static func can_buy(id: String) -> bool:
	return not has(id) and visible(id) and Meta.lapis >= int(ALL_IT[id]["cost"])


static func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	Meta.lapis -= int(ALL_IT[id]["cost"])
	Meta.favors.append(id)
	Meta.save()
	return true


## C'è una grazia della cassa che puoi già pagare? (il punto esclamativo sulla cassa)
static func something_affordable() -> bool:
	for id in SHOP:
		if can_buy(id):
			return true
	return false


## Quante volte per discesa si può usare la Voce degli Dèi.
static func voices() -> int:
	return 2 if has("voce2") else (1 if has("voce") else 0)


static func speaker_name(id: String) -> String:
	match String(ALL_IT[id]["speaker"]):
		"thoth":
			return Lang.t("Thoth")
		"imhotep":
			return "Imhotep"
	return Lang.t("Anubi")
