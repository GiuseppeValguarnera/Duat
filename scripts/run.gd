extends Node
## Stato della discesa in corso: vita, doni, patti di Set, Sekhem.
## Qui c'è anche l'effetto di ogni dono, così è tutto in un posto solo.
## Il Ka non si azzera tra una run e l'altra: è la valuta permanente.

signal blessing_granted(id: String)

const ROOMS_PER_RUN := 10             ## stanze della Prima Ora; poi c'è la stanza del boss
const GUARDIAN_ROOM := 5              ## a metà discesa: il Serpente della Porta
const MIN_DASH_CD := 0.6              ## la pausa dello scatto non scende mai sotto questa, con tutti i doni
const SEKHEM_MAX := 100.0

## Le tappe della notte: 1 = le acque di Wernes (Am-heh), 2 = il deserto di Sokar (Aker). La
## discesa continua da una all'altra, come in Hades. Sokar è in costruzione: si gioca solo con
## DUAT_REGION2=1 (per le prove) finché non è completa.
const SOKAR_READY := false
var region := 1


func max_region() -> int:
	return 2 if SOKAR_READY or OS.get_environment("DUAT_REGION2") != "" else 1


## Il nome della tappa, per l'HUD e i banner.
func region_name() -> String:
	return Lang.t("Wernes") if region == 1 else Lang.t("Sokar")


var max_hp := 60.0
var hp := 60.0
var ka := 0
var room := 0
var boons := {}                       # id -> livello
var blessings: Array[String] = []     # benedizioni di Set ottenute
var curses: Array = []                # [{"curse", "rooms", "blessing"}]
var sekhem := 0.0
var divine := false                   # true durante la Forma Divina
var revived := false                  # Protezione di Bastet già usata in questa run
var blood_kills := 0
var kills := 0                        # statistiche per il riepilogo di fine run
var damage_dealt := 0.0
var start_msec := 0
var mask_used := false                ## Capitolo 151: il primo colpo della stanza è già stato attutito
var heart_used := false               # Capitolo 30 già usato in questa discesa
var in_hub := false                   # true nella Sala del Giudizio
var training := false                 # nel Cortile di Neith: non si muore
var from_armory := false              # si torna nella Sala dalla porta del Cortile
var from_restore := false             # la Sala si è appena rinnovata (restauro): si riappare alla cassa
var from_casa := false                # si torna nella Sala dalla porta della Casa della Vita
var rebirth := ""                     # "death" o "win": nella Sala l'eroe riemerge dal disco solare (rebirth.gd)
var last_hit := ""                    # chi ti ha colpito per ultimo (per i commenti di Anubi)
var resume := {}                      # discesa salvata da riprendere (la imposta la Sala all'avvio)

const DESCENT_PATH := "user://duat_discesa.cfg"   ## salvataggio a metà discesa


## L'arma della discesa e il suo aspetto (scelti nel Cortile di Neith).
var weapon := "khopesh"
var aspect := "faraone"
var aspect_level := 1
# l'amuleto della Casa della Vita (amulets.gd) e ciò che serve alle sfide (challenges.gd)
var amulet := ""
var amulet_level := 1
var room_hit := false                  ## in questa stanza hai perso vita
var room_dashed := false               ## in questa stanza hai scattato
var ka_spent := 0                      ## Ka spesi dal Traghettatore in questa discesa
var was_stacks := 0                    ## Scettro Was: stanze pulite contate
var kheper_left := 0                   ## Scarabeo Kheper: doni che arrivano ancora al livello 2
var decoy_pos := Vector2.ZERO          ## Pilastro Djed: dove sta la statua che attira i nemici
var decoy_t := 0.0
# l'acqua alta dell'arena della Porta (arenas.gd): rallenta, scioglie il veleno, il Serpente ci si tuffa
var deep_center := Vector2.ZERO
var deep_radii := Vector2.ZERO


func in_deep(p: Vector2) -> bool:
	if deep_radii == Vector2.ZERO:
		return false
	return ((p - deep_center) / deep_radii).length() < 1.0


func aspect_val(id: String) -> float:
	if aspect != id:
		return 0.0
	return float(Weapons.ALL[weapon]["aspects"][id]["values"][clampi(aspect_level, 1, Weapons.MAX_LEVEL) - 1])


