extends Node
## Blocco 1 (novembre 2026): musica dei guardiani, Figlio di Iside con l'Ushabti, contatore dello
## Scettro Was, "Esci" sul web che torna alla Sala e riprende la discesa dal cancello.
## Uso: DUAT_REGION2=1 DUAT_WEBQUIT=1 tools/dev/shot.sh blocco1shot 1280 720 res://scenes/game.tscn [mobile]
var t := 0.0
var step := 0
var m = null
var hp0 := 0.0
var saved_room := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "b1_" + n + ".png")
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null:
		return
	if step == 30:
		# siamo nella Sala dopo "Esci"
		if g.name != "Hub":
			if t > 4.0:
				L("dopo Esci la scena è %s -> BUG" % g.name); get_tree().quit()
			return
		if t > 1.5:
			L("dopo Esci: scena=%s  discesa salvata=%s  in attesa al cancello=%s" % [g.name, str(Run.has_saved_descent()), str(Run.hold_descent)])
			_shot("6_sala_dopo_esci")
			g._start_run()
			step = 31; t = 0
		return
	if step == 31:
		if g.name == "Game" and t > 2.0:
			L("dal cancello: scena=%s stanza=%d (salvata %d) -> %s" % [g.name, Run.room, saved_room, "ok" if Run.room == saved_room else "BUG"])
			_shot("7_ripresa")
			get_tree().quit()
		return
	if g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	if g.menu != null and is_instance_valid(g.menu) and step != 30:
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				p.invuln_t = 99.0
				Run.region = 1; Run.room = 4
				g.start_room({"kind": "guardian"})
				step = 1; t = 0
		1:
			if t > 6.0 and not get_tree().paused:
				L("Serpente: musica=%s -> %s" % [Music.current, "ok" if Music.current == "boss" else "BUG"])
				_shot("1_serpente")
				Run.region = 2; Run.room = 4
				g.start_room({"kind": "guardian"})
				step = 2; t = 0
		2:
			if t > 6.0 and not get_tree().paused:
				L("Serket: musica=%s -> %s" % [Music.current, "ok" if Music.current == "boss" else "BUG"])
				Run.region = 1; Run.room = 2
				g.start_room({"kind": "ka"})
				step = 3; t = 0
		3:
			if t > 1.5:
				g.waves = []
				for e in get_tree().get_nodes_in_group("enemies"):
					e.queue_free()
				Run.add_boon("duo_iside_horus")
				p.global_position = Vector2(g.ROOM.size.x / 2.0, g.TOP + 200.0)
				m = g.ENEMIES["mummy"].instantiate()
				m.position = p.global_position + Vector2(70, 0)
				g.world.add_child(m)
				m.set_physics_process(false)
				p.hp = p.max_hp * 0.5
				hp0 = p.hp
				var eye = p.EyeScript.new()
				eye.direction = Vector2.RIGHT
				eye.damage = 1.0
				eye.from_player = false
				g.world.add_child(eye)
				eye.global_position = p.global_position + Vector2(20, -6)
				step = 4; t = 0
		4:
			if t > 0.8:
				L("Occhio dell'Ushabti a segno: vita %.0f -> %.0f -> %s" % [hp0, p.hp, "ok (nessuna cura)" if p.hp == hp0 else "BUG (cura)"])
				hp0 = p.hp
				var eye = p.EyeScript.new()
				eye.direction = Vector2.RIGHT
				eye.damage = 1.0
				g.world.add_child(eye)
				eye.global_position = p.global_position + Vector2(20, -6)
				step = 5; t = 0
		5:
			if t > 0.8:
				L("Occhio del giocatore a segno: vita %.0f -> %.0f -> %s" % [hp0, p.hp, "ok (cura 2)" if p.hp == hp0 + 2.0 else "BUG"])
				Run.amulet = "was"; Run.amulet_level = 2; Run.was_stacks = 3
				step = 6; t = 0
		6:
			if t > 0.5:
				L("HUD: %s" % g.hud.text.replace("\n", " | "))
				_shot("5_was_hud")
				saved_room = Run.room
				step = 7; t = 0
		7:
			if t > 0.3:
				g._quit_game()
				step = 30; t = 0
