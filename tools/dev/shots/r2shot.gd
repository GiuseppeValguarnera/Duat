extends Node
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "r2_" + n + ".png")
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g != null and g.name == "Hub" and t > 1.0 and step == 0:
		while g.talk_box.visible: g._advance_talk()
		g._start_run(); t = 0; return
	if g == null or g.name != "Game":
		return
	var p = g.player
	if p == null or not is_instance_valid(p): return
	p.hp = p.max_hp
	if g.menu != null and is_instance_valid(g.menu) and step != 99:
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				Run.room = 10; g.start_room({"kind": "boss"}); step = 1; t = 0
		1:
			if not get_tree().paused and t > 3.0 and g.boss != null and is_instance_valid(g.boss):
				g.boss.die(); step = 2; t = 0
		2:
			if t > 3.0:
				var dd = null
				for d in g.doors:
					if d.reward.get("kind", "") == "region": dd = d
				L("porta regione: %s" % str(dd != null))
				shot("1_porta")
				if dd != null:
					g._on_door_chosen(dd)
				step = 3; t = 0
		3:
			if t > 0.8 and step == 3:
				shot("2_passaggio"); step = 4; t = 0
		4:
			if t > 2.5:
				L("regione %d stanza %d, sabbie mobili %d" % [Run.region, Run.room, get_tree().get_nodes_in_group("quicksand").size()])
				shot("3_sokar_1")
				Run.room = 4; g.start_room({"kind": "ka"}); step = 5; t = 0
		5:
			if t > 1.5:
				var st = Hazards.Sandstorm.new(); st.room = Rect2(Vector2.ZERO, g.ROOM.size); g.world.add_child(st)
				st.phase = "gust"; st.pt = 5.0
				L("stanza 5: sabbie %d, nemici %d" % [get_tree().get_nodes_in_group("quicksand").size(), get_tree().get_nodes_in_group("enemies").size()])
				step = 6; t = 0
		6:
			if t > 0.4:
				shot("4_tempesta"); get_tree().quit()
