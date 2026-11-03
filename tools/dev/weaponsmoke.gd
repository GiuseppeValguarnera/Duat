extends SceneTree
## Prova veloce di un'arma senza grafica (DUAT_WEAPON=arco, flagello...): colpi, attacco caricato e
## attacco in scatto, con tutti i doni dedicati a quell'arma. Un nemico è élite (aggancio del pastorale).
var frames := 0
var p = null

func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")

func _process(_d: float) -> bool:
	frames += 1
	if frames == 240:
		p = get_first_node_in_group("player")
		var run = root.get_node("Run")
		var ids := ["nefti_veil", "sobek_river", "duo_sekhmet_bastet", "duo_anubi_sekhmet", "shu_column", "shu_divide",
			"thoth_first", "thoth_timing", "thoth_glyph", "thoth_judgment", "thoth_stolen", "thoth_hourglass", "thoth_lesson", "nefti_heavy",
			"shu_heavy", "duo_thoth_iside", "duo_thoth_anubi", "anubi_guide", "horus_multi", "horus_pierce", "horus_mark"]
		for id in load("res://scripts/boons.gd").ALL_IT:
			if String(id).begins_with(run.weapon + "_"):
				ids.append(id)
		for id in ids:
			run.boons[id] = 1
		for i in range(6):
			var m = load("res://scenes/mummy.tscn" if i % 2 == 0 else "res://scenes/scarab.tscn").instantiate()
			m.position = p.position + Vector2(60 + i * 18, -20 + (i % 3) * 20)
			if i == 0:
				m.elite = true
			p.get_parent().add_child(m)
		print("weapon=", root.get_node("Run").weapon, " enemies=", get_nodes_in_group("enemies").size())
	if p != null and frames > 240 and frames < 900:
		if frames % 20 == 0:
			p.atk_cd = 0.0
			p._swing()
		if frames % 50 == 0:
			p.charge_cd = 0.0
			p.charge_full = true
			p.charging = true
			p._release_charge()
		if frames % 70 == 0:
			p.after_dash_t = 0.2
			p._swing()
		if frames % 90 == 0:
			p.eye_charges = 1
			p._fire_eye()
		if frames == 400:
			p.invuln_t = 0.0
			p.dash_t = 0.0
			p.take_damage(5.0, p.position + Vector2(10, 0))
			print("clessidra=", snappedf(root.get_node("Run").hourglass_t, 0.1), " lezione=", root.get_node("Run").scribe_lesson())
		p.hp = p.max_hp
		paused = false
		if frames == 300:
			print("paused=", paused, " arrows=", p.get_parent().get_children().filter(func(n): return n.get_script() == load("res://scripts/arrow.gd")).size())
	if frames == 900:
		print("weapon ok, enemies left=", get_nodes_in_group("enemies").size(), " damage=", int(root.get_node("Run").damage_dealt))
		return true
	return false
