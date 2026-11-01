extends SceneTree
## Misura delle prestazioni (con la grafica, sotto xvfb): chiamate di disegno, oggetti disegnati,
## tempo di logica e di fisica per fotogramma. Scene: una stanza piena di Sokar, Aker, Am-heh.
## Uso: xvfb-run godot --path . --rendering-driver opengl3 --script res://tools/dev/perfprobe.gd
var frames := 0
var phase := 0
var samples := []
var t0 := 0
const PLAN := [
	[2, 8, "none", "Sokar stanza 8"],
	[2, 11, "none", "Aker"],
	[1, 11, "none", "Am-heh"],
	[1, 6, "none", "Wernes stanza 6"],
]

func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")

func _mon(id) -> float:
	return Performance.get_monitor(id)

func _process(_d: float) -> bool:
	frames += 1
	paused = false
	var g = current_scene
	if g == null or not g.has_method("start_room"):
		return false
	if g.menu != null:
		g._close_choice()
	var p = g.player
	if p != null and is_instance_valid(p):
		p.hp = p.max_hp
		p.invuln_t = 1.0
	if frames == 30 + phase * 600:
		if phase >= PLAN.size():
			return true
		var pr: Array = PLAN[phase]
		var run = root.get_node("Run")
		run.region = pr[0]
		run.room = pr[1] - 1
		g.start_room({"kind": pr[2]})
		samples = []
	var local := frames - (30 + phase * 600)
	if local > 300 and local <= 540:
		samples.append([_mon(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), _mon(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			_mon(Performance.TIME_PROCESS) * 1000.0, _mon(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			get_nodes_in_group("enemies").size(), _mon(Performance.OBJECT_NODE_COUNT)])
	if local == 541:
		var n := float(samples.size())
		var sums := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
		var mx := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
		for s in samples:
			for i in range(6):
				sums[i] += s[i]
				mx[i] = maxf(mx[i], s[i])
		print("PERF %s: draw %.0f (max %.0f) · oggetti %.0f · logica %.2f ms (max %.2f) · fisica %.2f ms (max %.2f) · nemici %.0f · nodi %.0f" % [PLAN[phase][3],
			sums[0] / n, mx[0], sums[1] / n, sums[2] / n, mx[2], sums[3] / n, mx[3], sums[4] / n, sums[5] / n])
		phase += 1
	return false
