extends Node
## Profondità delle colonne: una mummia DIETRO una colonna (sopra la base, sullo schermo) deve
## essere coperta dal fusto; una DAVANTI deve stare sopra la colonna. Prima i personaggi erano
## sempre disegnati sopra le colonne e chi passava dietro sembrava attraversarle.
## Uso: tools/dev/shot.sh pillardepth 1280 720 res://scenes/game.tscn [mobile]
var t := 0.0
var step := 0
var behind = null
var front = null
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	p.hp = p.max_hp
	p.invuln_t = 1.0
	if g.menu != null and is_instance_valid(g.menu):
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				Run.room = 3
				g.start_room({"kind": "ka"})
				step = 1; t = 0
		1:
			if t > 1.5:
				if g.pillars.is_empty():
					step = 0; t = 0.5
					return
				g.waves = []
				for e in get_tree().get_nodes_in_group("enemies"):
					e.queue_free()
				var col: Vector2 = g.pillars[0]
				for i in range(2):
					var m = g.ENEMIES["mummy"].instantiate()
					m.position = col + (Vector2(0, -18) if i == 0 else Vector2(4, 14))
					g.world.add_child(m)
					m.set_physics_process(false)          # fermi: è una foto della profondità
					if i == 0: behind = m
					else: front = m
				p.global_position = col + Vector2(0, 90)
				step = 2; t = 0
		2:
			if t > 0.5:
				var pa = g.pillar_art
				L("colonna z=%d  dietro z=%d  davanti z=%d" % [pa.z_index, behind.z_index, front.z_index])
				var ok: bool = behind.z_index < pa.z_index and front.z_index > pa.z_index
				L("profondità giusta: %s" % str(ok))
				get_viewport().get_texture().get_image().save_png(D + "pillar_depth.png")
				get_tree().quit()
