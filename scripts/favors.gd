class_name Favors
extends RefCounted
## Le grazie degli dèi: acquisti con i lapislazzuli che NON danno potenza (quella è del Libro dei
## Morti), ma più scelta durante la discesa. La Voce degli Dèi, la Seconda Barca e il Sigillo di
## Thoth si comprano alla cassa dello scalpellino, in una sezione separata dai restauri; la Collana
## a due amuleti al banco dell'orafo, nella Casa della Vita. Ogni acquisto ha la battuta di chi lo
## consegna (`speaker` e `lines`): Anubi, Thoth dai Papiri, Imhotep.

const ALL_IT := {
	"voce": {"name": "Voce degli Dèi", "cost": 15, "speaker": "anubi", "sub": "cambia le scelte",
		"desc": "Quando un dio ti offre tre doni, puoi premere 'Altre scelte' per vederne altri tre al loro posto. Una volta per discesa.",
		"lore": "Gli Egizi parlavano agli dèi attraverso le statue dei templi: il sacerdote poneva la domanda, e il dio rispondeva muovendo la barca sacra in avanti o indietro.",
		"lines": ["Ora la tua voce arriva fino agli dèi, Scriba. Non tutti amano essere interrogati due volte: chiedi con rispetto, e chiedi una volta sola."]},
	"voce2": {"name": "Voce degli Dèi · seconda eco", "cost": 30, "speaker": "anubi", "needs": "voce",
		"desc": "Puoi cambiare le scelte due volte per discesa invece di una.",
		"lore": "Nelle grandi feste di Tebe la statua di Amon usciva dal tempio e rispondeva a chiunque le parlasse lungo la strada: la sua voce arrivava due volte, all'andata e al ritorno.",
		"lines": ["La tua voce ha trovato un'eco. Gli dèi ti ascolteranno due volte. Ricorda però che anche il silenzio è una risposta."]},
	"barca": {"name": "La Seconda Barca", "cost": 25, "speaker": "anubi",
		"desc": "Nell'Oasi puoi scambiare un dono che hai già con un altro dello stesso dio, allo stesso livello. Una volta per discesa.",
		"lore": "Ra attraversava il cielo su due barche: la Mandjet del giorno e la Mesektet della notte. Al tramonto passava dall'una all'altra, e il carico restava lo stesso.",
		"lines": ["Ra cambia barca al tramonto, Scriba, e nessuno lo chiama incostante. Nell'Oasi troverai la tua seconda barca: lascia sulla riva un dono, e un altro dello stesso dio salirà con te."]},
	"sigillo": {"name": "Il Sigillo di Thoth", "cost": 22, "speaker": "thoth",
		"desc": "I doni rari e i doppi doni compaiono più spesso nelle scelte degli dèi.",
		"lore": "Thoth teneva il registro degli dèi e conosceva le parole che legano. Gli scribi gli dedicavano una goccia d'inchiostro prima di ogni lavoro.",
		"lines": ["Ho posato il mio sigillo sul tuo nome. Ora i patti tra gli dèi ti trovano più facilmente, e le cose rare ti vengono incontro. Non sprecarle: le ho contate."]},
	"collana": {"name": "La Collana a due amuleti", "cost": 40, "speaker": "imhotep",
		"desc": "Puoi equipaggiare due amuleti insieme invece di uno. Il secondo si sceglie al banco dell'orafo.",
		"lore": "Le mummie dei re erano coperte di amuleti, a decine, tra una benda e l'altra: ognuno con il suo capitolo del Libro dei Morti e il suo posto sul corpo.",
		"lines": ["Due sigilli d'oro sulla stessa catena. Ai miei tempi solo il faraone ne portava più d'uno, e lo pesavano ogni mattina perché non si stancasse.", "Ma tu non sei un faraone, giovane scriba. O forse sì. Portali bene: un amuleto è un pensiero, e due pensieri insieme sono già un dialogo."]},
	# blocco 17: si compra con i sigilli nel Tesoro della Sfinge; qui compare per spiegare cosa fa
	"favore_sfinge": {"name": "Il Favore della Sfinge", "cost": 450, "seals": true, "speaker": "sfinge", "sub": "doni della Sfinge nelle discese",
		"desc": "Nelle discese normali, a volte uno dei doni della Sfinge prende l'ultimo posto tra le scelte degli dèi (circa una scelta su otto). Non è mai garantito, ne puoi prendere al massimo uno per discesa e non compare insieme a un dono doppio, pesante o raro. Si ottiene nel Tesoro della Sfinge, con i sigilli.",
		"lore": "I re d'Egitto si facevano ritrarre come sfingi: corpo di leone, volto umano. Davanti alla Grande Sfinge di Giza Thutmose IV sognò che il dio gli prometteva il trono, se l'avesse liberata dalla sabbia.",
		"lines": ["Sei tornato con abbastanza sigilli da annoiarmi. Prendi il mio favore: ogni tanto, laggiù, ti offrirò un dono anch'io. Non sempre. Mi piace farmi desiderare."]},
}
## Quelle della cassa dello scalpellino, in ordine (la collana è dell'orafo; il Favore della Sfinge si vede
## qui ma si compra nel Tesoro della Sfinge, con i sigilli).
const SHOP := ["voce", "voce2", "barca", "sigillo", "favore_sfinge"]
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
	if ALL_IT[id].get("seals", false):
		return false                          # si compra solo nel Tesoro della Sfinge
	return not has(id) and visible(id) and Meta.lapis >= int(ALL_IT[id]["cost"])


## Il Favore della Sfinge comprato nel Tesoro (con i sigilli, non con i lapislazzuli).
static func grant(id: String) -> void:
	if not Meta.favors.has(id):
		Meta.favors.append(id)
		Meta.save()


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