func new_run() -> void:
	weapon = Meta.weapon if Weapons.is_unlocked(Meta.weapon) else "khopesh"
	aspect = Weapons.chosen_aspect(weapon)
	aspect_level = Weapons.aspect_level(weapon, aspect)
	max_hp = 60.0
	hp = max_hp
	room = 0
	region = 1
	boons.clear()
	blessings.clear()
	curses.clear()
	sekhem = 0.0
	divine = false
	revived = false
	blood_kills = 0
	ka = 0
	kills = 0
	damage_dealt = 0.0
	start_msec = Time.get_ticks_msec()
	heart_used = false
	last_hit = ""
	mask_used = false
	amulet = Meta.amulet if Amulets.owned(Meta.amulet) else ""
	amulet_level = Amulets.level(amulet) if amulet != "" else 1
	if OS.get_environment("DUAT_AMULET") != "":       # per le prove: un amuleto al livello 3
		amulet = OS.get_environment("DUAT_AMULET")
		amulet_level = 3
	room_hit = false
	room_dashed = false
	ka_spent = 0
	was_stacks = 0
	kheper_left = int(Amulets.value("kheper", amulet_level)) if amulet == "kheper" else 0
	decoy_t = 0.0
	deep_radii = Vector2.ZERO
	Challenges.on_run_start()
	if chap("c17"):
		max_hp += Chapters.value("c17")
		hp = max_hp
	ka = int(Chapters.value("c110"))         # Campi di Iaru: Ka per il Traghettatore


# --- salvataggio a metà discesa ---------------------------------------------------
# All'inizio di ogni stanza la discesa viene salvata. Se il gioco si chiude (o il telefono
# chiude la pagina), al prossimo avvio si riparte dall'inizio di quella stanza.
# A fine discesa (morte, vittoria, abbandono) il salvataggio viene cancellato.

func save_descent(reward: Dictionary, extra: Dictionary) -> void:
	var d := {
		"max_hp": max_hp, "hp": hp, "ka": ka, "room": room, "boons": boons.duplicate(),
		"blessings": Array(blessings), "curses": curses.duplicate(true), "sekhem": sekhem,
		"revived": revived, "blood_kills": blood_kills, "kills": kills, "damage_dealt": damage_dealt,
		"elapsed": Time.get_ticks_msec() - start_msec, "heart_used": heart_used, "reward": reward,
		"ka_spent": ka_spent, "was": was_stacks, "kheper": kheper_left, "region": region,
	}
	d.merge(extra)
	var cfg := ConfigFile.new()
	cfg.set_value("discesa", "stato", d)
	cfg.save(DESCENT_PATH)


func has_saved_descent() -> bool:
	return FileAccess.file_exists(DESCENT_PATH)


func load_descent() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(DESCENT_PATH) != OK:
		return {}
	return cfg.get_value("discesa", "stato", {})


func clear_descent() -> void:
	if has_saved_descent():
		DirAccess.remove_absolute(DESCENT_PATH)


func apply_descent(d: Dictionary) -> void:
	max_hp = d.get("max_hp", max_hp)
	hp = d.get("hp", hp)
	ka = d.get("ka", 0)
	room = d.get("room", 1)
	boons = d.get("boons", {}).duplicate()
	blessings.assign(d.get("blessings", []))
	curses = d.get("curses", []).duplicate(true)
	sekhem = d.get("sekhem", 0.0)
	revived = d.get("revived", false)
	blood_kills = d.get("blood_kills", 0)
	kills = d.get("kills", 0)
	damage_dealt = d.get("damage_dealt", 0.0)
	start_msec = Time.get_ticks_msec() - int(d.get("elapsed", 0))
	heart_used = d.get("heart_used", false)
	ka_spent = d.get("ka_spent", 0)
	region = d.get("region", 1)
	was_stacks = d.get("was", 0)
	kheper_left = d.get("kheper", 0)


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
	var god := String(Boons.ALL[id].get("god", ""))
	# Scarabeo Kheper: i primi doni nuovi della discesa arrivano già al livello 2
	if kheper_left > 0 and level(id) == 0 and not (god in ["anubi", "duo", "set"]) and not Boons.is_heavy(id) \
			and Boons.ALL[id].has("values") and (Boons.ALL[id]["values"] as Array).size() >= 2:
		kheper_left -= 1
		boons[id] = 1
	boons[id] = level(id) + 1
	Challenges.on_boon(god)
	if id == "anubi_stone":
		max_hp += val(id)
		hp += val(id)
	if id == "bastet_heavy":
		max_hp = maxf(20.0, max_hp - 15.0)
		hp = minf(hp, max_hp)
	if id == "anubi_canopic":
		max_hp -= 10.0
		hp = minf(hp, max_hp)
	if id == "anubi_tribute":
		max_hp -= 5.0
		hp = minf(hp, max_hp)
	if id == "anubi_light":
		max_hp -= 5.0
		hp = minf(hp, max_hp)


