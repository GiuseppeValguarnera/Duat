extends Node
var t := 0.0
var step := 0
var croc = null
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "croc_" + n + ".png")
	if croc != null and is_instance_valid(croc):
		var sp: Vector2 = croc.get_global_transform_with_canvas().origin
		print("POS ", n, " ", int(sp.x), " ", int(sp.y))
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game":
		return
	if g.menu != null and t > 1.0:
		for b in g.menu.find_children("*", "BaseButton", true, false):
			b.pressed.emit(); break
		t = 0
		return
	var p = g.player
	if p == null or not is_instance_valid(p): return
	p.hp = p.max_hp
	match step:
		0:
			if g.menu == null and t > 0.8:
				for e in get_tree().get_nodes_in_group("enemies"): e.die()
				g.waves = []
				var pool := Hazards.WaterPool.new()
				pool.rect = Vector2(200, 30)
				pool.position = p.global_position + Vector2(0, -110)
				g.world.add_child(pool)
				croc = g.ENEMIES["crocodile"].instantiate()
				croc.position = pool.position + Vector2(60, 0)
				g.world.add_child(croc)
				p.global_position += Vector2(-150, 0)
				step = 1; t = 0
		1:
			if t > 1.0:
				shot("1_sottacqua"); L("stato %s" % croc.state)
				p.global_position = croc.global_position + Vector2(-40, 60)
				step = 2; t = 0
		2:
			if is_instance_valid(croc) and croc.state == "warn" and t > 0.2:
				shot("2_avviso"); step = 3; t = 0
			elif t > 4.0:
				L("niente avviso, stato %s" % croc.state); step = 3; t = 0
		3:
			if is_instance_valid(croc) and croc.state == "lunge":
				shot("3_morso"); step = 4; t = 0
			elif t > 2.0:
				step = 4; t = 0
		4:
			if is_instance_valid(croc) and croc.state == "land" and t > 0.2:
				shot("4_a_terra"); L("a terra, vita %d" % croc.hp)
				croc.take_hit(10, Vector2.RIGHT, 0)
				step = 5; t = 0
			elif t > 3.0:
				step = 5; t = 0
		5:
			if is_instance_valid(croc) and croc.state == "submerged" and t > 0.1:
				L("tornato in acqua dopo %.1f s, vita %d" % [t, croc.hp]); step = 6
			elif t > 6.0:
				L("non torna, stato %s" % (croc.state if is_instance_valid(croc) else "morto")); step = 6
		6:
			get_tree().quit()
