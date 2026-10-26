extends Node
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Hub":
		return
	match step:
		0:
			if t > 1.0:
				while g.talk_box.visible: g._advance_talk()
				Meta.runs = 6; Meta.serpent_streak = 3; Meta.feather = false
				Meta.dialogue_seen = Meta.dialogue_seen.filter(func(x): return not str(x).begins_with("piuma"))
				g.commented = false
				g._start_talk(); step = 1; t = 0
		1:
			if t > 0.5:
				get_viewport().get_texture().get_image().save_png(D + "piuma_talk.png")
				while g.talk_box.visible: g._advance_talk()
				step = 2; t = 0
		2:
			if t > 0.6:
				get_viewport().get_texture().get_image().save_png(D + "piuma_offer.png")
				var f = get_viewport().gui_get_focus_owner()
				print("FOCUS ", f.text if f is Button else "none")
				if f is Button: (f as Button).pressed.emit()
				step = 3; t = 0
		3:
			if t > 0.4:
				print("FEATHER ", Meta.feather, " phys ", g.player.is_physics_processing())
				get_tree().quit()
