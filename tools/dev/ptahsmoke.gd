extends SceneTree
## Blocco 26: le incisioni di Ptah. Senza grafica: il menu dell'incudine (scelta e posto), poi per
## sette combinazioni che coprono tutte e 12 le leghe, con armi diverse, tre mummie vicine: colpi,
## uno scatto attraverso, l'Arte. Controlla che gli effetti scattino (dardi, pozze, scia, veleno, fuoco).
var frames := 0
var g = null
var sets := [
	["sole", "occhio", "falco"], ["acqua", "serpente", "scarabeo"], ["leone", "acqua", "loto"],
	["falco", "leone", "sole"], ["occhio", "serpente", "scarabeo"], ["scarabeo", "sole", "loto"],
	["falco", "loto", "acqua"],
]
var weapons := ["arco", "khopesh", "flagello", "lancia", "artigli", "scettro", "khopesh"]
var si := -1
var step := 0
var mark := 0
var foes: Array = []
var hp0 := 0.0
var seen := {}

func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")

func _process(_d: float) -> bool:
	frames += 1
	paused = false
	g = current_scene
	if g == null or not g.has_method("start_room"):
		return false
	var run = root.get_node("Run")
	if g.player != null and is_instance_valid(g.player):
		g.player.hp = g.player.max_hp
	match step:
		0:
			if frames >= 30:
				if g.menu != null:
					g._close_choice()
				g.waves = []
				g.room_gen += 1
				for e in get_nodes_in_group("enemies"):
					e.queue_free()
				# il menu dell'incudine
				g._show_ptah_menu()
				if g.menu == null:
					push_error("PTAH: il menu dell'incudine non si apre")
				g._ptah_slot_menu("leone")
				g._do_engrave("leone", 1)
				if run.incisions[1] != "leone":
					push_error("PTAH: incisione non registrata")
				if g.menu != null:
					g._close_choice()
				step = 1
				mark = frames
		1:
			if frames - mark == 5:
				si += 1
				if si >= sets.size():
					print("PTAH OK")
					quit()
					return true
				run.set_incisions(sets[si])
				run.inc_pool_hits = 0
				run.inc_hits = 0
				run.weapon = weapons[si]
				run.boons = {}
				seen = {"darts": 0, "pools": 0, "trail": 0, "psn": 0, "burn": 0, "big": 0}
				for e in get_nodes_in_group("enemies"):
					e.queue_free()
				for grp in ["inc_pools", "inc_darts", "inc_trails"]:
					for n in get_nodes_in_group(grp):
						n.queue_free()
				var p = g.player
				p.art_cd = 0.0
				p.aim = Vector2.RIGHT
				p.facing = Vector2.RIGHT
				var c: Vector2 = p.global_position
				foes = []
				var far: bool = run.weapon == "arco" or run.weapon == "lancia"
				var spots := [Vector2(30, 0), Vector2(34, 16), Vector2(28, -16)]
				if run.weapon == "flagello":
					spots = [Vector2(52, 0), Vector2(60, 6), Vector2(56, -6)]
				if far:
					spots = [Vector2(80, 0), Vector2(95, 12), Vector2(90, -12)] if run.weapon == "arco" else [Vector2(40, 0), Vector2(46, 12), Vector2(44, -12)]
				var ang: float = (p._bow_aim() if run.weapon == "arco" else Vector2.RIGHT).angle()
				for s in spots:
					var e = g.ENEMIES["mummy"].instantiate()
					e.position = c + s.rotated(ang)
					g.world.add_child(e)
					e.max_hp = 9999.0
					e.hp = 9999.0
					e.speed = 0.0
					foes.append(e)
			if frames - mark == 9 and run.weapon == "arco":
				# la mira la decide il mouse (fermo in un angolo): i bersagli si mettono lungo la mira vera
				var a2: float = g.player._bow_aim().angle()
				var offs := [Vector2(80, 0), Vector2(95, 12), Vector2(90, -12)]
				for i in range(foes.size()):
					foes[i].global_position = g.player.global_position + offs[i].rotated(a2)
			if frames - mark > 10 and frames - mark < 110 and (frames - mark) % 10 == 0:
				var p = g.player
				p.atk_cd = 0.0
				p.combo_window = 1.0
				p._swing()
			if frames - mark == 112:
				g.player._start_dash(Vector2.RIGHT.rotated((foes[0].global_position - g.player.global_position).angle()))
			if frames - mark == 140:
				g.player.art_cd = 0.0
				g.player.try_art()
			if frames - mark > 10:
				seen["darts"] = maxi(seen["darts"], get_nodes_in_group("inc_darts").size())
				seen["pools"] = maxi(seen["pools"], get_nodes_in_group("inc_pools").size())
				seen["trail"] = maxi(seen["trail"], get_nodes_in_group("inc_trails").size())
				seen["psn"] = maxi(seen["psn"], get_nodes_in_group("inc_poisoned").size())
				for pl in get_nodes_in_group("inc_pools"):
					if pl.r > 30.0:
						seen["big"] = 1
				for e in foes:
					if is_instance_valid(e) and e.burn_t > 0.0:
						seen["burn"] = 1
			if frames - mark == 200:
				var dealt := 0.0
				for e in foes:
					if is_instance_valid(e):
						dealt += 9999.0 - e.hp
				var inc: Array = sets[si]
				print("PTAH %s %s leghe %s danni %.0f %s" % [weapons[si], ",".join(inc), ",".join(run.alloys), dealt, str(seen)])
				if dealt <= 0.0:
					push_error("PTAH: nessun danno con %s" % weapons[si])
				if inc.has("occhio") and seen["darts"] == 0:
					push_error("PTAH: nessun dardo dell'Occhio")
				if inc.has("serpente") and seen["psn"] == 0:
					push_error("PTAH: nessun veleno")
				if inc.has("scarabeo") and seen["trail"] == 0:
					push_error("PTAH: nessuna scia dello scarabeo")
				if inc.has("leone") and run.alloys.has("acqua+leone") and seen["big"] == 0:
					push_error("PTAH: nessuna pozza grande della Piena")
				if inc.has("acqua") and seen["pools"] == 0:
					push_error("PTAH: nessuna pozza")
				mark = frames
	return false
