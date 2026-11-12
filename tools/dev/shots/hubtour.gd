extends Node
## Giro della Sala per guardarla: stato avanzato (restauri, Sfinge, Casa), poi stato nuovo con DUAT_FRESH=1.
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
var P := "hub_"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_environment("DUAT_FRESH") == "":
		Meta.restorations = Restorations.ALL_IT.keys()
		Meta.runs = 12
		Meta.serpent_wins = 3
		Meta.ammit_wins = 1
		Meta.casa = true
		Meta.lapis = 44
		Meta.sphinx["open"] = true
		Meta.weapons_unlocked = ["khopesh", "lancia"]
		Meta.options["arrows"] = true
	else:
		P = "hubnew_"
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + P + n + ".png")
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Hub":
		return
	var spots := [["start", Vector2.ZERO], ["scale", g.spots["bilancia"] + Vector2(0, 34)], ["pool", g.spots["vasca"] + Vector2(30, -34)], ["sphinx", Vector2(616, 110)], ["west", Vector2(90, 218)], ["east", Vector2(700, 218)], ["gate", Vector2(400, 96)]]
	if t > 1.5:
		t = 0.9
		if step > 0 and step <= spots.size():
			shot(spots[step - 1][0])
		if step >= spots.size():
			get_tree().quit()
			return
		while g.talk_box.visible: g._advance_talk()
		if spots[step][1] != Vector2.ZERO:
			g.player.global_position = spots[step][1]
		step += 1
