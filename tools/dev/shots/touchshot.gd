extends Node
## Il telefono in partita: comandi a schermo, HUD, una stanza di combattimento.
var t := 0.0
var n := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game":
		return
	Fx.device = "touch"
	if g.menu != null and t > 1.0:
		g._close_choice(); g.start_room({"kind": "ka"}); t = 0
	if g.player != null and is_instance_valid(g.player):
		g.player.invuln_t = 1.0
	if t > 4.0:
		get_viewport().get_texture().get_image().save_png(OS.get_environment("DUAT_SHOTS") + "/touch_%d.png" % n)
		n += 1; t = 2.0
		if n >= 2:
			get_tree().quit()
