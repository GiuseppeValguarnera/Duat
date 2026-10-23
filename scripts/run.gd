extends Node
## Stato della discesa in corso: vita, doni ottenuti, stanza attuale.
## Il Ka non si azzera tra una run e l'altra: è la valuta permanente.

const ROOMS_PER_RUN := 3

var max_hp := 60.0
var hp := 60.0
var ka := 0
var room := 0
var boons: Array[String] = []


func new_run() -> void:
	max_hp = 60.0
	hp = max_hp
	room = 0
	boons.clear()


func has(id: String) -> bool:
	return boons.has(id)


func add_boon(id: String) -> void:
	if not boons.has(id):
		boons.append(id)


# --- effetti dei doni letti dal giocatore e dai nemici -------------------------

func khopesh_mult() -> float:
	return 1.35 if has("sekhmet_fury") else 1.0


func eye_cooldown_mult() -> float:
	return 0.6 if has("thoth_calc") else 1.0


## Quanti nemici in più l'Occhio di Horus può attraversare. Senza doni: nessuno.
func eye_pierce() -> int:
	return 2 if has("thoth_pierce") else 0
