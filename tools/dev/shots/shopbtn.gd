extends Node
## Il tasto d'azione sul telefono dal Traghettatore: accanto alla barca deve dire PARLA,
## davanti a un oggetto COMPRA. Prima diceva sempre COMPRA.
## Uso: tools/dev/shot.sh shopbtn 1280 720 res://scenes/game.tscn mobile
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _label() -> String:
	for b in Touch._layout():
		if b["action"] == "interact":
			return b["label"]
	return "(nessun tasto)"
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	if g.menu != null and is_instance_valid(g.menu):
		g._close_choice()
	Fx.device = "touch"
	match step:
		0:
			if t > 1.0:
				Run.room = 3
				Run.ka = 100
				g.start_room({"kind": "shop"})
				step = 1; t = 0
		1:
			if t > 1.2:
				p.global_position = g.ferry.global_position + Vector2(0, 30)
				step = 2; t = 0
		2:
			if t > 0.3:
				var a := _label()
				L("accanto alla barca: %s -> %s" % [a, "ok" if a == Lang.t("PARLA") else "BUG"])
				get_viewport().get_texture().get_image().save_png(D + "shopbtn_barca.png")
				p.global_position = g.shop_items[0].global_position + Vector2(0, 8)
				step = 3; t = 0
		3:
			if t > 0.3:
				var a := _label()
				L("davanti a un oggetto: %s -> %s" % [a, "ok" if a == Lang.t("COMPRA") else "BUG"])
				get_viewport().get_texture().get_image().save_png(D + "shopbtn_oggetto.png")
				get_tree().quit()
