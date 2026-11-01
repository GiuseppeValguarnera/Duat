extends Node
## Le porte vere (blocco 2): chiuse finché la stanza non è ripulita; camminandoci contro non si
## passa; accanto, "interagisci" fa entrare.
## Uso: tools/dev/shot.sh doorpush 1280 720 res://scenes/game.tscn [mobile]
var t := 0.0
var step := 0
var room0 := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "door_" + n + ".png")
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	p.hp = p.max_hp; p.invuln_t = 1.0
	if g.menu != null and is_instance_valid(g.menu) and t > 0.5:
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				Run.room = 2; g.start_room({"kind": "none"}); step = 1; t = 0
		1:
			if t > 1.5:
				var sealed := 0
				for d in g.doors:
					if not d.open:
						sealed += 1
				L("inizio stanza: porte %d, chiuse %d" % [g.doors.size(), sealed])
				p.global_position = Vector2(g.ROOM.size.x / 2.0, g.TOP + 40.0)
				_shot("1_chiuse")
				g.waves = []
				for e in get_tree().get_nodes_in_group("enemies"): e.die()
				step = 2; t = 0
		2:
			if not g.cleared:
				for e in get_tree().get_nodes_in_group("enemies"): e.die()
				t = 0.0
			if t > 1.0:
				var open_n := 0
				for d in g.doors:
					if d.open:
						open_n += 1
				L("stanza ripulita: porte aperte %d su %d" % [open_n, g.doors.size()])
				_shot("2_aperte")
				var target = null
				for d in g.doors:
					if d.open:
						target = d
						break
				p.global_position = target.global_position + (Vector2(0, 30) if target.side == "n" else Vector2(30 if target.side == "w" else -30, 0))
				room0 = Run.room
				step = 3; t = 0
		3:
			# cammina contro la porta per un secondo: non deve passare
			var target = null
			for d in g.doors:
				if d.open:
					target = d
					break
			var dir: Vector2 = (target.global_position - p.global_position).normalized()
			Input.action_release("move_up"); Input.action_release("move_left"); Input.action_release("move_right")
			if dir.y < -0.5: Input.action_press("move_up")
			elif dir.x < -0.5: Input.action_press("move_left")
			elif dir.x > 0.5: Input.action_press("move_right")
			if t > 1.0:
				Input.action_release("move_up"); Input.action_release("move_left"); Input.action_release("move_right")
				L("camminando contro la porta: stanza %d -> %d (passato per sbaglio=%s)" % [room0, Run.room, str(Run.room != room0)])
				L("suggerimento: %s" % g.prompt.text)
				_shot("3_accanto")
				Input.action_press("interact")
				step = 4; t = 0
		4:
			if t > 0.1:
				Input.action_release("interact")
			if Run.room != room0 or t > 2.0:
				L("con interagisci: stanza %d -> %d (entrato=%s)" % [room0, Run.room, str(Run.room != room0)])
				get_tree().quit()
