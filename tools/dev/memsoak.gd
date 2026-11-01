extends SceneTree
## Caccia alle perdite di memoria, senza grafica: Sala → discesa (stanze di Wernes e di Sokar, i boss)
## → Sala, più volte. A ogni stanza e a ogni cambio di scena stampa memoria, oggetti, nodi, nodi
## orfani e risorse. Se un numero cresce giro dopo giro, è una perdita.
## Uso: DUAT_NOTUT=1 godot --headless --path . --script res://tools/dev/memsoak.gd  (CICLI=5)
var frames := 0
var step := 0
var cycle := 0
var room_i := 0
var wait := 0
var cycles := 4
var plan := []

func _initialize() -> void:
	cycles = int(OS.get_environment("CICLI")) if OS.get_environment("CICLI") != "" else 4
	# per ogni ciclo: 10 stanze di Wernes, il boss, poi 10 di Sokar e il suo boss
	for i in range(10):
		plan.append([1, i + 1, "none"])
	plan.append([1, 11, "boss"])
	for i in range(10):
		plan.append([2, i + 1, "none"])
	plan.append([2, 11, "boss"])
	change_scene_to_file("res://scenes/hub.tscn")
	wait = 90

func _log(tag: String) -> void:
	print("MEM %s c=%d mem=%.1f obj=%d nodes=%d orphans=%d res=%d" % [tag, cycle,
		OS.get_static_memory_usage() / 1048576.0,
		Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)])

func _process(_d: float) -> bool:
	paused = false
	if wait > 0:
		wait -= 1
		return false
	var run = root.get_node("Run")
	var g = current_scene
	if step == 0:
		_log("sala")
		change_scene_to_file("res://scenes/casa.tscn")
		step = 10
		wait = 60
		return false
	if step == 10:
		_log("casa")
		change_scene_to_file("res://scenes/armory.tscn")
		step = 11
		wait = 60
		return false
	if step == 11:
		_log("cortile")
		run.training = false
		run.new_run()
		change_scene_to_file("res://scenes/game.tscn")
		step = 1
		room_i = 0
		wait = 120
		return false
	if step == 1:
		if g == null or not g.has_method("start_room"):
			wait = 10
			return false
		if g.menu != null:
			g._close_choice()
		# chiudi la stanza: tutti i nemici a terra, poi la prossima
		for e in get_nodes_in_group("enemies"):
			if not e.dead:
				e.die()
		if room_i >= plan.size():
			_log("fine_discesa")
			step = 0
			cycle += 1
			if cycle >= cycles:
				return true
			change_scene_to_file("res://scenes/hub.tscn")
			wait = 120
			return false
		if room_i > 0:
			_log("prima")              # misurato prima di cambiare stanza: niente nodi in via di liberazione
		var pr: Array = plan[room_i]
		run.region = pr[0]
		run.room = pr[1] - 1
		g.start_room({"kind": pr[2]})
		room_i += 1
		_log("r%d.%d" % [pr[0], pr[1]])
		if OS.get_environment("ORFANI") != "" and room_i == 5:
			Node.print_orphan_nodes()
		wait = 240           # 4 secondi di gioco per stanza: nemici, proiettili, effetti
	return false
