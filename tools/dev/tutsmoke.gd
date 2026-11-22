extends SceneTree
## Blocco 27: l'addestramento rifatto dalla Sala. Passa tutti i 10 passi (chiamando next) e controlla
## che ci siano la porta per tornare alla Sala (sud) e, alla fine, quella della discesa (nord).
var frames := 0
var g = null
var stepped := 0

func _initialize() -> void:
	root.get_node("Run").tutorial_replay = true
	change_scene_to_file("res://scenes/game.tscn")

func _process(_d: float) -> bool:
	frames += 1
	g = current_scene
	if g == null or not g.has_method("start_room"):
		return false
	if frames == 40:
		if g.tut.step != 0:
			push_error("TUT: l'addestramento non è partito (passo %d)" % g.tut.step)
		var back := false
		for d in g.doors:
			if is_instance_valid(d) and d.reward.get("kind", "") == "hub_back":
				back = true
		if not back:
			push_error("TUT: manca la porta per tornare alla Sala")
	if frames > 40 and frames % 20 == 0 and stepped < 9:
		g.tut.next()
		stepped += 1
		print("TUT passo ", g.tut.step)
	if frames == 40 + 20 * 10 + 30:
		var down := false
		for d in g.doors:
			if is_instance_valid(d) and d.reward.get("kind", "") == "tutorial_end":
				down = true
		if not down:
			push_error("TUT: manca la porta della discesa")
		print("TUT OK")
		quit()
		return true
	return false
