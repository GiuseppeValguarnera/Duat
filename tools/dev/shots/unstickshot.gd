extends Node
## Rete di sicurezza dei nemici incastrati: uno scarabeo chiuso in una gabbia di muri, con te
## lontano, deve ricomparire fuori dopo circa 3 secondi. Uno vicino a te (mischia) no.
## Uso: tools/dev/shot.sh unstickshot 1280 720 res://scenes/game.tscn
var t := 0.0
var step := 0
var sc = null
var near = null
var p0 := Vector2.ZERO
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _cage(g, c: Vector2) -> void:
	for r in [Rect2(c + Vector2(-20, -20), Vector2(40, 6)), Rect2(c + Vector2(-20, 14), Vector2(40, 6)), Rect2(c + Vector2(-20, -20), Vector2(6, 40)), Rect2(c + Vector2(14, -20), Vector2(6, 40))]:
		g._solid(r)
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	p.hp = p.max_hp; p.invuln_t = 1.0
	if g.menu != null and is_instance_valid(g.menu) and t > 0.5:
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				Run.room = 2; g.start_room({"kind": "ka"}); step = 1; t = 0
		1:
			if t > 1.2:
				g.waves = []
				for e in get_tree().get_nodes_in_group("enemies"): e.die()
				p.global_position = Vector2(560, 360)
				var c := Vector2(150, 160)
				_cage(g, c)
				sc = g.ENEMIES["scarab"].instantiate(); sc.position = c; g.world.add_child(sc)
				p0 = c
				# uno scarabeo attaccato a te, spinto contro un muro: non deve sparire
				var c2: Vector2 = p.global_position + Vector2(30, 0)
				_cage(g, c2)
				near = g.ENEMIES["scarab"].instantiate(); near.position = c2; g.world.add_child(near)
				p.set_physics_process(false)
				# un terzo scarabeo finito fuori dalla stanza (oltre il muro di destra)
				var out = g.ENEMIES["scarab"].instantiate(); out.position = Vector2(g.ROOM.size.x + 10.0, 200.0); g.world.add_child(out)
				set_meta("out", out)
				step = 2; t = 0
		2:
			if not is_instance_valid(sc) or not is_instance_valid(near):
				L("uno scarabeo non c'è più: lontano=%s vicino=%s (t=%.1f)" % [str(is_instance_valid(sc)), str(is_instance_valid(near)), t])
				get_tree().quit()
				return
			if int(t) != int(t - dt):
				L("t=%d lontano a %s" % [int(t), str(sc.global_position)])
			if t > 2.0 and t - dt <= 2.0:
				L("dopo 2 s: nella gabbia=%s" % str(sc.global_position.distance_to(p0) < 20.0))
			if t > 5.5:
				var o = get_meta("out")
				L("fuori dalla stanza riportato dentro=%s (a %s)" % [str(is_instance_valid(o) and g._in_floor(o.global_position, 0.0)), str(o.global_position) if is_instance_valid(o) else "-"])
				L("dopo 5,5 s: lontano, fuori dalla gabbia=%s (a %s)   vicino a te, ancora al suo posto=%s" % [str(sc.global_position.distance_to(p0) > 20.0), str(sc.global_position), str(near.global_position.distance_to(p.global_position + Vector2(30, 0)) < 20.0)])
				get_tree().quit()
