extends Node
var t := 0.0
var step := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func act(a: String) -> void:
	var ev := InputEventAction.new(); ev.action = a; ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventAction.new(); ev2.action = a; ev2.pressed = false
	Input.parse_input_event(ev2)
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null: return
	match step:
		0:
			if g.name == "Hub" and t > 1.0:
				while g.talk_box.visible: g._advance_talk()
				Meta.casa = true; Meta.lapis = 50
				Meta.challenges = {"serpente": 1, "pulito": 1}
				Meta.dialogue_seen.append("imh_intro")
				get_tree().change_scene_to_file("res://scenes/casa.tscn"); step = 1; t = 0
		1:
			if g.name == "Casa" and t > 1.2:
				g._open_wall(); step = 2; t = 0
		2:
			if t > 0.4 and t < 0.5:
				print("LOG fuoco iniziale ", get_viewport().gui_get_focus_owner())
				act("ui_accept")
			if t > 1.0:
				print("LOG dopo A: sfide ", Meta.challenges)
				act("ui_down")
			if t > 1.3:
				print("LOG fuoco dopo giu' ", get_viewport().gui_get_focus_owner().get_class(), " ", get_viewport().gui_get_focus_owner().get("text"))
				act("ui_accept"); step = 3; t = 0
		3:
			if t > 0.6:
				print("LOG dopo seconda A: sfide ", Meta.challenges, " ricette ", Meta.amulet_recipes)
				g._close_menu(); g._open_forge(); step = 4; t = 0
		4:
			if t > 0.5 and t < 0.6:
				print("LOG orafo fuoco ", get_viewport().gui_get_focus_owner().get("text"))
				act("ui_accept")
			if t > 1.2:
				print("LOG amuleti ", Meta.amulets, " lapis ", Meta.lapis)
				get_tree().quit()
