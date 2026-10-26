extends Node
var t := 0.0
var step := 0
var shots := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "reb_" + n + ".png")
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null:
		return
	match step:
		0:
			if g.name == "Game" and g.menu != null and t > 1.0:
				for b in g.menu.find_children("*", "BaseButton", true, false):
					b.pressed.emit(); break
				t = 0
				return
			if g.name == "Game" and g.menu == null and t > 1.5:
				g.player.take_damage(999, g.player.global_position + Vector2(10, 0))
				step = 1; t = 0
		1:
			if t > 1.0:
				shot("1_ba"); step = 2; t = 0
		2:
			if t > 2.5:
				shot("2_pannello")
				Input.action_press("restart"); step = 3; t = 0
		3:
			if t > 0.15:
				Input.action_release("restart")
			if t > 1.1:
				shot("3_scarabeo"); step = 4; t = 0
		4:
			if g.name == "Hub" and shots == 0:
				shots = 1; t = 0
			if shots == 1 and t > 0.45:
				shot("4_raggio"); shots = 2; t = 0
			if shots == 2 and t > 0.7:
				shot("5_riemerso"); shots = 3; t = 0
			if shots == 3 and t > 1.0:
				shot("6_anubi")
				get_tree().quit()
