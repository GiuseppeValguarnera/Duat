extends Node
## Il tutorial (blocco 2): i suggerimenti in una pergamena piccola e semitrasparente a sinistra,
## sotto la barra della vita; il gioco non si ferma.
## Uso: tools/dev/shot.sh tutshot 1280 720 res://scenes/game.tscn [mobile]
var t := 0.0
var step := 0
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
	if g.menu != null and is_instance_valid(g.menu):
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				Run.room = 0
				g.start_room({"kind": "tutorial"})
				step = 1; t = 0
		1:
			if t > 1.5:
				var pn = g.tut.panel
				var vs: Vector2 = get_viewport().get_visible_rect().size
				L("pergamena: posizione %s grandezza %s schermo %s trasparenza %.2f gioco fermo=%s" % [str(pn.position.round()), str(pn.size.round()), str(vs), pn.modulate.a, str(get_tree().paused)])
				L("occupa il %.0f%% dello schermo" % (pn.size.x * pn.size.y / (vs.x * vs.y) * 100.0))
				get_viewport().get_texture().get_image().save_png(D + "tut_1.png")
				g.tut.next()
				step = 2; t = 0
		2:
			if t > 1.2:
				get_viewport().get_texture().get_image().save_png(D + "tut_2.png")
				get_tree().quit()
