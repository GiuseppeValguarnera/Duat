extends SceneTree
## Da dove vengono le chiamate di disegno? In una stanza piena (DUAT_REGION/ROOM), nasconde a turno
## ogni gruppo di nodi del mondo e dell'interfaccia e misura quante chiamate spariscono.
var frames := 0
var groups := {}
var keys := []
var ki := -1
var base := 0.0
var acc := 0.0
var cnt := 0

func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")

func _key(n: Node) -> String:
	var s = n.get_script()
	var k := n.get_class()
	if s != null:
		k = String(s.resource_path).get_file()
		if k == "":
			k = "inner:" + n.get_class() + ":" + str(s.get_instance_id() % 1000)
			if n.has_method("_draw"):
				var props := []
				for pr in n.get_property_list():
					if pr["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
						props.append(pr["name"])
				k += str(props.slice(0, 4))
	return k

func _process(_d: float) -> bool:
	frames += 1
	paused = false
	var g = current_scene
	if g == null or not g.has_method("start_room"):
		return false
	if g.menu != null:
		g._close_choice()
	if g.player != null and is_instance_valid(g.player):
		g.player.hp = g.player.max_hp
		g.player.invuln_t = 1.0
	if frames == 20:
		var run = root.get_node("Run")
		run.region = int(OS.get_environment("R")) if OS.get_environment("R") != "" else 2
		run.room = (int(OS.get_environment("S")) if OS.get_environment("S") != "" else 8) - 1
		g.start_room({"kind": "none"})
	if frames == 320:
		for n in g.world.get_children():
			if n is CanvasItem:
				var k := "mondo/" + _key(n)
				if not groups.has(k):
					groups[k] = []
				groups[k].append(n)
		for n in g.get_children():
			if n is CanvasItem and n != g.world:
				var k2 := "scena/" + _key(n)
				if not groups.has(k2):
					groups[k2] = []
				groups[k2].append(n)
		for n in g.get_node("UI").get_children():
			if n is CanvasItem:
				var k3 := "UI/" + _key(n)
				if not groups.has(k3):
					groups[k3] = []
				groups[k3].append(n)
		keys = groups.keys()
	if frames > 320 and frames <= 360:
		acc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		cnt += 1
	if frames == 360:
		base = acc / cnt
		print("SPLIT base %.0f" % base)
		ki = 0
		acc = 0.0
		cnt = 0
	if ki >= 0 and ki < keys.size():
		var local := (frames - 361) % 20
		if local == 0:
			for n in groups[keys[ki]]:
				if is_instance_valid(n):
					n.visible = false
		elif local >= 8:
			acc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			cnt += 1
		if local == 19:
			for n in groups[keys[ki]]:
				if is_instance_valid(n):
					n.visible = true
			print("SPLIT %-40s n=%3d  -%.0f" % [keys[ki], groups[keys[ki]].size(), base - acc / cnt])
			acc = 0.0
			cnt = 0
			ki += 1
	if ki >= keys.size() and ki > 0:
		return true
	return false
