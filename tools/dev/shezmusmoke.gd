extends SceneTree
## Blocco 22: Shezmu. Il giocatore non muore (vita piena a ogni fotogramma) e sta fermo; si forza la vita del guardiano per vedere
## tutte le parti nuove: piastre, dannati all'80% e al 45%, proiettili da lontano, spremitura e furia
## breve, tre mosse legate e respiro sotto il 35%, morte (i dannati si sciolgono, le piastre spariscono).
var frames := 0
var g = null
var boss = null
var seen := {}
var step := 0
var mark := 0
var found := false

func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")

func _process(_d: float) -> bool:
	frames += 1
	paused = false
	g = current_scene
	if g == null or not g.has_method("start_room"):
		return false
	if g.menu != null:
		g._close_choice()
	if g.player != null and is_instance_valid(g.player):
		g.player.hp = g.player.max_hp
	if frames == 30:
		var run = root.get_node("Run")
		run.region = 3
		run.room = run.GUARDIAN_ROOM
		g.start_room({"kind": "guardian"})
	if frames < 60:
		return false
	if not found:
		for e in g.get_tree().get_nodes_in_group("enemies"):
			if e.miniboss:
				boss = e
				found = true
		if frames > 1200:
			print("shezmu: NON comparso")
			return true
		if not found:
			return false
	if not is_instance_valid(boss) or boss.dead:
		print("shezmu stati visti: ", seen.keys())
		print("shezmu: caduto; dannati rimasti=", g.get_tree().get_nodes_in_group("grapes").filter(func(n): return not n.dead).size(), " piastre=", g.get_tree().get_nodes_in_group("ground_hazards").filter(func(n): return n.has_method("danger") and not n.is_queued_for_deletion()).size())
		return true
	seen[boss.state] = true
	if boss.shot_kind != "":
		seen["tiro:" + boss.shot_kind] = true
	if not boss.vases.is_empty():
		seen["vaso"] = true
	if boss.plates != null and boss.plates.phase != "":
		seen["piastra:" + boss.plates.phase] = true
	match step:
		0:
			if boss.state == "chase" and frames > 500:
				boss.hp = boss.max_hp * 0.79
				step = 1
				mark = frames
		1:
			if boss.squeezes >= 1 and boss.fury_t > 0.0:
				print("shezmu: spremitura 1, vita %.0f%%, furia %.1f s" % [100.0 * boss.hp / boss.max_hp, boss.fury_t])
				for gr in g.get_tree().get_nodes_in_group("grapes"):
					gr.die()
				step = 2
				mark = frames
			elif frames - mark > 1500:
				print("shezmu: nessuna spremitura")
				return true
		2:
			if boss.state == "chase" and frames - mark > 480:
				boss.hp = boss.max_hp * 0.3
				step = 3
				mark = frames
		3:
			# seconda chiamata (45%): si lasciano spremere tutti, fino al tetto di 3
			if frames - mark > 1500:
				print("shezmu: spremiture=%d (tetto %d), dannati vivi=%d" % [boss.squeezes, boss.SQUEEZE_MAX, boss._grapes().size()])
				for gr in g.get_tree().get_nodes_in_group("grapes"):
					gr.die()
				boss.hp = boss.max_hp * 0.2
				step = 4
				mark = frames
		4:
			if seen.has("breath") or frames - mark > 1500:
				print("shezmu: respiro visto=", seen.has("breath"))
				boss.take_hit(99999.0, Vector2.RIGHT, 0.0)
				step = 5
				mark = frames
		5:
			if frames - mark > 200:
				print("shezmu: non è caduto")
				return true
	return false
