extends Node
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if step == 5:
		if t > 2.5:
			if g != null and g.talk_box.visible: g._advance_talk()
			get_viewport().get_texture().get_image().save_png(D + "rest_cortile.png")
			get_tree().quit()
		return
	if g == null or g.name != "Hub":
		return
	while g.talk_box.visible: g._advance_talk()
	match step:
		0:
			if t > 1.0:
				Meta.restorations = []; Meta.lapis = 7; Meta.runs = 3
				get_tree().reload_current_scene(); step = 1; t = 0
		1:
			if t > 1.5:
				get_viewport().get_texture().get_image().save_png(D + "rest_prima.png")
				g.player.global_position = g.spots["cassa"] + Vector2(0, 30)
				step = 2; t = 0
		2:
			if t > 0.4:
				g._open_book("restauri"); step = 3; t = 0
		3:
			if t > 0.5:
				get_viewport().get_texture().get_image().save_png(D + "rest_finestra.png")
				g._close_book()
				Meta.restorations = Restorations.ALL_IT.keys()
				get_tree().reload_current_scene(); step = 4; t = 0
		4:
			if t > 1.5:
				get_viewport().get_texture().get_image().save_png(D + "rest_dopo.png")
				if not Meta.weapons_unlocked.has("lancia"): Meta.weapons_unlocked.append("lancia")
				get_tree().change_scene_to_file("res://scenes/armory.tscn"); step = 5; t = 0
