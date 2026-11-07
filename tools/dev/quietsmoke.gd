extends SceneTree
## Blocco 14: prima di boss e mini boss tutte le porte portano a stanze senza nemici
## (Traghettatore, sala con la cura, sala con un dono), poi una porta sola verso la prova.
var frames := 0
var g = null

func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")

func _rewards() -> Array:
	var out := []
	for d in g.doors:
		if is_instance_valid(d) and not d.reward.is_empty():
			out.append("%s%s" % [d.reward.get("kind", ""), " (calma)" if d.reward.get("calm", false) else ""])
	return out

func _process(_d: float) -> bool:
	frames += 1
	var run = root.get_node("Run")
	if frames == 60:
		g = current_scene
		for c in g.get_tree().get_nodes_in_group("enemies"):
			c.queue_free()
		for d in g.doors:
			if is_instance_valid(d):
				d.queue_free()
		g.doors.clear()
		run.room = run.GUARDIAN_ROOM - 2
		g._open_doors()
		print("porte prima del guardiano: ", _rewards())
		run.room = run.ROOMS_PER_RUN - 1
		for d in g.doors:
			if is_instance_valid(d):
				d.queue_free()
		g.doors.clear()
		g._open_doors()
		print("porte prima del boss: ", _rewards())
		run.room = run.GUARDIAN_ROOM - 1
		g.start_room({"kind": "heal", "calm": true})
	if frames == 90:
		print("sala tranquilla: nemici=", g.get_tree().get_nodes_in_group("enemies").size(), " ondate=", g.waves.size(), " ripulita=", g.cleared)
		print("cura traghettatore = %.0f%% della stanza di cura" % (100.0 * run.ferry_heal() / run.nile_heal()))
		return true
	return false
