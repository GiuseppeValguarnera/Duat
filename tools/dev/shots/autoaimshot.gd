extends Node
## Mira automatica sul telefono: arretri (vai in basso) con una mummia sopra di te; il colpo deve
## andare verso la mummia, non alle tue spalle.
## Uso: tools/dev/shot.sh autoaimshot 1280 720 res://scenes/game.tscn mobile
var t := 0.0
var step := 0
var m = null
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	match step:
		0:
			if t > 1.0:
				Run.room = 2
				g.start_room({"kind": "ka"})
				step = 1; t = 0
		1:
			if t > 1.5:
				g.waves = []
				for e in get_tree().get_nodes_in_group("enemies"):
					e.queue_free()
				p.global_position = Vector2(g.ROOM.size.x / 2.0 + 60.0, g.TOP + 150.0)
				m = g.ENEMIES["mummy"].instantiate()
				m.position = p.global_position + Vector2(0, -60)
				g.world.add_child(m)
				m.set_physics_process(false)
				step = 2; t = 0
		2:
			Fx.device = "touch"
			Input.action_press("move_down")
			if t > 0.4:
				var a: Vector2 = p.aim
				Input.action_press("attack")
				L("arretrando: mira=%s (la mummia è sopra: y<0 giusto) -> %s" % [str(a.snapped(Vector2(0.01, 0.01))), "ok" if a.y < -0.5 else "BUG (colpisce alle spalle)"])
				step = 3; t = 0
		3:
			if t > 0.15:
				get_viewport().get_texture().get_image().save_png(D + "autoaim.png")
				Input.action_release("attack"); Input.action_release("move_down")
				get_tree().quit()
