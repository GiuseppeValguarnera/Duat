extends Node
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "casa_" + n + ".png")
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null:
		return
	match step:
		0:
			if g.name == "Hub" and t > 1.0:
				while g.talk_box.visible: g._advance_talk()
				Meta.lapis = 55; Meta.casa = false; Meta.runs = 3
				g.player.global_position = Vector2(g.ROOM.size.x - 60, g.CASA_Y)
				step = 1; t = 0
		1:
			if t > 0.8:
				shot("sala_chiusa")
				g._open_casa()
				step = 2; t = 0
		2:
			if t > 0.8:
				shot("sala_aperta")
				Meta.challenges = {"serpente": 2, "pulito": 1, "cercatore": 1, "scarabei": 1}
				Meta.stats = {"scarabei": 37, "best_fermo": 2, "serdab": 3}
				Meta.amulet_recipes = ["iside"]
				Meta.amulets = ["iside"]; Meta.amulet = "iside"; Meta.amulet_rooms = {"iside": 12}
				get_tree().change_scene_to_file("res://scenes/casa.tscn"); step = 3; t = 0
		3:
			if g.name == "Casa" and t > 1.2:
				shot("imhotep_intro")
				while g.talk_box.visible: g._advance_talk()
				g.player.global_position = g.spots["imhotep"] + Vector2(24, 10)
				step = 30; t = 0
		30:
			if t > 0.4:
				shot("stanza")
				g._start_talk(); step = 31; t = 0
		31:
			if t > 0.4:
				shot("imhotep_amuleto")
				while g.talk_box.visible: g._advance_talk()
				g.player.global_position = g.spots["parete"] + Vector2(0, 30)
				step = 4; t = 0
		4:
			if t > 0.3:
				g._open_wall(); step = 5; t = 0
		5:
			if t > 0.5 and t < 0.6:
				for i in range(12):
					var ev := InputEventAction.new(); ev.action = "ui_down"; ev.pressed = true
					Input.parse_input_event(ev)
					var ev2 := InputEventAction.new(); ev2.action = "ui_down"; ev2.pressed = false
					Input.parse_input_event(ev2)
			if t > 1.2:
				print("FOCUS ", get_viewport().gui_get_focus_owner())
				shot("parete")
				for b in g.menu.find_children("*", "Button", true, false):
					if b.text.begins_with("Riscuoti") or b.text.begins_with("Claim"):
						b.pressed.emit(); break
				step = 6; t = 0
		6:
			if t > 0.5:
				g._open_forge(); step = 7; t = 0
		7:
			if t > 0.5:
				shot("orafo")
				for b in g.menu.find_children("*", "Button", true, false):
					if b.text.begins_with("Forgialo"):
						b.pressed.emit(); break
				step = 8; t = 0
		8:
			if t > 0.5:
				shot("orafo2")
				print("AMULETI ", Meta.amulets, " al collo ", Meta.amulet, " lapis ", Meta.lapis, " sfide ", Meta.challenges)
				g._close_menu()
				g._leave(); step = 9; t = 0
		9:
			if g.name == "Hub" and t > 1.0:
				shot("ritorno")
				get_tree().quit()
