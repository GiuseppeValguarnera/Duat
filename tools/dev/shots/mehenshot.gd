extends Node
## La Grotta di Mehen (sosta tra Sokar e il Banco di Apopi) e una stanza del Banco coi nemici nuovi.
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(dt: float) -> void:
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null:
		return
	t += dt
	if g.menu != null and is_instance_valid(g.menu):
		g._close_choice()
	if step == 0 and t > 1.0:
		step = 1
		get_tree().paused = false
		Run.region = 3
		Run.room = 0
		g.start_room({"kind": "oasis"})
	elif step == 1 and t > 4.5:
		step = 2
		get_viewport().get_texture().get_image().save_png(D + "mehen.png")
		g.start_room({"kind": "none"})
	elif step == 2 and t > 6.0:
		step = 3
		for k in ["apep_egg", "inverted", "sheut", "knifer", "shetyu", "apep_spawn"]:
			g._on_boss_summon([[k, g.player.global_position + Vector2(randf_range(-150, 150), randf_range(-110, -30))]])
	elif step == 3 and t > 9.5:
		step = 4
		get_viewport().get_texture().get_image().save_png(D + "banco.png")
		get_tree().quit()