# --- patti di Set -----------------------------------------------------------------

func add_pact(curse: String, blessing: String) -> void:
	curses.append({"curse": curse, "rooms": Boons.SET_CURSES[curse]["rooms"], "blessing": blessing})


## Davanti ai guardiani, ai boss e al Traghettatore Set tace: la maledizione non agisce
## e non conta la stanza. Così il patto non ti lascia maledetto nello scontro più duro.
var curse_paused := false


func cursed(curse: String) -> bool:
	if curse_paused:
		return false
	for c in curses:
		if c["curse"] == curse:
			return true
	return false


## Da chiamare a ogni stanza ripulita: le maledizioni scadono e arrivano le benedizioni.
## Una stanza della discesa è finita (anche quelle senza maledizioni da contare): le sfide "di
## fila", lo Scettro Was e i livelli dell'amuleto al collo.
func room_done() -> void:
	if training:
		return
	Challenges.on_room_done(room_hit, room_dashed)
	if amulet == "was" and not room_hit:
		was_stacks = mini(5, was_stacks + 1)
	if amulet != "":
		Meta.amulet_rooms[amulet] = Amulets.rooms(amulet) + 1
	room_hit = false
	room_dashed = false


func room_cleared() -> void:
	if curse_paused:
		return
	var still := []
	for c in curses:
		c["rooms"] -= 1
		if c["rooms"] <= 0:
			grant_blessing(c["blessing"])
		else:
			still.append(c)
	curses = still


func grant_blessing(id: String) -> void:
	blessings.append(id)
	if id == "set_vigor":
		max_hp += 15.0
		hp += 12.0
	blessing_granted.emit(id)


# --- Sekhem -----------------------------------------------------------------------

## Il Sekhem è il dono di Am-heh: si sblocca per sempre la prima volta che lo sconfiggi.
func sekhem_unlocked() -> bool:
	return Meta.sekhem_unlocked


func add_sekhem(amount: float) -> void:
	if divine or not sekhem_unlocked():
		return
	var m := 1.5 if has("set_sekhem") else 1.0
	m *= 1.0 + val("iside_word") / 100.0
	sekhem = minf(SEKHEM_MAX, sekhem + amount * m)


func sekhem_ready() -> bool:
	return sekhem >= SEKHEM_MAX


# --- effetti ----------------------------------------------------------------------

## Un capitolo del Libro dei Morti è attivo in questa discesa?
func chap(id: String) -> bool:
	return Meta.chapters_equipped.has(id)


func all_damage_mult() -> float:
	var m := 1.25 if has("set_might") else 1.0
	if amulet == "was":
		m *= 1.0 + was_stacks * Amulets.val() / 100.0     # Scettro Was: le stanze pulite
	if has("anubi_stone"):
		m *= 0.95                # Cuore di Pietra: più vita, colpi un po' più deboli
	if chap("c125") and hp > max_hp * 0.8:
		m *= 1.0 + Chapters.value("c125") / 100.0
	return m


func khopesh_mult() -> float:
	var m := 1.0 + val("sekhmet_fury") / 100.0
	if has("sekhmet_heavy"):
		m *= 1.5
	if has("thoth_heavy"):
		m *= 0.65
	if has("sobek_heavy"):
		m *= 1.4
	if has("iside_heavy"):
		m *= 0.75
	if has("horus_heavy"):
		m *= 0.6
	return m * all_damage_mult()


func eye_damage_mult() -> float:
	var m := (1.0 + val("thoth_scribe") / 100.0) * (1.0 + val("ra_eye") / 100.0) * all_damage_mult()
	if has("anubi_mouth"):
		m *= 0.9
	m *= 1.0 + val("horus_seek") / 100.0
	if has("horus_heavy"):
		m *= 2.0
	m *= 1.0 + Chapters.value("c42") / 100.0
	return m


## Il Sole e la Luna (Horus): quante volte di fila si può lanciare l'Occhio.
func eye_charges() -> int:
	return maxi(1, int(val("horus_twin")))


func eye_cooldown_mult() -> float:
	var m := 1.0 - val("thoth_calc") / 100.0
	if has("ra_heavy"):
		m *= 1.5
	if has("thoth_heavy"):
		m *= 0.45
	if has("anubi_mouth"):
		m *= 1.0 - val("anubi_mouth") / 100.0
	if chap("c89"):
		m *= 1.0 - Chapters.value("c89") / 100.0
	return m


