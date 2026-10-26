class_name Weights
## Il Peso del Cuore: dopo la prima vittoria sul boss della Prima Ora, nella Sala del Giudizio puoi posare
## dei pesi sulla bilancia di Ma'at prima di scendere. Ogni peso rende la discesa più dura
## e aumenta il Ka che porti a casa. È la "sfida su misura" per chi ha già vinto.
##
## Ogni peso ha da 1 a 2 livelli; il Peso totale è la somma dei livelli.
## Bonus di Ka: +10% per ogni livello di peso, applicato quando il Ka viene custodito.

const KA_PER_WEIGHT := 0.10

const ALL_IT := {
	"piombo": {"name": "Piume di piombo", "max": 2, "desc": "I nemici hanno il 20% di vita in più per livello."},
	"zanne": {"name": "Zanne affilate", "max": 2, "desc": "Subisci il 20% di danni in più per livello."},
	"orde": {"name": "Le orde del Duat", "max": 2, "desc": "Ogni ondata ha il 25% di nemici in più per livello."},
	"elite": {"name": "Il sangue dei campioni", "max": 1, "desc": "I nemici élite compaiono il doppio delle volte, e già dalla seconda stanza."},
	"sabbie": {"name": "Sabbie traditrici", "max": 1, "desc": "Le trappole compaiono dalla prima stanza, e ce ne sono di più."},
	"avarizia": {"name": "Il Nilo in secca", "max": 1, "desc": "L'Acqua del Nilo cura la metà."},
	"silenzio": {"name": "Il silenzio degli dèi", "max": 1, "desc": "Gli dèi ti offrono solo due doni invece di tre."},
	"fame": {"name": "La fame di Am-heh", "max": 1, "desc": "Am-heh ha il 30% di vita in più e la marea di fuoco arriva più spesso."},
	"ira_serpente": {"name": "L'ira del Serpente", "max": 1, "desc": "Il Serpente della Porta ha due mosse in più: la doppia emersione e la pioggia di veleno."},
	"ira_amheh": {"name": "L'ira di Am-heh", "max": 1, "desc": "Am-heh ha due mosse in più: il doppio balzo e l'anello di fuoco."},
	"ira_aker": {"name": "L'ira di Aker", "max": 1, "desc": "Ieri e Domani non muoiono da soli: se non finisci il secondo leone entro 8 secondi, il primo rinasce."},
}


static func unlocked() -> bool:
	return Meta.ammit_wins > 0


static func rank(id: String) -> int:
	if not unlocked() or Meta.feather:
		return 0
	return int(Meta.weights.get(id, 0))


static func total() -> int:
	var n := 0
	for id in ALL:
		n += rank(id)
	return n


static func ka_mult() -> float:
	return 1.0 + KA_PER_WEIGHT * total()


## Passa al livello successivo (e da quello massimo torna a 0).
static func cycle(id: String) -> void:
	var r := (rank(id) + 1) % (int(ALL[id]["max"]) + 1)
	Meta.weights[id] = r
	Meta.save()


## I testi qui sopra sono in italiano (le costanti *_IT); il gioco legge le copie tradotte
## nella lingua scelta, rifatte da Lang.refresh_data() quando cambia la lingua.
static var ALL: Dictionary = Lang.deep(ALL_IT)


static func refresh_lang() -> void:
	ALL = Lang.deep(ALL_IT)
