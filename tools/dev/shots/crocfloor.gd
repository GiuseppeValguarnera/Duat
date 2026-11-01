extends Node
## Coccodrilli "sott'acqua" sul pavimento asciutto: riproduce i due modi in cui succedeva.
## 1) la rete di sicurezza lo sposta sul pavimento mentre è immerso (_relocate);
## 2) torna verso l'acqua ma non ci arriva in tempo (stato "return" scaduto lontano dall'acqua).
## Dopo un secondo controlla: un coccodrillo immerso deve essere dentro l'acqua.
## Uso: tools/dev/shot.sh crocfloor 1280 720 res://scenes/game.tscn
var t := 0.0
var step := 0
var c1 = null
var c2 = null
var bad := {"spostato dalla rete": 0, "ritorno scaduto": 0}
var shot_done := false
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _in_water(c) -> bool:
	for w in get_tree().get_nodes_in_group("water"):
		var r: Vector2 = w.rect / 2.0 if w.rect != Vector2.ZERO else w.radii
		var d: Vector2 = c.global_position - w.global_position
		if w.rect != Vector2.ZERO:
			if absf(d.x) <= r.x and absf(d.y) <= r.y:
				return true
		elif (d / r).length() <= 1.0:
			return true
	return false
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
				g.waves = []
				for e in get_tree().get_nodes_in_group("enemies"):
					e.queue_free()
				var waters := get_tree().get_nodes_in_group("water")
				if waters.is_empty():
					L("nessuna acqua in questa stanza: riprovo"); step = 0; t = 0.5
					return
				var w = waters[0]
				for i in range(2):
					var c = g.ENEMIES["crocodile"].instantiate()
					c.position = w.global_position
					g.world.add_child(c)
					g.alive += 1
					c.killed.connect(g._on_enemy_killed)
					if i == 0: c1 = c
					else: c2 = c
				p.global_position = Vector2(g.ROOM.size.x - 80.0, g.ROOM.size.y - 70.0)
				step = 2; t = 0
		2:
			if t > 0.6:
				# 1) la rete di sicurezza lo porta sul pavimento mentre è immerso
				c1.global_position = Vector2(g.ROOM.size.x / 2.0 - 140.0, g.ROOM.size.y - 90.0)   # dove la rete lo può posare
				c1._relocate(g)
				# 2) il ritorno scade lontano dall'acqua
				c2._set_submerged(false)
				c2.state = "return"
				c2.st = 0.0
				c2.global_position = Vector2(g.ROOM.size.x / 2.0 + 120.0, g.TOP + 60.0)
				step = 3; t = 0
		3:
			for pair in [["spostato dalla rete", c1], ["ritorno scaduto", c2]]:
				var cc = pair[1]
				if is_instance_valid(cc) and (cc.state == "submerged" or cc.state == "warn") and not _in_water(cc):
					bad[pair[0]] += 1
					if not shot_done:
						shot_done = true
						get_viewport().get_texture().get_image().save_png(D + "croc_floor_bug.png")
			if t > 2.0:
				L("fotogrammi immerso fuori dall'acqua: %s" % str(bad))
				for pair in [["spostato dalla rete", c1], ["ritorno scaduto", c2]]:
					var c = pair[1]
					if is_instance_valid(c):
						var sub: bool = c.state == "submerged" or c.state == "warn"
						L("%s: stato=%s in acqua=%s -> %s" % [pair[0], c.state, str(_in_water(c)), "BUG (immerso sul pavimento)" if sub and not _in_water(c) else "ok"])
				get_viewport().get_texture().get_image().save_png(D + "croc_floor.png")
				get_tree().quit()
