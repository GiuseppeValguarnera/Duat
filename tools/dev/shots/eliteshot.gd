extends Node
var t := 0.0
var step := 0
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
	p.hp = p.max_hp; p.invuln_t = 9.0
	match step:
		0:
			if g.menu == null and t > 0.8:
				g.waves = []
				for e in get_tree().get_nodes_in_group("enemies"): e.die()
				var kinds := ["mummy", "scarab", "priest", "cobra", "crocodile"]
				for i in range(kinds.size()):
					for el in [false, true]:
						var e = g.ENEMIES[kinds[i]].instantiate()
						e.elite = el
						e.position = p.global_position + Vector2(-200 + i * 100, -150 + (70 if el else 0))
						g.world.add_child(e)
						e.set_physics_process(false)
				step = 1; t = 0
		1:
			if t > 0.6:
				get_viewport().get_texture().get_image().save_png(D + "elite.png"); get_tree().quit()
