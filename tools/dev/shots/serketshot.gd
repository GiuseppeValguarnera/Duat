extends Node
## Serket nel suo tempio: arena, presentazione, ventaglio, scavo con il solco, scorpioni dai
## cumuli, colpo di coda dalla sabbia, balzo in linea, adirata (aura e nube), premio.
## Uso: DUAT_REGION2=1 tools/dev/shot.sh serketshot 1280 720 res://scenes/game.tscn [mobile]
var t := 0.0
var step := 0
var flag := 0
var s5 := false
var s6 := false
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "serket_" + n + ".png")
func _boss(g):
	return g.boss if g.boss != null and is_instance_valid(g.boss) else null
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	if not (step == 2 or step == 5 or (step == 3 and flag >= 10)):
		p.invuln_t = 0.0
		p.hp = p.max_hp
		Run.hp = p.max_hp
		p.poison_t = 0.0
	if g.menu != null and is_instance_valid(g.menu) and t > 0.6:
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				Run.region = 2; Run.room = 4
				g.start_room({"kind": "guardian"}); step = 1; t = 0
		1:
			if t > 1.0 and flag == 0:
				shot("00_ingresso"); flag = 1
				p.get_node("Camera").zoom = Vector2(0.6, 0.6)
			if t > 1.3 and flag == 1:
				shot("01_tempio_intero"); flag = 2
				p.get_node("Camera").zoom = Vector2.ONE
			if t > 2.2 and flag == 2:
				shot("02_presentazione"); flag = 3
			if not get_tree().paused and t > 4.5 and _boss(g) != null:
				flag = 0
				var b = _boss(g)
				L("serket hp=%d arena dais=%s mounds=%d" % [b.max_hp, str(b.dais_radii), b.mounds.size()])
				b.global_position = Vector2(400, 180)
				p.global_position = b.global_position + Vector2(40, 60)
				b.aim = (p.global_position - b.global_position).normalized()
				b.state = "fan_windup"; b.st = b.fan_windup
				p.invuln_t = 0.0
				step = 2; t = 0
		2:
			if t > 0.45 and flag == 0:
				shot("03_ventaglio_avviso"); flag = 1
			if t > 0.95:
				L("ventaglio: vita giocatore %d/%d (dentro lo spicchio: deve aver preso il colpo)" % [p.hp, p.max_hp])
				var b = _boss(g)
				b.global_position = Vector2(200, 300)
				p.global_position = Vector2(560, 380)
				b._dive(); flag = 0
				step = 3; t = 0
		3:
			var b = _boss(g)
			if b != null and b.state == "under" and t > 1.0 and flag == 0:
				shot("04_solco"); flag = 1
				L("sotto la sabbia: nel gruppo nemici=%s, scorpioni in arrivo=%d" % [str(b.is_in_group("enemies")), g.spawning])
				# il colpo di coda dalla sabbia, puntato su di te: deve ferire chi resta sulla linea
				p.global_position = b.global_position + Vector2(120, 0)
				p.invuln_t = 0.0
				for e in get_tree().get_nodes_in_group("enemies"):
					if "sting_dir" in e: e.set_physics_process(false)
				b.state = "line_warn"; b.st = b.line_warn; b.aim = Vector2.RIGHT; b.line_done = true
				flag = 10
			if flag == 10 and b != null and b.state == "line_warn" and t > 1.35:
				shot("05_coda_dalla_sabbia"); flag = 11
			if flag == 11 and b != null and b.state == "under":
				L("coda dalla sabbia: vita giocatore %d/%d (sulla linea: deve aver preso il colpo)" % [p.hp, p.max_hp])
				for e in get_tree().get_nodes_in_group("enemies"):
					if "sting_dir" in e: e.set_physics_process(true)
				flag = 2
			if b != null and b.state == "breach_warn" and flag <= 2:
				shot("06_riemerge_avviso"); flag = 3
			if b != null and b.state == "breach" and flag == 3:
				shot("07_balzo"); flag = 4
			if flag == 4 and t > 0.2 or t > 7.0:
				var n := 0
				for e in get_tree().get_nodes_in_group("enemies"):
					if "sting_dir" in e: n += 1
				L("scavo finito dopo %.1f s, stato=%s, scorpioni vivi=%d" % [t, b.state if b != null else "-", n])
				shot("08_scorpioni")
				flag = 0; step = 4; t = 0
		4:
			# sul piano di pietra non si scava: se ci sei sopra si ferma al bordo
			var b = _boss(g)
			if t > 1.2 and flag == 0:
				b.global_position = Vector2(140, 250)
				p.global_position = Vector2(400, 262)
				b._dive(); flag = 5
			if int(t * 4.0) != int((t - dt) * 4.0):
				if false: L("verso la pietra t=%.2f: stato=%s pos=%s sulla pietra=%s" % [t, b.state, str(b.global_position), str(b.on_dais(b.global_position))])
			if b.state == "breach_warn" and flag == 5:
				L("fermata al bordo del piano: sul piano=%s, distanza dal centro %.0f" % [str(b.on_dais(b.global_position)), b.global_position.distance_to(b.dais_center)])
				shot("09_bordo_pietra"); flag = 1
			if flag == 1 and t > 2.5 or t > 9.0:
				flag = 0; step = 5; t = 0
		5:
			var b = _boss(g)
			if not s5:
				s5 = true
				b.take_hit(b.hp - b.max_hp * 0.45, Vector2.UP, 0.0)
				b.state = "recover"; b.st = 0.3
				b.global_position = Vector2(400, 200)
				p.global_position = Vector2(430, 225)
			if t < 1.0 and flag == 0:
				p.global_position = b.global_position + Vector2(20, 18)      # attaccato a lei, dentro la nube
			if t > 1.0 and flag == 0:
				L("hp=%.0f stato=%s" % [b.hp, b.state])
				L("adirata=%s, veleno sul giocatore=%.1f s" % [str(b.enraged), p.poison_t])
				shot("10_adirata_aura"); flag = 1
				b.aim = Vector2.DOWN
				b.state = "fan_windup"; b.st = b.fan_windup
			if b.second_fan and flag == 1:
				shot("11_ventaglio_doppio"); flag = 2
			if flag == 2 and t > 2.2:
				b.global_position = Vector2(250, 330); p.global_position = Vector2(560, 330)
				b.state = "under"; b._set_buried(true); b.under_left = 0.05; b.line_done = true
				flag = 3
			if flag == 3 and b.state == "recover":
				shot("12_nube"); flag = 4
				var clouds := 0
				for c in g.world.get_children():
					if c is Hazards.VenomCloud: clouds += 1
				L("nubi lasciate: %d" % clouds)
			if flag == 4 and t > 0.5 or t > 9.0:
				flag = 0; step = 6; t = 0
		6:
			var b = _boss(g)
			if not s6 and b != null:
				s6 = true
				b.take_hit(b.hp + 1.0, Vector2.UP, 0.0)
			if t > 0.5 and flag == 0 or t > 1.5 and flag == 1:
				flag += 1
				L("dopo la morte: alive=%d spawning=%d cleared=%s guardian_down=%s ricompensa=%s" % [g.alive, g.spawning, str(g.cleared), str(g.guardian_down), str(g.current_reward)])
			if t > 2.5:
				shot("13_premio")
				L("battuta: serket_wins=%d serpent_wins=%d" % [Meta.serket_wins, Meta.serpent_wins])
				get_tree().quit()
