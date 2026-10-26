class_name Challenges
extends RefCounted
## La parete di Thoth nella Casa della Vita: le sfide. Si compiono giocando, ma contano solo da
## quando la Casa è aperta (prima comparivano premi da riscuotere in un posto ancora murato), e il
## premio si riscuote davanti alla parete.
## Alcune danno la ricetta di un amuleto (amulets.gd), le altre Ka custodito, lapislazzuli o
## Lacrime di Iside. La seconda parete si svela dopo SECOND_WALL sfide compiute.
##
## Meta.challenges: id -> 1 compiuta, 2 premio riscosso. Meta.stats: i contatori che durano.

const SECOND_WALL := 7

## `goal`: il numero da raggiungere (per la barra), `stat`: il contatore in Meta.stats (se c'è).
## `reward`: ["amulet", id] / ["ka", n] / ["lapis", n] / ["tears", n].
const ALL_IT := {
	"serpente": {"name": "La Porta", "desc": "Batti il Serpente della Porta.", "goal": 1, "reward": ["amulet", "iside"]},
	"pulito": {"name": "Senza un graffio", "desc": "Finisci 3 stanze di fila senza essere colpito.", "goal": 3, "reward": ["amulet", "was"]},
	"fermo": {"name": "Piedi piantati", "desc": "Finisci 3 stanze di fila senza scattare.", "goal": 3, "reward": ["amulet", "djed"]},
	"devoto": {"name": "Il devoto", "desc": "Prendi 3 doni dallo stesso dio in una discesa.", "goal": 3, "reward": ["amulet", "shen"]},
	"cliente": {"name": "Un buon cliente", "desc": "Spendi 120 Ka dal Traghettatore in una discesa.", "goal": 120, "reward": ["amulet", "hathor"]},
	"cercatore": {"name": "Il cercatore", "desc": "Trova 3 stanze segrete.", "goal": 3, "stat": "serdab", "reward": ["amulet", "udjat"]},
	"stretto": {"name": "Per un soffio", "desc": "Batti il Serpente della Porta con meno di un quarto della vita.", "goal": 1, "reward": ["amulet", "ankh"]},
	"amheh": {"name": "Il Divoratore", "desc": "Batti Am-heh.", "goal": 1, "reward": ["amulet", "kheper"]},
	"scarabei": {"name": "Sterminatore", "desc": "Abbatti 100 scarabei.", "goal": 100, "stat": "scarabei", "reward": ["ka", 60]},
	"due_armi": {"name": "Due mani", "desc": "Arriva al Serpente della Porta con due armi diverse.", "goal": 2, "stat": "armi_serpente", "reward": ["tears", 1]},
}
static var ALL := {}
## Il migliore risultato della discesa in corso per le sfide "in una discesa" o "di fila".
static var _best := {}


static func refresh_lang() -> void:
	ALL = Lang.deep(ALL_IT)


static func data() -> Dictionary:
	if ALL.is_empty():
		refresh_lang()
	return ALL


static func state(id: String) -> int:
	return int(Meta.challenges.get(id, 0))


static func done_count() -> int:
	var n := 0
	for id in ALL_IT:
		if state(id) > 0:
			n += 1
	return n


static func to_claim() -> int:
	var n := 0
	for id in ALL_IT:
		if state(id) == 1:
			n += 1
	return n


## Quanto manca: [fatto, obiettivo].
static func progress(id: String) -> Vector2i:
	var d: Dictionary = ALL_IT[id]
	var goal := int(d["goal"])
	if state(id) > 0:
		return Vector2i(goal, goal)
	var now := 0
	if d.has("stat"):
		var v = Meta.stats.get(d["stat"], 0)
		now = (v as Array).size() if v is Array else int(v)
	else:
		now = int(Meta.stats.get("best_" + id, 0))
	return Vector2i(mini(now, goal), goal)


