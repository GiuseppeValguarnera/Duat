extends SceneTree
## Blocco 23: l'Arte dell'arma. Senza grafica: per ogni arma (prima base, poi con l'evoluzione II e
## III) mette tre mummie vicine (e una lontana sulla mira per lancia e arco), lancia l'Arte e controlla
## che colpisca, che la ricarica parta e che a ricarica in corso non riparta.
var frames := 0
var g = null
var weapons := ["khopesh", "lancia", "arco", "flagello", "artigli", "scettro"]
var wi := 0
var evo_pass := 0
var step := 0
var mark := 0
var foes: Array = []
var hp0 := 0.0

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
	var run = root.get_node("Run")
	var meta = root.get_node("Meta")
	if g.player != null and is_instance_valid(g.player) and evo_pass < 3:
		g.player.hp = g.player.max_hp
	match step:
		0:
			if frames >= 30:
				g.waves = []
				g.room_gen += 1
				for e in get_nodes_in_group("enemies"):
					e.queue_free()
				step = 1
				mark = frames
		1:
			if frames - mark == 5:
				var w: String = weapons[wi]
				run.weapon = w
				meta.weapon_evo[w] = [0, 2, 3, 0][evo_pass]
				# ultimo giro (blocco 24): tutti i doni dell'Arte dell'arma insieme
				run.boons = {}
				if evo_pass == 3:
					for god in ["ra", "sekhmet", "thoth", "bastet", "sobek", "iside", "horus", "anubi", "nefti", "shu"]:
						run.boons["arte_%s_%s" % [w, god]] = 1
					g.player.hp = g.player.max_hp - 10.0
					g.player.eye_cd = 2.0
					g.player.shield = 0.0
				var p = g.player
				p.art_cd = 0.0
				p.aim = Vector2.RIGHT
				p.facing = Vector2.RIGHT
				var c: Vector2 = p.global_position
				foes = []
				var spots := [Vector2(34, 0), Vector2(-30, 18), Vector2(0, -36)]
				if w == "lancia" or w == "arco":
					spots = [Vector2(110, 0), Vector2(126, 20), Vector2(100, -18)]
				for s in spots:
					var e = g.ENEMIES["mummy"].instantiate()
					e.position = c + s
					g.world.add_child(e)
					e.max_hp = 9999.0
					e.hp = 9999.0
					e.speed = 0.0
					foes.append(e)
			if frames - mark == 12:
				# la mira la decide il mouse (fermo in un angolo): i bersagli a distanza si mettono lungo la mira vera
				if weapons[wi] == "lancia" or weapons[wi] == "arco":
					var ang: float = (g.player._bow_aim() if weapons[wi] == "arco" else g.player.aim).angle()
					var offs := [Vector2(105, 0), Vector2(118, 16), Vector2(95, -14)]
					for i in range(foes.size()):
						foes[i].global_position = g.player.global_position + offs[i].rotated(ang)
				hp0 = 0.0
				for e in foes:
					hp0 += e.hp
				g.player.try_art()
				var cd: float = g.player.art_cd
				g.player.try_art()          # a ricarica in corso: non deve ripartire
				var arts := 0
				for n in g.world.get_children():
					if n.has_method("_spear"):
						arts += 1
				if arts != 1:
					print("ARTE %s: ERRORE, arti in campo=%d" % [weapons[wi], arts])
				print("ARTE %s evo %d: ricarica %.1f s" % [weapons[wi], [0, 2, 3, 0][evo_pass], cd])
				if evo_pass == 3:
					print("DONI ARTE %s: scudo %.0f, occhio pronto %s" % [weapons[wi], g.player.shield, g.player.eye_cd <= 0.0])
			if frames - mark == 12 + 70 and evo_pass == 3:
				var burn := 0
				var slow := 0
				var mark2 := 0
				for e in foes:
					if is_instance_valid(e):
						burn += 1 if e.burn_t > 0.0 else 0
						slow += 1 if e.slow_t > 0.0 else 0
						mark2 += 1 if e.has_meta("art_mark") else 0
				print("DONI ARTE %s: fuoco %d, rallentati %d, marchiati %d, vita %.0f/%.0f" % [weapons[wi], burn, slow, mark2, g.player.hp, g.player.max_hp])
				g.player.hp = g.player.max_hp
			if frames - mark == 12 + 200:
				var dealt := 0.0
				var hit := 0
				for e in foes:
					if is_instance_valid(e):
						dealt += 9999.0 - e.hp
						if e.hp < 9999.0:
							hit += 1
						e.queue_free()
				print("ARTE %s evo %d: colpiti %d/3, danni %.0f" % [weapons[wi], [0, 2, 3, 0][evo_pass], hit, dealt])
				for n in g.world.get_children():
					if n.has_method("_spear") or n.is_in_group("was_circle"):
						n.queue_free()
				wi += 1
				if wi >= weapons.size():
					wi = 0
					evo_pass += 1
					if evo_pass > 3:
						return true
				mark = frames
	return false
