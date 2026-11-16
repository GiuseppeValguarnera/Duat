extends SceneTree
## Blocco 21: il Banco di Apopi. Senza grafica: i quattro tipi di stanza, il fascio di Ra, le scaglie
## (10% chiuse, 100% nel fascio e per 3 s dopo), il palo che lega, il Divoratore che inghiotte il fascio
## (e il suo dorso), il velo che tiene chiuse le scaglie, nessuna comparsa dentro un pericolo a terra.
var frames := 0
var g = null
var step := 0
var mark := 0
var types := ["barca", "pozze", "pali", "torchio"]
var ti := 0
var sh = null
var eater = null

func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")

func _spawn(kind: String, at: Vector2):
	var e = g.ENEMIES[kind].instantiate()
	e.position = at
	g.world.add_child(e)
	return e

func _dmg(e, dir: Vector2 = Vector2.RIGHT) -> float:
	var before: float = e.hp
	e.take_hit(10.0, dir, 0.0)
	return before - e.hp

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
	var run = root.get_node("Run")
	match step:
		0:
			if frames >= 30:
				run.region = 3
				run.room = 3
				run.apep_order = types.duplicate()
				OS.set_environment("DUAT_APEP_ROOM", types[ti])
				g.start_room({"kind": "none"})
				step = 1
				mark = frames
		1:
			if frames - mark == 240:
				var beams := get_nodes_in_group("ra_beam").size()
				var en := get_nodes_in_group("enemies")
				var bad := 0
				for i in range(200):
					if g.rooms.in_ground_hazard(g._free_spot()):
						bad += 1
				print("stanza %s: fascio=%d nemici=%d con scaglie=%d punti di comparsa dentro un pericolo (su 200)=%d pali=%d colonne=%d grande=%s" % [run.apep_type, beams, en.size(), en.filter(func(e): return e.scales).size(), bad, get_nodes_in_group("ra_stakes").size(), g.pillars.size(), g.ROOM.size.x > 700.0])
				ti += 1
				if ti < types.size():
					step = 0
					frames = 29
				else:
					step = 2
					mark = frames
		2:
			# stanza dei pali (l'ultima era il torchio: si rifà quella dei pali) senza nemici
			OS.set_environment("DUAT_APEP_ROOM", "pali")
			run.room = 3
			g.start_room({"kind": "none"})
			step = 3
			mark = frames
		3:
			if frames - mark == 1:
				g.waves = []
				g.room_gen += 1                 # annulla le comparse annunciate
			if frames - mark == 20:
				for e in get_nodes_in_group("enemies"):
					e.queue_free()
			if frames - mark == 40:
				var mid := Vector2(g.ROOM.size.x / 2.0, (g.TOP + g.ROOM.size.y - g.WALL) / 2.0)
				sh = _spawn("knifer", mid + Vector2(0, 30))
				sh.scales = true
				sh.max_hp = 9999.0
				sh.hp = 9999.0
				sh.speed = 0.0
			if frames - mark == 50:
				print("scaglie chiuse: 10 → %.1f" % _dmg(sh))
				var b = get_first_node_in_group("ra_beam")
				b.dir = 0
				b.phase = "cross"
				b.st = 3.0
			if frames - mark == 150:
				print("dopo il fascio (aperte %.1f s): 10 → %.1f" % [sh.scale_open_t, _dmg(sh)])
			if frames - mark == 420:
				print("3 s dopo: aperte=%s, 10 → %.1f" % [sh.scale_open_t > 0.0, _dmg(sh)])
				var st = get_nodes_in_group("ra_stakes")[0]
				sh.global_position = st.global_position + Vector2(6, 0)
			if frames - mark == 430:
				print("al palo: legato=%s (fermo %.1f s), 10 → %.1f, palo speso=%s" % [sh.scale_open_t > 2.0, sh.stagger_t, _dmg(sh), not get_nodes_in_group("ra_stakes")[0].alive])
				var v = _spawn("veil", sh.global_position + Vector2(30, 0))
				v.max_hp = 9999.0
				v.hp = 9999.0
			if frames - mark == 440:
				print("sotto il velo: aperte=%s, 10 → %.1f" % [sh.scale_open_t > 0.0, _dmg(sh)])
				for v in get_nodes_in_group("veils"):
					v.queue_free()
				eater = _spawn("light_eater", sh.global_position + Vector2(-120, 0))
				var b2 = get_first_node_in_group("ra_beam")
				b2.phase = "cross"
				b2.st = 3.0
			if frames - mark == 450:
				var b3 = get_first_node_in_group("ra_beam")
				eater.max_hp = 9999.0
				eater.hp = 9999.0
				print("Divoratore vivo: fascio bloccato=%s fase='%s' (HUD %s); davanti 10 → %.1f, da dietro 10 → %.1f" % [b3.blocked, b3.phase, root.get_node("Run").get_script().get_global_name() if false else "ok", _dmg(eater, -eater.face), _dmg(eater, eater.face)])
				eater.die()
			if frames - mark == 470:
				print("Divoratore caduto: altri divoratori vivi=%d, fascio bloccato=%s" % [get_nodes_in_group("light_eaters").filter(func(e): return not e.dead).size(), get_first_node_in_group("ra_beam").blocked])
				return true
	return false
