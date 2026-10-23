extends Node
## Stato della discesa in corso: vita, doni, patti di Set, Sekhem.
## Qui c'è anche l'effetto di ogni dono, così è tutto in un posto solo.
## Il Ka non si azzera tra una run e l'altra: è la valuta permanente.

signal blessing_granted(id: String)

const ROOMS_PER_RUN := 3
const SEKHEM_MAX := 100.0

var max_hp := 60.0
var hp := 60.0
var ka := 0
var room := 0
var boons := {}                       # id -> livello
var blessings: Array[String] = []     # benedizioni di Set ottenute
var curses: Array = []                # [{"curse", "waves", "blessing"}]
var sekhem := 0.0
var divine := false                   # true durante la Forma Divina


func new_run() -> void:
	max_hp = 60.0
	hp = max_hp
	room = 0
	boons.clear()
	blessings.clear()
	curses.clear()
	sekhem = 0.0
	divine = false


func level(id: String) -> int:
	return boons.get(id, 0)


func has(id: String) -> bool:
	return boons.has(id) or blessings.has(id)


## Il numero del dono al livello attuale (0 se non lo hai).
func val(id: String) -> float:
	var l := level(id)
	if l == 0 or Boons.is_heavy(id):
		return 0.0
	return float(Boons.ALL[id]["values"][l - 1])


func add_boon(id: String) -> void:
	boons[id] = level(id) + 1
	if id == "anubi_stone":
		max_hp += val(id)
		hp += val(id)
	if id == "anubi_light":
		max_hp -= 10.0
		hp = minf(hp, max_hp)


# --- patti di Set -----------------------------------------------------------------

func add_pact(curse: String, blessing: String) -> void:
	curses.append({"curse": curse, "waves": Boons.SET_CURSES[curse]["waves"], "blessing": blessing})


func cursed(curse: String) -> bool:
	for c in curses:
		if c["curse"] == curse:
			return true
	return false


## Da chiamare a ogni ondata ripulita: le maledizioni scadono e arrivano le benedizioni.
func wave_cleared() -> void:
	var still := []
	for c in curses:
		c["waves"] -= 1
		if c["waves"] <= 0:
			grant_blessing(c["blessing"])
		else:
			still.append(c)
	curses = still


func grant_blessing(id: String) -> void:
	blessings.append(id)
	if id == "set_vigor":
		max_hp += 20.0
		hp += 20.0
	blessing_granted.emit(id)


# --- Sekhem -----------------------------------------------------------------------

func add_sekhem(amount: float) -> void:
	if divine:
		return
	sekhem = minf(SEKHEM_MAX, sekhem + amount * (1.5 if has("set_sekhem") else 1.0))


func sekhem_ready() -> bool:
	return sekhem >= SEKHEM_MAX


# --- effetti ----------------------------------------------------------------------

func all_damage_mult() -> float:
	return 1.25 if has("set_might") else 1.0


func khopesh_mult() -> float:
	var m := 1.0 + val("sekhmet_fury") / 100.0
	if has("sekhmet_heavy"):
		m *= 1.6
	if has("thoth_heavy"):
		m *= 0.65
	return m * all_damage_mult()


func eye_damage_mult() -> float:
	return (1.0 + val("thoth_scribe") / 100.0) * (1.0 + val("ra_eye") / 100.0) * all_damage_mult()


func eye_cooldown_mult() -> float:
	var m := 1.0 - val("thoth_calc") / 100.0
	if has("ra_heavy"):
		m *= 1.5
	if has("thoth_heavy"):
		m *= 0.45
	return m


## Quanti nemici in più l'Occhio di Horus può attraversare. Senza doni: nessuno.
func eye_pierce() -> int:
	return int(val("thoth_pierce"))


func eye_rays() -> int:
	return maxi(1, int(val("thoth_tri")))


func khopesh_burns() -> bool:
	return has("ra_burn") or has("ra_heavy")


func eye_burns() -> bool:
	return has("ra_eye") or has("ra_heavy")


func burn_tick_damage() -> float:
	var b := val("ra_burn") if has("ra_burn") else 5.0
	return b * (1.6 if has("ra_heavy") else 1.0)


func move_mult() -> float:
	var m := 1.15 if has("set_swift") else 1.0
	if has("anubi_light"):
		m *= 1.15
	if has("anubi_stone"):
		m *= 0.92
	return m


func dash_cooldown_mult() -> float:
	var m := 2.0 if cursed("slow_dash") else 1.0
	if has("anubi_light"):
		m *= 1.0 - val("anubi_light") / 100.0
	return m


func damage_taken_mult() -> float:
	var m := 1.5 if cursed("fragile") else 1.0
	if has("anubi_scale"):
		m *= 1.1
	return m


func enemy_hp_mult() -> float:
	return 1.05 if has("anubi_guide") else 1.0


## Fiuto dello Sciacallo: più danni ai nemici feriti, meno a quelli in salute.
func jackal_mult(hp_ratio: float) -> float:
	if not has("anubi_jackal"):
		return 1.0
	return 1.0 + val("anubi_jackal") / 100.0 if hp_ratio < 0.5 else 0.9


func enemy_speed_mult() -> float:
	return 1.3 if cursed("fast_enemies") else 1.0


func ka_mult() -> float:
	return 1.5 if has("set_greed") else 1.0
