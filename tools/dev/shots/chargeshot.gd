extends Node
## Attacco caricato e attacco in scatto (blocco 2), khopesh e lancia.
## Uso: tools/dev/shot.sh chargeshot 1280 720 res://scenes/game.tscn [mobile]
var t := 0.0
var step := 0
var ms: Array = []
var hp0: Array = []
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "charge_" + n + ".png")
func _spawn(g, positions: Array) -> void:
	for m in ms:
		if is_instance_valid(m):
			m.queue_free()
	ms.clear(); hp0.clear()
	for pos in positions:
		var m = g.ENEMIES["mummy"].instantiate()
		m.max_hp = 400.0
		m.position = pos
		g.world.add_child(m)
		m.set_physics_process(false)
		ms.append(m)
		hp0.append(m.hp)
func _hits() -> int:
	var n := 0
	for i in range(ms.size()):
		if is_instance_valid(ms[i]) and ms[i].hp < hp0[i]:
			n += 1
	return n
func _rel_all() -> void:
	for a in ["attack", "dash", "move_right", "move_up"]:
		Input.action_release(a)
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	p.hp = p.max_hp
	p.invuln_t = 1.0
	if g.menu != null and is_instance_valid(g.menu):
		g._close_choice()
	var c: Vector2 = Vector2(g.ROOM.size.x / 2.0, g.TOP + 190.0)
	Fx.device = "pad"                       # mira automatica (con il mouse si mirerebbe al puntatore)
	match step:
		0:
			if t > 1.0:
				Run.weapon = "khopesh"
				Run.room = 2
				g.start_room({"kind": "none"})
				step = 1; t = 0
		1:
			if t > 1.5:
				g.waves = []
				for e in get_tree().get_nodes_in_group("enemies"):
					e.queue_free()
				p.global_position = c
				_spawn(g, [c + Vector2(40, 0), c + Vector2(-40, 0), c + Vector2(0, 40), c + Vector2(0, -40)])
				Input.action_press("attack")
				step = 2; t = 0
		2:
			# tocco breve: un colpo, niente caricamento
			if t > 0.08:
				Input.action_release("attack")
				L("tocco: colpi a segno %d, caricamento %s" % [_hits(), str(p.charging)])
				step = 3; t = 0
		3:
			if t > 0.6:
				_spawn(g, [c + Vector2(40, 0), c + Vector2(-40, 0), c + Vector2(0, 40), c + Vector2(0, -40)])
				Input.action_press("attack")
				step = 4; t = 0
		4:
			# rilascio prima del pieno: annullato
			if t > 0.7:
				var k: float = p.charge_k
				Input.action_release("attack")
				step = 5; t = 0
				L("rilascio a metà carica (%.2f): sta caricando=%s" % [k, str(p.charging)])
		5:
			if t > 0.3:
				L("dopo l'annullamento: ricarica=%.1f (deve essere 0)" % p.charge_cd)
				_spawn(g, [c + Vector2(40, 0), c + Vector2(-40, 0), c + Vector2(0, 40), c + Vector2(0, -40)])
				Input.action_press("attack")
				step = 6; t = 0
		6:
			if t > 0.9 and t - dt <= 0.9:
				_shot("1_carica_khopesh")
				Input.action_press("move_right")
			if t > 1.0 and t - dt <= 1.0:
				L("caricando: velocità %.0f (rallentata), carica %.2f" % [p.velocity.length(), p.charge_k])
				Input.action_release("move_right")
			if t > 1.45:
				L("carica piena=%s" % str(p.charge_full))
				var before := _hits()
				Input.action_release("attack")
				step = 7; t = 0
				L("già colpite prima del rilascio (dal primo tocco): %d" % before)
		7:
			if t > 0.05 and t - dt <= 0.05:
				_shot("2_giro_khopesh")
			if t > 0.4:
				L("colpo a giro: nemici colpiti %d su 4, ricarica %.1f s" % [_hits(), p.charge_cd])
				step = 8; t = 0
		8:
			if t > 0.3:
				_shot("3_ricarica")
				# attacco in scatto del khopesh
				_spawn(g, [c + Vector2(90, 0)])
				p.global_position = c
				p.facing = Vector2.RIGHT
				Input.action_press("move_right")
				Input.action_press("dash")
				step = 9; t = 0
		9:
			if t > 0.05:
				Input.action_release("dash")
				Input.action_press("attack")
			if t > 0.4:
				_rel_all()
				L("attacco in scatto khopesh: indice %d, portata %.0f, ampiezza %.0f°, colpito %d" % [p.swing_index, p.swing_range, rad_to_deg(p.swing_arc), _hits()])
				step = 10; t = 0
		10:
			if t > 2.3:
				Run.weapon = "lancia"
				Run.aspect = "neith"
				p.global_position = c + Vector2(-150, 0)
				p.facing = Vector2.RIGHT
				_spawn(g, [c + Vector2(-90, 0), c + Vector2(-40, 0), c + Vector2(10, 0)])
				Input.action_press("attack")
				step = 11; t = 0
		11:
			if t > 1.45:
				Input.action_release("attack")
				step = 12; t = 0
		12:
			if t > 0.1 and t - dt <= 0.1:
				_shot("4_lancia_lanciata")
				L("lancia lanciata: in volo=%s" % str(p.spear_thrown != null))
				Input.action_press("attack")
			if t > 0.25 and t - dt <= 0.25:
				L("disarmato: tentativo di colpo, atk_t=%.2f (deve essere 0)" % p.atk_t)
				Input.action_release("attack")
			if t > 2.0:
				L("lancia: colpiti %d su 3 in fila, tornata=%s" % [_hits(), str(p.spear_thrown == null)])
				step = 13; t = 0
		13:
			if t > 2.2:
				p.global_position = c + Vector2(-150, 0)
				_spawn(g, [c + Vector2(-80, 0), c + Vector2(-55, 0), c + Vector2(-30, 0)])
				p.facing = Vector2.RIGHT
				Input.action_press("move_right")
				Input.action_press("dash")
				step = 14; t = 0
		14:
			if t > 0.05:
				Input.action_release("dash")
				Input.action_press("attack")
			if t > 0.12 and t - dt <= 0.12:
				_shot("5_affondo_in_corsa")
			if t > 0.4:
				_rel_all()
				L("affondo in corsa: portata %.0f, colpiti %d su 3 in fila" % [p.swing_range, _hits()])
				get_tree().quit()
