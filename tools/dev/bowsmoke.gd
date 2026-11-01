extends SceneTree
## Prova veloce dell'arco senza grafica: tiri, tiro carico, ventaglio, con tutti i doni dell'arco.
var frames := 0
var p = null

func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")

func _process(_d: float) -> bool:
	frames += 1
	if frames == 240:
		p = get_first_node_in_group("player")
		for id in ["arco_ra", "arco_sekhmet", "arco_thoth", "arco_bastet", "arco_sobek", "arco_iside", "arco_horus", "arco_anubi", "arco_nefti", "arco_shu", "nefti_veil", "sobek_river", "duo_sekhmet_bastet", "duo_anubi_sekhmet"]:
			root.get_node("Run").boons[id] = 1
		for i in range(6):
			var m = load("res://scenes/mummy.tscn" if i % 2 == 0 else "res://scenes/scarab.tscn").instantiate()
			m.position = p.position + Vector2(60 + i * 18, -20 + (i % 3) * 20)
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
		p.hp = p.max_hp
		paused = false
		if frames == 300:
			print("paused=", paused, " arrows=", p.get_parent().get_children().filter(func(n): return n.get_script() == load("res://scripts/arrow.gd")).size())
	if frames == 900:
		print("arrows ok, enemies left=", get_nodes_in_group("enemies").size())
		return true
	return false
