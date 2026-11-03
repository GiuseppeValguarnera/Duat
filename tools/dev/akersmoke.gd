extends SceneTree
## Prova veloce di Aker senza grafica: tutte le mosse della fase 1, la divisione, la tenaglia, la
## furia del sopravvissuto, la vittoria. L'eroe non muore (vita piena a ogni fotogramma).
var frames := 0
var g = null
var aker = null
var moves := ["bite", "charge", "breath", "leap", "ray"]
var mi := 0

func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")

func _process(_d: float) -> bool:
	frames += 1
	paused = false
	g = current_scene
	if g == null or not g.has_method("start_room"):
		return false
	if g.menu != null:
		g._close_choice()
	if g.player != null and is_instance_valid(g.player):
		g.player.hp = g.player.max_hp
	if frames == 30:
		var run = root.get_node("Run")
		run.region = 2
		run.room = 10
		g.start_room({"kind": "none"})
	if frames == 520:
		for e in get_nodes_in_group("enemies"):
			if e.has_method("facing_sign"):
				aker = e
		print("aker=", aker != null, " barra piena=", g.boss_full, " nemici=", get_nodes_in_group("enemies").map(func(e): return e.name), " stanza=", root.get_node("Run").room, " reg=", root.get_node("Run").region, " boss=", g.boss)
	# una mossa ogni 4 secondi
	if aker != null and is_instance_valid(aker) and frames > 520 and frames < 520 + 240 * moves.size() and (frames - 520) % 240 == 1:
		aker._start(moves[mi], g.player.global_position - aker.global_position)
		print("mossa ", moves[mi])
		mi += 1
	if frames == 520 + 240 * moves.size() + 30:
		var serv := get_nodes_in_group("aker_servants")
		print("arena: stele=", get_nodes_in_group("horizon_stele").size(), " sabbie=", get_nodes_in_group("quicksand").size(), " servitori=", serv.map(func(e): return e.name))
	if frames == 520 + 240 * moves.size() + 60 and aker != null and is_instance_valid(aker):
		aker.chain_left = 1
		aker.take_hit(99999.0, Vector2.RIGHT, 0.0)
		print("stato dopo il colpo finale: ", aker.state)
	if frames > 520 + 240 * moves.size() + 60 and frames < 520 + 240 * moves.size() + 260 and frames % 40 == 0:
		print("  ", frames, " nemici=", get_nodes_in_group("enemies").map(func(e): return [e.name, e.get("state"), e.hp]))
	if frames == 520 + 240 * moves.size() + 260:
		var lions := get_nodes_in_group("enemies").filter(func(e): return "kind" in e and e.has_method("bot_escape"))
		print("leoni: ", lions.size(), " gruppo boss: ", g.boss_group.size())
		if lions.size() == 2:
			lions[0]._pincer(g.player.global_position - lions[0].global_position)
	if frames == 520 + 240 * moves.size() + 600:
		var lions2 := get_nodes_in_group("enemies").filter(func(e): return "kind" in e and e.has_method("bot_escape"))
		if lions2.size() >= 1:
			lions2[0].take_hit(9999.0, Vector2.RIGHT, 0.0)
	if frames == 520 + 240 * moves.size() + 800:
		var lions3 := get_nodes_in_group("enemies").filter(func(e): return "kind" in e and e.has_method("bot_escape") and not e.dead)
		for l in lions3:
			print("sopravvissuto: ", l.kind, " furia=", l.fury, " solo=", l.alone, " partner=", l.partner, " valido=", is_instance_valid(l.partner), " stato=", l.state)
			l.take_hit(9999.0, Vector2.RIGHT, 0.0)
	if frames == 520 + 240 * moves.size() + 1300:
		print("aker ok, vittorie=", root.get_node("Meta").aker_wins)
		return true
	return false
