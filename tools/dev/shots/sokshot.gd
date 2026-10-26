extends Node
var t := 0.0
var step := 0
var shots := 0
var es := []
var D := OS.get_environment("DUAT_SHOTS") + "/"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game": return
	if g.menu != null and t > 1.0:
		for b in g.menu.find_children("*", "BaseButton", true, false):
			b.pressed.emit(); break
		t = 0; return
	var p = g.player
	if p == null or not is_instance_valid(p): return
	p.hp = p.max_hp
	match step:
		0:
			if g.menu == null and t > 0.8:
				Run.region = 2; Run.room = 4
				g.start_room({"kind": "ka"})
				step = 1; t = 0
		1:
			if t > 1.0:
				g.waves = []
				for e in get_tree().get_nodes_in_group("enemies"): e.die()
				var P: Vector2 = g.player.global_position
				var spec := [["jackal", Vector2(-160, -170)], ["jackal", Vector2(-120, -190)], ["jackal", Vector2(-80, -170)], ["vulture", Vector2(140, -150)], ["sokar_guard", Vector2(0, -230)], ["damned_ba", Vector2(220, -60)], ["damned_ba", Vector2(-240, -40)]]
				for s in spec:
					var e = g.ENEMIES[s[0]].instantiate()
					e.position = P + s[1]
					g.world.add_child(e)
					es.append(e)
				step = 2; t = 0
		2:
			g.player.hp = g.player.max_hp
			g.player.invuln_t = 0.2
			if t > 0.7 * (shots + 1) and shots < 6:
				shots += 1
				get_viewport().get_texture().get_image().save_png(D + "sok_%d.png" % shots)
				var st := []
				for e in es:
					if is_instance_valid(e): st.append("%s:%s" % [e.name, e.state])
				print("LOG ", shots, " ", st)
			if shots >= 6:
				# colpo frontale e alle spalle al guardiano
				for e in es:
					if is_instance_valid(e) and e.name.begins_with("SokarGuard"):
						var hp0 = e.hp
						e.state = "walk"; e.facing = Vector2.DOWN
						e.take_hit(20.0, Vector2.UP, 0.0)
						var hp1 = e.hp
						e.take_hit(20.0, Vector2.DOWN, 0.0)
						print("LOG scudo: davanti %d, dietro %d" % [hp0 - hp1, hp1 - e.hp])
				get_tree().quit()