static func reward_text(id: String) -> String:
	var r: Array = ALL_IT[id]["reward"]
	match r[0]:
		"amulet":
			return Lang.t("amuleto: %s") % Amulets.data()[r[1]]["name"]
		"ka":
			return Lang.t("%d Ka custodito") % int(r[1])
		"lapis":
			return Lang.t("%d lapislazzuli") % int(r[1])
		_:
			return Lang.t("%d Lacrima di Iside") % int(r[1]) if int(r[1]) == 1 else Lang.t("%d Lacrime di Iside") % int(r[1])


static func claim(id: String) -> bool:
	if state(id) != 1:
		return false
	var r: Array = ALL_IT[id]["reward"]
	match r[0]:
		"amulet":
			if not Meta.amulet_recipes.has(r[1]):
				Meta.amulet_recipes.append(r[1])
		"ka":
			Meta.ka_bank += int(r[1])
		"lapis":
			Meta.lapis += int(r[1])
		"tears":
			Meta.tears += int(r[1])
	Meta.challenges[id] = 2
	Meta.save()
	return true


# ---------------------------------------------------------------- si compiono giocando

static func _complete(id: String) -> void:
	if not Meta.casa or state(id) > 0:
		return
	Meta.challenges[id] = 1
	Meta.save()
	Sfx.play("boon", 0.0)
	var g = Engine.get_main_loop().current_scene if Engine.get_main_loop() is SceneTree else null
	if g != null and g.has_method("_banner"):
		g._banner(Lang.t("Sfida compiuta"), Lang.t("%s · riscuoti il premio alla Casa della Vita") % data()[id]["name"], Color(0.94, 0.72, 0.3), 3.5)


## Per le sfide "di fila" e "in una discesa": ricorda il migliore e la compie se basta.
static func _reach(id: String, n: int) -> void:
	if not Meta.casa:
		return
	if n > int(Meta.stats.get("best_" + id, 0)):
		Meta.stats["best_" + id] = n
	if n >= int(ALL_IT[id]["goal"]):
		_complete(id)


static func _count(stat: String, id: String, add: int = 1) -> void:
	if not Meta.casa:
		return
	Meta.stats[stat] = int(Meta.stats.get(stat, 0)) + add
	if int(Meta.stats[stat]) >= int(ALL_IT[id]["goal"]):
		_complete(id)


static func on_run_start() -> void:
	_best.clear()


## Una stanza della discesa è finita: le sfide "di fila".
static func on_room_done(was_hit: bool, dashed: bool) -> void:
	if Run.training:
		return
	_best["pulito"] = 0 if was_hit else int(_best.get("pulito", 0)) + 1
	_best["fermo"] = 0 if dashed else int(_best.get("fermo", 0)) + 1
	_reach("pulito", _best["pulito"])
	_reach("fermo", _best["fermo"])


static func on_boon(god: String) -> void:
	if Run.training or god in ["", "set", "anubi", "duo"]:
		return
	var n := 0
	for b in Run.boons:
		if Boons.ALL[b].get("god", "") == god:
			n += 1
	_reach("devoto", n)


static func on_ka_spent(total: int) -> void:
	_reach("cliente", total)


static func on_guardian_room() -> void:
	if not Meta.casa:
		return
	var list: Array = Meta.stats.get("armi_serpente", [])
	if not list.has(Run.weapon):
		list.append(Run.weapon)
		Meta.stats["armi_serpente"] = list
		Meta.save()
	if list.size() >= 2:
		_complete("due_armi")


static func on_serpent_beaten(hp_ratio: float) -> void:
	_complete("serpente")
	if hp_ratio < 0.25:
		_complete("stretto")


static func on_amheh_beaten() -> void:
	_complete("amheh")


static func on_serdab() -> void:
	_count("serdab", "cercatore")
	Meta.save()


static func on_kill(scene_path: String) -> void:
	if Run.training:
		return
	if scene_path.ends_with("scarab.tscn"):
		_count("scarabei", "scarabei")
