extends Node
var t := 0.0
var step := 0
var s = null
var ka0 := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
var P := ""
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	P = OS.get_environment("VSHOT_P")
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + P + "_" + n + ".png")
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g != null and g.name == "Hub" and t > 1.0 and step == 0:
		while g.talk_box.visible: g._advance_talk()
		g._start_run(); t = 0; return
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	p.hp = p.max_hp
	Fx.device = "pad"
	if P.begins_with("m"):
		Touch.active = true; Touch.visible = Touch._should_show(); Touch.buttons = Touch._layout(); Touch.draw_node.queue_redraw()
	if g.menu != null and is_instance_valid(g.menu) and step < 50:
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				Run.room = 3; g.start_room({"kind": "ka"}); step = 1; t = 0
		1:
			if t > 1.0:
				g.waves = []
				for e in get_tree().get_nodes_in_group("enemies"):
					if not e.dead: e.die()
				if g.cleared:
					step = 2; t = 0
				elif t > 15.0:
					L("la stanza non si ripulisce: spawning=%d" % g.spawning); step = 99
		2:
			if t > 0.8:
				for c in g.world.get_children():
					if c.get_script() == g.SerdabScript: s = c
				L("serdab comparso: %s cleared=%s room=%d reward=%s boss=%s" % [str(s != null), str(g.cleared), Run.room, str(g.current_reward), str(g.boss)])
				if s == null:
					step = 99; return
				p.global_position = Vector2(s.position.x, g.TOP + 40.0)
				step = 3; t = 0
		3:
			if t > 1.2:
				shot("1_crepa"); p.global_position = Vector2(s.position.x, g.TOP + 14.0); p.facing = Vector2.UP; step = 4; t = 0
		4:
			# tre colpi verso l'alto
			if int(t * 10) % 5 == 0: Input.action_press("attack")
			else: Input.action_release("attack")
			if s.open or t > 4.0:
				Input.action_release("attack")
				L("muro crollato: %s dopo %d colpi" % [str(s.open), s.hits])
				step = 5; t = 0
		5:
			if t > 0.8:
				shot("2_varco"); ka0 = Run.ka
				p.global_position = Vector2(s.position.x, -30.0)
				step = 6; t = 0
		6:
			if t > 1.2:
				shot("3_dentro")
				for tr in s.treasures: p.global_position = tr[1]; await get_tree().process_frame; await get_tree().process_frame
				step = 7; t = 0
		7:
			if t > 0.5:
				L("tesori presi: %s  Ka %d -> %d" % [str(s.treasures.map(func(x): return x[0] + ":" + str(x[3]))), ka0, Run.ka])
				shot("4_tesoro"); p.global_position = Vector2(s.position.x, g.TOP + 50.0); step = 8; t = 0
		8:
			if t > 1.2:
				shot("5_fuori"); L("fuori, buio=%s" % str(s.shade.color)); step = 99
		99:
			get_tree().quit()