## Quanti nemici in più l'Occhio di Horus può attraversare. Senza doni: nessuno.
func eye_pierce() -> int:
	if has("horus_heavy"):
		return 99
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
		m *= 1.12
	if has("sobek_heavy"):
		m *= 0.85
	if has("anubi_linen"):
		m *= 0.95
	return m


func dash_cooldown_mult() -> float:
	var m := 1.0
	if has("anubi_light"):
		m *= 1.0 - val("anubi_light") / 100.0
	m *= 1.0 - val("bastet_step") / 100.0
	if has("ra_dawn"):
		m *= 1.4
	m *= 1.0 - Chapters.value("c56") / 100.0
	return m


func damage_taken_mult() -> float:
	var m := 1.3 if cursed("fragile") else 1.0
	m *= 1.0 + 0.2 * Weights.rank("zanne")
	m *= 1.0 - val("sobek_skin") / 100.0
	m *= low_hp_guard()
	if has("anubi_linen"):
		m *= 1.0 - val("anubi_linen") / 100.0
	m *= 1.0 - feather_guard()
	return m


## Piuma di Ma'at: 10% di danni in meno, +2% a ogni morte, fino al 50%.
func feather_guard() -> float:
	if not Meta.feather:
		return 0.0
	return minf(0.5, 0.1 + 0.02 * Meta.feather_deaths)


## Vita dei nemici: +6% per ogni stanza dopo la prima, più l'eventuale prezzo di Anubi.
func enemy_hp_mult() -> float:
	var m := 1.0 + 0.06 * maxi(0, mini(room, ROOMS_PER_RUN) - 1)
	if has("anubi_guide"):
		m *= 1.05
	if cursed("tough"):
		m *= 1.25
	m *= 1.0 + 0.2 * Weights.rank("piombo")
	return m


## Ira del Deserto: il khopesh attacca più rapidamente.
func attack_speed_mult() -> float:
	return 0.8 if has("set_rage") else 1.0


## Fiuto dello Sciacallo: più danni ai nemici feriti, meno a quelli in salute.
func jackal_mult(hp_ratio: float) -> float:
	if not has("anubi_jackal"):
		return 1.0
	return 1.0 + val("anubi_jackal") / 100.0 if hp_ratio < 0.5 else 0.9


func enemy_speed_mult() -> float:
	return 1.2 if cursed("fast_enemies") else 1.0


## Moltiplicatore dei tesori di Ka (porte "Tesoro di Ka").
func treasure_mult() -> float:
	return ka_mult() * (1.0 + Chapters.value("c99") / 100.0)


## Quanto cura l'Acqua del Nilo, in frazione della vita massima.
func nile_heal() -> float:
	var h := Chapters.value("c154") / 100.0 if chap("c154") else 0.3
	if Weights.rank("avarizia") > 0:
		h *= 0.5
	return h


func ka_mult() -> float:
	var m := 1.5 if has("set_greed") else 1.0
	m *= 1.0 + val("anubi_tribute") / 100.0
	if has("anubi_scale"):
		m *= 0.85                # Bilancia Giusta: il prezzo è nel Ka, non nella difesa
	return m


## Custode della Necropoli: il terzo colpo della combo pesa di più, i primi due di meno.
func combo_mult(index: int) -> float:
	if not has("anubi_guardian"):
		return 1.0
	return 1.0 + val("anubi_guardian") / 100.0 if index == 2 else 0.9


# --- Bastet, Sobek, Iside ---------------------------------------------------------

## Moltiplicatore del colpo: 1 se normale, 2 (o 3) se critico.
func roll_crit(chance: float) -> float:
	if has("bastet_heavy"):
		chance = maxf(chance, 0.1)
	if chance > 0.0 and randf() < chance:
		return 3.0 if has("bastet_heavy") else 2.0
	return 1.0


func khopesh_crit_chance() -> float:
	return val("bastet_claws") / 100.0


func eye_crit_chance() -> float:
	return val("bastet_eyes") / 100.0


## Nodo di Iside (l'amuleto tyet): protegge quando sei sotto un terzo della vita.
func low_hp_guard() -> float:
	if has("iside_knot") and hp < max_hp / 3.0:
		return 1.0 - val("iside_knot") / 100.0
	return 1.0


func heal_mult() -> float:
	var m := 1.0 + val("iside_tears") / 100.0
	if cursed("thirst"):
		m *= 0.6
	return m


func knock_mult() -> float:
	return 2.0 if has("sobek_heavy") else 1.0

