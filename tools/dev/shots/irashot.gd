extends Node
var t := 0.0
var step := 0
var flag := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "ira_" + n + ".png")
func _boss(g):
	return g.boss if g.boss != null and is_instance_valid(g.boss) else null
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g != null and g.name == "Hub" and t > 1.0 and step == 0:
		while g.talk_box.visible: g._advance_talk()
		Meta.ammit_wins = 1; Meta.weights = {"ira_serpente": 1, "ira_amheh": 1}
		g._start_run(); t = 0; return
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	p.hp = p.max_hp
	p.invuln_t = maxf(p.invuln_t, 0.0)
	if g.menu != null and is_instance_valid(g.menu):
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				Run.room = 4; g.start_room({"kind": "guardian"}); step = 1; t = 0
		1:
			if t > 0.9 and flag == 0:
				shot("0_porta_ingresso"); flag = 1
				var cam = p.get_node("Camera"); cam.zoom = Vector2(0.6, 0.6)
			if t > 1.1 and flag == 1:
				shot("0b_porta_intera"); flag = 2
				p.get_node("Camera").zoom = Vector2.ONE
			if not get_tree().paused and t > 3.0 and _boss(g) != null:
				flag = 0
				var b = _boss(g)
				L("serpente ira=%s" % str(b.ira))
				p.global_position = b.global_position + Vector2(0, 110)
				b.state = "rain"; b.st = 0.05; step = 2; t = 0
		2:
			if t > 0.5 and flag == 0:
				shot("1_pioggia_avviso"); flag = 1
			if t > 1.6:
				shot("2_pioggia_pozze"); flag = 0
				var b = _boss(g); b.state = "spit"; b.st = 0.05; b.aim = (p.global_position - b.global_position).normalized().rotated(1.2)
				for k in range(3):
					var pd = Hazards.VenomPuddle.new()
					pd.position = p.global_position + Vector2(70 + k * 40, -20)
					g.world.add_child(pd)
				step = 3; t = 0
		3:
			if t > 1.2:
				shot("3_sputi_pozze")
				var b = _boss(g)
				b.global_position = Run.deep_center + Vector2(230, -40)
				b.state = "seek_deep"; b.st = 2.5
				L("seek_deep da fuori: in_deep=%s" % str(Run.in_deep(b.global_position)))
				p.global_position = b.global_position + Vector2(-120, 60)
				step = 4; t = 0
		4:
			var b = _boss(g)
			if b != null and b.state == "under" and flag == 0:
				L("si e' tuffato dopo %.1f s, in_deep=%s" % [t, str(Run.in_deep(b.global_position))])
				flag = 4
			if b != null and b.state == "under" and t > 0.5 and flag == 4:
				shot("3b_sottacqua"); flag = 5
			if b != null and b.second_dive and b.state == "warn" and flag == 5:
				shot("4_seconda_emersione"); flag = 1; L("seconda emersione ok")
			if flag == 1 or t > 8.0:
				flag = 0
				t = 0
				Run.room = 10; g.start_room({"kind": "boss"}); step = 5; t = 0
		5:
			if t > 1.0 and flag == 0:
				shot("4b_lago_ingresso"); flag = 1
				p.get_node("Camera").zoom = Vector2(0.6, 0.6)
			if t > 1.2 and flag == 1:
				shot("4c_lago_intero"); flag = 2
				p.get_node("Camera").zoom = Vector2.ONE
			if not get_tree().paused and t > 3.0 and _boss(g) != null:
				flag = 0
				var b = _boss(g)
				L("amheh ira=%s" % str(b.ira))
				p.global_position = b.global_position + Vector2(-60, 90)
				b.state = "ring_windup"; b.st = 0.8; step = 6; t = 0
		6:
			if t > 0.5 and flag == 0:
				shot("5_anello_avviso"); flag = 1
			if t > 1.6:
				shot("6_anello"); flag = 0
				var pools = get_tree().get_nodes_in_group("water")
				p.global_position = pools[0].global_position
				_boss(g)._dry_a_pool()
				step = 7; t = 0
		7:
			if t > 0.8:
				shot("7_pozza_bolle")
				var b = _boss(g); b.state = "leap_windup"; b.st = 0.3; b.leap_to = p.global_position + Vector2(40, 0)
				step = 8; t = 0
		8:
			var b = _boss(g)
			if b != null and b.second_leap and b.state == "leap_windup" and flag == 0 and t > 0.1:
				shot("8_doppio_balzo"); flag = 1; L("doppio balzo ok")
			if flag == 1 and t > 0.3 or t > 6.0:
				get_tree().quit()
