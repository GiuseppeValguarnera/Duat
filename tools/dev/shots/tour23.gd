extends Node
## Blocco 23: foto di controllo di una stanza di combattimento con l'Arte dell'arma in azione.
## DUAT_WEAPON sceglie l'arma, DUAT_START_REGION la regione, DUAT_SHOT_NAME il prefisso, DUAT_EVO il
## grado d'evoluzione (0-3). Con "-- --mobile" accende i comandi a tocco (così compaiono nella foto).
## Foto: 0 = la stanza con i nemici, 1 = l'Arte appena lanciata, 2 = l'Arte a metà, 3 = dopo.
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
var N := OS.get_environment("DUAT_SHOT_NAME")
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if N == "":
		N = "tour"
	var ev := OS.get_environment("DUAT_EVO")
	if ev != "":
		Meta.weapon_evo[Run.weapon if Run.weapon != "" else "khopesh"] = int(ev)
func shot(i: int) -> void:
	get_viewport().get_texture().get_image().save_png(D + N + "_%d.png" % i)
func _process(dt: float) -> void:
	var g = get_tree().current_scene
	if g == null or g.name != "Game":
		return
	if Fx.mobile:
		Touch.active = true
		Fx.device = "touch"
	if g.menu != null:
		g._close_choice()
		if step == 0:
			g.start_room({"kind": "ka"})
			t = 0.0
	if g.player == null or not is_instance_valid(g.player):
		return
	g.player.hp = maxf(g.player.hp, g.player.max_hp * 0.7)
	t += dt
	var ev := OS.get_environment("DUAT_EVO")
	if ev != "":
		Meta.weapon_evo[Run.weapon] = int(ev)
	match step:
		0:
			if t > 3.2:
				shot(0)
				step = 1
		1:
			if t > 3.6:
				# l'Arte verso il nemico più vicino
				var best = null
				for e in get_tree().get_nodes_in_group("enemies"):
					if not e.dead and (best == null or e.global_position.distance_to(g.player.global_position) < best.global_position.distance_to(g.player.global_position)):
						best = e
				if best != null:
					g.player.aim = (best.global_position - g.player.global_position).normalized()
				g.player.art_cd = 0.0
				g.player.try_art()
				step = 2
		2:
			if t > 3.72:
				shot(1)
				step = 3
		3:
			if t > 3.95:
				shot(2)
				step = 4
		4:
			if t > 5.0:
				shot(3)
				get_tree().quit()
