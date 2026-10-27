extends Node
var t := 0.0
var step := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func press(_a: String) -> void:
	var ev := InputEventJoypadButton.new(); ev.button_index = JOY_BUTTON_START; ev.pressed = true; ev.device = 0
	Input.parse_input_event(ev)
	var ev2 := InputEventJoypadButton.new(); ev2.button_index = JOY_BUTTON_START; ev2.pressed = false; ev2.device = 0
	Input.parse_input_event(ev2)
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null: return
	match step:
		0:
			if g.name == "Hub" and t > 1.0:
				while g.talk_box.visible: g._advance_talk()
				Meta.casa = true
				get_tree().change_scene_to_file("res://scenes/casa.tscn"); step = 1; t = 0
		1:
			if g.name == "Casa" and t > 1.5:
				while g.talk_box.visible: g._advance_talk()
				print("LOG premo start nella Casa"); press("pause"); step = 2; t = 0
		2:
			if t > 1.5:
				print("LOG dopo start: scena ", get_tree().current_scene.name, " pausa aperta ", g.menu != null)
				get_viewport().get_texture().get_image().save_png(OS.get_environment("DUAT_SHOTS") + "/pausa_casa.png")
				press("pause")
				if not Meta.weapons_unlocked.has("lancia"): Meta.weapons_unlocked.append("lancia")
				Meta.serpent_wins = 1
				get_tree().change_scene_to_file("res://scenes/armory.tscn"); step = 3; t = 0
		3:
			if g.name == "Armory" and t > 1.5:
				while g.talk_box.visible: g._advance_talk()
				g._close_menu(); print("LOG premo start nel Cortile, dialogo ", g.talk_box.visible, " menu ", g.menu); press("pause"); step = 4; t = 0
		4:
			if t > 1.5 and t < 1.6:
				print("LOG cortile: pausa aperta ", g.menu != null)
				for b in g.menu.find_children("*", "Button", true, false):
					if b.text.begins_with("Torna"): b.pressed.emit()
			if t > 3.0:
				print("LOG dopo torna: scena ", get_tree().current_scene.name)
				get_tree().quit()
