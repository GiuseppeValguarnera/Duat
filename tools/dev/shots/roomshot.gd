extends Node
## Fotografa la stanza in corso dopo qualche secondo (regione/stanza/arma dalle variabili DUAT_*).
## DUAT_SHOT_AT="2,5,9" secondi; DUAT_SHOT_NAME prefisso; DUAT_HURT=40 toglie vita (per l'HUD);
## DUAT_GODMODE=1 il giocatore non muore.
var t := 0.0
var times: Array = []
var idx := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
var hurt := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var s := OS.get_environment("DUAT_SHOT_AT")
	for x in (s if s != "" else "3,7").split(","):
		times.append(float(x))
func _process(dt: float) -> void:
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	t += dt
	if OS.get_environment("DUAT_GODMODE") != "":
		Run.hp = maxf(Run.hp, Run.max_hp * 0.6)
		g.player.hp = maxf(g.player.hp, Run.max_hp * 0.6) if "hp" in g.player else 0.0
	if not hurt and t > 1.0 and OS.get_environment("DUAT_HURT") != "":
		hurt = true
		g.player.take_damage(float(OS.get_environment("DUAT_HURT")), g.player.global_position)
	if idx < times.size() and t >= times[idx]:
		var n := OS.get_environment("DUAT_SHOT_NAME")
		get_viewport().get_texture().get_image().save_png(D + (n if n != "" else "room") + "_%d.png" % idx)
		idx += 1
		if idx >= times.size():
			get_tree().quit()
