extends Node
## L'Oasi della quarta ora: fotografa la sosta, usa fonte, altare e statua, poi cammina fino alla
## porta e controlla che la discesa riparta da Sokar (stanza 1).
## Uso: DUAT_REGION2=1 tools/dev/shot.sh oasisshot 1280 720 res://scenes/game.tscn [mobile]
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "oasi_" + n + ".png")
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	match step:
		0:
			if g.menu != null:
				g._close_choice()
			if t > 1.0:
				Meta.amulets = ["iside", "ankh", "djed"]
				Meta.amulet = "iside"
				Run.amulet = "iside"
				Run.region = 2; Run.room = 0
				Run.ka = 200
				Run.hp = Run.max_hp * 0.5
				g.start_room({"kind": "oasis"})
				step = 1; t = 0
		1:
			if t > 2.0:
				L("stanza=%d nodi=%d oggetti=%d porte=%d" % [Run.room, g.oasis_nodes.size(), g.shop_items.size(), g.doors.size()])
				_shot("0_intera")
				step = 2; t = 0
		2:
			var sp = g.oasis_nodes[0]
			p.global_position = sp.global_position + Vector2(0, 52)
			if t > 0.4:
				g.prompt.visible = g.prompt.visible
				L("prompt vicino alla fonte: %s" % g.prompt.text)
				_shot("1_fonte_prompt")
				var hp0: float = Run.hp
				g._use_oasis(sp)
				L("vita %.0f -> %.0f, fonte usata=%s" % [hp0, p.hp, str(sp.used)])
				step = 3; t = 0
		3:
			if t > 0.8:
				_shot("2_fonte_usata")
				step = 4; t = 0
		4:
			var al = g.oasis_nodes[1]
			p.global_position = al.global_position + Vector2(0, 30)
			if t > 0.4:
				L("prompt altare: %s" % g.prompt.text)
				g._use_oasis(al)
				step = 5; t = 0
		5:
			if t > 1.8:
				_shot("3_altare_carte")
				L("menu aperto=%s" % str(g.menu != null))
				g._wear_amulet("djed", g.oasis_nodes[1])
				L("amuleto ora=%s livello=%d" % [Run.amulet, Run.amulet_level])
				step = 6; t = 0
		6:
			if t > 0.6:
				var st = g.oasis_nodes[2]
				p.global_position = st.global_position + Vector2(0, 30)
				g._use_oasis(st)
				step = 7; t = 0
		7:
			if t > 1.2:
				_shot("4_statua")
				step = 8; t = 0
		8:
			var ft = g.ferry
			if ft != null:
				p.global_position = ft.global_position + Vector2(0, 40)
			if t > 0.6:
				_shot("5_mahaf")
				step = 9; t = 0
		9:
			if t < dt * 1.5:
				p.global_position = g.doors[0].global_position + Vector2(0, 40)
			Input.action_press("move_up")
			if t > 3.0 or Run.room == 1:
				Input.action_release("move_up")
				L("dopo la porta: regione=%d stanza=%d nemici in arrivo=%d" % [Run.region, Run.room, g.alive + g.spawning])
				_shot("6_dopo")
				get_tree().quit()
